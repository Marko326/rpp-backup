#!/usr/bin/env python3
"""REF-369R: two independent source-tracked puffs and post-pit timing.

Static source gate only. Does not replace RGBDS build or video acceptance.
"""
from pathlib import Path
import re

DUST='engine/overworld/johto_gold_strength_dust_369l.asm'
WRAM='wram.asm'
OAM='engine/overworld/oam.asm'
START='engine/menu/start_menu.asm'
FALL='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
KANTO='engine/overworld/push_boulder.asm'
VER='data/game_version.asm'


def audit(root, overrides=None):
    root=Path(root); overrides=overrides or {}
    def src(path): return overrides.get(path, (root/path).read_text())
    dust, wram, oam, start, fall, push = map(src,(DUST,WRAM,OAM,START,FALL,KANTO))
    errors=[]
    def require(ok, message):
        if not ok:errors.append(message)
    try:
        begin=dust.split('BeginJohtoGoldStrengthDust369L::',1)[1].split('UpdateJohtoGoldDustAnchor369Q::',1)[0]
        track=dust.split('UpdateJohtoGoldDustAnchor369Q::',1)[1].split('DrawJohtoGoldStrengthDust369L::',1)[0]
        draw=dust.split('DrawJohtoGoldStrengthDust369L::',1)[1].split('\n.writeQuadrant\n',1)[0]
    except IndexError:return ['smoke entry/tracker/renderer missing']
    require('ld a, [wBoulderSpriteIndex]' in begin and
            'ld a, [wSpriteStateData1 + 9]' in begin and
            'ld b, a ; source + accepted facing, not live player input' in begin,
            'accepted push must snapshot real boulder and direction')
    require('ld hl, wJohtoGoldDustDirection' in begin and
            'ld a, [wJohtoGoldDustFrames]' in begin and
            'ld a, [wJohtoGoldDustSlot2Frames369R]' in begin and
            'ld hl, wJohtoGoldDustSlot2Y369R' in begin and
            'jr z, .second' in begin and
            'ld c, a\n    ld a, [wJohtoGoldDustFrames]\n    cp c' in begin and
            'ld [hl], b' in begin,
            'puff creation must use either free slot and evict older on third push')
    require('ld [hl], 64' in begin and
            'call UpdateJohtoGoldDustAnchor369Q' in begin and
            'call CopyVideoData' in begin and
            not re.search(r'^\s*(?:call|jp)\s+DelayFrames\b',begin,re.M),
            'begin must not stall movement, must capture source and load Gold art')
    require('ld hl, wJohtoGoldDustDirection\n    call .updateOne' in track and
            'ld hl, wJohtoGoldDustSlot2Y369R\n    call .updateOne' in track and
            'ld a, [hl]\n    bit 2, a\n    jp nz, .done' in track,
            'both source slots must update independently and freeze after hiding')
    require('ld d, HIGH(wSpriteStateData1)' in track and
            'cp $ff\n    jr z, .hidden' in track and
            'set 2, [hl]' in track and
            'dec hl ; remaining lifetime\n    ld [hl], 60' in track,
            'falling stone must arm 60 post-hide frames exactly once')
    require(all(x in track for x in ('db -4, 0 ; DOWN','db 8, 0 ; UP',
             'db 2, 6 ; LEFT','db 2, -6 ; RIGHT','inc e ; C1x6',
             'dec hl ; cached Y\n    ld [hl], b\n    inc hl ; cached X\n    ld [hl], c')) and
            not any(x in track for x in ('hJoyHeld','wPlayerMovingDirection',
                                         'wSpriteStateData1 + 9','wBoulderSpriteIndex')),
            'Gold offsets and live STONE XY required; D-pad must not re-target puffs')
    require('call UpdateJohtoGoldDustAnchor369Q' in draw and
            'ld hl, wJohtoGoldDustDirection\n    call .drawSlot' in draw and
            'ld hl, wJohtoGoldDustSlot2Y369R\n    call .drawSlot' in draw and
            'dec [hl] ; lifetime is NOT dependent on OAM capacity' in draw and
            'cp $84' in draw and draw.index('dec [hl]') < draw.index('cp $84'),
            'both puffs must age and draw independently, even when OAM is full')
    require('bit 6, a\n    jp nz, .done' in draw and
            'cp $84 ; need 16 bytes;' in draw and
            'ld a, [hOAMBufferOffset]' in draw and
            'ld [hOAMBufferOffset], a' in draw and
            'ld a, $10 | PAL_OW_EMOJI' in draw and
            draw.count('call .writeQuadrant')==4,
            'OAM must remain capacity-safe and render Gold four quadrants/EMOTE palette')
    require('wJohtoGoldDustSlot2Y369R:: ; cd51' in wram and
            'wJohtoGoldDustSlot2X369R:: ; cd52' in wram and
            'wJohtoGoldDustSlot2Frames369R:: ; cd53' in wram and
            'wJohtoGoldDustSlot2Source369R:: ; cd54\n\tds 1\n\tds 1 ; CD55' in wram and
            'wJohtoGoldDustDirection:: ; cd56' in wram and
            'wJohtoGoldDustFrames:: ; cd58' in wram and
            'wJohtoGoldDustSourceAndFacing369Q:: ; cd59' in wram,
            'all smoke storage must alias fixed unsaved CD51..CD59 bytes')
    require('wJohtoGoldDustSlot2Frames369R' in oam and
            'or b\n\tjr z, .noGoldDust' in oam and
            'callab DrawJohtoGoldStrengthDust369L' in oam,
            'second puff must still draw after first has expired')
    require('ld [wJohtoGoldDustFrames], a' in start and
            'ld [wJohtoGoldDustSlot2Frames369R], a' in start and
            'ld [wJohtoGoldDustFrames], a' in fall and
            'ld [wJohtoGoldDustSlot2Frames369R], a' in fall,
            'START and completed pit dialogue must clear BOTH puffs')
    require('callab BeginJohtoGoldStrengthDust369L' in push and
            'callab AnimateBoulderDustQuiet369K' in push and
            'ld a, SFX_CUT\n\tjp PlaySound' in push and
            'ld [rOBP1]' not in dust,
            'Kanto must keep its original quiet push path without Gold smoke/flash')
    require('db "REF-369@"' in src(VER), 'REF-369R development version missing')
    return errors

if __name__=='__main__':
    import argparse
    ap=argparse.ArgumentParser();ap.add_argument('--root',type=Path,default=Path('.'))
    issues=audit(ap.parse_args().root)
    for issue in issues:print('FAIL:',issue)
    if issues:raise SystemExit(1)
    print('PASS: two independent puffs, one-shot 60f post-fall, safe OAM, Kanto isolated (source only)')
