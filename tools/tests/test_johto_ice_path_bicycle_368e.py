"""REF-368E bicycle regression: five Ice Path floors, both item paths, riding sprite."""
from pathlib import Path

import pytest

from tools.johto_ice_path_bicycle_368e_audit import FLOORS, audit

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {
    'IcePath1F': 818, 'IcePathB1F': 251,
    'IcePathB2FMahoganySide': 44, 'IcePathB2FBlackthornSide': 36,
    'IcePathB3F': 75,
}


def bad(path, old, replacement, error):
    text = (ROOT / path).read_text()
    assert old in text, (path, old)
    issues, _ = audit(ROOT, {path: text.replace(old, replacement, 1)})
    assert any(error in issue for issue in issues), issues


def test_every_cell_all_five_maps():
    problems, counts = audit(ROOT)
    assert problems == []
    assert counts == EXPECTED


@pytest.mark.parametrize('name', FLOORS)
def test_removing_one_floor_public_dispatch_is_rejected(name):
    map_id, label, *_ = FLOORS[name]
    bad('home/rom0_relief_349.asm', f'cp {map_id}\n\tjp z, {label}',
        f'cp {map_id}\n\tjp z, .legacyBike', f'{name}: public bike-ID dispatch missing')


@pytest.mark.parametrize('name', FLOORS)
def test_wrong_floor_private_helper_is_rejected(name):
    _map_id, label, helper, *_ = FLOORS[name]
    wrong = 'JohtoDarkCaveBikeFloorAllowed349'
    bad('home/rom0_relief_349.asm', f'callab {helper}\n\tret',
        f'callab {wrong}\n\tret', f'{name}: mounted player must remain on bicycle')


@pytest.mark.parametrize('name', FLOORS)
def test_stairs_cannot_unmount_an_already_riding_player(name):
    _map_id, label, helper, *_ = FLOORS[name]
    rel = 'home/rom0_relief_349.asm'
    text = (ROOT / rel).read_text()
    start = text.index('\n' + label + '\n')
    end = text.index(f'callab {helper}', start)
    prefix = text[start:end]
    assert '\tcp 1\n' in prefix
    broken = text[:start] + prefix.replace('\tcp 1\n', '\tcp 2\n', 1) + text[end:]
    issues, _ = audit(ROOT, {rel: broken})
    assert any(f'{name}: mounted player must remain on bicycle' in issue for issue in issues), issues


@pytest.mark.parametrize('name', FLOORS)
def test_current_position_must_be_used_for_bike_floor_role(name):
    _map_id, _label, helper, _role_func, filename, *_ = FLOORS[name]
    rel = 'data/johto_ice_path_stage/' + filename
    old = 'ld a, [wYCoord]\n    ld b, a\n    ld a, [wXCoord]\n    ld c, a'
    # Each role helper is after the ordinary collision routine. Change the
    # specific last occurrence to avoid changing unrelated land behavior.
    text = (ROOT / rel).read_text()
    start = text.index(helper + '::')
    assert old in text[start:]
    tampered = text[:start] + text[start:].replace(old,
        old.replace('[wXCoord]', '[wYCoord]'), 1)
    issues, _ = audit(ROOT, {rel: tampered})
    assert any(f'{name}: bicycle must inspect current cell' in issue for issue in issues), issues


def test_ice_tile_becomes_illegal_bike_mount_if_1f_helper_is_broken():
    bad('data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm',
        'cp 5 ; Gold WARP_CARPET_DOWN also has FLOOR permission',
        'cp 2 ; incorrectly lets ICE mount bicycles',
        'IcePath1F: bike fresh-mount flag')


def test_b1f_floor_branch_must_clear_carry_for_ice():
    bad('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm',
        'jr nz, .no\n    scf\n    ret\n.no\n    and a\n    ret',
        'jr z, .no\n    scf\n    ret\n.no\n    and a\n    ret',
        'IcePathB1F: bike fresh-mount flag')


def test_bag_must_query_ice_path_bike_permission():
    bad('engine/items/items.asm', 'callab IsBikeRidingAllowed\n\tjp nc,NoCyclingAllowedHere',
        'callab IsBikeRidingAllowed\n\tjp c,NoCyclingAllowedHere',
        'Bicycle Bag use')


def test_select_must_query_ice_path_bike_permission():
    bad('engine/overworld/bike_shortcut.asm', 'farcall IsBikeRidingAllowed',
        'farcall CheckIfInOutsideMap', 'Bicycle SELECT shortcut')


def test_sprite_reload_must_not_dismount_on_stairs():
    bad('home/overworld.asm', 'callab IsBikeRidingAllowed\n\tjr c, .determineGraphics',
        'callab IsBikeRidingAllowed\n\tjr nc, .determineGraphics',
        'Map transition bicycle sprite refresh')


def test_generic_ice_path_bike_bypass_is_not_allowed():
    original = 'db OVERWORLD,FOREST,UNDERGROUND,SHIP_PORT'
    bad('data/bike_riding_tilesets.asm', original,
        'db JOHTO_ICE_PATH,OVERWORLD,FOREST,UNDERGROUND,SHIP_PORT',
        'globally whitelisted')


def test_role_data_must_match_pinned_gold_source():
    p = 'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin'
    data = bytearray((ROOT / p).read_bytes())
    pos = data.index(2)
    data[pos] = 0
    issues, _ = audit(ROOT, {p: bytes(data)})
    assert any('Gold role bytes differ' in i for i in issues), issues
