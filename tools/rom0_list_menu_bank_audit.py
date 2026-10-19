"""Fail-closed static guard for ROM0 round 2: bank-$01 list-menu relocation.

This guards source structure, original instruction streams and the ROMX-to-HOME
return trampolines. It is not a link, CPU execution, or phone verification.
An intentional future menu behavior change requires explicit audit review.
"""
from pathlib import Path
import hashlib
import re

MAIN_SHA = "323dea8670baff5ff61844a430bf2006f0e644ed0f7d7bdcc23332e17d19bb1c"
EXIT_SHA = "b5c10646e2353940bdaae7b060a262477b70f6aa97c0247c391a87e977637ee1"


def instructions(text):
    return "\n".join(t for line in text.splitlines()
                     if (t := re.sub(r"\s+", " ", line.partition(";")[0].strip())))


def audit(root, overrides=None):
    root = Path(root)
    overrides = overrides or {}
    def read(name):
        return overrides[name] if name in overrides else (root / name).read_text(encoding="utf8")

    errors = []
    home = read("home.asm")
    main = read("main.asm")
    body = read("engine/menu/list_menu_main.asm")
    swaps = read("engine/menu/swap_items.asm")
    try:
        entry = home.split("DisplayListMenuID::", 1)[1].split("DisplayChooseQuantityMenu::", 1)[0]
        fin = home.split("ExitListMenuReturnHome:", 1)[1].split("RefreshBagPocketDescription:", 1)[0]
        mainblock = body.split("DisplayListMenuID_::", 1)[1].split("\nExitListMenu::", 1)[0]
        exitblock = body.split("ExitListMenu::", 1)[1]
    except IndexError:
        return ["HOME entry or ROMX loop/Cancel exit missing"]
    if instructions(entry) != "ld a, $01\ncall BankswitchHome\njp DisplayListMenuID_":
        errors.append("HOME entry must select bank $01, save caller bank, then tail-jump to ROMX")
    if instructions(fin) != ("call BankswitchBack\nxor a\nld [wMenuItemToSwap], a\nscf\nret"):
        errors.append("HOME Cancel finalizer must restore bank then return Carry=1")
    if instructions(mainblock).startswith("ld a, $01\ncall BankswitchHome") or "call BankswitchHome" in instructions(mainblock):
        errors.append("ROMX entry cannot call BankswitchHome again")
    if "call BankswitchBack" in instructions(body):
        errors.append("ROMX code must not execute after restoring a different bank")
    if "jp BankswitchBack" not in instructions(mainblock):
        errors.append("ROMX success exit must tail-jump to HOME bank restore")
    if "jp ExitListMenuReturnHome" not in instructions(exitblock):
        errors.append("ROMX Cancel must jump to HOME finalizer")
    if hashlib.sha256(instructions(mainblock).encode()).hexdigest() != MAIN_SHA:
        errors.append("relocated menu loop instruction stream changed")
    if hashlib.sha256(instructions(exitblock).encode()).hexdigest() != EXIT_SHA:
        errors.append("relocated Cancel path instruction stream changed")
    if (main.count('INCLUDE "engine/menu/list_menu_main.asm"') != 1 or
        main.count('INCLUDE "engine/menu/swap_items.asm"') != 1 or
        not re.search(r'SECTION "bank1",ROMX,BANK\[\$1\](.*?)\bINCLUDE "engine/menu/swap_items.asm"\s+(?:;[^\n]*\n)*INCLUDE "engine/menu/list_menu_main.asm"', main, re.S)):
        errors.append("swapping code and migrated menu must share the original ROMX bank $01")
    if main.find('INCLUDE "engine/menu/list_menu_main.asm"') > main.find('SECTION "bank3",ROMX,BANK[$3]'):
        errors.append("list-menu source not in bank1 section")
    if "DisplayListMenuIDLoop::" in home or re.search(r"(?m)^ExitListMenu::", home):
        errors.append("old large list-menu loop/ExitListMenu still occupies ROM0")
    if not all(tok in body for tok in ("DisplayListMenuIDLoop::", "ExitListMenu::", "checkOtherKeys:", "storeChosenEntry:")):
        errors.append("ROMX menu entry/loop/exit inventory incomplete")
    if "jp checkIfItemListMenu" not in home or "jp z, skipStoringItemName" not in home:
        errors.append("HOME price/name selection trampoline into bank1 was lost")
    if len(re.findall(r"\bjp\s+(?:nz,|z,)?DisplayListMenuIDLoop", swaps)) != 6:
        errors.append("existing bank1 item-swapping resumes no longer reach ROMX list loop")
    return errors
