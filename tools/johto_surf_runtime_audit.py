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
        (runtime, 'cp JOHTO_UNION_CAVE\n\tjr z, .johtoAllowed\n\tcp JOHTO\n\tjr nz, .kanto\n\tld a, [wCurMap]\n\tcp JOHTO_ROUTE_32\n\tjr z, .route32\n\tcp REGION_NATIVE_MAP_SLOT\n\tjr nz, .kanto\n\tld a, [wCurLocalMapID]\n\tcp JOHTO_ROUTE_35_LOCAL_ID\n\tjr nz, .kanto\n.route32\n\tld a, [wCurRegion]\n\tcp MAP_REGION_JOHTO\n\tjr nz, .kanto\n.johtoAllowed\n\tscf\n\tret\n.kanto', 'staged Route35/Route32/cave badge-free Surf permission'),
        (runtime, 'ld a, [wObtainedKantoBadges]\n\tbit 4, a ; SOUL_BADGE\n\tjr z, .denied', 'Kanto Soul Badge preserved'),
        (field, 'callba JohtoSurfBadgeAllowed\n\tjr nc, .cannotSurf', 'water interaction shared permission check'),
        (menu, 'callba JohtoSurfBadgeAllowed\n\tjp nc, .newBadgeRequired', 'party menu shared permission check'),
        (runtime, 'JohtoSurfStartOnWater::\n\tcall IsJohtoSurfWaterAhead\n\tccf', 'Surfboard water-only and carry polarity'),
    )
    for source, token, name in must_have:
        if token not in source:
            errors.append(f'cave Surf runtime contract missing/broken: {name}')
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
        'cp REGION_NATIVE_MAP_SLOT\n\tjp z, IsJohtoRoute35WaterAhead',
    )
    for token in route35_must:
        if token not in runtime:
            errors.append('Route35 Surf runtime missing/changed: '+token[:50])
    # This is intentionally a temporary policy: no hidden Johto badge gate
    # may be reintroduced in either of the two shared cave Surf entry points.
    badge_handlers = runtime.split('JohtoSurfBadgeAllowed::', 1)[-1]
    if 'wObtainedJohtoBadges' in badge_handlers or 'FOG_BADGE' in badge_handlers:
        errors.append('staged Johto Surf must not require Fog Badge until story rules exist')
    if len(identities.get('maps', [])) < 9:
        errors.append('no native map capabilities for Surf')
    else:
        for entry in identities['maps']:
            expect = 'ALLOWED' if entry['local_id'] in (7, 8, 17) else 'DEFERRED'
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
