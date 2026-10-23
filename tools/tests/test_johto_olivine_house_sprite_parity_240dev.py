"""Source-level Gold NPC art and movement validation, including mutation rejection."""
from pathlib import Path
from tempfile import TemporaryDirectory
import os,shutil,sys,unittest

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',str(ROOT/'pokegold-master')))
sys.path.insert(0,str(ROOT/'tools'))
from johto_olivine_house_sprite_audit import SOURCES,SPRITES,audit

class HouseGoldNPCParity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():raise AssertionError('Gold checkout required for parity tests')

    def test_gold_sprite_and_movement_contract(self):
        self.assertEqual(audit(ROOT,GOLD),[])

    def reject(self,rel,old,new,fragment,binary=False):
        with TemporaryDirectory() as d:
            temp=Path(d)
            for path in SOURCES:
                dest=temp/path;dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/path,dest)
            for name in SPRITES:
                src=Path(f'gfx/sprites/johto_{name}.png')
                dest=temp/src;dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/src,dest)
            file=temp/rel
            if binary:
                data=bytearray(file.read_bytes());data[64]^=1;file.write_bytes(data)
            else:
                text=file.read_text();self.assertIn(old,text);file.write_text(text.replace(old,new,1))
            self.assertTrue(any(fragment in e for e in audit(temp,GOLD)),fragment)

    def test_reject_visual_mismatch(self):
        self.reject('gfx/sprites/johto_lass.png','','','Gold source sprite differs',True)

    def test_reject_wrong_palette(self):
        self.reject('color/sprites.asm','; 0x65: SPRITE_JOHTO_LASS (Gold PAL_OW_RED)\n\tdb PAL_OW_RED\n','; 0x65: SPRITE_JOHTO_LASS (Gold PAL_OW_RED)\n\tdb PAL_OW_GREEN\n','Gold NPC fixed palette mismatch')

    def test_reject_wrong_daughter_movement(self):
        self.reject('data/mapObjects/JohtoOlivinePunishmentSpeechHouse.asm',
                    '5, 5, WALK, 2, 2','5, 5, STAY, LEFT, 2','house NPC uses wrong')

    def test_reject_outdoor_sprite_set_regression(self):
        self.reject('data/sprite_sets.asm','db SPRITE_FISHER\n','db SPRITE_JOHTO_POKEFAN_M\n',
                    'outdoor Johto $0b sprite set changed')

    def test_reject_legacy_four_tile_classification(self):
        self.reject('engine/overworld/map_sprites.asm','cp a, SPRITE_JOHTO_LASS','cp a, SPRITE_LASS',
                    'must bypass legacy')

if __name__=='__main__':unittest.main()
