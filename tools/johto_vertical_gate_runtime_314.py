#!/usr/bin/env python3
"""DEV-314/316 audit for the shared vertical-gate threshold runtime.

This validates profile tables and ASM dispatch shape, including the Route43
outdoor collision-only return carpet. It is source-only, not a ROM/device test.
"""
from __future__ import annotations

import re
from pathlib import Path

RUNTIME = 'data/johto_vertical_gate_runtime_314.asm'
MAP_DATA = 'data/johto_route43_mahogany_gate_313.asm'
ENGINE = 'engine/johto_pilot_runtime.asm'
OVERWORLD = 'home/overworld.asm'
MOVEMENT = 'engine/overworld/npc_movement.asm'
MAIN = 'main.asm'

EXPECTED = {
    'JohtoVerticalGateBeforeStepProfiles314': [
        ('JOHTO_MAHOGANY_TOWN_LOCAL_ID', 'PLAYER_DIR_UP', '9', '2'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '4', '6'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '5', '6'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '4', '1'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '5', '1'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '4', '6'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '5', '6'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '4', '1'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '5', '1'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_UP', '17', '36'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_UP', '14', '6'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_DOWN', '7', '32'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_DOWN', '8', '32'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_RIGHT', '7', '33'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_LEFT', '8', '33'),
        ('JOHTO_ROUTE_29_LOCAL_ID', 'PLAYER_DIR_UP', '27', '2'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '4', '6'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '5', '6'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '4', '1'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '5', '1'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', '17', '30'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', '18', '30'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_RIGHT', '17', '31'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_LEFT', '18', '31'),
    ],
    'JohtoVerticalGateAfterStepProfiles314': [
        ('JOHTO_MAHOGANY_TOWN_LOCAL_ID', 'PLAYER_DIR_UP', '9', '1', '2'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '4', '7', '1'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '5', '7', '1'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '4', '0', '2'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '5', '0', '2'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', '9', '51', '1'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', '10', '51', '1'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '4', '7', '1'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '5', '7', '1'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '4', '0', '2'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '5', '0', '2'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_UP', '17', '35', '2'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_UP', '14', '5', '2'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_DOWN', '7', '33', '1'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_DOWN', '8', '33', '1'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_RIGHT', '8', '33', '3'),
        ('JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_LEFT', '7', '33', '3'),
        ('JOHTO_ROUTE_29_LOCAL_ID', 'PLAYER_DIR_UP', '27', '1', '2'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '4', '7', '1'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', '5', '7', '1'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '4', '0', '2'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'PLAYER_DIR_UP', '5', '0', '2'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', '17', '31', '1'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', '18', '31', '1'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_RIGHT', '18', '31', '3'),
        ('JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_LEFT', '17', '31', '3'),
    ],
    'JohtoVerticalGateArrivalProfiles314': [
        ('JOHTO_MAHOGANY_TOWN_LOCAL_ID', '9', '1', 'D_DOWN'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', '4', '0', 'D_DOWN'),
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', '5', '0', 'D_DOWN'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', '4', '0', 'D_DOWN'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', '5', '0', 'D_DOWN'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', '4', '0', 'D_DOWN'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', '5', '0', 'D_DOWN'),
        ('JOHTO_ROUTE_46_LOCAL_ID', '14', '5', 'D_DOWN'),
        ('JOHTO_ROUTE_29_LOCAL_ID', '27', '1', 'D_DOWN'),
        ('JOHTO_ROUTE_43_LOCAL_ID', '17', '35', 'D_DOWN'),
    ],
    'JohtoVerticalGateBoundsProfiles314': [
        ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', '10', '8'),
        ('JOHTO_ROUTE_43_GATE_LOCAL_ID', '10', '8'),
        ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', '10', '8'),
        ('JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID', '10', '8'),
        ('JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID', '10', '8'),
    ],
}
END_LABELS = {
    'JohtoVerticalGateBeforeStepProfiles314': 'JohtoVerticalGateBeforeStepProfilesEnd314',
    'JohtoVerticalGateAfterStepProfiles314': 'JohtoVerticalGateAfterStepProfilesEnd314',
    'JohtoVerticalGateArrivalProfiles314': 'JohtoVerticalGateArrivalProfilesEnd314',
    'JohtoVerticalGateBoundsProfiles314': 'JohtoVerticalGateBoundsProfilesEnd314',
}


def _section(text: str, start: str, end: str) -> str:
    a = re.findall(r'(?m)^' + re.escape(start) + r'::?\s*$', text)
    if len(a) != 1:
        raise ValueError(f'{start}: expected one start label, got {len(a)}')
    tail = text.split(start + '::', 1)[1]
    parts = re.split(r'(?m)^' + re.escape(end) + r'::?\s*$', tail)
    if len(parts) != 2:
        raise ValueError(f'{end}: expected one end label')
    return parts[0]


def _rows(text: str, start: str, end: str) -> list[tuple[str, ...]]:
    body = _section(text, start, end)
    rows: list[tuple[str, ...]] = []
    for raw in body.splitlines():
        code = raw.split(';', 1)[0].strip()
        if not code:
            continue
        m = re.fullmatch(r'db\s+(.+)', code)
        if not m:
            raise ValueError(f'{start}: unsupported profile row: {code}')
        values = tuple(x.strip() for x in m.group(1).split(','))
        if values == ('$ff',):
            continue
        rows.append(values)
    return rows


def _matches(rows: list[tuple[str, ...]], map_id: str, direction: str,
             x: int, y: int, *, result: bool = False) -> int:
    for row in rows:
        if len(row) < 4:
            continue
        if row[0] == map_id and row[1] == direction and row[2] == str(x) and row[3] == str(y):
            return int(row[4]) if result and len(row) > 4 else 1
    return 0


def _edge_result(bounds: list[tuple[str, ...]], map_id: str,
                 x: int, y: int, direction: str) -> int:
    row = next((r for r in bounds if r[0] == map_id), None)
    if row is None:
        return 0
    width, height = int(row[1]), int(row[2])
    blocked = {
        'PLAYER_DIR_UP': y == 0,
        'PLAYER_DIR_DOWN': y == height - 1,
        'PLAYER_DIR_LEFT': x == 0,
        'PLAYER_DIR_RIGHT': x == width - 1,
    }
    return int(blocked.get(direction, False))


def simulate(root: Path) -> dict:
    return _simulate_text((Path(root) / RUNTIME).read_text(encoding='utf-8'))




def audit(root: Path, *, text_overrides: dict[str, str] | None = None) -> dict:
    root = Path(root).resolve()
    overrides = text_overrides or {}
    checks: list[dict] = []
    errors: list[str] = []

    def read(rel: str) -> str:
        return overrides[rel] if rel in overrides else (root / rel).read_text(encoding='utf-8')

    def ck(name: str, okay: bool, detail: str = '') -> None:
        checks.append({'check': name, 'status': 'PASS' if okay else 'FAIL', 'detail': detail})
        if not okay:
            errors.append(f'{name}: {detail}')

    try:
        runtime = read(RUNTIME)
        map_data = read(MAP_DATA)
        engine = read(ENGINE)
        overworld = read(OVERWORLD)
        movement = read(MOVEMENT)
        main = read(MAIN)
        for label, expected in EXPECTED.items():
            actual = _rows(runtime, label, END_LABELS[label])
            ck('profile_' + label, actual == expected,
               f'actual={actual}; expected={expected}')
        sim = simulate(root) if not text_overrides else _simulate_text(runtime)
        ck('before_step_profiles', sim['before_thresholds'], str(sim['before_rows']))
        ck('after_step_profiles', sim['after_thresholds'], str(sim['after_rows']))
        ck('route43_south_ID65_carpet_not_pre_step_bypassed',
           sim['route43_carpet_not_pre_step_bypassed'],
           'only south ID65 y=51/down stays on the y=52 collision path')
        ck('route43_north_ID66_carpet_reentry_and_lane_change',
           sim['id66_carpet_reentry_and_lane_change'],
           'north ID66 pair allows y=30/down re-entry and left/right movement between x=17/18')
        ck('route43_north_ID66_lane_change_not_collision_exit',
           sim['id66_lane_change_not_collision_exit'],
           'E=3 lane changes must not be accepted by the E=1-only CollisionExit hook')
        ck('route46_south_gate_carpet_lane_change',
           sim['route46_carpet_lane_change_not_collision_exit'],
           'Route46 (7,33) <-> (8,33) lateral movement is E=3 and cannot trigger a DOWN Warp')
        ck('route29_north_door_entry', sim['route29_door_entry_step_on'],
           'Route29 (27,2) UP -> Gold DOOR (27,1) is an exact STEP_ON entry; arrival steps D_DOWN')
        ck('town_door_arrival_auto_step', sim['town_arrival_step'] == 128,
           f"D_DOWN value={sim['town_arrival_step']}")
        ck('gate_carpet_arrival_stays_put', sim['gate_carpet_no_autostep'],
           'no auto-step row for the interior carpet landing')
        ck('closed_gate_bounds', sim['closed_edge_dimensions'],
           f"bounds={sim['bounds_rows']}")
        ck('closed_gate_edges', sim['closed_edge_cases'] == {
            'up': 1, 'down': 1, 'left': 1, 'right': 1,
            'interior': 0, 'town_not_profiled': 0,
            'id66_up': 1, 'id66_down': 1, 'id66_left': 1, 'id66_right': 1,
            'id66_interior': 0,
            'id74_up': 1, 'id74_down': 1, 'id74_left': 1, 'id74_right': 1, 'id74_interior': 0},
           f"edge behavior={sim['closed_edge_cases']}")
        routines = {
            'JohtoVerticalGateBeforeStep314': ('JohtoVerticalGateAfterStep314',
                'JohtoVerticalGateBeforeStepProfiles314',
                ('wCurLocalMapID', 'wPlayerDirection', 'wXCoord', 'wYCoord', 'ld e, 1', 'ld e, 0')),
            'JohtoVerticalGateAfterStep314': ('JohtoVerticalGateCollisionExit314',
                'JohtoVerticalGateAfterStepProfiles314',
                ('wCurLocalMapID', 'wPlayerDirection', 'wXCoord', 'wYCoord', 'ld e, b', 'ld de, 4', 'add hl, de')),
            'JohtoVerticalGateArrivalStep314': ('JohtoVerticalGateClosedEdge314',
                'JohtoVerticalGateArrivalProfiles314',
                ('wCurLocalMapID', 'wXCoord', 'wYCoord', 'ld e, b', 'ld de, 3', 'add hl, de')),
            'JohtoVerticalGateClosedEdge314': ('ASSERT BANK(',
                'JohtoVerticalGateBoundsProfiles314',
                ('wCurLocalMapID', 'wPlayerDirection', 'wXCoord', 'wYCoord', 'dec b', 'dec c', 'ld e, 1')),
        }
        for routine, (end_label, table, required) in routines.items():
            body = runtime.split(routine + '::', 1)[1].split(end_label + ('::' if end_label != 'ASSERT BANK(' else ''), 1)[0]
            ck('routine_' + routine, f'ld hl, {table}' in body and
               all(token in body for token in required),
               f'{routine} must use {table} and implement {required}')
        collision = runtime.split('JohtoVerticalGateCollisionExit314::', 1)[1].split('\n; Gold door landing', 1)[0]
        ck('collision_exit_only_carpet', 'call JohtoVerticalGateAfterStep314' in collision and
           'cp 1' in collision and 'ld e, 0' in collision,
           'only configured E=1 carpet rows may exit by collision')
        ck('shared_runtime_included_once', main.count(f'INCLUDE "{RUNTIME}"') == 1,
           f'include count={main.count(f"INCLUDE \\\"{RUNTIME}\\\"")}')
        old_labels = ('JohtoRoute43MahoganyGateBeforeStep313', 'JohtoRoute43MahoganyGateAfterStep313',
                      'JohtoRoute43MahoganyGateCollisionExit313', 'JohtoRoute43MahoganyGateArrivalStep313',
                      'JohtoRoute43MahoganyGateClosedEdge313')
        ck('no_per_gate_helper_copies', not any(label in map_data + engine for label in old_labels),
           'ID65 uses the shared profile runtime, not map-specific branch copies')
        ck('engine_dispatches_shared_runtime', all(('callab ' + name) in engine for name in (
            'JohtoVerticalGateBeforeStep314', 'JohtoVerticalGateAfterStep314',
            'JohtoVerticalGateCollisionExit314', 'JohtoVerticalGateArrivalStep314',
            'JohtoVerticalGateClosedEdge314')),
           'all five movement/arrival hooks route through the shared runtime')
        # The profile table is only useful if the original movement/warp hooks
        # actually reach it. Guard each stage of the live path, not just the
        # helper's existence: approach -> step-on Warp -> collision-only exit
        # -> arrival re-arm/facing.
        collision_entry = overworld.split('CollisionCheckOnLand::', 1)[1].split('ExtraWarpCheck::', 1)[0]
        no_collision_warps = overworld.split('CheckWarpsNoCollisionLoop::', 1)[1].split('CheckWarpsCollision::', 1)[0]
        collision_warps = overworld.split('CheckWarpsCollision::', 1)[1].split('ExtraWarpCheck::', 1)[0]
        extra_warp = overworld.split('ExtraWarpCheck::', 1)[1].split('CollisionCheckOnLand::', 1)[0]
        step_out = movement.split('PlayerStepOutFromDoor:', 1)[1].split('_EndNPCMovementScript:', 1)[0]
        ck('live_gate_approach_hook', 'callab JohtoPilotGateDoorApproachAllowed' in collision_entry,
           'CollisionCheckOnLand must consult the before-step profile before normal collision blocks the door/carpet')
        ck('live_gate_step_on_warp_hook', 'callab JohtoPilotGateDoorWarpMatched' in no_collision_warps,
           'matched Gold DOOR coordinates must consult the after-step profile before WarpFound1')
        ck('live_gate_collision_exit_hook', 'callab JohtoPilotGateCollisionExitAllowed' in collision_warps,
           'collision-only carpets must pass the direction-specific exit guard')
        ck('live_gate_exterior_carpet_hook', 'callab JohtoPilotGateExteriorCollisionAllowed' in extra_warp,
           'exterior carpet collisions must consult the exact registered gate profile before generic edge checks')
        ck('live_gate_arrival_hook', 'callab JohtoPilotGateArrivalStep' in step_out,
           'door step-out must apply the destination gate arrival profile')
        dispatch_helper = engine.split('JohtoPilotIsVerticalGatePairMap314::', 1)[1].split('JohtoPilotGateArrivalStep::', 1)[0]
        ck('single_vertical_gate_map_allowlist',
           'cp JOHTO_MAHOGANY_TOWN_LOCAL_ID' in dispatch_helper and
           'cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID' in dispatch_helper and
           'cp JOHTO_ROUTE_43_GATE_LOCAL_ID' in dispatch_helper and
           'cp JOHTO_ROUTE_43_LOCAL_ID' in dispatch_helper and
           'cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID' in dispatch_helper and
           'cp JOHTO_ROUTE_46_LOCAL_ID' in dispatch_helper and
           'cp JOHTO_ROUTE_29_LOCAL_ID' in dispatch_helper and
           all(dispatch_helper.count('cp ' + map_id) == 1 for map_id in (
               'JOHTO_MAHOGANY_TOWN_LOCAL_ID', 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID',
               'JOHTO_ROUTE_43_GATE_LOCAL_ID', 'JOHTO_ROUTE_43_LOCAL_ID',
               'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 'JOHTO_ROUTE_46_LOCAL_ID',
               'JOHTO_ROUTE_29_LOCAL_ID')) and
           engine.count('call JohtoPilotIsVerticalGatePairMap314') == 5,
           'Mahogany, ID65/66/74 gates, Route29, Route43 and Route46 are listed once; all five hooks call the common predicate')
        ck('id66_active_header_and_resource',
           'JohtoRoute43GateRuntimeHeader' in read('data/johto_header_descriptors.asm') and
           'JOHTO_ROUTE_43_GATE_LOCAL_ID' in read('data/johto_pilot_runtime_assets.asm') and
           'JohtoRoute43GateRuntimeHeader' in read('data/johto_route43_gate_319.asm'),
           'ID66 has its active header and runtime resource descriptor')
        gate66 = read('data/johto_route43_gate_319.asm')
        ck('id65_and_id66_gold_warps_registered',
           'db 4 ; Gold lower 2 carpets + upper 2 DOORs, Route43 (ID67) now active' in map_data and
           map_data.count('JOHTO_REGISTERED_WARP_SELECTOR') == 4 and
           'db 4 ; Gold #1/#2 top DOORs -> Route43 north carpets #4/#5' in gate66 and
           gate66.count('JOHTO_REGISTERED_WARP_SELECTOR') == 4,
           'ID65 and ID66 each retain four exact Gold Warp entries')
    except (OSError, ValueError, KeyError, IndexError) as exc:
        ck('read_and_parse', False, str(exc))
    return {'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks': checks, 'errors': errors,
            'runtime_verified': False, 'rom_built': False}


def _simulate_text(runtime: str) -> dict:
    before = _rows(runtime, 'JohtoVerticalGateBeforeStepProfiles314',
                   'JohtoVerticalGateBeforeStepProfilesEnd314')
    after = _rows(runtime, 'JohtoVerticalGateAfterStepProfiles314',
                  'JohtoVerticalGateAfterStepProfilesEnd314')
    arrival = _rows(runtime, 'JohtoVerticalGateArrivalProfiles314',
                    'JohtoVerticalGateArrivalProfilesEnd314')
    bounds = _rows(runtime, 'JohtoVerticalGateBoundsProfiles314',
                   'JohtoVerticalGateBoundsProfilesEnd314')
    before_ok = (
        _matches(before, 'JOHTO_MAHOGANY_TOWN_LOCAL_ID', 'PLAYER_DIR_UP', 9, 2) == 1 and
        all(_matches(before, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 6) == 1 for x in (4,5)) and
        all(_matches(before, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_UP', x, 1) == 1 for x in (4,5)) and
        all(_matches(before, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 6) == 1 for x in (4,5)) and
        all(_matches(before, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_UP', x, 1) == 1 for x in (4,5)) and
        _matches(before, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_UP', 17, 36) == 1 and
        all(_matches(before, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 30) == 1 for x in (17,18)) and
        _matches(before, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_RIGHT', 17, 31) == 1 and
        _matches(before, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_LEFT', 18, 31) == 1 and
        all(_matches(before, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 51) == 0 for x in (9,10)))
    after_ok = (
        _matches(after, 'JOHTO_MAHOGANY_TOWN_LOCAL_ID', 'PLAYER_DIR_UP', 9, 1, result=True) == 2 and
        all(_matches(after, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 7, result=True) == 1 for x in (4,5)) and
        all(_matches(after, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'PLAYER_DIR_UP', x, 0, result=True) == 2 for x in (4,5)) and
        all(_matches(after, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 7, result=True) == 1 for x in (4,5)) and
        all(_matches(after, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 'PLAYER_DIR_UP', x, 0, result=True) == 2 for x in (4,5)) and
        all(_matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 51, result=True) == 1 for x in (9,10)) and
        _matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_UP', 17, 35, result=True) == 2 and
        all(_matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 31, result=True) == 1 for x in (17,18)) and
        _matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_RIGHT', 18, 31, result=True) == 3 and
        _matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_LEFT', 17, 31, result=True) == 3)
    arrival_step = next((128 for row in arrival if row[:3] == ('JOHTO_MAHOGANY_TOWN_LOCAL_ID', '9', '1') and row[3] == 'D_DOWN'), 0)
    no_carpet_autostep = (
        not any(row[0] in ('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 'JOHTO_ROUTE_43_GATE_LOCAL_ID',
                           'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID')
                and row[1:3] in (('4','7'),('5','7')) for row in arrival) and
        not any(row[0] == 'JOHTO_ROUTE_43_LOCAL_ID' and row[1:3] in
                (('9','51'),('10','51'),('17','31'),('18','31')) for row in arrival))
    bounds_row = next((row for row in bounds if row[0] == 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID'), None)
    gate66_bounds_row = next((row for row in bounds if row[0] == 'JOHTO_ROUTE_43_GATE_LOCAL_ID'), None)
    gate74_bounds_row = next((row for row in bounds if row[0] == 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID'), None)
    edge_ok = bool(bounds_row and bounds_row[1:] == ('10','8') and gate66_bounds_row and
                   gate66_bounds_row[1:] == ('10','8') and gate74_bounds_row and
                   gate74_bounds_row[1:] == ('10','8'))
    edge_cases = {
        'up': _edge_result(bounds, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 4, 0, 'PLAYER_DIR_UP'),
        'down': _edge_result(bounds, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 4, 7, 'PLAYER_DIR_DOWN'),
        'left': _edge_result(bounds, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 0, 3, 'PLAYER_DIR_LEFT'),
        'right': _edge_result(bounds, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 9, 3, 'PLAYER_DIR_RIGHT'),
        'interior': _edge_result(bounds, 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID', 4, 3, 'PLAYER_DIR_UP'),
        'town_not_profiled': _edge_result(bounds, 'JOHTO_MAHOGANY_TOWN_LOCAL_ID', 9, 0, 'PLAYER_DIR_UP'),
        'id66_up': _edge_result(bounds, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 4, 0, 'PLAYER_DIR_UP'),
        'id66_down': _edge_result(bounds, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 4, 7, 'PLAYER_DIR_DOWN'),
        'id66_left': _edge_result(bounds, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 0, 3, 'PLAYER_DIR_LEFT'),
        'id66_right': _edge_result(bounds, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 9, 3, 'PLAYER_DIR_RIGHT'),
        'id66_interior': _edge_result(bounds, 'JOHTO_ROUTE_43_GATE_LOCAL_ID', 4, 3, 'PLAYER_DIR_UP'),
        'id74_up': _edge_result(bounds, 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 4, 0, 'PLAYER_DIR_UP'),
        'id74_down': _edge_result(bounds, 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 4, 7, 'PLAYER_DIR_DOWN'),
        'id74_left': _edge_result(bounds, 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 0, 3, 'PLAYER_DIR_LEFT'),
        'id74_right': _edge_result(bounds, 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 9, 3, 'PLAYER_DIR_RIGHT'),
        'id74_interior': _edge_result(bounds, 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 4, 3, 'PLAYER_DIR_UP'),
    }
    lane_change_not_collision_exit = (
        _matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_RIGHT', 18, 31, result=True) == 3 and
        _matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_LEFT', 17, 31, result=True) == 3)
    route46_lane_change_not_collision_exit = (
        _matches(after, 'JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_RIGHT', 8, 33, result=True) == 3 and
        _matches(after, 'JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_LEFT', 7, 33, result=True) == 3)
    route46_cave_door = (
        _matches(before, 'JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_UP', 14, 6) == 1 and
        _matches(after, 'JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_UP', 14, 5, result=True) == 2 and
        any(row == ('JOHTO_ROUTE_46_LOCAL_ID','14','5','D_DOWN') for row in arrival) and
        _matches(after, 'JOHTO_ROUTE_46_LOCAL_ID', 'PLAYER_DIR_DOWN', 14, 5, result=True) == 0)
    route29_door_entry_step_on = (
        _matches(before, 'JOHTO_ROUTE_29_LOCAL_ID', 'PLAYER_DIR_UP', 27, 2) == 1 and
        _matches(after, 'JOHTO_ROUTE_29_LOCAL_ID', 'PLAYER_DIR_UP', 27, 1, result=True) == 2 and
        any(row[:3] == ('JOHTO_ROUTE_29_LOCAL_ID', '27', '1') and row[3] == 'D_DOWN' for row in arrival))
    return {
        'before_rows': before, 'after_rows': after, 'arrival_rows': arrival, 'bounds_rows': bounds,
        'before_thresholds': before_ok, 'after_thresholds': after_ok,
        'route43_carpet_not_pre_step_bypassed': (
            all(_matches(before, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 51) == 0 for x in (9,10)) and
            all(_matches(after, 'JOHTO_ROUTE_43_LOCAL_ID', 'PLAYER_DIR_DOWN', x, 51, result=True) == 1 for x in (9,10))),
        'id66_carpet_reentry_and_lane_change': before_ok and after_ok,
        'id66_lane_change_not_collision_exit': lane_change_not_collision_exit,
        'route46_carpet_lane_change_not_collision_exit': route46_lane_change_not_collision_exit,
        'route29_door_entry_step_on': route29_door_entry_step_on,
        'route46_cave_door': route46_cave_door,
        'town_arrival_step': arrival_step, 'gate_carpet_no_autostep': no_carpet_autostep,
        'closed_edge_dimensions': edge_ok, 'closed_edge_cases': edge_cases,
    }
