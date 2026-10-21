"""EAST-42 real registration and eight non-vacuous Gold/runtime negative-guard proofs.

A static source audit, NEVER phone/ROM verification.
"""
import json
import os
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE', os.environ.get('JOHTO_GOLD_ROOT', str(ROOT/'pokegold-master'))))
sys.path.insert(0,str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import (predicate, object_warps, audit as gate_audit)
from johto_indoor_tiles_converter import build_mapping
from johto_rpp_connection_guard import audit_all_active
from johto_rom0_collision_audit import audit as collision_audit
from johto_gold_cells import decode_cells

GATE='JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID'
CITY='JOHTO_ECRUTEAK_CITY_LOCAL_ID'
ROUTE='JOHTO_ROUTE_42_LOCAL_ID'

class EcruteakEastGate(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        cls.gate=next(x for x in cls.manifest['active_warp_maps'] if x['rpp_map']=='JohtoRoute42EcruteakGate')
        cls.collision=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()

    def test_real_home_selector_and_immediate_reentry_gate(self):
        home=(ROOT/'home/overworld.asm').read_text()
        values={}
        import re
        for name in ('constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm'):
            values.update({k:int(v) for k,v in re.findall(
                r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\d+)',
                (ROOT/name).read_text())})
        for local in (GATE, ROUTE, CITY):
            self.assertTrue(predicate(home,'IsJohtoSouthGatePortal',local,0,0,'LEFT',values),local)
            self.assertFalse(predicate(home,'IsJohtoSouthGatePortal',local,0,0,'LEFT',values,
                                       region='MAP_REGION_KANTO'))
        for local in ('JOHTO_ROUTE_39_LOCAL_ID','JOHTO_MAHOGANY_TOWN_LOCAL_ID'):
            self.assertFalse(predicate(home,'IsJohtoSouthGatePortal',local,0,0,'LEFT',values),local)
        # Fault injection: deleting sparse-ID HOME branch must fail, even if
        # collision and ExtraWarpCheck helpers still contain the correct ID.
        damaged=home.replace('cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID',
                             'cp JOHTO_MAHOGANY_TOWN_LOCAL_ID',1)
        self.assertFalse(predicate(damaged,'IsJohtoSouthGatePortal',GATE,0,4,'LEFT',values))
        for item in self.gate['gatehouse_runtime']['approaches']:
            if item['map_local'] in (CITY,ROUTE):
                self.assertTrue(item['outside_guard'])
                for direction in ('UP','DOWN','LEFT','RIGHT'):
                    from johto_gatehouse_behavior_audit import predicate as execute
                    self.assertEqual(execute(self.collision,'JohtoInternalDoorFacingCheck',
                                      item['map_local'],item['x'],item['y'],direction),
                                      direction == item['direction'])

    def test_two_lane_bidirectional_warps(self):
        self.assertEqual(len(self.gate['gatehouse_runtime']['native_routes']),8)
        for name,n in [('JohtoEcruteakCity',4),('JohtoRoute42EcruteakGate',4),('JohtoRoute42',2)]:
            observed=object_warps((ROOT/'data/mapObjects'/f'{name}.asm').read_text(),name)
            self.assertEqual(len(observed),n)
            self.assertEqual(len(set((y,x) for y,x,_,_ in observed)),n)
        self.assertEqual(sorted(gate_audit(ROOT,GOLD)),[])

    def test_collision_only_wrong_direction_denied(self):
        for item in self.gate['gatehouse_runtime']['approaches']:
            for facing in ('UP','DOWN','LEFT','RIGHT'):
                got=predicate(self.collision,'JohtoGateCollisionDirectionAllowed',item['map_local'],item['x'],item['y'],facing)
                self.assertEqual(got,facing==item['direction'],str(item)+':'+facing)
                self.assertFalse(predicate(self.collision,'JohtoNorthGateStepWarpAllowed',item['map_local'],item['x'],item['y'],facing))

    def test_no_forced_step_at_either_gate_side(self):
        arrivals=self.gate['gatehouse_runtime']['arrivals']
        self.assertEqual(len(arrivals),1)
        self.assertEqual({(y,x,d) for y,x,d in arrivals[0]['points']},
                         {(4,0,'NONE'),(5,0,'NONE'),(4,9,'NONE'),(5,9,'NONE')})
        route=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        self.assertNotIn('JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID,',route.split('GetJohtoWarpArrivalStep::',1)[-1].split('NativeRegionWarpTargets::',1)[0])

    def test_reciprocal_gold_seams_and_outer_border(self):
        summary=audit_all_active(ROOT,GOLD)
        self.assertEqual(summary['status'],'PASS',str(summary.get('issues')))
        edges={(e.get('current'),e.get('target'),e.get('direction')) for e in summary['edges'] if e['status']=='PASS'}
        self.assertIn(('JohtoEcruteakCity','JohtoRoute42','east'),edges)
        self.assertIn(('JohtoRoute42','JohtoEcruteakCity','west'),edges)
        # Route42 east is now connected, but only reviewed y16/y17 may pass.
        self.assertIn('cp JOHTO_ROUTE_42_WIDTH * 2 - 1',self.collision)
        self.assertIn('db JOHTO_ROUTE_42_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID', (ROOT/'engine/overworld/region_map_lookup.asm').read_text())
        self.assertIn(('JohtoRoute42','JohtoMahoganyTown','east'),edges)
        self.assertIn(('JohtoMahoganyTown','JohtoRoute42','west'),edges)

    def test_gate_name_is_neutral(self):
        # From BOTH Ecruteak and Route42, the transit gate must inherit the
        # previous landmark without a popup. Roads and cities remain visible.
        names=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
        neutral=names.split('.IsNeutralMap\n',1)[1].split('.NeutralMapList\n',1)[0]
        self.assertIn('cp REGION_NATIVE_MAP_SLOT',neutral)
        self.assertIn('cp MAP_REGION_JOHTO',neutral)
        self.assertRegex(neutral,r'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\s+ret z')
        self.assertEqual(neutral.count('cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID'),1)
        self.assertNotIn('cp JOHTO_ROUTE_42_LOCAL_ID',neutral)
        self.assertNotIn('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID',neutral)
        transitions=names.split('\n.mapChanged\n',1)[1].split('\n.resolveLandmark\n',1)[0]
        self.assertIn('call .IsNeutralMap',transitions)
        self.assertIn('jp nz, .cancel',transitions)
        self.assertIn('jp .storeWithoutShowing',transitions)
        self.assertNotIn('ROUTE_42_ECRUTEAK_GATE', (ROOT/'engine/town_map.asm').read_text())

    def test_gold_gate_block_palette_fidelity(self):
        mapping,expected=build_mapping(ROOT,GOLD,'Route42EcruteakGate','gate','johto_gate')
        self.assertEqual(mapping['exact_mapped'],mapping['used_unique_blocks'])
        self.assertEqual((ROOT/'maps/JohtoRoute42EcruteakGate.blk').read_bytes(),expected)
        from johto_gate_audit import verify_gold_gate_palette_map
        self.assertEqual(verify_gold_gate_palette_map(ROOT,GOLD),[])

    def test_only_surf_cut_and_no_headbutt(self):
        cells=decode_cells((GOLD/'maps/Route42.blk').read_bytes(),(GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
                           (GOLD/'data/tilesets/johto_collision.asm').read_text(),30,9)
        water={(c['y'],c['x']) for c in cells if c['role']=='WATER'}
        cut={(c['y'],c['x']) for c in cells if c['role']=='CUT_TREE'}
        self.assertEqual(len(water),120)
        self.assertEqual(cut,{(13,24)})
        mask=(ROOT/'maps/JohtoRoute42.water_mask.bin').read_bytes()
        self.assertEqual(len(mask),18*8)
        actual={(y,x) for y in range(18) for x in range(60) if mask[y*8+x//8] & (1<<(x%8))}
        self.assertEqual(actual,water)
        graph=(ROOT/'engine/overworld/johto_union_cave_surf.asm').read_text()
        self.assertIn('IsJohtoRoute42WaterAhead::',graph)
        self.assertIn('JohtoRoute42RemoveCutTree::',self.collision)
        self.assertNotIn('IsJohtoRoute42HeadbuttTreeAhead::',graph)
        caps=json.loads((ROOT/'tools/johto_native_maps.json').read_text())['maps'][-2]['feature_status']
        self.assertEqual((caps['surf'],caps['cut'],caps['fly']),('ALLOWED','ALLOWED','DEFERRED'))

    def test_gate_5x4_dimensions_are_defined_for_assembly(self):
        # Static tests previously passed even though the ASM referenced an
        # undeclared width symbol, causing rgbasm to fail at link time.
        import re
        constants=(ROOT/'constants/region_map_constants.asm').read_text()
        header=(ROOT/'data/mapHeaders/JohtoRoute42EcruteakGate.asm').read_text()
        for dimension,expected in (('WIDTH',5),('HEIGHT',4)):
            symbol=f'JOHTO_ROUTE_42_ECRUTEAK_GATE_{dimension}'
            matches=re.findall(rf'(?m)^DEF\s+{symbol}\s+EQU\s+(\d+)\s*$',constants)
            self.assertEqual(matches,[str(expected)],f'missing or wrong ASM constant: {symbol}')
        self.assertIn('ld d, JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH * 2',self.collision)
        self.assertIn('db JOHTO_ROUTE_42_ECRUTEAK_GATE_HEIGHT, JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH',header)

    def test_existing_gate_regression(self):
        self.assertEqual(collision_audit(ROOT),[])
        self.assertEqual(gate_audit(ROOT,GOLD),[])
        from johto_roof_reference_audit import audit as roof_audit
        self.assertEqual(roof_audit(ROOT,GOLD),[])

if __name__=='__main__':unittest.main()
