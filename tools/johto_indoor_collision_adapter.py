#!/usr/bin/env python3
"""Offline Gold 16x16 collision -> RPP 8x8 walkability evidence.

This module deliberately does not infer RPP warp/door or runtime collision from
matching art. Per-quadrant disagreements are reported; none is auto-approved.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
from johto_indoor_common import ConversionError, dump, safe_roots
from johto_indoor_tiles_converter import build_mapping


GOLD_BLOCKED = frozenset(('WALL', 'COUNTER'))
GOLD_FLOOR = frozenset(('FLOOR',))

# Corpus labels checked against the COMPLETE Gold source, not a map-specific
# whitelist. Adding a new collision role requires explicitly reviewing it.
PORTAL_ROLES = frozenset({'CAVE', 'DOOR', 'STAIRCASE', 'LADDER',
                          'WARP_PANEL', 'WARP_CARPET_DOWN',
                          'WARP_CARPET_LEFT', 'WARP_CARPET_RIGHT',
                          'WARP_CARPET_UP'})
ORDINARY_ROLES = frozenset({'FLOOR', 'TALL_GRASS', 'LONG_GRASS'})
DIRECTIONAL_ROLES = frozenset({'HOP_DOWN', 'HOP_DOWN_LEFT', 'HOP_DOWN_RIGHT',
                                'HOP_LEFT', 'HOP_RIGHT'})
FIELD_MOVE_ROLES = frozenset({'CUT_TREE', 'HEADBUTT_TREE', 'WATER',
                              'WATER_21', 'WATERFALL', 'WHIRLPOOL'})
SOLID_ROLES = frozenset({'WALL', 'UP_WALL', 'COUNTER', 'BUOY', 'PIT'})
INTERACT_ROLES = frozenset({'BOOKSHELF', 'ICE', 'INCENSE_BURNER', 'MART_SHELF',
                             'PC', 'RADIO', 'TOWN_MAP', 'TV', 'WINDOW'})
ROLE_SEMANTICS = {role: group for group, roles in (
    ('portal', PORTAL_ROLES), ('ordinary', ORDINARY_ROLES),
    ('directional', DIRECTIONAL_ROLES), ('field_move', FIELD_MOVE_ROLES),
    ('solid', SOLID_ROLES), ('interact', INTERACT_ROLES)) for role in roles}


def portal_approach_edges(cells, width, height):
    """Enumerate all 4-direction source -> portal edges, not allowed steps.

    An approach from a solid Gold tile is still evidence to test BLOCKING.
    The direction and source role remain explicit for future runtime auditing.
    """
    directions = ((0, -1, 'UP'), (0, 1, 'DOWN'),
                  (-1, 0, 'LEFT'), (1, 0, 'RIGHT'))
    edges = []
    for target in cells:
        if target['role'] not in PORTAL_ROLES:
            continue
        x, y = target['x'], target['y']
        for dx, dy, direction in directions:
            sx, sy = x-dx, y-dy
            if 0 <= sx < width and 0 <= sy < height:
                src = cells[sy*width+sx]
                semantic = ROLE_SEMANTICS[src['role']]
                edges.append({'from_x': sx, 'from_y': sy,
                              'from_role': src['role'], 'to_x': x, 'to_y': y,
                              'to_role': target['role'], 'direction': direction,
                              'source_semantics': semantic,
                              'review_priority': ('TRAVERSAL_CANDIDATE' if semantic in
                                  ('ordinary', 'portal') else 'CHECK_BLOCKED_OR_SPECIAL'),
                              'rpp_runtime_verified': False})
    return edges


def classify_gold(label: str) -> str:
    if label in GOLD_FLOOR:
        return 'PASSABLE'
    if label in GOLD_BLOCKED:
        return 'BLOCKED'
    return 'SPECIAL'


def quadrant_evidence(block: bytes, passable: set[int]) -> list[str]:
    """For four 16x16 quadrants, inspect all four RPP 8x8 IDs."""
    if len(block) != 16:
        raise ConversionError('RPP metatile 必须恰好 16 字节')
    evidence = []
    for y in range(2):
        for x in range(2):
            quadrant = [block[(y*2+dy)*4+x*2+dx]
                        for dy in range(2) for dx in range(2)]
            status = ('PASSABLE' if all(i in passable for i in quadrant)
                      else 'BLOCKED' if all(i not in passable for i in quadrant)
                      else 'MIXED')
            evidence.append(status)
    return evidence


def compare_quadrants(gold_labels: list[str], rpp_quads: list[str]) -> list[dict]:
    if len(gold_labels) != 4 or len(rpp_quads) != 4:
        raise ConversionError('Gold/RPP 每个 metatile 必须有 4 个碰撞象限')
    compared = []
    for index, (gold_label, actual) in enumerate(zip(gold_labels, rpp_quads)):
        expected = classify_gold(gold_label)
        match = 'SPECIAL_REVIEW' if expected == 'SPECIAL' else (
            'MIXED_REVIEW' if actual == 'MIXED' else
            'MATCH' if expected == actual else 'MISMATCH')
        compared.append({'quadrant': index, 'gold_label': gold_label,
                         'gold_class': expected, 'rpp_evidence': actual,
                         'comparison': match})
    return compared


def check(rpp: Path, gold: Path, graphics: dict, rpp_set='gate'):
    labels, location = collision_labels(gold, graphics['gold_tileset'], gold_resource_aliases(gold))
    if not labels:
        raise ConversionError('Gold collision 源缺失')
    data = (rpp/'gfx/blocksets'/f'{rpp_set}.bst').read_bytes()
    # The selected RPP tileset may reuse another tileset's collision list.
    # JOHTO_GATE explicitly refers to Gate_Coll; selecting johto_gate.tilecoll
    # by filename would invent a resource that the runtime never loads.
    symbol=''.join(part.capitalize() for part in rpp_set.split('_'))
    header=(rpp/'data/tileset_headers.asm').read_text(encoding='utf-8')
    found=re.search(r'^\s*tileset\s+'+re.escape(symbol)+
                    r'_Block\s*,\s*\w+\s*,\s*(\w+)\s*,', header, re.M)
    if not found:
        raise ConversionError(f'RPP tileset header lacks collision symbol: {rpp_set}')
    decl=(rpp/'data/collision.asm').read_text(encoding='utf-8')
    resolved=re.search(r'^'+re.escape(found[1])+r'::\s*INCBIN\s+"(gfx/tilesets/[^"\n]+\.tilecoll)"',
                       decl, re.M)
    if not resolved:
        raise ConversionError(f'RPP collision symbol unresolved: {found[1]}')
    collision_file = rpp/resolved[1]
    whitelist = collision_file.read_bytes()
    if len(data) % 16 or not whitelist or whitelist[-1] != 255 or 255 in whitelist[:-1]:
        raise ConversionError('RPP blockset/tilecoll 结构不合法或存在提前终止符')
    passable = set(whitelist[:-1])
    if not passable:
        raise ConversionError('RPP 可通行表为空')
    table, issues = [], []
    for entry in graphics['mapping']:
        gid = entry['gold_block_id']
        if gid >= len(labels):
            raise ConversionError('Gold collision 数量与 metatile 不匹配')
        gold_coll = [v.strip() for v in labels[gid].split(',')]
        if len(gold_coll) != 4:
            raise ConversionError(f'Gold {gid} 碰撞不是四象限')
        choices = []
        if not entry['rpp_candidates']:
            issues.append({'gold_block_id': gid, 'code': 'NO_PIXEL_EXACT_RPP_CANDIDATE'})
        for target in entry['rpp_candidates']:
            if not isinstance(target, int) or target < 0 or (target+1)*16 > len(data):
                raise ConversionError('RPP 目标区块 ID 越界')
            block = data[target*16:(target+1)*16]
            actual = quadrant_evidence(block, passable)
            compared = compare_quadrants(gold_coll, actual)
            mismatches = [q['quadrant'] for q in compared if q['comparison'] == 'MISMATCH']
            special = [q['quadrant'] for q in compared if q['comparison'] == 'SPECIAL_REVIEW']
            mixed = [q['quadrant'] for q in compared if q['comparison'] == 'MIXED_REVIEW']
            choices.append({'rpp_block_id': target, 'quadrant_comparisons': compared,
                            'mismatching_quadrants': mismatches,
                            'special_quadrants': special, 'mixed_quadrants': mixed,
                            'all_ordinary_quadrants_match': not (mismatches or special or mixed)})
            for code, group in (('COLLISION_CLASS_MISMATCH', mismatches),
                                ('SPECIAL_SEMANTICS_UNVERIFIED', special),
                                ('MIXED_8X8_TILE_WALKABILITY', mixed)):
                if group:
                    issues.append({'gold_block_id': gid, 'rpp_block_id': target,
                                   'code': code, 'quadrants': group})
        # Gold `DOOR` and other specials require engine-specific checks even
        # when RPP's whitelist happens to classify the 8x8 tiles as passable.
        if any(classify_gold(label) == 'SPECIAL' for label in gold_coll):
            issues.append({'gold_block_id': gid, 'code': 'GOLD_SPECIAL_NEEDS_RUNTIME_MAPPING'})
        table.append({'gold_block_id': gid, 'gold_collision': gold_coll,
                      'rpp_candidates': choices, 'review_required': True})
    counts = {code: sum(x['code'] == code for x in issues)
              for code in sorted({i['code'] for i in issues})}
    return {'schema': 'johto-indoor-collision-v2',
            'gold_collision_file': location,
            'rpp_tilecoll_file': str(collision_file.relative_to(rpp)),
            'rpp_passable_tile_ids': sorted(passable),
            'blocks': table, 'issues': issues, 'issue_counts': counts,
            'status': 'COLLISION_REVIEW_REQUIRED', 'auto_approve': False,
            'reason': 'Tile-ID whitelist evidence cannot certify door/warp triggers, NPC collision or in-game behavior'}


def plan_gold_quadrant_collision(gold: Path, map_name: str, gold_set: str,
                                 *, walkable_roles=None, graphic_slots=96):
    """Generic 16x16 Gold collision plan; DOES NOT register runtime logic.

    All geometry is derived from Gold source and one explicit per-tileset
    walkable-role policy, never from the completed RPP map or audit outputs.
    """
    from collections import Counter, defaultdict
    from johto_gold_sources import gold_block_sources
    from johto_rpp_asset_audit import blocks_for, collision_labels, gold_resource_aliases
    from johto_indoor_common import gold_dimensions
    if walkable_roles is None:
        walkable_roles = {'FLOOR','TALL_GRASS','HOP_DOWN','HOP_LEFT','HOP_DOWN_LEFT','HOP_DOWN_RIGHT'}
    walkable_roles = set(walkable_roles)
    aliases = gold_resource_aliases(gold)
    w,h = gold_dimensions(gold,map_name)
    layout_source = gold_block_sources(gold).get(map_name)
    if layout_source is None:
        raise ConversionError('Missing Gold blocks source for map')
    layout = (gold/layout_source).read_bytes()
    blocks,_,_ = blocks_for(gold,gold_set,'gold',aliases)
    collision,_ = collision_labels(gold,gold_set,aliases)
    block_count=len(blocks)//16
    # Gold collision tables sometimes reserve more IDs than the graphical
    # metatile set (e.g. Forest: 40 metatiles, 64 collision entries).
    # Every graphical ID must have collision data; surplus entries are valid.
    if (len(layout)!=w*h or not blocks or len(blocks)%16 or block_count>256 or
            len(collision)<block_count):
        raise ConversionError('Gold collision/layout sources do not match dimensions')
    collision_rows=[tuple(x.strip() for x in c.split(',')) for c in collision]
    if any(len(row)!=4 or not all(row) for row in collision_rows):
        raise ConversionError('Gold collision has malformed quadrant definitions')
    width,height=w*2,h*2
    cells=[]
    for y in range(height):
        for x in range(width):
            block=layout[(y//2)*w + x//2]
            if block >= block_count:
                raise ConversionError('Out-of-range Gold block ID')
            quadrant=(y%2)*2+(x%2)
            base=block*16+(y%2)*8+(x%2)*2
            gfx=(blocks[base],blocks[base+1],blocks[base+4],blocks[base+5])
            if max(gfx)>=graphic_slots:
                raise ConversionError('Gold map references graphics beyond runtime window')
            role = collision_rows[block][quadrant]
            if role not in ROLE_SEMANTICS:
                raise ConversionError(f'Gold 未分类碰撞语义: {map_name} ({x},{y}) {role}')
            cells.append({'x':x,'y':y,'role':role,
                          'graphics':gfx,'image_id':gfx[2]})
    blocked=bytearray()
    for y in range(height):
        for byteidx in range((width+7)//8):
            value=0
            for bit in range(8):
                x=byteidx*8+bit
                if x<width and cells[y*width+x]['role'] not in walkable_roles:
                    value|=1<<bit
            blocked.append(value)
    hops=[]
    unsafe_hops=[]
    directions={'HOP_DOWN':((0,1),),'HOP_LEFT':((-1,0),),
                'HOP_DOWN_LEFT':((0,1),(-1,0)),
                'HOP_DOWN_RIGHT':((0,1),(1,0)),
                'HOP_UP':((0,-1),),'HOP_RIGHT':((1,0),)}
    for c in cells:
        for dx,dy in directions.get(c['role'],()):
            points=[(c['x']+n*dx,c['y']+n*dy) for n in (1,2,3)]
            safe=all(0<=xx<width and 0<=yy<height for xx,yy in points)
            if safe:
                behind, landing, nextstep=(cells[yy*width+xx] for xx,yy in points)
                safe=(behind['role'] in {'WALL','UP_WALL'} and
                      landing['role'] in {'FLOOR','TALL_GRASS'} and
                      nextstep['role'] in {'FLOOR','TALL_GRASS'})
            if not safe:
                unsafe_hops.append({'x':c['x'],'y':c['y'],'dx':dx,'dy':dy,
                                    'reason':'landing/solid/out-of-bounds needs manual review'})
                continue
            hops.append({'x':c['x'],'y':c['y'],'dx':dx,'dy':dy,
                         'from_tile':c['image_id'],'edge_tile':behind['image_id'],
                         'landing':[points[1][0],points[1][1]]})
    aliases_by_image=defaultdict(set)
    for c in cells: aliases_by_image[c['image_id']].add(c['role'])
    report={'schema':'gold-quadrant-candidate-v1','map':map_name,'tileset':gold_set,
            'width_cells':width,'height_cells':height,
            'mask_row_bytes':(width+7)//8,'mask_size_bytes':len(blocked),
            'blocked_count':sum(c['role'] not in walkable_roles for c in cells),
            'walkable_count':sum(c['role'] in walkable_roles for c in cells),
            'collision_roles':dict(sorted(Counter(c['role'] for c in cells).items())),
            'ambiguous_visual_ids':{f'{i:02X}':sorted(roles)
                                    for i,roles in aliases_by_image.items() if len(roles)>1},
            'walkable_roles':sorted(walkable_roles), 'hops':hops,
            'unsafe_hop_candidates':unsafe_hops,
            'special_cells':[{'x':c['x'],'y':c['y'],'role':c['role']}
                             for c in cells if c['role'] in PORTAL_ROLES],
            'portal_edges': portal_approach_edges(cells, width, height),
            'runtime_ready':False,
            'notes':'Gold collision evidence only; engine entry exceptions and map connections require separate review'}
    return report,bytes(blocked)



def audit_reviewed_geometry(rpp: Path, gold: Path) -> list[str]:
    """Compare reviewed map data with Gold using the shared converter.

    The JSON is a *regression expectation*, not a gameplay permission table.
    Keep executable mask bytes under maps/, not inside tools/ or test staging.
    """
    import hashlib
    import json
    errors = []
    try:
        root = Path(rpp)
        catalog = json.loads((root / 'tools/johto_gold_geometry_contracts.json').read_text())
        if catalog.get('schema') != 'rpp-reviewed-gold-geometry-v1' or not catalog.get('maps'):
            raise ConversionError('invalid reviewed geometry catalog')
        seen = set()
        for spec in catalog['maps']:
            name, tileset = spec['gold_map'], spec['gold_tileset']
            if name in seen or spec.get('review_only') is not True:
                raise ConversionError(f'unsafe or repeated reviewed map: {name}')
            seen.add(name)
            path = Path(spec['rpp_blocked_mask'])
            if path.is_absolute() or '..' in path.parts or path.parts[0] != 'maps':
                raise ConversionError(f'unsafe runtime geometry path: {path}')
            report, expected = plan_gold_quadrant_collision(Path(gold), name, tileset)
            actual = (root/path).read_bytes()
            if (actual != expected or hashlib.sha256(actual).hexdigest() != spec['mask_sha256']):
                errors.append(f'{name}: Gold geometry mask or reviewed SHA differs')
            for field in ('width_cells','height_cells','blocked_count','walkable_count','collision_roles'):
                if report[field] != spec[field]:
                    errors.append(f'{name}: reviewed {field} differs from Gold')
            if sorted(report['ambiguous_visual_ids']) != spec['ambiguous_visual_ids']:
                errors.append(f'{name}: reviewed visual-role aliases changed')
            hops = [[h[k] for k in ('x','y','dx','dy')] for h in report['hops']]
            if report['unsafe_hop_candidates'] or hops != spec['hops']:
                errors.append(f'{name}: directional hops differ or are unsafe')
            blocked = {(c['x'],c['y'],c['role']) for c in report['special_cells']}
            stride = report['mask_row_bytes']
            for x,y,role in spec['required_blocked_special_cells']:
                if ((x,y,role) not in blocked or not (0 <= x < report['width_cells'] and
                        0 <= y < report['height_cells']) or
                        not (expected[y*stride+x//8] & (1 << (x % 8)))):
                    errors.append(f'{name}: reviewed blocked special cell differs: {x},{y},{role}')
    except (OSError, ValueError, KeyError, IndexError, TypeError) as exc:
        errors.append(f'reviewed Gold geometry incomplete: {exc}')
    return errors


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('rpp', 'gold', 'output'):
        ap.add_argument('--'+name, required=True, type=Path)
    args = ap.parse_args(argv)
    rpp, gold, out = safe_roots(args.rpp, args.gold, args.output)
    art, _ = build_mapping(rpp, gold)
    result = check(rpp, gold, art)
    dump(out, 'indoor_collision.json', result)
    print('collision:', result['status'], 'issues:', len(result['issues']))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
