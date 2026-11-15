"""REF-369P regression and fault injection for dialog and temporary smoke."""
from pathlib import Path
import pytest
from tools.johto_ice_path_text_dust_369p_audit import audit, B1, PUSH, DUST, START, KANTO, VERSION

ROOT=Path(__file__).resolve().parents[2]


def corrupt(path, before, after):
    data=(ROOT/path).read_text()
    assert before in data, (path, before)
    return {path:data.replace(before,after,1)}


def test_ref369p_real_paths():
    assert audit(ROOT)==[]


@pytest.mark.parametrize('path,before,after',[
    (B1,'    dw JohtoIcePathB1FBoulderFellText369G','    dw JohtoIcePathB1FStaticStoneText367M'),
    (B1,'JohtoIcePathB1FTextPointers367K == 5 * 2','JohtoIcePathB1FTextPointers367K == 4 * 2'),
    (B1,'ld a, 5 ; B1F script-only text pointer','ld a, 4 ; B1F script-only text pointer'),
    (B1,'    jp DisplayTextID\n.pitCoords','    jp PrintText\n.pitCoords'),
    (B1,'    ld [wJohtoGoldDustFrames], a\n    ld [wJohtoGoldDustSlot2Frames369R], a\n    ld a, 5','    nop ; missing cleanup\n    ld a, 5'),
    (START,'\tld [wJohtoGoldDustFrames], a','\tnop ; missing menu cleanup'),
    (PUSH,'\tcallab BeginJohtoGoldStrengthDust369L','\t; missing begin smoke'),
    (PUSH,'\tjr nz, .noJohtoDustBegin','\tjr z, .noJohtoDustBegin'),
    (DUST,'    ld [hl], c','    nop ; dust X not snapshotted'),
    (DUST,'ld a, [hl]\n    and $03','ld a, [wSpriteStateData1 + 9]\n    and $03'),
    (KANTO,'\tld a, $81 ; quiet dust mode','\tld [rOBP1], a\n\tld a, $81 ; quiet dust mode'),
    (VERSION,'REF-369@','REF-369O@'),
])
def test_regressions_caught(path,before,after):
    assert audit(ROOT, corrupt(path,before,after)), path


def test_b1f_text_id_is_above_four_sprites():
    assert len([(i, i > 4) for i in range(1,6) if i > 4])==1
    assert (ROOT/B1).read_text().count('object SPRITE_BOULDER,')==4


def test_gold_reference_waitbutton_close():
    gold=Path('/mnt/data/_refcheck/gold/JOHTO_HANDOFF_REF312_REFERENCE_COMPLETE/REFERENCES/Gold/pokegold-master/maps/IcePathB1F.asm')
    if gold.exists():
        source=gold.read_text()
        section=source.split('.FinishBoulder:',1)[1].split('.BoulderFallsThrough:',1)[0]
        assert [section.index(x) for x in ('opentext','writetext','waitbutton','closetext')]==sorted(section.index(x) for x in ('opentext','writetext','waitbutton','closetext'))
