"""REF-351C doorway-only fast 2bpp graphics transfer contract (static)."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def src(name):
    return (ROOT / name).read_text(encoding="utf-8")


def fast_path():
    return src("home/copy2.asm").split("CopyVideoData::\n", 1)[1].split("\n.vblankQueue\n", 1)[0]


def test_doorway_and_lcd_gate_precede_any_fast_copy():
    body = fast_path()
    assert body.index("ldh a, [hMapLoadVRAMSafeFlag]") < body.index("ldh a, [rLCDC]")
    assert "and a\n\tjr z, .vblankQueue" in body
    assert "bit 7, a\n\tjr z, .vblankQueue" in body
    assert body.index("bit 7, a") < body.index("call FarCopyData2")


def test_fast_path_uses_existing_safe_copy_not_new_dma_or_stack_transfer():
    body = fast_path()
    assert body.count("call FarCopyData2") == 1
    assert "rHDMA" not in body
    assert "ld sp" not in body.lower()
    assert "H_VBCOPYSIZE" not in body
    assert "ld h, d\n\tld l, e\n\tpop de" in body


def test_tile_count_conversion_is_exact_across_byte_boundaries():
    body = fast_path()
    assert re.search(r"ld a, c\s+swap a\s+and \$0f\s+ld b, a", body)
    assert re.search(r"ld a, c\s+swap a\s+and \$f0\s+ld c, a", body)
    for tiles in [0, 1, 3, 4, 8, 12, 15, 16, 24, 32, 63, 255]:
        swapped = ((tiles << 4) | (tiles >> 4)) & 0xff
        bc = ((swapped & 0x0f) << 8) | (swapped & 0xf0)
        assert bc == tiles * 16


def test_copy_preserves_bank_and_original_pointer_registers():
    body = fast_path()
    for instruction in ["push bc", "push de", "push hl", "ld a, b", "push af", "pop af", "call FarCopyData2", "pop hl", "pop de", "pop bc", "ret"]:
        assert instruction in body
    assert body.index("push bc") < body.index("push de") < body.index("push hl")
    assert body.index("pop af") < body.index("call FarCopyData2")
    assert body.index("call FarCopyData2") < body.index("pop hl", body.index("call FarCopyData2")) < body.index("pop de", body.index("call FarCopyData2")) < body.index("pop bc", body.index("call FarCopyData2"))
    assert "ld [$ff8b],a" in src("home/copy.asm")


def test_legacy_vblank_copy_remains_for_every_other_caller():
    original = src("home/copy2.asm").split(".vblankQueue\n", 1)[1].split("\nCopyVideoDataDouble::", 1)[0]
    assert "ld [H_VBCOPYSIZE], a" in original
    assert "call DelayFrame" in original
    assert "ld [H_AUTOBGTRANSFERENABLED], a" in original
    assert "ld [H_LOADEDROMBANK], a" in original
    assert "ld [MBC1RomBank], a" in original


def test_map_guard_released_only_after_player_graphics():
    body = src("home/overworld.asm").split("LoadMapData::", 1)[1].split("\n; HAX: Padding", 1)[0]
    after = body.split(".lcdReady350B\n", 1)[1]
    assert "call LoadPlayerSpriteGraphics\n\txor a\n\tldh [hMapLoadVRAMSafeFlag],a" in after
    assert after.index("ldh [hMapLoadVRAMSafeFlag],a") < after.index("call UpdateMusic6Times")
    assert "call DisableLCD" in body  # the legacy path is unchanged
    assert "call LoadMapNameSignGFX" not in body  # legacy still uses original callab


def test_version_and_old_map_hdma_are_untouched():
    assert 'db "REF-364@"' in src("data/game_version.asm")
    body = src("color/refreshmaps.asm")
    assert body.count("call .copyDoorwayMapRowsHDMA") == 2
    assert "ld a,$80 ; one 16-byte HBlank DMA block" in body
