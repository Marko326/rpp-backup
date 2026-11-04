"""DEV-334: negative source fault injection on Center maps/heal/warp guards."""
import shutil
import tempfile
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
try:
    from tools.johto_pokecenter_334_audit import audit
except ImportError:
    from johto_pokecenter_334_audit import audit

ROOT=Path(__file__).resolve().parents[2]
SOURCES=[
 'engine/johto_shared_pokecenter.asm',
 'engine/johto_land_collision_gateway_272.asm',
 'engine/johto_pilot_runtime.asm',
 'data/johto_pilot_map_headers.asm',
 'data/johto_stable_id_slots.asm',
 'wram.asm',
 'engine/overworld/set_blackout_map.asm',
 'home/overworld.asm',
 'engine/town_map.asm',
 'data/johto_header_descriptors.asm',
 'data/johto_pilot_runtime_assets.asm',
 'engine/fly_town_map_helpers.asm',
 'constants/region_map_constants.asm',
 'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',
 'engine/overworld/healing_machine.asm', 'engine/overworld/pokecenter.asm',
 'engine/johto_gold_healing_machine_337.asm',
 'data/johto_pilot_source_resources.asm',
 'maps/johto_pilot/CherrygrovePokecenter1F.gold.blk',
 'engine/menu/options_menu.asm',
]

class Pokecenter334Tests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        for rel in SOURCES:
            out=self.root/rel;out.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/rel,out)
    def corrupt(self,rel,old,new,fail):
        p=self.root/rel;s=p.read_text();self.assertIn(old,s);p.write_text(s.replace(old,new,1))
        report=audit(self.root)
        self.assertIn(fail,report['errors'],report)
    def test_accept_valid_shared_center(self):
        r=audit(self.root)
        self.assertEqual(r['status'],'PASS_STATIC_ONLY',r['errors'])
        self.assertEqual(len(r['checks']),13)
        self.assertFalse(r['rom_built'])
    def test_wrong_city_center_warp_coordinate(self):
        self.corrupt('data/johto_pilot_map_headers.asm',
                     'db 3, 29, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                     'db 3, 30, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                     'city_two_independent_doors')
    def test_new_center_missing_return_route(self):
        self.corrupt('engine/johto_pilot_runtime.asm',
                     'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID',
                     'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_NEW_BARK_LOCAL_ID',
                     'three_exact_registered_warps')
    def test_nurse_script_not_a_dummy(self):
        self.corrupt('engine/johto_shared_pokecenter.asm',
                     'TX_POKECENTER_NURSE','TX_FAR',
                     'nurse_shared_healing')
    def test_room_exit_index_cannot_point_to_guide_house(self):
        self.corrupt('engine/johto_shared_pokecenter.asm',
                     'db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                     'db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                     'nurse_shared_healing')
    def test_no_extra_collision_bypass(self):
        self.corrupt('engine/johto_land_collision_gateway_272.asm',
                     'cp 4 ; approach Gold Pokecenter door',
                     'cp 5 ; approach Gold Pokecenter door',
                     'land_exact_up_approach')
    def test_must_immediately_enter_on_up(self):
        self.corrupt('engine/johto_pilot_runtime.asm',
                     'ld e, 2\n    ret\n.verticalGateDispatch314',
                     'ld e, 1\n    ret\n.verticalGateDispatch314',
                     'warp_actual_immediate_entry')
    def test_wrong_current_region_must_not_write_saved_heal(self):
        self.corrupt('engine/johto_gold_healing_machine_337.asm',
                     'ld [wJohtoLastHealMagic], a','ld [wLastBlackoutMap], a',
                     'healing_only_after_yes_animation')
    def test_invalid_healing_place_does_not_overwrite_kanto(self):
        self.corrupt('engine/johto_gold_healing_machine_337.asm',
                     'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID',
                     'cp JOHTO_CHERRYGROVE_LOCAL_ID',
                     'healing_only_after_yes_animation')
    def test_legacy_kanto_blackout_restored(self):
        self.corrupt('engine/johto_shared_pokecenter.asm',
                     'ld [wLastBlackoutMap], a',
                     'ld [wCurLocalMapID], a',
                     'kanto_healing_preserved')
    def test_old_save_requires_magic(self):
        self.corrupt('engine/johto_pilot_runtime.asm',
                     'cp JOHTO_LAST_HEAL_MAGIC',
                     'cp $00',
                     'town_start_heal_or_player_fallback')
    def test_town_map_fallback_is_not_teleport(self):
        self.corrupt('engine/johto_pilot_runtime.asm',
                     'jp JohtoPilotGetTownMapLandmark',
                     'jp SoftReset',
                     'town_start_heal_or_player_fallback')
    def test_shared_graphic_not_individual_copy(self):
        self.corrupt('engine/johto_shared_pokecenter.asm',
                     'INCBIN "maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk"',
                     'INCBIN "maps/SomeNewCopy.blk"',
                     'shared_gold_template')
    def test_gsc_center_music_not_city_music(self):
        self.corrupt('engine/menu/options_menu.asm',
                     'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot47 interior center tune',
                     'db MUSIC_GBP_GSC_CHERRYGROVE_CITY ; slot47 interior center tune',
                     'profile_music_and_map_labels')

if __name__=='__main__':unittest.main()
