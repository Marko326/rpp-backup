#!/usr/bin/env python3
"""Reproducible fingerprints for offline Gold/RPP converter reports.

Hash the inspected inputs and staged output artifacts.  Nothing here patches or
compiles a ROM. A manifest match only proves that a report is not stale.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from johto_gold_sources import gold_block_sources
from johto_rpp_asset_audit import gold_resource_aliases, gold_source_path
from johto_indoor_common import ConversionError, dump, sha


def input_paths(rpp: Path, gold: Path, gold_room: str, rpp_room: str,
                outdoor: tuple[str, ...], reference_room: str,
                gold_tileset: str, rpp_tileset: str) -> dict:
    gold_layout = gold_block_sources(gold).get(gold_room)
    if not gold_layout:
        raise ConversionError(f'Gold 找不到地图布局: {gold_room}')
    rpp_files = [
        'main.asm', 'constants/map_constants.asm', 'data/warp_tile_ids.asm',
        'home/overworld.asm', 'engine/overworld/player_state.asm',
        f'gfx/blocksets/{rpp_tileset}.bst',
        f'gfx/tilesets/{rpp_tileset}.tilecoll',
        'constants/tilesets.asm', 'data/tileset_headers.asm',
        'color/data/map_palette_assignments.asm',
        'data/johto_map_headers.asm', 'data/map_header_pointers.asm',
        'data/map_header_banks.asm', f'color/tilesets/{rpp_tileset}.asm',
    ]
    for name in ('johto_indoor_pipeline', 'johto_indoor_manifest',
                 'johto_warp_reference_profiles', 'johto_native_warp_converter',
                 'johto_bidirectional_warp_validator', 'johto_indoor_common',
                 'johto_indoor_tiles_converter', 'johto_indoor_collision_adapter',
                 'johto_indoor_registration_generator', 'johto_indoor_resource_budget',
                 'johto_indoor_palette_vram_audit', 'johto_indoor_conversion_plan',
                 'johto_indoor_batch', 'johto_indoor_border_adapter',
                 'johto_indoor_release_audit', 'johto_rpp_asset_audit',
                 'johto_gold_sources'):
        rpp_files.append(f'tools/{name}.py')
    # Tools-only release: tests must be fingerprinted too; old reports cannot
    # claim a newer test suite merely because runtime sources match.
    rpp_files.extend(str(p.relative_to(rpp)) for p in sorted((rpp / 'tools/tests').glob('test_johto*.py')))
    for picture in (f'gfx/tilesets/{rpp_tileset}.png',
                    f'gfx/tilesets/{rpp_tileset}.t1.png'):
        if (rpp / picture).is_file():
            rpp_files.append(picture)
    for name in dict.fromkeys((reference_room, rpp_room, *outdoor)):
        rpp_files.extend((f'data/mapObjects/{name}.asm',
                          f'data/mapHeaders/{name}.asm'))
        # RPP can reuse a shared block label (e.g. Route15GateBlocks), so
        # maps/<header name>.blk is not necessarily a real source file.
        if (rpp / f'maps/{name}.blk').is_file():
            rpp_files.append(f'maps/{name}.blk')
    aliases = gold_resource_aliases(gold)
    meta = gold_source_path(gold, gold_tileset, 'Meta', aliases)
    collision = gold_source_path(gold, gold_tileset, 'Coll', aliases)
    gold_files = ['main.asm', 'constants/map_constants.asm',
                  'data/maps/maps.asm', 'data/maps/blocks.asm',
                  'gfx/tilesets.asm', f'maps/{gold_room}.asm', gold_layout,
                  f'gfx/tilesets/{gold_tileset}.png',
                  str(meta.relative_to(gold)), str(collision.relative_to(gold))]
    return {'rpp': sorted(set(rpp_files)), 'gold': sorted(set(gold_files))}


def fingerprints(base: Path, files: list[str]) -> dict:
    rows = {}
    for rel in files:
        path = base / rel
        if not path.is_file() or path.is_symlink():
            raise ConversionError(f'来源文件不存在或为符号链接: {path}')
        rows[rel] = sha(path.read_bytes())
    return rows


def generated_files(out: Path) -> dict:
    result = {}
    for file in sorted(out.rglob('*')):
        if file.is_symlink():
            raise ConversionError(f'产物包含符号链接: {file}')
        if file.is_file() and file.name != '07_source_manifest.json':
            result[str(file.relative_to(out))] = sha(file.read_bytes())
    return result


def create_manifest(rpp: Path, gold: Path, out: Path, *, gold_room: str,
                    rpp_room: str, outdoor: tuple[str, ...],
                    reference_room: str, gold_tileset: str,
                    rpp_tileset: str) -> dict:
    paths = input_paths(rpp, gold, gold_room, rpp_room, outdoor,
                        reference_room, gold_tileset, rpp_tileset)
    result = {'schema': 'johto-indoor-offline-manifest-v1',
              'purpose': 'FINGERPRINTS_ONLY_NOT_GAMEPLAY_APPROVAL',
              'configuration': {'gold_room': gold_room, 'rpp_room': rpp_room,
                                'outdoor': list(outdoor),
                                'reference_room': reference_room,
                                'gold_tileset': gold_tileset,
                                'rpp_tileset': rpp_tileset},
              'sources': {'rpp': fingerprints(rpp, paths['rpp']),
                          'gold': fingerprints(gold, paths['gold'])},
              'generated_files': generated_files(out)}
    dump(out, '07_source_manifest.json', result)
    return result


def verify_manifest(rpp: Path, gold: Path, out: Path) -> dict:
    path = out / '07_source_manifest.json'
    if not path.is_file() or path.is_symlink():
        raise ConversionError(f'没有可核验的 manifest: {path}')
    manifest = json.loads(path.read_text(encoding='utf-8'))
    if manifest.get('schema') != 'johto-indoor-offline-manifest-v1':
        raise ConversionError('manifest 版本不兼容')
    mismatches = []
    for label, base in (('rpp', rpp), ('gold', gold)):
        for rel, old_sha in manifest['sources'][label].items():
            file = base / rel
            if not file.is_file() or file.is_symlink() or sha(file.read_bytes()) != old_sha:
                mismatches.append(f'{label}:{rel}')
    output_now = generated_files(out)
    if output_now != manifest['generated_files']:
        mismatches.append('generated_files: added/removed/modified')
    return {'valid': not mismatches, 'mismatches': mismatches,
            'gameplay_tested': False}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp', required=True, type=Path)
    ap.add_argument('--gold', required=True, type=Path)
    ap.add_argument('--output', required=True, type=Path)
    args = ap.parse_args(argv)
    result = verify_manifest(args.rpp.resolve(), args.gold.resolve(),
                             args.output.resolve())
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result['valid'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
