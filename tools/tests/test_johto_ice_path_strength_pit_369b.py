from pathlib import Path
import pytest
from tools.johto_ice_path_strength_pit_369b_audit import audit, B1, B2, PUSH

ROOT = Path(__file__).resolve().parents[2]

def test_ref369b_active_strength_pit_contract():
    assert audit(ROOT)==[]

@pytest.mark.parametrize('file,needle,replacement,expected', [
    (B1, 'object SPRITE_BOULDER, 11, 7, STAY, BOULDER_MOVEMENT_BYTE_2', 'object SPRITE_BOULDER, 11, 7, STAY, NONE', 'Gold Strength boulder'),
    (B1, 'db 2, 11, 7, 4, 12, 5, 13, 12, $ff', 'db 2, 12, 7, 4, 12, 5, 13, 12, $ff', 'positions'),
    (B1, 'db $04, $08, $10, $20', 'db $01, $02, $04, $04', 'independently'),
    (B1, 'db $10, $20, $40, $80', 'db $10, $20, $40, $40', 'independently'),
    (B1, 'DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED / 8', 'DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_9CA / 8', 'persistent flags'),
    (B1, 'jr nz, .blocked\n.checkSprites', 'jr z, .blocked\n.checkSprites', 'reject filled PITs'),
    (B1, 'callba CheckForBoulderCollisionWithSprites', 'callba CheckForCollisionWhenPushingBoulderLegacy', 'carry ABI'),
    (B1, 'ld [wSpriteStateData2 + $34], a', 'ld [wSpriteStateData2 + $39], a', 'source sprite'),
    (B1, 'ld [wSpriteStateData2 + $14], a', 'ld [wSpriteStateData2 + $19], a', 'source sprite'),
    (B2, 'ld [wSpriteStateData2 + $24], a', 'ld [wSpriteStateData2 + $29], a', 'visibility'),
    (B1, 'ld a, GSSFX_BURNED_TOWER_STRENGTH', 'ld a, SFX_STRENGTH', 'sound constant'),
    (B1, 'jp JohtoIcePathB1FCheckStoneDrop369B', 'ret', 'completion callback'),
    (B2, 'object SPRITE_BOULDER, 3, 12, STAY, NONE, $3', 'object SPRITE_BOULDER, 3, 11, STAY, NONE, $3', 'deposited static stone'),
    (B2, 'jp JohtoIcePathB2FMahoganySyncLanded369B', 'ret', 'hidden until'),
    (B2, 'ld [wSpriteStateData2 + $25], a', 'ld [wSpriteStateData2 + $29], a', 'visibility'),
    (PUSH, 'scf\n\tsbc a ; A=$ff, carry=1', 'ld a, $ff', 'carry ABI'),
    (PUSH, 'callab JohtoIcePathB1FCheckPush369B', 'callab JohtoBurnedTowerB1FCheckForCollisionWhenPushingBoulder', 'push collision'),
])
def test_mutation_is_blocked(file,needle,replacement,expected):
    source=(ROOT/file).read_text()
    assert needle in source,needle
    mutated=source.replace(needle,replacement,1)
    assert mutated != source
    assert any(expected in e for e in audit(ROOT,{file:mutated})),audit(ROOT,{file:mutated})
