#!/usr/bin/env python3
"""REF-367E Ice Path 1F authored art/header/warp fail-closed audit (staged).

No ROM construction: verifies exact Gold 1F materials and an INACTIVE header
contract; does not equate staged ASM with a live player movement integration.
"""
from __future__ import annotations

import argparse
from collections import deque
import hashlib
import json
from pathlib import Path
import re
import sys
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.johto_ice_path_367_movement import Model, Position, DIRECTIONS

SRC = Path('data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm')
GFX = Path('gfx/tilesets/johto_ice_path_gold_96tiles.bin')
CONTRACT = Path('docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json')
GFX_SHA = '7037aa7097b5ebb92976b308a1c08b49248050524603708472d074fa549d8043'
EXPECTED_WARPS = (
    'db 19, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR',
    'db 27, 36, 1, JOHTO_REGISTERED_WARP_SELECTOR',
    'db 5, 37, 0, JOHTO_REGISTERED_WARP_SELECTOR',
    'db 13, 37, 6, JOHTO_REGISTERED_WARP_SELECTOR',
)


def audit(root: Path) -> list[str]:
    issues = []
    if not (root / SRC).is_file() or not (root / GFX).is_file():
        return ['Ice Path 1F header or 2bpp art missing']
    text = (root / SRC).read_text(encoding='utf8')
    # Strip comments; checks must inspect the executable rows, not old prose.
    code = '\n'.join(line.split(';', 1)[0].strip() for line in text.splitlines())
    role_bytes = (root / 'data/johto_ice_path_stage/IcePath1F.roles.bin').read_bytes()
    binary = (root / GFX).read_bytes()
    if len(binary) != 96 * 16 or hashlib.sha256(binary).hexdigest() != GFX_SHA:
        issues.append('1F Gold tile bytes corrupt or wrong converter output')
    if len(role_bytes) != 40 * 36:
        issues.append('1F Gold role table not 40x36')
    if ((root / 'maps/johto_ice_path_stage/IcePath1F.runtime.blk').read_bytes() !=
            (root / 'maps/johto_ice_path_stage/IcePath1F.gold.blk').read_bytes()):
        issues.append('1F runtime block layout diverges from Gold')
    for label in ('JohtoIcePath1FGoldGFX367E::', 'JohtoIcePath1FGoldBlocks367E::',
                  'JohtoIcePath1FRuntimeHeader367E::', 'JohtoIcePath1FObjects367E::'):
        if label not in code:
            issues.append(f'missing 1F stage label {label}')
    if 'db 18, 20' not in code or 'db $09' not in code or 'db 4' not in code:
        issues.append('incorrect 1F dimensions/border/four Gold ordinal slots')
    # Exactly four object warp entries, never drop/renumber sealed #3/#4.
    body = code.split('JohtoIcePath1FObjects367E::', 1)[-1]
    rows = re.findall(r'^db\s+(.+),\s*JOHTO_REGISTERED_WARP_SELECTOR$', body, re.M)
    if len(rows) != 4:
        issues.append(f'expected exactly 4 staged 1F Gold warp object rows, got {len(rows)}')
    for row in EXPECTED_WARPS:
        if code.count(row) != 1:
            issues.append(f'1F Gold warp missing/altered: {row}')
    # Verify selected destinations/ordinals against the independent Gold contract.
    contract = json.loads((root / CONTRACT).read_text(encoding='utf8'))
    m = next((m for m in contract['maps'] if m['name'] == 'IcePath1F'), None)
    if m is None or m['stable_id'] != 70 or [
        (w['ordinal0'], w['x'], w['y'], w['destination'], w['destination_warp_1_based'])
        for w in m['warps']
    ] != [
        (0, 4, 19, 'Route44', 1),
        (1, 36, 27, 'BlackthornCity', 7),
        (2, 37, 5, 'IcePathB1F', 1),
        (3, 37, 13, 'IcePathB1F', 7),
    ]:
        issues.append('1F Warp Gold contract mismatch')
    # REF-367F deliberately activates ONLY 1F as a walk-only preview.
    # Previous REF-367E required the header to be dormant; that policy is now
    # replaced by exact entry + image + collision gates. Basement stays sealed.
    project = {p:(root/p).read_text(encoding='utf8') for p in (
        'main.asm', 'constants/region_map_constants.asm',
        'data/johto_header_descriptors.asm', 'data/johto_pilot_runtime_assets.asm',
        'data/johto_pilot_source_resources.asm', 'data/johto_stable_id_slots.asm',
        'data/tileset_headers.asm', 'data/warp_tile_ids.asm',
        'data/dungeon_tilesets.asm', 'engine/johto_pilot_runtime.asm',
        'data/johto_vertical_gate_runtime_314.asm',
        'engine/johto_land_collision_gateway_272.asm',
        'home.asm', 'data/game_version.asm',
    )}
    must = {
        'main.asm': ('INCLUDE "data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm"',),
        'constants/region_map_constants.asm': ('NUM_JOHTO_ACTIVE_MAPS EQU 67',),
        'data/johto_header_descriptors.asm': ('dw JohtoIcePath1FRuntimeHeader367E',),
        'data/johto_pilot_runtime_assets.asm': ('JohtoIcePath1FRuntimeDescriptor::', '.icePath1F'),
        'data/johto_pilot_source_resources.asm': ('DEF JOHTO_PILOT_SOURCE_COUNT EQU 67', 'JohtoIcePath1FSourceGoldBlocks::'),
        'data/johto_stable_id_slots.asm': ('37, 38, 40, 39, 41, 42, 65, 43',),
        'data/tileset_headers.asm': ('tileset JohtoIcePath1FGoldBlocks367E, JohtoIcePath1FGoldGFX367E',),
        'data/warp_tile_ids.asm': ('dw JohtoIcePathWarpTileIDs',),
        'data/dungeon_tilesets.asm': ('JOHTO_ICE_PATH, $FF',),
        'home.asm': ('JohtoIcePath_Coll:: db $ff',),
        'data/game_version.asm': ('db "REF-367@"',),
        'engine/johto_land_collision_gateway_272.asm': ('callab JohtoIcePath1FLandDecision367F',),
        'engine/johto_pilot_runtime.asm': (
            'JohtoIcePath1FDownCarpet367F::',
            'cp JOHTO_ICE_PATH_1F_LOCAL_ID',
            'JohtoRegisteredWarpRoutesEnd::',
        ),
    }
    for path, tokens in must.items():
        for token in tokens:
            if token not in project[path]:
                issues.append(f'1F live gateway missing: {path}: {token}')
    # 367H: previous validators checked exact Gold .blk/.2bpp but omitted
    # the CGB runtime palette index ID41 (unbounded after ID40), and map-sign
    # dispatch uses a separate bank-local name table from Town Map browsing.
    palette_sets = (root / 'color/data/map_palette_sets.asm').read_text(encoding='utf8')
    palette_assignments = (root / 'color/data/map_palette_assignments.asm').read_text(encoding='utf8')
    palette_1f = (root / 'color/tilesets/johto_ice_path_1f.asm')
    name_sign = (root / 'engine/overworld/map_name_sign.asm').read_text(encoding='utf8')
    if 'ASSERT MapPaletteSetsEnd - MapPaletteSets == (JOHTO_ICE_PATH + 1) * 8' not in palette_sets:
        issues.append('Ice Path tileset ID41 is missing palette set length contract')
    if 'ASSERT MapPaletteAssignmentsEnd - MapPaletteAssignments == (JOHTO_ICE_PATH + 1) * $60' not in palette_assignments:
        issues.append('Ice Path tileset ID41 is missing palette assignment length contract')
    # Check actual active data, not merely the ASSERT text. The final 8 slots
    # must belong to Ice Path, before MapPaletteSetsEnd.
    rows = []
    section = palette_sets.split('MapPaletteSets:', 1)[-1].split('MapPaletteSetsEnd::', 1)[0]
    for line in section.splitlines():
        match = re.match(r'\s*db\s+([^;]+)', line)
        if match:
            rows.extend(v.strip() for v in match.group(1).split(','))
    expected_color_slots = ['CAVE_GRAY', 'CAVE_RED', 'CAVE_GREEN', 'CAVE_BLUE',
                            'CAVE_YELLOW', 'CAVE_BROWN', 'CAVE_LIGHT_BLUE', 'CRYS_TEXTBOX']
    if len(rows) != 42 * 8 or rows[-8:] != expected_color_slots:
        issues.append('Ice Path ID41 palette set runtime row missing or wrong')
    active_palette_assignments = '\n'.join(line.split(';', 1)[0] for line in palette_assignments.splitlines())
    if 'INCLUDE "color/tilesets/johto_ice_path_1f.asm"' not in active_palette_assignments:
        issues.append('Ice Path ID41 palette assignment runtime INCLUDE missing')
    if not palette_1f.is_file():
        issues.append('Ice Path Gold palette assignment resource missing')
    else:
        # RGBDS 0.5.2 requires macro invocations (tilepal) to be indented.
        # The original REF-367H palette parser stripped indentation, so an
        # illegal column-zero macro passed static validation but failed rgbasm.
        raw_lines = palette_1f.read_text(encoding='utf8').splitlines()
        for n, raw in enumerate(raw_lines, 1):
            active = raw.split(';', 1)[0]
            if re.match(r'^tilepal\b', active):
                issues.append(f'Ice Path ID41 palette macro not indented at line {n} (RGBDS syntax)')
        lines = [line.split(';', 1)[0].strip() for line in raw_lines]
        palettes = []
        for line in lines:
            if line.startswith('tilepal 0,'):
                palettes += [v.strip() for v in line.split('tilepal 0,', 1)[1].split(',')]
        expected_gold_rows = [
            'BROWN BROWN BROWN BROWN BROWN BROWN BROWN BROWN',
            'GRAY BROWN BROWN BROWN BROWN BROWN WATER WATER',
            'BROWN BROWN BROWN BROWN BROWN BROWN BROWN BROWN',
            'GRAY BROWN BROWN BROWN BROWN BROWN WATER WATER',
            'WATER BROWN BROWN BROWN BROWN BROWN GRAY GRAY',
            'WATER WATER BROWN BROWN WATER WATER WATER WATER',
            'BROWN WATER WATER WATER WATER WATER GRAY GRAY',
            'WATER WATER BROWN BROWN GRAY GRAY WATER WATER',
            'YELLOW YELLOW YELLOW YELLOW GREEN GRAY GRAY WATER',
            'WATER WATER WATER WATER WATER WATER WATER WATER',
            'BROWN BROWN GRAY GRAY WATER WATER WATER WATER',
            'WATER WATER WATER WATER WATER WATER WATER WATER',
        ]
        gold = [value for row in expected_gold_rows for value in row.split()]
        if len(palettes) != 96 or palettes != gold:
            issues.append('Ice Path ID41 palette assignments are not the 96 Gold tile palette IDs')
    if not re.search(r'cp JOHTO_ICE_PATH_1F_LOCAL_ID\s*\n\s*jp z, \.johtoIcePath', name_sign):
        issues.append('Ice Path ID70 missing map-name sign ID dispatch')
    # REF-367J: a shared .johtoResolved clears B to zero. ID70 must return
    # B=1 directly so the old Kanto suffix renderer prints "Ice Path 1F".
    if not re.search(r'\.johtoIcePath\s*\n\s*ld hl, \.JohtoIcePathName\s*\n\s*ld b, 1\b[^\n]*\n\s*ret\b', name_sign):
        issues.append('Ice Path 1F floor tag missing: resolver must return B=1, not common zero-floor path')
    if '.JohtoIcePathName: db "Ice Path@"' not in name_sign:
        issues.append('Ice Path map-name sign must display Ice Path, not Johto fallback')
    # REF-367J: real public item / bike-shortcut / sprite-reload entry, not
    # just a role helper that can never be reached. Gold CAVE only permits
    # mounting on FLOOR or DOWN carpet. The live role table has 0,5 and ICE=2.
    relief = (root / 'home/rom0_relief_349.asm').read_text(encoding='utf8')
    dispatch = relief.split('IsBikeRidingAllowed::', 1)[-1].split('\n.legacyBike\n', 1)[0]
    if not re.search(r'cp JOHTO_ICE_PATH_1F_LOCAL_ID\s+jp z, \.icePathBike', dispatch):
        issues.append('Ice Path 1F missing public bike-entry stable-ID dispatch')
    handler = relief.split('\n.icePathBike\n', 1)[-1].split('INCLUDE "data/bike_riding_tilesets.asm"', 1)[0]
    if not re.search(r'ld a, \[wWalkBikeSurfState\]\s+cp 1\s+jr z, \.allowed\s+callab JohtoIcePath1FBikeFloorAllowed367J\s+ret', handler):
        issues.append('Ice Path bike must preserve existing rider and call Gold-floor predicate on new mount')
    if 'JOHTO_ICE_PATH' in (root / 'data/bike_riding_tilesets.asm').read_text():
        issues.append('Ice Path may not be globally bike-enabled without Gold floor check')
    bike_asm = text.split('JohtoIcePath1FBikeFloorAllowed367J::', 1)[-1]
    if not re.search(
        r'ld a, \[wYCoord\]\s+ld b, a\s+ld a, \[wXCoord\]\s+ld c, a\s+'
        r'call JohtoIcePath1FRoleAt367F\s+pop hl\s+pop bc\s+and a\b[^\n]*'
        r'\n\s+jr z, \.allowed\s+cp 5\b[^\n]*\n\s+jr z, \.allowed\s+'
        r'and a\b[^\n]*\n\s+ret\s+\.allowed\s+scf\s+ret', bike_asm):
        issues.append('Ice Path Gold bike-floor predicate must allow roles 0/5 only and reject ICE/obstacles')
    if 'JohtoIcePath1FLandDecision367F::' not in text or 'cp 4 ; Gold LADDER:' not in text:
        issues.append('Ice Path land rule must remain walk-only; source ladders must be reviewed')
    save_entries = (root / 'engine/fly_town_map_helpers.asm').read_text(encoding='utf8')
    if ('dw JohtoPilotIcePathName' not in save_entries or
            'JohtoPilotIcePathName:: db "Ice Path@"' not in save_entries or
            'db 38 ; slot65 Ice Path 1F -> Gold IcePath browse index' not in save_entries or
            not re.search(r'db 54, 138[^\n]*slot65[^\n]*\n\s*dw JohtoPilotIcePathName', save_entries) or
            not re.search(r'db 54, 138[^\n]*slot66[^\n]*\n\s*dw JohtoPilotIcePathName', save_entries)):
        issues.append('Ice Path 1F Save/Continue/Town Map must use its own Ice Path name')
    runtime_profiles = (root / 'engine/johto_pilot_runtime.asm').read_text(encoding='utf8')
    if 'johto_map_profile 0, 38, MUSIC_DUNGEON2, 0 ; slot65 IcePath1F' not in runtime_profiles:
        issues.append('Ice Path 1F music/landmark profile points to Route44 instead of Ice Path')
    route_code = project['engine/johto_pilot_runtime.asm']
    routes = (
        'db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ICE_PATH_1F_LOCAL_ID',
        'db MAP_REGION_JOHTO, JOHTO_ICE_PATH_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID',
        'db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ICE_PATH_1F_LOCAL_ID',
        'db MAP_REGION_JOHTO, JOHTO_ICE_PATH_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID',
    )
    for entry in routes:
        if route_code.count(entry) != 1:
            issues.append(f'1F missing/duplicated real warp route: {entry}')
    # REF-367K: B1F is separately registered, but no B2F/B3F may activate.
    for path in ('data/johto_header_descriptors.asm', 'data/johto_pilot_runtime_assets.asm'):
        for closed in ('JohtoIcePathB2F', 'JohtoIcePathB3F'):
            if closed in project[path]: issues.append(f'inactive lower Ice Path floor activated: {path}: {closed}')
    step_code = (root / SRC).read_text(encoding='utf8')
    if any(token not in step_code for token in (
        'JohtoIcePath1FLandDecision367F::',
        'cp 4 ; Gold LADDER:',
        'cp 1 ; WALL',
        'ld e, 0 ; FLOOR / ICE / carpet / legal ledge is WALKABLE',
    )):
        issues.append('1F walk-only Gold collision runtime missing or ladder not sealed')
    for label in ('JohtoIcePathGoldRoleAt367B', 'JohtoIcePathProbeStep367C',
                  'JohtoIcePathSlideHeading367D'):
        if f'callab {label}' in route_code:
            issues.append(f'1F prematurely activated slide/path mechanics: {label}')
    # The Gold 1F has separated floor areas; one layer at a time means the
    # two ladders MUST NOT be rewritten as a made-up direct Route44->city path.
    model = Model(root)
    def reachable(start: tuple[int, int], goal: tuple[int, int]) -> bool:
        origin = Position('IcePath1F', *start)
        queue, seen = deque([origin]), {origin}
        while queue:
            pos = queue.popleft()
            if (pos.x, pos.y) == goal:
                return True
            for d in DIRECTIONS:
                nxt = model.move(pos, d).location
                if nxt.map == 'IcePath1F' and nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        return False
    if reachable((4, 19), (36, 27)) or reachable((36, 27), (4, 19)):
        issues.append('1F Gold route unexpectedly bypasses required B1F traversal')
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    issues = audit(args.root)
    for i in issues:
        print('FAIL', i)
    if issues:
        return 1
    print('PASS: Ice Path 1F exact 2bpp art, independent header, Gold 4-ordinal Warp skeleton, live 1F ordinary walking, Gold B1F return ladders')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
