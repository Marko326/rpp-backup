"""REF-369O Gold pit completion, no-cut audio and timing regression mutations."""
from pathlib import Path
import pytest
from tools.johto_strength_push_drop_369o_audit import audit, PUSH,DUST,B1,MOVEMENT,KANTO
ROOT = Path(__file__).resolve().parents[2]


def changed(rel, old, new):
    text=(ROOT/rel).read_text()
    assert text.count(old)==1, (rel,old)
    return {rel:text.replace(old,new,1)}


def test_live_gold_push_drop_flow():
    assert audit(ROOT)==[]


@pytest.mark.parametrize('file,old,new', [
    (DUST, '    call CopyVideoData\n    ret',
     '    call CopyVideoData\n    ld c, 16\n    jp DelayFrames'),
    (DUST,'ld [hl], 64 ; original pre-hide duration',
     'ld [hl], 32 ; incorrect short-lived dust'),
    (DUST,'    cpl\n    and 4\n    srl a\n    srl a',
     '    cpl\n    and 2\n    srl a'),
    (B1, '    ld a, [wd730]\n    bit 0, a\n    ret nz',
     '    nop\n    nop ; hides while moving'),
    (B1,'    res 7, [hl]\n    jp JohtoIcePathB1FCheckStoneDrop369B',
     '    jp JohtoIcePathB1FCheckStoneDrop369B ; never clear pending'),
    (B1,'    call JohtoIcePathB1FHideDropped369B\n    ; Gold IcePathB1F',
     '    nop ; never hide stone\n    ; Gold IcePathB1F'),
    (PUSH,'\tcp JOHTO_RUNTIME_MAP_HANDLE\n\tret z\n\tld a, SFX_CUT',
     '\tcp JOHTO_RUNTIME_MAP_HANDLE\n\tnop\n\tld a, SFX_CUT'),
    (PUSH,'\tret z\n\tld a, SFX_CUT\n\tjp PlaySound',
     '\tret z\n\tret ; Kanto lost original sound'),
    (PUSH, '\tcp JOHTO_ICE_PATH_B1F_LOCAL_ID\n\tjr nz, .checkStrength',
     '\tcp JOHTO_ICE_PATH_B1F_LOCAL_ID\n\tjr z, .checkStrength'),
    (PUSH, '\tbit 7, a\n\tret nz\n.checkStrength',
     '\tbit 7, a\n\tnop\n.checkStrength'),
    (KANTO,'\tld c, 8 ; number of steps in animation',
     '\tld c, 4 ; change Kanto smoke'),
    (MOVEMENT,'\tld [hl], $10', '\tld [hl], $08'),
])
def test_regressions_rejected(file,old,new):
    assert audit(ROOT,changed(file,old,new))


def test_60hz_timing_relationship():
    # Model time only: real movement completion is from NPC pending flag.
    move_logical_ticks=16
    display_hz=60
    logical_hz=30
    move_display_frames=move_logical_ticks * display_hz // logical_hz
    gold_dust_display_frames=move_display_frames * 2
    assert move_display_frames==32
    assert gold_dust_display_frames==64
    assert gold_dust_display_frames - move_display_frames == 32
