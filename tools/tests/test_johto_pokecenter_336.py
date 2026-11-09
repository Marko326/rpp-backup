"""DEV-336 fail-closed tests: exact counter, safe walls, and dual carpets."""
from pathlib import Path
import shutil, tempfile, unittest, sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_pokecenter_336_audit import audit

ROOT=Path(__file__).resolve().parents[2]
FILES=('data/tileset_headers.asm','data/warp_tile_ids.asm',
 'engine/johto_shared_pokecenter.asm','engine/johto_pilot_runtime.asm',
 'data/johto_vertical_gate_runtime_314.asm','home/overworld.asm',
 'engine/johto_pilot_warp_tiles.asm','data/mapObjects/ViridianPokecenter.asm',
 'engine/overworld/doors.asm','engine/fly_town_map_helpers.asm','data/game_version.asm',
 'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',
 'gfx/blocksets/johto_shared_pokecenter.bst')

class GoldCenter336(unittest.TestCase):
    def setUp(self):
        d=tempfile.TemporaryDirectory();self.addCleanup(d.cleanup);self.root=Path(d.name)
        for f in FILES:
            p=self.root/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/f,p)
    def mutate(self,rel,old,new,expected):
        p=self.root/rel;s=p.read_text();self.assertIn(old,s);p.write_text(s.replace(old,new,1))
        self.assertIn(expected,audit(self.root)['errors'])
    def mutate_section(self,rel,start,end,old,new,expected):
        p=self.root/rel;s=p.read_text()
        before,tail=s.split(start,1);body,after=tail.split(end,1)
        self.assertIn(old,body)
        p.write_text(before+start+body.replace(old,new,1)+end+after)
        self.assertIn(expected,audit(self.root)['errors'])
    def test_all_source_guards_valid(self):
        r=audit(self.root)
        self.assertEqual(r['status'],'PASS_STATIC_ONLY',r)
        self.assertEqual(len(r['checks']),14)
    def test_missing_counter_tag_breaks_nurse_dialogue(self):
        self.mutate('data/tileset_headers.asm',
                    'Pokecenter_Coll, $15,$FF,$FF',
                    'Pokecenter_Coll, $FF,$FF,$FF',
                    'counter_registered_for_long_range_A')
    def test_wrong_counter_tile_breaks_nurse_dialogue(self):
        self.mutate('data/tileset_headers.asm',
                    'Pokecenter_Coll, $15,$FF,$FF',
                    'Pokecenter_Coll, $1d,$FF,$FF',
                    'counter_registered_for_long_range_A')
    def test_missing_ID37_pointer_is_out_of_bounds(self):
        self.mutate('data/warp_tile_ids.asm','    dw JohtoPokecenterWarpTileIDs ; ID37: Gold bottom carpets are collision-only','',
                    'all_38_warp_tile_pointer_indices')
    def test_wrong_pointer_index_detected(self):
        self.mutate('data/warp_tile_ids.asm','dw JohtoPokecenterWarpTileIDs ; ID37',
                    'dw JohtoHouseWarpTileIDs ; ID37','all_38_warp_tile_pointer_indices')
    def test_step_on_carpet_must_remain_disabled(self):
        self.mutate('data/warp_tile_ids.asm','JohtoPokecenterWarpTileIDs: db $ff',
                    'JohtoPokecenterWarpTileIDs: db $11','gold_exit_not_generic_step_on')
    def test_warp_entry_must_arm_and_not_trigger_immediately(self):
        self.mutate('engine/johto_pilot_runtime.asm',
                    '.centerCarpetStand\n    ; The warp coordinate has already matched the exact Gold carpet.\n    ; E=1 arms the standing flag but prevents STEP_ON and sideways warp.\n    ld e, 1',
                    '.centerCarpetStand\n    ; The warp coordinate has already matched the exact Gold carpet.\n    ; E=1 arms the standing flag but prevents STEP_ON and sideways warp.\n    ld e, 2',
                    'exact_room_warps_are_stand_only')
    def test_center_exit_not_any_facing(self):
        self.mutate('engine/johto_shared_pokecenter.asm',
                    'cp PLAYER_DIR_DOWN','cp PLAYER_DIR_LEFT',
                    'exit_guard_has_exact_map_direction_and_two_carpet_cells')
    def test_center_exit_only_bottom_row(self):
        self.mutate('engine/johto_shared_pokecenter.asm',
                    'cp 7\n    ret nz\n    ld a, [wXCoord]',
                    'cp 6\n    ret nz\n    ld a, [wXCoord]',
                    'exit_guard_has_exact_map_direction_and_two_carpet_cells')
    def test_center_left_carpet_x3_required(self):
        self.mutate('engine/johto_shared_pokecenter.asm',
                    'cp 3\n    jr z, .allow','cp 2\n    jr z, .allow',
                    'exit_guard_has_exact_map_direction_and_two_carpet_cells')
    def test_center_right_carpet_x4_required(self):
        self.mutate('engine/johto_shared_pokecenter.asm',
                    'cp 4\n    ret nz','cp 5\n    ret nz',
                    'exit_guard_has_exact_map_direction_and_two_carpet_cells')
    def test_no_extra_warp_guard_path(self):
        self.mutate_section('engine/johto_pilot_runtime.asm',
                    'JohtoPilotGateExteriorCollisionAllowed::',
                    'JohtoPilotGateCollisionExitAllowed::',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    jr z, .centerCarpetExit',
                    'cp JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID\n    jr z, .centerCarpetExit',
                    'extra_warp_entry_calls_guard')
    def test_no_final_collision_warp_guard_path(self):
        self.mutate_section('engine/johto_pilot_runtime.asm',
                    'JohtoPilotGateCollisionExitAllowed::',
                    'JohtoBatchCenterDoorBeforeStep336::',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    jr z, .centerCarpetExit',
                    'cp JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID\n    jr z, .centerCarpetExit',
                    'collision_warp_entry_calls_same_guard')
    def test_remove_bounds_profile_reenables_black_border(self):
        self.mutate('data/johto_vertical_gate_runtime_314.asm',
                    '    db JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 10, 8',
                    '    db JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 10, 9',
                    'finite_10x8_Gold_room_boundaries')
    def test_missing_bound_dispatch_reenables_black_border(self):
        self.mutate('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    jp z, .verticalGateClosedEdge314',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    jp nz, .verticalGateClosedEdge314',
                    'live_overworld_collision_calls_room_bounds')
    def test_risky_gfx_edit_is_not_a_facing_fix(self):
        p=self.root/'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk'
        b=bytearray(p.read_bytes());b[6]=0;p.write_bytes(b)
        self.assertIn('gold_front_counter_lower_left_is_15',audit(self.root)['errors'])
    def test_arrival_carpets_must_be_rearmed_after_load(self):
        self.mutate('engine/fly_town_map_helpers.asm',
                    'res 2, [hl]\n    callba IsPlayerStandingOnWarp',
                    'res 2, [hl]\n    nop',
                    'arriving_on_gold_carpet_rearms_collision_only_warp')
    def test_kanto_seafoam_arrival_must_remain_available(self):
        self.mutate('engine/fly_town_map_helpers.asm',
                    'cp SEAFOAM_ISLANDS_1\n\tret nz',
                    'cp ROUTE_20\n\tret nz',
                    'arriving_on_gold_carpet_rearms_collision_only_warp')
    def test_wrong_nurse_location_rejected(self):
        self.mutate('engine/johto_shared_pokecenter.asm',
                    'object SPRITE_NURSE, $3, $1, STAY, DOWN, $1',
                    'object SPRITE_NURSE, $3, $2, STAY, DOWN, $1',
                    'nurse_and_counter_geometry')

if __name__=='__main__':unittest.main()
