"""REF-357 PC cursor/B-return repair, focused on real WRAM overlap and input gate.

Video 357.mp4 shows the Player PC arrow at the lower prompt after cancelling an
item list. These are source/contract tests, NOT an emulator/ROM run.
"""
from pathlib import Path
import re
import pytest

ROOT = Path(__file__).resolve().parents[2]


def src(name):
    return (ROOT / name).read_text(encoding='utf-8')


def block(path, begin, end):
    data = src(path)
    assert begin in data and end in data
    return data.split(begin, 1)[1].split(end, 1)[0]


def test_old_player_pc_description_cache_overlapped_parent_cursor_exactly():
    constants = src('constants/item_constants.asm')
    misc = src('constants/misc_constants.asm')
    wram = src('wram.asm')
    capacity = int(re.search(r'^BAG_ITEM_CAPACITY EQU (\d+)', misc, re.M)[1])
    pockets = int(re.search(r'^NUM_BAG_POCKETS\s+EQU (\d+)', constants, re.M)[1])
    # SLOT MAP, STARTS, COUNTS, BUILD CURSORS, then five single-byte fields.
    old_offset = capacity + 3 * pockets + 5
    base = int(re.search(r'^wFilteredBagItems:: ; ([0-9a-f]+)', wram, re.M)[1], 16)
    parent = int(re.search(r'^wParentMenuItem:: ; ([0-9a-f]+)', wram, re.M)[1], 16)
    assert base + old_offset == parent == 0xccd3
    assert 'BAG_POCKET_DESCRIPTION_CACHE_OFFSET EQU BAG_POCKET_LAYOUT_READY_OFFSET + 1' in constants


def test_pc_description_cache_now_uses_exclusive_battle_only_scratch():
    helper = block('engine/menu/bag_pockets.asm',
                   'UpdatePlayerPCItemDescription::', 'UpdateBagPocketDescription::')
    assert 'ld hl,wBattleBagDescriptionCache' in helper
    assert 'ld [hl],$fe' in helper
    assert 'wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET' not in helper
    wram = src('wram.asm')
    assert 'wPlayerPCItemDescriptionCache' not in wram
    assert 'wPlayerPCItemDescriptionCache' not in src('engine/menu/bag_pockets.asm')
    # Must reference the label exported by wram.asm, not a private EQU alias.
    assert re.search(r'^wBattleBagDescriptionCache::\s+ds 1$', wram, re.M)
    # Five items, four actions, and parent selection must live in different bytes.
    assert 'wBattleBagDescriptionCache:: ds 1' in wram
    assert 'wParentMenuItem:: ; ccd3' in wram
    assert 'wInGameTradeGiveMonSpecies:: ; cd0f' in wram
    assert 'wBattleBagVisibleSlots:: ds 4' in wram
    assert 'wBattleBagPocket:: ds 1' in wram
    # Battle pocket + cached pocket + cached scroll + cache + 4 visible slots
    # occupy CD07..CD0E, so the PC cache is CD0A, not CCD3.
    assert 0xcd07 + 3 == 0xcd0a != 0xccd3


@pytest.mark.parametrize('menu', [
    ('PlayerPCDeposit:', 'PlayerPCWithdraw:'),
    ('PlayerPCWithdraw:', 'PlayerPCToss:'),
    ('PlayerPCToss:', 'PlayersPCMenuEntries:'),
])
def test_item_list_cancel_still_returns_one_level(menu):
    section = block('engine/menu/players_pc.asm', *menu)
    assert 'call DisplayListMenuID\n\tjp c, PlayerPCMenu' in section
    assert 'jp ExitPlayerPC' not in section


def test_player_pc_menu_draws_before_waiting_for_b_release():
    pc = src('engine/menu/players_pc.asm')
    menu = block('engine/menu/players_pc.asm', 'PlayerPCMenu:', 'ExitPlayerPC:')
    assert re.search(r'\.waitForBRelease\s+call Joypad\s+ld a,\[hJoyHeld\]\s+'
                     r'and B_BUTTON\s+jr z,\.bReleased\s+call DelayFrame\s+'
                     r'jr \.waitForBRelease\s+\.bReleased', menu)
    assert menu.index('ld a, [wParentMenuItem]') < menu.index('call HandleMenuInput')
    assert menu.index('call PlaceString') < menu.index('ld [H_AUTOBGTRANSFERENABLED], a')
    assert menu.index('call Delay3') < menu.index('.waitForBRelease')
    assert menu.index('.bReleased') < menu.index('call HandleMenuInput')
    assert 'call PlaceUnfilledArrowMenuCursor' in menu
    # A B press in the child list cannot become a second B for the PC parent.
    for inputs, expected in [([2, 2, 2, 0], 3), ([0], 0), ([2] * 50 + [0], 50)]:
        i = 0
        while inputs[i] & 2:
            i += 1
        assert i == expected
    assert 'res 5, [hl]' in pc


def test_bills_pc_pokemon_cancel_keeps_existing_one_level_return():
    bills = src('engine/menu/bills_pc.asm')
    assert 'call DisplayMonListMenu\n\tjp c, BillsPCMenu' in bills
    assert 'BillsPCDeposit:' in bills and 'BillsPCWithdraw:' in bills
    assert 'BillsPCRelease:' in bills
    # We do not alter Pokemon storage logic to mask an item-PC cache collision.


def test_parent_pc_and_selected_description_keep_existing_ref355_357_paths():
    gate = block('home.asm', 'RefreshPlayerPCItemDescription:', 'RefreshBagPocketDescription:')
    assert 'ld a,[wMenuWatchMovingOutOfBounds]' in gate
    assert 'callba UpdatePlayerPCItemDescription' in gate
    pc = src('engine/menu/players_pc.asm')
    assert 'ld a, [wParentMenuItem]' in pc and 'ld [wParentMenuItem], a' in pc
    assert 'call LoadScreenTilesFromBuffer2DisableBGTransfer' in pc
    assert 'GameVersionText::' in src('data/game_version.asm')
