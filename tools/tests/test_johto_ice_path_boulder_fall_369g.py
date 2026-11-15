from pathlib import Path
import pytest
from tools.johto_ice_path_boulder_fall_369g_audit import audit,B1

ROOT=Path(__file__).resolve().parents[2]

def test_gold_one_shot_fall_feedback():
    assert audit(ROOT)==[]

@pytest.mark.parametrize('old,new', [
 ('call CheckBoulderCoords','ret'),
 ('ret nz ; a filled hole cannot receive another boulder','jr nz, .checkSprites'),
 ('ld c, 60\n    call DelayFrames','ld c, 30\n    call DelayFrames'),
 ('ld a, GSSFX_BURNED_TOWER_STRENGTH\n    call PlaySound','ld a, SFX_PUSH_BOULDER\n    call PlaySound'),
 ('ld c, 16\n    call DelayFrames','ld c, 32\n    call DelayFrames'),
 ('call JohtoIcePathGoldQuake369M','nop'),
 ('call JohtoIcePathGoldQuake369M\n    ld c, 16','call JohtoIcePathGoldQuake369M\n    call JohtoIcePathGoldQuake369M\n    ld c, 16'),
 ('ld a, 5 ; B1F script-only text pointer, above four object sprite IDs\n    ld [hSpriteIndexOrTextID], a\n    jp DisplayTextID','ret'),
 ('line "through."','line "under."'),
 ('call JohtoIcePathB1FHideDropped369B\n    ; Gold IcePathB1F.StoneTable','nop\n    ; Gold IcePathB1F.StoneTable'),
])
def test_injected_bug_fails_gate(old,new):
    src=(ROOT/B1).read_text()
    assert old in src
    assert audit(ROOT,{B1:src.replace(old,new,1)})
