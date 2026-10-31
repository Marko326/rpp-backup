#!/usr/bin/env python3
"""Fail-closed source gate for Route35 + Route35GoldenrodGate onboarding.

This uses the existing Gold converter for staging; it NEVER enables a map,
changes RPP runtime ASM, or asserts phone/ROM acceptance. The NorthSouthGate
layout in the CURRENT project is already a verified shared Gold source, but
Route35's 180-byte Gold block layout must be supplied in full.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

from johto_gold_compat import resolve_gold_root
from johto_gold_sources import gold_block_sources

GATE = 'Route35GoldenrodGate'
ROAD = 'Route35'
EXPECTED_WARPS = {
    'GoldenrodCity': ((19, 1, 'ROUTE_35_GOLDENROD_GATE', 3),),
    GATE: ((4, 0, 'ROUTE_35', 1), (5, 0, 'ROUTE_35', 2),
           (4, 7, 'GOLDENROD_CITY', 13), (5, 7, 'GOLDENROD_CITY', 13)),
    ROAD: ((9, 33, 'ROUTE_35_GOLDENROD_GATE', 1),
           (10, 33, 'ROUTE_35_GOLDENROD_GATE', 2),
           (3, 5, 'ROUTE_35_NATIONAL_PARK_GATE', 3)),
}
EXPECTED_SEAMS = {
    ('GoldenrodCity', 'north'): ('Route35', 5),
    ('Route35', 'south'): ('GoldenrodCity', -5),
    ('Route35', 'north'): ('Route36', 0),
    ('Route36', 'south'): ('Route35', 0),
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def parse_warps(source):
    result = []
    for x, y, destination, entry in re.findall(
            r'^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z0-9_]*)\s*,\s*(\d+)',
            source, re.M):
        result.append((int(x), int(y), destination, int(entry)))
    return tuple(result)


def read_dimensions(root):
    raw = (root / 'constants/map_constants.asm').read_text()
    return {name: (int(w), int(h)) for name, w, h in re.findall(
        r'^\s*map_const\s+([A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*(\d+)', raw, re.M)}


def read_seams(root):
    raw = (root / 'data/maps/attributes.asm').read_text()
    current = None
    seams = {}
    for ln in raw.splitlines():
        match = re.match(r'^\s*map_attributes\s+(\w+),', ln)
        if match:
            current = match[1]
            continue
        match = re.match(r'^\s*connection\s+(north|south|east|west),\s*(\w+),\s*\w+,\s*(-?\d+)', ln)
        if match and current:
            seams[(current, match[1])] = (match[2], int(match[3]))
    return seams


def inspect_project(project):
    constants = (project / 'constants/region_map_constants.asm').read_text()
    for token in ('DEF NUM_JOHTO_ACTIVE_MAPS EQU 21',
                  'DEF JOHTO_ROUTE_35_LOCAL_ID EQU 17',
                  'DEF JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID EQU 18'):
        require(token in constants, 'Clean .282 project registration changed: ' + token)
    version = (project / 'data/game_version.asm').read_text()
    require('FIX-5.62.282' in version,
            'This preparation gate is based on FIX-5.62.282; inspect actual worktree first')
    require(not (project / 'maps/johto_pilot/Route35.runtime.blk').exists(),
            'Route35 already has a runtime map; use the actual new-stage audit')
    source = (project / 'data/johto_south_runtime.asm').read_text()
    require('JohtoSouthGoldenrodCityRuntimeHeader::' in source and
            'JohtoSouthRoute34RuntimeHeader::' in source,
            'Required .282 southern corridor missing')
    a = (project / 'maps/johto_pilot/Route34IlexForestGate.gold.blk').read_bytes()
    b = (project / 'maps/johto_pilot/Route36RuinsOfAlphGate.gold.blk').read_bytes()
    staged = (project / 'maps/johto_staged/Route35GoldenrodGate.gold.blk').read_bytes()
    require(len(a) == 20 and a == b == staged,
            'Route35 Goldenrod Gate shared Gold NorthSouthGate source differs')
    return {'active_maps': 21, 'gate_shared_bytes': len(staged),
            'gate_sha256': hashlib.sha256(staged).hexdigest(),
            'current_version': 'FIX-5.62.282', 'runtime_enabled': False}


def inspect_gold(gold, project):
    mapping = gold_block_sources(gold)
    require(mapping.get(GATE) == mapping.get('Route34IlexForestGate') == 'maps/NorthSouthGate.blk',
            'Gold gate must reuse source NorthSouthGate.blk')
    require(mapping.get(ROAD) == 'maps/Route35.blk',
            'Gold Route35 must use original maps/Route35.blk')
    gate = (gold / mapping[GATE]).read_bytes()
    road = (gold / mapping[ROAD]).read_bytes()
    shared = (project / 'maps/johto_staged/Route35GoldenrodGate.gold.blk').read_bytes()
    require(len(gate) == 20 and gate == shared, 'Shared NorthSouthGate source mismatch')
    require(len(road) == 180 and all(i < 128 for i in road),
            'Route35 must be exactly 180 valid Gold block bytes (10x18)')
    # The currently visible 3x10 Goldenrod north-edge pixels were frozen in
    # FIX-279. Never activate Route35 if its actual Gold bottom edge differs.
    engine=(project/'engine/johto_ilex_mature_runtime_275.asm').read_text()
    block=engine.split('PatchJohtoGoldenrodNorthBorder::',1)[1]
    preview=[]
    for row in ('row0','row1','row2'):
        match=re.search(r'(?m)^\.'+row+r'\s*\n\s*db\s+([^;\n]+)',block)
        require(bool(match),f'Missing Goldenrod north preview {row}')
        values=[int(n[1:],16) if n.startswith('$') else int(n) for n in
                (entry.strip() for entry in match[1].split(','))]
        require(len(values)==10, f'Goldenrod preview {row} not 10 blocks')
        preview.extend(values)
    require(road[-30:]==bytes(preview),
            'Route35 Gold southern three rows disagree with existing Goldenrod north preview')

    dims = read_dimensions(gold)
    require(dims.get('ROUTE_35') == (10, 18), 'Gold Route35 dimensions not 10x18')
    require(dims.get('ROUTE_35_GOLDENROD_GATE') == (5, 4), 'Gold gate dimensions not 5x4')
    for name, expected in EXPECTED_WARPS.items():
        raw = (gold / 'maps' / (name + '.asm')).read_text()
        actual = parse_warps(raw)
        if name == 'GoldenrodCity':
            require(all(w in actual for w in expected), 'Gold Goldenrod north gate warp missing')
        else:
            require(actual == expected, f'Gold {name} warp contract mismatch: {actual!r}')
    seams = read_seams(gold)
    for key, value in EXPECTED_SEAMS.items():
        require(seams.get(key) == value, f'Gold source seam wrong: {key}: {seams.get(key)}')
    # Do not allow original Gold's seamless city-road topology to bypass
    # the Gate warp: that source connection needs a *runtime* collision fence.
    return {'route35_bytes': len(road), 'route35_sha256': hashlib.sha256(road).hexdigest(),
            'gate_gold_bytes': len(gate), 'gate_gold_sha256': hashlib.sha256(gate).hexdigest(),
            'warp_contract': True, 'gold_seams': True,
            'national_park_exit_open': False, 'runtime_approved': False}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project', type=Path, required=True)
    ap.add_argument('--gold-root', type=Path)
    ap.add_argument('--output', type=Path)
    ap.add_argument('--gold-profile', choices=('auto', 'pret', 'mus'), default='auto')
    args = ap.parse_args(argv)
    try:
        project = args.project.resolve()
        project_info = inspect_project(project)
        if args.gold_root is None:
            print(json.dumps({'status':'BLOCKED_MISSING_GOLD_ROOT', 'project':project_info,
                              'required':['maps/Route35.blk','maps/NorthSouthGate.blk',
                                          'data/maps/blocks.asm','maps/Route35.asm',
                                          'maps/Route35GoldenrodGate.asm'],
                              'runtime_approved':False}, ensure_ascii=False))
            return 2
        gold = resolve_gold_root(args.gold_root, args.gold_profile)
        gold_info = inspect_gold(gold, project)
        if args.output is None:
            print(json.dumps({'status':'GOLD_SOURCE_CONFIRMED', 'project':project_info,
                              'gold':gold_info,'runtime_approved':False}, ensure_ascii=False))
            return 0
        from johto_rpp_pipeline import stage_adjacent_pair, stage_gold_map_candidate
        from johto_rpp_asset_audit import layout_inventory, tileset_key
        from johto_indoor_common import safe_roots, dump
        _, _, output = safe_roots(project, gold, args.output)
        inventory={x['name']:x for x in layout_inventory(gold)}
        # Reuse the existing Gold pipeline; do not generate or register game ASM.
        route35 = stage_adjacent_pair(project, gold, output/'Route35_Route36',
                                       ('Route35', 'Route36'))
        key=tileset_key(inventory[GATE]['tileset'])
        gate=stage_gold_map_candidate(project, gold, output/GATE, GATE, key)
        require(gate['staged_blk_matches_gold'], 'Gate stage not byte-exact Gold source')
        manifest={'status':'OFFLINE_STAGED_NOT_RUNTIME','project':project_info,
                  'gold':gold_info,'route35_route36_seams':route35['direct_seams'],
                  'gate':gate,'runtime_approved':False,'build_performed':False}
        dump(output,'route35_stage_manifest.json',manifest)
        print(json.dumps(manifest,ensure_ascii=False))
        return 0
    except (ValueError, FileNotFoundError, OSError) as exc:
        print(json.dumps({'status':'BLOCKED_SOURCE_OR_CONTRACT', 'reason':str(exc),
                          'runtime_approved':False},ensure_ascii=False))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
