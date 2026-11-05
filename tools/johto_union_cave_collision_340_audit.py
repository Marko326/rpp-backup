#!/usr/bin/env python3
"""REF-340 Union Cave exact Gold land/surf collision audit.

Checks the real 16x16 movement graph, not just block art or Warp rows.
The RBY runtime uses a tile whitelist, while Gold's CAVE collision includes
UP_WALL directional LAND.  The REF-340 hotfix must bridge that semantic gap.
"""
from pathlib import Path
from collections import Counter
import re, json, sys

ROOT=Path(__file__).resolve().parents[1]
GOLD=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path('/mnt/data/gold_reference')
MAPS=('UnionCave1F','UnionCaveB1F','UnionCaveB2F')
LOCAL={'UnionCave1F':'JOHTO_UNION_CAVE_1F_LOCAL_ID',
       'UnionCaveB1F':'JOHTO_UNION_CAVE_B1F_LOCAL_ID',
       'UnionCaveB2F':'JOHTO_UNION_CAVE_B2F_LOCAL_ID'}
DIRS={'UP':(0,-1),'DOWN':(0,1),'LEFT':(-1,0),'RIGHT':(1,0)}
LAND={'FLOOR','LADDER','WARP_CARPET_DOWN','UP_WALL','HOP_RIGHT'}


def parse_gold_collisions():
    rows={}
    for line in (GOLD/'data/tilesets/cave_collision.asm').read_text().splitlines():
        m=re.search(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})',line)
        if m:
            rows[int(m.group(2),16)]=[v.strip() for v in m.group(1).split(',')]
    assert len(rows)==64
    return rows

COLL=parse_gold_collisions()
BST=(ROOT/'gfx/blocksets/johto_union_cave.bst').read_bytes()
PASS=set((ROOT/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes())-{0xff}
FIELD=(ROOT/'engine/johto_violet_field_skills.asm').read_text()
GATEWAY=(ROOT/'engine/johto_land_collision_gateway_272.asm').read_text()


def table(label):
    body=FIELD.split(label+'::',1)[1].split(label+'End::',1)[0]
    vals=[]
    for y,x in re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*$',body):
        vals.append((int(y),int(x)))
    return vals

UP={
 'UnionCave1F':set(table('JohtoUnionCave1FUpWallCells')),
 'UnionCaveB1F':set(table('JohtoUnionCaveB1FUpWallCells')),
 'UnionCaveB2F':set(table('JohtoUnionCaveB2FUpWallCells')),
}
HOP=set(table('JohtoUnionCaveB1FHopRightCells'))

errors=[]
summary={}
for name in MAPS:
    gold=(GOLD/'maps'/f'{name}.blk').read_bytes()
    run=(ROOT/'maps/johto_pilot'/f'{name}.runtime.blk').read_bytes()
    assert len(gold)==len(run)==180
    def role(x,y):
        bid=gold[(y//2)*10+x//2]
        return COLL[bid][(y%2)*2+(x%2)]
    def probe(x,y):
        bid=run[(y//2)*10+x//2]
        off=((y&1)*2+1)*4+(x&1)*2
        return BST[bid*16+off]

    gold_up={(y,x) for y in range(36) for x in range(20) if role(x,y)=='UP_WALL'}
    if UP[name] != gold_up:
        errors.append(f'{name}: UP_WALL table mismatch missing={sorted(gold_up-UP[name])[:6]} extra={sorted(UP[name]-gold_up)[:6]}')
    if name=='UnionCaveB1F':
        gold_hop={(y,x) for y in range(36) for x in range(20) if role(x,y)=='HOP_RIGHT'}
        if HOP != gold_hop:
            errors.append(f'{name}: HOP_RIGHT table mismatch {HOP} != {gold_hop}')

    land_mismatch=[]
    surf_mismatch=[]
    checked_land=checked_surf=0
    for y in range(36):
      for x in range(20):
        sr=role(x,y)
        if sr in LAND:
          for d,(dx,dy) in DIRS.items():
            tx,ty=x+dx,y+dy
            expected=False
            if 0<=tx<20 and 0<=ty<36:
                tr=role(tx,ty)
                expected=tr in LAND
                if expected and d=='UP' and sr=='UP_WALL': expected=False
                if expected and d=='DOWN' and tr=='UP_WALL': expected=False
            # Model the actual hotfix + legacy fallback.
            if not (0<=tx<20 and 0<=ty<36):
                actual=False
            elif d=='UP' and (y,x) in UP[name]:
                actual=False
            elif (ty,tx) in UP[name]:
                actual=(d!='DOWN')
            elif name=='UnionCaveB1F' and (ty,tx) in HOP:
                actual=True
            else:
                actual=probe(tx,ty) in PASS
            checked_land+=1
            if actual!=expected:
                land_mismatch.append((x,y,d,tx,ty,sr,role(tx,ty) if 0<=tx<20 and 0<=ty<36 else 'OFF',expected,actual))
        if sr=='WATER':
          for d,(dx,dy) in DIRS.items():
            tx,ty=x+dx,y+dy
            if not (0<=tx<20 and 0<=ty<36):
                expected='block'; actual='block'
            else:
                tr=role(tx,ty)
                if tr=='WATER': expected='water'
                elif tr in LAND and not (tr=='UP_WALL' and d=='DOWN'): expected='land'
                else: expected='block'
                if tr=='WATER': actual='water'
                elif (ty,tx) in UP[name] and d!='DOWN': actual='land'
                elif name=='UnionCaveB1F' and (ty,tx) in HOP: actual='land'
                else: actual='land' if probe(tx,ty) in PASS else 'block'
            checked_surf+=1
            if actual!=expected:
                surf_mismatch.append((x,y,d,tx,ty,expected,actual))
    if land_mismatch:
        errors.append(f'{name}: land mismatches {len(land_mismatch)} first={land_mismatch[:5]}')
    if surf_mismatch:
        errors.append(f'{name}: surf mismatches {len(surf_mismatch)} first={surf_mismatch[:5]}')
    summary[name]={
        'up_wall_cells':len(UP[name]),
        'land_moves_checked':checked_land,
        'land_mismatches':len(land_mismatch),
        'surf_moves_checked':checked_surf,
        'surf_mismatches':len(surf_mismatch),
    }

# Source routing contracts: all three floors must enter the exact Gold helper.
for const in LOCAL.values():
    if f'cp {const}' not in GATEWAY:
        errors.append(f'gateway missing {const}')
for token in ('callab JohtoUnionCaveGoldLandDecision','callab HandleLedges'):
    if token not in GATEWAY: errors.append(f'gateway missing {token}')
for token in ('call JohtoUnionCaveSpecialShoreAhead','JohtoUnionCaveGoldLandDecision::','JohtoUnionCaveSpecialShoreAhead::'):
    if token not in FIELD: errors.append(f'field helper missing {token}')

# Non-vacuous negative control: remove one B2F UP_WALL coordinate and prove
# that at least one Gold-permitted move would fall back to the old solid tile.
if UP['UnionCaveB2F']:
    name='UnionCaveB2F'
    gold=(GOLD/'maps'/f'{name}.blk').read_bytes()
    run=(ROOT/'maps/johto_pilot'/f'{name}.runtime.blk').read_bytes()
    def neg_role(x,y):
        bid=gold[(y//2)*10+x//2]
        return COLL[bid][(y%2)*2+(x%2)]
    def neg_probe(x,y):
        bid=run[(y//2)*10+x//2]
        off=((y&1)*2+1)*4+(x&1)*2
        return BST[bid*16+off]
    removed=next(iter(UP[name]))
    mutated=set(UP[name]); mutated.remove(removed)
    negative_mismatches=0
    for y in range(36):
      for x in range(20):
        if neg_role(x,y) not in LAND: continue
        for d,(dx,dy) in DIRS.items():
            tx,ty=x+dx,y+dy
            if not (0<=tx<20 and 0<=ty<36): continue
            tr=neg_role(tx,ty)
            expected=tr in LAND
            if expected and d=='UP' and neg_role(x,y)=='UP_WALL': expected=False
            if expected and d=='DOWN' and tr=='UP_WALL': expected=False
            if d=='UP' and (y,x) in mutated: actual=False
            elif (ty,tx) in mutated: actual=(d!='DOWN')
            else: actual=neg_probe(tx,ty) in PASS
            negative_mismatches += int(actual != expected)
    if negative_mismatches == 0:
        errors.append(f'negative control failed after removing B2F UP_WALL {removed}')
    summary['negative_control']={'removed_b2f_up_wall':removed,'mismatches':negative_mismatches}

print(json.dumps({'ok':not errors,'summary':summary,'errors':errors},ensure_ascii=False,indent=2))
raise SystemExit(1 if errors else 0)
