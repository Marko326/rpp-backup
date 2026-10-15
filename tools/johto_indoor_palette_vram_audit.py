#!/usr/bin/env python3
"""Source-traced tileset loader/palette audit for offline indoor candidates.

This checks concrete RPP source facts, not the free space in ROM or VRAM.
Candidate art may fit the loader's tile window and still have wrong palettes,
collision or no tileset registration. Never emits importable ASM or ROM.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
from johto_indoor_common import ConversionError, dump, read, safe_roots
from johto_indoor_tiles_converter import build_mapping
from johto_indoor_resource_budget import inspect as inspect_budget


def parse_tilepals(source: str) -> list[str]:
    """Each tilepal 0 directive encodes eight tile palette assignments."""
    result = []
    for raw in source.splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        args = re.fullmatch(r'tilepal\s+([^;]+)', line, re.I)
        if args is None:
            raise ConversionError(f'无法解析调色表行: {line}')
        values = [x.strip() for x in args[1].split(',')]
        if len(values) != 9 or values[0] != '0' or not all(re.fullmatch(r'[A-Z_][A-Z_0-9]*', v) for v in values[1:]):
            raise ConversionError(f'调色表行必须是 tilepal 0 + 8 个合法符号: {line}')
        result.extend(values[1:])
    return result


def loader_window(text: str) -> dict:
    """Require one literal FarCopy loader path, rather than guessing capacity."""
    match = re.search(r'(?ms)^LoadTilesetTilePatternData::\s*\n(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*::?\s*$)', text)
    body = match[1] if match else ''
    sizes = re.findall(r'^\s*ld\s+bc\s*,\s*\$([0-9a-fA-F]+)\b', body, re.M)
    if len(sizes) != 1 or not re.search(r'^\s*ld\s+de\s*,\s*vTileset\b', body, re.M) or not re.search(r'^\s*call\s+FarCopyData2\b', body, re.M):
        raise ConversionError('无法证明 tileset 图形加载长度；拒绝猜测显存容量')
    size = int(sizes[0], 16)
    if size <= 0 or size % 16:
        raise ConversionError('tileset 图形复制长度不是 16 字节/图块的整数倍')
    return {'source': 'home/overworld.asm', 'routine': 'LoadTilesetTilePatternData',
            'fixed_copy_bytes': size, 'fixed_copy_8x8_slots': size // 16,
            'is_global_free_vram_evidence': False}


def inspect(rpp: Path, gold: Path, artwork: dict, budget: dict) -> dict:
    rpp_set = artwork['rpp_tileset']
    constants = re.findall(r'^\s*const\s+([A-Z_][A-Z_0-9]*)\b',
                           read(rpp, 'constants/tilesets.asm'), re.M)
    if constants.count(rpp_set.upper()) != 1:
        raise ConversionError(f'RPP tileset 常量缺失或重复: {rpp_set}')
    ident = constants.index(rpp_set.upper())
    rows = re.findall(r'^\s*tileset\s+([^;\n]+)', read(rpp, 'data/tileset_headers.asm'), re.M)
    if len(rows) != len(constants) or ident >= len(rows):
        raise ConversionError('tileset 常量与 Header 数目不一致')
    row = [s.strip() for s in rows[ident].split(',')]
    if len(row) < 3:
        raise ConversionError('tileset Header 行不完整')
    block_label, gfx_label, coll_label = row[:3]
    main = read(rpp, 'main.asm')
    gfx_def = re.findall(r'^\s*'+re.escape(gfx_label)+r':\s*INCBIN\s+"([^"]+)"', main, re.M)
    block_def = re.findall(r'^\s*'+re.escape(block_label)+r':\s*INCBIN\s+"([^"]+)"', main, re.M)
    if len(gfx_def) != 1 or len(block_def) != 1:
        raise ConversionError('tileset 图形/区块指针无法追溯到唯一 INCBIN')
    palette_path = f'color/tilesets/{rpp_set}.asm'
    include_line = re.findall(r'^\s*INCLUDE\s+"'+re.escape(palette_path)+r'"\s*(?:;[^\n]*)?$',
                              read(rpp, 'color/data/map_palette_assignments.asm'), re.M)
    if len(include_line) != 1:
        raise ConversionError('现有 tileset 调色表没有唯一 INCLUDE 引用')
    palette_entries = parse_tilepals(read(rpp, palette_path))
    loader = loader_window(read(rpp, 'home/overworld.asm'))
    slots = loader['fixed_copy_8x8_slots']
    used = budget['gold']['distinct_tile_ids_referenced']
    candidate = {'original_used_tile_ids': used,
                 'compact_candidate_tile_ids': used,  # No two source IDs are conflated.
                 'pixel_cells_fit_fixed_copy_window': used <= slots,
                 'total_graphics_copy_bytes_if_2bpp': slots*16,
                 'palette_plan_created': False,
                 'new_tileset_header_registered': False,
                 'new_graphics_bin_registered': False}
    palette = {'source': palette_path,
               'source_rows': len(palette_entries)//8,
               'source_entries': len(palette_entries),
               'matches_fixed_window': len(palette_entries) == slots,
               'distinct_palette_symbols': sorted(set(palette_entries)),
               'reference_only': True,
               'gold_to_rpp_color_parity_proven': False}
    source = {'constant': rpp_set.upper(), 'constant_index': ident,
              'header': 'data/tileset_headers.asm', 'header_entry': row,
              'graphics_label': gfx_label, 'graphics_incbin': gfx_def[0],
              'blocks_label': block_label, 'blocks_incbin': block_def[0],
              'collision_label': coll_label,
              'palette_assignment_include': 'color/data/map_palette_assignments.asm'}
    warnings = []
    if not candidate['pixel_cells_fit_fixed_copy_window']:
        warnings.append('CANDIDATE_TILE_IDS_EXCEED_FIXED_COPY_WINDOW')
    if not palette['matches_fixed_window']:
        warnings.append('PALETTE_SOURCE_ENTRIES_DIFFER_FROM_FIXED_COPY_WINDOW')
    warnings += ['NO_NEW_TILESET_REGISTRATION', 'NEW_PALETTE_MAPPING_UNPROVEN',
                 'ROM_BANK_AND_RUNTIME_VRAM_NOT_MEASURED',
                 'GRAPHICS_2BPP_AND_RUNTIME_ANIMATIONS_NOT_VALIDATED']
    return {'schema': 'johto-indoor-palette-vram-v1', 'tileset': rpp_set,
            'source_trace': source, 'loader': loader, 'existing_palette': palette,
            'candidate': candidate, 'warnings': warnings,
            'status': 'PALETTE_VRAM_REVIEW_REQUIRED', 'import_allowed': False}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for n in ('rpp', 'gold', 'output'):
        ap.add_argument('--'+n, required=True, type=Path)
    args = ap.parse_args(argv)
    rpp, gold, out = safe_roots(args.rpp, args.gold, args.output)
    art, _ = build_mapping(rpp, gold)
    result = inspect(rpp, gold, art, inspect_budget(rpp, gold, art))
    dump(out, 'indoor_palette_vram.json', result)
    print(result['status'], result['loader']['fixed_copy_8x8_slots'])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
