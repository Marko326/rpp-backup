"""DEV-324 Route44 source-level seam/geometry regression and negative probes."""
from pathlib import Path
import sys
import pytest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_route44_324_audit import audit


def test_current_route44_is_safe():
    result=audit(ROOT)
    assert result['status']=='PASS_STATIC_ONLY', result['errors']


@pytest.mark.parametrize('path,old,new,error',[
    ('data/johto_east_runtime_300.asm','cp 8\n    jp c, .closed\n    cp 10\n    jp c, .open\n    cp 11\n    jp z, .closed',
     'cp 7\n    jp c, .closed\n    cp 10\n    jp c, .open\n    cp 11\n    jp z, .closed',
     'route44_seam_guard_excludes_y0_and_y10'),
    ('data/johto_east_runtime_300.asm','jp .route44SeamY','jp .closed','mahogany_east_uses_same_seam_guard'),
    ('data/johto_route44_runtime_324.asm','db WEST | EAST ; DEV-326 Gold physical seam; IcePath cave still sealed',
     'db WEST ; dropped east visual preview', 'route44_east_visual_only_header'),
    ('data/johto_pilot_source_resources.asm',
     'JOHTO_ROUTE_44_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID',
     'JOHTO_ROUTE_44_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID',
     'route44_source_both_directions'),
    ('data/johto_east_runtime_300.asm',
     'cp JOHTO_ROUTE_44_WIDTH * 2 - 1\n    ret c\n    ; Gold Route44 eastern boundary is dry across all 18 rows.\n    jp .open',
     'cp JOHTO_ROUTE_44_WIDTH * 2 - 1\n    ret c\n    ; Gold Route44 eastern boundary is dry across all 18 rows.\n    jp .closed',
     'route44_north_south_closed_east_now_connected'),
    ('data/johto_east_runtime_300.asm',
     '.route44North\n    ld a, [wYCoord]\n    and a\n    jp z, .closed',
     '.route44North\n    ld a, [wYCoord]\n    and a\n    jp z, .open',
     'route44_north_south_closed_east_now_connected'),
    ('data/johto_east_runtime_300.asm',
     'cp JOHTO_ROUTE_44_HEIGHT * 2 - 1\n    jp nc, .closed',
     'cp JOHTO_ROUTE_44_HEIGHT * 2 - 1\n    jp nc, .open',
     'route44_north_south_closed_east_now_connected'),
    ('engine/johto_land_collision_gateway_272.asm',
     'cp JOHTO_ROUTE_44_LOCAL_ID\n    jr c, .afterEastSouth',
     'cp JOHTO_ROUTE_44_LOCAL_ID\n    jr c, .legacy',
     'route44_gold_role_dispatch'),
],ids=['widen-seam','wrong-mahogany-return','remove-east-preview','block-east-exit','open-north-exit','open-south-exit','drop-west-registry','skip-roles'])
def test_source_mutation_detected(path,old,new,error):
    src=(ROOT/path).read_text()
    assert old in src
    result=audit(ROOT,{path:src.replace(old,new,1)})
    assert error in result['errors'], result


def test_wrong_runtime_map_blocks_detected():
    p='maps/johto_pilot/Route44.runtime.blk'
    b=bytearray((ROOT/p).read_bytes()); b[3]^=1
    assert 'route44_exact_original_blocks' in audit(ROOT,{p:bytes(b)})['errors']


def test_water_role_corruption_detected():
    p='maps/johto_pilot/Route44.roles.bin'
    b=bytearray((ROOT/p).read_bytes()); b[b.index(2)] = 0
    assert 'route44_quadrants_water' in audit(ROOT,{p:bytes(b)})['errors']


def test_missing_blackthorn_east_preview_fails_even_if_route44_terrain_is_correct():
    path='maps/johto_pilot/BlackthornCity.east_preview.blk'
    bad=bytearray((ROOT/path).read_bytes());bad[20*12+1] ^= 1
    assert 'route44_gold_east_preview_data' in audit(ROOT,{path:bytes(bad)})['errors']


def test_missing_east_strip_fails_without_opening_east_connection():
    path='data/johto_route44_runtime_324.asm'
    src=(ROOT/path).read_text()
    assert 'dw JohtoRoute44EastBlackthornPreview + 9 * 20' in src
    bad=src.replace('dw JohtoRoute44EastBlackthornPreview + 9 * 20',
                    'dw JohtoRoute44Blocks + 9 * JOHTO_ROUTE_44_WIDTH',1)
    assert 'route44_east_visual_only_header' in audit(ROOT,{path:bad})['errors']


def test_duplicate_blackthorn_physical_connection_rejected():
    path='data/johto_pilot_source_resources.asm'
    src=(ROOT/path).read_text()
    bad=src.replace('JohtoPilotSourceConnectionsEnd::',
        '    db MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID\nJohtoPilotSourceConnectionsEnd::',1)
    assert 'route44_source_both_directions' in audit(ROOT,{path:bad})['errors']
