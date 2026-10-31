"""MAP-283: inject the regressions that previously passed superficial audits."""
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_route35_runtime_audit_283 import audit

class Route35LiveContractTests(unittest.TestCase):
    def assertReject(self, path, old, new, expected):
        src=(ROOT/path).read_bytes() if isinstance(old,bytes) else (ROOT/path).read_text()
        self.assertIn(old,src)
        changed=src.replace(old,new,1)
        self.assertNotEqual(src,changed)
        result=audit(ROOT,changes={path:changed})
        self.assertEqual('FAIL',result['status'])
        self.assertIn(expected,result['errors'])

    def test_live_23_map_route_and_gate_pass(self):
        result=audit(ROOT)
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result['errors'])
        self.assertGreaterEqual(len(result['checks']),23)
        self.assertFalse(result['rom_built'])
        self.assertFalse(result['phone_accepted'])

    def test_reject_284_old_gateway_missing_new_maps(self):
        path='engine/johto_land_collision_gateway_272.asm'
        text=(ROOT/path).read_text()
        faulty='''    ld a, [wCurLocalMapID]
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
'''
        self.assertReject(path,
            '    ld a, [wCurLocalMapID]\n    cp JOHTO_ROUTE_35_LOCAL_ID',
            faulty.rstrip('\n'),
            'route35_and_north_gate_reachable_in_land_gateway')

    def test_reject_route35_only_without_new_gate(self):
        self.assertReject('engine/johto_land_collision_gateway_272.asm',
            'cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
            'cp JOHTO_ROUTE_36_LOCAL_ID',
            'route35_and_north_gate_reachable_in_land_gateway')

    def test_reject_wrong_road_as_active(self):
        self.assertReject('engine/johto_land_collision_gateway_272.asm',
            'cp JOHTO_ROUTE_35_LOCAL_ID',
            'cp JOHTO_ROUTE_36_LOCAL_ID',
            'route35_and_north_gate_reachable_in_land_gateway')

    def test_reject_fallthrough_into_route33(self):
        self.assertReject('engine/johto_land_collision_gateway_272.asm',
            '.activeSouthMap\n    ; The accepted ledge handler',
            '.activeSouthMapBROKEN\n    ; The accepted ledge handler',
            'route35_and_north_gate_reachable_in_land_gateway')

    def test_reject_wrong_route35_gold_trees(self):
        path='maps/johto_pilot/Route35.runtime.blk'
        data=(ROOT/path).read_bytes()
        self.assertReject(path,data[:1],bytes([data[0]^1]),'original_route35_180_block_bytes')

    def test_reject_wrong_gate_layout(self):
        path='maps/johto_pilot/Route35GoldenrodGate.mature.blk'
        data=(ROOT/path).read_bytes()
        self.assertReject(path,data[:1],bytes([data[0]^1]),'mature_gate_byte_length_and_shared_gold')

    def test_reject_incorrect_road_tileset(self):
        self.assertReject('data/johto_north_runtime_283.asm','    db JOHTO_PILOT ; Gold TILESET_JOHTO',
                          '    db JOHTO_MODERN ; wrong visual metatiles',
                          'route35_has_correct_gold_tileset_and_closed_north')

    def test_reject_bad_route36_connection(self):
        self.assertReject('data/johto_north_runtime_283.asm',
                          'db NORTH ; Gold north -> existing Route36, offset 0',
                          'db 0 ; damaged Route36 connection',
                          'route35_has_correct_gold_tileset_and_closed_north')

    def test_reject_missing_south_gate_carpet(self):
        self.assertReject('data/johto_north_runtime_283.asm',
                          'db 33, 10, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                          'db 33, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                          'route35_exact_south_two_warps_only')

    def test_reject_warp_in_wrong_direction(self):
        self.assertReject('engine/johto_south_portals.asm',
                          '.route35South\n    cp PLAYER_DIR_DOWN',
                          '.route35South\n    cp PLAYER_DIR_RIGHT',
                          'route35_collision_only_down_exit')

    def test_reject_cut_cell_passthrough(self):
        self.assertReject('engine/johto_south_geometry.asm',
                          'cp 17\n    jr nz, .notClearedForestCut',
                          'cp 18\n    jr nz, .notClearedForestCut',
                          'cut_cleared_block_check_with_same_cell')

    def test_reject_missing_surf_role_grid(self):
        self.assertReject('engine/johto_south_geometry.asm',
                          'JohtoNorthRoute35Roles:: INCBIN "maps/johto_pilot/Route35.roles.bin"',
                          'JohtoNorthRoute35Roles:: INCBIN "maps/johto_pilot/Route34.roles.bin"',
                          'route35_role_grid_dispatch_and_surf_water_probe')

    def test_reject_gate_wrong_audio_source(self):
        self.assertReject('engine/johto_pilot_runtime.asm',
                          '    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID\n    jp z, .route35GoldenrodGate',
                          '    cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID\n    jp z, .route35GoldenrodGate',
                          'gate_music_inherited_and_bike_safe')

    def test_reject_software_version_out_of_sync(self):
        self.assertReject('data/game_version.asm','FIX-5.62.290','FIX-5.62.284',
                          'actual_game_version_and_active_count')

if __name__=='__main__':
    unittest.main()

# FIX-284: phone/video regressions must be caught by the active runtime
# auditor, not only by Gold source-file matching or warp-count checks.
class Route35Gate284RegressionTests(unittest.TestCase):
    def assertRejected(self, path, old, new, check):
        source=(ROOT/path).read_text()
        self.assertIn(old,source)
        mutated=source.replace(old,new,1)
        self.assertNotEqual(source,mutated)
        result=audit(ROOT,changes={path:mutated})
        self.assertEqual('FAIL',result['status'],result)
        self.assertIn(check,result['errors'])

    def test_reject_city_to_wrong_north_gate_warp_slot(self):
        self.assertRejected('data/johto_south_runtime.asm',
            'db 1, 19, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 1, 19, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'route35_gate_runtime_destination_ordinals_exact')

    def test_reject_gate_south_to_unregistered_city_slot(self):
        for row, bad in (('db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR'),
                         ('db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 7, 5, 3, JOHTO_REGISTERED_WARP_SELECTOR')):
            self.assertRejected('data/johto_north_runtime_283.asm',row,bad,
                                'route35_gate_runtime_destination_ordinals_exact')

    def test_reject_loss_of_south_buffer_dispatch(self):
        self.assertRejected('engine/johto_ilex_mature_runtime_275.asm',
            '    jp PatchJohtoRoute35SouthBorder',
            '    ret ; erroneously drop south border',
            'route35_south_preview_after_both_map_loading_paths')

    def test_reject_corrupt_cross_tileset_border_blocks(self):
        self.assertRejected('engine/johto_ilex_mature_runtime_275.asm',
            'db $12, $15, $01, $46, $16, $1e, $44, $01, $01, $12',
            'db $12, $15, $01, $46, $06, $1e, $44, $01, $01, $12',
            'route35_south_exact_gold_compatible_3x10_preview')

    def test_park_entry_is_now_active_but_south_gate_carpet_stays_safe(self):
        # Gold Park entrance is activated in MAP-286, not a sealed building.
        source=(ROOT/'engine/johto_south_geometry.asm').read_text()
        self.assertNotIn('    db JOHTO_ROUTE_35_LOCAL_ID, 3, 5\n',source)
        self.assertNotIn('    db JOHTO_ROUTE_35_LOCAL_ID, 9, 33\n',source)
        self.assertEqual('PASS_STATIC_ONLY', audit(ROOT)['status'])

    def test_reject_reversing_arrival_auto_step(self):
        self.assertRejected('engine/johto_south_portals.asm',
            '.cityDoor\n    ld a, [wXCoord]\n    cp 19',
            '.cityDoor\n    ld a, [wXCoord]\n    cp 18',
            'route35_gate_arrival_and_carpet_trigger_distinct')

    def test_accepted_gold_warp_ordinals_and_safe_viewport(self):
        report=audit(ROOT)
        self.assertEqual('PASS_STATIC_ONLY',report['status'],report['errors'])
        self.assertTrue(any(x['check']=='route35_gate_runtime_destination_ordinals_exact'
                            and x['status']=='PASS' for x in report['checks']))
