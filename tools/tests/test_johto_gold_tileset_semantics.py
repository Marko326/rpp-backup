from pathlib import Path
from unittest.mock import patch
import sys, tempfile, unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import johto_gold_tileset_semantics as sem


class GoldTilesetSemanticResolverTests(unittest.TestCase):
    def test_dark_cave_aliases_cave_meta_and_collision(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root/'gfx').mkdir()
            (root/'gfx/tilesets.asm').write_text(
                'TilesetCaveMeta::\nTilesetDarkCaveMeta::\n'
                'INCBIN "data/tilesets/cave_metatiles.bin"\n'
                'TilesetCaveColl::\nTilesetDarkCaveColl::\n'
                'INCLUDE "data/tilesets/cave_collision.asm"\n', encoding='utf-8')
            (root/'data/tilesets').mkdir(parents=True)
            (root/'data/tilesets/cave_collision.asm').write_text(
                'tilecoll FLOOR, FLOOR, FLOOR, FLOOR\n', encoding='utf-8')
            with patch.object(sem, 'resolve_gold_root', return_value=root):
                got = sem.resolve_tileset_resources(root, 'TILESET_DARK_CAVE')
                self.assertEqual('data/tilesets/cave_metatiles.bin', got['metatiles'])
                self.assertEqual('data/tilesets/cave_collision.asm', got['collision'])
                self.assertEqual([('FLOOR','FLOOR','FLOOR','FLOOR')],
                                 sem.collision_rows(root, 'TILESET_DARK_CAVE'))

    def test_missing_label_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root/'gfx').mkdir()
            (root/'gfx/tilesets.asm').write_text('', encoding='utf-8')
            with patch.object(sem, 'resolve_gold_root', return_value=root):
                with self.assertRaises(ValueError):
                    sem.resolve_tileset_resources(root, 'TILESET_DARK_CAVE')

if __name__ == '__main__':
    unittest.main()
