from pathlib import Path
import pytest
from tools.johto_ice_path_pit_arrival_visual_369u_audit import audit, FALL, PALETTE, B2F, SEAFOAM, VERSION

ROOT = Path(__file__).resolve().parents[2]


def test_source_gate():
    assert audit(ROOT) == []


@pytest.mark.parametrize('path, old, new, issue', [
    (FALL, 'jp PlaySilentMapChange369V', 'jp GBFadeOutToWhite', 'black exit'),
    (FALL, 'call GBFadeInFromBlack', 'call GBFadeInFromWhite', 'fade in black'),
    (FALL, '    ; REF-369U pre-fade UpdateSprites had no visible benefit in the phone test.\n', '    call UpdateSprites\n', 'saved sprite coordinates'),
    (FALL, 'callab JohtoIcePathB2FMahoganySyncLanded369B', 'callab JohtoIcePathInitializePitState369B', 'sprite coordinates'),
    (FALL, 'ld a, GSSFX_BURNED_TOWER_KINESIS', 'ld a, SFX_CUT', 'fall animation'),
    (PALETTE, '\tcp JOHTO_ICE_PATH\n\tjr z, .gotPaletteList\n', '', 'night sprite palette'),
    (PALETTE, '; 0x52: SPRITE_BOULDER\n\tdb PAL_OW_ROCK', '; 0x52: SPRITE_BOULDER\n\tdb PAL_OW_RED', 'BOULDER palette'),
    (SEAFOAM, '\tpredef ShowObject', '\tpredef HideObject', 'Seafoam'),
    (VERSION, 'REF-369@', 'REF-369T@', 'developer version'),
])
def test_mutated_source_fails(path, old, new, issue):
    source = (ROOT/path).read_text()
    assert old in source, (path, old)
    mutated = source.replace(old, new, 1)
    assert any(issue in e for e in audit(ROOT, {path: mutated}))
