"""REF-355 Mart SELL two-line item descriptions and Flash TODO, source checks only.

Does not execute a ROM, link RGBDS, or prove latency on a device.
"""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[2]


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


def chunk(rel, start, end):
    txt = read(rel)
    assert start in txt and end in txt, (rel, start, end)
    return txt.split(start, 1)[1].split(end, 1)[0]


def test_sell_skips_greeting_and_keeps_empty_bag_notice():
    sell = chunk('engine/overworld/pokemart.asm', '.sellMenu\n', '.buyMenu\n')
    pre_list = sell.split('.sellMenuLoop', 1)[0]
    active_pre_list = '\n'.join(row.split(';', 1)[0] for row in pre_list.splitlines())
    assert not re.search(r'^\s*call PrintText\b', active_pre_list, re.M)
    assert 'call SaveScreenTilesToBuffer1 ; save screen' in sell
    mart = read('engine/overworld/pokemart.asm')
    text = read('text.asm')
    # Keep the full historical call, wrapper and text, but not active ASM.
    for line in ('ld hl,PokemonSellingGreetingText', 'call PrintText'):
        assert f'; {line}' in pre_list
    for line in ('PokemonSellingGreetingText:',
                 'TX_FAR _PokemonSellingGreetingText', 'db "@"'):
        assert re.search(r'^;\s*' + re.escape(line) + r'$', mart, re.M)
    for line in ('_PokemonSellingGreetingText::', 'text "What would you"',
                 'line "like to sell?"', 'done'):
        assert re.search(r'^;\s*' + re.escape(line) + r'$', text, re.M)
    for code in (mart, text):
        active_asm = '\n'.join(row.split(';', 1)[0] for row in code.splitlines())
        assert 'PokemonSellingGreetingText' not in active_asm
    assert 'jp z,.bagEmpty' in sell
    assert 'ld hl,PokemartItemBagEmptyText' in sell
    assert 'ld hl,PokemartUnsellableItemText' in sell


def test_sell_menu_uses_original_list_and_temporary_gate():
    sell = chunk('engine/overworld/pokemart.asm', '.sellMenuLoop\n', '.confirmItemSale')
    for expected in ('ld hl,wNumBagItems', 'callba RestoreItemListPosition',
                     'ld a,ITEMLISTMENU', 'call DisplayListMenuID'):
        assert expected in sell
    assert 'call DisplayListMenuID_Mart' not in sell
    assert re.search(r'ld hl,wFlags_0xcd60\s+set 2,\[hl\]\s+call DisplayListMenuID'
                     r'\s+push af[^\n]*\n\s+ld hl,wFlags_0xcd60\s+res 2,\[hl\]'
                     r'\s+pop af\s+jp c,\.returnToMainPokemartMenu', sell)


def test_sell_flag_not_live_during_transaction_or_parent_menu():
    sell = chunk('engine/overworld/pokemart.asm', '.sellMenuLoop\n', '.buyMenu\n')
    i_clear = sell.index('res 2,[hl]')
    for marker in ('.confirmItemSale', 'call DisplayChooseQuantityMenu',
                   'call AddAmountSoldToMoney', '.unsellableItem', '.bagEmpty'):
        assert i_clear < sell.index(marker)
    assert sell.count('set 2,[hl]') == 1
    assert sell.count('res 2,[hl]') == 1
    assert 'jp .sellMenuLoop' in sell


def test_generic_refresh_requires_pc_or_sell_plus_valid_item_list():
    gate = chunk('home.asm', 'RefreshPlayerPCItemDescription:', 'RefreshBagPocketDescription:')
    assert 'ld a,[wBagPocketActive]\n\tand a\n\tret nz' in gate
    assert 'cp ITEMLISTMENU\n\tret nz' in gate
    assert re.search(r'bit 5,\[hl\].*?\n\s+jr nz,\.descriptionEnabled'
                     r'\s+bit 2,\[hl\].*?\n\s+ret z\s+\.descriptionEnabled',gate,re.S)
    assert 'ld a,[wMenuWatchMovingOutOfBounds]\n\tand a\n\tret z' in gate
    assert 'push bc\n\tcallba UpdatePlayerPCItemDescription\n\tpop bc' in gate
    assert 'call RefreshPlayerPCItemDescription' in read('home.asm')


def test_pc_unchanged_and_flag_reserved_documented():
    player = read('engine/menu/players_pc.asm')
    for fn in ('PlayerPCDeposit:', 'PlayerPCWithdraw:', 'PlayerPCToss:'):
        assert fn in player
    assert 'set 5, [hl]' in player and 'res 5, [hl]' in player
    assert 'bit 2: REF-355 temporary Mart Sell' in read('wram.asm')
    assert 'ds 1' in read('wram.asm').split('wFlags_0xcd60::',1)[1].split('wHPBarDamageSpeed::',1)[0]
