"""REF-353 shared ordinary-door/cave transition contracts (static only).

This does not prove RGBDS linking, timing on hardware, or phone rendering.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def src(rel):
    return (ROOT / rel).read_text(encoding="utf8")


def section(text, start, end):
    return text.split(start, 1)[1].split(end, 1)[0]


def test_kanto_rock_tunnel_enters_through_one_common_fade():
    warp = section(src("home/overworld.asm"), "WarpFound2::", "ContinueCheckWarpsNoCollisionLoop::")
    entry = re.search(r"cp ROCK_TUNNEL_1\n\s+jr nz,\.notRockTunnel\n(.*?)\n\.notRockTunnel", warp, re.S).group(1)
    assert "ld a,$06\n\tld [wMapPalOffset],a" in entry
    assert "GBFadeOutToBlack" not in entry  # the former duplicate fade is gone
    assert ".notRockTunnel\n\tcall PlayMapChangeSound" in warp
    assert "call PlayMapChangeSound\n\txor a\n\tld [wMapPalOffset],a" in warp


def test_all_ordinary_cave_warps_arm_lcd_on_like_houses():
    door = section(src("home/overworld.asm"), "PlayMapChangeSound::", "ExtraWarpCheck::")
    assert "[wMapPalOffset]" not in door
    assert "GBFadeOutToWhite" not in door
    assert "ret nz ; leave Kanto Rock Tunnel" not in door
    assert "call GBFadeOutToBlack\n\txor a\n\tldh [hDoorwayCGBFadeActive],a" in door
    assert "call GBFadeOutToBlackDarkBG353" in door
    assert "call GBFadeOutToBlackAlreadyDark353" in door
    assert door.count("ldh [hMapLoadVRAMSafeFlag],a") == 2
    assert door.index(".armLCDOnDoor353") < door.rindex("ldh [hMapLoadVRAMSafeFlag],a")


def test_cave_dark_palettes_remain_monotonic_on_every_stage():
    fade = src("home/fade.asm")
    def palette(key):
        raw = fade.split(key + "::\n", 1)[1].split("ASSERT FadePal4", 1)[0]
        rows = []
        for line in raw.splitlines():
            line = line.strip()
            if line.startswith("FadePal") and line.endswith(":"):
                break
            if line.startswith("db "):
                rows.append(tuple(int(x.strip().lstrip("$"), 16) for x in line.split(";", 1)[0][3:].split(",")))
        assert len(rows) == 4
        return list(reversed(rows))
    # The read pointer MUST start at the last of the four 3-byte rows.
    # GBFadeDecCommon uses three HLD instructions per stage; starting +2
    # (as the first REF-353 candidate did) reads previous FadePal tables.
    for name, routine in (
        ("FadePalDarkBG353", "GBFadeOutToBlackDarkBG353"),
        ("FadePalAlreadyDark353", "GBFadeOutToBlackAlreadyDark353"),
    ):
        matcher = re.search(rf"{routine}::\s+ld hl,\s*{name}\s*\+\s*(\d+)", fade)
        assert matcher is not None, f"missing explicit fade table cursor: {routine}"
        assert int(matcher.group(1)) == 11, f"{routine} must start at fourth stage, byte offset 11"
    johto = palette("FadePalDarkBG353")
    kanto = palette("FadePalAlreadyDark353")
    assert johto == [(0xFE, 0xE4, 0xE4), (0xFE, 0xF9, 0xF9), (0xFE, 0xFE, 0xFE), (0xFF, 0xFF, 0xFF)]
    assert kanto == [(0xFE, 0xFE, 0xFE)] * 3 + [(0xFF, 0xFF, 0xFF)]
    for initial, stages in [((0xFE,0xE4,0xE4), johto), ((0xFE,0xFE,0xFE), kanto)]:
        previous = initial
        for stage in stages:
            for old,new in zip(previous, stage):
                for shift in (0,2,4,6):
                    assert (new >> shift) & 3 >= (old >> shift) & 3
            previous = stage
        assert previous == (0xFF,0xFF,0xFF)
    assert "ld b, 4\n\tjr GBFadeDecCommon" in fade
    assert "ld c, 8\n\tcall DelayFrames" in fade


def test_johto_does_not_force_source_cave_white_on_exit():
    resolver = section(src("engine/johto_pilot_runtime.asm"), "JohtoPilotResolveRegisteredWarp::", "JohtoPilotMapProfiles::")
    assert "cp 12 ; was the source cave still unlit?" in resolver
    assert "ld a, 12 ; FadePal4 - FadePalJohtoDark349" in resolver
    assert not any(f"ld [{reg}], a" in resolver for reg in ("rBGP", "rOBP0", "rOBP1"))
    assert "ld [wMapPalOffset], a" in resolver
    helper = section(src("engine/johto_dark_cave_stage2.asm"), "JohtoDarkCavePreLCDPalette349::", "JohtoDarkCaveSurfDecision::")
    assert "jr z, .apply" in helper
    assert "ld [wMapPalOffset], a" in helper
    assert "ldh a, [hMapLoadVRAMSafeFlag]\n    and a\n    ret nz" in helper
    assert helper.index("ret nz") < helper.index("jp LoadGBPal")


def test_safe_guard_remains_until_after_destination_sprite_upload():
    load = section(src("home/overworld.asm"), "LoadMapData::", "SwitchToMapRomBank::")
    assert "call DisableLCD" in load and "callab LoadMapNameSignGFX" in load
    assert load.index("ldh a,[hMapLoadVRAMSafeFlag]") < load.index("call DisableLCD")
    assert load.index("callab JohtoDarkCavePreLCDPalette349") < load.index("call LoadPlayerSpriteGraphics")
    assert "call LoadPlayerSpriteGraphics\n\txor a\n\tldh [hMapLoadVRAMSafeFlag],a" in load
    assert "call _LoadMapVramAndColors" in load
    assert "ldh a,[hMapLoadVRAMSafeFlag]" in src("color/refreshmaps.asm")


def test_flash_controls_darkness_not_transfer_selection():
    flash = src("engine/menu/start_sub_menus.asm")
    assert "callab JohtoFlashEligibility349" in flash
    assert "ld [wMapPalOffset], a" in flash
    door = section(src("home/overworld.asm"), "PlayMapChangeSound::", "ExtraWarpCheck::")
    assert "[wMapPalOffset]" not in door
    fade = src("home/fade.asm")
    assert "FadePal2:: db %11111110, %11111110, %11111110" in fade
    assert "FadePalJohtoDark349:: db %11111110, %11100100, %11100100" in fade


def test_cave_lcd_safe_copy_paths_remain_unchanged():
    assert ".safeLCDOn" in src("color/refreshmaps.asm")
    assert ".pairLoop" in src("home/copy.asm")
