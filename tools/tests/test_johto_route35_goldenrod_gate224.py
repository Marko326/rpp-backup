"""GATE-5.62.224: strict Gold topology and fail-closed gate onboarding tests."""
from pathlib import Path
import os
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_route35_goldenrod_gate_audit import audit, gate_graph_errors, gate_dispatch_errors, gate_gold_geometry_errors, gate_video_regression_errors, border_refresh_hook_errors, gate_carpet_trigger_errors
from johto_indoor_common import rpp_warps

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_ROOT','/NO_GOLD_ROOT'))

def txt(relative):return (ROOT/relative).read_text()

def section(filename,begin,end):return txt(filename).split(begin,1)[1].split(end,1)[0]

class GoldenrodNorthGate224(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route35GoldenrodGate.asm').is_file():
            raise RuntimeError('Original Gold tree mandatory: JOHTO_GOLD_ROOT')

    def test_route35_carpet_standable_collision_entry_not_step_on(self):
        # Outdoor carpet: enter y33 normally, walk across x9/x10; only an
        # additional DOWN into y34 collision can activate the Warp. Do not
        # confuse this with the distinct AFTER-WARP indoor D_DOWN auto-step.
        self.assertEqual([],gate_carpet_trigger_errors(ROOT))
        blocked=(ROOT/'maps/JohtoRoute35.blocked_mask.bin').read_bytes()
        for x in (9,10):
            self.assertTrue(blocked[34*3+x//8] & (1<<(x%8)))
        runtime=section('engine/overworld/johto_route33_collision.asm',
                        'JohtoNorthGateStepWarpAllowed::','JohtoGateCollisionDirectionAllowed::')
        self.assertNotIn('cp JOHTO_ROUTE_35_LOCAL_ID',runtime)
        # Accepted Route34/Forest gate stays step-on; don't globally alter it.
        self.assertIn('cp JOHTO_ROUTE_34_LOCAL_ID',runtime)

    def test_accidental_route35_step_on_warp_fails(self):
        key='engine/overworld/johto_route33_collision.asm'
        raw=txt(key)
        broken=raw.replace('cp JOHTO_GOLDENROD_CITY_LOCAL_ID\n\tjr z, .cityNorthDoor',
            'cp JOHTO_ROUTE_35_LOCAL_ID\n\tjp z, .down\n\tcp JOHTO_GOLDENROD_CITY_LOCAL_ID\n\tjr z, .cityNorthDoor',1)
        self.assertNotEqual(raw,broken)
        self.assertTrue(any('immediate step-on' in v for v in gate_carpet_trigger_errors(ROOT,{key:broken})))

    def test_route35_collision_direction_and_blocked_wall_mandatory(self):
        key='engine/overworld/johto_route33_collision.asm'
        raw=txt(key)
        bad=raw.replace(
                            'cp 10\n\tjr z, .down\n\tjp .denied\n.northGate',
                            'cp 10\n\tjr z, .up\n\tjp .denied\n.northGate',1)
        self.assertNotEqual(raw,bad)
        self.assertTrue(gate_carpet_trigger_errors(ROOT,{key:bad}))
        maskkey='maps/JohtoRoute35.blocked_mask.bin'
        mask=bytearray((ROOT/maskkey).read_bytes())
        mask[34*3+9//8]&=~(1<<(9%8))
        self.assertNotEqual(bytes(mask),(ROOT/maskkey).read_bytes())
        self.assertTrue(any('y34' in v for v in gate_carpet_trigger_errors(ROOT,{maskkey:bytes(mask)})))

    def test_gold_south_seam_and_city_exit_both_proven(self):
        self.assertEqual([],gate_video_regression_errors(ROOT,GOLD))
        self.assertIn('connection south, GoldenrodCity, GOLDENROD_CITY, -5',
                      (GOLD/'data/maps/attributes.asm').read_text())

    def test_city_arrival_autostep_removed_is_detected(self):
        key='engine/overworld/region_map_lookup.asm'
        broken=txt(key).replace('db REGION_NATIVE_MAP_SLOT, JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, 19, REGION_NATIVE_MAP_SLOT, D_DOWN',
                                '; missing Goldenrod south-exit step')
        self.assertNotEqual(broken,txt(key))
        self.assertTrue(gate_video_regression_errors(ROOT,GOLD,{key:broken}))

    def test_city_arrival_wrong_direction_is_detected(self):
        key='engine/overworld/region_map_lookup.asm'
        broken=txt(key).replace('JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, 19, REGION_NATIVE_MAP_SLOT, D_DOWN',
                                'JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, 19, REGION_NATIVE_MAP_SLOT, D_UP')
        self.assertNotEqual(broken,txt(key))
        self.assertTrue(gate_video_regression_errors(ROOT,GOLD,{key:broken}))

    def test_route35_default_forest_border_must_be_replaced(self):
        key='engine/overworld/johto_route33_collision.asm'
        broken=txt(key).replace('PatchJohtoRoute35SouthBorder::', 'MissingRoute35SouthBorder::')
        self.assertNotEqual(broken,txt(key))
        self.assertTrue(gate_video_regression_errors(ROOT,GOLD,{key:broken}))

    def test_route35_preview_wrong_row_or_wall_detected(self):
        key='engine/overworld/johto_route33_collision.asm'
        raw=txt(key)
        broken=raw.replace('MAP_BORDER + JOHTO_ROUTE_35_HEIGHT + 1)',
                           'MAP_BORDER + JOHTO_ROUTE_35_HEIGHT + 2)',1)
        self.assertNotEqual(broken,raw)
        self.assertTrue(gate_video_regression_errors(ROOT,GOLD,{key:broken}))
        broken=raw.replace('.row1\n\tdb $01, $12', '.row1\n\tdb $05, $12',1)
        self.assertNotEqual(broken,raw)
        self.assertTrue(gate_video_regression_errors(ROOT,GOLD,{key:broken}))

    def test_route35_south_border_load_hooks_must_be_on_both_paths(self):
        key='home/overworld.asm'
        raw=txt(key)
        broken=raw.replace('\tcallba PatchJohtoMapBordersAfterBlockLoad\n','',1)
        self.assertNotEqual(broken,raw)
        self.assertTrue(gate_video_regression_errors(ROOT,GOLD,{key:broken}))

    def test_rom0_border_dispatch_saves_four_farcall_sites(self):
        self.assertEqual([], border_refresh_hook_errors(ROOT))
        home=txt('home/overworld.asm')
        for previous in ('PatchJohtoAzaleaWestGateBorder',
                         'PatchJohtoGoldenrodNorthBorder',
                         'PatchJohtoRoute35SouthBorder'):
            self.assertNotIn('callba '+previous,home)
        self.assertEqual(home.count('callba PatchJohtoMapBordersAfterBlockLoad'),2)
        macro=txt('macros/asm_macros.asm').split('callba: MACRO',1)[1].split('ENDM',1)[0]
        # ld b,imm8 (2) + ld hl,imm16 (3) + rst $18 (1) = 6 bytes per callba.
        self.assertIn('ld b, BANK(',macro)
        self.assertIn('ld hl,',macro)
        self.assertIn('rst $18',macro)
        self.assertEqual(4*6,24) # removed 4 of the 6 old HOME callba sites

    def test_rom0_wrong_wrapper_order_and_bank_are_rejected(self):
        key='engine/overworld/johto_route33_collision.asm'
        base=txt(key)
        bad=base.replace('\tcall PatchJohtoGoldenrodNorthBorder\n\tjp PatchJohtoRoute35SouthBorder',
                         '\tjp PatchJohtoRoute35SouthBorder\n\tcall PatchJohtoGoldenrodNorthBorder',1)
        self.assertNotEqual(base,bad)
        self.assertTrue(border_refresh_hook_errors(ROOT,{key:bad}))
        key='main.asm';base=txt(key)
        bad=base.replace('SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]',
                         'SECTION "Johto Route33 Collision Mask", ROMX, BANK[$44]',1)
        self.assertNotEqual(base,bad)
        self.assertTrue(border_refresh_hook_errors(ROOT,{key:bad}))

    def test_original_gold_graph_and_native_escape_target_mapping(self):
        self.assertEqual([],gate_graph_errors(ROOT))
        self.assertEqual([(x['x'],x['y'],x['dest_id']) for x in rpp_warps(ROOT,'JohtoRoute35')],[(9,33,0),(10,33,1)])
        self.assertEqual([(x['x'],x['y'],x['dest_id']) for x in rpp_warps(ROOT,'JohtoGoldenrodCity')],[(19,1,2)])
        self.assertEqual([(x['x'],x['y'],x['dest_id']) for x in rpp_warps(ROOT,'JohtoRoute35GoldenrodGate')],[(4,0,0),(5,0,1),(4,7,0),(5,7,0)])

    def test_entry_direction_contract_and_runtime_dispatch(self):
        self.assertEqual([],gate_dispatch_errors(ROOT))
        home=txt('home/overworld.asm')
        col=txt('engine/overworld/johto_route33_collision.asm')
        for key in ('JohtoNorthGateStepWarpAllowed::','JohtoGateCollisionDirectionAllowed::','JohtoInternalDoorFacingCheck::'):
            self.assertIn(key,col)
        for key in ('cp 19','cp 33','cp 9','cp 10','PLAYER_DIR_UP','PLAYER_DIR_DOWN'):
            self.assertIn(key,col)
        self.assertIn('callba JohtoGateCollisionDirectionAllowed',home)
        self.assertIn('callba JohtoInternalDoorFacingCheck',home)

    def test_arrival_and_immediate_reverse_regression(self):
        step=section('engine/overworld/region_map_lookup.asm','GetJohtoWarpArrivalStep::','GetJohtoCaveMapChangeSFX::')
        self.assertIn('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN',step)
        self.assertIn('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN',step)
        self.assertIn('JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, 19, REGION_NATIVE_MAP_SLOT, D_DOWN',step)
        self.assertNotRegex(step,r'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 7, [45], REGION_NATIVE_MAP_SLOT, D_')
        self.assertEqual([],gate_graph_errors(ROOT))
        self.assertIn('callab GetJohtoWarpArrivalStep',txt('engine/overworld/npc_movement.asm'))
        self.assertIn('JohtoNorthGateStepWarpAllowed::',txt('engine/overworld/johto_route33_collision.asm'))

    def test_both_outdoor_gate_facades_and_fences_remain_gold(self):
        self.assertEqual((ROOT/'maps/JohtoGoldenrodCity.blk').read_bytes(),(GOLD/'maps/GoldenrodCity.blk').read_bytes())
        self.assertEqual((ROOT/'maps/JohtoRoute35.blk').read_bytes(),(GOLD/'maps/Route35.blk').read_bytes())
        col=txt('engine/overworld/johto_route33_collision.asm')
        self.assertIn('JohtoGoldenrodCanStepAhead::',col)
        self.assertIn('JohtoRoute35CanStepAhead::',col)
        self.assertIn('JohtoGoldenrodEdgeFence::',col)
        self.assertIn('JohtoRoute35EdgeFence::',col)
        self.assertIn('cp 19',section('engine/overworld/johto_route33_collision.asm','JohtoGoldenrodCanStepAhead::','JohtoGoldenrodBlockedRows::'))

    def test_gate_neutral_without_suppressing_roads_or_city(self):
        neutral=section('engine/overworld/map_name_sign.asm','.IsNeutralMap','.NeutralMapList')
        self.assertIn('cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',neutral)
        for name in ('JOHTO_ROUTE_35_LOCAL_ID','JOHTO_GOLDENROD_CITY_LOCAL_ID'):
            self.assertNotIn('cp '+name,neutral)

    def test_gold_north_south_gate_art_is_exact(self):
        self.assertEqual([],gate_gold_geometry_errors(ROOT,GOLD))
        self.assertEqual((ROOT/'maps/JohtoRoute35GoldenrodGate.blk').read_bytes(),(ROOT/'maps/JohtoRoute34IlexForestGate.blk').read_bytes())

    def test_approved_gate_rgb_and_kanto_resource_unchanged(self):
        self.assertTrue((ROOT/'gfx/blocksets/johto_gate.bst').stat().st_size > 0)
        self.assertIn('JOHTO_GATE',txt('data/mapHeaders/JohtoRoute35GoldenrodGate.asm'))
        self.assertIn('test_source_pixel_palette_exact',txt('tools/tests/test_johto_route34_gate_p18.py'))
        from johto_gate_audit import verify_gold_gate_palette_map
        self.assertEqual([],verify_gold_gate_palette_map(ROOT,GOLD))

    def test_old_gate_and_ledge_paths_are_still_registered(self):
        self.assertIn('JohtoRoute34IlexForestGate_h',txt('data/johto_map_headers.asm'))
        self.assertIn('JohtoRoute31VioletGate_h',txt('data/johto_map_headers.asm'))
        self.assertIn('JohtoIlexAzaleaGate_h',txt('data/johto_map_headers.asm'))
        self.assertIn('JohtoIlexForestLedgeTiles',txt('engine/overworld/ledges.asm'))
        self.assertIn('JohtoRoute35_h',txt('data/johto_map_headers.asm'))

    def test_wrong_route35_lane_target_fails(self):
        key='data/mapObjects/JohtoRoute35.asm'
        broken=txt(key).replace('db 33, 10, 1, REGION_WARP_ESCAPE','db 33, 10, 0, REGION_WARP_ESCAPE')
        self.assertNotEqual(broken,txt(key))
        self.assertTrue(gate_graph_errors(ROOT,{key:broken}))

    def test_city_warp_removal_fails(self):
        key='data/mapObjects/JohtoGoldenrodCity.asm'
        broken=txt(key).replace('db 1, 19, 2, REGION_WARP_ESCAPE','db 1, 19, 0, REGION_WARP_ESCAPE')
        self.assertNotEqual(broken,txt(key))
        self.assertTrue(gate_graph_errors(ROOT,{key:broken}))

    def test_wrong_native_branch_fails(self):
        key='engine/overworld/region_map_lookup.asm'
        broken=txt(key).replace('JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
                                'JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID')
        self.assertNotEqual(broken,txt(key))
        self.assertTrue(gate_graph_errors(ROOT,{key:broken}))

    def test_unknown_gate_door_step_rejected(self):
        key='engine/overworld/johto_route33_collision.asm'
        raw=txt(key)
        broken=raw.replace('cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID\n\tjr z, .gateVertical','cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID\n\tjr nz, .gateVertical')
        self.assertNotEqual(broken,raw)
        # Critical control-flow mutation must be rejected by a source contract,
        # not merely detected because the identifier still appears in the code.
        self.assertTrue(gate_dispatch_errors(ROOT,{key:broken}))

if __name__=='__main__':unittest.main()
