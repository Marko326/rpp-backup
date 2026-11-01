#!/usr/bin/env python3
"""MAP-297 static acceptance gate for Ecruteak west -> Route38 -> Route39 -> Olivine.

Read-only. It validates source/runtime assets, stable slots, registered gate
warps, direct seams, field-move hooks, map names and deliberate closure of
Olivine interiors/Route40. It never assembles, links or claims phone acceptance.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

WEST = 'data/johto_west_runtime_297.asm'
RUNTIME = 'engine/johto_pilot_runtime.asm'
SOURCE = 'data/johto_pilot_source_resources.asm'

MAPS = {
    'Route38EcruteakGate': (20, 80, 0, 'maps/EastWestGate.blk'),
    'Route38': (180, 720, 0, 'maps/Route38.blk'),
    'Route39': (180, 720, 0, 'maps/Route39.blk'),
    'OlivineCity': (360, 1440, 406, 'maps/OlivineCity.blk'),
}


def audit(root: Path, gold_root: Path | None = None, *,
          text_overrides: dict[str, str] | None = None,
          bytes_overrides: dict[str, bytes] | None = None) -> dict:
    root = Path(root)
    gold_root = Path(gold_root) if gold_root else None
    text_overrides = text_overrides or {}
    bytes_overrides = bytes_overrides or {}
    checks: list[dict] = []
    errors: list[str] = []

    def text(rel: str) -> str:
        return text_overrides.get(rel, (root / rel).read_text(encoding='utf8'))

    def blob(rel: str) -> bytes:
        return bytes_overrides.get(rel, (root / rel).read_bytes())

    def ck(name: str, ok: bool, detail: str = '') -> None:
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
        if not ok:
            errors.append(name + (': ' + detail if detail else ''))

    try:
        constants = text('constants/region_map_constants.asm')
        fixed = text('constants/johto_fixed_map_ids.asm')
        slots = text('data/johto_stable_id_slots.asm')
        version = text('data/game_version.asm')
        west = text(WEST)
        runtime = text(RUNTIME)
        source = text(SOURCE)
        headers = text('data/johto_header_descriptors.asm')
        assets = text('data/johto_pilot_runtime_assets.asm')
        geometry = text('engine/johto_south_geometry.asm')
        surf = text('engine/johto_violet_field_skills.asm')
        ledges = text('engine/overworld/ledges.asm')
        fly = text('engine/fly_town_map_helpers.asm')
        names = text('engine/overworld/map_name_sign.asm')
        main = text('main.asm')
    except OSError as exc:
        return {'status': 'FAIL', 'checks': checks, 'errors': [str(exc)],
                'rom_built': False, 'phone_verified': False}

    ck('release_and_active_count', ('FIX-5.62.298@' in version or 'MAP-5.62.299@' in version) and 'TEST-231@' in version and
       re.search(r'(?m)^DEF NUM_JOHTO_ACTIVE_MAPS EQU (?:32|35)\b', constants) is not None,
       'west corridor remains valid in FIX-5.62.298 or later MAP-5.62.299 / TEST-231')
    id_values = {name: int(value[1:], 16) if value.startswith('$') else int(value)
                 for name, value in re.findall(r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\$[0-9A-Fa-f]+|\d+)\b', fixed + '\n' + constants)}
    slot_body = slots.split('JohtoStableIDToActiveSlot::', 1)[1].split('JohtoStableIDToActiveSlotEnd::', 1)[0]
    slot_values = []
    for line in slot_body.splitlines():
        code = line.split(';', 1)[0].strip()
        if not code.startswith('db '):
            continue
        for token in code[3:].split(','):
            token = token.strip()
            if token == 'JOHTO_INVALID_ACTIVE_SLOT':
                slot_values.append(255)
            elif token in id_values:
                slot_values.append(id_values[token])
            else:
                slot_values.append(int(token, 0))
    for symbol, stable, slot in (
        ('JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID', 23, 28),
        ('JOHTO_ROUTE_38_LOCAL_ID', 24, 29),
        ('JOHTO_ROUTE_39_LOCAL_ID', 25, 30),
        ('JOHTO_OLIVINE_CITY_LOCAL_ID', 26, 31),
    ):
        ck(f'stable_slot_{stable}', id_values.get(symbol) == stable and len(slot_values) == 256 and slot_values[stable] == slot,
           f'{symbol} -> slot {slot}; table value={slot_values[stable] if len(slot_values) > stable else None}')

    ck('west_runtime_included_once', main.count('INCLUDE "data/johto_west_runtime_297.asm"') == 1,
       'new runtime file included exactly once')
    for label in ('JohtoRoute38EcruteakGateRuntimeHeader', 'JohtoRoute38RuntimeHeader',
                  'JohtoRoute39RuntimeHeader', 'JohtoOlivineRuntimeHeader'):
        ck('header_descriptor_' + label, headers.count('dw ' + label) == 1, label)
    for symbol in ('JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID', 'JOHTO_ROUTE_38_LOCAL_ID',
                   'JOHTO_ROUTE_39_LOCAL_ID', 'JOHTO_OLIVINE_CITY_LOCAL_ID'):
        ck('runtime_asset_' + symbol, re.search(rf'(?m)^\s*db\s+{symbol}\s*,', assets) is not None, symbol)

    for name, (block_len, role_len, water_count, gold_rel) in MAPS.items():
        gold = blob(f'maps/johto_pilot/{name}.gold.blk')
        live = blob(f'maps/johto_pilot/{name}.runtime.blk')
        roles = blob(f'maps/johto_pilot/{name}.roles.bin')
        # The west gate deliberately uses the mature reference-project layout;
        # its .gold.blk remains separately frozen to Gold for provenance. Outdoor
        # Route38/39/Olivine runtime layouts are byte-identical to Gold.
        live_ok = len(gold) == block_len and len(live) == block_len and (name == 'Route38EcruteakGate' or live == gold)
        ck(f'{name}_source_runtime_exact', live_ok,
           f'block bytes={len(live)} expected={block_len}; mature_gate={name == "Route38EcruteakGate"}')
        ck(f'{name}_role_grid', len(roles) == role_len and roles.count(2) == water_count,
           f'role bytes={len(roles)}, WATER={roles.count(2)}')
        if gold_root is not None:
            ref = gold_root / gold_rel
            ck(f'{name}_matches_gold_reference', ref.is_file() and ref.read_bytes() == gold,
               gold_rel)

    ck('gate_header_is_warp_only', 'JohtoRoute38EcruteakGateRuntimeHeader::' in west and
       'db 0 ; both mouths are registered collision Warps' in west, 'no direct gate connection flags')
    ck('route38_two_sided_header', 'JohtoRoute38RuntimeHeader::' in west and 'db WEST | EAST' in west,
       'west=Route39, east=Ecruteak preview')
    ck('route39_two_sided_header', 'JohtoRoute39RuntimeHeader::' in west and 'db SOUTH | EAST' in west,
       'south=Olivine, east=Route38')
    ck('olivine_north_route39_preserved', 'JohtoOlivineRuntimeHeader::' in west and
       ('db NORTH ; Route40 west and all buildings remain closed' in west or 'db NORTH | WEST' in west),
       'Route39 north connection remains live; MAP-299 may additionally open reviewed Route40 west')

    gate_objects = west.split('JohtoRoute38EcruteakGateRuntimeObjects::', 1)[1].split('JohtoRoute38RuntimeObjects::', 1)[0]
    r38_objects = west.split('JohtoRoute38RuntimeObjects::', 1)[1].split('JohtoRoute39RuntimeObjects::', 1)[0]
    r39_objects = west.split('JohtoRoute39RuntimeObjects::', 1)[1].split('JohtoOlivineRuntimeObjects::', 1)[0]
    oli_objects = west.split('JohtoOlivineRuntimeObjects::', 1)[1].split('; Reference-project readable signs only', 1)[0]
    ck('west_gate_four_runtime_warps', len(re.findall(r'JOHTO_REGISTERED_WARP_SELECTOR', gate_objects)) == 4,
       '4 gate carpet warps')
    ck('route38_two_runtime_warps', len(re.findall(r'JOHTO_REGISTERED_WARP_SELECTOR', r38_objects)) == 2,
       '2 Route38 gate carpets')
    ck('route39_interiors_sealed', re.search(r'(?m)^\s*db\s+0\s*; barn/farmhouse interiors remain sealed', r39_objects) is not None and
       'JOHTO_REGISTERED_WARP_SELECTOR' not in r39_objects, '0 Route39 building warps')
    ck('olivine_interiors_sealed', re.search(r'(?m)^\s*db\s+0\s*; all 11 Gold building/port Warps remain sealed', oli_objects) is not None and
       'JOHTO_REGISTERED_WARP_SELECTOR' not in oli_objects, '0 Olivine building/port warps')

    route_body = runtime.split('JohtoRegisteredWarpRoutes::', 1)[1].split('JohtoRegisteredWarpRoutesEnd::', 1)[0]
    west_route_rows = [line.split(';',1)[0].strip() for line in route_body.splitlines()
                       if any(sym in line for sym in ('JOHTO_ECRUTEAK_CITY_LOCAL_ID',
                          'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID', 'JOHTO_ROUTE_38_LOCAL_ID'))]
    # Ecruteak/Route38 IDs also appear in comments only outside db rows; filter exact db records.
    west_route_rows = [line for line in west_route_rows if line.startswith('db MAP_REGION_JOHTO')]
    ck('west_gate_eight_registered_routes', len(west_route_rows) == 8 and
       sum('JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID' in row for row in west_route_rows) == 8,
       f'west registered rows={len(west_route_rows)}')

    direct = (
        'JOHTO_ECRUTEAK_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID',
        'JOHTO_ROUTE_38_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID',
        'JOHTO_ROUTE_38_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID',
        'JOHTO_ROUTE_39_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID',
        'JOHTO_ROUTE_39_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID',
        'JOHTO_OLIVINE_CITY_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID',
    )
    ck('six_bidirectional_source_seams', all(x in source for x in direct), 'Ecruteak<->38<->39<->Olivine')

    ck('route38_route39_gold_ledges', all(x in ledges for x in (
       'JohtoRoute38GoldHops:', 'JohtoRoute39GoldHops:',
       'cp JOHTO_ROUTE_38_LOCAL_ID', 'cp JOHTO_ROUTE_39_LOCAL_ID')),
       'both routes have coordinate-direction Gold hop tables')
    ck('olivine_spatial_surf', all(x in geometry for x in (
       'cp JOHTO_OLIVINE_CITY_LOCAL_ID', 'JohtoOlivineRoles:: INCBIN "maps/johto_pilot/OlivineCity.roles.bin"')) and
       re.search(r'cp JOHTO_OLIVINE_CITY_LOCAL_ID\s*\n\s*jp z, \.(?:southModern|westSea)', surf) is not None,
       'Olivine role grid reaches an audited Surf movement/shore path')

    ck('town_map_coordinates', all(x in fly for x in (
       'db 60, 60 ; slot 28 Route38/Ecruteak gate', 'db 60, 60 ; slot 29 Route38',
       'db 64, 44 ; slot 30 Route39', 'db 76, 44 ; slot 31 Olivine City')),
       'slots 28..31 have reviewed Town Map coordinates')
    ck('olivine_name_and_fly', 'JohtoPilotOlivineName:: db "Olivine City@"' in fly and
       'cp JOHTO_OLIVINE_CITY_LOCAL_ID' in names and 'db "Olivine City@"' in names,
       'Olivine display name and existing Fly landmark are live')

    return {'schema': 'johto-west-corridor-runtime-gate-297-v1',
            'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks': checks, 'errors': errors,
            'rom_built': False, 'phone_verified': False,
            'scope': 'Ecruteak west gate -> Route38 -> Route39 -> Olivine City exterior'}


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, default=Path.cwd())
    p.add_argument('--gold-root', type=Path)
    p.add_argument('--json', action='store_true')
    a = p.parse_args(argv)
    r = audit(a.project, a.gold_root)
    if a.json:
        print(json.dumps(r, ensure_ascii=False, indent=2))
    else:
        for c in r['checks']:
            print(f"[{c['status']}] {c['check']}: {c['detail']}")
        print(r['status'])
    return 0 if r['status'] == 'PASS_STATIC_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
