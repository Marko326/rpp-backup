"""Union Cave 1F isolated Gold art and native warp safety (no ROM compilation)."""
import os
from pathlib import Path
import re
import sys
import unittest
from collections import deque
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
from johto_indoor_tiles_converter import strict_2bpp

class UnionCaveGoldAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/UnionCave1F.blk').exists():
            raise unittest.SkipTest('complete Gold project ZIP required')
        cls.original=(GOLD/'maps/UnionCave1F.blk').read_bytes()
        cls.metatiles=(GOLD/'data/tilesets/cave_metatiles.bin').read_bytes()
        cls.layout=(ROOT/'maps/JohtoUnionCave1F.blk').read_bytes()
        cls.blocks=(ROOT/'gfx/blocksets/johto_union_cave.bst').read_bytes()
        cls.walk=set((ROOT/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes()[:-1])
        cls.labels,_=collision_labels(GOLD,'cave',gold_resource_aliases(GOLD))
        # Avoid the aliasing of indices: both atlases are 8x8 tile arrays.
        cls.src=Image.open(GOLD/'gfx/tilesets/cave.png').convert('RGB')
        cls.dst=Image.open(ROOT/'gfx/tilesets/johto_union_cave.png').convert('RGB')
        cls.gold_colors=[z for ln in (GOLD/'gfx/tilesets/cave_palette_map.asm').read_text().splitlines()
                         if 'tilepal 0' in ln for z in ln.split('tilepal 0,',1)[1].split(',')]
        cls.colors=[z.strip() for z in cls.gold_colors]
        cls.new_colors=[z.strip() for ln in (ROOT/'color/tilesets/johto_union_cave.asm').read_text().splitlines()
                        if 'tilepal 0' in ln for z in ln.split('tilepal 0,',1)[1].split(',')]

    def test_complete_pixel_identity_and_palette(self):
        self.assertEqual((len(self.layout),len(self.original)),(180,180))
        self.assertEqual(len(self.blocks)%16,0)
        self.assertLessEqual(max(self.layout),len(self.blocks)//16-2) # exclude border
        sc,dc=self.src.width//8,self.dst.width//8
        for pos,gid in enumerate(self.original):
            rid=self.layout[pos]
            for offset in range(16):
                gt=self.metatiles[gid*16+offset]
                rt=self.blocks[rid*16+offset]
                patch=self.src.crop(((gt%sc)*8,(gt//sc)*8,(gt%sc+1)*8,(gt//sc+1)*8))
                mapped=self.dst.crop(((rt%dc)*8,(rt//dc)*8,(rt%dc+1)*8,(rt//dc+1)*8))
                self.assertEqual(patch.tobytes(),mapped.tobytes(),(gid,rid,offset))
                self.assertEqual(self.colors[gt],self.new_colors[rt],(gid,rid,offset))

    def test_collision_independent_of_shared_graphic_tiles(self):
        walkable={'FLOOR','LADDER','TALL_GRASS','WARP_CARPET_DOWN'}
        blocked={'WALL','UP_WALL','WATER','CAVE','PIT'}
        for gid,rid in zip(self.original,self.layout):
            block=self.blocks[rid*16:rid*16+16]
            for qi,label in enumerate(self.labels[gid].split(',')):
                lab=label.strip()
                self.assertIn(lab,walkable|blocked)
                ids=[block[(qi//2*2+y)*4+qi%2*2+x] for y in range(2) for x in range(2)]
                self.assertTrue(all((v in self.walk)==(lab in walkable) for v in ids),(gid,lab,ids))
        border=self.blocks[-16:]
        self.assertEqual(len(set(border)),1)
        self.assertNotIn(border[0],self.walk)

    def test_fixed_tileset_loader_and_96_palette_slots(self):
        self.assertEqual(self.dst.size,(64,96))
        self.assertEqual(len(self.new_colors),96)
        self.assertEqual((ROOT/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes()[-1],255)
        expected=strict_2bpp(Image.open(ROOT/'gfx/tilesets/johto_union_cave.png'),96)
        self.assertEqual(len(expected),1536)
        built=ROOT/'gfx/tilesets/johto_union_cave.2bpp'
        if built.exists():self.assertEqual(expected,built.read_bytes())
        rules=(ROOT/'Makefile').read_text()
        self.assertIn('gfx/tilesets/johto_union_cave.2bpp: gfx/tilesets/johto_union_cave.png',rules)
        self.assertIn('$(RGBGFX) -o $@ $<',rules)

    def test_cave_walkable_route_with_no_route33_warp(self):
        width,height=20,36
        def passable(x,y):
            r=self.layout[y//2*10+x//2]
            q=(y%2)*2+x%2
            b=self.blocks[r*16:r*16+16]
            return all(b[(q//2*2+dy)*4+(q%2*2+dx)] in self.walk
                       for dy in range(2) for dx in range(2))
        start=(17,3); finish=(17,31)
        self.assertTrue(passable(*start))
        self.assertTrue(passable(*finish))
        seen={start};queue=deque([start])
        while queue:
            x,y=queue.popleft()
            for pos in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                a,b=pos
                if 0<=a<width and 0<=b<height and pos not in seen and passable(a,b):
                    seen.add(pos);queue.append(pos)
        self.assertIn(finish,seen,'Gold cave surface corridor is unexpectedly blocked')

    def test_only_safe_reversible_warp_and_expansion_bank(self):
        src=(ROOT/'data/mapObjects/JohtoRoute32.asm').read_text()
        dst=(ROOT/'data/mapObjects/JohtoUnionCave1F.asm').read_text()
        routes=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        self.assertIn('db 79, 6, 0, REGION_WARP_ESCAPE',src)
        self.assertIn('db 3, 17, 0, REGION_WARP_ESCAPE',dst)
        self.assertIn('db JOHTO_ROUTE_32, 0, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',routes)
        self.assertIn('db JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',routes)
        self.assertRegex(dst,r'(?m)^\s*db \$02\s*$')
        self.assertIn('db 31, 17, 0, REGION_WARP_ESCAPE',dst)
        self.assertNotIn('JohtoUnionCaveB1F',dst)
        self.assertNotIn('JohtoUnionCaveB1F',dst)
        self.assertEqual(len(self.layout),180)
        header=(ROOT/'data/mapHeaders/JohtoUnionCave1F.asm').read_text()
        self.assertIn('db $00',header)
        main=(ROOT/'main.asm').read_text()
        self.assertIn('SECTION "Johto Union Cave Tileset", ROMX, BANK[$42]',main)
        self.assertIn('SECTION "Johto Union Cave 1F Map", ROMX, BANK[$42]',main)
        self.assertNotIn('mapconst JOHTO_UNION_CAVE', (ROOT/'constants/map_constants.asm').read_text())
        warp_tiles=(ROOT/'data/warp_tile_ids.asm').read_text()
        self.assertRegex(warp_tiles,
                         r'JohtoUnionCaveWarpTileIDs:\s*db \$FF')
        self.assertNotRegex(warp_tiles,
                            r'JohtoUnionCaveWarpTileIDs:\s*db\s+0,\s*\$FF')

if __name__=='__main__':unittest.main()
