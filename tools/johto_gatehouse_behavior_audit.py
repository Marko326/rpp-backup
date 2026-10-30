#!/usr/bin/env python3
"""Audit Gold gatehouse collision semantics and current stable-ID Johto activation contracts.

The Gold inventory is sourced only from the supplied MUS-1.0.1 tree. Current
RPP gate activation is read from its stable-ID table and explicit per-gate contracts. This is a static audit: a
Gold role/contract match does not prove a built ROM behaves correctly.
"""
from __future__ import annotations
import argparse
import json
import re
from collections import Counter
from pathlib import Path

from johto_gold_door_audit import (
    GATE_CARPETS, GATE_SOLID_DOORS, GoldCollisionIndex, gold_gate_approach_rule,
    gold_gate_arrival_step, inspect as inspect_gold,
)
from johto_warp_arrival_audit import audit as audit_warp_arrival, _gold_warp_events

CONTRACT_PATH = 'tools/johto_pilot_door_contracts.json'
EXPECTED_ROLES = {
    'DOOR': 26,
    'WARP_CARPET_DOWN': 30,
    'WARP_CARPET_LEFT': 22,
    'WARP_CARPET_RIGHT': 22,
}


def _check(checks: list[dict], errors: list[str], name: str, ok: bool, detail: str) -> None:
    checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
    if not ok:
        errors.append(f'{name}: {detail}')


def _constants(root: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    for relative in ('constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm'):
        text = (root / relative).read_text(encoding='utf-8')
        for name, value in re.findall(r'(?m)^\s*DEF\s+([A-Za-z_][A-Za-z_0-9]*)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)\b', text):
            result[name] = int(value[1:], 16) if value.startswith('$') else int(value)
    return result


def _active_stable_ids(root: Path) -> set[int]:
    constants = _constants(root)
    slot_text = (root / 'data/johto_stable_id_slots.asm').read_text(encoding='utf-8')
    num_match = re.search(r'(?m)^\s*DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)\b',
                          (root / 'constants/region_map_constants.asm').read_text(encoding='utf-8'))
    if not num_match:
        raise ValueError('NUM_JOHTO_ACTIVE_MAPS missing')
    active_count = int(num_match[1])
    active: set[int] = set()
    rows = 0
    for line in slot_text.splitlines():
        code, sep, comment = line.partition(';')
        range_match = re.search(r'\$([0-9a-fA-F]{2})\s*-\s*\$([0-9a-fA-F]{2})', comment)
        m = re.match(r'\s*db\s+(.+)$', code)
        if not range_match or not m:
            continue
        start, end = int(range_match[1], 16), int(range_match[2], 16)
        tokens = [x.strip() for x in m[1].split(',')]
        if len(tokens) != end - start + 1:
            raise ValueError(f'stable slot row length mismatch at {comment.strip()}')
        rows += len(tokens)
        for index, token in enumerate(tokens):
            if token == 'JOHTO_INVALID_ACTIVE_SLOT':
                continue
            if token in constants:
                slot = constants[token]
            elif token.startswith('$'):
                slot = int(token[1:], 16)
            elif token.isdecimal():
                slot = int(token)
            else:
                raise ValueError(f'unresolved active slot token: {token}')
            if slot < active_count:
                active.add(start + index)
    if rows != 256:
        raise ValueError(f'stable slot table has {rows} entries, expected 256')
    return active


def _gate_ids(root: Path) -> dict[int, list[str]]:
    constants = _constants(root)
    result: dict[int, list[str]] = {}
    for name, value in constants.items():
        if 'GATE' in name and name.endswith('_LOCAL_ID'):
            result.setdefault(value, []).append(name)
    return result


def audit(project: Path, gold: Path) -> dict:
    project, gold = Path(project).resolve(), Path(gold).resolve()
    checks: list[dict] = []
    errors: list[str] = []
    try:
        contract_path = project / CONTRACT_PATH
        if not contract_path.is_file() or contract_path.is_symlink():
            raise FileNotFoundError(f'missing current door contract: {CONTRACT_PATH}')
        contract = json.loads(contract_path.read_text(encoding='utf-8'))
        gold_summary = inspect_gold(gold)
        index = GoldCollisionIndex(gold)
        inventory = index.gate_warp_inventory()
        active_ids = _active_stable_ids(project)
        gate_ids = _gate_ids(project)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        return {'schema': 'johto-gatehouse-behavior-audit-v1', 'status': 'FAIL',
                'checks': checks, 'errors': [str(exc)], 'runtime_verified': False,
                'rom_built': False, 'phone_accepted': False}

    _check(checks, errors, 'gold_source_integrity', not gold_summary.get('errors'),
           f"MUS source errors={len(gold_summary.get('errors', []))}; "
           f"registered maps={gold_summary.get('stats', {}).get('registered_maps')}")
    total_warps = sum(len(row['warps']) for row in inventory)
    roles = Counter(warp['collision_role'] for row in inventory for warp in row['warps'])
    _check(checks, errors, 'gold_gate_inventory_size',
           len(inventory) == 24 and total_warps == 100,
           f'gate maps={len(inventory)}, warp events={total_warps}')
    _check(checks, errors, 'gold_gate_collision_role_counts', dict(roles) == EXPECTED_ROLES,
           f'expected={EXPECTED_ROLES}; actual={dict(roles)}')

    semantic_errors = []
    for row in inventory:
        for warp in row['warps']:
            role = warp['collision_role']
            if role in GATE_SOLID_DOORS:
                expected_trigger, expected_direction = 'STEP_ON', 'UP'
                expected_arrival = 'D_DOWN'
            elif role in GATE_CARPETS:
                expected_trigger = 'COLLISION_ONLY'
                expected_direction = role.removeprefix('WARP_CARPET_')
                expected_arrival = 'NONE'
            else:
                semantic_errors.append(f"{row['gold_map']} {warp}: unsupported gate collision role")
                continue
            rule = gold_gate_approach_rule(role, 'COLLISION_ONLY')
            actual_arrival = gold_gate_arrival_step(role)
            if not rule or rule != (expected_trigger, expected_direction) or actual_arrival != expected_arrival:
                semantic_errors.append(f"{row['gold_map']} {warp}: trigger={rule}, arrival={actual_arrival}")
            if warp.get('trigger_contract') != expected_trigger:
                semantic_errors.append(f"{row['gold_map']} {warp}: inventory trigger {warp.get('trigger_contract')} != {expected_trigger}")
            if expected_trigger == 'COLLISION_ONLY' and warp.get('collision_direction') != expected_direction:
                semantic_errors.append(f"{row['gold_map']} {warp}: direction {warp.get('collision_direction')} != {expected_direction}")
    _check(checks, errors, 'gold_gate_trigger_and_arrival_semantics', not semantic_errors,
           f'validated {total_warps} gates; semantic errors={semantic_errors[:8]}')

    _check(checks, errors, 'contract_schema',
           contract.get('schema') == 'johto-pilot-door-contracts-v1' and
           contract.get('gold_reference') == 'MUS-1.0.1',
           f"schema={contract.get('schema')}, reference={contract.get('gold_reference')}")
    routes = contract.get('active_routes', [])
    _check(checks, errors, 'active_house_contract_count',
           len(routes) == 3 and {row.get('id') for row in routes} == {
               'cherrygrove_to_guide_house', 'guide_house_left_exit', 'guide_house_right_exit'},
           f'current enabled doorway contract rows={len(routes)}')
    phone_tests = contract.get('required_phone_tests', [])
    _check(checks, errors, 'phone_test_contract', len(phone_tests) >= 5 and
           contract.get('evidence_boundary', {}).get('phone_accepted') is False,
           f'phone test cases={len(phone_tests)}; contract does not claim acceptance')

    gate_ids_by_value = _gate_ids(project)
    active_gate_ids = sorted(set(gate_ids_by_value).intersection(active_ids))
    gate_contracts = contract.get('gatehouse_activation_policy', {}).get('active_gatehouse_contracts', [])
    contract_ids = {row.get('stable_id') for row in gate_contracts if isinstance(row, dict)}
    missing_contracts = [value for value in active_gate_ids if value not in contract_ids]
    extra_contracts = sorted(contract_ids - set(active_gate_ids))
    _check(checks, errors, 'no_uncontracted_gatehouse_activation',
           not missing_contracts and not extra_contracts,
           f'active gate IDs={active_gate_ids}; missing contracts={missing_contracts}; inactive contracts={extra_contracts}')
    gate_contracts_by_id = {row.get('stable_id'): row for row in gate_contracts if isinstance(row, dict)}

    # Keep the already accepted Route31/Violet horizontal gate contract exact.
    gate_errors = []
    gate_contract = gate_contracts_by_id.get(6)
    if gate_contract is None:
        gate_errors.append('missing stable ID 6 contract')
    else:
        if gate_contract.get('gold_map') != 'Route31VioletGate' or gate_contract.get('runtime_tileset') != 'JOHTO_GATE':
            gate_errors.append('wrong Route31/Violet gate reference/tileset')
        got = gate_contract.get('warp_contracts', [])
        expected = [
            ('route31_0', 4, 0, [4, 6], 'LEFT', 'COLLISION_ONLY', 6, 2, [9, 4]),
            ('route31_1', 4, 1, [4, 7], 'LEFT', 'COLLISION_ONLY', 6, 3, [9, 5]),
            ('violet_0', 5, 0, [39, 24], 'RIGHT', 'COLLISION_ONLY', 6, 0, [0, 4]),
            ('violet_1', 5, 1, [39, 25], 'RIGHT', 'COLLISION_ONLY', 6, 1, [0, 5]),
            ('gate_to_violet_0', 6, 0, [0, 4], 'LEFT', 'COLLISION_ONLY', 5, 0, [39, 24]),
            ('gate_to_violet_1', 6, 1, [0, 5], 'LEFT', 'COLLISION_ONLY', 5, 1, [39, 25]),
            ('gate_to_route31_0', 6, 2, [9, 4], 'RIGHT', 'COLLISION_ONLY', 4, 0, [4, 6]),
            ('gate_to_route31_1', 6, 3, [9, 5], 'RIGHT', 'COLLISION_ONLY', 4, 1, [4, 7]),
        ]
        records = [(r.get('id'), r.get('source_stable_id'), r.get('source_warp_ordinal'),
                    r.get('source_xy'), r.get('direction'), r.get('trigger'),
                    r.get('target_stable_id'), r.get('target_warp_ordinal'), r.get('target_xy')) for r in got]
        if records != expected or any(r.get('arrival_auto_step') != 'NONE' for r in got):
            gate_errors.append('ID6 contract differs from its eight Gold directional routes')
        try:
            gold_route = _gold_warp_events(gold, 'Route31')[:2]
            gold_city = [r for r in _gold_warp_events(gold, 'VioletCity') if r['destination']=='ROUTE_31_VIOLET_GATE']
            gold_gate = _gold_warp_events(gold, 'Route31VioletGate')
            if [(r['x'],r['y'],r['destination_warp_number']) for r in gold_route] != [(4,6,3),(4,7,4)]:
                gate_errors.append('MUS Route31 entry mismatch')
            if [(r['x'],r['y'],r['destination_warp_number']) for r in gold_city] != [(39,24,1),(39,25,2)]:
                gate_errors.append('MUS Violet City entry mismatch')
            if [(r['x'],r['y'],r['destination_warp_number']) for r in gold_gate] != [(0,4,8),(0,5,9),(9,4,1),(9,5,2)]:
                gate_errors.append('MUS gate return mismatch')
            gold_sources = (
                ('Route31',4,6),('Route31',4,7),
                ('VioletCity',39,24),('VioletCity',39,25),
                ('Route31VioletGate',0,4),('Route31VioletGate',0,5),
                ('Route31VioletGate',9,4),('Route31VioletGate',9,5),
            )
            for row, (map_name,x,y) in zip(got, gold_sources):
                role = index.role_at(map_name,x,y)
                actual_rule = gold_gate_approach_rule(role,'COLLISION_ONLY')
                if actual_rule != (row.get('trigger'),row.get('direction')):
                    gate_errors.append(f'MUS collision mismatch {map_name}({x},{y}): {role} -> {actual_rule}')
                if row.get('arrival_auto_step') != gold_gate_arrival_step(role):
                    gate_errors.append(f'MUS arrival mismatch {map_name}({x},{y})')
            source = (project/'data/johto_gate_runtime.asm').read_text()
            object_rows = re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR',source)
            if object_rows != [('4','0','0'),('5','0','1'),('4','9','0'),('5','9','1')]:
                gate_errors.append('ID6 runtime object warp positions/target indices mismatch')
        except (OSError, ValueError) as exc:
            gate_errors.append(str(exc))
    _check(checks, errors, 'active_gatehouse_exact_contract', not gate_errors,
           f'ID6 Route31/Violet gate: four doorway pairs, eight Gold routes; errors={gate_errors}')

    # The newly active South Gate is horizontal like the accepted Violet gate,
    # but its source Gold warp numbers differ from compact runtime ordinals:
    # Route32's enabled Gold warps are #2/#3, while its compact object rows are 0/1;
    # Ruins' enabled Gold warps are #10/#11, while its compact object rows are 0/1.
    south_errors = []
    south = gate_contracts_by_id.get(102)
    if south is None:
        south_errors.append('missing stable ID 102 contract')
    else:
        if south.get('gold_map') != 'Route32RuinsOfAlphGate' or south.get('runtime_tileset') != 'JOHTO_GATE':
            south_errors.append('wrong South Gate Gold map or runtime tileset')
        if south.get('runtime_object_file') != 'data/johto_ruins_south_runtime.asm' or south.get('runtime_object_label') != 'JohtoPilotAlphSouthGateRuntimeObjects':
            south_errors.append('wrong South Gate runtime object source')
        got = south.get('warp_contracts', [])
        expected = [
            ('route32_to_south_gate_0', 7, 0, [4, 2], 'LEFT', 'COLLISION_ONLY', 102, 2, [9, 4]),
            ('route32_to_south_gate_1', 7, 1, [4, 3], 'LEFT', 'COLLISION_ONLY', 102, 3, [9, 5]),
            ('south_gate_to_ruins_0', 102, 0, [0, 4], 'LEFT', 'COLLISION_ONLY', 20, 0, [13, 20]),
            ('south_gate_to_ruins_1', 102, 1, [0, 5], 'LEFT', 'COLLISION_ONLY', 20, 1, [13, 21]),
            ('south_gate_to_route32_0', 102, 2, [9, 4], 'RIGHT', 'COLLISION_ONLY', 7, 0, [4, 2]),
            ('south_gate_to_route32_1', 102, 3, [9, 5], 'RIGHT', 'COLLISION_ONLY', 7, 1, [4, 3]),
            ('ruins_to_south_gate_0', 20, 0, [13, 20], 'RIGHT', 'COLLISION_ONLY', 102, 0, [0, 4]),
            ('ruins_to_south_gate_1', 20, 1, [13, 21], 'RIGHT', 'COLLISION_ONLY', 102, 1, [0, 5]),
        ]
        records = [(r.get('id'), r.get('source_stable_id'), r.get('source_warp_ordinal'),
                    r.get('source_xy'), r.get('direction'), r.get('trigger'),
                    r.get('target_stable_id'), r.get('target_warp_ordinal'), r.get('target_xy')) for r in got]
        if records != expected or any(r.get('arrival_auto_step') != 'NONE' for r in got):
            south_errors.append('ID102 contract differs from the eight horizontal Gold routes')
        gold_destination = {7: 'ROUTE_32', 20: 'RUINS_OF_ALPH_OUTSIDE', 102: 'ROUTE_32_RUINS_OF_ALPH_GATE'}
        stable_symbol = {value: name for name, value in _constants(project).items()
                         if name.endswith('_LOCAL_ID')}
        runtime_route_source = (project/'engine/johto_pilot_runtime.asm').read_text()
        route_body = runtime_route_source.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        actual_routes = set(re.findall(r'(?m)^\s*db\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+)',route_body))
        try:
            for row in got:
                source_map = row.get('source_gold_map')
                source_number = row.get('source_gold_warp_number_one_based')
                target_map = row.get('target_gold_map')
                target_number = row.get('target_gold_warp_number_one_based')
                events = _gold_warp_events(gold, source_map)
                if not isinstance(source_number, int) or source_number < 1 or source_number > len(events):
                    south_errors.append(f'{row.get("id")}: invalid Gold source warp number')
                    continue
                event = events[source_number - 1]
                expected_event = (row.get('source_xy', [None,None])[0], row.get('source_xy', [None,None])[1],
                                  gold_destination.get(row.get('target_stable_id')), target_number)
                actual_event = (event['x'], event['y'], event['destination'], event['destination_warp_number'])
                if actual_event != expected_event:
                    south_errors.append(f'{row.get("id")}: Gold warp {actual_event} != {expected_event}')
                role = index.role_at(source_map, *row.get('source_xy', [None,None]))
                rule = gold_gate_approach_rule(role, row.get('trigger'))
                if rule != (row.get('trigger'), row.get('direction')) or gold_gate_arrival_step(role) != row.get('arrival_auto_step'):
                    south_errors.append(f'{row.get("id")}: Gold collision/arrival {role} -> {rule}')
                source_symbol = stable_symbol.get(row.get('source_stable_id'))
                target_symbol = stable_symbol.get(row.get('target_stable_id'))
                route = (source_symbol, str(row.get('source_warp_ordinal')), target_symbol)
                if None in route or route not in actual_routes:
                    south_errors.append(f'{row.get("id")}: registered runtime route missing {route}')
            object_file = (project / south['runtime_object_file']).read_text()
            object_body = object_file.split(south['runtime_object_label'] + '::',1)[1].split('JohtoPilotAlphOutsideRuntimeHeader::',1)[0]
            object_rows = re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR',object_body)
            expected_object_rows = [(str(r['source_xy'][1]), str(r['source_xy'][0]), str(r['target_warp_ordinal']))
                                    for r in got if r.get('source_stable_id') == 102]
            if object_rows != expected_object_rows:
                south_errors.append(f'South Gate object rows {object_rows} != {expected_object_rows}')
        except (OSError, ValueError, KeyError, TypeError, IndexError) as exc:
            south_errors.append(str(exc))
    _check(checks, errors, 'active_south_gate_exact_contract', not south_errors,
           f'ID102 South Gate: 8 Gold/runtime directional routes, no auto-step; errors={south_errors[:8]}')

    # Runtime direction guard is separate from the static object contract:
    # the existing RPP CheckWarpsCollision matches a coordinate alone.
    try:
        gate_runtime = (project/'engine/johto_pilot_runtime.asm').read_text()
        overworld = (project/'home/overworld.asm').read_text()
        direction_body = gate_runtime.split('JohtoPilotGateCollisionExitAllowed::', 1)[1]
        collision_body = overworld.split('CheckWarpsCollision::', 1)[1].split('CheckWarpsNoCollisionRetry1::', 1)[0]
        pass_direction = all(x in direction_body for x in (
            'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID',
            'cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID',
            'cp PLAYER_DIR_LEFT', 'cp PLAYER_DIR_RIGHT',
            'cp JOHTO_ROUTE31_VIOLET_GATE_WIDTH * 2 - 1',
            'cp 4', 'cp 5', 'ld e, 1')) and \
            all(x in collision_body for x in ('callab JohtoPilotGateCollisionExitAllowed',
                'jr z, .retry2', 'push bc', 'pop bc', 'push hl', 'pop hl'))
    except (OSError, IndexError) as exc:
        pass_direction = False
    _check(checks, errors, 'gate_collision_direction_guard', pass_direction,
           'matched gate collision exit requires outward facing direction and correct pair of carpet cells')

    _check(checks, errors, 'future_gatehouse_fail_closed_policy',
           contract.get('gatehouse_activation_policy', {}).get('require_explicit_contract_before_activation') is True,
           'a gatehouse must have an explicit contract before its stable ID is activated')

    arrival = audit_warp_arrival(project, gold)
    _check(checks, errors, 'current_house_arrival_audit', arrival.get('status') == 'PASS_STATIC_ONLY',
           f"arrival audit={arrival.get('status')}; errors={arrival.get('errors', [])[:5]}")
    errors.extend('arrival_audit: ' + e for e in arrival.get('errors', []))

    return {'schema': 'johto-gatehouse-behavior-audit-v1',
            'status': 'PASS_REFERENCE_ONLY' if not errors else 'FAIL',
            'project': str(project), 'gold_reference': str(gold),
            'checks': checks, 'errors': errors,
            'gold_gate_inventory': {'maps': len(inventory), 'warp_events': total_warps,
                                    'collision_roles': dict(roles)},
            'current_active_map_ids': sorted(active_ids),
            'current_active_gate_ids': active_gate_ids,
            'future_gatehouse_contracts': gate_contracts,
            'arrival_audit_status': arrival.get('status'),
            'runtime_verified': False, 'rom_built': False, 'phone_accepted': False,
            'note': 'Gold reference semantics and current source contracts passed; no ROM/runtime behavior is inferred.'}


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
    return 0 if report['status'] == 'PASS_REFERENCE_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
