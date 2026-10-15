"""R32-5.62.166: the Gold Route32 LADDER must remain walkable without wall leakage."""
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]

class Route32LadderCollisionTests(unittest.TestCase):
    def test_ladder_tile_is_walkable_but_wall_tile_stays_blocked(self):
        b = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        passable = (ROOT / 'gfx/tilesets/johto.tilecoll').read_bytes()
        self.assertEqual(b[6 * 16:7 * 16], bytes([0x5b]) * 16)
        self.assertIn(0x5b, passable[:-1])
        self.assertNotIn(7, passable[:-1])
        self.assertEqual(passable[-1], 0xff)
        self.assertEqual(b.count(0x5b), 16)
        for block_id in (15, 16, 17, 19, 23, 26, 27, 126, 127):
            self.assertIn(7, b[block_id * 16:(block_id + 1) * 16])
    def test_exact_gfx_and_cgb_palette_duplicate(self):
        im = Image.open(ROOT / 'gfx/tilesets/johto.png').convert('L')
        self.assertEqual(im.size, (128, 48))
        self.assertEqual(im.crop((88, 40, 96, 48)).tobytes(), im.crop((56, 0, 64, 8)).tobytes())
        palette = [v.strip() for l in (ROOT / 'color/tilesets/johto.asm').read_text().splitlines()
                   if 'tilepal' in l for v in l.strip().split(',', 1)[1].split(',')]
        self.assertEqual(palette[0x5b], palette[7])
        self.assertEqual(palette[7], 'RED')
    def test_gold_ladder_only_uses_metatile_06(self):
        b = (ROOT / 'maps/JohtoRoute32.blk').read_bytes()
        self.assertEqual(len(b), 450)
        self.assertEqual(b.count(6), 12)
        self.assertIn('db "REG-5.62.170@"', (ROOT / 'data/game_version.asm').read_text())

if __name__ == '__main__':
    unittest.main()
