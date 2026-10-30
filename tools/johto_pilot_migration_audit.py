#!/usr/bin/env python3
"""Read-only migration audit for the current stable-ID Johto pilot project.

This is intentionally separate from the legacy NPC-5.62.243 runtime auditors:
the current project uses data/johto_pilot_map_headers.asm, dense active slots,
shared runtime handle $FC, and registered Warp selector $FB. It validates the
current pilot source contracts without editing files, compiling ROMs, or
claiming phone/gameplay acceptance.

Usage:
  python tools/johto_pilot_migration_audit.py --project .
  python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold-master
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from johto_gold_compat import PROFILES, resolve_gold_root
try:
    from johto_gate_music_bike_audit import audit as audit_gate_music_bike
except ImportError:
    from tools.johto_gate_music_bike_audit import audit as audit_gate_music_bike
try:
    from johto_map_name_sign_audit import audit as audit_map_sign
except ImportError:
    from tools.johto_map_name_sign_audit import audit as audit_map_sign
try:
    from johto_rom0_space_preflight import inspect as inspect_rom0_space
except ImportError:
    from tools.johto_rom0_space_preflight import inspect as inspect_rom0_space
try:
    from johto_union_cave_portal_audit import audit as audit_union_cave_portal
except ImportError:
    from tools.johto_union_cave_portal_audit import audit as audit_union_cave_portal
try:
    from tileset_index_preflight_267 import audit as audit_tileset_index
except ImportError:
    from tools.tileset_index_preflight_267 import audit as audit_tileset_index
from typing import Iterable
try:
    from johto_table_assert_preflight import inspect as inspect_johto_table_asserts
except ImportError:
    from tools.johto_table_assert_preflight import inspect as inspect_johto_table_asserts

try:
    from johto_gold_door_audit import GoldCollisionIndex, inspect as inspect_gold
    from johto_gold_connection_reference import check_frozen_gold_source
except ImportError:  # Support import through unittest discovery from project root.
    from tools.johto_gold_door_audit import GoldCollisionIndex, inspect as inspect_gold
    from tools.johto_gold_connection_reference import check_frozen_gold_source


EXPECTED_ACTIVE_IDS = [0, 1, 2, 3, 4, 125, 5, 6, 7, 102, 20, 19, 16, 8, 9]
EXPECTED_CONNECTIONS = {
    (0, "WEST", 1), (1, "EAST", 0),
    (1, "WEST", 2), (2, "EAST", 1),
    (2, "NORTH", 3), (3, "SOUTH", 2),
    (3, "NORTH", 4), (4, "SOUTH", 3),
    (4, "WEST", 5), (5, "EAST", 4),
    (5, "SOUTH", 7), (7, "NORTH", 5),
}
MAP_LAYOUTS = {
    "NewBarkTown": (10, 9),
    "Route29": (30, 9),
    "CherrygroveCity": (20, 9),
    "Route30": (10, 27),
    "Route31": (20, 9),
    "GuideGentsHouse": (4, 4),
    "VioletCity": (20, 18),
    "Route31VioletGate": (5, 4),
    "Route32": (10, 45),
    "Route32RuinsOfAlphGate": (5, 4),
    "RuinsOfAlphOutside": (10, 18),
    "Route36RuinsOfAlphGate": (5, 4),
    "Route36": (30, 9),
    "UnionCave1F": (10, 18),
    "Route33": (10, 9),
}
GOLD_SOURCE_MAPS = {
    "NewBarkTown": "NewBarkTown",
    "Route29": "Route29",
    "CherrygroveCity": "CherrygroveCity",
    "Route30": "Route30",
    "Route31": "Route31",
    "GuideGentsHouse": "GuideGentsHouse",
    "VioletCity": "VioletCity",
    "Route31VioletGate": "Route31VioletGate",
    "Route32": "Route32",
    "Route32RuinsOfAlphGate": "Route32RuinsOfAlphGate",
    "RuinsOfAlphOutside": "RuinsOfAlphOutside",
    "Route36RuinsOfAlphGate": "Route36RuinsOfAlphGate",
    "Route36": "Route36",
    "UnionCave1F": "UnionCave1F",
    "Route33": "Route33",
}


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise FileNotFoundError(f"required source file missing: {relative}")
    return path.read_text(encoding="utf-8")


def _section(source: str, start: str, end: str) -> str:
    def positions(label: str) -> list[tuple[int, int]]:
        pattern = re.compile(r"(?m)^" + re.escape(label) + r"::?\s*$")
        # The optional second colon allows both common RGBDS label styles.
        return [(match.start(), match.end()) for match in pattern.finditer(source)]
    start_pos, end_pos = positions(start), positions(end)
    if len(start_pos) != 1 or len(end_pos) != 1 or start_pos[0][1] >= end_pos[0][0]:
        raise ValueError(f"missing/duplicate ASM section labels: {start}, {end}")
    return source[start_pos[0][1]:end_pos[0][0]]


def _equates(root: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    for relative in ("constants/region_map_constants.asm", "constants/johto_fixed_map_ids.asm"):
        text = _read(root, relative)
        for name, value in re.findall(r"(?m)^\s*DEF\s+([A-Za-z_][A-Za-z_0-9]*)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)\b", text):
            result[name] = int(value[1:], 16) if value.startswith("$") else int(value)
    return result


def _check(errors: list[str], checks: list[dict], name: str, condition: bool, detail: str) -> None:
    checks.append({"check": name, "status": "PASS" if condition else "FAIL", "detail": detail})
    if not condition:
        errors.append(f"{name}: {detail}")


def _parse_connection_rows(source: str, start: str, end: str, ids: dict[str, int]) -> set[tuple[int, str, int]]:
    body = _section(source, start, end)
    rows: set[tuple[int, str, int]] = set()
    for raw in body.splitlines():
        code = raw.split(";", 1)[0].strip()
        if not code:
            continue
        match = re.fullmatch(r"db\s+MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+)\s*,\s*(WEST|EAST|NORTH|SOUTH)\s*,\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+)", code)
        if not match:
            raise ValueError(f"unrecognized source connection row: {code}")
        src_symbol, direction, dst_symbol = match.groups()
        if src_symbol not in ids or dst_symbol not in ids:
            raise ValueError(f"unknown stable-ID symbol in connection: {code}")
        row = (ids[src_symbol], direction, ids[dst_symbol])
        if row in rows:
            raise ValueError(f"duplicate source connection: {row}")
        rows.add(row)
    return rows


def _parse_runtime_warp_rows(source: str) -> list[tuple[str, ...]]:
    body = _section(source, "JohtoRegisteredWarpRoutes", "JohtoRegisteredWarpRoutesEnd")
    rows = []
    for raw in body.splitlines():
        code = raw.split(";", 1)[0].strip()
        if not code:
            continue
        match = re.fullmatch(r"db\s+(MAP_REGION_(?:JOHTO|KANTO))\s*,\s*(JOHTO_[A-Z0-9_]+|[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*(MAP_REGION_(?:JOHTO|KANTO))\s*,\s*(JOHTO_[A-Z0-9_]+|[A-Z0-9_]+)", code)
        if not match:
            raise ValueError(f"unrecognized registered Warp row: {code}")
        rows.append(match.groups())
    return rows


def _render_block_map(blocks: bytes, blockset: bytes, tileset_png: Path, width: int, height: int) -> bytes:
    """Render a block map to RGBA bytes without assuming equal block IDs.

    Gold and RPP can use different metatile indices while still rendering the
    exact same room. Each block is 4x4 8x8 tiles (16 bytes).
    """
    try:
        from PIL import Image
    except ImportError as exc:
        raise ValueError("Pillow is required for Gold/RPP pixel comparison") from exc
    if len(blocks) != width * height:
        raise ValueError(f"block map size mismatch: {len(blocks)} != {width * height}")
    if len(blockset) % 16:
        raise ValueError(f"blockset length is not a multiple of 16: {len(blockset)}")
    with Image.open(tileset_png) as source:
        tiles = source.convert("RGBA")
    if tiles.width % 8 or tiles.height % 8:
        raise ValueError(f"tileset PNG dimensions are not multiples of 8: {tiles.size}")
    tiles_per_row = tiles.width // 8
    tile_count = tiles_per_row * (tiles.height // 8)
    block_count = len(blockset) // 16
    canvas = Image.new("RGBA", (width * 32, height * 32), (0, 0, 0, 0))
    for by in range(height):
        for bx in range(width):
            block_id = blocks[by * width + bx]
            if block_id >= block_count:
                raise ValueError(f"block ID {block_id} exceeds blockset ({block_count} blocks)")
            metatile = blockset[block_id * 16:(block_id + 1) * 16]
            for ty in range(4):
                for tx in range(4):
                    tile_id = metatile[ty * 4 + tx]
                    if tile_id >= tile_count:
                        raise ValueError(f"tile ID {tile_id} exceeds tileset ({tile_count} tiles)")
                    left = (tile_id % tiles_per_row) * 8
                    top = (tile_id // tiles_per_row) * 8
                    crop = tiles.crop((left, top, left + 8, top + 8))
                    canvas.paste(crop, (bx * 32 + tx * 8, by * 32 + ty * 8))
    return canvas.tobytes()


def _audit_gold_source(project: Path, gold: Path, errors: list[str], checks: list[dict]) -> dict:
    result: dict = {"status": "NOT_RUN", "errors": [], "door_roles": {}}
    try:
        gold_report = inspect_gold(gold)
        gold_errors = list(gold_report.get("errors", []))
        _check(errors, checks, "gold_reference_inventory", not gold_errors,
               f"Gold inventory: {gold_report.get('stats', {}).get('registered_maps', 0)} maps; "
               f"{gold_report.get('stats', {}).get('warp_events', 0)} Warp events; "
               f"errors={len(gold_errors)}")
        errors.extend(f"gold_reference: {error}" for error in gold_errors)
        result.update(status="PASS" if not gold_errors else "FAIL",
                      stats=gold_report.get("stats", {}), errors=gold_errors)

        index = GoldCollisionIndex(gold)
        expected_roles = {
            ("CherrygroveCity", 25, 9): "DOOR",
            ("GuideGentsHouse", 2, 7): "WARP_CARPET_DOWN",
            ("GuideGentsHouse", 3, 7): "WARP_CARPET_DOWN",
        }
        actual_roles = {}
        for (map_name, x, y), expected in expected_roles.items():
            actual = index.role_at(map_name, x, y)
            actual_roles[f"{map_name}({x},{y})"] = actual
            _check(errors, checks, f"gold_door_semantics_{map_name}_{x}_{y}", actual == expected,
                   f"expected {expected}, got {actual}")
        result["door_roles"] = actual_roles

        comparisons = []
        for current_name, gold_name in GOLD_SOURCE_MAPS.items():
            block_file = index.block_files.get(gold_name)
            if not block_file:
                _check(errors, checks, f"gold_source_layout_{current_name}", False,
                       f"Gold blocks.asm does not resolve {gold_name}")
                continue
            gold_bytes = (gold / "maps" / block_file).read_bytes()
            if current_name == "GuideGentsHouse":
                # This project's .reference.blk is the prior RPP branch's compact
                # block-ID layout, not Gold's raw House1.blk. Gold door semantics
                # are checked above; byte identity is checked against --reference-root.
                runtime_source = project / "maps/johto_pilot/GuideGentsHouse.reference.blk"
                comparisons.append({"map": current_name, "gold_layout": block_file,
                                    "bytes": len(gold_bytes), "byte_identical": False,
                                    "expected_remap": True,
                                    "note": "RPP compact block IDs differ from Gold raw IDs; compare against --reference-root"})
                _check(errors, checks, f"gold_source_layout_{current_name}",
                       runtime_source.is_file() and runtime_source.stat().st_size == len(gold_bytes),
                       f"Gold source {block_file} has {len(gold_bytes)} cells; RPP reference must preserve the same 4x4 geometry, not raw block IDs")
            else:
                runtime_source = project / f"maps/johto_pilot/{current_name}.gold.blk"
                equal = runtime_source.is_file() and runtime_source.read_bytes() == gold_bytes
                comparisons.append({"map": current_name, "gold_layout": block_file,
                                    "bytes": len(gold_bytes), "byte_identical": equal})
                _check(errors, checks, f"gold_source_layout_{current_name}", equal,
                       f"source block layout {block_file}; bytes={len(gold_bytes)}; exact_match={equal}")
        result["source_layout_comparisons"] = comparisons

        # Compare the final 4x4 room render, not raw .blk bytes: the old RPP
        # reference and Gold House1 use different metatile IDs by design.
        try:
            gold_room = (gold / "maps" / index.block_files["GuideGentsHouse"]).read_bytes()
            gold_pixels = _render_block_map(
                gold_room, (gold / "data/tilesets/house_metatiles.bin").read_bytes(),
                gold / "gfx/tilesets/house.png", 4, 4)
            rpp_room = (project / "maps/johto_pilot/GuideGentsHouse.runtime.blk").read_bytes()
            rpp_pixels = _render_block_map(
                rpp_room, (project / "gfx/blocksets/johto_house.bst").read_bytes(),
                project / "gfx/tilesets/johto_house.png", 4, 4)
            different_pixels = sum(gold_pixels[i:i+4] != rpp_pixels[i:i+4]
                                   for i in range(0, min(len(gold_pixels), len(rpp_pixels)), 4))
            same_pixels = len(gold_pixels) == len(rpp_pixels) and different_pixels == 0
            _check(errors, checks, "gold_house_visual_equivalence", same_pixels,
                   f"rendered 128x128 RGBA pixels differ at {different_pixels} pixels; raw block IDs may differ")
            result["house_visual_comparison"] = {"status": "PASS" if same_pixels else "FAIL",
                                                  "width": 128, "height": 128,
                                                  "different_pixels": different_pixels,
                                                  "gold_block_ids_equal_rpp": gold_room == rpp_room}
        except (OSError, KeyError, ValueError) as exc:
            _check(errors, checks, "gold_house_visual_equivalence", False, str(exc))
            result["house_visual_comparison"] = {"status": "FAIL", "errors": [str(exc)]}

        seams = check_frozen_gold_source(gold)
        expected_seams = {
            ("Route30", "north"): ("Route31", -10),
            ("Route31", "south"): ("Route30", 10),
            ("CherrygroveCity", "north"): ("Route30", 5),
            ("Route30", "south"): ("CherrygroveCity", -5),
        }
        for key, expected in expected_seams.items():
            actual = seams.get(key)
            _check(errors, checks, f"gold_seam_{key[0]}_{key[1]}", actual == expected,
                   f"expected {expected}, got {actual}")
        result["gold_seams"] = {f"{key[0]}:{key[1]}": list(value) for key, value in expected_seams.items()}
    except (OSError, ValueError, KeyError) as exc:
        result.update(status="FAIL", errors=[str(exc)])
        errors.append(f"gold_reference: {exc}")
        checks.append({"check": "gold_reference", "status": "FAIL", "detail": str(exc)})
    return result


def check_johto_gate_name_sign(source: str) -> bool:
    """Reject a Kanto-$FC lookup or a visible popup in the Johto gate.

    This is intentionally an ASM shape check, not a gameplay emulator.
    """
    try:
        sign = source.split("UpdateMapNameSign::", 1)[1]
        neutral = sign.split(".IsNeutralMap\n", 1)[1].split(".NeutralMapList\n", 1)[0]
        resolve = sign.split(".ResolvePhysicalLandmark\n", 1)[1].split(".ResolveKnownFloor\n", 1)[0]
        # The first occurrence of .ResolvePhysicalLandmark can be a 'call'
        # rather than the actual standalone label. Use line anchors below.
        resolve = re.search(r"(?ms)^\.ResolvePhysicalLandmark\s*$\n(.*?)(?=^\.ResolveKnownFloor\s*$)", sign).group(1)
        copy_name = re.search(r"(?ms)^\.CopyMapNameToBuffer\s*$\n(.*?)(?=^\.copyLocalName\s*$)", sign).group(1)
    except (IndexError, AttributeError):
        return False
    neutral_ok = re.search(
        r"(?s)ld a, \[wCurMap\]\s*cp JOHTO_RUNTIME_MAP_HANDLE\s*jr nz, \.legacyNeutralMap"
        r".*?ld a, \[wCurRegion\]\s*cp MAP_REGION_JOHTO\s*jr nz, \.legacyNeutralMap"
        r".*?ld a, \[wCurLocalMapID\]\s*cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID\s*ret z",
        neutral) is not None
    resolve_ok = (re.search(
        r"(?s)ld a, \[wCurMap\]\s*cp JOHTO_RUNTIME_MAP_HANDLE\s*jr nz, \.resolveLegacyLandmark"
        r".*?ld a, \[wCurRegion\]\s*cp MAP_REGION_JOHTO\s*jr nz, \.resolveLegacyLandmark",
        resolve) is not None and
        "cp JOHTO_VIOLET_CITY_LOCAL_ID" in resolve and
        "ld hl, .JohtoVioletName" in resolve and
        "cp JOHTO_ROUTE_32_LOCAL_ID" in resolve and
        "ld hl, .JohtoRoute32Name" in resolve and
        "ld b, 0" in resolve and "ret" in resolve)
    copy_ok = ("cp JOHTO_RUNTIME_MAP_HANDLE" in copy_name and
               "cp MAP_REGION_JOHTO" in copy_name and
               "jp z, .copyLocalName" in copy_name and
               "ld a, BANK(MapNames)" in copy_name)
    names_ok = all(re.search(r"(?m)^\.Johto" + name + r"Name:.*db \"[^\"]+@\"", sign)
                   for name in ("NewBark", "Route29", "Cherrygrove", "Route30", "Route31", "Violet", "Route32"))
    return bool(neutral_ok and resolve_ok and copy_ok and names_ok)


def audit_project(project: Path, gold_root: Path | None = None, reference_root: Path | None = None,
                  gold_profile: str = "auto") -> dict:
    project = Path(project).resolve()
    if gold_root is not None:
        try:
            gold_root = resolve_gold_root(gold_root, gold_profile)
        except (ValueError, OSError) as exc:
            return {"schema": "johto-pilot-migration-audit-v1", "status": "FAIL",
                    "errors": [f"Gold source compatibility: {exc}"], "checks": [], "metrics": {},
                    "runtime_verified": False, "rom_built": False, "phone_accepted": False}
    errors: list[str] = []
    checks: list[dict] = []
    metrics: dict = {}
    try:
        constants = _equates(project)
        region = _read(project, "constants/region_map_constants.asm")
        headers = _read(project, "data/johto_header_descriptors.asm")
        runtime_assets = _read(project, "data/johto_pilot_runtime_assets.asm")
        source_resources = _read(project, "data/johto_pilot_source_resources.asm")
        map_headers = _read(project, "data/johto_pilot_map_headers.asm")
        runtime = _read(project, "engine/johto_pilot_runtime.asm")
        warp_tiles = _read(project, "data/warp_tile_ids.asm")
        house = _read(project, "data/johto_indoor_house.asm")
        overworld = _read(project, "home/overworld.asm")
        home = _read(project, "home.asm")
        doors = _read(project, "engine/overworld/doors.asm")
        movement = _read(project, "engine/overworld/npc_movement.asm")
        map_sign = _read(project, "engine/overworld/map_name_sign.asm")
    except (OSError, ValueError) as exc:
        return {"schema": "johto-pilot-migration-audit-v1", "status": "FAIL",
                "errors": [str(exc)], "checks": [], "metrics": {},
                "runtime_verified": False, "rom_built": False, "phone_accepted": False}

    _check(errors, checks, "johto_gate_neutral_map_sign",
           check_johto_gate_name_sign(map_sign),
           "Johto stable ID6 must be neutral, and native city/route names must not use Kanto $FC MapNames")

    # Cross-check every active stable ID against popup and Save/Town Map names.
    sign_report = audit_map_sign(project)
    for item in sign_report["checks"]:
        _check(errors, checks, "johto_map_sign_" + item["check"],
               item["status"] == "PASS", item["detail"])

    active_count = constants.get("NUM_JOHTO_ACTIVE_MAPS")

    # RGBDS ASSERT on table *byte lengths* is independent of literal slot-count
    # ASSERTs.  New slot 13 once had 13 music db rows for 14 active maps and
    # passed all previous map/movement checks, but rgbasm refused main_red.o.
    # Reuse the separately runnable fail-closed preflight (no ROM build).
    table_issues, table_rows, table_expected = inspect_johto_table_asserts(project)
    _check(errors, checks, "active_map_rgbds_table_lengths",
           not table_issues and table_expected == active_count and len(table_rows) >= 3,
           f"NUM_JOHTO_ACTIVE_MAPS={table_expected}, checked={len(table_rows)}, "
           f"tables={[name for _file, name, _got, _expected in table_rows]}, "
           f"issues={table_issues}")
    # FIX-267: physically execute arithmetic offsets for all tileset IDs.
    # Gold asset hashes and RGBDS table lengths alone missed ID32 wraparound.
    # Legacy isolated test fixtures intentionally do not contain the full engine.
    # Require the 16-bit indexing audit whenever the real tileset and palette
    # loader source files are both present; never bypass it in complete builds.
    tileset_sources = (project / 'engine/overworld/tileset_header.asm',
                       project / 'color/loadpalettes.asm')
    if any(p.is_file() for p in tileset_sources):
        index_report = (audit_tileset_index(project) if all(p.is_file() for p in tileset_sources)
                        else {'status': 'FAIL', 'checks': {'missing_loader_source': False}})
        _check(errors, checks, 'johto_tileset_header_and_palette_16bit_index',
               index_report['status'] == 'PASS_STATIC_ONLY' and all(index_report['checks'].values()),
               f"checks={index_report['checks']}")
    rom0_report = inspect_rom0_space(project)
    _check(errors, checks, "rom0_surf_bank_budget_and_abi",
           rom0_report['status'] == 'PASS_STATIC_ONLY',
           f"metrics={rom0_report['metrics']}, issues={rom0_report['issues']}; "
           "old MAP advisory only; requires new rgblink + MAP")
    # UNION-263: independently check cave arrival, collision-only return,
    # and cycling against the old reference and Gold collision roles.
    cave_portal = audit_union_cave_portal(project, Path(gold_root) if gold_root else None)
    for item in cave_portal['checks']:
        _check(errors, checks, 'johto_union_cave_' + item['check'],
               item['status'] == 'PASS', item['detail'])
    if cave_portal['errors'] and not cave_portal['checks']:
        _check(errors, checks, 'johto_union_cave_audit_loaded', False,
               str(cave_portal['errors']))
    music_bike = audit_gate_music_bike(project, Path(gold_root) if gold_root else None)
    for item in music_bike['checks']:
        _check(errors, checks, 'johto_gate_music_bike_' + item['check'],
               item['status'] == 'PASS', item['detail'])

    _check(errors, checks, "active_map_count", active_count == len(EXPECTED_ACTIVE_IDS),
           f"expected {len(EXPECTED_ACTIVE_IDS)} active slots {EXPECTED_ACTIVE_IDS}, got {active_count}")

    # Source-level preflight for literal RGBDS ASSERT expressions.  These are
    # evaluated by rgbasm even when every map/warp asset is otherwise correct.
    # In P6-GATE-001, the 8-slot constant was correct but a stale == 6 in
    # johto_stable_id_slots.asm aborted main_red.o before the linker ran.
    # This check deliberately scans *ASM* files, not generated archives or
    # historical patches; it never invokes the assembler or modifies source.
    count_asserts = []
    for rel_dir in ("constants", "data", "engine", "home"):
        for asm_path in sorted((project / rel_dir).rglob("*.asm")):
            for lineno, line in enumerate(asm_path.read_text(encoding="utf-8").splitlines(), 1):
                code = line.split(";", 1)[0]
                match = re.match(r"^\s*ASSERT\s+NUM_JOHTO_ACTIVE_MAPS\s*==\s*(\$[0-9A-Fa-f]+|\d+)\s*$", code, re.I)
                if match:
                    token = match.group(1)
                    value = int(token[1:], 16) if token.startswith("$") else int(token)
                    count_asserts.append((str(asm_path.relative_to(project)), lineno, value))
    # The stable-slot router assertion is a mandatory contract; merely
    # deleting it must not allow the audit to return PASS.
    slot_file_asserts = [row for row in count_asserts if row[0] == "data/johto_stable_id_slots.asm"]
    _check(errors, checks, "rgbds_literal_active_count_asserts",
           len(slot_file_asserts) == 1 and len(count_asserts) >= 2 and
           active_count is not None and all(value == active_count for _, _, value in count_asserts),
           f"NUM_JOHTO_ACTIVE_MAPS={active_count}; literal ASM ASSERTs={count_asserts}; "
           "stable-slot-router equality must be present")
    # A new active slot must be reflected in *all* Town Map tables, not only
    # headers, music, and runtime profiles. This was missed for Route32 in 245
    # and rgbasm later failed both length ASSERTs before linking a ROM.
    try:
        fly = _read(project, "engine/fly_town_map_helpers.asm")
        browse = _read(project, "engine/johto_pilot_town_map_browse.asm")
        map_names = _read(project, "text/map_names.asm")

        def parse_map_pairs(source: str, first: str, last: str) -> list[tuple[int, int, str]]:
            body = _section(source, first, last)
            lines = [line.split(";", 1)[0].strip() for line in body.splitlines()]
            lines = [line for line in lines if line]
            if len(lines) % 2:
                raise ValueError(f"{first}: uneven db/dw table rows")
            rows = []
            for position in range(0, len(lines), 2):
                xy = re.fullmatch(r"db\s+(\d+)\s*,\s*(\d+)", lines[position])
                name = re.fullmatch(r"dw\s+([A-Za-z_][A-Za-z_0-9]*)", lines[position + 1])
                if not xy or not name:
                    raise ValueError(f"{first}: bad map entry near row {position // 2}: {lines[position:position+2]}")
                rows.append((int(xy.group(1)), int(xy.group(2)), name.group(1)))
            return rows

        displayed = parse_map_pairs(fly, "JohtoPilotTownMapEntries", "JohtoPilotTownMapEntriesEnd")
        landmarks = parse_map_pairs(browse, "JohtoBrowseEntries", "JohtoBrowseEntriesEnd")
        browse_index_body = _section(fly, "JohtoPilotTownMapBrowseIndexBySlot", "JohtoPilotTownMapBrowseIndexBySlotEnd")
        browse_indices = []
        for line in browse_index_body.splitlines():
            code = line.split(";", 1)[0].strip()
            if not code:
                continue
            if not code.startswith("db "):
                raise ValueError(f"browse index: non-db row: {code}")
            browse_indices.extend(int(token.strip(), 0) for token in code[3:].split(","))

        profiles = _section(runtime, "JohtoPilotMapProfiles", "JohtoPilotMapProfilesEnd")
        profile_indices = []
        for line in profiles.splitlines():
            code = line.split(";", 1)[0].strip()
            if not code:
                continue
            match = re.fullmatch(r"johto_map_profile\s+[01]\s*,\s*(\d+)\s*,\s*[^,]+\s*,\s*[^,]+", code)
            if not match:
                raise ValueError(f"unexpected johto_map_profile row: {code}")
            profile_indices.append(int(match.group(1)))

        # Copy of all names used by the two tables, including expansion-bank
        # labels. Compare the actual name bytes and coordinates, not only count.
        defined_names = {}
        for source in (map_names, fly, browse):
            for label, value in re.findall(
                r'(?m)^([A-Za-z_][A-Za-z_0-9]*)::?\s*\n?\s*db\s+"([^"]*)"', source
            ):
                defined_names[label] = value
        good = (active_count is not None and len(displayed) == active_count and
                len(browse_indices) == active_count and len(profile_indices) == active_count and
                len(landmarks) == constants.get("JOHTO_TOWNMAP_LANDMARK_COUNT", 45))
        for slot, (coord_y, coord_x, name) in enumerate(displayed):
            if slot >= len(profile_indices) or slot >= len(browse_indices):
                good = False
                continue
            landmark = browse_indices[slot]
            if not (0 <= landmark < len(landmarks)) or landmark != profile_indices[slot]:
                good = False
                continue
            expected_y, expected_x, expected_name = landmarks[landmark]
            if (coord_y, coord_x) != (expected_y, expected_x) or not (
                name in defined_names and expected_name in defined_names and
                defined_names[name] == defined_names[expected_name]
            ):
                good = False
        _check(errors, checks, "active_slot_town_map_tables", good,
               f"active={active_count}, town entries={len(displayed)}, browse indices={len(browse_indices)}, "
               f"profiles={len(profile_indices)}, landmarks={len(landmarks)}; "
               "each slot must have matching Gold landmark, coordinates, and name")
    except (ValueError, OSError) as exc:
        _check(errors, checks, "active_slot_town_map_tables", False, str(exc))

    header_body = _section(headers, "JohtoHeaderDescriptors", "JohtoHeaderDescriptorsEnd")
    header_rows = re.findall(r"(?m)^\s*dw\s+(\w+RuntimeHeader)\s*$", header_body)
    header_banks = re.findall(r"(?m)^\s*db\s+BANK\((\w+RuntimeHeader)\)\s*$", header_body)
    _check(errors, checks, "header_descriptor_cardinality",
           len(header_rows) == len(EXPECTED_ACTIVE_IDS) and len(header_banks) == len(EXPECTED_ACTIVE_IDS) and header_rows == header_banks,
           f"header pointers={len(header_rows)}, bank rows={len(header_banks)}, paired={header_rows == header_banks}")

    id_symbols = {name: value for name, value in constants.items() if name.startswith("JOHTO_") and name.endswith("_LOCAL_ID")}
    expected_id_symbols = ["JOHTO_NEW_BARK_LOCAL_ID", "JOHTO_ROUTE_29_LOCAL_ID",
                           "JOHTO_CHERRYGROVE_LOCAL_ID", "JOHTO_ROUTE_30_LOCAL_ID",
                           "JOHTO_ROUTE_31_LOCAL_ID", "JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID",
                           "JOHTO_VIOLET_CITY_LOCAL_ID", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID", "JOHTO_ROUTE_32_LOCAL_ID",
                           "JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID", "JOHTO_RUINS_OF_ALPH_LOCAL_ID",
                           "JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID", "JOHTO_ROUTE_36_LOCAL_ID",
                           "JOHTO_UNION_CAVE_1F_LOCAL_ID", "JOHTO_ROUTE_33_LOCAL_ID"]
    descriptor_body = _section(runtime_assets, "JohtoPilotRuntimeResourceDescriptors", "JohtoPilotRuntimeResourceDescriptorsEnd")
    descriptor_ids = []
    for symbol in re.findall(r"(?m)^\s*db\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s*,", descriptor_body):
        if symbol not in id_symbols:
            errors.append(f"runtime descriptor uses unknown ID symbol: {symbol}")
        else:
            descriptor_ids.append((symbol, id_symbols[symbol]))
    _check(errors, checks, "runtime_descriptor_ids",
           [symbol for symbol, _ in descriptor_ids] == expected_id_symbols and
           [value for _, value in descriptor_ids] == EXPECTED_ACTIVE_IDS,
           f"runtime descriptor stable IDs={descriptor_ids}")

    source_body = _section(source_resources, "JohtoPilotSourceRecords", "JohtoPilotSourceRecordsEnd")
    source_ids = re.findall(r"(?m)^\s*db\s+MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s*,", source_body)
    _check(errors, checks, "source_descriptor_ids",
           source_ids == expected_id_symbols,
           f"source descriptor IDs={source_ids}")

    # Check stable ID -> compact slot table, including sparse ID 125.
    slots = _read(project, "data/johto_stable_id_slots.asm")
    slot_body = _section(slots, "JohtoStableIDToActiveSlot", "JohtoStableIDToActiveSlotEnd")
    slot_values = []
    for raw in slot_body.splitlines():
        code = raw.split(";", 1)[0].strip()
        if not code:
            continue
        if not code.startswith("db "):
            errors.append(f"stable slot table contains non-data line: {code}")
            continue
        for value in code[3:].split(","):
            token = value.strip()
            if token == "JOHTO_INVALID_ACTIVE_SLOT":
                slot_values.append(255)
            elif token in id_symbols:
                slot_values.append(id_symbols[token])
            elif token.isdecimal():
                slot_values.append(int(token))
            else:
                errors.append(f"stable slot table contains unrecognized byte: {token}")
    expected_slots = [255] * 256
    expected_slots[0:5] = [0, 1, 2, 3, 4]
    expected_slots[125] = 5
    expected_slots[5:8] = [6, 7, 8]
    expected_slots[102] = 9
    expected_slots[20] = 10
    expected_slots[19] = 11
    expected_slots[16] = 12
    expected_slots[8] = 13
    expected_slots[9] = 14
    _check(errors, checks, "stable_id_sparse_router",
           len(slot_values) == 256 and slot_values == expected_slots,
           f"stable ID table bytes={len(slot_values)}; active mapping={{0:0,1:1,2:2,3:3,4:4,125:5,5:6,6:7,7:8,102:9,20:10,19:11,16:12,8:13,9:14}}; all others must be inactive")

    # Source adjacency table is 5 bytes per row and must be reciprocal.
    try:
        connection_rows = _parse_connection_rows(source_resources, "JohtoPilotSourceConnections", "JohtoPilotSourceConnectionsEnd", id_symbols)
        _check(errors, checks, "source_connection_topology", connection_rows == EXPECTED_CONNECTIONS,
               f"expected {len(EXPECTED_CONNECTIONS)} reciprocal edges; found {len(connection_rows)}")
        _check(errors, checks, "source_connection_cardinality_assert",
               "JOHTO_PILOT_SOURCE_CONNECTION_COUNT * JOHTO_PILOT_CONNECTION_BYTES" in source_resources and
               "JOHTO_PILOT_CONNECTION_BYTES EQU 5" in source_resources,
               "source connection table must assert 5-byte records")
    except ValueError as exc:
        connection_rows = set()
        errors.append(f"source_connection_topology: {exc}")
        checks.append({"check": "source_connection_topology", "status": "FAIL", "detail": str(exc)})

    # Check the runtime header fields for the narrow Route30/31 seam and the
    # two-lane Cherrygrove/Route30 opening. Exact assertions catch the historical
    # missing first byte / 33-byte Header regression before the user builds ROM.
    try:
        route30 = _section(map_headers, "JohtoPilotRoute30RuntimeHeader", "JohtoPilotRoute30RuntimeHeaderEnd")
        route31 = _section(map_headers, "JohtoPilotRoute31RuntimeHeader", "JohtoPilotRoute31RuntimeHeaderEnd")
        cherry = _section(map_headers, "JohtoPilotCherrygroveRuntimeHeader", "JohtoPilotCherrygroveRuntimeHeaderEnd")
        _check(errors, checks, "route30_connection_header",
               "db NORTH | SOUTH" in route30 and route30.count("db JOHTO_RUNTIME_MAP_HANDLE") == 2 and
               "db JOHTO_ROUTE_30_WIDTH ; exactly ten columns" in route30 and
               "db JOHTO_ROUTE_31_WIDTH ; source row stride = twenty blocks" in route30 and
               "db 20 ; Route30 X -> Route31 X + 20 tiles" in route30 and
               "db 10 ; Route30 x=3 -> Cherrygrove x=8" in route30 and
               "ASSERT JohtoPilotRoute30RuntimeHeaderEnd - JohtoPilotRoute30RuntimeHeader == 34" in map_headers,
               "Route30 needs two 11-byte records, 10-column overlap, offsets +20/+10 tiles and 34-byte ASSERT")
        _check(errors, checks, "route31_connection_header",
               "db SOUTH | WEST" in route31 and route31.count("db JOHTO_RUNTIME_MAP_HANDLE") == 2 and
               "db JOHTO_ROUTE_30_WIDTH ; exactly ten columns for the overlapping strip" in route31 and
               "db -20 ; Route31 X -> Route30 X - 20 tiles" in route31 and
               "dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * 9 + JOHTO_VIOLET_CITY_WIDTH - 3" in route31 and
               "db JOHTO_ROUTE_31_HEIGHT" in route31 and
               "db 18" in route31 and
               "ASSERT JohtoPilotRoute31RuntimeHeaderEnd - JohtoPilotRoute31RuntimeHeader == 34" in map_headers,
               "Route31 SOUTH + WEST preview must both be present, with +18-tile Gold Y offset and 34-byte ASSERT")
        new_bark = _section(map_headers, "JohtoPilotNewBarkRuntimeHeader", "JohtoPilotNewBarkRuntimeHeaderEnd")
        route29 = _section(map_headers, "JohtoPilotRoute29RuntimeHeader", "JohtoPilotRoute29RuntimeHeaderEnd")
        _check(errors, checks, "new_bark_route29_header",
               "db WEST" in new_bark and "db JOHTO_RUNTIME_MAP_HANDLE" in new_bark and
               "dw JohtoPilotRoute29RuntimeBlocks" in new_bark and
               "ASSERT JohtoPilotNewBarkRuntimeHeaderEnd - JohtoPilotNewBarkRuntimeHeader == 23" in map_headers,
               "New Bark WEST must target Route29 through one 11-byte record")
        _check(errors, checks, "route29_bidirectional_header",
               "db WEST | EAST" in route29 and route29.count("db JOHTO_RUNTIME_MAP_HANDLE") == 2 and
               "dw JohtoPilotCherrygroveRuntimeBlocks" in route29 and
               "dw JohtoPilotNewBarkRuntimeBlocks" in route29 and
               "ASSERT JohtoPilotRoute29RuntimeHeaderEnd - JohtoPilotRoute29RuntimeHeader == 34" in map_headers,
               "Route29 WEST/EAST must preserve both reciprocal connections and 34-byte header")
        _check(errors, checks, "cherrygrove_route30_header",
               "db NORTH | EAST" in cherry and cherry.count("db JOHTO_RUNTIME_MAP_HANDLE") == 2 and
               "dw JohtoPilotRoute30RuntimeBlocks" in cherry and
               "dw JohtoPilotRoute29RuntimeBlocks" in cherry and "db -10" in cherry and
               "ASSERT JohtoPilotCherrygroveRuntimeHeaderEnd - JohtoPilotCherrygroveRuntimeHeader == 34" in map_headers,
               "Cherrygrove NORTH must target Route30; EAST must still target Route29")
    except ValueError as exc:
        errors.append(f"runtime_connection_headers: {exc}")
        checks.append({"check": "runtime_connection_headers", "status": "FAIL", "detail": str(exc)})

    # Source/runtime layouts are fixed-size. Runtime maps may have reviewed
    # block-ID substitutions, so only dimensions are asserted here.
    layout_metrics = {}
    for name, (width, height) in MAP_LAYOUTS.items():
        variants = ("reference", "runtime") if name == "GuideGentsHouse" else ("gold", "runtime")
        for variant in variants:
            path = project / f"maps/johto_pilot/{name}.{variant}.blk"
            expected_bytes = width * height
            actual_bytes = path.stat().st_size if path.is_file() else -1
            ok = actual_bytes == expected_bytes
            _check(errors, checks, f"layout_size_{name}_{variant}", ok,
                   f"{path.relative_to(project)} has {actual_bytes} bytes; expected {expected_bytes} ({width}x{height})")
            layout_metrics[f"{name}.{variant}"] = {"bytes": actual_bytes, "expected": expected_bytes}

    # Registered Warp table must be fail-closed and exactly bidirectional for
    # the only currently enabled house. It must not silently open other houses.
    try:
        warp_rows = _parse_runtime_warp_rows(runtime)
        expected_warps = [
            ("MAP_REGION_JOHTO", "JOHTO_CHERRYGROVE_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_CHERRYGROVE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID", "1", "MAP_REGION_JOHTO", "JOHTO_CHERRYGROVE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE_31_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE_31_LOCAL_ID", "1", "MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_VIOLET_CITY_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_VIOLET_CITY_LOCAL_ID", "1", "MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_VIOLET_CITY_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID", "1", "MAP_REGION_JOHTO", "JOHTO_VIOLET_CITY_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID", "2", "MAP_REGION_JOHTO", "JOHTO_ROUTE_31_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID", "3", "MAP_REGION_JOHTO", "JOHTO_ROUTE_31_LOCAL_ID"),
        ]
        # Only reviewed southern Gold corridor pairs are enabled. Ruins north
        # gate, cave, puzzle rooms and Route36 remain fail-closed.
        for source, ordinal, target in (
            ("JOHTO_ROUTE_32_LOCAL_ID", 0, "JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID"),
            ("JOHTO_ROUTE_32_LOCAL_ID", 1, "JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID"),
            ("JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID", 0, "JOHTO_RUINS_OF_ALPH_LOCAL_ID"),
            ("JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID", 1, "JOHTO_RUINS_OF_ALPH_LOCAL_ID"),
            ("JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID", 2, "JOHTO_ROUTE_32_LOCAL_ID"),
            ("JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID", 3, "JOHTO_ROUTE_32_LOCAL_ID"),
            ("JOHTO_RUINS_OF_ALPH_LOCAL_ID", 0, "JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID"),
            ("JOHTO_RUINS_OF_ALPH_LOCAL_ID", 1, "JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID"),
        ):
            expected_warps.append(("MAP_REGION_JOHTO", source, str(ordinal), "MAP_REGION_JOHTO", target))
        # Northern Gold corridor (the original southern ordinals are unchanged).
        for source, ordinal, target in (
            ("JOHTO_RUINS_OF_ALPH_LOCAL_ID", 2, "JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID"),
            ("JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID", 0, "JOHTO_ROUTE_36_LOCAL_ID"),
            ("JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID", 1, "JOHTO_ROUTE_36_LOCAL_ID"),
            ("JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID", 2, "JOHTO_RUINS_OF_ALPH_LOCAL_ID"),
            ("JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID", 3, "JOHTO_RUINS_OF_ALPH_LOCAL_ID"),
            ("JOHTO_ROUTE_36_LOCAL_ID", 0, "JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID"),
            ("JOHTO_ROUTE_36_LOCAL_ID", 1, "JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID"),
        ):
            expected_warps.append(("MAP_REGION_JOHTO", source, str(ordinal), "MAP_REGION_JOHTO", target))
        # Union Cave 1F north/south activated, but B1F/B2F stay sealed.
        expected_warps.extend((
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE_32_LOCAL_ID", "2", "MAP_REGION_JOHTO", "JOHTO_UNION_CAVE_1F_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_UNION_CAVE_1F_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_ROUTE_32_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_UNION_CAVE_1F_LOCAL_ID", "1", "MAP_REGION_JOHTO", "JOHTO_ROUTE_33_LOCAL_ID"),
            ("MAP_REGION_JOHTO", "JOHTO_ROUTE_33_LOCAL_ID", "0", "MAP_REGION_JOHTO", "JOHTO_UNION_CAVE_1F_LOCAL_ID"),
        ))
        _check(errors, checks, "registered_warp_routes", warp_rows == expected_warps,
               f"expected Guide Gents + existing directional gate entries/exits; found {warp_rows}")
    except ValueError as exc:
        errors.append(f"registered_warp_routes: {exc}")
        checks.append({"check": "registered_warp_routes", "status": "FAIL", "detail": str(exc)})

    city_objects = _section(map_headers, "JohtoPilotCherrygroveRuntimeObjects", "JohtoPilotRoute30TextPointers")
    house_objects = _section(house, "JohtoGuideGentsHouseRuntimeObjects", "JohtoGuideGentsHouseRuntimeObjectsEnd") if "JohtoGuideGentsHouseRuntimeObjectsEnd::" in house else house.split("JohtoGuideGentsHouseRuntimeObjects::", 1)[1]
    _check(errors, checks, "door_object_coordinates",
           re.search(r"(?m)^\s*db\s+9\s*,\s*25\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR", city_objects) is not None and
           len(re.findall(r"(?m)^\s*db\s+7\s*,\s*[23]\s*,\s*0\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR", house_objects)) == 2,
           "one outdoor entry at (Y9,X25), two indoor exits at (Y7,X2/3)")

    outdoor_warp_tiles = _section(warp_tiles, "JohtoPilotWarpTileIDs", "JohtoHouseWarpTileIDs")
    indoor_warp_tiles = _section(warp_tiles, "JohtoHouseWarpTileIDs", "JohtoGateWarpTileIDs") if "JohtoGateWarpTileIDs:" in warp_tiles else warp_tiles.split("JohtoHouseWarpTileIDs:", 1)[1]
    indoor_db_rows = []
    for raw in indoor_warp_tiles.splitlines():
        code = raw.split(";", 1)[0].strip()
        if code.startswith("db "):
            indoor_db_rows.append([part.strip().upper() for part in code[3:].split(",")])
    _check(errors, checks, "door_tile_trigger_classes",
           re.search(r"(?m)^\s*db\s+\$06\s*,\s*\$39\s*,\s*\$FF\s*$", outdoor_warp_tiles) is not None and
           indoor_db_rows == [["$FF"]],
           f"outdoor $06/$39 are step-on candidates; indoor DOWN carpet $12 must not be in step-on Warp list (indoor rows={indoor_db_rows})")

    # First east/west gate: each face has two lanes; four direction-only
    # registered carpets, not a generic STEP_ON warp or an outdoor seam.
    gate_source = _read(project, "data/johto_gate_runtime.asm")
    gate_obj = gate_source.split("JohtoPilotVioletGateRuntimeObjects::", 1)[1]
    city_obj = map_headers.split("JohtoPilotVioletRuntimeObjects::", 1)[1]
    route31_obj = map_headers.split("JohtoPilotRoute31RuntimeObjects::", 1)[1].split("JohtoPilotVioletRuntimeHeader::", 1)[0]
    required_gate_rows = ["db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR",
                          "db 5, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR",
                          "db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR",
                          "db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR"]
    _check(errors, checks, "route31_violet_gate_lanes",
           all(row in gate_obj for row in required_gate_rows) and
           "db 6, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR" in route31_obj and
           "db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR" in route31_obj and
           "db 24, 39, 0, JOHTO_REGISTERED_WARP_SELECTOR" in city_obj and
           "db 25, 39, 1, JOHTO_REGISTERED_WARP_SELECTOR" in city_obj,
           "Route31 6/7,4 <-> gate 4/5,9 and Violet 24/25,39 <-> gate 4/5,0")
    _check(errors, checks, "route31_violet_gate_direction",
           "JohtoPilotGateDoorApproachAllowed" in overworld and
           "JohtoPilotGateDoorWarpMatched" in overworld and
           "cp JOHTO_GATE" in overworld and
           "JohtoPilotGateDoorApproachAllowed::" in runtime and
           "JohtoPilotGateDoorWarpMatched::" in runtime and
           "cp PLAYER_DIR_LEFT" in runtime and "cp PLAYER_DIR_RIGHT" in runtime and
           ".gateLeft" in runtime and ".violetEast" in runtime and
           "db $FF" in warp_tiles.split("JohtoGateWarpTileIDs:", 1)[1],
           "exterior directional matched warp, gate edge collision, no STEP_ON carpet")

    _check(errors, checks, "rom0_collision_tables",
           "JohtoPilot_Coll:: INCBIN \"gfx/tilesets/johto.tilecoll\"" in home and
           "JohtoHouse_Coll:: INCBIN \"gfx/tilesets/johto_house.tilecoll\"" in home and
           "ASSERT BANK(JohtoPilot_Coll) == 0" in runtime_assets and
           "ASSERT BANK(JohtoHouse_Coll) == 0" in _read(project, "data/johto_indoor_house.asm"),
           "both live collision lists must remain in ROM0 for unbanked collision readers")
    try:
        outdoor_coll = (project / "gfx/tilesets/johto.tilecoll").read_bytes()
        indoor_coll = (project / "gfx/tilesets/johto_house.tilecoll").read_bytes()
        _check(errors, checks, "collision_list_contents",
               len(outdoor_coll) == 8 and outdoor_coll[-1] == 0xFF and 0x37 in outdoor_coll[:-1] and
               len(indoor_coll) == 4 and indoor_coll[-1] == 0xFF,
               f"outdoor collision list={outdoor_coll.hex()}; indoor list={indoor_coll.hex()}")
    except OSError as exc:
        errors.append(f"collision_list_contents: {exc}")

    # Runtime entrance control flow and departure auto-step are separately
    # checked; neither is inferred from coordinates or graphics alone.
    try:
        collision_entry = overworld.split("CollisionCheckOnLand::", 1)[1].split("\n.collision\n", 1)[0]
        _check(errors, checks, "door_approach_collision_guard",
               all(token in collision_entry for token in (
                   "cp JOHTO_RUNTIME_MAP_HANDLE", "cp MAP_REGION_JOHTO",
                   "cp JOHTO_CHERRYGROVE_LOCAL_ID", "cp PLAYER_DIR_UP",
                   "cp 25", "cp 10", "jp z,.noCollision")),
               "only Johto Cherrygrove (Y10,X25) UP approach bypasses generic collision")
        warp_loop = overworld.split("CheckWarpsNoCollisionLoop::", 1)[1].split("CheckWarpsCollision::", 1)[0]
        _check(errors, checks, "door_step_on_warp_guard",
               all(token in warp_loop for token in (
                   "cp JOHTO_RUNTIME_MAP_HANDLE", "cp MAP_REGION_JOHTO",
                   "cp JOHTO_CHERRYGROVE_LOCAL_ID", "cp PLAYER_DIR_UP",
                   "cp 9", "cp 25", "jp WarpFound1", "callba IsPlayerStandingOnDoorTileOrWarpTile")),
               "matched registered Cherrygrove door enters on one UP step; other warps use common path")
        _check(errors, checks, "indoor_carpet_direction_guard",
               "cp JOHTO_HOUSE" in warp_loop and "jr z,CheckWarpsNoCollisionRetry2" in warp_loop and
               "CheckWarpsCollision::" in overworld,
               "indoor carpets are not STEP_ON warps; DOWN collision uses collision-Warp path")
        enter_map = overworld.split("EnterMap::", 1)[1].split("OverworldLoop::", 1)[0]
        _check(errors, checks, "indoor_arrival_warp_rearm",
               all(token in enter_map for token in ("cp JOHTO_HOUSE", "res 2,[hl]", "callba IsPlayerStandingOnWarp")),
               "entering/saving on the indoor carpet re-arms its standing-Warp state")
        warp_found = overworld.split("WarpFound2::", 1)[1].split("ContinueCheckWarpsNoCollisionLoop::", 1)[0]
        _check(errors, checks, "departure_requests_door_step",
               "set 0,[hl]" in warp_found and "jp EnterMap" in warp_found,
               "WarpFound2 sets the original engine's step-out flag before entering target map")
        movement_body = home.split("RunNPCMovementScript::", 1)[1].split("EndNPCMovementScript::", 1)[0]
        stepout_body = movement.split("PlayerStepOutFromDoor:", 1)[1].split("_EndNPCMovementScript:", 1)[0]
        _check(errors, checks, "departure_auto_step_down",
               "bit 0, [hl]" in movement_body and "jpba PlayerStepOutFromDoor" in movement_body and
               "call IsPlayerStandingOnDoorTile" in stepout_body and "ld a, D_DOWN" in stepout_body and
               "call StartSimulatingJoypadStates" in stepout_body,
               "outdoor door tile $39 reuses RPP PlayerStepOutFromDoor to simulate DOWN once")
        # P6-GATE-004: Independent Gold/old-RPP gate contract, not the
        # incorrect GATE-003 forced-step "static green" assertions.
        gate_arrival = runtime.split("JohtoPilotGateArrivalStep::", 1)[1].split(
            "JohtoPilotGateDoorApproachAllowed::", 1)[0] if "JohtoPilotGateArrivalStep::" in runtime else ""
        gate_exit = runtime.split("JohtoPilotGateExteriorCollisionAllowed::", 1)[1].split(
            "JohtoPilotGateCollisionExitAllowed::", 1)[0] if "JohtoPilotGateExteriorCollisionAllowed::" in runtime else ""
        extra = overworld.split("ExtraWarpCheck::", 1)[1].split("MapEntryAfterBattle::", 1)[0]
        _check(errors, checks, "gate_arrival_none_on_direction_carpet",
               ("callab JohtoPilotGateArrivalStep" in stepout_body and
                stepout_body.index("callab JohtoPilotGateArrivalStep") < stepout_body.index("call IsPlayerStandingOnDoorTile") and
                "cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID" in gate_arrival and
                "cp JOHTO_RUINS_OF_ALPH_LOCAL_ID" in gate_arrival and
                "ld e, 0" in gate_arrival and "ld e, D_DOWN" in gate_arrival and
                ".gateTop" in gate_arrival and "cp 5" in gate_arrival and
                "cp JOHTO_GATE\n\tjr z,.armJohtoCarpetArrival" in enter_map and
                "cp JOHTO_UNION_CAVE\n\tjr nz,.noJohtoCarpetArrival" in enter_map and
                "callba IsPlayerStandingOnWarp" in enter_map),
               "North-side Gold DOOR arrives with one DOWN step; all directional carpets stay in place")
        _check(errors, checks, "gate_exterior_collision_only",
               ("jp CheckWarpsNoCollisionRetry2\n.northGoldStepOnDoor" in warp_loop and
                "callab JohtoPilotGateExteriorCollisionAllowed" in extra and
                "scf\n    ret" in extra and
                ".route31" in gate_exit and "cp 4" in gate_exit and
                "cp 6" in gate_exit and "cp 7" in gate_exit and
                "cp 39" in gate_exit and "cp 24" in gate_exit and
                "cp 25" in gate_exit and "cp PLAYER_DIR_LEFT" in gate_exit and
                "cp PLAYER_DIR_RIGHT" in gate_exit),
               "outside paired Gold carpets must arm on step-on, then warp only on exact outward collision")
        _check(errors, checks, "gate_border_preview_pair",
               ("dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * 9 + JOHTO_VIOLET_CITY_WIDTH - 3" in route31 and
                "db SOUTH | EAST" in _section(map_headers, "JohtoPilotVioletRuntimeHeader", "JohtoPilotVioletRuntimeHeaderEnd") and
                "dw JohtoPilotRoute31RuntimeBlocks" in _section(map_headers, "JohtoPilotVioletRuntimeHeader", "JohtoPilotVioletRuntimeHeaderEnd") and
                "db -18" in _section(map_headers, "JohtoPilotVioletRuntimeHeader", "JohtoPilotVioletRuntimeHeaderEnd") and
                "ASSERT JohtoPilotVioletRuntimeHeaderEnd - JohtoPilotVioletRuntimeHeader == 34" in map_headers),
               "Violet/Route31 shared-border preview must use Gold +/-9-block alignment without opening a free seam")
        # Validate tilepal and independent Gold RGB, not just PNG/BLK bytes.
        palette_assign = _read(project, "color/data/map_palette_assignments.asm")
        palette_sets = _read(project, "color/data/map_palette_sets.asm")
        palette_consts = _read(project, "color/data/map_palette_constants.asm")
        palettes = _read(project, "color/data/map_palettes.asm")
        gate_tilepal = _read(project, "color/tilesets/johto_gate.asm")
        _check(errors, checks, "gate_palette_and_gold_colors",
               ("INCLUDE \"color/tilesets/johto_gate.asm\"" in palette_assign and
                "(JOHTO_MODERN + 1) * $60" in palette_assign and
                "INCLUDE \"color/tilesets/johto_union_cave.asm\"" in palette_assign and
                "JOHTO_GATE_GOLD_GREEN" in palette_sets and
                "JOHTO_GATE_GOLD_BROWN" in palette_sets and
                "(JOHTO_MODERN + 1) * 8" in palette_sets and
                "const JOHTO_GATE_GOLD_GREEN ; 28" in palette_consts and
                "const JOHTO_GATE_GOLD_BROWN ; 29" in palette_consts and
                "RGB 18,24,9" in palettes and "RGB 15,20,1" in palettes and
                "RGB 26,24,17" in palettes and "RGB 21,17,7" in palettes and
                len(re.findall(r"(?m)^\s*tilepal\s", gate_tilepal)) == 12),
               "dedicated old-RPP 96-tile gate palette assignment and Gold RGB constants must be loaded")
        door_tile_body = _section(doors, "DoorTileIDPointers", "OverworldDoorTileIDs")
        door_tile_list = doors.split("JohtoPilotDoorTileIDs:", 1)[1] if "JohtoPilotDoorTileIDs:" in doors else ""
        _check(errors, checks, "outdoor_door_tile_registration",
               "dbw JOHTO_PILOT,  JohtoPilotDoorTileIDs" in door_tile_body and
               re.search(r"(?m)^\s*db\s+\$39\s*,\s*\$00\s*$", door_tile_list) is not None,
               "the returned outdoor lower-left door tile $39 is recognized by the existing Kanto/RPP door step-out path")
    except (IndexError, ValueError) as exc:
        errors.append(f"door_control_flow: {exc}")
        checks.append({"check": "door_control_flow", "status": "FAIL", "detail": str(exc)})

    reference_result = {"status": "NOT_RUN", "errors": []}
    if reference_root is not None:
        reference_root = Path(reference_root).resolve()
        try:
            current_ref = (project / "maps/johto_pilot/GuideGentsHouse.reference.blk").read_bytes()
            prior_ref_path = reference_root / "maps/JohtoGuideGentsHouse.blk"
            prior_ref = prior_ref_path.read_bytes()
            identical = current_ref == prior_ref
            _check(errors, checks, "rpp_reference_house_layout", identical,
                   f"current GuideGentsHouse.reference.blk vs NPC reference maps/JohtoGuideGentsHouse.blk: exact_match={identical}")
            reference_result = {"status": "PASS" if identical else "FAIL",
                                "path": str(prior_ref_path), "bytes": len(prior_ref), "byte_identical": identical}
        except OSError as exc:
            _check(errors, checks, "rpp_reference_house_layout", False, str(exc))
            reference_result = {"status": "FAIL", "errors": [str(exc)]}
    metrics["layout_sizes"] = layout_metrics
    metrics["source_connection_count"] = len(connection_rows)
    metrics["registered_warp_count"] = len(warp_rows) if "warp_rows" in locals() else 0
    gold_result = None
    if gold_root is not None:
        gold_result = _audit_gold_source(project, Path(gold_root).resolve(), errors, checks)
    status = "PASS_STATIC_ONLY" if not errors else "FAIL"
    return {
        "schema": "johto-pilot-migration-audit-v1",
        "project": str(project),
        "gold_root": str(Path(gold_root).resolve()) if gold_root else None,
        "status": status,
        "errors": errors,
        "checks": checks,
        "metrics": metrics,
        "gold_reference": gold_result,
        "rpp_reference": reference_result,
        "runtime_verified": False,
        "rom_built": False,
        "phone_accepted": False,
        "warning": "Static source checks only. This report never means ROM build, MAP space validation, or phone/gameplay acceptance passed.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--gold-root", type=Path, default=None,
                        help="optional user-provided pret/MUS Gold source tree")
    parser.add_argument("--gold-profile", choices=PROFILES, default="auto")
    parser.add_argument("--reference-root", type=Path, default=None,
                        help="optional NPC-5.62.243 RPP reference source tree")
    parser.add_argument("--json-out", type=Path, default=None)
    args = parser.parse_args()
    report = audit_project(args.project, args.gold_root, args.reference_root, args.gold_profile)
    payload = json.dumps(report, ensure_ascii=False, indent=2)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(payload + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "errors": report["errors"],
                      "check_count": len(report["checks"]),
                      "passed": sum(x["status"] == "PASS" for x in report["checks"]),
                      "failed": sum(x["status"] == "FAIL" for x in report["checks"]),
                      "gold_reference": report["gold_reference"] and report["gold_reference"]["status"]},
                     ensure_ascii=False, indent=2))
    return 0 if report["status"] == "PASS_STATIC_ONLY" else 1


if __name__ == "__main__":
    raise SystemExit(main())
