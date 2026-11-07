"""DEV-321 Lake anti-airwall/fault-injection tests; developer-facing only."""
from pathlib import Path
import sys
import pytest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_lake_of_rage_321_audit import audit


def text(path): return (ROOT/path).read_text()
def raw(path): return (ROOT/path).read_bytes()

def test_clean_lake_contract():
    r=audit(ROOT)
    assert r['status']=='PASS_STATIC_ONLY', r['errors']
    assert r['seam_route43_x']==[0,8,9,10,11]
    assert r['lake_water_cells']==300

CASES=[
 ('drop_route43_x0_lane','data/johto_east_runtime_300.asm','and a\n    jp z, .open','and a\n    jp z, .closed','Route43_north_guard_matches_exact_five'),
 ('widen_route43_lane','data/johto_east_runtime_300.asm','cp 8\n    jp c, .closed','cp 7\n    jp c, .closed','Route43_north_guard_matches_exact_five'),
 ('wrong_lake_offset','data/johto_lake_of_rage_321.asm','db -10','db -8','Lake_Gold_south_connection_record'),
 ('drop_source_reciprocal','data/johto_pilot_source_resources.asm','JOHTO_LAKE_OF_RAGE_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID','JOHTO_LAKE_OF_RAGE_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID','source_registry_reciprocal_R43_Lake'),
 ('remove_land_dispatch','engine/johto_land_collision_gateway_272.asm','cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\n    jr z, .eastMap','cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\n    jr z, .route33','Lake_land_gateway_uses_exact_east_role_grid'),
 ('remove_surf_dispatch','engine/johto_violet_field_skills.asm','cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\n    jp z, .eastRoute42','cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\n    jp z, .legacy','Lake_Surf_routes_to_east_spatial'),
 ('remove_cut','engine/johto_violet_field_skills.asm','db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 4, 23, $5b','db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 4, 22, $5b','Lake_five_Cut_trees_and_postCut_walkability'),
 ('remove_hop','engine/overworld/ledges.asm','db 4, 28, PLAYER_DIR_DOWN','db 3, 28, PLAYER_DIR_DOWN','Lake_six_Gold_down_hops'),
 ('invert_spatial_allow_result','data/johto_east_runtime_300.asm','.allow\n    ld e, 0\n    ret','.allow\n    ld e, 1\n    ret','Lake_spatial_step_allow_and_block_return_codes'),
 ('invert_spatial_block_result','data/johto_east_runtime_300.asm','.block\n    ld e, 1\n    ret','.block\n    ld e, 0\n    ret','Lake_spatial_step_allow_and_block_return_codes'),
 ('skip_spatial_allow_branch','data/johto_east_runtime_300.asm','and a\n    jr z, .allow\n    cp 1','and a\n    jr z, .block\n    cp 1','Lake_spatial_step_branches_reach_named_outcomes'),
 ('premature_return_before_role_lookup','data/johto_east_runtime_300.asm','ret c\n    call JohtoEastSpatialRoleAhead','ret\n    call JohtoEastSpatialRoleAhead','Lake_spatial_step_role_call_and_decision_order'),
 ('ignore_role_grid_result','data/johto_east_runtime_300.asm','call JohtoEastSpatialRoleAhead\n    ld a, e','call JohtoEastSpatialRoleAhead\n    xor a','Lake_spatial_step_role_call_and_decision_order'),
]

@pytest.mark.parametrize('name,path,old,new,detector',CASES,ids=[x[0] for x in CASES])
def test_text_faults_detected(name,path,old,new,detector):
    s=text(path); assert old in s
    r=audit(ROOT,{path:s.replace(old,new,1)})
    assert detector in r['errors'], (name,r['errors'])

def test_water_fault_detected():
    path='maps/johto_pilot/LakeOfRage.roles.bin'
    b=bytearray(raw(path)); i=b.index(2); b[i]=0
    r=audit(ROOT,{path:bytes(b)})
    assert 'Lake_exact_300_water_roles' in r['errors']

def test_house_airwall_policy_fault_detected():
    path='maps/johto_pilot/LakeOfRage.roles.bin'
    b=bytearray(raw(path)); assert b[3*40+7]==1; b[3*40+7]=0
    r=audit(ROOT,{path:bytes(b)})
    assert 'Lake_houses_stay_solid' in r['errors']

def test_seam_role_fault_detected():
    path='maps/johto_pilot/LakeOfRage.roles.bin'
    b=bytearray(raw(path)); assert b[35*40+18]==0; b[35*40+18]=1
    r=audit(ROOT,{path:bytes(b)})
    assert 'Gold_reciprocal_land_seam_exact_five' in r['errors']


def test_older_release_marker_cannot_pass_current_lake_gate():
    path='data/game_version.asm'
    source=text(path)
    import re
    match=re.search(r'(?m)^\s*db "REF-(\d{3})([A-Z]?)@"\s*$',source)
    assert match
    mutated=source[:match.start()] + 'db "REF-310@"' + source[match.end():]
    result=audit(ROOT,{path:mutated})
    assert 'REF319_same_length_version_label' in result['errors']
