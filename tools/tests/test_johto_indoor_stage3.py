"""TOOLS.003 regression tests: static evidence and fail-closed review."""
from pathlib import Path
from unittest.mock import patch
import json
import sys
import tempfile
import unittest
import os

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
from johto_indoor_common import ConversionError
from johto_indoor_collision_adapter import classify_gold, quadrant_evidence, compare_quadrants, check
from johto_indoor_tiles_converter import build_mapping
from johto_indoor_resource_budget import inspect
from johto_indoor_registration_generator import generate
from johto_indoor_pipeline import pipeline
from johto_indoor_manifest import verify_manifest

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))


class CollisionPureTests(unittest.TestCase):
    def test_four_quadrant_walkability_order(self):
        block = bytes([1,1,9,9,
                       1,1,9,9,
                       9,9,1,1,
                       9,9,1,1])
        self.assertEqual(quadrant_evidence(block, {1}),
                         ['PASSABLE','BLOCKED','BLOCKED','PASSABLE'])

    def test_mixed_evidence_cannot_pass(self):
        block = bytes([1,9,9,9,
                       1,1,9,9,
                       9,9,9,9,
                       9,9,9,9])
        got = quadrant_evidence(block, {1})
        self.assertEqual(got[0], 'MIXED')
        result = compare_quadrants(['FLOOR','WALL','WALL','WALL'],got)
        self.assertEqual(result[0]['comparison'],'MIXED_REVIEW')

    def test_wrong_floor_wall_is_explicit_mismatch(self):
        got = compare_quadrants(['FLOOR']*4, ['BLOCKED']*4)
        self.assertTrue(all(x['comparison']=='MISMATCH' for x in got))

    def test_doors_not_treated_as_floor(self):
        self.assertEqual(classify_gold('DOOR'),'SPECIAL')
        got = compare_quadrants(['DOOR']*4,['PASSABLE']*4)
        self.assertTrue(all(x['comparison']=='SPECIAL_REVIEW' for x in got))

    def test_reject_invalid_quadrant_count(self):
        with self.assertRaises(ConversionError):
            compare_quadrants(['FLOOR']*3, ['PASSABLE']*4)


class Stage3IntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise unittest.SkipTest('Gold source tree required')

    def test_collision_has_machine_readable_gaps(self):
        art,_ = build_mapping(ROOT,GOLD)
        result=check(ROOT,GOLD,art)
        self.assertFalse(result['auto_approve'])
        self.assertEqual(result['schema'],'johto-indoor-collision-v2')
        self.assertGreater(result['issue_counts']['NO_PIXEL_EXACT_RPP_CANDIDATE'],0)
        self.assertGreater(result['issue_counts']['GOLD_SPECIAL_NEEDS_RUNTIME_MAPPING'],0)

    def test_resource_budget_is_not_certified(self):
        art,_=build_mapping(ROOT,GOLD)
        report=inspect(ROOT,GOLD,art)
        self.assertEqual(report['gold']['unique_blocks'],13)
        self.assertEqual(report['gold']['distinct_tile_ids_referenced'],22)
        self.assertEqual(report['gold']['metatile_bytes_compact'],208)
        self.assertIsNone(report['capacity_checks']['vram_available_tiles'])
        self.assertFalse(report['import_allowed'])

    def test_registration_checks_structural_references(self):
        result=generate(ROOT)
        self.assertEqual(result['failed_checks'],[])
        self.assertEqual(result['status'],'PRESENT_REVIEW_DEPENDENCIES')
        self.assertGreater(len(result['structural_checks']),10)

    def test_broken_include_reported_not_assumed(self):
        from johto_indoor_registration_generator import read as original
        def broken_read(root, name):
            raw = original(root, name)
            if name=='main.asm':
                return raw.replace('INCLUDE "data/mapObjects/JohtoRoute31VioletGate.asm"',
                                   '; object include was removed')
            return raw
        with patch('johto_indoor_registration_generator.read',side_effect=broken_read):
            result=generate(ROOT)
        self.assertEqual(result['status'],'REGISTRATION_REQUIRED')
        self.assertIn('MAIN_OBJECT_INCLUDE',result['failed_checks'])

    def test_broken_layout_length_cannot_pass(self):
        from johto_indoor_registration_generator import Path as path_obj
        original_read_bytes = Path.read_bytes
        def fake_bytes(p):
            if p.name == 'JohtoRoute31VioletGate.blk':
                return b'\x00\x01'
            return original_read_bytes(p)
        with patch.object(path_obj,'read_bytes',fake_bytes):
            result=generate(ROOT)
        self.assertIn('MAP_LAYOUT_LENGTH',result['failed_checks'])

    def test_pipeline_fingerprint_includes_new_resource_report(self):
        with tempfile.TemporaryDirectory() as folder:
            out=Path(folder)/'output'
            result=pipeline(ROOT,GOLD,out)
            self.assertFalse(result['import_allowed'])
            self.assertIn('RESOURCE_BUDGET_UNVERIFIED',result['blockers'])
            path=out/'08_resource_budget.json'
            self.assertTrue(path.is_file())
            manifest=json.loads((out/'07_source_manifest.json').read_text())
            self.assertIn('08_resource_budget.json',manifest['generated_files'])
            self.assertTrue(verify_manifest(ROOT,GOLD,out)['valid'])
            path.write_text('{}')
            self.assertFalse(verify_manifest(ROOT,GOLD,out)['valid'])


if __name__=='__main__':
    unittest.main()
