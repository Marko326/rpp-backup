from pathlib import Path
from tools.johto_strength_gold_dust_369l_audit import audit,PUSH,OAM,GOLD,WRAM,MAIN,TODO
ROOT=Path(__file__).parents[2]

def alter(path,old,new):
    s=(ROOT/path).read_text();assert old in s
    return {path:s.replace(old,new,1)}

def test_gold_source_static():assert audit(ROOT)==[]

def test_kanto_flash_rejected():
    assert audit(ROOT,alter(PUSH,'callab AnimateBoulderDustQuiet369K\n.dustFinished',
                              'callab AnimateBoulderDust\n.dustFinished'))

def test_johto_fallback_rejected():
    assert audit(ROOT,alter(PUSH,'callab BeginJohtoGoldStrengthDust369L',
                              'callab AnimateBoulderDustQuiet369K'))

def test_global_palette_write_rejected():
    assert audit(ROOT,alter(GOLD,'ld a, $10 | PAL_OW_EMOJI',
                              'ld [rOBP1], a\n    ld a, $10 | PAL_OW_EMOJI'))

def test_oam_last_slots_reserved():
    assert audit(ROOT,alter(GOLD,'cp $84 ; need 16 bytes;','cp $90 ; need 16 bytes;'))

def test_ledge_fishing_guard():
    assert audit(ROOT,alter(GOLD,'bit 6, a\n    jp nz, .done','bit 6, a\n    nop'))

def test_uses_one_oam_append():
    assert audit(ROOT,alter(GOLD,'ld [hOAMBufferOffset], a','nop'))

def test_wrong_art_or_tile_count():
    assert audit(ROOT,alter(GOLD,'lb bc, BANK(JohtoGoldStrengthDustGFX369L), 2',
                                'lb bc, BANK(JohtoGoldStrengthDustGFX369L), 4'))

def test_no_temp_lifetime():
    assert audit(ROOT,alter(GOLD,'ld [hl], 64 ; original pre-hide duration',
                                'ld [hl], 1 ; very short'))

def test_not_in_bank0():
    assert audit(ROOT,alter(MAIN,'SECTION "Johto Gold Strength Dust", ROMX',
                                'SECTION "Johto Gold Strength Dust", ROM0'))

def test_wram_length_preserved():
    assert audit(ROOT,alter(WRAM,'wJohtoGoldDustSlot2Source369R:: ; cd54\n\tds 1', 'wJohtoGoldDustSlot2Source369R:: ; cd54\n\tds 2'))

def test_todo_cannot_claim_phone_done():
    assert audit(ROOT,alter(TODO,'**[ ] 待验收**','**[x] 已验收**'))

def test_push_must_finish_before_b1f_pit_check():
    assert audit(ROOT,alter(GOLD,'    call CopyVideoData\n    ret',
                                'ret ; broken: pit check runs while boulder still moving'))

def test_obsolete_kanto_palette_write_rejected():
    from tools.johto_ice_path_boulder_quiet_369k_audit import DUST
    assert audit(ROOT,alter(DUST,'call LoadSmokeTileFourTimes',
                                'ld [rOBP1], a\n\tcall LoadSmokeTileFourTimes'))
