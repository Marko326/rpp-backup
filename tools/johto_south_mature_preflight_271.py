#!/usr/bin/env python3
"""Validate south-map collision/arrival differences and live warp exceptions.

Gold's art roles are retained unchanged. NPC-243 marks additional closed
interior doors and forest carpets blocked, with narrow live-Warp exceptions.
This is source/static validation only, not a simulator or ROM build.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
CLOSED = {
    'JOHTO_AZALEA_TOWN_LOCAL_ID': {(9,5),(21,5),(15,9),(21,13),(10,15)},
    'JOHTO_ROUTE_34_LOCAL_ID': {(11,14),(11,15),(13,15),(13,41)},
    'JOHTO_GOLDENROD_CITY_LOCAL_ID': {
        (19,1),(9,5),(33,5),(15,7),(24,7),(33,9),(9,13),(5,15),
        (14,21),(31,21),(5,25),(15,27),(24,27),(11,29),(29,29)},
}
FOREST_SPECIAL = {(1,5),(3,42),(3,43)}


def audit(root=ROOT):
    root = Path(root)
    problems = []
    try:
        objects = (root/'data/johto_south_runtime.asm').read_text()
        for label, code in [('JohtoSouthAzaleaTownRuntimeObjects::', '$05'),
                            ('JohtoSouthGoldenrodCityRuntimeObjects::', '$35')]:
            m = re.search(re.escape(label) + r'\s*db\s+(\$[\da-fA-F]+)', objects)
            if not m or m.group(1).lower() != code:
                problems.append(label + ': wrong NPC-243/Gold border block')
        home = (root/'home/overworld.asm').read_text()
        segment = home.split('\n.normalPlayerSpriteAdvancement\n',1)[1].split('\n.notRunning',1)[0]
        if not re.search(r'cp\s+JOHTO_ILEX_FOREST\s+jr\s+nz,\s*\.checkRunningButton\s+'
                         r'ld a,\s*\[wd736\]\s+bit 6,\s*a\s+jr nz,\s*\.notRunning',segment):
            problems.append('ILEX-217 B-button mid-jump speedup guard missing')
        geo = (root/'engine/johto_south_geometry.asm').read_text()
        if not re.search(r'call JohtoSouthMatureDoorFence\s+jp nc,\s*\.matureDoorAllowed\s+'
                         r'pop hl[^\n]*\n\s*ld e,\s*1\s+ret',geo):
            problems.append('south spatial step does not enforce mature closed doors')
        body = geo.split('JohtoSouthMatureDoorFence::',1)[1].split('JohtoSouthAzaleaTownRoles::',1)[0]
        entries = re.findall(r'^\s*db\s+(JOHTO_\w+_LOCAL_ID),\s*(\d+),\s*(\d+)\s*$', body, re.M)
        parsed = {}
        for label, x, y in entries:
            parsed.setdefault(label,set()).add((int(x),int(y)))
        if parsed != CLOSED or len(entries) != 24:
            problems.append('mature blocked-door list must match 24 exact closed interiors')
        # FIX-281: cross-check the runtime black list against the exact
        # registered exterior Warp targets, not just the old mask. These
        # coordinates are FLOOR in Gold and may be crossed sideways on foot
        # or bike; only an outward DOWN collision must activate the gate.
        live_carpet = {(13, 37), (14, 37)}
        route_closed = parsed.get('JOHTO_ROUTE_34_LOCAL_ID', set())
        if route_closed & live_carpet:
            problems.append('registered Route34 gate carpets blocked by closed-door list')
        contract = json.loads((root/'tools/johto_pilot_door_contracts.json').read_text())
        for entry in contract['south_batch_routes']:
            code = {'AzaleaTown': 'JOHTO_AZALEA_TOWN_LOCAL_ID',
                    'Route34': 'JOHTO_ROUTE_34_LOCAL_ID',
                    'GoldenrodCity': 'JOHTO_GOLDENROD_CITY_LOCAL_ID'}.get(entry['source_gold_map'])
            if code and tuple(entry['source_xy']) in parsed.get(code, set()):
                problems.append('registered south Warp conflicts with closed interiors: ' + entry['id'])
        portal = (root/'engine/johto_south_portals.asm').read_text()
        warps = (root/'data/johto_south_runtime.asm').read_text()
        for x, ordinal in ((13,0),(14,1)):
            if f'db 37, {x}, {ordinal}, JOHTO_REGISTERED_WARP_SELECTOR' not in warps:
                problems.append(f'Registered Route34 gate carpet ({x},37) warp missing')
        if not re.search(r'(?s)\.route34\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wYCoord\]\s+cp 37.*?cp 13\s+jp z, \.carpet\s+cp 14\s+jp z, \.carpet',portal):
            problems.append('Route34 carpet must warp only on outward DOWN collision')
        for token in ('cp JOHTO_ILEX_FOREST_LOCAL_ID', 'cp PLAYER_DIR_UP',
                      'cp PLAYER_DIR_RIGHT', 'cp PLAYER_DIR_DOWN',
                      'cp 42', 'cp 43', 'cp 5', 'jp .blocked'):
            if token not in body:
                problems.append('forest carpet/door approach rule missing: '+token)
        # Three special forest cells remain FLOOR in source Gold roles; only
        # approved source-facing directions are permitted by runtime guard.
        for name,w,coords in [('AzaleaTown',40,CLOSED['JOHTO_AZALEA_TOWN_LOCAL_ID']),
                              ('Route34',20,CLOSED['JOHTO_ROUTE_34_LOCAL_ID']),
                              ('GoldenrodCity',40,CLOSED['JOHTO_GOLDENROD_CITY_LOCAL_ID']),
                              ('IlexForest',30,FOREST_SPECIAL)]:
            roles = (root/'maps/johto_pilot'/f'{name}.roles.bin').read_bytes()
            if any(roles[y*w+x] != 0 for x,y in coords):
                problems.append(name+': source Gold role data changed instead of runtime fence')
        if (root/'gfx/tilesets/johto_ilex_forest.2bpp').exists():
            problems.append('generated .2bpp should not ship')
    except (OSError, IndexError, ValueError, KeyError, TypeError) as exc:
        problems.append(str(exc))
    return problems

if __name__ == '__main__':
    problems = audit()
    if problems:
        print('FAIL:', *problems, sep='\n- ')
        raise SystemExit(1)
    print('PASS: borders, jump speed, 24 closed interiors, two live Route34 gate carpets, forest directional rules')
