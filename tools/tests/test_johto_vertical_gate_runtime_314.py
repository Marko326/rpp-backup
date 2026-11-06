"""Vertical gate regression coverage for shared ID65/66/74 profiles and Route43/Route46 carpet movement."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_vertical_gate_runtime_314 import audit, simulate


class VerticalGateRuntime314(unittest.TestCase):
    def test_profile_runtime_is_shared_and_complete(self):
        report = audit(ROOT)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])
        self.assertGreaterEqual(len(report['checks']), 15)

    def test_before_and_after_thresholds_match_id65_and_id66_gold_positions(self):
        result = simulate(ROOT)
        self.assertTrue(result['before_thresholds'])
        self.assertTrue(result['after_thresholds'])
        self.assertEqual(128, result['town_arrival_step'])
        self.assertTrue(result['gate_carpet_no_autostep'])
        self.assertTrue(result['id66_carpet_reentry_and_lane_change'])
        self.assertTrue(result['id66_lane_change_not_collision_exit'])
        self.assertTrue(result['route46_carpet_lane_change_not_collision_exit'])
        self.assertTrue(result['route29_door_entry_step_on'])
        self.assertTrue(result['route46_cave_door'])

    def test_closed_edges_are_fail_closed_but_interior_and_town_are_not(self):
        result = simulate(ROOT)
        self.assertEqual({'up': 1, 'down': 1, 'left': 1, 'right': 1,
                          'interior': 0, 'town_not_profiled': 0,
                          'id66_up': 1, 'id66_down': 1, 'id66_left': 1,
                          'id66_right': 1, 'id66_interior': 0,
                          'id74_up': 1, 'id74_down': 1, 'id74_left': 1, 'id74_right': 1,
                          'id74_interior': 0},
                         result['closed_edge_cases'])

    def test_id66_is_active_in_the_shared_profiles(self):
        runtime = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        self.assertIn('JOHTO_ROUTE_43_GATE_LOCAL_ID', runtime)
        self.assertIn('db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 6', runtime)
        self.assertIn('db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_UP, 4, 1', runtime)
        self.assertIn('JohtoRoute43GateRuntimeHeader', (ROOT / 'data/johto_header_descriptors.asm').read_text())

    def test_route46_external_pair_has_two_way_lane_switch_and_route29_has_step_on_door(self):
        result = simulate(ROOT)
        self.assertTrue(result['route46_carpet_lane_change_not_collision_exit'])
        self.assertTrue(result['route29_door_entry_step_on'])
        runtime = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        self.assertIn('db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 7, 33', runtime)
        self.assertIn('db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_LEFT, 8, 33', runtime)
        self.assertIn('db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_RIGHT, 8, 33, 3', runtime)
        self.assertIn('db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_LEFT, 7, 33, 3', runtime)
        self.assertIn('db JOHTO_ROUTE_29_LOCAL_ID, PLAYER_DIR_UP, 27, 2', runtime)
        self.assertIn('db JOHTO_ROUTE_29_LOCAL_ID, PLAYER_DIR_UP, 27, 1, 2', runtime)

    def test_route43_north_carpet_is_down_warp_with_exact_lane_exceptions(self):
        roles = (ROOT / 'maps/johto_pilot/Route43.roles.bin').read_bytes()
        self.assertEqual(1, roles[31 * 20 + 17])
        self.assertEqual(1, roles[31 * 20 + 18])
        runtime = (ROOT / 'data/johto_vertical_gate_runtime_314.asm').read_text()
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 31, 1', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 31, 1', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 30', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 17, 31', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 18, 31', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3', runtime)
        self.assertIn('db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3', runtime)


    def test_id66_north_carpet_reentry_and_lane_change_are_required(self):
        result = simulate(ROOT)
        self.assertTrue(result['id66_carpet_reentry_and_lane_change'])
        self.assertTrue(result['id66_lane_change_not_collision_exit'])
        self.assertTrue(result['route46_carpet_lane_change_not_collision_exit'])
        self.assertTrue(result['route29_door_entry_step_on'])

    def test_missing_north_reentry_profile_is_rejected(self):
        rel = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / rel).read_text()
        broken = source.replace('    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30\n', '', 1)
        report = audit(ROOT, text_overrides={rel: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('profile_JohtoVerticalGateBeforeStepProfiles314' in e for e in report['errors']))

    def test_lateral_lane_change_must_not_become_collision_warp(self):
        rel = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / rel).read_text()
        broken = source.replace('PLAYER_DIR_RIGHT, 18, 31, 3', 'PLAYER_DIR_RIGHT, 18, 31, 1', 1)
        report = audit(ROOT, text_overrides={rel: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('profile_JohtoVerticalGateAfterStepProfiles314' in e or
                            'route43_north_ID66_lane_change_not_collision_exit' in e
                            for e in report['errors']))

    def test_wrong_before_coordinate_is_rejected(self):
        rel = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / rel).read_text()
        broken = source.replace('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 6',
                                'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 3, 6', 1)
        report = audit(ROOT, text_overrides={rel: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('profile_JohtoVerticalGateBeforeStepProfiles314' in e for e in report['errors']))

    def test_wrong_after_result_is_rejected(self):
        rel = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / rel).read_text()
        broken = source.replace('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 7, 1',
                                'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 7, 2', 1)
        report = audit(ROOT, text_overrides={rel: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('profile_JohtoVerticalGateAfterStepProfiles314' in e for e in report['errors']))


    def test_route43_down_carpet_must_not_bypass_collision(self):
        rel = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / rel).read_text()
        needle = '    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 1\n'
        self.assertIn(needle, source)
        broken = source.replace(needle, needle +
            '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 9, 51\n')
        report = audit(ROOT, text_overrides={rel: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('route43_south_ID65_carpet_not_pre_step_bypassed' in e
                            for e in report['errors']))

    def test_wrong_gate_bounds_are_rejected(self):
        rel = 'data/johto_vertical_gate_runtime_314.asm'
        source = (ROOT / rel).read_text()
        broken = source.replace('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 10, 8',
                                'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 9, 8', 1)
        report = audit(ROOT, text_overrides={rel: broken})
        self.assertEqual('FAIL', report['status'])
        self.assertTrue(any('profile_JohtoVerticalGateBoundsProfiles314' in e for e in report['errors']))


if __name__ == '__main__':
    unittest.main()
