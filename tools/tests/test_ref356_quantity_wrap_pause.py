"""REF-356 quantity rollover only on NEW press; continuous holds stop at edge.

Executes the actual UP/DOWN LR35902 source branches against the existing
40/5-frame input interpreter. This is a targeted source model, not a ROM build.
"""
from pathlib import Path
import re
import pytest

from test_ref356_quantity_repeat import UP, DOWN, run_one_poll

SRC = Path(__file__).resolve().parents[2] / 'engine/menu/list_menu_helpers.asm'
ASM = SRC.read_text(encoding='utf8')
BLOCK = ASM.split('\n.incrementQuantity\n', 1)[1].split('\n.decrementQuantityBy10\n', 1)[0]


def execute_up_down(direction, quantity, maximum, pressed):
    """Interpret the real up/down branches, including hJoyPressed gate."""
    code, labels = [], {'.incrementQuantity': 0}
    for raw in BLOCK.splitlines():
        inst = raw.split(';', 1)[0].strip()
        if not inst:
            continue
        if re.fullmatch(r'\.\w+', inst):
            labels[inst] = len(code)
        else:
            code.append(inst)
    a = 0
    zero = carry = False
    pc = labels['.incrementQuantity' if direction == UP else '.decrementQuantity']
    changed = False
    for _ in range(100):
        ins = code[pc]
        pc += 1
        if ins == 'ld hl,wItemQuantity':
            pass
        elif ins == 'ld a,[wMaxItemQuantity]':
            a = maximum
        elif ins == 'ld a,[hJoyPressed]':
            a = pressed
        elif ins == 'ld a,[hl]':
            a = quantity
        elif ins == 'ld [hl],a':
            quantity = a
            changed = True
        elif m := re.fullmatch(r'ld \[hl\],(\d+)', ins):
            quantity = int(m[1])
            changed = True
        elif m := re.fullmatch(r'ld a,(\d+)', ins):
            a = int(m[1])
        elif ins in ('and D_UP', 'and D_DOWN'):
            a &= UP if ins == 'and D_UP' else DOWN
            zero = a == 0
            carry = False
        elif ins == 'inc [hl]':
            quantity += 1
            changed = True
        elif ins == 'dec [hl]':
            quantity -= 1
            changed = True
        elif m := re.fullmatch(r'cp (\d+|\[hl\])', ins):
            other = quantity if m[1] == '[hl]' else int(m[1])
            zero = a == other
            carry = a < other
        elif m := re.fullmatch(r'(jp|jr) (?:(z|nz|c|nc),)?(\.\w+)', ins):
            _, condition, dest = m.groups()
            take = condition is None or {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}[condition]
            if take:
                if dest in ('.handleNewQuantity', '.waitForKeyPressLoop'):
                    return quantity, changed, dest
                pc = labels[dest]
        else:
            raise AssertionError('Unknown quantity instruction: ' + ins)
    raise AssertionError('Unbounded quantity branch')


def trace(initial, maximum, frames):
    """Feed held-key frames; collect visible quantity changes (frame, quantity)."""
    previous, timer, value, events = 0, 40, initial, []
    for frame, held in enumerate(frames):
        if timer:
            timer -= 1
        output, timer = run_one_poll(previous, held, timer)
        if output in (UP, DOWN):
            old = value
            value, changed, dest = execute_up_down(output, value, maximum, held & ~previous)
            assert 1 <= value <= maximum
            if changed and old != value:
                events.append((frame, value))
        previous = held
    return value, events


@pytest.mark.parametrize('direction,initial,limit,edge,first', [
    (UP, 48, 50, 50, 49), (DOWN, 3, 50, 1, 2),
    (UP, 7, 8, 8, 8), (DOWN, 2, 8, 1, 1),
])
def test_one_uninterrupted_hold_stops_at_boundary_forever(direction, initial, limit, edge, first):
    value, events = trace(initial, limit, [direction] * 350)
    assert value == edge
    assert events[0] == (0, first)
    assert events[-1][1] == edge
    assert all(v not in ({1} if direction == UP else {limit}) for _, v in events)
    assert events[-1][0] < 80, 'Nothing may wrap even after hundreds of held frames'


@pytest.mark.parametrize('direction,edge,wrap,after', [
    (UP, 50, 1, 2), (DOWN, 1, 50, 49),
])
def test_fresh_press_at_edge_wraps_once_then_holds_normally(direction, edge, wrap, after):
    value, events = trace(edge, 50, [direction] * 53)
    assert events[:3] == [(0, wrap), (40, after), (45, after + (1 if direction == UP else -1))]
    assert value != edge


@pytest.mark.parametrize('direction,initial,edge,wrap,after', [
    (UP, 48, 50, 1, 2), (DOWN, 3, 1, 50, 49),
])
def test_release_then_repress_at_edge_unlocks_one_wrap(direction, initial, edge, wrap, after):
    value, events = trace(initial, 50, [direction] * 190 + [0] * 5 + [direction] * 48)
    assert [e for e in events if e[0] < 190][-1][1] == edge
    assert events[-3:] == [(195, wrap), (235, after), (240, after + (1 if direction == UP else -1))]
    assert value == events[-1][1]


@pytest.mark.parametrize('direction,initial,edge', [(UP, 48, 50), (DOWN, 3, 1)])
def test_release_without_repress_does_not_wrap(direction, initial, edge):
    value, events = trace(initial, 50, [direction] * 180 + [0] * 40)
    assert value == edge and events[-1][1] == edge
    assert all(frame < 80 for frame, _ in events)


@pytest.mark.parametrize('direction,edge,wrapped', [(UP, 50, 1), (DOWN, 1, 50)])
def test_repress_and_hold_wraps_once_then_stops_at_next_edge(direction, edge, wrapped):
    # The first press starts at the edge, so it legitimately wraps. Holding
    # through another full traversal must NOT initiate a second wrap.
    value, events = trace(edge, 50, [direction] * 500)
    assert events[0] == (0, wrapped)
    assert value == edge
    assert events[-1][1] == edge
    assert sum(v == wrapped for _, v in events) == 1
    assert events[-1][0] < 350


@pytest.mark.parametrize('direction,initial,limit,expected', [
    (UP, 50, 50, 1), (DOWN, 1, 50, 50),
    (UP, 49, 50, 50), (DOWN, 2, 50, 1),
    (UP, 1, 1, 1), (DOWN, 1, 1, 1),
])
def test_single_press_wraps_only_if_already_at_edge(direction, initial, limit, expected):
    value, _ = trace(initial, limit, [direction] + [0] * 8)
    assert value == expected


def test_maximum_one_never_repaints_or_wraps_even_with_repress():
    value, events = trace(1, 1, [UP] * 100 + [0] * 2 + [UP] * 60 + [0] * 2 + [DOWN] * 100)
    assert value == 1 and events == []


def test_asm_guards_rollover_by_new_press_without_changing_bcd_or_repeat_timer():
    assert 'SetMartBuyAffordableQuantity356::' in ASM
    assert 'ld a,[wMaxItemQuantity]' in BLOCK
    assert 'ld a,[hJoyPressed]\n\tand D_UP\n\tjp z,.waitForKeyPressLoop' in BLOCK
    assert 'ld a,[hJoyPressed]\n\tand D_DOWN\n\tjp z,.waitForKeyPressLoop' in BLOCK
    assert '.pauseAtBoundary' not in BLOCK
    assert 'ld [H_FRAMECOUNTER],a' not in BLOCK
    assert 'hMoney' not in BLOCK and 'hItemPrice' not in BLOCK
