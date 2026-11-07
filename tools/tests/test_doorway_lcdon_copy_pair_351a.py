from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[2]
FAST_COPY_SHA256 = "13184e576c0593ea427a518c27274a96d8a73313bdd969569e6611533c9fcfe8"


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def copy_data_parts():
    src = read("home/copy.asm")
    body = src.split("CopyData::\n", 1)[1].split('\nSECTION "Home Far Copy Data 2"', 1)[0]
    safe = body.split("\n.safe\n", 1)[1].split("\n.fast\n", 1)[0]
    fast = body.split("\n.fast\n", 1)[1]
    return src, body, safe, fast


def test_safe_vram_copy_gates_only_lcd_on_vram_destinations():
    src, body, safe, fast = copy_data_parts()
    assert "ldh a, [hMapLoadVRAMSafeFlag]" in body
    assert "cp $80\n\tjr c, .fast\n\tcp $a0\n\tjr nc, .fast" in body
    assert "ldh a, [rSTAT]" in safe
    assert "and %10 ; modes 0 and 1 permit VRAM writes" in safe
    assert "ld a, [rSTAT]" not in safe
    assert "ld a, [hli]\n\tld [de], a\n\tinc de" in fast
    assert "ldh a, [rSTAT]" not in fast
    assert hashlib.sha256(fast.encode()).hexdigest() == FAST_COPY_SHA256
    assert safe.startswith("\t; REF-351A:")
    assert not safe.startswith("\tdi")  # BC=0 must not return with interrupts disabled


def test_odd_leading_byte_and_even_pair_count_are_exact():
    _, _, safe, _ = copy_data_parts()
    odd = safe.split("\n.pairCount\n", 1)[0]
    pairs = safe.split("\n.pairLoop\n", 1)[1]
    assert "bit 0, c\n\tjr z, .pairCount" in safe
    assert odd.count("ld a, [hli]") == 1
    assert odd.count("ld [de], a") == 1
    assert odd.count("dec bc") == 1
    assert "srl b\n\trr c" in safe
    assert "ld a, b\n\tor c\n\tret z" in safe
    assert pairs.count("ld a, [hli]") == 2
    assert pairs.count("ld [de], a") == 2
    assert pairs.count("inc de") == 2
    assert pairs.count("dec bc") == 1


def test_each_pair_is_written_inside_one_masked_safe_window():
    _, _, safe, _ = copy_data_parts()
    pair = safe.split(".pairLoop\n", 1)[1]
    assert pair.index("di") < pair.index(".waitPairVRAM")
    assert pair.index("ldh a, [rSTAT]") < pair.index("ld a, [hli]")
    assert pair.index("ld [de], a", pair.index("ld [de], a") + 1) < pair.index("ei")
    assert pair.index("ei") < pair.index("ld a, b")
    assert "ld sp" not in safe.lower()
    assert "push" not in safe.lower() and "pop" not in safe.lower()


def test_far_copy_bank_wrappers_remain_unchanged_and_call_copydata():
    src = read("home/copy.asm")
    assert "FarCopyData::" in src and "FarCopyData2::" in src
    assert src.count("call CopyData") == 2
    normalized = "".join(src.split())
    assert normalized.count("ld[H_LOADEDROMBANK],a") == 4
    assert normalized.count("ld[MBC1RomBank],a") == 4


def test_doorway_hdma_and_single_cell_attribute_path_are_preserved():
    src = read("color/refreshmaps.asm")
    safe = src.split("\n.safeLCDOn\n", 1)[1].split("; Refresh 1/3", 1)[0]
    assert "W2_DoorwayAttrMapBuffer" in safe
    assert "W2_DoorwayTileMapBuffer" in safe
    assert safe.count("call .copyDoorwayMapRowsHDMA") == 2
    assert "ld a,$80 ; one 16-byte HBlank DMA block" in safe
    assert "ldh a,[rSTAT]" in safe
    assert "ld a,[rSTAT]" not in safe
    assert "ld b,4" in safe
    assert "32 - 20" in safe


def test_version_and_double_speed_precondition_are_explicit():
    version = read("data/game_version.asm")
    assert 'db "REF-351B@"' in version
    init = read("color/init.asm")
    assert "ld [rKEY1], a\n\tstop" in init
    home = read("home.asm")
    assert "InitializeColor:\n\tcp $11\n\tjr nz,.IsNotGBC\n\tcall _InitGbcMode\n\tjp Start" in home
    overworld = read("home/overworld.asm")
    assert "60FPS: GBC double-speed is already enabled by InitGbcMode" in overworld
    door = overworld.split("PlayMapChangeSound::", 1)[1].split("ExtraWarpCheck::", 1)[0]
    assert door.index("call GBFadeOutToBlack") < door.rindex("ldh [hMapLoadVRAMSafeFlag],a")
    assert "ldh [hMapLoadVRAMSafeFlag],a" in door
