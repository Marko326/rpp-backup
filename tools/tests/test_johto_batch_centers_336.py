"""REF-336 four-center batch: positive independent Gold and negative mutation tests."""
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_batch_centers_336_audit import audit
GOLD=Path('/mnt/data/ref332_reference_gold/pokegold-master')
class BatchCenters336(unittest.TestCase):
    def reject(self,path,old,new,expected):
        original=(ROOT/path).read_text()
        self.assertIn(old,original)
        report=audit(ROOT,overrides={path:original.replace(old,new,1)})
        self.assertIn(expected,report['errors'],report['errors'])
    def test_current_project_passes(self):
        r=audit(ROOT)
        self.assertEqual(r['status'],'PASS_STATIC_ONLY',r['errors'])
        self.assertGreaterEqual(len(r['checks']),27)
    def test_original_gold_reference_passes(self):
        if not GOLD.is_dir():self.skipTest('Optional original Gold sources unavailable')
        r=audit(ROOT,GOLD)
        self.assertEqual(r['status'],'PASS_STATIC_ONLY',r['errors'])
    def test_misplaced_goldenrod_size_assert_rejected(self):
        # Reproduce the real REF-336 assembly failure: 5 * 20 bytes are
        # measured by one old 5 * 4 assertion placed after four more maps.
        path='data/johto_pilot_source_resources.asm'
        source=(ROOT/path).read_text()
        line='ASSERT @ - JohtoGoldenrodPokecenterGoldBlocks == 5 * 4\n'
        self.assertEqual(source.count(line),1)
        broken=source.replace(line,'',1).replace(
            'JohtoPilotSourceRecords::',line+'JohtoPilotSourceRecords::',1)
        report=audit(ROOT,overrides={path:broken})
        self.assertIn('all_ten_gold_center_size_asserts_immediately_follow_own_blob',report['errors'])
    def test_missing_cianwood_size_assert_rejected(self):
        self.reject('data/johto_pilot_source_resources.asm',
            'ASSERT @ - JohtoCianwoodPokecenterGoldBlocks == 5 * 4',
            'ASSERT @ - JohtoCianwoodPokecenterGoldBlocks == 5 * 5',
            'all_ten_gold_center_size_asserts_immediately_follow_own_blob')
    def test_wrong_ecruteak_warp_target_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
            'JOHTO_ECRUTEAK_CITY_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID',
            'JOHTO_ECRUTEAK_CITY_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID',
            'Ecruteak_independent_bidirectional_gold_warps')
    def test_game_version_is_bumped_for_runtime_fix(self):
        version=(ROOT/'data/game_version.asm').read_text()
        self.assertIn('Canonical project version REF-5.62.338',version)
        self.assertIn('db "REF-338@"',version)
        self.assertNotIn('db "REF-336@"',version)
    def test_ecruteak_entry_uses_left_carpet(self):
        path='data/johto_corridor_runtime_294.asm'
        source=(ROOT/path).read_text()
        self.assertIn('db 27, 23, 0, JOHTO_REGISTERED_WARP_SELECTOR',source)
        self.assertIn('JOHTO_ECRUTEAK_CITY_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID',
                      (ROOT/'engine/johto_pilot_runtime.asm').read_text())
        self.reject(path,'db 27, 23, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 27, 23, 4, JOHTO_REGISTERED_WARP_SELECTOR',
                    'ecruteak_entry_targets_left_center_carpet_warp_zero')
    def test_mahogany_entry_uses_left_carpet(self):
        path='data/johto_east_runtime_300.asm'
        source=(ROOT/path).read_text()
        self.assertIn('db 13, 15, 0, JOHTO_REGISTERED_WARP_SELECTOR',source)
        self.assertIn('JOHTO_MAHOGANY_TOWN_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID',
                      (ROOT/'engine/johto_pilot_runtime.asm').read_text())
        self.reject(path,'db 13, 15, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 13, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                    'mahogany_entry_targets_left_center_carpet_warp_zero')
    def test_wrong_cianwood_return_warp_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
            'JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID',
            'JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID',
            'Cianwood_independent_bidirectional_gold_warps')
    def test_wrong_olivine_door_coordinate_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
            '.olivine\n    ld a, [wXCoord]\n    cp 13\n    ret nz\n    ld a, [wYCoord]\n    cp 21',
            '.olivine\n    ld a, [wXCoord]\n    cp 12\n    ret nz\n    ld a, [wYCoord]\n    cp 21',
            'Olivine_only_up_exact_exterior_door')
    def test_wrong_mahogany_heal_landmark_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
            '.mahoganyHeal\n    ld e, 34', '.mahoganyHeal\n    ld e, 21',
            'Mahogany_healing_and_bounds_and_fly_mapping')
    def test_growing_fly_list_rejected(self):
        self.reject('engine/johto_pilot_fly_map.asm',
            'DEF JOHTO_FLY_TOWN_COUNT EQU 11','DEF JOHTO_FLY_TOWN_COUNT EQU 12',
            'frozen_57_maps_and_no_extra_fly_stops')
    def test_nurse_removed_rejected(self):
        self.reject('engine/johto_shared_pokecenter.asm',
            'JohtoCianwoodPokecenterRuntimeObjects::','JohtoChangedPokecenterRuntimeObjects::',
            'Cianwood_room_resource_header_nurse')
    def test_olivine_fly_row_change_rejected(self):
        self.reject('engine/johto_pilot_fly_map.asm',
            '.startOlivine\n    ld a, 6 ; existing Olivine Fly row',
            '.startOlivine\n    ld a, 7 ; existing Olivine Fly row',
            'Olivine_healing_and_bounds_and_fly_mapping')
    def test_wrong_success_stamp_rejected(self):
        self.reject('engine/johto_gold_healing_machine_337.asm',
            'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a',
            'ld a, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ld [wJohtoLastHealLocalID], a',
            'nurse_records_real_local_id_after_success')
    def test_existing_gate_warp_cannot_be_overwritten(self):
        self.reject('engine/johto_pilot_runtime.asm',
            'JOHTO_ROUTE_35_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
            'JOHTO_ROUTE_35_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID',
            'old_five_ids_and_legacy_gatehouse_preserved')
if __name__=='__main__':unittest.main()
