#!/usr/bin/env python3
"""Fail-closed source+runtime contract for MAP-268 multi-map Gold water masks.

Checks that 0/1/2 byte-per-cell geometry is exactly derived from Gold quadrants,
that all three Surf entry paths use the same map-scoped predicate, and that
no Kanto or non-batch map can be classified as south water. Static only.
"""
from __future__ import annotations
import json, re, sys, argparse
from pathlib import Path
from johto_gold_door_audit import GoldCollisionIndex
from johto_ilex_217_geometry import expected_runtime as expected_runtime_ilex

BATCH = ('AzaleaTown','IlexForestAzaleaGate','IlexForest','Route34IlexForestGate','Route34','GoldenrodCity')
WATER = {'IlexForest':32, 'Route34':226, 'GoldenrodCity':84}
ROLES_PASS = {'FLOOR','TALL_GRASS','HOP_DOWN','HOP_LEFT','HOP_DOWN_LEFT',
              'HOP_DOWN_RIGHT','WARP_CARPET_LEFT','WARP_CARPET_RIGHT',
              'WARP_CARPET_UP','WARP_CARPET_DOWN','DOOR'}

def audit(root:Path,gold:Path)->dict:
    root=Path(root); index=GoldCollisionIndex(gold)
    errors=[]
    geom=(root/'engine/johto_south_geometry.asm').read_text()
    water=re.sub(r";[^\n]*", "", (root/'engine/johto_violet_field_skills.asm').read_text())
    constants=(root/'constants/region_map_constants.asm').read_text()
    src=(root/'data/johto_pilot_source_resources.asm').read_text()
    entry='JohtoSouthGoldWaterProbe'
    for fragment in ('JohtoSouthSpatialRoleAhead::',entry+'::','call JohtoSouthSpatialRoleAhead',
                     'cp 2','scf','ld a, [wCurLocalMapID]',
                     'cp JOHTO_RUNTIME_MAP_HANDLE','cp MAP_REGION_JOHTO'):
        if fragment not in geom:errors.append('missing required geometry predicate '+fragment)
    if 'NUM_JOHTO_ACTIVE_MAPS EQU 21' not in constants:
        errors.append('active map count not 21')
    for tileset in ('JOHTO_MODERN','JOHTO_ILEX_FOREST','JOHTO_SOUTH_GATE'):
        if not re.search(r'\bcp '+tileset+r'\s+jp z, \.southModern',water):
            errors.append('Surf movement not routed for '+tileset)
    # FIX-275: nonwater must be checked against the same WALKABLE land
    # predicate before ending Surf. The former generic tilecoll fallback is
    # empty for Ilex; source water recognition alone never proves a landing.
    if not re.search(r'\.southModern\s+callab '+entry+r'\s+jp c, \.water\s+'
                     r'callab JohtoSouthGoldShoreProbe\s+jp c, \.floorShore\s+'
                     r'jp \.shore',water):
        errors.append('Surf movement must distinguish Gold water, safe land and blocked shore')
    if ('JohtoSouthGoldShoreProbe::' not in geom
        or 'call JohtoSouthSpatialStep' not in geom.split('JohtoSouthGoldShoreProbe::', 1)[1]
        .split('JohtoSouthGoldWaterProbe::', 1)[0]):
        errors.append('safe Surf landing must reuse mature land collision')
    if not re.search(r'callab '+entry+r'\s+ret c',water):
        errors.append('Surfboard/HM gateway lacks carry-safe shared water predicate')
    for name in BATCH:
        gold_cells=index.cells(name)
        width=max(x for x,_ in gold_cells)+1
        height=max(y for _,y in gold_cells)+1
        mask_path=root/'maps/johto_pilot'/f'{name}.roles.bin'
        runtime_path=root/'maps/johto_pilot'/f'{name}.runtime.blk'
        source_path=root/'maps/johto_pilot'/f'{name}.gold.blk'
        expected=[]
        for y in range(height):
            for x in range(width):
                role=gold_cells[(x,y)]['role']
                expected.append(2 if role=='WATER' else (0 if role in ROLES_PASS else 1))
        if not mask_path.is_file() or bytes(expected)!=mask_path.read_bytes():
            errors.append(name+': Gold cell role grid mismatch')
        if name in WATER and expected.count(2)!=WATER[name]:
            errors.append(name+': wrong Gold water count')
        if name not in WATER and 2 in expected:
            errors.append(name+': unregistered Gold water found')
        # Gold source is immutable, but accepted ILEX-217 must clone exactly
        # six block positions so its tile-pair HOP engine sees $40..$42.
        if not source_path.is_file() or not runtime_path.is_file():
            errors.append(name+': missing source/runtime block layout')
        else:
            original = source_path.read_bytes()
            expected_runtime = (expected_runtime_ilex(original) if name=='IlexForest' else original)
            if runtime_path.read_bytes()!=expected_runtime:
                errors.append(name+': candidate runtime layout differs from source-approved clone contract')
        if (f'JohtoSouth{name}Roles:: INCBIN "maps/johto_pilot/{name}.roles.bin"' not in geom
            or f'cp JOHTO_' not in geom):
            errors.append(name+': no runtime grid registration')
        if f'JohtoSouth{name}GoldBlocks::' not in src:
            errors.append(name+': no active source descriptor')
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'errors':errors,'maps':len(BATCH),'water_cells':sum(WATER.values()),
            'rom_built':False,'device_verified':False}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path.cwd());p.add_argument('--gold',type=Path,required=True)
    a=p.parse_args()
    try:result=audit(a.root,a.gold)
    except (OSError,ValueError,KeyError,IndexError,AttributeError) as exc:
        result={'status':'FAIL','errors':[str(exc)]}
    print(json.dumps(result,ensure_ascii=False,indent=2))
    sys.exit(0 if result['status']=='PASS_STATIC_ONLY' else 1)
