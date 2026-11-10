"""REF-365C activation/entry test: past missing bicycle and sticky doors fail closed."""
from pathlib import Path

from tools.johto_warp_field_entry_gate import (
    audit, active_ids, registered_routes, trace_arrival,
)

ROOT = Path(__file__).resolve().parents[2]
PILOT = 'engine/johto_pilot_runtime.asm'
BIKE = 'home/rom0_relief_349.asm'
ROSTER = 'data/johto_stable_id_slots.asm'
GATE = 'data/johto_vertical_gate_runtime_314.asm'
VIOLET = 'data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin'
OBJECTS = 'data/johto_dark_cave_stage/REF349_stage2_runtime.asm'


def _mutate(path, before, after):
    src = (ROOT/path).read_text()
    assert before in src, f'fault injection anchor disappeared in {path}'
    return {path: src.replace(before, after, 1)}


def _fails(label, override):
    result = audit(ROOT, override)
    assert result['status'] == 'FAIL', result
    assert any(label in error for error in result['errors']), result['errors']


def test_current_activation_and_high_risk_arrivals_pass():
    result = audit(ROOT)
    assert result['status'] == 'PASS_SOURCE_ONLY', result['errors']
    assert result['passed'] >= 55
    assert len(registered_routes((ROOT/PILOT).read_text())) == 172
    assert len(active_ids((ROOT/ROSTER).read_text())) == 65


def test_removing_real_bike_public_entry_fails():
    _fails('bike_public_entry_JOHTO_DARK_CAVE_BLACKTHORN',
           _mutate(BIKE,
                   '\tcp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n\tjp z, .darkCaveBike\n',
                   ''))


def test_wrong_bike_helper_call_fails():
    _fails('bike_public_entry_JOHTO_DARK_CAVE_VIOLET',
           _mutate(BIKE, '\tcallab JohtoDarkCaveBikeFloorAllowed349\n',
                   '\tcallab JohtoDarkCaveSurfDecision\n'))


def test_removing_internal_cave_step_fails_even_if_warps_still_registered():
    _fails('blackthorn_to_violet_arrival_execution',
           _mutate(PILOT, '    ld e, D_DOWN\n    ret\n.notVioletCaveArrival365C',
                   '    ld e, 0\n    ret\n.notVioletCaveArrival365C'))


def test_wrong_auto_step_on_blackthorn_carpet_fails():
    _fails('violet_to_blackthorn_arrival_execution',
           _mutate(PILOT,
                   '    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n    ret z',
                   '    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n    jr z, .down'))


def test_route45_public_gate_dispatch_fails_if_removed():
    _fails('blackthorn_to_route45_arrival_execution',
           _mutate(PILOT,
                   '    cp JOHTO_ROUTE_45_LOCAL_ID ; REF-365 exterior Gold cave-mouth profiles\n    ret z',
                   '    cp JOHTO_ROUTE_45_LOCAL_ID ; REF-365 exterior Gold cave-mouth profiles\n    ret nz'))


def test_route45_missing_vertical_profile_fails():
    _fails('blackthorn_to_route45_arrival_execution',
           _mutate(GATE, '    db JOHTO_ROUTE_45_LOCAL_ID, 2, 5, D_DOWN',
                   '    db JOHTO_ROUTE_45_LOCAL_ID, 2, 6, D_DOWN'))


def test_wrong_source_warp_coordinate_fails():
    _fails('violet_to_blackthorn_source_object_warp',
           _mutate(OBJECTS, '    db 1, 17, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                   '    db 1, 18, 1, JOHTO_REGISTERED_WARP_SELECTOR'))


def test_wrong_target_ordinal_fails():
    _fails('blackthorn_to_violet_target_object_warp',
           _mutate(OBJECTS, '    db 25, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                   '    db 25, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR'))


def test_unsafe_auto_step_landing_role_fails():
    roles = bytearray((ROOT/VIOLET).read_bytes())
    assert roles[2 * 40 + 17] == 0
    roles[2 * 40 + 17] = 1
    _fails('blackthorn_to_violet_safe_floor_after_step', {VIOLET: bytes(roles)})


def test_new_registered_warp_without_review_fails():
    old = 'JohtoRegisteredWarpRoutesEnd::'
    new = ('    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, 3, '
           'MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\n'
           + old)
    _fails('new_or_changed_route_requires_review', _mutate(PILOT, old, new))


def test_new_active_map_without_review_fails():
    old = '64, JOHTO_INVALID_ACTIVE_SLOT, JOHTO_INVALID_ACTIVE_SLOT, 9'
    new = '64, 65, JOHTO_INVALID_ACTIVE_SLOT, 9'
    _fails('new_active_map_requires_field_and_arrival_review', _mutate(ROSTER, old, new))


def test_neighbor_outside_door_stays_still():
    _fails('route31_adjacent_no_spurious_step',
           _mutate(PILOT, '    cp 34\n    jr nz, .notRoute31CaveArrival349',
                   '    cp 33\n    jr nz, .notRoute31CaveArrival349'))


def test_frozen_route_inventory_cannot_be_relabelled_as_reviewed():
    import json
    path = 'tools/johto_warp_field_entry_contracts.json'
    data = json.loads((ROOT/path).read_text())
    data['frozen_ref365c_route_rows'].append(
        'MAP_REGION_JOHTO,JOHTO_ROUTE_31_LOCAL_ID,3,MAP_REGION_JOHTO,JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID')
    _fails('frozen_ref365c_route_inventory_unchanged', {path: json.dumps(data)})


def test_frozen_map_inventory_cannot_be_silently_extended():
    import json
    path = 'tools/johto_warp_field_entry_contracts.json'
    data = json.loads((ROOT/path).read_text())
    data['frozen_ref365c_active_map_ids'].append(100)
    _fails('frozen_ref365c_active_map_inventory_unchanged', {path: json.dumps(data)})


def test_future_review_requires_explicit_field_policies():
    import json
    path = 'tools/johto_warp_field_entry_contracts.json'
    data = json.loads((ROOT/path).read_text())
    data['new_map_activation_reviews'].append({'stable_id': 100, 'bike_policy': 'FLOOR_ONLY_CAVE'})
    _fails('new_map_reviews_have_explicit_fields', {path: json.dumps(data)})
