#!/usr/bin/env python3
"""Static, fail-closed check of Ilex north gate -> Route34 -> Goldenrod.

FIX-279: catch the real phone-reported missing Route34 trees, truncated
4-column seam, and missing Goldenrod north Route35 preview. Gold roles
alone are insufficient: verify the live overworld border hook and its bytes.

Unlike the offline batch generator, this checks the ACTIVE RPP headers and
movement lane, not whether a new candidate was emitted. Does not build ROMs.
"""
from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path
import re


# Gold Gen II cell coordinates (16x16); these are not 32x32 block coordinates.
SIZES = {'Route34': (20, 54), 'GoldenrodCity': (40, 36)}
# FIX-281: (13,37)/(14,37) are LIVE two-lane gate carpets; not closed doors.
ROUTE34_CLOSED_DOORS = {(11, 14), (11, 15), (13, 15), (13, 41)}
GOLDENROD_CLOSED_DOORS = {
    (9, 5), (33, 5), (15, 7), (24, 7), (33, 9),
    (9, 13), (5, 15), (14, 21), (31, 21), (5, 25), (15, 27),
    (24, 27), (11, 29), (29, 29),
}


def connected(grid: bytes, width: int, height: int, sources, targets, closed) -> bool:
    """Conservative walking-only BFS: water, walls and sealed doors never pass.

    Route34 has zero Gold directed ledges. Paths through Surf or interiors do
    not count as evidence of an ordinary land connection.
    """
    def clear(p):
        x, y = p
        return (0 <= x < width and 0 <= y < height and
                (x, y) not in closed and grid[y * width + x] == 0)
    visited = {p for p in sources if clear(p)}
    queue = deque(visited)
    while queue:
        x, y = queue.popleft()
        if (x, y) in targets:
            return True
        for nxt in ((x+1, y), (x-1, y), (x, y+1), (x, y-1)):
            if nxt not in visited and clear(nxt):
                visited.add(nxt)
                queue.append(nxt)
    return False


def audit(project: Path, gold_root: Path | None = None) -> dict:
    project = Path(project)
    gold = Path(gold_root) if gold_root is not None else None
    errors = []
    checks = []

    def check(name, value):
        checks.append({'check': name, 'status': 'PASS' if value else 'FAIL'})
        if not value:
            errors.append(name)

    try:
        src = (project/'data/johto_south_runtime.asm').read_text()
        connections = (project/'data/johto_pilot_source_resources.asm').read_text()
        geo = (project/'engine/johto_south_geometry.asm').read_text()
        edge = (project/'engine/johto_pilot_runtime.asm').read_text()
        gate = (project/'engine/johto_south_portals.asm').read_text()
        constants = (project/'constants/region_map_constants.asm').read_text()
        mature = (project/'engine/johto_ilex_mature_runtime_275.asm').read_text()
        home = (project/'home/overworld.asm').read_text()
        source_gold = (gold/'data/maps/attributes.asm').read_text() if gold else None
        roles = {}
        for name, (w, h) in SIZES.items():
            terrain = (project/f'maps/johto_pilot/{name}.roles.bin').read_bytes()
            original = (project/f'maps/johto_pilot/{name}.gold.blk').read_bytes()
            runtime = (project/f'maps/johto_pilot/{name}.runtime.blk').read_bytes()
            check(f'{name}_runtime_gold_blocks', len(original) == w*h//4 and runtime == original)
            check(f'{name}_role_grid_size', len(terrain) == w*h)
            if source_gold is not None:
                check(f'{name}_source_gold_blocks',
                      original == (gold/f'maps/{name}.blk').read_bytes())
            roles[name] = terrain
        check('active_stable_ids_14_15',
              int(re.search(r'DEF NUM_JOHTO_ACTIVE_MAPS EQU (\d+)', constants).group(1)) >= 23 and
              'JOHTO_ROUTE_34_LOCAL_ID' in geo and 'JOHTO_GOLDENROD_CITY_LOCAL_ID' in edge)
        check('route34_city_source_connections', all(token in connections for token in (
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID',
        )))
        if source_gold is not None:
            route34 = source_gold.split('map_attributes Route34,', 1)[1].split('map_attributes ', 1)[0]
            city = source_gold.split('map_attributes GoldenrodCity,', 1)[1].split('map_attributes ', 1)[0]
            check('gold_reciprocal_seam_offsets',
                  'connection north, GoldenrodCity, GOLDENROD_CITY, -5' in route34 and
                  'connection south, Route34, ROUTE_34, 5' in city)
        # RPP connection descriptors are defined in ROMX and store the Gold
        # offset as the City/Route block pointer + WRAM copy destination.
        route_head = src.split('JohtoSouthRoute34RuntimeHeader::', 1)[1].split('JohtoSouthRoute34HeaderEnd::', 1)[0]
        city_head = src.split('JohtoSouthGoldenrodCityRuntimeHeader::', 1)[1].split('JohtoSouthGoldenrodCityHeaderEnd::', 1)[0]
        check('route34_north_runtime_connection', all(s in route_head for s in (
            'db 27, 10', 'db NORTH', 'dw JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 5',
            'dw wOverworldMap + 3', 'db 10\n    db 20\n    db 35\n    db 10',
            'dw wOverworldMap + 1 + 18 * (20 + 6)',
        )))
        check('goldenrod_south_runtime_connection', all(s in city_head for s in (
            'db 18, 20', 'db SOUTH', 'dw JohtoSouthRoute34Blocks',
            'dw wOverworldMap + (18 + 3) * (20 + 6) + 3 + 5',
            'db 10\n    db 10\n    db 0\n    db -10', 'dw wOverworldMap + 7 + 10',
        )))
        check('gate_to_route34_two_warps', all(s in src for s in (
            'db 37, 13, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 37, 14, 1, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR',
        )) and 'cp JOHTO_ROUTE_34_LOCAL_ID' in gate)
        route_edge = geo.split('JohtoSouthIsKnownClosedEdge::', 1)[1].split('\n.goldenrod\n', 1)[0]
        goldenrod_edge = geo.split('\n.goldenrod\n', 1)[1].split('\n.smallGate\n', 1)[0]
        # CLEAN-290: branch may be JR or JP depending on source distance;
        # do not reject user-side valid JP repairs. Preserve four-lane checks.
        # FIX-279: older TOOL-278 checked for only two lanes and silently
        # certified the precise phone-reported air-wall as correct.
        check('route34_north_gold_four_lanes', bool(re.search(
            r'(?s)\.route34\s+ld b, 20\s+ld c, 54.*?cp PLAYER_DIR_UP.*?'
            r'cp 8\s+jp c, \.closed\s+cp 12[^\n]*\s+ret c\s+(?:jp|jr) \.closed', route_edge)))
        check('goldenrod_south_gold_four_lanes', bool(re.search(
            r'(?s)ld b, 40\s+ld c, 36.*?cp PLAYER_DIR_DOWN.*?cp 35\s+ret nz.*?'
            r'cp 18\s+jp c, \.closed\s+cp 22[^\n]*\s+ret c\s+(?:jp|jr) \.closed', goldenrod_edge)))
        check('route34_gold_tree_border', bool(re.search(
            r'JohtoSouthRoute34RuntimeObjects::\s+db \$05\b', src)) and (
            source_gold is None or
            bool(re.search(r'map_attributes Route34,\s*ROUTE_34,\s*\$05,', source_gold))))
        # FIX-279: enforce the live render path, not a dead label in ROMX.
        blockmap = home.split('LoadTileBlockMap::', 1)[1].split('LoadNorthSouthConnectionsTileMap::', 1)[0]
        check('north_preview_runs_after_full_and_connection_load', bool(re.search(
            r'(?s)\.done\s+; FIX-279:.*?callab PatchJohtoSouthBordersAfterBlockLoad\s+ret', blockmap)))
        dispatcher = mature.split('PatchJohtoSouthBordersAfterBlockLoad::', 1)[1].split('PatchJohtoGoldenrodNorthBorder::', 1)[0] if 'PatchJohtoSouthBordersAfterBlockLoad::' in mature else ''
        check('preserve_azalea_then_north_preview_same_romx_bank',
              bool(re.search(r'call PatchJohtoAzaleaWestGateBorder\s+call PatchJohtoGoldenrodNorthBorder\s+jp PatchJohtoRoute35SouthBorder', dispatcher)))
        north = mature.split('PatchJohtoGoldenrodNorthBorder::', 1)[1] if 'PatchJohtoGoldenrodNorthBorder::' in mature else ''
        expected_rows = [bytes.fromhex(x) for x in (
            '05 05 58 59 01 78 44 05 05 05',
            '41 41 41 42 0c 0d 40 41 41 41',
            '01 01 01 46 08 09 44 01 01 01')]
        rows = []
        for i in range(3):
            match = re.search(r'\.row'+str(i)+r'\s+db ([^\n]+)', north)
            try:
                rows.append(bytes(int(t.strip().lstrip('$'), 16) for t in match.group(1).split(',')) if match else b'')
            except ValueError:
                rows.append(b'')
        check('route35_gold_three_buffer_rows', rows == expected_rows and (
            gold is None or rows == [
                (gold/'maps/Route35.blk').read_bytes()[-30+i*10:-20+i*10] for i in range(2)]
                + [(gold/'maps/Route35.blk').read_bytes()[-10:]]))
        check('goldenrod_north_preview_address_and_guard', all(t in north for t in (
            'cp JOHTO_RUNTIME_MAP_HANDLE', 'cp MAP_REGION_JOHTO',
            'cp JOHTO_GOLDENROD_CITY_LOCAL_ID',
            'ld hl, wOverworldMap + MAP_BORDER + 5',
            'ld hl, wOverworldMap + (JOHTO_SOUTH_GOLDENRODCITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5',
            'ld hl, wOverworldMap + 2 * (JOHTO_SOUTH_GOLDENRODCITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5',
            'ld b, 10', 'ld [hli], a',
        )) and 'db NORTH' not in city_head)
        check('precise_gold_spatial_dispatch', all(s in geo for s in (
            'cp JOHTO_ROUTE_34_LOCAL_ID', 'cp JOHTO_GOLDENROD_CITY_LOCAL_ID',
            'ld hl, JohtoSouthRoute34Roles', 'ld hl, JohtoSouthGoldenrodCityRoles',
            'call JohtoSouthMatureDoorFence',
        )))
        # FIX-281: ensure both registered gate carpet cells are passable in
        # the actual collision blacklist (not merely Gold roles). Cross-lane
        # transitions must be possible both ways on foot AND bike, and only
        # DOWN collision from the carpet is a warp trigger.
        closed_body = geo.split('JohtoSouthMatureDoorFence::', 1)[1].split('JohtoSouthAzaleaTownRoles::', 1)[0]
        runtime_closed = set((int(x), int(y)) for x, y in re.findall(
            r'^\s*db JOHTO_ROUTE_34_LOCAL_ID, (\d+), (\d+)\s*$', closed_body, re.M))
        carpet_lane = {(13,37),(14,37)}
        check('route34_registered_carpet_not_collision_blacklisted',
              runtime_closed == ROUTE34_CLOSED_DOORS and not (runtime_closed & carpet_lane))
        check('route34_two_carpet_lanes_gold_floor',
              all(roles['Route34'][37*20+x] == 0 for x in (13,14)))
        check('route34_carpet_bidirectional_horizontal_step',
              all((x,y) not in runtime_closed and roles['Route34'][y*20+x] == 0
                  for x,y in ((13,37),(14,37))) and
              all((x,y) not in runtime_closed and roles['Route34'][y*20+x] == 0
                  for x,y in ((13,36),(14,36))))
        # Ordinary land step uses the same passability for walking and bike;
        # the only state gate is Surf (on WATER roles), not bike on FLOOR.
        land = geo.split('JohtoSouthSpatialStep::', 1)[1].split('JohtoSouthMatureDoorFence::', 1)[0]
        check('route34_carpet_walk_and_bike_share_land_floor', bool(re.search(
            r'(?s)\.notWater\s+and a\s+jr z, \.allow.*?\.allow\s+ld e, 0', land)))
        check('route34_carpet_warp_down_only', bool(re.search(
            r'(?s)\.route34\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wYCoord\]\s+cp 37.*?cp 13\s+jp z, \.carpet\s+cp 14\s+jp z, \.carpet',gate)))
        # Gate collision warps stand on y=37; the immediately preceding safe
        # tiles are y=36. Both Gold northern seam columns must be walkable.
        route = roles['Route34']
        city = roles['GoldenrodCity']
        check('four_reciprocal_gold_seam_cells_walkable', all(route[x] == 0 for x in range(8, 12))
              and all(city[35*40+x] == 0 for x in range(18, 22)))
        check('route34_gate_to_goldenrod_walk_path', len(route) == 1080 and connected(
            route, 20, 54, {(13, 36), (14, 36)}, {(8, 0), (9, 0)}, ROUTE34_CLOSED_DOORS))
        check('goldenrod_entry_to_city_street', len(city) == 1440 and connected(
            city, 40, 36, {(18, 35), (19, 35)}, {(20, 20)}, GOLDENROD_CLOSED_DOORS))
    except (OSError, ValueError, IndexError, KeyError) as exc:
        errors.append(f'source_error: {exc}')
    return {'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks': checks, 'errors': errors,
            'rom_built': False, 'phone_accepted': False}


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, default=Path('.'))
    p.add_argument('--gold-root', type=Path)
    args = p.parse_args()
    result = audit(args.project, args.gold_root)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(result['status'] != 'PASS_STATIC_ONLY')
