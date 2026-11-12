"""REF-367D native ICE-heading state and defensive mutation tests."""
from pathlib import Path
import shutil
from tools.johto_ice_path_367_slide_audit import audit, SLIDE, CORE, GOLD
from tools.johto_ice_path_367_native_audit import execute, parse_asm, HEADING

ROOT=Path(__file__).resolve().parents[2]


def copy_fixture(dst:Path):
    for rel in (str(SLIDE),str(CORE),str(GOLD),'main.asm','home/overworld.asm'):
        p=dst/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/rel,p)
    for name in ('IcePath1F','IcePathB1F','IcePathB2FMahoganySide',
                 'IcePathB2FBlackthornSide','IcePathB3F'):
        rel=f'data/johto_ice_path_stage/{name}.roles.bin'
        shutil.copyfile(ROOT/rel,dst/rel)


def test_gold_native_slide_heading_comprehensive():
    assert audit(ROOT)==[]


def test_incorrect_ice_role_is_detected(tmp_path):
    copy_fixture(tmp_path)
    p=tmp_path/SLIDE
    original=p.read_text()
    change=original.replace('    cp 2\n    jr nz, .idle','    cp 3\n    jr nz, .idle')
    assert change!=original
    p.write_text(change)
    assert audit(tmp_path)


def test_forced_heading_must_not_use_live_input(tmp_path):
    copy_fixture(tmp_path)
    p=tmp_path/SLIDE
    original=p.read_text();change=original.replace('    ld d, e\n    call JohtoIcePathContinueSlide367C','    ld d, b\n    call JohtoIcePathContinueSlide367C')
    assert change!=original
    p.write_text(change)
    assert audit(tmp_path)


def test_missing_forced_carry_is_detected(tmp_path):
    copy_fixture(tmp_path)
    p=tmp_path/SLIDE
    original=p.read_text();change=original.replace('    ld a, e\n    scf\n    pop hl','    ld a, e\n    xor a\n    pop hl')
    assert change!=original
    p.write_text(change)
    assert audit(tmp_path)


def test_early_include_is_rejected(tmp_path):
    copy_fixture(tmp_path)
    p=tmp_path/'main.asm'
    p.write_text(p.read_text()+'\nINCLUDE "'+str(SLIDE)+'"\n')
    assert any('premature' in msg for msg in audit(tmp_path))


def test_b2f_ice_landing_is_not_an_automatic_step():
    source=(ROOT/CORE).read_text()+'\n'+(ROOT/SLIDE).read_text()
    code=parse_asm(source)
    # Synthetic B2F ICE arrival (3,3); no heading is remembered from a warp.
    roles=bytearray(20*18);roles[3*20+3]=2
    got,carry,_,state=execute(code,96,20,18,bytes(roles),3,3,0,
                    'JohtoIcePathResolveSlide367D',initial_e=0,with_state=True)
    assert (got,carry,state)==(0,False,0)


def test_blocked_ice_does_not_keep_forcing_collision():
    source=(ROOT/CORE).read_text()+'\n'+(ROOT/SLIDE).read_text()
    code=parse_asm(source)
    roles=bytearray(40*36);roles[1*40+1]=2;roles[1*40+2]=1
    got,carry,_,state=execute(code,70,40,36,bytes(roles),1,1,HEADING['LEFT'],
                    'JohtoIcePathResolveSlide367D',initial_e=HEADING['RIGHT'],with_state=True)
    assert (got,carry,state)==(HEADING['LEFT'],False,0)
