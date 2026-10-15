"""Prove offline report provenance checks and detect tampered output."""
import sys
import tempfile
import unittest
import os
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0, str(TOOLS))

from johto_indoor_manifest import verify_manifest
from johto_indoor_pipeline import pipeline


class OfflineManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise unittest.SkipTest('Gold complete source required')

    def test_generated_report_has_current_sources_and_artifacts(self):
        with tempfile.TemporaryDirectory() as parent:
            out = Path(parent) / 'report'
            pipeline(ROOT, GOLD, out)
            manifest = out / '07_source_manifest.json'
            self.assertTrue(manifest.is_file())
            self.assertTrue(verify_manifest(ROOT, GOLD, out)['valid'])

    def test_changed_report_fails_verification_without_touching_game(self):
        with tempfile.TemporaryDirectory() as parent:
            out = Path(parent) / 'report'
            pipeline(ROOT, GOLD, out)
            summary = out / '00_summary.json'
            summary.write_text('{}\n', encoding='utf-8')
            result = verify_manifest(ROOT, GOLD, out)
            self.assertFalse(result['valid'])
            self.assertIn('generated_files: added/removed/modified', result['mismatches'])

    def test_extra_output_fails_verification(self):
        with tempfile.TemporaryDirectory() as parent:
            out = Path(parent) / 'report'
            pipeline(ROOT, GOLD, out)
            (out / 'unexpected.bin').write_bytes(b'x')
            self.assertFalse(verify_manifest(ROOT, GOLD, out)['valid'])


if __name__ == '__main__':
    unittest.main()
