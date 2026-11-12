#!/usr/bin/env python3
"""Fail-closed REF-367K Gold Ice Path B1F live map and ladder review."""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

CONTRACT = 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'
ROLE = 'data/johto_ice_path_stage/IcePathB1F.roles.bin'

def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    def get(path: str) -> bytes:
        value = overrides.get(path)
        return (root / path).read_bytes() if value is None else value.encode() if isinstance(value,str) else value
    def code(path: str) -> str:
        return get(path).decode('utf8')
    errs: list[str] = []
    def ck(ok: bool, label: str):
        if not ok: errs.append(label)
    contract = json.loads(code(CONTRACT)); gold = next(m for m in contract['maps'] if m['name']=='IcePathB1F')
    ck((gold['stable_id'],gold['width_cells'],gold['height_cells'])==(95,20,36),'Gold B1F ID/dim mismatch')
    ck(get('maps/johto_ice_path_stage/IcePathB1F.gold.blk')==get('maps/johto_ice_path_stage/IcePathB1F.runtime.blk'),'B1F runtime visual blocks differ from Gold')
    role=get(ROLE)
    ck(len(role)==720 and role.count(3)==4 and role.count(4)==4 and role.count(2)==44,'B1F Gold role population mismatch')
    if len(role)==720:
        for x,y,expect in [(3,15,4),(5,25,4),(17,3,4),(11,27,4),(11,2,3),(4,7,3),(5,12,3),(12,13,3)]:
            ck(role[y*20+x]==expect,f'Gold B1F stair/PIT role mismatch ({x},{y})')
        for x,y in [(11,7),(7,8),(8,9),(17,7)]:
            ck(role[y*20+x]==0,f'Gold Strength pre-activation FLOOR coordinate altered ({x},{y})')
    asm=code('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm')
    one=code('data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm')
    wh=asm.split('JohtoIcePathB1FObjects367K::',1)[-1].split('JohtoIcePathB1FRoleAt367K::',1)[0]
    rows=re.findall(r'(?m)^\s*db\s+(\$ff|\d+),\s*(\$ff|\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR\s*$', '\n'.join(l.split(';')[0] for l in wh.splitlines()))
    expected=[('15','3','2'),('$ff','$ff','1'),('$ff','$ff','2'),('$ff','$ff','3'),('$ff','$ff','4'),('$ff','$ff','5'),('25','5','3'),('$ff','$ff','7')]
    ck(rows==expected,'B1F Gold 8 ordinal objects invalid / B2F/PIT prematurely unsealed')
    # REF-367M: text IDs 1..4 on the visible props are live even when
    # pushing is disabled. A missing entry makes DisplayTextID interpret the
    # warp/object bytes as 16-bit text pointers (e.g. an unrelated nurse menu).
    text_table = asm.split('JohtoIcePathB1FTextPointers367K:', 1)[-1].split('JohtoIcePathB1FTextPointers367KEnd::', 1)[0]
    text_refs = re.findall(r'(?m)^\s*dw\s+([A-Za-z_][A-Za-z_0-9]*)\s*(?:;[^\n]*)?$', text_table)
    ck(text_refs == ['JohtoIcePathB1FStaticStoneText367M'] * 4,
       'B1F four boulder text IDs do not have four valid in-bank pointers (nurse dialogue leak)')
    ck(bool(re.search(r'(?m)^ASSERT\s+JohtoIcePathB1FTextPointers367KEnd\s*-\s*JohtoIcePathB1FTextPointers367K\s*==\s*4\s*\*\s*2\s*$', asm)),
       'B1F four text pointers have no assembly-length assertion')
    text_body = asm.split('JohtoIcePathB1FStaticStoneText367M:', 1)[-1].split('JohtoIcePathB1FObjects367K::', 1)[0]
    ck('JohtoIcePathB1FStaticStoneText367M:' in asm and
       bool(re.search(r'(?m)^\s*text\s+"A heavy boulder\."\s*$', text_body)) and
       bool(re.search(r'(?m)^\s*line\s+"It won\'t budge\."\s*$', text_body)) and
       bool(re.search(r'(?m)^\s*done\s*$', text_body)) and
       bool(re.search(r'(?m)^\s*db\s+"@"\s*$', text_body)),
       'B1F fixed stone interaction text missing/invalid (nurse dialogue leak)')
    ck('ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FTextPointers367K)' in asm and
       'ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FStaticStoneText367M)' in asm,
       'B1F four boulder text pointers are not guaranteed in same ROM bank')
    ck('call EnableAutoTextBoxDrawing' in asm.split('JohtoIcePathB1FScript367K::',1)[-1].split('JohtoIcePathB1FTextPointers367K:',1)[0],
       'B1F ordinary text engine is not enabled for the four fixed boulders')
    # REF-367L: four hard-coded blockers MUST be represented by visible boulder
    # objects at the same world coordinates (x,y), with movement disabled.
    objects_section = wh.split('db 0 ; no sign / item / encounter', 1)[-1]
    match = re.search(r'(?m)^\s*db\s+(\d+)\s*$', objects_section)
    ck(match is not None and int(match.group(1)) == 4, 'B1F fixed boulder sprite count != 4 (invisible air wall)')
    boulder_records = re.findall(
        r'(?m)^\s*object\s+SPRITE_BOULDER,\s*(\d+),\s*(\d+),\s*STAY,\s*NONE,\s*\$(\w+)\s*$',
        objects_section)
    expected_boulders = [(11,7,1),(7,8,2),(8,9,3),(17,7,4)]
    actual_boulders = [(int(x),int(y),int(n,16)) for x,y,n in boulder_records]
    ck(actual_boulders == expected_boulders, 'Gold Strength boulder coordinate lacks visible immovable sprite (invisible air wall)')
    # The four Gold FLOOR locations are temporarily occupied by these sprites.
    # Never silently block a bare floor cell, nor allow a blocked stone to lack
    # a corresponding visible object.
    step_gate = asm.split('JohtoIcePathB1FRoleAhead367K::', 1)[-1].split('JohtoIcePathB1FLandDecision367K::',1)[0]
    for x,y,_ in expected_boulders:
        # Exact guards are verified by a small independent translation of the
        # assembly's four branches so renumbering one silently fails the audit.
        if y == 7:
            matched = bool(re.search(r'\bcp\s+7\s*\n\s*jr nz,\s*\.y8',step_gate)) and bool(re.search(rf'\bcp\s+{x}\s*\n\s*jr z,\s*\.blocked',step_gate))
        elif y == 8:
            matched = bool(re.search(r'\bcp\s+8\s*\n\s*jr nz,\s*\.y9',step_gate)) and bool(re.search(rf'\bcp\s+{x}\s*\n\s*jr z,\s*\.blocked',step_gate))
        else:
            matched = bool(re.search(r'\bcp\s+9\s*\n\s*jr nz,\s*\.read',step_gate)) and bool(re.search(rf'\bcp\s+{x}\s*\n\s*jr z,\s*\.blocked',step_gate))
        ck(matched, f'B1F boulder ({x},{y}) static collision guard missing')
    ck('db 8 ; original Gold #1-#8 SOURCE slots' in asm,'B1F eight warp objects header missing')
    ck('db 18, 10' in asm and 'db JOHTO_ICE_PATH' in asm,'B1F Gold runtime header missing')
    ck('INCLUDE "data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm"' in code('main.asm'),'B1F native runtime not linked')
    ck('JohtoIcePathB1FRuntimeHeader367K' in code('data/johto_header_descriptors.asm'),'B1F header not registered')
    ck('JohtoIcePathB1FRuntimeDescriptor::' in code('data/johto_pilot_runtime_assets.asm'),'B1F runtime descriptor not registered')
    ck('JOHTO_ICE_PATH_B1F_LOCAL_ID' in code('engine/johto_land_collision_gateway_272.asm') and 'callab JohtoIcePathB1FLandDecision367K' in code('engine/johto_land_collision_gateway_272.asm'),'B1F movement not linked')
    ck('JohtoIcePathB1FRoleAhead367K::' in asm and 'JohtoIcePathB1FLandDecision367K::' in asm,'B1F Gold role collision missing')
    for check in ('cp 3 ; PIT', 'cp 4 ; LADDER', 'cp 11', 'cp 17', 'cp 7', 'cp 8'):
        ck(check in asm, f'B1F collision safety gate missing {check}')
    ck('cp JOHTO_ICE_PATH_B1F_LOCAL_ID' in code('home/rom0_relief_349.asm'),'B1F bike mounting dispatch missing')
    sign=code('engine/overworld/map_name_sign.asm')
    ck(bool(re.search(r'\.johtoIcePathB1F\s*\n\s*ld hl, \.JohtoIcePathName\s*\n\s*ld b, \$81',sign)),'Ice Path B1F floor popup missing basement tag')
    lines=code('engine/johto_pilot_runtime.asm')
    for source,ord,target in [('JOHTO_ICE_PATH_1F_LOCAL_ID',2,'JOHTO_ICE_PATH_B1F_LOCAL_ID'),('JOHTO_ICE_PATH_B1F_LOCAL_ID',0,'JOHTO_ICE_PATH_1F_LOCAL_ID'),('JOHTO_ICE_PATH_1F_LOCAL_ID',3,'JOHTO_ICE_PATH_B1F_LOCAL_ID'),('JOHTO_ICE_PATH_B1F_LOCAL_ID',6,'JOHTO_ICE_PATH_1F_LOCAL_ID')]:
        ck(f'db MAP_REGION_JOHTO, {source}, {ord}, MAP_REGION_JOHTO, {target}' in lines,f'B1F reciprocal route missing {source}#{ord}')
    ck('db 5, 37, 0, JOHTO_REGISTERED_WARP_SELECTOR' in one and 'db 13, 37, 6, JOHTO_REGISTERED_WARP_SELECTOR' in one,'1F both original Gold stair objects sealed/changed')
    ck(bool(re.search(r'(?m)^\s*jr nz, \.notLadder367K\s*$', one)) and not re.search(r'(?m)^\s*jr nz, \.notLadder367K:', one), '1F Gold ladder JR operand has illegal label colon')
    ck('cp JOHTO_ICE_PATH_1F_LOCAL_ID' in lines and 'jr z, .icePathLadderOrCarpet367K' in lines and 'cp 37' in lines and 'jr z, .unionCaveLadder342' in lines,'1F LADDER not immediate STEP_IN')
    ck('cp JOHTO_ICE_PATH_B1F_LOCAL_ID' in lines and 'jr z, .unionCaveLadder342' in lines,'B1F return LADDER not immediate STEP_IN')
    ck('cp JOHTO_ICE_PATH_B1F_LOCAL_ID ; Gold LADDER arrivals stand still' in lines,'B1F ladder arrival must not auto-step')
    ck('NUM_JOHTO_ACTIVE_MAPS EQU 67' in code('constants/region_map_constants.asm'),'active map roster not raised to 67')
    ck('db "REF-367@"' in code('data/game_version.asm'),'official label not REF-367@')
    return errs

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);args=p.parse_args()
    problems=audit(args.root)
    for problem in problems: print('FAIL:', problem)
    if not problems:print('PASS: B1F two stair pairs, four fixed visible boulders with safe in-bank dialogue, B2F/PIT sealed')
    raise SystemExit(bool(problems))
