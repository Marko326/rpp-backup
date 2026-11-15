#!/usr/bin/env python3
"""REF-369E: hidden Ice Path stones must keep nonzero IDs on text-return reload.

This is a static regression gate, NOT ROM or video validation.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
B2 = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
SAVE = 'engine/menu/start_sub_menus.asm'
HELPERS = 'engine/menu/start_menu_helpers.asm'
SPRITES = 'engine/overworld/map_sprites.asm'
SHEETS = 'data/sprite_sets.asm'
HOME = 'home.asm'
VERSION = 'data/game_version.asm'


def active(source: str) -> str:
    return '\n'.join(line.split(';', 1)[0].strip() for line in source.splitlines()
                     if line.split(';', 1)[0].strip())


def audit(root: Path, overrides: dict[str, str] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    def get(name: str) -> str:
        return overrides.get(name, (root / name).read_text())
    errors: list[str] = []
    def ck(cond: bool, msg: str) -> None:
        if not cond:
            errors.append(msg)

    b1, b2 = active(get(B1)), active(get(B2))
    sprite = active(get(SPRITES))
    home = active(get(HOME))
    sheets = active(get(SHEETS))
    save = active(get(SAVE))
    helpers = active(get(HELPERS))
    version = active(get(VERSION))

    ck('db "REF-369@"' in version, 'REF-369E version missing')
    ck('InitMapSprites:' in sprite and 'ld a,[hl]' in sprite and
       'ld [de],a' in sprite and 'dec a\nadd a\nadd a' in sprite and
       'ld hl,SpriteSheetPointerTable' in sprite and
       'SpriteSheetPointerTableEnd::' in sheets and
       'ASSERT SpriteSheetPointerTableEnd - SpriteSheetPointerTable == SPRITE_JOHTO_OFFICER * 4' in sheets,
       'sprite picture ID lookup/guard assumptions changed; reassess zero-ID hazard')
    ck('CloseTextDisplayAfterWindowHide::' in home and
       'call InitMapSprites' in home.split('CloseTextDisplayAfterWindowHide::',1)[1].split('DisplayPokemartDialogue::',1)[0],
       'HOME text return no longer rebuilds map sprites; re-audit scope')
    for label,source,begin,end,masks in [
        ('B1F dropped',b1,'JohtoIcePathB1FHideDropped369B::','JohtoIcePathB1FCheckStoneDrop369B::',range(4,8)),
        ('B2F unlanded',b2,'JohtoIcePathB2FMahoganySyncLanded369B::',None,range(2,6)),
    ]:
        if begin not in source or (end and end not in source):
            errors.append(f'{label} live routine not found')
            continue
        body = source.split(begin,1)[1].split(end,1)[0] if end else source.split(begin,1)[1]
        for i,bit in enumerate(masks,1):
            off=i*0x10
            ck(f'bit {bit}, a' in body, f'{label} stone {i} event guard lost')
            # Sprite picture ID C1x0 is a 1-based SpriteSheetPointerTable index.
            # VRAM slot C2xE belongs to InitMapSprites, not to hide logic.
            ck(not re.search(rf'\bld\s*\[wSpriteStateData1\s*\+\s*\${off:02x}\]\s*,\s*a', body, re.I),
               f'{label} stone {i} zeroes sprite ID and can underflow table lookup')
            ck(not re.search(rf'\bld\s*\[wSpriteStateData2\s*\+\s*\${off+14:02x}\]\s*,\s*a', body, re.I),
               f'{label} stone {i} resets Sprite VRAM slot instead of just hiding')
            for delta in (4,5):
                ck(f'ld [wSpriteStateData2 + ${off+delta:02x}], a' in body,
                   f'{label} stone {i} missing off-map coordinate update')
            ck('dec a' in body, f'{label} must set off-map coordinates to $FF')

    ck('StartMenu_SaveReset:' in save and 'StartMenu_Option:' in save,
       'Save entry changed')
    if 'StartMenu_SaveReset:' in save and 'StartMenu_Option:' in save:
        live = save.split('StartMenu_SaveReset:',1)[1].split('StartMenu_Option:',1)[0]
        ck('predef SaveSAV\ncall LoadScreenTilesFromBuffer2\njp HoldTextDisplayOpen' in live,
           'restore original Save -> HOME flow; avoid speculative BG atlas reload')
        ck('ReloadTilesetTilePatterns' not in live and 'ReloadMapData' not in live,
           'previous unsuccessful Save-specific atlas reload still present')
    ck('StartMenuPrepareClose::' in helpers, 'START exit helper disappeared')
    if 'StartMenuPrepareClose::' in helpers and 'StartMenuFinishWhiteReturn::' in helpers:
        close = helpers.split('StartMenuPrepareClose::',1)[1].split('StartMenuFinishWhiteReturn::',1)[0]
        ck('ReloadTilesetTilePatterns' not in close,
           'dead-path REF-369C atlas reload remains')
    return errors


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    args=parser.parse_args()
    errors=audit(args.root)
    for err in errors:print('FAIL:',err)
    if not errors:print('PASS: REF-369E hidden boulder sprite IDs remain valid during HOME menu/text return')
    return bool(errors)

if __name__=='__main__':raise SystemExit(main())
