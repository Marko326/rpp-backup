"""DEV-311: source-trace the three Johto gates still using shared Gate_Coll."""
from __future__ import annotations

import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))

from johto_gatehouse_behavior_audit import (
    _constants, audit_active_gatehouse_carpet_walkability,
)
from johto_gatehouse_step_trace_308 import (
    simulate_legacy_gate_dispatch, simulate_legacy_gate_passability,
)

GOLD = (Path(os.environ.get('JOHTO_GOLD_SOURCE') or os.environ['GOLD_SOURCE_ROOT'])
        if os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('GOLD_SOURCE_ROOT') else None)


class GatehouseLegacyTrace311(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.constants = _constants(ROOT)
        cls.gateway = (ROOT / 'engine/johto_land_collision_gateway_272.asm').read_text()
        cls.home = (ROOT / 'home/overworld.asm').read_text()
        cls.player_state = (ROOT / 'engine/overworld/player_state.asm').read_text()
        cls.passable = (ROOT / 'gfx/tilesets/gate.tilecoll').read_bytes()

    def test_three_legacy_gates_dispatch_to_shared_generic_fallback(self):
        for gate_id in (6, 19, 102):
            with self.subTest(gate_id=gate_id):
                self.assertEqual(2, simulate_legacy_gate_dispatch(
                    self.gateway, constants=self.constants, gate_id=gate_id))

    def test_future_route43_gate_ids_can_reuse_the_generic_dispatch_runner(self):
        # IDs 65/66 are reserved and inactive today.  Their planned Gold maps
        # use JOHTO_GATE/Gate_Coll, so the same E=2 dispatcher is reusable.
        for gate_id in (65, 66):
            with self.subTest(gate_id=gate_id):
                self.assertEqual(2, simulate_legacy_gate_dispatch(
                    self.gateway, constants=self.constants, gate_id=gate_id))

    def test_actual_check_tile_passable_instruction_loop(self):
        for gate_id in (6, 19, 102):
            with self.subTest(gate_id=gate_id):
                self.assertFalse(simulate_legacy_gate_passability(
                    self.home, gate_id=gate_id, tile_id=0x02,
                    passable_tiles=self.passable))
                self.assertTrue(simulate_legacy_gate_passability(
                    self.home, gate_id=gate_id, tile_id=0x00,
                    passable_tiles=self.passable))
                # $3c is not given a special Cherrygrove exception in these
                # maps; it proceeds through the actual shared Gate_Coll list.
                self.assertFalse(simulate_legacy_gate_passability(
                    self.home, gate_id=gate_id, tile_id=0x3c,
                    passable_tiles=self.passable))

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT')
    def test_all_three_legacy_gatehouses_are_asm_traced_against_gold(self):
        result = audit_active_gatehouse_carpet_walkability(ROOT, GOLD)
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result['errors'])
        self.assertEqual({6: 172, 19: 218, 102: 172},
                         {int(k): v for k, v in result['asm_traced_moves'].items()
                          if int(k) in (6, 19, 102)})

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT')
    def test_legacy_check_tile_passable_fault_is_detected(self):
        relative = 'home/overworld.asm'
        segment = self.home.split('CheckTilePassable::', 1)[1].split(
            'CheckForJumpingAndTilePairCollisions::', 1)[0]
        self.assertIn('\tcp c\n\tret z', segment)
        broken_segment = segment.replace('\tcp c\n\tret z', '\tcp b\n\tret z', 1)
        broken = self.home.replace(segment, broken_segment, 1)
        self.assertNotEqual(self.home, broken)
        report = audit_active_gatehouse_carpet_walkability(
            ROOT, GOLD, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('ID6 Route31VioletGate' in error and
                            'legacy source trace' in error
                            for error in report['errors']), report['errors'][:12])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT')
    def test_legacy_gate_must_not_be_routed_to_south_role_grid(self):
        relative = 'engine/johto_land_collision_gateway_272.asm'
        needle = '.southMaps\n    ; FIX-285: 17 Route35 / 18 Goldenrod north gate were registered after'
        self.assertIn(needle, self.gateway)
        broken = self.gateway.replace(
            needle,
            '.southMaps\n'
            '    ld a, [wCurLocalMapID]\n'
            '    cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID\n'
            '    jp z, .activeSouthMap\n'
            '    ; FIX-285: 17 Route35 / 18 Goldenrod north gate were registered after',
            1,
        )
        report = audit_active_gatehouse_carpet_walkability(
            ROOT, GOLD, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('ID102 Route32RuinsOfAlphGate' in error and
                            'legacy source trace' in error
                            for error in report['errors']), report['errors'][:12])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT')
    def test_legacy_front_tile_probe_offset_is_guarded(self):
        relative = 'engine/overworld/player_state.asm'
        broken = self.player_state.replace('aCoord 8, 11', 'aCoord 8, 7', 1)
        self.assertNotEqual(self.player_state, broken)
        report = audit_active_gatehouse_carpet_walkability(
            ROOT, GOLD, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('GetTileAndCoordsInFrontOfPlayer probe offset missing' in error
                            for error in report['errors']), report['errors'][:12])


if __name__ == '__main__':
    unittest.main()
