#!/usr/bin/env python3
"""Convert Gold Route29 and Forest HOP collision cells into native RPP ledge pairs.

Run on an UNMODIFIED (pre-conversion) map and corresponding blockset,
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


# Forest's Gold HOP coordinates are discovered from its original collision
# metadata, never written as an ASM runtime coordinate interpreter.
FOREST_DUPLICATES = {0x2A: 0x40, 0x19: 0x41, 0x05: 0x42}
FOREST_PAIRS = {(0, 1): (0x05, 0x40), (-1, 0): (0x05, 0x41),
                (1, 0): (0x05, 0x42)}


def build_forest_native_pairs(mapdata: bytes, blocks: bytes, labels):
    """Route29's copied-front-tile technique on Gold Forest's 30x54 grid.

    Returns (map, blockset, source hops, cloned block count). Fail closed if
    future Gold data stops matching the reviewed barrier/landing contract.
    """
    width, height = 15, 27
    if len(mapdata) != width*height or len(blocks) % 16 or len(labels) < len(blocks)//16:
        raise ValueError('Unexpected Gold Forest geometry')
    if set(FOREST_DUPLICATES.values()) & set(blocks):
        raise ValueError('Forest collision-only graphic IDs already referenced')
    def cell(x, y):
        if not (0 <= x < 2*width and 0 <= y < 2*height):
            raise ValueError('Forest hop outside map')
        block_id=mapdata[(y//2)*width+x//2]
        q=(y%2)*2+(x%2)
        tile=blocks[block_id*16+(y%2)*8+(x%2)*2+4]
        return labels[block_id][q], tile
    changes={}
    hops=[]
    for y in range(height*2):
        for x in range(width*2):
            role, standing=cell(x,y)
            if not role.startswith('HOP_'):
                continue
            if role not in DIRS:
                raise ValueError('Unsupported Forest HOP role: '+role)
            for dx,dy in DIRS[role]:
                front=(x+dx,y+dy)
                landing=(x+2*dx,y+2*dy)
                front_role,original=cell(*front)
                dest_role,_=cell(*landing)
                if standing!=5 or front_role!='WALL' or dest_role!='FLOOR':
                    raise ValueError(f'Forest ledge geometry not safe: {(x,y,dx,dy)}')
                expected={ (0,1):0x2a, (-1,0):0x19, (1,0):0x05}
                if (dx,dy) not in expected or original != expected[dx,dy]:
                    raise ValueError(f'Unexpected Forest HOP 8x8 tile pair: {(x,y,dx,dy)}')
                bx,by=front
                pos=(by//2)*width+bx//2
                tile_offset=(by%2)*8+(bx%2)*2+4
                modified=changes.setdefault(pos,{})
                if tile_offset in modified and modified[tile_offset]!=FOREST_DUPLICATES[original]:
                    raise ValueError('Overlapping Forest hops require incompatible clones')
                modified[tile_offset]=FOREST_DUPLICATES[original]
                hops.append((x,y,dx,dy))
    if len(hops)!=10 or len(set(hops))!=10:
        raise ValueError('Forest expected ten Gold cardinal HOP actions')
    output_map=bytearray(mapdata)
    output_blocks=bytearray(blocks)
    variants={}
    for position, adjustments in sorted(changes.items()):
        old_id=mapdata[position]
        block=bytearray(blocks[old_id*16:(old_id+1)*16])
        for offset,newid in adjustments.items():
            block[offset]=newid
        signature=bytes(block)
        if signature not in variants:
            new_id=len(output_blocks)//16
            if new_id>=256:
                raise ValueError('Forest block variant index overflow')
            variants[signature]=new_id
            output_blocks.extend(signature)
        output_map[position]=variants[signature]
    def final(x,y):
        b=output_map[(y//2)*width+x//2]
        return output_blocks[b*16+(y%2)*8+(x%2)*2+4]
    expected=set(hops)
    found=set()
    for (dx,dy),(standing,front) in FOREST_PAIRS.items():
        for y in range(2*height):
            for x in range(2*width):
                tx,ty=x+dx,y+dy
                if not (0<=tx<2*width and 0<=ty<2*height):
                    continue
                if (final(x,y),final(tx,ty))==(standing,front):
                    found.add((x,y,dx,dy))
    if found!=expected:
        raise ValueError(f'Forest ledge pair false positives/missing: {found ^ expected}')
    return bytes(output_map), bytes(output_blocks), sorted(hops), len(variants)


def clone_forest_tiles_and_palettes(png_path, palette_path):
    """Duplicate art+palette in unused Forest IDs without touching originals."""
    im=Image.open(png_path)
    if im.size!=(128,48):
        raise ValueError('Unexpected Gold Forest atlas size')
    width=im.width//8
    for original,clone in FOREST_DUPLICATES.items():
        src=(original%width*8,original//width*8)
        im.paste(im.crop((*src,src[0]+8,src[1]+8)),(clone%width*8,clone//width*8))
    lines=palette_path.read_text().splitlines(keepends=True)
    parsed=[]
    for i,line in enumerate(lines):
        match=re.fullmatch(r'(\s*tilepal\s+0,\s*)([^;\n]*)(.*)',line.rstrip('\n'))
        if match:
            values=[v.strip() for v in match[2].split(',')]
            if len(values)!=8:
                raise ValueError('Unexpected Forest palette row')
            parsed.append((i,match[1],values,match[3],line.endswith('\n')))
    if len(parsed)!=12:
        raise ValueError('Expected 96 Forest palette entries')
    original=[v for _,_,values,_,_ in parsed for v in values]
    for src,dest in FOREST_DUPLICATES.items():
        parsed[dest//8][2][dest%8]=original[src]
    for i,prefix,values,suffix,newline in parsed:
        lines[i]=prefix+', '.join(values)+suffix+('\n' if newline else '')
    return im, ''.join(lines)


def convert_forest(root: Path, gold: Path):
    from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
    aliases=gold_resource_aliases(gold)
    labels,_=collision_labels(gold,'forest',aliases)
    rows=[tuple(x.strip() for x in v.split(',')) for v in labels]
    srcmap=(gold/'maps/IlexForest.blk').read_bytes()
    srcblocks=(gold/'data/tilesets/forest_metatiles.bin').read_bytes()
    output_map,output_blocks,hops,n=build_forest_native_pairs(srcmap,srcblocks,rows)
    mapfile=root/'maps/JohtoIlexForest.blk'
    blockfile=root/'gfx/blocksets/johto_ilex_forest.bst'
    png=root/'gfx/tilesets/johto_ilex_forest.png'
    pal=root/'color/tilesets/johto_ilex_forest.asm'
    if mapfile.read_bytes()!=srcmap or blockfile.read_bytes()!=srcblocks:
        raise ValueError('Forest must be original Gold data before data conversion')
    if png.read_bytes()!=(gold/'gfx/tilesets/forest.png').read_bytes():
        raise ValueError('Forest atlas must equal original Gold')
    if pal.read_bytes()!=(gold/'gfx/tilesets/forest_palette_map.asm').read_bytes():
        raise ValueError('Forest palette must equal original Gold')
    art,palette=clone_forest_tiles_and_palettes(png,pal)
    # No writes until all geometry, art, palette and source identity pass.
    mapfile.write_bytes(output_map)
    blockfile.write_bytes(output_blocks)
    art.save(png)
    pal.write_text(palette)
    return {'hops':len(hops),'block_variants':n}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--gold-collision', type=Path,
                   help='Local pokegold/data/tilesets/johto_collision.asm')
    p.add_argument('--project', type=Path, default=Path('.'))
    p.add_argument('--ilex-forest', action='store_true',
                   help='Clone Forest Gold HOP front tiles into native RPP collision pairs')
    p.add_argument('--batch-preview', action='store_true',
                   help='Scan and stage all Johto maps without changing the project')
    p.add_argument('--gold-root', type=Path,
                   help='Local pokegold root (batch preview only)')
    p.add_argument('--output', type=Path,
                   help='Batch preview output folder')
    args = p.parse_args()
    if args.ilex_forest:
        if not args.gold_root:
            p.error('--ilex-forest requires --gold-root')
        print(convert_forest(args.project,args.gold_root))
        return
    if args.batch_preview:
        if not args.gold_root or not args.output:
            p.error('--batch-preview requires --gold-root and --output')
        from johto_rpp_batch import batch
        import json
        print(json.dumps(batch(args.gold_root, args.project, args.output),
                         ensure_ascii=False, indent=2))
        return
    if args.gold_collision is None:
        p.error('single-Route29 conversion requires --gold-collision')
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
