"""REF-355 Player PC item-list descriptions: focused source contracts only.

These checks do NOT compile RGBDS or prove the frame/OAM display on hardware.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def src(name):
    return (ROOT / name).read_text(encoding="utf-8")


def block(text, start, end):
    assert text.count(start) == 1, f"missing/duplicate start: {start}"
    return text.split(start, 1)[1].split(end, 1)[0]


def test_main_list_redraw_renders_after_list_and_cursor_before_transfer():
    home = src("home.asm")
    body = block(home, "DisplayListMenuIDLoop::", "DisplayChooseQuantityMenu::")
    sequence = (
        "call PrintListMenuEntries",
        "call PlaceMenuCursor",
        "call RefreshPlayerPCItemDescription",
        "ld a,1\n\tld [H_AUTOBGTRANSFERENABLED],a",
        "call Delay3",
    )
    offsets = [body.index(s) for s in sequence]
    assert offsets == sorted(offsets)


def test_gate_is_pc_only_and_does_not_affect_other_lists():
    home = src("home.asm")
    gate = block(home, "RefreshPlayerPCItemDescription:", "RefreshBagPocketDescription:")
    assert all(token in gate for token in (
        "ld a,[wBagPocketActive]", "ret nz", "cp ITEMLISTMENU", "bit 5,[hl]",
        "ret z", "callba UpdatePlayerPCItemDescription",
    ))
    assert gate.index("ld a,[wBagPocketActive]") < gate.index("cp ITEMLISTMENU")
    assert gate.index("cp ITEMLISTMENU") < gate.index("bit 5,[hl]")
    assert "ld a,[wMenuWatchMovingOutOfBounds]" in gate and gate.count("ret z") >= 2
    assert "push bc\n\tcallba UpdatePlayerPCItemDescription\n\tpop bc" in gate
    handler = block(home, "HandleMenuInput_::", "PlaceMenuCursor::")
    assert ".refreshBagDescription" in handler
    assert "call RefreshBagPocketDescription" in handler
    assert "call RefreshPlayerPCItemDescription" in handler
    assert handler.index("call RefreshBagPocketDescription") < handler.index("call RefreshPlayerPCItemDescription")



def test_all_three_pc_item_lists_keep_conventional_entry_and_storage():
    code = src("engine/menu/players_pc.asm")
    for start, end, pointer in (
        ("PlayerPCDeposit:", "PlayerPCWithdraw:", "wNumBagItems"),
        ("PlayerPCWithdraw:", "PlayerPCToss:", "wNumBoxItems"),
        ("PlayerPCToss:", "PlayersPCMenuEntries:", "wNumBoxItems"),
    ):
        body = block(code, start, end)
        assert f"ld hl, {pointer}" in body
        assert "ld a, ITEMLISTMENU\n\tld [wListMenuID], a\n\tcall DisplayListMenuID" in body
    # PC parent supplies the bit5 session guard; it is cleaned on exit.
    assert "set 5, [hl]" in code and "res 5, [hl]" in code


def test_helper_validates_exact_inventory_pointers_and_clamps_cancel():
    helper = block(src("engine/menu/bag_pockets.asm"),
                   "UpdatePlayerPCItemDescription::", "UpdateBagPocketDescription::")
    assert "ld hl,wNumBagItems" in helper and "ld hl,wNumBoxItems" in helper
    assert "ld a,[wListCount]\n\tcp c\n\tjr z,.cancel\n\tjr c,.cancel" in helper
    assert "ld a,c\n\tadd a\n\tld e,a\n\tld d,0" in helper
    assert "inc hl\n\tadd hl,de\n\tld a,[hl]" in helper
    assert ".cancel\n\tld a,$ff" in helper


def test_selected_id_uses_existing_bag_and_mart_descriptions():
    helper = block(src("engine/menu/bag_pockets.asm"),
                   "UpdatePlayerPCItemDescription::", "UpdateBagPocketDescription::")
    assert "ld hl,wFilteredBagItems + BAG_POCKET_DESCRIPTION_CACHE_OFFSET" in helper
    assert "ld [hl],$fe\n\tjp UpdateBagPocketDescriptionFromItem" in helper
    existing = block(src("engine/menu/bag_pockets.asm"),
                     "UpdateBagPocketDescriptionFromItem:", "BagPocketTitleSpans:")
    assert "callab DrawMachineItemDescription" in existing
    assert "ld hl, ItemDescriptionPointers_Mart" in existing
    assert "callab PrintBagItemDescriptionText" in existing
    assert existing.count("call ClearScreenArea") == 2
    assert "ld a,[H_AUTOBGTRANSFERENABLED]" in existing or "ld a, [H_AUTOBGTRANSFERENABLED]" in existing


def test_redraw_does_not_allocate_wram_or_change_inventory_logic():
    # PC implementation remains the stock inventory code; graphics are separate.
    assert "wPlayerPCItemDescriptionActive" not in src("wram.asm")
    assert "UpdatePlayerPCItemDescription" not in src("engine/menu/players_pc.asm")
    assert 'db "REF-355@"' in src("data/game_version.asm")
