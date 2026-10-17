"""GATE-5.62.159: static regression for original Gold gate art integration.

The independent dual-source auditor compares every imported graphic and the
Gold collision quadrants; tests here do not claim in-game Warp or color QA.
"""
from pathlib import Path
from PIL import Image
import hashlib
import re
import os
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

    def test_compact_gate_palette_exactly_matches_gold_source(self):
        from johto_gate_audit import verify_gold_gate_palette_map, gold_gate_source_to_compact_tiles
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        self.assertTrue((gold/'gfx/tilesets/gate_palette_map.asm').is_file())
        ids=gold_gate_source_to_compact_tiles(ROOT, gold)
        self.assertEqual(len(ids),22)
        # Regression for the P16D sorting bug: indices are *not* interchangeable.
        self.assertEqual(ids[0],7)
        self.assertEqual(ids[2],1)
        self.assertEqual(ids[7],16)
        self.assertEqual(verify_gold_gate_palette_map(ROOT,gold),[])

    def test_gold_gate_runtime_rgb_exact_with_kanto_isolation(self):
        from johto_gate_rgb_audit import verify
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        self.assertEqual(verify(ROOT,gold),[])

    def test_gold_gate_rgb_wrong_value_or_wrong_tileset_rejected(self):
        from johto_gate_rgb_audit import verify
        import shutil
        from tempfile import TemporaryDirectory
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        paths=('color/data/map_palettes.asm','color/data/map_palette_sets.asm',
               'color/data/map_palette_constants.asm')
        with TemporaryDirectory() as td:
            root=Path(td)
            for rel in paths:
                dest=root/rel;dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,dest)
            pal=root/paths[0];good=pal.read_text()
            pal.write_text(good.replace('RGB 18,24,9','RGB 30,28,26',1))
            self.assertTrue(any('GREEN' in e for e in verify(root,gold)))
            pal.write_text(good)
            table=root/paths[1]; txt=table.read_text()
            table.write_text(txt.replace('db JOHTO_GATE_GOLD_GREEN','db INDOOR_GREEN',1))
            self.assertTrue(any('JOHTO_GATE' in e for e in verify(root,gold)))

    def test_palette_tag_mutation_is_detected(self):
        from johto_gate_audit import verify_gold_gate_palette_map
        from tempfile import TemporaryDirectory
        import shutil
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        with TemporaryDirectory() as td:
            fake=Path(td)
            for rel in ('color/tilesets/johto_gate.asm',
                        'maps/JohtoRoute31VioletGate.blk',
                        'gfx/blocksets/johto_gate.bst'):
                path=fake/rel
                path.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,path)
            pal=fake/'color/tilesets/johto_gate.asm'
            txt=pal.read_text()
            self.assertIn('tilepal 0, GREEN, GREEN, GRAY',txt)
            pal.write_text(txt.replace('tilepal 0, GREEN, GREEN, GRAY',
                                       'tilepal 0, GRAY, GREEN, GRAY',1))
            self.assertTrue(any('palette mismatch' in e for e in
                                verify_gold_gate_palette_map(fake,gold)))

    def test_sorted_source_order_regression_is_rejected(self):
        # The exact P16D failure must fail even though all 22 tags look valid.
        from johto_gate_audit import verify_gold_gate_palette_map
        from tempfile import TemporaryDirectory
        import shutil
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        blocks=(gold/'data/tilesets/gate_metatiles.bin').read_bytes()
        layout=(gold/'maps/EastWestGate.blk').read_bytes()
        tile_ids=sorted({t for b in layout for t in blocks[b*16:(b+1)*16]})
        source=[v.strip() for line in (gold/'gfx/tilesets/gate_palette_map.asm').read_text().splitlines()
                if 'tilepal 0,' in line for v in line.split('tilepal 0,',1)[1].split(',')]
        with TemporaryDirectory() as td:
            fake=Path(td)
            for rel in ('color/tilesets/johto_gate.asm',
                        'maps/JohtoRoute31VioletGate.blk',
                        'gfx/blocksets/johto_gate.bst'):
                p=fake/rel
                p.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,p)
            pal=fake/'color/tilesets/johto_gate.asm'
            text=pal.read_text()
            vals=[v.strip() for line in text.splitlines()
                  if 'tilepal 0,' in line for v in line.split('tilepal 0,',1)[1].split(';',1)[0].split(',')]
            vals[:22]=[source[i] for i in tile_ids] # incorrect P16D order
            lines=text.splitlines()
            row_ids=[i for i,l in enumerate(lines) if l.strip().startswith('tilepal 0,')]
            for row,j in enumerate(row_ids):
                lines[j]='\ttilepal 0, '+', '.join(vals[row*8:row*8+8])
            pal.write_text('\n'.join(lines)+'\n')
            errors=verify_gold_gate_palette_map(fake,gold)
            self.assertEqual(len(errors),10,errors)

    def test_corrupt_graphic_tile_correspondence_is_rejected(self):
        from johto_gate_audit import verify_gold_gate_palette_map
        from tempfile import TemporaryDirectory
        import shutil
        gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        with TemporaryDirectory() as td:
            fake=Path(td)
            for rel in ('color/tilesets/johto_gate.asm',
                        'maps/JohtoRoute31VioletGate.blk',
                        'gfx/blocksets/johto_gate.bst'):
                path=fake/rel
                path.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,path)
            blockfile=fake/'gfx/blocksets/johto_gate.bst'
            raw=bytearray(blockfile.read_bytes())
            raw[0]=1 if raw[0]!=1 else 0
            blockfile.write_bytes(raw)
            errors=verify_gold_gate_palette_map(fake,gold)
            self.assertTrue(any('tile reuse mismatch' in e for e in errors),errors)

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
        self.assertRegex(source('data/game_version.asm'), r'db \"[A-Z]+-5\.62\.\d+@\"')


if __name__=='__main__':
    unittest.main()
