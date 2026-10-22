#!/usr/bin/env python3
"""SRF-5.62.187: audit Gold water and Surf call paths for cave + Route32.

This is static contract validation, not a ROM build or an input simulator.
Only Route32 and Union Cave 1F are approved. All Gold WATER collision
cells must match; copied/widened global 8x8 tile permissions are forbidden.
"""
import argparse
import json
from pathlib import Path
import re

from johto_surf_geometry_audit import inspect as geometry_inspect
from johto_gold_cells import decode_cells
from johto_route32_surf_geometry import check as route32_check, gold_cells as johto_water_cells

TABLE = re.compile(r'(?m)^JohtoUnionCaveWaterCells::\s*\n((?:\s*db\s+[^\n]+\n)+)')
PAIR = re.compile(r'^\s*db\s+(\d+)\s*,\s*(\d+)\s*$')


def audit(root: Path, gold: Path) -> list[str]:
    errors = []
    try:
        runtime = (root / 'engine/overworld/johto_union_cave_surf.asm').read_text()
        field = (root / 'engine/overworld/field_moves.asm').read_text()
        items = (root / 'engine/items/items.asm').read_text()
        home = (root / 'home/overworld.asm').read_text()
        menu = (root / 'engine/menu/start_sub_menus.asm').read_text()
        main = (root / 'main.asm').read_text()
        identities = json.loads((root / 'tools/johto_native_maps.json').read_text())
    except (OSError, ValueError) as exc:
        return [f'Surf runtime source missing/invalid: {exc}']

    errors.extend(route32_check(root, gold))
    # R35-5.62.220: audit the full rectangle against Gold, not an
    # assumption that every similarly-looking JOHTO graphic is water.
    try:
        route35 = johto_water_cells(gold, 'Route35')
        if route35 != {(y,x) for y in range(24,32) for x in range(4,8)}:
            errors.append('Route35 Surf Gold 32-cell rectangle mismatch')
        if (root/'maps/JohtoRoute35.blk').read_bytes() != (gold/'maps/Route35.blk').read_bytes():
            errors.append('Route35 Surf source blocks drift from Gold')
    except (OSError, ValueError) as exc:
        errors.append(f'Route35 Surf reference missing: {exc}')
    geometry = geometry_inspect(root, gold)
    errors.extend(geometry['errors'])
    expected = {(y, x) for x, y, _ in geometry.get('water_cells', [])}
    match = TABLE.search(runtime)
    actual = []
    if not match:
        errors.append('Gold cave WATER coordinate table missing or malformed')
    else:
        lines = match[1].splitlines()
        for line in lines:
            if line.strip().upper() == 'DB $FF':
                continue
            pair = PAIR.fullmatch(line)
            if not pair:
                errors.append(f'unsupported cave water table entry: {line.strip()}')
                continue
            actual.append((int(pair[1]), int(pair[2])))
        if len(actual) != 64 or len(set(actual)) != 64 or set(actual) != expected:
            errors.append('Union Cave Surf WATER coordinates differ from Gold 64 cells')
        if not lines or lines[-1].strip().upper() != 'DB $FF':
            errors.append('Union Cave water table missing $FF terminator')
    if (len(expected) != 64 or len(set(expected)) != 64):
        errors.append('Gold cave WATER reference has no independent 64-cell set')
    if 'INCLUDE "engine/overworld/johto_union_cave_surf.asm"' not in main:
        errors.append('ROMX Union Cave Surf helper not included in main.asm')
    if not re.search(r'SECTION "Johto Union Cave 1F Map", ROMX, BANK\[\$42\][\s\S]*?'
                     r'INCLUDE "engine/overworld/johto_union_cave_surf.asm"', main):
        errors.append('Surf helper is not in the validated Union Cave ROMX bank')

    # Exact branch polarity and facing tests matter. This detects the known
    # failure class of a "call exists" audit green-lighting a reversed result.
    must_have = (
        (runtime, 'ld a, [wCurMap]\n\tcp REGION_NATIVE_MAP_SLOT', 'native cave map guard'),
        (runtime, 'ld a, [wCurRegion]\n\tcp MAP_REGION_JOHTO', 'Johto region guard'),
        (runtime, 'ld a, [wCurLocalMapID]\n\tcp JOHTO_UNION_CAVE_1F_LOCAL_ID', 'cave local ID guard'),
        (runtime, 'cp SPRITE_FACING_DOWN\n\tjr nz, .up\n\tinc d', 'downward water lookup'),
        (runtime, 'cp SPRITE_FACING_UP\n\tjr nz, .left\n\tdec d', 'upward water lookup'),
        (runtime, 'cp SPRITE_FACING_LEFT\n\tjr nz, .right\n\tdec e', 'leftward water lookup'),
        (runtime, 'cp SPRITE_FACING_RIGHT\n\tjr nz, .notWater\n\tinc e', 'rightward water lookup'),
        (runtime, 'cp JOHTO_UNION_CAVE_1F_HEIGHT * 2\n\tjr nc, .notWater', 'Y bound'),
        (runtime, 'cp JOHTO_UNION_CAVE_1F_WIDTH * 2\n\tjr nc, .notWater', 'X bound'),
        (runtime, '.water\n\tscf\n\tjr .done\n.notWater\n\tand a', 'water flag polarity'),
        (runtime, 'IsJohtoSurfWaterAhead::\n\tld a, [wCurMapTileset]\n\tcp JOHTO_UNION_CAVE\n\tjp z, IsJohtoUnionCaveWaterAhead\n\tcp JOHTO\n\tjr nz, .noWater\n\tld a, [wCurMap]\n\tcp JOHTO_ROUTE_32\n\tjp z, IsJohtoRoute32WaterAhead', 'shared Johto Surf dispatch'),
        (field, 'cp JOHTO\n\tjr z, .johtoWater\n\tcp JOHTO_UNION_CAVE\n\tjr nz, .legacyWater\n.johtoWater\n\tcallba IsJohtoSurfWaterAhead\n\tret', 'facing Surf helper'),
        (items, 'cp JOHTO\n\tjr z, .johtoWater\n\tcp JOHTO_UNION_CAVE\n\tjr nz, .legacyWater\n.johtoWater\n\tcallba JohtoSurfStartOnWater ; carry CLEAR = approved water ahead\n\tret', 'bag/party Surf inverse-carry Surf entry'),
        (home, 'cp JOHTO\n\tjr z, .johtoWater\n\tcp JOHTO_UNION_CAVE\n\tjr nz, .legacyWater\n.johtoWater\n\tcallba IsJohtoSurfWaterAhead\n\tjr c, .noCollision', 'Surf movement water branch'),
        (home, '\tld c, a ; preserve the tile for the existing walkable shore test\n\tjr .checkIfNextTileIsPassable', 'Surf shore dismount'),

        (runtime, 'ld a, [wObtainedKantoBadges]\n\tbit 4, a ; SOUL_BADGE\n\tjr z, .denied', 'Kanto Soul Badge preserved'),
        (field, 'callba JohtoSurfBadgeAllowed\n\tjr nc, .cannotSurf', 'water interaction shared permission check'),
        (menu, 'callba JohtoSurfBadgeAllowed\n\tjp nc, .newBadgeRequired', 'party menu shared permission check'),
        (runtime, 'JohtoSurfStartOnWater::\n\tcall IsJohtoSurfWaterAhead\n\tccf', 'Surfboard water-only and carry polarity'),
    )
    for source, token, name in must_have:
        if token not in source:
            errors.append(f'cave Surf runtime contract missing/broken: {name}')
    if 'cp JOHTO_ROUTE_32\n\tjr z, .route32' not in runtime.split('JohtoSurfBadgeAllowed::',1)[-1]:
        errors.append('staged Route35/Route32/cave badge-free Surf permission: Route32 branch polarity wrong')
    # Permission must remain explicit per local map and preserve old Johto and
    # Kanto cases. Require each approved ID in the executed badge handler.
    badge=runtime.split('JohtoSurfBadgeAllowed::',1)[-1].split('\n.kanto\n',1)[0]
    for local in ('JOHTO_ROUTE_35_LOCAL_ID','JOHTO_RUINS_OF_ALPH_LOCAL_ID',
                  'JOHTO_ECRUTEAK_CITY_LOCAL_ID','JOHTO_ROUTE_42_LOCAL_ID',
                  'JOHTO_OLIVINE_CITY_LOCAL_ID','JOHTO_ROUTE_40_LOCAL_ID',
                  'JOHTO_ROUTE_41_LOCAL_ID','JOHTO_CIANWOOD_CITY_LOCAL_ID'):
        if not re.search(r'cp '+local+r'\s+(?:jr|jp)\s+(?:z,\s*\.route32|nz,\s*\.kanto)', badge):
            errors.append('Surf exact badge whitelist missing '+local)
    if 'cp JOHTO_UNION_CAVE' not in badge or 'cp JOHTO_ROUTE_32' not in badge:
        errors.append('legacy cave/Route32 Surf badge behavior removed')
    # Exact native map, bounds and facing checks are required on Route35.
    route35_must = (
        'IsJohtoRoute35WaterAhead::',
        'cp REGION_NATIVE_MAP_SLOT\n\tjr nz, .notWater',
        'cp JOHTO_ROUTE_35_LOCAL_ID\n\tjr nz, .notWater',
        'cp SPRITE_FACING_DOWN\n\tjr nz, .up\n\tinc d',
        'cp SPRITE_FACING_UP\n\tjr nz, .left\n\tdec d',
        'cp SPRITE_FACING_LEFT\n\tjr nz, .right\n\tdec e',
        'cp SPRITE_FACING_RIGHT\n\tjr nz, .notWater\n\tinc e',
        'cp 24\n\tjr c, .notWater\n\tcp 32\n\tjr nc, .notWater',
        'cp 4\n\tjr c, .notWater\n\tcp 8\n\tjr nc, .notWater',
        'cp REGION_NATIVE_MAP_SLOT\n\tjp z, IsJohtoNativeOutdoorWaterAhead',
    )
    for token in route35_must:
        if token not in runtime:
            errors.append('Route35 Surf runtime missing/changed: '+token[:50])
    # RUINS-5.62.224: independently derive Gold 16x16 WATER cells and
    # require precisely the two original rectangles. This is not a blanket
    # JOHTO-tileset enable; all other native outdoor maps remain excluded.
    try:
        gold_blocks = (gold / 'maps/RuinsOfAlphOutside.blk').read_bytes()
        rpp_blocks = (root / 'maps/JohtoRuinsOfAlphOutside.blk').read_bytes()
        art = (root / 'gfx/blocksets/johto.bst').read_bytes()
        walkable = set((root / 'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
        labels = []
        for line in (gold / 'data/tilesets/johto_collision.asm').read_text().splitlines():
            m = re.search(r'\btilecoll\s+([^;]+)', line)
            if m:
                fields = tuple(v.strip() for v in m[1].split(','))
                if len(fields) != 4:
                    raise ValueError('invalid Gold JOHTO collision quartet')
                labels.append(fields)
        if len(gold_blocks) != 180 or len(rpp_blocks) != 180 or len(art) % 16 or not walkable:
            raise ValueError('unexpected Ruins map/art dimensions')
        # RUINS-5.62.224: the map references $8A at block (2,15).  During
        # the cross-branch merge, the last 16-byte JOHTO block was omitted:
        # Surf-only water checks missed it because it is a dry cliff edge.
        # Reject ALL block IDs outside the actual loaded blockset, even when
        # the corresponding area is inaccessible without debug movement.
        max_block = max(rpp_blocks)
        if max_block >= len(art) // 16:
            errors.append(f'Ruins metatile ${max_block:02X} out of range: '
                          f'JOHTO blockset has {len(art) // 16} definitions')
        elif 0x8A in rpp_blocks and art[0x8A*16:0x8B*16] != bytes.fromhex(
                '3b0606063b0606063b0606064b4c214c'):
            errors.append('Ruins metatile $8A differs from reviewed backup branch')
        gold_water = {(2 * (i // 10) + q // 2, 2 * (i % 10) + q % 2)
                      for i, block in enumerate(gold_blocks)
                      for q, role in enumerate(labels[block]) if role == 'WATER'}
        expected_ruins = ({(y, x) for y in range(6, 14) for x in range(2, 6)}
                          | {(y, x) for y in range(26, 30) for x in range(12, 16)})
        if gold_water != expected_ruins or len(gold_water) != 48:
            errors.append('Ruins Surf original Gold WATER 48-cell geometry mismatch')
        for y, x in gold_water:
            offset = rpp_blocks[(y // 2) * 10 + x // 2] * 16
            pixel_y, pixel_x = (y % 2) * 2, (x % 2) * 2
            ids = {art[offset + (pixel_y + dy) * 4 + pixel_x + dx]
                   for dy in range(2) for dx in range(2)}
            if ids & walkable:
                errors.append(f'Ruins Surf WATER ({x},{y}) erroneously walkable on land')
                break
    except (ValueError, OSError, IndexError) as exc:
        errors.append(f'Ruins Surf Gold/RPP geometry unavailable: {exc}')
    native_dispatch = (
        'cp REGION_NATIVE_MAP_SLOT\n\tjp z, IsJohtoNativeOutdoorWaterAhead',
        'IsJohtoNativeOutdoorWaterAhead::\n\tld a, [wCurRegion]\n\tcp MAP_REGION_JOHTO',
        'cp JOHTO_ROUTE_35_LOCAL_ID\n\tjp z, IsJohtoRoute35WaterAhead',
        'cp JOHTO_RUINS_OF_ALPH_LOCAL_ID\n\tjp z, IsJohtoRuinsWaterAhead',
        'IsJohtoRuinsWaterAhead::',
        'cp SPRITE_FACING_DOWN\n\tjr nz, .up\n\tinc d',
        'cp SPRITE_FACING_UP\n\tjr nz, .left\n\tdec d',
        'cp SPRITE_FACING_LEFT\n\tjr nz, .right\n\tdec e',
        'cp SPRITE_FACING_RIGHT\n\tjr nz, .notWater\n\tinc e',
        'cp 6\n\tjr c, .notWater\n\tcp 14\n\tjr nc, .lower',
        'cp 2\n\tjr c, .notWater\n\tcp 6\n\tjr nc, .notWater',
        'cp 26\n\tjr c, .notWater\n\tcp 30\n\tjr nc, .notWater',
        'cp 12\n\tjr c, .notWater\n\tcp 16\n\tjr nc, .notWater',
        'cp JOHTO_ROUTE_35_LOCAL_ID\n\tjr z, .route32\n\tcp JOHTO_RUINS_OF_ALPH_LOCAL_ID\n\tjr z, .route32',

    )
    for token in native_dispatch:
        if token not in runtime:
            errors.append('Ruins Surf runtime missing/changed: ' + token[:70])
    # Ecruteak's exact pond is an asymmetric 20-cell Gold WATER shape;
    # negative tests must reject broad 8x8 water permission or one wrong row.
    try:
        city = {(cell['y'],cell['x']) for cell in decode_cells(
            (gold/'maps/EcruteakCity.blk').read_bytes(),
            (gold/'data/tilesets/johto_metatiles.bin').read_bytes(),
            (gold/'data/tilesets/johto_collision.asm').read_text(), 20, 18)
            if cell['role']=='WATER'}
        expected_city = {(y,x) for y in (12,13) for x in range(22,28)} | {(y,x) for y in (14,15) for x in range(24,28)}
        if city != expected_city or len(city)!=20:
            errors.append('EcruteakCity Gold WATER 20-cell pond geometry mismatch')
        cells=(root/'maps/JohtoEcruteakCity.blk').read_bytes()
        goldblocks=(gold/'maps/EcruteakCity.blk').read_bytes()
        if cells != goldblocks:
            errors.append('EcruteakCity must use Gold west road art; unfinished gate must not be drawn as a house')
    except (OSError, ValueError) as exc:
        errors.append('EcruteakCity Surf geometry missing: '+str(exc))
    for token in ('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n\tjp z, IsJohtoEcruteakWaterAhead',
                  'IsJohtoEcruteakWaterAhead::', 'cp 12\n\tjr c, .notWater',
                  'cp 16\n\tjr nc, .notWater', 'cp 14\n\tjr nc, .lower',
                  'cp 22\n\tjr c, .notWater', 'cp 28\n\tjr nc, .notWater',
                  'cp 24\n\tjr c, .notWater'):
        if token not in runtime: errors.append('EcruteakCity Surf runtime check missing: '+token[:58])
    # This is intentionally a temporary policy: no hidden Johto badge gate
    # may be reintroduced in either of the two shared cave Surf entry points.
    badge_handlers = runtime.split('JohtoSurfBadgeAllowed::', 1)[-1]
    if 'wObtainedJohtoBadges' in badge_handlers or 'FOG_BADGE' in badge_handlers:
        errors.append('staged Johto Surf must not require Fog Badge until story rules exist')
    if len(identities.get('maps', [])) < 9:
        errors.append('no native map capabilities for Surf')
    else:
        for entry in identities['maps']:
            expect = 'ALLOWED' if entry['local_id'] in (7, 8, 17, 20, 22, 26, 27, 28, 29, 63, 67, 68) else 'DEFERRED'
            if entry['feature_status'].get('surf') != expect:
                errors.append(f'Johto local {entry["local_id"]} Surf status must be {expect}')
    for source, name in ((field, 'WaterTilesets2'), (items, 'WaterTilesets')):
        match = re.search(rf'(?m)^{name}:\s*[^\n]*\n([\s\S]*?)(?:\n\S|\Z)', source)
        if match and ('JOHTO_UNION_CAVE' in match[1] or 'JOHTO' in match[1]):
            errors.append(f'global {name} cannot include Johto wall aliases')
    return errors


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--rpp', type=Path, required=True)
    p.add_argument('--gold', type=Path, required=True)
    args = p.parse_args()
    errors = audit(args.rpp, args.gold)
    print(json.dumps({'status': 'FAIL' if errors else 'PASS', 'errors': errors,
                      'runtime_static_checked': True, 'rom_built': False,
                      'phone_accepted': False}, ensure_ascii=False, indent=2))
    return int(bool(errors))

if __name__ == '__main__':
    raise SystemExit(main())
