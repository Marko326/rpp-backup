"""House NPC-floor regression: require real walking and reject furniture leaks."""
from pathlib import Path
from tempfile import TemporaryDirectory
import sys,shutil,unittest,os
ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',str(ROOT/'pokegold-master')))
sys.path.insert(0,str(ROOT/'tools'))
from johto_olivine_house_npc_floor_audit import audit

NEEDED=('gfx/tilesets/johto_house.tilecoll',
        'maps/JohtoOlivinePunishmentSpeechHouse.blk',
        'maps/JohtoOlivinePunishmentSpeechHouse.blocked_mask.bin',
        'gfx/blocksets/johto_house.bst',
        'data/tileset_headers.asm','data/collision.asm',
        'data/mapObjects/JohtoOlivinePunishmentSpeechHouse.asm',
        'engine/overworld/movement.asm','engine/overworld/johto_route33_collision.asm')

class HouseNPCFloor(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir(): raise AssertionError('Gold source required')
    def test_conservative_floor_passable_and_gold_events(self):
        self.assertEqual(audit(ROOT,GOLD),[])
    def reject(self,rel,body,problem):
        with TemporaryDirectory() as t:
            base=Path(t)
            for name in NEEDED:
                dst=base/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/name,dst)
            (base/rel).write_bytes(body)
            self.assertTrue(any(problem in err for err in audit(base,GOLD)),problem)
    def test_original_ff_only_cannot_walk(self):
        self.reject(NEEDED[0],b'\xff','collision whitelist')
    def test_reject_moving_on_furniture(self):
        self.reject(NEEDED[0],bytes((1,0x10,0x12,0x2b,0xff)),'mask conflict')
    def test_reject_missing_daughter_floor(self):
        self.reject(NEEDED[0],bytes((0x10,0x12,0xff)),'horizontal floor blocked')
    def test_reject_mask_mismatch(self):
        m=bytearray((ROOT/NEEDED[2]).read_bytes());m[5]|=1<<4
        self.reject(NEEDED[2],bytes(m),'mask conflict')
    def test_reject_replacing_daughter_with_stationary(self):
        source=(ROOT/NEEDED[6]).read_text();source=source.replace('5, 5, WALK, 2, 2','5, 5, STAY, LEFT, 2')
        self.reject(NEEDED[6],source.encode(),'horizontal walking')

if __name__=='__main__':unittest.main()
