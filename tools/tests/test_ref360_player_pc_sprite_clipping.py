"""REF-360 Player PC parent sprite occlusion, source-level regression contracts.

These tests do not run RGBDS or a Game Boy emulator. They check that
UpdateSprites uses the finished parent tilemap without altering child menus.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


def active(text):
    return "\n".join(line.split(";", 1)[0] for line in text.splitlines())


def between(path, start, end):
    text = source(path)
    assert text.count(start) == 1 and end in text
    return active(text.split(start, 1)[1].split(end, 1)[0])


def test_parent_clipping_occurs_once_after_both_boxes_before_screen_transfer():
    code = between("engine/menu/players_pc.asm", "PlayerPCMenu:", "ExitPlayerPC:")
    assert code.count("call UpdateSprites") == 1
    upper_box = code.index("call TextBoxBorder")
    upper_label = code.index("ld de, PlayersPCMenuEntries")
    prompt_box = code.index("coord hl, 0, 12")
    assert re.search(r"coord hl, 0, 12\s+lb bc, 4, 18\s+call TextBoxBorder", code)
    lower_label = code.index("ld de, WhatDoYouWantText")
    prompt_render = code.index("call PlaceString", lower_label)
    clipping = code.index("call UpdateSprites")
    screen_transfer = code.index("ld [H_AUTOBGTRANSFERENABLED], a")
    wait_frames = code.index("call Delay3", screen_transfer)
    b_release = code.index(".waitForBRelease", wait_frames)
    assert upper_box < upper_label < prompt_box < lower_label < prompt_render
    assert prompt_render < clipping < screen_transfer < wait_frames < b_release
    # The clipping call is moved, not duplicated or swapped for a slower PrintText.
    assert "call PrintText" not in code


def test_fast_return_and_cancel_reentrance_remain_intact():
    pc = active(source("engine/menu/players_pc.asm"))
    code = between("engine/menu/players_pc.asm", "PlayerPCMenu:", "ExitPlayerPC:")
    gate = code.split("\n.waitForBRelease\n", 1)[1].split("\n.bReleased\n", 1)[0]
    assert "call Joypad" in gate
    assert "and B_BUTTON" in gate
    assert "call DelayFrame" in gate
    assert "call HandleMenuInput" in code.split("\n.bReleased\n", 1)[1]
    assert "ld [wParentMenuItem], a" in code
    assert "call LoadScreenTilesFromBuffer2DisableBGTransfer" in code
    for label, end in (("PlayerPCDeposit:", "PlayerPCWithdraw:"),
                       ("PlayerPCWithdraw:", "PlayerPCToss:"),
                       ("PlayerPCToss:", "PlayersPCMenuEntries:")):
        child = pc.split(label, 1)[1].split(end, 1)[0]
        assert "call DisplayListMenuID\n\tjp c, PlayerPCMenu" in child
        assert "jp ExitPlayerPC" not in child


def test_bills_pc_and_common_sprite_and_description_paths_still_exist():
    bills = source("engine/menu/bills_pc.asm")
    assert "ld hl, WhatText\n\tcall PrintText" in bills
    assert "call DisplayMonListMenu\n\tjp c, BillsPCMenu" in bills
    pc_items = source("engine/menu/bag_pockets.asm")
    assert "UpdatePlayerPCItemDescription::" in pc_items
    assert "call UpdateSprites" in pc_items
    assert "CheckSpriteAvailability:" in source("engine/overworld/movement.asm")
    assert "UpdateSprites::" in source("home.asm")


def test_version_raised_at_canonical_location():
    code = source("data/game_version.asm")
    assert re.search(r'^\s*db "REF-360@"$', code, re.M)
    assert "REF-359: disable obsolete Player PC item-list question printing." in code
    assert 'WhatDoYouWantText:' in source('engine/menu/players_pc.asm')
