#!/usr/bin/env python3
"""Gold-anchored executable-source guard for the second Union Cave mouth.

The route33 modern CAVE graphic is solid in the map's 16x16 mask, so only
11,10 facing up may enter its step-on warp. The cave uses the same DOWN
collision style as its pre-existing Route32 mouth. Does not build a ROM.
"""
from pathlib import Path
import re


def audit(root: Path, gold: Path) -> list[str]:
    root, gold = Path(root), Path(gold)
    errors: list[str] = []
    try:
        read = lambda file: (root / file).read_text()
        cave_gold = (gold / 'maps/UnionCave1F.asm').read_text()
        r33_gold = (gold / 'maps/Route33.asm').read_text()
        cave = read('data/mapObjects/JohtoUnionCave1F.asm')
        route = read('data/mapObjects/JohtoRoute33.asm')
        resolver = read('engine/overworld/region_map_lookup.asm')
        escape = read('engine/overworld/johto_cave_escape.asm')
        modern = read('engine/overworld/johto_route33_collision.asm')
        state = read('engine/overworld/player_state.asm')
        special = read('engine/special_warps.asm')
        home = read('home/overworld.asm')
        legacy = read('data/mapObjects/JohtoRoute32.asm')
    except OSError as exc:
        return ['Union Cave 192 audit source missing: ' + str(exc)]

    if not re.search(r'warp_event\s+17,\s*31,\s*ROUTE_33,\s*1\b', cave_gold):
        errors.append('Gold cave southern mouth drifted')
    if not re.search(r'warp_event\s+11,\s*9,\s*UNION_CAVE_1F,\s*3\b', r33_gold):
        errors.append('Gold Route33 cave mouth drifted')
    c_warps = re.findall(r'^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*REGION_WARP_ESCAPE', cave, re.M)
    r_warps = re.findall(r'^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*REGION_WARP_ESCAPE', route, re.M)
    if c_warps != [('3', '17', '0'), ('31', '17', '0')] or 'db $02' not in cave:
        errors.append('cave must have exactly original two reviewed outdoor warps')
    if r_warps != [('9', '11', '1')] or 'db $01' not in route:
        errors.append('Route33 must have exactly one Gold cave warp (11,9)')
    if 'db 79, 6, 0, REGION_WARP_ESCAPE' not in legacy:
        errors.append('old Route32 cave mouth changed')

    native = resolver.split('NativeRegionWarpTargets::', 1)[-1].split('; Native connection lookup', 1)[0]
    for line in (
        'db JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',
        'db JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',
        'db JOHTO_ROUTE_33_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
    ):
        if native.count(line) != 1:
            errors.append('native Warp graph changed/missing: ' + line)
    if 'db JOHTO_ROUTE_32, 0, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID' not in resolver:
        errors.append('legacy Route32 -> Union Cave Warp disappeared')

    capture = resolver.split('RecordJohtoCaveEscapeSource::', 1)[-1].split('ResolveNativeRegionWarp::', 1)[0]
    for tok in ('push de', 'pop de', 'cp JOHTO_UNION_CAVE_1F_LOCAL_ID',
                'cp JOHTO_ROUTE_33_LOCAL_ID', 'cp JOHTO_ROUTE_32_LOCAL_ID',
                'cp 1 ; Gold cave third warp', 'ld [wLastMap], a',
                'ld [wLastRegion], a', 'ld [wLastLocalMapID], a',
                'ld a, [wDestinationWarpID]', 'ld a, [wWarpedFromWhichWarp]'):
        if tok not in capture:
            errors.append('verified last-entry identity capture missing: ' + tok)
    # Capturing after StoreNativeWarpTarget loses source local ID; check both call paths.
    if len(re.findall(r'call RecordJohtoCaveEscapeSource\s+call StoreNativeWarpTarget', resolver)) != 2:
        errors.append('must capture entrance before key mutation in both $FE warp resolvers')
    if 'RecordJohtoCaveEscapeSource::' in home or 'ld [wLastMap]' in escape:
        errors.append('source capture must only occur at verified Warp resolution')

    intercept = escape.split('TryLoadJohtoUnionCaveEscapeWarp::', 1)[-1]
    for tok in ('and (1 << 3) | (1 << 6)', 'cp (1 << 3) | (1 << 6)',
                'call CanUseJohtoUnionCaveEscape', 'ld a, [wLastMap]',
                'ld a, [wLastRegion]', 'ld a, [wLastLocalMapID]',
                'cp JOHTO_ROUTE_33_LOCAL_ID',
                'FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 80, 6',
                'FLYWARP_DATA JOHTO_ROUTE_33_WIDTH, 10, 11',
                'ld a, JOHTO_MODERN', 'ld a, JOHTO', 'ld e, 0'):
        if tok not in intercept:
            errors.append('two-mouth special field-move return incomplete: ' + tok)
    if re.search(r'ld a,\s*\[wLastBlackoutMap\]', intercept) or 'callba TryLoadJohtoUnionCaveEscapeWarp' not in special:
        errors.append('blackout and cave escape must remain separated')

    cave_edge = state.split('\n.facingDown\n', 1)[-1].split('\n.facingUp\n', 1)[0]
    if not re.search(r'cp 17\s+jr nz, \.normalDownEdge\s+ld a, b\s+cp 3\s+jr z, \.setCarry.*?cp 31\s+jr z, \.setCarry', cave_edge, re.S):
        errors.append('southern cave exit must accept DOWN collision only at x17 y31')
    if 'JohtoUnionCaveWarpTileIDs:\n\tdb $FF' not in read('data/warp_tile_ids.asm'):
        errors.append('cave remains collision-only, not a global step-on warp')
    entry = modern.split('JohtoRoute33CanStepAhead::', 1)[-1].split('JohtoRoute33BlockedRows::', 1)[0]
    if not re.search(r'cp 11\s+jr nz, \.normalStep\s+ld a, \[wYCoord\]\s+cp 10\s+jr nz, \.normalStep\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jp z, \.allowed', entry):
        errors.append('Route33 cave entry must require x11 y10 facing north')
    check = resolver.split('JohtoRoute33CaveWarpTileCheck::', 1)[-1]
    if not all(tok in check for tok in ('cp MAP_REGION_JOHTO', 'cp JOHTO_ROUTE_33_LOCAL_ID', 'cp 9', 'cp 11')):
        errors.append('Route33 stepping warp must validate exact physical key and tile')
    tile = state.split('IsPlayerStandingOnDoorTileOrWarpTile:', 1)[-1].split('INCLUDE "data/warp_tile_ids.asm"', 1)[0]
    if 'callba JohtoRoute33CaveWarpTileCheck' not in tile or 'callba JohtoRoute32CaveWarpTileCheck' not in tile:
        errors.append('new cave doorway hook must preserve existing Route32 entry')
    arrival = resolver.split('GetJohtoWarpArrivalStep::', 1)[-1].split('GetJohtoCaveMapChangeSFX::', 1)[0]
    if 'db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_33_LOCAL_ID, 9, 11, REGION_NATIVE_MAP_SLOT, D_DOWN' not in arrival:
        errors.append('Route33 arrival must step south onto walkable tile')
    if 'db REGION_NATIVE_MAP_SLOT, JOHTO_UNION_CAVE_1F_LOCAL_ID, 31, 17' in arrival:
        errors.append('cave warp must not auto-step or immediately re-enter')
    return errors
