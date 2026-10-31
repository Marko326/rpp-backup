#!/usr/bin/env python3
"""Audit current stable-ID Johto indoor registration and emit a review scaffold.

This is intentionally tailored to the current PAL pilot architecture: the first
indoor map is registered through data/johto_indoor_house.asm, the shared pilot
header/resource tables, stable ID 125 and the $FB route table. It never writes
ASM or enables a new map. Unknown maps fail closed until a dedicated contract is
added.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from johto_indoor_common import ConversionError, dump, safe_roots

SUPPORTED = {
    'GuideGentsHouse': {
        'stable_id_symbol': 'JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID',
        'stable_id': 125,
        'width_symbol': 'JOHTO_GUIDE_GENTS_HOUSE_WIDTH',
        'height_symbol': 'JOHTO_GUIDE_GENTS_HOUSE_HEIGHT',
        'width': 4,
        'height': 4,
        'header_file': 'data/johto_indoor_house.asm',
        'header_label': 'JohtoGuideGentsHouseRuntimeHeader',
        'objects_label': 'JohtoGuideGentsHouseRuntimeObjects',
        'runtime_layout': 'maps/johto_pilot/GuideGentsHouse.runtime.blk',
        'reference_layout': 'maps/johto_pilot/GuideGentsHouse.reference.blk',
        'blockset': 'gfx/blocksets/johto_house.bst',
        'tileset': 'johto_house',
    }
}


def _read(root: Path, rel: str) -> str:
    path = root / rel
    if not path.is_file() or path.is_symlink():
        raise ConversionError(f'缺少必需文件或为符号链接: {rel}')
    return path.read_text(encoding='utf-8')


def _section(source: str, start: str, end: str | None = None) -> str:
    pat = re.compile(r'(?m)^' + re.escape(start) + r'::?\s*$')
    matches = list(pat.finditer(source))
    if len(matches) != 1:
        raise ConversionError(f'标签缺失或重复: {start} ({len(matches)})')
    tail = source[matches[0].end():]
    if end is None:
        return tail
    end_pat = re.compile(r'(?m)^' + re.escape(end) + r'::?\s*$')
    end_matches = list(end_pat.finditer(tail))
    if len(end_matches) != 1:
        raise ConversionError(f'结束标签缺失或重复: {end} ({len(end_matches)})')
    return tail[:end_matches[0].start()]


def _active_slot_for_125(source: str) -> int | None:
    for line in source.splitlines():
        code, _, comment = line.partition(';')
        if '$70-$7f' not in comment.lower():
            continue
        m = re.match(r'\s*db\s+(.+)$', code)
        if not m:
            return None
        values = [v.strip() for v in m[1].split(',')]
        if len(values) != 16:
            return None
        token = values[125 - 0x70]
        if token.startswith('$'):
            return int(token[1:], 16)
        if token.isdecimal():
            return int(token)
        return None
    return None


def _runtime_warp_rows(source: str) -> list[tuple[str, ...]]:
    body = _section(source, 'JohtoRegisteredWarpRoutes', 'JohtoRegisteredWarpRoutesEnd')
    rows: list[tuple[str, ...]] = []
    pattern = re.compile(
        r'db\s+(MAP_REGION_(?:JOHTO|KANTO))\s*,\s*'
        r'(JOHTO_[A-Z0-9_]+|[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*'
        r'(MAP_REGION_(?:JOHTO|KANTO))\s*,\s*'
        r'(JOHTO_[A-Z0-9_]+|[A-Z0-9_]+)')
    for raw in body.splitlines():
        code = raw.split(';', 1)[0].strip()
        if not code:
            continue
        match = pattern.fullmatch(code)
        if not match:
            raise ConversionError('无法解析 Warp 路由行: ' + code)
        rows.append(match.groups())
    return rows


def generate(rpp: Path, map_name: str = 'GuideGentsHouse') -> dict:
    rpp = Path(rpp).resolve()
    key = map_name
    if key in ('JohtoGuideGentsHouse', 'JohtoGuideGentsHouseRuntimeHeader'):
        key = 'GuideGentsHouse'
    if key not in SUPPORTED:
        return {
            'schema': 'johto-current-indoor-registration-v1',
            'map': map_name,
            'status': 'UNSUPPORTED_MAP_REQUIRES_MANUAL_CONTRACT',
            'checks': [],
            'errors': [f'当前工具只为 {", ".join(SUPPORTED)} 建立了当前架构合同；新地图不得自动注册。'],
            'asm_written': False,
        }
    spec = SUPPORTED[key]
    checks: list[dict] = []
    errors: list[str] = []

    def add(name: str, ok: bool, detail: str) -> None:
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
        if not ok:
            errors.append(f'{name}: {detail}')

    try:
        fixed = _read(rpp, 'constants/johto_fixed_map_ids.asm')
        dims = _read(rpp, 'constants/region_map_constants.asm')
        slots = _read(rpp, 'data/johto_stable_id_slots.asm')
        descriptors = _read(rpp, 'data/johto_header_descriptors.asm')
        runtime_assets = _read(rpp, 'data/johto_pilot_runtime_assets.asm')
        source_resources = _read(rpp, 'data/johto_pilot_source_resources.asm')
        map_headers = _read(rpp, 'data/johto_pilot_map_headers.asm')
        runtime = _read(rpp, 'engine/johto_pilot_runtime.asm')
        main = _read(rpp, 'main.asm')
        header = _read(rpp, spec['header_file'])
        header_body = _section(header, spec['header_label'], spec['header_label'] + 'End')
        objects_body = _section(header, spec['objects_label'])
        runtime_layout = (rpp / spec['runtime_layout']).read_bytes()
        reference_layout = (rpp / spec['reference_layout']).read_bytes()
        blockset = (rpp / spec['blockset']).read_bytes()
    except (OSError, ConversionError) as exc:
        return {'schema': 'johto-current-indoor-registration-v1', 'map': key,
                'status': 'FAIL', 'checks': checks, 'errors': [str(exc)],
                'asm_written': False}

    add('STABLE_ID', re.search(r'(?m)^\s*DEF\s+' + re.escape(spec['stable_id_symbol']) +
        r'\s+EQU\s+' + str(spec['stable_id']) + r'\b', fixed) is not None,
        f"{spec['stable_id_symbol']} == {spec['stable_id']}")
    for symbol, expected in ((spec['width_symbol'], spec['width']),
                             (spec['height_symbol'], spec['height'])):
        add('DIMENSION_' + symbol, re.search(r'(?m)^\s*DEF\s+' + re.escape(symbol) +
            r'\s+EQU\s+' + str(expected) + r'\b', dims) is not None,
            f'{symbol} == {expected}')
    slot = _active_slot_for_125(slots)
    # Cardinality is set by the main project, not by the first-house milestone.
    # A stale literal ASSERT in the router must be detected before rgbasm runs.
    active_match = re.search(r'(?m)^\s*DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)\s*$', dims)
    active_count = int(active_match.group(1)) if active_match else None
    stable_assert = re.search(r'(?m)^\s*ASSERT\s+NUM_JOHTO_ACTIVE_MAPS\s*==\s*(\d+)\s*$', slots)
    asserted_count = int(stable_assert.group(1)) if stable_assert else None
    add('STABLE_ID_SLOT', slot == 5 and active_count is not None and asserted_count == active_count,
        f'ID125 slot={slot}; active map count={active_count}; stable-router ASSERT={asserted_count}')
    add('HEADER_DESCRIPTOR',
        len(re.findall(r'(?m)^\s*dw\s+' + re.escape(spec['header_label']) + r'\s*$', descriptors)) == 1 and
        len(re.findall(r'(?m)^\s*db\s+BANK\(' + re.escape(spec['header_label']) + r'\)\s*$', descriptors)) == 1,
        'one pointer+bank descriptor row')
    add('RUNTIME_RESOURCE_DESCRIPTOR',
        re.search(r'(?m)^\s*db\s+' + re.escape(spec['stable_id_symbol']) + r'\s*,\s*JOHTO_HOUSE\s*,\s*' +
                  re.escape(spec['width_symbol']) + r'\s*,\s*' + re.escape(spec['height_symbol']) + r'\s*$', runtime_assets) is not None and
        'JohtoGuideGentsHouseRuntimeBlocks' in runtime_assets,
        'runtime resource row references ID125, JOHTO_HOUSE, dimensions and block data')
    add('GOLD_SOURCE_RESOURCE',
        re.search(r'(?m)^\s*db\s+MAP_REGION_JOHTO\s*,\s*' + re.escape(spec['stable_id_symbol']) +
                  r'\s*,\s*' + re.escape(spec['width_symbol']) + r'\s*,\s*' +
                  re.escape(spec['height_symbol']) + r'\s*$', source_resources) is not None and
        'JohtoGuideGentsHouseSourceBlocks' in source_resources,
        'source resource record references the same stable ID and dimensions')
    add('HEADER_SHAPE',
        re.search(r'(?s)db\s+JOHTO_HOUSE\s*\n\s*db\s+' + re.escape(spec['height_symbol']) +
                  r'\s*,\s*' + re.escape(spec['width_symbol']) + r'\s*\n\s*dw\s+JohtoGuideGentsHouseRuntimeBlocks', header_body) is not None and
        'JohtoGuideGentsHouseRuntimeObjects' in header_body and
        'ASSERT JohtoGuideGentsHouseRuntimeHeaderEnd - JohtoGuideGentsHouseRuntimeHeader == 12' in header,
        'header uses JOHTO_HOUSE, 4x4 dimensions, runtime blocks/objects and 12-byte ASSERT')
    add('LAYOUT_SIZES', len(runtime_layout) == spec['width'] * spec['height'] and
        len(reference_layout) == spec['width'] * spec['height'] and len(blockset) % 16 == 0 and
        all(block < len(blockset) // 16 for block in runtime_layout + reference_layout),
        f'runtime/reference layout bytes={len(runtime_layout)}/{len(reference_layout)}; blockset blocks={len(blockset)//16}')
    add('MAIN_INCLUDES', all(len(re.findall(r'(?m)^\s*INCLUDE\s+"' + re.escape(path) + r'"\s*$', main)) == 1
        for path in ('data/johto_pilot_source_resources.asm', 'data/johto_pilot_runtime_assets.asm',
                     'data/johto_pilot_map_headers.asm', 'data/johto_indoor_house.asm')),
        'source, runtime resource, map header and indoor header are each included once')
    city_objects = _section(map_headers, 'JohtoPilotCherrygroveRuntimeObjects', 'JohtoPilotRoute30TextPointers')
    add('WARP_OBJECTS',
        len(re.findall(r'(?m)^\s*db\s+9\s*,\s*25\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', city_objects)) == 1 and
        len(re.findall(r'(?m)^\s*db\s+7\s*,\s*[23]\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', objects_body)) == 2,
        'one city entry at (Y9,X25) and two room exits at (Y7,X2/3)')
    try:
        contract = json.loads(_read(rpp, 'tools/johto_pilot_door_contracts.json'))
        id_symbols = {}
        for symbol, value in re.findall(r'(?m)^\s*DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)\b', fixed + '\n' + dims):
            id_symbols[int(value[1:], 16) if value.startswith('$') else int(value)] = symbol
        expected_routes = []
        for row in contract.get('active_routes', []):
            source, target = row['source'], row['target']
            expected_routes.append(('MAP_REGION_JOHTO', id_symbols[source['stable_id']],
                str(source['warp_ordinal_zero_based']), 'MAP_REGION_JOHTO', id_symbols[target['stable_id']]))
        for gate in contract.get('gatehouse_activation_policy', {}).get('active_gatehouse_contracts', []):
            if gate.get('stable_id') in (11,13,18,104,105):
                continue  # new gates are appended in exact global South route order
            for row in gate.get('warp_contracts', []):
                expected_routes.append(('MAP_REGION_JOHTO', id_symbols[row['source_stable_id']],
                    str(row['source_warp_ordinal']), 'MAP_REGION_JOHTO', id_symbols[row['target_stable_id']]))
        # MAP-283 gate routes are appended *after* the earlier southern rows.
        northern_routes = [gate for gate in contract.get('gatehouse_activation_policy', {}).get('active_gatehouse_contracts', [])
                           if gate.get('stable_id') == 18]
        for row in contract.get('cave_1f_routes', []):
            expected_routes.append(('MAP_REGION_JOHTO', id_symbols[row['source_stable_id']],
                str(row['source_warp_ordinal']), 'MAP_REGION_JOHTO', id_symbols[row['target_stable_id']]))
        for row in contract.get('south_batch_routes', []):
            expected_routes.append(('MAP_REGION_JOHTO', id_symbols[row['source_stable_id']],
                str(row['source_warp_ordinal']), 'MAP_REGION_JOHTO', id_symbols[row['target_stable_id']]))
        for gate in northern_routes:
            for row in gate.get('warp_contracts', []):
                expected_routes.append(('MAP_REGION_JOHTO', id_symbols[row['source_stable_id']],
                    str(row['source_warp_ordinal']), 'MAP_REGION_JOHTO', id_symbols[row['target_stable_id']]))
        # MAP-286: Park registration follows the historical 50 rows without
        # renumbering Route36 Ruins gate rows (ordinals 0/1).
        park_rows = (
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
        expected_routes.extend(('MAP_REGION_JOHTO', src, str(n), 'MAP_REGION_JOHTO', dst)
                               for src, n, dst in park_rows)
        rows = _runtime_warp_rows(runtime)
        add('REGISTERED_WARP_ROUTES', rows == expected_routes,
            f'contract-derived route rows={len(expected_routes)}; runtime rows={len(rows)}; exact={rows == expected_routes}')
    except (ConversionError, OSError, KeyError, ValueError, TypeError) as exc:
        add('REGISTERED_WARP_ROUTES', False, str(exc))
    add('ROM0_COLLISION_ASSERT',
        'JohtoHouse_Coll:: INCBIN "gfx/tilesets/johto_house.tilecoll"' in _read(rpp, 'home.asm') and
        'ASSERT BANK(JohtoHouse_Coll) == 0' in header,
        'indoor collision list remains in ROM0; header asserts bank 0')
    add('DOOR_PROFILE', 'johto_map_profile 0, 2, MUSIC_CITIES1, 0' in runtime,
        'house profile is indoor and inherits Cherrygrove landmark')

    return {'schema': 'johto-current-indoor-registration-v1', 'map': key,
            'stable_id': spec['stable_id'], 'dimensions': [spec['width'], spec['height']],
            'registration_status': 'PRESENT_STATIC_ONLY' if not errors else 'STRUCTURAL_ERRORS',
            'status': 'PRESENT_STATIC_ONLY' if not errors else 'FAIL',
            'checks': checks, 'errors': errors, 'asm_written': False,
            'manual_review': ['actual Red/Blue MAP and bank budget',
                              'phone entry/exit and immediate reverse re-entry',
                              'save/load on the indoor warp carpet',
                              'future room must add its own explicit contract']}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp', type=Path, required=True)
    ap.add_argument('--gold', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--rpp-map', default='GuideGentsHouse')
    args = ap.parse_args(argv)
    rpp, gold, out = safe_roots(args.rpp, args.gold, args.output)
    result = generate(rpp, args.rpp_map)
    dump(out, 'indoor_registration.json', result)
    print('registration:', result['status'], 'checks:', len(result.get('checks', [])),
          'errors:', len(result.get('errors', [])))
    return 0 if result['status'] == 'PRESENT_STATIC_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
