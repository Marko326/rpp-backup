"""Gold scripting semantics of pause 30 / earthquake 80 (source-verified)."""
from pathlib import Path
from tools.johto_ice_path_boulder_fall_369g_audit import audit, B1

ROOT=Path(__file__).resolve().parents[2]

def test_gold_encoded_quake_80_and_pause_30():
    gold_pause=30*2
    quake_parameter=80
    assert quake_parameter == 0x50
    shake_steps=quake_parameter&0x3f
    power=1<<((quake_parameter>>6)&3)
    assert (gold_pause,shake_steps,power)==(60,16,2)
    # The Gold script copies the lower 6 bits into step_sleep too.
    assert (quake_parameter&0x3f)==16
    assert audit(ROOT)==[]

def test_regression_old_five_bursts_is_rejected():
    original=(ROOT/B1).read_text()
    old=original.replace('call JohtoIcePathGoldQuake369M\n    ld c, 16',
                         'ld b, 5\n.quake80\n    push bc\n    call JohtoIcePathGoldQuake369M\n    pop bc\n    dec b\n    jr nz, .quake80\n    ld c, 16',1)
    assert original!=old
    assert audit(ROOT,{B1:old})
