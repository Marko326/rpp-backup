from pathlib import Path
import pytest
from tools.johto_ice_path_pit_fade_sprite_slide_369t_audit import audit, FALL, LANDING, SLIDE

ROOT = Path(__file__).resolve().parents[2]


def test_current_source_passes():
    assert not audit(ROOT)


@pytest.mark.parametrize('path,old,new', [
    (FALL, 'jp PlaySilentMapChange369V', 'jp GBFadeOutToWhite'),
    (FALL, 'call GBFadeInFromBlack', 'call GBFadeInFromWhite'),
    (FALL, '    ; REF-369U pre-fade UpdateSprites had no visible benefit in the phone test.\n', '    call UpdateSprites\n'),
    (FALL, 'callab JohtoIcePathInitializePitState369B', 'callab JohtoIcePathB2FMahoganySyncLanded369B'),
    (FALL, 'callab JohtoIcePathB2FMahoganySyncLanded369B', 'callab JohtoIcePathInitializePitState369B'),
    (SLIDE, '    or B_BUTTON\n', ''),
    (SLIDE, '    ld [hJoyPressed], a ; block START/SELECT/A until collision/end of slide\n', ''),
    *[(LANDING, f'    ld [wSpriteStateData1 + ${i}2], a ; hide current rendered OAM frame before fade\n', '') for i in range(1,5)],
])
def test_rejects_reintroduced_bug(path, old, new):
    source = (ROOT / path).read_text()
    assert old in source
    assert audit(ROOT, {path: source.replace(old, new, 1)})
