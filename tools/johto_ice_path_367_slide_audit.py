#!/usr/bin/env python3
"""REF-367D dormant LR35902 slide-heading controller audit.

Executes the REAL ASM control flow using the bounded REF-367C interpreter;
only the validated Gold role-array reader is stubbed.  This neither assembles
ROMs nor proves overworld hooks, sprite occupancy or animation timing.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.johto_ice_path_367_native_audit import (
    HEADING, parse_asm, execute, validate_relative_branches, expected,
)

CORE = Path('data/johto_ice_path_stage/ice_path_step_runtime_367c.asm')
SLIDE = Path('data/johto_ice_path_stage/ice_path_slide_state_367d.asm')
GOLD = Path('docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json')


def audit(root: Path) -> list[str]:
    problems=[]
    for rel in (CORE, SLIDE, GOLD):
        if not (root / rel).is_file():
            return [f'missing slide audit prerequisite {rel}']
    source=(root / SLIDE).read_text(encoding='utf8')
    combined=(root / CORE).read_text(encoding='utf8')+'\n'+source
    try:
        code=parse_asm(combined)
    except ValueError as exc:
        return [f'invalid native ASM: {exc}']
    problems+=validate_relative_branches(code)
    if 'JohtoIcePathArmSlide367D' not in code[1] or 'JohtoIcePathResolveSlide367D' not in code[1] or 'JohtoIcePathClearSlide367D' not in code[1]:
        return problems+['incomplete slide-heading native entry points']
    for path in ('main.asm', 'home/overworld.asm'):
        if SLIDE.name in (root / path).read_text(encoding='utf8'):
            problems.append(f'unsafe premature Ice Path slide linking: {path}')
    contract=json.loads((root/GOLD).read_text(encoding='utf8'))
    def run(map_id,w,h,roles,x,y,heading,entry,previous=0):
        return execute(code,map_id,w,h,roles,x,y,heading,entry,initial_e=previous,with_state=True)
    for m in contract['maps']:
        mid=m['stable_id'];w=m['width_cells'];h=m['height_cells']
        roles=(root / f"data/johto_ice_path_stage/{m['name']}.roles.bin").read_bytes()
        if len(roles)!=w*h:
            problems.append(f'{m["name"]}: wrong role byte length')
            continue
        def role(_id,x,y):
            return roles[y*w+x] if _id==mid and 0<=x<w and 0<=y<h else 1
        for y in range(h):
            for x in range(w):
                here=role(mid,x,y)
                for heading in HEADING.values():
                    try:
                        got,carry,_,state=run(mid,w,h,roles,x,y,heading,'JohtoIcePathArmSlide367D')
                        armed=here==2
                        if (got,carry,state)!=(heading if armed else 0,armed,heading if armed else 0):
                            problems.append(f'arm {mid} ({x},{y}) heading {heading}: {(got,carry,state)}')
                        # When sliding, a newly pressed opposite direction must
                        # NOT steer the player until ICE ends or the route blocks.
                        user=heading ^ 0xf  # arbitrary divergent direction
                        want_force=here==2 and bool(expected(role,mid,x,y,next(k for k,v in HEADING.items() if v==heading)))
                        got,carry,_,state=run(mid,w,h,roles,x,y,user,'JohtoIcePathResolveSlide367D',heading)
                        if (got,carry,state)!=(heading if want_force else user,want_force,heading if want_force else 0):
                            problems.append(f'continue {mid} ({x},{y}) heading {heading}: {(got,carry,state)}')
                    except (ValueError,KeyError,IndexError) as exc:
                        problems.append(f'native slide execution {mid} ({x},{y}): {exc}')
                    if len(problems)>30:return problems
        # ICE warp landing must not create heading without a real walking step.
        for warp in m['warps']:
            if warp['role']=='ICE':
                x,y=warp['x'],warp['y']
                try:
                    got,carry,_,state=run(mid,w,h,roles,x,y,0,'JohtoIcePathResolveSlide367D',0)
                    if (got,carry,state)!=(0,False,0):
                        problems.append(f'{m["name"]} arrival-only ICE auto-slides')
                except ValueError as exc:
                    problems.append(str(exc))
    # Invalid and stale saved headings are inert. A map departure must clear.
    for bad in (0,3,5,16,255):
        roles=bytes([2])*1440
        for entry,mid,prior in [('JohtoIcePathResolveSlide367D',70,bad),
                                ('JohtoIcePathResolveSlide367D',190,4)]:
            a,c,_,e=run(mid,40,36,roles,1,1,8,entry,prior)
            if (a,c,e)!=(8,False,0):
                problems.append(f'bad or unsupported slide state {mid}/{prior}: {(a,c,e)}')
    a,c,_,e=run(70,40,36,bytes([2])*1440,1,1,8,'JohtoIcePathClearSlide367D',4)
    if (a,c,e)!=(0,False,0):problems.append('reset slide must clear heading and carry')
    # No hidden reuse of the byte that existing item routines already write.
    if 'wUnusedD71F' in '\n'.join(line.split(';',1)[0] for line in source.splitlines()):
        problems.append('slide controller uses shared item scratch wUnusedD71F')
    return problems


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    ns=ap.parse_args()
    errors=audit(ns.root)
    for err in errors:print('FAIL',err)
    if errors:return 1
    print('PASS: dormant native slide state arming, forced heading, blocking, invalid state and ICE arrival guards across 3,060 Gold cells')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
