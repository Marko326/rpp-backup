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
        r'(?m)^(\w+)::\s*INCBIN\s+"(maps/johto_pilot/[^"\n]+)"', src))
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
    # MAP-268 is a different, explicitly checked representation: a Gold
    # quadrant role grid rather than a hand-written y,x WATER db table.
    # Never count a map as covered merely because a .roles.bin file exists.
    from johto_south_spatial_surf_audit import audit as audit_south_spatial
    south_check = audit_south_spatial(root, gold_root)
    if south_check['status'] != 'PASS_STATIC_ONLY':
        raise ValueError('south batch Surf missing/corrupt: ' + '; '.join(south_check['errors']))
    registered.update(('IlexForest', 'Route34', 'GoldenrodCity'))
    # MAP-283: independently require Route35 to have a registered Gold role
    # array and actual ROMX water probe before classifying its Surf as live.
    geo=(root/'engine/johto_south_geometry.asm').read_text()
    fld=(root/'engine/johto_violet_field_skills.asm').read_text()
    if ('JohtoNorthRoute35Roles:: INCBIN "maps/johto_pilot/Route35.roles.bin"' in geo and
        'cp JOHTO_ROUTE_35_LOCAL_ID' in geo and
        'cp JOHTO_ROUTE_35_LOCAL_ID' in fld and
        (root/'maps/johto_pilot/Route35.roles.bin').is_file()):
        registered.add('Route35')
    # MAP-294: the city pond uses the existing JOHTO_PILOT spatial Surf predicate.
    spatial=(root/'engine/johto_south_geometry.asm').read_text()
    surf_runtime=(root/'engine/johto_violet_field_skills.asm').read_text()
    if (any(r['map']=='EcruteakCity' for r in active)
        and 'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID' in spatial
        and 'JohtoEcruteakRoles:: INCBIN "maps/johto_pilot/EcruteakCity.roles.bin"' in spatial
        and 'JohtoSouthGoldWaterProbe' in surf_runtime
        and (root/'maps/johto_pilot/EcruteakCity.roles.bin').is_file()
        and (root/'maps/johto_pilot/EcruteakCity.roles.bin').read_bytes().count(2)==20):
        registered.add('EcruteakCity')
    # MAP-297: Olivine uses the same Gold-role spatial Surf predicate. Keep the
    # inventory independent from the manifest by requiring the live role table,
    # dispatcher branch and the exact 406 Gold WATER cells.
    if (any(r['map']=='OlivineCity' for r in active)
        and 'cp JOHTO_OLIVINE_CITY_LOCAL_ID' in spatial
        and 'JohtoOlivineRoles:: INCBIN "maps/johto_pilot/OlivineCity.roles.bin"' in spatial
        and 'cp JOHTO_OLIVINE_CITY_LOCAL_ID' in surf_runtime
        and 'JohtoSouthGoldWaterProbe' in surf_runtime
        and (root/'maps/johto_pilot/OlivineCity.roles.bin').is_file()
        and (root/'maps/johto_pilot/OlivineCity.roles.bin').read_bytes().count(2)==406):
        registered.add('OlivineCity')
    # MAP-299: Route40/Route41/Cianwood use the dedicated Bank $52 west-sea
    # selector.  Register them only when the live dispatcher and role-grid
    # coordinates independently match Gold WATER; the manifest alone is not proof.
    west_path=root/'data/johto_west_sea_runtime_299.asm'
    west_runtime=west_path.read_text() if west_path.is_file() else ''
    west_specs=(
        ('Route40','JOHTO_ROUTE_40_LOCAL_ID','JohtoRoute40Roles'),
        ('Route41','JOHTO_ROUTE_41_LOCAL_ID','JohtoRoute41Roles'),
        ('CianwoodCity','JOHTO_CIANWOOD_CITY_LOCAL_ID','JohtoCianwoodRoles'),
    )
    for name,symbol,label in west_specs:
        grid_path=root/'maps/johto_pilot'/f'{name}.roles.bin'
        if not (any(r['map']==name for r in active)
                and f'{label}:: INCBIN "maps/johto_pilot/{name}.roles.bin"' in west_runtime
                and f'cp {symbol}' in west_runtime
                and f'cp {symbol}\n    jp z, .westSea' in surf_runtime
                and 'JohtoWestSeaGoldWaterProbe' in surf_runtime
                and grid_path.is_file()):
            continue
        cells=gold.cells(name)
        width=max(c['x'] for c in cells.values())+1
        height=max(c['y'] for c in cells.values())+1
        raw=grid_path.read_bytes()
        if len(raw) != width*height:
            continue
        role_water={(y,x) for y in range(height) for x in range(width)
                    if raw[y*width+x] == 2}
        gold_water={(c['y'],c['x']) for c in cells.values() if c['role']=='WATER'}
        if role_water == gold_water:
            registered.add(name)
    # MAP-300: Route42 uses the east ROMX spatial role contract; require the
    # live selector, role grid and both Gold water/shore probes before marking it.
    east_path=root/'data/johto_east_runtime_300.asm'
    east_runtime=east_path.read_text() if east_path.is_file() else ''
    route42_roles=root/'maps/johto_pilot/Route42.roles.bin'
    if (any(r['map']=='Route42' for r in active)
            and 'JohtoRoute42Roles:: INCBIN "maps/johto_pilot/Route42.roles.bin"' in east_runtime
            and 'JohtoEastGoldWaterProbe::' in east_runtime
            and 'JohtoEastGoldShoreProbe::' in east_runtime
            and 'cp JOHTO_ROUTE_42_LOCAL_ID' in east_runtime
            and re.search(r'cp JOHTO_ROUTE_42_LOCAL_ID\s*\n\s*jp z, \.eastRoute42', surf_runtime)
            and route42_roles.is_file()
            and route42_roles.read_bytes().count(2)==120):
        registered.add('Route42')
    # REF-315: Route43 full Gold WATER grid routed through the existing east
    # Bank $53 water/shore probes. Require every link and frozen 72-water mask.
    route43_roles=root/'maps/johto_pilot/Route43.roles.bin'
    if (any(r['map']=='Route43' for r in active)
            and 'JohtoRoute43Roles:: INCBIN "maps/johto_pilot/Route43.roles.bin"' in east_runtime
            and 'JohtoEastGoldWaterProbe::' in east_runtime
            and 'JohtoEastGoldShoreProbe::' in east_runtime
            and 'cp JOHTO_ROUTE_43_LOCAL_ID' in east_runtime
            and re.search(r'cp JOHTO_ROUTE_43_LOCAL_ID\s*\n\s*jp z, \.eastRoute42', surf_runtime)
            and route43_roles.is_file()
            and len(route43_roles.read_bytes())==20*54
            and route43_roles.read_bytes().count(2)==72):
        gold_water={(c['y'],c['x']) for c in gold.cells('Route43').values() if c['role']=='WATER'}
        grid=route43_roles.read_bytes()
        role_water={(y,x) for y in range(54) for x in range(20) if grid[y*20+x]==2}
        if gold_water==role_water:
            registered.add('Route43')
    # REF-318: Lake of Rage uses the same Bank $53 east spatial Surf path.
    # Require exact 40x36 role geometry and all 300 Gold WATER cells.
    lake_roles=root/'maps/johto_pilot/LakeOfRage.roles.bin'
    if (any(r['map']=='LakeOfRage' for r in active)
            and 'JohtoLakeOfRageRoles:: INCBIN "maps/johto_pilot/LakeOfRage.roles.bin"' in east_runtime
            and 'JohtoEastGoldWaterProbe::' in east_runtime
            and 'JohtoEastGoldShoreProbe::' in east_runtime
            and 'cp JOHTO_LAKE_OF_RAGE_LOCAL_ID' in east_runtime
            and re.search(r'cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\s*\n\s*jp z, \.eastRoute42', surf_runtime)
            and lake_roles.is_file()
            and len(lake_roles.read_bytes())==40*36
            and lake_roles.read_bytes().count(2)==300):
        gold_water={(c['y'],c['x']) for c in gold.cells('LakeOfRage').values() if c['role']=='WATER'}
        grid=lake_roles.read_bytes()
        role_water={(y,x) for y in range(36) for x in range(40) if grid[y*40+x]==2}
        if gold_water==role_water:
            registered.add('LakeOfRage')
    # DEV-326 Blackthorn City: 80 Gold WATER quadrants in Bank $53.
    blackthorn_grid = root/'maps/johto_pilot/BlackthornCity.roles.bin'
    if (any(r['map']=='BlackthornCity' for r in active)
            and 'JohtoBlackthornRoles:: INCBIN "maps/johto_pilot/BlackthornCity.roles.bin"' in (root/'data/johto_blackthorn_runtime_326.asm').read_text()
            and 'cp JOHTO_BLACKTHORN_CITY_LOCAL_ID' in east_runtime
            and re.search(r'cp JOHTO_BLACKTHORN_CITY_LOCAL_ID\s*\n\s*jp z, \.eastRoute42', surf_runtime)
            and blackthorn_grid.is_file() and len(blackthorn_grid.read_bytes())==40*36):
        grid=blackthorn_grid.read_bytes()
        gold_water={(c['y'],c['x']) for c in gold.cells('BlackthornCity').values() if c['role']=='WATER'}
        if {(y,x) for y in range(36) for x in range(40) if grid[y*40+x]==2}==gold_water:
            registered.add('BlackthornCity')
    # DEV-324: Route44 exact Gold WATER grid (120 cells); cannot be declared
    # Surf-enabled by a map name or a reusable compact graphic tile alone.
    route44_roles = root/'maps/johto_pilot/Route44.roles.bin'
    if (any(r['map']=='Route44' for r in active)
            and 'JohtoRoute44Roles:: INCBIN "maps/johto_pilot/Route44.roles.bin"' in east_runtime
            and 'cp JOHTO_ROUTE_44_LOCAL_ID' in east_runtime
            and re.search(r'cp JOHTO_ROUTE_44_LOCAL_ID\s*\n\s*jp z, \.eastRoute42', surf_runtime)
            and route44_roles.is_file() and len(route44_roles.read_bytes())==60*18):
        grid=route44_roles.read_bytes()
        gold_water={(c['y'],c['x']) for c in gold.cells('Route44').values() if c['role']=='WATER'}
        role_water={(y,x) for y in range(18) for x in range(60) if grid[y*60+x]==2}
        if len(gold_water)==120 and gold_water==role_water:
            registered.add('Route44')
    # DEV-328 Route45 Gold WATER (16 quadrant cells) in the active south-chain role grid.
    route45_grid = root/'maps/johto_pilot/Route45.roles.bin'
    south_chain_src = (root/'data/johto_south_chain_runtime_328.asm').read_text() if (root/'data/johto_south_chain_runtime_328.asm').is_file() else ''
    if (any(r['map']=='Route45' for r in active)
            and 'JohtoRoute45Roles:: INCBIN "maps/johto_pilot/Route45.roles.bin"' in south_chain_src
            and 'cp JOHTO_ROUTE_45_LOCAL_ID' in east_runtime
            and re.search(r'cp JOHTO_ROUTE_45_LOCAL_ID\s*\n\s*jp z, \.eastRoute42', surf_runtime)
            and route45_grid.is_file() and len(route45_grid.read_bytes())==20*90):
        grid=route45_grid.read_bytes()
        gold_water={(c['y'],c['x']) for c in gold.cells('Route45').values() if c['role']=='WATER'}
        role_water={(y,x) for y in range(90) for x in range(20) if grid[y*20+x]==2}
        if len(gold_water)==16 and gold_water==role_water:
            registered.add('Route45')
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
