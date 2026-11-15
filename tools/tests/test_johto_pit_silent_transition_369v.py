from pathlib import Path
import pytest
from tools.johto_pit_silent_transition_369v_audit import audit,FALL,HOME,SEAFOAM,VERSION
ROOT=Path(__file__).resolve().parents[2]

def test_source_passes():assert not audit(ROOT)

@pytest.mark.parametrize('path,old,new,why',[
 (FALL,'jp PlaySilentMapChange369V','jp PlayMapChangeSound','silent shared'),
 (HOME,'PlaySilentMapChange369V::','; removed','silent fade'),
 (FALL,'    ; REF-369U pre-fade UpdateSprites had no visible benefit in the phone test.\n','    call UpdateSprites\n','ineffective'),
 (FALL,'callab JohtoIcePathB2FMahoganySyncLanded369B','callab JohtoIcePathInitializePitState369B','ineffective'),
 (FALL,'call GBFadeInFromBlack','call GBFadeInFromWhite','skyfall'),
 (FALL,'ld a, GSSFX_BURNED_TOWER_KINESIS','ld a, SFX_CUT','skyfall'),
 (SEAFOAM,'predef_jump ShowObject','predef_jump HideObject','Seafoam'),
 (VERSION,'REF-369@','REF-369U@','label'),
])
def test_fault_injection(path,old,new,why):
    txt=(ROOT/path).read_text();assert old in txt
    errors=audit(ROOT,{path:txt.replace(old,new,1)})
    assert any(why in e for e in errors), errors
