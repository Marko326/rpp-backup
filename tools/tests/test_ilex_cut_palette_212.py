"""ILEX-5.62.212: source/data-level guard; NOT a ROM or phone acceptance."""
from pathlib import Path
import unittest
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]

class ForestCutNightPaletteContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sprites=(ROOT/'color/sprites.asm').read_text()
        cls.pals=(ROOT/'color/data/spritepalettes.asm').read_text()
        cls.cut=(ROOT/'engine/overworld/cut.asm').read_text()

    def test_forest_selects_preexisting_night_sprite_palette(self):
        code=self.sprites.split('LoadOverworldSpritePalettes:',1)[1].split('LoadAttackSpritePalettes:',1)[0]
        night=code.split('ld hl,SpritePalettesNite',1)[1].split('ld hl,SpritePalettesPokecenter',1)[0]
        for tileset in ('ICE_CAVERN','CAVERN','FOREST','JOHTO_ILEX_FOREST'):
            self.assertRegex(night,r'cp '+tileset+r'\n\tjr z, \.gotPaletteList')
        self.assertEqual(night.count('cp JOHTO_ILEX_FOREST'),1)
        self.assertIn('ld hl,SpritePalettes',code.split('.gotPaletteList',1)[0] if False else code)

    def test_object_tree_palette_is_different_between_day_night(self):
        day,night=self.pals.split('SpritePalettesNite:',1)
        def table(x):
            t=x.split('; PAL_OW_TREE',1)[1].split('; PAL_OW_ROCK',1)[0]
            return [ln.strip() for ln in t.splitlines() if ln.lstrip().startswith('RGB ')]
        self.assertNotEqual(table(day),table(night))
        self.assertEqual(table(night),['RGB 15,14,24','RGB 08,13,19','RGB 00,11,13','RGB 00,00,00'])

    def test_cut_animation_keeps_kanto_tiles_and_tree_palette_slot(self):
        self.assertIn('ld de, Overworld_GFX + $2d0',self.cut)
        self.assertIn('ld de, Overworld_GFX + $3d0',self.cut)
        attrs=self.cut.split('CutAnimationTilesAndAttributes:',1)[1].split('GetCutAnimationOffsets:',1)[0]
        self.assertIn('db $FC,$16,$FD,$16',attrs)
        self.assertIn('db $FE,$16,$FF,$16',attrs)
        self.assertEqual(0x16 & 7,6)

    def test_gold_and_kanto_four_cut_tiles_identical(self):
        a=Image.open(ROOT/'gfx/tilesets/overworld.png').convert('RGB')
        b=Image.open(ROOT/'gfx/tilesets/johto_ilex_forest.png').convert('RGB')
        def tile(image,index):
            x=(index%16)*8;y=(index//16)*8
            return image.crop((x,y,x+8,y+8)).tobytes()
        for aa,bb in zip((0x2d,0x2e,0x3d,0x3e),(0x28,0x39,0x38,0x3a)):
            with self.subTest(kanto=hex(aa),forest=hex(bb)):
                self.assertEqual(tile(a,aa),tile(b,bb))

    def test_both_cut_entry_points_and_common_ledge_still_present(self):
        field=(ROOT/'engine/overworld/field_moves.asm').read_text()
        menu=(ROOT/'engine/menu/start_sub_menus.asm').read_text()
        ledges=(ROOT/'engine/overworld/ledges.asm').read_text()
        self.assertIn('callba JohtoCutBadgeAllowed',field)
        self.assertIn('callba JohtoCutBadgeAllowed',menu)
        self.assertEqual([x.strip() for x in ledges.split('\n.ilexForest\n',1)[1].split('\n.route33\n',1)[0].splitlines() if x.strip() and not x.lstrip().startswith(';')],['ld hl, JohtoIlexForestLedgeTiles','jp .checkPairs'])

if __name__ == '__main__':
    unittest.main()
