#!/usr/bin/env python3
"""REF-369U source-only guard: shared black warp, Ice Path cave OBJ tint,
B2F visible fallen stones on first fade frame and Seafoam isolation.

This is *not* an emulator test, ROM compile, or palette/framebuffer capture.
"""
from __future__ import annotations
import argparse
from pathlib import Path

FALL = 'data/johto_burned_tower/REF348_b1f_runtime.asm'
PALETTE = 'color/sprites.asm'
OBJ_PAL = 'color/data/spritepalettes.asm'
B2F = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
SEAFOAM = 'scripts/SeafoamIslands4.asm'
VERSION = 'data/game_version.asm'


def audit(root: Path, overrides: dict[str, str] | None = None) -> list[str]:
    overrides = overrides or {}
    def read(path: str) -> str:
        return overrides.get(path, (root/path).read_text())
    fall = read(FALL)
    palette = read(PALETTE)
    nite = read(OBJ_PAL)
    b2f = read(B2F)
    seafoam = read(SEAFOAM)
    errors = []
    def check(ok: bool, issue: str) -> None:
        if not ok:
            errors.append(issue)

    selector = fall.split('JohtoBurnedTowerMaybeFallWarp::', 1)[-1].split('JohtoEnterMapAnimationDispatcher::', 1)[0]
    check(selector.count('jp PlaySilentMapChange369V') == 1 and
          'GBFadeOutToWhite' not in selector and
          'set 7, [hl]' in selector and
          'cp JOHTO_ICE_PATH_B1F_LOCAL_ID' in selector and
          'cp JOHTO_BURNED_TOWER_1F_LOCAL_ID' in selector,
          'Burned Tower / Ice Path PIT must share ordinary cave black exit; keep skyfall selector')
    anim = fall.split('JohtoBurnedTowerFallEntryAnim::', 1)[-1].split('JohtoBurnedTowerEarthquake16::', 1)[0]
    check(anim.count('call GBFadeInFromBlack') == 1 and
          'GBFadeInFromWhite' not in anim and
          'callba InitFacingDirectionList' in anim and
          'ld a, GSSFX_BURNED_TOWER_KINESIS' in anim and
          'call JohtoBurnedTowerEarthquake16' in anim,
          'shared skyfall movement must fade in black, preserve fall animation and sounds')

    dispatch = fall.split('JohtoEnterMapAnimationDispatcher::', 1)[-1].split('JohtoBurnedTowerFallEntryAnim::', 1)[0]
    init = 'callab JohtoIcePathInitializePitState369B'
    sync = 'callab JohtoIcePathB2FMahoganySyncLanded369B'
    check(all(x in dispatch for x in [init, sync, 'cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID']) and
          dispatch.count(init) == 1 and dispatch.count(sync) == 1 and
          dispatch.index(init) < dispatch.index(sync) < dispatch.index('bit 7, a') and
          'call UpdateSprites' not in dispatch,
          'B2F saved sprite coordinates and PIT state must be synced before fade; ineffective UpdateSprites must stay reverted')
    check('SPRITE_BOULDER' in b2f and
          all(f'ld [wSpriteStateData1 + ${i}2], a' in b2f for i in range(1,5)),
          'B2F still hides all four unfilled rock sprites on first visible frame')

    palette_selector = palette.split('LoadOverworldSpritePalettes:', 1)[-1].split('.gotPaletteList', 1)[0]
    # The first branch after ICE_CAVERN may end in .gotPaletteList; inspect the
    # whole function instead of the first substring for this condition.
    palette_selector = palette.split('LoadOverworldSpritePalettes:', 1)[-1].split('LoadAttackSpritePalettes:', 1)[0]
    check('ld hl,SpritePalettesNite' in palette_selector and
          'cp JOHTO_ICE_PATH\n\tjr z, .gotPaletteList' in palette_selector and
          palette_selector.index('cp JOHTO_ICE_PATH') < palette_selector.index('ld hl,SpritePalettesPokecenter'),
          'Gold Ice Path objects must use existing cave/night sprite palette, not day yellow ROCK')
    assign = palette.split('SpritePaletteAssignments:', 1)[-1]
    check('; 0x52: SPRITE_BOULDER\n\tdb PAL_OW_ROCK' in assign and
          '; PAL_OW_ROCK' in nite.split('SpritePalettesNite:', 1)[-1],
          'retain shared BOULDER palette assignment and existing grey cave palette for Kanto/Burned Tower')
    check('predef HideObject' in seafoam and 'predef ShowObject' in seafoam and
          'SetEventReuseHL EVENT_SEAFOAM4_BOULDER1_DOWN_HOLE' in seafoam,
          'Seafoam Islands uses its own hide/show flag transition, not Johto B2F sprite priming')
    check('db "REF-369@"' in read(VERSION), 'developer version must be REF-369@')
    return errors


def main() -> int:
    arg = argparse.ArgumentParser()
    arg.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    root = arg.parse_args().root
    errors = audit(root)
    for e in errors:
        print('FAIL:', e)
    if not errors:
        print('PASS_SOURCE_ONLY: silent black PIT fade, Ice Path cave OBJ palette, B2F saved visibility sync, Seafoam isolation')
    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
