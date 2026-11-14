"""REF-368B B3F static contracts with deliberate negative error injection."""
from pathlib import Path
from tools.johto_ice_path_b3f_368b_audit import audit

ROOT = Path(__file__).resolve().parents[2]
SRC = 'data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm'

def corrupt(path, old, new, failure):
    original=(ROOT/path).read_text()
    assert old in original
    issues=audit(ROOT,{path:original.replace(old,new,1)})
    assert any(failure in s for s in issues),issues

def test_ice_path_b3f_new_map_review():
    assert audit(ROOT)==[]

def test_second_blackthorn_ladder_must_stay_open():
    corrupt(SRC,'db 5, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR',
            'db $ff, $ff, 1, JOHTO_REGISTERED_WARP_SELECTOR', 'warp table')

def test_primary_gold_ladder_ordinal_must_not_shift():
    corrupt(SRC,'db 5, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 5, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR', 'warp table')

def test_registered_route_missing_rejected():
    f='engine/johto_pilot_runtime.asm'
    before='    db MAP_REGION_JOHTO, JOHTO_ICE_PATH_B3F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID'
    corrupt(f,before,'    ; missing live return route', 'reciprocal route')

def test_gold_block_mutation_rejected():
    path='maps/johto_ice_path_stage/IcePathB3F.runtime.blk'
    orig=bytearray((ROOT/path).read_bytes()); orig[0]^=1
    assert any('block bytes' in e for e in audit(ROOT,{path:bytes(orig)}))

def test_gold_stair_role_corruption_rejected():
    path='data/johto_ice_path_stage/IcePathB3F.roles.bin'
    orig=bytearray((ROOT/path).read_bytes()); orig[5*20+3]=1
    assert any('Gold role' in e or 'LADDER' in e for e in audit(ROOT,{path:bytes(orig)}))

def test_bike_public_entry_missing_rejected():
    corrupt('home/rom0_relief_349.asm','callab JohtoIcePathB3FBikeFloorAllowed368B',
            'callab JohtoIcePathB2FMahoganyBikeFloorAllowed368A', 'collision/bike public')

def test_wrong_floor_sign_rejected():
    corrupt('engine/overworld/map_name_sign.asm','ld b, $83 ; B3F','ld b, $82 ; B3F','map-sign')

def test_blackthorn_accidental_activation_rejected():
    f='data/johto_header_descriptors.asm'
    corrupt(f,'dw JohtoIcePathB2FBlackthornRuntimeHeader368C', 'dw JohtoIcePathB2FBlackthornFake', 'B3F must connect')

def test_missing_header_rejected():
    corrupt('main.asm','INCLUDE "data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm"',
            '; B3F include removed','header/descriptor/source/main')


def test_b3f_hotfixed_long_jump_must_not_regress_to_short():
    corrupt('engine/johto_pilot_runtime.asm',
            'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jp z, .unionCaveLadder342',
            'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jr z, .unionCaveLadder342',
            'stationary arrival / STEP_IN / boundary')
