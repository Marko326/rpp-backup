from __future__ import annotations
from pathlib import Path
from tools.johto_ice_path_b1f_367k_audit import audit

ROOT=Path(__file__).resolve().parents[2]

def test_ice_path_b1f_new_map_review():
    assert audit(ROOT)==[]

def test_b1f_sealed_pit_mutation_fails():
    f='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source=(ROOT/f).read_text()
    bad=source.replace('db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR', 'db 2, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR',1)
    assert any('8 ordinal objects' in e for e in audit(ROOT,{f:bad}))

def test_b1f_stair_destination_mutation_fails():
    f='engine/johto_pilot_runtime.asm'; source=(ROOT/f).read_text()
    old='db MAP_REGION_JOHTO, JOHTO_ICE_PATH_1F_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ICE_PATH_B1F_LOCAL_ID'
    bad=source.replace(old,old.replace(' 2,',' 3,'),1)
    assert any('reciprocal route missing' in e for e in audit(ROOT,{f:bad}))

def test_b1f_location_sign_mutation_fails():
    f='engine/overworld/map_name_sign.asm';source=(ROOT/f).read_text()
    bad=source.replace('ld b, $81 ; B1F','ld b, 0 ; B1F',1)
    assert any('floor popup' in e for e in audit(ROOT,{f:bad}))

def test_b1f_role_grid_mutation_fails():
    raw=(ROOT/'data/johto_ice_path_stage/IcePathB1F.roles.bin').read_bytes()
    bad=bytearray(raw);bad[2*20+11]=0
    assert any('Gold' in e for e in audit(ROOT,{'data/johto_ice_path_stage/IcePathB1F.roles.bin':bytes(bad)}))

def test_b1f_ladder_1f_object_mutation_fails():
    f='data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm';source=(ROOT/f).read_text()
    bad=source.replace('db 5, 37, 0, JOHTO_REGISTERED_WARP_SELECTOR','db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR',1)
    assert any('1F both original Gold stair' in e for e in audit(ROOT,{f:bad}))


def test_1f_ladder_illegal_jump_operand_colon_is_detected():
    f='data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm'
    source=(ROOT/f).read_text()
    assert 'jr nz, .notLadder367K' in source
    bad=source.replace('jr nz, .notLadder367K', 'jr nz, .notLadder367K:', 1)
    assert any('illegal label colon' in e for e in audit(ROOT,{f:bad}))


def test_b1f_airwall_when_stone_sprite_is_missing():
    f='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source=(ROOT/f).read_text()
    bad=source.replace('    object SPRITE_BOULDER, 8, 9, STAY, NONE, $3\n', '', 1)
    assert any('invisible air wall' in e for e in audit(ROOT,{f:bad}))


def test_b1f_airwall_when_stone_sprite_uses_wrong_coordinates():
    f='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source=(ROOT/f).read_text()
    bad=source.replace('SPRITE_BOULDER, 11, 7, STAY, NONE', 'SPRITE_BOULDER, 12, 7, STAY, NONE',1)
    assert any('invisible air wall' in e for e in audit(ROOT,{f:bad}))


def test_b1f_airwall_when_stone_sprite_hidden_by_zero_count():
    f='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source=(ROOT/f).read_text()
    bad=source.replace('    db 4\n    object SPRITE_BOULDER', '    db 0\n    object SPRITE_BOULDER',1)
    assert any('invisible air wall' in e for e in audit(ROOT,{f:bad}))


def test_b1f_pre_push_stones_must_be_stationary():
    f='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source=(ROOT/f).read_text()
    bad=source.replace('SPRITE_BOULDER, 7, 8, STAY, NONE', 'SPRITE_BOULDER, 7, 8, STAY, BOULDER_MOVEMENT_BYTE_2',1)
    assert any('invisible air wall' in e for e in audit(ROOT,{f:bad}))


# REF-367M: an object text ID is a one-based pointer-table index.  Guard
# against adjacent object bytes turning into unrelated dialogue/menu scripts.
def test_b1f_stone_missing_text_pointer_is_rejected():
    f = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source = (ROOT / f).read_text()
    bad = source.replace('    dw JohtoIcePathB1FStaticStoneText367M ; stone $4, (17,7)\n', '', 1)
    assert any('four valid in-bank pointers' in e for e in audit(ROOT, {f: bad}))


def test_b1f_stone_pointer_cannot_jump_to_unrelated_text():
    f = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source = (ROOT / f).read_text()
    bad = source.replace('    dw JohtoIcePathB1FStaticStoneText367M ; stone $2',
                         '    dw FuchsiaHealNurseText ; stone $2', 1)
    assert any('four valid in-bank pointers' in e for e in audit(ROOT, {f: bad}))


def test_b1f_stone_message_requires_terminator():
    f = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source = (ROOT / f).read_text()
    bad = source.replace('    line "It won\'t budge."\n    done',
                         '    line "It won\'t budge."\n    nop', 1)
    assert any('interaction text missing/invalid' in e for e in audit(ROOT, {f: bad}))


def test_b1f_stone_text_must_stay_in_map_bank():
    f = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source = (ROOT / f).read_text()
    bad = source.replace(
        'ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FStaticStoneText367M)\n',
        '', 1)
    assert any('same ROM bank' in e for e in audit(ROOT, {f: bad}))


def test_b1f_props_cannot_be_pushed_before_strength_pit_phase():
    f = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source = (ROOT / f).read_text()
    bad = source.replace('SPRITE_BOULDER, 17, 7, STAY, NONE',
                         'SPRITE_BOULDER, 17, 7, STAY, BOULDER_MOVEMENT_BYTE_2', 1)
    assert any('invisible air wall' in e for e in audit(ROOT, {f: bad}))
