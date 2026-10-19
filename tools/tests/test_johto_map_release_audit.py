"""Ensure the consolidated gate rejects missing references and false-green suites."""
from pathlib import Path
import os
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_map_release_audit import (audit_project, inspect_test_output,
                                     verify_gold, REQUIRED_TEST_MODULES)  # noqa: E402


class MapReleaseGateTest(unittest.TestCase):
    def test_absent_gold_is_fatal_without_running_tests(self):
        with TemporaryDirectory() as tmp:
            self.assertTrue(verify_gold(Path(tmp)))
            report = audit_project(ROOT, Path(tmp))
            self.assertEqual(report['status'], 'FAIL')
            self.assertEqual(report['tests'], 0)

    def test_actual_connection_failure_blocks_release_before_unittests(self):
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold-source'))
        if not gold.is_dir():
            self.skipTest('Gold fixture not mounted')
        fake={'status':'FAIL','issues':[],
              'edges':[{'status':'FAIL','current':'JohtoRoute30',
                        'direction':'south','target':'JohtoCherrygroveCity',
                        'issues':['source_start incorrect']} ]}
        with patch('johto_map_release_audit.audit_all_active',return_value=fake):
            report=audit_project(ROOT,gold,run_tests=False)
        self.assertEqual(report['status'],'FAIL')
        self.assertTrue(any('CONNECTION:' in v and 'source_start incorrect' in v
                            for v in report['errors']),report['errors'])
        self.assertEqual(report['tests'],0)

    def test_skips_are_fatal_even_with_exit_zero(self):
        done = subprocess.CompletedProcess([], 0, '',
                                           'Ran 237 tests in 0.3s\n\nOK (skipped=28)')
        self.assertIn('Gold-backed or other tests were skipped', inspect_test_output(done))

    def test_no_tests_is_fatal_even_with_exit_zero(self):
        done = subprocess.CompletedProcess([], 0, '', 'OK')
        self.assertIn('test runner did not confirm a nonempty suite', inspect_test_output(done))

    def test_wrong_version_is_fatal(self):
        gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold-source'))
        if not gold.is_dir():
            self.skipTest('Gold fixture not mounted')
        report = audit_project(ROOT, gold, 'FAKE-0.0.0', run_tests=False)
        self.assertIn('wrong RPP baseline version', ' '.join(report['errors']))

    def test_missing_warp_module_is_fatal_even_when_other_tests_pass(self):
        completed = subprocess.CompletedProcess([], 0, '',
                    'test_example (test_johto_gate157_collision.Fixture.test_example) ... ok\n'
                    'Ran 1 test in 0.03s\n\nOK')
        errors = inspect_test_output(completed, enforce_manifest=True)
        self.assertTrue(any('required test modules not discovered:' in s and
                            'test_johto_warp_arrival175' in s for s in errors), errors)
        self.assertIn('test_johto_warp_arrival175', REQUIRED_TEST_MODULES)

    def test_missing_critical_negative_case_is_fatal(self):
        completed = subprocess.CompletedProcess([], 0, '',
                    'test_example (test_johto_warp_arrival175.Fixture.test_example) ... ok\n'
                    'Ran 1 test in 0.03s\n\nOK')
        errors = inspect_test_output(completed, enforce_manifest=True)
        self.assertTrue(any('required test IDs not executed:' in s for s in errors), errors)

    def test_successful_unittest_output(self):
        done = subprocess.CompletedProcess([], 0, '', 'Ran 10 tests in 1s\n\nOK')
        self.assertEqual(inspect_test_output(done), [])


if __name__ == '__main__':
    unittest.main()
