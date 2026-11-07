from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[2]
FAST_LCD_OFF_SHA256 = "02211b5d483e2ebc645d0ab6d2350c04e2d51511e611babb20db518051dbce83"


def read_source(path):
    return (ROOT / path).read_text(encoding="utf-8")


def safe_upload_block():
    src = read_source("color/refreshmaps.asm")
    start = src.index("\n.safeLCDOn\n") + 1
    end = src.index("; Refresh 1/3 of the window each frame.", start)
    return src[start:end]


def test_lcd_on_upload_stages_both_planes_and_uses_row_hdma():
    safe = safe_upload_block()
    assert "W2_DoorwayAttrMapBuffer" in safe
    assert "W2_DoorwayTileMapBuffer" in safe
    assert safe.count("call .copyDoorwayMapRowsHDMA") == 2
    assert "ld c,1" in safe
    assert "ld c,0" in safe
    assert ".buildAttrRow" in safe
    assert ".buildTileRow" in safe
    assert "ld a,$80 ; one 16-byte HBlank DMA block" in safe
    assert "ld [rHDMA5],a" in safe


def test_hdma_copies_16_bytes_and_cpu_tail_checks_each_vram_write():
    safe = safe_upload_block()
    assert ".hdmaWaitBlock" in safe
    assert "ld a,[rHDMA5]" in safe
    assert "bit 7,a" in safe
    assert "ld b,4" in safe
    assert ".hdmaWaitTailVRAM" in safe
    assert "and %10 ; modes 0 and 1 permit VRAM writes" in safe
    assert "ld a,[hli]" in safe
    assert "ld [de],a" in safe
    assert "32 - 20" in safe  # preserve the 12 off-screen columns


def test_bank_and_vbk_are_restored_before_interrupts_resume():
    safe = safe_upload_block()
    helper = safe.split("\n.copyDoorwayMapRowsHDMA\n", 1)[1]
    assert helper.index("ld a,2") < helper.index("ld [rSVBK],a")
    assert helper.index("ld [rVBK],a") < helper.index("ld a,$80")
    assert helper.index("ld [rVBK],a", helper.index("pop bc")) < helper.index("ei")
    assert helper.index("ld [rSVBK],a", helper.index("pop bc")) < helper.index("ei")


def test_staging_buffers_are_aligned_and_leave_the_stack_region_clear():
    wram = read_source("color/wram.asm")
    attr = int(re.search(r"W2_DoorwayAttrMapBuffer\s+EQU\s+\$(\w+)", wram).group(1), 16)
    tile = int(re.search(r"W2_DoorwayTileMapBuffer\s+EQU\s+\$(\w+)", wram).group(1), 16)
    plane_size = 32 * 18
    assert attr % 16 == 0
    assert tile % 16 == 0
    assert tile == attr + plane_size
    assert tile + plane_size <= 0xDF00
    assert "ASSERT W2_DoorwayTileMapBuffer == W2_DoorwayAttrMapBuffer + $240" in wram


def test_lcd_off_path_and_special_cave_loader_remain_unchanged():
    src = read_source("color/refreshmaps.asm")
    start = src.index("\n.fastLCDOff\n") + 1
    end = src.index("\n.safeLCDOn\n", start) + 1
    fast = src[start:end]
    assert hashlib.sha256(fast.encode()).hexdigest() == FAST_LCD_OFF_SHA256
    loader = read_source("home/overworld.asm")
    assert "callab JohtoDarkCavePreLCDPalette349" in loader
    assert "hMapLoadVRAMSafeFlag" in loader
