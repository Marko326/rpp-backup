"""REF-369R multi-slot source gate, fault injection and conservative timing model.

Static/inferred behavior only; no RGBDS build or device frames generated here.
"""
from pathlib import Path
import pytest
from tools.johto_gold_dust_lifecycle_369r_audit import (
    audit, DUST, WRAM, OAM, START, FALL, KANTO, VER,
)
ROOT=Path(__file__).resolve().parents[2]


def change(path, old, new):
    data=(ROOT/path).read_text()
    assert data.count(old)==1,(path,old,data.count(old))
    return {path:data.replace(old,new,1)}


def test_static_multislot_gate():
    assert audit(ROOT)==[]


@pytest.mark.parametrize('path,old,new',[
    (DUST,'ld a, [wJohtoGoldDustSlot2Frames369R]','ld a, [wJohtoGoldDustFrames]'),
    (DUST,'jr z, .second','jr z, .selected'),
    (DUST,'ld hl, wJohtoGoldDustSlot2Y369R\n.selected','ld hl, wJohtoGoldDustDirection\n.selected'),
    (DUST,'ld [hl], 64 ; original pre-hide duration','ld [hl], 16 ; incorrect short-lived dust'),
    (DUST,'ld a, [wBoulderSpriteIndex]','ld a, [hJoyHeld]'),
    (DUST,'set 2, [hl] ; arm post-hide period ONCE','res 2, [hl] ; broken re-arm forever'),
    (DUST,'ld [hl], 60','ld [hl], 12'),
    (DUST,'ld hl, wJohtoGoldDustSlot2Y369R\n    call .updateOne','ld hl, wJohtoGoldDustDirection\n    call .updateOne'),
    (DUST,'ld hl, wJohtoGoldDustSlot2Y369R\n    call .drawSlot','ld hl, wJohtoGoldDustDirection\n    call .drawSlot'),
    (DUST,'dec [hl] ; lifetime is NOT dependent on OAM capacity','nop ; frozen when full'),
    (DUST,'cp $84 ; need 16 bytes;','cp $90 ; unsafe OAM overwrite'),
    (DUST,'ld a, $10 | PAL_OW_EMOJI','ld a, $10 | PAL_OW_ROCK'),
    (WRAM,'wJohtoGoldDustSlot2Y369R:: ; cd51','wJohtoGoldDustSlot2Y369R:: ; cd50'),
    (WRAM,'wJohtoGoldDustSlot2Source369R:: ; cd54\n\tds 1','wJohtoGoldDustSlot2Source369R:: ; cd54\n\tds 2'),
    (OAM,'\tld a, [wJohtoGoldDustSlot2Frames369R]','\tld a, [wJohtoGoldDustFrames]'),
    (START,'\tld [wJohtoGoldDustSlot2Frames369R], a','\tnop ; leaked secondary after START'),
    (FALL,'    ld [wJohtoGoldDustSlot2Frames369R], a','    nop ; leaked secondary after text'),
    (KANTO,'\tcallab AnimateBoulderDustQuiet369K','\tcallab AnimateBoulderDust'),
    (VER,'REF-369@','REF-369Q@'),
])
def test_bad_implementation_is_caught(path,old,new):
    assert audit(ROOT, change(path,old,new)), (path,old)


def test_display_slots_state_model():
    """Pure timing arithmetic, not a claim of actual frame-exact runtime."""
    class Slot:
        def __init__(self):self.source=None;self.timer=0;self.hidden=False
        def start(self,source):self.source=source;self.timer=64;self.hidden=False
        def tick(self,hidden_now=False):
            if not self.timer:return
            if hidden_now and not self.hidden:
                self.hidden=True;self.timer=60
            self.timer-=1
    a,b=Slot(),Slot()
    a.start('stone 1')
    for _ in range(20):a.tick()
    b.start('stone 2')
    for _ in range(12):a.tick();b.tick()
    assert a.source=='stone 1' and b.source=='stone 2'
    assert a.timer==32 and b.timer==52
    a.tick(hidden_now=True)
    assert a.hidden and a.timer==59 and b.timer==52
    for _ in range(20):a.tick();b.tick()
    assert a.timer==39 and b.timer==32
    a.tick(hidden_now=True)
    assert a.timer==38  # No second reset of the post-fall counter
    assert b.source=='stone 2'  # No overwrite from the first puff


def test_unified_source_gate_registers_all_recent_dust_checks():
    code=(ROOT/'tools/validate_current_project.py').read_text()
    for audit_name in ('johto_strength_push_drop_369o_audit.py',
                       'johto_ice_path_text_dust_369p_audit.py',
                       'johto_gold_dust_tracking_369q_audit.py',
                       'johto_gold_dust_lifecycle_369r_audit.py'):
        assert audit_name in code
