"""Failure injection for REF-368A live B2F Mahogany one-area deployment."""
from pathlib import Path
from tools.johto_ice_path_b2f_mahogany_368a_audit import audit

ROOT = Path(__file__).resolve().parents[2]
SRC = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'


def failure(path, before, after, marker):
    source = (ROOT / path).read_text()
    assert before in source
    errors = audit(ROOT, {path: source.replace(before, after, 1)})
    assert any(marker in error for error in errors), errors


def test_new_map_review():
    assert audit(ROOT) == []


def test_arrival_only_ice_must_not_be_live_source_warp():
    failure(SRC, 'db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 4, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR', 'six-ordinal warp')


def test_b3f_ladder_source_must_match_gold():
    failure(SRC, 'db 11, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 11, 8, 0, JOHTO_REGISTERED_WARP_SELECTOR', 'six-ordinal warp')


def test_wrong_return_destination_ordinal_is_rejected():
    failure(SRC, 'db 1, 17, 1, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 1, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR', 'six-ordinal warp')


def test_b1f_south_ladder_wrong_coordinate_is_rejected():
    failure('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm',
            'db 3, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 3, 16, 0, JOHTO_REGISTERED_WARP_SELECTOR', 'B1F Gold #2')


def test_landing_stair_wall_conversion_fails():
    data = bytearray((ROOT / 'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin').read_bytes())
    data[1*20+17] = 1
    assert any('Gold stair/arrival role' in s for s in
               audit(ROOT, {'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin': bytes(data)}))


def test_ice_landing_role_corruption_fails():
    data = bytearray((ROOT / 'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin').read_bytes())
    data[4*20+11] = 4
    assert any('Gold stair/arrival role' in s for s in
               audit(ROOT, {'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin': bytes(data)}))


def test_wrong_b2f_bike_public_dispatch_fails():
    failure('home/rom0_relief_349.asm',
            'callab JohtoIcePathB2FMahoganyBikeFloorAllowed368A',
            'callab JohtoIcePath1FBikeFloorAllowed367J', 'bike public item entry')


def test_wrong_floor_popup_fails():
    failure('engine/overworld/map_name_sign.asm',
            'ld b, $82 ; B2F', 'ld b, 0 ; B2F', 'location card')


def test_missing_game_map_include_fails():
    failure('main.asm',
            'INCLUDE "data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm"',
            '; INCLUDE removed', 'map/header/resource/main ASM')


def test_no_invisible_boulder_objects():
    failure(SRC, 'db 0 ; no NPC or dropped boulder objects',
            'db 4 ; unseen dropped boulder objects', 'unfinished boulder')


def test_warp_source_b1f_pit_must_stay_sealed():
    f = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
    source = (ROOT / f).read_text()
    assert 'db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR' in source
    assert 'db $ff, $ff, 5, JOHTO_REGISTERED_WARP_SELECTOR' in source
