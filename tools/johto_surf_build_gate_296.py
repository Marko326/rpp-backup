#!/usr/bin/env python3
"""TOOL-296 developer-side, all-active-map Surf admission audit.

This is invoked by developers during map editing, never by user ROM compilation.
The manifest freezes every
active source .blk hash and the original Gold WATER coordinates. Newly activated
maps or edited .blk fail this developer review until an explicit Gold-based audit.
For every water map, verify both initiation paths and the *reachable* swim and
shore handler. A manifest entry is never proof of runtime implementation.
Pass --gold-root during onboarding to independently compare Gold WATER bytes.
Read-only: never patches a map, changes gameplay, or pretends to run the ROM.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re

from johto_surf_coverage_audit import read_active_maps
from johto_surf_preflight import code_only, routine, check_project, water_coordinates
from johto_gold_door_audit import GoldCollisionIndex

MANIFEST = 'tools/johto_surf_active_water_manifest_296.json'
CONTRACT = 'tools/johto_surf_contracts.json'
SURF = 'engine/johto_violet_field_skills.asm'
SPATIAL = 'engine/johto_south_geometry.asm'
WEST_SEA = 'data/johto_west_sea_runtime_299.asm'
EAST_RUNTIME = 'data/johto_east_runtime_300.asm'
DESCRIPTORS = 'data/johto_pilot_runtime_assets.asm'
ENTRY = 'engine/overworld/field_moves.asm'
ITEMS = 'engine/items/items.asm'
HOME = 'home/overworld.asm'
CONSTANTS = ('constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm')


def audit(root: Path, gold_root: Path | None = None, *,
          overrides: dict[str, str] | None = None,
          active_override: list[dict] | None = None,
          manifest_override: dict | None = None,
          bytes_override: dict[str, bytes] | None = None) -> dict:
    root = Path(root)
    overrides, bytes_override = overrides or {}, bytes_override or {}
    def read(path: str) -> str:
        return overrides.get(path) if path in overrides else (root/path).read_text(encoding='utf8')
    def read_bytes(path: str) -> bytes:
        return bytes_override.get(path) if path in bytes_override else (root/path).read_bytes()
    manifest = manifest_override if manifest_override is not None else json.loads(read(MANIFEST))
    contract = json.loads(read(CONTRACT))
    active = active_override if active_override is not None else read_active_maps(root)
    errors: list[str] = []
    records: list[dict] = []
    frozen = manifest.get('maps', [])
    if manifest.get('schema_version') != 1 or len(frozen) != len(active):
        errors.append('ACTIVE_SURF_MANIFEST: active count changed: re-audit all Gold WATER maps before developer signoff')
    if len({x.get('map') for x in frozen}) != len(frozen):
        errors.append('ACTIVE_SURF_MANIFEST: duplicate map records')
    if len({x.get('map') for x in active}) != len(active):
        errors.append('ACTIVE_SURF_REGISTRY: duplicate active maps')
    frozen_by_name = {x['map']: x for x in frozen}
    live_names = {x['map'] for x in active}
    for name in frozen_by_name.keys() - live_names:
        errors.append(f'{name}: stale frozen Surf manifest record, map no longer active')

    sources = {path: code_only(read(path)) for path in
               (SURF, SPATIAL, WEST_SEA, EAST_RUNTIME, DESCRIPTORS, ENTRY, ITEMS, HOME)}
    asm = routine(sources[SURF], 'JohtoOverworldSurfDecision')
    selector = routine(sources[SPATIAL], 'JohtoSouthSpatialRoleAhead')
    west_selector = routine(sources[WEST_SEA], 'JohtoWestSeaSpatialRoleAhead')
    east_selector = routine(sources[EAST_RUNTIME], 'JohtoEastSpatialRoleAhead')
    water_probe = routine(sources[SPATIAL], 'JohtoSouthGoldWaterProbe')
    initiate = routine(sources[SURF], 'JohtoVioletWaterAhead')
    if not re.search(r'(?m)^callab JohtoVioletWaterAhead\s*\nret c$', routine(sources[ENTRY], 'IsSurfTile')):
        errors.append('SURF_INPUT: A-button WATER entry is missing/incorrect Carry')
    if not re.search(r'(?m)^callab JohtoVioletWaterAhead\s*\n(?:jr|jp) c, \.shoreOrWater$',
                     routine(sources[ITEMS], 'IsNextTileShoreOrWater')):
        errors.append('SURF_INPUT: Surfboard/item WATER entry is missing/incorrect Carry')
    if not re.search(r'(?m)^callab JohtoSouthGoldWaterProbe\s*\nret c$', initiate):
        errors.append('SURF_INPUT: south Gold WATER probe not reachable from A/item gateway')
    if not re.search(r'(?m)^callab JohtoWestSeaGoldWaterProbe\s*\nret c', initiate):
        errors.append('SURF_INPUT: west-sea Gold WATER probe not reachable from A/item gateway')
    if not re.search(r'(?m)^callab JohtoEastGoldWaterProbe\s*\nret c', initiate):
        errors.append('SURF_INPUT: east Route42 Gold WATER probe not reachable from A/item gateway')
    if not re.search(r'\.southModern\s+callab JohtoSouthGoldWaterProbe\s+'
                     r'jp c, \.water\s+callab JohtoSouthGoldShoreProbe\s+'
                     r'jp c, \.floorShore\s+jp \.shore', asm):
        errors.append('SURF_MOVE_LAND: south Gold movement/shore dispatch missing')
    if not re.search(r'\.westSea\s+callab JohtoWestSeaGoldWaterProbe\s+'
                     r'jp c, \.water\s+callab JohtoWestSeaUnsafeSurfEdge\s+'
                     r'jr nc, \.westSeaShore\s+ld a, \$ff\s+'
                     r'ld \[wTileInFrontOfPlayer\], a\s+jp \.shore\s+'
                     r'\.westSeaShore\s+callab JohtoWestSeaGoldShoreProbe', asm):
        errors.append('SURF_MOVE_LAND: west-sea WATER/unsafe-edge/shore dispatch missing')
    if not re.search(r'\.eastRoute42\s+callab JohtoEastGoldWaterProbe\s+'
                     r'jp c, \.water\s+callab JohtoEastUnsafeSurfEdge\s+'
                     r'jr nc, \.eastRoute42Shore\s+ld a, \$ff\s+'
                     r'ld \[wTileInFrontOfPlayer\], a\s+jp \.shore\s+'
                     r'\.eastRoute42Shore\s+callab JohtoEastGoldShoreProbe', asm):
        errors.append('SURF_MOVE_LAND: east Route42 WATER/unsafe-edge/shore dispatch missing')
    if not re.search(r'(?m)^call JohtoSouthSpatialRoleAhead\s*\nld a, e\s*\ncp 2', water_probe):
        errors.append('SURF_ROLE: Gold role=2 water query missing')
    # Do not accept a water mask whose direction-to-next-cell calculation is
    # incomplete. All four D-pad directions must select the adjacent Gold
    # quadrant before WATER/shore are decided; old .295 checked only role=2.
    direction_contracts = (
        r'cp PLAYER_DIR_UP\s+(?:jp|jr) z, \.north',
        r'cp PLAYER_DIR_DOWN\s+(?:jp|jr) z, \.south',
        r'cp PLAYER_DIR_LEFT\s+(?:jp|jr) z, \.west',
        r'cp PLAYER_DIR_RIGHT\s+(?:jp|jr) nz, \.bad\s+inc e',
        r'\.north\s+dec d\s+(?:jp|jr) \.bounds',
        r'\.south\s+inc d\s+(?:jp|jr) \.bounds',
        r'\.west\s+dec e\s+\.bounds',
        r'\.bounds\s+ld a, e\s+cp b\s+(?:jp|jr) nc, \.offMap\s+'
        r'ld a, d\s+cp c\s+(?:jp|jr) nc, \.offMap',
    )
    for index, pattern in enumerate(direction_contracts, 1):
        if not re.search(pattern, selector):
            errors.append(f'SURF_DPAD: Gold four-direction step/bounds rule #{index} missing')
    if not re.search(r'(?m)^call JohtoSouthSpatialStep',
                     routine(sources[SPATIAL], 'JohtoSouthGoldShoreProbe')):
        errors.append('SURF_LAND: mature walkable-shore predicate missing')
    # Require the ROM0 land/surf decision to dispatch the actual carry/zero ABI.
    if not re.search(r'callab JohtoOverworldSurfDecision\s+jr nc, \.johtoSurfNotWater\s+'
                     r'jp z, \.noCollision\s+jp \.stopSurfing',
                     routine(sources[HOME], 'CollisionCheckOnWater')):
        errors.append('SURF_MOVE_LAND: ROM0 does not consume Gold swim/shore flags')
    # Validate individual legacy helpers as well as shared Gold role-grid maps.
    errors.extend('SURF_LEGACY: '+msg for msg in check_project(root,contract,None))
    legacy = {x['gold_map']: x for x in contract['maps']}
    ids_text = '\n'.join(read(x) for x in CONSTANTS)
    ids = {int(num[1:],16) if num.startswith('$') else int(num): sym for sym,num in
           re.findall(r'(?m)^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\$[0-9A-Fa-f]+|\d+)',ids_text)}
    desc = dict(re.findall(r'(?m)^db\s+(JOHTO_\w+_LOCAL_ID)\s*,\s*(JOHTO_\w+)\s*,',sources[DESCRIPTORS]))
    # Source records freeze each active map's block dimensions.  This lets the
    # ordinary source-only CI validate role-grid byte dimensions without an
    # external Gold checkout; --gold-root still independently re-derives every
    # WATER coordinate and source byte during developer onboarding/signoff.
    equates = {k: int(v[1:],16) if v.startswith('$') else int(v) for k,v in re.findall(
        r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+)\s+EQU\s+(\$[0-9A-Fa-f]+|\d+)\b', ids_text)}
    source_records = read('data/johto_pilot_source_resources.asm')
    dimensions = {}
    dimension_token = r'(JOHTO_[A-Z0-9_]+|\$[0-9A-Fa-f]+|\d+)'
    for sid, wtoken, htoken in re.findall(
            r'(?m)^\s*db\s+MAP_REGION_JOHTO,\s*(JOHTO_\w+_LOCAL_ID),\s*'
            + dimension_token + r',\s*' + dimension_token + r'\s*$', source_records):
        def resolve_dimension(token: str) -> int | None:
            if token in equates:
                return equates[token]
            try:
                return int(token[1:], 16) if token.startswith('$') else int(token)
            except ValueError:
                return None
        width_blocks = resolve_dimension(wtoken)
        height_blocks = resolve_dimension(htoken)
        if width_blocks is not None and height_blocks is not None:
            dimensions[sid] = (width_blocks * 2, height_blocks * 2)
    # Executable dispatch prefix: ignore fake branches after the terminal legacy jump.
    pilot_prefix = asm.split('\n.violet\n',1)[0].split('\njp .legacy\n',1)[0]
    tile_prefix = pilot_prefix.split('\ncp JOHTO_PILOT\n',1)[0]
    if not re.search(r'(?m)^cp JOHTO_PILOT\s*\njp nz, \.legacy$',asm) or not re.search(
            r'(?m)^cp MAP_REGION_JOHTO\s*\njp nz, \.legacy$',asm):
        errors.append('SURF_REGION: Gold PILOT dispatcher lacks Johto/tileset guard')
    if not all(needle in selector for needle in ('wCurMap','JOHTO_RUNTIME_MAP_HANDLE',
                                                 'wCurRegion','MAP_REGION_JOHTO','wCurLocalMapID')):
        errors.append('SURF_SCOPE: south spatial selector missing map/region guards')
    if not all(needle in west_selector for needle in ('wCurMap','JOHTO_RUNTIME_MAP_HANDLE',
                                                       'wCurRegion','MAP_REGION_JOHTO','wCurLocalMapID')):
        errors.append('SURF_SCOPE: west-sea spatial selector missing map/region guards')
    if not all(needle in east_selector for needle in ('wCurMap','JOHTO_RUNTIME_MAP_HANDLE',
                                                       'wCurRegion','MAP_REGION_JOHTO','wCurLocalMapID')):
        errors.append('SURF_SCOPE: east spatial selector missing map/region guards')
    # Individual helper branch -> exact registered handler in the runnable block.
    gold = GoldCollisionIndex(gold_root) if gold_root is not None else None
    for m in active:
        name = m['map']
        manifest_row = frozen_by_name.get(name)
        if not manifest_row:
            errors.append(f'{name}: NEW ACTIVE MAP NOT SURF-REVIEWED; developer review required (water may be present)')
            continue
        if (manifest_row.get('stable_id') != m['stable_id'] or
                manifest_row.get('source_asset') != m['source_asset']):
            errors.append(f'{name}: frozen source ID/path differs from live registration')
        if hashlib.sha256(read_bytes(m['source_asset'])).hexdigest() != manifest_row.get('source_sha256'):
            errors.append(f'{name}: Gold source bytes changed without Surf review')
        coords_raw = manifest_row.get('water_yx')
        if not isinstance(coords_raw,list):
            errors.append(f'{name}: frozen Gold WATER coordinate list missing')
            continue
        coords = {tuple(p) for p in coords_raw if isinstance(p,list) and len(p)==2}
        if len(coords) != len(coords_raw):
            errors.append(f'{name}: frozen Gold WATER coordinates duplicated/invalid')
        if gold is not None:
            original = {(c['y'],c['x']) for c in gold.cells(name).values() if c['role']=='WATER'}
            if coords != original:
                errors.append(f'{name}: manifest WATER mask differs from original Gold')
            if m['exact_gold']:
                source_gold = gold.gold/'maps'/gold.block_files[name]
                if read_bytes(m['source_asset']) != source_gold.read_bytes():
                    errors.append(f'{name}: source map differs from original Gold')
        if not coords:
            # A previously dry map cannot quietly acquire role=2 WATER by
            # changing only its runtime grid (Gold .blk SHA would not change).
            # This includes staged-to-active maps with a mature role grid.
            dry_role='maps/johto_pilot/'+name+'.roles.bin'
            if dry_role in bytes_override or (root/dry_role).is_file():
                if 2 in read_bytes(dry_role):
                    errors.append(f'{name}: runtime WATER role=2 appeared on Gold-dry map')
            records.append({'map':name,'water_cells':0,'handler':'NO_WATER','status':'PASS'})
            continue
        sym = ids.get(m['stable_id'])
        tileset = desc.get(sym)
        if sym is None or tileset is None:
            errors.append(f'{name}: active WATER map has no live stable ID/tileset')
            continue
        if name in legacy:
            item = legacy[name]
            if item['local_id_symbol'] != sym or item['expected_water_cells'] != len(coords):
                errors.append(f'{name}: registered legacy Surf contract disagrees with WATER manifest')
            try:
                table = water_coordinates(read(item['routine_file']),item['water_table'],item['water_end'])
                if table != coords:
                    errors.append(f'{name}: registered legacy Surf table differs from frozen Gold coordinates')
            except (KeyError,ValueError) as exc:
                errors.append(f'{name}: invalid legacy WATER contract {exc}')
            helper=item['water_helper']
            if tileset == 'JOHTO_UNION_CAVE':
                if not re.search(r'(?m)^cp JOHTO_UNION_CAVE\s*\njp z, \.unionCave$', tile_prefix) or not re.search(
                        rf'\.unionCave\s+call {re.escape(helper)}',asm):
                    errors.append(f'{name}: legacy cave WATER movement/shore branch not executable')
            else:
                branch=re.search(r'(?m)^cp '+re.escape(sym)+r'\s*\njp z, \.(\w+)$',pilot_prefix)
                if not branch or not re.search(r'(?m)^\.'+re.escape(branch[1])+r'\s+call '
                                               +re.escape(helper)+r'\s+',asm):
                    errors.append(f'{name}: legacy WATER movement/shore branch not executable')
            records.append({'map':name,'water_cells':len(coords),'handler':'LEGACY','status':'CHECKED'})
            continue
        # New water-bearing maps cannot be signed off by declaring WATER cells
        # alone. A real 16x16 role-grid selector plus executable runtime branch is required.
        grid_rel='maps/johto_pilot/'+name+'.roles.bin'
        in_south = grid_rel in sources[SPATIAL] and bool(re.search(r'(?m)^cp '+re.escape(sym)+r'\b', selector))
        in_west = grid_rel in sources[WEST_SEA] and bool(re.search(r'(?m)^cp '+re.escape(sym)+r'\b', west_selector))
        in_east = grid_rel in sources[EAST_RUNTIME] and bool(re.search(r'(?m)^cp '+re.escape(sym)+r'\b', east_selector))
        # Olivine keeps its accepted role grid in the south geometry bank but
        # movement now routes through westSea so reciprocal Route40 seams can be checked.
        routed_west = in_west or name == 'OlivineCity'
        if not (in_south or in_west or in_east):
            errors.append(f'{name}: WATER present but no live Gold spatial selector/grid')
            continue
        raw = read_bytes(grid_rel)
        if gold is not None:
            cells = gold.cells(name)
            width = max(x for x,y in cells) + 1
            height = max(y for x,y in cells) + 1
        else:
            dims = dimensions.get(sym)
            if dims is None:
                errors.append(f'{name}: registered source dimensions unavailable for spatial role grid')
                continue
            width, height = dims
        if len(raw) != width*height:
            errors.append(f'{name}: spatial role grid size mismatch')
            continue
        actual = {(y,x) for y in range(height) for x in range(width) if raw[y*width+x] == 2}
        if actual != coords:
            errors.append(f'{name}: role=2 grid does not match Gold WATER coordinates')
        if tileset in ('JOHTO_PILOT','JOHTO_PILOT_TILESET_ID'):
            branch = '.eastRoute42' if in_east else '.westSea' if routed_west else '.southModern'
            if not re.search(r'(?m)^cp '+re.escape(sym)+r'\s*\n(?:jp|jr) z, '+re.escape(branch)+r'$',pilot_prefix):
                errors.append(f'{name}: WATER exists, Surf movement/shore not routed to live {branch}')
        elif not re.search(r'(?m)^cp '+re.escape(tileset)+r'\s*\njp z, \.southModern$', tile_prefix):
            errors.append(f'{name}: WATER exists, tileset {tileset} not routed to live .southModern')
        records.append({'map':name,'water_cells':len(coords),'handler':'GOLD_SPATIAL','status':'CHECKED'})
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','errors':errors,
            'active_maps':len(active),'water_maps':sum(bool(x['water_yx']) for x in frozen),
            'checked':records,'rom_built':False,'device_verified':False}


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path.cwd())
    p.add_argument('--gold-root',type=Path,default=Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None)
    a=p.parse_args()
    try:
        result=audit(a.root,a.gold_root)
    except (OSError,ValueError,KeyError,IndexError,TypeError) as exc:
        result={'status':'FAIL','errors':[str(exc)]}
    if result['status']=='FAIL':
        for err in result['errors']:
            print('SURF DEVELOPER AUDIT FAILED:',err)
        return 1
    print(f"SURF DEV AUDIT PASS (static): {result['active_maps']} active, {result['water_maps']} WATER maps; A/item, swim, shore verified")
    return 0
if __name__=='__main__':
    raise SystemExit(main())
