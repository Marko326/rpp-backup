"""REF349 Stage 2: strict Gold Dark Cave role/warp/Surf runtime contracts.
No ROM build or phone behavior is implied.
"""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_dark_cave_stage2_audit import check
ROOT=Path(__file__).resolve().parents[2]

def test_exact_gold_route_and_surface():
    assert not check(ROOT)

def test_mutation_role_byte_is_rejected():
    rel='data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin'
    raw=bytearray((ROOT/rel).read_bytes());raw[2*40+2]^=1
    assert check(ROOT,{rel:bytes(raw)})

def test_mutation_route_warp_table_is_rejected():
    rel='engine/johto_pilot_runtime.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('JOHTO_ROUTE_31_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID','JOHTO_ROUTE_31_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',1)})

def test_mutation_flash_palette_restore_is_rejected():
    rel='engine/johto_pilot_runtime.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('ld a, 12 ; FadePal4 - FadePalJohtoDark349, BG dark / OBJ normal','ld a, 0 ; wrong dark cave palette',1)})

def test_mutation_missing_hop_is_rejected():
    rel='engine/overworld/ledges.asm';src=(ROOT/rel).read_text()
    k='JohtoDarkCaveGoldHops:'; assert k in src
    head,tail=src.split(k,1);assert 'PLAYER_DIR_DOWN' in tail
    assert check(ROOT,{rel:head+k+tail.replace('PLAYER_DIR_DOWN','PLAYER_DIR_UP',1)})

def test_mutation_surftile_dispatch_is_rejected():
    rel='engine/johto_violet_field_skills.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('callab JohtoDarkCaveWaterAhead','callab JohtoFakeWaterAhead',1)})

def test_mutation_open_unapproved_exit_is_rejected():
    rel='data/johto_dark_cave_stage/REF349_stage2_runtime.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('db $ff, $ff, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                                      'db 1, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR',1)})


def test_mutation_untrimmed_graphics_length_assert_is_rejected():
    rel='data/johto_dark_cave_stage/REF349_stage2_runtime.asm';src=(ROOT/rel).read_text()
    assert 'ASSERT @ - JohtoDarkCave_GFX == 65 * 16' in src
    assert check(ROOT,{rel:src.replace('== 65 * 16','== 96 * 16',1)})


def test_gold_nite_palette_mutation_is_rejected():
    rel='color/data/map_palette_sets.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('db CAVE_GRAY, CAVE_RED, CAVE_GREEN, CAVE_BLUE\n    db CAVE_YELLOW, CAVE_BROWN, CAVE_LIGHT_BLUE, CRYS_TEXTBOX\nMapPaletteSetsEnd::',
                 'db OUTDOOR_GRAY, OUTDOOR_RED, OUTDOOR_GREEN, OUTDOOR_BLUE\n    db OUTDOOR_YELLOW, OUTDOOR_BROWN, OUTDOOR_ROOF, CRYS_TEXTBOX\nMapPaletteSetsEnd::',1)})


def test_missing_route31_automatic_exit_step_is_rejected():
    rel='engine/johto_pilot_runtime.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp 34\n    jr nz, .notRoute31CaveArrival349',
                                     'cp 35\n    jr nz, .notRoute31CaveArrival349',1)})


def test_flash_in_normal_map_is_rejected():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\n    jr nz, .notDark',
                                     'cp JOHTO_ROUTE_31_LOCAL_ID\n    jr nz, .notDark',1)})


def test_flash_reusable_on_already_lit_cave_is_rejected():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    old='cp 12 ; Johto unlit Dark Cave BG / visible OBJ'
    assert old in src
    assert check(ROOT,{rel:src.replace(old, 'cp 0 ; wrong: already-lit cave',1)})


def test_kanto_flash_wrong_map_rejected():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    old='cp ROCK_TUNNEL_2'
    assert old in src
    assert check(ROOT,{rel:src.replace(old, 'cp ROUTE_10',1)})


def test_kanto_flash_wrong_dark_palette_rejected():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    old='cp 6 ; Kanto unlit Rock Tunnel BG / OBJ'
    assert old in src
    assert check(ROOT,{rel:src.replace(old, 'cp 0 ; incorrectly allowing lit caves',1)})


def test_flash_bank4_gate_is_required():
    rel='engine/menu/start_sub_menus.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('callab JohtoFlashEligibility349', 'callab JohtoOtherFlashEligibility349',1)})


def test_surf_hop_shore_omission_is_rejected():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp 5 ; HOP_LEFT is land unless moving against the ledge',
                                     'cp 1 ; incorrectly treating HOP_LEFT as WALL',1)})


def test_surf_direction_guard_omission_is_rejected():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp PLAYER_DIR_RIGHT\n    ret z\n.land',
                                     'cp PLAYER_DIR_LEFT\n    ret z\n.land',1)})


def test_future_same_tileset_warp_guard_is_required():
    rel='data/dungeon_tilesets.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace(', JOHTO_DARK_CAVE, $FF', ', $FF',1)})


# Tests added after the user's Gold-vs-RPP recording exposed invisible player
# sprites and a full-purple cave frame during the Gold white-fade transition.
def test_darkness_palette_leaves_sprite_visible_in_gbc():
    rel='home/fade.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('FadePalJohtoDark349:: db %11111110, %11100100, %11100100',
                                       'FadePalJohtoDark349:: db %11111110, %11111110, %11111110',1)})

def test_darkness_does_not_recolor_legacy_rock_tunnel():
    rel='home/fade.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('FadePal2:: db %11111110, %11111110, %11111110',
                                       'FadePal2:: db %11111110, %11100100, %11100100',1)})

def test_entry_uses_shared_cave_black_fade_and_safe_loader():
    rel='home/overworld.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('call GBFadeOutToBlackDarkBG353',
                                       'call GBFadeOutToWhite',1)})

def test_exit_must_not_brighten_dark_cave():
    rel='home/overworld.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('call GBFadeOutToBlackAlreadyDark353',
                                       'call GBFadeOutToBlack',1)})

def test_registered_exit_must_not_force_white_before_fade():
    rel='engine/johto_pilot_runtime.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('    ; REF-353: do not force the source cave white.',
                                       '    ld [rBGP], a ; REF-353: do not force the source cave white.',1)})

def test_pre_lcd_palette_must_run_before_enable_lcd():
    rel='home/overworld.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('callab JohtoDarkCavePreLCDPalette349\n\n\tld a,$01',
                                       'nop\n\n\tld a,$01',1)})

def test_pre_lcd_palette_must_clear_only_after_exit():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('jr z, .apply\n    ; Deferred exit clear:',
                                       'jr nz, .apply\n    ; Deferred exit clear:',1)})

# REF349 third hotfix: these assertions cover the previously untested
# two-step landing *and* the Surf state lifecycle, not merely 26 entries.
def test_all_gold_hops_cross_wall_then_reach_nonwall():
    roles=(ROOT/'data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin').read_bytes()
    paths=[]
    for y in range(36):
        for x in range(40):
            role=roles[y*40+x]
            if role not in (4,5):
                continue
            dx,dy=(0,1) if role==4 else (-1,0)
            assert roles[(y+dy)*40+x+dx]==1
            assert roles[(y+2*dy)*40+x+2*dx] not in (1,7)
            paths.append((x,y,dx,dy))
    assert len(paths)==26
    # The two WATER-to-HOP_LEFT disembarks should not start a ledge jump.
    for y in (12,13):
        assert roles[y*40+8]==2
        assert roles[y*40+7]==5
        assert (7,y,-1,0) in paths
        assert (8,y,-1,0) not in paths


def test_previous_one_cell_early_hop_registration_is_rejected():
    rel='engine/overworld/ledges.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('db 2, 10, PLAYER_DIR_DOWN',
                                       'db 2, 9, PLAYER_DIR_DOWN',1)})


def test_previous_water_edge_false_hop_is_rejected():
    rel='engine/overworld/ledges.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('db 7, 12, PLAYER_DIR_LEFT',
                                       'db 8, 12, PLAYER_DIR_LEFT',1)})


def test_surf_sprite_loader_must_not_clear_indoor_cave_state():
    rel='home/overworld.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp JOHTO_DARK_CAVE\n\tjr nz, .startWalking',
                                       'cp JOHTO_UNION_CAVE\n\tjr nz, .startWalking',1)})


def test_surf_sprite_loader_requires_active_mount_not_all_indoor():
    rel='home/overworld.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp 2\n\tjr z, .determineGraphics',
                                       'cp 1\n\tjr z, .determineGraphics',1)})


def test_party_summary_return_must_preserve_cave_surf():
    rel='engine/menu/summary_return_helpers.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('cp JOHTO_DARK_CAVE\n\tjr nz, .startWalking',
                                       'cp JOHTO_PILOT\n\tjr nz, .startWalking',1)})


def test_surfboard_dismount_uses_gold_terrain_not_empty_tile_list():
    rel='engine/items/items.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('callab JohtoDarkCaveSurfDecision',
                                       'callab JohtoDarkCaveWaterAhead',1)})


def test_surfboard_dismount_must_not_accept_water():
    rel='engine/items/items.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('ld a, e\n\tand a\n\tjr z, .stopSurfing',
                                       'ld a, e\n\tcp 2\n\tjr z, .stopSurfing',1)})


def test_johto_fog_surf_badge_required_without_legacy_compatibility():
    rel='engine/johto_dark_cave_stage2.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('bit 3, a ; Fog Badge',
                                       'bit 0, a ; incorrect Zephyr Badge',1)})


def test_both_surf_entrypoints_use_same_permission():
    rel='engine/overworld/field_moves.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('callab JohtoSurfBadgeAllowed349',
                                       'callab JohtoFlashEligibility349',1)})
    rel='engine/menu/start_sub_menus.asm';src=(ROOT/rel).read_text()
    assert check(ROOT,{rel:src.replace('callab JohtoSurfBadgeAllowed349',
                                       'callab JohtoFlashEligibility349',1)})


def test_ledge_gateway_does_not_preempt_gold_hop_wall():
    src=(ROOT/'engine/johto_pilot_runtime.asm').read_text()
    segment=src.split('\n.darkCaveClosedEdge\n',1)[1].split('\n.unionCaveClosedEdge\n',1)[0]
    bad='    ld e, 0\n    callab JohtoDarkCaveLandDecision\n    ret\n'
    assert check(ROOT, overrides={'engine/johto_pilot_runtime.asm':src.replace(segment,bad)})


def test_ledge_gateway_checks_both_bounds():
    src=(ROOT/'engine/johto_pilot_runtime.asm').read_text()
    p='engine/johto_pilot_runtime.asm'
    assert check(ROOT, overrides={p:src.replace('cp JOHTO_DARK_CAVE_HEIGHT * 2 - 1',
                                                    'cp JOHTO_ROUTE_31_HEIGHT * 2 - 1')})
    assert check(ROOT, overrides={p:src.replace('cp JOHTO_DARK_CAVE_WIDTH * 2 - 1',
                                                    'cp JOHTO_ROUTE_31_WIDTH * 2 - 1')})


def test_dark_cave_hop_must_run_before_land_collision():
    p='engine/johto_land_collision_gateway_272.asm'
    src=(ROOT/p).read_text()
    old='    callab HandleLedges\n    ld a, [wd736]\n    bit 6, a\n    jr nz, .allowJump\n    callab JohtoDarkCaveLandDecision'
    new='    callab JohtoDarkCaveLandDecision\n    ld a, [wd736]\n    bit 6, a\n    jr nz, .allowJump\n    callab HandleLedges'
    assert old in src
    assert check(ROOT, overrides={p:src.replace(old,new)})


# REF-349 stage3: physical two-exit Warp and gate behavior regression checks.
def test_route46_warp_ordinals_and_door_bidirectionality():
    assert not check(ROOT)
    rel = 'data/johto_south_chain_runtime_328.asm'
    src = (ROOT / rel).read_text()
    assert check(ROOT, {rel: src.replace('db 5, 14, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                                         'db 5, 14, 1, JOHTO_REGISTERED_WARP_SELECTOR', 1)})

def test_route46_cave_down_carpet_is_required():
    rel = 'engine/johto_pilot_runtime.asm'
    src = (ROOT / rel).read_text()
    old = 'cp 35\n    ret nz\n    ld a, [wYCoord]\n    cp 33'
    assert old in src
    assert check(ROOT, {rel: src.replace(old, old.replace('cp 35', 'cp 34'), 1)})

def test_blackthorn_warp_ordinal_stays_sealed():
    rel = 'engine/johto_pilot_runtime.asm'
    src = (ROOT / rel).read_text()
    needle = 'db MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID'
    assert needle in src
    assert check(ROOT, {rel: src.replace(needle, needle.replace(', 2,', ', 1,'), 1)})

def test_route46_door_profile_removal_is_rejected():
    from johto_vertical_gate_runtime_314 import audit
    rel = 'data/johto_vertical_gate_runtime_314.asm'
    src = (ROOT / rel).read_text()
    row = '    db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_UP, 14, 6\n'
    assert row in src
    assert audit(ROOT, text_overrides={rel: src.replace(row, '', 1)})['status'] == 'FAIL'


# REF-349 map-opening checklist: Gold permits cycling in CAVE on FLOOR.
def test_dark_cave_bike_gold_floor_and_cave_state():
    assert not check(ROOT)
    roles=(ROOT/'data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin').read_bytes()
    allowed={i for i,role in enumerate(roles) if role in (0,6)}
    assert len(allowed)==1012
    for value in (1,2,3,4,5,7):
        assert all(i not in allowed for i,r in enumerate(roles) if r==value)


def test_bike_identity_is_required_not_global_tileset():
    rel='home/rom0_relief_349.asm'
    s=(ROOT/rel).read_text()
    assert check(ROOT,{rel:s.replace('cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',
                                     'cp JOHTO_UNION_CAVE_1F_LOCAL_ID',1)})


def test_bike_from_indoors_must_keep_existing_mount():
    rel='home/rom0_relief_349.asm'
    s=(ROOT/rel).read_text()
    assert check(ROOT,{rel:s.replace('cp 1\n\tjr z, .allowed\n\tcallab JohtoDarkCaveBikeFloorAllowed349',
                                     'cp 2\n\tjr z, .allowed\n\tcallab JohtoDarkCaveBikeFloorAllowed349',1)})


def test_bike_must_reach_gold_floor_handler():
    rel='home/rom0_relief_349.asm'
    s=(ROOT/rel).read_text()
    assert check(ROOT,{rel:s.replace('callab JohtoDarkCaveBikeFloorAllowed349',
                                     'callab JohtoDarkCaveWaterAhead',1)})


def test_bike_mount_must_reject_hop_tile():
    rel='engine/johto_dark_cave_stage2.asm'
    s=(ROOT/rel).read_text()
    assert check(ROOT,{rel:s.replace('cp 6 ; WARP_CARPET_DOWN ($70)',
                                     'cp 4 ; incorrectly admits HOP_DOWN',1)})


def test_bike_mount_must_reject_wrong_region():
    rel='engine/johto_dark_cave_stage2.asm'
    s=(ROOT/rel).read_text()
    assert check(ROOT,{rel:s.replace('cp MAP_REGION_JOHTO\n    jr nz, .deny',
                                     'cp MAP_REGION_KANTO\n    jr nz, .deny',1)})


def test_unsafe_escape_rope_tileset_exception_is_rejected():
    rel='engine/items/items.asm'
    s=(ROOT/rel).read_text()
    assert check(ROOT,{rel:s.replace('db FOREST,CEMETERY,INTERIOR,CAVERN,FACILITY,SAFARI,ICE_CAVERN,$FF',
                                     'db FOREST,CEMETERY,INTERIOR,CAVERN,FACILITY,SAFARI,ICE_CAVERN,JOHTO_DARK_CAVE,$FF',1)})
