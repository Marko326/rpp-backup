#!/usr/bin/env python3
"""Frozen Gold evidence for the Route44 -> Blackthorn -> Route46 corridor.

No game map activation, ROM creation, or auto-import. This adds an independent
anti-drift preflight before any eastern corridor runtime work can be approved.
Existing Johto Gold parsers and the established tile contract are reused.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re

from johto_rpp_batch import gold_connections, gold_event_records
from johto_gold_cells import decode_cells
from johto_rpp_tileset_contract import check_runtime_contract

CONTRACT = Path(__file__).with_name('johto_east_corridor_source_contract.json')
REVERSE = {'east': 'west', 'west': 'east', 'north': 'south', 'south': 'north'}


def audit(project, gold, *, contract=None, runtime_tileset=None,
          connection_override=None, event_override=None):
    """Fail closed on altered identity, geometry, reciprocal seams or cave warps.

    Overrides are injectable solely for deterministic negative unit tests.
    """
    project, gold = Path(project), Path(gold)
    spec = contract if contract is not None else json.loads(CONTRACT.read_text())
    issues = []
    rows = []
    if spec.get('schema') != 'johto-east-corridor-source-v1':
        issues.append('manifest_schema')
    if (project / 'data/game_version.asm').read_text().count('SPID-5.62.239@') != 1:
        issues.append('formal_version_not_239')
    ids = (project / 'constants/johto_fixed_map_ids.asm').read_text()
    header = (project / 'data/johto_map_headers.asm').read_text()
    rpp_tiles = runtime_tileset
    gold_tiles = (gold / 'data/tilesets/johto_metatiles.bin').read_bytes()
    if rpp_tiles is None:
        try:
            rpp_tiles = check_runtime_contract(gold_tiles, project)
        except (ValueError, FileNotFoundError) as exc:
            issues.append('shared_johto_tileset:' + str(exc))
            rpp_tiles = b''
    johto_collision = (gold / 'data/tilesets/johto_collision.asm').read_text()
    actual_events = {}
    actual_connections = {}
    for info in spec.get('maps', []):
        name = info['name']
        width, height = info['dimensions_blocks']
        local_id = info['stable_local_id']
        symbol = re.sub(r'(?<!^)(?=[A-Z])', '_', name).upper()
        # Gold fixed ids are explicitly written with ROUTE_44 style for numbered maps.
        if name.startswith('Route') and name[5:].isdigit():
            symbol = 'ROUTE_' + name[5:]
        elif name == 'IcePath1F':
            symbol = 'ICE_PATH_1F'
        elif name == 'BlackthornCity':
            symbol = 'BLACKTHORN_CITY'
        pattern = rf'(?m)^DEF JOHTO_{re.escape(symbol)}_LOCAL_ID EQU {local_id}\b'
        if re.search(pattern, ids) is None:
            issues.append(name + ':frozen_local_id')
        # The four Gold outdoor maps are independently reviewed for runtime;
        # IcePath1F remains unbuilt and must not be activated by staging.
        if name == 'IcePath1F' and re.search(r'\bJohto' + re.escape(name) + r'_h\b', header):
            issues.append(name + ':unreviewed_runtime_activation')
        layout_path = gold / info['gold_blk']
        if not layout_path.is_file():
            issues.append(name + ':missing_gold_layout')
            continue
        layout = layout_path.read_bytes()
        if len(layout) != width * height:
            issues.append(name + ':gold_dimensions')
            continue
        if hashlib.sha256(layout).hexdigest() != info['sha256']:
            issues.append(name + ':layout_sha256')
        staged = info.get('staged_assets') or {}
        for field in ('layout', 'mask', 'onboarding', 'mask_sha256', 'mask_bytes'):
            if field not in staged:
                issues.append(name + ':missing_staging_evidence:' + field)
        if {'layout', 'mask', 'onboarding', 'mask_sha256', 'mask_bytes'} <= staged.keys():
            copied_layout = project / staged['layout']
            collision_mask = project / staged['mask']
            onboarding = project / staged['onboarding']
            try:
                if copied_layout.read_bytes() != layout:
                    issues.append(name + ':staged_layout_drift')
                mask_bytes = collision_mask.read_bytes()
                if (len(mask_bytes) != staged['mask_bytes'] or
                    hashlib.sha256(mask_bytes).hexdigest() != staged['mask_sha256'] or
                    len(mask_bytes) != ((width * 2 + 7) // 8) * height * 2):
                    issues.append(name + ':staged_mask_drift')
                if not onboarding.read_text(encoding='utf8').startswith('# ' + name):
                    issues.append(name + ':staged_onboarding_drift')
            except (FileNotFoundError, OSError, UnicodeError) as exc:
                issues.append(name + ':staging_file_missing:' + str(exc))
        events = gold_event_records(gold, name, width, height)
        actual_events[name] = events
        if events['warnings']:
            issues.append(name + ':gold_events_' + ','.join(events['warnings']))
        got_warps = [{'xy': [w['x'], w['y']], 'target': w['destination'],
                      'target_warp': int(w['destination_warp'])} for w in events['warps']]
        if event_override and name in event_override:
            got_warps = event_override[name]
        if got_warps != info['warps'] or len(got_warps) != info['warp_count']:
            issues.append(name + ':gold_warp_topology')
        actual_connections[name] = gold_connections(gold, name)
        if info['tileset'] == 'johto':
            try:
                decoded = decode_cells(layout, gold_tiles, johto_collision, width, height)
            except ValueError as exc:
                issues.append(name + ':gold_collision:' + str(exc))
                continue
            water = sum(c['role'] == 'WATER' for c in decoded)
            if water != info['water_cells']:
                issues.append(name + ':gold_water_cells')
            # RPP's base JOHTO blockset has additional blocks and the explicit
            # Gold LADDER $06 clone. Compare precisely the IDs this map uses.
            # This detects visual drift without falsely failing on unrelated extras.
            different = [i for i in set(layout) if i * 16 + 16 > len(rpp_tiles)
                         or rpp_tiles[i * 16:i * 16+16] != gold_tiles[i * 16:i * 16+16]]
            if different:
                issues.append(name + ':used_metatile_graphics:' + ','.join(str(i) for i in sorted(different)))
        rows.append({'map': name, 'stable_local_id': local_id, 'width': width,
                     'height': height, 'gold_sha256': hashlib.sha256(layout).hexdigest(),
                     'gold_warps': len(events['warps']), 'status': 'SOURCE_CHECKED'})
    seams = spec.get('direct_seams', [])
    for s in seams:
        if s['from'] not in actual_connections:
            actual_connections[s['from']] = gold_connections(gold, s['from'])
        name, target, direction, offset = s['from'], s['to'], s['direction'], s['gold_offset_blocks']
        got = connection_override.get(name) if connection_override and name in connection_override else actual_connections.get(name, [])
        if not any(c['to'] == target and c['direction'] == direction
                   and int(c['offset']) == offset for c in got):
            issues.append(name + ':' + target + ':source_seam')
        if not any(x['from'] == target and x['to'] == name
                   and x['direction'] == REVERSE[direction] and
                   x['gold_offset_blocks'] == -offset for x in seams):
            issues.append(name + ':' + target + ':missing_reciprocal_manifest')
    if not spec.get('purpose') == 'OFFLINE_ONLY_NOT_RUNTIME_APPROVED':
        issues.append('unsafe_runtime_approval')
    return {'status': 'PASS' if not issues else 'FAIL', 'version': 'SPID-5.62.239',
            'scope': 'OFFLINE_SOURCE_ONLY', 'gameplay_ready': False,
            'maps_checked': len(rows), 'directed_seams_checked': len(seams),
            'errors': issues, 'maps': rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--gold', type=Path, required=True)
    args = parser.parse_args()
    result = audit(args.project, args.gold)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(0 if result['status'] == 'PASS' else 1)


if __name__ == '__main__':
    main()
