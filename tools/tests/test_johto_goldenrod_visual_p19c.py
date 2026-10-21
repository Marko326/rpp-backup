"""P19C Gold-accurate Goldenrod presentation: static contract only (no ROM proof)."""
import os
import re
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.getenv('JOHTO_GOLD_SOURCE', str(ROOT/'pokegold-master')))

def rgb_values(txt):
    return [tuple(map(int, xs)) for xs in re.findall(r'(?m)^\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)', txt)]

def multi_rgb_rows(src):
    values=[]
    for line in src.splitlines():
        if "RGB" not in line: continue
        body=line.split("RGB",1)[1].split(";",1)[0]
        nums=[int(v) for v in re.findall(r"\d+",body)]
        values.extend(tuple(nums[k:k+3]) for k in range(0,len(nums),3))
    return values

def gold_roof_pixels(path=None):
    im = Image.open(path or GOLD/'gfx/tilesets/roofs/goldenrod.png').convert('L')
    assert im.size == (24,24)
    out = bytearray()
    for j in range(3):
        for i in range(3):
            for y in range(8):
                lo=hi=0
                for x in range(8):
                    p=(255-im.getpixel((i*8+x,j*8+y)))//85
                    lo=(lo<<1)|(p&1)
                    hi=(hi<<1)|((p>>1)&1)
                out.extend((lo,hi))
    return bytes(out)

class GoldenrodP19CVisual(unittest.TestCase):
    def test_exact_gold_map_border(self):
        src=(GOLD/'data/maps/attributes.asm').read_text()
        self.assertRegex(src,r'map_attributes\s+GoldenrodCity,\s+GOLDENROD_CITY,\s+\$35')
        obj=(ROOT/'data/mapObjects/JohtoGoldenrodCity.asm').read_text()
        self.assertRegex(obj,r'JohtoGoldenrodCityObject:\s+db\s+\$35\b')

    def test_exact_gold_route35_preview_rows_and_closed_edge(self):
        raw=(GOLD/'maps/Route35.blk').read_bytes()
        self.assertEqual(len(raw),10*18)
        actual=[raw[10*(18-3+i):10*(18-2+i)] for i in range(3)]
        code=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        section=code.split('PatchJohtoGoldenrodNorthBorder::',1)[1].split('; Shared 16x16 Gold block mask',1)[0]
        for i,row in enumerate(actual):
            values=re.search(r'(?m)^\.row'+str(i)+r'\s+db\s+([^\n]+)',section)
            self.assertIsNotNone(values,('preview row',i))
            self.assertEqual(bytes(int(x.strip().replace('$','0x'),16) for x in values.group(1).split(',')),row)
        header=(ROOT/'data/mapHeaders/JohtoGoldenrodCity.asm').read_text()
        self.assertRegex(header,r'(?m)^\s*db SOUTH\s*$')
        code2=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        self.assertIn('JohtoGoldenrodEdgeFence::', code2)
        self.assertIn('cp JOHTO_GOLDENROD_CITY_LOCAL_ID',section)
        world=(ROOT/'home/overworld.asm').read_text()
        self.assertEqual(world.count('callba PatchJohtoMapBordersAfterBlockLoad'),2)
        self.assertIn('call PatchJohtoGoldenrodNorthBorder',code)

    def test_exact_gold_day_rgb_and_green_unmodified(self):
        bg=multi_rgb_rows((GOLD/'gfx/tilesets/bg_tiles.pal').read_text())
        # Gold day: 8 palettes x 4 colors after the 8 morning palettes
        gold_day=[bg[32+i*4:36+i*4] for i in range(8)]
        # Day outdoor WATER uses extra palette near the end of bg_tiles.pal.
        exact_water=bg[-8:-4]
        self.assertEqual(exact_water,[(23,23,31),(18,19,31),(13,12,31),(7,7,7)])
        roofs=rgb_values((GOLD/'gfx/tilesets/roofs.pal').read_text())
        exact_roof=[gold_day[6][0],roofs[11*4],roofs[11*4+1],gold_day[6][3]]
        s=(ROOT/'color/loadpalettes.asm').read_text()
        def palette(label):
            body=s.split(label+':',1)[1]
            return rgb_values('\n'.join(body.splitlines()[:5]))
        self.assertEqual(palette('GoldenrodGoldDayWaterPalette'),exact_water)
        self.assertEqual(palette('GoldenrodGoldDayRoofPalette'),exact_roof)
        self.assertNotIn('GoldenrodGreenPalette',s)
        regular=(ROOT/'color/data/map_palettes.asm').read_text()
        green=regular.split('; 0x03: OUTDOOR_GREEN',1)[1].split('; 0x04:',1)[0]
        self.assertEqual(rgb_values(green),gold_day[2])
        self.assertIn('JohtoGoldDayRoofGroups:',s)
        self.assertRegex(s,r'(?m)^\s*db 0,0,1,1,1,2,\$ff,2,\$ff,3,3,\$ff,\$ff,\$ff,4,4,2,2,\$ff,\$ff,\$ff,2,5,\$ff,6,\$ff,7\s*;')

    def test_exact_gold_roof_pixels_both_live_and_full_load(self):
        src=gold_roof_pixels(ROOT/'gfx/tilesets/johto_goldenrod_roofs.png')
        self.assertEqual(len(src),144)
        self.assertEqual(src,gold_roof_pixels())
        code=(ROOT/'engine/overworld/johto_goldenrod_roof_gfx.asm').read_text()
        for kw in ['vTileset + $0a * $10','ld c,9','CopyVideoData',
                   'FarCopyData2','JohtoModern_GFX + $0a * $10',
                   'JohtoGoldenrodRoofs_GFX']:
            self.assertIn(kw,code)
        world=(ROOT/'home/overworld.asm').read_text()
        self.assertIn('callba PatchGoldenrodRoofOnConnection',world)
        self.assertIn('callba PatchGoldenrodRoofAfterTilesetLoad',world)

if __name__ == '__main__':
    unittest.main()
