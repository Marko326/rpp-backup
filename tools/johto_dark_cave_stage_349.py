#!/usr/bin/env python3
"""REF-349 immutable Gold Dark Cave assets, stage1 frozen + stage2 active gate."""
from __future__ import annotations

import argparse
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import re

CONTRACT = 'docs/REF349_DARK_CAVE_VIOLET_STAGE1.json'
MAP = 'DarkCaveVioletEntrance'
BLOCKS = 'maps/johto_pilot/DarkCaveVioletEntrance.gold.blk'
RUNTIME = 'maps/johto_pilot/DarkCaveVioletEntrance.runtime.blk'
COLL = 'data/johto_dark_cave_stage/cave_collision.gold.asm'
EVENTS = 'data/johto_dark_cave_stage/DarkCaveVioletEntrance.events.gold.asm'
GOLD_WARPS = [
    (3, 15, 'ROUTE_31', 3, 'WARP_CARPET_DOWN', 'DOWN'),
    (17, 1, 'DARK_CAVE_BLACKTHORN_ENTRANCE', 2, 'CAVE', 'STEP_IN'),
    (35, 33, 'ROUTE_46', 3, 'WARP_CARPET_DOWN', 'DOWN'),
]
EXPECTED_ROLES = {
    'FLOOR': 1002, 'WALL': 296, 'WATER': 64, 'UP_WALL': 41,
    'HOP_LEFT': 14, 'HOP_DOWN': 12, 'WARP_CARPET_DOWN': 10, 'CAVE': 1,
}
STAGED_FILES = {
    BLOCKS: 'maps/DarkCaveVioletEntrance.blk',
    'gfx/tilesets/johto_dark_cave_violet_gold.png': 'gfx/tilesets/dark_cave.png',
    'gfx/blocksets/johto_dark_cave_violet_gold.bst': 'data/tilesets/cave_metatiles.bin',
    EVENTS: 'maps/DarkCaveVioletEntrance.asm',
    COLL: 'data/tilesets/cave_collision.asm',
    'data/johto_dark_cave_stage/cave_palette_map.gold.asm': 'gfx/tilesets/cave_palette_map.asm',
}
# These are live execution/registration sources, not offline tools or staged sources.
LIVE_FENCE = [
    'main.asm', 'home.asm', 'data/johto_pilot_map_headers.asm',
    'data/johto_pilot_runtime_assets.asm', 'data/johto_stable_id_slots.asm',
    'engine/johto_pilot_runtime.asm', 'engine/johto_pilot_warp_tiles.asm',
    'engine/johto_violet_field_skills.asm',
]


def check(project: Path, gold_root: Path | None = None,
          overrides: dict[str, str | bytes] | None = None) -> list[str]:
    overrides = overrides or {}
    errors: list[str] = []
    def read(path: str) -> bytes:
        if path in overrides:
            raw = overrides[path]
            return raw.encode() if isinstance(raw, str) else raw
        return (project / path).read_bytes()
    def want(ok: bool, message: str) -> None:
        if not ok: errors.append(message)

    try:
        manifest = json.loads(read(CONTRACT))
        want(manifest.get('stage') in ('STAGED_INACTIVE','VIOLET_ROUTE31_ACTIVE'), 'manifest: unknown stage')
        want(manifest.get('palette') == 'PALETTE_DARK' and manifest.get('flash_required') is True,
             'manifest: requires Flash-aware DARK, not fixed NITE')
        want(manifest.get('stable_local_id') == 190, 'manifest: stable ID changed')
        want(manifest.get('gold_map_size_blocks') == [20, 18], 'manifest: map dimensions changed')
        want(manifest.get('border_block') == 9, 'manifest: cave border changed')
        active = manifest.get('stage') == 'VIOLET_ROUTE31_ACTIVE'
        want(len(manifest.get('gate', {})) == 7 and all(v is active for v in manifest.get('gate', {}).values()),
             'manifest: stage-specific gate flags drift')
        src = read(BLOCKS)
        run = read(RUNTIME)
        want(len(src) == 360 and run == src, 'Gold map / candidate runtime block mismatch')
        if len(src) != 360: return errors
        for path, gold_path in STAGED_FILES.items():
            raw = read(path)
            hash_expected = manifest['source_sha256'].get(path)
            want(hash_expected == sha256(raw).hexdigest(), f'{path}: frozen SHA-256 drift')
            if gold_root is not None:
                want(raw == (gold_root / gold_path).read_bytes(), f'{path}: Gold source bytes changed')
        tiles = read('gfx/blocksets/johto_dark_cave_violet_gold.bst')
        want(len(tiles) == 64 * 16, 'shared Gold Cave metatile count wrong')
        if len(tiles) == 64 * 16:
            used8 = {tiles[bid * 16 + i] for bid in src for i in range(16)}
            want(used8 and max(used8) < 65,
                 'Gold map uses an 8x8 tile ID removed by Makefile --trim-whitespace (65 tiles remain)')
        coll = read(COLL).decode()
        role_table = {}
        for line in coll.splitlines():
            m = re.search(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})\b', line)
            if m:
                role_table[int(m.group(2), 16)] = [x.strip() for x in m.group(1).split(',')]
        want(len(role_table) == 64 and all(len(q) == 4 for q in role_table.values()),
             'Gold cave collision table incomplete')
        if len(role_table) != 64: return errors
        def role(x: int, y: int) -> str:
            bid = src[(y // 2) * 20 + x // 2]
            return role_table[bid][(y % 2) * 2 + (x % 2)]
        counts = Counter(role(x, y) for y in range(36) for x in range(40))
        want(dict(counts) == EXPECTED_ROLES, f'Gold collision roles changed: {dict(counts)}')
        want(manifest.get('collision_roles') == EXPECTED_ROLES,
             'manifest: collision role count drift')
        special = json.loads(read('data/johto_dark_cave_stage/DarkCaveVioletEntrance.special_cells.json'))
        expected_special = {
            name: [[x, y] for y in range(36) for x in range(40) if role(x, y) == name]
            for name in ('UP_WALL', 'HOP_DOWN', 'HOP_LEFT', 'WATER', 'CAVE')
        }
        want(special.get('size_cells') == [40, 36] and
             special.get('coords_by_role') == expected_special,
             'Gold directional wall, ledge, Surf or cave coordinates changed')
        events = read(EVENTS).decode()
        warps = [
            (int(x), int(y), dest, int(index))
            for x, y, dest, index in re.findall(
                r'^\s*warp_event\s+(\d+),\s*(\d+),\s*([A-Z_0-9]+),\s*(\d+)\s*$',
                events, re.M)]
        want(len(warps) == 3, 'Gold event source must have exactly 3 warps')
        want([(x, y, dest, num) for x, y, dest, num, _, _ in GOLD_WARPS] == warps,
             'Gold warp ordinals/coordinates/destinations changed')
        for x, y, dest, num, expected, trigger in GOLD_WARPS:
            want(role(x, y) == expected,
                 f'Gold warp {dest} at ({x},{y}) must be {expected}, not {role(x,y)}')
        want([(w['x'],w['y'],w['destination'],w['destination_warp'],
               w['role'],w['activation']) for w in manifest.get('gold_warps', [])] == GOLD_WARPS,
             'manifest: warp contract changed')
        if active:
            live = read('engine/johto_pilot_runtime.asm').decode()
            want('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' in live,
                 'stage2: active ID190 missing')
            # Runtime topology is checked in stage2 auditor below.
        else:
            for path in LIVE_FENCE:
                body = read(path).decode()
                want('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' not in body,
                     f'{path}: ID190 prematurely registered in live runtime')
                want('johto_dark_cave_violet_gold' not in body and
                     'DarkCaveVioletEntrance.runtime.blk' not in body,
                     f'{path}: inactive cave art/map prematurely included')
            assets = read('data/johto_pilot_runtime_assets.asm').decode()
            want('NUM_JOHTO_ACTIVE_MAPS == 63' in assets, 'active map count changed before gate')
        fixed_ids = read('constants/johto_fixed_map_ids.asm').decode()
        want(re.search(r'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\s+EQU\s+190\b', fixed_ids)
             is not None, 'stable ID190 was changed')
    except (OSError, ValueError, KeyError, TypeError, IndexError) as exc:
        errors.append(f'could not inspect staged Gold cave: {exc}')
    return errors


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    ap.add_argument('--gold-root', type=Path, default=None)
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    errors = check(args.project.resolve(), args.gold_root.resolve() if args.gold_root else None)
    if errors:
        print('FAIL: Dark Cave Violet staged contract')
        for err in errors: print(' -', err)
        return 1
    print('PASS: Dark Cave Violet Gold immutable 20x18 / 1440 cells / 3 source warps / FLASH DARK')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
