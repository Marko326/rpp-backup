"""Regression + negative fault injections for REF-369E hidden sprite ID fix."""
from pathlib import Path
import pytest
from tools.johto_ice_path_sprite_hide_369e_audit import audit,B1,B2,SAVE,HELPERS,SPRITES,HOME,VERSION

ROOT=Path(__file__).resolve().parents[2]


def test_live_hidden_sprite_contract():
    assert audit(ROOT)==[]

@pytest.mark.parametrize('file,old,new,expected',[
    (B1,'ld [wSpriteStateData2 + $14], a', 'ld [wSpriteStateData1 + $10], a\n    ld [wSpriteStateData2 + $14], a', 'zeroes sprite ID'),
    (B1,'ld [wSpriteStateData2 + $45], a', 'ld [wSpriteStateData2 + $4e], a\n    ld [wSpriteStateData2 + $45], a', 'VRAM slot'),
    (B2,'ld [wSpriteStateData2 + $34], a', 'ld [wSpriteStateData1 + $30], a\n    ld [wSpriteStateData2 + $34], a', 'zeroes sprite ID'),
    (B2,'ld [wSpriteStateData2 + $25], a', 'ld [wSpriteStateData2 + $2e], a\n    ld [wSpriteStateData2 + $25], a', 'VRAM slot'),
    (B2,'ld [wSpriteStateData2 + $44], a', 'ld [wSpriteStateData2 + $49], a', 'coordinate'),
    (B1,'bit 7, a', 'bit 6, a', 'event guard'),
    (SAVE,'jp HoldTextDisplayOpen', 'call ReloadTilesetTilePatterns\n\tjp HoldTextDisplayOpen', 'atlas reload'),
    (HOME,'call InitMapSprites ; reload sprite tile pattern data', 'nop ; removed reload', 'HOME text return'),
    (VERSION,'REF-369@','REF-369D@','version'),
])
def test_reject_regressions(file,old,new,expected):
    original=(ROOT/file).read_text()
    assert old in original
    mutated=original.replace(old,new,1)
    problems=audit(ROOT,{file:mutated})
    assert any(expected in problem for problem in problems),problems
