"""REF-366A Gold Union Cave B1F two Ruins mouth regression tests.

Source-only; destination data and source-trigger branches are separately
validated. Real RGBDS/mobile verification is still required.
"""
from pathlib import Path

from tools.johto_warp_field_entry_gate import audit, warp_objects

ROOT = Path(__file__).resolve().parents[2]
ROUTE_FILE = 'engine/johto_pilot_runtime.asm'
RUINS_FILE = 'data/johto_ruins_south_runtime.asm'
CAVE_FILE = 'data/johto_union_cave_runtime.asm'


def _parts(src: str):
    return (
        src.split('JohtoPilotGateDoorApproachAllowed::', 1)[1].split('JohtoPilotGateDoorWarpMatched::', 1)[0],
        src.split('JohtoPilotGateDoorWarpMatched::', 1)[1].split('JohtoPilotGateExteriorCollisionAllowed::', 1)[0],
        src.split('JohtoPilotGateCollisionExitAllowed::', 1)[1].split('; REF-336 center-door ingress', 1)[0],
    )


def _entry_gate_ok(src: str) -> bool:
    before, after, coll = _parts(src)
    return ('.ruinsCaveApproach366' in before and
            'cp 20\n    jp z, .allow\n    cp 28' in before and
            '.ruinsCaveEntered366' in after and
            'cp 19\n    jp z, .yesDoor\n    cp 27' in after and
            'jr z, .unionCaveB1FRuinsExit366' in coll and
            '.unionCaveB1FRuinsExit366' in coll and
            'cp PLAYER_DIR_DOWN\n    ret nz\n    ld a, [wXCoord]\n    cp 3' in coll.split('.unionCaveB1FRuinsExit366', 2)[-1].split('.unionCaveNoCollisionWarp342', 1)[0] and
            'cp 3\n    jr z, .yes\n    cp 11' in coll)


def test_source_entry_and_directional_collision_exact():
    assert _entry_gate_ok((ROOT/ROUTE_FILE).read_text())


def test_fault_wrong_outdoor_door_approach_rejected():
    src = (ROOT/ROUTE_FILE).read_text()
    assert _entry_gate_ok(src)
    assert not _entry_gate_ok(src.replace('cp 20\n    jp z, .allow\n    cp 28',
                                              'cp 21\n    jp z, .allow\n    cp 29', 1))


def test_fault_wrong_entrance_warp_y_rejected():
    src = (ROOT/ROUTE_FILE).read_text()
    assert not _entry_gate_ok(src.replace('cp 19\n    jp z, .yesDoor\n    cp 27',
                                              'cp 18\n    jp z, .yesDoor\n    cp 27', 1))


def test_fault_wrong_b1f_collision_facing_rejected():
    src = (ROOT/ROUTE_FILE).read_text()
    a = src.split('.unionCaveB1FRuinsExit366', 2)
    assert len(a) == 3
    damaged = src.replace('.unionCaveB1FRuinsExit366\n    ; Gold B1F Ruins carpets: DOWN-collision only at exact (3,3)/(3,11).\n    ; The other three B1F stairs remain STEP_IN and never collision-warp.\n    ld e, 0\n    ld a, [wPlayerDirection]\n    cp PLAYER_DIR_DOWN',
                          '.unionCaveB1FRuinsExit366\n    ; Gold B1F Ruins carpets: DOWN-collision only at exact (3,3)/(3,11).\n    ; The other three B1F stairs remain STEP_IN and never collision-warp.\n    ld e, 0\n    ld a, [wPlayerDirection]\n    cp PLAYER_DIR_UP', 1)
    assert not _entry_gate_ok(damaged)


def test_dual_warp_source_target_objects_and_auto_steps():
    checker = audit(ROOT)
    assert checker['status'] == 'PASS_SOURCE_ONLY', checker['errors']
    names = {r['check'] for r in checker['checks'] if r['status'] == 'PASS'}
    for marker in ('ruins_north_into_union_b1f_registered',
                   'union_b1f_north_to_ruins_arrival_execution',
                   'ruins_south_into_union_b1f_registered',
                   'union_b1f_south_to_ruins_arrival_execution'):
        assert marker in names
    ruins = warp_objects((ROOT/RUINS_FILE).read_text(), 'JohtoPilotAlphOutsideRuntimeObjects')
    b1f = warp_objects((ROOT/CAVE_FILE).read_text(), 'JohtoUnionCaveB1FRuntimeObjects')
    assert ruins[3:] == [(6,19,0), (6,27,1)]
    assert b1f[:2] == [(3,3,3), (3,11,4)]


def test_fault_wrong_ruins_ordinal_rejected():
    src = (ROOT/RUINS_FILE).read_text()
    old = 'db 27, 6, 1, JOHTO_REGISTERED_WARP_SELECTOR'
    assert old in src
    result = audit(ROOT, {RUINS_FILE: src.replace(old, 'db 27, 6, 0, JOHTO_REGISTERED_WARP_SELECTOR', 1)})
    assert result['status'] == 'FAIL'
    assert any('ruins_south_into_union_b1f_target_object_warp' in x for x in result['errors'])


def test_fault_missing_arrival_step_rejected():
    src = (ROOT/ROUTE_FILE).read_text()
    old = '    cp 27\n    jp z, .down\n    ret\n.ruinsNorthGateArrival366'
    assert old in src
    altered = src.replace(old, '    cp 27\n    ret z\n    ret\n.ruinsNorthGateArrival366', 1)
    result = audit(ROOT, {ROUTE_FILE: altered})
    assert result['status'] == 'FAIL'
    assert any('union_b1f_south_to_ruins_arrival_execution' in x for x in result['errors'])
