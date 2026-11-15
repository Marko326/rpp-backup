"""REF-369N Gold facing layout and negative mutation checks (source only)."""
from pathlib import Path
import pytest
from tools.johto_gold_dust_quadrants_369n_audit import audit,ROOT_DUST,PUSH,KANTO,OAM,B1,VER
ROOT=Path(__file__).resolve().parents[2]


def changed(path,old,new):
    text=(ROOT/path).read_text()
    assert old in text, (path,old)
    return {path:text.replace(old,new,1)}


def test_four_quadrant_source_gate():
    assert audit(ROOT)==[]


@pytest.mark.parametrize('path,old,new',[
    (ROOT_DUST,'    call .writeQuadrant\n    ld a, c\n    add 8', '    nop ; removed first quadrant\n    ld a, c\n    add 8'),
    (ROOT_DUST,'    call .writeQuadrant\n    ld a, c\n    sub 8', '    nop ; missing second quadrant\n    ld a, c\n    sub 8'),
    (ROOT_DUST,'    call .writeQuadrant\n    ld a, c\n    add 8\n    ld c, a\n    call .writeQuadrant\n    ld a, e', '    nop ; skipped last quadrant\n    ld a, c\n    add 8\n    ld c, a\n    nop ; missing last quadrant\n    ld a, e'),
    (ROOT_DUST,'    add 8\n    ld c, a\n    call .writeQuadrant', '    add 4\n    ld c, a\n    call .writeQuadrant'),
    (ROOT_DUST,'    add 8\n    ld b, a\n    call .writeQuadrant', '    add 4\n    ld b, a\n    call .writeQuadrant'),
    (ROOT_DUST,'    ld a, h\n    ld [de], a ; same tile in all four quadrants', '    ld a, b\n    ld [de], a ; same tile in all four quadrants'),
    (ROOT_DUST,'    ld a, l\n    ld [de], a ; same palette in all four quadrants', '    ld a, c\n    ld [de], a ; same palette in all four quadrants'),
    (ROOT_DUST,'    cp $84 ; need 16 bytes;' , '    cp $90 ; need 16 bytes;' ),
    (ROOT_DUST,'    bit 6, a\n    jp nz, .done','    bit 6, a\n    nop ; guard removed'),
    (ROOT_DUST,'    cpl\n    and 4','    nop\n    and 2'),
    (ROOT_DUST,'    add $fc ; Gold', '    add $fa ; Gold'),
    (ROOT_DUST,'    ld a, $10 | PAL_OW_EMOJI', '    ld a, $10 | PAL_OW_ROCK'),
    (ROOT_DUST,'    ld [hOAMBufferOffset], a\n.done','    nop ; never advance OAM\n.done'),
    (ROOT_DUST,'    call CopyVideoData\n    ret','    call CopyVideoData\n    ld c, 1\n    jp DelayFrames'),
    (PUSH,'\tjr nz, .kantoQuietDust','\tjr z, .kantoQuietDust'),
    (KANTO,'\tld a, $81 ; quiet dust mode','\tld [rOBP1], a\n\tld a, $81 ; quiet dust mode'),
    (OAM,'\tcallab DrawJohtoGoldStrengthDust369L','\tnop ; missing renderer'),
    (B1,'    ld e, 2\n    ld b, 16','    ld e, 1\n    ld b, 16'),
    (VER,'REF-369@','REF-369M@'),
])
def test_negative_mutations(path,old,new):
    assert audit(ROOT,changed(path,old,new)), (path,old)


def test_gold_reference_facings():
    gold=Path('/mnt/data/_refcheck/gold/JOHTO_HANDOFF_REF312_REFERENCE_COMPLETE/REFERENCES/Gold/pokegold-master')
    if gold.is_dir():assert audit(ROOT,gold_root=gold)==[]


def test_oam_capacity_math():
    # Four OAM entries = 4 * 4 bytes; last safe start before $90 is $80.
    for offset in range(0,0xa0,4):
        if offset < 0x84:
            assert offset+16 <= 0x90
        else:
            assert offset+16 > 0x90


def test_frame_phase_matches_gold_30hz_on_60fps():
    # Countdown decrements every display frame; Gold facing toggles every
    # two original logical frames, i.e. four RPP 60Hz display frames.
    frames=[((~left)&4)//4 for left in range(63,47,-1)]
    assert frames==[0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1]
