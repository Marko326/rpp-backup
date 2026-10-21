#!/usr/bin/env python3
"""Read-only inventory for every *registered* RPP ledge implementation.

Cross-checks every registered Johto HOP position+direction against independent
Gold collision roles and validates the two-cell landing. Kanto is inventoried
by tile pairs only. A source audit is NOT a ROM or real-device test.
"""
from collections import Counter
import json
import os
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
FACING = {'SPRITE_FACING_DOWN': (0, 1), 'SPRITE_FACING_LEFT': (-1, 0),
          'SPRITE_FACING_RIGHT': (1, 0), 'SPRITE_FACING_UP': (0, -1)}
NATIVE = {
    'JohtoRoute29': (30, 'johto', 'JohtoRoute29LedgeTiles'),
    'JohtoRoute30': (10, 'johto', 'JohtoRoute29LedgeTiles'),
    'JohtoRoute31': (20, 'johto', 'JohtoRoute31LedgeTiles'),
    'JohtoRoute32': (10, 'johto', 'JohtoRoute31LedgeTiles'),
    'JohtoVioletCity': (20, 'johto', 'JohtoRoute29LedgeTiles'),
    'JohtoIlexForest': (15, 'johto_ilex_forest', 'JohtoIlexForestLedgeTiles'),
}
FOREST_ACTIONS = {
    (22, 2, 0, 1), (24, 2, 0, 1), (25, 2, 0, 1),
    (15, 14, -1, 0), (15, 15, -1, 0),
    (23, 22, 0, 1), (23, 22, -1, 0),
    (24, 22, 0, 1), (26, 22, 0, 1), (26, 22, 1, 0),
}


def pairs(src, label):
    match = re.search(r'(?m)^' + re.escape(label) + r':\s*\n', src)
    if not match:
        raise AssertionError('missing ledge table: ' + label)
    section = src[match.end():].split('\n\n', 1)[0]
    result = []
    for line in section.splitlines():
        m = re.search(r'\bdb\s+(SPRITE_FACING_\w+),\s*(\$[\da-fA-F]+),\s*'
                      r'(\$[\da-fA-F]+),\s*(D_\w+)', line)
        if m:
            result.append((FACING[m[1]], int(m[2][1:], 16), int(m[3][1:], 16), m[4]))
    if not result:
        raise AssertionError('no ledge tile pairs in ' + label)
    return result


def registration_errors(src):
    """Fail closed if a future ledge route/table bypasses the audited registry."""
    legacy = src.split('\n.johto\n', 1)[1].split('\n.checkPairs\n', 1)[0]
    actual = set(re.findall(r'\bcp\s+(JOHTO_(?:ROUTE_\d+|VIOLET_CITY))\b', legacy))
    expected = {'JOHTO_ROUTE_29', 'JOHTO_ROUTE_30', 'JOHTO_ROUTE_31',
                'JOHTO_ROUTE_32', 'JOHTO_VIOLET_CITY'}
    tables = set(re.findall(r'(?m)^([A-Za-z0-9_]+LedgeTiles):', src))
    expected_tables = {'JohtoRoute29LedgeTiles', 'JohtoRoute31LedgeTiles',
                       'JohtoIlexForestLedgeTiles'}
    coord = set(re.findall(r'(?m)^\.(\w+Hops)\s*$', src))
    expected_coord = {'route33Hops', 'azaleaHops', 'ruinsHops', 'route37Hops', 'ecruteakHops', 'route38Hops'}
    errors = []
    for label, actual_set, expected_set in (
            ('native router', actual, expected),
            ('native table', tables, expected_tables),
            ('coordinate HOP router', coord, expected_coord)):
        if actual_set != expected_set:
            errors.append(f'{label} registration changed: got={sorted(actual_set)}, expected={sorted(expected_set)}; update audit + geometry contract')
    # A perfect coordinate inventory is worthless if the dispatcher routes
    # the map to the wrong table. Lock the executable entry chain as well.
    contract = (
        'cp JOHTO_MODERN\n\tjp z, .route33',
        'cp JOHTO_ILEX_FOREST\n\tjp z, .ilexForest',
        'cp JOHTO_ROUTE_31\n\tjr z, .route31And32',
        'cp JOHTO_ROUTE_32\n\tret nz',
        'cp REGION_NATIVE_MAP_SLOT\n\tret nz',
        'cp MAP_REGION_JOHTO\n\tret nz',
        'cp JOHTO_ROUTE_33_LOCAL_ID\n\tjr z, .route33HopTable',
        'cp JOHTO_AZALEA_TOWN_LOCAL_ID\n\tret nz',
        'ld hl, .azaleaHops\n\tjr .modernHopLookup',
        'ld hl, .route33Hops',
        'jp .foundMatch',
        'cp JOHTO_RUINS_OF_ALPH_LOCAL_ID\n\tret nz',
        'ld hl, .ruinsHops\n\tjp .modernHopLookup',
        'cp JOHTO_ROUTE_37_LOCAL_ID\n\tjr z, .route37HopTable',
        'ld hl, .route37Hops\n\tjp .modernHopLookup',
        'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n\tjr z, .ecruteakHopTable',
        'ld hl, .ecruteakHops\n\tjp .modernHopLookup',
        'cp JOHTO_ROUTE_38_LOCAL_ID\n\tjr z, .route38HopTable',
        'ld hl, .route38Hops\n\tjp .modernHopLookup',
    )
    for snippet in contract:
        if snippet not in src:
            errors.append(f'ledge runtime dispatcher changed: missing {snippet!r}')
    return errors


def decode(root, map_name, width, tileset, rules):
    blockmap = (root / f'maps/{map_name}.blk').read_bytes()
    blocks = (root / f'gfx/blocksets/{tileset}.bst').read_bytes()
    if len(blockmap) % width or len(blocks) % 16:
        raise AssertionError(f'invalid dimensions: {map_name}')
    height = len(blockmap) // width

    def cell(x, y):
        if not 0 <= x < 2 * width or not 0 <= y < 2 * height:
            return None
        block = blockmap[(y // 2) * width + x // 2]
        offset = block * 16 + (y % 2) * 8 + (x % 2) * 2 + 4
        if offset >= len(blocks):
            raise AssertionError(f'{map_name}: block index out of range')
        return blocks[offset]

    matches = []
    for y in range(2 * height):
        for x in range(2 * width):
            for (dx, dy), standing, front, joy in rules:
                if cell(x, y) == standing and cell(x + dx, y + dy) == front:
                    matches.append((x, y, dx, dy, joy,
                                    cell(x + 2 * dx, y + 2 * dy),
                                    cell(x + 3 * dx, y + 3 * dy)))
    return matches


def expected_gold_hops(gold, map_name, tileset):
    """Use actual Gold HOP role/direction, not counts or RPP trigger tables.

    A solid third cell is deliberate in some Gold maps and is NOT a reason
    to reject the valid two-cell jump. The general collision converter checks
    the barrier and landing geometry with the same source labels.
    """
    from johto_indoor_collision_adapter import plan_gold_quadrant_collision
    plan, _ = plan_gold_quadrant_collision(gold, map_name, tileset)
    rejected={(h['x'],h['y'],h['dx'],h['dy'])
              for h in plan['unsafe_hop_candidates']}
    # Gold Ruins has a cliff-tip marked HOP_DOWN that would land in WALL.
    # Pin *exactly* this physical exception, rather than ignoring all bad
    # landings or inventing a runtime action at the unsafe tile.
    reviewed_unsafe={(9,30,0,1)} if map_name=='RuinsOfAlphOutside' else set()
    if rejected != reviewed_unsafe:
        raise AssertionError(f'{map_name}: Gold HOP barrier/landing invalid: '
                             f"{plan['unsafe_hop_candidates']} (reviewed={sorted(reviewed_unsafe)})")
    return {(h['x'], h['y'], h['dx'], h['dy']) for h in plan['hops']}


def coordinate_hops(src, label):
    section = src.split('\n' + label + '\n', 1)[1].split('\tdb $ff', 1)[0]
    actions = re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*PLAYER_DIR_(\w+)', section)
    steps = {'DOWN': (0, 1), 'LEFT': (-1, 0),
             'RIGHT': (1, 0), 'UP': (0, -1)}
    if any(direction not in steps for _, _, direction in actions):
        raise AssertionError(f'{label}: invalid direction')
    parsed = [(int(x), int(y), *steps[direction]) for x, y, direction in actions]
    if len(parsed) != len(set(parsed)):
        raise AssertionError(f'{label}: duplicate jump actions')
    return set(parsed)


def mask_blocked(mask, x, y, width=30):
    if not 0 <= x < width or not 0 <= y < 54:
        return True
    return bool(mask[y * ((width + 7) // 8) + x // 8] & (1 << (x % 8)))


def audit(root=ROOT, gold=None):
    root = Path(root)
    gold = Path(gold or os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
    src = (root / 'engine/overworld/ledges.asm').read_text()
    report = {'native_pair_maps': {}, 'kanto_overworld': {}, 'modern_coordinate_maps': {},
              'errors': registration_errors(src), 'warnings': []}
    counts = {}
    constants = (root / 'constants/map_constants.asm').read_text()
    for name, (width, tileset, label) in NATIVE.items():
        constant = re.search(r'(?m)^\s*mapconst\s+' +
                             re.escape({'JohtoVioletCity': 'JOHTO_VIOLET_CITY', 'JohtoIlexForest': 'JOHTO_ILEX_FOREST'}.get(name, 'JOHTO_ROUTE_' + name.removeprefix('JohtoRoute'))) +
                             r',\s*(\d+),\s*(\d+)\b', constants)
        actual_width = (int(constant[2]) if constant else
                        15 if name == 'JohtoIlexForest' and
                        'DEF JOHTO_ILEX_FOREST_WIDTH EQU 15' in
                        (root / 'constants/region_map_constants.asm').read_text() else None)
        if actual_width != width:
            report['errors'].append(f'{name}: ledge-audit width {width} disagrees with registered map width')
            continue
        matches = decode(root, name, width, tileset, pairs(src, label))
        counts[name] = len(matches)
        if not (gold / 'maps' / (name[5:] + '.blk')).is_file():
            report['errors'].append(name + ': complete Gold source is required for ledge coverage')
        else:
            try:
                expected = expected_gold_hops(gold, name[5:],
                                              'forest' if tileset == 'johto_ilex_forest' else 'johto')
                observed = {(x, y, dx, dy) for x, y, dx, dy, *_ in matches}
                if expected != observed:
                    report['errors'].append(f'{name}: Gold HOP missing={sorted(expected-observed)} '
                                            f'extra={sorted(observed-expected)}')
            except (AssertionError, OSError, ValueError, KeyError) as exc:
                report['errors'].append(f'{name}: Gold ledge contract: {exc}')
        report['native_pair_maps'][name] = {
            'matches': len(matches),
            'by_direction': dict(Counter({'down': sum((dx, dy) == (0, 1) for x, y, dx, dy, *_ in matches),
                                          'left': sum((dx, dy) == (-1, 0) for x, y, dx, dy, *_ in matches),
                                          'right': sum((dx, dy) == (1, 0) for x, y, dx, dy, *_ in matches)})),
            'out_of_bounds_landings': sum(dest is None for *_, dest, third in matches),
            'out_of_bounds_third_cells': sum(third is None for *_, dest, third in matches),
        }
        if any(dest is None for *_, dest, third in matches):
            report['errors'].append(name + ': out-of-bounds two-cell landing')
        if name == 'JohtoIlexForest':
            found = {(x, y, dx, dy) for x, y, dx, dy, *_ in matches}
            if found != FOREST_ACTIONS or len(matches) != 10:
                report['errors'].append('Forest HOP source/direction set changed')
            mask = (root / 'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
            if len(mask) != 216:
                report['errors'].append('Forest collision mask not 216 bytes')
            else:
                for x, y, dx, dy in FOREST_ACTIONS:
                    if (mask_blocked(mask, x, y) or
                            not mask_blocked(mask, x + dx, y + dy) or
                            mask_blocked(mask, x + 2 * dx, y + 2 * dy)):
                        report['errors'].append(f'Forest two-cell collision invalid at {(x,y,dx,dy)}')
                report['native_pair_maps'][name]['third_cell_tiles'] = dict(
                    Counter(hex(third) for *_, third in matches))
    # These are the accepted rendered-tile pair counts in the supplied .206
    # worktree, not a claim that 95 gameplay jumps have been CPU-tested.
    accepted = {'JohtoRoute29': 39, 'JohtoRoute30': 21, 'JohtoRoute31': 14,
                'JohtoRoute32': 8, 'JohtoVioletCity': 3, 'JohtoIlexForest': 10}
    if counts != accepted:
        report['errors'].append(f'Johto native ledge count drift: {counts}')

    # The modern maps use coordinate-based rules rather than native tile IDs.
    # Inventory all those authored rules; geometry acceptance still needs Gold.
    for label, map_name, width, height, expected in (
            ('.route33Hops', 'JohtoRoute33', 20, 18, 7),
            ('.azaleaHops', 'JohtoAzaleaTown', 40, 18, 10),
            ('.ruinsHops', 'JohtoRuinsOfAlphOutside', 20, 36, 16),
            ('.route37Hops', 'JohtoRoute37', 20, 18, 6),
            ('.ecruteakHops', 'JohtoEcruteakCity', 40, 36, 6),
            ('.route38Hops', 'JohtoRoute38', 40, 18, 24)):
        part = src.split('\n' + label + '\n', 1)[1].split('\tdb $ff', 1)[0]
        actions = re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*PLAYER_DIR_(\w+)', part)
        try:
            actual_actions = coordinate_hops(src, label)
            reference = expected_gold_hops(gold, map_name[5:],
                        'johto' if map_name in ('JohtoRuinsOfAlphOutside', 'JohtoRoute37', 'JohtoEcruteakCity', 'JohtoRoute38') else 'johto_modern')
            if actual_actions != reference:
                report['errors'].append(f'{map_name}: Gold HOP missing={sorted(reference-actual_actions)} '
                                        f'extra={sorted(actual_actions-reference)}')
        except (AssertionError, OSError, ValueError, KeyError, IndexError) as exc:
            report['errors'].append(f'{map_name}: Gold coordinate HOP contract: {exc}')
        mask = (root / f'maps/{map_name}.blocked_mask.bin').read_bytes()
        stride = (width + 7) // 8
        if len(mask) != stride * height:
            report['errors'].append(f'{map_name}: incorrect blocked-mask size')
            continue
        def blocked(x, y):
            if not 0 <= x < width or not 0 <= y < height:
                return True
            return bool(mask[y * stride + x // 8] & (1 << (x % 8)))
        steps = {'DOWN': (0, 1), 'LEFT': (-1, 0),
                 'RIGHT': (1, 0), 'UP': (0, -1)}
        third_cells_passable = 0
        for xs, ys, direction in actions:
            x, y = int(xs), int(ys)
            if direction not in steps:
                report['errors'].append(f'{map_name}: invalid jump direction {direction}')
                continue
            dx, dy = steps[direction]
            if (blocked(x, y) or not blocked(x + dx, y + dy) or
                    blocked(x + 2 * dx, y + 2 * dy)):
                report['errors'].append(f'{map_name}: invalid two-cell ledge {(x,y,direction)}')
            third_cells_passable += not blocked(x + 3*dx, y + 3*dy)
        report['modern_coordinate_maps'][map_name] = {
            'actions': len(actions), 'third_cell_passable': third_cells_passable,
            'runtime_extra_simulated_inputs': 2,
            'tileset': 'johto' if map_name in ('JohtoRuinsOfAlphOutside', 'JohtoRoute37', 'JohtoEcruteakCity', 'JohtoRoute38') else 'johto_modern',
        }
        if len(actions) != expected:
            report['errors'].append(f'{map_name}: coordinate HOP count drift')
    report['warnings'].append('All registered Johto Gold HOP directions are checked against original '
                              'collision roles; static comparison does not prove final runtime landing '
                              'or Kanto emulator behavior. Modern HOPs still use coordinate triggers.')

    # Every currently registered Johto outdoor map must be considered for
    # ledges. Future maps with Gold HOP roles must have a reviewed runtime
    # dispatcher and join this exact per-position/dir audit, not silently
    # inherit a zero-rule default just because the old roster was complete.
    known = set(NATIVE) | {'JohtoRoute33', 'JohtoAzaleaTown', 'JohtoRuinsOfAlphOutside', 'JohtoRoute37', 'JohtoEcruteakCity', 'JohtoRoute38'}
    registered = json.loads((root / 'tools/johto_native_maps.json').read_text())['maps']
    for entry in registered:
        name = entry['header'].removesuffix('_h')
        header = root / 'data/mapHeaders' / (name + '.asm')
        if not header.exists():
            report['errors'].append(f'{name}: registered Johto header missing')
            continue
        tileset = re.search(r'(?m)^\s*db\s+(JOHTO(?:_MODERN|_ILEX_FOREST)?)\b',
                            header.read_text())
        if not tileset:
            continue  # Gate, cave and other explicitly different movement sets
        key = tileset[1]
        gold_name = name.removeprefix('Johto')
        source_tileset = 'forest' if key == 'JOHTO_ILEX_FOREST' else (
                         'johto_modern' if key == 'JOHTO_MODERN' else 'johto')
        try:
            gold_hops = expected_gold_hops(gold, gold_name, source_tileset)
        except (AssertionError, OSError, ValueError, KeyError) as exc:
            report['errors'].append(f'{name}: cannot inventory registered Gold map: {exc}')
            continue
        if gold_hops and name not in known:
            report['errors'].append(f'{name}: Gold has {len(gold_hops)} HOP directions '
                                    'but this new map has no registered ledge audit')

    # Discover every Kanto map using the overworld tileset, including headers
    # with a literal 00 instead of OVERWORLD. No assumptions about Gold here.
    dims = {}
    for name, h, w in re.findall(r'(?m)^\s*mapconst\s+(\w+),\s*(\d+),\s*(\d+)',
                                  (root / 'constants/map_constants.asm').read_text()):
        dims[name] = (int(h), int(w))
    for path in sorted((root / 'data/mapHeaders').glob('*.asm')):
        lines = path.read_text().splitlines()
        if not any(re.match(r'^\s*db\s+(OVERWORLD|00|\$00)\b', line) for line in lines[:5]):
            continue
        asset = root / 'maps' / (path.stem + '.blk')
        if not asset.is_file():
            continue
        matches = re.search(r'\bdb\s+(\w+)_HEIGHT,\s*(\w+)_WIDTH', '\n'.join(lines[:10]))
        if not matches or matches[1] != matches[2] or matches[1] not in dims:
            report['warnings'].append(f'{path.stem}: unresolved Kanto header dimensions')
            continue
        h, w = dims[matches[1]]
        if len(asset.read_bytes()) != h * w:
            report['warnings'].append(f'{path.stem}: Kanto map dimensions mismatch')
            continue
        try:
            kanto = decode(root, path.stem, w, 'overworld', pairs(src, 'LedgeTiles'))
        except AssertionError:
            report['warnings'].append(f'{path.stem}: OVERWORLD header has nonstandard blockset indices')
            continue
        report['kanto_overworld'][path.stem] = len(kanto)
    report['totals'] = {'johto_native_pair_approaches': sum(counts.values()),
                        'modern_coordinate_rules': 23,
                        'route37_coordinate_rules': len(coordinate_hops(src, '.route37Hops')),
                        'route38_coordinate_rules': len(coordinate_hops(src, '.route38Hops')),
                        'ruins_coordinate_rules': len(coordinate_hops(src,'.ruinsHops')),
                        'kanto_overworld_maps_checked': len(report['kanto_overworld']),
                        'kanto_pair_approaches': sum(report['kanto_overworld'].values())}
    return report


if __name__ == '__main__':
    result = audit()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(bool(result['errors']))
