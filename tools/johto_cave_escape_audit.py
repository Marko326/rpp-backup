#!/usr/bin/env python3
"""Gold-backed two-entrance Union Cave Dig/Rope and legacy-blackout isolation.

This is NOT a simulation or ROM build: the audit pins branch ordering, state
separation, map identity, and a deterministic coordinate contract for review.
"""
import re
from pathlib import Path


def audit(root: Path, gold: Path) -> list[str]:
    errors = []
    try:
        items = (root / 'engine/items/items.asm').read_text()
        special = (root / 'engine/special_warps.asm').read_text()
        escape = (root / 'engine/overworld/johto_cave_escape.asm').read_text()
        main = (root / 'main.asm').read_text()
        manifest = (root / 'tools/johto_native_maps.json').read_text()
        route = (root / 'data/mapObjects/JohtoRoute32.asm').read_text()
        cave = (root / 'data/mapObjects/JohtoUnionCave1F.asm').read_text()
        route33 = (root / 'data/mapObjects/JohtoRoute33.asm').read_text()
        resolver = (root / 'engine/overworld/region_map_lookup.asm').read_text()
        gold_route = (gold / 'maps/Route32.asm').read_text()
        gold_cave = (gold / 'maps/UnionCave1F.asm').read_text()
        gold_map = (gold / 'home/map.asm').read_text()
        gold_move = (gold / 'engine/events/overworld.asm').read_text()
    except OSError as exc:
        return [f'missing Dig/Rope input: {exc}']
    # Only reviewed Gold Route32/33 mouths; B1F and unrelated caves remain closed.
    for name, expr, data in (
        ('Gold Route32 cave mouth', r'(?m)^\s*warp_event\s+6,\s*79,\s*UNION_CAVE_1F,\s*4\b', gold_route),
        ('Gold cave Route32 exit', r'(?m)^\s*warp_event\s+17,\s*3,\s*ROUTE_32,\s*4\b', gold_cave),
        ('Gold cave Route33 exit', r'(?m)^\s*warp_event\s+17,\s*31,\s*ROUTE_33,\s*1\b', gold_cave),
        ('Gold Route33 cave entrance', r'(?m)^\s*warp_event\s+11,\s*9,\s*UNION_CAVE_1F,\s*3\b', (gold / 'maps/Route33.asm').read_text()),
        ('Gold saves the entering warp', r'(?s)\.SaveDigWarp::.*?ld \[wDigWarpNumber\], a.*?ld \[wDigMapGroup\], a.*?ld \[wDigMapNumber\], a', gold_map),
        ('Gold Dig uses the saved warp', r'(?s)\.DoDig:.*?wDigWarpNumber.*?wNextWarp', gold_move),
        ('RPP outdoor cave Warp', r'(?m)^\s*db\s+79,\s*6,\s*0,\s*REGION_WARP_ESCAPE\b', route),
        ('RPP cave Route32 Warp', r'(?m)^\s*db\s+3,\s*17,\s*0,\s*REGION_WARP_ESCAPE\b', cave),
        ('RPP cave Route33 Warp', r'(?m)^\s*db\s+31,\s*17,\s*0,\s*REGION_WARP_ESCAPE\b', cave),
        ('RPP Route33 entry', r'(?m)^\s*db\s+9,\s*11,\s*1,\s*REGION_WARP_ESCAPE\b', route33),
        ('special Warp hook located before blackout selection', r'(?s)\.notFirstMap\s*\n\s*;[^\n]*\n\s*;[^\n]*\n\s*callba TryLoadJohtoUnionCaveEscapeWarp\s*\n\s*ld a, e[^\n]*\n\s*jp c, \.done[^\n]*\n\s*ld hl, wd732.*?ld a, \[wLastBlackoutMap\]', special),
        ('only native Johto maps enter new eligibility', r'(?s)CanUseEscapeRope::.*?cp REGION_NATIVE_MAP_SLOT\s*\n\s*jr nz,\.legacyTileset\s*\n\s*callba CanUseJohtoUnionCaveEscape\s*\n\s*ret\s*\n\.legacyTileset', items),
        ('old escape whitelist not widened', r'(?m)^\s*db FOREST,CEMETERY,INTERIOR,CAVERN,FACILITY,SAFARI,ICE_CAVERN,\$FF\s*$', items),
        ('banked helper registered', r'(?m)^INCLUDE "engine/overworld/johto_cave_escape.asm"$', main),
        ('safe Route32 return', r'(?m)^\s*FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 80, 6\s*$', escape),
        ('safe Route33 return', r'(?m)^\s*FLYWARP_DATA JOHTO_ROUTE_33_WIDTH, 10, 11\s*$', escape),
    ):
        if not re.search(expr, data):
            errors.append(name + ' not supported by source')

    eligible = escape.split('CanUseJohtoUnionCaveEscape::', 1)[-1].split('TryLoadJohtoUnionCaveEscapeWarp::', 1)[0]
    interceptor = escape.split('TryLoadJohtoUnionCaveEscapeWarp::', 1)[-1]
    for token in ('cp REGION_NATIVE_MAP_SLOT', 'cp MAP_REGION_JOHTO',
                  'cp JOHTO_UNION_CAVE_1F_LOCAL_ID', 'cp JOHTO_UNION_CAVE',
                  'cp REGION_STATE_MAGIC0', 'cp REGION_STATE_MAGIC1',
                  'scf', '.deny', 'and a'):
        if token not in eligible:
            errors.append('native cave identity guard missing: ' + token)
    for token in ('and (1 << 3) | (1 << 6)', 'cp (1 << 3) | (1 << 6)',
                  'call CanUseJohtoUnionCaveEscape', 'jr nc, .notOurWarp',
                  'res 6, [hl]', 'ld a, JOHTO_ROUTE_32', 'ld [wCurMap], a',
                  'ld [wDestinationMap], a', 'ld a, MAP_REGION_JOHTO',
                  'ld [wCurRegion], a', 'ld a, JOHTO_ROUTE_32_LOCAL_ID',
                  'ld [wCurLocalMapID], a', 'ld de, wCurrentTileBlockMapViewPointer',
                  'ld bc, 6', 'call CopyData', 'ld a, JOHTO',
                  'ld [wCurMapTileset], a', 'ld e, 0', '.notOurWarp', 'and a'):
        if token not in interceptor:
            errors.append('special Warp isolation or destination missing: ' + token)
    # Saved source-key is intentional now, but it must not use the healing
    # destination or unrelated scratch. Physical route33 must be exact FC+region+local.
    code = '\n'.join(line.split(';', 1)[0] for line in (eligible + interceptor).splitlines())
    if re.search(r'\bwLastBlackoutMap\b|\bwUnusedD71F\b', code):
        errors.append('cave escape reads healing or unrelated scratch return state')
    for item in ('ld a, [wLastMap]', 'cp REGION_NATIVE_MAP_SLOT', 'ld a, [wLastRegion]',
                 'ld a, [wLastLocalMapID]', 'cp JOHTO_ROUTE_33_LOCAL_ID',
                 'ld a, JOHTO_MODERN', 'ld a, JOHTO_ROUTE_32',
                 'ld a, JOHTO_ROUTE_33_LOCAL_ID'):
        if item not in interceptor:
            errors.append('dynamic safe escape source selection missing: ' + item)
    for item in ('RecordJohtoCaveEscapeSource::', 'push de', 'pop de',
                 'ld [wLastMap], a', 'ld [wLastLocalMapID], a',
                 'ld [wLastRegion], a', 'cp JOHTO_ROUTE_33_LOCAL_ID',
                 'cp JOHTO_ROUTE_32_LOCAL_ID', 'cp JOHTO_UNION_CAVE_1F_LOCAL_ID',
                 'cp 1 ; Gold cave third warp', 'call RecordJohtoCaveEscapeSource'):
        if item not in resolver:
            errors.append('verified source capture before native resolver missing: ' + item)
    # Validate the explicit capability scope independently of preflight.
    import json
    maps = json.loads(manifest)['maps']
    enabled = [m['local_id'] for m in maps
               if m['feature_status']['dig'] == 'ALLOWED'
               or m['feature_status']['escape_rope'] == 'ALLOWED']
    if enabled != [8]:
        errors.append('Dig/Rope capability scope is not exactly Union Cave 1F')
    return errors
