#!/usr/bin/env python3
"""Static RPP/Gold dual-source preflight and Route31-Violet Gate geometry audit.

MUST have both readable complete source trees. Not a ROM-build/runtime test.
Usage: python tools/johto_gate_audit.py --rpp . --gold /path/to/pokegold-master
"""
import argparse
from pathlib import Path
import re
import sys

RPP_REQUIRED = (
    'Makefile', 'constants.asm', 'wram.asm',
    'main.asm', 'home/overworld.asm', 'data/game_version.asm',
    'constants/map_constants.asm', 'constants/region_map_constants.asm',
    'data/map_header_banks.asm', 'data/map_header_pointers.asm',
    'data/johto_map_headers.asm', 'data/town_map_entries.asm',
    'data/mapObjects/JohtoRoute31.asm', 'data/mapObjects/JohtoVioletCity.asm',
    'data/mapObjects/JohtoRoute31VioletGate.asm',
    'data/mapHeaders/JohtoRoute31.asm', 'data/mapHeaders/JohtoVioletCity.asm',
    'data/mapHeaders/JohtoRoute31VioletGate.asm',
    'maps/JohtoRoute31VioletGate.blk', 'maps/Route11Gate1F.blk',
    'gfx/blocksets/gate.bst', 'gfx/tilesets/gate.t1.png',
    'engine/overworld/region_map_lookup.asm', 'engine/town_map.asm',
    'scripts/JohtoRoute31VioletGate.asm',
    'data/warp_tile_ids.asm', 'gfx/blocksets/johto.bst',
    'gfx/tilesets/johto.tilecoll', 'maps/JohtoRoute31.blk', 'maps/JohtoVioletCity.blk',
    'RPP_DEVELOPMENT_PITFALLS.md',
)
GOLD_REQUIRED = (
    'Makefile', 'main.asm', 'includes.asm',
    'maps/Route31.asm', 'maps/VioletCity.asm', 'maps/Route31VioletGate.asm',
    'maps/EastWestGate.blk', 'data/maps/blocks.asm', 'data/maps/maps.asm',
    'data/tilesets/gate_metatiles.bin', 'gfx/tilesets/gate.png',
)
WARP_RPP = re.compile(r'^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*(JOHTO_[A-Z_0-9]+)\s*$', re.M)
WARP_GOLD = re.compile(r'^\s*warp_event\s+(\d+),\s*(\d+),\s*([A-Z_0-9]+),\s*(\d+)\s*$', re.M)
RPP_EXPECTED = {
    'JohtoRoute31.asm': [(6,4,2,'JOHTO_ROUTE31_VIOLET_GATE'), (7,4,3,'JOHTO_ROUTE31_VIOLET_GATE')],
    'JohtoVioletCity.asm': [(24,39,0,'JOHTO_ROUTE31_VIOLET_GATE'), (25,39,1,'JOHTO_ROUTE31_VIOLET_GATE')],
    'JohtoRoute31VioletGate.asm': [(4,0,0,'JOHTO_VIOLET_CITY'), (5,0,1,'JOHTO_VIOLET_CITY'),
                                   (4,9,0,'JOHTO_ROUTE_31'), (5,9,1,'JOHTO_ROUTE_31')],
}
GOLD_GATE = [(0,4,'VIOLET_CITY',8),(0,5,'VIOLET_CITY',9),
             (9,4,'ROUTE_31',1),(9,5,'ROUTE_31',2)]
RPP_GATE_ART_ADAPTER = bytes([
    0x04,0x02,0x02,0x02,0x05,
    0x1a,0x16,0x16,0x16,0x1c,
    0x18,0x01,0x01,0x01,0x19,
    0x01,0x01,0x20,0x01,0x01,
])


def text(root, rel):
    return (root/rel).read_text(encoding='utf-8')


def preflight(rpp, gold):
    problems = []
    for label, root, minimum in (('RPP',Path(rpp),3200),('GOLD',Path(gold),4000)):
        if not root.is_dir():
            problems.append(f'{label} SOURCE DIRECTORY MISSING: {root}')
        else:
            count=sum(p.is_file() for p in root.rglob('*') if '.git' not in p.parts)
            if count < minimum:
                problems.append(f'{label} INCOMPLETE SOURCE TREE: only {count} files (<{minimum})')
    for label, root, names in (('RPP',Path(rpp),RPP_REQUIRED), ('GOLD',Path(gold),GOLD_REQUIRED)):
        for name in names:
            file = root/name
            if not file.is_file():
                problems.append(f'{label} MISSING {name}')
            else:
                try:
                    if len(file.read_bytes()) == 0:
                        problems.append(f'{label} EMPTY {name}')
                except OSError as ex:
                    problems.append(f'{label} UNREADABLE {name}: {ex}')
    return problems


def audit(rpp, gold):
    rpp, gold = Path(rpp), Path(gold)
    problems = preflight(rpp, gold)
    if problems: return problems  # hard-stop, no extrapolation on partial sources
    if 'GT-5.62.158@' not in text(rpp,'data/game_version.asm'):
        problems.append('WRONG RPP BASE: expected GT-5.62.158 with gate fix')
    # GATE-5.62.157: the portal remains walkable, but stepping on it must
    # never auto-warp. The second outward input collides and uses native Warp.
    # The outdoor entrance 16x16 cells still contain four $40 subtiles.
    coll=(rpp/'gfx/tilesets/johto.tilecoll').read_bytes()
    if coll != bytes((3,4,5,6,0x40,0xff)):
        problems.append('RPP JOHTO COLLISION must allow gate portal tile $40')
    if not re.search(r'NewBarkWarpTileIDs:\s*db\s+\$06,\$FF',text(rpp,'data/warp_tile_ids.asm')):
        problems.append('RPP JOHTO WARP TILES must exclude $40 (no standing auto-warp)')
    src = text(rpp,'home/overworld.asm')
    facing = text(rpp,'engine/overworld/player_state.asm')
    if 'cp JOHTO_ROUTE31_VIOLET_GATE' not in src[src.index('CheckWarpsNoCollisionLoop::'):src.index('CheckWarpsCollision::')]:
        problems.append('RPP missing gate on-step Warp suppression')
    if 'cp JOHTO_ROUTE_31' not in facing[facing.index('IsPlayerFacingEdgeOfMap:'):facing.index('IsWarpTileInFrontOfPlayer:')]:
        problems.append('RPP missing Route31 pseudo-edge facing check')
    bst=(rpp/'gfx/blocksets/johto.bst').read_bytes()
    for basename,width,points in (('JohtoRoute31',20,[(4,6),(4,7)]),
                                  ('JohtoVioletCity',20,[(39,24),(39,25)])):
        blocks=(rpp/f'maps/{basename}.blk').read_bytes()
        for x,y in points:
            bid=blocks[(y//2)*width+x//2]
            sub=bst[bid*16:(bid+1)*16]
            row=(y%2)*2; col=(x%2)*2
            portal=[sub[row*4+col],sub[row*4+col+1],sub[(row+1)*4+col],sub[(row+1)*4+col+1]]
            if portal!=[0x40]*4:
                problems.append(f'{basename} entry ({x},{y}) changed from portal tile $40: {portal}')
    # Avoid making an unrelated Johto floor tile walkable by accident.
    gate_blocks={b for b in range(len(bst)//16) if 0x40 in bst[b*16:(b+1)*16]}
    for basename in ('JohtoRoute29','JohtoRoute30','JohtoCherrygroveCity'):
        ids=set((rpp/f'maps/{basename}.blk').read_bytes())
        if ids & gate_blocks:
            problems.append(f'{basename} unexpectedly uses gate portal tile $40')
    constants = text(rpp,'constants/map_constants.asm')
    if not re.search(r'mapconst JOHTO_ROUTE31_VIOLET_GATE,\s*4,\s*5\b',constants):
        problems.append('RPP GATE DIMENSIONS must be Height=4 Width=5 (Gold 5x4)')
    if len((gold/'maps/EastWestGate.blk').read_bytes()) != 20:
        problems.append('GOLD EastWestGate 5x4 source is not 20 blocks')
    if 'Route31VioletGate_Blocks:' not in text(gold,'data/maps/blocks.asm'):
        problems.append('GOLD shared EastWestGate map label missing')
    if 'INCBIN "maps/EastWestGate.blk"' not in text(gold,'data/maps/blocks.asm'):
        problems.append('GOLD shared EastWestGate reference missing')
    gg = [(int(x),int(y),m,int(dest)) for x,y,m,dest in WARP_GOLD.findall(text(gold,'maps/Route31VioletGate.asm'))]
    if gg != GOLD_GATE: problems.append(f'GOLD GATE WARPS changed: {gg!r}')
    gold_route = [(int(x),int(y),m,int(dest)) for x,y,m,dest in WARP_GOLD.findall(text(gold,'maps/Route31.asm'))]
    if gold_route[:2] != [(4,6,'ROUTE_31_VIOLET_GATE',3),(4,7,'ROUTE_31_VIOLET_GATE',4)]:
        problems.append('GOLD Route31 original gate coordinates changed')
    gold_city = [(int(x),int(y),m,int(dest)) for x,y,m,dest in WARP_GOLD.findall(text(gold,'maps/VioletCity.asm'))]
    if gold_city[-2:] != [(39,24,'ROUTE_31_VIOLET_GATE',1),(39,25,'ROUTE_31_VIOLET_GATE',2)]:
        problems.append('GOLD VioletCity original gate coordinates changed')
    for name,expected in RPP_EXPECTED.items():
        got=[(int(y),int(x),int(i),m) for y,x,i,m in WARP_RPP.findall(text(rpp,'data/mapObjects/'+name))]
        if got!=expected: problems.append(f'RPP WARPS {name}: {got!r} expected {expected!r}')
    actual=(rpp/'maps/JohtoRoute31VioletGate.blk').read_bytes()
    if actual!=RPP_GATE_ART_ADAPTER:
        problems.append('RPP indoor 5x4 20-block GATE art adapter differs from reviewed layout')
    refs={
        'constants/region_map_constants.asm':['JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID EQU 6','NUM_JOHTO_MAPS EQU 7'],
        'data/johto_map_headers.asm':['dw JohtoRoute31VioletGate_h','db BANK(JohtoRoute31VioletGate_h)','db JOHTO_ROUTE31_VIOLET_GATE'],
        'data/map_header_banks.asm':['db BANK(JohtoRoute31VioletGate_h)'],
        'data/map_header_pointers.asm':['dw JohtoRoute31VioletGate_h'],
        'data/mapHeaders/JohtoRoute31VioletGate.asm':['db GATE','JOHTO_ROUTE31_VIOLET_GATE_HEIGHT, JOHTO_ROUTE31_VIOLET_GATE_WIDTH'],
        'main.asm':['INCLUDE "data/mapHeaders/JohtoRoute31VioletGate.asm"','INCLUDE "data/mapObjects/JohtoRoute31VioletGate.asm"', 'JohtoRoute31VioletGateBlocks: INCBIN "maps/JohtoRoute31VioletGate.blk"'],
        'RPP_DEVELOPMENT_PITFALLS.md':['SRC-PREFLIGHT-151','Gold 双源码'],
        }
    for rel,markers in refs.items():
        data=text(rpp,rel)
        for marker in markers:
            if marker not in data: problems.append(f'RPP MISSING REGISTRATION {rel}: {marker}')
    for name in ('JohtoRoute31.asm','JohtoVioletCity.asm'):
        src=text(rpp, 'data/mapHeaders/'+name)
        if re.search(r'^\s*(WEST_MAP_CONNECTION|EAST_MAP_CONNECTION)\b', src, re.M):
            problems.append(f'RPP FORBIDDEN outdoor straight crossing: {name}')
    return problems


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp',required=True,type=Path)
    parser.add_argument('--gold',required=True,type=Path)
    args=parser.parse_args()
    errors=audit(args.rpp,args.gold)
    if errors:
        print('FAIL - incomplete/mismatched source; stop modifications:')
        print('\n'.join(errors))
        sys.exit(1)
    print('PASS - RPP + Gold source present; original 5x4 gate, exact warp coordinates, map registrations (STATIC ONLY)')
