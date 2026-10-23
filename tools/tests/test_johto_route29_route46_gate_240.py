"""Gold Route29/Route46 single-DOOR + paired-carpet gate: executable evidence.

STATIC evidence only. The two doorway lanes and phone visuals remain PENDING.
"""
import json
import os
from pathlib import Path
import re
import unittest

from johto_gatehouse_behavior_audit import audit as behavior_audit, predicate, object_warps
from johto_gold_door_audit import gold_collision_index
from johto_indoor_tiles_converter import build_mapping
from johto_warp_arrival_audit import profiles

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',os.environ.get('JOHTO_GOLD_ROOT','/missing-Gold')))
GATE='JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID'
R29='JOHTO_ROUTE_29_LOCAL_ID'
R46='JOHTO_ROUTE_46_LOCAL_ID'
DIRECTIONS=('UP','DOWN','LEFT','RIGHT')


def trace_route46_carpet(source, mask, x, y, direction):
    """Strictly run REAL .maskRoute46 assembly, then the real blocked-map bit.

    Interpreter scope intentionally narrow: unsupported instruction is a hard
    error. No manifest-derived hardcoded door rules in the executor itself.
    """
    start=source.split('JohtoEastCanStepAhead::',1)[1]
    start=start.split('JohtoEastMaskedStep::',1)[0]
    program=[]; labels={}; active=False
    for line in start.splitlines():
        stmt=line.split(';',1)[0].strip()
        if stmt=='.maskRoute46': active=True
        if not active or not stmt: continue
        if re.fullmatch(r'\.[A-Za-z]\w*',stmt): labels[stmt]=len(program)
        else: program.append(stmt)
    if '.maskRoute46' not in labels: raise ValueError('real Route46 carpet caller missing')
    vals={'wYCoord':y,'wXCoord':x,'wPlayerDirection':'PLAYER_DIR_'+direction}
    coords={'UP':(0,-1),'DOWN':(0,1),'LEFT':(-1,0),'RIGHT':(1,0)}
    a=None; zero=False; pc=labels['.maskRoute46']
    for _ in range(100):
        if pc>=len(program): raise ValueError('ASM ran outside carpet routine')
        op=program[pc];pc+=1
        m=re.fullmatch(r'ld a,\[(w\w+)\]',op)
        if m: a=vals[m[1]];continue
        m=re.fullmatch(r'cp (\d+|PLAYER_DIR_\w+)',op)
        if m:
            v=int(m[1]) if m[1].isdigit() else m[1]
            if type(a)!=type(v): raise ValueError('ASM bad carpet compare '+op)
            zero=(a==v);continue
        m=re.fullmatch(r'(jr|jp)\s+(?:(z|nz),\s*)?(\.\w+|JohtoEastMaskedStep)',op)
        if m:
            _, condition, target=m.groups()
            if condition=='z' and not zero or condition=='nz' and zero:continue
            if target=='JohtoEastMaskedStep':
                dx,dy=coords[direction]; tx,ty=x+dx,y+dy
                if not (0<=tx<20 and 0<=ty<36): return True
                return bool(mask[ty*3+tx//8] & 1<<(tx%8))
            if target not in labels: raise ValueError('ASM unknown jump '+target)
            pc=labels[target];continue
        if op=='xor a': a=0;zero=True;continue
        if op=='ld e,a':continue
        if op=='ret':
            if a!=0:raise ValueError('unreviewed carpet return value')
            return False
        if op.startswith('ld hl,') or op.startswith('ld d,') or op.startswith('ld e,'):
            continue  # pointer/stride prep; actual mask bit checked on jump
        raise ValueError('uninterpretable Route46 carpet ASM: '+op)
    raise ValueError('ASM carpet interpreter budget exceeded')


class Route29Route46Gate240(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route29Route46Gate.asm').is_file():
            raise RuntimeError('complete original Gold checkout required')
        cls.gold=gold_collision_index(GOLD)
        cls.runtime=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        cls.east=(ROOT/'engine/overworld/johto_east_exterior.asm').read_text()
        cls.home=(ROOT/'home/overworld.asm').read_text()
        cls.lookup=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        cls.ids={}
        for path in ('constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm'):
            cls.ids.update({symbol:int(value) for symbol,value in re.findall(
                r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\d+)',(ROOT/path).read_text())})
        cls.contract=next(r for r in json.loads((ROOT/'tools/johto_door_contracts.json').read_text())['active_warp_maps']
                          if r['rpp_map']=='JohtoRoute29Route46Gate')

    def test_gold_warp_graph(self):
        outside29=object_warps((ROOT/'data/mapObjects/JohtoRoute29.asm').read_text(),'JohtoRoute29')
        outside46=object_warps((ROOT/'data/mapObjects/JohtoRoute46.asm').read_text(),'JohtoRoute46')
        inside=object_warps((ROOT/'data/mapObjects/JohtoRoute29Route46Gate.asm').read_text(),'JohtoRoute29Route46Gate')
        self.assertEqual(outside29,[(1,27,2,'REGION_WARP_ESCAPE')])
        self.assertEqual(outside46,[(33,7,0,'REGION_WARP_ESCAPE'),(33,8,1,'REGION_WARP_ESCAPE')])
        self.assertEqual(inside,[(0,4,0,'REGION_WARP_ESCAPE'),(0,5,1,'REGION_WARP_ESCAPE'),
                                 (7,4,0,'REGION_WARP_ESCAPE'),(7,5,0,'REGION_WARP_ESCAPE')])
        g=(GOLD/'maps/Route29Route46Gate.asm').read_text()
        self.assertEqual({(int(x),int(y)) for x,y in re.findall(r'warp_event\s+(\d+),\s*(\d+)',g)},
                         {(4,0),(5,0),(4,7),(5,7)})
        self.assertEqual(len(self.contract['gatehouse_runtime']['native_routes']),6)
        for origin,src,target,dest in self.contract['gatehouse_runtime']['native_routes']:
            self.assertIn(f'db {origin}, {src}, {target}, MAP_REGION_JOHTO, {dest}',self.lookup)
        self.assertIn(f'db JOHTO_ROUTE_29, 0, 2, MAP_REGION_JOHTO, {GATE}',
                      self.lookup.split('ExplicitWarpRegionTargets::',1)[1].split('NativeRegionWarpTargets::',1)[0])
        self.assertEqual(len((ROOT/'maps/JohtoRoute29Route46Gate.blk').read_bytes()),20)

    def test_trigger_and_direction(self):
        approaches=[(R29,27,1,'UP','STEP_ON'),(R46,7,33,'DOWN','COLLISION_ONLY'),
                    (R46,8,33,'DOWN','COLLISION_ONLY')]
        approaches += [(GATE,x,y,dr,mode) for y,dr,mode in
                       ((0,'UP','STEP_ON'),(7,'DOWN','COLLISION_ONLY')) for x in (4,5)]
        gold_maps={R29:'Route29',R46:'Route46',GATE:'Route29Route46Gate'}
        for local,x,y,wanted,mode in approaches:
            role=self.gold.role_at(gold_maps[local],x,y)
            self.assertEqual(role,'DOOR' if mode=='STEP_ON' else 'WARP_CARPET_DOWN')
            for direction in DIRECTIONS:
                with self.subTest(local=local,x=x,y=y,direction=direction):
                    self.assertEqual(predicate(self.runtime,'JohtoNorthGateStepWarpAllowed',local,x,y,direction),
                                     mode=='STEP_ON' and direction==wanted)
                    self.assertEqual(predicate(self.runtime,'JohtoGateCollisionDirectionAllowed',local,x,y,direction),
                                     direction==wanted)
                    if local in (R29,R46):
                        self.assertEqual(predicate(self.runtime,'JohtoInternalDoorFacingCheck',local,x,y,direction),
                                         direction==wanted)
        # Legacy Route29 $F4 source must be exact, never any other alias/local/region.
        self.assertTrue(predicate(self.home,'IsJohtoSouthGatePortal',R29,27,1,'UP',self.ids,alias='JOHTO_ROUTE_29'))
        for local,alias,region,x,y in [(R29,'REGION_NATIVE_MAP_SLOT','MAP_REGION_JOHTO',27,1),
                                      (R29,'JOHTO_ROUTE_31','MAP_REGION_JOHTO',27,1),
                                      (R29,'JOHTO_ROUTE_29','MAP_REGION_KANTO',27,1),
                                      (R29,'JOHTO_ROUTE_29','MAP_REGION_JOHTO',28,1),
                                      (R29,'JOHTO_ROUTE_29','MAP_REGION_JOHTO',27,2)]:
            self.assertFalse(predicate(self.home,'IsJohtoSouthGatePortal',local,x,y,'UP',
                                       const_values=self.ids,region=region,alias=alias))
        for local,x,y in [(R46,7,33),(R46,8,33),(GATE,4,0),(GATE,5,0),(GATE,4,7),(GATE,5,7)]:
            self.assertTrue(predicate(self.home,'IsJohtoSouthGatePortal',local,x,y,'DOWN',self.ids))
            self.assertFalse(predicate(self.home,'IsJohtoSouthGatePortal',local,x,y,'DOWN',self.ids,
                                       alias='JOHTO_ROUTE_31'))

    def test_arrival_and_immediate_return(self):
        found={(alias,local,y,x):move for alias,local,y,x,from_map,move in profiles(self.lookup)}
        self.assertEqual(found[('JOHTO_ROUTE_29',R29,1,27)],'D_DOWN')
        for x in (4,5):
            self.assertEqual(found[('REGION_NATIVE_MAP_SLOT',GATE,0,x)],'D_DOWN')
        for local,y,x in [(GATE,7,4),(GATE,7,5),(R46,33,7),(R46,33,8)]:
            self.assertNotIn(('REGION_NATIVE_MAP_SLOT',local,y,x),found)
        for x in (4,5):
            self.assertEqual(self.gold.role_at('Route29Route46Gate',x,0),'DOOR')
            self.assertEqual(self.gold.role_at('Route29Route46Gate',x,1),'FLOOR')
            self.assertEqual(self.gold.role_at('Route29Route46Gate',x,7),'WARP_CARPET_DOWN')
        self.assertEqual(self.gold.role_at('Route29',27,2),'FLOOR')
        mask=(ROOT/'maps/JohtoRoute29Route46Gate.blocked_mask.bin').read_bytes()
        for x,y in [(4,1),(5,1),(4,6),(5,6)]:
            self.assertFalse(mask[y*2+x//8] & 1<<(x%8),(x,y))
        self.assertEqual(behavior_audit(ROOT,GOLD),[])

    def test_exteriors_and_border_loads(self):
        # Route29 has a separate previously approved RPP original layout;
        # do not rewrite that asset while enabling only its Warp object.
        self.assertEqual((ROOT/'maps/JohtoRoute46.blk').read_bytes(),(GOLD/'maps/Route46.blk').read_bytes())
        r29=(ROOT/'data/mapHeaders/JohtoRoute29.asm').read_text()
        r46=(ROOT/'data/mapHeaders/JohtoRoute46.asm').read_text()
        self.assertIn('db NORTH | WEST | EAST',r29)
        self.assertIn('db SOUTH | EAST',r46)
        self.assertIn('dw JohtoRoute46Blocks + JOHTO_ROUTE_46_WIDTH',r29)
        self.assertIn('dw JohtoRoute29Blocks + 10',r46)
        home=(ROOT/'home/overworld.asm').read_text()
        self.assertIn('LoadMapData::',home)
        self.assertIn('.ordinaryConnection',home)
        self.assertEqual((ROOT/'maps/JohtoRoute46.blocked_mask.bin').stat().st_size,108)
        for x in (7,8):
            self.assertEqual(self.gold.role_at('Route46',x,32),'FLOOR')
            self.assertEqual(self.gold.role_at('Route46',x,33),'WARP_CARPET_DOWN')
            self.assertEqual(self.gold.role_at('Route46',x,34),'WALL')
        # Execute the actual Route46 carpet override in the walkable path.
        mask=(ROOT/'maps/JohtoRoute46.blocked_mask.bin').read_bytes()
        for x in (7,8):
            for y,direction,blocked in [(32,'DOWN',False),(33,'DOWN',True),(33,'UP',False)]:
                self.assertEqual(trace_route46_carpet(self.east,mask,x,y,direction),blocked,(x,y,direction))
        self.assertFalse(trace_route46_carpet(self.east,mask,7,33,'RIGHT'))
        self.assertFalse(trace_route46_carpet(self.east,mask,8,33,'LEFT'))

    def test_neutral_map_name(self):
        signs=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
        self.assertIn('cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID\n\tret z',signs)
        self.assertIn('db JOHTO_GATE',(ROOT/'data/mapHeaders/JohtoRoute29Route46Gate.asm').read_text())
        self.assertNotIn('Route 29',(ROOT/'scripts/JohtoRoute29Route46Gate.asm').read_text())

    def test_exact_gold_gate_art(self):
        mapping,expected=build_mapping(ROOT,GOLD,'Route29Route46Gate','gate','johto_gate')
        self.assertEqual(mapping['unmapped'],[])
        self.assertEqual(mapping['exact_mapped'],mapping['used_unique_blocks'])
        self.assertEqual((ROOT/'maps/JohtoRoute29Route46Gate.blk').read_bytes(),expected)
        self.assertEqual((ROOT/'maps/JohtoRoute29Route46Gate.blk').read_bytes(),
                         (ROOT/'maps/JohtoRoute35GoldenrodGate.blk').read_bytes())
        self.assertEqual((ROOT/'maps/JohtoRoute29Route46Gate.blocked_mask.bin').read_bytes(),
                         (ROOT/'maps/JohtoRoute35GoldenrodGate.blocked_mask.bin').read_bytes())

    def test_palette_kanto_isolation(self):
        header=(ROOT/'data/mapHeaders/JohtoRoute29Route46Gate.asm').read_text()
        self.assertIn('db JOHTO_GATE',header)
        script=(ROOT/'scripts/JohtoRoute29Route46Gate.asm').read_text()
        self.assertNotIn('RGB',script)
        self.assertEqual(self.contract['runtime_palette_status'],'PHONE_PENDING')
        self.assertEqual(self.contract['phone_visual_status'],'PHONE_ACCEPTED')
        # RGB and Kanto gate isolation are independently audited inside behavior_audit.
        self.assertEqual(behavior_audit(ROOT,GOLD),[])

    def test_old_gate_and_seam_regression(self):
        src=(ROOT/'data/johto_map_headers.asm').read_text()
        for old in ('JohtoRoute31VioletGate_h','JohtoRoute34IlexForestGate_h',
                    'JohtoRoute43Gate_h','JohtoRoute32RuinsOfAlphGate_h'):
            self.assertIn('dw '+old,src)
        self.assertEqual(len(self.contract['gatehouse_proof_ids']),8)
        self.assertEqual(self.contract['phone_door_status'],'PHONE_ACCEPTED')
        self.assertEqual(behavior_audit(ROOT,GOLD),[])

    def test_wrong_warp_route_fails(self):
        changed=self.lookup.replace(f'{GATE}, 3, 0, MAP_REGION_JOHTO, {R29}',
                                    f'{GATE}, 3, 1, MAP_REGION_JOHTO, {R29}',1)
        self.assertNotEqual(self.lookup,changed)
        self.assertTrue(behavior_audit(ROOT,GOLD,overrides={'engine/overworld/region_map_lookup.asm':changed}))

    def test_missing_carpet_entry_fails(self):
        path='data/mapObjects/JohtoRoute46.asm'
        original=(ROOT/path).read_text()
        changed=original.replace('db 33, 8, 1, REGION_WARP_ESCAPE','db 33, 8, 2, REGION_WARP_ESCAPE',1)
        self.assertNotEqual(original,changed)
        self.assertTrue(behavior_audit(ROOT,GOLD,overrides={path:changed}))

    def test_wrong_direction_fails(self):
        changed=self.runtime.replace('cp 33\n jp nz, .denied\n ld a, [wXCoord]\n cp 7\n jp z, .down',
                                     'cp 33\n jp nz, .denied\n ld a, [wXCoord]\n cp 7\n jp z, .up',1)
        self.assertNotEqual(changed,self.runtime)
        self.assertTrue(behavior_audit(ROOT,GOLD,overrides={'engine/overworld/johto_route33_collision.asm':changed}))

    def test_missing_arrival_step_fails(self):
        old=f'db REGION_NATIVE_MAP_SLOT, {GATE}, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN'
        changed=self.lookup.replace(old,old.replace('D_DOWN','D_UP'),1)
        self.assertNotEqual(changed,self.lookup)
        self.assertTrue(behavior_audit(ROOT,GOLD,overrides={'engine/overworld/region_map_lookup.asm':changed}))

    def test_removed_route46_mat_walk_fails(self):
        original=self.east
        changed=original.replace('cp 32\n jr z,.route46AboveCarpets','cp 31\n jr z,.route46AboveCarpets',1)
        self.assertNotEqual(original,changed)
        for x in (7,8):
            self.assertTrue(trace_route46_carpet(changed,(ROOT/'maps/JohtoRoute46.blocked_mask.bin').read_bytes(),x,32,'DOWN'))

if __name__=='__main__': unittest.main()
