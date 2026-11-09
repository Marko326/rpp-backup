"""REF-316 regression coverage for the now-active Route43/ID65 pair."""
from __future__ import annotations
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gatehouse_step_trace_308 import simulate_legacy_gate_dispatch, simulate_legacy_gate_passability
from johto_gatehouse_behavior_audit import _constants, audit_active_gatehouse_carpet_walkability

GOLD = os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('GOLD_SOURCE_ROOT')


class Route43MahoganyGate316(unittest.TestCase):
    def test_route43_has_registered_ID65_and_ID66_pairs(self):
        constants = (ROOT / 'constants/region_map_constants.asm').read_text()
        version = (ROOT / 'data/game_version.asm').read_text()
        route43 = (ROOT / 'data/johto_route43_runtime_315.asm').read_text()
        gate = (ROOT / 'data/johto_route43_mahogany_gate_313.asm').read_text()
        gate66 = (ROOT / 'data/johto_route43_gate_319.asm').read_text()
        shared = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        engine = (ROOT / 'engine/johto_pilot_runtime.asm').read_text()
        self.assertRegex(constants, r'NUM_JOHTO_ACTIVE_MAPS EQU (?:4[1-9]|[5-9][0-9]|[1-9][0-9]{2,})')
        self.assertRegex(version, r'db "REF-\d{3}[A-Z]?@"')
        self.assertIn('db 5 ; Gold Route43 warps #1..#5 in original order', route43)
        self.assertIn('db 4 ; Gold lower 2 carpets + upper 2 DOORs, Route43 (ID67) now active', gate)
        self.assertIn('db 4 ; Gold #1/#2 top DOORs -> Route43 north carpets #4/#5', gate66)
        self.assertIn('JOHTO_ROUTE_43_LOCAL_ID', engine)
        before = shared.split('JohtoVerticalGateBeforeStepProfiles314::', 1)[1].split(
            'JohtoVerticalGateBeforeStepProfilesEnd314::', 1)[0]
        after = shared.split('JohtoVerticalGateAfterStepProfiles314::', 1)[1].split(
            'JohtoVerticalGateAfterStepProfilesEnd314::', 1)[0]
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 36', before)
        for x in (9,10):
            self.assertNotIn(f'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, {x}, 51', before)
            self.assertIn(f'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, {x}, 51, 1', after)
        for x in (17,18):
            self.assertIn(f'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, {x}, 30', before)
            self.assertIn(f'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, {x}, 31, 1', after)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 17, 31', before)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 18, 31', before)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3', after)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3', after)
        helper = engine.split('JohtoPilotIsVerticalGatePairMap314::', 1)[1].split(
            'JohtoPilotGateArrivalStep::', 1)[0]
        self.assertEqual(1, helper.count('cp JOHTO_MAHOGANY_TOWN_LOCAL_ID'))
        self.assertEqual(1, helper.count('cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID'))
        self.assertEqual(1, helper.count('cp JOHTO_ROUTE_43_LOCAL_ID'))
        self.assertEqual(1, helper.count('cp JOHTO_ROUTE_43_GATE_LOCAL_ID'))
        self.assertEqual(1, helper.count('cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID'))
        self.assertEqual(1, helper.count('cp JOHTO_ROUTE_46_LOCAL_ID'))
        self.assertEqual(1, helper.count('cp JOHTO_ROUTE_29_LOCAL_ID'))
        self.assertEqual(5, engine.count('call JohtoPilotIsVerticalGatePairMap314'))
        warp_table = engine.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        self.assertIn('db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID', warp_table)
        self.assertIn('db MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID', warp_table)
        objects = gate.split('JohtoRoute43MahoganyGateRuntimeObjects::', 1)[1]
        self.assertIn('db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR', objects)
        self.assertIn('db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR', objects)
        self.assertIn('db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR', objects)
        self.assertIn('db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR', objects)
        self.assertEqual(4, objects.split('db 4 ; Gold lower', 1)[1].split('db 0 ; no signs', 1)[0].count('JOHTO_REGISTERED_WARP_SELECTOR'))

    def test_existing_legacy_collision_is_shared(self):
        constants = _constants(ROOT)
        gateway = (ROOT / 'engine/johto_land_collision_gateway_272.asm').read_text()
        home = (ROOT / 'home/overworld.asm').read_text()
        for stable in (6, 19, 65, 66, 102):
            with self.subTest(stable=stable):
                self.assertEqual(2, simulate_legacy_gate_dispatch(gateway, constants=constants, gate_id=stable))
                self.assertTrue(simulate_legacy_gate_passability(home, gate_id=stable, tile_id=0,
                    passable_tiles=(ROOT / 'gfx/tilesets/gate.tilecoll').read_bytes()))

    def test_route43_north_warp_carpet_uses_exact_gold_directional_profile(self):
        roles = (ROOT / 'maps/johto_pilot/Route43.roles.bin').read_bytes()
        # Coarse role grid stays fail-closed; exact BeforeStep profiles emulate Gold LAND_TILE.
        self.assertEqual(1, roles[31 * 20 + 17])
        self.assertEqual(1, roles[31 * 20 + 18])
        self.assertEqual(0, roles[51 * 20 + 9])  # ID65 south pair retains its proven role.
        self.assertEqual(0, roles[51 * 20 + 10])
        self.assertEqual(1, roles[35 * 20 + 17])  # DOOR remains a solid trigger.
        self.assertEqual(1, roles[31 * 20 + 16])  # Gold side walls remain blocked.
        self.assertEqual(1, roles[31 * 20 + 19])
        shared = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        for row in (
            'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30',
            'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 30',
            'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 17, 31',
            'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 18, 31',
            'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3',
            'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3'):
            self.assertIn(row, shared)

    def test_gold_source_reuse_is_exact(self):
        new_gold = (ROOT / 'maps/johto_pilot/Route43MahoganyGate.gold.blk').read_bytes()
        new_runtime = (ROOT / 'maps/johto_pilot/Route43MahoganyGate.runtime.blk').read_bytes()
        self.assertEqual(20, len(new_gold))
        self.assertEqual(new_gold, (ROOT / 'maps/johto_pilot/Route35GoldenrodGate.gold.blk').read_bytes())
        self.assertEqual(new_runtime, (ROOT / 'maps/johto_pilot/Route35GoldenrodGate.mature.blk').read_bytes())
        if GOLD:
            self.assertEqual(new_gold, (Path(GOLD) / 'maps/NorthSouthGate.blk').read_bytes())
            id66_gold = (ROOT / 'maps/johto_pilot/Route43Gate.gold.blk').read_bytes()
            self.assertEqual(id66_gold, (Path(GOLD) / 'maps/NorthSouthGate.blk').read_bytes())

    @unittest.skipUnless(GOLD, 'Gold root not available')
    def test_active_gatehouses_include_both_route43_gold_gates(self):
        result = audit_active_gatehouse_carpet_walkability(ROOT, Path(GOLD))
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result['errors'])
        self.assertEqual(13, result['gatehouses_checked'])
        self.assertEqual('PASS', next(r['status'] for r in result['results'] if r['stable_id'] == 65))
        self.assertEqual(218, result['asm_traced_moves'][65])
        self.assertEqual('PASS', next(r['status'] for r in result['results'] if r['stable_id'] == 66))
        self.assertEqual(218, result['asm_traced_moves'][66])

if __name__ == '__main__':
    unittest.main()
