#!/usr/bin/env python3
"""REF-369T source audit: shared cave transition, early landing-hide, Gold fast ice slide.

This does not execute the ROM or verify real-time graphics. Negative mutations
are exercised by tools/tests/test_johto_ice_path_pit_fade_sprite_slide_369t.py.
"""
from __future__ import annotations
from pathlib import Path
import argparse

FALL = 'data/johto_burned_tower/REF348_b1f_runtime.asm'
LANDING = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
SLIDE = 'engine/johto_ice_path_slide_368f.asm'
OVERWORLD = 'home/overworld.asm'
VERSION = 'data/game_version.asm'


def audit(root: Path, overrides: dict[str, str] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    def read(name: str) -> str:
        return overrides.get(name, (root / name).read_text())
    fall, landing, slide, overworld, ver = map(read, (FALL, LANDING, SLIDE, OVERWORLD, VERSION))
    errors = []
    def check(ok: bool, why: str) -> None:
        if not ok:
            errors.append(why)

    source = fall.split('JohtoBurnedTowerMaybeFallWarp::', 1)[-1].split('JohtoEnterMapAnimationDispatcher::', 1)[0]
    check('jp PlaySilentMapChange369V' in source and
          'GBFadeOutToWhite' not in source and
          'jp PlayMapChangeSound' not in source,
          'both Burned Tower and Ice Path player PITs must share ordinary black cave fade')
    dispatcher = fall.split('JohtoEnterMapAnimationDispatcher::', 1)[-1].split('JohtoBurnedTowerFallEntryAnim::', 1)[0]
    check('cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID' in dispatcher and
          'callab JohtoIcePathInitializePitState369B' in dispatcher and
          'callab JohtoIcePathB2FMahoganySyncLanded369B' in dispatcher and
          'call UpdateSprites' not in dispatcher and
          dispatcher.index('callab JohtoIcePathInitializePitState369B') <
          dispatcher.index('callab JohtoIcePathB2FMahoganySyncLanded369B') <
          dispatcher.index('bit 7, a'),
          'B2F saved-stone state sync must precede fade; unverified pre-render refresh stays reverted')
    anim = fall.split('JohtoBurnedTowerFallEntryAnim::', 1)[-1].split('JohtoBurnedTowerEarthquake16::', 1)[0]
    check('call GBFadeInFromBlack' in anim and 'call GBFadeInFromWhite' not in anim,
          'both player PITs must use standard black cave fade-in')
    sync = landing.split('JohtoIcePathB2FMahoganySyncLanded369B::', 1)[-1]
    for i in range(1, 5):
        render = f'ld [wSpriteStateData1 + ${i}2], a'
        pos_y = f'ld [wSpriteStateData2 + ${i}4], a'
        pos_x = f'ld [wSpriteStateData2 + ${i}5], a'
        check(render in sync and pos_y in sync and pos_x in sync and
              sync.index(render) < sync.index(pos_y) < sync.index(pos_x),
              f'B2F hidden stone {i} must invalidate its current rendered frame and position')
    force = slide.split('\n.force\n', 1)[-1].split('\n.clear\n', 1)[0]
    check('or B_BUTTON' in force and 'ld [hJoyHeld], a' in force and
          force.index('or B_BUTTON') < force.index('ld [hJoyHeld], a') and
          'ld [hJoyPressed], a' in force,
          'Gold fast_slide_step: ICE forced direction must use existing B acceleration and suppress menu input')
    check('call DoBikeSpeedup' in overworld and 'call AdvancePlayerSprite' in overworld and
          'ld a,$10\n\tld [wWalkCounter],a' in overworld,
          'keep existing 60FPS movement counter, B speedup, collision and step pipeline')
    check('REF-369@' in ver, 'development version marker not advanced to REF-369@')
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    problems = audit(args.root)
    for p in problems:
        print('FAIL:', p)
    if not problems:
        print('PASS_SOURCE_ONLY: Ice Path black cave PIT fade, B2F early stone hide, Gold STEP_ICE fast pacing')
    return bool(problems)


if __name__ == '__main__':
    raise SystemExit(main())
