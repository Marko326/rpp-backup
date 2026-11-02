#!/usr/bin/env python3
"""Read-only Gold visual-seam guard built from the .269-.290 and .313-.317 failures.

Do not equate correct .blk bytes with correct out-of-map rendering or passable
edges.  This gate checks live post-load hooks, actual header strip widths,
source Gold bytes, exact old facade patches, and the newer Route43 fix.

This is a source-only developer check: it neither builds a ROM nor proves a
handheld frame.  Overrides are only used for non-destructive fault injection.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from johto_route43_visual_preview_audit_317 import audit as audit_route43


def audit(root: Path, gold_root: Path, overrides: dict[str, str | bytes] | None = None) -> dict:
    root, gold_root = Path(root), Path(gold_root)
    overrides = overrides or {}
    checks: list[dict] = []
    errors: list[str] = []

    def blob(path: str) -> bytes:
        item = overrides.get(path)
        if item is not None:
            return item.encode('utf-8') if isinstance(item, str) else item
        return (root / path).read_bytes()

    def txt(path: str) -> str:
        return blob(path).decode('utf-8')

    def check(name: str, condition: bool, group: str):
        ok = bool(condition)
        checks.append({'name': name, 'passed': ok, 'group': group})
        if not ok:
            errors.append(name)

    def region(src: str, begin: str, end: str) -> str:
        if begin not in src or end not in src.split(begin, 1)[1]:
            return ''
        return src.split(begin, 1)[1].split(end, 1)[0]

    def rows(src: str) -> list[bytes]:
        parsed = []
        for i in range(3):
            match = re.search(r'(?m)^\.row' + str(i) + r'\s*\n\s*db\s+([^;\n]+)', src)
            if not match:
                parsed.append(b'')
                continue
            try:
                parsed.append(bytes(int(t.strip().removeprefix('$'), 16) for t in match.group(1).split(',')))
            except ValueError:
                parsed.append(b'')
        return parsed

    try:
        south = txt('data/johto_south_runtime.asm')
        mature = txt('engine/johto_ilex_mature_runtime_275.asm')
        north = txt('data/johto_north_runtime_283.asm')
        geom = txt('engine/johto_south_geometry.asm')
        home = txt('home/overworld.asm')
        wrapper = txt('data/johto_east_runtime_300.asm')
        south_portals = txt('engine/johto_south_portals.asm')
        route43 = txt('data/johto_route43_runtime_315.asm')

        # All comparisons use independent Gold files, never the RPP copy as
        # its own expected value (a failure in both copies must still fail).
        for name in ('AzaleaTown', 'Route34', 'GoldenrodCity', 'Route35',
                     'Route36', 'Route43', 'MahoganyTown'):
            original = (gold_root / 'maps' / (name + '.blk')).read_bytes()
            live = blob(f'maps/johto_pilot/{name}.runtime.blk')
            check(f'gold_{name}_runtime_bytes', len(live) == len(original) and live == original, 'Gold source')

        # Ilex Forest's east-hand settlement: Azalea Town (桧皮镇), not a
        # separate gate interior tile fix. Both missing halves lie in WRAM's
        # west-side 3-block preview margin AFTER LoadTileBlockMap completes.
        town = region(south, 'JohtoSouthAzaleaTownRuntimeObjects::', 'JohtoSouthIlexForestAzaleaGateBlocks::')
        check('azalea_outdoor_border_05', bool(re.search(r'^\s*db \$05\b', town)), 'Azalea west')
        west = region(mature, 'PatchJohtoAzaleaWestGateBorder::', 'PatchJohtoSouthBordersAfterBlockLoad::')
        check('azalea_two_west_facade_halves', all(s in west for s in (
            'cp JOHTO_AZALEA_TOWN_LOCAL_ID',
            'wOverworldMap + (MAP_BORDER + 4) * (JOHTO_SOUTH_AZALEATOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1',
            'ld [hl], $08',
            'wOverworldMap + (MAP_BORDER + 5) * (JOHTO_SOUTH_AZALEATOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1',
            'ld [hl], $1c')), 'Azalea west')

        # A correct painter function is ineffective if it is never invoked
        # on BOTH complete map loads and connection redraws.
        render = region(home, 'LoadTileBlockMap::', 'LoadNorthSouthConnectionsTileMap::')
        dispatcher = region(mature, 'PatchJohtoSouthBordersAfterBlockLoad::', 'PatchJohtoGoldenrodNorthBorder::')
        check('preview_post_load_full_dispatch', all(x in render for x in (
            '.done', 'callab PatchJohtoBordersAfterBlockLoad300')) and
            'callab PatchJohtoSouthBordersAfterBlockLoad' in wrapper and
            bool(re.search(r'call PatchJohtoAzaleaWestGateBorder\s+call PatchJohtoGoldenrodNorthBorder\s+jp PatchJohtoRoute35SouthBorder', dispatcher)), 'Live dispatch')

        # Goldenrod: a Gold-perfect source .blk does not restore three
        # Route35 rows above the city or fix the source border metatile.
        city_objects = region(south, 'JohtoSouthGoldenrodCityRuntimeObjects::', 'JohtoSouthScript::')
        route34_objects = region(south, 'JohtoSouthRoute34RuntimeObjects::', 'JohtoSouthGoldenrodCityBlocks::')
        check('goldenrod_outdoor_border_35', bool(re.search(r'^\s*db \$35\b', city_objects)), 'Goldenrod')
        check('route34_outdoor_border_05', bool(re.search(r'^\s*db \$05\b', route34_objects)), 'Route34')
        north_patch = region(mature, 'PatchJohtoGoldenrodNorthBorder::', 'PatchJohtoRoute35SouthBorder::')
        gold_35 = (gold_root / 'maps/Route35.blk').read_bytes()
        check('goldenrod_north_three_gold_rows', rows(north_patch) ==
              [gold_35[-30:-20], gold_35[-20:-10], gold_35[-10:]], 'Goldenrod')
        check('goldenrod_north_copy_coords_and_guard', all(s in north_patch for s in (
            'cp JOHTO_GOLDENROD_CITY_LOCAL_ID',
            'ld hl, wOverworldMap + MAP_BORDER + 5',
            'ld hl, wOverworldMap + (JOHTO_SOUTH_GOLDENRODCITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5',
            'ld hl, wOverworldMap + 2 * (JOHTO_SOUTH_GOLDENRODCITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5',
            'ld b, 10', 'ld [hli], a')), 'Goldenrod')

        road_header = region(south, 'JohtoSouthRoute34RuntimeHeader::', 'JohtoSouthRoute34HeaderEnd::')
        city_header = region(south, 'JohtoSouthGoldenrodCityRuntimeHeader::', 'JohtoSouthGoldenrodCityHeaderEnd::')
        check('route34_north_to_city_display_offset', all(s in road_header for s in (
            'db NORTH', 'dw JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 5',
            'dw wOverworldMap + 3', 'db 10\n    db 20\n    db 35\n    db 10')), 'Route34')
        check('goldenrod_south_to_route34_display_offset', all(s in city_header for s in (
            'db SOUTH', 'dw JohtoSouthRoute34Blocks',
            'dw wOverworldMap + (18 + 3) * (20 + 6) + 3 + 5',
            'db 10\n    db 10\n    db 0\n    db -10')), 'Goldenrod')
        e34 = region(geom, '\n.route34\n', '\n.goldenrod\n')
        ecity = region(geom, '\n.goldenrod\n', '\n.route35\n')
        check('route34_four_walkable_columns_not_two', bool(re.search(
            r'cp PLAYER_DIR_UP.*?cp 8\s+jp c, \.closed\s+cp 12[^\n]*\s+ret c\s+(?:jp|jr) \.closed',
            e34, flags=re.S)), 'Route34 physical edge')
        check('goldenrod_four_walkable_columns_not_two', bool(re.search(
            r'cp PLAYER_DIR_DOWN.*?cp 35\s+ret nz.*?cp 18\s+jp c, \.closed\s+cp 22[^\n]*\s+ret c\s+(?:jp|jr) \.closed',
            ecity, flags=re.S)), 'Goldenrod physical edge')

        # Route35 southern visual patch has DIFFERENT tileset from Goldenrod.
        # Never equate its raw tile IDs with Goldenrod's .blk values.
        south_35 = mature.split('PatchJohtoRoute35SouthBorder::', 1)[-1]
        known_safe = [bytes.fromhex(line) for line in (
            '12 15 01 46 16 1e 44 01 01 12',
            '01 12 15 46 01 01 44 01 01 04',
            '15 12 18 19 01 01 18 1f 19 02')]
        check('route35_south_tileset_safe_three_rows', rows(south_35) == known_safe and
              'cp JOHTO_ROUTE_35_LOCAL_ID' in south_35 and
              'ld b, JOHTO_ROUTE35_WIDTH' in south_35, 'Route35 south')
        header35 = region(north, 'JohtoNorthRoute35RuntimeHeader::', 'JohtoNorthRoute35HeaderEnd::')
        check('route35_north_thirteen_visible_columns', all(s in header35 for s in (
            'db NORTH',
            'dw JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)',
            'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10',
            'db JOHTO_ROUTE_36_WIDTH')), 'Route35 north')
        check('route35_north_bank_safe_source_mirror',
              'JohtoRoute35NorthRoute36Mirror::' in north and
              'INCBIN "maps/johto_pilot/Route36.runtime.blk"' in north and
              'ASSERT BANK(JohtoRoute35NorthRoute36Mirror) == BANK(JohtoNorthRoute35RuntimeHeader)' in north,
              'Route35 north')
        check('route35_south_two_gate_carpet_warps', all(s in north for s in (
            'db 33, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 33, 10, 1, JOHTO_REGISTERED_WARP_SELECTOR')) and
            all(s in south_portals for s in (
                '.route35South', 'cp PLAYER_DIR_DOWN', 'cp 33')), 'Route35 south')

        # Re-use the dev-317 Route43 audit (source, Gold strip, collision,
        # display-only versus actually open connection, inward Warp return).
        result43 = audit_route43(root, gold_root, overrides)
        # Keep this historical *visual* regression guard valid as the map
        # roster grows. In particular, do NOT freeze NUM_ACTIVE_MAPS==40,
        # the currently sealed ID66/Lake milestone, or a permanent 40th
        # Town Map slot. Those belong to their respective stage auditors.
        # This named allowlist is intentional: it protects the already
        # fixed Route43 display/return mechanism without blocking new maps.
        route43_stable = {
            'exact_Gold_10x27', 'Gold_south_carpet_pair_walkable',
            'registered_bidirectional_warp_routes',
            'south_ID65_carpet_keeps_collision_return',
            'north_ID66_carpet_reentry_and_lane_change',
            'Gold_NORTH_SOUTH_preview_flags',
            'Gold_LakeOfRage_preview_source_exact_360B',
            'Gold_MahoganyTown_south_preview_source_exact_90B',
            'Gold_north_preview_strip_alignment',
            'Gold_south_preview_strip_alignment',
            'header_34_bytes_and_ROMX_same_bank',
            'only_Lake_physical_Route43_seam_registered',
            'north_Lake_lanes_open_south_and_side_edges_fail_closed',
            'closed_edge_guard_runs_before_collision_transition',
        }
        listed = {item['name']: item['passed'] for item in result43['checks'] if 'passed' in item}
        for name in sorted(route43_stable):
            check('route43_' + name, listed.get(name, False), 'Route43')
        check('route43_header_is_seam_preview_not_blank_border',
              'db NORTH | SOUTH' in region(route43, 'JohtoRoute43RuntimeHeader::', 'JohtoRoute43HeaderEnd::'),
              'Route43')
    except (OSError, UnicodeDecodeError, IndexError, ValueError, KeyError) as exc:
        check('audit_input_or_parse_failure', False, f'{type(exc).__name__}: {exc}')

    return {
        'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
        'checks_total': len(checks),
        'checks_passed': len(checks) - len(errors),
        'checks': checks,
        'errors': errors,
        'rom_built': False,
        'phone_verified': False,
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path('.'))
    parser.add_argument('--gold-root', type=Path, required=True)
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    result = audit(args.project, args.gold_root)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"Historic visual seams: {result['checks_passed']}/{result['checks_total']} passed; {result['status']}")
        for error in result['errors']:
            print('FAIL:', error)
    raise SystemExit(0 if not result['errors'] else 1)
