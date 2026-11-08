"""REF-359 behavior: remove obsolete Player PC list questions, retain source history.

Source-level assertions only; not an RGBDS link or ROM execution test.
"""
from pathlib import Path
import re
import pytest

ROOT = Path(__file__).resolve().parents[2]
MENU = (ROOT / 'engine/menu/players_pc.asm').read_text(encoding='utf-8')
TEXT = (ROOT / 'text.asm').read_text(encoding='utf-8')


def active(s):
    return '\n'.join(row.split(';', 1)[0] for row in s.splitlines())


@pytest.mark.parametrize('operation,next_label,tail', [
    ('Deposit', 'PlayerPCWithdraw:', 'to deposit?'),
    ('Withdraw', 'PlayerPCToss:', 'to withdraw?'),
    ('Toss', 'PlayersPCMenuEntries:', 'to toss away?'),
])
def test_whole_deprecated_question_chain_is_commented(operation, next_label, tail):
    start = 'PlayerPC' + operation + ':'
    block = MENU.split(start, 1)[1].split(next_label, 1)[0]
    loop = block.split('\n.loop\n', 1)[1].split('call DisplayListMenuID', 1)[0]
    label = f'WhatTo{operation}Text'
    # The exact original two instructions must remain as comments at the
    # original .loop position, ahead of list setup.
    assert re.search(r'^\s*; ld hl, ' + label + r'\s*$', loop, re.M)
    assert re.search(r'^\s*; call PrintText\s*$', loop, re.M)
    # The wrapper and text must survive as whole contiguous commented chains.
    assert (f'; {label}:\n; \tTX_FAR _{label}\n; \tdb "@"') in MENU
    assert (f'; _{label}::\n; \ttext "What do you want"\n'
            f'; \tline "{tail}"\n; \tdone') in TEXT
    assert label not in active(MENU + '\n' + TEXT)
    assert 'call PrintText' not in active(loop)
    # The list is still rebuilt normally, including returning to parent on B.
    assert 'call DisplayListMenuID' in active(block)
    assert 'jp c, PlayerPCMenu' in active(block)
    assert 'callba RestoreItemListPosition' in active(block)


def test_quantity_empty_inventory_and_transaction_messages_still_live():
    a = active(MENU)
    for label in ('NothingToDepositText', 'NothingStoredText',
                  'DepositHowManyText', 'WithdrawHowManyText', 'TossHowManyText',
                  'NoRoomToStoreText', 'CantCarryMoreText',
                  'ItemWasStoredText', 'WithdrewItemText',
                  'HMItemCantBeStoredText'):
        assert re.search(r'^' + label + r':$', a, re.M)
    for op in ('Deposit', 'Withdraw', 'Toss'):
        assert re.search(r'^' + op + r'HowManyText:', a, re.M)
    assert 'ld de, WhatDoYouWantText' in a  # parent menu remains intact
    assert 'call PlaceString' in a
    assert 'call RefreshPlayerPCItemDescription' in active((ROOT/'home.asm').read_text())


def test_version_and_other_pc_and_mart_routes_unchanged():
    # Historical REF-359 behavior must survive later versions (REF-360+).
    version = (ROOT / 'data/game_version.asm').read_text()
    number = re.search(r'db "REF-(\d+)@"', version)
    assert number and int(number.group(1)) >= 359
    bills = (ROOT/'engine/menu/bills_pc.asm').read_text()
    assert 'call DisplayMonListMenu\n\tjp c, BillsPCMenu' in bills
    shop = (ROOT/'engine/overworld/pokemart.asm').read_text()
    assert 'call DisplayListMenuID' in shop
    assert 'callab SetMartBuyAffordableQuantity356' in shop
    assert 'ld hl,wBattleBagDescriptionCache' in (ROOT/'engine/menu/bag_pockets.asm').read_text()
