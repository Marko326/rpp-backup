"""Q source-tracking regression tests expanded for R multi-slot lifecycle."""
from pathlib import Path
import pytest
from tools.johto_gold_dust_tracking_369q_audit import audit, DUST, PUSH, WRAM, START, VERSION
ROOT=Path(__file__).resolve().parents[2]

def change(path,before,after):
    code=(ROOT/path).read_text();assert before in code,(path,before)
    return {path:code.replace(before,after,1)}

def test_source_lifecycle_complete():
    assert audit(ROOT)==[]

@pytest.mark.parametrize('path,before,after',[
    (DUST,'ld a, [wBoulderSpriteIndex]\n    and a','ld a, [wSpriteStateData1 + 9]\n    and a'),
    (DUST,'ld hl, wJohtoGoldDustSlot2Y369R\n.selected','ld hl, wJohtoGoldDustDirection\n.selected'),
    (DUST,'ld [hl], 64 ; original pre-hide duration','ld [hl], 12 ; broken short dust'),
    (DUST,'ld hl, wJohtoGoldDustSlot2Y369R\n    call .updateOne','ld hl, wJohtoGoldDustDirection\n    call .updateOne'),
    (DUST,'cp $ff\n    jr z, .hidden','cp $fe\n    jr z, .hidden'),
    (DUST,'ld [hl], 60','ld [hl], 10'),
    (DUST,'db -4, 0 ; DOWN','db 12, 0 ; DOWN'),
    (DUST,'db 2, -6 ; RIGHT','db 2, 10 ; RIGHT'),
    (DUST,'ld a, [hl]\n    and $03','ld a, [wSpriteStateData1 + 9]\n    and $03'),
    (DUST,'ld a, $10 | PAL_OW_EMOJI','ld a, $10 | PAL_OW_ROCK'),
    (DUST,'dec [hl] ; lifetime is NOT dependent on OAM capacity','nop ; no lifetime'),
    (DUST,'cp $84 ; need 16 bytes;','cp $90 ; need 16 bytes;'),
    (PUSH,'\tcallab BeginJohtoGoldStrengthDust369L','\tnop ; no Gold dust'),
    (START,'\tld [wJohtoGoldDustSlot2Frames369R], a','\tnop ; stale second puff'),
    (WRAM,'wJohtoGoldDustSlot2Frames369R:: ; cd53','wJohtoGoldDustSlot2Frames369R:: ; cd55'),
    (VERSION,'REF-369@','REF-369Q@'),
])
def test_mutations_caught(path,before,after):
    assert audit(ROOT,change(path,before,after)),(path,before)

def test_dpad_directions_never_retarget_rendering():
    code=(ROOT/DUST).read_text()
    tracking=code.split('UpdateJohtoGoldDustAnchor369Q::',1)[1].split('DrawJohtoGoldStrengthDust369L::',1)[0]
    assert all(x not in tracking for x in ('hJoyHeld','wPlayerMovingDirection','wSpriteStateData1 + 9'))
    assert 'ld d, HIGH(wSpriteStateData1)' in tracking
