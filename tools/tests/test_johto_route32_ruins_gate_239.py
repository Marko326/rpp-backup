"""Gold-independent (source-backed) Route32<->Ruins east-west gatehouse contract.

These are static execution proofs, NOT emulator/phone acceptance.
"""
import json
import os
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gold_door_audit import gold_collision_index
from johto_gold_sources import gold_block_sources
from johto_gatehouse_behavior_audit import predicate, object_warps, audit as gate_audit
from johto_masked_step_audit import parse_caller,trace_masked_step
from johto_gate_rgb_audit import verify as verify_rgb

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('JOHTO_GOLD_ROOT') or '/INVALID_GOLD_ROOT')
GATE='JohtoRoute32RuinsOfAlphGate'
ID='JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'
R32='JOHTO_ROUTE_32_LOCAL_ID'
RUINS='JOHTO_RUINS_OF_ALPH_LOCAL_ID'


class RuinsGate239(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'data/maps/blocks.asm').exists():
            raise AssertionError('Original Gold source must be provided via JOHTO_GOLD_SOURCE')
        cls.doc=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        cls.gate=next(x for x in cls.doc['active_warp_maps'] if x['rpp_map']==GATE)
        cls.collision=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()

    def mask_step(self,stem,symbol,w,h,x,y,d):
        program,labels=parse_caller(self.collision,symbol)
        mask=(ROOT/f'maps/{stem}.blocked_mask.bin').read_bytes()
        return trace_masked_step(program,labels,mask,w,h,ID if stem==GATE else RUINS,x,y,d)[0]

    def test_two_lane_warps(self):
        runtime=self.gate['gatehouse_runtime']
        raw=object_warps((ROOT/f'data/mapObjects/{GATE}.asm').read_text(),GATE)
        self.assertCountEqual(raw,[tuple(row) for side in runtime['warp_sides'].values() for row in side])
        gold_rows=re.findall(r'(?m)^\s*warp_event\s+(\d+),\s*(\d+),',(GOLD/f'maps/Route32RuinsOfAlphGate.asm').read_text())
        self.assertEqual({(int(y),int(x)) for x,y in gold_rows},{(y,x) for y,x,_,_ in raw})
        region=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        subset=region.split('NativeRegionWarpTargets::',1)[1].split('SelectNativeMapConnection::',1)[0]
        real={(a,int(i),int(j),b) for a,i,j,b in re.findall(r'(?m)^\s*db\s+(JOHTO_\w+),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s*(JOHTO_\w+)\s*$',subset)}
        self.assertEqual({x for x in real if ID in (x[0],x[3])},set(tuple(x) for x in runtime['native_routes']))
        self.assertEqual(len(raw),4)

    def test_directional_collision(self):
        index=gold_collision_index(GOLD)
        names={ID:'Route32RuinsOfAlphGate',RUINS:'RuinsOfAlphOutside',R32:'Route32'}
        for spec in self.gate['gatehouse_runtime']['approaches']:
            local,x,y,wanted=spec['map_local'],spec['x'],spec['y'],spec['direction']
            role=index.role_at(names[local],x,y)
            self.assertEqual(role,'WARP_CARPET_'+wanted)
            for d in ('UP','DOWN','LEFT','RIGHT'):
                self.assertEqual(predicate(self.collision,'JohtoGateCollisionDirectionAllowed',local,x,y,d),d==wanted,(spec,d))
                self.assertFalse(predicate(self.collision,'JohtoNorthGateStepWarpAllowed',local,x,y,d),(spec,d))
                if spec.get('outside_guard'):
                    self.assertEqual(predicate(self.collision,'JohtoInternalDoorFacingCheck',local,x,y,d),d==wanted,(spec,d))

    def test_immediate_return(self):
        # Four actual gate boundary carpets standable from inside; a second
        # direction collision (not an extra auto-step) transfers either way.
        for x,d,adjacent,inward in ((0,'LEFT',1,'RIGHT'),(9,'RIGHT',8,'LEFT')):
            for y in (4,5):
                self.assertFalse(self.mask_step(GATE,'JohtoRoute32RuinsOfAlphGateCanStepAhead',10,8,adjacent,y,d))
                self.assertTrue(self.mask_step(GATE,'JohtoRoute32RuinsOfAlphGateCanStepAhead',10,8,x,y,d))
                self.assertFalse(self.mask_step(GATE,'JohtoRoute32RuinsOfAlphGateCanStepAhead',10,8,x,y,'DOWN' if y==4 else 'UP'))
        # Ruins exterior's ROMX masked-step predicate permits entering both mats.
        for y in (20,21):
            self.assertFalse(self.mask_step('JohtoRuinsOfAlphOutside','JohtoRuinsOfAlphCanStepAhead',20,36,12,y,'RIGHT'))
            self.assertTrue(self.mask_step('JohtoRuinsOfAlphOutside','JohtoRuinsOfAlphCanStepAhead',20,36,13,y,'RIGHT'))
        # Route32 remains legacy $FB: do not invent a native blocked mask.
        home=(ROOT/'home/overworld.asm').read_text()
        self.assertIn('cp JOHTO_ROUTE_32\n\tjr z, .legacyRuinsGate',home)
        self.assertIn('callba JohtoRoute32RuinsGateFacingCheck',home)
        self.assertIn('callba JohtoGateCollisionDirectionAllowed',home)

    def test_exterior_border_loads(self):
        golden=(GOLD/gold_block_sources(GOLD)['Route32RuinsOfAlphGate']).read_bytes()
        self.assertEqual(golden,(ROOT/f'maps/{GATE}.blk').read_bytes())
        self.assertEqual(len(golden),5*4)
        home=(ROOT/'home/overworld.asm').read_text()
        self.assertEqual(home.count('callba PatchJohtoMapBordersAfterBlockLoad'),2)
        self.assertIn('callba PatchJohtoMapBordersAfterBlockLoad',home.split('LoadMapData::',1)[1].split('; HAX: Padding',1)[0])
        self.assertIn('callba PatchJohtoMapBordersAfterBlockLoad',home.split('.ordinaryConnection\n',1)[1].split('.didNotEnterConnectedMap',1)[0])

    def test_neutral_map_name(self):
        src=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
        fragment=src.split('\n.IsNeutralMap\n',1)[1].split('\n.legacyMap\n',1)[0]
        self.assertRegex(fragment,rf'cp {ID}\s+ret z')

    def test_gold_art_tile_palette(self):
        self.assertEqual((ROOT/'gfx/blocksets/johto_ruins_gate.bst').read_bytes(),(GOLD/'data/tilesets/gate_metatiles.bin').read_bytes())
        self.assertEqual((ROOT/'gfx/tilesets/johto_ruins_gate.png').read_bytes(),(GOLD/'gfx/tilesets/gate.png').read_bytes())
        self.assertEqual((ROOT/'color/tilesets/johto_ruins_gate.asm').read_text().splitlines(),(GOLD/'gfx/tilesets/gate_palette_map.asm').read_text().splitlines()[:12])
        self.assertEqual((ROOT/f'maps/{GATE}.blk').read_bytes(),(GOLD/gold_block_sources(GOLD)['Route32RuinsOfAlphGate']).read_bytes())

    def test_runtime_rgb_kanto_isolation(self):
        self.assertEqual(verify_rgb(ROOT,GOLD),[])
        self.assertIn('tileset JohtoRuinsGate_Block, JohtoRuinsGate_GFX, Gate_Coll',(ROOT/'data/tileset_headers.asm').read_text())
        self.assertIn('INCLUDE "color/tilesets/johto_ruins_gate.asm"',(ROOT/'color/data/map_palette_assignments.asm').read_text())
        self.assertNotRegex((ROOT/'engine/overworld/doors.asm').read_text(),r'(?m)^\s*dbw\s+JOHTO_RUINS_GATE')

    def test_legacy_gate_regression(self):
        self.assertEqual(object_warps((ROOT/'data/mapObjects/JohtoRoute32.asm').read_text(),'JohtoRoute32')[0],(79,6,0,'REGION_WARP_ESCAPE'))
        self.assertEqual(object_warps((ROOT/'data/mapObjects/JohtoRuinsOfAlphOutside.asm').read_text(),'JohtoRuinsOfAlphOutside')[0],(5,7,2,'REGION_WARP_ESCAPE'))
        self.assertEqual(object_warps((ROOT/'data/mapObjects/JohtoRoute36.asm').read_text(),'JohtoRoute36')[:2],[(13,47,0,'REGION_WARP_ESCAPE'),(13,48,1,'REGION_WARP_ESCAPE')])
        self.assertEqual(gate_audit(ROOT,GOLD),[])
        # Actively reverse the gate's first carpet direction: fail closed.
        good='cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID\n\tjp z, .route32RuinsGate'
        self.assertIn(good,self.collision)
        bad=self.collision.replace(good,'cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID\n\tjp z, .denied',1)
        failures=gate_audit(ROOT,GOLD,{'engine/overworld/johto_route33_collision.asm':bad})
        self.assertTrue(failures, 'Fault injection must be detected')


if __name__=='__main__':unittest.main()
