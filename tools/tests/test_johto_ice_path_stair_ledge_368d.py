"""REF368D regression: Gold stair & two-map hop, field-use and cave escape."""
from pathlib import Path
from tools.johto_ice_path_stair_ledge_368d_audit import audit

ROOT = Path(__file__).resolve().parents[2]


def mutate(path: str, original: str, replacement: str, expected: str):
    source = (ROOT / path).read_text()
    assert original in source, (path, original)
    output = audit(ROOT, {path: source.replace(original, replacement, 1)})
    assert any(expected in error for error in output), output


def test_all_five_maps_gold_bicycle_hops_and_escape():
    assert audit(ROOT) == []


def test_b1f_eighth_stair_cannot_overlap_seventh():
    mutate('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm',
           'db 27, 11, 0, JOHTO_REGISTERED_WARP_SELECTOR',
           'db 25, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR',
           'IcePathB1F live Warp cell/ordinal')


def test_b1f_eighth_stair_collision_must_release_gold_cell():
    mutate('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm',
           '.ladder11\n    cp 11 ; Gold #8', '.ladder11\n    cp 10 ; Gold #8',
           'LADDER wall/collision')


def test_1f_ledge_left_entry_cannot_turn_right():
    mutate('engine/overworld/ledges.asm', 'db 35, 16, PLAYER_DIR_LEFT',
           'db 35, 16, PLAYER_DIR_RIGHT', 'IcePath1F full Gold directed HOP')


def test_1f_ledge_down_entry_cannot_be_removed():
    mutate('engine/overworld/ledges.asm', 'db 37, 16, PLAYER_DIR_DOWN',
           'db 37, 16, PLAYER_DIR_RIGHT', 'IcePath1F full Gold directed HOP')


def test_blackthorn_ledge_left_entry_also_checked():
    mutate('engine/overworld/ledges.asm', 'db 5, 8, PLAYER_DIR_LEFT',
           'db 5, 8, PLAYER_DIR_RIGHT', 'IcePathB2FBlackthornSide full Gold directed HOP')


def test_1f_ledge_must_use_actual_player_gateway():
    mutate('engine/johto_land_collision_gateway_272.asm',
           'bit 6, a\n    jr nz, .allowJump\n    callab JohtoIcePath1FLandDecision367F',
           'bit 5, a\n    jr nz, .allowJump\n    callab JohtoIcePath1FLandDecision367F',
           'HOP not connected')


def test_1f_dispatch_must_be_present():
    mutate('engine/overworld/ledges.asm',
           'cp JOHTO_ICE_PATH_1F_LOCAL_ID\n    jr z, .icePath1FHops368D',
           'cp JOHTO_ICE_PATH_1F_LOCAL_ID\n    ret z', 'native HandleLedges dispatcher')


def test_public_bicycle_item_cannot_lack_1f_entry():
    mutate('home/rom0_relief_349.asm',
           'callab JohtoIcePath1FBikeFloorAllowed367J',
           'callab JohtoIcePathB1FBikeFloorAllowed367K',
           'public Bicycle must retain')


def test_rope_must_be_usable_through_public_handler():
    mutate('engine/items/items.asm',
           'callab JohtoIcePathEscapeAllowed368D\n    ret',
           'callab JohtoDarkCaveEscapeAllowed365\n    ret',
           'public item usability')


def test_rope_must_return_to_saved_exterior():
    mutate('engine/fly_town_map_helpers.asm',
           'callab JohtoIcePathApplyEscape368D',
           'callab JohtoDarkCaveApplyEscape365',
           'special warp / original exterior')


def test_route44_cave_mouth_cannot_be_rope_landing():
    mutate('engine/johto_ice_path_escape_368d.asm',
           'FLYWARP_DATA JOHTO_ROUTE_44_WIDTH, 8, 56',
           'FLYWARP_DATA JOHTO_ROUTE_44_WIDTH, 7, 56',
           'safe-floor data')


def test_exterior_source_must_be_recorded_on_entering_1f():
    mutate('engine/johto_pilot_runtime.asm',
           'callab JohtoIcePathRememberOutdoorSource368D',
           'callab JohtoDarkCaveRememberOutdoorSource365',
           'outside-only entrance anchor capture')


def test_uninitialized_anchor_must_not_be_treated_as_valid():
    mutate('engine/johto_ice_path_escape_368d.asm',
           'cp $04\n    jr z, .allow', 'cp $00\n    jr z, .allow',
           'save-backed exterior anchor')


def test_roping_back_to_route44_does_not_change_older_gold_warp():
    source = (ROOT / 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm').read_text()
    assert 'db 25, 5, 3, JOHTO_REGISTERED_WARP_SELECTOR' in source
    assert 'db 27, 11, 0, JOHTO_REGISTERED_WARP_SELECTOR' in source


def test_clean_ref368_keeps_actual_device_long_jump_fixes():
    # Earlier audit expected JR and therefore rejected the user's corrected JP.
    fixes = [
        ('engine/johto_pilot_runtime.asm',
         'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jp z, .unionCaveLadder342',
         'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jr z, .unionCaveLadder342'),
        ('engine/johto_land_collision_gateway_272.asm',
         'bit 6, a\n    jp nz, .allowJump\n    callab JohtoEastSpatialStep',
         'bit 6, a\n    jr nz, .allowJump\n    callab JohtoEastSpatialStep'),
        ('engine/johto_land_collision_gateway_272.asm',
         'bit 6, a\n    jp nz, .allowJump\n    callab JohtoRoute33StepPolicy',
         'bit 6, a\n    jr nz, .allowJump\n    callab JohtoRoute33StepPolicy'),
        ('engine/overworld/ledges.asm',
         'cp JOHTO_MODERN\n\tjp z, .route33Modern',
         'cp JOHTO_MODERN\n\tjr z, .route33Modern'),
        ('engine/overworld/ledges.asm',
         'cp JOHTO_PILOT\n\tjp z, .johtoPilot',
         'cp JOHTO_PILOT\n\tjr z, .johtoPilot'),
    ]
    for path, original, corrupted in fixes:
        mutate(path, original, corrupted, 'REF-368 user long-jump hotfix')
