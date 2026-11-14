#!/usr/bin/env python3
"""REF-368C Gold B2F Blackthorn source, stair, ledge & registration audit.

Source-only. This is deliberately *not* an RGBDS build or emulator test.
"""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

ROOTFILE = 'data/johto_ice_path_stage/ice_path_b2f_blackthorn_runtime_368c.asm'
ROLES = 'data/johto_ice_path_stage/IcePathB2FBlackthornSide.roles.bin'
GOLD = 'maps/johto_ice_path_stage/IcePathB2FBlackthornSide.gold.blk'
BLOCK = 'maps/johto_ice_path_stage/IcePathB2FBlackthornSide.runtime.blk'
CONTRACT = 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'
ROUTE = 'engine/johto_pilot_runtime.asm'


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    overrides = overrides or {}
    issues: list[str] = []
    def content(path: str) -> bytes:
        replacement = overrides.get(path)
        return (root / path).read_bytes() if replacement is None else replacement.encode() if isinstance(replacement, str) else replacement
    def code(path: str) -> str: return content(path).decode()
    def ck(cond: bool, label: str):
        if not cond: issues.append(label)
    stage = next(m for m in json.loads(code(CONTRACT))['maps'] if m['name'] == 'IcePathB2FBlackthornSide')
    ck(stage['stable_id'] == 97 and (stage['width_cells'], stage['height_cells']) == (10, 18)
       and [(w['x'],w['y'],w['destination'],w['destination_warp_1_based']) for w in stage['warps']] ==
       [(3,15,'IcePathB1F',8),(3,3,'IcePathB3F',2)], 'Gold B2F Blackthorn warp / geometry contract changed')
    ck(len(content(GOLD)) == 45 and content(GOLD) == content(BLOCK), 'B2F Blackthorn Gold/runtime .blk divergence')
    roles = content(ROLES)
    rolecounts = {'FLOOR':36, 'WALL':43, 'ICE':91, 'LADDER':2, 'UP_WALL':3, 'HOP_DOWN':4, 'HOP_DOWN_LEFT':1}
    ck(len(roles) == 180 and Counter(roles) == Counter({0:36,1:43,2:91,4:2,6:3,7:4,8:1})
       and stage['role_counts']==rolecounts, 'B2F Blackthorn original Gold role grid/counts corrupted')
    if len(roles) == 180:
        ck(roles[3*10+3] == 4 and roles[15*10+3] == 4, 'B2F Gold both LADDER cells corrupted')
        hops = [(5,8,'PLAYER_DIR_LEFT'),(5,8,'PLAYER_DIR_DOWN')] + [(x,8,'PLAYER_DIR_DOWN') for x in range(6,10)]
        for x,y,direction in hops:
            value = roles[y*10+x]
            ck(value == (8 if x==5 else 7), f'Gold one-way hop role bad at {(x,y)}')
            nx,ny=(x-2,y) if direction=='PLAYER_DIR_LEFT' else (x,y+2)
            ck(0<=nx<10 and 0<=ny<18 and roles[ny*10+nx] in (0,2,4),
               f'Gold hop landing non-walkable at {(nx,ny)}')
    asm=code(ROOTFILE)
    for needle in ('JohtoIcePathB2FBlackthornRuntimeHeader368C::', 'db 9, 5',
        'INCBIN "maps/johto_ice_path_stage/IcePathB2FBlackthornSide.runtime.blk"',
        'INCBIN "data/johto_ice_path_stage/IcePathB2FBlackthornSide.roles.bin"',
        'ASSERT JohtoIcePathB2FBlackthornRuntimeHeader368CEnd - JohtoIcePathB2FBlackthornRuntimeHeader368C == 12',
        'ASSERT BANK(JohtoIcePathB2FBlackthornRuntimeHeader368C) == BANK(JohtoIcePathB2FBlackthornRuntimeBlocks368C)',
        'JohtoIcePathB2FBlackthornRoleAt368C::','JohtoIcePathB2FBlackthornLandDecision368C::',
        'JohtoIcePathB2FBlackthornBikeFloorAllowed368C::', 'cp 18', 'cp 10', 'add hl, de ; 10*y'):
        ck(needle in asm, 'B2F Blackthorn source/header/width guard missing: '+needle)
    try:
        from tools.johto_warp_field_entry_gate import warp_objects, registered_routes
        warps = warp_objects(asm, 'JohtoIcePathB2FBlackthornObjects368C')
        ck(warps == [(3,15,7),(3,3,1)], 'B2F Blackthorn two Gold warp objects/ordinals incorrect')
        routes = registered_routes(code(ROUTE))
        ck(len(routes)==188 and len(set(routes))==188,'B2F Blackthorn global route count/uniqueness !=188')
        pairs=[('JOHTO_ICE_PATH_B1F_LOCAL_ID',7,'JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID'),
               ('JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID',0,'JOHTO_ICE_PATH_B1F_LOCAL_ID'),
               ('JOHTO_ICE_PATH_B3F_LOCAL_ID',1,'JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID'),
               ('JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID',1,'JOHTO_ICE_PATH_B3F_LOCAL_ID')]
        for src,ordinal,dst in pairs:
            ck(f'MAP_REGION_JOHTO,{src},{ordinal},MAP_REGION_JOHTO,{dst}' in routes,
               f'B2F Blackthorn reciprocal route absent: {src} #{ordinal} -> {dst}')
    except (ValueError, KeyError, IndexError, ImportError) as ex:
        issues.append('B2F Blackthorn route/object parse failure: '+str(ex))
    obj=asm.split('JohtoIcePathB2FBlackthornObjects368C::',1)[-1].split('JohtoIcePathB2FBlackthornRoleAt368C::',1)[0]
    ck('db 0 ; no hidden Ice Heal' in obj and 'db 0 ; no TM Rest/item objects' in obj,
       'B2F unimplemented items/NPC objects accidentally activated')
    land=asm.split('JohtoIcePathB2FBlackthornLandDecision368C::',1)[-1].split('JohtoIcePathB2FBlackthornBikeFloorAllowed368C::',1)[0]
    ck('call JohtoIcePathB2FBlackthornRoleAhead368C' in land and all('cp '+str(x) in land for x in (1,2,4,6,7,8,15))
       and '.currentDownLeftHop' in land and '.stair' in land and 'cp 3' in land,
       'B2F Blackthorn collision must handle ICE, UP_WALL, directed HOP, 2 LADDERs')
    bike=asm.split('JohtoIcePathB2FBlackthornBikeFloorAllowed368C::',1)[-1]
    ck('call JohtoIcePathB2FBlackthornRoleAt368C' in bike and 'and a' in bike and 'jr nz, .no' in bike and 'scf' in bike,
       'B2F Blackthorn bike mount must be FLOOR-only')
    ledges=code('engine/overworld/ledges.asm')
    hopstr=ledges.split('JohtoIcePathBlackthornGoldHops368C:',1)[-1].split('JohtoUnionCaveB1FGoldHops:',1)[0]
    hops=re.findall(r'(?m)^\s*db (\d+), (\d+), (PLAYER_DIR_\w+)',hopstr)
    ck(hops == [('5','8','PLAYER_DIR_LEFT'),('5','8','PLAYER_DIR_DOWN')] + [(str(x),'8','PLAYER_DIR_DOWN') for x in range(6,10)]
       and 'db $ff' in hopstr,'B2F Blackthorn Gold directional ledge table changed')
    ck('cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID' in ledges and
       'ld hl, JohtoIcePathBlackthornGoldHops368C' in ledges and
       'jp .ruinsCoordinateHopLookup' in ledges and
       'jp .scan' in ledges,
       'B2F directional ledge dispatch / forced hop-landing guard missing')
    gateway=code('engine/johto_land_collision_gateway_272.asm')
    ck('callab HandleLedges' in gateway.split('.icePathB2FBlackthorn',1)[-1].split('.darkCave',1)[0] and
       'callab JohtoIcePathB2FBlackthornLandDecision368C' in gateway,
       'B2F Blackthorn ledge + collision native public dispatch missing')
    ck('callab JohtoIcePathB2FBlackthornBikeFloorAllowed368C' in code('home/rom0_relief_349.asm'),
       'B2F Blackthorn bike public dispatch missing')
    ck('db 27, 11, 0, JOHTO_REGISTERED_WARP_SELECTOR' in code('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm') and
       'db 5, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR' in code('data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm'),
       'B2F Blackthorn B1F #8 (11,27)/B3F predecessor stairs not live')
    pilot=code(ROUTE)
    ck('cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID ; Gold LADDER arrival stands still' in pilot and
       'cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID\n    jr z, .unionCaveLadder342' in pilot and
       'cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID\n    jp z, .darkCaveClosedEdge' in pilot,
       'B2F Blackthorn stationary arrival, STEP_IN or edge dispatcher missing')
    ck('dw JohtoIcePathB2FBlackthornRuntimeHeader368C' in code('data/johto_header_descriptors.asm') and
       'JohtoIcePathB2FBlackthornRuntimeDescriptor::' in code('data/johto_pilot_runtime_assets.asm') and
       'JohtoIcePathB2FBlackthornSourceGoldBlocks368C::' in code('data/johto_pilot_source_resources.asm') and
       'INCLUDE "data/johto_ice_path_stage/ice_path_b2f_blackthorn_runtime_368c.asm"' in code('main.asm'),
       'B2F Blackthorn runtime header/descriptor/source/main registration incomplete')
    ck('DEF NUM_JOHTO_ACTIVE_MAPS EQU 70' in code('constants/region_map_constants.asm') and
       'db 67, 69, 68, 64' in code('data/johto_stable_id_slots.asm'),
       'B2F Blackthorn ID97 must occupy slot69 of 70 active maps')
    ck('cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID\n    jp z, .johtoIcePathB2F' in code('engine/overworld/map_name_sign.asm'),
       'B2F Blackthorn name sign must display Ice Path B2F')
    town=code('engine/fly_town_map_helpers.asm')
    ck('db 54, 138 ; slot69 Ice Path B2F Blackthorn Side' in town and
       'db 38 ; slot69 Ice Path B2F Blackthorn Side Gold landmark' in town and
       'slot69 Ice Path B2F Blackthorn temporary cave theme' in code('engine/menu/options_menu.asm'),
       'B2F Blackthorn Town Map / music slot69 missing')
    ck('db "REF-368@"' in code('data/game_version.asm'), 'REF-368@ developer version missing')
    return issues


def main() -> int:
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]); args=p.parse_args()
    issues=audit(args.root)
    for x in issues:print('FAIL:',x)
    if not issues:print('PASS: REF368C Gold B2F Blackthorn ID97, 10x18 roles, two stairs, six directed hops, 70 active maps / 188 routes')
    return bool(issues)

if __name__ == '__main__':raise SystemExit(main())
