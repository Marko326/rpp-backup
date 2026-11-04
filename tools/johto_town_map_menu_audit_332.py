#!/usr/bin/env python3
"""DEV-332/333 Town Map menu source-contract gate (no ROM build or input replay).

Protect the DEV-333 approved Kanto-style Johto shortcuts without inventing
Johto Pokemon Centers, new Fly warp destinations, or missing wild encounters.
This is a source-level contract, not a CPU/input emulator.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def _block(src: str, start: str, end: str) -> str:
    lines = src.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.strip() == start]
    if len(starts) != 1:
        raise ValueError(f"expected one label {start}, found {len(starts)}")
    start_pos = starts[0]
    ends = [i for i in range(start_pos + 1, len(lines)) if lines[i].strip() == end]
    if not ends:
        raise ValueError(f"missing end label {end} after {start}")
    return "".join(lines[start_pos + 1:ends[0]])


def _code(src: str) -> str:
    # Do not allow comments to satisfy execution-path checks.
    return "\n".join(line.split(";", 1)[0].rstrip() for line in src.splitlines())


def _sequence(src: str, *patterns: str) -> bool:
    pos = 0
    for pattern in patterns:
        found = re.search(pattern, src[pos:], re.MULTILINE)
        if not found:
            return False
        pos += found.end()
    return True


def audit(root: Path) -> dict:
    root = Path(root)
    issues: list[str] = []
    checks: list[dict[str, str]] = []
    def verify(name: str, passed: bool, detail: str) -> None:
        checks.append({"check": name, "status": "PASS" if passed else "FAIL", "detail": detail})
        if not passed:
            issues.append(f"{name}: {detail}")

    try:
        town = _code((root / "engine/town_map.asm").read_text(encoding="utf-8"))
        fly = _code((root / "engine/johto_pilot_fly_map.asm").read_text(encoding="utf-8"))
        browse = _code((root / "engine/johto_pilot_town_map_browse.asm").read_text(encoding="utf-8"))
        item = _block(town, "DisplayTownMap:", "DrawJohtoPilotFlyPlayerMarker::")
        # 1. On Johto's $FC map, choose the Johto map, not the Kanto renderer.
        verify("ordinary_region_dispatch", _sequence(item,
            r"ld a, \[wCurMap\]\s+cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.selectKantoTownMap",
            r"ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.selectKantoTownMap",
            r"ld a, 1\s+jr \.storeTownMapSelector",
            r"\.selectKantoTownMap\s+xor a\s+\.storeTownMapSelector\s+ld \[wFlyLocationsAxis\], a",
            r"call LoadTownMap"),
            "Johto $FC + region -> axis 1; all other maps -> Kanto axis 0")
        initial = _block(item, ".drawJohtoInitialMarker", ".initialMarkerReady")
        browse_draw = _block(item, ".johtoBrowseName", ".writeBrowseName")
        verify("ordinary_banked_name_and_marker", _sequence(initial,
            r"callab JohtoPilotGetTownMapLandmark",
            r"callab LoadJohtoBrowseEntry",
            r"call DrawJohtoPilotFlyPlayerMarker",
            r"ld de, wBuffer") and
            "ld de, wBuffer" in browse_draw and "ld de, wcd6d" not in browse_draw,
            "Johto map name must be copied to 30-byte wBuffer inside the correct ROM bank")
        inputs = _block(item, ".inputLoop", ".pressedStart")
        verify("ordinary_input_exit", _sequence(inputs,
            r"and A_BUTTON \| B_BUTTON \| D_UP \| D_DOWN",
            r"and START \| SELECT", r"bit 3, b\s+jr nz, \.pressedStart",
            r"bit 2, b\s+jr nz, \.pressedSelect",
            r"bit 6, b\s+jr nz, \.pressedUp",
            r"bit 7, b\s+jr nz, \.pressedDown",
            r"call ExitTownMap\s+ret"),
            "B/A exits, UP/DOWN browse, START/SELECT edge-triggered")
        start = _block(item, ".pressedStart", ".pressedSelect")
        select = _block(item, ".pressedSelect", ".pressedUp")
        wrap_up = _block(item, ".pressedUp", ".pressedDown")
        wrap_down = item[item.index(".pressedDown"):]
        verify("ordinary_johto_start_recenter", _sequence(start,
            r"ld a, \[wFlyLocationsAxis\]\s+and a\s+jr z, \.kantoStartShortcut",
            r"callab JohtoPilotGetLastHealLandmarkOrPlayer\s+ld a, e\s+ld \[wWhichTownMapLocation\], a\s+jp \.townMapLoop",
            r"\.kantoStartShortcut", r"ld a, \[wLastBlackoutMap\]", r"callab InitTownMapLocationFromPlayerMap")
            and bool(re.search(r"xor a\s+ld \[wWhichTownMapLocation\], a\s+jp \.townMapLoop", select)),
            "START recenters Johto on player's Gold landmark; Kanto keeps last-heal; SELECT selects region's first landmark")
        verify("ordinary_45_landmark_wrap", _sequence(wrap_up,
            r"cp JOHTO_TOWNMAP_LANDMARK_COUNT\s+jr c, \.storeUp")
            and _sequence(wrap_down, r"\.downUnderflow", r"ld a, JOHTO_TOWNMAP_LANDMARK_COUNT - 1"),
            "Browse 45 Gold landmarks, independent of 47 active maps and 11 Fly rows")
        verify("ordinary_cursor_name_terminator", "callab LoadJohtoBrowseEntry" in item and
            "ld de, wBuffer" in browse_draw and "ld b, 29" in browse and
            'cp "@"' in browse and 'ld a, "@"' in browse,
            "Runtime name-copy bound remains present; exhaustive length check is a separate gate")

        # 2. Fly screen must never select a merely listed but unavailable place.
        load = _block(fly, "LoadJohtoPilotFlyTownMap::", ".findForward")
        verify("fly_johto_entry", _sequence(load,
            r"ld \[wFlySelectedSpecies\], a", r"ld a, 1\s+ld \[wFlyLocationsAxis\], a",
            r"callba LoadTownMap", r"callba DrawJohtoPilotFlyPlayerMarker",
            r"xor a\s+ld \[wWhichTownMapLocation\], a\s+call \.findForward"),
            "Fly displays Johto and initializes the player marker and first available entry")
        fly_input = _block(load, ".input", ".next")
        verify("fly_input_and_cancel", _sequence(fly_input,
            r"and A_BUTTON \| B_BUTTON \| D_LEFT \| D_RIGHT \| D_UP \| D_DOWN",
            r"and START \| SELECT", r"bit 0, b\s+jp nz, \.accept",
            r"bit 1, b\s+jp nz, \.cancel",
            r"bit 3, b\s+jp nz, \.startShortcut",
            r"bit 2, b\s+jp nz, \.selectShortcut",
            r"bit 4, b\s+jp nz, \.specialAxis",
            r"bit 5, b\s+jp nz, \.specialAxis",
            r"bit 6, b\s+jp nz, \.next\s+jp \.previous"),
            "Johto Fly dispatches START/SELECT/LEFT/RIGHT separately; A confirms, B cancels")
        select_fly = _block(fly, ".selectShortcut", ".startShortcut")
        verify("fly_select_returns_first_unlocked", _sequence(select_fly,
            r"ld a, 1\s+ld \[wFlyLocationsAxis\], a",
            r"xor a\s+ld \[wWhichTownMapLocation\], a",
            r"call \.findForward\s+jp \.render"),
            "SELECT returns to Johto city axis and scans for first registered+visited stop")
        start_fly = _block(fly, ".startShortcut", ".specialAxis")
        verify("fly_start_last_heal_guard", _sequence(start_fly,
            r"ld a, \[wJohtoLastHealMagic\]\s+cp JOHTO_LAST_HEAL_MAGIC\s+jp nz, \.render",
            r"ld a, \[wJohtoLastHealLocalID\]\s+cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\s+jp z, \.startCherrygrove",
            r"cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID\s+jp z, \.startAzalea\s+cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID\s+jp z, \.startViolet\s+cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID\s+jp z, \.startGoldenrod\s+cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID\s+jp z, \.startEcruteak\s+cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID\s+jp z, \.startOlivine\s+cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID\s+jp z, \.startCianwood\s+cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID\s+jp z, \.startMahogany\s+cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID\s+jp z, \.startBlackthorn\s+jp \.render",
            r"ld a, 4\s+jr \.startSelect\s+\.startEcruteak\s+ld a, 5\s+jp \.startSelect\s+\.startOlivine\s+ld a, 6\s+jp \.startSelect\s+\.startCianwood\s+ld a, 8\s+jp \.startSelect\s+\.startMahogany\s+ld a, 7\s+jp \.startSelect\s+\.startBlackthorn\s+ld a, 10\s+jp \.startSelect\s+\.startViolet\s+ld a, 2\s+jr \.startSelect\s+\.startAzalea\s+ld a, 3\s+jr \.startSelect",
            r"\.startCherrygrove\s+ld a, 1",
            r"\.startSelect\s+ld b, a\s+ld a, \[wWhichTownMapLocation\]\s+push af",
            r"ld a, \[wFlyLocationsAxis\]\s+push af",
            r"ld a, b\s+ld \[wWhichTownMapLocation\], a\s+call \.isUnlocked\s+jr z, \.startRestore",
            r"pop af\s+pop af\s+ld a, 1\s+ld \[wFlyLocationsAxis\], a\s+jp \.render",
            r"\.startRestore\s+pop af\s+ld \[wFlyLocationsAxis\], a\s+pop af\s+ld \[wWhichTownMapLocation\], a\s+jp \.render") and
            "JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID" not in start_fly and
            "wCurLocalMapID" not in start_fly,
            "START uses last successful center ID: Cherrygrove/Azalea/Violet/Goldenrod city row only if active+visited; roadside Route32 never gains Fly; locked preserves cursor+axis")
        special = _block(fly, ".specialAxis", ".next")
        verify("fly_lake_special_axis_guard", _sequence(special,
            r"ld a, \[wWhichTownMapLocation\]\s+push af",
            r"ld a, 9\s+ld \[wWhichTownMapLocation\], a\s+call \.isUnlocked",
            r"jr nz, \.specialUnlocked\s+pop af\s+ld \[wWhichTownMapLocation\], a\s+jp \.render",
            r"\.specialUnlocked\s+pop af\s+ld a, 2\s+ld \[wFlyLocationsAxis\], a"),
            "LEFT/RIGHT only enters Lake of Rage special axis when active + visited, restoring cursor if locked")
        special_return = _block(fly, ".next", ".accept")
        verify("fly_special_to_city_returns", _sequence(special_return,
            r"ld a, \[wFlyLocationsAxis\]\s+cp 2",
            r"ld a, 10\s+jr \.nextStore", r"call \.findForward",
            r"\.previous\s+ld a, \[wFlyLocationsAxis\]\s+cp 2",
            r"ld a, 7\s+jr \.previousStore", r"call \.findBackward"),
            "UP/DOWN leave special axis via Blackthorn City/Mahogany Town side; both scan visited destinations")
        accept = _block(fly, ".accept", ".findForward")
        cancel = accept[accept.index(".cancel"):]
        verify("fly_accept_requires_unlock", _sequence(accept,
            r"call \.isUnlocked\s+jp z, \.input",
            r"ld \[wJohtoFlySelectedLocalID\], a",
            r"ld a, JOHTO_PILOT_FLY_SELECTOR\s+ld \[wDestinationMap\], a") and
            _sequence(cancel, r"\.cancel\s+xor a\s+ld \[wTownMapSpriteBlinkingEnabled\], a",
                      r"call GBPalWhiteOutWithDelay3", r"ld \[hTilesetType\], a\s+ret") and
            "wDestinationMap" not in cancel and "wJohtoFlySelectedLocalID" not in cancel,
            "A is blocked for locked entries; B exits without setting a Fly destination")
        forward = _block(fly, ".findForward", ".findBackward")
        backward = _block(fly, ".findBackward", ".isUnlocked")
        verify("fly_locked_row_skip_both_directions", _sequence(forward,
            r"ld b, JOHTO_FLY_TOWN_COUNT", r"call \.isUnlocked", r"ret nz",
            r"cp JOHTO_FLY_TOWN_COUNT", r"dec b\s+jr nz, \.forwardLoop") and
            _sequence(backward, r"ld b, JOHTO_FLY_TOWN_COUNT", r"call \.isUnlocked", r"ret nz",
                       r"ld a, JOHTO_FLY_TOWN_COUNT - 1", r"dec b\s+jr nz, \.backwardLoop"),
            "Both directions inspect at most 11 candidates, skipping unregistered/unvisited rows")
        unlocked = _block(fly, ".isUnlocked", ".entry")
        verify("fly_active_and_visit_flags", _sequence(unlocked,
            r"callab GetJohtoActiveSlot", r"cp JOHTO_INVALID_ACTIVE_SLOT",
            r"jr z, \.locked", r"ld hl, wEventFlags", r"and \[hl\]\s+ret",
            r"\.locked\s+xor a\s+ret"),
            "Active slot AND visited event both required")
        dispatch = _block(fly, "JohtoPilotApplyNewBarkFlyWarp::", "JohtoPilotFlyDestinations:")
        verify("fly_warp_rechecks_unlock", _sequence(dispatch,
            r"callab GetJohtoActiveSlot", r"cp JOHTO_INVALID_ACTIVE_SLOT",
            r"jp z, SoftReset", r"ld hl, wEventFlags", r"and \[hl\]",
            r"jp z, SoftReset", r"ld a, JOHTO_RUNTIME_MAP_HANDLE",
            r"ld \[wCurLocalMapID\], a"),
            "Warp dispatch rechecks both guards after the animation alters scratch WRAM")
        rows = _block(fly, "JohtoPilotFlyDestinations:", ".end:")
        names = re.findall(r"(?m)^\s*db\s+(JOHTO_[A-Z_0-9]+_LOCAL_ID)\s*,", rows)
        verify("fly_11_registered_candidates", len(names) == 11 and len(set(names)) == 11 and
            names[9:10] == ["JOHTO_LAKE_OF_RAGE_LOCAL_ID"] and
            "ASSERT .end - JohtoPilotFlyDestinations == JOHTO_FLY_TOWN_COUNT * 9" in fly,
            "11 distinct physical stable IDs in the 9-byte destination table")

        # 3. Document Kanto's current Nest behavior without pretending Johto
        # distribution data exists; retain the existing Kanto Fly special axis.
        nest = _block(town, "LoadTownMap_Nest:", "MonsText:")
        verify("nest_kanto_only_policy_unchanged", _sequence(nest,
            r"xor a\s+ld \[hTilesetType\], a\s+ld \[wFlyLocationsAxis\], a",
            r"call LoadTownMap", r"call DisplayWildLocations", r"call GetMonName",
            r"call WaitForTextScrollButtonPress", r"call ExitTownMap\s+ret"),
            "Existing Nest still draws Kanto only; no unapproved Johto distribution switch")
        kanto_fly = _block(town, ".pressedLeftOrRight", ".selectFirstAvailable")
        verify("kanto_fly_special_axis_preserved", _sequence(kanto_fly,
            r"ld a, \[wSpecialFlyVisitedFlag\]", r"ld a, \[wFlyLocationsAxis\]",
            r"callab BuildSpecialFlyLocationsListFromCityAnchor"),
            "Kanto LEFT/RIGHT special destination axis retained")
    except (OSError, ValueError) as exc:
        verify("audit_source_available", False, str(exc))
    return {"status": "PASS_STATIC_ONLY" if not issues else "FAIL", "checks": checks,
            "errors": issues, "runtime_verified": False, "rom_built": False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=".")
    args = parser.parse_args()
    result = audit(Path(args.project))
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "PASS_STATIC_ONLY" else 1


if __name__ == "__main__":
    raise SystemExit(main())
