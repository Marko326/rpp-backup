"""REF368F regression: live overworld ICE slide hooks and bank ABI."""
from pathlib import Path
from tools.johto_ice_path_slide_368f_audit import audit

ROOT=Path(__file__).resolve().parents[2]
SLIDE='engine/johto_ice_path_slide_368f.asm'
HOME='home/overworld.asm'
MAIN='main.asm'
WRAM='wram.asm'
B1='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'


def fail_when(path: str, original: str, replacement: str):
    text=(ROOT/path).read_text(encoding='utf-8')
    assert original in text
    errors,_=audit(ROOT,{path:text.replace(original,replacement,1)})
    assert errors, (path,original)


def test_live_slide_gold_all_five_floors():
    errors, counts=audit(ROOT)
    assert not errors,errors
    assert list(counts.values())==[234,44,304,91,0]


def test_missing_live_romx_include_rejected():
    fail_when(MAIN,'INCLUDE "engine/johto_ice_path_slide_368f.asm"', '; LIVE ICE slide removed')


def test_joypad_hook_rejected_when_missing():
    fail_when(HOME,'callab JohtoIcePathInjectSlideInput368F','; missing input call')


def test_incomplete_step_hook_rejected():
    fail_when(HOME,'callab JohtoIcePathArmAfterStep368F','; missing arm call')


def test_collision_no_longer_disarms_rejected():
    fail_when(HOME,'ld [wIcePathSlideHeading], a\n\t;ld a,[wChannelSoundIDs',
              'ld [wPlayerLastStopDirection], a\n\t;ld a,[wChannelSoundIDs')


def test_battle_no_longer_disarms_rejected():
    fail_when(HOME,'ld [wIcePathSlideHeading],a ; REF-368F:',
              'ld [wPlayerLastStopDirection],a ; REF-368F:')


def test_warp_clear_removed_rejected():
    fail_when('engine/overworld/clear_variables.asm',
              'ld [wIcePathSlideHeading], a', 'ld [wUnusedCD37], a')


def test_no_save_compatible_wram_alias_rejected():
    fail_when(WRAM,'wIcePathSlideHeading::\nwUnusedD5A3::',
              'wIcePathSlideHeading::\n\tds 1\nwUnusedD5A3::')


def test_script_guard_removed_rejected():
    fail_when(SLIDE,'bit 7, a ; scripts and scripted hops',
              'bit 0, a ; scripts and scripted hops')


def test_wrong_direction_mapping_rejected():
    fail_when(SLIDE,'.up\n    ld a, D_UP', '.up\n    ld a, D_LEFT')


def test_bank_coordinate_race_rejected():
    fail_when(B1,'push bc\n    ld a, [wYCoord]\n    ld b, a',
              'push bc\n    ld a, [wCurLocalMapID]\n    ld b, a')


def test_live_role_dispatch_region_guard_rejected():
    fail_when(SLIDE,'cp MAP_REGION_JOHTO', 'cp MAP_REGION_KANTO')


def test_overworld_slide_not_started_by_warp_rejected():
    fail_when(SLIDE,'ld a, [wPlayerMovingDirection]', 'ld a, [wPlayerDirection]')


def test_surf_guard_rejected():
    fail_when(SLIDE,'cp 2 ; Surf', 'cp 1 ; Surf')


def test_ice_slide_holds_fixed_foot_pose():
    movement=(ROOT/'engine/overworld/movement.asm').read_text(encoding='utf-8')
    sprite=movement.split('UpdatePlayerSprite:',1)[-1].split('; Sprite foot occlusion',1)[0]
    moving=sprite.split('\n.moving\n',1)[-1].split('\n.animateMovingSprite\n',1)[0]
    assert 'ld a, [wIcePathSlideHeading]' in moving
    assert 'ld [wSpriteStateData1 + 7], a' in moving
    assert 'ld [wSpriteStateData1 + 8], a' in moving
    assert 'jr .calcImageIndex' in moving
    assert sprite.find('ld [wSpriteStateData1 + 9], a') < sprite.find('\n.moving\n')


def test_bicycle_animation_is_not_frozen_by_ice_pose():
    movement=(ROOT/'engine/overworld/movement.asm').read_text(encoding='utf-8')
    sprite=movement.split('UpdatePlayerSprite:',1)[-1].split('; Sprite foot occlusion',1)[0]
    moving=sprite.split('\n.moving\n',1)[-1].split('\n.animateMovingSprite\n',1)[0]
    assert 'ld a, [wWalkBikeSurfState]' in moving
    assert 'jr nz, .animateMovingSprite' in moving


def test_fixed_pose_hook_removal_rejected():
    fail_when('engine/overworld/movement.asm',
              'ld a, [wIcePathSlideHeading]\n\tand a\n\tjr z, .animateMovingSprite',
              'ld a, [wIcePathSlideHeading]\n\tand a\n\tjr nz, .animateMovingSprite')


def test_bicycle_pose_guard_removal_rejected():
    fail_when('engine/overworld/movement.asm',
              'ld a, [wWalkBikeSurfState]\n\tand a\n\tjr nz, .animateMovingSprite',
              'ld a, [wWalkBikeSurfState]\n\tand a\n\tjr z, .animateMovingSprite')


def test_neutral_foot_frame_reset_removal_rejected():
    fail_when('engine/overworld/movement.asm',
              'ld [wSpriteStateData1 + 8], a ; hold neutral foot frame',
              'ld [wSpriteStateData1 + 8], b ; hold neutral foot frame')


def test_frame_zero_is_standing_for_all_four_directions():
    facing=(ROOT/'data/facing.asm').read_text(encoding='utf-8')
    table=facing.split('SpriteFacingAndAnimationTable:',1)[-1].split('\nSpriteFacingDownAndStanding:',1)[0]
    rows=[line.strip() for line in table.splitlines() if line.strip().startswith('dw ')]
    assert len(rows)>=16
    assert all('AndStanding' in rows[i] for i in (0,4,8,12))
    assert all('AndWalking' in rows[i] for i in (1,5,9,13))


def test_neutral_frame_table_corruption_rejected():
    fail_when('data/facing.asm',
              'dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; facing down, walk animation frame 0',
              'dw SpriteFacingDownAndWalking, SpriteOAMParameters         ; facing down, walk animation frame 0')
