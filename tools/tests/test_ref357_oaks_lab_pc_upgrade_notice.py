"""REF-357 #45: Oak introduces upgraded home PC after awarding the Pokédex.

Source-level call/sequence contract only; this is not a ROM execution test.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = (ROOT / 'scripts/OaksLab.asm').read_text(encoding='utf8')
TEXT = (ROOT / 'text/maps/OaksLab.asm').read_text(encoding='utf8')


def active(source):
    return '\n'.join(row.split(';', 1)[0].strip() for row in source.splitlines()
                     if row.split(';', 1)[0].strip())


def test_oak_pokedex_text_sfx_new_notice_and_terminator_are_in_order():
    wrapper = active(SCRIPT.split('OaksLabText25:', 1)[1].split('OaksLabText26:', 1)[0])
    assert re.fullmatch(r'TX_FAR _OaksLabText25\nTX_SFX_KEY_ITEM\n'
                        r'TX_FAR _OaksLabHomePCUpdatedText\ndb "@"', wrapper)
    assert SCRIPT.count('TX_FAR _OaksLabHomePCUpdatedText') == 1


def test_existing_oak_pokedex_acquisition_text_is_unchanged():
    original = TEXT.split('_OaksLabText25::', 1)[1].split('_OaksLabHomePCUpdatedText::', 1)[0]
    assert 'text "Oak: [PLAYER] and"' in original
    assert 'line "#dex from Oak!@@"' in original
    assert 'done' not in active(original)
    assert TEXT.count('_OaksLabHomePCUpdatedText::') == 1


def test_new_dialogue_is_independent_paragraph_and_fits_screen():
    block = active(TEXT.split('_OaksLabHomePCUpdatedText::', 1)[1].split('_OaksLabText26::', 1)[0])
    assert block.startswith('text ""\npara "Oak: By the way,"')
    assert block.endswith('done')
    assert block.count('para ') == 2
    assert 'home PC has' in block and '#mon now!' in block
    for line in block.splitlines():
        m = re.fullmatch(r'(?:text|para|line|cont) "(.*)"', line)
        if m:
            assert len(m[1]) <= 18, f'text line too long: {line}'


def test_story_event_and_existing_followup_remain_in_place():
    assert 'SetEvent EVENT_GOT_POKEDEX' in SCRIPT
    assert 'ld a, $19\n\tld [hSpriteIndexOrTextID], a\n\tcall DisplayTextID' in SCRIPT
    assert 'OaksLabText26:\n\tTX_FAR _OaksLabText26' in SCRIPT
    assert 'INCLUDE "scripts/OaksLab.asm"' in (ROOT / 'main.asm').read_text()
    assert 'INCLUDE "text/maps/OaksLab.asm"' in (ROOT / 'text.asm').read_text()


def test_no_new_pc_logic_or_other_reference_feature_migration():
    bedroom = (ROOT / 'engine/menu/red_bedroom_pc.asm').read_text()
    assert 'CheckEvent EVENT_GOT_POKEDEX' in bedroom
    assert 'callba ActivatePC' in bedroom and 'callba PlayerPC' in bedroom
    assert 'GameVersionText::' in (ROOT / 'data/game_version.asm').read_text()
