"""Mutation/negative assertions for the REF-369M live paths."""
import pytest
from pathlib import Path
from tools.johto_ice_path_gold_visual_369m_audit import audit, DUST,PUSH,KANTO,B1,BURNED
ROOT=Path(__file__).parents[2]

def test_live_visual_audit():assert audit(ROOT)==[]

@pytest.mark.parametrize('path,old,new',[
 (DUST,'ld a, $10 | PAL_OW_EMOJI','ld a, $17'),
 (DUST,'ld a, $10 | PAL_OW_EMOJI','ld a, $10 | PAL_OW_ROCK'),
 (DUST,'ld a, $10 | PAL_OW_EMOJI','ld [rOBP1], a\n    ld a, $10 | PAL_OW_EMOJI'),
 (PUSH,'jr nz, .kantoQuietDust','jr z, .kantoQuietDust'),
 (PUSH,'callab AnimateBoulderDustQuiet369K','callab AnimateBoulderDust'),
 (KANTO,'ld c, 8 ; number of steps in animation','ld c, 2 ; number of steps in animation'),
 (B1,'ld e, 2','ld e, 1'),
 (B1,'xor $fc','xor $fe'),
 (B1,'ld b, 16\n.shakeLoop','ld b, 80\n.shakeLoop'),
 (B1,'ld c, 2\n    call DelayFrames','ld c, 4\n    call DelayFrames'),
 (B1,'ld [hSCY], a ; restore before static wait and text','nop ; omit restoration'),
 (B1,'call JohtoIcePathGoldQuake369M\n    ld c, 16','call JohtoIcePathGoldQuake369M\n    ld c, 32'),
 (B1,'call JohtoIcePathGoldQuake369M\n    ld c, 16','callab JohtoBurnedTowerEarthquake16\n    ld c, 16'),
 (BURNED,'ld e, 1','ld e, 2'),
])
def test_regressions_rejected(path,old,new):
    src=(ROOT/path).read_text(); assert old in src
    assert audit(ROOT,{path:src.replace(old,new,1)})
