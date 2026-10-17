#!/usr/bin/env python3
"""Strict Gold indoor gate RGB comparison; uses real 2bpp/palette map contracts.

Visual *render parity*, not ROM runtime evidence. Confines palette edits to unused
0x28/0x29 slots and JOHTO_GATE's palette indices, leaves Kanto GATE unmodified.
"""
from pathlib import Path
import re

LABELS = ('GRAY','RED','GREEN','WATER','YELLOW','BROWN','ROOF')
GATE_BASE = ('INDOOR_GRAY','INDOOR_RED','JOHTO_GATE_GOLD_GREEN',
             'INDOOR_BLUE','INDOOR_YELLOW','JOHTO_GATE_GOLD_BROWN',
             'INDOOR_LIGHT_BLUE','CRYS_TEXTBOX')
KANTO_GATE = ('INDOOR_GRAY','POKECENTER_TABLE','INDOOR_GREEN',
              'INDOOR_BLUE','POKECENTER_FLOOR','INDOOR_BROWN',
              'INDOOR_LIGHT_BLUE','ALT_TEXTBOX_2')

def _triples(line):
    return [tuple(map(int,p)) for p in re.findall(r'(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',line.split(';',1)[0])]

def _gold_indoor(source):
    fragment=source.split('; indoor',1)
    if len(fragment)!=2:raise ValueError('Gold indoor marker missing')
    rows=[_triples(s) for s in fragment[1].split('; overworld water',1)[0].splitlines() if 'RGB' in s]
    if len(rows)!=8 or any(len(row)!=4 for row in rows):raise ValueError('Gold indoor palettes incomplete')
    return dict(zip(LABELS+('TEXT',),rows))

def _rpp_palettes(source):
    parts=re.split(r'(?m)^; 0x([0-9a-fA-F]{2}):',source)
    if len(parts)!=129:raise ValueError('RPP map palettes must have exactly 64 slots')
    out={}
    for i in range(1,len(parts),2):
        n=int(parts[i],16)
        rows=[_triples(s) for s in parts[i+1].splitlines() if 'RGB' in s]
        if len(rows)!=4 or any(len(v)!=1 for v in rows):raise ValueError(f'palette {n:02x} malformed')
        out[n]=[v[0] for v in rows]
    if set(out)!=set(range(64)):raise ValueError('palette ID table modified')
    return out

def _sets(source):
    rows=[[v.strip() for v in line.split('db',1)[1].split(';',1)[0].split(',')]
          for line in source.splitlines() if re.match(r'^\s*db\s+\w+',line)]
    if len(rows)%8:raise ValueError('palette sets not in 8 slots')
    return [tuple(r[0] for r in rows[i:i+8]) for i in range(0,len(rows),8)]

def verify(rpp:Path,gold:Path):
    errors=[]
    try:
        gold_colors=_gold_indoor((gold/'gfx/tilesets/bg_tiles.pal').read_text())
        rpp_colors=_rpp_palettes((rpp/'color/data/map_palettes.asm').read_text())
        slots=_sets((rpp/'color/data/map_palette_sets.asm').read_text())
        const=(rpp/'color/data/map_palette_constants.asm').read_text()
        for symbol,index in (('JOHTO_GATE_GOLD_GREEN',0x28),('JOHTO_GATE_GOLD_BROWN',0x29)):
            if not re.search(r'(?m)^\s*const\s+'+symbol+r'\s*;\s*'+f'{index:02X}',const):
                errors.append(f'{symbol} missing or wrong spare slot')
        if len(slots)!=32:errors.append('tileset palette sets count changed')
        elif slots[29]!=GATE_BASE:errors.append('JOHTO_GATE must use isolated Gold palettes')
        if len(slots)>12 and slots[12]!=KANTO_GATE:errors.append('Kanto GATE palette set was changed')
        for label,pid in (('GRAY',0x09),('RED',0x0a),('GREEN',0x28),('WATER',0x0c),('YELLOW',0x0d),('BROWN',0x29),('ROOF',0x0f)):
            if rpp_colors[pid]!=gold_colors[label]:errors.append(f'Gold gate actual RGB mismatch: {label} at {pid:02x}: {rpp_colors[pid]} != {gold_colors[label]}')
        if rpp_colors[0x0b][0]!=(30,28,26) or rpp_colors[0x0e][0]!=(30,28,26):
            errors.append('shared Kanto INDOOR_GREEN/BROWN modified')
    except (OSError,ValueError,IndexError,KeyError) as e:
        errors.append('RGB source parse failed: '+str(e))
    return errors

if __name__=='__main__':
    import argparse
    a=argparse.ArgumentParser();a.add_argument('--rpp',type=Path,required=True);a.add_argument('--gold',type=Path,required=True)
    args=a.parse_args();errors=verify(args.rpp,args.gold)
    print('GOLD GATE RGB', 'PASS' if not errors else 'FAIL',errors)
    raise SystemExit(bool(errors))
