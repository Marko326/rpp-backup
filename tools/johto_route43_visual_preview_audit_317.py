#!/usr/bin/env python3
"""DEV-317 Route43 Gold north/south visual seam preview audit; no ROM build."""
from __future__ import annotations
from pathlib import Path
from johto_route43_return_audit_316 import audit as audit316


def audit(root: Path, gold_root: Path, overrides: dict[str, bytes | str] | None = None) -> dict:
    root, gold_root = Path(root), Path(gold_root)
    overrides = overrides or {}
    result = audit316(root, gold_root, overrides)
    checks = result['checks']
    errors = result['errors']

    def test(name: str, condition: bool):
        checks.append(dict(name=name, passed=bool(condition)))
        if not condition:
            errors.append(name)

    def blob(relative: str) -> bytes:
        value = overrides.get(relative)
        if isinstance(value, str):
            return value.encode()
        return value if value is not None else (root / relative).read_bytes()

    def txt(relative: str) -> str:
        return blob(relative).decode('utf8')

    header_file = txt('data/johto_route43_runtime_315.asm')
    header = header_file.split('JohtoRoute43RuntimeHeader::', 1)[1].split('JohtoRoute43HeaderEnd::', 1)[0]
    source_connections = txt('data/johto_pilot_source_resources.asm').split('JohtoPilotSourceConnections::', 1)[1].split('JohtoPilotSourceConnectionsEnd::', 1)[0]
    east = txt('data/johto_east_runtime_300.asm')
    lake = blob('maps/johto_pilot/LakeOfRage.preview.blk')
    gold_lake = (gold_root / 'maps/LakeOfRage.blk').read_bytes()
    mahogany = blob('maps/johto_pilot/MahoganyTown.runtime.blk')
    gold_mahogany = (gold_root / 'maps/MahoganyTown.blk').read_bytes()

    test('Gold_NORTH_SOUTH_preview_flags', 'db NORTH | SOUTH' in header)
    test('Gold_LakeOfRage_preview_source_exact_360B', len(lake) == 360 and lake == gold_lake and
         'JohtoRoute43LakeOfRagePreviewBlocks:: INCBIN "maps/johto_pilot/LakeOfRage.preview.blk"' in header_file)
    test('Gold_MahoganyTown_south_preview_source_exact_90B', len(mahogany) == 90 and mahogany == gold_mahogany and
         'dw JohtoMahoganyBlocks' in header)
    test('Gold_north_preview_strip_alignment', all(x in header for x in (
         'dw JohtoRoute43LakeOfRagePreviewBlocks + 2 + JOHTO_LAKE_OF_RAGE_WIDTH * (JOHTO_LAKE_OF_RAGE_HEIGHT - 3)',
         'dw wOverworldMap', 'db JOHTO_ROUTE_43_WIDTH + 3', 'db JOHTO_LAKE_OF_RAGE_WIDTH',
         'db JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1', 'db 10',
         'dw wOverworldMap + 1 + JOHTO_LAKE_OF_RAGE_HEIGHT * (JOHTO_LAKE_OF_RAGE_WIDTH + 6)')))
    test('Gold_south_preview_strip_alignment', all(x in header for x in (
         'dw JohtoMahoganyBlocks',
         'dw wOverworldMap + (JOHTO_ROUTE_43_HEIGHT + 3) * (JOHTO_ROUTE_43_WIDTH + 6) + 3',
         'db JOHTO_ROUTE_43_WIDTH', 'db JOHTO_MAHOGANY_TOWN_WIDTH',
         'dw wOverworldMap + 7 + JOHTO_MAHOGANY_TOWN_WIDTH')))
    test('header_34_bytes_and_ROMX_same_bank',
         'ASSERT JohtoRoute43HeaderEnd - JohtoRoute43RuntimeHeader == 34' in header_file and
         'ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoRoute43LakeOfRagePreviewBlocks)' in header_file and
         'ASSERT BANK(JohtoRoute43RuntimeHeader) == BANK(JohtoMahoganyBlocks)' in header_file)
    north_connection = ('db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, NORTH, '
                        'MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID')
    south_connection = ('db MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID, SOUTH, '
                        'MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID')
    forbidden_south = ('db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, SOUTH, '
                       'MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID')
    test('only_Lake_physical_Route43_seam_registered',
         source_connections.count(north_connection) == 1 and
         source_connections.count(south_connection) == 1 and
         forbidden_south not in source_connections)
    edge = east.split('JohtoEastIsKnownClosedEdge::', 1)[1].split('\n.gate\n', 1)[0]
    north_start = edge.find('\n.route43North\n')
    south_start = edge.find('\n.route43South\n')
    north_body = edge[north_start:south_start] if north_start >= 0 and south_start > north_start else ''
    south_body = edge[south_start:] if south_start >= 0 else ''
    west_start = edge.find('\n.route43West\n')
    west_body = edge[west_start:] if west_start >= 0 else ''
    pilot = txt('engine/johto_pilot_runtime.asm')
    dispatch = pilot.split('JohtoPilotIsClosedOutdoorEdge::', 1)[1].split('\n.route37ClosedEdge\n', 1)[0]
    overworld = txt('home/overworld.asm')
    land_collision = overworld.split('CollisionCheckOnLand::', 1)[1].split('\nCheckTilePassable::', 1)[0]
    test('north_Lake_lanes_open_south_and_side_edges_fail_closed',
         bool(north_body and south_body and west_body) and
         'and a\n    jp z, .open' in north_body and
         'cp 8\n    jp c, .closed' in north_body and
         'cp 12\n    jp c, .open' in north_body and
         'jp nc, .closed' in south_body and 'jp z, .closed' in west_body and
         'cp JOHTO_ROUTE_43_WIDTH * 2 - 1\n    jp nc, .closed' in edge and
         '.lakeSouth' in edge and 'cp 10\n    jp z, .open' in edge and
         'cp 18\n    jp c, .closed' in edge and 'cp 22\n    jp c, .open' in edge)
    test('closed_edge_guard_runs_before_collision_transition',
         'cp JOHTO_ROUTE_43_LOCAL_ID\n    jp z, .eastClosedEdge' in dispatch and
         'callab JohtoPilotIsClosedOutdoorEdge' in land_collision and
         land_collision.index('callab JohtoPilotIsClosedOutdoorEdge') < land_collision.index('jp nz,.collision'))
    result['status'] = 'PASS_STATIC_ONLY' if not errors else 'FAIL'
    result['checks_total'] = len(checks)
    result['checks_passed'] = len(checks) - len(errors)
    result['errors'] = errors
    result['rom_built'] = False
    result['phone_verified'] = False
    return result
