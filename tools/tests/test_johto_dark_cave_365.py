"""REF-365 Gold Dark Cave same-floor source gate; no ROM/emulator claims."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.johto_dark_cave_365_audit import audit, blackthorn_role_offset


def test_gold_two_regions_and_bidirectional_warps():
    result = audit(ROOT)
    assert result['errors'] == [], result['errors']
    assert result['passed'] >= 49


def test_no_smashable_rocks_or_move_logic_added():
    run = (ROOT/'data/johto_dark_cave_stage/REF349_stage2_runtime.asm').read_text()
    assert 'db 0 ; no signs or Rock Smash objects' in run
    assert 'db 0 ; no signs/NPCs/items until later' in run
    assert 'JohtoDarkCaveRockSmash' not in (ROOT/'engine/johto_dark_cave_stage2.asm').read_text()


def test_route45_active_dispatch_and_south_exit():
    pilot = (ROOT/'engine/johto_pilot_runtime.asm').read_text()
    dispatch = pilot.split('JohtoPilotIsVerticalGatePairMap314::',1)[1].split('JohtoPilotGateArrivalStep::',1)[0]
    assert 'cp JOHTO_ROUTE_45_LOCAL_ID' in dispatch
    gate = (ROOT/'data/johto_vertical_gate_runtime_314.asm').read_text()
    for needle in ('JOHTO_ROUTE_45_LOCAL_ID, PLAYER_DIR_UP, 2, 6',
                   'JOHTO_ROUTE_45_LOCAL_ID, PLAYER_DIR_UP, 2, 5, 2',
                   'JOHTO_ROUTE_45_LOCAL_ID, 2, 5, D_DOWN'):
        assert needle in gate


def test_flash_branch_label_exists_in_actual_asm():
    block = (ROOT/'engine/johto_dark_cave_stage2.asm').read_text().split(
        'JohtoFlashEligibility349::',1)[1].split('WaitForFlashAOnly349::',1)[0]
    assert 'jr z, .supported365' in block
    assert '.supported365\n' in block
    assert 'jr nz, .notDark' in block
    assert '.notDark\n' in block


def test_saved_rope_entrance_anchor_three_roads():
    src = (ROOT/'engine/johto_dark_cave_stage2.asm').read_text()
    for road in ('31','46','45'):
        assert f'cp JOHTO_ROUTE_{road}_LOCAL_ID' in src
        assert f'FLYWARP_DATA JOHTO_ROUTE_{road}_WIDTH' in src
    assert 'and $3f' in src and 'or b' in src
    assert 'ret nz ; interior transfer MUST NOT rewrite the outdoor anchor' in src
    assert 'jr z, .deny ; old save/invalid origin' in src


def test_blackthorn_role_grid_uses_legal_LR35902_stride():
    src = (ROOT/'engine/johto_dark_cave_stage2.asm').read_text()
    for y in range(36):
        for x in range(30):
            assert blackthorn_role_offset(src, y, x) == y*30+x


def test_blackthorn_unsupported_16bit_sbc_is_rejected():
    src = (ROOT/'engine/johto_dark_cave_stage2.asm').read_text()
    assert all('sbc hl, de' not in line.split(';',1)[0].lower() for line in src.split('\n.blackthorn\n',1)[1].split('\n.wall\n',1)[0].splitlines())
    bad = src.replace('add hl, de ; 30y', 'sbc hl, de ; 30y')
    assert bad != src
    assert blackthorn_role_offset(bad, 13, 17) is None


def test_ref365c_internal_landing_and_bike_dispatch_regressions():
    """Guard the two real device failures, not just table existence."""
    import tempfile
    from tools.johto_dark_cave_365_audit import audit
    source = (ROOT/'engine/johto_pilot_runtime.asm').read_text()
    bike = (ROOT/'home/rom0_relief_349.asm').read_text()
    expected = audit(ROOT)
    assert not expected['errors'], expected['errors']
    checks = {c['check']: c['status'] for c in expected['checks']}
    assert checks['Violet_internal_CAVE_arrival_step_down'] == 'PASS'
    assert checks['bike_dispatched_for_both_dark_cave_ids'] == 'PASS'
    assert checks['Blackthorn_carpets_no_auto_step'] == 'PASS'

    # Mutation: delete the Violet landing step, preserving all warp records.
    broken_arrival = source.replace('    ld e, D_DOWN\n    ret\n.notVioletCaveArrival365C',
                                    '    ld e, 0\n    ret\n.notVioletCaveArrival365C', 1)
    assert broken_arrival != source
    # Mutation: restore the original oversight, where ID99 falls into the
    # generic indoor tileset path and fails the bicycle permission check.
    broken_bike = bike.replace('\tcp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n\tjp z, .darkCaveBike\n', '', 1)
    assert broken_bike != bike
    import unittest.mock
    original_read = Path.read_text
    def altered_read(path, *args, **kwargs):
        if str(path).endswith('engine/johto_pilot_runtime.asm'):
            return broken_arrival
        if str(path).endswith('home/rom0_relief_349.asm'):
            return broken_bike
        return original_read(path, *args, **kwargs)
    with unittest.mock.patch.object(Path, 'read_text', altered_read):
        bad = audit(ROOT)
    assert 'Violet_internal_CAVE_arrival_step_down' in bad['errors']
    assert 'bike_dispatched_for_both_dark_cave_ids' in bad['errors']


def test_ref365c_entrance_roles_prevent_wrong_side_auto_step():
    violet=(ROOT/'data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin').read_bytes()
    blackthorn=(ROOT/'data/johto_dark_cave_stage/DarkCaveBlackthornEntrance.roles.bin').read_bytes()
    assert violet[1*40+17] == 7  # Gold CAVE source + return landing
    assert violet[2*40+17] == 0  # legal FLOOR one tile south
    assert blackthorn[25*30+3] == 6  # return carpet, collision DOWN only
    assert blackthorn[26*30+3] == 1  # never auto-step south into WALL
