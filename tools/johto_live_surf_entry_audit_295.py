#!/usr/bin/env python3
"""FIX-295: live, fail-closed A-button/Surfboard/movement/shore path audit.

Unlike the historical water inventory, this enumerates *actual active* Gold
WATER maps and verifies whether a JOHTO_PILOT spatial-role-backed map is
reachable from both Surf initiation and Surf movement. A role array with 20
WATER bytes is not evidence of Surf gameplay by itself. Read-only, static.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re

from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_coverage_audit import read_active_maps
from johto_surf_preflight import code_only, routine

ENTRY = 'engine/overworld/field_moves.asm'
ITEMS = 'engine/items/items.asm'
SURF = 'engine/johto_violet_field_skills.asm'
SPATIAL = 'engine/johto_south_geometry.asm'
DESCRIPTORS = 'data/johto_pilot_runtime_assets.asm'


def audit(root: Path, gold_root: Path, overrides: dict[str, str] | None = None) -> dict:
    root = Path(root)
    overrides = overrides or {}
    def read(rel: str) -> str:
        return overrides[rel] if rel in overrides else (root / rel).read_text(encoding='utf8')

    source = {p: code_only(read(p)) for p in (ENTRY, ITEMS, SURF, SPATIAL, DESCRIPTORS)}
    runtime = routine(source[SURF], 'JohtoOverworldSurfDecision')
    spatial = routine(source[SPATIAL], 'JohtoSouthSpatialRoleAhead')
    violet_entry = routine(source[SURF], 'JohtoVioletWaterAhead')
    error: list[str] = []
    records = []

    # Check the common *actual* initiation path; no source-wide substring
    # matching, and reject a false appearance in another unrelated routine.
    if not re.search(r'(?m)^callab JohtoVioletWaterAhead\s*\nret c$', routine(source[ENTRY], 'IsSurfTile')):
        error.append('IsSurfTile: A-button Surf fails to forward water Carry')
    if not re.search(r'(?m)^callab JohtoVioletWaterAhead\s*\n(?:jr|jp) c, \.shoreOrWater$',
                     routine(source[ITEMS], 'IsNextTileShoreOrWater')):
        error.append('IsNextTileShoreOrWater: Surfboard/item water entry missing')
    if not re.search(r'(?m)^callab JohtoSouthGoldWaterProbe\s*\nret c$', violet_entry):
        error.append('JohtoVioletWaterAhead: shared Gold water probe not reachable from Surf initiation')
    if not re.search(r'\.southModern\s+callab JohtoSouthGoldWaterProbe\s+' 
                     r'jp c, \.water\s+callab JohtoSouthGoldShoreProbe\s+'
                     r'jp c, \.floorShore\s+jp \.shore', runtime):
        error.append('JohtoOverworldSurfDecision: Gold water and safe shore branch broken')
    if not re.search(r'(?m)^cp JOHTO_PILOT\s*\njp nz, \.legacy$',runtime) or not re.search(
            r'(?m)^cp MAP_REGION_JOHTO\s*\njp nz, \.legacy$',runtime):
        error.append('JohtoOverworldSurfDecision: missing JOHTO_PILOT+region routing guard')
    if not re.search(r'(?m)^call JohtoSouthSpatialRoleAhead\s*\nld a, e\s*\ncp 2',
                     routine(source[SPATIAL], 'JohtoSouthGoldWaterProbe')):
        error.append('JohtoSouthGoldWaterProbe: missing live role=2 lookup')

    # Exclude non-pilot tilesets, since JOHTO_MODERN/PARK etc have a separate
    # wCurMapTileset branch and older pilot maps have their own water helpers.
    descriptor_pairs = dict(re.findall(r'(?m)^db\s+(JOHTO_\w+_LOCAL_ID)\s*,\s*(JOHTO_\w+)\s*,',
                                       source[DESCRIPTORS]))
    # local ID symbol is deterministically paired to Gold asset by source
    # descriptor order, never guessed from map name spelling.
    live = read_active_maps(root)
    id_constants = read('constants/johto_fixed_map_ids.asm') + '\n' + read('constants/region_map_constants.asm')
    ids = {int(num[1:],16) if num.startswith('$') else int(num): symbol for symbol, num in
           re.findall(r'(?m)^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\$[0-9A-Fa-f]+|\d+)', id_constants)}
    gold = GoldCollisionIndex(gold_root)
    # Only branches before the first unconditional fallthrough to legacy are
    # executable. A later fake `cp/map` text must not satisfy this audit.
    pilot_dispatch = runtime.split('\n.violet\n', 1)[0].split('\njp .legacy\n', 1)[0]
    registered_legacy = {e['gold_map'] for e in json.loads(
        (root / 'tools/johto_surf_contracts.json').read_text(encoding='utf8'))['maps']}
    for m in live:
        name = m['map']
        water = {(c['y'], c['x']) for c in gold.cells(name).values() if c['role'] == 'WATER'}
        if not water:
            continue
        symbol = ids.get(m['stable_id'])
        tileset = descriptor_pairs.get(symbol)
        if tileset is None:
            error.append(f'{name}: active map missing live tileset descriptor')
            continue
        if tileset not in ('JOHTO_PILOT', 'JOHTO_PILOT_TILESET_ID'):
            continue
        # Gold-role-backed maps are those with a real spatial selector AND
        # per-cell bin, not per-map static contracts elsewhere. New maps
        # acquire this obligation without editing a whitelist.
        grid = root / 'maps/johto_pilot' / (name + '.roles.bin')
        selector = bool(re.search(r'(?m)^cp '+re.escape(symbol)+r'\s*\njp z, \.\w+$', spatial))
        indexed = 'maps/johto_pilot/' + name + '.roles.bin'
        role_grid = indexed in source[SPATIAL]
        if not (selector and role_grid and grid.is_file()):
            if name not in registered_legacy:
                error.append(f'{name}: Gold WATER map has neither live spatial role grid nor registered legacy water helper')
            # Older PILOT-only maps use their individually audited Surf helpers.
            continue
        raw = grid.read_bytes()
        if len(raw) != len(gold.cells(name)):
            error.append(f'{name}: runtime role grid dimensions do not match Gold')
        else:
            width = max(x for x,y in gold.cells(name)) + 1
            actual = {(y,x) for y in range(len(raw)//width) for x in range(width)
                      if raw[y*width+x] == 2}
            if actual != water:
                error.append(f'{name}: Gold WATER coordinates disagree with runtime role=2 grid')
        routed = bool(re.search(r'(?m)^cp '+re.escape(symbol)+r'\s*\njp z, \.southModern$', pilot_dispatch))
        if not routed:
            error.append(f'{name}: WATER role present but no live movement/landing dispatch {symbol} -> .southModern')
        records.append({'map':name,'stable_id':m['stable_id'],'water_cells':len(water),
                        'pilot_role_grid':True,'movement_and_shore_routed':routed})
    return {'status':'PASS_STATIC_ONLY' if not error else 'FAIL','errors':error,
            'role_backed_pilot_water_maps':records,'rom_built':False,'phone_verified':False}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project',type=Path,default=Path.cwd())
    p.add_argument('--gold-root',type=Path,required=True)
    a=p.parse_args()
    try: result=audit(a.project,a.gold_root)
    except (OSError,KeyError,ValueError,IndexError,AttributeError) as exc:
        result={'status':'FAIL','errors':[str(exc)]}
    print(json.dumps(result,indent=2,ensure_ascii=False))
    return 0 if result['status']=='PASS_STATIC_ONLY' else 1
if __name__=='__main__': raise SystemExit(main())
