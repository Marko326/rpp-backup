"""DEV-329 regressions for the Route29/46 vertical gate and all southern hops."""
from __future__ import annotations

import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / 'tools'
sys.path.insert(0, str(TOOLS))

from johto_vertical_gate_runtime_314 import audit as audit_vertical_gate, simulate as simulate_vertical_gate
from johto_warp_arrival_audit import audit as audit_warp_arrival
from johto_gatehouse_behavior_audit import audit_active_gatehouse_carpet_walkability
from johto_field_move_coverage_audit import audit as audit_field_moves, _landing_guard_has_route_table

GOLD = (Path(os.environ.get('JOHTO_GOLD_SOURCE') or os.environ['GOLD_SOURCE_ROOT'])
        if os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('GOLD_SOURCE_ROOT') else None)


class Route29Route46Gate329(unittest.TestCase):
    def test_route46_two_outdoor_carpet_lanes_can_switch_sideways_without_warp(self):
        sim = simulate_vertical_gate(ROOT)
        self.assertTrue(sim['before_thresholds'])
        self.assertTrue(sim['after_thresholds'])
        self.assertTrue(sim['route46_carpet_lane_change_not_collision_exit'])
        source = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        for row in (
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 7, 33',
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_LEFT, 8, 33',
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 8, 33, 3',
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_LEFT, 7, 33, 3',
        ):
            self.assertIn(row, source)

    def test_missing_route46_lane_switch_before_profile_fails_closed(self):
        relative = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / relative).read_text()
        broken = source.replace(
            '    db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 7, 33\n', '', 1)
        self.assertNotEqual(source, broken)
        report = audit_vertical_gate(ROOT, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any(row['check'] == 'profile_JohtoVerticalGateBeforeStepProfiles314' and row['status'] == 'FAIL'
                            for row in report['checks']))

    def test_route29_south_door_entry_is_exact_up_step_on(self):
        sim = simulate_vertical_gate(ROOT)
        self.assertTrue(sim['route29_door_entry_step_on'])
        source = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        self.assertIn('db JOHTO_ROUTE_29_LOCAL_ID, PLAYER_DIR_UP, 27, 2', source)
        self.assertIn('db JOHTO_ROUTE_29_LOCAL_ID, PLAYER_DIR_UP, 27, 1, 2', source)
        self.assertTrue(any(row[:3] == ('JOHTO_ROUTE_29_LOCAL_ID', '27', '1') and row[3] == 'D_DOWN'
                            for row in sim['arrival_rows']))

    def test_missing_route29_door_after_profile_fails_closed(self):
        relative = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / relative).read_text()
        broken = source.replace(
            '    db JOHTO_ROUTE_29_LOCAL_ID, PLAYER_DIR_UP, 27, 1, 2\n', '', 1)
        self.assertNotEqual(source, broken)
        report = audit_vertical_gate(ROOT, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any(row['check'] == 'profile_JohtoVerticalGateAfterStepProfiles314' and row['status'] == 'FAIL'
                            for row in report['checks']))
        self.assertTrue(any(row['check'] == 'route29_north_door_entry' and row['status'] == 'FAIL'
                            for row in report['checks']))

    def test_live_collision_approach_hook_is_mandatory(self):
        relative = 'home/overworld.asm'
        source = (ROOT / relative).read_text()
        needle = '    callab JohtoPilotGateDoorApproachAllowed\n'
        self.assertIn(needle, source)
        broken = source.replace(needle, '', 1)
        report = audit_vertical_gate(ROOT, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any(row['check'] == 'live_gate_approach_hook' and row['status'] == 'FAIL'
                            for row in report['checks']))

    def test_live_step_on_warp_hook_is_mandatory(self):
        relative = 'home/overworld.asm'
        source = (ROOT / relative).read_text()
        needle = '    callab JohtoPilotGateDoorWarpMatched\n'
        self.assertIn(needle, source)
        broken = source.replace(needle, '', 1)
        report = audit_vertical_gate(ROOT, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any(row['check'] == 'live_gate_step_on_warp_hook' and row['status'] == 'FAIL'
                            for row in report['checks']))

    def test_route46_lane_switch_must_remain_non_warp_result_three(self):
        relative = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / relative).read_text()
        broken = source.replace(
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 8, 33, 3',
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 8, 33, 1', 1)
        self.assertNotEqual(source, broken)
        report = audit_vertical_gate(ROOT, text_overrides={relative: broken})
        self.assertEqual('FAIL', report['status'])

    @unittest.skipUnless(GOLD, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT to MUS Gold')
    def test_all_seven_route29_46_gate_warps_match_gold(self):
        report = audit_warp_arrival(ROOT, GOLD)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])
        check = next(row for row in report['checks'] if row['check'] == 'route29_46_gate_exact_gold_warps')
        self.assertEqual('PASS', check['status'], check['detail'])

    @unittest.skipUnless(GOLD, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT to MUS Gold')
    def test_gatehouse_collision_inventory_includes_id74(self):
        report = audit_active_gatehouse_carpet_walkability(ROOT, GOLD)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])
        self.assertEqual((13, 38), (report['gatehouses_checked'], report['carpets_checked']))
        id74 = next(row for row in report['results'] if row['stable_id'] == 74)
        self.assertEqual(('PASS', 2), (id74['status'], id74['carpets']))
        self.assertEqual(218, report['asm_traced_moves'][74])

    @unittest.skipUnless(GOLD, 'set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT to MUS Gold')
    def test_every_gold_route45_route46_hop_direction_is_registered_and_guarded(self):
        report = audit_field_moves(ROOT, GOLD)
        self.assertEqual('PASS', report['status'], report['errors'])
        rows = {row['map']: row for row in report['rows']}
        self.assertEqual((83, 88, 'REGISTERED'),
                         (rows['Route45']['hop_cells'], rows['Route45']['safe_hop_directions'], rows['Route45']['ledge']))
        self.assertEqual((19, 20, 'REGISTERED'),
                         (rows['Route46']['hop_cells'], rows['Route46']['safe_hop_directions'], rows['Route46']['ledge']))
        ledges = (ROOT / 'engine/overworld/ledges.asm').read_text()
        self.assertTrue(_landing_guard_has_route_table(ledges, 'Route45'))
        self.assertTrue(_landing_guard_has_route_table(ledges, 'Route46'))
        start = ledges.index('JohtoSouthHopLandingGuard::')
        end = ledges.index('LoadHoppingShadowOAM:', start)
        guard = ledges[start:end]
        broken_guard = guard.replace('ld hl, JohtoRoute46GoldHops',
                                     'ld hl, JohtoRoute45GoldHops', 1)
        broken = ledges[:start] + broken_guard + ledges[end:]
        self.assertFalse(_landing_guard_has_route_table(broken, 'Route46'))


if __name__ == '__main__':
    unittest.main()
