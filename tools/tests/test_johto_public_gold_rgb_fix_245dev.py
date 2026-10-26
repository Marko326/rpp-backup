"""Negative mutations protect Gold PC/MART RGB and Kanto isolation."""
from pathlib import Path
import os
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_public_gold_rgb_audit import verify

class JohtoPublicGoldRGBTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
        if not (cls.gold / 'gfx/tilesets/bg_tiles.pal').is_file():
            raise unittest.SkipTest('Gold source required')

    def check_fails_with(self, rel, old, new, fragment):
        text = (ROOT / rel).read_text()
        self.assertIn(old, text)
        changed = text.replace(old, new, 1)
        errors = verify(ROOT, self.gold, {rel: changed})
        self.assertTrue(any(fragment in e for e in errors), errors)

    def test_gold_shared_pc_mart_rgb(self):
        self.assertEqual(verify(ROOT, self.gold), [])

    def test_pc_green_old_palette_rejected(self):
        self.check_fails_with('color/data/map_palette_sets.asm',
          'db JOHTO_GATE_GOLD_GREEN ; Gold indoor GREEN, shared with Cherrygrove PC',
          'db INDOOR_GREEN', 'POKECENTER: GREEN')

    def test_mart_brown_old_palette_rejected(self):
        self.check_fails_with('color/data/map_palette_sets.asm',
          'db JOHTO_GATE_GOLD_BROWN ; Gold indoor BROWN, not legacy MART_FLOOR',
          'db MART_FLOOR', 'MART: BROWN')

    def test_mart_green_old_palette_rejected(self):
        self.check_fails_with('color/data/map_palette_sets.asm',
          'db JOHTO_GATE_GOLD_GREEN ; Gold indoor GREEN, shared with Cherrygrove MART',
          'db INDOOR_GREEN', 'MART: GREEN')

    def test_underlying_gold_rgb_corruption_rejected(self):
        self.check_fails_with('color/data/map_palettes.asm',
          '\tRGB 18,24,9', '\tRGB 30,28,26', 'Gold GREEN RGB differs')

    def test_kanto_green_color_must_not_change(self):
        self.check_fails_with('color/data/map_palettes.asm',
          '; 0x0b: INDOOR_GREEN\n\tRGB 30,28,26',
          '; 0x0b: INDOOR_GREEN\n\tRGB 18,24,9',
          'Kanto INDOOR_GREEN/BROWN')

    def test_reinstall_template_regression_rejected(self):
        self.check_fails_with('tools/install_olivine_public_runtime.py',
          "s += '; JOHTO_OLIVINE_MART\\n\\tdb INDOOR_GRAY\\n\\tdb INDOOR_RED\\n\\tdb JOHTO_GATE_GOLD_GREEN",
          "s += '; JOHTO_OLIVINE_MART\\n\\tdb INDOOR_GRAY\\n\\tdb INDOOR_RED\\n\\tdb INDOOR_GREEN",
          'MART: installer would revert')

if __name__ == '__main__':
    unittest.main()
