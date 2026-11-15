#!/usr/bin/env python3
"""REF-369L two-region Strength dust audit: guards actual OAM and Gold lifecycle.

Static/source only. Exact graphical identity still requires ROM and emulator frames.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import struct

PUSH='engine/overworld/push_boulder.asm'
OAM='engine/overworld/oam.asm'
GOLD='engine/overworld/johto_gold_strength_dust_369l.asm'
WRAM='wram.asm'
MAIN='main.asm'
ART='gfx/overworld/johto_gold_boulder_dust.png'
TODO='TODO.md'


def audit(root:Path, overrides=None, reference_gold:Path|None=None)->list[str]:
    root=Path(root); overrides=overrides or {}; errors=[]
    def read(path):return overrides.get(path,(root/path).read_text())
    def check(ok,msg):
        if not ok:errors.append(msg)
    push=read(PUSH); oam=read(OAM); dust=read(GOLD); wram=read(WRAM); olddust=read('engine/overworld/ssanne.asm')
    body=push.split('DoBoulderDustAnimation:',1)[1].split('ResetBoulderPushFlags:',1)[0]
    goldbranch=body.split('\n.kantoQuietDust',1)[0]
    kantobranch=body.split('\n.kantoQuietDust',1)[1]
    check('cp JOHTO_RUNTIME_MAP_HANDLE' in goldbranch and
          'callab BeginJohtoGoldStrengthDust369L' in push.split('TryPushingBoulder:',1)[1].split('DoBoulderDustAnimation:',1)[0],
          'Johto Gold temp dust must be selected at live Strength entry')
    check('callab AnimateBoulderDustQuiet369K' in kantobranch and
          'callab AnimateBoulderDust\n' not in body,
          'Kanto must not call global palette-cycling animation')
    check('ld [rOBP1]' not in olddust and 'xor %01100100' not in olddust,
          'obsolete Kanto global palette flash must be removed from the renderer')
    check('callab PlayStrengthPushSFX369L' in push and
          'ld a, SFX_PUSH_BOULDER' in dust and
          'ld a, GSSFX_BURNED_TOWER_STRENGTH' in dust,
          'region-appropriate push sounds must remain selected')
    start=dust.split('BeginJohtoGoldStrengthDust369L::',1)[1].split('DrawJohtoGoldStrengthDust369L::',1)[0]
    check('ld [hl], b' in start and
          'ld hl, wJohtoGoldDustSlot2Y369R' in start and
          'ld [hl], 64' in start and
          'lb bc, BANK(JohtoGoldStrengthDustGFX369L), 2' in start and
          'call CopyVideoData' in start and
          'call DelayFrames' not in start and
          'jp DelayFrames' not in start and
          '    ret\n' in start,
          'Gold dust must cache screen XY, frame lifetime and original 2-tile art')
    check('ld [hl], 64' in start and
          'call Delay3' not in start and 'ld [rOBP1]' not in dust,
          'Gold dust must be independent of push and never cycle rOBP1')
    renderer=dust.split('DrawJohtoGoldStrengthDust369L::',1)[1]
    check('cp JOHTO_RUNTIME_MAP_HANDLE' in renderer and
          'ld [wJohtoGoldDustFrames], a' in renderer and
          'bit 6, a\n    jp nz, .done' in renderer and
          'cp $84 ; need 16 bytes;' in renderer,
          'OAM renderer requires region, lifetime, reserved ledge slots and capacity guards')
    check('ld [hOAMBufferOffset], a' in renderer and
          'ld d, HIGH(wOAMBuffer)' in renderer and
          'add $fc' in renderer and
          renderer.count('call .writeQuadrant') == 4 and
          'ld a, $10 | PAL_OW_EMOJI' in renderer and
          'ld a, $17' not in renderer,
          'Gold four-quadrant two-frame sprite append or palette is missing')
    check('ld a, [wJohtoGoldDustFrames]' in oam and
          'callab DrawJohtoGoldStrengthDust369L' in oam and
          oam.index('callab DrawJohtoGoldStrengthDust369L') < oam.index('; Clear unused OAM.'),
          'Gold OAM must be composed after sprites, before unused-slot clear')
    check('wWhichAnimationOffsets:: ; cd50\n; Scratch' in wram and
          'wJohtoGoldDustSlot2Y369R:: ; cd51' in wram and
          'wJohtoGoldDustSlot2Source369R:: ; cd54\n\tds 1\n\tds 1 ; CD55' in wram and
          'wJohtoGoldDustDirection:: ; cd56' in wram and
          'wJohtoGoldDustSpriteIndex:: ; cd57' in wram and
          'wJohtoGoldDustFrames:: ; cd58' in wram and
          '\tds 1 ; CD55: original final scratch byte' in wram,
          'must reuse only last 3 bytes of existing 9-byte WRAM scratch without resizing')
    check('SECTION "Johto Gold Strength Dust", ROMX\nINCLUDE' in read(MAIN),
          'Gold logic must live outside BANK0 and fixed Bank3')
    check('INCBIN "gfx/overworld/johto_gold_boulder_dust.2bpp"' in dust,
          'Gold source artwork must be included as ROM tile resource')
    art=root/ART
    check(art.exists(), 'Gold dust PNG missing')
    if art.exists():
        data=art.read_bytes()
        shape=struct.unpack('>II', data[16:24]) if data[:8]==b'\x89PNG\r\n\x1a\n' and len(data)>=24 else None
        check(shape == (8,16), 'Gold sprite art must have exactly two 8x8 frames')
        if reference_gold and reference_gold.exists():
            check(art.read_bytes() == reference_gold.read_bytes(),
                  'dust artwork differs from the supplied Gold source PNG')
    todo=read(TODO)
    check('**怪力推动岩石的局部视觉反馈（源码实现 REF-369L）**' in todo and
          '**[ ] 待验收**' in todo, 'TODO must mark code done while preserving device acceptance')
    return errors


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',default='.');p.add_argument('--gold-png');a=p.parse_args()
    errors=audit(Path(a.root),reference_gold=Path(a.gold_png) if a.gold_png else None)
    if errors:print(*('FAIL: '+err for err in errors),sep='\n');raise SystemExit(1)
    print('PASS: Gold Johto transient dust & Kanto quiet; static only')
