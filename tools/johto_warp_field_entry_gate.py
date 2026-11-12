#!/usr/bin/env python3
"""Required source gate for new Johto map/warp activation.

This freezes the explicitly *reviewed* live roster, then executes the selected
high-risk arrival hook and checks the actual bike entry dispatcher. A future
map/route must be added to the review inventory and given new semantic checks;
unknown activations FAIL rather than inheriting a presumed safe default.

Not a ROM/CPU emulator: unmodeled old arrivals remain legacy-unverified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

CONTRACT = 'tools/johto_warp_field_entry_contracts.json'
ROUTE_SOURCE = 'engine/johto_pilot_runtime.asm'
SLOT_SOURCE = 'data/johto_stable_id_slots.asm'
BIKE_SOURCE = 'home/rom0_relief_349.asm'
GATE_SOURCE = 'data/johto_vertical_gate_runtime_314.asm'
CAVE_VIOLET = 'data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin'
CAVE_BLACKTHORN = 'data/johto_dark_cave_stage/DarkCaveBlackthornEntrance.roles.bin'
FROZEN_ROUTES_HASH = 'b01907270c237275d8bb5d28655ab1d8d329695907eb05c1c6f30ced6eb6f364'
FROZEN_IDS_HASH = '0570a770cb9d3f89464b8876c911cab19c597a85a20d5b26da6d60067aad2df4'
OBJECTS = {
    'JOHTO_ROUTE_31_LOCAL_ID': ('data/johto_pilot_map_headers.asm', 'JohtoPilotRoute31RuntimeObjects'),
    'JOHTO_ROUTE_45_LOCAL_ID': ('data/johto_south_chain_runtime_328.asm', 'JohtoRoute45RuntimeObjects'),
    'JOHTO_ROUTE_46_LOCAL_ID': ('data/johto_south_chain_runtime_328.asm', 'JohtoRoute46RuntimeObjects'),
    'JOHTO_ROUTE_44_LOCAL_ID': ('data/johto_route44_runtime_324.asm', 'JohtoRoute44RuntimeObjects'),
    'JOHTO_BLACKTHORN_CITY_LOCAL_ID': ('data/johto_blackthorn_runtime_326.asm', 'JohtoBlackthornRuntimeObjects'),
    'JOHTO_ICE_PATH_1F_LOCAL_ID': ('data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm', 'JohtoIcePath1FObjects367E'),
    'JOHTO_ICE_PATH_B1F_LOCAL_ID': ('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm', 'JohtoIcePathB1FObjects367K'),
    'JOHTO_RUINS_OF_ALPH_LOCAL_ID': ('data/johto_ruins_south_runtime.asm', 'JohtoPilotAlphOutsideRuntimeObjects'),
    'JOHTO_UNION_CAVE_B1F_LOCAL_ID': ('data/johto_union_cave_runtime.asm', 'JohtoUnionCaveB1FRuntimeObjects'),
    'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID': ('data/johto_dark_cave_stage/REF349_stage2_runtime.asm', 'JohtoDarkCaveObjects'),
    'JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID': ('data/johto_dark_cave_stage/REF349_stage2_runtime.asm', 'JohtoDarkCaveBlackthornObjects'),
}


def registered_routes(source: str) -> list[str]:
    section = source.split('JohtoRegisteredWarpRoutes::', 1)[1].split('JohtoRegisteredWarpRoutesEnd::', 1)[0]
    routes = []
    for line in section.splitlines():
        line = line.split(';', 1)[0].strip()
        if line.startswith('db MAP_REGION_'):
            fields = [s.strip() for s in line[3:].split(',')]
            if len(fields) != 5 or any(not f for f in fields):
                raise ValueError(f'invalid Warp row: {line}')
            routes.append(','.join(fields))
    return routes


def active_ids(source: str) -> dict[int, int]:
    section = source.split('JohtoStableIDToActiveSlot::', 1)[1].split('JohtoStableIDToActiveSlotEnd::', 1)[0]
    cells = []
    for line in section.splitlines():
        line = line.partition(';')[0].strip()
        if line.startswith('db '):
            cells.extend(s.strip() for s in line[3:].split(','))
    if len(cells) != 256:
        raise ValueError(f'stable ID table is {len(cells)} bytes, not 256')
    result = {}
    for index, cell in enumerate(cells):
        if cell == 'JOHTO_INVALID_ACTIVE_SLOT':
            continue
        if cell.isdecimal():
            result[index] = int(cell)
        elif index < 5 and cell.startswith('JOHTO_'):
            result[index] = index
        else:
            raise ValueError(f'non-numeric active slot {index}: {cell}')
    if len(set(result.values())) != len(result):
        raise ValueError('duplicate active slots')
    return result



def warp_objects(source: str, label: str) -> list[tuple[int, int, int]]:
    """Read real object rows: (x,y,target ordinal), not registered pairs."""
    rest = source.split(label + ':', 1)[1]
    lines = [line.partition(';')[0].strip() for line in rest.splitlines()[1:]]
    rows = [line for line in lines if line]
    if not rows[0].startswith('db ') or not rows[1].startswith('db '):
        raise ValueError(f'{label} object header absent')
    count = int(rows[1][3:].strip().replace('$', '0x'), 0)
    warps = []
    for line in rows[2:2+count]:
        m = re.fullmatch(r'db\s+(\d+|\$ff),\s*(\d+|\$ff),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR', line)
        if not m:
            raise ValueError(f'{label}: bad object Warp {line}')
        y, x, target_ordinal = (int(c[1:], 16) if c.startswith('$') else int(c) for c in m.groups())
        warps.append((x, y, target_ordinal))
    if len(warps) != count:
        raise ValueError(f'{label}: expected {count} Warps, found {len(warps)}')
    return warps


def _asm(source: str, start: str, end: str):
    text = source.split(start, 1)[1].split(end, 1)[0]
    statements = []
    labels = {}
    for line in text.splitlines():
        line = line.split(';', 1)[0].strip()
        if not line:
            continue
        if line.startswith('.') and re.fullmatch(r'\.[A-Za-z][\w]*:?', line):
            name = line.rstrip(':')
            if name in labels:
                raise ValueError(f'duplicate arrival label {name}')
            labels[name] = len(statements)
            continue
        m = re.fullmatch(r'(callab|call|ld|cp|and|jr|jp|ret)\s*(.*?)\s*', line)
        if not m:
            raise ValueError(f'unrecognized arrival instruction: {line}')
        statements.append((m[1], m[2]))
    return statements, labels


def _vertical_step(source: str, name: str, x: int, y: int) -> int:
    section = source.split('JohtoVerticalGateArrivalProfiles314::', 1)[1].split('JohtoVerticalGateArrivalProfilesEnd314::', 1)[0]
    rows = re.findall(r'^\s*db\s+(JOHTO_\w+_LOCAL_ID),\s*(\d+),\s*(\d+),\s*(D_DOWN|D_UP|D_LEFT|D_RIGHT)\b', section, re.M)
    matches = [direction for symbol, xx, yy, direction in rows if symbol == name and int(xx) == x and int(yy) == y]
    if len(matches) > 1:
        raise ValueError('duplicate matching arrival profile')
    if not matches:
        return 0
    if matches[0] != 'D_DOWN':
        raise ValueError(f'arrival direction not yet modelled: {matches[0]}')
    return 1


def trace_arrival(pilot: str, vertical: str, ids_source: str, name: str, x: int, y: int) -> int:
    """Trace actual matching branches, including the vertical dispatch call.

    Return E as 0=stay or 1=D_DOWN. Reject unknown instructions/branches rather
    than silently asserting the text contains a named label somewhere.
    """
    main = _asm(pilot, 'JohtoPilotGateArrivalStep::', 'JohtoPilotGateDoorApproachAllowed::')
    vertical_ids = _asm(pilot, 'JohtoPilotIsVerticalGatePairMap314::', 'JohtoPilotGateArrivalStep::')
    regs = {'a': 0, 'e': 0}
    zero = False
    carry = False
    constants = {'JOHTO_RUNTIME_MAP_HANDLE': 252, 'MAP_REGION_JOHTO': 1}
    for match in re.finditer(r'DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\d+)', (ids_source)):
        constants[match[1]] = int(match[2])
    if name not in constants:
        raise ValueError(f'unknown map id {name}')

    def run(statements, labels, depth=0):
        nonlocal zero, carry
        if depth > 2:
            raise ValueError('arrival call depth exceeded')
        pc = 0
        for _ in range(400):
            if not 0 <= pc < len(statements):
                raise ValueError('arrival execution left function')
            op, arg = statements[pc]
            pc += 1
            if op == 'ld':
                left, _, right = arg.partition(',')
                left, right = left.strip(), right.strip()
                memory = {'[wCurMap]': 252, '[wCurRegion]': 1,
                          '[wCurLocalMapID]': constants[name],
                          '[wXCoord]': x, '[wYCoord]': y}
                if left not in regs or right not in memory and right not in constants and right not in ('0', 'D_DOWN'):
                    raise ValueError(f'unsupported arrival load {arg}')
                regs[left] = memory.get(right, constants.get(right, {'0': 0, 'D_DOWN': 1}.get(right)))
            elif op == 'cp':
                rhs = arg.strip()
                if rhs.endswith(' + 1'):
                    rhs = rhs[:-4].strip()
                    value = constants[rhs] + 1
                elif rhs.isdecimal():
                    value = int(rhs)
                else:
                    value = constants[rhs]
                zero = regs['a'] == value
                carry = regs['a'] < value
            elif op == 'and':
                if arg != 'a':
                    raise ValueError(f'unsupported AND: {arg}')
                zero = regs['a'] == 0
                carry = False
            elif op in ('jr', 'jp'):
                fields = [p.strip() for p in arg.split(',')]
                cond, target = (None, fields[0]) if len(fields) == 1 else (fields[0], fields[1])
                if cond not in (None, 'z', 'nz', 'c', 'nc'):
                    raise ValueError(f'unsupported branch condition {arg}')
                jump = cond is None or {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}.get(cond, False)
                if jump:
                    if target not in labels:
                        raise ValueError(f'arrival jumped outside helper: {target}')
                    pc = labels[target]
            elif op == 'call':
                if arg != 'JohtoPilotIsVerticalGatePairMap314':
                    raise ValueError(f'unmodeled arrival call {arg}')
                run(*vertical_ids, depth=depth+1)
            elif op == 'callab':
                if arg != 'JohtoVerticalGateArrivalStep314':
                    raise ValueError(f'unmodeled banked arrival call {arg}')
                regs['e'] = _vertical_step(vertical, name, x, y)
            elif op == 'ret':
                if arg:
                    ok = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}
                    if arg not in ok:
                        raise ValueError(f'unsupported return {arg}')
                    if not ok[arg]:
                        continue
                return
        raise ValueError('arrival tracing hit step limit')
    run(*main)
    return regs['e']


def bike_entry(bike: str, cave_id: str) -> bool:
    """Inspect the *live public entry*, not the leaf Gold-floor helper."""
    part = bike.split('IsBikeRidingAllowed::', 1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"', 1)[0]
    pre = part.split('\n.legacyBike\n', 1)[0]
    branch = re.search(r'\bcp\s+' + re.escape(cave_id) + r'\s+jp z, (\.\w+)', pre)
    if branch is None or branch[1] != '.darkCaveBike':
        return False
    helper = part.split('\n.darkCaveBike\n', 1)[1] if '\n.darkCaveBike\n' in part else ''
    return ('callab JohtoDarkCaveBikeFloorAllowed349' in helper and
            'cp 1' in helper and 'jr z, .allowed' in helper and
            'ret' in helper)


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> dict:
    root = Path(root)
    overrides = overrides or {}
    checks = []
    def content(name):
        if name in overrides:
            value = overrides[name]
            return value if isinstance(value, str) else value.decode('utf-8')
        return (root / name).read_text()
    def binary(name):
        if name in overrides:
            value = overrides[name]
            return value if isinstance(value, bytes) else value.encode()
        return (root / name).read_bytes()
    def ck(label: str, passed: bool, detail=''):
        checks.append({'check': label, 'status': 'PASS' if passed else 'FAIL', 'detail': detail})
    contract = json.loads(content(CONTRACT))
    current = registered_routes(content(ROUTE_SOURCE))
    roster = active_ids(content(SLOT_SOURCE))
    def contract_digest(rows):
        return hashlib.sha256(json.dumps(sorted(rows), separators=(',', ':')).encode()).hexdigest()
    frozen_routes = set(contract['frozen_ref365c_route_rows'])
    frozen_ids = set(map(int, contract['frozen_ref365c_active_map_ids']))
    ck('frozen_ref365c_route_inventory_unchanged',
       contract_digest(frozen_routes) == FROZEN_ROUTES_HASH)
    ck('frozen_ref365c_active_map_inventory_unchanged',
       contract_digest(frozen_ids) == FROZEN_IDS_HASH)
    new_routes = set()
    for row in contract['critical_arrivals']:
        if row.get('new_route_review'):
            new_routes.add('MAP_REGION_JOHTO,' + row['from'] + ',' + str(row['ordinal']) +
                           ',MAP_REGION_JOHTO,' + row['to'])
    ck('registered_routes_unique', len(current) == len(set(current)))
    ck('new_or_changed_route_requires_review', set(current) == frozen_routes | new_routes,
       f'new={sorted(set(current) - frozen_routes - new_routes)[:4]}, removed={sorted((frozen_routes | new_routes)-set(current))[:4]}')
    reviews = contract['new_map_activation_reviews']
    extra_ids = [int(item['stable_id']) for item in reviews]
    ck('new_active_map_requires_field_and_arrival_review',
       set(roster) == frozen_ids | set(extra_ids),
       f'new={sorted(set(roster) - frozen_ids - set(extra_ids))}, removed={sorted((frozen_ids | set(extra_ids))-set(roster))}')
    ck('new_map_reviews_have_explicit_fields', all(
       item.get('bike_policy') in ('FLOOR_ONLY_CAVE', 'ALLOW_GATE', 'FORBID_INDOOR', 'OUTDOOR') and
       item.get('surf_policy') in ('GOLD_WATER', 'NO_WATER') and
       item.get('flash_policy') in ('DARK_CAVE', 'NOT_APPLICABLE') and
       item.get('warp_arrival_review') and
       item.get('source_reference') and
       item.get('audit_test_file') and item.get('audit_test_function') and
       (root / item['audit_test_file']).is_file() and
       ('def ' + item['audit_test_function'] + '(' in (root / item['audit_test_file']).read_text())
       for item in reviews) and
       len(extra_ids) == len(set(extra_ids)) and not (set(extra_ids) & frozen_ids))
    ck('active_slots_contiguous', set(roster.values()) == set(range(len(roster))))
    symbols = content('constants/johto_fixed_map_ids.asm') + '\n' + content('constants/region_map_constants.asm')
    pilot = content(ROUTE_SOURCE)
    gate = content(GATE_SOURCE)
    source_set = set(current)
    object_tables = {}
    for map_id, (src_file, label) in OBJECTS.items():
        try:
            object_tables[map_id] = warp_objects(content(src_file), label)
        except (IndexError, ValueError) as exc:
            ck('source_object_table_'+map_id, False, str(exc))
    for item in contract['critical_arrivals']:
        source = item['from']
        dest = item['to']
        ordinal = item['ordinal']
        row = f'MAP_REGION_JOHTO,{source},{ordinal},MAP_REGION_JOHTO,{dest}'
        label = item['name']
        ck(label+'_registered', row in source_set)
        try:
            source_warp = object_tables[source][ordinal]
            target_warp = object_tables[dest][source_warp[2]]
            ck(label+'_target_object_warp', list(target_warp[:2]) == item['landing'],
               f'actual={target_warp[:2]}, expected={item["landing"]}')
            ck(label+'_source_object_warp', list(source_warp[:2]) == item['departure'],
               f'actual={source_warp[:2]}, expected={item["departure"]}')
            actual = trace_arrival(pilot, gate, symbols, dest, *item['landing'])
            ck(label+'_arrival_execution', actual == {'NONE': 0, 'DOWN': 1}[item['step']],
               f'expected={item["step"]}, got={actual}')
            if item['step'] == 'DOWN':
                end = item['after_step']
                ck(label+'_step_xy', end == [item['landing'][0], item['landing'][1]+1])
            if dest == 'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' or dest == 'JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID':
                filename = CAVE_VIOLET if 'VIOLET' in dest else CAVE_BLACKTHORN
                width = 40 if 'VIOLET' in dest else 30
                roles = binary(filename)
                x, y = item['landing']
                ck(label+'_landing_role', roles[y*width+x] == item['landing_role'])
                if item['step'] == 'DOWN':
                    ck(label+'_safe_floor_after_step', roles[end[1]*width+end[0]] == 0)
        except (IndexError, KeyError, TypeError, ValueError) as ex:
            ck(label+'_trace_error', False, str(ex))
    # Check neighboring ordinary tiles/carpets: new gate branch must not step
    # anywhere simply because it shares a map ID with a known destination.
    for item in contract['must_stay_stationary']:
        try:
            actual = trace_arrival(pilot, gate, symbols, item['map'], *item['xy'])
            ck(item['name']+'_no_spurious_step', actual == 0, f'got={actual}')
        except (KeyError, ValueError) as ex:
            ck(item['name']+'_trace_error', False, str(ex))
    bike = content(BIKE_SOURCE)
    for name in contract['bike_eligible_cave_ids']:
        ck('bike_public_entry_'+name, bike_entry(bike, name))
    ck('no_unspecified_eligible_cave', set(contract['bike_eligible_cave_ids']) == {
        'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',
        'JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID'})
    errors = [c['check'] + (': ' + c['detail'] if c['detail'] else '') for c in checks if c['status'] == 'FAIL']
    return {'status': 'PASS_SOURCE_ONLY' if not errors else 'FAIL', 'passed': len(checks)-len(errors),
            'failed': len(errors), 'errors': errors, 'checks': checks}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = p.parse_args()
    result = audit(args.root)
    print(json.dumps({k: v for k, v in result.items() if k != 'checks'}, ensure_ascii=False, indent=2))
    return 0 if not result['errors'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
