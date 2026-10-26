"""Gold Cherrygrove three ordinary houses: strict static tests with mutations."""
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_cherrygrove_houses_audit import audit
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',ROOT/'pokegold-master'))

class CherrygroveHouses243DEV(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise AssertionError('Gold source checkout required for three-house tests')

    def check_mutation(self, path, original, changed, expected):
        src=(ROOT/path).read_text()
        self.assertEqual(src.count(original),1, 'mutation must hit exactly one real source anchor')
        failures=audit(ROOT,GOLD,{path:src.replace(original,changed,1)})
        self.assertTrue(any(expected in issue for issue in failures), failures)

    def test_gold_three_house_full_contract(self):
        self.assertEqual(audit(ROOT,GOLD),[])

    def test_reject_missing_actual_native_warp_resolver(self):
        self.check_mutation('engine/overworld/region_map_lookup.asm',
                            'db JOHTO_CHERRYGROVE_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID',
                            'db JOHTO_ROUTE_29_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID',
                            'native city→room Warp target missing')

    def test_reject_missing_real_collision_call(self):
        self.check_mutation('home/overworld.asm',
                            'callba JohtoCherrygroveHouseDoorStepAllowed',
                            'callba JohtoRoute29GateStepAllowed',
                            'live native city collision path')

    def test_reject_missing_matched_warp_direct_transfer(self):
        self.check_mutation('home/overworld.asm',
                            'pop bc\n\tpop hl\n\tjp WarpFound1\n.otherJohtoPortals',
                            'pop bc\n\tpop hl\n\tjp CheckMapConnections\n.otherJohtoPortals',
                            'live native Cherrygrove Warp must transfer')

    def test_reject_wrong_collision_check_order(self):
        code=(ROOT/'home/overworld.asm').read_text()
        old='\tcallba JohtoCherrygroveHouseDoorStepAllowed\n\tjp c, .noCollision\n.ordinaryTilePair'
        new='\tcallba JohtoCherrygroveHouseDoorStepAllowed\n\tand a\n.ordinaryTilePair'
        self.assertEqual(code.count(old),1)
        issues=audit(ROOT,GOLD,{'home/overworld.asm':code.replace(old,new,1)})
        self.assertTrue(any('live native city collision path' in i for i in issues),issues)

    def test_reject_wrong_outdoor_arrival_handle(self):
        self.check_mutation('engine/overworld/region_map_lookup.asm',
                            'db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 9, 25, REGION_NATIVE_MAP_SLOT, D_DOWN',
                            'db JOHTO_CHERRYGROVE_CITY, JOHTO_CHERRYGROVE_LOCAL_ID, 9, 25, REGION_NATIVE_MAP_SLOT, D_DOWN',
                            'outdoor arrival must match native Cherrygrove $FC/local 2')

    def test_gold_front_doors_execute_only_on_correct_approach(self):
        from johto_gatehouse_behavior_audit import predicate
        src=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        # The native $FC/local 2 outside Warp branch is checked in the source-order audit.
        for (x,y) in ((17,8),(25,10),(31,12)):
            for dx,dy in ((0,0),(-1,0),(1,0),(0,1)):
                for facing in ('UP','DOWN','LEFT','RIGHT'):
                    with self.subTest(x=x+dx,y=y+dy,facing=facing):
                        result=predicate(src,'JohtoCherrygroveHouseDoorStepAllowed',
                            'JOHTO_CHERRYGROVE_LOCAL_ID',x+dx,y+dy,facing,
                            {'JOHTO_CHERRYGROVE_LOCAL_ID':2})
                        self.assertEqual(result,dx==0 and dy==0 and facing=='UP')

    def test_reject_wrong_city_guide_house_door(self):
        self.check_mutation('data/mapObjects/JohtoCherrygroveCity.asm',
                            'db 9, 25, 0, REGION_WARP_ESCAPE',
                            'db 9, 26, 0, REGION_WARP_ESCAPE', 'city Warps')

    def test_reject_wrong_evolution_return_lane(self):
        self.check_mutation('engine/overworld/region_map_lookup.asm',
                            'db JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID, 1, 2, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID',
                            'db JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID',
                            'resolver wrong lane')

    def test_reject_bug_catcher_as_item_object(self):
        self.check_mutation('data/mapObjects/JohtoCherrygroveGymSpeechHouse.asm',
                            'object SPRITE_JOHTO_BUG_CATCHER_RED, 5, 5, WALK, 2, 2',
                            'object SPRITE_JOHTO_BUG_CATCHER_RED, 5, 5, WALK, 2, 2, 2',
                            'macro MUST have 6 args')

    def test_reject_lass_recolored_red(self):
        self.check_mutation('color/sprites.asm',
                            '; SPRITE_JOHTO_LASS_GREEN: Gold EvolutionSpeechHouse lass\n\tdb PAL_OW_GREEN',
                            '; SPRITE_JOHTO_LASS_GREEN: Gold EvolutionSpeechHouse lass\n\tdb PAL_OW_RED',
                            'must be Gold green')

    def test_reject_slot_changed_but_header_length_still_valid(self):
        self.check_mutation('data/johto_map_headers.asm',
                            'dw JohtoGuideGentsHouse_h ; stable JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID -> slot 53',
                            'dw JohtoGuideGentsHouse_h ; stable JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID -> slot 52',
                            'active header slot')

    def test_reject_green_lass_12_tile_classification_removed(self):
        self.check_mutation('engine/overworld/map_sprites.asm',
                            'cp a, SPRITE_JOHTO_LASS_GREEN',
                            'cp a, SPRITE_BLACK_HAIR_BOY_1',
                            'classified as 12-tile')

if __name__=='__main__': unittest.main()
