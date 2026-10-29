#!/usr/bin/env python3
"""Audit Surf, Cut and ledge coverage across every active Johto pilot map.

Read-only source/Gold audit. It intentionally excludes staged-only maps and
never claims ROM-link or phone acceptance. Gold collision coordinates are read
from the supplied original Gold source through the shared decoder.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys

from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_coverage_audit import read_active_maps
from johto_surf_preflight import check_project

HOP_ROLES = {
    'HOP_DOWN', 'HOP_DOWN_LEFT', 'HOP_DOWN_RIGHT',
    'HOP_LEFT', 'HOP_RIGHT', 'HOP_UP', 'HOP_UP_LEFT', 'HOP_UP_RIGHT',
}
LEDGE_TABLES = {
    'Route29': ('JOHTO_ROUTE_29_LOCAL_ID', 'JohtoPilotRoute29LedgeTiles'),
    'Route30': ('JOHTO_ROUTE_30_LOCAL_ID', 'JohtoPilotRoute29LedgeTiles'),
    'VioletCity': ('JOHTO_VIOLET_CITY_LOCAL_ID', 'JohtoPilotRoute29LedgeTiles'),
    'Route31': ('JOHTO_ROUTE_31_LOCAL_ID', 'JohtoPilotRoute31LedgeTiles'),
    'Route32': ('JOHTO_ROUTE_32_LOCAL_ID', 'JohtoPilotRoute31LedgeTiles'),
}


def _id_values(root: Path) -> dict[str, int]:
    text = '\n'.join((root / f).read_text(encoding='utf8') for f in (
        'constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm'))
    values = {}
    for symbol, raw in re.findall(
            r'^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\$[\da-fA-F]+|\d+)\b', text, re.M):
        values[symbol] = int(raw[1:], 16) if raw.startswith('$') else int(raw)
    return values


def _cut_records(root: Path, active: list[dict]) -> tuple[dict[str, set[tuple[int, int, int]]], list[str]]:
    source = (root / 'engine/johto_violet_field_skills.asm').read_text(encoding='utf8')
    ids = _id_values(root)
    active_by_id = {r['stable_id']: r['map'] for r in active}
    records: dict[str, set[tuple[int, int, int]]] = {r['map']: set() for r in active}
    errors: list[str] = []
    try:
        body = source.split('JohtoRoutesGoldCutCells::', 1)[1].split(
            'JohtoRoutesGoldCutCellsEnd::', 1)[0]
    except IndexError:
        return records, ['missing JohtoRoutesGoldCutCells table']
    for symbol, y, x, block in re.findall(
            r'(?m)^\s*db\s+(JOHTO_\w+_LOCAL_ID)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*\$([\da-fA-F]+)', body):
        if symbol not in ids or ids[symbol] not in active_by_id:
            errors.append(f'Cut record uses non-active ID symbol: {symbol}')
            continue
        records[active_by_id[ids[symbol]]].add((int(y), int(x), int(block, 16)))
    # Violet's long-standing single tree uses its dedicated helper instead of
    # the shared route table; its full coordinate/live-block contract has its
    # own regression test and is checked here as an explicit exact record.
    violet = source.split('JohtoVioletCutTreeAhead::', 1)
    if len(violet) != 2:
        errors.append('missing JohtoVioletCutTreeAhead')
    else:
        body = violet[1].split('\nJohtoRoutesGoldCutCells::', 1)[0]
        required = ('call JohtoVioletIsActive', 'cp 36', 'cp 18', 'cp 20',
                    'cp 37', 'cp 19', 'cp 35', 'cp $63')
        missing = [x for x in required if x not in body]
        if missing:
            errors.append('Violet Cut helper missing exact Gold guard(s): ' + ', '.join(missing))
        elif 'VioletCity' in records:
            records['VioletCity'].add((19, 36, 0x63))
    return records, errors


def _ledge_table_for_map(source: str, map_name: str) -> str | None:
    if map_name not in LEDGE_TABLES:
        return None
    symbol, table = LEDGE_TABLES[map_name]
    match = re.search(r'(?ms)^\.johtoPilot\s*$\n(.*?)(?=^\.checkPairs\s*$)', source.split('HandleLedges:', 1)[1])
    if not match:
        return None
    dispatch = match.group(1)
    if map_name in ('Route29', 'Route30', 'VioletCity'):
        if re.search(rf'(?m)^\s*cp {re.escape(symbol)}\s*\n\s*jr z, \.supportedJohtoLedges\s*$', dispatch):
            return table if table in dispatch else None
        return None
    if map_name == 'Route31':
        if re.search(rf'(?m)^\s*cp {re.escape(symbol)}\s*\n\s*jr z, \.route31PairTable\s*$', dispatch):
            return table if table in dispatch else None
        return None
    # Route32 deliberately shares the reviewed Route31 table but must have its
    # own stable-ID guard before the common table label.
    if re.search(rf'(?m)^\s*cp {re.escape(symbol)}\s*\n\s*ret nz\s*\n\.route31PairTable\s*$', dispatch):
        return table if table in dispatch else None
    return None


def audit(root: Path, gold_root: Path) -> dict:
    root, gold_root = root.resolve(), gold_root.resolve()
    active = read_active_maps(root)
    gold = GoldCollisionIndex(gold_root)
    contract = json.loads((root / 'tools/johto_surf_contracts.json').read_text(encoding='utf8'))
    surf_errors = check_project(root, contract, gold_root)
    if surf_errors:
        raise ValueError('Surf preflight failed: ' + '; '.join(surf_errors))
    surf_maps = {entry['gold_map']: entry for entry in contract['maps']}
    cut_records, cut_errors = _cut_records(root, active)
    ledges = (root / 'engine/overworld/ledges.asm').read_text(encoding='utf8')
    rows = []
    errors = list(cut_errors)
    for item in active:
        name = item['map']
        cells = gold.cells(name)
        water = {(c['y'], c['x']) for c in cells.values() if c['role'] == 'WATER'}
        trees = {(c['y'], c['x'], c['block_id']) for c in cells.values()
                 if c['role'] == 'CUT_TREE'}
        hops = [c for c in cells.values() if c['role'] in HOP_ROLES]
        if item['exact_gold']:
            source_path = root / item['source_asset']
            original = gold.gold / 'maps' / gold.block_files[name]
            if source_path.read_bytes() != original.read_bytes():
                errors.append(f'{name}: Gold source .blk mismatch')
        if not water:
            surf_status = 'NO_WATER'
        elif name in surf_maps:
            surf_status = 'REGISTERED'
        else:
            surf_status = 'MISSING_SURF'
            errors.append(f'{name}: {len(water)} Gold WATER cells lack Surf contract')
        if not trees:
            cut_status = 'NO_CUT_TREE'
        elif cut_records.get(name, set()) == trees:
            cut_status = 'REGISTERED'
        else:
            cut_status = 'MISSING_OR_MISMATCHED_CUT'
            errors.append(f'{name}: Cut mismatch; expected {sorted(trees)}, got {sorted(cut_records.get(name, set()))}')
        if not hops:
            ledge_status = 'NO_HOPS'
            ledge_table = None
        else:
            ledge_table = _ledge_table_for_map(ledges, name)
            if ledge_table:
                ledge_status = 'REGISTERED'
            else:
                ledge_status = 'MISSING_LEDGE_DISPATCH'
                errors.append(f'{name}: {len(hops)} Gold HOP cells lack a map-specific ledge table')
        rows.append({
            'slot': item['slot'], 'stable_id': item['stable_id'], 'map': name,
            'water_cells': len(water), 'surf': surf_status,
            'cut_trees': len(trees), 'cut': cut_status,
            'hop_cells': len(hops), 'ledge': ledge_status, 'ledge_table': ledge_table,
        })
    totals = {
        'active_maps': len(active),
        'water_cells': sum(r['water_cells'] for r in rows),
        'cut_trees': sum(r['cut_trees'] for r in rows),
        'hop_cells': sum(r['hop_cells'] for r in rows),
    }
    return {
        'schema_version': 1,
        'gold_root': str(gold.gold),
        'status': 'PASS' if not errors else 'FAIL',
        'totals': totals, 'rows': rows, 'errors': errors,
        'runtime_verified': False, 'rom_built': False, 'phone_accepted': False,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--gold', type=Path, default=Path(os.environ['GOLD_SOURCE_ROOT'])
                        if os.environ.get('GOLD_SOURCE_ROOT') else None)
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args(argv)
    if args.gold is None:
        parser.error('--gold /path/to/pokegold required')
    try:
        result = audit(args.root, args.gold)
    except (OSError, ValueError, KeyError, IndexError) as exc:
        print(f'FAIL: {exc}', file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print('Active Johto field-move coverage (Gold source vs current project):')
        print('Map                  WATER Surf          CUT Cut                HOP Ledge')
        for r in result['rows']:
            print(f"{r['map']:<21} {r['water_cells']:>5} {r['surf']:<14} "
                  f"{r['cut_trees']:>3} {r['cut']:<21} {r['hop_cells']:>3} {r['ledge']}")
        print('Totals:', json.dumps(result['totals'], ensure_ascii=False))
        print('Status:', result['status'])
        if result['errors']:
            for err in result['errors']:
                print('FAIL:', err, file=sys.stderr)
        print('NOTE: source/static coverage only; no ROM build or phone acceptance')
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
