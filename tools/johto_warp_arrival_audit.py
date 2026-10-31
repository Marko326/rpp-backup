#!/usr/bin/env python3
"""Static source/landing audit for the currently enabled Johto house Warp.

Uses MUS/Gold as the only Gold source input and the current PAL stable-ID
runtime as target. It checks source Warp numbers, actual collision roles,
registered $FB routes, tile passability at the exit/arrival cells, and the
existing door step-out path. It is not a ROM emulator or phone acceptance.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

from johto_gold_door_audit import GoldCollisionIndex, inspect as inspect_gold


def _check(checks: list[dict], errors: list[str], name: str, ok: bool, detail: str) -> None:
    checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
    if not ok:
        errors.append(f'{name}: {detail}')


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file() or path.is_symlink():
        raise FileNotFoundError(f'required file missing or symlink: {relative}')
    return path.read_text(encoding='utf-8')


def _section(source: str, start: str, end: str | None = None) -> str:
    start_re = re.compile(r'(?m)^' + re.escape(start) + r'::?\s*$')
    starts = list(start_re.finditer(source))
    if len(starts) != 1:
        raise ValueError(f'missing/duplicate label {start}: {len(starts)}')
    tail = source[starts[0].end():]
    if end is None:
        return tail
    end_re = re.compile(r'(?m)^' + re.escape(end) + r'::?\s*$')
    ends = list(end_re.finditer(tail))
    if len(ends) != 1:
        raise ValueError(f'missing/duplicate end label {end}: {len(ends)}')
    return tail[:ends[0].start()]


def _gold_warp_events(gold: Path, map_name: str) -> list[dict]:
    text = _read(gold, f'maps/{map_name}.asm')
    rows = []
    pattern = re.compile(r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z0-9_]*)\s*,\s*(-?\d+)\b')
    for ordinal, match in enumerate(pattern.finditer(text), 1):
        rows.append({'warp_number': ordinal, 'x': int(match[1]), 'y': int(match[2]),
                     'destination': match[3], 'destination_warp_number': int(match[4])})
    return rows


def _current_cell_tiles(project: Path, map_name: str, width: int, height: int,
                        tileset: str, x: int, y: int) -> tuple[list[int], list[int]]:
    """Return all four 8x8 IDs and the lower (player-feet) two IDs for a 16x16 cell."""
    if not (0 <= x < width * 2 and 0 <= y < height * 2):
        raise ValueError(f'cell outside {map_name}: ({x},{y}) for {width}x{height} blocks')
    layout = (project / f'maps/johto_pilot/{map_name}.runtime.blk').read_bytes()
    blockset = (project / f'gfx/blocksets/{tileset}.bst').read_bytes()
    if len(layout) != width * height or len(blockset) % 16:
        raise ValueError(f'invalid runtime layout/blockset for {map_name}/{tileset}')
    block_id = layout[(y // 2) * width + x // 2]
    if block_id * 16 + 15 >= len(blockset):
        raise ValueError(f'block ID {block_id} outside {tileset} blockset')
    start = block_id * 16 + (y % 2) * 8 + (x % 2) * 2
    all_ids = [blockset[start + j * 4 + i] for j in range(2) for i in range(2)]
    feet_ids = [blockset[start + 4 + i] for i in range(2)]
    return all_ids, feet_ids


def _route_rows(source: str) -> list[tuple[str, ...]]:
    body = _section(source, 'JohtoRegisteredWarpRoutes', 'JohtoRegisteredWarpRoutesEnd')
    pattern = re.compile(r'db\s+(MAP_REGION_(?:JOHTO|KANTO))\s*,\s*'
        r'(JOHTO_[A-Z0-9_]+|[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*'
        r'(MAP_REGION_(?:JOHTO|KANTO))\s*,\s*(JOHTO_[A-Z0-9_]+|[A-Z0-9_]+)')
    result = []
    for raw in body.splitlines():
        code = raw.split(';', 1)[0].strip()
        if not code:
            continue
        match = pattern.fullmatch(code)
        if not match:
            raise ValueError('unsupported registered Warp row: ' + code)
        result.append(match.groups())
    return result


def audit(project: Path, gold: Path) -> dict:
    project, gold = Path(project).resolve(), Path(gold).resolve()
    checks: list[dict] = []
    errors: list[str] = []
    try:
        map_headers = _read(project, 'data/johto_pilot_map_headers.asm')
        house = _read(project, 'data/johto_indoor_house.asm')
        runtime = _read(project, 'engine/johto_pilot_runtime.asm')
        overworld = _read(project, 'home/overworld.asm')
        home = _read(project, 'home.asm')
        movement = _read(project, 'engine/overworld/npc_movement.asm')
        doors = _read(project, 'engine/overworld/doors.asm')
        warp_tiles = _read(project, 'data/warp_tile_ids.asm')
        collision_index = GoldCollisionIndex(gold)
        gold_summary = inspect_gold(gold)
        contract = json.loads(_read(project, 'tools/johto_pilot_door_contracts.json'))
    except (OSError, ValueError) as exc:
        return {'schema': 'johto-warp-arrival-audit-v1', 'status': 'FAIL',
                'checks': checks, 'errors': [str(exc)], 'runtime_verified': False,
                'rom_built': False, 'phone_accepted': False}

    _check(checks, errors, 'door_contract_schema',
           contract.get('schema') == 'johto-pilot-door-contracts-v1' and
           contract.get('gold_reference') == 'MUS-1.0.1' and
           len(contract.get('active_routes', [])) == 3 and
           len(contract.get('gatehouse_activation_policy', {}).get('active_gatehouse_contracts', [])) == 8 and
           contract.get('runtime_invariants', {}).get('registered_warp_route_rows') == 65 and
           contract.get('runtime_invariants', {}).get('indoor_step_on_warp_tile_ids') == [],
           'MUS contract records 3 house arcs, 8 gates and all activated north/south arcs')
    _check(checks, errors, 'gold_inventory', not gold_summary.get('errors'),
           f"MUS Gold inventory errors={len(gold_summary.get('errors', []))}; "
           f"maps={gold_summary.get('stats', {}).get('registered_maps')}; "
           f"warps={gold_summary.get('stats', {}).get('warp_events')}")

    city_warps = _gold_warp_events(gold, 'CherrygroveCity')
    room_warps = _gold_warp_events(gold, 'GuideGentsHouse')
    city_entry = [w for w in city_warps if (w['x'], w['y']) == (25, 9)]
    room_left = [w for w in room_warps if (w['x'], w['y']) == (2, 7)]
    room_right = [w for w in room_warps if (w['x'], w['y']) == (3, 7)]
    _check(checks, errors, 'gold_city_door_warp',
           len(city_entry) == 1 and city_entry[0]['warp_number'] == 4 and
           city_entry[0]['destination'] == 'GUIDE_GENTS_HOUSE' and
           city_entry[0]['destination_warp_number'] == 1,
           f'Gold CherrygroveCity door source row: {city_entry}')
    _check(checks, errors, 'gold_house_exit_warps',
           len(room_left) == 1 and len(room_right) == 1 and
           all(w['destination'] == 'CHERRYGROVE_CITY' and w['destination_warp_number'] == 4
               for w in room_left + room_right),
           f'Gold GuideGentsHouse exit rows: left={room_left}, right={room_right}')
    roles = {}
    try:
        roles = {
            'CherrygroveCity(25,9)': collision_index.role_at('CherrygroveCity', 25, 9),
            'GuideGentsHouse(2,7)': collision_index.role_at('GuideGentsHouse', 2, 7),
            'GuideGentsHouse(3,7)': collision_index.role_at('GuideGentsHouse', 3, 7),
        }
    except ValueError as exc:
        errors.append('gold_collision_roles: ' + str(exc))
    _check(checks, errors, 'gold_collision_roles', roles == {
        'CherrygroveCity(25,9)': 'DOOR',
        'GuideGentsHouse(2,7)': 'WARP_CARPET_DOWN',
        'GuideGentsHouse(3,7)': 'WARP_CARPET_DOWN'}, f'actual Gold roles={roles}')

    city_objects = _section(map_headers, 'JohtoPilotCherrygroveRuntimeObjects', 'JohtoPilotRoute30TextPointers')
    room_objects = _section(house, 'JohtoGuideGentsHouseRuntimeObjects')
    _check(checks, errors, 'current_warp_coordinates',
           len(re.findall(r'(?m)^\s*db\s+9\s*,\s*25\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', city_objects)) == 1 and
           len(re.findall(r'(?m)^\s*db\s+7\s*,\s*2\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', room_objects)) == 1 and
           len(re.findall(r'(?m)^\s*db\s+7\s*,\s*3\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', room_objects)) == 1,
           'current RPP source rows are city (Y9,X25) and room (Y7,X2)/(Y7,X3)')

    expected_routes = [
        ('MAP_REGION_JOHTO', 'JOHTO_CHERRYGROVE_LOCAL_ID', '0', 'MAP_REGION_JOHTO', 'JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID', '0', 'MAP_REGION_JOHTO', 'JOHTO_CHERRYGROVE_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID', '1', 'MAP_REGION_JOHTO', 'JOHTO_CHERRYGROVE_LOCAL_ID'),
    ]
    expected_routes += [
        ('MAP_REGION_JOHTO', 'JOHTO_ROUTE_31_LOCAL_ID', '0', 'MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_ROUTE_31_LOCAL_ID', '1', 'MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_VIOLET_CITY_LOCAL_ID', '0', 'MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_VIOLET_CITY_LOCAL_ID', '1', 'MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID', '0', 'MAP_REGION_JOHTO', 'JOHTO_VIOLET_CITY_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID', '1', 'MAP_REGION_JOHTO', 'JOHTO_VIOLET_CITY_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID', '2', 'MAP_REGION_JOHTO', 'JOHTO_ROUTE_31_LOCAL_ID'),
        ('MAP_REGION_JOHTO', 'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID', '3', 'MAP_REGION_JOHTO', 'JOHTO_ROUTE_31_LOCAL_ID'),
    ]
    for source, ordinal, target in (
        ('JOHTO_ROUTE_32_LOCAL_ID', 0, 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE_32_LOCAL_ID', 1, 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID', 0, 'JOHTO_RUINS_OF_ALPH_LOCAL_ID'),
        ('JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID', 1, 'JOHTO_RUINS_OF_ALPH_LOCAL_ID'),
        ('JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID', 2, 'JOHTO_ROUTE_32_LOCAL_ID'),
        ('JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID', 3, 'JOHTO_ROUTE_32_LOCAL_ID'),
        ('JOHTO_RUINS_OF_ALPH_LOCAL_ID', 0, 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'),
        ('JOHTO_RUINS_OF_ALPH_LOCAL_ID', 1, 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'),
    ):
        expected_routes.append(('MAP_REGION_JOHTO', source, str(ordinal), 'MAP_REGION_JOHTO', target))
    for source, ordinal, target in (
        ('JOHTO_RUINS_OF_ALPH_LOCAL_ID', 2, 'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', 0, 'JOHTO_ROUTE_36_LOCAL_ID'),
        ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', 1, 'JOHTO_ROUTE_36_LOCAL_ID'),
        ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', 2, 'JOHTO_RUINS_OF_ALPH_LOCAL_ID'),
        ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', 3, 'JOHTO_RUINS_OF_ALPH_LOCAL_ID'),
        ('JOHTO_ROUTE_36_LOCAL_ID', 0, 'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE_36_LOCAL_ID', 1, 'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'),
    ):
        expected_routes.append(('MAP_REGION_JOHTO', source, str(ordinal), 'MAP_REGION_JOHTO', target))
    for row in contract.get('cave_1f_routes', []):
        ids = {7: 'JOHTO_ROUTE_32_LOCAL_ID', 8: 'JOHTO_UNION_CAVE_1F_LOCAL_ID',
               9: 'JOHTO_ROUTE_33_LOCAL_ID'}
        expected_routes.append(('MAP_REGION_JOHTO', ids[row['source_stable_id']],
            str(row['source_warp_ordinal']), 'MAP_REGION_JOHTO', ids[row['target_stable_id']]))
    # MAP-268: South route order and physical Gold endpoints are frozen together.
    south_routes = contract.get('south_batch_routes', [])
    south_names = {10:'AzaleaTown', 11:'IlexForestAzaleaGate', 12:'IlexForest',
                   13:'Route34IlexForestGate',14:'Route34'}
    source_gold_ord = {10:[7,8],11:[1,2,3,4],12:[1,2,3],13:[1,2,3,4],14:[1,2]}
    verified_south = len(south_routes) == 15
    for row in south_routes:
        try:
            src, dst = row['source_stable_id'], row['target_stable_id']
            if src not in south_names or dst not in south_names:
                verified_south = False; continue
            name, target_name = south_names[src], south_names[dst]
            src_ordinal = row['source_warp_ordinal']
            gold_num = source_gold_ord[src][src_ordinal]
            gold_event = _gold_warp_events(gold,name)[gold_num - 1]
            target_num = gold_event['destination_warp_number']
            target_ordinal = source_gold_ord[dst].index(target_num)
            target_event = _gold_warp_events(gold,target_name)[target_num-1]
            actual = (gold_num, [gold_event['x'],gold_event['y']], target_num,
                      target_ordinal, [target_event['x'],target_event['y']])
            wanted = (row['source_gold_warp_number_one_based'],row['source_xy'],
                      row['target_gold_warp_number_one_based'],row['target_warp_ordinal'],row['target_xy'])
            role = collision_index.role_at(name,gold_event['x'],gold_event['y'])
            if (actual != wanted or role != row['source_gold_collision_role'] or
                gold_event['destination'].replace('_','') != target_name.upper().replace('_','')):
                verified_south = False
            expected_routes.append(('MAP_REGION_JOHTO', {10: 'JOHTO_AZALEA_TOWN_LOCAL_ID', 11: 'JOHTO_ILEX_AZALEA_GATE_LOCAL_ID', 12: 'JOHTO_ILEX_FOREST_LOCAL_ID', 13: 'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID', 14: 'JOHTO_ROUTE_34_LOCAL_ID'}[src], str(src_ordinal),
                                     'MAP_REGION_JOHTO',{10: 'JOHTO_AZALEA_TOWN_LOCAL_ID', 11: 'JOHTO_ILEX_AZALEA_GATE_LOCAL_ID', 12: 'JOHTO_ILEX_FOREST_LOCAL_ID', 13: 'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID', 14: 'JOHTO_ROUTE_34_LOCAL_ID'}[dst]))
        except (IndexError, KeyError, ValueError, TypeError):
            verified_south = False
    _check(checks, errors, 'south_batch_exact_gold_warps', verified_south,
           '15 source ordinal, target ordinal, XY and original Gold role pairs must match')
    # MAP-283: require exact registered Gold routes, in on-ROM append order.
    north_gates = [g for g in contract['gatehouse_activation_policy']['active_gatehouse_contracts']
                   if g.get('stable_id') == 18]
    ids_north = {15: 'JOHTO_GOLDENROD_CITY_LOCAL_ID',
                 18: 'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
                 17: 'JOHTO_ROUTE_35_LOCAL_ID'}
    north_verified = len(north_gates) == 1 and len(north_gates[0].get('warp_contracts', [])) == 7
    if north_verified:
        north_entries = north_gates[0]['warp_contracts']
        north_verified = [(r['source_stable_id'], r['source_warp_ordinal']) for r in north_entries] == [
            (15, 0), (18, 0), (18, 1), (18, 2), (18, 3), (17, 0), (17, 1)]
        if north_verified:
            for row in north_entries:
                src, dst = row['source_stable_id'], row['target_stable_id']
                if src not in ids_north or dst not in ids_north:
                    north_verified = False
                    break
                try:
                    native = _gold_warp_events(gold, row['source_gold_map'])[
                        row['source_gold_warp_number_one_based'] - 1]
                    source_role = collision_index.role_at(row['source_gold_map'], *row['source_xy'])
                    if ([native['x'], native['y']] != row['source_xy'] or
                        native['destination'].replace('_', '') != row['target_gold_map'].upper().replace('_','') or
                        source_role != row['source_gold_collision_role']):
                        north_verified = False
                except (IndexError, ValueError, KeyError):
                    north_verified = False
                expected_routes.append(('MAP_REGION_JOHTO', ids_north[src],
                    str(row['source_warp_ordinal']), 'MAP_REGION_JOHTO', ids_north[dst]))
    _check(checks, errors, 'route35_gold_and_registered_warps', north_verified,
           'Route35 gate requires 7 contract arcs, exact source Gold warp and collision roles')
    # MAP-286: exact 15 newly activated Park/source arcs in *append* order.
    # Explicit IDs and ordinals prevent changing the existing Route36 Ruins
    # slots0/1 when Park Route36 slots2/3 become active.
    park_routes = (
        ('JOHTO_ROUTE_35_LOCAL_ID', 2, 'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE_36_LOCAL_ID', 2, 'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE_36_LOCAL_ID', 3, 'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_NATIONAL_PARK_LOCAL_ID', 0, 'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_NATIONAL_PARK_LOCAL_ID', 1, 'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_NATIONAL_PARK_LOCAL_ID', 2, 'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_NATIONAL_PARK_LOCAL_ID', 3, 'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID'),
        ('JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID', 0, 'JOHTO_NATIONAL_PARK_LOCAL_ID'),
        ('JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID', 1, 'JOHTO_NATIONAL_PARK_LOCAL_ID'),
        ('JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID', 2, 'JOHTO_ROUTE_35_LOCAL_ID'),
        ('JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID', 3, 'JOHTO_ROUTE_35_LOCAL_ID'),
        ('JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID', 0, 'JOHTO_NATIONAL_PARK_LOCAL_ID'),
        ('JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID', 1, 'JOHTO_NATIONAL_PARK_LOCAL_ID'),
        ('JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID', 2, 'JOHTO_ROUTE_36_LOCAL_ID'),
        ('JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID', 3, 'JOHTO_ROUTE_36_LOCAL_ID'),
    )
    expected_routes.extend(('MAP_REGION_JOHTO', source, str(ordinal), 'MAP_REGION_JOHTO', target)
                           for source, ordinal, target in park_routes)
    try:
        rows = _route_rows(runtime)
        _check(checks, errors, 'registered_routes', rows == expected_routes,
               f'expected exact activated house and gate routes; actual={rows}')
    except ValueError as exc:
        _check(checks, errors, 'registered_routes', False, str(exc))

    contract_routes = contract.get('active_routes', [])
    contract_expectations = {
        'cherrygrove_to_guide_house': (2, 0, [25, 9], 'DOOR', 'STEP_ON', 'UP',
                                       125, 0, [2, 7], 'WARP_CARPET_DOWN', 'NONE'),
        'guide_house_left_exit': (125, 0, [2, 7], 'WARP_CARPET_DOWN', 'COLLISION_ONLY', 'DOWN',
                                 2, 0, [25, 9], 'DOOR', 'D_DOWN'),
        'guide_house_right_exit': (125, 1, [3, 7], 'WARP_CARPET_DOWN', 'COLLISION_ONLY', 'DOWN',
                                  2, 0, [25, 9], 'DOOR', 'D_DOWN'),
    }
    contract_errors = []
    if {row.get('id') for row in contract_routes} != set(contract_expectations):
        contract_errors.append('contract route IDs differ')
    for row in contract_routes:
        route_id = row.get('id')
        if route_id not in contract_expectations:
            continue
        source = row.get('source', {})
        target = row.get('target', {})
        actual = (source.get('stable_id'), source.get('warp_ordinal_zero_based'), source.get('xy'),
                  source.get('gold_collision_role'), source.get('trigger'), source.get('approach_direction'),
                  target.get('stable_id'), target.get('warp_ordinal_zero_based'), target.get('xy'),
                  target.get('gold_collision_role'), target.get('arrival_step'))
        if actual != contract_expectations[route_id]:
            contract_errors.append(f'{route_id}: {actual}')
    _check(checks, errors, 'door_contract_route_details', not contract_errors,
           f'contract source/target coordinates, roles, trigger and arrival step checked; errors={contract_errors}')

    outdoor_warp_tiles = _section(warp_tiles, 'JohtoPilotWarpTileIDs', 'JohtoHouseWarpTileIDs')
    indoor_warp_tiles = _section(warp_tiles, 'JohtoHouseWarpTileIDs', 'JohtoGateWarpTileIDs')
    indoor_values = []
    for raw in indoor_warp_tiles.splitlines():
        code = raw.split(';', 1)[0].strip()
        if code.startswith('db '):
            indoor_values.extend(x.strip().upper() for x in code[3:].split(','))
    _check(checks, errors, 'trigger_class_separation',
           re.search(r'(?m)^\s*db\s+\$06\s*,\s*\$39\s*,\s*\$FF\s*$', outdoor_warp_tiles) is not None and
           indoor_values == ['$FF'],
           f'outdoor step-on IDs include $39; indoor carpet list remains empty: {indoor_values}')

    # Collision/landing cells use the current RPP 32x32 blockset and 16x16
    # coordinate grid. Only the two lower 8x8 tile IDs form the player's feet.
    try:
        outdoor_whitelist = set((project / 'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
        indoor_whitelist = set((project / 'gfx/tilesets/johto_house.tilecoll').read_bytes()[:-1])
        door_all, door_feet = _current_cell_tiles(project, 'CherrygroveCity', 20, 9, 'johto', 25, 9)
        outside_all, outside_feet = _current_cell_tiles(project, 'CherrygroveCity', 20, 9, 'johto', 25, 10)
        left_all, left_feet = _current_cell_tiles(project, 'GuideGentsHouse', 4, 4, 'johto_house', 2, 7)
        right_all, right_feet = _current_cell_tiles(project, 'GuideGentsHouse', 4, 4, 'johto_house', 3, 7)
        _check(checks, errors, 'outdoor_door_guard_needed',
               0x37 in door_all and not all(tile in outdoor_whitelist for tile in door_feet) and
               all(tile in outdoor_whitelist for tile in outside_feet),
               f'door tile IDs={door_all}, feet={door_feet}; outside landing feet={outside_feet}')
        _check(checks, errors, 'indoor_carpet_standable',
               all(tile in indoor_whitelist for tile in left_feet + right_feet) and 0x12 in indoor_whitelist,
               f'left/right carpet feet={left_feet}/{right_feet}; whitelist={sorted(indoor_whitelist)}')
    except (OSError, ValueError, IndexError) as exc:
        _check(checks, errors, 'landing_cell_decode', False, str(exc))

    # FIX-272 moved the guide-house Y10/X25/UP exception to ROMX. Verify
    # the actual ROM0 -> ROMX call and E=0 result rather than an obsolete
    # inline ROM0 shape (which used to make this test fail on valid builds).
    collision_entry = overworld.split('CollisionCheckOnLand::', 1)[1].split('\n.collision\n', 1)[0]
    land = _read(project, 'engine/johto_land_collision_gateway_272.asm')
    guide = land.split('JohtoOverworldSouthLandDecision::', 1)[1].split('\n.southMaps\n', 1)[0]
    _check(checks, errors, 'one_step_up_entry_guard',
           all(token in collision_entry for token in (
               'cp JOHTO_RUNTIME_MAP_HANDLE', 'callab JohtoOverworldSouthLandDecision',
               'cp 2', 'jp z, .noCollision')) and
           all(token in guide for token in (
               'cp MAP_REGION_JOHTO', 'cp JOHTO_CHERRYGROVE_LOCAL_ID',
               'cp PLAYER_DIR_UP', 'cp 25', 'cp 10', 'ld e, 0', 'ret')) and
           bool(re.search(r'cp JOHTO_CHERRYGROVE_LOCAL_ID\s+jr nz, \.southMaps\s+'
                          r'ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jr nz, \.southMaps\s+'
                          r'ld a, \[wXCoord\]\s+cp 25\s+jr nz, \.southMaps\s+'
                          r'ld a, \[wYCoord\]\s+cp 10\s+jr nz, \.southMaps\s+'
                          r'ld e, 0\s+ret', guide)),
           'only the registered Cherrygrove (Y10,X25) UP approach returns E=0 through ROMX')
    warp_loop = overworld.split('CheckWarpsNoCollisionLoop::', 1)[1].split('CheckWarpsCollision::', 1)[0]
    _check(checks, errors, 'step_on_door_warp_guard',
           all(token in warp_loop for token in ('cp JOHTO_RUNTIME_MAP_HANDLE', 'cp MAP_REGION_JOHTO',
               'cp JOHTO_CHERRYGROVE_LOCAL_ID', 'cp PLAYER_DIR_UP', 'cp 9', 'cp 25', 'jp WarpFound1')),
           'matched door entry warp routes to WarpFound1 on the same UP step')
    _check(checks, errors, 'directional_carpet_no_step_on',
           'cp JOHTO_HOUSE' in warp_loop and 'jr z,CheckWarpsNoCollisionRetry2' in warp_loop and
           re.search(r'(?m)^\s*JohtoHouseWarpTileIDs:\s*$', warp_tiles) is not None,
           'indoor carpet is not a generic STEP_ON warp; collision path remains separate')
    enter_map = overworld.split('EnterMap::', 1)[1].split('OverworldLoop::', 1)[0]
    _check(checks, errors, 'arrival_warp_rearm',
           'cp JOHTO_HOUSE' in enter_map and 'res 2,[hl]' in enter_map and 'callba IsPlayerStandingOnWarp' in enter_map,
           'landing on the carpet re-arms the warp collision state for first DOWN input/save-load')
    warp_found = overworld.split('WarpFound2::', 1)[1].split('ContinueCheckWarpsNoCollisionLoop::', 1)[0]
    _check(checks, errors, 'door_step_out_requested',
           'set 0,[hl]' in warp_found and 'jp EnterMap' in warp_found,
           'the original engine step-out flag is set before target map entry')
    stepout = movement.split('PlayerStepOutFromDoor:', 1)[1].split('_EndNPCMovementScript:', 1)[0]
    door_list = doors.split('JohtoPilotDoorTileIDs:', 1)[1].split('\n', 1)[1] if 'JohtoPilotDoorTileIDs:' in doors else ''
    door_pointer = _section(doors, 'DoorTileIDPointers', 'OverworldDoorTileIDs')
    _check(checks, errors, 'auto_step_outdoor_only',
           'dbw JOHTO_PILOT,  JohtoPilotDoorTileIDs' in door_pointer and
           re.search(r'(?m)^\s*db\s+\$39\s*,\s*\$00\s*$', door_list) is not None and
           'call IsPlayerStandingOnDoorTile' in stepout and 'ld a, D_DOWN' in stepout and
           'call StartSimulatingJoypadStates' in stepout and
           'dbw JOHTO_HOUSE' not in door_pointer,
           'returned outdoor $39 uses the original single DOWN step; indoor carpet is not a door-step tile')

    return {'schema': 'johto-warp-arrival-audit-v1',
            'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'project': str(project), 'gold_reference': str(gold),
            'checks': checks, 'errors': errors,
            'gold_roles': roles,
            'landing': {
                'city_door': {'x': 25, 'y': 9, 'gold_role': roles.get('CherrygroveCity(25,9)'),
                              'auto_step': 'NONE_ON_ENTRY'},
                'room_exit_left': {'x': 2, 'y': 7, 'gold_role': roles.get('GuideGentsHouse(2,7)'),
                                   'trigger': 'DOWN_COLLISION_ONLY'},
                'room_exit_right': {'x': 3, 'y': 7, 'gold_role': roles.get('GuideGentsHouse(3,7)'),
                                    'trigger': 'DOWN_COLLISION_ONLY'},
                'outdoor_final': {'x': 25, 'y': 10, 'auto_step': 'D_DOWN'},
            },
            'runtime_verified': False, 'rom_built': False, 'phone_accepted': False,
            'required_phone_tests': [
                '从(10,25)按一次UP进入，直接落在室内(2,7)，不能自动走出',
                '刚进屋第一次按DOWN能离开；左右两格出口都测试',
                '出门先落回(25,9)，引擎自动DOWN一格到(25,10)',
                '出门后立即UP重新进屋；重复往返至少三次',
                '门毯左右移动/朝上移动不应误传送，室内存读档后再出门',
            ]}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--gold-root', type=Path, required=True,
                        help='MUS-1.0.1 Gold reference source root')
    parser.add_argument('--json-out', type=Path, required=True)
    args = parser.parse_args(argv)
    report = audit(args.project, args.gold_root)
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    passed = sum(x['status'] == 'PASS' for x in report['checks'])
    print(json.dumps({'status': report['status'], 'checks': len(report['checks']),
                      'passed': passed, 'failed': len(report['errors']),
                      'runtime_verified': False, 'phone_accepted': False}, ensure_ascii=False))
    return 0 if report['status'] == 'PASS_STATIC_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
