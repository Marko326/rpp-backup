"""Regression and fault-injection for ROM0 roof farcall reuse in FIX-270."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_rom0_roof_preflight_270 import audit

FILES=('home/overworld.asm','engine/johto_south_roofs_269.asm','macros/asm_macros.asm','main.asm')

class Rom0Roof270(unittest.TestCase):
    def setUp(self):
        self.dir=tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)
        self.root=Path(self.dir.name)
        for rel in FILES:
            dst=self.root/rel;dst.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/rel,dst)

    def break_code(self, rel, old, new, hint):
        p=self.root/rel
        s=p.read_text();self.assertIn(old,s)
        p.write_text(s.replace(old,new,1))
        problems=audit(self.root)
        self.assertTrue(any(hint in x for x in problems),problems)

    def test_current_hooks_preserve_rom0_budget(self):
        self.assertEqual([],audit(ROOT))

    def test_extra_home_roof_call_is_rejected(self):
        self.break_code('home/overworld.asm',
            '\tcall LoadCurrentMapView',
            '\tcallba JohtoSouthRoofAfterTilesetLoad\n\tcall LoadCurrentMapView','overflow')

    def test_wrong_seamless_order_is_rejected(self):
        self.break_code('home/overworld.asm',
            '\tcallba JohtoSouthConnectionSpritesAndRoofs270\n\tcall LoadTileBlockMap',
            '\tcall LoadTileBlockMap\n\tcallba JohtoSouthConnectionSpritesAndRoofs270', 'order')

    def test_snow_wrapper_is_mandatory(self):
        self.break_code('engine/johto_south_roofs_269.asm',
            '    callba ApplySnowTilesetGfxPatch\n    jp JohtoSouthRoofAfterTilesetLoad',
            '    jp JohtoSouthRoofAfterTilesetLoad', 'Snow')

    def test_connection_wrapper_must_initialize_sprites(self):
        self.break_code('engine/johto_south_roofs_269.asm',
            '    callba InitMapSprites\n    jp JohtoSouthRoofOnConnection',
            '    jp JohtoSouthRoofOnConnection', 'sprite')

    def test_user_long_jump_is_preserved(self):
        self.break_code('home/overworld.asm','jp nz,.noCollision','jr nz,.noCollision','long JP')

if __name__=='__main__':unittest.main()
