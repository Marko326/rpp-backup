#!/usr/bin/env python3
"""Fail-closed Gold -> RPP north/south connection geometry audit (source-only).

The Gold `connection` macro and RPP's legacy *_MAP_CONNECTION macros do NOT
interpret negative offsets in the same way. This deliberately audits the
emitted strip fields, not merely the macro's spelling or Gold's offset.

No ROM compilation, no files modified. For EAST/WEST, implement and test an
additional model before enabling that direction: unsupported == FAIL.
"""
import argparse
import ast
import json
from pathlib import Path
import re
import sys


class ConnectionError(ValueError):
    pass


def dimensions(project):
    text = (project / 'constants/map_constants.asm').read_text(encoding='utf-8')
    found = {}
    for name, height, width in re.findall(r'^\s*mapconst\s+(\w+),\s*(\d+),\s*(\d+)', text, re.M):
        found[name] = (int(width), int(height))
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
    if direction not in ('north', 'south'):
        raise ConnectionError('Only north/south modeled: east/west must not silently pass')
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
            else:
                source_start = source_offset
                dest_start = 3+(h1+3)*(w1+6)+move
                width = (w1 - move + (3 if len(args) == 6 else 0)) if w1 < w2 else (w2-source_offset)
                y = 0
                window = 7+w2
            candidates.append(dict(format='legacy_macro', source_start=source_start, dest_start=dest_start,
                                   width=width, map_width=w2, arrive_y=y, arrive_x=-2*(move-source_offset),
                                   window=window))
    return candidates, lines, names


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
    for i, line in enumerate(lines):
        if line != 'db ' + target_id:
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
        values = [constant_expr(expr, names) for kind, expr in next_fields]
        candidates.append(dict(format='bounded_custom', source_start=values[0], dest_start=values[1],
                               width=values[2], map_width=values[3], arrive_y=values[4],
                               arrive_x=values[5], window=values[6]))
    if len(candidates) != 1:
        raise ConnectionError(f'Need exactly one {direction} connection {current}->{target}; found {len(candidates)}')
    return candidates[0]


def audit(project, gold, current, target, gold_current, gold_target, direction):
    direction = direction.lower()
    if direction not in ('north', 'south'):
        raise ConnectionError('Only north/south modeled; east/west fail closed until implemented')
    all_dims = dimensions(project)
    # Convert header CamelCase names to the constant referenced in the RPP map header.
    def map_id(camel):
        head = project/'data/mapHeaders'/f'{camel}.asm'
        source = head.read_text(encoding='utf-8')
        # The first db JOHTO is a region byte; following dimensions identify the map.
        m = re.search(r'^\s*db\s+(JOHTO_[A-Z0-9_]+)_HEIGHT\s*,\s*\1_WIDTH', source, re.M)
        if m is None:
            raise ConnectionError('Cannot resolve RPP width and height constants for '+camel)
        return m.group(1)
    id1, id2 = map_id(current), map_id(target)
    if id1 not in all_dims or id2 not in all_dims:
        raise ConnectionError('Unknown RPP map dimensions')
    w1,h1=all_dims[id1]
    w2,h2=all_dims[id2]
    if min(w1,h1,w2,h2) <= 0 or min(h1,h2) < 3:
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
    src_col=max(0,-offset)
    dst_col=max(0,offset)
    overlap=min(w1-dst_col, w2-src_col)
    if overlap<=0:
        raise ConnectionError('Gold connection has no horizontal overlap')
    stride=w1+6
    start_row=(h2-3) if direction=='north' else 0
    dest_row=0 if direction=='north' else (h1+3)
    expected=dict(source_start=start_row*w2+src_col,
                  dest_start=dest_row*stride+3+dst_col,
                  width=overlap, map_width=w2,
                  arrive_y=2*h2-1 if direction=='north' else 0,
                  arrive_x=-2*offset,
                  window=1+h2*(w2+6) if direction=='north' else 7+w2)
    actual=read_connection(project,current,target,direction,id1,id2,w1,h1,w2,h2)
    issues=[]
    for name, want in expected.items():
        if actual[name]!=want:
            issues.append(f'{name}: actual={actual[name]}, expected={want}')
    # Independently check every row against both real .blk dimensions and
    # the current overworld buffer row, rather than assuming named constants
    # or macro expansion always imply safety.
    for i in range(3):
        sr = actual['source_start']+i*w2
        dr = actual['dest_start']+i*stride
        if sr < 0 or sr//w2 != start_row+i or (sr+actual['width']-1)//w2 != start_row+i or sr+actual['width'] > w2*h2:
            issues.append(f'source_row_{i}: read crosses target .blk row or bounds')
        if dr < 0 or dr//stride != dest_row+i or (dr+actual['width']-1)//stride != dest_row+i:
            issues.append(f'dest_row_{i}: write crosses overworld buffer row or starts negative')
        if dr % stride < 3 or (dr+actual['width']-1)%stride > w1+2:
            issues.append(f'dest_row_{i}: writes outside current map/canonical border')
    return dict(status='PASS' if not issues else 'FAIL', current=current, target=target,
                gold_offset=offset, direction=direction,
                current_size=[w1,h1], target_size=[w2,h2],
                overlap=dict(source_columns=[src_col,src_col+overlap-1],
                             dest_columns=[dst_col,dst_col+overlap-1], rows=3),
                actual=actual, expected=expected, issues=issues)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,required=True)
    parser.add_argument('--gold-root',type=Path,required=True)
    parser.add_argument('--edge',nargs=5,action='append',required=True,
                        metavar=('RPP_CURRENT','RPP_TARGET','GOLD_CURRENT','GOLD_TARGET','DIRECTION'),
                        help='Repeat per NEW connection; only north/south supported until extended')
    parser.add_argument('--json-out',type=Path,default=None)
    args=parser.parse_args()
    result=[]
    for edge in args.edge:
        try:
            result.append(audit(args.project,args.gold_root,*edge))
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
