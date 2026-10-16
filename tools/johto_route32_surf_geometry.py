#!/usr/bin/env python3
"""SRF-5.62.187: Route32 water bitset contract, independently derived from Gold.

Audit-only, not a converter. Does not alter ROM data or enable any other map.
"""
from pathlib import Path
import re

ROW = re.compile(r'^\s*db\s+\$([0-9a-fA-F]{2}),\s*\$([0-9a-fA-F]{2}),\s*\$([0-9a-fA-F]{2})\s*;\s*y=(\d{2})\s*$')


def gold_cells(gold: Path) -> set[tuple[int, int]]:
    blocks = (gold / 'maps/Route32.blk').read_bytes()
    if len(blocks) != 450:
        raise ValueError('Gold Route32 must have 10x45 blocks')
    labels = []
    for line in (gold / 'data/tilesets/johto_collision.asm').read_text().splitlines():
        match = re.search(r'\btilecoll\s+([^;]+)', line)
        if match:
            fields = tuple(x.strip() for x in match[1].split(','))
            if len(fields) != 4:
                raise ValueError('Gold Johto collision quartet malformed')
            labels.append(fields)
    if max(blocks) >= len(labels):
        raise ValueError('Gold Johto collision records incomplete')
    return {(2 * (i // 10) + q // 2, 2 * (i % 10) + q % 2)
            for i, block in enumerate(blocks)
            for q, tile in enumerate(labels[block]) if tile == 'WATER'}


def check(root: Path, gold: Path) -> list[str]:
    errors = []
    try:
        original = gold_cells(gold)
        source = (root / 'engine/overworld/johto_union_cave_surf.asm').read_text()
        mapping = (root / 'maps/JohtoRoute32.blk').read_bytes()
        blockset = (root / 'gfx/blocksets/johto.bst').read_bytes()
        passable = (root / 'gfx/tilesets/johto.tilecoll').read_bytes()
    except (OSError, ValueError) as exc:
        return [f'Route32 Gold water source unavailable: {exc}']
    if len(original) != 278:
        errors.append(f'Gold Route32 WATER count {len(original)} != 278; review source change')
    if len(mapping) != 450 or len(blockset) % 16 or not passable.endswith(b'\xff'):
        errors.append('RPP Route32 conversion geometry/tileset invalid')
    else:
        # The generated RPP block art must not make any true Gold water walkable.
        walkable = set(passable[:-1])
        for y, x in original:
            block = mapping[(y // 2) * 10 + x // 2]
            pos = block * 16
            if pos + 16 > len(blockset):
                errors.append('RPP Route32 block pointer outside blockset')
                break
            row, col = y % 2 * 2, x % 2 * 2
            ids = {blockset[pos + (row + dy) * 4 + col + dx]
                   for dy in range(2) for dx in range(2)}
            if walkable & ids:
                errors.append(f'Gold WATER cell ({x},{y}) uses passable RPP tile')
                break
    try:
        table = source.split('JohtoRoute32WaterRows::\n', 1)[1].splitlines()
    except IndexError:
        return errors + ['Route32 Surf row bitset missing']
    found = set()
    if len(table) < 90:
        errors.append('Route32 Surf row table truncated')
    for y, line in enumerate(table[:90]):
        match = ROW.fullmatch(line)
        if not match or int(match[4]) != y:
            errors.append(f'Route32 Surf bitset row malformed at y={y}')
            continue
        mask = sum(int(match[i], 16) << (8*(i-1)) for i in (1, 2, 3))
        if mask >> 20:
            errors.append(f'Route32 Surf row y={y} contains out-of-map bits')
        for x in range(20):
            if mask & (1 << x):
                found.add((y, x))
    if len(table) > 90 and ROW.fullmatch(table[90]):
        errors.append('Route32 Surf bitset unexpectedly has more than 90 rows')
    if original != found:
        errors.append(f'Route32 Surf Gold water bitset mismatch: missing {len(original-found)}, extra {len(found-original)}')
    must = (
        'IsJohtoRoute32WaterAhead::',
        'ld a, [wCurMap]\n\tcp JOHTO_ROUTE_32\n\tjp nz, .notWater',
        'ld a, [wCurRegion]\n\tcp MAP_REGION_JOHTO\n\tjp nz, .notWater',
        'cp SPRITE_FACING_DOWN\n\tjr nz, .up\n\tinc d',
        'cp SPRITE_FACING_UP\n\tjr nz, .left\n\tdec d',
        'cp SPRITE_FACING_LEFT\n\tjr nz, .right\n\tdec e',
        'cp SPRITE_FACING_RIGHT\n\tjp nz, .notWater\n\tinc e',
        'cp JOHTO_ROUTE_32_HEIGHT * 2\n\tjp nc, .notWater',
        'cp JOHTO_ROUTE_32_WIDTH * 2\n\tjp nc, .notWater',
        'ld l, d\n\tld h, 0\n\tadd hl, hl\n\tld c, d\n\tld b, 0\n\tadd hl, bc',
        'ld bc, JohtoRoute32WaterRows\n\tadd hl, bc',
        'ld c, a\n\tinc c\n\tld a, [hl]\n.shift\n\tsrl a\n\tdec c\n\tjr nz, .shift\n\tjr nc, .notWater',
        'scf\n\tjr .done\n.notWater\n\tand a',
        'pop hl\n\tpop de\n\tpop bc\n\tret',
    )
    for token in must:
        if token not in source:
            errors.append('Route32 Surf runtime missing/changed: ' + token[:50])
    return errors
