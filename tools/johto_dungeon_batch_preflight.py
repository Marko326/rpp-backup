#!/usr/bin/env python3
"""Gold Johto dungeon semantic preflight for safe batch conversion.

This is deliberately read-only. It inventories the original Gold map layout,
collision roles, warp trigger semantics, palette/border requirements and
special movement mechanics BEFORE a dungeon is converted into RPP.

The purpose is to prevent the Union Cave mistakes from becoming a batch
conversion pattern: guessing collision filenames, treating UP_WALL as a solid
cell, conflating LADDER with directional carpets, preserving source XY across
same-tileset floor warps, hard-coding border $09, or assuming every cave uses
one fixed palette/mechanic set.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re

try:
    from johto_gold_compat import PROFILES, resolve_gold_root
    from johto_gold_door_audit import GoldCollisionIndex
    from johto_gold_tileset_semantics import resolve_tileset_resources
except ImportError:
    from tools.johto_gold_compat import PROFILES, resolve_gold_root
    from tools.johto_gold_door_audit import GoldCollisionIndex
    from tools.johto_gold_tileset_semantics import resolve_tileset_resources

DUNGEON_GROUPS = {
    'Union Cave': ('UnionCave1F', 'UnionCaveB1F', 'UnionCaveB2F'),
    'Slowpoke Well': ('SlowpokeWellB1F', 'SlowpokeWellB2F'),
    'Mount Mortar': ('MountMortar1FOutside', 'MountMortar1FInside',
                     'MountMortar2FInside', 'MountMortarB1F'),
    'Ice Path': ('IcePath1F', 'IcePathB1F', 'IcePathB2FMahoganySide',
                 'IcePathB2FBlackthornSide', 'IcePathB3F'),
    'Whirl Islands': ('WhirlIslandNW', 'WhirlIslandNE', 'WhirlIslandSW',
                      'WhirlIslandCave', 'WhirlIslandSE', 'WhirlIslandB1F',
                      'WhirlIslandB2F', 'WhirlIslandLugiaChamber'),
    'Dark Cave': ('DarkCaveVioletEntrance', 'DarkCaveBlackthornEntrance'),
    'Dragons Den': ('DragonsDen1F', 'DragonsDenB1F'),
    'Burned Tower': ('BurnedTower1F', 'BurnedTowerB1F'),
}

DIRECTIONAL_CARPETS = {
    'WARP_CARPET_DOWN': 'DOWN', 'WARP_CARPET_UP': 'UP',
    'WARP_CARPET_LEFT': 'LEFT', 'WARP_CARPET_RIGHT': 'RIGHT',
}
IMMEDIATE_WARPS = {
    'LADDER', 'STAIRCASE', 'STAIRCASE_73', 'CAVE', 'CAVE_74',
    'DOOR', 'DOOR_75', 'DOOR_79', 'DOOR_7D', 'WARP_PANEL', 'PIT', 'PIT_68',
}
SIDE_WALLS = {
    'UP_WALL', 'DOWN_WALL', 'LEFT_WALL', 'RIGHT_WALL',
    'UP_LEFT_WALL', 'UP_RIGHT_WALL', 'DOWN_LEFT_WALL', 'DOWN_RIGHT_WALL',
}
LEDGES = {
    'HOP_RIGHT', 'HOP_LEFT', 'HOP_UP', 'HOP_DOWN',
    'HOP_DOWN_RIGHT', 'HOP_DOWN_LEFT', 'HOP_UP_RIGHT', 'HOP_UP_LEFT',
}
FIELD = {'WATER', 'WATERFALL', 'WATERFALL_RIGHT', 'WATERFALL_LEFT',
         'WATERFALL_UP', 'WHIRLPOOL', 'ICE'}


def _read(path: Path) -> str:
    return path.read_text(encoding='utf-8', errors='replace')


def _metadata(gold: Path):
    maps = {}
    for line in _read(gold / 'data/maps/maps.asm').splitlines():
        m = re.match(r'^\s*map\s+(\w+),\s*(TILESET_\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(TRUE|FALSE),\s*(PALETTE_\w+),', line)
        if m:
            maps[m[1]] = {'tileset': m[2], 'environment': m[3],
                          'landmark': m[4], 'music': m[5], 'palette': m[7]}
    dims = {n: (int(w), int(h)) for n, w, h in re.findall(
        r'^\s*map_const\s+(\w+),\s*(\d+),\s*(\d+)',
        _read(gold / 'constants/map_constants.asm'), re.M)}
    attrs = {}
    for line in _read(gold / 'data/maps/attributes.asm').splitlines():
        m = re.match(r'^\s*map_attributes\s+(\w+),\s*(\w+),\s*\$([0-9a-fA-F]+),', line)
        if m:
            attrs[m[1]] = {'map_const': m[2], 'border_block': int(m[3], 16)}
    const_to_name = {v['map_const']: k for k, v in attrs.items()}
    return maps, dims, attrs, const_to_name


def _warp_events(gold: Path, map_name: str) -> list[dict]:
    text = _read(gold / 'maps' / f'{map_name}.asm')
    result = []
    for ordinal, m in enumerate(re.finditer(
            r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z0-9_]*)\s*,\s*(-?\d+)\b', text), 1):
        result.append({'ordinal': ordinal, 'x': int(m[1]), 'y': int(m[2]),
                       'destination_const': m[3], 'destination_warp': int(m[4])})
    return result


def _trigger(role: str) -> dict:
    if role in DIRECTIONAL_CARPETS:
        return {'kind': 'DIRECTIONAL_COLLISION', 'direction': DIRECTIONAL_CARPETS[role]}
    if role in IMMEDIATE_WARPS:
        return {'kind': 'STEP_IN_IMMEDIATE'}
    # Gold permits destination-only warp_event entries on ordinary/ledge cells
    # (Burned Tower B1F is the important example). Never turn these into a
    # source trigger merely because a warp_event record exists.
    return {'kind': 'ARRIVAL_ONLY_OR_SPECIAL_REVIEW'}


def _profile(meta: dict, counts: Counter) -> str:
    if counts['ICE'] or counts['PIT']:
        return 'ICE_OR_PIT_DUNGEON'
    if meta['palette'] == 'PALETTE_DARK':
        return 'FLASH_DARK_DUNGEON'
    if meta['tileset'] == 'TILESET_TOWER':
        return 'TOWER_INTERIOR'
    if meta['tileset'] == 'TILESET_JOHTO':
        return 'MIXED_JOHTO_CAVE'
    return 'STANDARD_CAVE'


def inspect(gold_root: Path) -> dict:
    gold = resolve_gold_root(gold_root)
    index = GoldCollisionIndex(gold)
    maps_meta, dims, attrs, const_to_name = _metadata(gold)
    errors = []
    groups = []
    for group, names in DUNGEON_GROUPS.items():
        rows = []
        for name in names:
            if name not in maps_meta or name not in attrs:
                errors.append(f'{name}: missing Gold map registration/attributes')
                continue
            const = attrs[name]['map_const']
            if const not in dims:
                errors.append(f'{name}: missing dimensions for {const}')
                continue
            cells = index.cells(name)
            counts = Counter(cell['role'] for cell in cells.values())
            resources = resolve_tileset_resources(gold, maps_meta[name]['tileset'])
            warps = []
            for w in _warp_events(gold, name):
                role = index.role_at(name, w['x'], w['y'])
                dest_name = const_to_name.get(w['destination_const'])
                same_tileset = bool(dest_name and dest_name in maps_meta and
                                    maps_meta[dest_name]['tileset'] == maps_meta[name]['tileset'])
                warps.append({**w, 'collision_role': role,
                              'trigger': _trigger(role),
                              'destination_map': dest_name,
                              'same_tileset_destination': same_tileset,
                              'destination_rebase_required': same_tileset})
            mechanics = {
                'directional_wall_cells': sum(counts[r] for r in SIDE_WALLS),
                'ledge_cells': sum(counts[r] for r in LEDGES),
                'water_cells': counts['WATER'],
                'waterfall_cells': sum(counts[r] for r in FIELD if r.startswith('WATERFALL')),
                'whirlpool_cells': counts['WHIRLPOOL'],
                'ice_cells': counts['ICE'],
                'pit_cells': counts['PIT'] + counts['PIT_68'],
                'requires_flash_palette': maps_meta[name]['palette'] == 'PALETTE_DARK',
                'fixed_nite_palette': maps_meta[name]['palette'] == 'PALETTE_NITE',
            }
            rows.append({
                'name': name,
                **maps_meta[name],
                'width_blocks': dims[const][0], 'height_blocks': dims[const][1],
                'border_block': attrs[name]['border_block'],
                'gold_metatiles': resources['metatiles'],
                'gold_collision_source': resources['collision'],
                'profile': _profile(maps_meta[name], counts),
                'mechanics': mechanics,
                'warp_events': warps,
                'collision_role_counts': dict(sorted(counts.items())),
            })
        groups.append({'group': group, 'maps': rows})
    # Non-vacuous source assertions for the exact classes that caused the
    # Union Cave regressions and for the important exceptions that prove caves
    # cannot share one hard-coded conversion profile.
    flat = {m['name']: m for g in groups for m in g['maps']}
    expected = {
        'SlowpokeWellB1F': ('TILESET_CAVE', 'PALETTE_NITE', 0x09),
        'MountMortar1FOutside': ('TILESET_DARK_CAVE', 'PALETTE_DARK', 0x09),
        'IcePathB1F': ('TILESET_ICE_PATH', 'PALETTE_NITE', 0x19),
        'WhirlIslandB2F': ('TILESET_DARK_CAVE', 'PALETTE_DARK', 0x2e),
        'DragonsDenB1F': ('TILESET_JOHTO', 'PALETTE_NITE', 0x71),
        'BurnedTowerB1F': ('TILESET_CAVE', 'PALETTE_DAY', 0x09),
    }
    for name, (tileset, pal, border) in expected.items():
        row = flat.get(name)
        if not row or (row['tileset'], row['palette'], row['border_block']) != (tileset, pal, border):
            errors.append(f'{name}: expected {(tileset, pal, border)}, got {None if not row else (row["tileset"], row["palette"], row["border_block"])}')
    if flat.get('SlowpokeWellB1F', {}).get('mechanics', {}).get('directional_wall_cells', 0) == 0:
        errors.append('SlowpokeWellB1F: expected directional wall semantics')
    if flat.get('MountMortar1FOutside', {}).get('mechanics', {}).get('waterfall_cells', 0) == 0:
        errors.append('MountMortar1FOutside: expected waterfall semantics')
    if flat.get('IcePathB1F', {}).get('mechanics', {}).get('pit_cells', 0) == 0:
        errors.append('IcePathB1F: expected pit semantics')
    if flat.get('DragonsDenB1F', {}).get('mechanics', {}).get('whirlpool_cells', 0) == 0:
        errors.append('DragonsDenB1F: expected whirlpool semantics')
    if not any(w['trigger']['kind'] == 'ARRIVAL_ONLY_OR_SPECIAL_REVIEW'
               for w in flat.get('BurnedTowerB1F', {}).get('warp_events', [])):
        errors.append('BurnedTowerB1F: expected destination-only/special warp entries')
    return {
        'schema': 'rpp-gold-johto-dungeon-preflight-v1',
        'mode': 'READ_ONLY_GOLD_SOURCE_AUDIT',
        'status': 'PASS' if not errors else 'FAIL',
        'errors': errors,
        'groups': groups,
        'conversion_rules': [
            'Resolve Meta/Coll through Gold Tileset labels; never infer filenames from TILESET_*.',
            'Preserve per-map border block; do not hard-code cave border $09.',
            'PALETTE_NITE is fixed dark styling; PALETTE_DARK requires Flash-aware darkness semantics.',
            'LADDER/PIT/CAVE/STAIRCASE are immediate step-in warps; WARP_CARPET_* is directional.',
            'warp_event on FLOOR/HOP/etc may be arrival-only; never synthesize a source trigger from the record alone.',
            'Same-tileset floor changes must rebuild destination XY (RPP DungeonTilesets or equivalent).',
            'UP_WALL/side walls are directional barriers, not whole-cell solids.',
            'HOP_* requires directional ledge behavior and safe landing, not a generic passable/solid bit.',
            'ICE, PIT, WATERFALL and WHIRLPOOL are separate mechanics and block batch activation until supported.',
        ],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--gold-root', required=True)
    ap.add_argument('--gold-profile', choices=PROFILES, default='auto')
    ap.add_argument('--json-out')
    args = ap.parse_args()
    gold = resolve_gold_root(Path(args.gold_root), args.gold_profile)
    result = inspect(gold)
    text = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if args.json_out:
        Path(args.json_out).write_text(text, encoding='utf-8')
    print(text, end='')
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
