from pathlib import Path
import pytest
from tools.johto_ice_path_boulder_target_369h_audit import (
    audit, B1, ROLES, GOLD_BOULDERS, WIDTH, HEIGHT, DIRECTION_OFFSETS,
    target_cell, reference_allowed, GOLD_PITS,
)

ROOT=Path(__file__).resolve().parents[2]


def test_live_source_and_gold_map_target_gate():
    assert audit(ROOT)==[]


@pytest.mark.parametrize('old,new',[
    ('    ld a, [$ffdb]\n    bit 0, a', '    call JohtoIcePathB1FRoleAt367K\n    bit 0, a'),
    ('    bit 0, a ; down', '    bit 1, a ; down'),
    ('    bit 1, a ; up', '    bit 0, a ; up'),
    ('    bit 2, a ; left', '    bit 3, a ; left'),
    ('    bit 3, a ; right', '    bit 2, a ; right'),
    ('    inc b\n    jr .checkTarget', '    dec b\n    jr .checkTarget'),
    ('    dec b\n    jr .checkTarget', '    inc b\n    jr .checkTarget'),
    ('    dec c\n    jr .checkTarget', '    inc c\n    jr .checkTarget'),
    ('    inc c\n.checkTarget', '    dec c\n.checkTarget'),
    ('    jp .blocked ; invalid direction must fail closed', '    jr .checkTarget ; accept undefined direction'),
    ('    call JohtoIcePathB1FRoleAt367K\n    and a ; FLOOR', '    and a ; FLOOR'),
    ('    callba CheckForBoulderCollisionWithSprites', '    xor a ; bypass objects'),
    ('    jr c, .blocked ; Bankswitch overwrites A but preserves carry', '    jr nc, .blocked ; bad ABI'),
    ('    jr nz, .blocked\n.checkSprites', '    jr z, .blocked\n.checkSprites'),
    ('    predef GetTileTwoStepsInFrontOfPlayer', '    nop ; skip ABI initialization'),
])
def test_injected_terrain_or_direction_bug_fails_gate(old,new):
    source=(ROOT/B1).read_text()
    assert old in source
    bad=source.replace(old,new,1)
    assert audit(ROOT,{B1:bad})


@pytest.mark.parametrize('x,y,direction',[
    (11,7,'left'),(7,8,'up'),(8,9,'down'),(17,7,'down'),
])
def test_fixed_rocks_reject_pushing(x,y,direction):
    roles=(ROOT/ROLES).read_bytes()
    # The old buggy lookup would check the walkable tile under the stone.
    assert roles[y*WIDTH+x]==0
    actual=target_cell(x,y,direction)
    assert roles[actual[1]*WIDTH+actual[0]]==1
    assert not reference_allowed(roles,x,y,direction)


def test_all_four_directions_and_roles_against_gold_grid():
    roles=(ROOT/ROLES).read_bytes()
    assert len(roles)==WIDTH*HEIGHT
    # Exhaustive legal target classifier: 720 cells * 4 cardinal directions.
    assert len(DIRECTION_OFFSETS)==4
    for y in range(HEIGHT):
        for x in range(WIDTH):
            for direction,(dx,dy) in DIRECTION_OFFSETS.items():
                tx,ty=target_cell(x,y,direction)
                if not 0<=tx<WIDTH or not 0<=ty<HEIGHT:
                    expected=False
                else:
                    role=roles[ty*WIDTH+tx]
                    expected=role in (0,2) or role==3 and (tx,ty) in GOLD_PITS
                assert reference_allowed(roles,x,y,direction)==expected


def test_all_four_pits_can_fill_only_once():
    roles=(ROOT/ROLES).read_bytes()
    for x,y in GOLD_PITS:
        candidates=[]
        for direction,(dx,dy) in DIRECTION_OFFSETS.items():
            ox,oy=x-dx,y-dy
            if 0<=ox<WIDTH and 0<=oy<HEIGHT:
                candidates.append((ox,oy,direction))
        assert candidates
        for ox,oy,direction in candidates:
            assert reference_allowed(roles,ox,oy,direction)
            assert not reference_allowed(roles,ox,oy,direction,frozenset({(x,y)}))


def test_mutated_gold_wall_detected_by_role_guard():
    roles=bytearray((ROOT/ROLES).read_bytes())
    x,y=10,7
    assert roles[y*WIDTH+x]==1
    roles[y*WIDTH+x]=0
    assert audit(ROOT,{ROLES:bytes(roles)})
