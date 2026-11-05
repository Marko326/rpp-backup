#!/usr/bin/env python3
"""REF-345 Burned Tower Gold-to-RPP staging and fail-closed audit.

This tool does not enable either map or build ROMs. Run --stage only after
verifying the Gold source; --check compares the already tracked inputs to the
Gold reference and rejects premature entrance/PIT activation.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

try:
    from johto_gold_compat import resolve_gold_root
    from johto_gold_door_audit import GoldCollisionIndex
    from johto_dungeon_batch_preflight import _warp_events, _trigger
    from johto_gold_tileset_semantics import resolve_tileset_resources
except ImportError:
    from tools.johto_gold_compat import resolve_gold_root
    from tools.johto_gold_door_audit import GoldCollisionIndex
    from tools.johto_dungeon_batch_preflight import _warp_events, _trigger
    from tools.johto_gold_tileset_semantics import resolve_tileset_resources

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = Path('docs/REF345_BURNED_TOWER_GOLD_CONTRACT.json')
MAPS = {
    'BurnedTower1F': {
        'tileset': 'TILESET_TOWER', 'palette': 'PALETTE_DAY',
        'width': 10, 'height': 9, 'border': 0x00,
        'roles': {'PIT': 11, 'LADDER': 1, 'WARP_CARPET_DOWN': 2},
        'warp_count': 14, 'runtime_id': 177,
        'tileset_image': 'gfx/tilesets/johto_burned_tower_1f.png',
        'blockset': 'gfx/blocksets/johto_burned_tower_1f.bst',
        'palette_source': 'color/tilesets/johto_burned_tower_1f.gold_palette.asm',
    },
    'BurnedTowerB1F': {
        'tileset': 'TILESET_CAVE', 'palette': 'PALETTE_DAY',
        'width': 10, 'height': 9, 'border': 0x09,
        'roles': {'LADDER': 1, 'UP_WALL': 26, 'HOP_DOWN': 16,
                  'HOP_DOWN_LEFT': 1, 'HOP_LEFT': 8, 'HOP_RIGHT': 4},
        'warp_count': 6, 'runtime_id': 178,
        'tileset_image': 'gfx/tilesets/johto_burned_tower_b1f.png',
        'blockset': 'gfx/blocksets/johto_burned_tower_b1f.bst',
        'palette_source': 'color/tilesets/johto_burned_tower_b1f.gold_palette.asm',
    },
}


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def _map_source(path: Path, map_name: str) -> dict:
    idx = GoldCollisionIndex(path)
    conf = MAPS[map_name]
    maplist = (path / 'data/maps/maps.asm').read_text()
    attrs = (path / 'data/maps/attributes.asm').read_text()
    if not re.search(rf'^\s*map\s+{map_name},\s*{conf["tileset"]},[^\n]*\b{conf["palette"]}\b', maplist, re.M):
        raise ValueError(f'{map_name}: Gold tileset/palette changed')
    if not re.search(rf'^\s*map_attributes\s+{map_name},[^\n]*\${conf["border"]:02x}\b', attrs, re.M | re.I):
        raise ValueError(f'{map_name}: Gold border changed')
    blk = (path / 'maps' / f'{map_name}.blk').read_bytes()
    if len(blk) != conf['width'] * conf['height']:
        raise ValueError(f'{map_name}: block dimensions changed')
    info = resolve_tileset_resources(path, conf['tileset'])
    meta = (path / info['metatiles']).read_bytes()
    if len(meta) % 16 or max(blk) >= len(meta) // 16:
        raise ValueError(f'{map_name}: metatile index invalid')
    source_tileset = 'tower' if map_name == 'BurnedTower1F' else 'cave'
    image = (path / 'gfx/tilesets' / f'{source_tileset}.png').read_bytes()
    palette = (path / 'gfx/tilesets' / f'{source_tileset}_palette_map.asm').read_bytes()
    # Gold block format and RPP .bst are both 16 eight-by-eight tile IDs.
    # Exact identities make pixel translation bijective, with no tile remapping.
    if max(meta[block * 16 + quadrant] for block in blk for quadrant in range(16)) >= 96:
        raise ValueError(f'{map_name}: *used* Gold art exceeds 96-tile RPP tileset capacity')
    cells = idx.cells(map_name)
    role_counts = Counter(c['role'] for c in cells.values())
    for name, n in conf['roles'].items():
        if role_counts[name] != n:
            raise ValueError(f'{map_name}: {name} changed: {role_counts[name]} vs {n}')
    ordered_roles = tuple(sorted(role_counts))
    role_bytes = bytes(ordered_roles.index(cells[x, y]['role']) for y in range(conf['height'] * 2) for x in range(conf['width'] * 2))
    events = []
    for w in _warp_events(path, map_name):
        role = idx.role_at(map_name, w['x'], w['y'])
        events.append({**w, 'role': role, 'trigger': _trigger(role)['kind']})
    if len(events) != conf['warp_count']:
        raise ValueError(f'{map_name}: Gold Warp cardinality changed')
    return {
        'name': map_name,
        'width': conf['width'], 'height': conf['height'],
        'gold_tileset': conf['tileset'], 'gold_palette': conf['palette'],
        'gold_border': conf['border'],
        'roles': list(ordered_roles), 'role_counts': dict(sorted(role_counts.items())),
        'warp_events': events,
        'sha256': {'layout': sha(blk), 'metatiles': sha(meta), 'image': sha(image), 'palette_source': sha(palette), 'rolegrid': sha(role_bytes)},
    }, {
        f'maps/johto_pilot/{map_name}.gold.blk': blk,
        f'maps/johto_pilot/{map_name}.runtime.blk': blk,
        f'maps/johto_pilot/{map_name}.gold_roles.bin': role_bytes,
        conf['blockset']: meta,
        conf['tileset_image']: image,
        conf['palette_source']: palette,
    }


def _contract(gold: Path):
    manifest = {'schema': 'rpp-ref345-burned-tower-staging-v1',
                'status': 'RESOURCES_ONLY_NOT_REGISTERED',
                'game_version_unchanged': 'REF-344',
                'maps': []}
    files = {}
    for name in MAPS:
        entry, assets = _map_source(gold, name)
        manifest['maps'].append(entry)
        files.update(assets)
    first, basement = manifest['maps']
    # Gold 1F has two DOWN-only exit carpets, 11 PITs and one ladder.
    if ([w['role'] for w in first['warp_events']].count('PIT') != 11 or
            [w['role'] for w in first['warp_events']].count('LADDER') != 1 or
            [w['role'] for w in first['warp_events']].count('WARP_CARPET_DOWN') != 2):
        raise ValueError('BurnedTower1F: unsafe PIT/ladder/carpet trigger inventory')
    # B1F ordinals 1..5 are destination-only! A generic register-all-Warps
    # converter would teleport players upward by walking on ordinary floor.
    if [w['trigger'] for w in basement['warp_events']] != [
            'ARRIVAL_ONLY_OR_SPECIAL_REVIEW'] * 5 + ['STEP_IN_IMMEDIATE']:
        raise ValueError('BurnedTowerB1F: destination-only warp must not be an exit')
    if [w['role'] for w in basement['warp_events']] != [
            'FLOOR', 'HOP_LEFT', 'HOP_DOWN', 'FLOOR', 'FLOOR', 'LADDER']:
        raise ValueError('BurnedTowerB1F: Gold warp landing roles changed')
    return manifest, files


def _require_closed(root: Path) -> list[str]:
    errors = []
    constants = (root / 'constants/region_map_constants.asm').read_text()
    m = re.search(r'^DEF NUM_JOHTO_ACTIVE_MAPS EQU (\d+)', constants, re.M)
    if not m or int(m[1]) != 61:
        errors.append('activity count changed: REF345 staging must remain at 61')
    slots = (root / 'data/johto_stable_id_slots.asm').read_text()
    row = next((x for x in slots.splitlines() if '; $b0-$bf' in x), '')
    values = [v.strip() for v in re.search(r'\bdb\s+([^;]+)', row)[1].split(',')] if re.search(r'\bdb\s+([^;]+)', row) else []
    if len(values) != 16 or values[1:3] != ['JOHTO_INVALID_ACTIVE_SLOT'] * 2:
        errors.append('Burned Tower stable IDs 177/178 must remain inactive')
    portal = (root / 'engine/johto_pilot_runtime.asm').read_text()
    section = portal.split('JohtoRegisteredWarpRoutes::', 1)
    if len(section) < 2:
        errors.append('registered Warp route table missing')
    elif re.search(r'\bJOHTO_BURNED_TOWER_(?:1F|B1F)_LOCAL_ID\b', section[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]):
        errors.append('Burned Tower Warp is prematurely registered')
    version = (root / 'data/game_version.asm').read_text()
    if 'db "REF-344@"' not in version:
        errors.append('staging must not change in-ROM game version')
    return errors


def verify(gold: Path, root: Path = ROOT) -> list[str]:
    expected, files = _contract(gold)
    errors = _require_closed(root)
    if not (root / CONTRACT).exists():
        errors.append(f'missing {CONTRACT}')
    else:
        try:
            actual = json.loads((root / CONTRACT).read_text())
            if actual != expected:
                errors.append('frozen Gold map semantics/warp contract mismatch')
        except (ValueError, OSError) as exc:
            errors.append(f'bad contract: {exc}')
    for name, data in files.items():
        p = root / name
        if not p.is_file() or p.read_bytes() != data:
            errors.append(f'{name}: not byte-identical to Gold / role grid')
    return errors


def run(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gold-root', required=True, type=Path, help='extracted pokegold source')
    ap.add_argument('--root', default=ROOT, type=Path, help='RPP source root')
    ap.add_argument('--stage', action='store_true', help='create the RPP staging files (never register maps)')
    ns = ap.parse_args(argv)
    try:
        gold = resolve_gold_root(ns.gold_root)
        expected, files = _contract(gold)
        if ns.stage:
            if _require_closed(ns.root):
                raise ValueError('refuse to stage when Burned Tower is already active')
            files[str(CONTRACT)] = (json.dumps(expected, indent=2, ensure_ascii=False) + '\n').encode()
            for name, raw in files.items():
                p = ns.root / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(raw)
        problems = verify(gold, ns.root)
    except (ValueError, FileNotFoundError, KeyError, AssertionError) as e:
        print('REF345 FAIL:', e)
        return 1
    if problems:
        for problem in problems:
            print('REF345 FAIL:', problem)
        return 1
    print('REF345 PASS_STATIC_ONLY: 2 Gold floors, 720 collision cells, 20 warp records; maps remain closed')
    return 0


if __name__ == '__main__':
    raise SystemExit(run())
