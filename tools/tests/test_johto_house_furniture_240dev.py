"""Verify exact Gold house furniture collision semantics and rejection cases."""
from pathlib import Path
from tempfile import TemporaryDirectory
import os,shutil,sys,unittest
ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',str(ROOT/'pokegold-master')))
sys.path.insert(0,str(ROOT/'tools'))
from johto_house_furniture_audit import audit,collision_cells,front

RELS=('engine/overworld/johto_indoor_furniture.asm',
      'engine/hidden_object_functions3.asm','home.asm','main.asm','text.asm',
      'data/mapObjects/JohtoOlivinePunishmentSpeechHouse.asm',
      'scripts/JohtoOlivinePunishmentSpeechHouse.asm')

class TestGoldHouseFurniture(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():raise AssertionError('JOHTO_GOLD_SOURCE required')
    def test_clean_contract(self): self.assertEqual(audit(ROOT,GOLD),[])
    def test_independent_gold_house1_cell_positions(self):
        c=collision_cells(GOLD)
        self.assertEqual([(y,x,t) for (y,x),t in sorted(c.items())
                          if t in {'TV','RADIO','TOWN_MAP','WINDOW'}],
                         [(0,3,'TOWN_MAP'),(0,5,'WINDOW'),(1,2,'TV'),(1,7,'RADIO')])
    def test_specific_valid_facing_approaches(self):
        self.assertEqual(front(3,1,'UP'),(0,3))
        self.assertEqual(front(5,1,'UP'),(0,5))
        self.assertEqual(front(2,2,'UP'),(1,2))
        self.assertEqual(front(7,2,'UP'),(1,7))
        self.assertEqual(front(6,1,'RIGHT'),(1,7))
        self.assertNotIn(front(5,2,'UP'),{(0,3),(0,5),(1,2),(1,7)})
    def mutated(self,rel,before,after,expected):
        with TemporaryDirectory() as d:
            root=Path(d)
            for item in RELS:
                target=root/item;target.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(ROOT/item,target)
            p=root/rel;s=p.read_text();self.assertIn(before,s)
            p.write_text(s.replace(before,after,1))
            self.assertTrue(any(expected in e for e in audit(root,GOLD)),expected)
    def test_reject_wrong_radio_coord(self):
        self.mutated(RELS[0],'db 1, 7','db 1, 6','furniture lookup')
    def test_reject_missing_window(self):
        self.mutated(RELS[0],'db 0, 5','db 0, 4','furniture lookup')
    def test_reject_room_guard_removed(self):
        self.mutated(RELS[0],'cp JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID','cp JOHTO_OLIVINE_CITY_LOCAL_ID','safeguards')
    def test_reject_wrong_front_facing(self):
        self.mutated(RELS[0],'cp SPRITE_FACING_UP','cp SPRITE_FACING_LEFT','safeguards')
    def test_reject_missing_map_display(self):
        self.mutated(RELS[1],'jp TownMapOpenScript','jp PrintCardKeyText','town map must')
    def test_reject_missing_tv_text(self):
        self.mutated(RELS[4],'_JohtoIndoorTVText::','_WrongTVText::','text missing')
    def test_reject_missing_hidden_item_priority(self):
        self.mutated(RELS[2],'call CheckForHiddenObject','call PrintBookshelfText','hidden item priority')
    def test_reject_attempt_to_unblock_right_bookshelf(self):
        self.mutated(RELS[5],'object SPRITE_JOHTO_POKEFAN_M, 1, 2, STAY',
                     'object SPRITE_JOHTO_POKEFAN_M, 2, 2, STAY','preserve father')
    def test_reject_bookshelf_replacement(self):
        self.mutated(RELS[5],'db 1, 0, 3','db 1, 0, 2','both original bookshelf')

if __name__=='__main__':unittest.main()
