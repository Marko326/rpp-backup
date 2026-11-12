#!/usr/bin/env python3
"""REF-367C: bounded instruction interpreter for dormant native ICE terrain ASM.

Executes the actual LR35902 conditional branches for every Gold map cell and
four headings, replacing *only* the previously validated Gold-role reader with
its role bytes. This is NOT a ROM emulator, linker, frame scheduler or sprite
collision test; it does not prove that a live entrypoint exists.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

SOURCE = Path('data/johto_ice_path_stage/ice_path_step_runtime_367c.asm')
GOLD = Path('docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json')
HEADING = {'RIGHT': 1, 'LEFT': 2, 'DOWN': 4, 'UP': 8}
DELTA = {'RIGHT': (1,0), 'LEFT':(-1,0), 'DOWN':(0,1), 'UP':(0,-1)}
NUMBERS = {'PLAYER_DIR_'+d:n for d,n in HEADING.items()}
NUMBERS.update({'JOHTO_ICE_PATH_B1F_LOCAL_ID':95})


def parse_asm(source: str):
    instructions, labels = [], {}
    current = None
    for raw in source.splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        if line.endswith('::'):
            current = line[:-2]
            labels[current] = len(instructions)
            continue
        if (line.endswith(':') or (line.startswith('.') and ' ' not in line)):
            if current is None or not line.startswith('.'):
                raise ValueError('unexpected local label: '+line)
            labels[current+line.rstrip(':')] = len(instructions)
            continue
        if current is None:
            raise ValueError('instruction before global entry: '+line)
        cmd, _, args = line.partition(' ')
        cmd = cmd.lower()
        if cmd not in {'push','pop','ld','cp','jr','jp','inc','dec','call','ret','scf','xor'}:
            raise ValueError('unsupported native opcode: '+cmd)
        instructions.append((current,cmd,[x.strip() for x in args.split(',') if x.strip()]))
    for name in ('JohtoIcePathProbeStep367C','JohtoIcePathContinueSlide367C'):
        if name not in labels:
            raise ValueError('missing native ASM entry: '+name)
    return instructions, labels


def validate_relative_branches(code):
    """Reject out-of-range native JR without assembling or linking a ROM."""
    instructions, labels = code
    widths=[]
    for scope,op,a in instructions:
        if op in {'jr'}: width=2
        elif op in {'jp','call'}: width=3
        elif op == 'ld': width=3 if a[1]=='[wCurLocalMapID]' else (2 if a[1] in NUMBERS or a[1].isdigit() else 1)
        elif op == 'cp': width=2 if a[0] in NUMBERS or a[0].isdigit() else 1
        else: width=1
        widths.append(width)
    offset=[0]
    for width in widths: offset.append(offset[-1]+width)
    problems=[]
    for i,(scope,op,a) in enumerate(instructions):
        if op not in ('jr','jp'):
            continue
        label=a[-1]
        key=scope+label if label.startswith('.') else label
        if key not in labels:
            problems.append('undefined native jump: '+key)
            continue
        if op == 'jr':
            displacement=offset[labels[key]]-offset[i+1]
            if not -128 <= displacement <= 127:
                problems.append(f'native JR out of range: {key}, displacement {displacement}')
    return problems


def execute(code, map_id: int, w: int, h: int, roles: bytes, x: int, y: int,
            heading: int, entry: str, *, initial_e: int = 0, with_state: bool = False):
    instructions, labels = code
    regs = dict(a=0,b=y&255,c=x&255,d=heading&255,e=initial_e&255,h=0,l=0)
    stack, calls = [], []
    pc = labels[entry]
    z = False
    carry = False
    role_reads = 0

    def value(arg):
        if arg in regs:
            return regs[arg]
        if arg == '[wCurLocalMapID]':
            return map_id
        if arg in NUMBERS:
            return NUMBERS[arg]
        return int(arg,0)

    for _ in range(180):
        if not 0 <= pc < len(instructions):
            raise ValueError('invalid native PC')
        scope,op,a = instructions[pc]
        pc += 1
        if op == 'ld':
            if len(a)!=2 or a[0] not in regs:
                raise ValueError('unsupported LD operand: '+str(a))
            regs[a[0]] = value(a[1])&255
        elif op == 'cp':
            if len(a)!=1:
                raise ValueError('invalid CP')
            rhs=value(a[0]);z=regs['a']==rhs;carry=regs['a']<rhs
        elif op in ('inc','dec'):
            if len(a)!=1 or a[0] not in regs:
                raise ValueError('unsupported INC/DEC')
            reg=a[0]
            regs[reg] = (regs[reg]+(1 if op=='inc' else -1))&255
            z = regs[reg]==0
        elif op == 'xor':
            if a != ['a']:
                raise ValueError('unsupported XOR')
            regs['a']=0;z=True;carry=False
        elif op == 'scf':
            if a: raise ValueError('unexpected SCF operands')
            carry=True
        elif op in ('push','pop'):
            if len(a)!=1 or a[0] not in {'bc','de','hl'}:
                raise ValueError('unsupported stack pair')
            pair=a[0]
            if op=='push':
                stack.append((pair,regs[pair[0]],regs[pair[1]]))
            else:
                if not stack or stack[-1][0]!=pair:
                    raise ValueError('unbalanced ASM stack')
                _,hi,lo=stack.pop()
                regs[pair[0]],regs[pair[1]]=hi,lo
        elif op in ('jr','jp'):
            if len(a)==1:
                take=True;label=a[0]
            elif len(a)==2:
                cond,label=a
                take={'z':z,'nz':not z,'c':carry,'nc':not carry}.get(cond)
                if take is None:
                    raise ValueError('bad jump condition '+cond)
            else:
                raise ValueError('unsupported jump: '+str(a))
            if take:
                key=scope+label if label.startswith('.') else label
                if key not in labels:
                    raise ValueError('missing branch label '+key)
                pc=labels[key]
        elif op == 'call':
            if a == ['JohtoIcePathGoldRoleAt367B']:
                role_reads += 1
                # Invalid map, coordinate underflow and map-specific stride all
                # fail closed through the actual staged Gold role byte arrays.
                if (not 0<=regs['c']<w or not 0<=regs['b']<h or map_id not in (70,95,96,97,98)):
                    regs['a']=1
                else:
                    regs['a']=roles[regs['b']*w+regs['c']]
            elif len(a)==1 and a[0] in labels:
                calls.append(pc)
                pc=labels[a[0]]
            else:
                raise ValueError('unapproved CALL '+str(a))
        elif op == 'ret':
            if calls:
                pc=calls.pop()
            else:
                if stack:
                    raise ValueError('unbalanced stack at native return')
                if regs['b'] != y&255 or regs['c'] != x&255 or regs['d'] != heading&255:
                    raise ValueError('native ABI clobbered BC or D')
                return (regs['a'], carry,role_reads,regs['e']) if with_state else (regs['a'], carry,role_reads)
    raise ValueError('possible infinite native execution / exceeded 180 instructions')


def expected(role, map_id, x, y, direction):
    if direction not in HEADING:
        return 0
    src=role(map_id,x,y)
    if src in (1,3):
        return 0
    if src==6 and direction=='UP':
        return 0
    dx,dy=DELTA[direction]
    dst=role(map_id,x+dx,y+dy)
    if dst==1 or (dst==6 and direction=='DOWN') or (dst==7 and direction=='UP') or (dst==8 and direction in ('UP','RIGHT')):
        return 0
    if dst==2: return 2
    if dst==3: return 3 if map_id==95 else 0
    return 1


def audit(root: Path):
    problems=[]
    source=root/SOURCE
    if not source.is_file():
        return ['missing native Ice Path ASM']
    try:
        code=parse_asm(source.read_text(encoding='utf8'))
    except ValueError as e:
        return [str(e)]
    problems.extend(validate_relative_branches(code))
    main=(root/'main.asm').read_text(encoding='utf8')
    if SOURCE.name in main or 'ice_path_role_runtime_367b.asm' in main:
        problems.append('native Ice Path code prematurely linked into ROM')
    contract=json.loads((root/GOLD).read_text(encoding='utf8'))
    names={m['stable_id']:m for m in contract['maps']}
    roles={i:(root/f"data/johto_ice_path_stage/{m['name']}.roles.bin").read_bytes() for i,m in names.items()}
    def role(map_id,x,y):
        m=names.get(map_id)
        if m is None or not (0<=x<m['width_cells'] and 0<=y<m['height_cells']): return 1
        return roles[map_id][y*m['width_cells']+x]

    count=0
    for map_id,m in names.items():
        w,h=m['width_cells'],m['height_cells']
        for y in range(h):
            for x in range(w):
                for direction,heading in HEADING.items():
                    count+=1
                    want=expected(role,map_id,x,y,direction)
                    try:
                        got,c,_=execute(code,map_id,w,h,roles[map_id],x,y,heading,
                                        'JohtoIcePathProbeStep367C')
                    except ValueError as e:
                        problems.append(f'probe {map_id} {x},{y} {direction}: {e}')
                        if len(problems)>25: return problems
                        continue
                    if (got,c)!=(want,bool(want)):
                        problems.append(f'probe {map_id} ({x},{y}) {direction}: native {(got,c)} != Gold {(want,bool(want))}')
                        if len(problems)>25:return problems
                    if role(map_id,x,y)==2:
                        count+=1
                        try:
                            got,c,_=execute(code,map_id,w,h,roles[map_id],x,y,heading,
                                      'JohtoIcePathContinueSlide367C')
                        except ValueError as e:
                            problems.append(f'slide {map_id} {x},{y} {direction}: {e}')
                            if len(problems)>25:return problems
                            continue
                        if (got,c)!=(want,bool(want)):
                            problems.append(f'slide {map_id} ({x},{y}) {direction}: {(got,c)} != {(want,bool(want))}')
                            if len(problems)>25:return problems
    # Unknown stable IDs and byte-wrap boundaries must not expose an ICE step.
    for invalid in (0,69,71,94,100,190,255):
        for direction,heading in HEADING.items():
            got,c,_=execute(code,invalid,40,36,b'\x00'*1440,10,10,heading,
                            'JohtoIcePathProbeStep367C')
            if (got,c)!=(0,False):
                problems.append(f'unknown ID{invalid} permits native ICE movement')
    for map_id,m in names.items():
        w,h=m['width_cells'],m['height_cells']
        for x,y in ((0,0),(w-1,0),(0,h-1),(w-1,h-1)):
            for direction,heading in HEADING.items():
                got,c,_=execute(code,map_id,w,h,roles[map_id],x,y,heading,
                                   'JohtoIcePathProbeStep367C')
                want=expected(role,map_id,x,y,direction)
                if (got,c)!=(want,bool(want)):
                    problems.append(f'boundary {map_id} ({x},{y}) {direction}')
    if problems:
        return problems
    return []


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    args=p.parse_args()
    errors=audit(args.root)
    if errors:
        for e in errors: print('FAIL',e)
        return 1
    print('PASS: native LR35902 ICE probe + forced-heading branches vs 3,060 Gold cells, all directions; dormant, no ROM link')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
