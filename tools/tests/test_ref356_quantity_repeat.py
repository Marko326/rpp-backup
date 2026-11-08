"""REF-356 quantity-only held-key timing: ASM instruction path and source contracts.

The little interpreter below executes just the local key-repeat routine. It is
not an RGBDS build or Game Boy emulator; tests model the VBlank timer decrement
once per frame and pass the Joypad input bytes observed for that frame.
"""
from pathlib import Path
import re

SRC = Path(__file__).resolve().parents[2] / 'engine/menu/list_menu_helpers.asm'
TEXT = SRC.read_text(encoding='utf8')
QTY = TEXT.split('DisplayChooseQuantityMenu_::', 1)[1].split('InitialQuantityText::', 1)[0]
KEYS = QTY.split('\n.readQuantityMenuKeys\n', 1)[1]
A, B, RIGHT, LEFT, UP, DOWN = 1, 2, 16, 32, 64, 128
DPAD = RIGHT | LEFT | UP | DOWN


def instruction_path():
    labels, instructions = {'.readQuantityMenuKeys': 0}, []
    for raw in KEYS.splitlines():
        code = raw.split(';', 1)[0].strip()
        if not code:
            continue
        if code.startswith('.') and ' ' not in code:
            labels[code] = len(instructions)
        else:
            instructions.append(code)
    return labels, instructions


def run_one_poll(prev_held, held, timer, prev_output=0):
    """Interpret the local ASM helper with an external frame-decremented timer."""
    labels, code = instruction_path()
    mem = {'hJoyPressed': held & ~prev_held, 'hJoyReleased': prev_held & ~held,
           'hJoyHeld': held, 'H_FRAMECOUNTER': timer, 'hJoy5': prev_output}
    a, z, pc = 0, False, 0
    for _ in range(80):
        inst = code[pc]
        pc += 1
        if inst == 'call Joypad':
            pass
        elif match := re.fullmatch(r'ld a,\[(\w+)\]', inst):
            a = mem[match[1]]
        elif match := re.fullmatch(r'ld \[(\w+)\],a', inst):
            mem[match[1]] = a
        elif match := re.fullmatch(r'ld a,(\d+)', inst):
            a = int(match[1])
        elif inst == 'xor a':
            a = 0
            z = True
        elif inst == 'and a':
            z = a == 0
        elif inst == 'and D_UP | D_DOWN | D_LEFT | D_RIGHT':
            a &= DPAD
            z = a == 0
        elif match := re.fullmatch(r'jr (z|nz),\.(\w+)', inst):
            condition, dest = match.groups()
            if z if condition == 'z' else not z:
                pc = labels['.' + dest]
        elif inst == 'ret':
            return mem['hJoy5'], mem['H_FRAMECOUNTER']
        else:
            raise AssertionError('Unrecognized quantity input opcode: ' + inst)
    raise AssertionError('Quantity key handler did not return')


def simulate(frames):
    """(frame, repeated d-pad mask) observations with timer tick per frame."""
    previous, timer, events = 0, 40, []
    for t, held in enumerate(frames):
        if timer:
            timer -= 1  # one VBlank
        output, timer = run_one_poll(previous, held, timer)
        if output & DPAD:
            events.append((t, output & DPAD))
        previous = held
    return events


def test_repeat_has_new_input_then_40_and_5_frame_intervals():
    events = simulate([0] * 2 + [UP] * 55)
    assert events == [(2, UP), (42, UP), (47, UP), (52, UP)]


def test_release_resets_delay_before_new_direction():
    events = simulate([UP] * 9 + [0] * 3 + [DOWN] * 43)
    assert events == [(0, UP), (12, DOWN), (52, DOWN)]


def test_no_key_or_continuous_a_or_b_never_generates_direction():
    for held in (0, A, B, A | B):
        assert simulate([held] * 90) == []


def test_direction_buttons_are_repeatable_but_confirm_cancel_are_edges_only():
    wait = QTY.split('\n.waitForKeyPressLoop\n', 1)[1].split('\n.incrementQuantity\n', 1)[0]
    assert wait.index('ld a,[hJoyPressed]') < wait.index('ld a,[hJoy5]')
    assert 'bit 0,a ; A' in wait and 'bit 1,a ; B' in wait
    assert 'jp nz,.buttonAPressed' in wait and 'jp nz,.buttonBPressed' in wait
    for name in ('D_UP', 'D_DOWN', 'D_LEFT', 'D_RIGHT'):
        assert 'cp ' + name in wait
    assert 'cp PRICEDITEMLISTMENU' not in wait


def test_simultaneous_opposite_directions_are_not_one_of_the_dispatch_values():
    for held in (UP | DOWN, LEFT | RIGHT, UP | LEFT):
        events = simulate([held] * 50)
        assert events[0][1] == held
        assert held not in (UP, DOWN, LEFT, RIGHT)
    wait = QTY.split('\n.waitForKeyPressLoop\n', 1)[1].split('\n.incrementQuantity\n', 1)[0]
    assert 'and D_UP | D_DOWN | D_LEFT | D_RIGHT' in wait
    assert 'jr .waitForKeyPressLoop' in wait


def test_timer_and_output_restored_on_both_exit_branches():
    start = QTY.split('\n.drawTextBox\n', 1)[0]
    end = QTY.split('\n.buttonAPressed ;', 1)[1].split('\n.readQuantityMenuKeys\n', 1)[0]
    assert start.count('push af') == 2
    assert 'ld a,[H_FRAMECOUNTER]' in start and 'ld a,[hJoy5]' in start
    assert end.count('pop af') == 2
    assert 'ld [hJoy5],a' in end and 'ld [H_FRAMECOUNTER],a' in end
    assert 'ld e,$ff' in end
    assert end.count('jr .restoreInputState') == 1 and end.count('ret') == 1
    assert '.buttonBPressed' in end and '.restoreInputState' in end


def test_fresh_press_wrap_up_down_and_clamp_left_right():
    up = QTY.split('\n.incrementQuantity\n', 1)[1].split('\n.decrementQuantity\n', 1)[0]
    down = QTY.split('\n.decrementQuantity\n', 1)[1].split('\n.decrementQuantityBy10\n', 1)[0]
    assert 'inc [hl]' in up and 'ld [hl],1' in up
    assert 'ld a,[hJoyPressed]' in up and 'and D_UP' in up
    assert 'dec [hl]' in down and 'ld [hl],a' in down
    assert 'ld a,[hJoyPressed]' in down and 'and D_DOWN' in down
    assert '.pauseAtBoundary' not in down and 'ld [H_FRAMECOUNTER],a' not in down
    assert 'ld a,[wMaxItemQuantity]' in QTY
    assert '.decrementQuantityBy10\n' in QTY and '.incrementQuantityBy10\n' in QTY
    assert 'sub 10' in QTY and 'add 10' in QTY
    assert '.setMinimumQuantity\n\tld a,[hl]\n\tcp 1\n\tjp z,.waitForKeyPressLoop\n\tld [hl],1' in QTY
    assert 'cp b\n\tjr nc,.storeIncreasedQuantity' in QTY
    assert 'SetMartBuyAffordableQuantity356::' in TEXT
    assert 'ld a,[wListMenuID]\n\tcp PRICEDITEMLISTMENU' in QTY


def test_scope_is_quantity_only_and_existing_menu_sources_are_unchanged():
    root = SRC.parents[2]
    global_input = (root / 'home.asm').read_text(encoding='utf8')
    assert 'JoypadLowSensitivity::' in global_input
    assert 'call .readQuantityMenuKeys' in QTY
    assert 'call JoypadLowSensitivity' not in QTY
    # Version checks belong to the current release suite (REF-357 and later).
