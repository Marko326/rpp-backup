#!/usr/bin/env python3
"""Read-only inventory for every *registered* RPP ledge implementation.

Counts front-tile/facing matches in installed maps and checks Forest's Gold
2-cell landing against the shipped mask. A terrain audit is NOT a ROM test.
"""
from collections import Counter
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
FACING = {'SPRITE_FACING_DOWN': (0, 1), 'SPRITE_FACING_LEFT': (-1, 0),
          'SPRITE_FACING_RIGHT': (1, 0), 'SPRITE_FACING_UP': (0, -1)}
NATIVE = {
    'JohtoRoute29': (30, 'johto', 'JohtoRoute29LedgeTiles'),
    'JohtoRoute30': (10, 'johto', 'JohtoRoute29LedgeTiles'),
    'JohtoRoute31': (10, 'johto', 'JohtoRoute31LedgeTiles'),
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
    expected_coord = {'route33Hops', 'azaleaHops'}
    errors = []
    for label, actual_set, expected_set in (
            ('native router', actual, expected),
            ('native table', tables, expected_tables),
            ('coordinate HOP router', coord, expected_coord)):
        if actual_set != expected_set:
            errors.append(f'{label} registration changed: got={sorted(actual_set)}, expected={sorted(expected_set)}; update audit + geometry contract')
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


def mask_blocked(mask, x, y, width=30):
    if not 0 <= x < width or not 0 <= y < 54:
        return True
    return bool(mask[y * ((width + 7) // 8) + x // 8] & (1 << (x % 8)))


def audit(root=ROOT):
    root = Path(root)
    src = (root / 'engine/overworld/ledges.asm').read_text()
    report = {'native_pair_maps': {}, 'kanto_overworld': {}, 'modern_coordinate_maps': {},
              'errors': registration_errors(src), 'warnings': []}
    counts = {}
    for name, (width, tileset, label) in NATIVE.items():
        matches = decode(root, name, width, tileset, pairs(src, label))
        counts[name] = len(matches)
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
            ('.azaleaHops', 'JohtoAzaleaTown', 40, 18, 9)):
        part = src.split('\n' + label + '\n', 1)[1].split('\tdb $ff', 1)[0]
        actions = re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*PLAYER_DIR_(\w+)', part)
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
        }
        if len(actions) != expected:
            report['errors'].append(f'{map_name}: coordinate HOP count drift')
    report['warnings'].append('Modern Route33/Azalea HOPs still use coordinate triggers and '
                              'the legacy two-simulated-input path; a potential third-cell '
                              'overshoot needs CPU/gameplay review (mask check alone is insufficient).')

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
                        'modern_coordinate_rules': 16,
                        'kanto_overworld_maps_checked': len(report['kanto_overworld']),
                        'kanto_pair_approaches': sum(report['kanto_overworld'].values())}
    return report


if __name__ == '__main__':
    result = audit()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(bool(result['errors']))
