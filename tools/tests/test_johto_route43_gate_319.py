"""DEV-320 offline ID66 Gold-gate movement regression; developer-facing only.

Fault injections change in-memory copies, never source files or a ROM build.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path
import pytest

SRC = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(SRC / 'tools'))
from johto_route43_gate_319_audit import audit

GOLD = Path(os.getenv('JOHTO_GOLD_ROOT', '/mnt/data/seam_guard_work/ref/JOHTO_HANDOFF_REF312_REFERENCE_COMPLETE/REFERENCES/Gold/pokegold-master'))


def source(name: str):
    return (SRC / name).read_text()


def fault(name, old, new):
    data = source(name)
    assert old in data, f'fault target disappeared: {name} {old!r}'
    return {name: data.replace(old, new, 1)}


@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
def test_clean_gate_contract():
    result = audit(SRC, GOLD)
    assert result['checks_total'] >= 40
    assert not result['errors'], result['errors']


# Each case must violate an independently tested contract, not simply a
# version literal.  Assert the expected detector, so a broken test cannot
# accidentally pass due to an unrelated pre-existing failure.
CASES = [
    ('missing_gate_header', 'data/johto_pilot_runtime_assets.asm',
     'JohtoRoute43GateRuntimeDescriptor::', 'JohtoRoute43GateBrokenDescriptor::', 'resource_descriptor_appended'),
    ('missing_gate_source_block', 'data/johto_pilot_source_resources.asm',
     'JohtoRoute43GateGoldBlocks:: INCBIN "maps/johto_pilot/Route43Gate.gold.blk"',
     'JohtoRoute43GateBrokenBlocks:: INCBIN "maps/johto_pilot/Route43Gate.gold.blk"', 'source_descriptor_appended'),
    ('wrong_map_size', 'constants/region_map_constants.asm',
     'DEF JOHTO_ROUTE43_GATE_HEIGHT EQU 4', 'DEF JOHTO_ROUTE43_GATE_HEIGHT EQU 5', 'ID66_width_height_5x4'),
    ('warp_to_incorrect_house_exit', 'data/johto_route43_gate_319.asm',
     'db 0, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR',
     'db 0, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR', 'Gold_ID66_4_original_warps'),
    ('Route43_gate_solid_DOOR_wrong_x', 'data/johto_route43_runtime_315.asm',
     'db 35, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR',
     'db 35, 16, 2, JOHTO_REGISTERED_WARP_SELECTOR', 'Gold_Route43_5_original_warps'),
    ('missing_north_reentry', 'data/johto_vertical_gate_runtime_314.asm',
     '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30\n', '',
     'Gold_before_step_profiles_include_ID66_reentry_and_lane_changes'),
    ('missing_north_lane_switch', 'data/johto_vertical_gate_runtime_314.asm',
     '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 17, 31\n', '',
     'Gold_before_step_profiles_include_ID66_reentry_and_lane_changes'),
    ('south_carpet_pre_step_bypassed', 'data/johto_vertical_gate_runtime_314.asm',
     '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 36 ; Gold #3 DOOR only\n',
     '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 9, 51\n    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 36 ; Gold #3 DOOR only\n',
     'south_ID65_carpet_keeps_collision_return'),
    ('lateral_lane_change_becomes_collision_warp', 'data/johto_vertical_gate_runtime_314.asm',
     'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3 ; ID66 lateral lane change only',
     'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 1 ; ID66 lateral lane change only',
     'north_ID66_lane_change_not_collision_exit'),
    ('outdoor_solid_DOOR_becomes_carpet', 'data/johto_vertical_gate_runtime_314.asm',
     'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 35, 2 ; solid DOOR',
     'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 35, 1 ; solid DOOR', 'door_vs_carpet_1_or_2'),
    ('carpet_wrong_collision_exit', 'data/johto_vertical_gate_runtime_314.asm',
     'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 31, 1 ; ID66 DOWN collision exit',
     'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 31, 2 ; collision-only carpet', 'door_vs_carpet_1_or_2'),
    ('incorrect_arrival_auto_step', 'data/johto_vertical_gate_runtime_314.asm',
     'db JOHTO_ROUTE_43_LOCAL_ID, 17, 35, D_DOWN ; arrival from ID66 south carpet onto DOOR',
     'db JOHTO_ROUTE_43_LOCAL_ID, 17, 31, D_DOWN ; arrival from ID66 south carpet onto DOOR',
     'arrival_auto_down_on_three_solid_doors'),
    ('Route43_south_seam_disappears', 'data/johto_route43_runtime_315.asm',
     'db NORTH | SOUTH', 'db NORTH ; break south seam', 'old_visual_seams_preserved_and_Lake_not_a_warp'),
    ('gate_no_longer_shared', 'engine/johto_pilot_runtime.asm',
     'cp JOHTO_ROUTE_43_GATE_LOCAL_ID\n    ret z',
     'cp JOHTO_ROUTE_43_GATE_LOCAL_ID\n    ret nz', 'shared_engine_dispatch_ID66'),
    ('fake_Rocket_text_added', 'data/johto_route43_gate_319.asm',
     'db 0 ; Rocket and Officer events require separate story-state port',
     'db 2 ; Rocket and Officer events require separate story-state port', 'Rocket_toll_and_TM36_not_faked'),
]


@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
@pytest.mark.parametrize('name,path,old,new,detector', CASES, ids=[c[0] for c in CASES])
def test_fault_injections_are_detected(name, path, old, new, detector):
    result = audit(SRC, GOLD, overrides=fault(path,old,new))
    assert detector in result['errors'], f'{name}: expected {detector}, got {result["errors"]}'



@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
def test_north_carpet_reentry_and_lane_change_contract_is_present():
    result = audit(SRC, GOLD)
    names = {check['name'] for check in result['checks']}
    assert 'ID66_user_reported_movement_sequence' in names
    assert 'north_ID66_lane_change_not_collision_exit' in names
    assert not result['errors'], result['errors']


@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
def test_real_gold_gate_art_mutation_is_detected():
    path = 'maps/johto_pilot/Route43Gate.gold.blk'
    raw = (SRC / path).read_bytes()
    result = audit(SRC,GOLD,overrides={path: bytes([raw[0] ^ 1]) + raw[1:]})
    assert 'Gold_shared_NorthSouthGate_5x4' in result['errors']



@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
def test_north_carpet_role_grid_must_remain_fail_closed():
    filename = 'maps/johto_pilot/Route43.roles.bin'
    raw = bytearray((SRC / filename).read_bytes())
    raw[31 * 20 + 17] = 0  # Broadly opening the role grid bypasses the exact direction profiles.
    result = audit(SRC, GOLD, overrides={filename: bytes(raw)})
    assert 'Route43_north_carpet_role_grid_fail_closed' in result['errors']


@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
def test_north_warp_carpet_direction_cannot_be_changed_to_left():
    filename = 'data/johto_vertical_gate_runtime_314.asm'
    data = source(filename)
    old = 'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 31, 1 ; ID66 DOWN collision exit'
    new = 'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 1 ; collision-only carpet'
    assert old in data
    result = audit(SRC, GOLD, overrides={filename: data.replace(old, new, 1)})
    assert 'Route43_north_carpet_warp_is_DOWN_only' in result['errors']


@pytest.mark.skipif(not (GOLD / 'maps/Route43.asm').exists(), reason='Gold reference not installed')
def test_north_carpet_tile_cannot_become_generic_step_on_warp():
    filename = 'data/warp_tile_ids.asm'
    data = source(filename)
    old = 'db $06,$39,$FF'
    new = 'db $06,$39,$40,$FF'
    assert old in data
    result = audit(SRC, GOLD, overrides={filename: data.replace(old, new, 1)})
    assert 'Route43_north_carpet_visuals_not_generic_STEP_ON_warps' in result['errors']
