#!/usr/bin/env python3
"""REF-369P: source-only safety audit of B1F text lifecycle and temp smoke.

Tests reachable code placement and Gold script contract; not a ROM replay.
"""
from pathlib import Path
import argparse

B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
PUSH = 'engine/overworld/push_boulder.asm'
DUST = 'engine/overworld/johto_gold_strength_dust_369l.asm'
START = 'engine/menu/start_menu.asm'
HOME = 'home.asm'
VERSION = 'data/game_version.asm'
KANTO = 'engine/overworld/ssanne.asm'


def audit(root: Path, overrides: dict[str, str] | None = None) -> list[str]:
    overrides = overrides or {}
    def read(path):
        return overrides.get(path, (Path(root) / path).read_text())
    failures = []
    def req(ok, message):
        if not ok: failures.append(message)

    b1, push, dust, start, home = (read(p) for p in (B1, PUSH, DUST, START, HOME))
    try:
        table = b1.split('JohtoIcePathB1FTextPointers367K:',1)[1].split('JohtoIcePathB1FTextPointers367KEnd::',1)[0]
        fall = b1.split('JohtoIcePathB1FCheckStoneDrop369B::',1)[1].split('\n.pitCoords',1)[0]
        begin = dust.split('BeginJohtoGoldStrengthDust369L::',1)[1].split('DrawJohtoGoldStrengthDust369L::',1)[0]
        render = dust.split('DrawJohtoGoldStrengthDust369L::',1)[1].split('\n.writeQuadrant',1)[0]
        accepted = push.split('TryPushingBoulder:',1)[1].split('DoBoulderDustAnimation:',1)[0]
        finished = push.split('DoBoulderDustAnimation:',1)[1].split('ResetBoulderPushFlags:',1)[0]
        entry = start.split('DisplayStartMenu::',1)[1].split('RedisplayStartMenu::',1)[0]
    except IndexError:
        return ['live entry missing']
    req(table.count('dw JohtoIcePathB1FStaticStoneText367M') == 4 and
        table.count('dw JohtoIcePathB1FBoulderFellText369G') == 1 and
        table.index('dw JohtoIcePathB1FBoulderFellText369G') > table.rindex('dw JohtoIcePathB1FStaticStoneText367M') and
        'JohtoIcePathB1FTextPointers367K == 5 * 2' in b1,
        'B1F map text IDs must be four boulder objects followed by safe script text ID5')
    req('db 4\n    object SPRITE_BOULDER' in b1,
        'B1F must have four object IDs below script-only text ID5')
    req('ld a,[wNumSprites]' in home and 'jr nc,.skipSpriteHandling' in home,
        'DisplayTextID must route text ID5 past the B1F four sprite IDs')
    sequence = ['call JohtoIcePathB1FHideDropped369B', 'ld c, 60\n    call DelayFrames',
                'call JohtoIcePathGoldQuake369M','ld c, 16\n    call DelayFrames',
                'ld [wJohtoGoldDustFrames], a', 'ld [wJohtoGoldDustSlot2Frames369R], a', 'ld a, 5 ; B1F script-only text pointer',
                'ld [hSpriteIndexOrTextID], a','jp DisplayTextID']
    positions = [fall.find(token) for token in sequence]
    req(all(p >= 0 for p in positions) and positions == sorted(positions) and
        '\n    jp PrintText\n' not in fall and 'ld hl, JohtoIcePathB1FBoulderFellText369G\n    jp PrintText' not in fall,
        'falling stone must show its message via full DisplayTextID, after quake/rest/dust cleanup')
    req('call WaitForTextScrollButtonPress' in home and
        'CloseTextDisplay::' in home and 'pop af' in home.split('CloseTextDisplayAfterWindowHide::',1)[1].split('DisplayPokemartDialogue::',1)[0],
        'project text lifecycle must wait A/B, close Window and return ROM bank')
    req('xor a\n\tld [wJohtoGoldDustFrames], a' in entry and
        entry.index('ld [wJohtoGoldDustFrames], a') < entry.index('call PlaySound'),
        'START must clear dust before the menu is drawn or new input is accepted')
    req('call MoveSprite' in accepted and 'callab BeginJohtoGoldStrengthDust369L' in accepted and
        accepted.index('call MoveSprite') < accepted.index('callab BeginJohtoGoldStrengthDust369L') < accepted.index('callab PlayStrengthPushSFX369L') and
        'callab BeginJohtoGoldStrengthDust369L' not in finished,
        'Johto smoke must begin at accepted step, not after moving')
    req('cp JOHTO_RUNTIME_MAP_HANDLE\n\tjr nz, .noJohtoDustBegin' in accepted and
        'callab AnimateBoulderDustQuiet369K' in finished and
        'ld a, SFX_CUT\n\tjp PlaySound' in finished,
        'Kanto must retain old quiet smoke and sound while skipping Johto begin')
    track = begin.split('UpdateJohtoGoldDustAnchor369Q::',1)[1]
    req('ld a, [wSpriteStateData1 + 9]' not in track and
        'wPlayerMovingDirection' not in track and 'hJoyHeld' not in track,
        'dust must not consult live player direction after accepted push')
    req('call UpdateJohtoGoldDustAnchor369Q' in begin and
        'ld [hl], b' in begin and
        'ld hl, wJohtoGoldDustDirection' in begin and
        'ld hl, wJohtoGoldDustSlot2Y369R' in begin and
        'call UpdateJohtoGoldDustAnchor369Q' in render and
        'ld hl, wJohtoGoldDustDirection\n    call .drawSlot' in render and
        'ld hl, wJohtoGoldDustSlot2Y369R\n    call .drawSlot' in render and
        'ld [hl], 64' in begin and
        'dec hl ; cached Y\n    ld [hl], b\n    inc hl ; cached X\n    ld [hl], c' in begin,
        'Gold dust must track the accepted source boulder and freeze its anchor after hiding')
    req('ld [rOBP1]' not in read(KANTO) and 'ld [rOBP1]' not in dust and
        'ld a, $10 | PAL_OW_EMOJI' in render,
        'never reintroduce Kanto flashing or incorrect Gold palette')
    req('db "REF-369@"' in read(VERSION), 'REF-369@ version missing')
    return failures


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', type=Path, default=Path('.'))
    errors = audit(ap.parse_args().root)
    if errors:
        for error in errors: print('FAIL', error)
        raise SystemExit(1)
    print('PASS: B1F text lifecycle, START dust cleanup, independent dust snapshot, Kanto isolation (source-only)')
