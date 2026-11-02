"""DEV-316 Route43 return-carpet regression tests; source-only, no ROM build."""
import os
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_route43_return_audit_316 import audit

ROOT = Path(__file__).resolve().parents[2]
GOLD = os.environ.get('GOLD_SOURCE_ROOT')

@unittest.skipUnless(GOLD, 'set GOLD_SOURCE_ROOT to the uploaded Gold reference checkout')
class TestRoute43Return(unittest.TestCase):
    def test_actual_contract(self):
        result = audit(ROOT, Path(GOLD))
        self.assertEqual(result['errors'], [])
        self.assertEqual(result['route43_gold_water_cells'], 72)

    def test_mutation_bad_water_fails(self):
        filename = 'maps/johto_pilot/Route43.roles.bin'
        raw = bytearray((ROOT / filename).read_bytes())
        target = next(i for i, n in enumerate(raw) if n == 2)
        raw[target] = 0
        result = audit(ROOT, Path(GOLD), {filename: bytes(raw)})
        self.assertIn('Gold_WATER_all_72_exact', result['errors'])

    def test_mutation_north_warp_carpet_globally_opened_fails(self):
        filename = 'maps/johto_pilot/Route43.roles.bin'
        raw = bytearray((ROOT / filename).read_bytes())
        raw[31 * 20 + 17] = 0
        result = audit(ROOT, Path(GOLD), {filename: bytes(raw)})
        self.assertIn('Gold_north_carpet_pair_role_grid_fail_closed', result['errors'])

    def test_mutation_warp_removed_fails(self):
        filename = 'engine/johto_pilot_runtime.asm'
        raw = (ROOT / filename).read_text()
        needle = 'db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID'
        self.assertIn(needle, raw)
        result = audit(ROOT, Path(GOLD), {filename: raw.replace(needle, '; disabled')})
        self.assertIn('registered_bidirectional_warp_routes', result['errors'])

    def test_mutation_north_autostep_fails(self):
        filename = 'data/johto_vertical_gate_runtime_314.asm'
        raw = (ROOT / filename).read_text()
        result = audit(ROOT, Path(GOLD), {filename: raw.replace(
            'db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 4, 0, D_DOWN',
            'db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 4, 0, D_UP')})
        self.assertIn('arrival_only_gold_DOORS_not_carpets', result['errors'])

    def test_mutation_north_reentry_profile_removed_fails(self):
        filename = 'data/johto_vertical_gate_runtime_314.asm'
        raw = (ROOT / filename).read_text()
        needle = '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30\n'
        self.assertIn(needle, raw)
        result = audit(ROOT, Path(GOLD), {filename: raw.replace(needle, '', 1)})
        self.assertIn('north_ID66_carpet_reentry_and_lane_change', result['errors'])

    def test_mutation_lane_change_marked_as_collision_exit_fails(self):
        filename = 'data/johto_vertical_gate_runtime_314.asm'
        raw = (ROOT / filename).read_text()
        needle = 'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3 ; ID66 lateral lane change only'
        self.assertIn(needle, raw)
        result = audit(ROOT, Path(GOLD), {filename: raw.replace(needle, needle.replace(', 3 ;', ', 1 ;'), 1)})
        self.assertIn('north_ID66_lane_change_not_collision_exit', result['errors'])

    def test_mutation_route43_pre_step_bypass_fails(self):
        filename = 'data/johto_vertical_gate_runtime_314.asm'
        raw = (ROOT / filename).read_text()
        needle = '    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 1\n'
        self.assertIn(needle, raw)
        injected = raw.replace(needle, needle +
            '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 9, 51\n')
        result = audit(ROOT, Path(GOLD), {filename: injected})
        self.assertIn('south_ID65_carpet_keeps_collision_return', result['errors'])

if __name__ == '__main__':
    unittest.main()
