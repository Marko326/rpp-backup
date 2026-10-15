"""Source-only regression tests. No ROM compilation or mutation."""
import sys
import tempfile
import unittest
import os
from pathlib import Path

TOOLS=Path(__file__).resolve().parents[1]
ROOT=TOOLS.parent
sys.path.insert(0,str(TOOLS))
from johto_indoor_common import (ConversionError, safe_roots, rpp_warps, gold_warps,
                                 gold_dimensions,rpp_dimensions, warp_tile_ids)
from johto_native_warp_converter import analyze
from johto_bidirectional_warp_validator import validate
from johto_indoor_tiles_converter import build_mapping, stage_dedicated_gold_tileset
from johto_indoor_collision_adapter import check
from johto_indoor_registration_generator import generate
from johto_indoor_pipeline import pipeline

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))  # local test fixture; skip when Gold source not provided

class IndoorToolchainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise unittest.SkipTest('Gold source tree must be supplied for integration test')

    def test_route15_reference_has_four_edge_warps(self):
        records=rpp_warps(ROOT,'Route15Gate1F')
        self.assertEqual([(r['x'],r['y']) for r in records[:4]],[(0,4),(0,5),(7,4),(7,5)])

    def test_dimensions_and_coordinate_order(self):
        self.assertEqual(rpp_dimensions(ROOT,'JohtoRoute31VioletGate'),(5,4))
        self.assertEqual(gold_dimensions(GOLD,'Route31VioletGate'),(5,4))
        self.assertEqual([(q['x'],q['y']) for q in gold_warps(GOLD,'Route31VioletGate')],
                         [(0,4),(0,5),(9,4),(9,5)])

    def test_native_tile_40_walkable_not_auto_warp(self):
        plan=analyze(ROOT,GOLD)
        self.assertEqual(len(plan['outside_warps']),4)
        self.assertFalse(any(w['potential_standing_trigger'] for w in plan['outside_warps']))
        self.assertNotIn(0x40,warp_tile_ids(ROOT,'NewBarkWarpTileIDs'))
        self.assertTrue(plan['engine']['extra_warp_checks_johto_explicit'])

    def test_bidirectional_static_graph_is_not_gameplay_approval(self):
        result=validate(ROOT,analyze(ROOT,GOLD))
        self.assertEqual(result['graph_check'],'PASS')
        self.assertFalse(result['gameplay_accepted'])
        self.assertFalse(any(x['code']=='OUTDOOR_STANDING_TRIGGER_RISK' for x in result['findings']))

    def test_gold_art_is_not_assumed_compatible(self):
        report,staged=build_mapping(ROOT,GOLD)
        self.assertEqual(report['width'],5)
        self.assertEqual(report['height'],4)
        self.assertFalse(report['can_stage_pixel_exact_candidate'])
        self.assertIsNone(staged)

    def test_isolated_art_has_same_block_cells_as_gold(self):
        with tempfile.TemporaryDirectory() as path:
            result=stage_dedicated_gold_tileset(GOLD,Path(path))
            self.assertEqual(result['used_compacted_blocks'],13)
            self.assertEqual(len((Path(path)/result['layout']).read_bytes()),20)
            self.assertEqual(len((Path(path)/result['blockset']).read_bytes()),14*16)
            self.assertEqual(result['status'],'PIXEL_ASSET_CANDIDATE_ONLY')

    def test_collision_requires_explicit_review(self):
        artwork,_=build_mapping(ROOT,GOLD)
        result=check(ROOT,GOLD,artwork)
        self.assertFalse(result['auto_approve'])
        self.assertEqual(result['status'],'COLLISION_REVIEW_REQUIRED')

    def test_registration_references(self):
        out=generate(ROOT)
        self.assertTrue(out['components']['object_table'])
        self.assertTrue(out['components']['map_header'])
        self.assertIn('status',out)

    def test_safe_output_blocks_project_and_gold(self):
        with self.assertRaises(ConversionError):safe_roots(ROOT,GOLD,ROOT/'reports')
        with self.assertRaises(ConversionError):safe_roots(ROOT,GOLD,GOLD/'reports')

    def test_pipeline_generates_only_external_reports(self):
        with tempfile.TemporaryDirectory() as path:
            target=Path(path)/'audit'
            result=pipeline(ROOT,GOLD,target)
            self.assertFalse(result['import_allowed'])
            self.assertTrue((target/'REPORT_zh.md').is_file())
            self.assertTrue((target/'05_registration.json').is_file())
            self.assertFalse((target/'Route31VioletGate.pixel_candidate.blk').exists())
            self.assertTrue((target/'06_isolated_original_art.json').exists())
            with self.assertRaises(ConversionError): pipeline(ROOT,GOLD,target)

if __name__=='__main__':unittest.main()
