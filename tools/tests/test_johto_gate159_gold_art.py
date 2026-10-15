"""GATE-5.62.159: static regression for original Gold gate art integration.

The independent dual-source auditor compares every imported graphic and the
Gold collision quadrants; tests here do not claim in-game Warp or color QA.
"""
from pathlib import Path
from PIL import Image
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def source(rel):
    return (ROOT/rel).read_text()


class JohtoGoldGateArtwork(unittest.TestCase):
    def test_dedicated_tileset_preserves_existing_gate(self):
        header = source('data/mapHeaders/JohtoRoute31VioletGate.asm')
        self.assertRegex(header, r'(?m)^\s*db JOHTO_GATE\s*$')
        self.assertRegex(source('constants/tilesets.asm'), r'(?m)^\s*const JOHTO_GATE\b')
        self.assertIn('tileset JohtoGate_Block,   JohtoGate_GFX,   Gate_Coll,',
                      source('data/tileset_headers.asm'))
        self.assertRegex(source('data/mapHeaders/Route15Gate1F.asm'), r'(?m)^\s*db GATE\b')

    def test_generated_blockset_and_original_layout_geometry(self):
        room = (ROOT/'maps/JohtoRoute31VioletGate.blk').read_bytes()
        blockset = (ROOT/'gfx/blocksets/johto_gate.bst').read_bytes()
        self.assertEqual(len(room), 20)
        self.assertEqual(len(blockset), 14*16)
        self.assertEqual(sorted(set(room)), list(range(13)))
        self.assertEqual(room[10], 8)  # source Gold warp border block, left bottom
        self.assertEqual(room[14], 9)  # opposite warp border block
        self.assertEqual(room[0], 10)  # original Gold interior block, NOT the border
        self.assertEqual(blockset[13*16:14*16], bytes([21]*16))
        self.assertIn('db $0d',source('data/mapObjects/JohtoRoute31VioletGate.asm'))

    def test_gate_collisions_reuse_original_rom0_whitelist(self):
        allowed = set((ROOT/'gfx/tilesets/gate.tilecoll').read_bytes()[:-1])
        self.assertEqual((ROOT/'gfx/tilesets/gate.tilecoll').read_bytes()[-1], 0xff)
        blockset = (ROOT/'gfx/blocksets/johto_gate.bst').read_bytes()
        walkable = {2,3,20,22}
        self.assertTrue(walkable.issubset(allowed))
        self.assertTrue(all((tile in allowed)==(tile in walkable) for tile in blockset))
        # Gold WARP_CARPET_LEFT and RIGHT are both walkable, not auto-warps.
        for block, col in ((8,0),(9,1)):
            for quadrant in (0,2) if col == 0 else (1,3):
                start=(quadrant//2)*8 + (quadrant%2)*2
                self.assertTrue(all(blockset[block*16+start+i] in walkable
                                    for i in (0,1,4,5)))
        # Dedicated map-border block is opaque; Gold room block 10 stays untouched.
        self.assertTrue(all(tile not in allowed for tile in blockset[13*16:14*16]))

    def test_palette_and_2bpp_have_exact_fixed_window(self):
        palette=source('color/tilesets/johto_gate.asm')
        entries=[]
        for line in palette.splitlines():
            if 'tilepal 0,' in line:
                fields=[x.strip() for x in line.split('tilepal 0,',1)[1].split(',')]
                self.assertEqual(len(fields), 8)
                entries.extend(fields)
        self.assertEqual(len(entries),96)
        picture=ROOT/'gfx/tilesets/johto_gate.png'
        with Image.open(picture) as image:
            self.assertEqual(image.size, (128,48))
            image=image.convert('RGB')
            expected=[]
            for i in range(96):
                for y in range(8):
                    lo=hi=0
                    for x in range(8):
                        rgb=image.getpixel(((i%16)*8+x, (i//16)*8+y))
                        index={(255,255,255):0,(170,170,170):1,(85,85,85):2,(0,0,0):3}[rgb]
                        lo|=(index&1)<<(7-x)
                        hi|=((index>>1)&1)<<(7-x)
                    expected.extend([lo,hi])
        self.assertEqual(len(expected), 96*16)
        # .2bpp is ignored output; a clean source checkout must still pass.
        built = ROOT/'gfx/tilesets/johto_gate.2bpp'
        if built.exists():
            self.assertEqual(bytes(expected), built.read_bytes())
        self.assertRegex(source('Makefile'),
                         r'(?m)^gfx/tilesets/johto_gate\.2bpp: gfx/tilesets/johto_gate\.png\n\s+\$\(RGBGFX\) -o \$@ \$<')


    def test_imported_room_preview_matches_gold_source_signature(self):
        room=(ROOT/'maps/JohtoRoute31VioletGate.blk').read_bytes()
        blocks=(ROOT/'gfx/blocksets/johto_gate.bst').read_bytes()
        with Image.open(ROOT/'gfx/tilesets/johto_gate.png') as atlas:
            atlas=atlas.convert('RGB')
            preview=Image.new('RGB',(160,128))
            for i,block in enumerate(room):
                for j in range(16):
                    tile=blocks[block*16+j]
                    crop=atlas.crop((tile%16*8,tile//16*8,(tile%16+1)*8,(tile//16+1)*8))
                    preview.paste(crop, (i%5*32+j%4*8,i//5*32+j//4*8))
        self.assertEqual(hashlib.sha256(preview.tobytes()).hexdigest(),
                         '60ad7d6a1ee33bfc1f609934dfcbb97f87225ab802954c8a07eaf2bae214e990')


    def test_outside_black_border_is_distinct_from_gold_interior(self):
        # Rendering only the 5x4 Gold room missed the .159 regression.
        from PIL import Image
        from pathlib import Path
        blocks=(ROOT/'gfx/blocksets/johto_gate.bst').read_bytes()
        room=(ROOT/'maps/JohtoRoute31VioletGate.blk').read_bytes()
        with Image.open(ROOT/'gfx/tilesets/johto_gate.png') as f:
            atlas=f.convert('RGB')
            border_tiles=blocks[13*16:14*16]
            self.assertEqual(set(border_tiles),{21})
            self.assertEqual(atlas.crop((21%16*8,21//16*8,21%16*8+8,21//16*8+8)).getbbox(),None)
            # Gold 5x4 room still retains its exact previously-reviewed pixels.
            picture=Image.new('RGB',(160,128))
            for idx, bid in enumerate(room):
                for tile_index,tile in enumerate(blocks[bid*16:(bid+1)*16]):
                    crop=atlas.crop((tile%16*8,tile//16*8,(tile%16+1)*8,(tile//16+1)*8))
                    picture.paste(crop,(idx%5*32+tile_index%4*8,idx//5*32+tile_index//4*8))
        self.assertEqual(hashlib.sha256(picture.tobytes()).hexdigest(),
                         '60ad7d6a1ee33bfc1f609934dfcbb97f87225ab802954c8a07eaf2bae214e990')

    def test_warp_standing_not_cleared_by_new_tileset(self):
        warp=source('data/warp_tile_ids.asm')
        self.assertEqual(re.findall(r'(?m)^\s*dw JohtoGateWarpTileIDs\b',warp).__len__(),1)
        self.assertRegex(warp,r'JohtoGateWarpTileIDs:\s*\n\s*db \$FF')
        check=source('home/overworld.asm').split('ExtraWarpCheck::',1)[1].split('MapEntryAfterBattle::',1)[0]
        self.assertRegex(check,r'cp JOHTO_GATE\s*;[^\n]*\n\s*jr z, \.useFunction1')
        self.assertIn('ld hl, IsPlayerFacingEdgeOfMap',check)
        self.assertIn('ld hl, IsWarpTileInFrontOfPlayer',check)

    def test_asset_is_in_expansion_bank_only(self):
        src=source('main.asm')
        block=src.split('SECTION "Johto Route31 Gate Tileset",',1)[1].split('SECTION ',1)[0]
        self.assertTrue(block.startswith(' ROMX, BANK[$41]'))
        for symbol in ('JohtoGate_GFX:', 'JohtoGate_Block:'):
            self.assertEqual(src.count(symbol),1)
        self.assertNotIn('JohtoGate_Coll:',source('data/collision.asm'))
        self.assertIn('MUS-5.62.162@',source('data/game_version.asm'))


if __name__=='__main__':
    unittest.main()
