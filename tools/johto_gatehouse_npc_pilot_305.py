#!/usr/bin/env python3
"""REF-305 source audit for native counter dialogue and Gold-red Ecruteak Officers.

This is a source/asset contract audit only. It does not build/link a ROM or emulate
the Game Boy's OAM, tilemap, or text engine.
"""
from __future__ import annotations

import argparse
import json
import re
try:
    from johto_audit_phase import approved_phase
except ImportError:
    from tools.johto_audit_phase import approved_phase
from pathlib import Path
from typing import Mapping

GATES = (
    {
        "stable_id": 23,
        "gold_map": "Route38EcruteakGate",
        "runtime_file": "data/johto_west_runtime_297.asm",
        "header": "JohtoRoute38EcruteakGateRuntimeHeader",
        "header_end": "JohtoRoute38EcruteakGateHeaderEnd",
        "objects": "JohtoRoute38EcruteakGateRuntimeObjects",
        "objects_end": "JohtoRoute38RuntimeObjects",
        "text_pointers": "JohtoRoute38EcruteakGateTextPointers",
        "text_pointers_end": "JohtoRoute38TextPointers",
        "text": "JohtoRoute38EcruteakGateOfficerText",
        "sprite": "SPRITE_JOHTO_OFFICER",
        "dialogue": (
            "Where did you say",
            "you're from?",
            "NEW BARK TOWN?",
            "PROF.ELM lives",
            "over there, right?",
            "You've come a long",
            "way to get here.",
        ),
    },
    {
        "stable_id": 62,
        "gold_map": "Route42EcruteakGate",
        "runtime_file": "data/johto_east_runtime_300.asm",
        "header": "JohtoRoute42EcruteakGateRuntimeHeader",
        "header_end": "JohtoRoute42EcruteakGateHeaderEnd",
        "objects": "JohtoRoute42EcruteakGateRuntimeObjects",
        "objects_end": "JohtoRoute42RuntimeObjects",
        "text_pointers": "JohtoRoute42EcruteakGateTextPointers",
        "text_pointers_end": "JohtoRoute42TextPointers",
        "text": "JohtoRoute42EcruteakGateOfficerText",
        "sprite": "SPRITE_JOHTO_OFFICER",
        "dialogue": (
            "MOUNT MORTAR is",
            "like a maze.",
            "Be careful. Don't",
            "get lost in there.",
        ),
    },
)

GOLD_DAY_RED = ((27, 31, 27), (31, 19, 10), (31, 7, 1), (0, 0, 0))


def _read(root: Path, rel: str, overrides: Mapping[str, str] | None) -> str:
    if overrides and rel in overrides:
        return overrides[rel]
    return (root / rel).read_text(encoding="utf-8")


def _bytes(root: Path, rel: str, overrides: Mapping[str, bytes] | None) -> bytes:
    if overrides and rel in overrides:
        return overrides[rel]
    return (root / rel).read_bytes()


def _section(source: str, start: str, end: str) -> str:
    if start not in source or end not in source:
        raise ValueError(f"missing section delimiter {start!r} / {end!r}")
    return source.split(start, 1)[1].split(end, 1)[0]


def _counter_front_tile_id(project: Path, gate: Mapping[str, object],
                           byte_overrides: Mapping[str, bytes] | None) -> int:
    """Return the ACTUAL 8x8 probe for UP-facing player at (5,4).

    GetTileAndCoordsInFrontOfPlayer reads ``aCoord 8,7`` when facing UP.
    Player's 16x16 screen box occupies columns 8-9, rows 8-9. Thus row 7
    is the LOWER row (not upper!) of the 16x16 cell directly in front.
    The front cell (5,3) is the lower-right quadrant of 32px block #3;
    the engine probes that quadrant's lower-left 8x8 tile, offset +14.
    """
    blockmap_rel = f"maps/johto_pilot/{gate['gold_map']}.runtime.blk"
    blockmap = _bytes(project, blockmap_rel, byte_overrides)
    blockset_rel = "gfx/blocksets/johto_gate.bst"
    blockset = _bytes(project, blockset_rel, byte_overrides)
    if len(blockmap) != 20 or len(blockset) != 19 * 16:
        raise ValueError("JohtoGate map/blockset dimensions changed")
    x, y = 5, 3
    block_id = blockmap[(y // 2) * 5 + (x // 2)]
    tile_offset = ((y % 2) * 2 + 1) * 4 + ((x % 2) * 2)
    return blockset[block_id * 16 + tile_offset]


def _palette_rgb_rows(source: str, start: str, end: str) -> tuple[tuple[int, int, int], ...]:
    body = _section(source, start, end)
    rows = re.findall(r"(?m)^\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*$", body)
    return tuple(tuple(map(int, row)) for row in rows[:4])


def _sprite_const_values(source: str) -> dict[str, int]:
    values: dict[str, int] = {}
    current: int | None = None
    for line in source.splitlines():
        match = re.match(r"^\s*const_value\s*=\s*(\d+)", line)
        if match:
            current = int(match.group(1))
            continue
        match = re.match(r"^\s*const\s+(SPRITE_\w+)", line)
        if match and current is not None:
            values[match.group(1)] = current
            current += 1
    return values


def audit(
    project: Path,
    gold_root: Path | None = None,
    text_overrides: Mapping[str, str] | None = None,
    byte_overrides: Mapping[str, bytes] | None = None,
) -> dict:
    project = Path(project)
    errors: list[str] = []
    checks: list[dict] = []

    def ck(name: str, ok: bool, detail: str = "") -> None:
        checks.append({"check": name, "status": "PASS" if ok else "FAIL", "detail": detail})
        if not ok:
            errors.append(f"{name}: {detail or 'contract mismatch'}")

    try:
        version = _read(project, "data/game_version.asm", text_overrides)
        ck(
            "one_shared_rom_version_ref317",
            approved_phase(version, _read(project, "constants/region_map_constants.asm", text_overrides), 40, 317)
            and "IF DEF(BATTLE_TEST_BUILD)" not in version
            and "ENDC" not in version,
            "normal and BATTLE_TEST_BUILD ROMs must share approved REF-317+ label",
        )

        build_sources = []
        for rel in ("Makefile", "constants.asm", "main.asm", "wram.asm"):
            try:
                build_sources.append(_read(project, rel, text_overrides))
            except OSError:
                pass
        ck(
            "battle_test_build_switch_preserved",
            any("BATTLE_TEST_BUILD" in src for src in build_sources),
            "BATTLE_TEST_BUILD must remain available for test-only behavior",
        )

        home = _read(project, "home/overworld.asm", text_overrides)
        talk = _section(home, "IsSpriteOrSignInFrontOfPlayer::", "IsSpriteInFrontOfPlayer::")
        ck(
            "native_counter_talk_range_32px",
            "wTilesetTalkingOverTiles" in talk
            and "ld d,$20" in talk
            and "cp c" in talk,
            "native RBY interaction must compare the front tile against the tileset's counter list and use 32px range",
        )
        player_state = _read(project, "engine/overworld/player_state.asm", text_overrides)
        front_reader = _section(
            player_state, "GetTileAndCoordsInFrontOfPlayer:", "GetTileTwoStepsInFrontOfPlayer:"
        )
        ck(
            "native_front_tile_reader_uses_up_cell",
            "aCoord 8, 7" in front_reader and "dec d" in front_reader,
            "facing UP reads the actual tile in front of the player from wTileMap",
        )
        ck(
            "native_interaction_faces_selected_sprite",
            "set 7,[hl]" in home,
            "the selected object is flagged to face the player before its text is dispatched",
        )

        display = _section(
            _read(project, "home.asm", text_overrides),
            "DisplayTextID::", "AfterDisplayingTextID::"
        )
        ck(
            "native_object_text_id_dispatch",
            "ld hl,wMapSpriteData" in display
            and "ld a,[hl] ; a = text ID of the sprite" in display
            and "wMapTextPtr" in display,
            "DisplayTextID must resolve the selected sprite's map-local text ID",
        )

        sprite_engine = _read(project, "engine/overworld/map_sprites.asm", text_overrides)
        init_sprites = _section(sprite_engine, "InitMapSprites:", "LoadMapSpriteTilePatterns:")
        ck(
            "indoor_maps_load_object_sprite_ids",
            "call InitOutsideMapSprites" in init_sprites
            and "ret c" in init_sprites
            and "ld hl,wSpriteStateData1" in init_sprites,
            "LoadMapHeader must decode object count and six-byte sprite records",
        )
        outside_sprite_init = _section(
            sprite_engine, "InitOutsideMapSprites:", "InitMapSprites:"
        )
        tilesets = _read(project, "constants/tilesets.asm", text_overrides)
        map_handles = _read(project, "constants/region_map_constants.asm", text_overrides)
        descriptors = _read(project, "data/johto_pilot_runtime_assets.asm", text_overrides)
        ck(
            "johto_gate_uses_indoor_object_sprite_path",
            "const JOHTO_PILOT" in tilesets
            and "const JOHTO_GATE" in tilesets
            and "DEF JOHTO_RUNTIME_MAP_HANDLE EQU $fc" in map_handles
            and "cp JOHTO_PILOT" in outside_sprite_init
            and "cp a,REDS_HOUSE_1F" in outside_sprite_init
            and "ret nc ; not an outdoor Kanto map" in outside_sprite_init
            and re.search(r"(?m)^\s*db JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID, JOHTO_GATE,", descriptors) is not None
            and re.search(r"(?m)^\s*db JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, JOHTO_GATE,", descriptors) is not None,
            "both gate maps use JOHTO_GATE, not the JOHTO_PILOT outdoor sprite-set path",
        )

        sprite_constants = _read(project, "constants/sprite_constants.asm", text_overrides)
        sprite_table = _read(project, "data/sprite_sets.asm", text_overrides)
        color_sprites = _read(project, "color/sprites.asm", text_overrides)
        map_sprites = _read(project, "engine/overworld/map_sprites.asm", text_overrides)
        palette_data = _read(project, "color/data/spritepalettes.asm", text_overrides)
        sprite_values = _sprite_const_values(sprite_constants)
        sprite_pointer_body = _section(
            sprite_table, "SpriteSheetPointerTable:", "SpriteSheetPointerTableEnd::"
        )
        sprite_palette_body = _section(
            color_sprites, "SpritePaletteAssignments:", "SpritePaletteAssignmentsEnd::"
        )

        ck(
            "johto_officer_alias_constant",
            re.search(r"(?m)^\s*const SPRITE_JOHTO_OFFICER\s*;\s*\$64\b", sprite_constants) is not None
            and sprite_values.get("SPRITE_BALL") == 0x51
            and sprite_values.get("SPRITE_BENCH_GUY") == 0x63
            and sprite_values.get("SPRITE_JOHTO_OFFICER") == 0x64,
            "SPRITE_JOHTO_OFFICER must be actual ID $64, after SPRITE_BENCH_GUY $63 and SPRITE_BALL $51",
        )
        ck(
            "johto_officer_sprite_tables_are_index_aligned",
            len(re.findall(r"(?m)^\s*dw ", sprite_pointer_body)) == sprite_values.get("SPRITE_JOHTO_OFFICER")
            and len(re.findall(r"(?m)^\s*db PAL_", sprite_palette_body)) == sprite_values.get("SPRITE_JOHTO_OFFICER"),
            "sprite sheet pointer and palette assignment tables must each contain one row for every ID 1..$64",
        )
        ck(
            "johto_officer_alias_uses_guard_sheet",
            re.search(
                r"(?s);\s*SPRITE_JOHTO_OFFICER[^\n]*\n\s*dw GuardSprite\s*\n\s*db \$c0[^\n]*\n\s*db BANK\(GuardSprite\)",
                sprite_table,
            ) is not None
            and "ASSERT SpriteSheetPointerTableEnd - SpriteSheetPointerTable == SPRITE_JOHTO_OFFICER * 4" in sprite_table,
            "new alias must load the male Guard/Gold Officer sheet as a normal 12-tile human sprite",
        )
        ck(
            "johto_officer_alias_has_gold_red_palette",
            re.search(
                r"(?m)^\s*;\s*0x63:\s*SPRITE_JOHTO_OFFICER[^\n]*\n\s*db PAL_OW_RED",
                color_sprites,
            ) is not None
            and "ASSERT SpritePaletteAssignmentsEnd - SpritePaletteAssignments == SPRITE_JOHTO_OFFICER" in color_sprites,
            "the Johto-only alias must use PAL_OW_RED without recoloring Kanto's SPRITE_GUARD",
        )
        ck(
            "global_kanto_guard_palette_unchanged",
            re.search(
                r"(?m)^\s*;\s*0x31:\s*SPRITE_GUARD[^\n]*\n\s*db PAL_OW_BLUE",
                color_sprites,
            ) is not None,
            "global SPRITE_GUARD remains blue for existing Kanto uses",
        )
        ck(
            "johto_officer_alias_not_misclassified_as_four_tile",
            "cp a,SPRITE_BALL ; is it a 4-tile sprite?" in map_sprites
            and "cp a,SPRITE_JOHTO_OFFICER ; this alias is a normal 12-tile human sprite" in map_sprites
            and "jr z,.notFourTileSprite" in map_sprites,
            "the $63 alias is exempted from the static 4-tile object range and loads GuardSprite's 12 tiles",
        )

        red_rows = _palette_rgb_rows(palette_data, "; PAL_OW_RED", "; PAL_OW_BLUE")
        ck(
            "rpp_red_palette_matches_gold_day_pal_npc_red",
            red_rows == GOLD_DAY_RED,
            f"PAL_OW_RED must match Gold PAL_NPC_RED day RGB rows; got {red_rows!r}",
        )
        if gold_root is not None:
            gold_palette = (Path(gold_root) / "gfx/overworld/npc_sprites.pal").read_text(encoding="utf-8")
            gold_day = _section(gold_palette, "; day", "; nite")
            ck(
                "gold_day_pal_npc_red_reference",
                re.search(
                    r"RGB\s+27,31,27,\s*31,19,10,\s*31,07,01,\s*00,00,00\s*;\s*red",
                    gold_day,
                ) is not None,
                "Gold's day PAL_NPC_RED is the red palette used by the original gate Officers",
            )

        object_macro = _read(project, "macros/data_macros.asm", text_overrides)
        object_macro = _section(object_macro, "object: MACRO", "ENDM")
        ck(
            "object_macro_encodes_gold_coordinates_and_facing",
            all(x in object_macro for x in (
                "db \\1", "db \\3 + 4", "db \\2 + 4",
                "db \\4", "db \\5", "db \\6",
            )),
            "object macro must preserve Gold x/y, standing mode, facing, and text ID",
        )

        tileset_headers = _read(project, "data/tileset_headers.asm", text_overrides)
        ck(
            "johto_gate_counter_tile_registered",
            re.search(
                r"(?m)^\s*tileset\s+JohtoGate_Block\s*,\s*JohtoGate_GFX\s*,\s*Gate_Coll\s*,\s*\$0E\s*,\s*\$FF\s*,\s*\$FF\s*,",
                tileset_headers,
            ) is not None,
            "JohtoGate must register the actual lower-left front-cell probe $0E; other slots remain disabled",
        )

        for gate in GATES:
            rel = str(gate["runtime_file"])
            source = _read(project, rel, text_overrides)
            header = _section(source, str(gate["header"]) + "::", str(gate["header_end"]) + "::")
            objects = _section(source, str(gate["objects"]) + "::", str(gate["objects_end"]) + "::")
            text_section = _section(
                source, str(gate["text_pointers"]) + ":", str(gate["text_pointers_end"]) + ":"
            )
            ck(
                f"id{gate['stable_id']}_header_map_local",
                f"dw {gate['text_pointers']}" in header
                and f"dw {gate['objects']}" in header,
                "map header must point to this gate's own text and object tables",
            )
            object_lines = [
                line.strip() for line in objects.splitlines()
                if line.strip().startswith("object ")
            ]
            ck(
                f"id{gate['stable_id']}_one_officer_object",
                re.search(r"(?m)^\s*db 1\s*;.*Officer", objects) is not None
                and len(object_lines) == 1
                and object_lines[0] == (
                    f"object {gate['sprite']}, 5, 2, STAY, DOWN, $1"
                ),
                "exactly one Gold Officer object at (5,2), standing down, using the red-palette Johto alias",
            )

            roles_rel = f"maps/johto_pilot/{gate['gold_map']}.roles.bin"
            roles = _bytes(project, roles_rel, byte_overrides)
            object_role = roles[2 * 10 + 5] if len(roles) == 80 else 1
            counter_role = roles[3 * 10 + 5] if len(roles) == 80 else 0
            approach_role = roles[4 * 10 + 5] if len(roles) == 80 else 1
            counter_tile = _counter_front_tile_id(project, gate, byte_overrides)
            ck(
                f"id{gate['stable_id']}_south_approach_geometry",
                len(roles) == 80
                and object_role == 0
                and counter_role == 1
                and approach_role == 0
                and counter_tile == 0x0E,
                f"Gold geometry must be Officer (5,2), blocked counter (5,3) with actual UP-facing sample tile $0E, and walkable player approach (5,4); got role={object_role}/{counter_role}/{approach_role}, tile=${counter_tile:02x}",
            )
            ck(
                f"id{gate['stable_id']}_counter_tile_long_range_path",
                counter_tile == 0x0E
                and re.search(
                    r"(?m)^\s*tileset\s+JohtoGate_Block\s*,\s*JohtoGate_GFX\s*,\s*Gate_Coll\s*,\s*\$0E\s*,",
                    tileset_headers,
                ) is not None
                and "ld d,$20" in talk,
                "standing at (5,4) facing UP reads lower-left counter tile $0E and enables the native 32px sprite search for the Officer at (5,2)",
            )
            ck(
                f"id{gate['stable_id']}_map_local_text_pointer",
                re.search(rf"(?m)^\s*dw {re.escape(str(gate['text']))}\s*$", text_section) is not None,
                "text ID 1 must point to this gate's own Officer dialogue",
            )
            for phrase in gate["dialogue"]:
                ck(
                    f"id{gate['stable_id']}_dialogue_{len(checks)}",
                    f'"{phrase}"' in text_section,
                    f"missing Gold-derived dialogue line: {phrase}",
                )
            ck(
                f"id{gate['stable_id']}_dialogue_line_width",
                all(len(phrase) <= 18 for phrase in gate["dialogue"]),
                "every Officer dialogue line must fit the 18-character text window",
            )
            ck(
                f"id{gate['stable_id']}_bank_local_data",
                f"ASSERT BANK({gate['header']}) == BANK({gate['objects']})" in source
                and f"ASSERT BANK({gate['header']}) == BANK({gate['text_pointers']})" in source
                and f"ASSERT BANK({gate['header']}) == BANK({gate['text']})" in source,
                "header, objects, text pointer table and text must be in the same ROMX bank",
            )

        west_source = _read(project, str(GATES[0]["runtime_file"]), text_overrides)
        east_source = _read(project, str(GATES[1]["runtime_file"]), text_overrides)
        west_text = _section(west_source, str(GATES[0]["text_pointers"]) + ":",
                             str(GATES[0]["text_pointers_end"]) + ":")
        east_text = _section(east_source, str(GATES[1]["text_pointers"]) + ":",
                             str(GATES[1]["text_pointers_end"]) + ":")
        ck(
            "west_east_dialogue_isolation",
            GATES[0]["text"] in west_text
            and GATES[1]["text"] not in west_text
            and GATES[1]["text"] in east_text
            and GATES[0]["text"] not in east_text
            and "NEW BARK TOWN?" not in east_text
            and "MOUNT MORTAR is" not in west_text,
            "ID23 and ID62 must not reuse or cross-wire the other gate's dialogue",
        )

        descriptors = _read(project, "data/johto_pilot_runtime_assets.asm", text_overrides)
        ck(
            "stable_map_ids_dispatch_independently",
            "cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID" in descriptors
            and "ld hl, JohtoRoute38EcruteakGateRuntimeDescriptor" in descriptors
            and "cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID" in descriptors
            and "ld hl, JohtoRoute42EcruteakGateRuntimeDescriptor" in descriptors,
            "stable IDs 23 and 62 must resolve to their own runtime descriptors",
        )

        if gold_root is not None:
            for gate in GATES:
                gold_map = Path(gold_root) / "maps" / f"{gate['gold_map']}.asm"
                gold = gold_map.read_text(encoding="utf-8")
                ck(
                    f"id{gate['stable_id']}_gold_officer_source",
                    re.search(
                        r"(?m)^\s*object_event\s+5,\s*2,\s*SPRITE_OFFICER,\s*"
                        r"SPRITEMOVEDATA_STANDING_DOWN,.*PAL_NPC_RED",
                        gold,
                    ) is not None
                    and len(re.findall(r"(?m)^\s*object_event\b", gold)) == 1,
                    "Gold source must define one red-palette Officer at (5,2), standing down",
                )
                ck(
                    f"id{gate['stable_id']}_gold_simple_text_script",
                    f"{gate['gold_map']}OfficerScript:" in gold
                    and f"jumptextfaceplayer {gate['gold_map']}OfficerText" in gold
                    and f"{gate['gold_map']}OfficerText:" in gold,
                    "Gold source must use a simple face-player text script",
                )
                for phrase in gate["dialogue"]:
                    ck(
                        f"id{gate['stable_id']}_gold_text_{len(checks)}",
                        phrase in gold,
                        f"Gold map is missing source phrase {phrase!r}",
                    )
                ck(
                    f"id{gate['stable_id']}_gold_no_scene_or_callback",
                    re.search(r"(?s)def_scene_scripts\s*\n\s*def_callbacks\s*\n", gold) is not None,
                    "the Gold gate has no scene/callback event requirements",
                )

    except (OSError, ValueError, KeyError, IndexError, TypeError) as exc:
        ck("read_parse", False, str(exc))

    return {
        "status": "PASS_STATIC_ONLY" if not errors else "FAIL",
        "errors": errors,
        "checks": checks,
        "rom_built": False,
        "device_verified": False,
    }


def fault_tests(project: Path, gold_root: Path | None = None) -> dict[str, bool]:
    project = Path(project)
    west_rel = str(GATES[0]["runtime_file"])
    east_rel = str(GATES[1]["runtime_file"])
    west = (project / west_rel).read_text(encoding="utf-8")
    east = (project / east_rel).read_text(encoding="utf-8")
    version = (project / "data/game_version.asm").read_text(encoding="utf-8")
    tileset_rel = "data/tileset_headers.asm"
    tilesets = (project / tileset_rel).read_text(encoding="utf-8")
    palette_rel = "color/sprites.asm"
    palettes = (project / palette_rel).read_text(encoding="utf-8")
    sprite_table_rel = "data/sprite_sets.asm"
    sprite_table = (project / sprite_table_rel).read_text(encoding="utf-8")
    loader_rel = "engine/overworld/map_sprites.asm"
    loader = (project / loader_rel).read_text(encoding="utf-8")
    west_roles_rel = "maps/johto_pilot/Route38EcruteakGate.roles.bin"
    west_roles = bytearray((project / west_roles_rel).read_bytes())
    west_blocks_rel = "maps/johto_pilot/Route38EcruteakGate.runtime.blk"
    blockset_rel = "gfx/blocksets/johto_gate.bst"
    blockset = bytearray((project / blockset_rel).read_bytes())

    faults: dict[str, bool] = {}

    def rejected_text(rel: str, changed: str) -> bool:
        return changed != (project / rel).read_text(encoding="utf-8") and audit(
            project, gold_root, {rel: changed}
        )["status"] == "FAIL"

    bad_west_sprite = west.replace(
        "object SPRITE_JOHTO_OFFICER, 5, 2, STAY, DOWN, $1",
        "object SPRITE_OFFICER_JENNY, 5, 2, STAY, DOWN, $1", 1
    )
    faults["wrong_west_sprite_rejected"] = rejected_text(west_rel, bad_west_sprite)

    bad_west_facing = west.replace(
        "object SPRITE_JOHTO_OFFICER, 5, 2, STAY, DOWN, $1",
        "object SPRITE_JOHTO_OFFICER, 5, 2, STAY, UP, $1", 1
    )
    faults["wrong_west_facing_rejected"] = rejected_text(west_rel, bad_west_facing)

    bad_east_text_id = east.replace(
        "object SPRITE_JOHTO_OFFICER, 5, 2, STAY, DOWN, $1",
        "object SPRITE_JOHTO_OFFICER, 5, 2, STAY, DOWN, $2", 1
    )
    faults["wrong_east_text_id_rejected"] = rejected_text(east_rel, bad_east_text_id)

    bad_east_coord = east.replace(
        "object SPRITE_JOHTO_OFFICER, 5, 2, STAY, DOWN, $1",
        "object SPRITE_JOHTO_OFFICER, 4, 2, STAY, DOWN, $1", 1
    )
    faults["wrong_east_coordinate_rejected"] = rejected_text(east_rel, bad_east_coord)

    bad_east_pointer = east.replace(
        "dw JohtoRoute42EcruteakGateOfficerText",
        "dw JohtoRoute38EcruteakGateOfficerText", 1
    )
    faults["cross_gate_text_pointer_rejected"] = rejected_text(east_rel, bad_east_pointer)

    bad_east_text = east.replace("MOUNT MORTAR is", "ROUTE 42 is", 1)
    faults["wrong_east_dialogue_rejected"] = rejected_text(east_rel, bad_east_text)

    bad_version = re.sub(r'db "REF-\d+[A-Z]?@"', 'db "TEST-LABEL@"', version, count=1)
    faults["separate_test_version_rejected"] = (
        bad_version != version
        and audit(project, gold_root, {"data/game_version.asm": bad_version})["status"] == "FAIL"
    )

    blocked_roles = bytearray(west_roles)
    blocked_roles[2 * 10 + 5] = 1
    faults["blocked_officer_tile_rejected"] = (
        audit(project, gold_root, byte_overrides={west_roles_rel: bytes(blocked_roles)})["status"] == "FAIL"
    )

    blocked_approach = bytearray(west_roles)
    blocked_approach[4 * 10 + 5] = 1
    faults["blocked_south_approach_rejected"] = (
        audit(project, gold_root, byte_overrides={west_roles_rel: bytes(blocked_approach)})["status"] == "FAIL"
    )

    missing_counter_registration = tilesets.replace(
        "tileset JohtoGate_Block, JohtoGate_GFX, Gate_Coll, $0E,$FF,$FF, $FF, INDOOR",
        "tileset JohtoGate_Block, JohtoGate_GFX, Gate_Coll, $FF,$FF,$FF, $FF, INDOOR", 1
    )
    faults["missing_counter_tile_registration_rejected"] = rejected_text(tileset_rel, missing_counter_registration)

    wrong_counter_tile = bytearray(blockset)
    # Source: aCoord 8,7 means LOWER-left tile of target cell (5,3): block3, offset 14.
    wrong_counter_tile[3 * 16 + 14] = 1
    faults["wrong_counter_graphic_tile_rejected"] = (
        audit(project, gold_root, byte_overrides={blockset_rel: bytes(wrong_counter_tile)})["status"] == "FAIL"
    )

    mistaken_top_left_registration = tilesets.replace(
        "tileset JohtoGate_Block, JohtoGate_GFX, Gate_Coll, $0E,$FF,$FF, $FF, INDOOR",
        "tileset JohtoGate_Block, JohtoGate_GFX, Gate_Coll, $00,$FF,$FF, $FF, INDOOR", 1
    )
    faults["mistaken_upper_left_tile_registration_rejected"] = rejected_text(
        tileset_rel, mistaken_top_left_registration
    )

    # Changing just the upper-left graphic MUST NOT look like a broken talk tile:
    # the real UP-facing probe is lower-left. Previous REF-305 audit failed this.
    unrelated_upper_left_tile = bytearray(blockset)
    unrelated_upper_left_tile[3 * 16 + 10] = 1
    faults["upper_left_graphic_not_confused_with_talk_probe"] = (
        audit(project, gold_root, byte_overrides={blockset_rel: bytes(unrelated_upper_left_tile)})["status"] == "PASS_STATIC_ONLY"
    )

    wrong_alias_palette = palettes.replace(
        "; 0x63: SPRITE_JOHTO_OFFICER (Gold PAL_NPC_RED equivalent; keep SPRITE_GUARD unchanged)\n\tdb PAL_OW_RED",
        "; 0x63: SPRITE_JOHTO_OFFICER (Gold PAL_NPC_RED equivalent; keep SPRITE_GUARD unchanged)\n\tdb PAL_OW_BLUE", 1
    )
    faults["wrong_johto_officer_palette_rejected"] = rejected_text(palette_rel, wrong_alias_palette)

    recolored_global_guard = palettes.replace(
        "; 0x31: SPRITE_GUARD ($30)\n\tdb PAL_OW_BLUE",
        "; 0x31: SPRITE_GUARD ($30)\n\tdb PAL_OW_RED", 1
    )
    faults["global_kanto_guard_recolor_rejected"] = rejected_text(palette_rel, recolored_global_guard)

    wrong_alias_sheet = sprite_table.replace(
        "; SPRITE_JOHTO_OFFICER: Gold male Officer uses the same pixels as GuardSprite.\n\tdw GuardSprite",
        "; SPRITE_JOHTO_OFFICER: Gold male Officer uses the same pixels as GuardSprite.\n\tdw RocketFSprite", 1
    )
    faults["wrong_johto_officer_sheet_rejected"] = rejected_text(sprite_table_rel, wrong_alias_sheet)

    missing_human_exception = loader.replace(
        "\tcp a,SPRITE_JOHTO_OFFICER ; this alias is a normal 12-tile human sprite\n\tjr z,.notFourTileSprite\n",
        "; missing Johto Officer human-sprite exception\n", 1
    )
    faults["johto_officer_four_tile_misclassification_rejected"] = rejected_text(loader_rel, missing_human_exception)

    bad_east_count = east.replace(
        "db 1 ; Gold Route42EcruteakGate Officer", "db 0 ; Gold Route42EcruteakGate Officer", 1
    )
    faults["missing_east_sprite_count_rejected"] = rejected_text(east_rel, bad_east_count)

    return faults


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path("."))
    parser.add_argument("--gold-root", type=Path)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()

    report = audit(args.project, args.gold_root)
    report["fault_tests"] = fault_tests(args.project, args.gold_root)
    report["fault_tests_passed"] = all(report["fault_tests"].values())
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{report['status']}: {len(report['checks'])} checks; "
          f"fault tests {'PASS' if report['fault_tests_passed'] else 'FAIL'}")
    for error in report["errors"]:
        print("FAIL:", error)
    for name, passed in report["fault_tests"].items():
        print(("PASS " if passed else "FAIL ") + name)
    return 0 if report["status"] == "PASS_STATIC_ONLY" and report["fault_tests_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
