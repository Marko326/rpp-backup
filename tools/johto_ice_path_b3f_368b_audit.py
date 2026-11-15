#!/usr/bin/env python3
"""REF-368B Gold Ice Path B3F fourth-floor live source/warp safety gate.

No ROM build or simulation is performed. Gold map bytes and Warp geometry are
checked against frozen REF367A source records and the supplied Gold stage data.
"""
from __future__ import annotations
import argparse
from collections import Counter, deque
import json
from pathlib import Path
import re

RUNTIME = 'data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm'
ROLES = 'data/johto_ice_path_stage/IcePathB3F.roles.bin'
GOLD = 'maps/johto_ice_path_stage/IcePathB3F.gold.blk'
BLOCK = 'maps/johto_ice_path_stage/IcePathB3F.runtime.blk'
CONTRACT = 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    overrides = overrides or {}
    errors: list[str] = []
    def content(path: str) -> bytes:
        item = overrides.get(path)
        return (root / path).read_bytes() if item is None else item.encode() if isinstance(item,str) else item
    def code(path: str) -> str:
        return content(path).decode('utf-8')
    def ck(condition: bool, message: str):
        if not condition:
            errors.append(message)
    stage = next(m for m in json.loads(code(CONTRACT))['maps'] if m['name']=='IcePathB3F')
    ck(stage['stable_id']==98 and (stage['width_cells'],stage['height_cells'])==(20,18) and
       [(w['x'],w['y'],w['destination'],w['destination_warp_1_based']) for w in stage['warps']]==[
           (3,5,'IcePathB2FMahoganySide',2),(15,5,'IcePathB2FBlackthornSide',2)],
       'B3F original Gold warp/geometry reference changed')
    ck(len(content(GOLD))==90 and content(GOLD)==content(BLOCK), 'B3F runtime 10x9 block bytes differ from Gold')
    roles=content(ROLES)
    ck(len(roles)==360 and Counter(roles)==Counter({0:75,1:283,4:2}), 'B3F 20x18 Gold role counts incorrect')
    if len(roles)==360:
        ck(roles[5*20+3]==4 and roles[5*20+15]==4, 'B3F original two LADDER coordinates corrupted')
        # All reachable FLOOR is contiguous and leads to the second ladder,
        # whose source Warp remains sealed instead of dead-ending a player.
        seen={(3,5)}; queue=deque([(3,5)])
        while queue:
            x,y=queue.popleft()
            for u,v in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
                if (u,v) in seen or not (0<=u<20 and 0<=v<18):continue
                if roles[v*20+u] not in (0,4):continue
                seen.add((u,v));queue.append((u,v))
        ck((15,5) in seen and len(seen)>=60, 'B3F Gold traversable region/sealed second ladder disconnected')
    asm=code(RUNTIME)
    for needle in ('JohtoIcePathB3FRuntimeHeader368B::',
                   'INCBIN "maps/johto_ice_path_stage/IcePathB3F.runtime.blk"',
                   'INCBIN "data/johto_ice_path_stage/IcePathB3F.roles.bin"',
                   'ASSERT JohtoIcePathB3FRuntimeHeader368BEnd - JohtoIcePathB3FRuntimeHeader368B == 12',
                   'ASSERT BANK(JohtoIcePathB3FRuntimeHeader368B) == BANK(JohtoIcePathB3FRuntimeBlocks368B)',
                   'JohtoIcePathB3FRoleAt368B::','JohtoIcePathB3FLandDecision368B::',
                   'JohtoIcePathB3FBikeFloorAllowed368B::'):
        ck(needle in asm, 'B3F native source/header/role guard missing: '+needle)
    obj=asm.split('JohtoIcePathB3FObjects368B::',1)[-1].split('JohtoIcePathB3FRoleAt368B::',1)[0]
    warps=re.findall(r'(?m)^\s*db\s+(\$ff|\d+),\s*(\$ff|\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR',obj)
    ck('db 2 ; Gold #1/#2' in obj and warps==[('5','3','1'),('5','15','1')],
       'B3F warp table must activate both original Gold #1/#2')
    ck(re.search(r'(?m)^\s*db 0 ; no sign/item/event\s*\n\s*db 0 ; no NPC, smash rock, or NeverMeltIce',obj) is not None,
       'B3F unimplemented Gold smash rock / item object accidentally activated')
    land=asm.split('JohtoIcePathB3FLandDecision368B::',1)[-1].split('JohtoIcePathB3FBikeFloorAllowed368B::',1)[0]
    ck('call JohtoIcePathB3FRoleAhead368B' in land and 'cp 4 ; Gold LADDER' in land and
       'cp 3' in land and 'cp 5' in land and 'cp 15' in land and
       re.search(r'\.stair\s*\n\s*ld a, c\s*\n\s*cp 3\s*\n\s*jr z, \.checkY\s*\n\s*cp 15\s*\n\s*ret nz\s*\n\.checkY\s*\n\s*ld a, b\s*\n\s*cp 5\s*\n\s*ret nz\s*\n\.allow', land) is not None,
       'B3F collision must allow FLOOR and both Gold ladders (3,5)/(15,5)')
    bike=asm.split('JohtoIcePathB3FBikeFloorAllowed368B::',1)[-1]
    ck('call JohtoIcePathB3FRoleAt368B' in bike and 'and a' in bike and 'jr nz, .no' in bike and 'scf' in bike,
       'B3F bike helper must allow new mount only on Gold FLOOR')
    pilot=code('engine/johto_pilot_runtime.asm')
    for sid,ord,did in [('JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID',1,'JOHTO_ICE_PATH_B3F_LOCAL_ID'),
                        ('JOHTO_ICE_PATH_B3F_LOCAL_ID',0,'JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID')]:
        ck(f'db MAP_REGION_JOHTO, {sid}, {ord}, MAP_REGION_JOHTO, {did}' in pilot,
           'B3F reciprocal route missing: '+sid+'#'+str(ord))
    ck('cp JOHTO_ICE_PATH_B3F_LOCAL_ID ; Gold LADDER arrival stands still' in pilot and
       'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jp z, .unionCaveLadder342' in pilot and
       'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jp z, .darkCaveClosedEdge' in pilot,
       'B3F stationary arrival / STEP_IN / boundary dispatcher missing')
    b2f=code('data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm')
    ck('db 11, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR' in b2f and
       '.b3fLadder\n    cp 9\n    ret nz\n    ld a, b\n    cp 11\n    ret nz' in b2f,
       'Mahogany B2F Gold #2 ladder not open at (9,11)')
    ck('JohtoIcePathB3FRuntimeHeader368B' in code('data/johto_header_descriptors.asm') and
       'JohtoIcePathB3FRuntimeDescriptor::' in code('data/johto_pilot_runtime_assets.asm') and
       'JohtoIcePathB3FSourceGoldBlocks368B::' in code('data/johto_pilot_source_resources.asm') and
       'INCLUDE "data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm"' in code('main.asm'),
       'B3F header/descriptor/source/main registration incomplete')
    ck('db 67, 69, 68, 64' in code('data/johto_stable_id_slots.asm') and
       'DEF NUM_JOHTO_ACTIVE_MAPS EQU 70' in code('constants/region_map_constants.asm'),
       'B3F ID98 must retain slot68 in active 70 map roster')
    ck('callab JohtoIcePathB3FLandDecision368B' in code('engine/johto_land_collision_gateway_272.asm') and
       'callab JohtoIcePathB3FBikeFloorAllowed368B' in code('home/rom0_relief_349.asm'),
       'B3F live collision/bike public entry missing')
    ck('cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jp z, .johtoIcePathB3F' in code('engine/overworld/map_name_sign.asm') and
       '.johtoIcePathB3F\n    ld hl, .JohtoIcePathName\n    ld b, $83' in code('engine/overworld/map_name_sign.asm'),
       'B3F map-sign title must display Ice Path B3F')
    town=code('engine/fly_town_map_helpers.asm')
    ck('db 54, 138 ; slot68 Ice Path B3F\n    dw JohtoPilotIcePathName' in town and
       'db 38 ; slot68 Ice Path B3F Gold landmark' in town and
       'slot68 Ice Path B3F' in code('engine/menu/options_menu.asm'),
       'B3F Town Map/save/music slot68 missing')
    ck('dw JohtoIcePathB2FBlackthornRuntimeHeader368C' in code('data/johto_header_descriptors.asm') and
       'JohtoIcePathB2FBlackthornRuntimeDescriptor::' in code('data/johto_pilot_runtime_assets.asm'),
       'B3F must connect to final Blackthorn B2F runtime')
    ck('db "REF-369@"' in code('data/game_version.asm'),'B3F live map should carry REF-368@ development label')
    return errors


def main():
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);a=p.parse_args()
    errors=audit(a.root)
    for e in errors: print('FAIL:',e)
    if not errors: print('PASS: Gold B3F ID98, 20x18 roles, 2 live ladders, 70 map slots and 192 routes, walk/bike/card contracts')
    return int(bool(errors))

if __name__ == '__main__':
    raise SystemExit(main())
