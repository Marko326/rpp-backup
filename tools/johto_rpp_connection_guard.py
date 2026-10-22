#!/usr/bin/env python3
"""Fail-closed Gold -> RPP map connection geometry audit (source-only).

The Gold `connection` macro and RPP's legacy *_MAP_CONNECTION macros do NOT
interpret negative offsets in the same way. This deliberately audits the
emitted strip fields, not merely the macro's spelling or Gold's offset.

No ROM compilation, no files modified. Audits all four directions using
RPP strip-copy machinery, including 3-column vertical borders for east/west.
"""
import argparse
import ast
import json
from pathlib import Path
import re
import sys


class ConnectionError(ValueError):
    pass


# Immutable *direct overworld seam* contract for the user's pokegold-master.
# All 142 directed edges across 368 Gold maps (including the Kanto reference
# edges); DOOR/WARP links are not seamless connections and remain the domain of
# the existing gatehouse/door audit tools. This is authoritative, NOT a list
# of maps that RPP has implemented. Do not edit entries merely to make a test
# pass: compare with original Gold and review the map topology first.
GOLD_DIRECT_SEAMS = """\
NewBarkTown west Route29 0
NewBarkTown east Route27 0
CherrygroveCity north Route30 5
CherrygroveCity east Route29 0
VioletCity south Route32 0
VioletCity west Route36 0
VioletCity east Route31 9
AzaleaTown west Route34 -18
AzaleaTown east Route33 0
CianwoodCity east Route41 0
GoldenrodCity north Route35 5
GoldenrodCity south Route34 5
OlivineCity north Route39 5
OlivineCity west Route40 9
EcruteakCity south Route37 5
EcruteakCity west Route38 5
EcruteakCity east Route42 9
MahoganyTown north Route43 0
MahoganyTown west Route42 0
MahoganyTown east Route44 0
LakeOfRage south Route43 5
BlackthornCity south Route45 0
BlackthornCity west Route44 9
SilverCaveOutside east Route28 9
Route26 west Route27 45
Route27 west NewBarkTown 0
Route27 east Route26 -45
Route28 west SilverCaveOutside -9
Route29 north Route46 10
Route29 west CherrygroveCity 0
Route29 east NewBarkTown 0
Route30 north Route31 -10
Route30 south CherrygroveCity -5
Route31 south Route30 10
Route31 west VioletCity -9
Route32 north VioletCity 0
Route32 south Route33 0
Route33 north Route32 0
Route33 west AzaleaTown 0
Route34 north GoldenrodCity -5
Route34 east AzaleaTown 18
Route35 north Route36 0
Route35 south GoldenrodCity -5
Route36 north Route37 10
Route36 south Route35 0
Route36 east VioletCity 0
Route37 north EcruteakCity -5
Route37 south Route36 -10
Route38 west Route39 0
Route38 east EcruteakCity -5
Route39 south OlivineCity -5
Route39 east Route38 0
Route40 south Route41 -15
Route40 east OlivineCity -9
Route41 north Route40 15
Route41 west CianwoodCity 0
Route42 west EcruteakCity -9
Route42 east MahoganyTown 0
Route43 north LakeOfRage -5
Route43 south MahoganyTown 0
Route44 west MahoganyTown 0
Route44 east BlackthornCity -9
Route45 north BlackthornCity 0
Route45 west Route46 36
Route46 south Route29 -10
Route46 east Route45 -36
PewterCity south Route2 5
PewterCity east Route3 5
Route2 north PewterCity -5
Route2 south ViridianCity -5
ViridianCity north Route2 5
ViridianCity south Route1 10
ViridianCity west Route22 4
Route22 east ViridianCity -4
Route1 north ViridianCity -10
Route1 south PalletTown 0
PalletTown north Route1 0
PalletTown south Route21 0
Route21 north PalletTown 0
Route21 south CinnabarIsland 0
CinnabarIsland north Route21 0
CinnabarIsland east Route20 0
Route20 west CinnabarIsland 0
Route20 east Route19 -9
Route19 north FuchsiaCity 0
Route19 west Route20 9
FuchsiaCity south Route19 0
FuchsiaCity west Route18 7
FuchsiaCity east Route15 9
Route18 west Route17 -38
Route18 east FuchsiaCity -7
Route17 north Route16 0
Route17 east Route18 38
Route16 south Route17 0
Route16 east CeladonCity -9
CeladonCity west Route16 9
CeladonCity east Route7 5
Route7 west CeladonCity -5
Route7 east SaffronCity -9
Route15 west FuchsiaCity -9
Route15 east Route14 -9
Route14 north Route13 0
Route14 west Route15 9
Route13 north Route12 20
Route13 south Route14 0
Route12 north LavenderTown 0
Route12 south Route13 -20
Route12 west Route11 9
Route11 west VermilionCity 0
Route11 east Route12 -9
LavenderTown north Route10South 0
LavenderTown south Route12 0
LavenderTown west Route8 0
VermilionCity north Route6 5
VermilionCity east Route11 0
Route6 north SaffronCity -5
Route6 south VermilionCity -5
SaffronCity north Route5 5
SaffronCity south Route6 5
SaffronCity west Route7 9
SaffronCity east Route8 9
Route5 north CeruleanCity -5
Route5 south SaffronCity -5
CeruleanCity north Route24 6
CeruleanCity south Route5 5
CeruleanCity west Route4 5
CeruleanCity east Route9 9
Route9 south Route10North 20
Route9 west CeruleanCity -9
Route24 north Route25 0
Route24 south CeruleanCity -6
Route25 south Route24 0
Route3 west PewterCity -5
Route3 east Route4 0
Route4 west Route3 0
Route4 east CeruleanCity -5
Route8 west SaffronCity -9
Route8 east LavenderTown 0
Route10North north Route9 -20
Route10North south Route10South 0
Route10South north Route10North 0
Route10South south LavenderTown 0
"""

# Original Gold uses direct outdoor seams at these places, while this RPP
# project intentionally connects them through independently registered gates
# and forest routes. Both ends may exist without a direct RPP seam.
# This exception set is *not* a license to omit any other registered edge.
GATE_REPLACED_DIRECT_SEAMS = {
    ('AzaleaTown', 'west', 'Route34'),       # via Ilex Forest / Route34 gate
    ('Route34', 'east', 'AzaleaTown'),
    ('GoldenrodCity', 'north', 'Route35'),  # via Route35GoldenrodGate
    ('Route35', 'south', 'GoldenrodCity'),
}


def frozen_gold_direct_seams():
    result = {}
    for row in GOLD_DIRECT_SEAMS.splitlines():
        parts = row.split()
        if len(parts) != 4 or parts[1] not in ('north', 'south', 'west', 'east'):
            raise ConnectionError('Invalid frozen Gold seam contract: '+row)
        current, direction, target, offset = parts
        key = (current, direction)
        if key in result:
            raise ConnectionError('Duplicate frozen Gold seam: '+str(key))
        result[key] = (target, int(offset))
    if len(result) != 142:
        raise ConnectionError(f'Frozen Gold seams incomplete: {len(result)} != 142')
    reverse = {'north':'south', 'south':'north', 'west':'east', 'east':'west'}
    for (current,direction),(target,offset) in result.items():
        if result.get((target,reverse[direction])) != (current,-offset):
            raise ConnectionError(f'Gold seam missing reverse: {current} {direction}->{target}')
    return result


def check_frozen_gold_source(gold_root):
    """Independently compare ALL Gold source seams to the frozen 142 records.

    The Gold source is needed for .blk geometry anyway; absent/modified Gold
    must not allow the all-active release gate to claim full coverage.
    """
    path = gold_root / 'data/maps/attributes.asm'
    current = None
    entries = set()
    seen = {}
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.split(';', 1)[0].strip()
        m = re.match(r'^map_attributes\s+(\w+)\s*,', line)
        if m:
            current = m.group(1)
            if current in entries:
                raise ConnectionError('Duplicate Gold map attributes: '+current)
            entries.add(current)
        if line.startswith('connection ') and current is not None:
            m = re.fullmatch(r'connection\s+(north|south|west|east),\s*(\w+),\s*(\w+),\s*([+-]?\d+)', line)
            if not m or current is None:
                raise ConnectionError('Unparseable Gold connection: '+line)
            direction,target,unused_symbol,offset=m.groups()
            key=(current,direction)
            if key in seen:
                raise ConnectionError('Duplicate Gold connection: '+str(key))
            seen[key]=(target,int(offset))
    if len(entries) != 368:
        raise ConnectionError(f'Gold attributes: expected 368 maps, found {len(entries)}')
    frozen=frozen_gold_direct_seams()
    if seen != frozen:
        missing=sorted(set(frozen)-set(seen))
        extra=sorted(set(seen)-set(frozen))
        changed=sorted(k for k in seen.keys() & frozen.keys() if seen[k]!=frozen[k])
        raise ConnectionError(f'Gold direct connection contract mismatch: missing={missing[:4]} '
                              f'extra={extra[:4]} changed={[(k,seen[k],frozen[k]) for k in changed[:4]]}')
    if any((a,d) not in frozen or frozen[(a,d)][0]!=b
           for a,d,b in GATE_REPLACED_DIRECT_SEAMS):
        raise ConnectionError('Gate-replaced Gold seam exceptions differ from frozen Gold')
    return frozen


def require_registered_gold_seams(project, active_edges, gold_seams):
    """Reject accidentally *deleted* connections, not merely wrong active ones."""
    registry=json.loads((project/'tools/johto_native_maps.json').read_text(encoding='utf-8'))['maps']
    registered={record['header'][:-2] for record in registry}
    goldnames={name: (name[5:] if name.startswith('Johto') else name) for name in registered}
    by_gold={value:key for key,value in goldnames.items()}
    if len(by_gold)!=len(registered):
        raise ConnectionError('Registered RPP maps share a Gold connection name')
    expected={
        (by_gold[current],direction,by_gold[target])
        for (current,direction),(target,_offset) in gold_seams.items()
        if current in by_gold and target in by_gold
        and (current,direction,target) not in GATE_REPLACED_DIRECT_SEAMS
    }
    actual={(current,direction,target) for current,target,_,_,direction in active_edges}
    missing=sorted(expected-actual)
    unexpected=sorted(actual-expected)
    if missing or unexpected:
        raise ConnectionError('Gold topology of registered maps: '
                              f'MISSING={missing[:8]} UNEXPECTED={unexpected[:8]}')


def check_all_native_selectors(project, active_edges):
    """Every $FC seam requires exactly one selector; no orphan/duplicate row."""
    symbols={m['header'][:-2]:m['local_symbol'] for m in
             json.loads((project/'tools/johto_native_maps.json').read_text(encoding='utf-8'))['maps']}
    expected={}
    direction_index={'north':0,'south':1,'west':2,'east':3}
    for current,target,_,_,direction in active_edges:
        header=(project/'data/mapHeaders'/f'{current}.asm').read_text(encoding='utf-8')
        bounded=re.findall(r'^\s*db\s+REGION_NATIVE_MAP_SLOT\s*\n\s*dw\s+(\w+)Blocks\b',header,re.M)
        if target in bounded:
            key=(symbols[current],direction_index[direction])
            if key in expected:
                raise ConnectionError('Two $FC connections require the same selector key: '+str(key))
            expected[key]=('MAP_REGION_JOHTO',symbols[target])
    source=(project/'engine/overworld/region_map_lookup.asm').read_text(encoding='utf-8')
    if source.count('NativeRegionConnectionTargets::') != 1:
        raise ConnectionError('Missing/duplicate NativeRegionConnectionTargets table')
    body=re.split(r'^\w+::', source.split('NativeRegionConnectionTargets::',1)[1], maxsplit=1, flags=re.M)[0]
    actual={}
    sentinel=0
    for raw in body.splitlines():
        line=raw.split(';',1)[0].strip()
        if not line: continue
        if line == 'db $ff':
            sentinel+=1
            continue
        if sentinel:
            raise ConnectionError('Native selector has records after $ff: '+line)
        m=re.fullmatch(r'db\s+(\w+),\s*(\d+),\s*(\w+),\s*(\w+)',line)
        if not m:
            raise ConnectionError('Unrecognized native selector record: '+line)
        current,number,region,target=m.groups()
        key=(current,int(number))
        if current not in symbols.values() or target not in symbols.values() or int(number) not in range(4):
            raise ConnectionError('Unknown ID/direction in native selector: '+line)
        if key in actual:
            raise ConnectionError('Duplicate native selector: '+str(key))
        actual[key]=(region,target)
    if sentinel!=1:
        raise ConnectionError('Missing native selector $ff terminator')
    if actual!=expected:
        missing=sorted(expected.keys()-actual.keys())
        extra=sorted(actual.keys()-expected.keys())
        wrong=sorted(k for k in actual.keys() & expected.keys() if actual[k]!=expected[k])
        raise ConnectionError('Native selector mismatch: '
                              f'MISSING={missing} EXTRA={extra} '
                              f'WRONG={[(k,actual[k],expected[k]) for k in wrong]}')

def dimensions(project):
    text = (project / 'constants/map_constants.asm').read_text(encoding='utf-8')
    found = {}
    for name, height, width in re.findall(r'^\s*mapconst\s+(\w+),\s*(\d+),\s*(\d+)', text, re.M):
        found[name] = (int(width), int(height))
    # Native Johto maps use two-part (region, local_id) identities and
    # separate *_WIDTH/HEIGHT EQU declarations; a shared $FC byte is not a
    # unique map dimension. Parse both groups, reject inconsistent pairs.
    native_file = project / 'constants/region_map_constants.asm'
    if native_file.is_file():
        native = native_file.read_text(encoding='utf-8')
        widths = dict((key, int(value)) for key,value in re.findall(
            r'^\s*DEF\s+(JOHTO_[A-Z0-9_]+)_WIDTH\s+EQU\s+(\d+)',native,re.M))
        heights = dict((key, int(value)) for key,value in re.findall(
            r'^\s*DEF\s+(JOHTO_[A-Z0-9_]+)_HEIGHT\s+EQU\s+(\d+)',native,re.M))
        for key in sorted(set(widths) | set(heights)):
            if key not in widths or key not in heights:
                raise ConnectionError('Incomplete native dimension pair: '+key)
            pair=(widths[key],heights[key])
            if key in found and found[key]!=pair:
                raise ConnectionError('Inconsistent native vs legacy dimensions: '+key)
            found[key]=pair
    return found


def gold_offset(gold_root, current, target, direction):
    text = (gold_root / 'data/maps/attributes.asm').read_text(encoding='utf-8')
    start = re.search(r'^\s*map_attributes\s+' + re.escape(current) + r'\s*,[^\n]*$', text, re.M)
    if start is None:
        raise ConnectionError('Gold missing map_attributes for ' + current)
    matches = []
    for line in text[start.end():].splitlines():
        clean = line.split(';', 1)[0].strip()
        if not clean:
            continue
        if not clean.startswith('connection '):
            break
        m = re.fullmatch(r'connection\s+(north|south|east|west),\s*(\w+),\s*(\w+),\s*([+-]?\d+)', clean)
        if m and m.group(1) == direction and m.group(2) == target:
            matches.append(int(m.group(4)))
    if len(matches) != 1:
        raise ConnectionError(f'Gold expected one {current} {direction} -> {target} edge, got {len(matches)}')
    return matches[0]


def constant_expr(expr, names):
    """Evaluate only integer +/-/* with explicitly supplied identifiers."""
    expr = re.sub(r'\$([0-9a-fA-F]+)', lambda m: '0x' + m.group(1), expr)
    tree = ast.parse(expr, mode='eval').body
    def calc(node):
        if isinstance(node, ast.Constant) and type(node.value) is int:
            return node.value
        if isinstance(node, ast.Name) and node.id in names:
            return names[node.id]
        if isinstance(node, ast.BinOp) and isinstance(node.op, (ast.Add, ast.Sub, ast.Mult)):
            a, b = calc(node.left), calc(node.right)
            return a+b if isinstance(node.op, ast.Add) else a-b if isinstance(node.op, ast.Sub) else a*b
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.USub, ast.UAdd)):
            return -calc(node.operand) if isinstance(node.op, ast.USub) else calc(node.operand)
        raise ConnectionError('Unsupported/unknown assembler expression: ' + expr)
    try:
        return calc(tree)
    except (SyntaxError, TypeError, RecursionError) as ex:
        raise ConnectionError('Invalid assembler expression: ' + expr) from ex


def strip_entry(project, current, target, direction, current_id, target_id, w1, h1, w2, h2):
    if direction not in ('north', 'south', 'east', 'west'):
        raise ConnectionError('Invalid connection direction: ' + direction)
    path = project / 'data/mapHeaders' / (current + '.asm')
    lines = [line.split(';', 1)[0].strip() for line in path.read_text(encoding='utf-8').splitlines()]
    direction_macro = direction.upper() + '_MAP_CONNECTION'
    candidates = []
    names = {
        'wOverworldMap': 0,
        target + 'Blocks': 0,
        current + 'Blocks': 0,
    }
    # Map constants are authoritative for all WIDTH/HEIGHT expansions.
    for key, (width, height) in dimensions(project).items():
        names[key + '_WIDTH'] = width
        names[key + '_HEIGHT'] = height
    for i, line in enumerate(lines):
        if re.match(r'^' + re.escape(direction_macro) + r'\s+', line):
            args = [p.strip() for p in line.split(None, 1)[1].split(',')]
            if len(args) not in (5, 6) or args[0] != current_id or args[1] != target_id or args[4] != target + 'Blocks':
                continue
            move = constant_expr(args[2], names)
            source_offset = constant_expr(args[3], names)
            if direction == 'north':
                source_start = w2*(h2-3) + source_offset
                dest_start = 3+move
                width = (w1 - move + 3) if w1 < w2 else (w2-source_offset)
                y = 2*h2-1
                window = 1+h2*(w2+6)
            elif direction == 'south':
                source_start = source_offset
                dest_start = 3+(h1+3)*(w1+6)+move
                width = (w1 - move + (3 if len(args) == 6 else 0)) if w1 < w2 else (w2-source_offset)
                y = 0
                window = 7+w2
            else:
                # East/west copy exactly 3 columns for each of `height` rows.
                # The legacy macro calls its third/fourth parameters a
                # strip-row move and a source-row offset, NOT Gold offsets.
                source_start = w2*source_offset + (w2-3 if direction=='west' else 0)
                dest_start = (w1+6)*(move+3) + (0 if direction=='west' else w1+3)
                width = ((h1-move+(3 if direction=='west' or len(args)==6 else 0))
                         if h1 < h2 else h2-source_offset)
                y = -2*(move-source_offset)
                window = 6+2*w2 if direction=='west' else 7+w2
            entry=dict(format='legacy_macro', source_start=source_start, dest_start=dest_start,
                       map_width=w2, window=window)
            if direction in ('north','south'):
                entry.update(width=width, arrive_y=y, arrive_x=-2*(move-source_offset))
            else:
                entry.update(height=width, arrive_y=y,
                             arrive_x=2*w2-1 if direction=='west' else 0)
            candidates.append(entry)
    return candidates, lines, names


def registered_native_alias(project, target, target_id):
    """Allow the shared $FC handle only for maps registered to that slot."""
    source = project/'data/johto_map_headers.asm'
    if not source.is_file():
        return False
    text = source.read_text(encoding='utf-8')
    def section(start, end):
        match = re.search(re.escape(start)+r'(.*?)'+re.escape(end), text, re.S)
        if not match:
            raise ConnectionError('Missing native Johto header/alias table')
        return match.group(1)
    pointer_table = section('JohtoMapHeaderPointers::','JohtoMapHeaderPointersEnd::')
    alias_table = section('JohtoMapLegacyAliases::','JohtoMapLegacyAliasesEnd::')
    pointers = re.findall(r'^\s*dw\s+(\w+)_h\b', pointer_table, re.M)
    aliases = re.findall(r'^\s*db\s+([A-Z0-9_]+)\b', alias_table, re.M)
    if not pointers or len(pointers)!=len(aliases) or pointers.count(target)!=1:
        return False
    idx = pointers.index(target)
    if aliases[idx] != 'REGION_NATIVE_MAP_SLOT':
        return False
    native = project/'constants/region_map_constants.asm'
    if not native.is_file():
        return False
    constants = native.read_text(encoding='utf-8')
    # The frozen 21+ constants are real assembler INCLUDEs, not new runtime slots.
    if 'INCLUDE "constants/johto_fixed_map_ids.asm"' in constants:
        frozen = project / 'constants/johto_fixed_map_ids.asm'
        if frozen.is_file():
            constants += '\n' + frozen.read_text(encoding='utf-8')
        # Minimal negative-test fixtures can omit the frozen asset; pre-21
        # active local IDs remain defined in region_map_constants.asm.
    local = re.search(r'^\s*DEF\s+'+re.escape(target_id)+r'_LOCAL_ID\s+EQU\s+(\d+)',
                      constants, re.M)
    if local is None:
        return False
    stable_id = int(local.group(1))
    if stable_id == idx:
        return True
    # Sparse stable physical IDs (62, 63) must resolve to dense active slots
    # through the exact 256-byte table, not by indexing header row 62.
    table = re.search(r'JohtoStableIDToActiveSlot::(.*?)JohtoStableIDToActiveSlotEnd::',text,re.S)
    if not table:
        return False
    slots=[]
    for row in table.group(1).splitlines():
        code=row.split(';',1)[0].strip()
        if code.startswith('db '):
            slots += [int(v.strip()[1:],16) for v in code[3:].split(',')]
    return len(slots)==256 and 0<=stable_id<256 and slots[stable_id]==idx


def read_connection(project, current, target, direction, current_id, target_id, w1, h1, w2, h2):
    candidates, lines, names = strip_entry(project, current, target, direction, current_id, target_id, w1, h1, w2, h2)
    # A correct strip is still inert if the header does not set its direction bit.
    direction_flags = []
    for line in lines:
        m = re.fullmatch(r'db\s+((?:NORTH|SOUTH|EAST|WEST)(?:\s*\|\s*(?:NORTH|SOUTH|EAST|WEST))*)', line)
        if m:
            direction_flags.extend(part.strip().lower() for part in m.group(1).split('|'))
    if direction not in direction_flags:
        raise ConnectionError('Header does not enable connection direction '+direction)
    expected_target_lines = {'db ' + target_id}
    if registered_native_alias(project,target,target_id):
        expected_target_lines.add('db REGION_NATIVE_MAP_SLOT')
    for i, line in enumerate(lines):
        if line not in expected_target_lines:
            continue
        next_fields = []
        for item in lines[i+1:]:
            if not item:
                continue
            m = re.fullmatch(r'(db|dw)\s+(.+)', item)
            if not m:
                break
            next_fields.append((m.group(1), m.group(2)))
            if len(next_fields) == 7:
                break
        if len(next_fields) != 7 or [x[0] for x in next_fields] != ['dw','dw','db','db','db','db','dw']:
            raise ConnectionError('Malformed custom edge record after db ' + target_id)
        # Multiple neighbors can use the SAME $FC native handle.  The
        # next block pointer identifies the actual destination.  Do not
        # accidentally decode a different neighbor's seven fields.
        if not re.fullmatch(re.escape(target) + r'Blocks(?:\s*\+.*)?', next_fields[0][1]):
            continue
        values = [constant_expr(expr, names) for kind, expr in next_fields]
        entry=dict(format='bounded_custom', source_start=values[0], dest_start=values[1],
                   map_width=values[3], arrive_y=values[4], arrive_x=values[5], window=values[6])
        entry['width' if direction in ('north','south') else 'height']=values[2]
        candidates.append(entry)
    if len(candidates) != 1:
        raise ConnectionError(f'Need exactly one {direction} connection {current}->{target}; found {len(candidates)}')
    return candidates[0]


def map_header_bank(project, name):
    """Source-level BANK for a registered map's header (not tileset art)."""
    main = (project/'main.asm').read_text(encoding='utf-8')
    marker = 'INCLUDE "data/mapHeaders/' + name + '.asm"'
    if main.count(marker)!=1:
        raise ConnectionError('Missing/duplicate main.asm header INCLUDE: ' + name)
    prefix=main.split(marker,1)[0]
    sections=re.findall(r'^\s*SECTION\s+"[^"]+"\s*,\s*ROMX\s*,\s*BANK\[([^]]+)\]',prefix,re.M)
    if not sections:
        raise ConnectionError('Cannot determine ROMX BANK for header: ' + name)
    bank=sections[-1].strip()
    declarations=dict(re.findall(r'^\s*DEF\s+(\w+)\s+EQU\s+(\$[0-9A-Fa-f]+|\d+)',main,re.M))
    resolved=constant_expr(bank,{key:int(val[1:],16) if val.startswith('$') else int(val)
                                  for key,val in declarations.items()})
    return resolved


def north_visual_borders(project, gold, current, gold_current, direction,
                              w1, w2, src_col, dst_col, overlap):
    """Derive needed preview from REVIEWED reachable exits, not map width alone.

    A 20-tile-wide screen has roughly five 16px tiles to the player's right.
    When a legal crossing can expose past the eastern edge of a narrow map,
    keep the existing three 32px WRAM border columns filled defensively.
    The Gold overlap still determines movement and arrival; extra is DISPLAY ONLY.
    """
    if direction != 'north' or dst_col + overlap != w1 or src_col + overlap >= w2:
        return 0, 0
    manifest = project / 'tools/johto_native_maps.json'
    if not manifest.is_file():  # Minimal legacy synthetic fixtures.
        return 0, 0
    entries = json.loads(manifest.read_text(encoding='utf-8'))['maps']
    matches = [m for m in entries if m.get('header') == current + '_h']
    if len(matches) != 1:
        raise ConnectionError('Missing/duplicate north seam registration for ' + current)
    item = matches[0]
    exits = item.get('north_connection_exit_x_tiles')
    if not isinstance(exits, list) or not exits or any(
            type(x) is not int or not 0 <= x < 2*w1 for x in exits) or len(set(exits)) != len(exits):
        raise ConnectionError('Unreviewed north crossing reachability for ' + current)
    # Confirm exit cells exist on the actual Gold border, not arbitrary
    # assumed walkable positions. RPP runtime fence must agree as well.
    from johto_indoor_collision_adapter import plan_gold_quadrant_collision
    geom, mask = plan_gold_quadrant_collision(gold, gold_current, 'johto')
    stride = geom['mask_row_bytes']
    for x in exits:
        if mask[x // 8] & (1 << (x % 8)):
            raise ConnectionError(f'{current} north exit x={x} is blocked in Gold')
    if current == 'JohtoRoute45':
        # The new eastern maps use a shared ROMX $47 byte-table fence rather
        # than a local EdgeFence. Verify table AND dispatch, then cross-check
        # the two Gold border masks independently (not a guessed lane range).
        east = (project/'engine/overworld/johto_east_exterior.asm').read_text(encoding='utf8')
        main = (project/'main.asm').read_text(encoding='utf8')
        dispatch = (project/'engine/overworld/johto_route33_collision.asm').read_text(encoding='utf8')
        match = re.search(r'(?m)^\.route45uplist\s*\n\s*db\s+([^;\n]+)', east)
        if (not match or 'jp z,.route45up' not in east or
                'ld hl,.route45uplist' not in east or
                'callba JohtoEastEdgeFence' not in main or
                'callab JohtoEastCanStepAhead' not in dispatch):
            raise ConnectionError('Route45 north shared fence dispatcher/table removed')
        try:
            legal = [int(x.strip()) for x in match.group(1).replace('$ff','255').split(',')][:-1]
        except ValueError:
            raise ConnectionError('Route45 Gold north table has nonliteral coordinates')
        # Also require one walkable tile *inside* each side of the seam;
        # a pair of visually FLOOR-looking edge cells behind a wall is not
        # an actual walkable crossing (Gold north R45 has such fragments).
        from johto_gold_cells import decode_cells
        meta = (gold/'data/tilesets/johto_metatiles.bin').read_bytes()
        coll = (gold/'data/tilesets/johto_collision.asm').read_text()
        def roles(name, w, h):
            decoded = decode_cells((gold/'maps'/(name+'.blk')).read_bytes(),meta,coll,w,h)
            return {(c['x'],c['y']):c['role'] for c in decoded}
        lower = roles('Route45',w1,45)
        upper = roles('BlackthornCity',w2,18)
        floors = {'FLOOR','TALL_GRASS'}
        independent = [x for x in range(2*dst_col,2*(dst_col+overlap))
                       if lower.get((x,0)) in floors and lower.get((x,1)) in floors
                       and upper.get((x-2*dst_col+2*src_col,35)) in floors
                       and upper.get((x-2*dst_col+2*src_col,34)) in floors]
        if legal != independent or legal != sorted(exits):
            raise ConnectionError(f'Route45 north shared fence openings {legal}, Gold {independent}, registry {exits}')
        if item.get('north_connection_visual_left_border',0) != 0 or item.get('north_connection_visual_right_border',0) != 0:
            raise ConnectionError('Route45 north visual border must stay zero for reviewed path')
        return 0, 0
    # Guard against a manifest that silently omits legal crossing positions.
    # Only audited code patterns are accepted, so future fence shapes fail
    # closed until the auditor is taught to interpret them.
    sources = [project/'main.asm',
               project/'engine/overworld/johto_route33_collision.asm']
    # Route34 has a dedicated north-only fence on the .216/.217 branch.
    if current == 'JohtoRoute32':
        fence_name = current + 'CollisionFence::'
    elif current == 'JohtoRoute34':
        fence_name = current + 'NorthEdgeFence::'
    else:
        fence_name = current + 'EdgeFence::'
    fence = '\n'.join(f.read_text(encoding='utf-8') for f in sources if f.is_file())
    match = re.search(re.escape(fence_name) + r'(.*?)(?=^\w+(?:::|:)|\Z)',
                      fence, re.S | re.M)
    if not match:
        raise ConnectionError('Missing runtime north boundary fence for '+current)
    if current == 'JohtoRoute34':
        # .216's dedicated fence checks x>=8 && x<12 directly before
        # .otherEdges. This is an independent audited shape, not a guess.
        branch = re.search(r'^\s*cp\s+PLAYER_DIR_UP.*?^\.otherEdges\s*$', match.group(1), re.S|re.M)
    else:
        branch = re.search(r'^\.north\s*\n(.*?)(?=^\.[a-zA-Z]+\s*$|\Z)', match.group(1), re.S|re.M)
    if not branch:
        raise ConnectionError('Cannot prove north crossing reachability for '+current)
    code = branch.group(0) if current == 'JohtoRoute34' else branch.group(1)
    bounded = re.search(r'cp\s+(\d+)\s*\n\s*jr c, \.blocked\s*\n\s*cp\s+(\d+)\s*\n\s*jr nc, \.blocked',code)
    single = re.search(r'cp\s+(\d+)\s*\n\s*jr z, \.clear\s*\n\s*jr \.block',code)
    if bounded:
        legal = list(range(int(bounded.group(1)),int(bounded.group(2))))
    elif current == 'JohtoRoute34':
        guard = re.search(r'cp\s+(\d+)\s*\n\s*jr c, \.blocked\s*\n\s*cp\s+(\d+)\s*\n\s*jr nc, \.blocked', code)
        if not guard:
            raise ConnectionError('Unhandled runtime north fence pattern for '+current)
        legal = list(range(int(guard.group(1)),int(guard.group(2))))
    elif single:
        legal = [int(single.group(1))]
    else:
        raise ConnectionError('Unhandled runtime north fence pattern for '+current)
    # Unlike extracting one cp-range, interpret the *whole* EdgeFence for
    # every north tile, including an early disjoint branch (Route43 x0).
    # This shares the existing fail-closed masked-step ASM interpreter; no
    # Route43-only exception or hand-entered exit list can hide a second path.
    if current not in ('JohtoRoute32', 'JohtoRoute34'):
        from johto_masked_step_audit import parse_caller, trace_masked_step
        matching_files = [file for file in sources if file.is_file() and
                          re.search(r'(?m)^' + re.escape(fence_name) + r'\s*$',
                                    file.read_text(encoding='utf-8'))]
        if len(matching_files) != 1:
            raise ConnectionError('Cannot uniquely execute north EdgeFence '+current)
        source = matching_files[0].read_text(encoding='utf-8')
        try:
            program, labels = parse_caller(source, fence_name.removesuffix('::'))
            mask = (project/'maps'/f'{current}.blocked_mask.bin').read_bytes()
            trace_legal = [x for x in range(2*w1) if not trace_masked_step(
                program, labels, mask, 2*w1, len(mask)//((2*w1+7)//8), item['local_symbol'], x, 0, 'UP')[0]]
        except (ValueError, KeyError, OSError) as exc:
            raise ConnectionError('Unsupported north EdgeFence execution '+current+': '+str(exc))
        # A reviewer could otherwise delete the x0 branch AND silently
        # rewrite the manifest to match. For ordinary EdgeFence north seams,
        # cross-check *both* original Gold border masks independently.
        # The older NorthEdgeFence/CollisionFence have specialized gate
        # semantics and their original dedicated contracts remain in force.
        from johto_indoor_collision_adapter import plan_gold_quadrant_collision
        candidates = [e for e in discover_active_edges(project)
                      if e[0] == current and e[4] == 'north']
        if len(candidates) != 1:
            raise ConnectionError('Cannot identify independent Gold north neighbor for '+current)
        gtarget = candidates[0][3]
        geom_target, target_mask = plan_gold_quadrant_collision(gold, gtarget, 'johto')
        stride_target = geom_target['mask_row_bytes']
        current_allowed = lambda tile: not (mask[tile//8] & (1 << (tile%8)))
        def target_allowed(tile):
            return not (target_mask[(len(target_mask)//stride_target-1)*stride_target+tile//8]
                        & (1 << (tile%8)))
        floor_crossings = []
        for x in range(2*dst_col, 2*(dst_col+overlap)):
            neighbor_x = x - 2*dst_col + 2*src_col
            if current_allowed(x) and target_allowed(neighbor_x):
                floor_crossings.append(x)
        if trace_legal != floor_crossings:
            raise ConnectionError(f'{current} executable north openings {trace_legal} '
                                  f'differ from independent Gold FLOOR/FLOOR seam {floor_crossings}')
        legal = trace_legal
    if sorted(exits) != legal:
        raise ConnectionError(f'{current} manifest exits {sorted(exits)} differ from runtime fence {legal}')
    # The camera also sees to the WEST of the first lane. Prior audits
    # covered only the right margin; the west Route43->Lake path x0 exposed
    # three default-tree columns despite a valid Gold neighboring blockset.
    left = min(3, src_col) if dst_col == 0 and min(exits) < 5 else 0
    right = (min(3, w2-(src_col+overlap))
             if max(exits) + 5 >= 2*w1 else 0)
    recorded_left = item.get('north_connection_visual_left_border', 0)
    recorded_right = item.get('north_connection_visual_right_border', 0)
    if type(recorded_left) is not int or recorded_left != left:
        raise ConnectionError(f'{current} north LEFT visual margin: recorded={recorded_left}, needed={left}')
    if type(recorded_right) is not int or recorded_right != right:
        raise ConnectionError(f'{current} north RIGHT visual margin: recorded={recorded_right}, needed={right}')
    if (src_col < left or src_col+overlap+right > w2 or
            3+dst_col-left < 0 or 3+dst_col+overlap+right > w1+6):
        raise ConnectionError('North display-only extension exceeds Gold source or WRAM margin')
    return left, right


def audit(project, gold, current, target, gold_current, gold_target, direction):
    direction = direction.lower()
    if direction not in ('north', 'south', 'east', 'west'):
        raise ConnectionError('Invalid direction: ' + direction)
    all_dims = dimensions(project)
    # Convert header CamelCase names to the constant referenced in the RPP map header.
    def map_id(camel):
        head = project/'data/mapHeaders'/f'{camel}.asm'
        source = head.read_text(encoding='utf-8')
        # The first db JOHTO is a region byte; following dimensions identify the map.
        m = re.search(r'^\s*db\s+([A-Z0-9_]+)_HEIGHT\s*,\s*\1_WIDTH\b', source, re.M)
        if m is None:
            raise ConnectionError('Cannot resolve RPP width and height constants for '+camel)
        return m.group(1)
    id1, id2 = map_id(current), map_id(target)
    if id1 not in all_dims or id2 not in all_dims:
        raise ConnectionError('Unknown RPP map dimensions')
    w1,h1=all_dims[id1]
    w2,h2=all_dims[id2]
    if min(w1,h1,w2,h2) <= 0 or (min(h1,h2) < 3 if direction in ('north','south') else min(w1,w2)<3):
        raise ConnectionError('Bad source or target dimensions')
    blocks=project/'maps'/f'{target}.blk'
    if len(blocks.read_bytes()) != w2*h2:
        raise ConnectionError(f'{blocks.name} size != registered dimensions {w2}x{h2}')
    gold_dims = {}
    for name, width, height in re.findall(r'^\s*map_const\s+(\w+),\s*(\d+),\s*(\d+)',
                                          (gold/'constants/map_constants.asm').read_text(encoding='utf-8'), re.M):
        gold_dims[name]=(int(width),int(height))
    def to_gold_const(name):
        return re.sub(r'(?<!^)(?=[A-Z])', '_', name).upper()  # Route30 -> ROUTE30; underscores inserted before number below
    def standard_gold_const(name):
        return re.sub(r'([A-Za-z])(\d+)', r'\1_\2', to_gold_const(name))
    g1, g2 = standard_gold_const(gold_current), standard_gold_const(gold_target)
    if gold_dims.get(g1)!=(w1,h1) or gold_dims.get(g2)!=(w2,h2):
        raise ConnectionError(f'Gold map sizes do not match RPP: {g1}={gold_dims.get(g1)} vs {(w1,h1)}; '+
                              f'{g2}={gold_dims.get(g2)} vs {(w2,h2)}')
    offset=gold_offset(gold, gold_current, gold_target, direction)
    stride=w1+6
    if direction in ('north','south'):
        src_col=max(0,-offset)
        dst_col=max(0,offset)
        overlap=min(w1-dst_col, w2-src_col)
        if overlap<=0:
            raise ConnectionError('Gold connection has no horizontal overlap')
        start_row=(h2-3) if direction=='north' else 0
        dest_row=0 if direction=='north' else (h1+3)
        visual_left, visual_right = north_visual_borders(project, gold, current, gold_current,
                                                          direction, w1, w2, src_col, dst_col, overlap)
        if (src_col < visual_left or src_col+overlap+visual_right > w2 or
                3+dst_col-visual_left < 0 or
                3+dst_col+overlap+visual_right > stride):
            raise ConnectionError('Visual-only north extension exceeds source or WRAM border')
        expected=dict(source_start=start_row*w2+src_col-visual_left,
                      dest_start=dest_row*stride+3+dst_col-visual_left,
                      width=overlap + visual_left + visual_right, map_width=w2,
                      arrive_y=2*h2-1 if direction=='north' else 0,
                      arrive_x=-2*offset,
                      window=1+h2*(w2+6) if direction=='north' else 7+w2)
        overlap_info=dict(source_columns=[src_col,src_col+overlap-1],
                          dest_columns=[dst_col,dst_col+overlap-1], rows=3,
                          visual_left_border=visual_left,
                          visual_right_border=visual_right)
    else:
        # Gold's east/west offset is the target map's TOP relative to the
        # current map's TOP. Positive => target starts farther south.
        src_row=max(0,-offset)
        dst_row=max(0,offset)
        overlap=min(h1-dst_row, h2-src_row)
        if overlap<=0:
            raise ConnectionError('Gold connection has no vertical overlap')
        src_col=w2-3 if direction=='west' else 0
        dst_col=0 if direction=='west' else w1+3
        expected=dict(source_start=src_row*w2+src_col,
                      dest_start=(dst_row+3)*stride+dst_col,
                      height=overlap, map_width=w2,
                      arrive_y=-2*offset,
                      arrive_x=2*w2-1 if direction=='west' else 0,
                      window=6+2*w2 if direction=='west' else 7+w2)
        overlap_info=dict(source_rows=[src_row,src_row+overlap-1],
                          dest_rows=[dst_row,dst_row+overlap-1], columns=3)
    actual=read_connection(project,current,target,direction,id1,id2,w1,h1,w2,h2)
    issues=[]
    for name, want in expected.items():
        if actual[name]!=want:
            issues.append(f'{name}: actual={actual[name]}, expected={want}')
    if direction in ('north','south'):
        # Independently check every row against the real .blk and buffer.
        for i in range(3):
            sr = actual['source_start']+i*w2
            dr = actual['dest_start']+i*stride
            if sr < 0 or sr//w2 != start_row+i or (sr+actual['width']-1)//w2 != start_row+i or sr+actual['width'] > w2*h2:
                issues.append(f'source_row_{i}: read crosses target .blk row or bounds')
            if dr < 0 or dr//stride != dest_row+i or (dr+actual['width']-1)//stride != dest_row+i:
                issues.append(f'dest_row_{i}: write crosses overworld buffer row or starts negative')
            if dr % stride < 3-visual_left or (dr+actual['width']-1)%stride > w1+2+visual_right:
                issues.append(f'dest_row_{i}: writes outside approved map/visual border')
            if dr + actual['width'] > (h1+6)*stride:
                issues.append(f'dest_row_{i}: write exceeds entire WRAM block map')
    else:
        # LoadEastWestConnectionsTileMap copies 3 columns per iteration.
        # Validate EACH source/destination row separately (not only endpoints).
        height=actual['height']
        if height <= 0 or height > min(h1,h2):
            issues.append('height: nonpositive or exceeds map height')
        for i in range(max(0,min(height,max(h1,h2)+6))):
            sr=actual['source_start']+i*w2
            dr=actual['dest_start']+i*stride
            if sr<0 or sr//w2 != src_row+i or (sr+2)//w2 != src_row+i or sr+2>=w2*h2:
                issues.append(f'source_row_{i}: 3-column read crosses target .blk or row')
            if dr<0 or dr//stride != dst_row+i+3 or (dr+2)//stride != dst_row+i+3 or dr+2>=(h1+6)*stride:
                issues.append(f'dest_row_{i}: 3-column write crosses overworld buffer or row')
            if dr%stride != dst_col:
                issues.append(f'dest_row_{i}: wrong edge column (expected {dst_col})')
    return dict(status='PASS' if not issues else 'FAIL', current=current, target=target,
                gold_offset=offset, direction=direction,
                current_size=[w1,h1], target_size=[w2,h2],
                overlap=overlap_info,
                actual=actual, expected=expected, issues=issues)

def discover_active_edges(project):
    """Read the registered Johto headers and enumerate every enabled edge.

    Reject incomplete records rather than allowing an omitted --edge to pass.
    This is a discovery layer for the existing audit(), not a map generator.
    """
    manifest = json.loads((project/'tools/johto_native_maps.json').read_text(encoding='utf-8'))
    entries = manifest['maps']
    registered = []
    for entry in entries:
        header = entry['header']
        if not header.endswith('_h'):
            raise ConnectionError('Unrecognized registered map header: '+str(header))
        registered.append(header[:-2])
    if len(registered)!=len(set(registered)) or not registered:
        raise ConnectionError('Duplicate/empty Johto native map registrations')
    active = []
    for current in registered:
        path = project/'data/mapHeaders'/f'{current}.asm'
        source = path.read_text(encoding='utf-8')
        # The single direction mask lives after the dimensions + data pointers.
        m = re.search(r'^\s*'+re.escape(current)+r'_h:\s*\n'
                      r'(?:[^\n]*\n)*?\s*db\s+((?:NORTH|SOUTH|EAST|WEST)(?:\s*\|\s*(?:NORTH|SOUTH|EAST|WEST))*)\s*(?:;[^\n]*)?$',
                      source, re.M)
        if not m:
            # Headers without map connections have a numeric 0 direction mask.
            # Verify such a mask exists; missing/parsing-failed masks are fatal.
            if not re.search(r'^\s*db\s+(?:\$00|0)\s*(?:;[^\n]*)?$', source, re.M):
                raise ConnectionError('Missing/unreadable direction mask in '+current)
            continue
        directions = [x.strip().lower() for x in m.group(1).split('|')]
        if not directions or len(set(directions))!=len(directions) or any(
                d not in ('north','south','east','west') for d in directions):
            raise ConnectionError('Bad connection mask in '+current)
        tail = [line.split(';',1)[0].strip() for line in source[m.end():].splitlines()]
        targets=[]
        for i,line in enumerate(tail):
            if line.startswith('dw '+current+'Object'):
                break
            macro = re.fullmatch(r'(NORTH|SOUTH|WEST|EAST)_MAP_CONNECTION\s+.*?,\s*(\w+)Blocks\s*',line)
            if macro:
                targets.append((macro.group(1).lower(),macro.group(2)))
                continue
            # A native bounded record starts with its one-byte map key
            # followed IMMEDIATELY by the neighbor block pointer. Numeric
            # width/arrival fields must never be mistaken for additional edges.
            if re.fullmatch(r'db\s+[A-Z_][A-Z0-9_]*',line):
                following=next((other for other in tail[i+1:] if other), '')
                block=re.fullmatch(r'dw\s+(\w+)Blocks(?:\s*\+.*)?', following)
                if block:
                    targets.append((None,block.group(1)))
        if len(targets)!=len(directions) or any(t is None for _,t in targets):
            raise ConnectionError(f'Cannot enumerate all active edges of {current}: '
                                  f'mask={directions} records={targets}')
        for direction,(macro_dir,target) in zip(directions,targets):
            if macro_dir is not None and macro_dir!=direction:
                raise ConnectionError(f'{current} direction order mismatch: {macro_dir} vs {direction}')
            if target not in registered:
                raise ConnectionError(f'{current} {direction}: unregistered Johto target {target}')
            def goldname(n):
                return n[5:] if n.startswith('Johto') else n
            active.append((current,target,goldname(current),goldname(target),direction))
    if not active:
        raise ConnectionError('No active native Johto connections discovered')
    return active


def check_native_connection_selector(project, current, target, direction):
    """Verify that a $FC header edge resolves to the correct native map.

    Geometry checks cannot see this separate runtime selector table. A bad
    direction used to make Route37 SOUTH fall back to legacy Route32.
    """
    header = (project/'data/mapHeaders'/f'{current}.asm').read_text(encoding='utf-8')
    target_record = re.search(
        r'^\s*db\s+REGION_NATIVE_MAP_SLOT\s*\n\s*dw\s+'
        + re.escape(target) + r'Blocks\b', header, re.M)
    if target_record is None:
        return
    entries = json.loads((project/'tools/johto_native_maps.json').read_text(encoding='utf-8'))['maps']
    symbols = {entry['header'][:-2]: entry['local_symbol'] for entry in entries}
    if current not in symbols or target not in symbols:
        raise ConnectionError(f'Native selector lacks registered ID: {current}->{target}')
    source = (project/'engine/overworld/region_map_lookup.asm').read_text(encoding='utf-8')
    if 'NativeRegionConnectionTargets::' not in source:
        raise ConnectionError('NativeRegionConnectionTargets table is missing')
    table = source.split('NativeRegionConnectionTargets::', 1)[1].split('\tdb $ff', 1)[0]
    records = re.findall(
        r'^\s*db\s+([A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*'
        r'(MAP_REGION_[A-Z0-9_]+)\s*,\s*([A-Z0-9_]+)\s*(?:;[^\n]*)?$',
        table, re.M)
    direction_index = {'north': 0, 'south': 1, 'west': 2, 'east': 3}[direction]
    matches = [(region, destination) for key, number, region, destination in records
               if key == symbols[current] and int(number) == direction_index]
    wanted = ('MAP_REGION_JOHTO', symbols[target])
    if matches != [wanted]:
        raise ConnectionError(
            f'{current} {direction}->{target}: runtime native selector '
            f'{symbols[current]}/{direction_index} gives {matches}, expected {[wanted]}')


def check_native_connection_preview_abi(project):
    """Prove the edge-direction argument survives RPP's far-call ABI.

    The $40/$45 seam once passed direction in A; Bankswitch overwrites A
    with BANK(callee), so source-only geometry tests missed wrong-bank art.
    This rule covers every cardinal preview, not just the current sea maps.
    """
    home = (project/'home/overworld.asm').read_text(encoding='utf-8')
    resolver = (project/'engine/overworld/region_map_lookup.asm').read_text(encoding='utf-8')
    macro = (project/'macros/asm_macros.asm').read_text(encoding='utf-8')
    switch = (project/'home.asm').read_text(encoding='utf-8')
    if not re.search(r'callab: MACRO.*?rst \$18', macro, re.S) or not re.search(
            r'Bankswitch::.*?ld a,b.*?jp hl', switch, re.S):
        raise ConnectionError('Cannot prove far-call ABI: direction register unknown')
    if 'ResolveNativeConnectionPreviewBank::' not in resolver:
        raise ConnectionError('Missing native connection preview bank resolver')
    resolver_body = resolver.split('ResolveNativeConnectionPreviewBank::',1)[1].split(
        'NativeRegionConnectionTargets::',1)[0]
    if not re.search(r'^\s*ld c,e\s*$',resolver_body,re.M):
        raise ConnectionError('Preview ABI: far call clobbers A; use E to pass direction to ld c,e')
    block = home.split('.northConnection\n',1)[-1].split(
        'LoadNorthSouthConnectionsTileMap::',1)[0]
    sites = re.findall(r'ld ([ae]),([0-3])\s+callab ResolveNativeConnectionPreviewBank',block)
    if sites != [('e',str(i)) for i in range(4)]:
        raise ConnectionError('Preview ABI: all four far-call edge directions must use E, not A: '+str(sites))
    if block.count('ld [MBC1RomBank],a')!=4 or block.count('ld [H_LOADEDROMBANK],a')!=4:
        raise ConnectionError('Preview ABI: four destination bank switches required')
    if not re.search(r'\bld e,\[hl\]',resolver_body):
        raise ConnectionError('Preview ABI: neighbor bank must be returned in E')


def check_sea_chain_surf_outer_edge(project, gold):
    """Reject the executable Surf -> legacy-land fallthrough at a map edge.

    Source-only contract plus independent Gold WATER connectivity: an ocean
    preview is not a new connection, and a passable 8x8 tile outside the map
    must never trigger a forced Surf dismount. Not a phone/CPU trace.
    """
    home=(project/'home/overworld.asm').read_text(encoding='utf-8')
    source=(project/'engine/overworld/johto_union_cave_surf.asm').read_text(encoding='utf-8')
    branch=home.split('CollisionCheckOnWater::',1)[-1].split('RunMapScript::',1)[0]
    pattern=(r'callba IsJohtoSurfWaterAhead\s+jr c, \.noCollision[^\n]*\n'
             r'(?:(?:\s*;[^\n]*\n)*)\s*callba IsJohtoSeaChainUnsafeSurfEdge\s+'
             r'jr c, \.collision\s+ld a, \[wTileInFrontOfPlayer\]')
    if not re.search(pattern,branch):
        raise ConnectionError('Sea Surf edge guard must execute after WATER and before legacy shore fallback')
    if 'IsJohtoSeaChainUnsafeSurfEdge::' not in source:
        raise ConnectionError('Missing Surf outer-edge predicate')
    body=source.split('IsJohtoSeaChainUnsafeSurfEdge::',1)[1].split('; Shared Gold WATER bitmap read',1)[0]
    allowed=('JOHTO_OLIVINE_CITY_LOCAL_ID','JOHTO_ROUTE_40_LOCAL_ID',
             'JOHTO_ROUTE_41_LOCAL_ID','JOHTO_CIANWOOD_CITY_LOCAL_ID')
    for identity in allowed:
        if 'cp '+identity not in body:
            raise ConnectionError('Surf outer-edge map whitelist missing '+identity)
    # Reject a helper which mistakenly claims a valid Gold seam is blocked:
    # the water dispatch MUST run first, with carry immediately accepted.
    for token in ('cp REGION_NATIVE_MAP_SLOT','cp MAP_REGION_JOHTO',
                  'cp PLAYER_DIR_LEFT','cp PLAYER_DIR_UP',
                  'cp PLAYER_DIR_RIGHT','cp PLAYER_DIR_DOWN',
                  'ld a,[wCurrentMapHeight2]','ld a,[wCurrentMapWidth2]',
                  'jr z,.blocked','.blocked\n scf\n pop bc\n ret',
                  '.clear\n and a\n pop bc\n ret'):
        if token not in body:
            raise ConnectionError('Surf outer-edge predicate contract changed: '+token)
    # Both Gold land-shapes and the runtime WATER masks are compared via the
    # dedicated Gold sea-chain tests. Here we also freeze the real topology;
    # the port lagoon is not a secret south connection into Route40.
    if ('OlivineCity west Route40 9' not in GOLD_DIRECT_SEAMS or
        re.search(r'(?m)^OlivineCity south ',GOLD_DIRECT_SEAMS)):
        raise ConnectionError('Gold Olivine route topology was changed to invent a south exit')
    return True


def check_olivine_route40_walk_seam(project, gold, *, collision_source=None):
    """Execute the restricted native collision ASM for every Gold coast seam cell.

    Gold FLOOR/FLOOR must pass *both* edge and land-mask predicates. WATER
    is a Surf-only exit. Any other role pair must block. Unknown opcodes fail
    closed rather than silently accepting an unverified source-code shape.
    """
    from johto_gold_cells import decode_cells
    root = Path(gold)
    met = (root/'data/tilesets/johto_metatiles.bin').read_bytes()
    coll = (root/'data/tilesets/johto_collision.asm').read_text()
    def cells(name, width, height):
        return {(c['x'],c['y']):c['role'] for c in decode_cells(
            (root/'maps'/f'{name}.blk').read_bytes(),met,coll,width,height)}
    olivine=cells('OlivineCity',20,18)
    route=cells('Route40',10,18)
    source=(collision_source if collision_source is not None else
            (Path(project)/'engine/overworld/johto_route33_collision.asm').read_text())
    width={'JOHTO_OLIVINE_CITY_WIDTH':20,'JOHTO_ROUTE_40_WIDTH':10}
    def subroutine(name):
        pattern=r'(?m)^'+re.escape(name)+r'::\s*$'
        found=re.search(pattern,source)
        if not found:
            raise ConnectionError('Missing land seam predicate: '+name)
        part=re.split(r'(?m)^\w+::\s*$',source[found.end():],maxsplit=1)[0]
        lines=[]; labels={}
        for raw in part.splitlines():
            line=raw.split(';',1)[0].strip()
            if not line:continue
            if re.fullmatch(r'\.[a-zA-Z0-9_]+',line):
                if line in labels:raise ConnectionError('Duplicate local collision label '+line)
                labels[line]=len(lines)
            elif re.fullmatch(r'\w+::',line):
                break
            else: lines.append(line)
        return lines,labels
    def run(name,x,y,direction):
        instr,labels=subroutine(name)
        a=0; zero=False; carry=False; hl=None; stride=None; rowbytes=None
        def eval_cp(expr):
            expr=expr.strip()
            if expr in width:return width[expr]
            if expr=='MAP_REGION_JOHTO':return 'MAP_REGION_JOHTO'
            if expr.startswith('JOHTO_') and expr.endswith('_LOCAL_ID'):return expr
            if expr.startswith('PLAYER_DIR_'):return expr
            if expr in ('JOHTO_OLIVINE_CITY_WIDTH * 2 - 1','JOHTO_ROUTE_40_WIDTH * 2 - 1'):
                return width[expr.split(' *')[0]]*2-1
            if expr in ('JOHTO_OLIVINE_CITY_WIDTH * 2','JOHTO_ROUTE_40_WIDTH * 2'):
                return width[expr.split(' *')[0]]*2
            if expr.isdecimal():return int(expr)
            raise ConnectionError('Unsupported collision comparison: '+expr)
        env={'[wCurRegion]':'MAP_REGION_JOHTO',
             '[wCurLocalMapID]':'JOHTO_OLIVINE_CITY_LOCAL_ID' if 'Olivine' in name else 'JOHTO_ROUTE_40_LOCAL_ID',
             '[wXCoord]':x,'[wYCoord]':y,'[wPlayerDirection]':direction}
        pos=0
        for _ in range(100):
            if pos<0 or pos>=len(instr):
                raise ConnectionError('Collision routine fell through '+name)
            line=instr[pos];pos+=1
            m=re.fullmatch(r'ld\s+(a|hl|d|e),\s*(.+)',line)
            if m:
                reg,arg=m.groups()
                if reg=='a':a=env[arg] if arg in env else eval_cp(arg)
                elif reg=='hl':hl=arg
                elif reg=='d':stride=eval_cp(arg)
                else:rowbytes=eval_cp(arg)
                continue
            if line=='and a':zero=(a==0);carry=False;continue
            if line=='scf':carry=True;continue
            if line=='ret':return carry
            m=re.fullmatch(r'cp\s+(.+)',line)
            if m:
                other=eval_cp(m.group(1));zero=(a==other)
                carry=(a<other) if isinstance(a,int) and isinstance(other,int) else False
                continue
            m=re.fullmatch(r'(jr|jp)\s+(?:(z|nz|c|nc),\s*)?(\.\w+|JohtoModernMaskedStep)',line)
            if m:
                _,flag,target=m.groups()
                take=(flag is None or {'z':zero,'nz':not zero,'c':carry,'nc':not carry}[flag])
                if not take:continue
                if target=='JohtoModernMaskedStep':
                    src='JohtoOlivineCity' if 'Olivine' in name else 'JohtoRoute40'
                    expect_width=40 if src.endswith('OlivineCity') else 20
                    expect_bytes=5 if expect_width==40 else 3
                    if (hl!=src+'BlockedRows' or stride!=expect_width or rowbytes!=expect_bytes):
                        raise ConnectionError('Wrong land mask binding '+name)
                    dx={'PLAYER_DIR_LEFT':-1,'PLAYER_DIR_RIGHT':1,
                        'PLAYER_DIR_UP':0,'PLAYER_DIR_DOWN':0}[direction]
                    dy={'PLAYER_DIR_LEFT':0,'PLAYER_DIR_RIGHT':0,
                        'PLAYER_DIR_UP':-1,'PLAYER_DIR_DOWN':1}[direction]
                    nx,ny=x+dx,y+dy
                    if not (0<=nx<expect_width and 0<=ny<36):return True
                    mask=(Path(project)/'maps'/f'{src}.blocked_mask.bin').read_bytes()
                    return bool(mask[ny*expect_bytes+nx//8] & (1<<(nx%8)))
                if target not in labels:raise ConnectionError('Unknown collision target: '+target)
                pos=labels[target]
                continue
            raise ConnectionError('Unsupported collision instruction '+name+': '+line)
        raise ConnectionError('Nonterminating collision predicate: '+name)
    olivine_edge='JohtoOlivineCityEdgeFence'
    olivine_land='JohtoOlivineCityCanStepAhead'
    route_edge='JohtoRoute40EdgeFence'
    route_land='JohtoRoute40CanStepAhead'
    checked=[]
    for y in range(36):
        other=y-18
        role1=olivine[(0,y)]
        role2=route.get((19,other))
        allow=role1==role2 and role1 in ('FLOOR','WATER')
        walk=role1==role2=='FLOOR'
        for name,step,yy,xx,dirn in ((olivine_edge,False,y,0,'PLAYER_DIR_LEFT'),
                                       (olivine_land,True,y,0,'PLAYER_DIR_LEFT')):
            actual=not run(name,xx,yy,dirn)
            if actual!=(walk if step else allow):
                raise ConnectionError(f'Gold walk seam mismatch {name} y={yy}: '
                                      f'roles={role1}/{role2}, allowed={actual}')
        if 0<=other<36:
            for name,step in ((route_edge,False),(route_land,True)):
                actual=not run(name,19,other,'PLAYER_DIR_RIGHT')
                if actual!=(walk if step else allow):
                    raise ConnectionError(f'Gold reverse walk seam mismatch {name} y={other}: '
                                          f'roles={role2}/{role1}, allowed={actual}')
        if walk:checked.append(y)
    if checked != [20,22,23,24,25]:
        raise ConnectionError('Gold land seam changed unexpectedly: '+str(checked))
    return {'land_rows':checked,'water_rows':list(range(26,32))}


def check_native_connection_copy_executor(project):
    """Fail closed if the actual three-strip renderer diverges from audited ASM.

    A correct Header and Gold connection offset do *not* prove the renderer
    fills all three WRAM rows/columns. This protects the small existing
    north/south and east/west executors, ignoring only layout/comments.
    A legitimate kernel rewrite requires separately reviewing this contract.
    """
    root = Path(project)
    constants = (root/'constants/connection_constants.asm').read_text(encoding='utf-8')
    if not re.search(r'(?m)^\s*MAP_BORDER\s+EQU\s+3\s*(?:;.*)?$', constants):
        raise ConnectionError('BLK renderer requires reviewed MAP_BORDER=3')
    source = (root/'home/overworld.asm').read_text(encoding='utf-8')
    expected = {
        'LoadNorthSouthConnectionsTileMap': """
            ld c,MAP_BORDER
            .loop
            push de
            push hl
            ld a,[hNorthSouthConnectionStripWidth]
            ld b,a
            .innerLoop
            ld a,[hli]
            ld [de],a
            inc de
            dec b
            jr nz,.innerLoop
            pop hl
            pop de
            ld a,[hNorthSouthConnectedMapWidth]
            add l
            ld l,a
            jr nc,.noCarry1
            inc h
            .noCarry1
            ld a,[wCurMapWidth]
            add MAP_BORDER * 2
            add e
            ld e,a
            jr nc,.noCarry2
            inc d
            .noCarry2
            dec c
            jr nz,.loop
            ret
        """,
        'LoadEastWestConnectionsTileMap': """
            push hl
            push de
            ld c,MAP_BORDER
            .innerLoop
            ld a,[hli]
            ld [de],a
            inc de
            dec c
            jr nz,.innerLoop
            pop de
            pop hl
            ld a,[hEastWestConnectedMapWidth]
            add l
            ld l,a
            jr nc,.noCarry1
            inc h
            .noCarry1
            ld a,[wCurMapWidth]
            add MAP_BORDER * 2
            add e
            ld e,a
            jr nc,.noCarry2
            inc d
            .noCarry2
            dec b
            jr nz,LoadEastWestConnectionsTileMap
            ret
        """,
    }

    def normalize(text):
        # Never ignore an actual instruction or extra branch: only whitespace
        # and semicolon-comments are irrelevant for this frozen RPP kernel.
        return [re.sub(r'\s+', '', line.split(';', 1)[0])
                for raw in text.splitlines()
                if (line := raw.strip().split(';', 1)[0].strip())]

    for label, desired in expected.items():
        head = re.search(r'(?m)^' + label + r'::\s*$', source)
        if not head or len(re.findall(r'(?m)^' + label + r'::\s*$', source)) != 1:
            raise ConnectionError('BLK copy executor missing/duplicated: ' + label)
        tail = source[head.end():]
        next_label = re.search(r'(?m)^\w+::\s*$', tail)
        if not next_label:
            raise ConnectionError('BLK copy executor has no terminal label: '+label)
        actual = normalize(tail[:next_label.start()])
        want = normalize(desired)
        if actual != want:
            offset = next((i for i in range(min(len(actual),len(want)))
                           if actual[i] != want[i]), min(len(actual),len(want)))
            found = actual[offset] if offset < len(actual) else '<missing>'
            requested = want[offset] if offset < len(want) else '<end>'
            raise ConnectionError(f'BLK copy executor drift {label} opcode {offset}: '
                                  f'actual={found}, reviewed={requested}')


def audit_all_active(project, gold):
    """Fail closed on any missing, unparseable, or unsafe enabled connection."""
    try:
        edges = discover_active_edges(project)
    except (ConnectionError, OSError, ValueError, KeyError) as ex:
        return {'status':'FAIL', 'edges':[], 'issues':['DISCOVERY: '+str(ex)]}
    global_issues=[]
    try:
        check_native_connection_copy_executor(project)
    except (ConnectionError, OSError, ValueError) as ex:
        global_issues.append('BLK_COPY_EXECUTOR: '+str(ex))
    try:
        check_olivine_route40_walk_seam(project,gold)
    except (ConnectionError,OSError,ValueError) as ex:
        global_issues.append('COAST_WALK_SEAM: '+str(ex))
    try:
        check_sea_chain_surf_outer_edge(project,gold)
    except (ConnectionError,OSError,ValueError) as ex:
        global_issues.append('SURF_OUTER_EDGE: '+str(ex))
    try:
        frozen=check_frozen_gold_source(gold)
        require_registered_gold_seams(project,edges,frozen)
    except (ConnectionError, OSError, ValueError, KeyError) as ex:
        global_issues.append('GOLD_TOPOLOGY: '+str(ex))
    result = []
    for edge in edges:
        try:
            item=audit(project,gold,*edge)
            check_native_connection_selector(project,edge[0],edge[1],edge[4])
            if map_header_bank(project,edge[0])!=map_header_bank(project,edge[1]):
                # Only reviewed native cross-bank seams are allowed. .235's
                # MahoganyTown ($40) <-> Route43 ($45) uses the same preview
                # bank resolver/ABI previously proved for Olivine/Route40.
                # An unrelated relocation must still fail closed.
                approved_cross_bank = {
                    frozenset(('JohtoOlivineCity', 'JohtoRoute40')),
                    frozenset(('JohtoMahoganyTown', 'JohtoRoute43')),
                    frozenset(('JohtoMahoganyTown', 'JohtoRoute44')),
                    frozenset(('JohtoRoute29', 'JohtoRoute46')),
                }
                if frozenset((edge[0], edge[1])) not in approved_cross_bank:
                    item['issues'].append('ROM bank mismatch: unregistered cross-bank map seam')
                    item['status']='FAIL'
                    result.append(item)
                    continue
                # Validate the *far-call ABI*, not merely the presence of
                # four calls; a direction in A is destroyed by Bankswitch.
                check_native_connection_preview_abi(project)
            result.append(item)
        except (ConnectionError,OSError,ValueError,KeyError) as ex:
            result.append({'status':'FAIL','edge':edge,'issues':[str(ex)]})
    try:
        check_all_native_selectors(project,edges)
    except (ConnectionError, OSError, ValueError, KeyError) as ex:
        global_issues.append('NATIVE_SELECTOR: '+str(ex))
    return {'status':'PASS' if not global_issues and all(e['status']=='PASS' for e in result) else 'FAIL',
            'edges':result,'issues':global_issues,
            'scope':'Frozen Gold 368 maps/142 direct seams + complete registered RPP topology + native selectors; source-only. Warps use separate gatehouse audits.'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,required=True)
    parser.add_argument('--gold-root',type=Path,required=True)
    parser.add_argument('--all-active',action='store_true',
                        help='Automatically check EVERY enabled registered native Johto connection')
    parser.add_argument('--edge',nargs=5,action='append',
                        metavar=('RPP_CURRENT','RPP_TARGET','GOLD_CURRENT','GOLD_TARGET','DIRECTION'),
                        help='Repeat per NEW connection (north/south/east/west)')
    parser.add_argument('--json-out',type=Path,default=None)
    args=parser.parse_args()
    if args.all_active and args.edge:
        parser.error('Use --all-active or explicit --edge, not both')
    if not args.all_active and not args.edge:
        parser.error('Use --all-active or at least one --edge')
    if args.all_active:
        output = audit_all_active(args.project,args.gold_root)
        serialized = json.dumps(output,ensure_ascii=False,indent=2)
        print(serialized)
        if args.json_out:
            args.json_out.write_text(serialized+'\n',encoding='utf-8')
        return 0 if output['status']=='PASS' else 2
    result=[]
    for edge in args.edge:
        try:
            item=audit(args.project,args.gold_root,*edge)
            if (args.project/'tools/johto_native_maps.json').is_file():
                check_native_connection_selector(args.project,edge[0],edge[1],edge[4])
            result.append(item)
        except (ConnectionError,OSError,ValueError) as ex:
            result.append(dict(status='FAIL',edge=edge,issues=[str(ex)]))
    output={'status':'PASS' if all(e['status']=='PASS' for e in result) else 'FAIL', 'edges':result,
            'scope':'Static connection bytes only; does not compile or run ROM'}
    serialized=json.dumps(output,ensure_ascii=False,indent=2)
    print(serialized)
    if args.json_out:
        args.json_out.write_text(serialized+'\n',encoding='utf-8')
    return 0 if output['status']=='PASS' else 2


if __name__=='__main__':
    sys.exit(main())
