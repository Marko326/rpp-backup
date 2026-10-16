#!/usr/bin/env python3
"""Gold Union Cave 1F water -> RPP collision translation, static only.

This is intentionally NOT a Surf enablement tool. Gold WATER is a 16x16
collision class; RPP compares rendered 8x8 tile IDs on several movement
paths. IDs reused by cave walls must not be made globally surfable.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import re

EXPECTED_WATER_QUADRANTS = 64
EXPECTED_WATER_TILES = frozenset((0x03, 0x08, 0x0a, 0x0c, 0x0d, 0x14))
EXPECTED_SHARED_WALL_WATER = frozenset((0x03, 0x08, 0x0a, 0x0c, 0x0d))


def inspect(root: Path, gold: Path) -> dict:
    errors = []
    try:
        original = (gold / 'maps/UnionCave1F.blk').read_bytes()
        converted = (root / 'maps/JohtoUnionCave1F.blk').read_bytes()
        blocks = (root / 'gfx/blocksets/johto_union_cave.bst').read_bytes()
        collision = (gold / 'data/tilesets/cave_collision.asm').read_text()
        walkable_data = (root / 'gfx/tilesets/johto_union_cave.tilecoll').read_bytes()
    except OSError as exc:
        return {'errors': [f'missing Union Cave water source: {exc}']}
    if len(original) != 180 or len(converted) != 180 or len(blocks) % 16:
        return {'errors': ['Union Cave 1F geometry is not the validated 10x18 map']}
    if not walkable_data.endswith(b'\xff') or walkable_data.count(0xff) != 1:
        return {'errors': ['RPP cave passability list has no unique terminator']}

    labels = []
    for line in collision.splitlines():
        match = re.search(r'\btilecoll\s+([^;]+)', line)
        if match:
            quartet = tuple(s.strip() for s in match.group(1).split(','))
            if len(quartet) != 4:
                errors.append('Gold cave collision record has wrong arity')
            labels.append(quartet)
    if errors or len(labels) <= max(original):
        return {'errors': errors or ['Gold cave collision records are incomplete']}

    by_label = defaultdict(set)
    water_count = 0
    water_cells = []
    walkable = set(walkable_data[:-1])
    for position, (gold_block, rpp_block) in enumerate(zip(original, converted)):
        offset = rpp_block * 16
        if offset + 16 > len(blocks):
            errors.append(f'RPP block out of range at map position {position}')
            continue
        block = blocks[offset:offset + 16]
        for q, label in enumerate(labels[gold_block]):
            ids = {block[(q // 2 * 2 + y) * 4 + (q % 2 * 2 + x)]
                   for y in range(2) for x in range(2)}
            by_label[label].update(ids)
            if label == 'WATER':
                water_count += 1
                water_cells.append((position % 10 * 2 + q % 2,
                                    position // 10 * 2 + q // 2, sorted(ids)))
                bad = ids & walkable
                if bad:
                    errors.append(f'Gold WATER became walkable at block {position}, '
                                  f'quadrant {q}: {sorted(bad)}')
    water = frozenset(by_label['WATER'])
    walls = frozenset(by_label['WALL'])
    shared = water & walls
    if water_count != EXPECTED_WATER_QUADRANTS:
        errors.append(f'Gold WATER quadrants: {water_count}, expected '
                      f'{EXPECTED_WATER_QUADRANTS}')
    if water != EXPECTED_WATER_TILES:
        errors.append(f'RPP water tile IDs changed: {sorted(water)}')
    if shared != EXPECTED_SHARED_WALL_WATER:
        errors.append(f'water/wall shared IDs changed: {sorted(shared)}')
    if (water - shared) != {0x14}:
        errors.append('unique $14 water tile invariant lost')
    return {'errors': errors, 'water_quadrants': water_count,
            'water_tiles': [f'${x:02X}' for x in sorted(water)],
            'also_used_by_walls': [f'${x:02X}' for x in sorted(shared)],
            'water_cells': water_cells}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp', type=Path, required=True)
    parser.add_argument('--gold', type=Path, required=True)
    args = parser.parse_args()
    result = inspect(args.rpp, args.gold)
    # Full per-cell grid remains available to tests, but keep CLI readable.
    result.pop('water_cells', None)
    result['status'] = 'FAIL' if result['errors'] else 'PASS'
    result['surf_runtime_candidate'] = (args.rpp / 'engine/overworld/johto_union_cave_surf.asm').is_file()
    result['rom_built'] = False
    result['phone_accepted'] = False
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return bool(result['errors'])


if __name__ == '__main__':
    raise SystemExit(main())
