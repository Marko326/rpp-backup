"""Native ASM branch-level regressions: source is not yet included in ROM."""
from pathlib import Path
import shutil

from tools.johto_ice_path_367_native_audit import audit, execute, parse_asm, HEADING

ROOT = Path(__file__).resolve().parents[2]
ASM = 'data/johto_ice_path_stage/ice_path_step_runtime_367c.asm'


def setup(root):
    for rel in ('main.asm', 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json',ASM):
        dst=root/rel
        dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(ROOT/rel,dst)
    for name in ('IcePath1F', 'IcePathB1F', 'IcePathB2FMahoganySide',
                 'IcePathB2FBlackthornSide', 'IcePathB3F'):
        p=f'data/johto_ice_path_stage/{name}.roles.bin'
        shutil.copyfile(ROOT/p,root/p)


def test_exhaustive_native_branches_and_stack_contract():
    assert audit(ROOT) == []


def test_wrong_gold_role_comparison_is_rejected(tmp_path):
    setup(tmp_path)
    p=tmp_path/ASM
    text=p.read_text().replace('    cp 2\n    jr z, .ice', '    cp 7\n    jr z, .ice')
    assert text != p.read_text()
    p.write_text(text)
    assert any('native' in err or 'probe' in err for err in audit(tmp_path))


def test_wrong_heading_motion_is_rejected(tmp_path):
    setup(tmp_path)
    p=tmp_path/ASM
    text=p.read_text().replace('    inc c\n    jr .read', '    dec c\n    jr .read')
    assert text != p.read_text()
    p.write_text(text)
    assert audit(tmp_path), 'changing east step to west must not pass'


def test_broken_b1f_pit_scope_rejected_on_synthetic_role():
    source=(ROOT/ASM).read_text()
    code=parse_asm(source)
    # Place PIT ahead in an ID70 synthetic grid. Native code MUST reject it;
    # a B2F landing must never become a two-way pit passage.
    data=bytearray([0]*1440)
    data[1*40+2]=3
    got,carry,_=execute(code,70,40,36,bytes(data),1,1,HEADING['RIGHT'],
                        'JohtoIcePathProbeStep367C')
    assert (got,carry)==(0,False)
    got,carry,_=execute(code,95,40,36,bytes(data),1,1,HEADING['RIGHT'],
                        'JohtoIcePathProbeStep367C')
    assert (got,carry)==(3,True)


def test_illegal_instruction_is_fatal(tmp_path):
    setup(tmp_path)
    p=tmp_path/ASM
    p.write_text(p.read_text().replace('    inc c\n    jr .read','    sbc hl, de\n    jr .read'))
    assert any('unsupported native opcode' in error for error in audit(tmp_path))


def test_native_ice_asm_must_stay_unlinked_while_strength_unfinished(tmp_path):
    setup(tmp_path)
    p=tmp_path/'main.asm'
    p.write_text(p.read_text() + '\nINCLUDE "'+ASM+'"\n')
    assert any('prematurely linked' in e for e in audit(tmp_path))


def test_slide_continues_only_from_ice():
    code=parse_asm((ROOT/ASM).read_text())
    roles=bytearray([0]*1440)
    # FLOOR -> ICE directly ahead. Probe sees ICE; slide continuation from
    # FLOOR must deny, avoiding an automatic move before the first input.
    roles[1*40+2]=2
    got,carry,_=execute(code,70,40,36,bytes(roles),1,1,HEADING['RIGHT'],
                        'JohtoIcePathProbeStep367C')
    assert (got,carry)==(2,True)
    got,carry,_=execute(code,70,40,36,bytes(roles),1,1,HEADING['RIGHT'],
                        'JohtoIcePathContinueSlide367C')
    assert (got,carry)==(0,False)
    roles[1*40+1]=2
    got,carry,_=execute(code,70,40,36,bytes(roles),1,1,HEADING['RIGHT'],
                        'JohtoIcePathContinueSlide367C')
    assert (got,carry)==(2,True)
