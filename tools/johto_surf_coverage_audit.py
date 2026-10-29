#!/usr/bin/env python3
"""Inventory *all active* Johto maps for Gold WATER vs live Surf contracts.

Read-only. This complements johto_surf_preflight.py, which validates only
registered Surf helpers and does not discover maps still lacking Surf support.
No ROM or Git modification occurs. Gold reference source is required for counts.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys

from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_preflight import check_project

SOURCE_RECORDS = 'data/johto_pilot_source_resources.asm'
RUNTIME_RECORDS = 'data/johto_pilot_runtime_assets.asm'
CONSTANTS = ('constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm')
DEFAULT_SKIP: tuple[str, ...] = ()  # All active Gold WATER maps are now in scope.


def read_active_maps(root: Path) -> list[dict]:
    """Read live source & runtime descriptors; reject staged-only maps."""
    src = (root / SOURCE_RECORDS).read_text(encoding='utf8')
    runtime = (root / RUNTIME_RECORDS).read_text(encoding='utf8')
    reg = (root / CONSTANTS[0]).read_text(encoding='utf8')
    defs = '\n'.join((root / name).read_text(encoding='utf8') for name in CONSTANTS)
    count_match = re.search(r'^DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)\b', reg, re.M)
    if not count_match:
        raise ValueError('missing NUM_JOHTO_ACTIVE_MAPS')
    count = int(count_match[1])
    id_defs = {}
    for symbol, value in re.findall(r'^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\$[\da-fA-F]+|\d+)\b', defs, re.M):
        id_defs[symbol] = int(value[1:], 16) if value.startswith('$') else int(value)
    labels = dict(re.findall(
        r'(?m)^(\w+)::\s*\n\s*INCBIN\s+"(maps/johto_pilot/[^"\n]+)"', src))
    section = src.split('JohtoPilotSourceRecords::', 1)[-1].split('JohtoPilotSourceRecordsEnd::', 1)[0]
    rows = re.findall(r'(?m)^\s*db\s+MAP_REGION_JOHTO\s*,\s*(JOHTO_\w+_LOCAL_ID)\s*,[^\n]*\n\s*dw\s+(\w+)', section)
    if len(rows) != count:
        raise ValueError(f'active source descriptor count {len(rows)} != {count}')
    runtime_section = runtime.split('JohtoPilotRuntimeResourceDescriptors::', 1)[-1].split('JohtoPilotRuntimeResourceDescriptorsEnd::', 1)[0]
    runtime_ids = re.findall(r'(?m)^\s*db\s+(JOHTO_\w+_LOCAL_ID)\s*,', runtime_section)
    if runtime_ids != [symbol for symbol, _ in rows]:
        raise ValueError('source and runtime descriptor order/identities differ')
    out = []
    for slot, (symbol, label) in enumerate(rows):
        if symbol not in id_defs or label not in labels:
            raise ValueError(f'unresolved stable ID or source .blk label: {symbol} / {label}')
        block_path = labels[label]
        name = Path(block_path).name
        if name.endswith('.gold.blk'):
            name = name.removesuffix('.gold.blk')
            exact_gold = True
        elif name.endswith('.reference.blk'):
            name = name.removesuffix('.reference.blk')
            exact_gold = False  # Compact/remapped house is not Gold byte-identical.
        else:
            raise ValueError(f'unexpected source block file: {block_path}')
        out.append(dict(slot=slot, stable_id=id_defs[symbol], map=name,
                        source_asset=block_path, exact_gold=exact_gold))
    if len({r['stable_id'] for r in out}) != count or len({r['map'] for r in out}) != count:
        raise ValueError('duplicate stable IDs or map names')
    return out


def water_components(water: set[tuple[int, int]]) -> list[dict]:
    """Four-neighbor connected areas *within this map*, not across map seams."""
    remaining = set(water)
    result = []
    while remaining:
        stack = [remaining.pop()]
        component = []
        while stack:
            y, x = stack.pop()
            component.append((y, x))
            for neighbor in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    stack.append(neighbor)
        result.append(dict(cells=len(component),
                           bounds_xyxy=[min(x for _, x in component),
                                        min(y for y, _ in component),
                                        max(x for _, x in component),
                                        max(y for y, _ in component)]))
    return sorted(result, key=lambda c: (-c['cells'], c['bounds_xyxy']))


def audit(root: Path, gold_root: Path, skips: set[str]) -> dict:
    gold = GoldCollisionIndex(gold_root)
    active = read_active_maps(root)
    contract = json.loads((root / 'tools/johto_surf_contracts.json').read_text(encoding='utf8'))
    surf_errors = check_project(root, contract, gold_root)
    if surf_errors:
        raise ValueError('registered Surf preflight failed: ' + '; '.join(surf_errors))
    registered = {e['gold_map'] for e in contract['maps']}
    known_maps = {r['map'] for r in active}
    if not skips <= known_maps:
        raise ValueError('skip map not active: ' + ', '.join(sorted(skips - known_maps)))
    if not registered <= known_maps:
        raise ValueError('Surf contract contains inactive map: ' + ', '.join(sorted(registered - known_maps)))
    rows = []
    for item in active:
        name = item['map']
        cells = gold.cells(name)
        water = {(v['y'], v['x']) for v in cells.values() if v['role'] == 'WATER'}
        if item['exact_gold']:
            path = root / item['source_asset']
            original = gold.gold / 'maps' / gold.block_files[name]
            if path.read_bytes() != original.read_bytes():
                raise ValueError(f'{name}: .gold.blk differs from original Gold source')
        if not water:
            status = 'NO_WATER'
        elif name in skips:
            status = 'DEFERRED'
        elif name in registered:
            status = 'REGISTERED'
        else:
            status = 'MISSING_SURF'
        rows.append(dict(slot=item['slot'], stable_id=item['stable_id'], map=name,
                         gold_water_cells=len(water),
                         connected_water_areas=water_components(water), status=status))
    # Only currently active maps; staged cave and future regions must not be
    # misrepresented as already accessible or implemented.
    return dict(schema_version=1, source='active runtime source descriptors + Gold .blk/collision',
                gold_path=str(gold.gold), rows=rows,
                missing=[r['map'] for r in rows if r['status'] == 'MISSING_SURF'],
                deferred=[r['map'] for r in rows if r['status'] == 'DEFERRED'],
                registered=[r['map'] for r in rows if r['status'] == 'REGISTERED'],
                note='REGISTERED is static contract only, not a ROM/phone acceptance result')


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--gold', type=Path, default=Path(os.environ['GOLD_SOURCE_ROOT'])
                        if os.environ.get('GOLD_SOURCE_ROOT') else None)
    parser.add_argument('--skip-map', action='append', default=None,
                        help='Explicitly defer an active map (none by default)')
    parser.add_argument('--require-map', help='Fail if the chosen map has no complete Surf contract')
    parser.add_argument('--json', action='store_true', help='Write machine-readable JSON to stdout')
    args = parser.parse_args(argv)
    if args.gold is None:
        parser.error('--gold /path/to/pokegold required to verify source WATER cells')
    try:
        result = audit(args.root.resolve(), args.gold.resolve(),
                       set(DEFAULT_SKIP if args.skip_map is None else args.skip_map))
        names = {r['map']: r for r in result['rows']}
        if args.require_map and args.require_map not in names:
            raise ValueError(f'not an active map: {args.require_map}')
        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            print('Live Johto WATER coverage (Gold original 16x16 collision cells):')
            for row in result['rows']:
                print(f"slot {row['slot']:>2} | ID {row['stable_id']:>3} | {row['map']:<23} "
                      f"| WATER {row['gold_water_cells']:>3} | {row['status']}")
            print('NOTE: audit discovers unregistered active water; REGISTERED != phone-tested')
        if args.require_map and names[args.require_map]['status'] != 'REGISTERED':
            print(f'FAIL: {args.require_map} is {names[args.require_map]["status"]}', file=sys.stderr)
            return 1
        return 0
    except (OSError, ValueError, KeyError) as exc:
        print('FAIL:', exc, file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
