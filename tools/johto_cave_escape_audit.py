#!/usr/bin/env python3
"""Static Gold-backed contract for a single-entry Union Cave Dig/Rope pilot.

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
        gold_route = (gold / 'maps/Route32.asm').read_text()
        gold_cave = (gold / 'maps/UnionCave1F.asm').read_text()
        gold_map = (gold / 'home/map.asm').read_text()
        gold_move = (gold / 'engine/events/overworld.asm').read_text()
    except OSError as exc:
        return [f'missing Dig/Rope input: {exc}']
    # No second entrance, no optional floor, no different source Warp contract.
    for name, expr, data in (
        ('Gold Route32 cave mouth', r'(?m)^\s*warp_event\s+6,\s*79,\s*UNION_CAVE_1F,\s*4\b', gold_route),
        ('Gold cave Route32 exit', r'(?m)^\s*warp_event\s+17,\s*3,\s*ROUTE_32,\s*4\b', gold_cave),
        ('Gold saves the entering warp', r'(?s)\.SaveDigWarp::.*?ld \[wDigWarpNumber\], a.*?ld \[wDigMapGroup\], a.*?ld \[wDigMapNumber\], a', gold_map),
        ('Gold Dig uses the saved warp', r'(?s)\.DoDig:.*?wDigWarpNumber.*?wNextWarp', gold_move),
        ('RPP outdoor cave Warp', r'(?m)^\s*db\s+79,\s*6,\s*0,\s*REGION_WARP_ESCAPE\b', route),
        ('RPP cave return Warp', r'(?m)^\s*db\s+3,\s*17,\s*0,\s*REGION_WARP_ESCAPE\b', cave),
        ('special Warp hook located before blackout selection', r'(?s)\.notFirstMap\s*\n\s*;[^\n]*\n\s*;[^\n]*\n\s*callba TryLoadJohtoUnionCaveEscapeWarp\s*\n\s*ld a, e[^\n]*\n\s*jp c, \.done[^\n]*\n\s*ld hl, wd732.*?ld a, \[wLastBlackoutMap\]', special),
        ('only native Johto maps enter new eligibility', r'(?s)CanUseEscapeRope::.*?cp REGION_NATIVE_MAP_SLOT\s*\n\s*jr nz,\.legacyTileset\s*\n\s*callba CanUseJohtoUnionCaveEscape\s*\n\s*ret\s*\n\.legacyTileset', items),
        ('old escape whitelist not widened', r'(?m)^\s*db FOREST,CEMETERY,INTERIOR,CAVERN,FACILITY,SAFARI,ICE_CAVERN,\$FF\s*$', items),
        ('banked helper registered', r'(?m)^INCLUDE "engine/overworld/johto_cave_escape.asm"$', main),
        ('fixed Route32 safe return', r'(?m)^\s*FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 80, 6\s*$', escape),
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
    # The new route must never read stale healing or last-map bytes.
    code = '\n'.join(line.split(';', 1)[0] for line in (eligible + interceptor).splitlines())
    if re.search(r'\bwLastBlackoutMap\b|\bwLastMap\b|\bwUnusedD71F\b', code):
        errors.append('cave escape reads legacy/scratch return state')
    # Validate the explicit capability scope independently of preflight.
    import json
    maps = json.loads(manifest)['maps']
    enabled = [m['local_id'] for m in maps
               if m['feature_status']['dig'] == 'ALLOWED'
               or m['feature_status']['escape_rope'] == 'ALLOWED']
    if enabled != [8]:
        errors.append('Dig/Rope capability scope is not exactly Union Cave 1F')
    return errors
