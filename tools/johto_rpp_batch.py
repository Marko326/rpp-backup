#!/usr/bin/env python3
"""Offline, conservative Johto map staging for the existing RPP engine.

This does not register any new maps or modify ROM/project files. It builds
candidate .blk files and a SHARED Johto blockset, plus an auditable report.
Route29 and NewBarkTown remain byte-for-byte unchanged as .134 references.
"""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import re
from johto_gold_sources import gold_block_sources
from johto_rpp_tileset_contract import check_runtime_contract, matches_gold_prefix

# All directions are handled by RPP's *existing* ledge action, not a Gold
# movement interpreter. Composite HOP labels expand into ordinary RPP pairs.
DIRECTIONS = {
    'HOP_LEFT': ((-1, 0),), 'HOP_RIGHT': ((1, 0),),
    'HOP_DOWN': ((0, 1),),
    'HOP_DOWN_LEFT': ((0, 1), (-1, 0)),
    'HOP_DOWN_RIGHT': ((0, 1), (1, 0)),
}
# Tile $30 is unused in Gold Johto metatiles and also in .134's blockset;
# it is a pixel-identical copy of tile $06 for RIGHT ledges on other routes.
CLONES = {0x05: 0x20, 0x4c: 0x21, 0x06: 0x30}
PAIR = {(-1, 0, 0x05): (0x05, 0x3b),
        (-1, 0, 0x06): (0x06, 0x3b),
        (1, 0, 0x05): (0x05, 0x20),
        (1, 0, 0x06): (0x06, 0x30),
        (0, 1, 0x05): (0x05, 0x21),
        (0, 1, 0x06): (0x06, 0x21)}


def read_metadata(gold):
    reg = re.findall(r'^\s*map\s+(\w+),\s*TILESET_JOHTO,\s*(\w+),',
                     (gold / 'data/maps/maps.asm').read_text(), re.M)
    dims = {n.replace('_', '').lower(): (int(w), int(h)) for n, w, h in
            re.findall(r'^\s*map_const\s+(\w+),\s*(\d+),\s*(\d+)',
                       (gold / 'constants/map_constants.asm').read_text(), re.M)}
    raw = (gold / 'data/tilesets/johto_collision.asm').read_text()
    labels = []
    for line in raw.splitlines():
        mt = re.search(r'\btilecoll\s+([^;]+)\s*;', line)
        if mt:
            q = [k.strip() for k in mt.group(1).split(',')]
            if len(q) != 4:
                raise ValueError('bad collision quartet: ' + line)
            labels.append(q)
    if len(labels) != 128 or len(reg) < 20:
        raise ValueError('incomplete Gold Johto metadata')
    maps = []
    block_sources = gold_block_sources(gold)
    for name, environment in reg:
        if name.lower() not in dims:
            raise ValueError('missing map dimensions: ' + name)
        width, height = dims[name.lower()]
        if name not in block_sources:
            raise ValueError('Gold map blocks label not found: ' + name)
        src = gold / block_sources[name]
        data = src.read_bytes()
        if len(data) != width * height:
            raise ValueError(f'{name} expects {width*height} bytes but has {len(data)}')
        if any(i >= 128 for i in data):
            raise ValueError(name + ': Gold map references an out-of-range block')
        maps.append(dict(name=name, environment=environment, width=width,
                         height=height, source=data))
    return maps, labels


def tile_at(mapdata, w, x, y, blocks, labels):
    bid = mapdata[(y // 2) * w + x // 2]
    off = (y % 2) * 8 + (x % 2) * 2 + 4
    return labels[bid][(y % 2) * 2 + (x % 2)], blocks[bid * 16 + off]


def gold_events(gold, name):
    path = gold / 'maps' / (name + '.asm')
    txt = path.read_text() if path.exists() else ''
    cnt = {}
    for kind in ('warp_event', 'bg_event', 'object_event', 'coord_event',
                 'fruittree', 'itemball', 'trainer'):
        cnt[kind] = len(re.findall(r'^\s*' + kind + r'\b', txt, re.M))
    return cnt



def gold_event_records(gold, name, width, height):
    """Structured source coordinates only; never execute Gold event scripts."""
    path=gold/'maps'/(name+'.asm')
    if not path.exists():
        return {'warps': [], 'signs': [], 'objects': [], 'coord_events': [], 'warnings': ['missing_events_file']}
    source=path.read_text()
    fruit_handlers=dict(re.findall(r'(?m)^([A-Za-z0-9_]+):\s*\n\s*fruittree\s+([A-Za-z0-9_]+)',source))
    ball_handlers=dict(re.findall(r'(?m)^([A-Za-z0-9_]+):\s*\n\s*itemball\s+([A-Za-z0-9_]+)',source))
    result={'warps': [], 'signs': [], 'objects': [], 'coord_events': [], 'warnings': []}
    mapping={'warp_event':'warps','bg_event':'signs','object_event':'objects','coord_event':'coord_events'}
    for line in source.splitlines():
        m=re.match(r'^\s*(warp_event|bg_event|object_event|coord_event)\s+([^;]+)',line)
        if not m:continue
        parts=[x.strip() for x in m[2].split(',')]
        if len(parts)<3:continue
        try: x,y=int(parts[0],0),int(parts[1],0)
        except ValueError:
            result['warnings'].append('non_numeric_event_coordinates')
            continue
        typ=m[1]
        v={'x':x,'y':y,'fields':parts[2:]}
        if not (0 <= x < 2*width and 0 <= y < 2*height):
            result['warnings'].append(f'event_out_of_bounds:{typ}:{x},{y}')
        if typ=='object_event':
            v['gold_sprite']=parts[2]
            handler=parts[-2] if len(parts)>3 else ''
            v['handler']=handler
            v['kind']='fruit_tree' if handler in fruit_handlers else ('item_ball' if handler in ball_handlers else 'npc_or_script')
            if v['kind']=='fruit_tree':v['gold_fruit_id']=fruit_handlers[handler]
            if v['kind']=='item_ball':v['gold_item']=ball_handlers[handler]
        elif typ=='warp_event':
            v['destination']=parts[2]
            v['destination_warp']=parts[3] if len(parts)>3 else ''
        elif typ=='bg_event':
            v['gold_bg_type']=parts[2]
            v['handler']=parts[3] if len(parts)>3 else ''
        result[mapping[typ]].append(v)
    return result


def gold_connections(gold, name):
    src = (gold / 'data/maps/attributes.asm').read_text()
    start = re.search(r'^\s*map_attributes\s+' + re.escape(name) + r'\s*,[^\n]*', src, re.M)
    if not start:
        return []
    matches = []
    for line in src[start.end():].splitlines():
        c = re.match(r'\s*connection\s+(north|south|east|west),\s*(\w+),\s*(\w+),\s*([^;\s]+)', line)
        if c:
            matches.append(dict(direction=c[1], to=c[2], offset=c[4]))
        elif line.strip() and not line.lstrip().startswith(';'):
            break
    return matches


def audit_land_collisions(gold_layout, candidate_layout, width, height,
                          gold_blocks, candidate_blocks, labels, passable):
    """Audit Gold walkability against the ACTUAL staged .blk and metatiles.

    Gold supplies a 16x16 semantic label at each coordinate; the RPP runtime
    walks using an 8x8 tile whitelist. Never infer RPP collision from the
    original Gold layout after a ledge or other block variant is generated.
    """
    if (len(gold_layout) != width * height or
            len(candidate_layout) != width * height or
            len(gold_blocks) < 128 * 16 or
            len(candidate_blocks) % 16 or len(labels) < 128 or
            any(b >= len(candidate_blocks) // 16 for b in candidate_layout)):
        raise ValueError('invalid staged geometry or blockset in collision audit')
    dangerous = []
    ambiguous_floor = []
    must_walk = {'LADDER', 'TALL_GRASS', 'WARP_CARPET_LEFT',
                 'WARP_CARPET_RIGHT', 'WARP_CARPET_DOWN'}
    for y in range(2 * height):
        for x in range(2 * width):
            quadrant = (y % 2) * 2 + x % 2
            gold_bid = gold_layout[(y // 2) * width + x // 2]
            label = labels[gold_bid][quadrant]
            bid = candidate_layout[(y // 2) * width + x // 2]
            offset = (y % 2) * 8 + (x % 2) * 2 + 4
            rpp_tile = candidate_blocks[bid * 16 + offset]
            if label in must_walk and rpp_tile not in passable:
                dangerous.append((x, y, label, rpp_tile))
            elif label == 'FLOOR' and rpp_tile not in passable:
                ambiguous_floor.append((x, y, rpp_tile))
    issues = []
    if dangerous:
        issues.append({'code': 'missing_walkable_collision_mapping',
                       'count': len(dangerous),
                       'examples': [{'at': [x, y], 'label': label, 'tile': f'{tile:02X}'}
                                    for x, y, label, tile in dangerous[:12]]})
    if ambiguous_floor:
        # Original FLOOR may include cliffs/roofs: review locations, do not
        # globally make an ambiguous shared tile passable.
        issues.append({'code': 'floor_collision_requires_spatial_review',
                       'count': len(ambiguous_floor),
                       'examples': [{'at': [x, y], 'tile': f'{tile:02X}'}
                                    for x, y, tile in ambiguous_floor[:8]]})
    return issues



def audit_entrance_semantics(gold_layout, width, height, labels, gold_warp_count):
    """Require manual Warp/engine review for Gold DOOR/CAVE cells.

    A Gold 16x16 collision label is not an RPP 8x8 door-tile/warp rule.
    Do not make shared wall tiles globally passable or synthesize warps to
    missing indoor destinations. Gold warp count is context, not proof that
    a particular visual entrance has a valid destination.
    """
    locations = []
    for y in range(height * 2):
        for x in range(width * 2):
            pos = (y // 2) * width + x // 2
            label = labels[gold_layout[pos]][(y % 2) * 2 + x % 2]
            if label in ('DOOR', 'CAVE'):
                locations.append((x, y, label))
    if not locations:
        return []
    return [{'code': 'entrance_requires_warp_and_engine_review',
             'count': len(locations),
             'by_label': {label: sum(t == label for _, _, t in locations)
                          for label in ('DOOR', 'CAVE') if any(t == label for _, _, t in locations)},
             'gold_warp_count': gold_warp_count,
             'examples': [{'at': [x, y], 'label': label}
                          for x, y, label in locations[:10]]}]

def convert_one(name, data, w, h, original, labels, shared, intern):
    # Stage locally; do not commit variants if a map is blocked.
    additions = {}
    issues = []
    triggers = []
    hop_labels = Counter()
    collisions = Counter()
    for y in range(2*h):
        for x in range(2*w):
            name_label, src = tile_at(data, w, x, y, original, labels)
            collisions[name_label] += 1
            if not name_label.startswith('HOP_'):
                continue
            hop_labels[name_label] += 1
            if name_label not in DIRECTIONS:
                issues.append(dict(code='unsupported_gold_hop', location=[x,y], label=name_label))
                continue
            for dx, dy in DIRECTIONS[name_label]:
                ax, ay = x+dx, y+dy
                bx, by = x+2*dx, y+2*dy
                if not (0 <= ax < 2*w and 0 <= ay < 2*h and
                        0 <= bx < 2*w and 0 <= by < 2*h):
                    issues.append(dict(code='off_map_ledge', location=[x,y], direction=[dx,dy]))
                    continue
                front_label, front = tile_at(data, w, ax, ay, original, labels)
                landing_label, landing = tile_at(data, w, bx, by, original, labels)
                key = (dx, dy, src)
                expected_front = {(-1,0):0x3b, (1,0):src, (0,1):0x4c}[dx,dy]
                if key not in PAIR or front != expected_front:
                    issues.append(dict(code='unknown_graphics_pair', location=[x,y],
                                       direction=[dx,dy], source_tile=src,
                                       front_tile=front))
                    continue
                if landing_label not in ('FLOOR','TALL_GRASS'):
                    issues.append(dict(code='landing_needs_review', location=[x,y],
                                       direction=[dx,dy], landing_label=landing_label))
                _, target = PAIR[key]
                if front != target:
                    block_pos = (ax//2,ay//2)
                    offset = (ay%2)*8+(ax%2)*2+4
                    changes = additions.setdefault(block_pos,{})
                    if offset in changes and changes[offset] != target:
                        issues.append(dict(code='conflicting_barriers', location=[ax,ay]))
                    changes[offset] = target
                triggers.append((x,y,dx,dy,src,target))

    blockers = {'unsupported_gold_hop','off_map_ledge','unknown_graphics_pair','conflicting_barriers'}
    if any(e['code'] in blockers for e in issues):
        return None, None, dict(hop_labels), dict(collisions), issues, triggers

    # shared = original 128 Gold blocks + the .134 Route29 variants and previously staged variants.
    local = bytearray(shared)
    local_intern = dict(intern)
    out = bytearray(data)
    for (bx, by), edits in sorted(additions.items()):
        pos = by*w+bx
        bid = out[pos]
        # Start with the installed RPP equivalent, not untouched Gold bytes:
        # block $06 must keep its walkable $5B LADDER clone in variants.
        buf = bytearray(shared[bid*16:bid*16+16])
        for off, tile in edits.items():
            buf[off] = tile
        sig = bytes(buf)
        if sig not in local_intern:
            new_id = len(local)//16
            if new_id >= 256:
                issues.append(dict(code='blockset_overflow', needed_index=new_id))
                return None,None,dict(hop_labels),dict(collisions),issues,triggers
            local_intern[sig] = new_id
            local.extend(sig)
        out[pos] = local_intern[sig]
    # Catch accidental native ledges at non-Gold starting cells.
    valid = {(x,y,dx,dy) for x,y,dx,dy,_,_ in triggers}
    unexpected = []
    for y in range(2*h):
        for x in range(2*w):
            def final_tile(xx, yy):
                bid = out[yy//2*w+xx//2]
                return local[bid*16+(yy%2)*8+(xx%2)*2+4]
            src = final_tile(x,y)
            for (dx,dy,src_id),(_,front_id) in PAIR.items():
                if src != src_id or not(0<=x+dx<2*w and 0<=y+dy<2*h):
                    continue
                if final_tile(x+dx,y+dy)==front_id and (x,y,dx,dy) not in valid:
                    unexpected.append([x,y,dx,dy])
    if unexpected:
        issues.append(dict(code='unexpected_ledge_trigger', count=len(unexpected),
                           examples=unexpected[:12]))
        return None,None,dict(hop_labels),dict(collisions),issues,triggers
    # Visual invariance: changed IDs must refer to identical graphics tiles.
    for (bx,by), edits in additions.items():
        for off, tile in edits.items():
            source = original[data[by*w+bx]*16+off]
            if (source,tile) not in ((0x05,0x20),(0x4c,0x21),(0x06,0x30)):
                raise AssertionError('visual invariance failed')
    return bytes(out),(local,local_intern),dict(hop_labels),dict(collisions),issues,triggers


def make_gfx_preview(project, output):
    from PIL import Image
    png = project / 'gfx/tilesets/johto.png'
    img=Image.open(png)
    if img.size != (128,48):
        raise ValueError('unexpected Johto PNG size')
    # .134 already installed the clones $20/$21; add a clone of $06 in $30.
    width=img.width//8
    source=0x06;target=0x30
    img.paste(img.crop(((source%width)*8,(source//width)*8,(source%width)*8+8,(source//width)*8+8)),((target%width)*8,(target//width)*8))
    img.save(output / 'johto_tileset_candidate.png')
    pals=(project/'color/tilesets/johto.asm').read_text()
    lines=pals.splitlines(keepends=True)
    rows=[]
    for i,line in enumerate(lines):
        m=re.match(r'(\s*tilepal\s+0,\s*)(.*?)(\s*(?:;.*)?\n?)$',line)
        if m:
            colors=[x.strip() for x in m.group(2).split(',')]
            if len(colors)!=8:raise ValueError('palette row not eight items')
            rows.append((i,m[1],colors,m[3]))
    if len(rows)!=12:raise ValueError('unexpected palette size')
    pal=rows[0][2][6]
    rows[0x30//8][2][0x30%8]=pal
    for pos,pre,cs,suffix in rows:
        lines[pos]=pre+', '.join(cs)+suffix
    (output/'johto_palette_candidate.asm').write_text(''.join(lines))
    (output/'johto_ledge_pairs_candidate.asm').write_text('''; PREVIEW ONLY. Do not INCLUDE without registering new maps and validating collisions.\n; Uses existing RPP HandleLedges action. No simulated joypad changes.\nJohtoAllMapLedgeTiles:\n db SPRITE_FACING_LEFT,  $05,$3B,D_LEFT\n db SPRITE_FACING_LEFT,  $06,$3B,D_LEFT\n db SPRITE_FACING_RIGHT, $05,$20,D_RIGHT\n db SPRITE_FACING_RIGHT, $06,$30,D_RIGHT\n db SPRITE_FACING_DOWN,  $05,$21,D_DOWN\n db SPRITE_FACING_DOWN,  $06,$21,D_DOWN\n db $FF\n''')


def inventory_all_gold_maps(gold, project, output, staged_records):
    """Audit every Gold map, not only the 29 TILESET_JOHTO candidates.

    Identical metatile bytes establish a *possible* resource reuse, not
    identical artwork, collision, palettes, scripts, or safe game imports.
    Only the existing Johto prefix is already established by the .134 project.
    """
    map_file = gold / 'data/maps/maps.asm'
    const_file = gold / 'constants/map_constants.asm'
    definitions = re.findall(
        r'^\s*map\s+(\w+),\s*(TILESET_\w+),\s*(\w+)\s*,',
        map_file.read_text(), re.M)
    dimensions = {
        name.replace('_', '').lower(): (int(w), int(h))
        for name, w, h in re.findall(
            r'^\s*map_const\s+(\w+),\s*(\d+),\s*(\d+)',
            const_file.read_text(), re.M)
    }
    if not definitions:
        raise ValueError('No Gold map registrations found for full inventory')
    seen = set()
    block_sources = gold_block_sources(gold)
    registered = {name for name, _, _ in definitions}
    missing_labels = registered - block_sources.keys()
    if missing_labels:
        raise ValueError('Missing Gold blocks labels: ' + ', '.join(sorted(missing_labels)))
    shared_users = {}
    for name in registered:
        shared_users.setdefault(block_sources[name], []).append(name)
    for names in shared_users.values():
        names.sort()
    staged = {entry['name']: entry for entry in staged_records}
    tileset_checks = {}
    all_events = {}
    entries = []
    compatible_candidates = output / 'unverified_shared_metatiles_maps'
    compatible_candidates.mkdir(exist_ok=True)
    for name, tileset, environment in definitions:
        if name in seen:
            raise ValueError('duplicate Gold map registration: ' + name)
        seen.add(name)
        key = tileset.removeprefix('TILESET_').lower()
        if tileset not in tileset_checks:
            metatiles = gold / 'data/tilesets' / (key + '_metatiles.bin')
            rpp = project / 'gfx/blocksets' / (key + '.bst')
            source = metatiles.read_bytes() if metatiles.exists() else b''
            target = rpp.read_bytes() if rpp.exists() else b''
            # Some names can coincide by chance; neither geometry nor sprites
            # certify the graphics/palettes or Gen-1 collision semantics.
            exact_prefix = bool(source and target and
                                len(source) % 16 == 0 and
                                len(target) % 16 == 0 and
                                (matches_gold_prefix(source, target)
                                 if tileset == 'TILESET_JOHTO'
                                 else target.startswith(source)))
            tileset_checks[tileset] = {
                'gold_metatiles': str(metatiles.relative_to(gold)),
                'gold_metatiles_present': bool(source),
                'rpp_blockset': str(rpp.relative_to(project)),
                'rpp_blockset_present': bool(target),
                'rpp_tileset_png_present': (project / 'gfx/tilesets' / (key + '.png')).is_file(),
                'rpp_palette_present': (project / 'color/tilesets' / (key + '.asm')).is_file(),
                'metatile_prefix_identical': exact_prefix,
                'artwork_and_collision_verified': tileset == 'TILESET_JOHTO' and exact_prefix,
                'requires_specialized_adapter': tileset != 'TILESET_JOHTO' or not exact_prefix,
                'map_count': 0,
                'staged_unverified_map_count': 0,
            }
        match = tileset_checks[tileset]
        match['map_count'] += 1
        dims = dimensions.get(name.replace('_', '').lower())
        layout_name = block_sources[name]
        layout = gold / layout_name
        raw = layout.read_bytes() if layout.exists() else None
        issues = []
        if dims is None:
            issues.append('missing_dimensions')
        elif raw is None:
            issues.append('missing_layout')
        elif len(raw) != dims[0] * dims[1]:
            issues.append('invalid_layout_size')
        if not match['artwork_and_collision_verified']:
            issues.append('tileset_or_collision_not_verified')
        stage_path = None
        if name in staged:
            status = staged[name]['status']
            if status == 'blocked':
                issues.append('johto_terrain_conversion_blocked')
        elif (dims is not None and raw is not None and
              len(raw) == dims[0] * dims[1] and
              match['metatile_prefix_identical'] and
              max(raw, default=0) < (
                  len((gold / match['gold_metatiles']).read_bytes()) // 16)):
            # Only the layout bytes are safe to copy here. Artwork and engine
            # collisions are still UNVERIFIED; do not place these in RPP/maps.
            stage_path = 'unverified_shared_metatiles_maps/' + name + '.blk'
            (output / stage_path).write_bytes(raw)
            match['staged_unverified_map_count'] += 1
            status = 'unverified_shared_metatiles_candidate'
        else:
            status = ('requires_adapter' if
                      issues == ['tileset_or_collision_not_verified'] else
                      'source_review_required')
            if (match['metatile_prefix_identical'] and raw is not None and
                not issues[:1] == ['invalid_layout_size']):
                issues.append('metatile_index_out_of_range_or_invalid_layout')
        counts = gold_events(gold, name)
        if dims is not None:
            all_events[name] = gold_event_records(gold, name, *dims)
        entries.append({
            'name': name,
            'tileset': tileset,
            'environment': environment,
            'width': dims[0] if dims else None,
            'height': dims[1] if dims else None,
            'block_count': len(raw) if raw is not None else None,
            'source_sha256': hashlib.sha256(raw).hexdigest() if raw is not None else None,
            'source_layout': layout_name,
            'shared_layout_with': [other for other in shared_users[layout_name] if other != name],
            'existing_rpp_legacy_alias': {'NewBarkTown': 'NEW_BARK_TOWN',
                                          'Route29': 'JOHTO_ROUTE_29'}.get(name),
            'connections': gold_connections(gold, name),
            'terrain_status': status,
            'unverified_layout_candidate': stage_path,
            'events': counts,
            'issues': issues,
        })
    # Deterministic source inventory: this is a discovery artifact, not a ROM
    # or a claim that non-Johto scenery can be imported without conversion.
    result = {
        'schema': 'rpp-gold-full-map-inventory-v1',
        'mode': 'AUDIT_ONLY',
        'registered_gold_maps': len(entries),
        'staged_johto_maps': len(staged),
        'tilesets': dict(sorted(tileset_checks.items())),
        'maps': entries,
    }
    (output / 'full_gold_inventory.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (output / 'full_gold_events_locations.json').write_text(
        json.dumps(all_events, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (output / 'full_gold_map_index.csv').open(
            'w', newline='', encoding='utf-8-sig') as fh:
        fields = ['name', 'tileset', 'environment', 'width', 'height',
                  'source_layout', 'shared_layout_with', 'existing_rpp_legacy_alias',
                  'terrain_status', 'block_count', 'issues']
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for entry in entries:
            writer.writerow({**{field: (','.join(entry[field])
                                        if isinstance(entry[field], list) else entry[field])
                                  for field in fields[:-1]},
                             'issues': ','.join(entry['issues'])})
    with (output / 'shared_blocks_index.csv').open(
            'w', newline='', encoding='utf-8-sig') as fh:
        writer = csv.writer(fh)
        writer.writerow(['source_layout', 'registered_map_count', 'registered_maps'])
        for source_name, users in sorted(shared_users.items()):
            writer.writerow([source_name, len(users), ','.join(users)])
    return result


def make_import_plan(output, records):
    """Stable all-at-once staging order; no unsupported legacy IDs assigned."""
    legacy = {'NewBarkTown': ('NEW_BARK_TOWN', 0),
              'Route29': ('JOHTO_ROUTE_29', 1)}
    name_set = {entry['name'] for entry in records}
    if not set(legacy).issubset(name_set):
        raise ValueError('RPP reference maps missing from import plan')
    order = ['NewBarkTown', 'Route29'] + sorted(name_set - set(legacy))
    lookup = {record['name']: record for record in records}
    result = []
    for index, name in enumerate(order):
        record = lookup[name]
        connections = []
        for connection in record['connections']:
            target = connection['to']
            connections.append({**connection,
                                'destination_in_johto_batch': target in name_set,
                                'geometry_requires_rpp_macro_review': True})
        alias = legacy.get(name)
        result.append({
            'name': name,
            'proposed_johto_local_id': index,
            'existing_rpp_legacy_alias': alias[0] if alias else None,
            'requires_native_region_map_support': alias is None,
            'terrain_status': record['status'],
            'terrain_file': ('candidate_maps/' + name + '.blk'
                             if record['status'] != 'blocked' else None),
            'dimensions': [record['width'], record['height']],
            'connections': connections,
            'gold_event_counts': record['events'],
            'rpp_events_compiled': False,
            'game_registered': alias is not None,
        })
    plan = {
        'schema': 'rpp-johto-import-plan-v1',
        'mode': 'NON_EXECUTABLE_PLAN',
        'required_first': [
            'Native region/local map identity in all connection and warp paths',
            'Region-safe save/load, Fly/Teleport/blackout and indoor return',
            'Per-map header, object, sprite and event script compatibility',
            'Bank capacity and same-bank connection data constraints',
            'Verified ledge palette, collisions and sprite initialization',
        ],
        'warning': 'IDs are proposals, not aliases or active map registrations.',
        'maps': result,
    }
    (output / 'import_plan.json').write_text(
        json.dumps(plan, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return plan

def batch(gold, project, output):
    output.mkdir(parents=True, exist_ok=True)
    maps,labels=read_metadata(gold)
    source=(gold/'data/tilesets/johto_metatiles.bin').read_bytes()
    existing=(project/'gfx/blocksets/johto.bst').read_bytes()
    # Fail closed if a previous hand-fix changed Gold geometry, shared art,
    # colors or collision semantics. Preserve the already-playtested LADDER.
    check_runtime_contract(source, project)
    if len(existing)//16 < 133:
        raise ValueError('Expected .134 Route29 base with 5 extra block variants')
    for t in CLONES.values():
        if t in source:
            raise ValueError(f'reserved tile index {t:02X} used in Gold blockset')
    # Guard existing reference: no output may mutate 29 (nor the user's game).
    golden29=(project/'maps/JohtoRoute29.blk').read_bytes()
    golden_town=(project/'maps/NewBarkTown.blk').read_bytes()
    if len(golden29)!=270 or len(golden_town)!=90:
        raise ValueError('Route29 or NewBarkTown .134 reference missing')
    # Regeneration must never leave stale .blk candidates behind when a map
    # changes from candidate to blocked. Delete only files owned by this tool.
    for folder_name in ('candidate_maps', 'original_maps',
                        'unverified_shared_metatiles_maps'):
        folder = output / folder_name
        if folder.is_symlink():
            raise ValueError('refusing symlinked staging directory: ' + str(folder))
        if folder.is_dir():
            for candidate in folder.glob('*.blk'):
                if candidate.is_symlink():
                    raise ValueError('refusing symlinked candidate: ' + str(candidate))
                candidate.unlink()
    pairs={(existing[i:i+16]):i//16 for i in range(0,len(existing),16)}
    shared=bytearray(existing)
    passable = set((project/'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
    records=[]
    semantic_by_map={}
    events_catalog={}
    candidate=output/'candidate_maps'
    candidate.mkdir(exist_ok=True)
    raw=output/'original_maps'
    raw.mkdir(exist_ok=True)
    # Sort with Route29 first to make comparison obvious.
    order=sorted(maps,key=lambda x:(x['name']!='Route29',x['name']))
    supported_names={k['name'] for k in maps}
    for entry in order:
        n,w,h,data=entry['name'],entry['width'],entry['height'],entry['source']
        (raw/f'{n}.blk').write_bytes(data)
        co=gold_connections(gold,n)
        ev=gold_events(gold,n)
        events_catalog[n]=gold_event_records(gold,n,w,h)
        if n in ('Route29','NewBarkTown'):
            stage = None
            out=golden29 if n=='Route29' else golden_town
            hops={'note':'Existing RPP modified map is preserved verbatim'}
            collision={}
            issues=[]
            hop_count=39 if n=='Route29' else 0
            status='reference_preserved'
        else:
            out, stage, hops, collision, issues, triggers=convert_one(n,data,w,h,source,labels,shared,pairs)
            hop_count=len(triggers)
            status = ('blocked' if out is None else
                      'review_required' if issues else 'candidate')
        # Use the staged variant set, not the pre-conversion blockset.
        # Already integrated references keep their own game-tested layout.
        staged_layout = out if out is not None else data
        staged_blocks = stage[0] if out is not None and stage is not None else shared
        semantic_issues = audit_land_collisions(
            data, staged_layout, w, h, source, staged_blocks, labels, passable)
        issues.extend(semantic_issues)
        # Gold DOOR/CAVE labels are not equivalent to RPP door tile IDs.
        # Report their presence even when the graphics and ordinary collision
        # look correct; entering requires a real registered destination Warp.
        if n not in ('Route29', 'NewBarkTown') and out is not None:
            entrance_issues = audit_entrance_semantics(
                data, w, h, labels, len(events_catalog[n]['warps']))
            issues.extend(entrance_issues)
            if entrance_issues and status == 'candidate':
                status = 'review_required'
        if any(item['code'] == 'missing_walkable_collision_mapping' for item in semantic_issues):
            # A candidate must not silently omit a Gold walkable terrain type.
            status = 'blocked'
            out = None
        elif semantic_issues and status == 'candidate':
            status = 'review_required'
        if entry['environment'] not in ('TOWN','ROUTE'):
            issues.append({'code':'non_outdoor_environment','environment':entry['environment']})
            if status=='candidate':status='review_required'
        if out is not None:
            semantic_by_map[n] = semantic_issues
            if n not in ('Route29','NewBarkTown'):
                # A blocked conversion must never poison the shared blockset.
                shared,pairs=stage
            (candidate/f'{n}.blk').write_bytes(out)
        records.append(dict(name=n,environment=entry['environment'],width=w,height=h,
                            source_sha256=hashlib.sha256(data).hexdigest(),status=status,
                            block_bytes=w*h,hop_directions=hop_count,hop_types=hops,
                            collisions=collision,events=ev,connections=co,
                            cross_tileset_connections=[q['to'] for q in co if q['to'] not in supported_names],
                            findings=issues))
    if (candidate/'Route29.blk').read_bytes()!=golden29 or (candidate/'NewBarkTown.blk').read_bytes()!=golden_town:
        raise AssertionError('existing RPP map regression')
    (output/'johto_blockset_candidate.bst').write_bytes(shared)
    # Fail closed on the actual exported artifacts, including variants from
    # later maps. A conversion must not pass solely on its intermediate state.
    exported_blocks = (output/'johto_blockset_candidate.bst').read_bytes()
    for entry in order:
        n, w, h, data = (entry[k] for k in ('name', 'width', 'height', 'source'))
        path = candidate / (n + '.blk')
        if not path.exists():
            continue
        exported = audit_land_collisions(
            data, path.read_bytes(), w, h, source, exported_blocks, labels, passable)
        if exported != semantic_by_map[n]:
            raise ValueError(f'{n}: exported candidate collision audit drift')
    make_gfx_preview(project,output)
    # Original Gold -> staged visual equivalence, factoring in the three cloned 8x8 graphics slots.
    clone_reverse={v:k for k,v in CLONES.items()}
    clone_reverse[0x5b]=0x07
    for e in records:
        name=e['name']; path=candidate/(name+'.blk')
        if not path.exists() or name in ('Route29','NewBarkTown'):continue
        dat=(raw/(name+'.blk')).read_bytes();gen=path.read_bytes()
        for i in range(len(dat)):
            a=source[dat[i]*16:dat[i]*16+16]
            b=shared[gen[i]*16:gen[i]*16+16]
            if bytes(clone_reverse.get(k,k) for k in b)!=a:
                raise AssertionError(f'{name} visual tile identity mismatch at block {i}')
    for e in records:
        # Mark non-registered maps explicitly to avoid misleading claims.
        e['game_registered']=e['name'] in ('Route29','NewBarkTown')
    j={'schema':'rpp-johto-batch-preview-v1', 'mode':'OFFLINE_PREVIEW_ONLY',
       'note':'Staging assets are NOT wired into the ROM; candidate status does not mean gameplay tested.',
       'project_reference':'MAP-5.62.134',
       'shared_block_count':len(shared)//16,
       'maps':records}
    (output/'manifest.json').write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n')
    (output/'events_locations.json').write_text(json.dumps(events_catalog,ensure_ascii=False,indent=2)+'\n')
    full_inventory = inventory_all_gold_maps(gold, project, output, records)
    import_plan = make_import_plan(output, records)
    fields=['name','environment','width','height','status','hop_directions','warp_event',
            'object_event','bg_event','fruit_tree','map_connections','issues']
    with (output/'map_index.csv').open('w',newline='',encoding='utf-8-sig') as fh:
        wr=csv.DictWriter(fh,fieldnames=fields);wr.writeheader()
        for e in records:
            v={k:e.get(k) for k in fields}
            v.update({k:e['events'][k] for k in ('warp_event','object_event','bg_event')})
            v['fruit_tree']=e['events']['fruittree']
            v['map_connections']=len(e['connections']);v['issues']=','.join(i['code'] for i in e['findings'])
            wr.writerow(v)
    tally=Counter(e['status'] for e in records)
    issue_counts=Counter(i['code'] for e in records for i in e['findings'])
    total_hops=sum(e['hop_directions'] for e in records)
    overview=['# 城都室外地图批量预转换（仅离线候选）','',
              '生成基线：MAP-5.62.134。既有 RPP 引擎保持不变；无自动注册、无 ROM 修改。','',
              f'- 扫描 {len(records)} 张 Gold `TILESET_JOHTO` 地图，{total_hops} 条方向跳跃关系。',
              f'- 状态统计：'+', '.join(f'{k} {v}' for k,v in sorted(tally.items()))+'。',
              f'- 共享区块集：128 个原版区块 → {len(shared)//16} 个候选区块（含 .134 的 5 个变体）。',
              '- 已验证的 Route29 与保留渡轮改动的 NewBarkTown 原样保留，未覆盖实际工程。',
              '- `candidate_maps/` 为地形候选，不可直接覆盖进项目使用。',
              '- `original_maps/` 是原始 Gold 布局，用于比较。',
              f'- 全 Gold 地图库盘点：{full_inventory["registered_gold_maps"]} 张地图，{len(full_inventory["tilesets"])} 组图块；仅 29 张 Johto 户外进入此轮地形转换。',
              '- `full_gold_inventory.json` / `full_gold_map_index.csv` 汇总全部原版地图及复用条件；字节一致只代表候选，不能推定贴图/碰撞/事件兼容。',
              '- `full_gold_events_locations.json` 提取全部地图的事件位置，供后续室内和其他图块组统一生成。',
              '- `unverified_shared_metatiles_maps/` 只暂存其他图块集字节前缀匹配的 .blk；未验证美术与碰撞，不能直接导入 ROM。',
              '- `import_plan.json` 提议全部城都户外地图的稳定本地 ID 与连接依赖；目前不是可用地图编号，不可直接接入。',
              '- `johto_ledge_pairs_candidate.asm` 仅提供兼容表草案；RPP 原跳崖动作不变。',
              '- 已批量提取 NPC / 果树 / 道具球 / Warp / 路牌坐标到 `events_locations.json`，但不自动生成游戏脚本、不自动加入 ROM。',
              '- `review_required` 包含金银原版多级跳崖连续格，需要实机前复查落点；`blocked` 无候选。',
              '- `floor_collision_requires_spatial_review` 为原版 FLOOR / RPP 共用墙面瓦片差异，须按坐标检查，不会自动放开整类墙块。',
              '- `missing_walkable_collision_mapping` 按最终候选 .blk 与合并图块集检查，未适配通行区块会阻止生成。',
              '', '## 分类警告', '']
    overview += [f'- {k}: {v}' for k,v in issue_counts.most_common()] or ['- 暂无']
    overview+=['','## 下一步接入时必须检查','','- 新地图的地区＋地图编号 / map header Bank / 存档 / 跨图连接。',
               '- RPP Johto 跳崖查表目前只在 29 号道路启用；接入新地图必须先更新启用范围和 $06 配对。',
               '- 必须核对共享 blockset 容量、tile $30 图形与调色板、碰撞白名单。',
               '- 原版 Gold 场景事件、NPC 贴图、果树结果只作提取，不能直接代替 RPP 脚本。',
               '- 不更改已实测生效的 Continue 修复和草地遮挡。',
               '']
    (output/'REPORT_zh.md').write_text('\n'.join(overview),encoding='utf-8')
    return {'event_locations':sum(len(v[k]) for v in events_catalog.values() for k in ('warps','signs','objects','coord_events')),
            'fruit_tree_locations':sum(sum(o['kind']=='fruit_tree' for o in v['objects']) for v in events_catalog.values()),
            'maps':len(records),'hops':total_hops,'statuses':dict(tally),
            'issues':dict(issue_counts),'blocks':len(shared)//16,
            'staged':sum((candidate/(e['name']+'.blk')).exists() for e in records),
            'full_gold_map_count': full_inventory['registered_gold_maps'],
            'gold_tileset_count': len(full_inventory['tilesets']),
            'proposed_local_ids': len(import_plan['maps'])}


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gold-root',required=True,type=Path)
    ap.add_argument('--project',default='.',type=Path)
    ap.add_argument('--output',required=True,type=Path)
    args=ap.parse_args()
    print(json.dumps(batch(args.gold_root,args.project,args.output),ensure_ascii=False,indent=2))


if __name__=='__main__':
    main()
