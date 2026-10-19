"""Independent Gold-backed, fail-closed executable behavior regression for Ruins north gate.

Deliberately corrupts the *source* in memory; PASS requires a real audit error.
"""
from pathlib import Path
import json,os,sys,unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import audit,ASM,LOOKUP,MANIFEST
from johto_door_onboarding_audit import audit as audit_onboard
from johto_gate_rgb_audit import verify as verify_rgb
from johto_gate_audit import verify_gold_gate_palette_map
from johto_indoor_tiles_converter import build_mapping

class RuinsGateMerged224(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold=Path(os.environ['JOHTO_GOLD_SOURCE'])
    def original(self,path):
        return (ROOT/path).read_text()
    def check_mutation(self,path,old,new,expect):
        text=self.original(path)
        self.assertIn(old,text)
        test=text.replace(old,new,1)
        self.assertNotEqual(test,text)
        issues=audit(ROOT,self.gold,{path:test})
        self.assertTrue(any(expect in e for e in issues),(expect,issues))
    def test_two_lane_routes(self):
        self.assertEqual(audit(ROOT,self.gold),[])
    def test_direction_selectors(self):
        self.assertEqual(audit(ROOT,self.gold),[])
    def test_arrival_and_masks(self):
        self.assertEqual(audit(ROOT,self.gold),[])
    def test_gold_outdoor_geometry(self):
        issues,ids=audit_onboard(ROOT,self.gold)
        self.assertEqual(issues,[])
        self.assertTrue(any('RuinsGate' in x for x in ids))
    def test_neutral_map_name(self):
        self.assertIn('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',self.original('engine/overworld/map_name_sign.asm'))
        self.assertIn('JohtoBrowseRoute36Name',self.original('engine/town_map.asm'))
    def test_original_gold_metatiles(self):
        mapping, gold_blocks=build_mapping(ROOT,self.gold,'Route36RuinsOfAlphGate','gate','johto_gate')
        self.assertEqual((ROOT/'maps/JohtoRoute36RuinsGate.blk').read_bytes(),gold_blocks)
        self.assertEqual(mapping['exact_mapped'],mapping['used_unique_blocks'])
    def test_palette_resource_isolation(self):
        self.assertEqual(verify_rgb(ROOT,self.gold),[])
        self.assertEqual(verify_gold_gate_palette_map(ROOT,self.gold),[])
    def test_old_gate_still_passes(self):
        self.assertEqual(audit(ROOT,self.gold),[])
    def test_mutate_route_rejected(self):
        self.check_mutation(LOOKUP,'db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID', 'db JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 2, 1, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID','native Warp routes changed')
    def test_mutate_direction_rejected(self):
        self.check_mutation(ASM,'cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n\tjr z, .gateVertical','cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n\tjr nz, .gateVertical','JohtoRoute36RuinsGate')
    def test_mutate_arrival_rejected(self):
        self.check_mutation(LOOKUP,'db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN','db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_UP','arrival')
    def test_mutate_gate_warp_rejected(self):
        self.check_mutation('data/mapObjects/JohtoRoute36RuinsGate.asm','db 7, 5, 0, REGION_WARP_ESCAPE','db 7, 5, 1, REGION_WARP_ESCAPE','Warp coordinate/slot/target')
    def test_mutate_contract_rejected(self):
        d=json.loads(self.original(MANIFEST))
        e=next(t for t in d['active_warp_maps'] if t['rpp_map']=='JohtoRoute36RuinsGate')
        e['gatehouse_runtime']['approaches']=[]
        issues=audit(ROOT,self.gold,manifest=d)
        self.assertTrue(any('missing outdoor and indoor' in x for x in issues),issues)
    def test_route36_collision_dispatch_wrong_target_is_rejected(self):
        # This formerly escaped when a broad north-gate branch hid Route36.
        self.check_mutation(
            ASM,
            'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjp z, .ruinsRoute36',
            'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjp z, .ruinsOutside',
            'JohtoRoute36RuinsGate')

    def test_ruins_ledge_is_a_real_release_gate(self):
        # Ruins was added to the shared ledge dispatcher and Gold inventory.
        from ledge_regression_audit import audit as ledge_audit
        result=ledge_audit(ROOT,self.gold)
        self.assertEqual(result['errors'],[],result['errors'])
        self.assertEqual(result['totals']['ruins_coordinate_rules'],16)

    def test_unknown_asm_fails_closed(self):
        self.check_mutation(ASM,'JohtoNorthGateStepWarpAllowed::\n\tld a, [wCurRegion]', 'JohtoNorthGateStepWarpAllowed::\n\tcall UnknownDoorOpcode\n\tld a, [wCurRegion]','cannot be verified')
