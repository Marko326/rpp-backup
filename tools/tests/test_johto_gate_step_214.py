"""P18 North/South Gate: execute the exact supported source branch subset.

The ASM branch must only trigger when the player *steps onto* a registered
north-gate warp facing through the door. Normal RPP door-step simulation then
moves one tile away on the destination map (not a door-warp loop).
This is source-branch modelling, not Game Boy CPU simulation.
"""
import os
import re
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_warp_arrival_audit import profiles, audit
from johto_indoor_common import rpp_warps

KEYS={'JOHTO_ILEX_FOREST_LOCAL_ID':'forest','JOHTO_ROUTE_34_LOCAL_ID':'route',
      'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID':'gate',
      'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID':'north_gate'}


def step_warp_exec(source, map_id, y, direction):
    body=source.split('JohtoNorthGateStepWarpAllowed::',1)[1].split('JohtoGateCollisionDirectionAllowed::',1)[0]
    instructions=[];labels={}
    for line in body.splitlines():
        s=line.split(';')[0].strip()
        if not s:continue
        if s.startswith('.') and re.fullmatch(r'\.[A-Za-z_][\w]*',s):labels[s]=len(instructions)
        else:instructions.append(s)
    regs={'[wCurRegion]':'MAP_REGION_JOHTO','[wCurLocalMapID]':map_id,
          '[wYCoord]':y,'[wPlayerDirection]':direction}
    a=b=None;z=False;carry=False;pc=0
    for tick in range(90):
        if pc >= len(instructions):raise ValueError('fell off source branch')
        op=instructions[pc];pc+=1
        if op.startswith('ld a, '):
            arg=op[6:].strip()
            a=regs[arg] if arg in regs else (b if arg=='b' else arg)
        elif op=='ld b, a':b=a
        elif op.startswith('cp '):
            q=op[3:]
            q=b if q=='b' else int(q) if q.isdecimal() else q
            z=(a==q)
        elif op=='and a':carry=False;z=(a==0)
        elif op=='scf':carry=True
        elif op.startswith(('jr ', 'jp ')):
            parts=[x.strip() for x in op[3:].split(',')]
            if len(parts)==1 or (parts[0]=='z' and z) or (parts[0]=='nz' and not z):
                pc=labels[parts[-1]]
        elif op=='ret':return carry
        else:raise ValueError('new source opcode requires review: '+op)
    raise ValueError('source branch exceeded 90 operations')


class GateOneStepContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.branch=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        cls.arrival=profiles((ROOT/'engine/overworld/region_map_lookup.asm').read_text())

    def test_four_directions_at_all_registered_warps(self):
        expected={'JohtoIlexForest': ('JOHTO_ILEX_FOREST_LOCAL_ID', {(1,5):'PLAYER_DIR_UP'}),
                  # Gold Route34 (13/14,37) are WARP_CARPET_DOWN, not STEP_ON.
                  'JohtoRoute34': ('JOHTO_ROUTE_34_LOCAL_ID', {}),
                  'JohtoRoute34IlexForestGate': ('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',{
                      (4,0):'PLAYER_DIR_UP',(5,0):'PLAYER_DIR_UP'}),
                  'JohtoRoute35GoldenrodGate': ('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',{
                      (4,0):'PLAYER_DIR_UP',(5,0):'PLAYER_DIR_UP'})}
        for name,(key,valid) in expected.items():
            for w in rpp_warps(ROOT,name):
                coord=w['x'],w['y']
                for d in ['PLAYER_DIR_UP','PLAYER_DIR_DOWN','PLAYER_DIR_LEFT','PLAYER_DIR_RIGHT']:
                    want=valid.get(coord)==d
                    self.assertEqual(step_warp_exec(self.branch,key,coord[1],d),want,
                                     (name,coord,d))

    def test_old_south_gate_cannot_step_on(self):
        for k in ('JOHTO_ILEX_AZALEA_GATE_LOCAL_ID','JOHTO_AZALEA_TOWN_LOCAL_ID',
                  'JOHTO_ROUTE_31_LOCAL_ID'):
            for y in (0,4,7,10,37,42):
                for d in ('PLAYER_DIR_UP','PLAYER_DIR_DOWN','PLAYER_DIR_LEFT','PLAYER_DIR_RIGHT'):
                    self.assertFalse(step_warp_exec(self.branch,k,y,d),(k,y,d))

    def test_only_down_arrivals_auto_step_and_land_on_floor(self):
        actual=self.arrival
        self.assertEqual(len(actual),23)
        expected_by_map={
            'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID':{(0,4,'D_DOWN'),(0,5,'D_DOWN')},
            'JOHTO_ROUTE_29_LOCAL_ID':{(1,27,'D_DOWN')},
            'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID':{(0,4,'D_DOWN'),(0,5,'D_DOWN')},
            'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID':{(0,4,'D_DOWN'),(0,5,'D_DOWN')},
            'JOHTO_ILEX_FOREST_LOCAL_ID':{(5,1,'D_DOWN')},
            'JOHTO_GOLDENROD_CITY_LOCAL_ID':{(1,19,'D_DOWN')},
            'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID':{(0,4,'D_DOWN'),(0,5,'D_DOWN')},
            'JOHTO_RUINS_OF_ALPH_LOCAL_ID':{(5,7,'D_DOWN')},
            'JOHTO_ROUTE_34_LOCAL_ID':set(),
            'JOHTO_ROUTE_35_LOCAL_ID':{(5,3,'D_DOWN')},
            'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID':{(0,4,'D_DOWN'),(0,5,'D_DOWN')},
            'JOHTO_MAHOGANY_TOWN_LOCAL_ID':{(1,9,'D_DOWN')},
            'JOHTO_ROUTE_43_LOCAL_ID':{(35,17,'D_DOWN')},
            'JOHTO_ROUTE_43_GATE_LOCAL_ID':{(0,4,'D_DOWN'),(0,5,'D_DOWN')}}
        actual_by_map={key:set((y,x,d) for _,local,y,x,source,d in actual if local==key)
                       for key in expected_by_map}
        self.assertEqual(actual_by_map,expected_by_map)
        self.assertEqual(audit(ROOT),[])

    def test_up_arrivals_remain_on_original_warp(self):
        # No simulated input on Forest -> gate bottom / gate -> Route34 south.
        all_profiles={(local,y,x,source) for alias,local,y,x,source,d in self.arrival}
        for local,coords in (
            ('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',[(7,4),(7,5)]),
            ('JOHTO_ROUTE_34_LOCAL_ID',[(37,13),(37,14)]),
            ('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',[(7,4),(7,5)]),
        ):
            for y,x in coords:
                self.assertNotIn((local,y,x,'REGION_NATIVE_MAP_SLOT'),all_profiles)
        # Neither of the new tilesets is a legacy auto-DOWN door tile:
        # when the profile returns E=0, PlayerStepOutFromDoor exits without
        # starting simulated movement.
        doors=(ROOT/'engine/overworld/doors.asm').read_text().split('DoorTileIDPointers:',1)[1].split('OverworldDoorTileIDs:',1)[0]
        self.assertNotRegex(doors,r'dbw\s+JOHTO_GATE\b')
        self.assertNotRegex(doors,r'dbw\s+JOHTO_MODERN\b')
        self.assertIn('db JOHTO_GATE', (ROOT/'data/mapHeaders/JohtoRoute34IlexForestGate.asm').read_text())
        self.assertIn('db JOHTO_MODERN', (ROOT/'data/mapHeaders/JohtoRoute34.asm').read_text())

    def test_mutation_adding_up_step_is_rejected(self):
        src=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        rogue='\tdb REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_34_LOCAL_ID, 37, 13, REGION_NATIVE_MAP_SLOT, D_UP\n'
        marker='\tdb $ff\n'
        original=src.split('GetJohtoWarpArrivalStep::',1)[1].split('GetJohtoCaveMapChangeSFX::',1)[0]
        mutated=original.replace(marker,rogue+marker,1)
        self.assertNotEqual(mutated,original)
        mutated_source=src.replace(original,mutated,1)
        from johto_warp_arrival_audit import profiles
        self.assertEqual(len(profiles(mutated_source)),len(self.arrival)+1)
        self.assertNotEqual(profiles(mutated_source)[2:],self.arrival[2:])

    def test_step_entry_uses_existing_executor_no_new_warp_logic(self):
        src=(ROOT/'home/overworld.asm').read_text()
        b=src.split('CheckWarpsNoCollisionLoop::',1)[1].split('CheckWarpsCollision::',1)[0]
        self.assertRegex(b, r'call IsJohtoSouthGatePortal[\s\S]*?callba JohtoNorthGateStepWarpAllowed[\s\S]*?pop de[\s\S]*?pop bc[\s\S]*?pop hl[\s\S]*?jp c, WarpFound1')
        # Old gates continue using collision, and the new code never forces
        # player movement in the warp detector: only PlayerStepOutFromDoor does.
        self.assertIn('jp CheckWarpsNoCollisionRetry2',b)
        self.assertNotIn('StartSimulatingJoypadStates',b)
        movement=(ROOT/'engine/overworld/npc_movement.asm').read_text()
        self.assertIn('callab GetJohtoWarpArrivalStep',movement)
        self.assertIn('ld a, $1\n\tld [wSimulatedJoypadStatesIndex], a',movement)

    def test_wrong_gate_direction_mutation_detected(self):
        mutated=self.branch.replace('.up\n\tld a, PLAYER_DIR_UP','.up\n\tld a, PLAYER_DIR_DOWN',1)
        self.assertNotEqual(step_warp_exec(mutated,'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',0,'PLAYER_DIR_UP'),True)


if __name__=='__main__':unittest.main()
