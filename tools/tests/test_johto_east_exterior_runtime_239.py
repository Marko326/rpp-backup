"""Gold-derived fail-closed tests for eastern live exterior runtime."""
import json
import os
from pathlib import Path
import unittest

from johto_east_exterior_runtime_audit import audit
ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_ROOT','/mnt/data/pokegold-master'))

class EastLiveRuntime239(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route44.blk').is_file():
            raise RuntimeError('Gold checkout is mandatory; cannot skip negative tests')
    def modify(self,source,old,new,expected):
        current=(ROOT/source).read_text() if not source.endswith('.blk') else (ROOT/source).read_bytes()
        self.assertIn(old,current)
        errors=audit(ROOT,GOLD,connections=False,fly=False,overrides={source:current.replace(old,new,1)})
        self.assertTrue(any(expected in e for e in errors),errors)
    def test_verified_runtime_and_all_gold_connections(self):
        self.assertEqual([],audit(ROOT,GOLD))
    def test_modified_gold_route44_block_caught(self):
        self.modify('maps/JohtoRoute44.blk',bytes([(ROOT/'maps/JohtoRoute44.blk').read_bytes()[0]]),bytes([((ROOT/'maps/JohtoRoute44.blk').read_bytes()[0]+1)%256]),'Gold map layout differs')
    def test_corrupt_blocked_mask_caught(self):
        source='maps/JohtoRoute45.blocked_mask.bin'
        blob=(ROOT/source).read_bytes(); broken=bytes([blob[0]^1])+blob[1:]
        errors=audit(ROOT,GOLD,connections=False,fly=False,overrides={source:broken})
        self.assertTrue(any('Route45: live Gold blocked mask differs' in e for e in errors),errors)
    def test_route45_gold_right_hops_enterable_wall_remains_solid(self):
        # These Gold HOP_RIGHT positions are a takeoff, not generic WALL.
        # The preserved source review mask is immutable and deliberately
        # differs in these four bits from the running game's walk mask.
        from johto_indoor_collision_adapter import plan_gold_quadrant_collision
        plan, _ = plan_gold_quadrant_collision(GOLD,'Route45','johto')
        hops={(v['x'],v['y'],v['dx'],v['dy']) for v in plan['hops']}
        mask=(ROOT/'maps/JohtoRoute45.blocked_mask.bin').read_bytes()
        stage=(ROOT/'docs/gold_east_source_239/Route45/Route45.gold_collision_review_mask.bin').read_bytes()
        for x,y in ((6,20),(6,21),(6,64),(6,65)):
            self.assertIn((x,y,1,0),hops)
            offset=y*3+x//8
            self.assertTrue(stage[offset]&(1<<(x%8)))
            self.assertFalse(mask[offset]&(1<<(x%8)))
            self.assertTrue(mask[y*3+7//8]&(1<<(7%8)),(x,y,'wall'))
            self.assertFalse(mask[y*3+8//8]&(1<<(8%8)),(x,y,'landing'))

    def test_route45_hop_takeoff_reblocked_detected(self):
        source='maps/JohtoRoute45.blocked_mask.bin'
        blob=bytearray((ROOT/source).read_bytes())
        blob[20*3] |= 1<<6
        errors=audit(ROOT,GOLD,connections=False,fly=False,
                     overrides={source:bytes(blob)})
        self.assertTrue(any('Route45: live Gold blocked mask differs' in e for e in errors),errors)

    def test_route45_hop_wall_accidentally_opened_detected(self):
        source='maps/JohtoRoute45.blocked_mask.bin'
        blob=bytearray((ROOT/source).read_bytes())
        blob[20*3] &= ~(1<<7)
        errors=audit(ROOT,GOLD,connections=False,fly=False,
                     overrides={source:bytes(blob)})
        self.assertTrue(any('Route45: live Gold blocked mask differs' in e for e in errors),errors)

    def test_route44_fly_destination_cannot_be_enabled(self):
        source='tools/johto_native_maps.json';obj=json.loads((ROOT/source).read_text())
        next(x for x in obj['maps'] if x['local_id']==69)['feature_status']['fly']='ALLOWED'
        errors=audit(ROOT,GOLD,connections=False,fly=False,overrides={source:json.dumps(obj)})
        self.assertTrue(any('Fly destination only at original Gold city' in e for e in errors),errors)
    def test_blackthorn_fly_cannot_disappear(self):
        self.modify('engine/johto_fly_town_map.asm', 'dw .blackthornName','dw .lakeName','Blackthorn Fly missing menu row')
    def test_cliff_takeoff_missing_detected(self):
        self.modify('engine/overworld/johto_east_exterior.asm','db 47, 6, PLAYER_DIR_LEFT','; removed hop','Gold hop takeoff count changed')
    def test_bank47_source_missing_detected(self):
        self.modify('main.asm','INCLUDE "engine/overworld/johto_east_exterior.asm"','; removed EAST hooks','Bank47 collision implementation not included')
    def test_fly_save_bits_missing_detected(self):
        self.modify('engine/johto_fly_town_map.asm','EVENT_JOHTO_FLY_BLACKTHORN','EVENT_JOHTO_FLY_CIANWOOD','Blackthorn Fly missing persistent visited gate')
    def test_wrong_town_map_index_detected(self):
        self.modify('engine/overworld/johto_town_map_helpers.asm','db 37, 39, 41, 43','db 38, 40, 42, 44','active slot -> Gold Town Map index drift')
    def test_cave_cannot_falsely_activate(self):
        self.modify('data/johto_map_headers.asm','JohtoStableIDToActiveSlot::','JohtoIcePath1F_h:\nJohtoStableIDToActiveSlot::','Ice Path 1F opened without Gold ice/sliding')
    def test_surf_permission_cannot_be_revoked(self):
        source='tools/johto_native_maps.json';obj=json.loads((ROOT/source).read_text());next(x for x in obj['maps'] if x['local_id']==69)['feature_status']['surf']='DEFERRED'
        errors=audit(ROOT,GOLD,connections=False,fly=False,overrides={source:json.dumps(obj)})
        self.assertTrue(any('Surf permission must match reviewed Gold water' in e for e in errors),errors)
    def test_original_route44_cliff_water_count_and_no_cave(self):
        text=(ROOT/'engine/overworld/johto_east_exterior.asm').read_text()
        self.assertIn('JohtoRoute44HopList::',text)
        self.assertIn('INCBIN "maps/JohtoRoute44.water_mask.bin"',(ROOT/'engine/overworld/johto_union_cave_surf.asm').read_text())
        self.assertNotIn('JohtoIcePath1F_h',(ROOT/'data/johto_map_headers.asm').read_text())

if __name__=='__main__':unittest.main()
