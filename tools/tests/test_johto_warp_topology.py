"""Negative cases: a graph that points to the right *map* can still be wrong."""
import copy
import sys
import unittest
import os
from pathlib import Path
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))

import johto_bidirectional_warp_validator as graph_module
from johto_indoor_common import ConversionError, rpp_warps
from johto_native_warp_converter import analyze
from johto_warp_reference_profiles import compare, edge_of, profile

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))


class WarpTopologyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise unittest.SkipTest('Need both complete source trees')

    def test_route15_and_gold_gate_have_same_shape_not_same_behavior(self):
        ref = profile(ROOT, 'Route15Gate1F')
        target = profile(ROOT, 'JohtoRoute31VioletGate')
        summary = compare(ref, target)
        self.assertEqual(summary['status'], 'GEOMETRY_MATCH_ONLY')
        self.assertFalse(summary['runtime_equivalent'])
        self.assertEqual(summary['target_edges'], [('EAST', 2), ('WEST', 2)])

    def test_other_native_door_style_is_not_forced_into_gate_geometry(self):
        house = profile(ROOT, 'RedsHouse1F')
        gate = profile(ROOT, 'JohtoRoute31VioletGate')
        self.assertEqual(compare(house, gate)['status'], 'REVIEW_DIFFERENT_DOOR_GEOMETRY')
        plan = analyze(ROOT, GOLD, reference_room='RedsHouse1F')
        self.assertTrue(any('边缘几何不同' in item for item in plan['warnings']))

    def test_edge_coordinates_are_16x16_tiles(self):
        self.assertEqual(edge_of({'x': 9, 'y': 4}, 5, 4), 'EAST')
        self.assertEqual(edge_of({'x': 0, 'y': 7}, 5, 4), 'WEST+SOUTH')
        with self.assertRaises(ConversionError):
            edge_of({'x': 10, 'y': 4}, 5, 4)

    def test_current_exact_two_way_indices_pass(self):
        plan = analyze(ROOT, GOLD)
        report = graph_module.validate(ROOT, plan)
        self.assertTrue(report['strict_pair_index_check'])
        self.assertEqual(report['graph_check'], 'PASS')
        self.assertFalse(report['gameplay_accepted'])

    @staticmethod
    def swapped_outside():
        original = graph_module.rpp_warps

        def load(root, name):
            rows = copy.deepcopy(original(root, name))
            if name == 'JohtoVioletCity':
                rows[0]['dest_id'], rows[1]['dest_id'] = rows[1]['dest_id'], rows[0]['dest_id']
            return rows

        return load

    def test_swapped_doors_must_fail_not_silently_pass(self):
        plan = analyze(ROOT, GOLD)
        with patch.object(graph_module, 'rpp_warps', side_effect=self.swapped_outside()):
            report = graph_module.validate(ROOT, plan)
        self.assertEqual(report['graph_check'], 'FAIL')
        self.assertIn('REVERSE_INDEX_MISMATCH', {f['code'] for f in report['findings']})
        self.assertFalse(report['gameplay_accepted'])

    def test_shared_landing_mode_does_not_claim_gameplay(self):
        plan = analyze(ROOT, GOLD)
        with patch.object(graph_module, 'rpp_warps', side_effect=self.swapped_outside()):
            report = graph_module.validate(ROOT, plan, strict_pairs=False)
        self.assertEqual(report['graph_check'], 'PASS')
        self.assertFalse(report['strict_pair_index_check'])
        self.assertFalse(report['gameplay_accepted'])

    def test_unreachable_indoor_return_is_reported(self):
        plan = analyze(ROOT, GOLD)
        original = graph_module.rpp_warps

        def duplicate_landing(root, name):
            rows = copy.deepcopy(original(root, name))
            if name == 'JohtoVioletCity':
                rows[1]['dest_id'] = rows[0]['dest_id']
            return rows

        with patch.object(graph_module, 'rpp_warps', side_effect=duplicate_landing):
            result = graph_module.validate(ROOT, plan)
        self.assertEqual(result['graph_check'], 'FAIL')
        self.assertIn('UNREACHABLE_RETURN_ENTRANCE',
                      {f['code'] for f in result['findings']})


    def test_unscoped_destination_is_partial_not_false_pass(self):
        plan = analyze(ROOT, GOLD)
        original = graph_module.rpp_warps

        def outside_not_in_scope(root, name):
            rows = copy.deepcopy(original(root, name))
            if name == 'JohtoVioletCity':
                rows.append({'id': 2, 'x': 4, 'y': 4,
                             'dest_map': 'UNLOADED_ROUTE', 'dest_id': 0})
            return rows

        with patch.object(graph_module, 'rpp_warps', side_effect=outside_not_in_scope):
            result = graph_module.validate(ROOT, plan)
        self.assertEqual(result['graph_check'], 'PARTIAL')
        self.assertIn('UNRESOLVED_TARGET_MAP', {f['code'] for f in result['findings']})
        self.assertFalse(result['gameplay_accepted'])

    def test_out_of_bounds_reference_rejected(self):
        with patch('johto_warp_reference_profiles.rpp_warps',
                   return_value=[{'id': 0, 'x': 1000, 'y': 2,
                                  'dest_map': 'NONE', 'dest_id': 0}]):
            with self.assertRaises(ConversionError):
                profile(ROOT, 'Route15Gate1F')


if __name__ == '__main__':
    unittest.main()
