#!/usr/bin/env python3
"""DEV-324: read-only Route44 geometry/seam safety gate (not ROM simulation)."""
from __future__ import annotations
import re
import hashlib
from pathlib import Path
from johto_surf_coverage_audit import read_active_maps

OPEN_Y = frozenset((8, 9, 11, 12, 13, 14, 15, 16, 17))


def audit(root: Path, changes: dict[str, bytes | str] | None = None, gold_root: Path | None = None) -> dict:
    root = Path(root)
    changes = changes or {}
    checks = []
    def read(rel: str) -> bytes:
        override = changes.get(rel)
        return (override.encode('utf8') if isinstance(override, str)
                else bytes(override) if override is not None else (root / rel).read_bytes())
    def txt(rel: str) -> str:
        return read(rel).decode('utf8')
    def ck(name: str, ok: bool):
        checks.append({'name': name, 'passed': bool(ok)})
    rows = read_active_maps(root)
    ck('route44_slot42_ID69', len(rows) >= 43 and rows[42]['slot'] == 42
       and rows[42]['stable_id'] == 69 and rows[42]['map'] == 'Route44')
    original = read('maps/johto_pilot/Route44.gold.blk')
    runtime = read('maps/johto_pilot/Route44.runtime.blk')
    ck('route44_exact_original_blocks', len(original) == 270 and original == runtime)
    if gold_root is not None:
        reference = Path(gold_root) / 'maps' / 'Route44.blk'
        ck('route44_gold_reference_byte_identical', reference.is_file() and original == reference.read_bytes())
    roles = read('maps/johto_pilot/Route44.roles.bin')
    mahogany = read('maps/johto_pilot/MahoganyTown.roles.bin')
    ck('route44_quadrants_water', len(roles) == 1080 and set(roles) <= {0,1,2} and roles.count(2) == 120)
    ck('route44_dry_reciprocal_seam', len(roles) == 1080 and len(mahogany) == 360 and
       {y for y in range(18) if roles[y*60] == 0 and mahogany[y*20+19] == 0}
       == OPEN_Y | {0})
    east = txt('data/johto_east_runtime_300.asm')
    edge = east.split('JohtoEastIsKnownClosedEdge::', 1)[1].split('JohtoEastUnsafeSurfEdge::', 1)[0] if 'JohtoEastIsKnownClosedEdge::' in east and 'JohtoEastUnsafeSurfEdge::' in east else ''
    match = re.search(r'(?ms)^\.route44SeamY\s*\n(.*?)(?=^\.route44East\s*$)', edge)
    seam = re.sub(r';[^\n]*', '', match.group(1)).strip() if match else ''
    ck('route44_seam_guard_excludes_y0_and_y10', bool(re.fullmatch(
       r'cp 8\s+jp c, \.closed\s+cp 10\s+jp c, \.open\s+cp 11\s+jp z, \.closed\s+jp \.open', seam)))
    ck('mahogany_east_uses_same_seam_guard', bool(re.search(
       r'(?s)\.mahoganyEast\s+ld a, \[wXCoord\]\s+cp 19\s+ret c\s+ld a, \[wYCoord\]\s+jp \.route44SeamY',edge)))
    ck('route44_west_uses_same_seam_guard', bool(re.search(
       r'(?s)\.route44West\s+ld a, \[wXCoord\]\s+and a\s+ret nz\s+ld a, \[wYCoord\]\s+\.route44SeamY',edge)))
    # DEV-328 activated the Blackthorn/Route44 east seam.  Check the exit
    # decision as well as the coordinate threshold: matching only `ret c`
    # would miss an accidental jump to .closed for every east-border step.
    route44_exits = re.search(
       r'(?ms)^\.route44\n(?P<south>.*?)^\.route44West\n.*?^\.route44SeamY\n'
       r'.*?^\.route44East\n(?P<east>.*?)^\.route44North\n(?P<north>.*?)^\.blackthorn\n',
       edge)
    south = route44_exits.group('south') if route44_exits else ''
    east_exit = route44_exits.group('east') if route44_exits else ''
    north = route44_exits.group('north') if route44_exits else ''
    ck('route44_north_south_closed_east_now_connected',
       'cp JOHTO_ROUTE_44_HEIGHT * 2 - 1\n    jp nc, .closed' in south
       and bool(re.search(r'cp JOHTO_ROUTE_44_WIDTH \* 2 - 1\s+ret c\s+(?:;[^\n]*\s+)*jp \.open\s*$', east_exit))
       and 'ld a, [wYCoord]\n    and a\n    jp z, .closed' in north)
    ck('route44_gold_role_dispatch', 'cp JOHTO_ROUTE_44_LOCAL_ID\n    jr z, .route44' in east and
       'cp JOHTO_ROUTE_44_LOCAL_ID\n    jr c, .afterEastSouth' in txt('engine/johto_land_collision_gateway_272.asm'))
    header = txt('data/johto_route44_runtime_324.asm')
    mahogany_header = east.split('JohtoMahoganyRuntimeHeader::',1)[1].split('JohtoMahoganyHeaderEnd::',1)[0] if 'JohtoMahoganyRuntimeHeader::' in east else ''
    # A correct Route44 .blk cannot guarantee Gold's east-hand viewport:
    # Blackthorn is not active, but its left three columns must be previewed.
    # The preview is strictly visual; never approve an east map transition.
    preview = read('maps/johto_pilot/BlackthornCity.east_preview.blk')
    ck('route44_gold_east_preview_data', len(preview) == 360 and
       hashlib.sha256(preview).hexdigest() == 'f6460760a67901f6dce2b4df3f3c75c68e429a5c71bd907c725a955578e4676c')
    if gold_root is not None:
        exact = Path(gold_root) / 'maps' / 'BlackthornCity.blk'
        ck('route44_east_preview_matches_gold_source', exact.is_file() and
           preview == exact.read_bytes())
    ck('route44_east_visual_only_header', all(x in header for x in (
       'db WEST | EAST ; DEV-326 Gold physical seam; IcePath cave still sealed',
       'JohtoRoute44EastBlackthornPreview::\nJohtoBlackthornBlocks:: INCBIN "maps/johto_pilot/BlackthornCity.east_preview.blk"',
       'dw JohtoRoute44EastBlackthornPreview + 9 * 20',
       'dw wOverworldMap + 3 * (JOHTO_ROUTE_44_WIDTH + 6) + JOHTO_ROUTE_44_WIDTH + 3',
       'db JOHTO_ROUTE_44_HEIGHT\n    db 20 ; Gold BlackthornCity width\n    db 18 ; connection Y alignment for -9 block offset',
       'dw wOverworldMap + 7 + 20',
       'ASSERT JohtoRoute44HeaderEnd - JohtoRoute44RuntimeHeader == 34',
       'ASSERT BANK(JohtoRoute44RuntimeHeader) == BANK(JohtoRoute44EastBlackthornPreview)',
    )))
    source_routes = txt('data/johto_pilot_source_resources.asm')
    ck('route44_east_gold_physical_seam',
       'cp JOHTO_ROUTE_44_WIDTH * 2 - 1\n    ret c' in edge
       and 'JOHTO_ROUTE_44_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID' in source_routes
       and 'JOHTO_BLACKTHORN_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID' in source_routes)

    ck('route44_header_closed_entrances_and_eventless', '    db WEST | EAST ; DEV-326 Gold physical seam; IcePath cave still sealed' in header and
       'dw JohtoMahoganyBlocks + JOHTO_MAHOGANY_TOWN_WIDTH - 3' in header and
       bool(re.search(r'JohtoRoute44RuntimeObjects::\s*db \$71[^\n]*\s+db 0[^\n]*\s+db 0[^\n]*\s+db 0',header)) and
       '    db WEST | EAST' in mahogany_header and 'dw JohtoRoute44Blocks' in mahogany_header)
    connections = txt('data/johto_pilot_source_resources.asm')
    ck('route44_source_both_directions', all(connections.count(x)==1 for x in (
       'db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID',
       'db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID',
       'db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID',
       'db MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID')))
    hops = txt('engine/overworld/ledges.asm').split('JohtoRoute44GoldHops:',1)[1].split('db $ff',1)[0]
    ck('route44_21_safe_directional_hops',len(re.findall(r'(?m)^\s*db \d+, \d+, PLAYER_DIR_(?:DOWN|LEFT|RIGHT)\s*$',hops))==21)
    return {'status':'PASS_STATIC_ONLY' if all(x['passed'] for x in checks) else 'FAIL',
            'checks':checks,'errors':[x['name'] for x in checks if not x['passed']]}
