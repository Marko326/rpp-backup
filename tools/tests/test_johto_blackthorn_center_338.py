"""REF-338 Blackthorn City Gold center positive and fault-injection regression."""
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_blackthorn_center_338_audit import audit

GOLD=Path('/mnt/data/ref337_review/references/JOHTO_HANDOFF_REF312_REFERENCE_COMPLETE/REFERENCES/Gold/pokegold-master')

class BlackthornCenter338(unittest.TestCase):
    def reject(self,path,old,new,check):
        source=(ROOT/path).read_text()
        self.assertIn(old,source)
        changed=source.replace(old,new,1)
        self.assertNotEqual(changed,source)
        report=audit(ROOT,overrides={path:changed})
        self.assertIn(check,report['errors'],report['errors'])
    def test_current_center_passes(self):
        result=audit(ROOT)
        self.assertEqual(result['errors'],[],result)
        self.assertGreaterEqual(len(result['checks']),11)
    def test_original_gold_door_and_carpets(self):
        if not GOLD.is_dir():self.skipTest('Optional original Gold sources unavailable')
        self.assertEqual(audit(ROOT,GOLD)['errors'],[])
    def test_target_warp_out_of_bounds_rejected(self):
        self.reject('data/johto_blackthorn_runtime_326.asm',
                    'db 29, 21, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 29, 21, 4, JOHTO_REGISTERED_WARP_SELECTOR',
                    'blackthorn_exterior_only_gold_door_destination_zero')
    def test_wrong_right_carpet_arrival_rejected(self):
        self.reject('data/johto_blackthorn_runtime_326.asm',
                    'db 29, 21, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 29, 21, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                    'blackthorn_exterior_only_gold_door_destination_zero')
    def test_second_indoor_exit_wrong_source_ordinal_rejected(self):
        self.reject('engine/johto_shared_pokecenter.asm',
                    'JohtoBlackthornPokecenterRuntimeObjects::\n    db $0f\n    db 2\n    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR\n    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'JohtoBlackthornPokecenterRuntimeObjects::\n    db $0f\n    db 2\n    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR\n    db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                    'two_gold_carpet_room_exits_and_nurse_no_upstairs')
    def test_wrong_exterior_door_coordinate_rejected(self):
        self.reject('data/johto_blackthorn_runtime_326.asm',
                    'db 29, 21, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 29, 20, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'blackthorn_exterior_only_gold_door_destination_zero')
    def test_disabled_door_rejected(self):
        self.reject('data/johto_blackthorn_runtime_326.asm',
                    'db 1 ; only the Gold Pokecenter at (21,29)',
                    'db 0 ; all buildings closed',
                    'blackthorn_exterior_only_gold_door_destination_zero')
    def test_indoor_returns_to_other_city_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
                    'JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID',
                    'JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID',
                    'one_source_three_distinct_routes_and_134_total')
    def test_no_extra_fly_destination_rejected(self):
        self.reject('engine/johto_pilot_fly_map.asm',
                    'DEF JOHTO_FLY_TOWN_COUNT EQU 11',
                    'DEF JOHTO_FLY_TOWN_COUNT EQU 12',
                    'town_map_music_and_fly_existing_row_only')
    def test_wrong_last_heal_fly_row_rejected(self):
        self.reject('engine/johto_pilot_fly_map.asm',
                    '.startBlackthorn\n    ld a, 10 ; existing Blackthorn City Fly row',
                    '.startBlackthorn\n    ld a, 7 ; existing Blackthorn City Fly row',
                    'town_map_music_and_fly_existing_row_only')
    def test_wrong_heal_landmark_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
                    '.blackthornHeal\n    ld e, 39',
                    '.blackthornHeal\n    ld e, 34',
                    'healing_actual_center_id_and_landmark39')
    def test_wrong_entry_direction_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
                    '.blackthorn\n    ld a, [wXCoord]\n    cp 21\n    ret nz\n    ld a, [wYCoord]\n    cp 30',
                    '.blackthorn\n    ld a, [wXCoord]\n    cp 21\n    ret nz\n    ld a, [wYCoord]\n    cp 29',
                    'door_before_step_only_from_below_up')
    def test_gold_asset_size_assert_not_greedy_rejected(self):
        self.reject('data/johto_pilot_source_resources.asm',
                    'ASSERT @ - JohtoBlackthornPokecenterGoldBlocks == 5 * 4',
                    'ASSERT @ - JohtoBlackthornPokecenterGoldBlocks == 5 * 5',
                    'gold_5x4_shared_layout_and_adjacent_size_assert')
    def test_second_nurse_not_allowed(self):
        self.reject('engine/johto_shared_pokecenter.asm',
                    'JohtoBlackthornPokecenterRuntimeObjects::\n    db $0f\n    db 2\n    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR\n    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR\n    db 0 ; PC storage and upstairs still deferred\n    db 1',
                    'JohtoBlackthornPokecenterRuntimeObjects::\n    db $0f\n    db 2\n    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR\n    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR\n    db 0 ; PC storage and upstairs still deferred\n    db 2',
                    'two_gold_carpet_room_exits_and_nurse_no_upstairs')

if __name__=='__main__':unittest.main()
