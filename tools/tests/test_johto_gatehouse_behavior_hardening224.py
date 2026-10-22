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
        self.failed(ASM,'\tjp z, .route35South','\tjp nz, .route35South',
                    'Route35GoldenrodGate')

    def test_route34_gold_carpet_step_on_branch_mutation_fails(self):
        # Gold Route34 (13/14,37) is WARP_CARPET_DOWN, not a solid DOOR.
        # Reintroducing the old .215 step-on exception must fail the runtime
        # predicate audit even though the old contract once documented it.
        raw=self.source(ASM)
        needle=('cp JOHTO_ILEX_FOREST_LOCAL_ID\n\tjp z, .forest\n'
                '\tcp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID')
        replacement=('cp JOHTO_ILEX_FOREST_LOCAL_ID\n\tjp z, .forest\n'
                     '\tcp JOHTO_ROUTE_34_LOCAL_ID\n\tjr z, .route34StepOn\n'
                     '\tcp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID')
        self.assertIn(needle,raw)
        damaged=raw.replace(needle,replacement,1)
        label='JohtoNorthGateStepWarpAllowed::'
        self.assertIn(label,damaged)
        start=damaged.index('JohtoNorthGateStepWarpAllowed::')
        end=damaged.index('\nJohtoGateCollisionDirectionAllowed::',start)
        section=damaged[start:end].replace('\n.gateVertical\n',
            '\n.route34StepOn\n'
            '\tld a, [wYCoord]\n\tcp 37\n\tjp nz, .deny\n'
            '\tld a, [wXCoord]\n\tcp 13\n\tjr z, .route34DownStep\n'
            '\tcp 14\n\tjp nz, .deny\n'
            '.route34DownStep\n\tld a, PLAYER_DIR_DOWN\n\tjr .match\n'
            '\n.gateVertical\n',1)
        damaged=damaged[:start]+section+damaged[end:]
        self.assertNotEqual(raw,damaged)
        errors=audit(ROOT,self.gold,{ASM:damaged})
        self.assertTrue(any('JohtoRoute34IlexForestGate' in error and
                            'STEP_ON actual=True wanted=False' in error
                            for error in errors),errors)

    def test_vertical_gate_south_carpet_step_on_self_consistency_fails_gold(self):
        # Mutate both the declared contract and the runtime so a self-only
        # checker would pass. Gold's WARP_CARPET_DOWN source must still reject it.
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps']
                  if g['rpp_map']=='JohtoRoute43Gate')
        for approach in gate['gatehouse_runtime']['approaches']:
            if approach['map_local']==gate['gatehouse_runtime']['local_id'] and approach['y']==7:
                approach['trigger']='STEP_ON'
        raw=self.source(ASM)
        old='''\tld a, [wYCoord]
\tand a
\tjr z, .up
\tjp .deny
.cityNorthDoor'''
        new='''\tld a, [wYCoord]
\tand a
\tjr z, .up
\tcp 7
\tjr z, .downStep
\tjp .deny
.cityNorthDoor'''
        self.assertIn(old,raw)
        damaged=raw.replace(old,new,1)
        start=damaged.index('JohtoNorthGateStepWarpAllowed::')
        end=damaged.index('\nJohtoGateCollisionDirectionAllowed::',start)
        section=damaged[start:end].replace('.up\n\tld a, PLAYER_DIR_UP\n\tjr .match\n.match',
            '.up\n\tld a, PLAYER_DIR_UP\n\tjr .match\n.downStep\n\tld a, PLAYER_DIR_DOWN\n\tjr .match\n.match',1)
        damaged=damaged[:start]+section+damaged[end:]
        errors=audit(ROOT,self.gold,{ASM:damaged},manifest=manifest)
        self.assertTrue(any('Gold WARP_CARPET_DOWN at Route43Gate (4,7) must be COLLISION_ONLY'
                            in error for error in errors),errors)

    def test_route34_outdoor_carpet_step_on_self_consistency_fails_gold(self):
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps']
                  if g['rpp_map']=='JohtoRoute34IlexForestGate')
        for approach in gate['gatehouse_runtime']['approaches']:
            if approach['map_local']=='JOHTO_ROUTE_34_LOCAL_ID' and approach['y']==37:
                approach['trigger']='STEP_ON'
        raw=self.source(ASM)
        needle=('cp JOHTO_ILEX_FOREST_LOCAL_ID\n\tjr z, .forest\n'
                '\tcp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID')
        replacement=('cp JOHTO_ILEX_FOREST_LOCAL_ID\n\tjr z, .forest\n'
                     '\tcp JOHTO_ROUTE_34_LOCAL_ID\n\tjr z, .route34StepOn\n'
                     '\tcp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID')
        damaged=raw.replace(needle,replacement,1)
        start=damaged.index('JohtoNorthGateStepWarpAllowed::')
        end=damaged.index('\nJohtoGateCollisionDirectionAllowed::',start)
        section=damaged[start:end].replace('\n.gateVertical\n',
            '\n.route34StepOn\n\tld a, [wYCoord]\n\tcp 37\n\tjp nz, .deny\n'
            '\tld a, [wXCoord]\n\tcp 13\n\tjr z, .route34DownStep\n\tcp 14\n\tjp nz, .deny\n'
            '.route34DownStep\n\tld a, PLAYER_DIR_DOWN\n\tjr .match\n.gateVertical\n',1)
        damaged=damaged[:start]+section+damaged[end:]
        errors=audit(ROOT,self.gold,{ASM:damaged},manifest=manifest)
        self.assertTrue(any('Gold WARP_CARPET_DOWN at Route34 (13,37) must be COLLISION_ONLY'
                            in error for error in errors),errors)

    def test_gold_carpet_direction_cannot_be_rewritten_with_manifest_and_asm(self):
        manifest=json.loads(self.source(MANIFEST))
        gate=next(g for g in manifest['active_warp_maps']
                  if g['rpp_map']=='JohtoRoute43Gate')
        for approach in gate['gatehouse_runtime']['approaches']:
            if (approach['map_local']=='JOHTO_ROUTE_43_LOCAL_ID' and
                approach['x']==17 and approach['y']==31):
                approach['direction']='UP'
        raw=self.source(ASM)
        start=raw.index('.route43MiddleNorth\n')
        end=raw.index('\n.mahoganyNorth',start)
        section=raw[start:end]
        self.assertIn('jp z,.down',section)
        section=section.replace('jp z,.down','jp z,.up')
        damaged=raw[:start]+section+raw[end:]
        errors=audit(ROOT,self.gold,{ASM:damaged},manifest=manifest)
        self.assertTrue(any('Gold WARP_CARPET_DOWN at Route43 (17,31) requires DOWN, not UP'
                            in error for error in errors),errors)

    def test_gold_arrival_carpet_never_receives_automatic_step(self):
        from johto_gatehouse_behavior_audit import gold_arrival_step_errors
        doc=json.loads(self.source(MANIFEST))
        gate=next(g for g in doc['active_warp_maps']
                  if g['rpp_map']=='JohtoRoute43Gate')
        arrival=next(a for a in gate['gatehouse_runtime']['arrivals']
                     if a['local']==gate['gatehouse_runtime']['local_id'])
        for point in arrival['points']:
            if point[0]==7 and point[1] in (4,5):
                point[2]='D_DOWN'
        errors=gold_arrival_step_errors(ROOT,self.gold,[gate])
        self.assertTrue(any('Gold arrival Route43Gate (4,7) role=WARP_CARPET_DOWN '
                            'requires NONE, not D_DOWN' in error for error in errors),errors)

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
