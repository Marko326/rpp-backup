#!/usr/bin/env python3
"""Source-level interpreter for shared ROMX gatehouse inbound carpet handler.

Tests the actual small ASM instruction stream + data table, rather than a
reimplemented floor whitelist. Explicitly NOT a Game Boy emulator or ROM link.
"""
from __future__ import annotations
import re
from pathlib import Path

SYMBOL = 'JohtoGateHorizontalCarpetInbound303::'
TABLE = 'JohtoGateHorizontalCarpetProfiles303::'

def _load(code, constants):
    head = code.split(TABLE, 1)[1].split(SYMBOL, 1)[0]
    raw_rows = re.findall(r'(?m)^\s*db\s+([^;\n]+)', head)
    records = []
    for row in raw_rows:
        for item in row.split(','):
            token=item.strip()
            if token in constants: n=constants[token]
            elif token.startswith('$'): n=int(token[1:],16)
            elif token.isdecimal(): n=int(token)
            else: raise ValueError('unknown table constant: '+token)
            if not 0<=n<=255: raise ValueError('byte outside range')
            records.append(n)
    if not records or records[-1] != 255 or (len(records)-1)%5:
        raise ValueError('invalid gate profile sentinel/size')
    asm=code.split(SYMBOL,1)[1].split('JohtoRoute42CutClearedAhead300:',1)[0]
    labels={}; instr=[]
    for raw in asm.splitlines():
        line=raw.split(';',1)[0].strip()
        if not line: continue
        if re.fullmatch(r'\.[A-Za-z][\w]*',line): labels[line]=len(instr)
        else:
            op,_,oper=line.partition(' ')
            instr.append((op,oper.strip()))
    if not instr or '.find' not in labels: raise ValueError('missing instruction entry/loop')
    return records,labels,instr

def evaluate(code, constants, map_id, x, y, direction):
    table, labels, instr = _load(code,constants)
    direction_code='PLAYER_DIR_'+direction
    registers={'a':0,'b':0,'c':0,'d':0,'e':0,'hl':0}
    mem={'[wCurLocalMapID]':map_id,'[wXCoord]':x,'[wYCoord]':y,'[wPlayerDirection]':direction_code}
    zero=False; carry=False; pc=0
    def val(t):
        if t in registers: return registers[t]
        if t in mem: return mem[t]
        if t in constants: return constants[t]
        if t=='JohtoGateHorizontalCarpetProfiles303': return 0
        if t.startswith('PLAYER_DIR_'): return t
        if t.startswith('$'): return int(t[1:],16)
        if t.isdecimal(): return int(t)
        if t=='[hl]': return table[registers['hl']]
        if t=='[hli]':
            v=table[registers['hl']]; registers['hl']+=1; return v
        raise ValueError('unsupported operand '+t)
    for _ in range(180):
        if not 0<=pc<len(instr): raise ValueError('escaped shared helper')
        op,oper=instr[pc]; pc+=1
        if op=='ld':
            reg,rhs=(t.strip() for t in oper.split(',',1))
            if reg == 'de':
                n=val(rhs); registers['d']=(n>>8)&255; registers['e']=n&255
            elif reg not in registers: raise ValueError('unsupported destination '+reg)
            else: registers[reg]=val(rhs)
        elif op=='cp':
            a=registers['a']; b=val(oper)
            zero=(a==b); carry=(a<b) if isinstance(a,int) and isinstance(b,int) else False
        elif op=='inc' or op=='dec':
            if oper not in ('b','c','hl'): raise ValueError('unsupported increment '+oper)
            registers[oper]=(registers[oper]+(1 if op=='inc' else -1)) & (65535 if oper=='hl' else 255)
        elif op=='add' and oper=='hl, de':
            registers['hl']+=registers['d']*256+registers['e']
        elif op=='and' and oper=='a':
            zero=(registers['a']==0); carry=False
        elif op=='scf' and not oper:
            carry=True
        elif op in ('jr','jp'):
            parts=[p.strip() for p in oper.split(',')]
            if len(parts)==1: jump=True; dest=parts[0]
            elif len(parts)==2:
                cond,dest=parts
                jump={'z':zero,'nz':not zero,'c':carry,'nc':not carry}.get(cond)
                if jump is None: raise ValueError('unknown branch '+cond)
            else: raise ValueError('bad branch')
            if jump: pc=labels[dest]
        elif op=='ret':
            if not oper or (oper=='c' and carry) or (oper=='nc' and not carry):
                return registers['e'],carry
        else: raise ValueError('unsupported instruction '+op+' '+oper)
    raise ValueError('nonterminating gate helper')

def scan(code, constants, map_id, roles):
    if len(roles)!=80: raise ValueError('role size must be 80')
    moves={'UP':(0,-1),'DOWN':(0,1),'LEFT':(-1,0),'RIGHT':(1,0)}
    carpets={(0,4),(0,5),(9,4),(9,5)}
    failures=[]; count=0
    for y in range(8):
        for x in range(10):
            if roles[y*10+x]!=0 and (x,y) not in carpets: continue
            for d,(dx,dy) in moves.items():
                tx,ty=x+dx,y+dy
                if not(0<=tx<10 and 0<=ty<8): continue
                e,carry=evaluate(code,constants,map_id,x,y,d)
                actual=carry and e==0
                expected=(tx,ty) in carpets
                count+=1
                if actual!=expected:
                    failures.append(f'({x},{y}) {d} -> ({tx},{ty}) expected={expected} actual={actual}')
    return count,failures

def structural_check(west,east,code,constants):
    """Keep only intended banked and local callers, no public global override."""
    entry=west.split('JohtoWestCarpetSpatialStep::',1)[1].split('\n.city\n',1)[0]
    step=east.split('JohtoEastSpatialStep::',1)[1].split(TABLE,1)[0]
    if ('cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID' not in entry or
        'callab JohtoGateHorizontalCarpetInbound303' not in entry or
        'ret z' not in entry): return False
    if 'call JohtoGateHorizontalCarpetInbound303\n    ret c' not in step: return False
    profiles,_,_= _load(code,constants)
    return profiles == [constants['JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID'],0,9,4,5,
                        constants['JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID'],0,9,4,5,255]
