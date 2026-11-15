#!/usr/bin/env python3
"""REF-369G Gold Ice Path B1F post-boulder-drop feedback contract.

Inspects reachable B1F stone/pit completion sequence and one-shot state
barrier. Static-only: ROM, MAP, device timing and save reload remain unverified.
"""
from pathlib import Path
import argparse

B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
GOLD_PITS = [(11, 2), (4, 7), (5, 12), (12, 13)]

def audit(root: Path, overrides: dict[str, str] | None = None) -> list[str]:
    root=Path(root)
    overrides=overrides or {}
    text=overrides.get(B1,(root/B1).read_text())
    errors=[]
    def check(ok, msg):
        if not ok:errors.append(msg)
    try:
        live=text.split('JohtoIcePathB1FScript367K::',1)[1].split('JohtoIcePathB1FTextPointers367K:',1)[0]
        drop=text.split('JohtoIcePathB1FCheckStoneDrop369B::',1)[1].split('; Distinguish Gold PIT',1)[0]
    except IndexError:
        return ['active map/drop entry labels missing']
    check('bit 7, [hl]' in live and 'res 7, [hl]' in live and 'jp JohtoIcePathB1FCheckStoneDrop369B' in live,
          'dust-completion one-shot gating is missing')
    check('call CheckBoulderCoords' in drop and 'ret nc' in drop and
          'db 2, 11, 7, 4, 12, 5, 13, 12, $ff' in drop,
          'Gold four PIT coordinate detection incorrect')
    check('and b\n    ret nz ; a filled hole cannot receive another boulder' in drop,
          'occupied pit must not trigger the fall feedback twice')
    ordered=['or b\n    ld [hl], a','call JohtoIcePathB1FHideDropped369B',
             'ld c, 60\n    call DelayFrames','ld a, GSSFX_BURNED_TOWER_STRENGTH\n    call PlaySound',
             'call JohtoIcePathGoldQuake369M','ld c, 16\n    call DelayFrames',
             'ld a, 5 ; B1F script-only text pointer, above four object sprite IDs\n    ld [hSpriteIndexOrTextID], a\n    jp DisplayTextID']
    pos=[drop.find(x) for x in ordered]
    check(-1 not in pos and pos==sorted(pos) and len(set(pos))==len(pos),
          'Gold fall one-shot order: saved state -> hide -> 60-frame pause -> sound -> 16-step 2px shake -> 16-frame rest -> text')
    check(drop.count('call JohtoIcePathGoldQuake369M') == 1 and
          '.quake80' not in drop and 'ld b, 5' not in drop,
          'Gold earthquake 80 is encoded ($50), not five 16-step quakes')
    check('db $04, $08, $10, $20' in drop and 'db $10, $20, $40, $80' in drop,
          'source/pit event masks changed')
    check('JohtoIcePathB1FBoulderFellText369G:\n    text "The boulder fell"\n    line "through."\n    done\n    db "@"' in drop,
          'Gold boulder-fell-through message/terminator missing')
    check('db "REF-369@"' in (root/'data/game_version.asm').read_text(),
          'developer version must be REF-369@')
    check('call JohtoIcePathGoldQuake369M' in drop and
          'JohtoIcePathGoldQuake369M::' in text and 'ld e, 2' in text and 'xor $fc' in text,
          'dedicated Gold amplitude-2 quake symbol missing')
    return errors

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',default='.')
    errs=audit(Path(parser.parse_args().root))
    if errs:
        print(*['FAIL: '+e for e in errs],sep='\n')
        raise SystemExit(1)
    print('PASS: Gold B1F four-stone one-shot fall pause 60f/quake 32f+rest 32f/text; static only')
