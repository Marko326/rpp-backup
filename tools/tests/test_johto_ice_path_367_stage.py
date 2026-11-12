"""REF-367A resource-stage integrity and mutation-resistant proof."""
from pathlib import Path
import json
import shutil

from tools.johto_ice_path_367_stage_audit import audit, CONTRACT

ROOT = Path(__file__).resolve().parents[2]


def test_stage_unmodified_passes():
    assert audit(ROOT) == []


def setup_copy(tmp_path):
    contract = json.loads((ROOT/CONTRACT).read_text(encoding='utf8'))
    files = [*contract['assets'], CONTRACT,
             'constants/region_map_constants.asm',
             'data/johto_header_descriptors.asm',
             'data/game_version.asm']
    for rel in files:
        p = tmp_path/rel
        p.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/rel,p)
    return contract


def test_bad_ice_role_caught(tmp_path):
    setup_copy(tmp_path)
    file = tmp_path/'data/johto_ice_path_stage/IcePath1F.roles.bin'
    data=bytearray(file.read_bytes());data[0]^=1;file.write_bytes(data)
    issues=audit(tmp_path)
    assert any('sha256 mismatch' in e for e in issues)
    assert any('role grid diverges' in e for e in issues)


def test_bad_landing_trigger_caught(tmp_path):
    data=setup_copy(tmp_path)
    warps=next(m for m in data['maps'] if m['name']=='IcePathB2FMahoganySide')['warps']
    assert sum(w['role']=='ICE' for w in warps)==4
    next(w for w in warps if w['role']=='ICE')['trigger']='STEP_IN_IMMEDIATE'
    (tmp_path/CONTRACT).write_text(json.dumps(data),encoding='utf8')
    assert any('ICE arrival-only' in e for e in audit(tmp_path))


def test_bad_target_warp_caught(tmp_path):
    data=setup_copy(tmp_path)
    next(m for m in data['maps'] if m['name']=='IcePathB1F')['warps'][1]['destination_warp_1_based']=2
    (tmp_path/CONTRACT).write_text(json.dumps(data),encoding='utf8')
    assert any('reciprocal Gold destination' in e for e in audit(tmp_path))


def test_cannot_enable_incomplete_map(tmp_path):
    setup_copy(tmp_path)
    f=tmp_path/'constants/region_map_constants.asm'
    f.write_text(f.read_text().replace('DEF NUM_JOHTO_ACTIVE_MAPS EQU 67','DEF NUM_JOHTO_ACTIVE_MAPS EQU 70'))
    assert any('only Ice Path 1F and B1F walk pilots should activate' in e for e in audit(tmp_path))


def test_bad_external_door_caught(tmp_path):
    data=setup_copy(tmp_path)
    data['outside_warps'][0]['x']=55
    (tmp_path/CONTRACT).write_text(json.dumps(data),encoding='utf8')
    assert any('outdoor entry locations' in e for e in audit(tmp_path))


def test_bad_gold_block_caught(tmp_path):
    setup_copy(tmp_path)
    f=tmp_path/'maps/johto_ice_path_stage/IcePathB1F.gold.blk'
    data=bytearray(f.read_bytes());data[1]^=1;f.write_bytes(data)
    assert any('sha256 mismatch' in e for e in audit(tmp_path))
