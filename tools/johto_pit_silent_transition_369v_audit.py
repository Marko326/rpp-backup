#!/usr/bin/env python3
"""REF-369V: silent player PIT transition; revert ineffective first-frame sprite refresh."""
from pathlib import Path

FALL='data/johto_burned_tower/REF348_b1f_runtime.asm'
HOME='home/overworld.asm'
SEAFOAM='scripts/SeafoamIslands2.asm'
VERSION='data/game_version.asm'


def audit(root: Path, overrides=None):
    overrides=overrides or {}
    def read(path):return overrides.get(path,(Path(root)/path).read_text())
    fall,home,seafoam,version=[read(x) for x in [FALL,HOME,SEAFOAM,VERSION]]
    issues=[]
    sel=fall.split('JohtoBurnedTowerMaybeFallWarp::',1)[-1].split('JohtoEnterMapAnimationDispatcher::',1)[0]
    entry=home.split('PlayMapChangeSound::',1)[-1].split('; These routines manage gradual fading',1)[0]
    dispatch=fall.split('JohtoEnterMapAnimationDispatcher::',1)[-1].split('JohtoBurnedTowerFallEntryAnim::',1)[0]
    anim=fall.split('JohtoBurnedTowerFallEntryAnim::',1)[-1].split('JohtoBurnedTowerEarthquake16::',1)[0]
    if not ('jp PlaySilentMapChange369V' in sel and 'jp PlayMapChangeSound' not in sel
            and 'set 7, [hl]' in sel and 'cp JOHTO_ICE_PATH_B1F_LOCAL_ID' in sel
            and 'cp JOHTO_BURNED_TOWER_1F_LOCAL_ID' in sel):
        issues.append('player PIT must use silent shared black transition (not door SFX)')
    if not ('PlaySilentMapChange369V::' in entry and
            entry.index('call PlaySound') < entry.index('PlaySilentMapChange369V::') < entry.index('GBFadeOutToBlack')
            and 'ldh [hMapLoadVRAMSafeFlag],a' in entry and 'ldh [hDoorwayCGBFadeActive],a' in entry):
        issues.append('silent fade must reuse safe ordinary map loader AFTER door sound without new HOME instructions')
    if not ('call UpdateSprites' not in dispatch and
            dispatch.count('callab JohtoIcePathInitializePitState369B') == 1 and
            dispatch.count('callab JohtoIcePathB2FMahoganySyncLanded369B') == 1 and
            dispatch.find('callab JohtoIcePathInitializePitState369B') <
            dispatch.find('callab JohtoIcePathB2FMahoganySyncLanded369B') <
            dispatch.find('bit 7, a')):
        issues.append('ineffective B2F first-frame UpdateSprites must be reverted, keep PIT visibility sync')
    if not ('call GBFadeInFromBlack' in anim and 'GBFadeInFromWhite' not in anim
            and 'ld a, GSSFX_BURNED_TOWER_KINESIS' in anim
            and 'ld a, GSSFX_BURNED_TOWER_STRENGTH' in anim):
        issues.append('keep black transition and Gold skyfall/landing audio (not door SFX)')
    if not ('predef HideObject' in seafoam and 'predef_jump ShowObject' in seafoam):
        issues.append('Kanto Seafoam original hide/show event must remain untouched')
    if 'REF-369@' not in version:issues.append('REF-369V development label missing')
    return issues

if __name__=='__main__':
    errors=audit(Path(__file__).resolve().parents[1]);print('\n'.join(errors) if errors else 'PASS_SOURCE_ONLY: silent PIT, rollback pre-refresh, Seafoam guard')
    raise SystemExit(bool(errors))
