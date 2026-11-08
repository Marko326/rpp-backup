"""REF-357 #45: run the bedroom PC branch and check the shared PC contract.

This is a source-level interpreter, not a compiled ROM or Game Boy emulator.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
BEDROOM = (ROOT / 'engine/menu/red_bedroom_pc.asm').read_text(encoding='utf8')
PLAYER = (ROOT / 'engine/menu/players_pc.asm').read_text(encoding='utf8')
PC = (ROOT / 'engine/menu/pc.asm').read_text(encoding='utf8')


def active_lines(source):
    return [line.split(';', 1)[0].strip() for line in source.splitlines()
            if line.split(';', 1)[0].strip()]


def run_bedroom_entry(has_pokedex):
    """Interpret actual branch and its calls, tracking the PC nesting flag."""
    lines = active_lines(BEDROOM)
    start = lines.index('OpenRedBedroomPC::')
    instructions, labels = [], {}
    for line in lines[start + 1:]:
        if line.endswith(':') or re.fullmatch(r'\.\w+', line):
            labels[line.rstrip(':')] = len(instructions)
        else:
            instructions.append(line)
    pc, zero, pc_nested = 0, False, True  # start with stale flag to test cleanup
    calls = []
    for _ in range(40):
        opcode = instructions[pc]
        pc += 1
        if opcode == 'CheckEvent EVENT_GOT_POKEDEX':
            zero = not has_pokedex
        elif opcode == 'jr z, .playerItemsOnly':
            if zero:
                pc = labels['.playerItemsOnly']
        elif opcode == 'call SaveScreenTilesToBuffer2':
            calls.append('SaveScreenTilesToBuffer2')
        elif opcode == 'ld hl, wFlags_0xcd60':
            pass
        elif opcode == 'res 3, [hl]':
            pc_nested = False
            calls.append('clear generic-PC flag')
        elif opcode in ('callba ActivatePC', 'callba PlayerPC'):
            calls.append(opcode.split(' ', 1)[1])
        elif opcode == 'ret':
            return calls, pc_nested
        else:
            raise AssertionError(f'Unexpected bedroom PC instruction: {opcode}')
    raise AssertionError('Bedroom PC entry did not return')


def test_before_pokedex_uses_standalone_item_pc_with_valid_screen_buffer():
    calls, nested = run_bedroom_entry(False)
    assert calls == ['SaveScreenTilesToBuffer2', 'clear generic-PC flag', 'PlayerPC']
    assert nested is False


def test_after_pokedex_uses_original_full_pc_without_extra_side_effects():
    calls, nested = run_bedroom_entry(True)
    assert calls == ['ActivatePC']
    assert nested is True  # early direct-PC cleanup is not run on this branch


def test_old_rejection_call_and_text_are_retained_as_inactive_comments():
    for old in ('.temporarilyUnavailable', 'ld hl, RedBedroomPCUnavailableText',
                'call PrintText', 'ret', 'RedBedroomPCUnavailableText:',
                'text "The PC can\'t be"', 'line "used right now."',
                'prompt', 'db "@"'):
        assert re.search(r'^;\s*' + re.escape(old) + r'$', BEDROOM, re.M), old
    active = '\n'.join(active_lines(BEDROOM))
    assert 'RedBedroomPCUnavailableText' not in active
    assert '.temporarilyUnavailable' not in active
    assert 'call PrintText' not in active


def test_standalone_player_pc_has_item_choices_and_restores_screen_on_exit():
    assert 'PlayerPC:' in PLAYER
    for choice in ('Withdraw Item', 'Deposit Item', 'Toss Item', 'Log off@'):
        assert choice in PLAYER
    assert 'bit 3, a ; accessing player\'s PC through another PC?' in PLAYER
    assert 'call LoadScreenTilesFromBuffer2' in PLAYER
    assert 'res 5, [hl]' in PLAYER
    assert 'res 6, [hl]' in PLAYER
    assert 'call PlaySound' in PLAYER
    assert 'call RefreshPlayerPCItemDescription' in (ROOT / 'home.asm').read_text()


def test_full_pc_and_pokedex_unlock_logic_remain_in_their_existing_modules():
    assert 'ActivatePC:' in PC
    assert 'callba DisplayPCMainMenu' in PC
    assert 'jp z, BillsPC' in PC
    assert 'callba PlayerPC' in PC
    menu = (ROOT / 'engine/menu/bills_pc.asm').read_text()
    assert 'DisplayPCMainMenu::' in menu
    assert 'CheckEvent EVENT_GOT_POKEDEX' in menu
    assert 'OaksPCText' in menu and 'LogOffPCText' in menu


def test_version_is_ref357_without_touching_other_menu_repeat_settings():
    ver = (ROOT / 'data/game_version.asm').read_text()
    assert 'GameVersionText::' in ver
    quantity = (ROOT / 'engine/menu/list_menu_helpers.asm').read_text()
    assert 'SetMartBuyAffordableQuantity356::' in quantity
    assert 'ld a,40 ; first repeat after ~40 VBlanks' in quantity
    assert 'ld a,5 ; subsequent repeats every ~5 VBlanks' in quantity
