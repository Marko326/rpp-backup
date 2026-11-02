"""DEV-312: future Route43 gatehouses must reuse the existing gate backend."""
from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))

from johto_gatehouse_onboarding_312 import PROFILE_PATH, audit
from johto_gatehouse_step_trace_308 import (
    simulate_legacy_gate_dispatch, simulate_legacy_gate_passability,
)

GOLD = (Path(os.environ.get('JOHTO_GOLD_SOURCE') or os.environ['GOLD_SOURCE_ROOT'])
        if os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('GOLD_SOURCE_ROOT') else None)


@unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT')
@unittest.skip('Historical DEV-312 snapshot: ID66 was planned-only then; REF-317 activates it. Current ID65/ID66 behavior is covered by DEV-320 and active gatehouse audits.')
class FutureGatehouseOnboarding312(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gateway = (ROOT / 'engine/johto_land_collision_gateway_272.asm').read_text(encoding='utf-8')
        cls.home = (ROOT / 'home/overworld.asm').read_text(encoding='utf-8')
        cls.passable = (ROOT / 'gfx/tilesets/gate.tilecoll').read_bytes()
        cls.profile_text = (ROOT / PROFILE_PATH).read_text(encoding='utf-8')

    def run_audit(self, **overrides):
        return audit(ROOT, GOLD, text_overrides=overrides)

    def test_both_route43_gates_use_existing_vertical_gate_runtime(self):
        result = self.run_audit()
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result['errors'])
        self.assertEqual({65: 218, 66: 218},
                         {int(k): v for k, v in result['trace_moves'].items()})
        self.assertEqual('ID65 south-only active; Route43 and ID66 fail-closed', result['activation'])

    def test_future_stable_ids_take_the_shared_legacy_fallback(self):
        for stable_id in (65, 66):
            with self.subTest(stable_id=stable_id):
                self.assertEqual(2, simulate_legacy_gate_dispatch(
                    self.gateway, constants=__import__('johto_gatehouse_behavior_audit')._constants(ROOT),
                    gate_id=stable_id))
                self.assertFalse(simulate_legacy_gate_passability(
                    self.home, gate_id=stable_id, tile_id=0x02,
                    passable_tiles=self.passable))
                self.assertTrue(simulate_legacy_gate_passability(
                    self.home, gate_id=stable_id, tile_id=0x00,
                    passable_tiles=self.passable))

    def test_tool_only_release_does_not_falsely_bump_rom_version(self):
        version = (ROOT / 'data/game_version.asm').read_text(encoding='utf-8')
        self.assertIn('db "REF-312@"', version)
        self.assertNotIn('db "REF-310@"', version)

    def test_wrong_collision_strategy_fails_closed(self):
        data = json.loads(self.profile_text)
        data['future_gatehouses'][0]['collision_strategy'] = 'south_gold_role_grid'
        result = self.run_audit(**{PROFILE_PATH: json.dumps(data)})
        self.assertEqual('FAIL', result['status'])
        self.assertTrue(any('future_65_Route43MahoganyGate_profile_policy' in x
                            for x in result['errors']))

    def test_wrong_carpet_direction_fails_closed(self):
        data = json.loads(self.profile_text)
        data['future_gatehouses'][1]['warp_events'][2]['direction'] = 'UP'
        result = self.run_audit(**{PROFILE_PATH: json.dumps(data)})
        self.assertEqual('FAIL', result['status'])
        self.assertTrue(any('future_66_Route43Gate_warp_contracts' in x
                            for x in result['errors']))

    def test_accidental_runtime_activation_fails_closed(self):
        assets = (ROOT / 'data/johto_pilot_runtime_assets.asm').read_text(encoding='utf-8')
        broken = assets + '\n    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, JOHTO_GATE, 5, 4\n'
        result = self.run_audit(**{'data/johto_pilot_runtime_assets.asm': broken})
        self.assertEqual('FAIL', result['status'])
        self.assertTrue(any('runtime_assets_65_exact_activation' in x
                            for x in result['errors']))

    def test_event_state_machine_must_remain_map_local_and_explicit(self):
        data = json.loads(self.profile_text)
        data['future_gatehouses'][1]['event_profile']['scene_scripts'] = 0
        result = self.run_audit(**{PROFILE_PATH: json.dumps(data)})
        self.assertEqual('FAIL', result['status'])
        self.assertTrue(any('future_66_Route43Gate_event_profile' in x
                            for x in result['errors']))


if __name__ == '__main__':
    unittest.main()
