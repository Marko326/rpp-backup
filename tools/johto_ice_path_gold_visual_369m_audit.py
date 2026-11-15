#!/usr/bin/env python3
"""REF-369M source gate: Gold dust palette, region isolation, quake amplitude/order.

Not ROM, emulator or phone validation.
"""
from pathlib import Path
import argparse
DUST='engine/overworld/johto_gold_strength_dust_369l.asm'
PUSH='engine/overworld/push_boulder.asm'
KANTO='engine/overworld/ssanne.asm'
B1='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
BURNED='data/johto_burned_tower/REF348_b1f_runtime.asm'
VERSION='data/game_version.asm'

def audit(root:Path, overrides=None):
    root=Path(root);overrides=overrides or {};errors=[]
    def read(p):return overrides.get(p,(root/p).read_text())
    def check(value,why):
        if not value:errors.append(why)
    dust=read(DUST);push=read(PUSH);b1=read(B1);burned=read(BURNED)
    kanto=read(KANTO)
    try:
        live=push.split('DoBoulderDustAnimation:',1)[1].split('ResetBoulderPushFlags:',1)[0]
        render=dust.split('DrawJohtoGoldStrengthDust369L::',1)[1]
        quake=b1.split('JohtoIcePathGoldQuake369M::',1)[1].split('; Distinguish Gold PIT',1)[0]
        fall=b1.split('JohtoIcePathB1FCheckStoneDrop369B::',1)[1].split('\n.pitCoords\n',1)[0]
    except IndexError:return ['live Gold visual entry missing']
    check('ld a, $10 | PAL_OW_EMOJI' in render and
          'ld a, $17' not in render and 'ld [rOBP1]' not in dust,
          'Gold EMOTE index 5 required; ROCK index 7 and global flash forbidden')
    check('callab BeginJohtoGoldStrengthDust369L' in push.split('TryPushingBoulder:',1)[1].split('DoBoulderDustAnimation:',1)[0] and
          'callab AnimateBoulderDustQuiet369K' in live and
          push.find('callab BeginJohtoGoldStrengthDust369L') < push.find('callab AnimateBoulderDustQuiet369K') and
          'cp JOHTO_RUNTIME_MAP_HANDLE' in live and 'jr nz, .kantoQuietDust' in live,
          'Johto/Kanto Strength animation branch changed')
    check('ld [rOBP1]' not in kanto and 'ld a, $81' in kanto and
          'ld c, 8 ; number of steps in animation' in kanto and
          'call Delay3' in kanto,
          'Kanto smoke motion/pacing or no-flash invariant changed')
    check('ld e, 2' in quake and 'xor $fc' in quake and
          'ld b, 16' in quake and 'ld c, 2\n    call DelayFrames' in quake and
          'ld [hSCY], a ; restore before static wait and text' in quake,
          'Ice Path Gold 16-step +/-2px quake or SCY restoration incorrect')
    order=['call JohtoIcePathB1FHideDropped369B', 'ld c, 60\n    call DelayFrames',
           'ld a, GSSFX_BURNED_TOWER_STRENGTH\n    call PlaySound',
           'call JohtoIcePathGoldQuake369M', 'ld c, 16\n    call DelayFrames',
           'ld a, 5 ; B1F script-only text pointer']
    at=[fall.find(x) for x in order]
    check(-1 not in at and at==sorted(at) and fall.count('call JohtoIcePathGoldQuake369M')==1,
          'B1F hide / pause / sound / quake / 16f-rest / text order invalid')
    check('callab JohtoBurnedTowerEarthquake16' not in fall and
          'JohtoBurnedTowerEarthquake16::' in burned and
          'ld e, 1' in burned,
          'Burned Tower legacy quake must stay unchanged and be isolated')
    check('db "REF-369@"' in read(VERSION), 'version contract REF-369@ missing')
    return errors

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--root',default='.');args=ap.parse_args()
    errs=audit(Path(args.root))
    if errs:print(*('FAIL: '+e for e in errs),sep='\n');raise SystemExit(1)
    print('PASS: Gold EMOTE palette, isolated 2px B1F quake, 16f rest, Kanto unchanged (source only)')
