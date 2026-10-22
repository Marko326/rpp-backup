"""Safe Gold entrance staging: deliberately does not enable any RPP door."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rpp_batch import audit_entrance_semantics, batch, read_metadata
from johto_rpp_validate import verify


class JohtoEntranceAuditTest(unittest.TestCase):
    def test_doors_and_caves_require_review_not_auto_passability(self):
        labels = [('WALL',) * 4 for _ in range(128)]
        labels[1] = ('DOOR', 'CAVE', 'WALL', 'FLOOR')
        found = audit_entrance_semantics(b'\x01', 1, 1, labels, 3)
        self.assertEqual(found[0]['by_label'], {'DOOR': 1, 'CAVE': 1})
        self.assertEqual(found[0]['gold_warp_count'], 3)
        self.assertEqual(len(found[0]['examples']), 2)
        self.assertEqual(audit_entrance_semantics(b'\x00', 1, 1, labels, 0), [])

    @classmethod
    def setUpClass(cls):
        if not (GOLD / 'data/tilesets/johto_collision.asm').exists():
            raise unittest.SkipTest('complete Gold source required')

    def test_route32_staged_entrances_remain_unimported(self):
        with tempfile.TemporaryDirectory() as tmp:
            stage = Path(tmp)
            batch(GOLD, ROOT, stage)
            report = verify(stage, GOLD, ROOT)
            self.assertNotEqual(report['status'], 'FAILED')
            manifest = json.loads((stage/'manifest.json').read_text())
            route = next(e for e in manifest['maps'] if e['name'] == 'Route32')
            review = [f for f in route['findings']
                      if f['code'] == 'entrance_requires_warp_and_engine_review']
            self.assertEqual(len(review), 1)
            self.assertEqual(review[0]['by_label'], {'DOOR': 1, 'CAVE': 2})
            self.assertEqual(review[0]['gold_warp_count'], 4)
            self.assertEqual(route['status'], 'review_required')
            objects = (ROOT/'data/mapObjects/JohtoRoute32.asm').read_text()
            self.assertIn('db $03 ; cave slot0 unchanged; Route32 west carpets are slots1/2', objects)
            self.assertIn('db 79, 6, 0, REGION_WARP_ESCAPE', objects)
            self.assertIn('db 2, 4, 2, REGION_WARP_ESCAPE', objects)
            self.assertIn('db 3, 4, 3, REGION_WARP_ESCAPE', objects)
            self.assertNotIn('db 73, 11,', objects)  # Gold Pokemon Center remains deferred
            # Tampering with the entrance review must fail independent audit.
            route['findings'].remove(review[0])
            (stage/'manifest.json').write_text(json.dumps(manifest))
            tampered = verify(stage, GOLD, ROOT)
            self.assertEqual(tampered['status'], 'FAILED')
            errors = next(e for e in tampered['maps'] if e['name'] == 'Route32')['issues']
            self.assertIn('entrance_review_manifest_missing_or_mismatched',
                          {e['code'] for e in errors})


if __name__ == '__main__':
    unittest.main()
