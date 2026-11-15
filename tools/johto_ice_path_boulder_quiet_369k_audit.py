#!/usr/bin/env python3
"""REF-369L: Gold Johto dust and quiet Kanto guard; replaces REF-369K audit."""
from pathlib import Path
import argparse
PUSH='engine/overworld/push_boulder.asm'
DUST='engine/overworld/ssanne.asm'
VERSION='data/game_version.asm'
def audit(root:Path,overrides=None):
 root=Path(root); overrides=overrides or {}
 def read(p):return overrides.get(p,(root/p).read_text())
 errors=[]
 try:
  pushfull=read(PUSH)
  begin=pushfull.split('TryPushingBoulder:',1)[1].split('DoBoulderDustAnimation:',1)[0]
  push=pushfull.split('DoBoulderDustAnimation:',1)[1].split('ResetBoulderPushFlags:',1)[0]
 except IndexError:return ['missing actual Strength animation entry']
 for part in ('cp JOHTO_RUNTIME_MAP_HANDLE','jr nz, .kantoQuietDust',
              'jr .dustFinished',
              '.kantoQuietDust','callab AnimateBoulderDustQuiet369K',
              '.dustFinished','call DiscardButtonPresses'):
  idx=push.find(part)
  if idx<0:errors.append('missing live path: '+part)
 order=[push.find(s) for s in ('cp JOHTO_RUNTIME_MAP_HANDLE',
  '\n.kantoQuietDust','callab AnimateBoulderDustQuiet369K')]
 if 'callab BeginJohtoGoldStrengthDust369L' not in begin:errors.append('Gold dust must start at accepted push')
 if order!=sorted(order):errors.append('Johto / Kanto branch order is wrong')
 if 'callab AnimateBoulderDust\n' in push:errors.append('old palette-flashing Strength entry still reachable')
 if 'callab PlayStrengthPushSFX369L' not in read(PUSH):errors.append('Gold / Kanto sound dispatch missing')
 dust=read(DUST)
 if 'AnimateBoulderDustQuiet369K::\n\tld a, $81' not in dust:errors.append('quiet Kanto dust missing')
 if 'ld [rOBP1]' in dust:errors.append('global Strength palette cycle is still present')
 if 'db "REF-369@"' not in read(VERSION):errors.append('current label missing')
 return errors
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--root',default='.');errs=audit(Path(ap.parse_args().root));
 print(*errs,sep='\n') if errs else print('PASS: Johto Gold async dust; Kanto no palette flash')
 raise SystemExit(bool(errs))
