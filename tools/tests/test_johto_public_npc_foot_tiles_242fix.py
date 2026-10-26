"""Regression: RPP NPC collision reads row-major, not quadrant-packed foot tiles.

Source-level checks only. No compiled ROM or mobile movement is implied.
"""
from pathlib import Path
import json
import sys
import unittest

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_olivine_public_runtime import ROOMS, _blocked, _npc_foot_index


class PublicNPCFootTiles(unittest.TestCase):
    def test_foot_indices_match_draw_tile_block_rows(self):
        self.assertEqual([_npc_foot_index(x, y) for y in range(2) for x in range(2)],
                         [4, 6, 12, 14])
        # This is the actual four-8x8-tiles-per-row implementation, not a
        # Gold quadrant table. A refactor cannot silently flip the layout.
        renderer = (ROOT / 'home/overworld.asm').read_text()
        body = renderer.split('DrawTileBlock::', 1)[1].split('ret\n', 1)[0]
        self.assertIn('ld c,$04 ; 4 loop iterations', body)
        self.assertIn('ld bc,$0015', body)

    def test_generated_npc_foot_ids_agree_with_gold_mask_everywhere(self):
        for room in ROOMS.values():
            name, tileset = room['map'], room['tileset']
            blocks = (ROOT / 'maps' / f'{name}.blk').read_bytes()
            bst = (ROOT / 'gfx/blocksets' / f'{tileset}.bst').read_bytes()
            mask = (ROOT / 'maps' / f'{name}.blocked_mask.bin').read_bytes()
            allowed = (ROOT / 'gfx/tilesets' / f'{tileset}.tilecoll').read_bytes()
            self.assertEqual(allowed[-1], 0xff)
            self.assertEqual(len(allowed[:-1]), len(set(allowed[:-1])))
            source = ROOT / 'tools/olivine_public_candidates' / next(
                key for key, spec in ROOMS.items() if spec['map'] == name)
            w = json.loads((source / 'provenance.json').read_text())['dimensions_blocks'][0]
            h = len(blocks) // w
            for y in range(2 * h):
                for x in range(2 * w):
                    bid = blocks[(y // 2) * w + (x // 2)]
                    foot = bst[bid * 16 + _npc_foot_index(x, y)]
                    with self.subTest(room=name, x=x, y=y, tile=f'${foot:02x}'):
                        self.assertEqual(foot in allowed[:-1],
                                         not _blocked(mask, w * 2, x, y))

    def test_affected_npcs_have_contiguous_passable_routes(self):
        # Both stores use the same Mart blockset; Cherrygrove's source object
        # is at x7,y6. Check two further steps, not just the first step.
        cases = (
            ('JohtoOlivinePokecenter1F', 'johto_olivine_pokecenter', 5,
             [(x, 4) for x in (6, 7, 8, 9)]),
            ('JohtoOlivineMart', 'johto_olivine_mart', 6,
             [(x, 2) for x in (4, 5, 6, 7, 8)]),
            ('JohtoOlivineMart', 'johto_olivine_mart', 6,
             [(x, 6) for x in (5, 6, 7, 8, 9)]),
            ('JohtoOlivineCafe', 'johto_olivine_cafe', 4,
             [(1, y) for y in (4, 5, 6)]),
        )
        for name, tileset, w, points in cases:
            blk = (ROOT / 'maps' / f'{name}.blk').read_bytes()
            bst = (ROOT / 'gfx/blocksets' / f'{tileset}.bst').read_bytes()
            allowed = set((ROOT / 'gfx/tilesets' / f'{tileset}.tilecoll').read_bytes()[:-1])
            for x, y in points:
                bid = blk[(y//2)*w+x//2]
                foot = bst[16*bid+_npc_foot_index(x, y)]
                with self.subTest(name=name, pos=(x, y)):
                    self.assertIn(foot, allowed, 'Kanto TryWalking would reject this floor ID')

    def test_generated_graphics_match_gold_candidates_pixel_for_pixel(self):
        # Cloned passable graphics must retain their source appearance; only
        # the tile IDs and collision list may change, never the visible map.
        for key, room in ROOMS.items():
            name, tileset = room['map'], room['tileset']
            candidate = ROOT / 'tools/olivine_public_candidates' / key
            original_map = (candidate / f'{name}.blk').read_bytes()
            original_blocks = (candidate / f'{tileset}.bst').read_bytes()
            runtime_map = (ROOT / 'maps' / f'{name}.blk').read_bytes()
            runtime_blocks = (ROOT / 'gfx/blocksets' / f'{tileset}.bst').read_bytes()
            w = json.loads((candidate / 'provenance.json').read_text())['dimensions_blocks'][0]
            h = len(original_map)//w
            def render(map_bytes, block_bytes, atlas_file):
                atlas = Image.open(atlas_file).convert('L')
                output = Image.new('L', (w*32, h*32), 255)
                for y in range(h):
                    for x in range(w):
                        b = map_bytes[y*w+x]
                        for sub_y in range(4):
                            for sub_x in range(4):
                                index = block_bytes[b*16 + sub_y*4 + sub_x]
                                src = ((index % 8)*8, (index // 8)*8)
                                output.paste(atlas.crop((*src, src[0]+8, src[1]+8)),
                                             (x*32+sub_x*8, y*32+sub_y*8))
                return output
            src = render(original_map, original_blocks, candidate / f'{tileset}.png')
            dst = render(runtime_map, runtime_blocks, ROOT / 'gfx/tilesets' / f'{tileset}.png')
            with self.subTest(room=name):
                self.assertIsNone(ImageChops.difference(src, dst).getbbox(),
                                  'runtime map pixels must equal original Gold candidate')

if __name__ == '__main__':
    unittest.main()
