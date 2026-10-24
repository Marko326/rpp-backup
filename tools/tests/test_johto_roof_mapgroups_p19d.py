"""P19D: verify every completed Johto exterior against the *Gold* map-group roof contract.
Static source/asset validation; it is not an emulator runtime proof.
"""
import os
import re
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
# Group index 0 new bark, 1 cherrygrove, 2 violet, 3 azalea, 4 goldenrod.
SCOPE = (
 ('NewBarkTown',0), ('Route29',0), ('CherrygroveCity',1), ('Route30',1),
 ('Route31',1), ('VioletCity',2), (None,None), ('Route32',2),
 (None,None), ('Route33',3), ('AzaleaTown',3), (None,None),
 (None,None), (None,None), ('Route34',4), ('GoldenrodCity',4), ('Route36',2), ('Route35',2), (None,None), (None,None), (None,None), ('Route37',2), ('EcruteakCity',5), (None,None), ('Route38',6), (None,None), ('Route42',7),
)
GROUP_NAME = ('NewBark','Cherrygrove','Violet','Azalea','Goldenrod','Ecruteak','Olivine','Mahogany')
GOLD_MAP_GROUP = (24,26,10,8,11,4,1,2)
ROOF_ART_NAME = ('new_bark','new_bark','violet','azalea','goldenrod','violet','olivine','azalea')
PAL_LABEL = ('JohtoNewBarkGoldDayRoofPalette','JohtoCherrygroveGoldDayRoofPalette',
             'JohtoVioletGoldDayRoofPalette','JohtoAzaleaGoldDayRoofPalette','GoldenrodGoldDayRoofPalette','EcruteakGoldDayRoofPalette','Route38OlivineGoldDayRoofPalette','Route42GoldDayRoofPalette')

def bytes_from_png(path):
    im=Image.open(path).convert('L')
    assert im.size == (24,24)
    out=bytearray()
    for ytile in range(3):
        for xtile in range(3):
            for y in range(8):
                pixels=[(255-im.getpixel((xtile*8+x,ytile*8+y)))//85 for x in range(8)]
                out.extend((sum((v&1) << (7-x) for x,v in enumerate(pixels)),
                            sum(((v>>1)&1) << (7-x) for x,v in enumerate(pixels))))
    return bytes(out)

def current_roof_group_table(src, label):
    section=src.split(label+':',1)[1].split('End:',1)[0]
    rows=re.findall(r'^\s*db\s+([^;\n]+)',section,re.M)
    return [None if z.strip()=='$ff' else int(z.strip(),0) for row in rows for z in row.split(',')]

def rgb_palette(src, label):
    section=src.split(label+':',1)[1].splitlines()[1:5]
    ret=[]
    for line in section:
        m=re.search(r'RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',line)
        if m: ret.append(tuple(map(int,m.groups())))
    return ret

class GoldRoofMapgroupsP19D(unittest.TestCase):
    def test_gold_mapgroup_source_covers_every_registered_outdoor(self):
        gold=(GOLD/'data/maps/maps.asm').read_text()
        for map_name,index in SCOPE:
            if index is None:
                continue
            group=GROUP_NAME[index]
            section=re.search(r'^MapGroup_'+group+r':\s*(.*?)(?=^MapGroup_|\Z)',gold,re.M|re.S)
            self.assertIsNotNone(section,group)
            self.assertRegex(section.group(1),r'\bmap\s+'+map_name+r'\s*,')
        # Gold uses a roof for a *whole mapgroup*, not only its city.
        gold_roofs=(GOLD/'data/maps/roofs.asm').read_text()
        for groupidx,expected_art in enumerate(ROOF_ART_NAME):
            const='ROOF_'+expected_art.upper()
            line=[x for x in gold_roofs.splitlines() if re.search(r';\s*'+str(GOLD_MAP_GROUP[groupidx])+r'\s+\(',x)]
            self.assertEqual(len(line),1,(groupidx,line))
            self.assertIn('db '+const,line[0])

    def test_gfx_and_palette_same_group_for_all_19_local_maps(self):
        color=(ROOT/'color/loadpalettes.asm').read_text()
        graphics=(ROOT/'engine/overworld/johto_goldenrod_roof_gfx.asm').read_text()
        expected=[index for _,index in SCOPE]+[7, 6, 6, 8, 8, 8, None, 9, 9, None, None, None, None, None, 7, 10, 10, 10, None, None, None, None]  # Last four $ff: gate and three Olivine houses
        self.assertEqual(current_roof_group_table(color,'JohtoGoldDayRoofGroups'),expected)
        self.assertEqual(current_roof_group_table(graphics,'JohtoRoofGroupForLocalMap'),expected)
        self.assertIn('cp JOHTO_MODERN',graphics)
        self.assertIn('cp JOHTO\n',graphics)
        self.assertIn('cp MAP_REGION_JOHTO',graphics)
        self.assertIn('callab GetJohtoActiveSlot',graphics)
        self.assertIn('cp $ff',graphics)
        self.assertIn('cp JOHTO_MODERN',color)
        self.assertIn('cp JOHTO\n',color)
        self.assertIn('cp MAP_REGION_JOHTO',color)
        self.assertIn('callab GetJohtoActiveSlot',color)
        self.assertIn('cp $ff',color)
        # Index 14 (Route34) and 15 (Goldenrod) *both* map to Gold roof #11.
        self.assertEqual(expected[14:16],[4,4])
        self.assertIn('JohtoGoldenrodRoofs_GFX',graphics)
        self.assertIn('JohtoModern_GFX + $0a * $10',graphics)
        self.assertIn('NewBark_GFX + $0a * $10',graphics)

    def test_daytime_palette_rgb_matches_gold_all_five(self):
        original=(GOLD/'gfx/tilesets/roofs.pal').read_text()
        rgb=[tuple(map(int,t)) for t in re.findall(r'(?m)^\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',original)]
        src=(ROOT/'color/loadpalettes.asm').read_text()
        for group, name in enumerate(PAL_LABEL):
            gold_index=GOLD_MAP_GROUP[group]
            self.assertEqual(rgb_palette(src,name),[(27,31,27),*rgb[4*gold_index:4*gold_index+2],(7,7,7)])
        # Group #26 Cherrygrove is fuchsia/pink; Gold #11 Goldenrod is yellow.
        self.assertEqual(rgb_palette(src,PAL_LABEL[1])[1:3],[(31,14,28),(31,5,21)])
        self.assertEqual(rgb_palette(src,PAL_LABEL[4])[1:3],[(25,25,0),(20,17,8)])
        body=src.split('JohtoGoldDayRoofPalettes:',1)[1].split('JohtoGoldDayRoofPalettesEnd:',1)[0]
        self.assertEqual(len(re.findall(r'(?m)^\s*RGB\s+',body)),11*4)
        self.assertIn('ASSERT JohtoGoldDayRoofPalettesEnd - JohtoGoldDayRoofPalettes == 11 * 8',src)

    def test_all_9_roof_tiles_match_gold_original_png(self):
        # Input PNGs, not ignored build-time .2bpp artifacts, are the source of truth.
        for group in ('violet','azalea','goldenrod','violet','olivine','azalea'):
            actual=bytes_from_png(ROOT/f'gfx/tilesets/johto_{group}_roofs.png')
            gold=bytes_from_png(GOLD/f'gfx/tilesets/roofs/{group}.png')
            self.assertEqual(len(actual),144)
            self.assertEqual(actual,gold,group)
        # Both base Johto tilesets already carry the new_bark roof art exactly.
        for img in ('johto.png','johto_modern.png'):
            src=Image.open(ROOT/'gfx/tilesets'/img).convert('L')
            out=bytearray()
            for tile in range(10,19):
                for y in range(8):
                    pixels=[(255-src.getpixel(((tile%16)*8+x,(tile//16)*8+y)))//85 for x in range(8)]
                    out.extend((sum((v&1)<<(7-x) for x,v in enumerate(pixels)),
                                sum(((v>>1)&1)<<(7-x) for x,v in enumerate(pixels))))
            self.assertEqual(bytes(out),bytes_from_png(GOLD/'gfx/tilesets/roofs/new_bark.png'))

    def test_full_load_and_seamless_connection_restore_original_group(self):
        src=(ROOT/'home/overworld.asm').read_text()
        gfx=(ROOT/'engine/overworld/johto_goldenrod_roof_gfx.asm').read_text()
        self.assertIn('callba PatchGoldenrodRoofAfterTilesetLoad',src)
        self.assertIn('callba PatchGoldenrodRoofOnConnection',src)
        self.assertIn('ld c,9',gfx)
        self.assertIn('CopyVideoData',gfx)
        self.assertIn('FarCopyData2',gfx)
        self.assertIn('vTileset + $0a * $10',gfx)
        self.assertNotIn('cp JOHTO_GOLDENROD_CITY_LOCAL_ID',gfx)
        # A neighboring route never falls through to a generic green roof.
        self.assertIn('db 4 ; 0e Route34',gfx)
        self.assertIn('db 4 ; 0f GoldenrodCity',gfx)

if __name__ == '__main__':
    unittest.main()
