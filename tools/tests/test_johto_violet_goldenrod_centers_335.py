"""REF-335 new centers: positive Gold invariants and negative fault injections."""
import sys
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_violet_goldenrod_centers_335_audit import audit

class NewCenters335(unittest.TestCase):
    def mutate(self,p,old,new):
        s=(ROOT/p).read_text()
        self.assertIn(old,s)
        return {p:s.replace(old,new,1)}
    def reject(self,p,old,new,check):
        data=self.mutate(p,old,new)
        report=audit(ROOT,overrides=data)
        self.assertIn(check,report['errors'],(check,report['errors']))
    def test_current_source_passes(self):
        result=audit(ROOT)
        self.assertEqual(result['status'],'PASS_STATIC_ONLY',result['errors'])
        self.assertGreaterEqual(len(result['checks']),10)
    def test_wrong_violet_warp_target_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
            'JOHTO_VIOLET_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID',
            'JOHTO_VIOLET_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID',
            'six_exact_reciprocal_warps')
    def test_wrong_goldenrod_return_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
            'JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID',
            'JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID',
            'six_exact_reciprocal_warps')
    def test_wrong_gold_center_asset_rejected(self):
        self.reject('data/johto_pilot_source_resources.asm',
            'JohtoVioletPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/VioletPokecenter1F.gold.blk"',
            'JohtoVioletPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/AzaleaPokecenter1F.gold.blk"',
            'same_gold_5x4_room_no_2f')
    def test_goldenrod_entrance_collision_rejected(self):
        self.reject('engine/johto_south_portals.asm',
            '.goldenrodCenterArrival\n    ld a, [wYCoord]', '.badCenterArrival\n    ld a, [wYCoord]',
            'goldenrod_up_only_and_north_gate_preserved')
    def test_fly_count_cannot_grow(self):
        self.reject('engine/johto_pilot_fly_map.asm',
            'DEF JOHTO_FLY_TOWN_COUNT EQU 11','DEF JOHTO_FLY_TOWN_COUNT EQU 12',
            'fly_is_existing_town_only')
    def test_goldenrod_map_landmark_not_route36(self):
        self.reject('engine/fly_town_map_helpers.asm',
            'db 15 ; slot51 Goldenrod Center', 'db 19 ; slot51 Goldenrod Center',
            'map_and_music_no_new_fly_landmark')
    def test_nurse_cannot_disappear(self):
        self.reject('engine/johto_shared_pokecenter.asm',
            'JohtoGoldenrodPokecenterRuntimeObjects::', 'JohtoWrongPokecenterRuntimeObjects::',
            'two_independent_nurse_objects')
    def test_existing_north_gatehouse_not_lost(self):
        self.reject('engine/johto_pilot_runtime.asm',
            'JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
            'JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID',
            'goldenrod_two_existing_gatehouses_preserved')
    def test_treatment_stamps_source_id(self):
        self.reject('engine/johto_gold_healing_machine_337.asm',
            'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a',
            'ld a, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ld [wJohtoLastHealLocalID], a',
            'success_stamps_correct_center')
    def test_violet_door_position_cannot_change(self):
        self.reject('data/johto_pilot_map_headers.asm',
            'db 25, 31, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 24, 31, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'gold_exterior_objects')

if __name__=='__main__': unittest.main()
