"""REF-367B movement/Strength/PIT specification contract, not ROM emulation."""
from pathlib import Path
import shutil

from tools.johto_ice_path_367_movement import (
    Model, Position, DIRECTIONS, BOULDERS, PITS, BOULDER_FALL_ARRIVALS, audit,
)

ROOT = Path(__file__).resolve().parents[2]


def test_movement_model_exhaustive():
    assert audit(ROOT) == []


def test_all_five_dedicated_runtime_blocksets_equal_gold():
    for name in ['IcePath1F', 'IcePathB1F', 'IcePathB2FMahoganySide',
                 'IcePathB2FBlackthornSide', 'IcePathB3F']:
        a = ROOT/f'maps/johto_ice_path_stage/{name}.gold.blk'
        b = ROOT/f'maps/johto_ice_path_stage/{name}.runtime.blk'
        assert a.read_bytes() == b.read_bytes()
        assert len(a.read_bytes()) == Model(ROOT).maps[name]['width_blocks'] * Model(ROOT).maps[name]['height_blocks']


def test_four_pits_have_one_way_drop_landing_on_ice():
    model = Model(ROOT)
    for x, y in PITS:
        pos = Position('IcePathB1F', x, y)
        assert model.role(pos) == 'PIT'
        result = model.step_on(pos)
        assert result and result.location.map == 'IcePathB2FMahoganySide'
        assert model.role(result.location) == 'ICE'
        assert model.step_on(result.location) is None, 'arrival ICE must never warp upward'


def test_south_carpet_only_when_direction_is_down():
    model = Model(ROOT)
    pos = Position('IcePath1F', 4, 19)
    assert model.role(pos) == 'WARP_CARPET_DOWN'
    down = model.move(pos, 'DOWN')
    assert down.kind == 'warp' and down.location.map == 'Route44'
    assert model.step_on(pos) is None, 'standing on carpet is not a warp'
    for direction in ('UP', 'LEFT', 'RIGHT'):
        assert model.move(pos, direction).kind != 'warp'


def test_ice_is_forced_movement_and_collision_stops_it():
    model = Model(ROOT)
    examples = []
    for name, spec in model.maps.items():
        for y in range(spec['height_cells']):
            for x in range(spec['width_cells']):
                start = Position(name, x, y)
                if model.role(start) != 'ICE':
                    continue
                for direction in DIRECTIONS:
                    res = model.move(start, direction)
                    if res.kind == 'slide' and len(res.trace) > 3:
                        examples.append((name, start, direction, res))
    assert len(examples) > 50, 'map should contain long ice slides, not one-step walking'
    for _, _, direction, res in examples:
        dx, dy = DIRECTIONS[direction]
        assert all((b.x-a.x, b.y-a.y) == (dx, dy)
                   for a,b in zip(res.trace, res.trace[1:]))


def test_strength_boulder_and_pit_behaviour_differ_from_rock_smash():
    model = Model(ROOT)
    assert tuple(model.boulders.values()) == BOULDERS
    assert tuple(PITS) == ((11, 2), (4, 7), (5, 12), (12, 13))
    assert tuple(BOULDER_FALL_ARRIVALS) == ((11, 3), (4, 7), (3, 12), (12, 13))
    # Position first stone immediately left of its matching PIT for an isolated push
    # transaction.  This verifies the state machine, not the full strength puzzle.
    model.boulders[0] = (10, 2)
    player = Position('IcePathB1F', 9, 2)
    no_strength = model.move(player, 'RIGHT', strength=False)
    assert no_strength.kind == 'blocked_boulder'
    assert model.boulders[0] == (10, 2)
    with_strength = model.move(player, 'RIGHT', strength=True)
    assert with_strength.kind == 'boulder_fell'
    assert with_strength.landed_boulder == 0
    assert model.boulders[0] is None
    assert 0 in model.landed_boulders
    # Gold PIT remains a drop for the PLAYER after the boulder disappears.
    assert model.step_on(Position('IcePathB1F',11,2)).location.map == 'IcePathB2FMahoganySide'


def test_no_strength_cannot_push_stone_even_if_adjacent():
    model = Model(ROOT)
    for i, (x, y) in enumerate(BOULDERS):
        model.boulders = {i: (x,y)}
        for d, (dx, dy) in DIRECTIONS.items():
            loc = Position('IcePathB1F', x-dx, y-dy)
            if model.role(loc) in ('FLOOR', 'ICE'):
                old = model.boulders.copy()
                model.move(loc, d, strength=False)
                assert model.boulders == old


def test_defensive_slide_on_cyclic_or_broken_map(tmp_path):
    # Mutating runtime graphics should not silently pass the new runtime contract.
    for rel in ['docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json', 'main.asm']:
        p = tmp_path/rel
        p.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/rel,p)
    for directory in ('data/johto_ice_path_stage','maps/johto_ice_path_stage'):
        shutil.copytree(ROOT/directory,tmp_path/directory)
    f=tmp_path/'maps/johto_ice_path_stage/IcePath1F.runtime.blk'
    b=bytearray(f.read_bytes());b[0]^=1;f.write_bytes(b)
    assert any('runtime metatile byte mismatch' in e for e in audit(tmp_path))


def test_role_reader_present_but_not_linked():
    asm = (ROOT/'data/johto_ice_path_stage/ice_path_role_runtime_367b.asm').read_text()
    assert 'JohtoIcePathGoldRoleAt367B::' in asm
    assert 'ice_path_role_runtime_367b.asm' not in (ROOT/'main.asm').read_text()
    for role, dimensions in [('1F', (40,36)),('B1F',(20,36)),
                             ('B2FMahogany',(20,18)),('B2FBlackthorn',(10,18)),
                             ('B3F',(20,18))]:
        label=f'JohtoIcePath{role}RoleBytes367B'
        assert f'{label}::' in asm
        assert f'ASSERT @ - {label} == {dimensions[0]} * {dimensions[1]}' in asm


def test_illegal_16bit_subtraction_is_rejected(tmp_path):
    for rel in ['docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json','main.asm']:
        dest = tmp_path/rel
        dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/rel,dest)
    for directory in ('data/johto_ice_path_stage','maps/johto_ice_path_stage'):
        shutil.copytree(ROOT/directory,tmp_path/directory)
    f=tmp_path/'data/johto_ice_path_stage/ice_path_role_runtime_367b.asm'
    f.write_text(f.read_text().replace('    add hl, de                 ; 40*y',
                                       '    sbc hl, de                 ; invalid LR35902 instruction'))
    assert any('illegal LR35902' in e for e in audit(tmp_path))
