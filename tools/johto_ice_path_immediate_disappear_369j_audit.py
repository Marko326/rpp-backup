#!/usr/bin/env python3
"""REF-369J: Gold B1F stone vanishes before pause/sound/earthquake.

Offline source guard; device and ROM build validation still necessary.
"""
from pathlib import Path
import argparse

B1='data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
HOME='home.asm'
OAM='engine/overworld/oam.asm'
VERSION='data/game_version.asm'

def audit(root:Path, overrides:dict[str,str]|None=None)->list[str]:
    root=Path(root);overrides=overrides or {}
    def read(rel):return overrides.get(rel,(root/rel).read_text())
    text=read(B1)
    errors=[]
    def ck(ok,msg):
        if not ok:errors.append(msg)
    try:
        hide=text.split('JohtoIcePathB1FHideDropped369B::',1)[1].split('JohtoIcePathB1FCheckStoneDrop369B::',1)[0]
        drop=text.split('JohtoIcePathB1FCheckStoneDrop369B::',1)[1].split('\n.pitCoords\n',1)[0]
    except IndexError:return ['B1F hide / stone-drop live entry missing']
    for i in range(1,5):
        bit=i+3
        section=hide.split(f'bit {bit}, a',1)
        if len(section)!=2:
            errors.append(f'stone {i}: missing dropped-state guard');continue
        block=section[1].split(f'bit {bit+1}, a',1)[0] if i<4 else section[1]
        # All three must be written after dec a, under this stone's event guard.
        order=['dec a',f'ld [wSpriteStateData1 + ${i*16+2:02x}], a',
               f'ld [wSpriteStateData2 + ${i*16+4:02x}], a',
               f'ld [wSpriteStateData2 + ${i*16+5:02x}], a']
        pos=[block.find(x) for x in order]
        ck(-1 not in pos and pos==sorted(pos),
           f'stone {i}: rendered C1x2=$ff must precede off-map C2 coords')
        ck(f'ld [wSpriteStateData1 + ${i*16:02x}], a' not in block,
           f'stone {i}: sprite picture ID C1x0 must stay nonzero')
    must=['call JohtoIcePathB1FHideDropped369B',
          'ld c, 60\n    call DelayFrames',
          'ld a, GSSFX_BURNED_TOWER_STRENGTH\n    call PlaySound',
          'call JohtoIcePathGoldQuake369M']
    positions=[drop.find(x) for x in must]
    ck(-1 not in positions and positions==sorted(positions),
       'Gold disappear->pause->strength sound->quake live timing order invalid')
    ck('CALL_INDIRECT PrepareOAMData' in read(HOME) and
       "cp $ff ; off-screen (don't draw)" in read(OAM),
       'DelayFrame OAM rebuild/off-screen c1x2 sentinel changed')
    ck('db "REF-369@"' in read(VERSION),'developer version must be REF-369@')
    return errors

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--root',default='.')
    errors=audit(Path(a.parse_args().root))
    for e in errors:print('FAIL:',e)
    if errors:raise SystemExit(1)
    print('PASS: four Gold boulders immediately disappear before fall feedback (source only)')
