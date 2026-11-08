"""REF-358 PC parent-menu B-return responsiveness, anchored to real source.

The supplied 357修复.mp4 contains a trailing GBPK-INPUT-LOG. Video-time B-down
to parent-menu frame difference is documented separately, not emulator timing proof.
This is a targeted ASM contract; no ROM or controller simulation is claimed.
"""
from pathlib import Path
import re
import pytest

ROOT = Path(__file__).resolve().parents[2]


def src(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


def section(rel, first, last):
    code = src(rel)
    assert first in code and last in code
    return code.split(first, 1)[1].split(last, 1)[0]


def active_code(code):
    return '\n'.join(line.split(';', 1)[0] for line in code.splitlines())


def test_parent_screen_visible_before_b_release_poll():
    menu = section('engine/menu/players_pc.asm', 'PlayerPCMenu:', 'ExitPlayerPC:')
    a = active_code(menu)
    assert a.index('call LoadScreenTilesFromBuffer2DisableBGTransfer') < a.index('ld de, WhatDoYouWantText')
    prompt = a.index('ld de, WhatDoYouWantText')
    after_prompt = a.index('call PlaceString', prompt)
    reveal = a.index('ld [H_AUTOBGTRANSFERENABLED], a', after_prompt)
    delay = a.index('call Delay3', reveal)
    poll = a.index('\n.waitForBRelease\n', delay)
    ready = a.index('\n.bReleased\n', poll)
    input_call = a.index('call HandleMenuInput', ready)
    assert prompt < after_prompt < reveal < delay < poll < ready < input_call
    assert 'call PrintText' not in a
    # The only backward branch inside the release gate repeats the poll,
    # never re-renders the background or parent prompt.
    release = a.split('\n.waitForBRelease\n', 1)[1].split('\n.bReleased\n', 1)[0]
    assert re.search(r'call Joypad\s+ld a,\[hJoyHeld\]\s+and B_BUTTON\s+'
                     r'jr z,\.bReleased\s+call DelayFrame\s+'
                     r'jr \.waitForBRelease', release)
    assert 'TextBoxBorder' not in release and 'PlaceString' not in release


def test_menu_fixed_text_matches_original_message_box_layout():
    a = active_code(section('engine/menu/players_pc.asm',
                            'PlayerPCMenu:', 'ExitPlayerPC:'))
    assert re.search(r'coord hl, 0, 12\s+lb bc, 4, 18\s+'
                     r'call TextBoxBorder\s+coord hl, 1, 14\s+'
                     r'ld de, WhatDoYouWantText\s+call PlaceString', a)
    box = src('engine/menu/text_box.asm')
    assert 'db MESSAGE_BOX,       0, 12, 19, 17' in box
    string = active_code(section('engine/menu/players_pc.asm',
                                 'WhatDoYouWantText:', 'WhatToDepositText:'))
    assert re.search(r'db "What do you want"\s+next "to do\?"\s+db "@"', string)
    assert 'TX_FAR' not in string
    place = src('home/text.asm')
    assert 'PlaceString::' in place and 'cp $4E ; next' in place


def test_old_far_text_and_wrapper_are_comment_only():
    menu = src('engine/menu/players_pc.asm')
    txt = src('text.asm')
    for name in ('WhatDoYouWantText:', 'TX_FAR _WhatDoYouWantText'):
        assert any(line.lstrip().startswith(';') and name in line
                   for line in menu.splitlines())
    for name in ('_WhatDoYouWantText::', 'text "What do you want"',
                 'line "to do?"', 'done'):
        assert re.search(r'^;\s*' + re.escape(name) + r'$', txt, re.M)
    assert '_WhatDoYouWantText' not in active_code(menu + '\n' + txt)


@pytest.mark.parametrize('begin,end', [
    ('PlayerPCDeposit:', 'PlayerPCWithdraw:'),
    ('PlayerPCWithdraw:', 'PlayerPCToss:'),
    ('PlayerPCToss:', 'PlayersPCMenuEntries:'),
])
def test_three_item_list_cancels_still_return_to_parent_once(begin, end):
    a = active_code(section('engine/menu/players_pc.asm', begin, end))
    assert 'call DisplayListMenuID\n\tjp c, PlayerPCMenu' in a
    assert 'jp ExitPlayerPC' not in a


def test_bills_mon_menu_unmodified_and_ref358_test_version():
    a = src('engine/menu/bills_pc.asm')
    assert 'call DisplayMonListMenu\n\tjp c, BillsPCMenu' in a
    assert 'ld hl, WhatText\n\tcall PrintText' in a
    assert 'GameVersionText::' in src('data/game_version.asm')
    pc = src('engine/menu/players_pc.asm')
    assert 'ld [wParentMenuItem], a' in pc
    assert 'wBattleBagDescriptionCache' in src('engine/menu/bag_pockets.asm')
    assert 'wBattleBagDescriptionCache:: ds 1' in src('wram.asm')
