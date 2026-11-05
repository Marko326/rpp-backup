"""REF-350: ROM0 safe-exit invariants for the small sprite-reset migration."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[2]

OLD_BODY = """	ld hl, wSpriteStateData1
	call ResetPlayerSpriteData_ClearSpriteData
	ld hl, wSpriteStateData2
	call ResetPlayerSpriteData_ClearSpriteData
	ld a, $1
	ld [wSpriteStateData1], a
	ld [wSpriteStateData2 + $0e], a
	ld hl, wSpriteStateData1 + 4
	ld [hl], $3c     ; set Y screen pos
	inc hl
	inc hl
	ld [hl], $40     ; set X screen pos
	ret
"""

def test_sprite_reset_body_is_identical_to_original():
    bank = (ROOT / 'home/rom0_relief_349.asm').read_text()
    assert 'ResetPlayerSpriteData_ROMX::\n' + OLD_BODY in bank
    assert 'ResetPlayerSpriteData_ClearSpriteData::\n\tld bc, $10\n\txor a\n\tjp FillMemory' in bank

def test_home_gateway_preserves_return_a_and_bank():
    home=(ROOT / 'home.asm').read_text()
    assert re.search(r'ResetPlayerSpriteData::\n\tcallab ResetPlayerSpriteData_ROMX\n\tld a, \$1\n\tret',home)
    assert 'ASSERT BANK(ResetPlayerSpriteData_ROMX) == $2a' in (ROOT/'home/rom0_relief_349.asm').read_text()

def test_existing_bank1_call_footprint_is_not_increased():
    for file in ('engine/oak_speech.asm','engine/menu/main_menu.asm'):
        src=(ROOT/file).read_text()
        assert re.search(r'\bcall ResetPlayerSpriteData\b',src)
        assert not re.search(r'\bcallab ResetPlayerSpriteData\b',src)

def test_no_other_direct_calls_to_romx_private_helper():
    for file in ROOT.rglob('*.asm'):
        if file.relative_to(ROOT).as_posix()=='home/rom0_relief_349.asm': continue
        data=file.read_text(errors='ignore')
        assert not re.search(r'\b(call|jp) ResetPlayerSpriteData_ClearSpriteData\b',data)
