"""Gold boulder drop visibility before pause/quake: regression and mutation tests."""
from pathlib import Path
import pytest
from tools.johto_ice_path_immediate_disappear_369j_audit import audit,B1

ROOT=Path(__file__).resolve().parents[2]

def test_live_gold_disappear_before_quake():
    assert audit(ROOT)==[]

@pytest.mark.parametrize('stone',range(1,5))
def test_missing_render_hide_is_caught(stone):
    original=(ROOT/B1).read_text()
    bad=f'ld [wSpriteStateData1 + ${stone*16+2:02x}], a'
    assert bad in original
    changed=original.replace(bad,'nop',1)
    assert any(f'stone {stone}' in e for e in audit(ROOT,{B1:changed}))

@pytest.mark.parametrize('old,new',[
    ('call JohtoIcePathB1FHideDropped369B\n    ; Gold IcePathB1F.StoneTable',
     'nop\n    ; Gold IcePathB1F.StoneTable'),
    ('ld c, 60\n    call DelayFrames','ld c, 16\n    call DelayFrames'),
    ('call JohtoIcePathGoldQuake369M','nop'),
])
def test_bad_order_or_missing_feedback_is_caught(old,new):
    original=(ROOT/B1).read_text();assert old in original
    assert audit(ROOT,{B1:original.replace(old,new,1)})
