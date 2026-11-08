"""REF-356 BUY affordability and shared quantity boundaries (ASM-focused tests).

A small interpreter executes the actual affordability helper's LR35902 ops; the
pre-existing DivideBCDPredef3 is represented by its packed-BCD division contract.
No RGBDS build or ROM execution is claimed.
"""
from pathlib import Path
import re
import pytest

ROOT = Path(__file__).resolve().parents[2]
MENU = (ROOT / 'engine/menu/list_menu_helpers.asm').read_text()
MART = (ROOT / 'engine/overworld/pokemart.asm').read_text()
HELPER = MENU.split('SetMartBuyAffordableQuantity356::', 1)[1].split('InitialQuantityText::', 1)[0]
QUANTITY = MENU.split('DisplayChooseQuantityMenu_::', 1)[1].split('SetMartBuyAffordableQuantity356::', 1)[0]


def packed(n):
    return [(n // (100 ** i)) % 100 // 10 * 16 + (n // (100 ** i)) % 10 for i in (2, 1, 0)]


def unBCD(byte_triplet):
    n = 0
    for x in byte_triplet:
        n = 100 * n + ((x >> 4) * 10) + (x & 15)
    return n


def execute_affordability(money, price):
    """Interpret price->max helper, supplying original routine's BCD quotient."""
    instructions, labels = [], {}
    for raw in HELPER.splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        if line.startswith('.') and ' ' not in line:
            labels[line] = len(instructions)
        else:
            instructions.append(line)
    mem = {}
    for base, number in (('wPlayerMoney', money), ('hItemPrice', price)):
        for i, value in enumerate(packed(number)):
            mem[base + (f' + {i}' if i else '')] = value
    regs = {'a': 0, 'b': 0, 'c': 0}
    zero, pc = False, 0
    for _ in range(200):
        code = instructions[pc]
        pc += 1
        if m := re.fullmatch(r'ld ([abc]),\[(.+)\]', code):
            regs[m[1]] = mem[m[2]]
        elif m := re.fullmatch(r'ld \[(.+)\],([abc])', code):
            mem[m[1]] = regs[m[2]]
        elif m := re.fullmatch(r'ld ([abc]),([abc]|99)', code):
            regs[m[1]] = regs[m[2]] if m[2] in regs else int(m[2])
        elif code == 'or b':
            regs['a'] |= regs['b']
            zero = not regs['a']
        elif code == 'and a':
            zero = not regs['a']
        elif code == 'and $0f':
            regs['a'] &= 0x0f
            zero = not regs['a']
        elif code == 'swap a':
            a = regs['a']
            regs['a'] = ((a & 15) << 4) | (a >> 4)
        elif code == 'add a':
            regs['a'] = (regs['a'] * 2) & 255
        elif code == 'add c':
            regs['a'] = (regs['a'] + regs['c']) & 255
        elif m := re.fullmatch(r'jr (z|nz),(\.\w+)', code):
            if zero == (m[1] == 'z'):
                pc = labels[m[2]]
        elif m := re.fullmatch(r'jr (\.\w+)', code):
            pc = labels[m[1]]
        elif code == 'predef DivideBCDPredef3':
            dividend = unBCD([mem['hMoney' + (f' + {i}' if i else '')] for i in range(3)])
            divisor = unBCD([mem['hDivideBCDDivisor' + (f' + {i}' if i else '')] for i in range(3)])
            assert divisor > 0, 'Division by zero would hang the Game Boy BCD routine'
            for i, val in enumerate(packed(dividend // divisor)):
                mem['hDivideBCDQuotient' + (f' + {i}' if i else '')] = val
        elif code == 'ret':
            return mem['wMaxItemQuantity']
        else:
            raise AssertionError(f'Unexpected affordability opcode: {code}')
    raise AssertionError('Affordability helper did not return')


@pytest.mark.parametrize('balance,price,expected', [
    (10_000, 200, 50), (10_000, 201, 49),
    (10_000, 333, 30), (199, 200, 0), (200, 200, 1),
    (0, 200, 0), (100, 0, 99), (0, 0, 99),
    (999_999, 1, 99), (999_999, 999_999, 1),
    (99_999, 999, 99), (200, 999_999, 0),
    (50_000, 1_000, 50), (1_000, 2_000, 0),
])
def test_buy_affordability_uses_exact_bcd_quotient_and_caps_99(balance, price, expected):
    assert execute_affordability(balance, price) == expected


def test_buy_caller_handles_zero_before_opening_quantity_and_sell_is_unchanged():
    buy = MART.split('.buyMenuLoop\n', 1)[1].split('.returnToMainPokemartMenu\n', 1)[0]
    assert buy.index('call DisplayListMenuID_Mart') < buy.index('callab SetMartBuyAffordableQuantity356')
    assert buy.index('ld a,[wMaxItemQuantity]\n\tand a\n\tjp z,.notEnoughMoney') < buy.index('call DisplayChooseQuantityMenu')
    assert buy.index('call DisplayChooseQuantityMenu') < buy.index('call .isThereEnoughMoney')
    sell = MART.split('.sellMenu\n', 1)[1].split('.buyMenu\n', 1)[0]
    assert 'SetMartBuyAffordableQuantity356' not in sell
    assert sell.count('call DisplayChooseQuantityMenu') == 1
    assert 'ld [hHalveItemPrices],a ; halve prices when selling' in sell


def test_shared_up_down_wrap_requires_new_press_and_left_right_still_clamp():
    up = QUANTITY.split('\n.incrementQuantity\n', 1)[1].split('\n.decrementQuantity\n', 1)[0]
    down = QUANTITY.split('\n.decrementQuantity\n', 1)[1].split('\n.decrementQuantityBy10\n', 1)[0]
    assert 'cp [hl]' in up and 'inc [hl]' in up
    assert 'ld [hl],1' in up and 'and D_UP' in up
    assert 'cp 2' in down and 'and D_DOWN' in down
    assert 'dec [hl]' in down and 'ld a,[wMaxItemQuantity]' in down
    assert 'ld a,[hJoyPressed]' in up and 'ld a,[hJoyPressed]' in down
    assert 'ld [H_FRAMECOUNTER],a' not in up + down
    left = QUANTITY.split('\n.setMinimumQuantity\n', 1)[1].split('\n.incrementQuantityBy10\n', 1)[0]
    right = QUANTITY.split('\n.storeIncreasedQuantity\n', 1)[1].split('\n.handleNewQuantity\n', 1)[0]
    assert 'jp z,.waitForKeyPressLoop' in left
    assert 'jp z,.waitForKeyPressLoop' in right


def test_all_quantity_dialogs_keep_existing_repeat_and_confirmation_controls():
    assert 'ld a,40 ; first repeat after ~40 VBlanks' in QUANTITY
    assert 'ld a,5 ; subsequent repeats every ~5 VBlanks' in QUANTITY
    assert 'ld a,[hJoyPressed]' in QUANTITY
    assert 'bit 0,a ; A' in QUANTITY and 'bit 1,a ; B' in QUANTITY
    assert 'call JoypadLowSensitivity' not in QUANTITY
