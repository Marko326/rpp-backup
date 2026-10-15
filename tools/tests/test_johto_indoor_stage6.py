"""TOOLS.006 offline release-gate negative and deterministic regression tests."""
import copy
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest
import os
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
ROOT = TOOLS.parent
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
from johto_indoor_common import ConversionError
from johto_indoor_release_audit import (DEFAULT_JOBS, compare_manifests,
    protected_fingerprint, release_audit, probe_tamper, run_tests)
from johto_indoor_batch import validate_jobs
from johto_indoor_manifest import verify_manifest
from johto_indoor_pipeline import pipeline


class Stage6Units(unittest.TestCase):
    def test_test_runner_uses_external_gold_and_rejects_skips(self):
        from types import SimpleNamespace
        with patch('johto_indoor_release_audit.subprocess.run') as runner:
            runner.return_value = SimpleNamespace(returncode=0, stdout='', stderr='Ran 112 tests in 6s\nOK (skipped=1)')
            bad = run_tests(ROOT, GOLD)
            self.assertFalse(bad['passed'])
            self.assertEqual(bad['skipped_count'], 1)
            self.assertEqual(runner.call_args.kwargs['env']['JOHTO_GOLD_SOURCE'], str(GOLD))
            runner.return_value = SimpleNamespace(returncode=0, stdout='', stderr='Ran 112 tests in 6s\nOK')
            good = run_tests(ROOT, GOLD)
            self.assertTrue(good['passed'])
            self.assertEqual(good['skipped_count'], 0)

    def test_manifest_compare_includes_source_and_output_hashes(self):
        good = {'configuration': {'source': 'A'}, 'sources': {'rpp': {'a': '1'}},
                'generated_files': {'report': '2'}}
        self.assertTrue(compare_manifests(good, copy.deepcopy(good)))
        for field, key in [('sources', 'rpp'), ('generated_files', 'report'),
                           ('configuration', 'source')]:
            bad = copy.deepcopy(good)
            bad[field][key] = 'changed'
            self.assertFalse(compare_manifests(good, bad))

    def test_two_reference_room_configs_are_explicit(self):
        self.assertEqual(len(validate_jobs({'schema': 'johto-indoor-batch-v1', 'jobs': DEFAULT_JOBS})), 2)
        self.assertNotEqual(DEFAULT_JOBS[0]['reference_room'], DEFAULT_JOBS[1]['reference_room'])
        self.assertEqual(len({job['gold_room'] for job in DEFAULT_JOBS}), 1)

    def test_reject_duplicate_and_unsafe_jobs(self):
        with self.assertRaises(ConversionError):
            validate_jobs({'schema': 'johto-indoor-batch-v1',
                           'jobs': [DEFAULT_JOBS[0], DEFAULT_JOBS[0]]})
        bad = dict(DEFAULT_JOBS[0], id='../game')
        with self.assertRaises(ConversionError):
            validate_jobs({'schema': 'johto-indoor-batch-v1', 'jobs': [bad]})

    def test_tests_skipped_cannot_create_commit_ready_state(self):
        if not GOLD.is_dir(): self.skipTest('Gold needed')
        with TemporaryDirectory() as folder:
            audit = release_audit(ROOT, GOLD, Path(folder)/'out', execute_tests=False,
                                  jobs=[DEFAULT_JOBS[0]])
            self.assertEqual(audit['status'], 'BLOCK_TOOL_COMMIT')
            self.assertFalse(audit['tests']['passed'])
            self.assertFalse(audit['game_sources_changed'])
            self.assertTrue(audit['jobs'][0]['tamper_detected'])
            self.assertTrue(audit['jobs'][0]['restored_manifest_valid'])
            self.assertTrue(audit['jobs'][0]['bit_reproducible_outputs'])
            self.assertFalse(audit['gameplay_integration_ready'])


@unittest.skipUnless(GOLD.is_dir(), 'Needs Gold source tree')
class Stage6RealSources(unittest.TestCase):
    def test_provenance_mutation_detection_and_recovery(self):
        with TemporaryDirectory() as folder:
            out=Path(folder)/'candidate'
            pipeline(ROOT, GOLD, out)
            self.assertTrue(verify_manifest(ROOT, GOLD, out)['valid'])
            self.assertTrue(probe_tamper(ROOT, GOLD, out))
            self.assertTrue(verify_manifest(ROOT, GOLD, out)['valid'])

    def test_guard_source_snapshot_stable_across_offline_run(self):
        rpp_before = protected_fingerprint(ROOT, rpp=True)
        gold_before = protected_fingerprint(GOLD, rpp=False)
        with TemporaryDirectory() as folder:
            pipeline(ROOT, GOLD, Path(folder)/'out')
        self.assertEqual(rpp_before, protected_fingerprint(ROOT, rpp=True))
        self.assertEqual(gold_before, protected_fingerprint(GOLD, rpp=False))

    def test_a_second_reference_profile_is_provenance_tracked(self):
        with TemporaryDirectory() as folder:
            out=Path(folder)/'candidate'
            pipeline(ROOT, GOLD, out, reference_room='Route11Gate1F')
            manifest=json.loads((out/'07_source_manifest.json').read_text(encoding='utf8'))
            self.assertIn('data/mapObjects/Route11Gate1F.asm',manifest['sources']['rpp'])
            self.assertTrue(verify_manifest(ROOT, GOLD, out)['valid'])
            summary=json.loads((out/'00_summary.json').read_text(encoding='utf8'))
            self.assertFalse(summary['import_allowed'])
            self.assertEqual(summary['reference_room'],'Route11Gate1F')

    def test_release_output_cannot_overlap_rpp(self):
        with self.assertRaises(ConversionError):
            release_audit(ROOT,GOLD,ROOT/'tools'/'out',execute_tests=False)


if __name__ == '__main__': unittest.main()
