"""Gold/RPP gatehouse executable ASM contract: negative mutations must fail."""
from pathlib import Path
import json
import os
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import audit, ASM, HOME, LOOKUP, MANIFEST


class GatehouseBehaviorHardening224(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold=Path(os.environ['JOHTO_GOLD_SOURCE'])

    def source(self,path):
        return (ROOT/path).read_text(encoding='utf8')

    def failed(self,path,old,new,fragment):
        raw=self.source(path)
        self.assertIn(old,raw)
        damaged=raw.replace(old,new,1)
        self.assertNotEqual(raw,damaged)
        problems=audit(ROOT,self.gold,{path:damaged})
        self.assertTrue(any(fragment in error for error in problems),problems)

    def test_all_existing_gatehouses_are_verified_as_runtime_paths(self):
        self.assertEqual(audit(ROOT,self.gold),[])

    def test_route35_carpet_step_on_bug_is_rejected(self):
        self.failed(ASM,
          'cp JOHTO_GOLDENROD_CITY_LOCAL_ID\n\tjr z, .cityNorthDoor',
          'cp JOHTO_ROUTE_35_LOCAL_ID\n\tjr z, .cityNorthDoor',
          'Route35GoldenrodGate')

    def test_route35_warp_collision_direction_mutation_fails(self):
        self.failed(ASM,'\tjr z, .route35South','\tjr nz, .route35South',
                    'Route35GoldenrodGate')

    def test_old_route34_step_on_branch_mutation_fails(self):
        self.failed(ASM,'cp JOHTO_ROUTE_34_LOCAL_ID\n\tjr z, .route34',
                    'cp JOHTO_ROUTE_34_LOCAL_ID\n\tjr nz, .route34',
                    'JohtoRoute34IlexForestGate')

    def test_azalea_horizontal_gate_wrong_direction_fails(self):
        self.failed(ASM,'\tld a, PLAYER_DIR_LEFT\n\tjr .compare',
                    '\tld a, PLAYER_DIR_RIGHT\n\tjr .compare',
                    'JohtoIlexAzaleaGate')

    def test_north_gate_arrival_removed_fails(self):
        self.failed(LOOKUP,
          'db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN',
          'db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_UP',
          'arrival')

    def test_unexpected_south_gate_arrival_fails(self):
        raw=self.source(LOOKUP)
        needle='db $ff\n\n; Native cave entrances'
        self.assertIn(needle,raw)
        edited=raw.replace(needle,
          'db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 7, 4, REGION_NATIVE_MAP_SLOT, D_DOWN\n\tdb $ff\n\n; Native cave entrances',1)
        errors=audit(ROOT,self.gold,{LOOKUP:edited})
        self.assertTrue(any('arrival' in e for e in errors),errors)

    def test_wrong_gate_warp_target_fails(self):
        p='data/mapObjects/JohtoRoute35GoldenrodGate.asm'
        self.failed(p,'db 7, 5, 0, REGION_WARP_ESCAPE','db 7, 5, 1, REGION_WARP_ESCAPE',
                    'Warp coordinate/slot/target')

    def test_old_legacy_gate_lane_removal_fails(self):
        p='data/mapObjects/JohtoRoute31VioletGate.asm'
        self.failed(p,'db 5, 9, 1, JOHTO_ROUTE_31','db 5, 8, 1, JOHTO_ROUTE_31',
                    'Warp coordinate/slot/target')

    def test_missing_border_load_path_fails(self):
        self.failed(HOME,'callba PatchJohtoMapBordersAfterBlockLoad',
                    'callba PatchJohtoAzaleaWestGateBorder',
                    'BOTH load paths')

    def test_missing_border_renderer_fails(self):
        self.failed(ASM, 'call PatchJohtoGoldenrodNorthBorder',
                    'call PatchJohtoAzaleaWestGateBorder',
                    'renderer lost one side')

    def test_missing_gate_contract_is_blocked(self):
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps'] if g['rpp_map']=='JohtoIlexAzaleaGate')
        gate.pop('gatehouse_runtime')
        errors=audit(ROOT,self.gold,manifest=manifest)
        self.assertTrue(any('missing mandatory executable' in e for e in errors),errors)

    def test_missing_new_gate_policy_is_blocked(self):
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps'] if g['rpp_map']=='JohtoRoute35GoldenrodGate')
        gate['gatehouse_runtime']['approaches']=[]
        errors=audit(ROOT,self.gold,manifest=manifest)
        self.assertTrue(any('missing outdoor and indoor' in e for e in errors),errors)

    def test_unrecognized_selector_opcode_fails_closed(self):
        self.failed(ASM, 'JohtoNorthGateStepWarpAllowed::\n\tld a, [wCurRegion]',
                    'JohtoNorthGateStepWarpAllowed::\n\tcall HiddenUnknownSideEffect\n\tld a, [wCurRegion]',
                    'cannot be verified')


    def test_changed_gold_gate_metatile_layout_fails(self):
        p='maps/JohtoRoute35GoldenrodGate.blk'
        original=(ROOT/p).read_bytes()
        self.assertGreater(len(original),0)
        # Local copy prevents touching checked-in binary map assets.
        from tempfile import TemporaryDirectory
        import shutil
        with TemporaryDirectory() as temp:
            copy=Path(temp)/'gate'
            shutil.copytree(ROOT,copy,symlinks=False,ignore=shutil.ignore_patterns('.git','pokegold-master'))
            dest=copy/p
            raw=bytearray(original)
            raw[0]^=1
            dest.write_bytes(raw)
            issues=audit(copy,self.gold)
            self.assertTrue(any('metatile layout differs' in e for e in issues),issues)

    def test_moving_arrival_into_wall_is_rejected(self):
        p='maps/JohtoRoute35GoldenrodGate.blocked_mask.bin'
        original=(ROOT/p).read_bytes()
        corrupted=bytearray(original)
        corrupted[1*2+4//8]|=1<<(4%8)
        errors=audit(ROOT,self.gold,{p:bytes(corrupted)})
        self.assertTrue(any('forced arrival step lands in blocked terrain' in e for e in errors),errors)

    def test_native_warp_to_wrong_gate_is_rejected(self):
        self.failed(LOOKUP,
           'db JOHTO_ROUTE_35_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
           'db JOHTO_ROUTE_35_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',
           'native Warp routes changed')

    def test_missing_outdoor_lane_proof_is_rejected(self):
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps'] if g['rpp_map']=='JohtoRoute35GoldenrodGate')
        gate['gatehouse_runtime']['approaches']=[v for v in gate['gatehouse_runtime']['approaches']
             if not (v['map_local']=='JOHTO_ROUTE_35_LOCAL_ID' and v['x']==10)]
        errors=audit(ROOT,self.gold,manifest=manifest)
        self.assertTrue(any('missing exactly one outside approach' in e for e in errors),errors)

    def test_arrival_policy_side_metadata_cannot_lie(self):
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps'] if g['rpp_map']=='JohtoRoute34IlexForestGate')
        gate['arrival_step_review']['by_gate_side']['north']='NONE'
        errors=audit(ROOT,self.gold,manifest=manifest)
        self.assertTrue(any('reviewed arrival direction disagrees' in e for e in errors),errors)

    def test_removed_arrival_step_runtime_executor_fails(self):
        p='engine/overworld/npc_movement.asm'
        self.failed(p,'callab GetJohtoWarpArrivalStep', 'callab GetJohtoCaveMapChangeSFX',
                    'shared gate runtime missing post-Warp step executor')

if __name__=='__main__':unittest.main()
