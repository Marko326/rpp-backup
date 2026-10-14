#!/usr/bin/env python3
"""P1-3: read-only Gold/RPP metatile and graphics-reuse audit.

Only generates reports in a separate empty directory. Never copies assets into
RPP or edits ROM sources. Pixel matches are *not* collision equivalence.
Requires the project's P1.136 johto_gold_sources.py and Pillow for PNG audit.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import re
import sys

from johto_gold_sources import gold_block_sources

try:
    from PIL import Image
except ImportError:
    Image = None

MAP_REG = re.compile(r'^\s*map\s+(\w+),\s*(TILESET_\w+)\s*,', re.M)
MAP_DIM = re.compile(r'^\s*map_const\s+(\w+),\s*(\d+)\s*,\s*(\d+)', re.M)
TILECOLL = re.compile(r'^\s*tilecoll\s+([^;\r\n]+)', re.M)
MAX_SUGGESTIONS = 8
TILESET_SOURCE_LABEL = re.compile(r'^Tileset([A-Za-z0-9]+)(Meta|Coll)::$')
TILESET_SOURCE_FILE = re.compile(r'^(INCBIN|INCLUDE)\s+"(data/tilesets/[^"]+)"')


def gold_resource_aliases(gold):
    """Read actual Gold asm alias declarations (e.g., Cave/DarkCave Meta).

    Synthetic test fixtures without gfx/tilesets.asm retain conventional paths.
    Never guess an alias from the target tileset's name.
    """
    path = gold / 'gfx/tilesets.asm'
    if not path.is_file():
        return {}
    result = {}
    pending = []
    for raw in read_text(path).splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        label = TILESET_SOURCE_LABEL.fullmatch(line)
        if label:
            pending.append((label.group(1).lower(), label.group(2)))
            continue
        source = TILESET_SOURCE_FILE.match(line)
        if pending and source:
            command, filename = source.groups()
            suffix = 'Meta' if command == 'INCBIN' and filename.endswith('_metatiles.bin') else (
                'Coll' if command == 'INCLUDE' and filename.endswith('_collision.asm') else None)
            if suffix is not None:
                for label_name, label_type in pending:
                    if label_type != suffix:
                        raise AuditError(f'Gold tileset 源声明类型冲突: {path} {label_name}')
                    key = (label_name, suffix)
                    if key in result and result[key] != filename:
                        raise AuditError(f'Gold tileset 源声明重复: {label_name} {suffix}')
                    result[key] = filename
        pending = []  # Do not cross unrelated directives/labels/sections.
    return result


def gold_source_path(root, name, kind, aliases):
    filename = aliases.get((name.replace('_', '').lower(), kind))
    if filename is None:
        filename = f'data/tilesets/{name}_{"metatiles.bin" if kind == "Meta" else "collision.asm"}'
    return root / filename



class AuditError(ValueError):
    """Input is missing, ambiguous or cannot be safely processed."""


def read_text(path):
    if not path.is_file():
        raise AuditError(f'缺少必需文件: {path}')
    return path.read_text(encoding='utf-8')


def safe_output(gold, project, output):
    gold, project, output = (p.resolve() for p in (gold, project, output))
    if not gold.is_dir() or not project.is_dir():
        raise AuditError('Gold 和 RPP 工程目录必须存在')
    for source in (gold, project):
        if output == source or source in output.parents or output in source.parents:
            raise AuditError('--output 必须在两套源码目录之外，且不能是源码的上层目录')
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise AuditError('输出目录必须不存在或为空，避免覆盖历史报告')
    return gold, project, output


def sha(data):
    return hashlib.sha256(data).hexdigest()


def layout_inventory(gold):
    definitions = MAP_REG.findall(read_text(gold / 'data/maps/maps.asm'))
    if not definitions:
        raise AuditError('无法读取 Gold maps.asm 中的地图注册')
    sizes = {}
    for name, width, height in MAP_DIM.findall(read_text(gold / 'constants/map_constants.asm')):
        key = name.replace('_', '').lower()
        if key in sizes:
            raise AuditError(f'Gold 地图尺寸键重复: {name}')
        sizes[key] = (int(width), int(height))
    mapping = gold_block_sources(gold)
    maps = []
    names = set()
    for name, tileset in definitions:
        if name in names:
            raise AuditError(f'重复 Gold 地图: {name}')
        names.add(name)
        dims = sizes.get(name.replace('_', '').lower())
        if dims is None:
            raise AuditError(f'缺少地图宽高: {name}')
        src = mapping.get(name)
        if not src:
            raise AuditError(f'缺少地图布局引用: {name}')
        raw = (gold / src).read_bytes()
        width, height = dims
        if len(raw) != width * height:
            raise AuditError(f'地图布局长度错误: {name} ({len(raw)} != {width*height})')
        maps.append({'name': name, 'tileset': tileset, 'source_layout': src,
                     'width': width, 'height': height, 'blocks': raw})
    return maps


def load_png_tiles(path):
    """PNG scanline order; each entry is 8x8 RGBA bytes. No palette assumptions."""
    if not path.is_file():
        return None
    if Image is None:
        raise AuditError('PNG 需要 Pillow：python -m pip install Pillow')
    with Image.open(path) as file:
        im = file.convert('RGBA')
    w, h = im.size
    if w % 8 or h % 8 or not w or not h:
        raise AuditError(f'图块 PNG 尺寸不是 8 的倍数: {path} ({w}x{h})')
    result = []
    for top in range(0, h, 8):
        for left in range(0, w, 8):
            result.append(im.crop((left, top, left + 8, top + 8)).tobytes())
    return result


def color_pattern(pixels):
    """Palette-independent shape; never treated as exact artwork."""
    ids = {}
    pattern = bytearray()
    for i in range(0, len(pixels), 4):
        color = pixels[i:i+4]
        if color not in ids:
            ids[color] = len(ids)
        pattern.extend(ids[color].to_bytes(2, 'little'))
    return bytes(pattern)


def gfx_signatures(raw16, tiles):
    """Full 32x32 metatile in row-major order, plus color-relabeling pattern."""
    if tiles is None:
        return None
    if any(idx >= len(tiles) for idx in raw16):
        return 'OUT_OF_RANGE'
    rgba = bytearray()
    # Arrange 4x4 8x8 tiles into the actual 32x32 image, not 16 tile hashes.
    for ty in range(4):
        for py in range(8):
            for tx in range(4):
                tile = tiles[raw16[ty * 4 + tx]]
                rgba.extend(tile[py*32:(py+1)*32])
    pixels = bytes(rgba)
    return (sha(pixels), sha(color_pattern(pixels)))


def blocks_for(root, name, suffix, aliases=None):
    path = (gold_source_path(root, name, 'Meta', aliases or {}) if suffix == 'gold'
            else root / 'gfx/blocksets' / f'{name}.bst')
    if not path.is_file():
        return None, str(path.relative_to(root)), 0
    raw = path.read_bytes()
    tail = len(raw) % 16
    # A single known legacy RPP file contains 128 complete metatiles plus
    # one terminal 0x00. Preserve/report this anomaly; do not edit the asset
    # or assume that the ROM loader ignores its final byte.
    if tail and suffix == 'rpp' and name == 'facility' and len(raw) == 2049 and raw[-1:] == b'\x00':
        raw = raw[:-1]
    elif tail:
        raise AuditError(f'区块集长度必须是正的 16 倍数，发现 {tail} 个非完整区块字节: {path}')
    if not raw:
        raise AuditError(f'区块集为空: {path}')
    return raw, str(path.relative_to(root)), tail


def metatile_entries(raw, tiles):
    entries = []
    if raw is None:
        return entries
    for i in range(len(raw)//16):
        chunk = raw[i*16:i*16+16]
        sig = gfx_signatures(chunk, tiles)
        entries.append({'id': i, 'bytes': chunk, 'raw_sha': sha(chunk),
                        'pixel_sha': sig[0] if isinstance(sig, tuple) else None,
                        'pattern_sha': sig[1] if isinstance(sig, tuple) else None,
                        'art_issue': sig if isinstance(sig, str) else ('PNG_MISSING' if sig is None else None)})
    return entries


def compose_candidates(raw16, gold_tiles, rpp_tile_indexes, by_shape=False):
    """Can the 16 Gold 8x8 pixels be found inside *one* RPP tile atlas?"""
    if gold_tiles is None or any(tile_id >= len(gold_tiles) for tile_id in raw16):
        return []
    basis = 'pattern' if by_shape else 'pixel'
    found = []
    for name, table in sorted(rpp_tile_indexes.items()):
        mapped = []
        for tile_id in raw16:
            bitmap = gold_tiles[tile_id]
            key = sha(color_pattern(bitmap)) if by_shape else sha(bitmap)
            choices = table[basis].get(key, [])
            if not choices:
                break
            mapped.append(choices[0])
        if len(mapped) == 16:
            found.append({'rpp_tileset': name, 'rpp_tile_ids': mapped})
    return found


def tileset_key(name):
    return name.removeprefix('TILESET_').lower()


def collision_labels(root, name, aliases=None):
    path = gold_source_path(root, name, 'Coll', aliases or {})
    if not path.is_file():
        return None, str(path.relative_to(root))
    return ([','.join(t.strip() for t in x.split(','))
             for x in TILECOLL.findall(path.read_text(encoding='utf-8'))],
            str(path.relative_to(root)))


def audit(gold, project):
    maps = layout_inventory(gold)
    gold_names = sorted({tileset_key(m['tileset']) for m in maps})
    gold_aliases = gold_resource_aliases(gold)
    rpp_names = sorted(p.stem for p in (project/'gfx/blocksets').glob('*.bst'))
    if not rpp_names:
        raise AuditError('RPP gfx/blocksets 目录中找不到 .bst')

    rpp_sets = {}
    per_tile = {}
    reverse = {k: defaultdict(list) for k in ('pixel_sha', 'pattern_sha', 'raw_sha')}
    for name in rpp_names:
        blocks, path, extra_bytes = blocks_for(project, name, 'rpp')
        tiles = load_png_tiles(project / 'gfx/tilesets' / f'{name}.png')
        entries = metatile_entries(blocks, tiles)
        tile_lookup = {'pixel': defaultdict(list), 'pattern': defaultdict(list)}
        if tiles is not None:
            for tile_id, bitmap in enumerate(tiles):
                tile_lookup['pixel'][sha(bitmap)].append(tile_id)
                tile_lookup['pattern'][sha(color_pattern(bitmap))].append(tile_id)
        per_tile[name] = tile_lookup
        rpp_sets[name] = {'blocks': path, 'png': f'gfx/tilesets/{name}.png' if tiles is not None else None,
                          'palette': f'color/tilesets/{name}.asm' if (project/'color/tilesets'/f'{name}.asm').is_file() else None,
                          'metatile_count': len(entries), 'art_errors': sum(bool(e['art_issue']) for e in entries),
                          'trailing_partial_bytes': extra_bytes}
        for entry in entries:
            for key in reverse:
                if entry[key]:
                    reverse[key][entry[key]].append((name, entry['id']))

    tile_reports = []
    summary = []
    gold_catalog = {}
    for name in gold_names:
        raw, path, extra_bytes = blocks_for(gold, name, 'gold', gold_aliases)
        tiles = load_png_tiles(gold/'gfx/tilesets'/f'{name}.png')
        collisions, coll_path = collision_labels(gold, name, gold_aliases)
        entries = metatile_entries(raw, tiles)
        gold_catalog[name] = entries
        totals = Counter()
        for entry in entries:
            category, hits = 'UNMATCHED', []
            if entry['pixel_sha']:
                hits = reverse['pixel_sha'].get(entry['pixel_sha'], [])
                if hits:
                    category = 'PIXEL_EXACT'
            if not hits and entry['pattern_sha']:
                hits = reverse['pattern_sha'].get(entry['pattern_sha'], [])
                if hits:
                    category = 'PATTERN_ONLY'
            # A missing complete 32x32 block may still be constructible from
            # sixteen already existing 8x8 RPP tiles. This is the key P1-3
            # reuse-first distinction. Never write the proposed new .bst here.
            composed = []
            if not hits:
                composed = compose_candidates(entry['bytes'], tiles, per_tile)
                if composed:
                    category = 'RECOMPOSE_8X8'
            if not hits and not composed:
                composed = compose_candidates(entry['bytes'], tiles, per_tile, by_shape=True)
                if composed:
                    category = 'RECOMPOSE_PATTERN_8X8'
            if not hits and not composed:
                hits = reverse['raw_sha'].get(entry['raw_sha'], [])
                if hits:
                    category = 'RAW_BYTES_ONLY'
            totals[category] += 1
            # same-named tilesets are a tie-break for presentation, not certification
            hits = sorted(hits, key=lambda p: (p[0] != name, p[0], p[1]))
            composed = sorted(composed, key=lambda p: (p['rpp_tileset'] != name, p['rpp_tileset']))
            candidates = composed if composed else [
                {'rpp_tileset': n, 'rpp_metatile_id': index} for n, index in hits]

            if collisions is None:
                coll = 'COLLISION_SOURCE_MISSING'
            elif len(collisions) != len(entries):
                coll = 'COLLISION_COUNT_MISMATCH'
            else:
                coll = 'NOT_RPP_VALIDATED'
            tile_reports.append({
                'gold_tileset': name, 'gold_metatile_id': entry['id'],
                'status': category, 'candidate_count': len(candidates),
                'candidates': candidates[:MAX_SUGGESTIONS],
                'gold_collision': collisions[entry['id']] if collisions and entry['id'] < len(collisions) else None,
                'collision_status': coll, 'gold_art_issue': entry['art_issue'],
                'raw_sha256': entry['raw_sha'],
            })
        summary.append({'gold_tileset': name, 'gold_metatiles': len(entries),
                        'gold_metatile_file': path, 'gold_collision_file': coll_path,
                        'gold_png_exists': tiles is not None,
                        'gold_collision_rows': len(collisions) if collisions is not None else None,
                        'registered_maps': sum(m['tileset'] == 'TILESET_'+name.upper() for m in maps),
                        'pixel_exact': totals['PIXEL_EXACT'],
                        'pattern_only': totals['PATTERN_ONLY'],
                        'recompose_8x8': totals['RECOMPOSE_8X8'],
                        'recompose_pattern_8x8': totals['RECOMPOSE_PATTERN_8X8'],
                        'raw_bytes_only': totals['RAW_BYTES_ONLY'],
                        'unmatched': totals['UNMATCHED'],
                        'coverage_note': 'Only graphical candidates; every collision needs RPP review.'})

    by_tileset_id = {(r['gold_tileset'], r['gold_metatile_id']): r for r in tile_reports}
    priority = []
    for m in maps:
        source = gold_catalog[tileset_key(m['tileset'])]
        if not source:
            raise AuditError(f"源区块集缺失，无法统计地图: {m['name']}")
        if m['blocks'] and max(m['blocks']) >= len(source):
            raise AuditError(f"地图 {m['name']} 使用超出区块集的 ID")
        freq = Counter(m['blocks'])
        statuses = Counter()
        unmatched = Counter()
        for block_id, used in freq.items():
            status = by_tileset_id[(tileset_key(m['tileset']), block_id)]['status']
            statuses[status] += used
            if status in ('UNMATCHED', 'RAW_BYTES_ONLY', 'RECOMPOSE_PATTERN_8X8'):
                unmatched[block_id] += used
        priority.append({'name': m['name'], 'gold_tileset': tileset_key(m['tileset']),
                         'source_layout': m['source_layout'],
                         'blocks_used': sum(freq.values()), 'unique_metatiles': len(freq),
                         'pixel_exact_cells': statuses['PIXEL_EXACT'],
                         'pattern_only_cells': statuses['PATTERN_ONLY'],
                         'recompose_8x8_cells': statuses['RECOMPOSE_8X8'],
                         'recompose_pattern_8x8_cells': statuses['RECOMPOSE_PATTERN_8X8'],
                         'raw_bytes_only_cells': statuses['RAW_BYTES_ONLY'],
                         'unmatched_cells': statuses['UNMATCHED'],
                         'priority_manual_ids': [f'${bid:02X}:{cnt}' for bid, cnt in unmatched.most_common(12)]})
    unrenderable_gold = sum(bool(r['gold_art_issue']) for r in tile_reports)
    rpp_missing_png = sum(v['png'] is None for v in rpp_sets.values())
    trailing_files = [n for n,v in rpp_sets.items() if v['trailing_partial_bytes']]
    return {'schema':'rpp-gold-asset-audit-v1', 'mode':'READ_ONLY_NOT_IMPORTABLE',
            'registered_maps': len(maps), 'gold_tilesets': len(gold_names),
            'rpp_blocksets': len(rpp_sets), 'gold_summary': summary,
            'diagnostics': {'gold_unrenderable_metatiles': unrenderable_gold,
                            'rpp_blocksets_without_png': rpp_missing_png,
                            'rpp_partial_trailing_files': trailing_files},
            'rpp_inventory': rpp_sets, 'metatiles': tile_reports, 'map_priority': priority,
            'warnings': [
                f'{unrenderable_gold} Gold metatiles have missing/out-of-range atlas tiles; no graphic match inferred from them.',
                f'{rpp_missing_png} RPP blocksets have no same-named PNG; they cannot provide pixel-verified matches.',
                f'Known RPP blocksets with residual partial block bytes: {trailing_files}. facility.bst has 1 trailing 00; interpretation in ROM not verified.',
                'PIXEL_EXACT only proves 32x32 RGBA equality with parsed source PNG; not collision or palette-bank equivalence.',
                'PATTERN_ONLY ignores actual colors: manual palette comparison required.',
                'RECOMPOSE_8X8 is only an art-composition candidate; check RPP bank, tile indices, and collision.',
                'RECOMPOSE_PATTERN_8X8 is shape-only and requires manual color matching.',
                'RAW_BYTES_ONLY is never proof of a valid graphics match.',
                'All Gold tilecoll fields require manual mapping to RPP collision/interaction rules.',
                'Atlas mapping assumes row-major 8x8 tiles; verify against engine graphic loading before applying.',
            ]}


def write_csv(path, rows, fields):
    with path.open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: (json.dumps(row.get(k), ensure_ascii=False, sort_keys=True)
                                 if isinstance(row.get(k), (list, dict)) else row.get(k)) for k in fields})


def emit(result, output):
    output.mkdir(parents=True, exist_ok=True)
    (output/'asset_audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    write_csv(output/'tileset_summary.csv', result['gold_summary'],
              ['gold_tileset','registered_maps','gold_metatiles','gold_metatile_file',
               'gold_png_exists','gold_collision_file','gold_collision_rows','pixel_exact','recompose_8x8','pattern_only','recompose_pattern_8x8','raw_bytes_only','unmatched'])
    write_csv(output/'metatile_matches.csv', result['metatiles'],
              ['gold_tileset','gold_metatile_id','status','candidate_count','candidates',
               'gold_collision','collision_status','gold_art_issue','raw_sha256'])
    write_csv(output/'map_material_priority.csv', result['map_priority'],
              ['name','gold_tileset','source_layout','blocks_used','unique_metatiles',
               'pixel_exact_cells','recompose_8x8_cells','pattern_only_cells','recompose_pattern_8x8_cells','raw_bytes_only_cells',
               'unmatched_cells','priority_manual_ids'])
    lines = ['# P1-3 金银 × RPP 素材复用候选报告', '',
             '**本报告仅供离线资源判断，不能直接导入地图、不能视为碰撞通过。**', '',
             f"- Gold 已注册地图：{result['registered_maps']}",
             f"- Gold 地图区块集：{result['gold_tilesets']}",
             f"- RPP 区块集：{result['rpp_blocksets']}",
             f"- Gold 贴图缺失/索引越界区块：{result['diagnostics']['gold_unrenderable_metatiles']}",
             f"- RPP 缺少同名 PNG 的区块集：{result['diagnostics']['rpp_blocksets_without_png']}",
             f"- RPP 存在残余字节的区块集：{', '.join(result['diagnostics']['rpp_partial_trailing_files']) or '无'}（原文件不改；需人工确认）", '',
             '| Gold 区块集 | 地图 | 像素相同 | 8×8 重组 | 图案候选 | 重组图案候选 | 仅编号相同 | 未找到 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for t in result['gold_summary']:
        lines.append(f"| {t['gold_tileset']} | {t['registered_maps']} | {t['pixel_exact']} | {t['recompose_8x8']} | {t['pattern_only']} | {t['recompose_pattern_8x8']} | {t['raw_bytes_only']} | {t['unmatched']} |")
    lines += ['', '## 优先地图（待人工核验）', '',
              '| 地图 | 图块集 | 未匹配格数 | 仅编号匹配格数 | 首要复核 ID |',
              '|---|---|---:|---:|---|']
    target = ['CherrygroveCity', 'Route30', 'Route31', 'VioletCity', 'NewBarkTown', 'Route29']
    lookup = {m['name']: m for m in result['map_priority']}
    for name in target:
        if name not in lookup:
            continue
        m = lookup[name]
        lines.append(f"| {name} | {m['gold_tileset']} | {m['unmatched_cells']} | {m['raw_bytes_only_cells']} | {', '.join(m['priority_manual_ids'][:5])} |")
    lines += ['', '## 分类和操作边界', '',
              '- `PIXEL_EXACT`：当前源 PNG 复合出的 32×32 RGBA 完全相同，但必须审核碰撞、调色板、地图可用的图块集与 bank。',
              '- `RECOMPOSE_8X8`：单套 RPP PNG 中能找到全部 16 个所需 8×8 贴图；可候选重组 RPP 新区块，需检查容量、调色板与碰撞。',
              '- `PATTERN_ONLY`：忽略颜色，仅证明完整区块图案形状相同，不能自动换素材。',
              '- `RECOMPOSE_PATTERN_8X8`：仅用忽略颜色的形状找到足够小图块，不能视为画面一致。',
              '- `RAW_BYTES_ONLY`：16 字节图块编号数组相同，**绝不代表图像相同**。',
              '- `UNMATCHED`：未找到上述候选；可能需要手工重组或增加 Gold 素材。',
              '- 解析 PNG 默认 8×8 图块按行排列，需要人工核对实际图块顺序与调色板。',
              '- 缺少 PNG 时可能退化为仅原始编号比较，详见 `gold_art_issue`。',
              '- Gold 共享 Meta/Coll 来源通过 `gfx/tilesets.asm` 标号解析；关联文件路径记录在 JSON 和摘要 CSV。',
              '- 仅对已知的 facility.bst 2049 字节、末尾 00 进行有告警的审计读取，不修改源文件；运行时含义未认证。',
              '- 无论是哪一类，都不自动标记碰撞可用。', '',
              '依次核对 `metatile_matches.csv`、`map_material_priority.csv` 与原地图屏幕效果，再决定对照映射。', '']
    (output/'00_审计摘要.md').write_text('\n'.join(lines), encoding='utf-8')


def main(argv=None):
    p = argparse.ArgumentParser(description='Gold 与 RPP 区块/图形复用离线审计，不写入游戏源码')
    p.add_argument('--gold-root', type=Path, required=True)
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args(argv)
    try:
        gold, project, output = safe_output(args.gold_root, args.project, args.output)
        result = audit(gold, project)
        emit(result, output)
    except (AuditError, ValueError, OSError) as e:
        p.exit(2, f'资源审计失败（源码未被修改）: {e}\n')
    print(f"READ_ONLY: Gold {result['registered_maps']} maps, {result['gold_tilesets']} tilesets; RPP {result['rpp_blocksets']} blocksets")
    print(f'报告目录: {output}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
