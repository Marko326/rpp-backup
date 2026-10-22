"""Two newly enabled National Park gatehouse static proofs; phone status PENDING.

Run actual Gold file comparisons and the original mask/gate ASM trace interpreters.
These tests are not a replacement for a linked ROM or a phone playthrough.
"""
import json
import re
import unittest
from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import predicate, object_warps
from johto_masked_step_audit import parse_caller, trace_masked_step
from johto_gate_rgb_audit import verify as verify_gate_rgb

SRC = os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('JOHTO_GOLD_ROOT')
GOLD = Path(SRC) if SRC else None
PARK='JOHTO_NATIONAL_PARK_LOCAL_ID'
G35='JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID'
G36='JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID'
R35='JOHTO_ROUTE_35_LOCAL_ID'
R36='JOHTO_ROUTE_36_LOCAL_ID'
DIRECTIONS=('UP','DOWN','LEFT','RIGHT')
CONFIGS={
  '35': ('JohtoRoute35NationalParkGate','Route35NationalParkGate',G35,
         'JohtoRoute35NationalParkGateCanStepAhead',8,8),
  '36': ('JohtoRoute36NationalParkGate','Route36NationalParkGate',G36,
         'JohtoRoute36NationalParkGateCanStepAhead',10,8),
}

def gold():
    if GOLD is None or not (GOLD/'maps/NationalPark.asm').exists():
        raise AssertionError('Need the full original Gold source in JOHTO_GOLD_SOURCE to review park gates')
    return GOLD


def masked(stem, symbol, width, height, x, y, direction):
    source=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
    name = {'JohtoRoute35':'JohtoRoute35CanStepAhead','JohtoRoute36':'JohtoRoute36CanStepAhead',
            'JohtoNationalPark':'JohtoNationalParkCanStepAhead',
            'JohtoRoute35NationalParkGate':'JohtoRoute35NationalParkGateCanStepAhead',
            'JohtoRoute36NationalParkGate':'JohtoRoute36NationalParkGateCanStepAhead'}[stem]
    caller,labels=parse_caller(source,name)
    mask=(ROOT/f'maps/{stem}.blocked_mask.bin').read_bytes()
    return trace_masked_step(caller,labels,mask,width,height,symbol,x,y,direction)[0]


class StaticParkGates(unittest.TestCase):
    def contract(self,num):
        manifest=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        return next(e for e in manifest['active_warp_maps'] if e['rpp_map']==CONFIGS[num][0])

    def proof(self,num,category):
        stem,original,local,caller,w,h=CONFIGS[num]
        contract=self.contract(num)['gatehouse_runtime']
        if category=='two_lane_warps':
            warps=object_warps((ROOT/f'data/mapObjects/{stem}.asm').read_text(),stem)
            expected=[tuple(v) for side in contract['warp_sides'].values() for v in side]
            self.assertCountEqual(warps,expected)
            gold_warps=re.findall(r'^\s*warp_event\s+(\d+),\s*(\d+),',
                    (gold()/f'maps/{original}.asm').read_text(),re.M)
            self.assertEqual({(y,x) for x,y in gold_warps},{(str(y),str(x)) for y,x,_,_ in warps})
            src=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
            table=src.split('NativeRegionWarpTargets::',1)[1].split('SelectNativeMapConnection::',1)[0]
            real={(a,int(b),int(c),d) for a,b,c,d in re.findall(
                r'(?m)^\s*db\s+(JOHTO_\w+),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s*(JOHTO_\w+)',table)}
            self.assertEqual({row for row in real if local in (row[0],row[3])},
                             {tuple(row) for row in contract['native_routes']})
        elif category=='directional_collision':
            source=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
            for spec in contract['approaches']:
                for face in DIRECTIONS:
                    wanted=face==spec['direction']
                    self.assertEqual(predicate(source,'JohtoGateCollisionDirectionAllowed',
                                    spec['map_local'],spec['x'],spec['y'],face),wanted,
                                    (stem,spec,face))
                    self.assertEqual(predicate(source,'JohtoNorthGateStepWarpAllowed',
                                    spec['map_local'],spec['x'],spec['y'],face),
                                     wanted and spec['trigger']=='STEP_ON')
                    if spec.get('outside_guard'):
                        self.assertEqual(predicate(source,'JohtoInternalDoorFacingCheck',
                                        spec['map_local'],spec['x'],spec['y'],face),wanted)
        elif category=='immediate_return':
            for spec in contract['approaches']:
                if spec['map_local']==local:
                    # Collision-only carpet -> outgoing boundary collision.
                    self.assertTrue(masked(stem,local,w,h,spec['x'],spec['y'],spec['direction']))
            if num=='35':
                for x in (3,4):
                    self.assertFalse(masked(stem,local,w,h,x,1,'UP'))
                    self.assertFalse(masked(stem,local,w,h,x,6,'DOWN'))
                self.assertFalse(masked('JohtoRoute35',R35,20,36,3,6,'UP'))
                # Route35 Cut-tree dynamic helper is outside the mask tracer's supported scope.
                # Independently verify the north cell of the carpet is blocked in original mask.
                mask=(ROOT/'maps/JohtoRoute35.blocked_mask.bin').read_bytes()
                self.assertTrue(mask[4*3+3//8] & (1<<(3%8)))
                for x in (10,11):
                    self.assertFalse(masked('JohtoNationalPark',PARK,40,54,x,46,'DOWN'))
                    self.assertTrue(masked('JohtoNationalPark',PARK,40,54,x,47,'DOWN'))
            else:
                for y in (4,5):
                    self.assertFalse(masked(stem,local,w,h,1,y,'LEFT'))
                    self.assertFalse(masked(stem,local,w,h,8,y,'RIGHT'))
                    self.assertFalse(masked('JohtoRoute36',R36,60,18,19,y+4,'LEFT'))
                    self.assertTrue(masked('JohtoRoute36',R36,60,18,18,y+4,'LEFT'))
                    self.assertFalse(masked('JohtoNationalPark',PARK,40,54,32,y+14,'RIGHT'))
                    self.assertTrue(masked('JohtoNationalPark',PARK,40,54,33,y+14,'RIGHT'))
                    self.assertFalse(masked(stem,local,w,h,0,y,'DOWN' if y==4 else 'UP'))
                    self.assertFalse(masked(stem,local,w,h,9,y,'DOWN' if y==4 else 'UP'))
        elif category=='exterior_border_loads':
            self.assertEqual((ROOT/f'maps/{stem}.blk').read_bytes(),
                             (gold()/f'maps/{original}.blk').read_bytes())
            home=(ROOT/'home/overworld.asm').read_text()
            hook='callba PatchJohtoMapBordersAfterBlockLoad'
            self.assertEqual(home.count(hook),2)
            self.assertIn(hook,home.split('LoadMapData::',1)[-1].split('; HAX: Padding',1)[0])
            self.assertIn(hook,home.split('.ordinaryConnection\n',1)[-1].split('.didNotEnterConnectedMap',1)[0])
            self.assertEqual((ROOT/'gfx/blocksets/johto_park_gate.bst').read_bytes()[1024:],bytes(16))
        elif category=='neutral_map_name':
            src=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
            m=src.split('\n.IsNeutralMap\n',1)[1].split('\n.legacyMap\n',1)[0]
            self.assertRegex(m,rf'cp {local}\s+ret z')
            self.assertNotIn('cp JOHTO_NATIONAL_PARK_LOCAL_ID\n\tret z',m)
        elif category=='gold_art_tile_palette':
            self.assertEqual((ROOT/'gfx/blocksets/johto_park_gate.bst').read_bytes()[:1024],
                             (gold()/'data/tilesets/gate_metatiles.bin').read_bytes())
            self.assertEqual((ROOT/'gfx/tilesets/johto_park_gate.png').read_bytes(),
                             (gold()/'gfx/tilesets/gate.png').read_bytes())
            self.assertEqual((ROOT/'color/tilesets/johto_park_gate.asm').read_text().splitlines(),
                             (gold()/'gfx/tilesets/gate_palette_map.asm').read_text().splitlines()[:12])
        elif category=='runtime_rgb_kanto_isolation':
            self.assertFalse(verify_gate_rgb(ROOT,gold()))
            self.assertIn('tileset JohtoParkGate_Block, JohtoParkGate_GFX, Gate_Coll',
                          (ROOT/'data/tileset_headers.asm').read_text())
            src=(ROOT/'color/data/map_palette_assignments.asm').read_text()
            self.assertIn('INCLUDE "color/tilesets/johto_park_gate.asm"',src)
        elif category=='legacy_gate_regression':
            s=(ROOT/'data/mapObjects/JohtoRoute36.asm').read_text()
            old=[(13,47,0,'REGION_WARP_ESCAPE'),(13,48,1,'REGION_WARP_ESCAPE')]
            if num=='36':
                self.assertEqual(object_warps(s,'JohtoRoute36')[:2],old)
            s=(ROOT/'data/mapObjects/JohtoRoute35.asm').read_text()
            self.assertEqual(object_warps(s,'JohtoRoute35')[:2],
                             [(33,9,0,'REGION_WARP_ESCAPE'),(33,10,1,'REGION_WARP_ESCAPE')])
            src=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
            self.assertIn('db JOHTO_ROUTE_36_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',src)
            self.assertIn('db JOHTO_ROUTE_36_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',src)
        else:
            raise AssertionError('Unknown review category '+category)


def make_proof(num,cat):
    def run(self):
        self.proof(num,cat)
    run.__name__ = 'test_'+num+'_'+cat
    return run
for _num in CONFIGS:
    for _cat in ('two_lane_warps','directional_collision','immediate_return',
                 'exterior_border_loads','neutral_map_name','gold_art_tile_palette',
                 'runtime_rgb_kanto_isolation','legacy_gate_regression'):
        setattr(StaticParkGates,'test_'+_num+'_'+_cat,make_proof(_num,_cat))
