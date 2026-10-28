#!/usr/bin/env python3
"""Audit Gold gatehouse collision semantics and current PAL activation policy.

The Gold inventory is sourced only from the supplied MUS-1.0.1 tree. Current
RPP activation is read from its stable-ID table. This is a static audit: a
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
    _check(checks, errors, 'no_uncontracted_gatehouse_activation', not missing_contracts,
           f'active gate IDs={active_gate_ids}; IDs without explicit gate contract={missing_contracts}')
    # The first activated gate needs an *exact* source, direction, exit and
    # destination contract. Only the contracted gate may be enabled: later gates
    # still fail closed. Independently compare to MUS and the PAL object rows.
    gate_errors = []
    if len(gate_contracts) != 1 or contract_ids != {6}:
        gate_errors.append(f'unexpected active gate contract IDs: {sorted(contract_ids)}')
    else:
        gate_contract = gate_contracts[0]
        if gate_contract.get('gold_map') != 'Route31VioletGate' or gate_contract.get('runtime_tileset') != 'JOHTO_GATE':
            gate_errors.append('wrong reference/tileset')
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
            gate_errors.append('gate contract differs from eight actual directional routes')
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
            # Derive the current gate contract from MUS *collision cells* rather
            # than trusting a copied hard-coded trigger policy. In particular,
            # the four outside warps are WARP_CARPET_LEFT/RIGHT, not DOOR.
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
                    gate_errors.append(f'MUS collision mismatch {map_name}({x},{y}): '
                                       f'{role} -> {actual_rule}, contract='
                                       f'{row.get("trigger"),row.get("direction")}')
                if row.get('arrival_auto_step') != gold_gate_arrival_step(role):
                    gate_errors.append(f'MUS arrival behavior mismatch {map_name}({x},{y}): '
                                       f'{row.get("arrival_auto_step")} vs {gold_gate_arrival_step(role)}')
            source = (project/'data/johto_gate_runtime.asm').read_text()
            rows = re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR',source)
            if rows != [('4','0','0'),('5','0','1'),('4','9','0'),('5','9','1')]:
                gate_errors.append('PAL gate object warp positions/target indices mismatch')
        except (OSError, ValueError) as exc:
            gate_errors.append(str(exc))
    _check(checks, errors, 'active_gatehouse_exact_contract', not gate_errors,
           f'Gate ID6 exact four doorways, eight routes and MUS source references; errors={gate_errors}')

    # Runtime direction guard is separate from the static object contract:
    # the existing RPP CheckWarpsCollision matches a coordinate alone.
    try:
        gate_runtime = (project/'engine/johto_pilot_runtime.asm').read_text()
        overworld = (project/'home/overworld.asm').read_text()
        direction_body = gate_runtime.split('JohtoPilotGateCollisionExitAllowed::', 1)[1]
        collision_body = overworld.split('CheckWarpsCollision::', 1)[1].split('CheckWarpsNoCollisionRetry1::', 1)[0]
        pass_direction = all(x in direction_body for x in (
            'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID', 'cp PLAYER_DIR_LEFT',
            'cp PLAYER_DIR_RIGHT', 'cp JOHTO_ROUTE31_VIOLET_GATE_WIDTH * 2 - 1',
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
