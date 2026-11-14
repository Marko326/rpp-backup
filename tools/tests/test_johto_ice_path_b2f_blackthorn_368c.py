"""REF368C Blackthorn B2F Gold stage: positive and mutation regression checks."""
from pathlib import Path
from tools.johto_ice_path_b2f_blackthorn_368c_audit import audit
ROOT=Path(__file__).resolve().parents[2]
SRC='data/johto_ice_path_stage/ice_path_b2f_blackthorn_runtime_368c.asm'

def reject(path,old,new,expected):
    original=(ROOT/path).read_text()
    assert old in original, (path,old)
    result=audit(ROOT,{path:original.replace(old,new,1)})
    assert any(expected in error for error in result),result

def test_new_blackthorn_map_review():
    assert audit(ROOT)==[]

def test_gold_warp1_guard():
    reject(SRC,'db 15, 3, 7, JOHTO_REGISTERED_WARP_SELECTOR',
           'db 15, 3, 6, JOHTO_REGISTERED_WARP_SELECTOR','warp objects')

def test_gold_warp2_guard():
    reject(SRC,'db 3, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR',
           'db 3, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR','warp objects')

def test_lost_b3f_return_route():
    reject('engine/johto_pilot_runtime.asm',
           'db MAP_REGION_JOHTO, JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ICE_PATH_B3F_LOCAL_ID',
           '; removed return', 'reciprocal route')

def test_corrupt_block_detected():
    src='maps/johto_ice_path_stage/IcePathB2FBlackthornSide.runtime.blk'
    b=bytearray((ROOT/src).read_bytes()); b[0]^=1
    assert any('.blk divergence' in s for s in audit(ROOT,{src:bytes(b)}))

def test_wrong_gold_ledge_role():
    src='data/johto_ice_path_stage/IcePathB2FBlackthornSide.roles.bin'
    b=bytearray((ROOT/src).read_bytes()); b[8*10+5]=1
    assert any('role' in s for s in audit(ROOT,{src:bytes(b)}))

def test_missing_hop_left_guard():
    reject('engine/overworld/ledges.asm','db 5, 8, PLAYER_DIR_LEFT',
           'db 5, 8, PLAYER_DIR_RIGHT','directional ledge table')

def test_missing_step_in_dispatch():
    reject('engine/johto_pilot_runtime.asm',
           'cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID\n    jr z, .unionCaveLadder342',
           'cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID\n    jr z, .notBlackthorn',
           'STEP_IN')

def test_wrong_bike_floor():
    reject('home/rom0_relief_349.asm','callab JohtoIcePathB2FBlackthornBikeFloorAllowed368C',
           'callab JohtoIcePathB3FBikeFloorAllowed368B','bike public')

def test_no_live_header():
    reject('main.asm', 'INCLUDE "data/johto_ice_path_stage/ice_path_b2f_blackthorn_runtime_368c.asm"',
           '; missing Blackthorn include','registration incomplete')

def test_wrong_music_slot():
    reject('engine/menu/options_menu.asm','slot69 Ice Path B2F Blackthorn temporary cave theme',
           'slot69 Missing B2F','Town Map / music')
