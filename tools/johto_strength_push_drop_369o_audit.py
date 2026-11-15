#!/usr/bin/env python3
"""REF-369O: source-level Gold push/pit completion ordering and Kanto isolation.

This verifies the reachable call sequence, NOT a ROM/emulator replay.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

PUSH = 'engine/overworld/push_boulder.asm'
DUST = 'engine/overworld/johto_gold_strength_dust_369l.asm'
B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
MOVEMENT = 'engine/overworld/movement.asm'
HOME = 'home/overworld.asm'
DELAY = 'home/vblank.asm'
KANTO = 'engine/overworld/ssanne.asm'
VER = 'data/game_version.asm'


def audit(root: Path, overrides: dict[str,str] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    def read(path): return overrides.get(path, (root / path).read_text())
    errors=[]
    def check(ok, why):
        if not ok: errors.append(why)
    push,dust,b1,move,home,delay,kanto=(read(x) for x in (PUSH,DUST,B1,MOVEMENT,HOME,DELAY,KANTO))
    try:
        start = dust.split('BeginJohtoGoldStrengthDust369L::', 1)[1].split('DrawJohtoGoldStrengthDust369L::',1)[0]
        draw = dust.split('DrawJohtoGoldStrengthDust369L::',1)[1].split('\n.writeQuadrant\n',1)[0]
        effect = push.split('DoBoulderDustAnimation:',1)[1].split('ResetBoulderPushFlags:',1)[0]
        map_script = b1.split('JohtoIcePathB1FScript367K::',1)[1].split('JohtoIcePathB1FTextPointers367K:',1)[0]
        fall = b1.split('JohtoIcePathB1FCheckStoneDrop369B::',1)[1].split('\n.pitCoords\n',1)[0]
    except IndexError:
        return ['Gold push/dust/PIT live entry missing']
    check('MoveSprite::' in read('home.asm') and
          '\tld [wNPCNumScriptedSteps],a' in read('home.asm') and
          '\tset 0,[hl]' in read('home.asm'),
          'MoveSprite must queue NPC movement with wd730 bit 0')
    check('UpdateSpriteInWalkingAnimation:' in move and
          'ld [hl], $10' in move and
          'call ToggleSprite60FPSPhase' in move and
          'add b                            ; 60FPS: cancel the decrement' in move,
          'RPP move must still be 16 logical steps at 30Hz / 32 display frames')
    check('DelayFrame::' in delay and 'call DelayFrameHook' in delay and
          'DelayFrameHook:' in read('home.asm') and
          'CALL_INDIRECT PrepareOAMData' in read('home.asm'),
          'DelayFrame must only redraw OAM, not be used to wait for NPC movement')
    check('call CopyVideoData' in start and '\n    ret\n' in start and
          re.search(r'^\s*(?:call|jp)\s+DelayFrames\b', start, re.M) is None,
          'begin-dust must be nonblocking while NPC movement runs')
    check('ld [hl], 64' in start and
          'ld a, [hl]\n    cpl\n    and 4\n    srl a\n    srl a' in draw and
          'call .writeQuadrant' in draw and draw.count('call .writeQuadrant') == 4,
          'Gold dust must last 64 display frames with 4-display-frame facing phases')
    guards = ['bit 7, [hl]', 'ld a, [wd730]', 'bit 0, a', 'ret nz', 'res 7, [hl]', 'jp JohtoIcePathB1FCheckStoneDrop369B']
    positions = [map_script.find(p) for p in guards]
    check(-1 not in positions and positions == sorted(positions),
          'B1F must wait for real wd730 movement completion before checking PIT')
    ordered = ['call JohtoIcePathB1FHideDropped369B', 'ld c, 60\n    call DelayFrames',
               'ld a, GSSFX_BURNED_TOWER_STRENGTH\n    call PlaySound',
               'call JohtoIcePathGoldQuake369M', 'ld c, 16\n    call DelayFrames',
               'ld a, 5 ; B1F script-only text pointer']
    at=[fall.find(s) for s in ordered]
    check(-1 not in at and at==sorted(at),
          'Gold pit event must hide stone before pause/Strength/quake/text')
    source_guard = push.split('TryPushingBoulder:',1)[1].split('ld a, [wd728]',1)[0]
    check(all(t in source_guard for t in ('cp JOHTO_RUNTIME_MAP_HANDLE\n\tjr nz, .checkStrength',
          'cp JOHTO_ICE_PATH_B1F_LOCAL_ID\n\tjr nz, .checkStrength', 'bit 7, a\n\tret nz',
          '.checkStrength')) and
          source_guard.index('cp JOHTO_ICE_PATH_B1F_LOCAL_ID') < source_guard.index('bit 7, a'),
          'B1F pending move must keep wBoulderSpriteIndex stable; Kanto bypasses guard')
    check('callab BeginJohtoGoldStrengthDust369L' in push.split('TryPushingBoulder:',1)[1].split('DoBoulderDustAnimation:',1)[0] and
          'callab AnimateBoulderDustQuiet369K' in effect and
          'cp JOHTO_RUNTIME_MAP_HANDLE\n\tret z\n\tld a, SFX_CUT\n\tjp PlaySound' in effect and
          'callab PlayStrengthPushSFX369L' in push and
          'ld a, GSSFX_BURNED_TOWER_STRENGTH' in dust,
          'Johto must skip spurious CUT but Kanto must retain its sound/animation')
    check('ld [rOBP1]' not in kanto and 'ld c, 8 ; number of steps in animation' in kanto and
          'call Delay3' in kanto,
          'Kanto prior quiet smoke must remain unchanged')
    check('db "REF-369@"' in read(VER), 'version REF-369@ missing')
    return errors


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,default=Path('.'))
    errors=audit(parser.parse_args().root)
    for x in errors:print('FAIL:',x)
    if errors:raise SystemExit(1)
    print('PASS: push completes before B1F pit; no wait stalls; Gold dust cadence; Kanto sound preserved (source-only)')
