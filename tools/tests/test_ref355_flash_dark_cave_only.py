"""REF-355 Flash cave-only gate: test the *actual ASM branches* with a
small, restricted instruction interpreter.
No ROM/PPU/GBC emulation is implied by these tests.
"""
from pathlib import Path
import re
import pytest

ROOT = Path(__file__).resolve().parents[2]
TEXT = (ROOT / 'engine/johto_dark_cave_stage2.asm').read_text(encoding='utf8')
GATE = TEXT.split('JohtoFlashEligibility349::', 1)[1].split('WaitForFlashAOnly349::', 1)[0]
WAIT_A = TEXT.split('WaitForFlashAOnly349::', 1)[1].split('JohtoDarkCavePreLCDPalette349::', 1)[0]
SYMBOLS = {
    'JOHTO_RUNTIME_MAP_HANDLE': 'J', 'MAP_REGION_JOHTO': 'JOHTO',
    'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID': 'VIOLET',
    'JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID': 'BLACKTHORN',
    'ROCK_TUNNEL_1': 'ROCK1', 'ROCK_TUNNEL_2': 'ROCK2',
}


def run_asm_gate(cur_map, region='KANTO', local='NONE', offset=0,
                 kanto_badges=0, johto_badges=0):
    """Execute the subset of LR35902 operations used in this one tiny gate.

    Unknown instructions raise an assertion instead of silently being ignored.
    """
    instructions, labels = [], {}
    for raw in GATE.splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        if line.startswith('Johto') or line.startswith('db '):
            continue
        if line.endswith(':') or re.fullmatch(r'\.[A-Za-z0-9_]+', line):
            labels[line.rstrip(':')] = len(instructions)
            continue
        instructions.append(line)
    memory = {
        'wCurMap': cur_map, 'wCurRegion': region, 'wCurLocalMapID': local,
        'wMapPalOffset': offset, 'wObtainedKantoBadges': kanto_badges,
        'wObtainedJohtoBadges': johto_badges,
    }
    a, e, flag_z, hltxt, pc = None, None, False, None, 0
    for _ in range(150):
        if pc >= len(instructions):
            raise AssertionError('Flash gate fell through without ret')
        code = instructions[pc]
        pc += 1
        if (m := re.fullmatch(r'ld a, \[(\w+)\]', code)):
            a = memory[m[1]]
        elif (m := re.fullmatch(r'cp ([A-Za-z0-9_]+)', code)):
            val = SYMBOLS.get(m[1], None)
            if val is None:
                val = int(m[1], 0)
            flag_z = a == val
        elif (m := re.fullmatch(r'bit (\d+), a', code)):
            flag_z = not bool(a & (1 << int(m[1])))
        elif (m := re.fullmatch(r'jr(?: (nz|z),)? (\.\w+)', code)):
            cond, label = m.groups()
            if cond is None or (flag_z if cond == 'z' else not flag_z):
                pc = labels[label]
        elif (m := re.fullmatch(r'ld e, ([01])', code)):
            e = int(m[1])
        elif (m := re.fullmatch(r'ld hl, (\.\w+)', code)):
            hltxt = m[1]
        elif code == 'call PrintText':
            pass  # The printed-text pointer is already in hltxt.
        elif code == 'call WaitForFlashAOnly349':
            pass  # See separate A-release/new-press instruction simulation below.
        elif code == 'ret':
            assert e is not None
            return e, hltxt
        else:
            raise AssertionError(f'Unknown gate instruction: {code}')
    raise AssertionError('Flash gate loop / runaway branch')


@pytest.mark.parametrize('cur_map,region,local,offset,kbadge,jbadge,expected', [
    ('ROUTE10', 'KANTO', 'NONE', 0, 1, 0, (1, '.notDarkText')),
    ('HOUSE', 'KANTO', 'NONE', 0, 1, 0, (1, '.notDarkText')),
    ('OTHER_CAVE', 'KANTO', 'NONE', 6, 1, 0, (1, '.notDarkText')),
    ('ROCK1', 'KANTO', 'NONE', 6, 1, 0, (0, None)),
    ('ROCK2', 'KANTO', 'NONE', 6, 1, 0, (0, None)),
    ('ROCK1', 'KANTO', 'NONE', 6, 0, 0, (1, '.badgeText')),
    ('ROCK2', 'KANTO', 'NONE', 6, 0, 0, (1, '.badgeText')),
    ('ROCK1', 'KANTO', 'NONE', 0, 1, 0, (1, '.notDarkText')),
    ('ROCK2', 'KANTO', 'NONE', 0, 1, 0, (1, '.notDarkText')),
    ('ROCK1', 'KANTO', 'NONE', 12, 1, 0, (1, '.notDarkText')),
    ('J', 'JOHTO', 'ROUTE31', 0, 1, 1, (1, '.notDarkText')),
    ('J', 'JOHTO', 'VIOLET', 12, 0, 1, (0, None)),
    ('J', 'JOHTO', 'BLACKTHORN', 12, 0, 1, (0, None)),
    ('J', 'JOHTO', 'BLACKTHORN', 12, 0, 0, (1, '.badgeText')),
    ('J', 'JOHTO', 'BLACKTHORN', 0, 1, 1, (1, '.notDarkText')),
    ('J', 'JOHTO', 'VIOLET', 12, 1, 0, (0, None)),
    ('J', 'JOHTO', 'VIOLET', 12, 0, 0, (1, '.badgeText')),
    ('J', 'JOHTO', 'VIOLET', 0, 1, 1, (1, '.notDarkText')),
    ('J', 'JOHTO', 'VIOLET', 6, 1, 1, (1, '.notDarkText')),
    ('J', 'JOHTO', 'OTHER_CAVE', 12, 1, 1, (1, '.notDarkText')),
    ('J', 'KANTO', 'VIOLET', 12, 1, 1, (1, '.notDarkText')),
])
def test_asm_cave_darkness_and_badge_decisions(cur_map, region, local, offset, kbadge, jbadge, expected):
    assert run_asm_gate(cur_map, region, local, offset, kbadge, jbadge) == expected


def test_flash_success_gate_still_controls_palette_and_effect():
    caller = (ROOT / 'engine/menu/start_sub_menus.asm').read_text(encoding='utf8')
    flash = caller.split('.flash\n', 1)[1].split('\n.dig\n', 1)[0]
    assert 'callab JohtoFlashEligibility349' in flash
    assert re.search(r'ld a, e\s+and a\s+jp nz, \.loop\s+xor a\s+ld \[wMapPalOffset\], a', flash)
    assert 'call GBPalWhiteOutWithDelay3' in flash


def simulate_fresh_a_wait(button_frames):
    """Run the actual A-only wait assembly against a sequence of button frames.

    The only modeled inputs are hJoyHeld/hJoyPressed from Joypad.  Returning
    False means no requested fresh A press occurred before the trace ended.
    """
    lines = [x.split(';', 1)[0].strip() for x in WAIT_A.splitlines()]
    lines = [x for x in lines if x]
    labels, instructions = {}, []
    for line in lines:
        if line.startswith('.') and not ' ' in line or line.endswith(':'):
            labels[line.rstrip(':')] = len(instructions)
        else:
            instructions.append(line)
    frame, pc, a, held, pressed, last, z = -1, 0, 0, 0, 0, 0, False
    for _ in range(500):
        inst = instructions[pc]
        pc += 1
        if inst == 'call DelayFrame':
            frame += 1
            if frame >= len(button_frames):
                return False
        elif inst == 'call Joypad':
            held = button_frames[frame]
            pressed = held & ~last
            last = held
        elif inst == 'ld a, [hJoyHeld]':
            a = held
        elif inst == 'ld a, [hJoyPressed]':
            a = pressed
        elif inst == 'and A_BUTTON':
            a &= 1
            z = not a
        elif inst == 'jr nz, .waitForRelease':
            if not z:
                pc = labels['.waitForRelease']
        elif inst == 'jr z, .waitForNewA':
            if z:
                pc = labels['.waitForNewA']
        elif inst in ('ld a, "▼"', 'ld a, " "', 'Coorda 18, 16'):
            continue  # Only display state; does not affect the sampled buttons.
        elif inst == 'ret':
            return True
        else:
            raise AssertionError('Unexpected Flash wait opcode: ' + inst)
    raise AssertionError('Flash A-only wait did not terminate within bounded steps')


def test_flash_rejection_requires_release_then_fresh_a_not_b():
    src = GATE.rsplit('\n.notDark\n', 1)[1].split('.badgeText\n', 1)[0]
    code = '\n'.join(line.strip() for line in src.splitlines() if not line.strip().startswith(';'))
    assert re.search(r'call PrintText\s+call WaitForFlashAOnly349\s+ld e, 1\s+ret', code)
    assert '.waitForRelease' in WAIT_A and '.waitForNewA' in WAIT_A
    assert 'ld a, [hJoyHeld]' in WAIT_A and 'ld a, [hJoyPressed]' in WAIT_A
    assert 'and A_BUTTON' in WAIT_A and 'B_BUTTON' not in WAIT_A
    assert not simulate_fresh_a_wait([1] * 12), 'Held selection A must not dismiss'
    assert not simulate_fresh_a_wait([0] * 8), 'No input must keep text open'
    assert not simulate_fresh_a_wait([0, 2, 2, 0, 2, 0]), 'B alone must not dismiss'
    assert simulate_fresh_a_wait([1, 1, 0, 0, 1]), 'New A after release must dismiss'
    assert simulate_fresh_a_wait([0, 0, 1]), 'Fresh A must dismiss'
