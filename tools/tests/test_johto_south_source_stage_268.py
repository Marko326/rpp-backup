"""MAP-268 south batch: immutable historical source snapshot vs live maps.

The original source_manifest describes a previously staged-only candidate.
The current 21-map runtime must match these immutable Gold source blocks.
This test does not replace ROM linking or gameplay validation.
"""
import hashlib
import json
import unittest
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_ilex_217_geometry import expected_runtime as expected_ilex_runtime

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'docs/JOHTO_BATCH_SOUTH_268/source_manifest.json'


class SouthSourceStage(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))

    def test_source_only_and_stable_ids_reserved(self):
        self.assertEqual(self.manifest['state'], 'SOURCE_ONLY_NOT_PLAYABLE')
        self.assertEqual(len(self.manifest['maps']), 6)
        self.assertTrue(all(not row['runtime_enabled'] for row in self.manifest['maps']))
        table = (ROOT / 'constants/region_map_constants.asm').read_text()
        self.assertIn('NUM_JOHTO_ACTIVE_MAPS EQU 21', table)
        slots = (ROOT / 'data/johto_stable_id_slots.asm').read_text()
        # Existing IDs 10..15 are now live; source .gold.blk still remains an immutable comparison oracle.
        self.assertIn('13, 14, 15, 16, 17, 18, 19, 20', slots)

    def test_gold_source_hashes_and_sizes(self):
        names = set()
        for entry in self.manifest['maps']:
            with self.subTest(map=entry['name']):
                names.add(entry['name'])
                data = (ROOT/'maps/johto_pilot'/f"{entry['name']}.gold.blk").read_bytes()
                self.assertEqual(len(data), entry['width'] * entry['height'])
                self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'])
                expected=(expected_ilex_runtime(data) if entry['name']=='IlexForest' else data)
                self.assertEqual(expected,(ROOT/'maps/johto_pilot'/f"{entry['name']}.runtime.blk").read_bytes())
        self.assertEqual(len(names), 6)

    def test_png_only_and_separate_gold_tilesets(self):
        from PIL import Image
        for name in ('johto_ilex_forest', 'johto_south_gold_gate'):
            with self.subTest(tileset=name):
                p = ROOT/'gfx/tilesets'/f'{name}.png'
                self.assertTrue(p.is_file())
                with Image.open(p) as image:
                    self.assertEqual(image.size, (128, 48))
                self.assertFalse(p.with_suffix('.2bpp').exists())
        self.assertNotEqual((ROOT/'gfx/tilesets/forest.png').read_bytes(),
                            (ROOT/'gfx/tilesets/johto_ilex_forest.png').read_bytes())
        self.assertGreaterEqual((ROOT/'gfx/blocksets/johto_ilex_forest.bst').stat().st_size, 640)
        self.assertEqual((ROOT/'gfx/blocksets/johto_south_gold_gate.bst').stat().st_size, 1024)

    def test_no_new_runtime_registration(self):
        assets=(ROOT/'data/johto_pilot_runtime_assets.asm').read_text()
        self.assertIn('JOHTO_AZALEA_TOWN_LOCAL_ID',assets)
        self.assertIn('JOHTO_ILEX_FOREST_LOCAL_ID',assets)
        self.assertIn('JOHTO_ROUTE_34_LOCAL_ID',assets)
        self.assertIn('JOHTO_GOLDENROD_CITY_LOCAL_ID',assets)

if __name__ == '__main__':
    unittest.main()
