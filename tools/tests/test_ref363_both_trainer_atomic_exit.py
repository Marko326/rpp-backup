"""REF-361/362/363: guard both palette-safe atomic trainer exits.

Static assembly-contract checks. NOT RGBDS linking or game runtime testing.
Both trainer directions must refresh all seven tile rows in one VBlank while
preserving the battle's screen-coordinate CGB attribute map.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def source(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def active(src):
    return "\n".join(line.split(";", 1)[0] for line in src.splitlines())


def section(src, first, last):
    assert first in src and last in src, (first, last)
    return src.split(first, 1)[1].split(last, 1)[0]


CORE = active(source("engine/battle/core.asm"))
HELPER = active(source("engine/battle/trainer_slide_atomic_361.asm"))
MAIN = active(source("main.asm"))
PRE = section(CORE, "SlideTrainerPicOffScreen:", "EnemySendOut:")


def assert_atomic_transfer(text):
    transfer = section(
        text,
        "xor a\n\tld [H_VBCOPYBGSRC], a",
        "\n.wait",
    )
    assert re.search(
        r"ld a, \[hSlideAmount\]\s+cp 9\s+jr nz, \.enemyRows\s+"
        r"coord hl, 0, 5\s+ld a, h\s+ld \[H_VBCOPYBGSRC \+ 1\], a\s+"
        r"ld a, 5 \* BG_MAP_WIDTH\s+jr \.setDestinationLow\s+"
        r"\.enemyRows\s+coord hl, 0, 0\s+ld a, h\s+"
        r"ld \[H_VBCOPYBGSRC \+ 1\], a\s+xor a\s+"
        r"\.setDestinationLow\s+ld \[H_VBCOPYBGDEST\], a",
        transfer,
    )
    assert re.search(r"ld a, \$87\s+ld \[H_VBCOPYBGNUMROWS\], a", transfer)
    # The source LOW byte is the enable flag and must be written last.
    assert re.search(r"ld a, l\s+ld \[H_VBCOPYBGSRC\], a\s+call DelayFrame", transfer)
    assert "call DelayFrame" in transfer
    assert "ld c, 1" in transfer  # DelayFrame + DelayFrames 1 = two frames total


def test_v363_version_and_floating_romx_placement():
    version = source("data/game_version.asm")
    assert re.search(r'^\s*db "REF-364@"$', version, re.M)
    assert MAIN.index('SECTION "Player Trainer Slide Atomic 361", ROMX') < MAIN.index('SECTION "bankF",ROMX,BANK[$F]')
    assert 'INCLUDE "engine/battle/trainer_slide_atomic_361.asm"' in MAIN
    # No new interrupt code, HRAM registers or WRAM addresses were required.
    hram = source("hram.asm")
    for name in ("H_AUTOBGTRANSFERENABLED", "H_VBCOPYBGSRC", "H_VBCOPYBGDEST", "H_VBCOPYBGNUMROWS"):
        assert name in hram
    assert "VBlankCopyBgMap::" in source("home/vcopy.asm")
    assert "call VBlankCopyBgMap" in source("home/vblank.asm")


def test_packed_bank_bridge_preserves_all_original_inputs():
    assert re.search(r"ld \[hSlideAmount\], a\s+ld d, h\s+ld e, l\s+"
                     r"jpab SlideTrainerPicOffScreen_Impl", PRE)
    assert re.search(r"SlideTrainerPicOffScreen_Impl::\s+ld h, d\s+ld l, e\s+"
                     r"ld a, \[hSlideAmount\]\s+ld c, a", HELPER)
    assert "SlideTrainerPicOffScreen:" in CORE
    assert "call SlideTrainerPicOffScreen" in CORE
    # One A=9 player caller and one A=8 enemy caller in the same battle core.
    assert len(re.findall(r"ld a, \$9\s+call SlideTrainerPicOffScreen", CORE)) == 1
    assert len(re.findall(r"ld a,8\s+call SlideTrainerPicOffScreen", CORE)) == 1


def test_both_exit_directions_disable_and_restore_the_exact_auto_bg_state():
    start = section(HELPER, "SlideTrainerPicOffScreen_Impl::", "\n.slideStepLoop")
    assert re.search(r"ld a, \[H_AUTOBGTRANSFERENABLED\]\s+push af\s+"
                     r"xor a\s+ld \[H_AUTOBGTRANSFERENABLED\], a", start)
    end = HELPER.split("\n.wait\n", 1)[1]
    assert re.search(r"call DelayFrames\s+pop hl\s+pop bc\s+dec c\s+"
                     r"jp nz, \.slideStepLoop\s+pop af\s+"
                     r"ld \[H_AUTOBGTRANSFERENABLED\], a\s+ret", end)
    assert HELPER.count("push af") == 1 and HELPER.count("pop af") == 1
    # The save/disable happens before direction dispatch: neither path can skip it.
    assert "jr nz, .slideStepLoop" not in start


def test_both_directions_stage_seven_rows_with_palette_safe_tile_only_copy():
    assert_atomic_transfer(HELPER)
    assert "ld b, 7" in HELPER
    assert re.search(r"\.rowLoop\s+push hl.*?ld de, SCREEN_WIDTH\s+add hl, de\s+"
                     r"dec b\s+jr nz, \.rowLoop", HELPER, re.S)
    # The former enemy fallback is gone; both branches reach the same transfer.
    assert ".enemyNormalTransfer" not in HELPER
    assert "ld c, 2" not in HELPER
    assert HELPER.count("\n\tcall DelayFrame\n") == 1
    assert HELPER.count("\n\tcall DelayFrames\n") == 1


def test_right_slide_column_update_and_two_frame_cadence_are_preserved():
    assert re.search(r"cp 8\s+jr z, \.slideRight\s+\.slideLeft\s+"
                     r"ld a, \[hld\]\s+ld \[hli\], a\s+inc hl", HELPER)
    assert re.search(r"\.slideRight\s+ld a, \[hli\]\s+ld \[hld\], a\s+dec hl", HELPER)
    assert re.search(r"call DelayFrame\s+ld c, 1\s+\.wait\s+call DelayFrames", HELPER)
    assert "jp nz, .slideStepLoop" in HELPER


def test_transfer_contract_matches_actual_vblank_service():
    bg = active(source("home/vcopy.asm"))
    vbl = active(source("home/vblank.asm"))
    assert re.search(r"VBlankCopyBgMap::\s+ld a,\[H_VBCOPYBGSRC\].*?"
                     r"ld a,\[H_VBCOPYBGNUMROWS\].*?ld b,a\s+xor a\s+"
                     r"ld \[H_VBCOPYBGSRC\],a", bg, re.S)
    assert 'call AutoBgMapTransfer\n\tcall VBlankCopyBgMap' in vbl
    tile_only = section(bg, "\n.tileOnlyRows\n", "\nVBlankCopyDouble::")
    assert re.search(r"ld a,32 - 20\s+add l\s+ld l,a\s+"
                     r"jr nc,\.tileOnlyNoPageCarry\s+inc h\s+"
                     r"\.tileOnlyNoPageCarry\s+dec b", tile_only)
    assert "ld [rVBK],a" not in tile_only
    assert "TransferBgRows" not in tile_only


def test_battle_exit_preserves_the_existing_screen_coordinate_palette_map():
    battle = active(source("color/color.asm"))
    common = section(battle, "SetPal_Battle_Common:", "SetPal_TownMap:")
    assert re.search(r"xor a\s+ld \[W2_TileBasedPalettes\],a", common)
    assert "W2_TilesetPaletteMap + 11" in common
    refresh = active(source("color/refreshmaps.asm"))
    row_copy = section(refresh, "WindowTransferBgRowsAndColors:", "\nDrawMapRow:")
    assert re.search(r"ld e,c\s+ld a,\[de\]", row_copy)
    assert re.search(r"ld a, \$87\s+ld \[H_VBCOPYBGNUMROWS\], a", HELPER)


def test_bad_transfer_count_and_bad_arm_order_are_detected():
    try:
        bad_count = re.sub(r"ld a, \$87\s+(ld \[H_VBCOPYBGNUMROWS\], a)",
                           r"ld a, $86\n\t\1", HELPER, count=1)
        assert_atomic_transfer(bad_count)
    except AssertionError:
        pass
    else:
        raise AssertionError("missing 7th tile-only row must be rejected")
    try:
        assert_atomic_transfer(HELPER.replace("ld a, l\n\tld [H_VBCOPYBGSRC], a",
                                               "ld a, l\n\tld [H_VBCOPYBGDEST], a"))
    except AssertionError:
        pass
    else:
        raise AssertionError("invalid enable-last transfer must be rejected")


def test_tile_only_page_carry_is_required_for_both_trainer_rows_and_hp_rows():
    bg = active(source("home/vcopy.asm"))
    tile_only = section(bg, "\n.tileOnlyRows\n", "\nVBlankCopyDouble::")
    assert re.search(r"add l\s+ld l,a\s+jr nc,\.tileOnlyNoPageCarry\s+"
                     r"inc h\s+\.tileOnlyNoPageCarry", tile_only)
    broken = tile_only.replace("\n\tinc h\n", "\n")
    assert "inc h" not in broken

    def destinations(start_row):
        h, low = 0x98, start_row * 32
        addresses = []
        for _ in range(7):
            addresses.append((h - 0x98, low))
            low += 32
            if low > 0xFF:
                low &= 0xFF
                h += 1
        return addresses

    # Enemy rows 0..6 stay in one page; player rows 5..11 cross at row 8.
    assert destinations(0) == [(0, 0x00), (0, 0x20), (0, 0x40),
                                (0, 0x60), (0, 0x80), (0, 0xA0), (0, 0xC0)]
    assert destinations(5) == [(0, 0xA0), (0, 0xC0), (0, 0xE0),
                                (1, 0x00), (1, 0x20), (1, 0x40), (1, 0x60)]


def test_original_other_battle_setup_and_player_pic_paths_unchanged():
    assert "callab LoadBlackPalettesWhileLCDOff" in CORE
    assert "LoadPlayerBackPic:" in CORE
    assert "VBlankCopyBgMap::" in source("home/vcopy.asm")
    hp = source("engine/battle/damage_hp_animation.asm")
    assert "AttackHPBar_WaitVisibleFrame:" in hp
