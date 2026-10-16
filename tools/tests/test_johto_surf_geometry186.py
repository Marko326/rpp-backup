"""Gold WATER is not safe to treat as a single RPP water tile ID."""
import os
from pathlib import Path
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_geometry_audit import inspect  # noqa: E402


class JohtoSurfGeometry186(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold-source'))
        if not (cls.gold / 'maps/UnionCave1F.blk').exists():
            raise AssertionError('complete Gold sources required for Surf geometry contract')

    def setUp(self):
        tmp = TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.rpp = Path(tmp.name) / 'rpp'
        self.gold_copy = Path(tmp.name) / 'gold'
        for relative in ('maps/JohtoUnionCave1F.blk',
                         'gfx/blocksets/johto_union_cave.bst',
                         'gfx/tilesets/johto_union_cave.tilecoll'):
            target = self.rpp / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)
        for relative in ('maps/UnionCave1F.blk',
                         'data/tilesets/cave_collision.asm'):
            target = self.gold_copy / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(self.gold / relative, target)

    def test_real_gold_water_geometry_and_wall_aliases(self):
        actual = inspect(self.rpp, self.gold_copy)
        self.assertEqual(actual['errors'], [])
        self.assertEqual(actual['water_quadrants'], 64)
        self.assertEqual(actual['water_tiles'], ['$03', '$08', '$0A', '$0C', '$0D', '$14'])
        self.assertEqual(actual['also_used_by_walls'], ['$03', '$08', '$0A', '$0C', '$0D'])
        self.assertEqual(len(actual['water_cells']), 64)

    def test_relabelled_gold_water_is_detected(self):
        target = self.gold_copy / 'data/tilesets/cave_collision.asm'
        text = target.read_text()
        self.assertIn('tilecoll WATER, WATER, WATER, WATER ; 25', text)
        target.write_text(text.replace('tilecoll WATER, WATER, WATER, WATER ; 25',
                                       'tilecoll WALL, WALL, WALL, WALL ; 25', 1))
        self.assertTrue(inspect(self.rpp, self.gold_copy)['errors'])

    def test_accidentally_walkable_water_is_detected(self):
        target = self.rpp / 'gfx/tilesets/johto_union_cave.tilecoll'
        data = target.read_bytes()
        target.write_bytes(data[:-1] + bytes((0x14, 0xff)))
        self.assertIn('walkable', ' '.join(inspect(self.rpp, self.gold_copy)['errors']))

    def test_replacing_water_with_wall_tile_is_detected(self):
        target = self.rpp / 'gfx/blocksets/johto_union_cave.bst'
        data = bytearray(target.read_bytes())
        # Block $16 is the translated Gold $25 all-water block.
        self.assertEqual(data[22 * 16], 0x14)
        data[22 * 16] = 0x06
        target.write_bytes(data)
        self.assertTrue(inspect(self.rpp, self.gold_copy)['errors'])


if __name__ == '__main__':
    unittest.main()
