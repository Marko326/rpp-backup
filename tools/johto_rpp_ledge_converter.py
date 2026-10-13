#!/usr/bin/env python3
"""Convert Gold's Route 29 HOP collision cells into existing RPP ledge pairs.

Run on an UNMODIFIED (pre-conversion) Route 29 map and Johto blockset,
with the local pokegold repository available. This is an offline data
conversion, not a new overworld movement/collision interpreter.

Example (from the RPP project root):
    python tools/johto_rpp_ledge_converter.py \
      --gold-collision ../pokegold-master/data/tilesets/johto_collision.asm

The converter duplicates two unused 8x8 graphics slots ($20/$21) so
normal floor ($05) and an otherwise shared downward ledge tile ($4c)
can be visually unchanged but have distinct collision identities. It
clones only affected map block instances, leaving New Bark unaffected.
"""
import argparse
from collections import Counter
from pathlib import Path
import re
from PIL import Image

MAP_W, MAP_H = 30, 9
WORLD_W, WORLD_H = 60, 18
DIRS = {
    'HOP_LEFT': [(-1, 0)], 'HOP_RIGHT': [(1, 0)],
    'HOP_DOWN': [(0, 1)], 'HOP_UP': [(0, -1)],
    'HOP_DOWN_LEFT': [(0, 1), (-1, 0)],
    'HOP_DOWN_RIGHT': [(0, 1), (1, 0)],
    'HOP_UP_LEFT': [(0, -1), (-1, 0)],
    'HOP_UP_RIGHT': [(0, -1), (1, 0)],
}
# Tile #5 is ordinary grass-edge floor. Tile #76 is an existing wall.
# These two unused graphics slots keep the rendering pixel-identical.
DUPLICATES = {5: 0x20, 76: 0x21}


def parse_gold_collisions(path):
    labels = []
    for line in path.read_text(encoding='utf-8').splitlines():
        m = re.search(r'\btilecoll\s+([^;]+)\s*;', line)
        if m:
            values = tuple(x.strip() for x in m.group(1).split(','))
            if len(values) != 4:
                raise ValueError('Invalid Gold collision quartet: ' + line)
            labels.append(values)
    if len(labels) < 128:
        raise ValueError('Gold Johto collision table is incomplete')
    return labels


def build(mapdata, blocks, labels):
    if len(mapdata) != MAP_W * MAP_H or len(blocks) != 128 * 16:
        raise ValueError('Expected original Route29 map and 128-block Johto tileset')
    if max(mapdata) >= 128:
        raise ValueError('Already converted or unexpected map blocks: use the original map')
    if any(v in blocks for v in DUPLICATES.values()):
        raise ValueError('Reserved duplicate tile indices already used')

    def get_cell(x, y):
        b = mapdata[(y // 2) * MAP_W + x // 2]
        q = (y % 2) * 2 + x % 2
        char = blocks[b * 16 + (y % 2) * 8 + (x % 2) * 2 + 4]
        return labels[b][q], char

    changes = {}  # map 32x32 block position => per-tile adjustments
    hops = []
    for y in range(WORLD_H):
        for x in range(WORLD_W):
            t, src = get_cell(x, y)
            if not t.startswith('HOP_'):
                continue
            if t not in DIRS:
                raise ValueError(f'Unknown Gold hop collision {t} at {(x, y)}')
            for dx, dy in DIRS[t]:
                bx, by = x + dx, y + dy
                lx, ly = x + 2 * dx, y + 2 * dy
                x3, y3 = x + 3 * dx, y + 3 * dy
                if not (0 <= lx < WORLD_W and 0 <= ly < WORLD_H):
                    raise ValueError('Jump target outside map')
                if not (0 <= x3 < WORLD_W and 0 <= y3 < WORLD_H):
                    raise ValueError('Original RPP simulated step would exit map')
                if get_cell(lx, ly)[0] not in ('FLOOR', 'TALL_GRASS'):
                    raise ValueError(f'Gold two-cell landing blocked: {(lx, ly)}')
                if get_cell(x3, y3)[0] not in ('FLOOR', 'TALL_GRASS'):
                    raise ValueError(f'RPP third-cell fallback blocked: {(x3, y3)}')
                barrier, front_tile = get_cell(bx, by)
                # Left uses existing blocked $3b and never needs cloning.
                if (dx, dy) == (-1, 0):
                    if (src, front_tile) != (5, 59):
                        raise ValueError(f'Unexpected left pair: {src}, {front_tile}')
                    newtile = front_tile
                else:
                    expected = 5 if dx else 76
                    if (src, front_tile) != (5, expected):
                        raise ValueError(f'Unexpected {dx,dy} pair: {src}, {front_tile}')
                    newtile = DUPLICATES[front_tile]
                    block_pos = (bx // 2, by // 2)
                    off = (by % 2) * 8 + (bx % 2) * 2 + 4
                    current = changes.setdefault(block_pos, {})
                    if off in current and current[off] != newtile:
                        raise ValueError('Incompatible hop overlaps')
                    current[off] = newtile
                hops.append((x, y, dx, dy, bx, by, newtile))

    output_blocks = bytearray(blocks)
    output_map = bytearray(mapdata)
    variants = {}
    for (bx, by), adjustments in sorted(changes.items()):
        i = by * MAP_W + bx
        original_id = mapdata[i]
        patch = bytearray(blocks[original_id * 16:(original_id + 1) * 16])
        for off, tile in adjustments.items():
            patch[off] = tile
        signature = bytes(patch)
        if signature not in variants:
            new_id = len(output_blocks) // 16
            if new_id >= 256:
                raise ValueError('No free map block indices')
            variants[signature] = new_id
            output_blocks.extend(patch)
        output_map[i] = variants[signature]

    def final_char(x, y):
        b = output_map[y // 2 * MAP_W + x // 2]
        return output_blocks[b * 16 + (y % 2) * 8 + (x % 2) * 2 + 4]
    # Direction-specific trigger pairs must be unique across the entire
    # map. This also catches accidental hops at ordinary cliffs/walls.
    valid = {(x, y, dx, dy) for x, y, dx, dy, _, _, _ in hops}
    expected_pairs = {(-1, 0): (5, 59), (1, 0): (5, 32), (0, 1): (5, 33)}
    for (dx, dy), (s, f) in expected_pairs.items():
        for y in range(WORLD_H):
            for x in range(WORLD_W):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < WORLD_W and 0 <= ny < WORLD_H):
                    continue
                if (final_char(x, y), final_char(nx, ny)) == (s, f):
                    if (x, y, dx, dy) not in valid:
                        raise ValueError(f'Incorrect extra RPP hop at {(x,y)} in {(dx,dy)}')
    for x, y, dx, dy, _, _, _ in hops:
        assert (final_char(x, y), final_char(x + dx, y + dy)) == expected_pairs[(dx, dy)]
    counts = Counter((dx, dy) for _, _, dx, dy, _, _, _ in hops)
    assert counts == {(0, 1): 25, (1, 0): 8, (-1, 0): 6}, counts
    return output_map, output_blocks, counts, len(variants)


def clone_tiles_and_palettes(png_path, pal_path):
    im = Image.open(png_path)
    if im.size != (128, 48):
        raise ValueError('Unexpected Johto graphics layout')
    width = im.width // 8
    for original, clone in DUPLICATES.items():
        oldbox = (original % width * 8, original // width * 8,
                  original % width * 8 + 8, original // width * 8 + 8)
        newpoint = (clone % width * 8, clone // width * 8)
        im.paste(im.crop(oldbox), newpoint)
    im.save(png_path)
    lines = pal_path.read_text(encoding='utf-8').splitlines(keepends=True)
    indices = []
    for li, line in enumerate(lines):
        m = re.match(r'(\s*tilepal\s+0,\s*)(.*?)(\s*(?:;.*)?\n?)$', line)
        if m:
            colors = m.group(2).split(', ')
            if len(colors) != 8:
                raise ValueError('Unexpected 8-tile palette layout')
            indices.append((li, m.group(1), colors, m.group(3)))
    if len(indices) * 8 != 96:
        raise ValueError('Unexpected Johto palette length')
    original_palette = [c for _, _, cs, _ in indices for c in cs]
    for original, clone in DUPLICATES.items():
        pos, col = divmod(clone, 8)
        indices[pos][2][col] = original_palette[original]
    for li, prefix, colors, suffix in indices:
        lines[li] = prefix + ', '.join(colors) + suffix
    pal_path.write_text(''.join(lines), encoding='utf-8')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--gold-collision', type=Path, required=True,
                   help='Local pokegold/data/tilesets/johto_collision.asm')
    p.add_argument('--project', type=Path, default=Path('.'))
    args = p.parse_args()
    root = args.project
    gold = parse_gold_collisions(args.gold_collision)
    mappath = root / 'maps/JohtoRoute29.blk'
    blockpath = root / 'gfx/blocksets/johto.bst'
    m, b, counts, nblocks = build(mappath.read_bytes(), blockpath.read_bytes(), gold)
    # Mutations only happen after all compatibility checks passed.
    mappath.write_bytes(m)
    blockpath.write_bytes(b)
    clone_tiles_and_palettes(root / 'gfx/tilesets/johto.png',
                             root / 'color/tilesets/johto.asm')
    print(f'Converted {sum(counts.values())} hops ({counts}), {nblocks} unique new blocks')
    print('Original Kanto ledge actions and simulated input count remain unchanged')

if __name__ == '__main__':
    main()
