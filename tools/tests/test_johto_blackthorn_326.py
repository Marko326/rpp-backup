"""DEV-326: the single new active Gold outdoor map must remain source-fail-closed."""
from pathlib import Path
import sys
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_blackthorn_326_audit import audit


def test_blackthorn_current_statically_reviewed():
    result = audit(ROOT)
    assert result['status'] == 'PASS_STATIC_ONLY', result['errors']


@pytest.mark.parametrize('rel,old,new,check', [
    ('data/johto_blackthorn_runtime_326.asm', 'db SOUTH | WEST ; Gold Route45 and Route44 seams physically active',
     'db WEST ; accidentally loses south preview', 'south_preview_and_west_connection'),
    ('data/johto_blackthorn_runtime_326.asm', 'dw JohtoBlackthornSouthRoute45Preview',
     'dw JohtoBlackthornBlocks', 'south_preview_and_west_connection'),
    ('data/johto_blackthorn_runtime_326.asm', '    db 0 ; no people, scripted scenes or plot',
     '    db 1 ; incorrectly enabled event', 'only_gold_center_door_open'),
    ('data/johto_east_runtime_300.asm', 'cp JOHTO_BLACKTHORN_CITY_HEIGHT * 2 - 1\n    ret c',
     'cp JOHTO_BLACKTHORN_CITY_HEIGHT * 2 - 1\n    jp .closed', 'collision_and_sealed_south'),
    ('data/johto_pilot_source_resources.asm', 'JOHTO_BLACKTHORN_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID',
     'JOHTO_BLACKTHORN_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID', 'registered_only_reciprocal_west'),
])
def test_mutated_source_is_detected(rel,old,new,check):
    source=(ROOT/rel).read_text()
    assert old in source
    result=audit(ROOT,overrides={rel:source.replace(old,new,1)})
    assert check in result['errors'], result


def test_bad_south_preview_bytes_rejected():
    rel='maps/johto_pilot/Route45.south_preview.blk'
    data=bytearray((ROOT/rel).read_bytes())
    data[10]^=1
    assert 'south_preview_original_not_trees' in audit(ROOT,overrides={rel:bytes(data)})['errors']


def test_broken_water_role_count_rejected():
    rel='maps/johto_pilot/BlackthornCity.roles.bin'
    data=bytearray((ROOT/rel).read_bytes())
    data[data.index(2)]=0
    assert 'blackthorn_40x36_roles_80_water' in audit(ROOT,overrides={rel:bytes(data)})['errors']
