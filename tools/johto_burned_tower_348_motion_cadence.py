#!/usr/bin/env python3
"""Static Gold-vs-RPP visual cadence contract. Never builds a ROM."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parent.parent

def check(text):
    def need(s,label):
        if not s: raise AssertionError(label)
    fall=text.split('JohtoBurnedTowerFallEntryAnim::',1)[1].split('\n.SkyfallOffsets',1)[0]
    shake=text.split('JohtoBurnedTowerEarthquake16::',1)[1]
    need('ld c, 16' in fall, 'Gold initial 16-frame skyfall pause changed')
    need(bool(re.search(r'\.skyfallLoop.*?ld c, 2[^\n]*\n\s*call DelayFrames',fall,re.S)), 'Skyfall must hold each offset for 2 captured frames')
    need(bool(re.search(r'ld c, 32[^\n]*\n\s*call DelayFrames',fall)), 'Gold 16 movement-tick post-shake sleep not preserved')
    need(bool(re.search(r'\.shakeLoop.*?ld c, 2[^\n]*\n\s*call DelayFrames',shake,re.S)), 'Gold shake must change direction every 2 captured frames')
    need('xor $fe' in shake and 'ld [hSCY], a' in shake, 'existing elevator vertical-shake core lost')
    need('ld b, 16' in shake and 'ld b, 16' in fall, 'Gold 16-step cadence changed')
    return True

if __name__=='__main__':
    p=ROOT/'data/johto_burned_tower/REF348_b1f_runtime.asm'
    code=p.read_text();check(code)
    for old,new in [('ld c, 2 ; Gold skyfall','ld c, 1 ; Gold skyfall'), ('ld c, 2 ; Gold video shake','ld c, 1 ; Gold video shake'),('ld c, 32 ; Gold step_sleep','ld c, 16 ; Gold step_sleep')]:
        assert old in code
        try: check(code.replace(old,new))
        except AssertionError: pass
        else: raise AssertionError('mutation not caught: '+old)
    print('REF348 Gold motion cadence PASS + 3 negative tests')
