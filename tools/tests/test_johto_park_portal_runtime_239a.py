"""Independent Gold evidence plus fault injection for post-phone Park / Route32 fixes."""
import os
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_park_portal_runtime_audit import audit,source_grass
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('JOHTO_GOLD_ROOT') or '/INVALID_GOLD_ROOT')

class ParkPortal239A(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'data/tilesets/park_metatiles.bin').exists():
            raise AssertionError('Full original Gold source is mandatory')
    def good(self):
        self.assertEqual(audit(ROOT,GOLD),[])
    def test_actual_source_matches(self):
        self.good()
        roles,n=source_grass(GOLD)
        self.assertEqual((n['TALL_GRASS'],roles['TALL_GRASS']),(176,{4}))
        self.assertEqual((n['LONG_GRASS'],roles['LONG_GRASS']),(176,{0x3a,0x3b,0x4a,0x4b}))
    def test_missing_right_entrance_is_caught(self):
        p='engine/overworld/region_map_lookup.asm';s=(ROOT/p).read_text()
        old='db JOHTO_ROUTE_32, 1, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'
        self.assertEqual(s.count(old),1)
        self.assertTrue(any('legacy Route32' in v for v in audit(ROOT,GOLD,{p:s.replace(old,'',1)})))
    def test_wrong_right_destination_is_caught(self):
        p='engine/overworld/region_map_lookup.asm';s=(ROOT/p).read_text()
        old='db JOHTO_ROUTE_32, 2, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'
        self.assertEqual(s.count(old),1)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace(old,old.replace(', 2, 3,',', 2, 2,'),1)}))
    def test_old_cave_cannot_be_replaced(self):
        p='engine/overworld/region_map_lookup.asm';s=(ROOT/p).read_text()
        old='db JOHTO_ROUTE_32, 0, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID'
        self.assertEqual(s.count(old),1)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace(old,'',1)}))
    def test_grass_marker_mutation(self):
        p='data/tileset_headers.asm';s=(ROOT/p).read_text();needle='JohtoPark_GFX, JohtoModern_Coll, $FF,$FF,$FF, $04, OUTDOOR'
        self.assertEqual(s.count(needle),1)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace(needle,needle.replace('$04','$FF'),1)}))
    def test_long_grass_mutation(self):
        p='engine/overworld/movement.asm';s=(ROOT/p).read_text()
        self.assertEqual(s.count('cp $4b'),1)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace('cp $4b','cp $4c',1)}))
    def test_player_npc_path_mutation(self):
        p='engine/overworld/movement.asm';s=(ROOT/p).read_text()
        self.assertEqual(s.count('call GetGrassSpritePriority'),2)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace('call GetGrassSpritePriority','nop ; removed grass priority',1)}))
    def test_bike_permission_mutation(self):
        p='data/bike_riding_tilesets.asm';s=(ROOT/p).read_text()
        self.assertEqual(s.count(',JOHTO_PARK,'),1)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace(',JOHTO_PARK,',',',1)}))
    def test_fly_permission_mutation(self):
        p='engine/menu/start_sub_menus.asm';s=(ROOT/p).read_text()
        self.assertEqual(s.count('\tcp JOHTO_PARK ;'),1)
        self.assertTrue(audit(ROOT,GOLD,{p:s.replace('\tcp JOHTO_PARK ;','\tcp JOHTO_PARK_GATE ;',1)}))
    def test_map_no_fake_fly_destination(self):
        p='tools/johto_native_maps.json';s=(ROOT/p).read_text()
        import json
        j=json.loads(s)
        park=next(i for i in j['maps'] if i['local_id']==103)
        self.assertEqual(park['gold_fly_landmark'],None)
        self.assertEqual(park['feature_status']['fly'],'FORBIDDEN')
        park['feature_status']['fly']='ALLOWED'
        self.assertTrue(audit(ROOT,GOLD,{p:json.dumps(j)}))
    def test_wrong_townmap_mark(self):
        p='tools/johto_native_maps.json';s=(ROOT/p).read_text()
        import json
        j=json.loads(s);next(i for i in j['maps'] if i['local_id']==103)['town_map_index']=17
        self.assertTrue(audit(ROOT,GOLD,{p:json.dumps(j)}))

if __name__=='__main__':unittest.main()
