from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def table_values(source, label):
    body = source.split(f"{label}:\n", 1)[1].split(f"{label}End:", 1)[0]
    values = []
    for line in body.splitlines():
        line = line.strip()
        if line.startswith("db "):
            values.extend(int(value.strip(), 0) for value in line[3:].split(","))
    return values


def audit_source(overworld, fade, vblank, wram, hram, version, init):
    door = overworld.split("PlayMapChangeSound::", 1)[1].split("ExtraWarpCheck::", 1)[0]
    # REF-353: normal and dark-cave warps share the LCD-on loader; only the
    # palette fade stage differs if the currently visible scene is already dim.
    assert "ret nz ; leave Kanto Rock Tunnel" not in door
    assert "jp GBFadeOutToWhite" not in door
    assert door.index("ldh [hMapLoadVRAMSafeFlag],a") < door.index("ldh a,[rBGP]")
    assert "call GBFadeOutToBlackDarkBG353" in door
    assert "call GBFadeOutToBlackAlreadyDark353" in door
    assert door.index("ldh [hDoorwayCGBFadeActive],a") < door.index("call GBFadeOutToBlack")
    clear = "xor a\n\tldh [hDoorwayCGBFadeActive],a"
    assert clear in door
    assert door.index("call GBFadeOutToBlack") < door.index(clear)
    safe_loader_arm = "ld a,1\n\tldh [hMapLoadVRAMSafeFlag],a"
    assert door.index(clear) < door.index(safe_loader_arm)
    assert "cp $fe" in door
    assert ".armLCDOnDoor353" in door

    common = fade.split("GBFadeDecCommon:\n", 1)[1].split("; HAX: some of these palettes", 1)[0]
    assert common.index("ldh [hDoorwayFadeTargetBGP], a") < common.index("callab DoorwayFadePreparePalette")
    assert common.index("callab DoorwayFadePreparePalette") < common.index("ld [rOBP1], a")
    assert common.index("callab DoorwayFadePreparePalette") < common.index("ld [rOBP0], a")
    assert common.index("callab DoorwayFadePreparePalette") < common.index("ld [rBGP], a")
    assert common.index("\tdi\n") < common.index("ld [rOBP1], a")
    assert common.index("ld [rBGP], a") < common.index("ei") < common.index("ld c, 8")
    assert "push bc\n\tpush de\n\tpush hl" in common
    assert "pop hl\n\tpop de\n\tpop bc" in common
    assert "ld c, 8\n\tcall DelayFrames" in common
    assert "ld b, 4\n\tjr GBFadeDecCommon" in fade
    assert "FadePal1:: db %11111111, %11111111, %11111111" in fade
    assert "FadePal2:: db %11111110, %11111110, %11111110" in fade
    assert "FadePal3:: db %11111001, %11111001, %11111001" in fade
    assert "FadePal4:: db %11100100, %11100100, %11100100" in fade

    set_color = vblank.split("SetColor:\n", 1)[1].split("SetBlackColor:", 1)[0]
    assert "ldh a,[hDoorwayCGBFadeActive]" in set_color
    assert "cp $f9" in set_color and "cp $fe" in set_color
    assert "add LOW(W2_DoorwayFadeOneThirdBuffer)" in set_color
    assert "ld d,HIGH(W2_DoorwayFadeTwoThirdsBuffer)" in set_color

    bg_mapping = vblank.split(".doNextBgPal:", 1)[1].split(".checkSprPalettes", 1)[0]
    obj_mapping = vblank.split("\n.checkDoorwaySprIdentity\n", 1)[1].split("\n.doNextSprColor\n", 1)[0]
    assert "cp $f9" in bg_mapping and "cp $fe" in bg_mapping and "ld d,$e4" in bg_mapping
    assert "cp $f9" in obj_mapping and "cp $fe" in obj_mapping and "ld d,$e4" in obj_mapping

    prepare = vblank.split("DoorwayFadePreparePalette:\n", 1)[1].split("; Floor-scaled", 1)[0]
    assert "ld de,W2_DoorwayFadeTwoThirdsBuffer" in prepare
    assert "ld de,W2_DoorwayFadeOneThirdBuffer" in prepare
    assert prepare.count("ld de,W2_DoorwayFadeTwoThirdsBuffer") == 1
    assert prepare.count("ld de,W2_DoorwayFadeOneThirdBuffer") == 1
    assert "ld hl,W2_BgPaletteData" in prepare
    assert "ld c,64" in prepare
    assert "ldh [hDoorwayFadeSavedSVBK],a" in prepare
    assert "ld [rSVBK],a\n\tret" in prepare
    assert "ld hl,DoorwayFadeScaleTwoThirds" in prepare
    assert "ld hl,DoorwayFadeScaleOneThird" in prepare
    assert "ld a,l\n\tld [W2_DoorwayFadeScaleTableLow],a\n\tld a,h\n\tld [W2_DoorwayFadeScaleTableHigh],a" in prepare
    assert prepare.index("ld [rSVBK],a") < prepare.index("ld [W2_DoorwayFadeScaleTableLow],a")
    assert prepare.index("ld [W2_DoorwayFadeScaleTableHigh],a") < prepare.index("ld hl,W2_BgPaletteData")
    full_pointer_lookup = (
        "ld a,[W2_DoorwayFadeScaleTableLow]\n\tld l,a\n"
        "\tld a,[W2_DoorwayFadeScaleTableHigh]\n\tld h,a\n"
        "\tadd hl,de\n\tld a,[hl]"
    )
    assert prepare.count(full_pointer_lookup) == 3
    assert "ld h,b" not in prepare
    assert "srl a\n\tsrl a\n\tsrl a\n\tsrl a\n\tsrl a\n\tld e,a" in prepare
    assert "and 3\n\tadd a\n\tadd a\n\tadd a\n\tor e\n\tld e,a\n\tld d,0" in prepare
    assert "ld a,[W2_DoorwayFadeTempR]\n\tor e" in prepare
    assert "ld a,[W2_DoorwayFadeTempB]\n\tadd a\n\tadd a\n\tor e" in prepare

    batch = vblank.split("RefreshPalettesVBlank:\n", 1)[1].split("\n.normalPaletteRefresh\n", 1)[0]
    assert "cp $f9" in batch and "cp $fe" in batch and "cp $ff" in batch
    assert batch.index("W2_BgPaletteDataModified") < batch.index("W2_SprPaletteDataModified")
    assert batch.index("W2_SprPaletteDataModified") < batch.index("call .checkScanline")
    assert batch.count("call .load8") == 2
    assert batch.index("W2_BgPaletteDataModified],a") < batch.index("W2_SprPaletteDataModified],a")

    assert "hDoorwayCGBFadeActive  EQU $FFDE" in hram
    assert "hDoorwayFadeSavedSVBK  EQU $FFDF" in hram
    assert 'db "REF-363@"' in version
    assert "ldh [hDoorwayCGBFadeActive], a" in init
    assert "W2_DoorwayFadeTwoThirdsBuffer + $80 == W2_DoorwayFadeOneThirdBuffer" in wram
    assert "W2_DoorwayFadeOneThirdBuffer + $80 == W2_TilesetPaletteMap" in wram
    assert "LOW(W2_DoorwayFadeOneThirdBuffer) == $80" in wram
    assert "W2_DoorwayFadeScaleTableLow  EQU $d089" in wram
    assert "W2_DoorwayFadeScaleTableHigh EQU $d08a" in wram
    assert "W2_DoorwayFadeScaleTableHigh < W2_DoorwayFadeTwoThirdsBuffer" in wram


def rgb555_scale(color, table):
    red = color & 0x1F
    green = (color >> 5) & 0x1F
    blue = (color >> 10) & 0x1F
    return table[red] | (table[green] << 5) | (table[blue] << 10)


def test_rgb555_scale_tables_match_floor_ratios_for_all_5bit_channels():
    source = read("color/vblank.asm")
    two_thirds = table_values(source, "DoorwayFadeScaleTwoThirds")
    one_third = table_values(source, "DoorwayFadeScaleOneThird")
    assert len(two_thirds) == len(one_third) == 32
    assert two_thirds == [(value * 2) // 3 for value in range(32)]
    assert one_third == [value // 3 for value in range(32)]


def test_rgb555_packing_is_uniform_for_every_valid_color():
    source = read("color/vblank.asm")
    two_thirds = table_values(source, "DoorwayFadeScaleTwoThirds")
    one_third = table_values(source, "DoorwayFadeScaleOneThird")
    expected_two = [(value * 2) // 3 for value in range(32)]
    expected_one = [value // 3 for value in range(32)]
    for color in range(0x8000):
        scaled_two = rgb555_scale(color, two_thirds)
        scaled_one = rgb555_scale(color, one_third)
        assert scaled_one <= scaled_two <= color
        assert scaled_two == rgb555_scale(color, expected_two)
        assert scaled_one == rgb555_scale(color, expected_one)


def test_rgb555_lookup_tables_do_not_require_inline_section_alignment():
    source = read("color/vblank.asm")
    tables = source.split("; Floor-scaled 5-bit channel values.", 1)[1]
    assert not any(line.strip().startswith("ALIGN") for line in tables.splitlines())
    assert "DoorwayFadeScaleTwoThirdsEnd - DoorwayFadeScaleTwoThirds == 32" in tables
    assert "DoorwayFadeScaleOneThirdEnd - DoorwayFadeScaleOneThird == 32" in tables
    prepare = source.split("DoorwayFadePreparePalette:\n", 1)[1].split("; Floor-scaled", 1)[0]
    assert prepare.count("add hl,de") == 3
    assert "ld a,[W2_DoorwayFadeScaleTableLow]" in prepare
    assert "ld a,[W2_DoorwayFadeScaleTableHigh]" in prepare


def test_doorway_rgb555_fade_is_scoped_and_keeps_bg_obj_in_one_vblank():
    audit_source(
        read("home/overworld.asm"),
        read("home/fade.asm"),
        read("color/vblank.asm"),
        read("color/wram.asm"),
        read("hram.asm"),
        read("data/game_version.asm"),
        read("color/init.asm"),
    )


def test_negative_injection_reusing_the_active_stage_buffer_is_rejected():
    overworld = read("home/overworld.asm")
    fade = read("home/fade.asm")
    vblank = read("color/vblank.asm").replace(
        "ld de,W2_DoorwayFadeOneThirdBuffer",
        "ld de,W2_DoorwayFadeTwoThirdsBuffer",
        1,
    )
    with pytest.raises(AssertionError):
        audit_source(
            overworld, fade, vblank, read("color/wram.asm"), read("hram.asm"),
            read("data/game_version.asm"), read("color/init.asm")
        )


def test_negative_injection_leaving_the_doorway_flag_armed_is_rejected():
    import pytest

    overworld = read("home/overworld.asm").replace(
        "xor a\n\tldh [hDoorwayCGBFadeActive],a",
        "",
        1,
    )
    with pytest.raises(AssertionError):
        audit_source(
            overworld, read("home/fade.asm"), read("color/vblank.asm"),
            read("color/wram.asm"), read("hram.asm"),
            read("data/game_version.asm"), read("color/init.asm")
        )


def test_negative_injection_reenabling_dmg_shade_remap_is_rejected():
    vblank = read("color/vblank.asm").replace("ld d,$e4", "ld d,a", 1)
    with pytest.raises(AssertionError):
        audit_source(
            read("home/overworld.asm"), read("home/fade.asm"), vblank,
            read("color/wram.asm"), read("hram.asm"),
            read("data/game_version.asm"), read("color/init.asm")
        )
