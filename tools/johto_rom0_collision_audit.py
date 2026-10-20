"""Static, fail-closed ROM0 -> bank $43 native land-collision ABI audit.

Checks the actual branch-to-callee graph, not just names/comments.  The
original map-specific predicates remain authoritative for their own XY/dir
behaviors; this ensures all recognized maps reach exactly their old predicate,
unknown IDs still run HOME's generic path, and Carry survives the round trip.
This is NOT a ROM linker/emulator proof.
"""
from pathlib import Path
import re

MAPPINGS = {
    'JOHTO_ROUTE_37_LOCAL_ID': 'JohtoRoute37CanStepAhead',
    'JOHTO_ROUTE_35_LOCAL_ID': 'JohtoRoute35CanStepAhead',
    'JOHTO_ROUTE_36_LOCAL_ID': 'JohtoRoute36CanStepAhead',
    'JOHTO_ROUTE_33_LOCAL_ID': 'JohtoRoute33CanStepAhead',
    'JOHTO_AZALEA_TOWN_LOCAL_ID': 'JohtoAzaleaCanStepAhead',
    'JOHTO_ILEX_FOREST_LOCAL_ID': 'JohtoIlexForestCanStepAhead',
    'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID': 'JohtoRoute34GateCanStepAhead',
    'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID': 'JohtoRoute34GateCanStepAhead',
    'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID': 'JohtoRuinsCanStepAhead',
    'JOHTO_RUINS_OF_ALPH_LOCAL_ID': 'JohtoRuinsCanStepAhead',
    'JOHTO_ROUTE_34_LOCAL_ID': 'JohtoRoute34CanStepAhead',
    'JOHTO_GOLDENROD_CITY_LOCAL_ID': 'JohtoGoldenrodCanStepAhead',
}


def audit(root, overrides=None):
    root = Path(root)
    overrides = overrides or {}
    def src(path):
        item = overrides.get(path)
        return item if item is not None else (root / path).read_text(encoding='utf8')

    errors = []
    home = src('home/overworld.asm')
    collision = src('engine/overworld/johto_route33_collision.asm')
    main = src('main.asm')
    try:
        step = home.split('CheckTilePassable::\n', 1)[1].split('\nCheckForJumpingAndTilePairCollisions::', 1)[0]
        romx = collision.split('JohtoNativeCanStepAhead::\n', 1)[1]
    except IndexError:
        return ['ROM0 native collision dispatch missing HOME or ROMX entry']
    guard = step.split('\n.route32Seam\n', 1)[0]
    if not re.search(r'ld a, \[wCurMap\]\s+cp REGION_NATIVE_MAP_SLOT\s+jr nz, \.route32Seam\s+'
                     r'ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.normal\s+'
                     r'callba JohtoNativeCanStepAhead\s+bit 0, e\b[^\n]*\n\s+jr z, \.normal\s+ret\b', guard):
        errors.append('ROM0 exact region gate / single far-call / Carry-preserving fallback ABI broken')
    if re.search(r'\bcp JOHTO_.*_LOCAL_ID\b|\bcallba Johto(?!NativeCanStepAhead)\w+CanStepAhead\b', guard):
        errors.append('ROM0 native collision dispatcher must not grow per-map ID/callee branches')
    seam = step.split('\n.route32Seam\n', 1)[-1]
    if not all(token in seam for token in ('cp JOHTO_ROUTE_32', 'cp PLAYER_DIR_DOWN',
            'cp JOHTO_ROUTE_32_HEIGHT * 2 - 1', 'cp 15',
            '.normal\n\tpredef GetTileAndCoordsInFrontOfPlayer',
            'ld hl,wTilesetCollisionPtr', '.tileNotPassable\n\tscf\n\tret')):
        errors.append('ROM0 legacy Route32 seam / generic collision fallback altered')
    if ('SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]' not in main or
            'INCLUDE "engine/overworld/johto_route33_collision.asm"' not in
            main.split('SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]', 1)[-1].split('SECTION ', 1)[0] or
            'INCLUDE "engine/overworld/johto_ilex_forest_collision.asm"' not in main):
        errors.append('native collision dispatcher / original callees must remain co-banked in ROMX $43')
    if not re.match(r'\s*ld a, \[wCurLocalMapID\]\s+', romx):
        errors.append('ROMX native collision dispatcher must load exact local map ID')
    compare = re.findall(r'(?m)^\s*cp (JOHTO_\w+_LOCAL_ID)\s*\n\s*jr (\w+), (\.\w+)',
                         romx.split('\n\tld e, 0\n', 1)[0])
    if len(compare) != len(MAPPINGS) or {x[0] for x in compare} != set(MAPPINGS) or any(cond != 'z' for _, cond, _ in compare):
        errors.append('ROMX native collision local-ID inventory / equality branches changed')
    branches = re.findall(r'(?m)^(\.\w+)\n\s*call (Johto\w+CanStepAhead)\n(?=\s*(?:jr \.handled|\.handled))',romx)
    if len(branches) != len(set(MAPPINGS.values())) or len({b for b,_ in branches}) != len(branches):
        errors.append('ROMX native collision callee branches missing or duplicated')
    targets = dict(branches)
    for mapid, _cond, label in compare:
        if targets.get(label) != MAPPINGS[mapid]:
            errors.append('ROMX wrong native map->collision predicate: '+mapid)
    if not re.search(r'\n\s*ld e, 0\n\s*ret\n\.route35\n', romx):
        errors.append('ROMX unknown local ID must return E=0 for original generic collision')
    if not re.search(r'\.handled\n\s*ld e, 1\n\s*ret(?:\n|$)', romx):
        errors.append('ROMX recognized local ID must return E=1 without changing Carry')
    if re.search(r'\n\s*(?:and a|or a|xor a|scf|ccf)\n\s*ret\b', romx.split('\n.handled\n')[-1]):
        errors.append('ROMX collision Carry must not be clobbered after predicate')
    return errors
