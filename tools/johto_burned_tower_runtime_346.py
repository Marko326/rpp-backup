#!/usr/bin/env python3
"""REF-346: prepare audited Burned Tower runtime assets/route templates.

Fail closed: never edit the active map, tileset, Warp or game-version registries.
The generated ASM is an unlinked integration candidate, not a live cave.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re

try:
    import johto_burned_tower_345 as stage
except ImportError:
    from tools import johto_burned_tower_345 as stage

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = Path('docs/REF345_BURNED_TOWER_GOLD_CONTRACT.json')
PLAN = Path('docs/REF346_BURNED_TOWER_ROUTE_PLAN.json')
CANDIDATE = Path('data/johto_burned_tower/REF346_runtime_candidate.asm')
ROUTES = Path('data/johto_burned_tower/REF346_routes_candidate.asm')

FLOORS = ('BurnedTower1F', 'BurnedTowerB1F')
ALIASES = ('1F', 'B1F')
PREFIXES = ('JohtoBurnedTower1F', 'JohtoBurnedTowerB1F')
LOCAL_IDS = ('JOHTO_BURNED_TOWER_1F_LOCAL_ID', 'JOHTO_BURNED_TOWER_B1F_LOCAL_ID')
TILESET_IDS = ('JOHTO_BURNED_TOWER_1F', 'JOHTO_BURNED_TOWER_B1F')
STAGING = ('johto_burned_tower_1f', 'johto_burned_tower_b1f')
# Original Gold palette semantics: both floors PALETTE_DAY, *not* Union Cave NITE.
# The used Gold blocks reference only BROWN/RED/GRAY (no WATER/BLUE tiles).
WALKABLE_ROLE = frozenset({'FLOOR', 'LADDER', 'WARP_CARPET_DOWN'})
ARRIVAL_ROLE = ('FLOOR', 'HOP_LEFT', 'HOP_DOWN', 'FLOOR', 'FLOOR')


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read(root: Path, name: str) -> bytes:
    return (root / name).read_bytes()


def _palette_families(raw: str) -> list[str]:
    entries = []
    for line in raw.splitlines():
        m = re.fullmatch(r'\s*tilepal\s+0,\s*([A-Z_,\s]+)\s*', line)
        if not m:
            raise ValueError('Gold tilepal changed/contains unsupported syntax')
        vals = [x.strip() for x in m[1].split(',')]
        if len(vals) != 8:
            raise ValueError('Gold tilepal must encode 8 palette families')
        entries.extend(vals)
    if len(entries) != 96:
        raise ValueError(f'Gold tilepal family length {len(entries)} != 96')
    return entries


def build_plan(root: Path = ROOT) -> dict:
    source = json.loads((root / CONTRACT).read_text())
    if source['schema'] != 'rpp-ref345-burned-tower-staging-v1':
        raise ValueError('unknown REF345 Gold data schema')
    if tuple(m['name'] for m in source['maps']) != FLOORS:
        raise ValueError('Gold floor order changed')
    if stage._require_closed(root):
        raise ValueError('not safe to prepare: REF345 fail-closed registry changed')

    floors = []
    for m, alias, name in zip(source['maps'], ALIASES, STAGING):
        roles = m['roles']
        roledata = _read(root, f'maps/johto_pilot/{m["name"]}.gold_roles.bin')
        blockmap = _read(root, f'maps/johto_pilot/{m["name"]}.gold.blk')
        meta = _read(root, f'gfx/blocksets/{name}.bst')
        pal_raw = _read(root, f'color/tilesets/{name}.gold_palette.asm')
        families = _palette_families(pal_raw.decode('ascii'))
        if len(roledata) != 360 or len(blockmap) != 90 or len(meta) != 1024:
            raise ValueError(f'{alias}: wrong Gold sizes')
        if sha(blockmap) != m['sha256']['layout'] or sha(roledata) != m['sha256']['rolegrid']:
            raise ValueError(f'{alias}: Gold layout or role grid changed')
        if sha(meta) != m['sha256']['metatiles'] or sha(pal_raw) != m['sha256']['palette_source']:
            raise ValueError(f'{alias}: Gold meta/palettes changed')
        if max(meta[b * 16 + q] for b in blockmap for q in range(16)) >= 96:
            raise ValueError(f'{alias}: runtime needs more than 96 tiles')
        if Counter(roles[i] for i in roledata) != m['role_counts']:
            raise ValueError(f'{alias}: Gold role counts changed')

        # In a 32x32 metatile there are 4x4 8x8 graphics; each 16x16
        # collision role covers exactly 2x2 of these. A reused art tile may
        # have multiple roles; only wholly safe IDs belong in the fallback
        # RPP whitelist. Spatial role logic must govern the other cells.
        tile_roles = defaultdict(set)
        for y in range(18):
            for x in range(20):
                block = blockmap[(y // 2) * 10 + x // 2]
                role = roles[roledata[y * 20 + x]]
                for yy in range(2):
                    for xx in range(2):
                        q = ((y % 2) * 2 + yy) * 4 + (x % 2) * 2 + xx
                        tile_roles[meta[block * 16 + q]].add(role)
        safe_tiles = sorted(t for t, r in tile_roles.items() if r <= WALKABLE_ROLE)
        used_families = Counter({fam: sum(families[t] == fam for t in tile_roles)
                                 for fam in sorted({families[t] for t in tile_roles})})
        if not set(used_families) <= {'BROWN', 'RED', 'GRAY'}:
            raise ValueError(f'{alias}: DAY palette needs other family: {used_families}')
        floors.append({'name': m['name'], 'role_order': roles,
                       'width_cells': 20, 'height_cells': 18,
                       'role_counts': m['role_counts'],
                       'fallback_passable_tile_ids': safe_tiles,
                       'ambiguous_tile_ids': sorted(t for t, r in tile_roles.items() if len(r) > 1),
                       'used_palette_families': dict(used_families),
                       'asset_sha256': {'layout': sha(blockmap), 'rolegrid': sha(roledata),
                                        'metatiles': sha(meta), 'palette': sha(pal_raw)},
                       'warp_events': m['warp_events']})

    first, basement = floors
    assert first['role_counts']['PIT'] == 11
    assert basement['role_counts']['UP_WALL'] == 26
    assert sum(basement['role_counts'][r] for r in basement['role_counts'] if r.startswith('HOP')) == 29
    if len(first['warp_events']) != 14 or len(basement['warp_events']) != 6:
        raise ValueError('Gold ordinal count changed')
    if tuple(w['role'] for w in basement['warp_events'][:5]) != ARRIVAL_ROLE:
        raise ValueError('B1F first five warp slots must stay arrival-only')
    if any(w['trigger'] != 'ARRIVAL_ONLY_OR_SPECIAL_REVIEW' for w in basement['warp_events'][:5]):
        raise ValueError('B1F arrival-only falsely marked as return warp')
    if basement['warp_events'][5]['role'] != 'LADDER':
        raise ValueError('B1F final warp must be an active ladder')
    if any(w['role'] != 'PIT' for w in first['warp_events'][2:13]):
        raise ValueError('Gold 11 PIT ordinals changed')
    if first['warp_events'][13]['role'] != 'LADDER':
        raise ValueError('Gold first floor ladder changed')

    # All 11 PIT triggers point at exactly five B1F *arrival* records;
    # source ordinals in project runtime arrays are zero-based. The B1F
    # five arrival records must never be registered as outgoing routes.
    route = []
    for w in first['warp_events']:
        ordinal = w['ordinal'] - 1
        if w['destination_const'] == 'ECRUTEAK_CITY':
            dest_ordinal = 5  # planned appended city Warp; five existing entries
            dest = 'EcruteakCity'
        else:
            dest_ordinal = w['destination_warp'] - 1
            dest = 'BurnedTowerB1F'
        route.append({'source': 'BurnedTower1F', 'ordinal': ordinal,
                      'x': w['x'], 'y': w['y'],
                      'role': w['role'], 'trigger': w['trigger'],
                      'destination': dest, 'destination_ordinal': dest_ordinal})
    for w in basement['warp_events']:
        route.append({'source': 'BurnedTowerB1F', 'ordinal': w['ordinal'] - 1,
                      'x': w['x'], 'y': w['y'],
                      'role': w['role'], 'trigger': w['trigger'],
                      'destination': 'BurnedTower1F',
                      'destination_ordinal': w['destination_warp'] - 1})

    pit = [r for r in route if r['role'] == 'PIT']
    if len(pit) != 11:
        raise ValueError('Gold PIT cardinality changed')
    if any(not 0 <= r['destination_ordinal'] < 5 for r in pit):
        raise ValueError('PIT would land on the returning ladder or outside 5 safe arrival slots')
    if sorted(set(r['destination_ordinal'] for r in pit)) != [0, 1, 2, 3, 4]:
        raise ValueError('PIT routes do not cover exactly 5 Gold arrival locations')
    for r in pit:
        landing = basement['warp_events'][r['destination_ordinal']]
        if landing['role'] == 'LADDER':
            raise ValueError('PIT would land on the returning ladder')
    if (first['warp_events'][13]['destination_warp'] - 1) != 5:
        raise ValueError('1F ladder does not point to B1F ladder')
    if basement['warp_events'][5]['destination_warp'] - 1 != 13:
        raise ValueError('B1F ladder does not point to 1F ladder')

    return {'schema': 'rpp-ref346-burned-tower-inactive-runtime-v1',
            'base_git_head': '02a65db8343abb34cae9edbb2d23fe73d9da9578',
            'active': False, 'game_version': 'REF-344',
            'active_maps': 61, 'registered_warps': 144,
            'planned_maps_after_activation': 63, 'planned_warps_after_activation': 160,
            'ecruteak_new_entrance': {'x': 5, 'y': 5, 'source_ordinal': 5,
                                      'destination': 'BurnedTower1F', 'destination_ordinal': 0},
            'floor_resources': floors, 'warp_candidate_records': route,
            'pit_to_arrival': [{'source_ordinal': r['ordinal'], 'source_xy': [r['x'], r['y']],
                                'target_ordinal': r['destination_ordinal'],
                                'target_xy': [basement['warp_events'][r['destination_ordinal']]['x'],
                                              basement['warp_events'][r['destination_ordinal']]['y']]}
                               for r in pit],
            'activation_blockers': [
                'implement spatial wall/UP_WALL/HOP collision including boulder movement',
                'hook exact PIT step-in and no standing retrigger, plus Gold fall animation',
                'register both tile sets and DAY palettes without Kanto color regressions',
                'register city entrance and 1F/B1F target ordinals, never five arrival-only as triggers',
                'check new Red/Blue/TEST MAP and ROM0 >=64 bytes, then phone/old-save tests',
            ]}


def make_candidate(plan: dict, root: Path = ROOT) -> dict[str, bytes]:
    files = {}
    # The first-stage Gold tile palettes are already in the runtime tilepal
    # macro format. They cannot use the Union Cave's NITE palette-set indices.
    for name in STAGING:
        files[f'color/tilesets/{name}.asm'] = _read(root, f'color/tilesets/{name}.gold_palette.asm')

    lines = ['; REF-346 UNLINKED candidate; do not INCLUDE until PIT + role logic is tested.',
             '; Exact Gold art and blockset: two distinct DAY tilesets, not Union Cave NITE.']
    for alias, prefix, tile, name, floor, border in zip(ALIASES, PREFIXES, TILESET_IDS, STAGING,
                                                        plan['floor_resources'], (0, 9)):
        lines += ['', f'{prefix}_GFX:: INCBIN "gfx/tilesets/{name}.2bpp"',
                  f'{prefix}_Block:: INCBIN "gfx/blocksets/{name}.bst"',
                  f'{prefix}_BlockEnd::',
                  f'ASSERT {prefix}_BlockEnd - {prefix}_Block == 64 * 16',
                  f'{prefix}RuntimeBlocks:: INCBIN "maps/johto_pilot/{floor["name"]}.runtime.blk"',
                  f'{prefix}RuntimeBlocksEnd::',
                  f'ASSERT {prefix}RuntimeBlocksEnd - {prefix}RuntimeBlocks == 10 * 9',
                  f'{prefix}RuntimeHeader::',
                  f'    db {tile} ; proposed tileset index; not yet registered',
                  '    db 9, 10',
                  f'    dw {prefix}RuntimeBlocks',
                  f'    dw {prefix}TextPointers',
                  f'    dw {prefix}Script',
                  '    db 0 ; no cardinal map connection',
                  f'    dw {prefix}RuntimeObjects',
                  f'{prefix}RuntimeHeaderEnd::',
                  f'ASSERT {prefix}RuntimeHeaderEnd - {prefix}RuntimeHeader == 12',
                  f'ASSERT BANK({prefix}RuntimeHeader) == BANK({prefix}RuntimeBlocks)',
                  f'{prefix}Script::', '    call EnableAutoTextBoxDrawing', '    ret',
                  f'{prefix}TextPointers:', f'{prefix}RuntimeObjects::',
                  f'    db ${border:02x} ; Gold border metatile',
                  f'    db {len(floor["warp_events"])} ; preserve all Gold ordinals']
        for r in plan['warp_candidate_records']:
            if r['source'] != floor['name']:
                continue
            tag = 'ARRIVAL ONLY; never register as source' if r['trigger'].startswith('ARRIVAL') else r['role']
            lines.append(f'    db {r["y"]}, {r["x"]}, {r["destination_ordinal"]}, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal {r["ordinal"]}: {tag}')
        lines += ['    db 0 ; deferred signs/NPC dialogue',
                  '    db 0' if alias == '1F' else '    db 1 ; Gold (17,4) Strength boulder, existing RBY engine']
        if alias == 'B1F':
            lines += ['    object SPRITE_BOULDER, 17, 4, STAY, BOULDER_MOVEMENT_BYTE_2, $1']
    files[str(CANDIDATE)] = ('\n'.join(lines) + '\n').encode('utf-8')

    route = ['; REF-346 unlinked proposed route rows; original 144 remain unchanged.',
             '; First append Ecruteak ordinal5, then the 14 1F warps and only B1F ladder5.',
             '; Critically B1F ordinals0..4 are arrival destinations, NOT source routes.',
             '    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 5, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID']
    for r in plan['warp_candidate_records']:
        if r['trigger'] == 'ARRIVAL_ONLY_OR_SPECIAL_REVIEW':
            continue
        local = 'JOHTO_BURNED_TOWER_1F_LOCAL_ID' if r['source'] == 'BurnedTower1F' else 'JOHTO_BURNED_TOWER_B1F_LOCAL_ID'
        dest = 'JOHTO_ECRUTEAK_CITY_LOCAL_ID' if r['destination'] == 'EcruteakCity' else ('JOHTO_BURNED_TOWER_B1F_LOCAL_ID' if r['destination'] == 'BurnedTowerB1F' else 'JOHTO_BURNED_TOWER_1F_LOCAL_ID')
        route.append(f'    db MAP_REGION_JOHTO, {local}, {r["ordinal"]}, MAP_REGION_JOHTO, {dest} ; {r["role"]}')
    assert len(route) - 3 == 16
    files[str(ROUTES)] = ('\n'.join(route) + '\n').encode('utf-8')

    files[str(PLAN)] = (json.dumps(plan, indent=2, ensure_ascii=False) + '\n').encode('utf-8')
    return files


def verify(root: Path = ROOT, gold: Path | None = None) -> list[str]:
    errors = []
    try:
        plan = build_plan(root)
        generated = make_candidate(plan, root)
    except (ValueError, KeyError, AssertionError, FileNotFoundError) as e:
        return [f'Gold source/runtime contract invalid: {e}']
    for rel, raw in generated.items():
        p = root / rel
        if not p.is_file() or p.read_bytes() != raw:
            errors.append(f'{rel}: candidate differs from audited generation')
    if gold is not None:
        try:
            errors += stage.verify(stage.resolve_gold_root(gold), root)
        except (ValueError, FileNotFoundError) as e:
            errors.append(f'Gold reference rejected: {e}')
    # The candidate is deliberately not imported into main.asm or any runtime
    # header/tileset tables. It MUST NOT advertise a playable cave.
    imported = ('INCLUDE "data/johto_burned_tower/REF346_runtime_candidate.asm"' in
                (root / 'main.asm').read_text())
    if imported:
        errors.append('unreviewed runtime candidate was accidentally linked')
    if 'REF-344@' not in (root / 'data/game_version.asm').read_text():
        errors.append('project in-ROM version changed without tower activation')
    return errors


def run(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--root', type=Path, default=ROOT)
    ap.add_argument('--gold-root', type=Path)
    ap.add_argument('--prepare', action='store_true')
    ns = ap.parse_args(argv)
    try:
        if ns.prepare:
            files = make_candidate(build_plan(ns.root), ns.root)
            for name, data in files.items():
                p = ns.root / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(data)
        errors = verify(ns.root, ns.gold_root)
    except (ValueError, KeyError, AssertionError, FileNotFoundError) as e:
        errors = [str(e)]
    for err in errors:
        print('REF346 FAIL:', err)
    if not errors:
        print('REF346 PASS_STATIC_ONLY: 2 independent DAY palettes; 14+6 stable warp slots; 11 PIT -> 5 landings; five arrival-only; closed runtime')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(run())
