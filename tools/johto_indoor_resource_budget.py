#!/usr/bin/env python3
"""Audit indoor candidate art footprint and palette references (offline only).

No hardcoded ROM/VRAM capacity is treated as authoritative. Resource evidence is
reported for a human decision; a matching palette file is not palette parity.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
from johto_indoor_common import ConversionError, dump, safe_roots
from johto_indoor_tiles_converter import build_mapping
from johto_gold_sources import gold_block_sources
from johto_rpp_asset_audit import blocks_for, gold_resource_aliases, load_png_tiles


def inspect(rpp: Path, gold: Path, artwork: dict) -> dict:
    gold_set = artwork['gold_tileset']
    rpp_set = artwork['rpp_tileset']
    src = gold_block_sources(gold).get(artwork['source_map'])
    if not src:
        raise ConversionError('Gold layout reference missing')
    data = (gold / src).read_bytes()
    if len(data) != artwork['block_count']:
        raise ConversionError('Gold block layout dimensions mismatch')
    gblocks, gblock_path, _ = blocks_for(gold, gold_set, 'gold', gold_resource_aliases(gold))
    rblocks, rblock_path, _ = blocks_for(rpp, rpp_set, 'rpp')
    if not gblocks or not rblocks:
        raise ConversionError('缺少 Gold 或 RPP 区块文件')
    used_blocks = sorted(set(data))
    used_tile_ids = sorted({tile for bid in used_blocks for tile in gblocks[bid*16:(bid+1)*16]})
    png = gold / 'gfx/tilesets' / f'{gold_set}.png'
    atlas = load_png_tiles(png)
    if atlas is None or any(t >= len(atlas) for t in used_tile_ids):
        raise ConversionError('Gold 图集缺失或 tile ID 超出图集')
    rpp_png = rpp/'gfx/tilesets'/f'{rpp_set}.png'
    if not rpp_png.is_file():
        rpp_png = rpp/'gfx/tilesets'/f'{rpp_set}.t1.png'
    rpp_atlas = load_png_tiles(rpp_png)
    if rpp_atlas is None:
        raise ConversionError('RPP 当前 tileset 找不到 PNG 图集')
    palette = rpp/'color/tilesets'/f'{rpp_set}.asm'
    palette_text = palette.read_text(encoding='utf-8') if palette.is_file() else ''
    # `tilepal` is a source table, not a guarantee that its entries are usable
    # for the proposed Gold art or that all runtime palettes are loaded.
    pal_entries = sum(max(0, len(line.split(';')[0].split('tilepal', 1)[1].split(',')) - 1)
                      for line in palette_text.splitlines() if re.match(r'^\s*tilepal\b', line))
    pal_lines = sum(bool(re.match(r'^\s*tilepal\b', s)) for s in palette_text.splitlines())
    # Primary arithmetic is on referenced 8x8 source cells, not PNG file size.
    distinct_bitmap_count = len({atlas[i] for i in used_tile_ids})
    new_count = len(used_blocks)
    if new_count > 256:
        raise ConversionError('候选区块表超过单字节索引限制')
    facts = {
        'source_map': artwork['source_map'],
        'gold': {'block_file': gblock_path, 'used_block_ids': used_blocks,
                 'unique_blocks': new_count, 'metatile_bytes_compact': new_count*16,
                 'distinct_tile_ids_referenced': len(used_tile_ids),
                 'distinct_tile_bitmaps': distinct_bitmap_count,
                 'highest_tile_id': max(used_tile_ids, default=None),
                 'atlas_tiles': len(atlas)},
        'rpp': {'block_file': rblock_path, 'existing_metatiles': len(rblocks)//16,
                'existing_png': str(rpp_png.relative_to(rpp)),
                'existing_png_tiles': len(rpp_atlas),
                'palette_file': str(palette.relative_to(rpp)) if palette.is_file() else None,
                'palette_source_lines': pal_lines, 'palette_source_entries_estimate': pal_entries},
        'capacity_checks': {'compact_block_ids_fit_in_byte': new_count <= 256,
                            'atlas_references_resolved': True,
                            'vram_available_tiles': None, 'rom_available_bank_bytes': None,
                            'runtime_palette_compatibility': None,
                            'tile_animation_compatibility': None,
                            'engine_tile_id_mapping': None},
        'status': 'RESOURCE_BUDGET_REVIEW_REQUIRED',
        'import_allowed': False,
        'manual_checks': ['target tileset allocation and VRAM loaded tile slots',
                          'ROM bank free space and map header references',
                          'palette and CGB/DMG runtime color behavior',
                          'tile animation and door-frame collision mapping']}
    return {'schema': 'johto-indoor-resource-audit-v1', **facts}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('rpp', 'gold', 'output'):
        ap.add_argument('--'+name, required=True, type=Path)
    args = ap.parse_args(argv)
    rpp, gold, out = safe_roots(args.rpp, args.gold, args.output)
    artwork, _ = build_mapping(rpp, gold)
    result = inspect(rpp, gold, artwork)
    dump(out, 'indoor_resource_budget.json', result)
    print(result['status'], result['gold']['unique_blocks'], 'blocks')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
