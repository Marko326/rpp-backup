#!/usr/bin/env python3
"""REF-369N Gold 2x2 BoulderDust OAM geometry & region isolation source audit.

This is a static check, not an emulator/ROM video verification. An optional
Gold reference root enables parsing FacingBoulderDust1/2 in source.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

ROOT_DUST='engine/overworld/johto_gold_strength_dust_369l.asm'
PUSH='engine/overworld/push_boulder.asm'
KANTO='engine/overworld/ssanne.asm'
B1='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
VER='data/game_version.asm'
OAM='engine/overworld/oam.asm'


def audit(root:Path, overrides:dict[str,str]|None=None, gold_root:Path|None=None)->list[str]:
    root=Path(root);overrides=overrides or {};errors=[]
    def read(p):return overrides.get(p,(root/p).read_text())
    def require(cond,what):
        if not cond:errors.append(what)
    dust=read(ROOT_DUST);push=read(PUSH);oam=read(OAM);kanto=read(KANTO);b1=read(B1)
    try:
        begin=dust.split('BeginJohtoGoldStrengthDust369L::',1)[1].split('DrawJohtoGoldStrengthDust369L::',1)[0]
        draw=dust.split('DrawJohtoGoldStrengthDust369L::',1)[1].split('\n.writeQuadrant\n',1)[0]
        one=dust.split('\n.writeQuadrant\n',1)[1].split('JohtoGoldStrengthDustGFX369L:',1)[0]
        live=push.split('DoBoulderDustAnimation:',1)[1].split('ResetBoulderPushFlags:',1)[0]
    except IndexError:return ['live animation entry, quadrant helper or source block missing']
    # Original Gold facings: four *same* tile IDs at 2x2 8-pixel offsets.
    call_pattern='''    call .writeQuadrant
    ld a, c
    add 8
    ld c, a
    call .writeQuadrant
    ld a, c
    sub 8
    ld c, a
    ld a, b
    add 8
    ld b, a
    call .writeQuadrant
    ld a, c
    add 8
    ld c, a
    call .writeQuadrant'''
    require(call_pattern in draw and draw.count('call .writeQuadrant')==4,
            'Gold must draw 4 same-tile OAM quadrants at 0,0 / 0,8 / 8,0 / 8,8')
    helper='    ld a, b\n    ld [de], a ; screen Y\n    inc e\n    ld a, c\n    ld [de], a ; screen X\n    inc e\n    ld a, h\n    ld [de], a ; same tile in all four quadrants\n    inc e\n    ld a, l\n    ld [de], a ; same palette in all four quadrants\n    inc e\n    ret'
    require(helper in one, 'each quadrant must still write Y,X,tile,palette and advance OAM by 4')
    require('cp $84 ; need 16 bytes;' in draw and 'bit 6, a\n    jp nz, .done' in draw,
            'Gold four quadrants need 16 OAM bytes and must preserve ledge/fishing slots')
    require('ld [hOAMBufferOffset], a' in draw and draw.count('call .writeQuadrant')==4,
            'all four quadrants must append to OAM exactly once')
    require('and 4\n    srl a\n    srl a\n    add $fc' in draw and
            'ld a, $10 | PAL_OW_EMOJI' in draw,
            'Gold two-phase and index-5 palette must remain')
    require('ld [hl], 64' in begin and 'call CopyVideoData' in begin and
            'call UpdateJohtoGoldDustAnchor369Q' in begin and
            re.search(r'^\s*(?:call|jp)\s+DelayFrames\b',begin,re.M) is None,
            'Gold pre-hide lifetime, original tile resource, no blocking wait')
    require('cp JOHTO_RUNTIME_MAP_HANDLE\n\tjr nz, .kantoQuietDust' in live and
            'callab BeginJohtoGoldStrengthDust369L' in push and
            'callab AnimateBoulderDustQuiet369K' in live and 'ld [rOBP1]' not in kanto,
            'Kanto no-flash push path must remain separate')
    require('callab DrawJohtoGoldStrengthDust369L' in oam and
            'ld [rOBP1]' not in dust,
            'OAM hook and global palette flash prohibition required')
    require('JohtoIcePathGoldQuake369M::' in b1 and 'ld e, 2' in b1 and
            'ld b, 16' in b1 and 'ld c, 16\n    call DelayFrames' in b1,
            'original Gold-like 2px quake unchanged')
    require('db "REF-369@"' in read(VER),'development label REF-369@ required')
    if gold_root:
        gold=gold_root/'data/sprites/facings.asm'
        if not gold.exists():errors.append('Gold source facings missing')
        else:
            txt=gold.read_text()
            for num,tile in ((1,'$fe'),(2,'$ff')):
                try:
                    section=txt.split(f'FacingBoulderDust{num}:',1)[1].split('\n\n',1)[0]
                    rows=[tuple(x.strip() for x in row.split(',')) for row in re.findall(r'^\s*db\s+([^;\n]+)',section,re.M) if row.count(',')==3]
                    target=[(str(y),str(x),'ABSOLUTE_TILE_ID',tile) for y,x in ((0,0),(0,8),(8,0),(8,8))]
                    require(rows==target,f'Gold reference FacingBoulderDust{num} does not match expected 2x2 tiled pattern')
                except IndexError:errors.append(f'Gold reference FacingBoulderDust{num} missing')
    return errors

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path('.'));p.add_argument('--gold-root',type=Path)
    a=p.parse_args();errors=audit(a.root,gold_root=a.gold_root)
    if errors:
        print(*(f'FAIL: {e}' for e in errors),sep='\n');raise SystemExit(1)
    print('PASS: Gold four quadrant dust, safe OAM, palette, Kanto isolation (source only)')
