#!/usr/bin/env python3
"""Historical DEV-312 snapshot audit for pre-activation Route43 gatehouses.

At REF-312 this tool audited Gold-derived planned profiles while ID66 was still
inactive. REF-317 activates ID66; this historical snapshot is retained for
provenance and is not a current-state gate. Current active gatehouse behavior
is audited by johto_gatehouse_behavior_audit and the DEV-320 Route43 checks.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

try:
    from johto_gold_door_audit import (
        GoldCollisionIndex, gold_gate_approach_rule, gold_gate_arrival_step,
    )
    from johto_gatehouse_behavior_audit import (
        _audit_gatehouse_legacy_source_walk, _constants,
    )
    from johto_gatehouse_step_trace_308 import (
        simulate_legacy_gate_dispatch, simulate_legacy_gate_passability,
    )
except ImportError:  # package-style imports in tests/tools runners
    from tools.johto_gold_door_audit import (
        GoldCollisionIndex, gold_gate_approach_rule, gold_gate_arrival_step,
    )
    from tools.johto_gatehouse_behavior_audit import (
        _audit_gatehouse_legacy_source_walk, _constants,
    )
    from tools.johto_gatehouse_step_trace_308 import (
        simulate_legacy_gate_dispatch, simulate_legacy_gate_passability,
    )

PROFILE_PATH = 'tools/johto_gatehouse_future_profiles_312.json'
EXPECTED_IDS = {65: 'Route43MahoganyGate', 66: 'Route43Gate'}


def _parse_warps(gold_root: Path, map_name: str, gold_index: GoldCollisionIndex) -> list[dict[str, Any]]:
    path = gold_root / 'maps' / f'{map_name}.asm'
    source = path.read_text(encoding='utf-8')
    if source.count('def_warp_events') != 1 or source.count('def_coord_events') != 1:
        raise ValueError(f'{map_name}: expected one Gold warp section')
    section = source.split('def_warp_events', 1)[1].split('def_coord_events', 1)[0]
    rows = []
    pattern = re.compile(
        r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z_0-9]*)\s*,\s*(\d+)\b'
    )
    for ordinal, match in enumerate(pattern.finditer(section), start=1):
        x, y, destination, destination_warp = match.groups()
        rows.append({
            'gold_warp_number': ordinal,
            'xy': [int(x), int(y)],
            'destination_constant': destination,
            'destination_gold_warp_number': int(destination_warp),
            'collision_role': gold_index.role_at(map_name, int(x), int(y)),
        })
    return rows


def _event_profile(source: str) -> dict[str, int]:
    try:
        scene = source.split('def_scene_scripts', 1)[1].split('def_callbacks', 1)[0]
        callbacks = source.split('def_callbacks', 1)[1].split('def_warp_events', 1)[0]
        objects = source.split('def_object_events', 1)[1]
    except IndexError as exc:
        raise ValueError('Gold map event sections are incomplete') from exc
    return {
        'scene_scripts': len(re.findall(r'(?m)^\s*scene_script\b', scene)),
        'callbacks': len(re.findall(r'(?m)^\s*callback\b', callbacks)),
        'object_events': len(re.findall(r'(?m)^\s*object_event\b', objects)),
    }


def _slot_tokens(source: str) -> list[str]:
    try:
        body = source.split('JohtoStableIDToActiveSlot::', 1)[1].split(
            'JohtoStableIDToActiveSlotEnd::', 1)[0]
    except IndexError as exc:
        raise ValueError('stable ID active-slot table missing') from exc
    tokens: list[str] = []
    for line in body.splitlines():
        line = line.partition(';')[0].strip()
        if line.startswith('db '):
            tokens.extend(item.strip() for item in line[3:].split(','))
    return tokens


def _source_warp_contract(row: dict[str, Any], target_warps: dict[str, list[dict[str, Any]]],
                          destination_maps: dict[str, str]) -> dict[str, Any]:
    source_role = row['collision_role']
    approach = gold_gate_approach_rule(source_role, 'COLLISION_ONLY')
    if approach is None:
        raise ValueError(f"unsupported source collision role {source_role}")
    trigger, direction = approach
    target_map = destination_maps.get(row['destination_constant'])
    if target_map is None:
        raise ValueError(f"unmapped Gold warp destination {row['destination_constant']}")
    target_number = row['destination_gold_warp_number']
    target_rows = target_warps.get(target_map, [])
    if not 1 <= target_number <= len(target_rows):
        raise ValueError(f'{target_map}: target Gold warp #{target_number} is missing')
    target_role = target_rows[target_number - 1]['collision_role']
    arrival = gold_gate_arrival_step(target_role)
    if arrival is None:
        raise ValueError(f'{target_map} warp #{target_number}: unsupported arrival role {target_role}')
    return {
        'source_gold_warp_number': row['gold_warp_number'],
        'source_xy': row['xy'],
        'source_role': source_role,
        'trigger': trigger,
        'direction': direction,
        'target_gold_map': target_map,
        'target_gold_warp_number': target_number,
        'target_role': target_role,
        'arrival_auto_step': arrival,
    }


def audit(project: Path, gold_root: Path, *, text_overrides: dict[str, str] | None = None) -> dict:
    project = Path(project).resolve()
    gold_root = Path(gold_root).resolve()
    text_overrides = text_overrides or {}
    checks: list[dict[str, str]] = []
    errors: list[str] = []
    traces: dict[int, int] = {}

    def check(name: str, ok: bool, detail: str = '') -> None:
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
        if not ok:
            errors.append(name + (': ' + detail if detail else ''))

    def txt(relative: str) -> str:
        return text_overrides[relative] if relative in text_overrides else (
            project / relative).read_text(encoding='utf-8')

    try:
        profiles = json.loads(txt(PROFILE_PATH))
        constants = _constants(project)
        fixed_ids = txt('constants/johto_fixed_map_ids.asm')
        region_constants = txt('constants/region_map_constants.asm')
        slots_source = txt('data/johto_stable_id_slots.asm')
        runtime_assets = txt('data/johto_pilot_runtime_assets.asm')
        source_resources = txt('data/johto_pilot_source_resources.asm')
        headers = txt('data/johto_header_descriptors.asm')
        map_headers = txt('data/johto_pilot_map_headers.asm')
        tileset_headers = txt('data/tileset_headers.asm')
        collision_source = txt('data/collision.asm')
        gateway_source = txt('engine/johto_land_collision_gateway_272.asm')
        home_source = txt('home/overworld.asm')
        player_state_source = txt('engine/overworld/player_state.asm')
        passable_tiles = (project / 'gfx/tilesets/gate.tilecoll').read_bytes()
        blockset = (project / 'gfx/blocksets/johto_gate.bst').read_bytes()
        gold_index = GoldCollisionIndex(gold_root)
        gold_maps_source = (gold_root / 'data/maps/maps.asm').read_text(encoding='utf-8')
        gold_attributes = (gold_root / 'constants/map_constants.asm').read_text(encoding='utf-8')
        gold_blocks_source = (gold_root / 'data/maps/blocks.asm').read_text(encoding='utf-8')
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        return {'status': 'FAIL', 'checks': checks, 'errors': [f'input load failed: {exc}'],
                'trace_moves': traces}

    check('schema', profiles.get('schema') == 'johto-future-gatehouse-onboarding-v1',
          str(profiles.get('schema')))
    phase1_active = profiles.get('status') == 'partial_65_active'
    check('activation_state', phase1_active
          and profiles.get('game_version') == 'REF-312'
          and [row.get('active') for row in profiles.get('future_gatehouses', [])] == [True, False],
          'ID65 south-only active and ID66 remains closed; game version REF-312')
    candidate_rows = profiles.get('future_gatehouses', [])
    candidate_ids = [row.get('stable_id') for row in candidate_rows]
    candidate_map = {row.get('stable_id'): row.get('gold_map') for row in candidate_rows}
    check('candidate_ids_unique', len(candidate_ids) == len(set(candidate_ids))
          and all(isinstance(value, int) and 0 <= value <= 255 for value in candidate_ids),
          'candidate stable IDs are unique bytes')
    check('route43_candidates_present', all(candidate_map.get(k) == v for k, v in EXPECTED_IDS.items()),
          'reserved Route43 gate candidates 65/66 remain represented; additional future gates may be appended')

    shared = profiles.get('shared_runtime', {})
    check('shared_backend_contract',
          shared.get('runtime_tileset') == 'JOHTO_GATE'
          and shared.get('collision_list') == 'Gate_Coll'
          and shared.get('dispatcher') == 'JohtoOverworldSouthLandDecision'
          and shared.get('legacy_result') == 2,
          'future vertical gates use the existing generic Gate_Coll fallback, not the Ecruteak/Park helpers')
    check('runtime_layout_reference',
          shared.get('reuse_layout_from_stable_id') == 19
          and shared.get('reuse_layout_block_dimensions') == [5, 4],
          'reuse the accepted ID19 vertical-gate runtime layout')
    check('activation_fail_closed',
          profiles.get('activation_policy', {}).get('require_explicit_warp_contract_before_activation') is True
          and profiles.get('activation_policy', {}).get('require_route43_runtime_map_before_activation') is True
          and profiles.get('activation_policy', {}).get('do_not_copy_gold_warp_ordinals_directly_to_runtime_ordinals') is True,
          'no activation or runtime ordinal is inferred from Gold alone')

    # Existing RPP backend is already common and generic. Prove the exact call
    # chain rather than adding a second vertical-gate implementation.
    check('johto_gate_tileset_uses_gate_coll', bool(re.search(
        r'(?m)^\s*tileset\s+JohtoGate_Block\s*,\s*JohtoGate_GFX\s*,\s*Gate_Coll\s*,',
        tileset_headers)))
    check('gate_coll_source_is_shared', bool(re.search(
        r'(?m)^\s*Gate_Coll::\s*INCBIN\s+"gfx/tilesets/gate\.tilecoll"', collision_source)))
    check('legacy_collision_chain', all(token in home_source for token in (
        'callab JohtoOverworldSouthLandDecision', 'call CheckForJumpingAndTilePairCollisions',
        'call CheckTilePassable')) and 'wTilesetCollisionPtr' in home_source,
        'CollisionCheckOnLand retains the shared E=2 tile-pair/CheckTilePassable path')

    slots = _slot_tokens(slots_source)
    check('stable_id_65_south_only_active', len(slots) > 65 and slots[65] == '38',
          slots[65] if len(slots) > 65 else 'slot missing')
    for stable_id in (66, 67, 69):
        check(f'stable_id_{stable_id}_reserved_inactive',
              len(slots) > stable_id and slots[stable_id] == 'JOHTO_INVALID_ACTIVE_SLOT',
              slots[stable_id] if len(slots) > stable_id else 'slot missing')
    check('active_map_count_phase1', bool(re.search(
        r'(?m)^DEF NUM_JOHTO_ACTIVE_MAPS EQU 39$', region_constants)))

    profile_rows = candidate_rows
    destination_maps = {constant: name for name, constant in gold_index.map_const.items()}
    target_map_names = set()
    for profile in profile_rows:
        for warp in _parse_warps(gold_root, profile.get('gold_map', ''), gold_index):
            target_name = destination_maps.get(warp['destination_constant'])
            if target_name:
                target_map_names.add(target_name)
    target_warps = {name: _parse_warps(gold_root, name, gold_index)
                    for name in sorted(target_map_names)}
    descriptor = ('JOHTO_GATE', 5, 4)
    reuse_layout_path = shared.get('reuse_runtime_layout', '')
    try:
        reuse_layout = (project / reuse_layout_path).read_bytes()
    except OSError as exc:
        reuse_layout = b''
        errors.append(f'runtime layout reference missing: {exc}')

    gold_north_south = (gold_root / 'maps/NorthSouthGate.blk').read_bytes()
    check('gold_north_south_layout_20_bytes', len(gold_north_south) == 20,
          f'{len(gold_north_south)} bytes; expected 5x4')
    id19_gold_layout = (project / 'maps/johto_pilot/Route36RuinsOfAlphGate.gold.blk').read_bytes()
    check('gold_north_south_source_matches_id19', id19_gold_layout == gold_north_south,
          'ID19 Gold source layout is the same NorthSouthGate.blk used by both future maps')
    check('reusable_runtime_layout_matches_reference', len(reuse_layout) == 20,
          'reuse the already-converted 5x4 ID19 runtime layout; Gold roles are verified by ASM trace below')
    check('gate_blockset_present', bool(blockset) and len(blockset) % 16 == 0,
          f'{len(blockset)} bytes')
    check('gate_coll_terminator', bool(passable_tiles) and passable_tiles[-1] == 0xff
          and 0xff not in passable_tiles[:-1], 'one terminal $FF')

    for row in profile_rows:
        stable_id = row.get('stable_id')
        gold_map = row.get('gold_map')
        prefix = f'future_{stable_id}_{gold_map}'
        if not isinstance(stable_id, int) or not isinstance(gold_map, str):
            check(prefix + '_identity', False, 'stable ID must be a byte and Gold map must be a name')
            continue
        check(prefix + '_profile_policy',
              row.get('active') is (stable_id == 65 and phase1_active) and row.get('layout') == 'vertical_ns'
              and row.get('collision_strategy') == 'legacy_gate_tilecoll'
              and row.get('gold_environment') == 'GATE'
              and row.get('bike_allowed') is True
              and row.get('runtime_tileset') == 'JOHTO_GATE'
              and row.get('gold_block_file') == 'NorthSouthGate.blk'
              and row.get('block_dimensions') == [5, 4],
              'vertical GATE; bike allowed; generic Gate_Coll; only ID65 active')

        gold_map_line = re.search(
            rf'(?m)^\s*map\s+{re.escape(gold_map)}\s*,\s*(\w+)\s*,\s*(\w+)\s*,',
            gold_maps_source)
        check(prefix + '_gold_tileset_environment',
              bool(gold_map_line) and gold_map_line.group(1) == 'TILESET_GATE'
              and gold_map_line.group(2) == 'GATE',
              gold_map_line.group(0).strip() if gold_map_line else 'Gold map line missing')
        dimension_key = gold_index.map_const.get(gold_map)
        dimensions = gold_index.dimensions.get(dimension_key) if dimension_key else None
        check(prefix + '_gold_dimensions', dimensions == (5, 4), str(dimensions))
        check(prefix + '_gold_block_source',
              gold_index.block_files.get(gold_map) == 'NorthSouthGate.blk',
              str(gold_index.block_files.get(gold_map)))

        cells = gold_index.cells(gold_map)
        roles = {coord: cell['role'] for coord, cell in cells.items()}
        source_rows = _parse_warps(gold_root, gold_map, gold_index)
        actual_warp_contracts = []
        for warp in source_rows:
            actual_warp_contracts.append(_source_warp_contract(warp, target_warps, destination_maps))
        actual_thresholds = [{
            'xy': warp['source_xy'], 'role': warp['source_role'],
            'trigger': warp['trigger'], 'direction': warp['direction'],
            'arrival_auto_step': warp['arrival_auto_step'],
        } for warp in actual_warp_contracts]
        check(prefix + '_threshold_geometry', actual_thresholds == row.get('thresholds', []),
              json.dumps(actual_thresholds, sort_keys=True))
        expected_warp_contracts = row.get('warp_events', [])
        check(prefix + '_warp_contracts', actual_warp_contracts == expected_warp_contracts,
              json.dumps(actual_warp_contracts, sort_keys=True))
        check(prefix + '_warp_count', len(source_rows) == 4, f'{len(source_rows)} Gold warps')

        gold_script = (gold_root / 'maps' / f'{gold_map}.asm').read_text(encoding='utf-8')
        actual_events = _event_profile(gold_script)
        expected_events = row.get('event_profile', {})
        check(prefix + '_event_profile', actual_events == {
            key: expected_events.get(key) for key in ('scene_scripts', 'callbacks', 'object_events')
        }, json.dumps(actual_events, sort_keys=True))
        if stable_id == 65 and gold_map == 'Route43MahoganyGate':
            check(prefix + '_officer_event_stays_map_local',
                  'Route43MahoganyGateOfficer' in gold_script
                  and 'EVENT_CLEARED_ROCKET_HIDEOUT' in gold_script
                  and 'def_scene_scripts\n\n\tdef_callbacks' in gold_script,
                  'Officer conditional text; no scene/callback state machine')
        elif stable_id == 66 and gold_map == 'Route43Gate':
            check(prefix + '_rocket_scene_stays_map_local',
                  'SCENE_ROUTE43GATE_ROCKET_SHAKEDOWN' in gold_script
                  and 'EVENT_CLEARED_ROCKET_HIDEOUT' in gold_script
                  and 'EVENT_ROUTE_43_GATE_ROCKETS' in gold_script
                  and 'ROUTE43GATE_TOLL EQU 1000' in gold_script,
                  'Rocket toll/scene/callback/event flags remain separate from collision')

        # Active ID65 must use its actual deployed runtime bytes. Only the
        # inactive ID66 may use ID19's established layout as a read-only fixture.
        def candidate_read_bytes(relative: str) -> bytes:
            if relative == f'maps/johto_pilot/{gold_map}.runtime.blk' and stable_id == 66:
                return reuse_layout
            return (project / relative).read_bytes()

        checked, trace_errors = _audit_gatehouse_legacy_source_walk(
            gold_index=gold_index, gold_map=gold_map, stable_id=stable_id,
            descriptor=descriptor, read_bytes=candidate_read_bytes,
            constants=constants, gateway_source=gateway_source,
            home_source=home_source, player_state_source=player_state_source,
            tileset_headers=tileset_headers, collision_source=collision_source,
        )
        traces[stable_id] = checked
        check(prefix + '_legacy_gate_coll_source_trace', not trace_errors,
              f'{checked} ASM-traced moves' + (': ' + '; '.join(trace_errors[:4]) if trace_errors else ''))
        check(prefix + '_dispatcher_generic_fallback',
              simulate_legacy_gate_dispatch(gateway_source, constants=constants,
                                            gate_id=stable_id) == 2,
              'stable ID remains on E=2 generic CheckTilePassable path')
        # Check the shared byte-list leaf independently of map-specific roles.
        leaf_ok = (
            not simulate_legacy_gate_passability(home_source, gate_id=stable_id,
                                                 tile_id=0x02, passable_tiles=passable_tiles)
            and simulate_legacy_gate_passability(home_source, gate_id=stable_id,
                                                 tile_id=0x00, passable_tiles=passable_tiles)
            and not simulate_legacy_gate_passability(home_source, gate_id=stable_id,
                                                     tile_id=0x3c, passable_tiles=passable_tiles)
        )
        check(prefix + '_shared_checktilepassable_leaf', leaf_ok,
              'walkable tile passes; wall tile blocks; non-Cherrygrove $3C uses Gate_Coll')

    # Explicit activation allowlist: 65 deployed once in source resources and
    # exactly at its known two references in runtime assets; 66 stays absent.
    for row in profile_rows:
        stable_id, gold_map = row.get('stable_id'), row.get('gold_map')
        symbol = row.get('stable_id_symbol')
        if not symbol:
            check(f'runtime_symbol_{stable_id}_declared', False, 'gate profile needs stable_id_symbol')
            continue
        if stable_id == 65 and phase1_active:
            check('runtime_assets_65_exact_activation', runtime_assets.count(symbol) == 2,
                  'exactly two deployed references; duplicates or missing refs fail')
            check('source_resources_65_exact_activation', source_resources.count(symbol) == 1,
                  'one deployed source resource')
            check('header_descriptors_65_exact_activation',
                  headers.count('JohtoRoute43MahoganyGateRuntimeHeader') == 2,
                  'one pointer and one BANK expression')
            gate = txt('data/johto_route43_mahogany_gate_313.asm')
            check('north_exit_65_closed',
                  'db 2 ; Gold lower (south) two doors only' in gate
                  and 'db 0, 4,' not in gate and 'db 0, 5,' not in gate,
                  'north-side Route43 warp remains blocked')
        else:
            for label, source in (
                ('runtime_assets', runtime_assets), ('source_resources', source_resources),
                ('header_descriptors', headers), ('map_headers', map_headers),
            ):
                check(f'{label}_{stable_id}_not_activated', symbol not in source,
                      f'{gold_map} remains planned-only')
    check('route43_runtime_gate_remains_closed', 'JOHTO_ROUTE_43_LOCAL_ID' not in runtime_assets
          and 'JOHTO_ROUTE_43_LOCAL_ID' not in source_resources,
          'Route43 outdoor and ID66 remain inactive')
    check('route44_remains_closed', 'JOHTO_ROUTE_44_LOCAL_ID' not in runtime_assets
          and 'JOHTO_ROUTE_44_LOCAL_ID' not in source_resources,
          'Route44 remains inactive')

    return {
        'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
        'checks': checks,
        'errors': errors,
        'trace_moves': traces,
        'candidate_ids': sorted(EXPECTED_IDS),
        'active_map_count': 39,
        'activation': 'ID65 south-only active; Route43 and ID66 fail-closed',
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--gold-root', type=Path, required=True)
    parser.add_argument('--json-out', type=Path)
    args = parser.parse_args(argv)
    report = audit(args.project, args.gold_root)
    payload = json.dumps(report, indent=2, ensure_ascii=False)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(payload + '\n', encoding='utf-8')
    print(payload)
    return 0 if report['status'] == 'PASS_STATIC_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
