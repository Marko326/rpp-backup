"""Route43 middle gate: independent Gold geometry and executable runtime audits.

The Rocket toll/Officer events are NOT implemented by this transit-only stage.
"""
import json
import os
import sys
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', os.environ.get('JOHTO_GOLD_ROOT', '/missing-Gold')))
sys.path.insert(0, str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import (audit as behavior_audit, predicate, object_warps)
from johto_gold_cells import decode_cells
from johto_indoor_tiles_converter import build_mapping
from johto_masked_step_audit import parse_caller, trace_masked_step
from johto_warp_arrival_audit import profiles

ROUTE='JOHTO_ROUTE_43_LOCAL_ID'
GATE='JOHTO_ROUTE_43_GATE_LOCAL_ID'

class Route43Gate236(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route43Gate.asm').is_file():
            raise RuntimeError('full Gold source is mandatory')
        cls.runtime=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        cls.lookup=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        cls.manifest=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        cls.contract=next(x for x in cls.manifest['active_warp_maps'] if x['rpp_map']=='JohtoRoute43Gate')

    def test_gold_warp_graph(self):
        outdoor=object_warps((ROOT/'data/mapObjects/JohtoRoute43.asm').read_text(), 'JohtoRoute43')
        indoor=object_warps((ROOT/'data/mapObjects/JohtoRoute43Gate.asm').read_text(), 'JohtoRoute43Gate')
        self.assertEqual(outdoor[2:],[(35,17,2,'REGION_WARP_ESCAPE'), (31,17,0,'REGION_WARP_ESCAPE'), (31,18,1,'REGION_WARP_ESCAPE')])
        self.assertEqual(indoor,[(0,4,3,'REGION_WARP_ESCAPE'),(0,5,4,'REGION_WARP_ESCAPE'),(7,4,2,'REGION_WARP_ESCAPE'),(7,5,2,'REGION_WARP_ESCAPE')])
        for origin,idx,dest_idx,target in self.contract['gatehouse_runtime']['native_routes']:
            self.assertIn(f'db {origin}, {idx}, {dest_idx}, MAP_REGION_JOHTO, {target}', self.lookup)
        self.assertEqual(len(self.contract['gatehouse_runtime']['native_routes']),7)
        gold=(GOLD/'maps/Route43Gate.asm').read_text()
        self.assertEqual(gold.count('warp_event '),4)

    def test_asymmetric_gold_entry_types(self):
        src=decode_cells((GOLD/'maps/Route43.blk').read_bytes(),
             (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
             (GOLD/'data/tilesets/johto_collision.asm').read_text(),10,27,graphic_slots=256)
        roles={(c['x'],c['y']):c['role'] for c in src}
        self.assertEqual(roles[17,35],'DOOR')
        self.assertEqual(roles[17,31],'WARP_CARPET_DOWN')
        self.assertEqual(roles[18,31],'WARP_CARPET_DOWN')
        approaches=[(ROUTE,17,35,'UP','STEP_ON'),(ROUTE,17,31,'DOWN','COLLISION_ONLY'),(ROUTE,18,31,'DOWN','COLLISION_ONLY')]
        approaches += [(GATE,x,y,d,trigger)
                       for y,d,trigger in ((0,'UP','STEP_ON'),(7,'DOWN','COLLISION_ONLY'))
                       for x in (4,5)]
        for local,x,y,wanted,trigger in approaches:
            for direction in ('UP','DOWN','LEFT','RIGHT'):
                self.assertEqual(predicate(self.runtime,'JohtoNorthGateStepWarpAllowed',local,x,y,direction),direction==wanted and trigger=='STEP_ON',(local,x,y,direction))
                self.assertEqual(predicate(self.runtime,'JohtoGateCollisionDirectionAllowed',local,x,y,direction),direction==wanted,(local,x,y,direction))
        self.assertEqual(behavior_audit(ROOT,GOLD),[])

    def test_arrival_and_immediate_reentry(self):
        steps={(l,y,x):direction for _,l,y,x,_,direction in profiles(self.lookup)}
        self.assertEqual(steps[(ROUTE,35,17)],'D_DOWN')
        for x in (4,5):self.assertEqual(steps[(GATE,0,x)],'D_DOWN')
        for key in ((GATE,7,4),(GATE,7,5),(ROUTE,31,17),(ROUTE,31,18)):
            self.assertNotIn(key,steps)
        mask=(ROOT/'maps/JohtoRoute43.blocked_mask.bin').read_bytes()
        self.assertFalse(mask[36*3+17//8] & (1<<(17%8)))
        gmask=(ROOT/'maps/JohtoRoute43Gate.blocked_mask.bin').read_bytes()
        for x,y in ((4,1),(5,1),(4,6),(5,6)):
            self.assertFalse(gmask[y*2+x//8] & (1<<(x%8)))

    def test_exterior_stays_original(self):
        self.assertEqual((ROOT/'maps/JohtoRoute43.blk').read_bytes(),(GOLD/'maps/Route43.blk').read_bytes())
        self.assertEqual((ROOT/'maps/JohtoRoute43.blocked_mask.bin').stat().st_size,54*3)
        # Native connection geometry and border preview are untouched.
        self.assertIn('JOHTO_ROUTE_43_WIDTH + 3',(ROOT/'data/mapHeaders/JohtoRoute43.asm').read_text())

    def test_gate_neutral_no_sign(self):
        self.assertIn('cp JOHTO_ROUTE_43_GATE_LOCAL_ID\n\tret z',(ROOT/'engine/overworld/map_name_sign.asm').read_text())
        self.assertIn('db JOHTO_GATE',(ROOT/'data/mapHeaders/JohtoRoute43Gate.asm').read_text())

    def test_shared_gold_art(self):
        mapping,candidate=build_mapping(ROOT,GOLD,'Route43Gate','gate','johto_gate')
        self.assertEqual(mapping['unmapped'],[])
        self.assertEqual(mapping['exact_mapped'],9)
        self.assertEqual((ROOT/'maps/JohtoRoute43Gate.blk').read_bytes(),(ROOT/'maps/JohtoRoute43MahoganyGate.blk').read_bytes())
        self.assertEqual((ROOT/'maps/JohtoRoute43Gate.blocked_mask.bin').read_bytes(),(ROOT/'maps/JohtoRoute34IlexForestGate.blocked_mask.bin').read_bytes())

    def test_shared_palette_unchanged(self):
        self.assertIn('db JOHTO_GATE',(ROOT/'data/mapHeaders/JohtoRoute43Gate.asm').read_text())
        self.assertFalse((ROOT/'scripts/JohtoRoute43Gate.asm').read_text().count('RGB'))
        self.assertEqual(self.contract['runtime_palette_status'],'PHONE_PENDING')

    def test_old_gate_still_registered(self):
        self.assertIn('dw JohtoRoute43MahoganyGate_h',(ROOT/'data/johto_map_headers.asm').read_text())
        self.assertIn('dw JohtoRoute43Gate_h',(ROOT/'data/johto_map_headers.asm').read_text())
        self.assertEqual(len(self.manifest['active_warp_maps'][-1]['gatehouse_proof_ids']),8)

    def test_real_movement_executors_no_air_walls(self):
        program,labels=parse_caller(self.runtime,'JohtoRoute43CanStepAhead')
        mask=(ROOT/'maps/JohtoRoute43.blocked_mask.bin').read_bytes()
        cells=decode_cells((GOLD/'maps/Route43.blk').read_bytes(), (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(), (GOLD/'data/tilesets/johto_collision.asm').read_text(),10,27,graphic_slots=256)
        cut={(c['x'],c['y']) for c in cells if c['role']=='CUT_TREE'}
        cases=[(17,36,'UP',False),(17,30,'DOWN',False),(18,30,'DOWN',False),
               (17,31,'RIGHT',False),(18,31,'LEFT',False),
               (17,31,'DOWN',True),(18,31,'DOWN',True),
               (17,35,'UP',True)]
        for x,y,d,blocked in cases:
            actual,_=trace_masked_step(program,labels,mask,20,54,ROUTE,x,y,d,gold_cut_cells=cut)
            self.assertEqual(actual,blocked,(x,y,d))

    def test_wrong_gold_door_mode_even_both_asm_and_manifest_changed_fails(self):
        # Mutation tests the independent Gold source, not same-data consistency.
        changed=self.runtime.replace('jr z, .route43MiddleDoor','jp .deny')
        self.assertNotEqual(changed,self.runtime)
        contract=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        case=next(x for x in contract['active_warp_maps'] if x['rpp_map']=='JohtoRoute43Gate')
        case['gatehouse_runtime']['approaches'][0]['trigger']='COLLISION_ONLY'
        overrides={'engine/overworld/johto_route33_collision.asm':changed,
                   'tools/johto_door_contracts.json':json.dumps(contract)}
        failures=behavior_audit(ROOT,GOLD,overrides=overrides)
        self.assertTrue(any('Gold single solid DOOR' in x for x in failures),failures)

    def test_warp_target_mutation_fails(self):
        changed=self.lookup.replace('JOHTO_ROUTE_43_LOCAL_ID, 4, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID',
            'JOHTO_ROUTE_43_LOCAL_ID, 4, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_43_GATE_LOCAL_ID')
        self.assertNotEqual(changed,self.lookup)
        self.assertTrue(behavior_audit(ROOT,GOLD,overrides={'engine/overworld/region_map_lookup.asm':changed}))

if __name__=='__main__':unittest.main()
