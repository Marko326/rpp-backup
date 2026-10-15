"""TOOLS.005: standalone proposal, strict evidence and batch jobs."""
import copy
import json
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
import os

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
ROOT = TOOLS.parent
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
from johto_indoor_common import ConversionError
from johto_indoor_batch import validate_jobs, run_batch
from johto_indoor_conversion_plan import create_plan, validate_plan
from johto_indoor_tiles_converter import build_mapping
from johto_indoor_collision_adapter import check as collision_check
from johto_indoor_resource_budget import inspect as budget_check
from johto_indoor_palette_vram_audit import inspect as palette_check
from johto_indoor_manifest import verify_manifest
from johto_indoor_pipeline import pipeline

JOB = {'id': 'gate31', 'gold_room': 'Route31VioletGate',
       'rpp_room': 'JohtoRoute31VioletGate',
       'outdoor': ['JohtoVioletCity', 'JohtoRoute31'],
       'gold_tileset': 'gate', 'rpp_tileset': 'gate',
       'reference_room': 'Route15Gate1F', 'strict_pairs': True}


class BatchInputTests(unittest.TestCase):
    def test_known_good_job(self):
        self.assertEqual(len(validate_jobs({'schema': 'johto-indoor-batch-v1', 'jobs': [JOB]})), 1)

    def test_bad_manifest_schema_rejected(self):
        for raw in ({'jobs': [JOB]}, {'schema': 'johto-indoor-batch-v1', 'jobs': []},
                    {'schema': 'johto-indoor-batch-v1', 'jobs': [JOB]*33}):
            with self.subTest(raw=str(raw)[:50]), self.assertRaises(ConversionError):
                validate_jobs(raw)

    def test_path_traversal_and_duplicate_rejected(self):
        for value in ('../unsafe', 'gate/../../bad', '.', '_leading'):
            broken = dict(JOB, id=value)
            with self.subTest(value=value), self.assertRaises(ConversionError):
                validate_jobs({'schema':'johto-indoor-batch-v1','jobs':[broken]})
        with self.assertRaises(ConversionError):
            validate_jobs({'schema':'johto-indoor-batch-v1','jobs':[JOB,dict(JOB)]})

    def test_invalid_outdoors_and_flag(self):
        for changed in ({'outdoor': ['JohtoRoute31','JohtoRoute31']},
                        {'outdoor': ['../escape']}, {'strict_pairs': 1},
                        {'extra': 'bad'}):
            broken = dict(JOB, **changed)
            with self.subTest(changed=changed), self.assertRaises(ConversionError):
                validate_jobs({'schema':'johto-indoor-batch-v1','jobs':[broken]})


@unittest.skipUnless(GOLD.is_dir(), 'Needs complete Gold source tree')
class RealRoomTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.art, _ = build_mapping(ROOT, GOLD)
        cls.collision = collision_check(ROOT, GOLD, cls.art)
        cls.budget = budget_check(ROOT, GOLD, cls.art)
        cls.palette = palette_check(ROOT, GOLD, cls.art, cls.budget)
        cls.isolated = {'source_tile_ids': list(range(cls.budget['gold']['distinct_tile_ids_referenced'])),
                        'source_block_ids': sorted(b['gold_block_id'] for b in cls.art['mapping'])}
        cls.plan = create_plan(cls.art, cls.collision, cls.palette, cls.isolated)

    def test_plan_emits_all_gold_blocks_no_auto_import(self):
        plan = self.plan
        self.assertEqual(len(plan['blocks']), 13)
        self.assertEqual(len(plan['tiles']), 22)
        self.assertEqual(plan['fixed_loader_tile_slots'], 96)
        self.assertFalse(plan['import_allowed'])
        self.assertTrue(validate_plan(plan, self.art, self.collision, self.palette, self.isolated)['structural_valid'])

    def test_bad_block_selection_rejected(self):
        plan = copy.deepcopy(self.plan)
        plan['blocks'][0]['selected_rpp_block_id'] = 999
        report = validate_plan(plan, self.art, self.collision, self.palette, self.isolated)
        self.assertFalse(report['structural_valid'])
        self.assertTrue(any(x.startswith('UNPROVEN_BLOCK_SELECTION') for x in report['errors']))

    def test_source_tampering_and_missing_entry_rejected(self):
        for key, value in [('gold_layout_sha256', '0'*64), ('import_allowed', True),
                           ('fixed_loader_tile_slots', 512)]:
            plan = copy.deepcopy(self.plan)
            plan[key] = value
            with self.subTest(key=key):
                self.assertFalse(validate_plan(plan, self.art, self.collision, self.palette, self.isolated)['structural_valid'])
        plan = copy.deepcopy(self.plan)
        plan['blocks'].pop()
        self.assertFalse(validate_plan(plan, self.art, self.collision, self.palette, self.isolated)['structural_valid'])

    def test_palette_unknown_or_misaligned_rejected(self):
        plan = copy.deepcopy(self.plan)
        plan['tiles'][0]['requested_rpp_palette'] = 'DO_NOT_EXIST'
        report = validate_plan(plan, self.art, self.collision, self.palette, self.isolated)
        self.assertIn('UNKNOWN_PALETTE:0', report['errors'])
        plan = copy.deepcopy(self.plan)
        plan['tiles'][0]['gold_tile_id'] = -1
        self.assertFalse(validate_plan(plan, self.art, self.collision, self.palette, self.isolated)['structural_valid'])

    def test_palette_selection_remains_unapproved(self):
        plan = copy.deepcopy(self.plan)
        plan['tiles'][0]['requested_rpp_palette'] = plan['reference_palette_symbols'][0]
        report = validate_plan(plan, self.art, self.collision, self.palette, self.isolated)
        self.assertTrue(report['structural_valid'])
        self.assertEqual(report['palette_selections_made'], 1)
        self.assertFalse(report['import_allowed'])

    def test_batch_pipeline_all_reports_are_only_offline(self):
        with TemporaryDirectory() as temp:
            out = Path(temp)/'audit'
            data = {'schema':'johto-indoor-batch-v1', 'jobs':[JOB]}
            result = run_batch(ROOT, GOLD, out, data)
            self.assertFalse(result['import_allowed'])
            self.assertTrue((out/'gate31/10_conversion_plan.json').is_file())
            self.assertTrue((out/'gate31/11_conversion_plan_validation.json').is_file())
            self.assertTrue(verify_manifest(ROOT, GOLD, out/'gate31')['valid'])
            (out/'gate31/10_conversion_plan.json').write_text('{}', encoding='utf8')
            self.assertFalse(verify_manifest(ROOT, GOLD, out/'gate31')['valid'])

    def test_more_than_one_isolated_job(self):
        with TemporaryDirectory() as temp:
            out=Path(temp)/'audits'
            manifest={'schema':'johto-indoor-batch-v1', 'jobs':[JOB,dict(JOB,id='gate31_check')]}
            result=run_batch(ROOT,GOLD,out,manifest)
            self.assertEqual(len(result['jobs']), 2)
            for job in ('gate31','gate31_check'):
                self.assertTrue((out/job/'07_source_manifest.json').exists())
            self.assertFalse(result['gameplay_tested'])


if __name__ == '__main__':
    unittest.main()
