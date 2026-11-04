#!/usr/bin/env python3
"""MAP-299 fail-closed static gate for Route40 -> Route41 -> Cianwood outdoors.

Validates the current RPP runtime against original Gold source and the mature
NPC-5.62.243 reference.  It checks map bytes, mature collision/water masks,
role grids, active IDs, reciprocal connections, connection headers, Surf seam
routing, names/Fly/music/roof registration, and keeps deferred cave/indoor
Warps closed.  Static only: it does not assemble/link a ROM or claim device play.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

try:
    from johto_gold_door_audit import GoldCollisionIndex
except ImportError:
    from tools.johto_gold_door_audit import GoldCollisionIndex

MAPS = (
    ("Route40", "JOHTO_ROUTE_40_LOCAL_ID", "JOHTO_ROUTE_40", 27, 10, 18, 466, "JohtoRoute40"),
    ("Route41", "JOHTO_ROUTE_41_LOCAL_ID", "JOHTO_ROUTE_41", 28, 25, 27, 1699, "JohtoRoute41"),
    ("CianwoodCity", "JOHTO_CIANWOOD_CITY_LOCAL_ID", "JOHTO_CIANWOOD_CITY", 29, 15, 27, 519, "JohtoCianwoodCity"),
)
NEW_CONNECTIONS = (
    ("JOHTO_OLIVINE_CITY_LOCAL_ID", "WEST", "JOHTO_ROUTE_40_LOCAL_ID"),
    ("JOHTO_ROUTE_40_LOCAL_ID", "EAST", "JOHTO_OLIVINE_CITY_LOCAL_ID"),
    ("JOHTO_ROUTE_40_LOCAL_ID", "SOUTH", "JOHTO_ROUTE_41_LOCAL_ID"),
    ("JOHTO_ROUTE_41_LOCAL_ID", "NORTH", "JOHTO_ROUTE_40_LOCAL_ID"),
    ("JOHTO_ROUTE_41_LOCAL_ID", "WEST", "JOHTO_CIANWOOD_CITY_LOCAL_ID"),
    ("JOHTO_CIANWOOD_CITY_LOCAL_ID", "EAST", "JOHTO_ROUTE_41_LOCAL_ID"),
)


def _mask_roles(blocked: bytes, water: bytes, width: int, height: int) -> bytes:
    """Mature masks are row-major, LSB-first bitmaps over 16x16 Gold cells."""
    row_bytes = (width + 7) // 8
    expected_len = row_bytes * height
    if len(blocked) != expected_len or len(water) != expected_len:
        raise ValueError(f"mature mask bytes {len(blocked)}/{len(water)} != {expected_len}")
    out = bytearray()
    for y in range(height):
        for x in range(width):
            bit = 1 << (x & 7)
            idx = y * row_bytes + (x >> 3)
            is_water = bool(water[idx] & bit)
            is_blocked = bool(blocked[idx] & bit)
            out.append(2 if is_water else 1 if is_blocked else 0)
    return bytes(out)


def _section(text: str, start: str, end: str) -> str:
    try:
        return text.split(start, 1)[1].split(end, 1)[0]
    except IndexError as exc:
        raise ValueError(f"missing section {start}..{end}") from exc


def _core(root: Path, gold_root: Path, reference_root: Path,
          text_overrides: dict[str, str] | None = None,
          byte_overrides: dict[str, bytes] | None = None) -> dict:
    root, gold_root, reference_root = map(Path, (root, gold_root, reference_root))
    text_overrides = text_overrides or {}
    byte_overrides = byte_overrides or {}
    checks: list[dict] = []
    errors: list[str] = []

    def ck(name: str, ok: bool, detail: str = "") -> None:
        checks.append({"check": name, "status": "PASS" if ok else "FAIL", "detail": detail})
        if not ok:
            errors.append(f"{name}: {detail}" if detail else name)

    def txt(rel: str) -> str:
        return text_overrides.get(rel, (root / rel).read_text(encoding="utf-8"))

    def raw(rel: str) -> bytes:
        return byte_overrides.get(rel, (root / rel).read_bytes())

    try:
        constants = txt("constants/region_map_constants.asm")
        fixed = txt("constants/johto_fixed_map_ids.asm")
        version = txt("data/game_version.asm")
        slots = txt("data/johto_stable_id_slots.asm")
        headers = txt("data/johto_header_descriptors.asm")
        runtime_assets = txt("data/johto_pilot_runtime_assets.asm")
        source = txt("data/johto_pilot_source_resources.asm")
        west = txt("data/johto_west_sea_runtime_299.asm")
        old_west = txt("data/johto_west_runtime_297.asm")
        surf = txt("engine/johto_violet_field_skills.asm")
        land = txt("engine/johto_land_collision_gateway_272.asm")
        runtime = txt("engine/johto_pilot_runtime.asm")
        town_map = txt("engine/fly_town_map_helpers.asm")
        fly = txt("engine/johto_pilot_fly_map.asm")
        names = txt("engine/overworld/map_name_sign.asm")
        music = txt("engine/menu/options_menu.asm")
        roof = txt("engine/johto_south_roofs_269.asm")
        palette = txt("color/loadpalettes.asm")
        main = txt("main.asm")

        ck("version_299_and_test_232",
           'db "REF-337@"' in version and 'TEST-' not in version,
           "REF-5.62.312; normal and battle-test builds share the same in-ROM version")
        ck("active_35", re.search(r"(?m)^DEF NUM_JOHTO_ACTIVE_MAPS EQU 56$", constants) is not None)
        for name, sym, dim_sym, ident, w, h, water_count, mature in MAPS:
            m = re.search(rf"(?m)^DEF {re.escape(sym)} EQU (\$[0-9A-Fa-f]+|\d+)(?:\s*;.*)?$", fixed + "\n" + constants)
            parsed_id = int(m.group(1)[1:], 16) if m and m.group(1).startswith("$") else int(m.group(1)) if m else None
            ck(f"id_{name}", parsed_id == ident, f"{sym}={parsed_id}, expected={ident}")
            ck(f"dimensions_{name}",
               f"DEF {dim_sym}_WIDTH EQU {w}" in constants and
               f"DEF {dim_sym}_HEIGHT EQU {h}" in constants,
               f"{w}x{h} blocks")

        # Sparse stable IDs 27/28/29 must route only to newly appended slots 32/33/34.
        slot_body = _section(slots, "JohtoStableIDToActiveSlot::", "JohtoStableIDToActiveSlotEnd::")
        tokens: list[int] = []
        for line in slot_body.splitlines():
            code = line.split(";", 1)[0].strip()
            if not code.startswith("db "):
                continue
            for item in code[3:].split(","):
                item = item.strip()
                if item == "JOHTO_INVALID_ACTIVE_SLOT": tokens.append(255)
                elif item.isdigit(): tokens.append(int(item))
                else:
                    # The table currently uses literal slot numbers for active entries.
                    tokens.append(999)
        ck("stable_slots_27_29", len(tokens) == 256 and tokens[27:30] == [32, 33, 34],
           f"slots[27:30]={tokens[27:30] if len(tokens) >= 30 else None}")

        for name, sym, dim_sym, ident, w, h, water_count, mature in MAPS:
            header_label = "JohtoCianwoodRuntimeHeader" if name == "CianwoodCity" else f"Johto{name}RuntimeHeader"
            block_label = "JohtoCianwoodBlocks" if name == "CianwoodCity" else f"Johto{name}Blocks"
            ck(f"header_registered_{name}", f"dw {header_label}" in headers and f"db BANK({header_label})" in headers)
            ck(f"runtime_descriptor_{name}",
               f"db {sym}, JOHTO_PILOT" in runtime_assets and f"dw {block_label}" in runtime_assets)
            ck(f"source_descriptor_{name}",
               f"db MAP_REGION_JOHTO, {sym}," in source and f'INCBIN "maps/johto_pilot/{name}.gold.blk"' in source)

        # Source topology: exactly one of each approved new directed edge.
        conn = _section(source, "JohtoPilotSourceConnections::", "JohtoPilotSourceConnectionsEnd::")
        for a, direction, b in NEW_CONNECTIONS:
            row = f"db MAP_REGION_JOHTO, {a}, {direction}, MAP_REGION_JOHTO, {b}"
            ck(f"connection_{a}_{direction}_{b}", conn.count(row) == 1, row)
        ck("source_connection_count_36", "JOHTO_PILOT_SOURCE_CONNECTION_COUNT EQU 52" in source)

        # Gold source + mature reference identity and role-grid derivation.
        gold = GoldCollisionIndex(gold_root)
        for name, sym, dim_sym, ident, w, h, water_count, mature in MAPS:
            source_rel = f"maps/johto_pilot/{name}.gold.blk"
            runtime_rel = f"maps/johto_pilot/{name}.runtime.blk"
            blocked_rel = f"maps/johto_pilot/{name}.mature_blocked_mask.bin"
            water_rel = f"maps/johto_pilot/{name}.mature_water_mask.bin"
            roles_rel = f"maps/johto_pilot/{name}.roles.bin"
            gold_blk = (gold.gold / "maps" / gold.block_files[name]).read_bytes()
            ref_blk = (reference_root / "maps" / f"{mature}.blk").read_bytes()
            ref_blocked = (reference_root / "maps" / f"{mature}.blocked_mask.bin").read_bytes()
            ref_water = (reference_root / "maps" / f"{mature}.water_mask.bin").read_bytes()
            ck(f"gold_blk_{name}", raw(source_rel) == gold_blk and len(gold_blk) == w*h,
               f"{len(gold_blk)} bytes")
            ck(f"mature_runtime_{name}", raw(runtime_rel) == ref_blk == gold_blk,
               "runtime == NPC-243 mature == Gold")
            ck(f"mature_masks_{name}", raw(blocked_rel) == ref_blocked and raw(water_rel) == ref_water,
               "copied masks byte-identical to mature reference")
            expected_roles = _mask_roles(ref_blocked, ref_water, w*2, h*2)
            roles = raw(roles_rel)
            ck(f"role_grid_{name}", roles == expected_roles and len(roles) == w*h*4,
               f"role bytes={len(roles)}")
            gold_water = {(c["y"], c["x"]) for c in gold.cells(name).values() if c["role"] == "WATER"}
            role_water = {(y, x) for y in range(h*2) for x in range(w*2) if roles[y*w*2+x] == 2}
            ck(f"gold_water_{name}", role_water == gold_water and len(role_water) == water_count,
               f"Gold/role WATER={len(role_water)}, expected={water_count}")

        # Exact header/preview contracts from the mature implementation.
        r40 = _section(west, "JohtoRoute40RuntimeHeader::", "JohtoRoute40HeaderEnd::")
        r41 = _section(west, "JohtoRoute41RuntimeHeader::", "JohtoRoute41HeaderEnd::")
        cw = _section(west, "JohtoCianwoodRuntimeHeader::", "JohtoCianwoodHeaderEnd::")
        ol = _section(old_west, "JohtoOlivineRuntimeHeader::", "JohtoOlivineHeaderEnd::")
        ck("header_route40_exact",
           all(x in r40 for x in ("db SOUTH | EAST", "dw JohtoRoute41Blocks + 15", "db 30",
                                  "dw JohtoRoute40EastOlivineMirror + JOHTO_OLIVINE_CITY_WIDTH * 9",
                                  "db 9", "db 18")) and
           "ASSERT JohtoRoute40HeaderEnd - JohtoRoute40RuntimeHeader == 34" in west)
        ck("header_route41_exact",
           all(x in r41 for x in ("db NORTH | WEST",
                                  "dw JohtoRoute40Blocks + JOHTO_ROUTE_40_WIDTH * (JOHTO_ROUTE_40_HEIGHT - 3)",
                                  "db -30", "dw JohtoCianwoodBlocks + JOHTO_CIANWOOD_CITY_WIDTH - 3")) and
           "ASSERT JohtoRoute41HeaderEnd - JohtoRoute41RuntimeHeader == 34" in west)
        ck("header_cianwood_exact",
           all(x in cw for x in ("db EAST", "dw JohtoRoute41Blocks", "db JOHTO_ROUTE_41_HEIGHT",
                                 "db JOHTO_ROUTE_41_WIDTH")) and
           "ASSERT JohtoCianwoodHeaderEnd - JohtoCianwoodRuntimeHeader == 23" in west)
        ck("olivine_preserves_north_and_adds_west",
           all(x in ol for x in ("db NORTH | WEST", "dw JohtoOlivineNorthRoute39Mirror",
                                 "dw JohtoOlivineWestRoute40Mirror + JOHTO_ROUTE_40_WIDTH - 3",
                                 "db -18", "db JOHTO_ROUTE_40_WIDTH * 2 - 1")) and
           "ASSERT JohtoOlivineHeaderEnd - JohtoOlivineRuntimeHeader == 34" in old_west)

        # Land and Surf seam contracts. Olivine north regression must remain open.
        edge = _section(west, "JohtoWestSeaIsKnownClosedEdge::", "; Carry=1 only on a verified reciprocal WATER seam.")
        seam = _section(west, "JohtoWestSeaSeamWaterAhead::", "; Carry=1 when a Surf step points outside")
        ck("olivine_north_regression_guard",
           ".olivineNorth" in edge and "cp 18" in edge.split(".olivineNorth",1)[1].split(".olivineWest",1)[0]
           and "cp 22" in edge.split(".olivineNorth",1)[1].split(".olivineWest",1)[0])
        ck("olivine_route40_floor_lanes",
           all(x in edge for x in ("cp 20", "cp 22", "cp 26", ".route40East", "cp 2", "cp 4", "cp 8")))
        ck("water_seam_ranges",
           all(x in seam for x in ("cp 26", "cp 32", "cp 8", "cp 14", "cp 2", "cp 19", "cp 46")))
        ck("water_only_land_edges_closed",
           ".downClosed40" in edge and "; Route41 seam is WATER only" in edge and
           ".rightClosedCianwood" in edge)

        surf_decision = _section(surf, "JohtoOverworldSurfDecision::", "JohtoVioletIsActive::")
        ck("surf_dispatch_all_four",
           all(re.search(rf"cp {sym}\s+jp z, \.westSea", surf_decision) for sym in
               ("JOHTO_OLIVINE_CITY_LOCAL_ID", "JOHTO_ROUTE_40_LOCAL_ID",
                "JOHTO_ROUTE_41_LOCAL_ID", "JOHTO_CIANWOOD_CITY_LOCAL_ID")))
        ck("surf_unsafe_edge",
           all(x in surf_decision for x in ("callab JohtoWestSeaGoldWaterProbe",
                                            "callab JohtoWestSeaUnsafeSurfEdge",
                                            "callab JohtoWestSeaGoldShoreProbe",
                                            "ld [wTileInFrontOfPlayer], a")))
        ck("surf_entry_probe",
           "callab JohtoWestSeaGoldWaterProbe" in _section(surf, "JohtoVioletWaterAhead::", "JohtoNewBarkIsActive::"))
        ck("land_gateway",
           all(sym in land for sym in ("JOHTO_ROUTE_40_LOCAL_ID", "JOHTO_ROUTE_41_LOCAL_ID",
                                       "JOHTO_CIANWOOD_CITY_LOCAL_ID")) and
           "callab JohtoWestSeaSpatialStep" in land)
        ck("closed_edge_dispatch",
           all(sym in runtime for sym in ("JOHTO_OLIVINE_CITY_LOCAL_ID", "JOHTO_ROUTE_40_LOCAL_ID",
                                          "JOHTO_ROUTE_41_LOCAL_ID", "JOHTO_CIANWOOD_CITY_LOCAL_ID")) and
           "callab JohtoWestSeaIsKnownClosedEdge" in runtime)

        # Keep intentionally deferred content closed.
        r40_obj = _section(west, "JohtoRoute40RuntimeObjects::", "JohtoRoute41RuntimeObjects::")
        r41_obj = _section(west, "JohtoRoute41RuntimeObjects::", "JohtoCianwoodRuntimeObjects::")
        cw_obj = _section(west, "JohtoCianwoodRuntimeObjects::", "JohtoRoute40TextPointers:")
        ck("deferred_warps_closed",
           re.search(r"db \$05\s+db 0\s+db 1", r40_obj) is not None and
           re.search(r"db \$05\s+db 0\s*; four Whirl Islands cave entries remain intentionally closed\s+db 0\s+db 0", r41_obj) is not None and
           re.search(r"db \$05\s+db 1\s*; REF-336 center enabled alongside existing warps\s+db 43, 23, 0, JOHTO_REGISTERED_WARP_SELECTOR\s*; Gold Cianwood #3 Center\s+db 5", cw_obj) is not None,
           "Route40/41 remain sealed; Cianwood only Gold center door #3 open")
        ck("route41_no_signs", re.search(r"db 0\s+db 0\s*$", r41_obj.strip()) is not None)
        ck("route40_sign_object_exact",
           re.search(r"db 1\s+db 8, 16, 1\s+db 0\s*$", r40_obj.strip()) is not None,
           "Gold route sign at x16/y8; no trainer objects")
        ck("cianwood_sign_objects_exact",
           all(row in cw_obj for row in ("db 34, 20, 1", "db 45, 7, 2", "db 43, 24, 3",
                                         "db 47, 19, 4", "db 32, 8, 5")) and
           re.search(r"db 5.*db 34, 20, 1.*db 45, 7, 2.*db 43, 24, 3.*db 47, 19, 4.*db 32, 8, 5.*db 0\s*$",
                     cw_obj.strip(), re.S) is not None,
           "five Gold BGEVENT_READ signs; no NPC scenes")
        ck("west_sea_sign_texts_exact",
           all(token in west for token in ('text "ROUTE 40"', 'para "CIANWOOD CITY"',
                                           'text "CIANWOOD GYM"', 'text "#MON CENTER"',
                                           'text "PHARMACY"', 'text "PHOTO STUDIO"')),
           "approved mature sign text only")

        # User-facing registrations.
        ck("town_map_names",
           all(x in town_map for x in ("JohtoPilotRoute40Name", "JohtoPilotRoute41Name", "JohtoPilotCianwoodName",
                                       'db "Route 40@"', 'db "Route 41@"', 'db "Cianwood City@"')))
        ck("popup_names",
           all(x in names for x in ("JOHTO_ROUTE_40_LOCAL_ID", "JOHTO_ROUTE_41_LOCAL_ID",
                                    "JOHTO_CIANWOOD_CITY_LOCAL_ID", 'db "Route 40@"',
                                    'db "Route 41@"', 'db "Cianwood City@"')))
        ck("gsc_music",
           music.count("MUSIC_GBP_GSC_ROUTE36") >= 2 and "MUSIC_GBP_GSC_ECRUTEAK_CITY" in music)
        ck("roof_registration",
           all(sym in roof for sym in ("JOHTO_ROUTE_40_LOCAL_ID", "JOHTO_ROUTE_41_LOCAL_ID",
                                       "JOHTO_CIANWOOD_CITY_LOCAL_ID")) and
           'INCBIN "gfx/tilesets/johto_olivine_roofs.2bpp"' in roof and
           all(sym in palette for sym in ("JOHTO_ROUTE_40_LOCAL_ID", "JOHTO_ROUTE_41_LOCAL_ID",
                                          "JOHTO_CIANWOOD_CITY_LOCAL_ID")) and
           "JohtoCianwoodRoofPalette299" in palette)
        ck("roof_png_matches_mature_reference",
           raw("gfx/tilesets/johto_olivine_roofs.png") ==
           (reference_root / "gfx/tilesets/johto_olivine_roofs.png").read_bytes(),
           "PNG source copied byte-identically; generated .2bpp remains untracked")
        ck("fly_cianwood_active",
           "JOHTO_CIANWOOD_CITY_LOCAL_ID" in fly and ".warpCianwood:" in fly and
           re.search(r"\.warpCianwood:\s*\n\s*FLYWARP_DATA\s+15,\s*44,\s*23", fly) is not None)

        # Bank placement and capacity strategy: no new runtime logic in ROM0/$51.
        ck("dedicated_bank52",
           'SECTION "Johto West Sea Runtime 299", ROMX, BANK[$52]' in main and
           'INCLUDE "data/johto_west_sea_runtime_299.asm"' in main)

    except (OSError, ValueError, KeyError, IndexError, AttributeError) as exc:
        ck("source_parse", False, str(exc))

    return {"status": "PASS_STATIC_ONLY" if not errors else "FAIL", "errors": errors,
            "checks": checks, "rom_built": False, "phone_verified": False}


def audit(root: Path, gold_root: Path, reference_root: Path, run_fault_tests: bool = True) -> dict:
    report = _core(root, gold_root, reference_root)
    if run_fault_tests:
        root = Path(root)
        faults = []
        # 1) Removing the off-map Surf guard must be detected.
        surf_rel = "engine/johto_violet_field_skills.asm"
        surf = (root / surf_rel).read_text(encoding="utf-8")
        mutated = surf.replace("callab JohtoWestSeaUnsafeSurfEdge", "callab JohtoWestSeaGoldShoreProbe", 1)
        faults.append(("fault_rejects_missing_unsafe_surf_edge",
                       _core(root, gold_root, reference_root, {surf_rel: mutated})["status"] == "FAIL"))
        # 2) A one-byte role-grid drift must fail Gold/mature comparison.
        role_rel = "maps/johto_pilot/Route41.roles.bin"
        role = bytearray((root / role_rel).read_bytes())
        role[0] = 0 if role[0] != 0 else 1
        faults.append(("fault_rejects_role_grid_drift",
                       _core(root, gold_root, reference_root, byte_overrides={role_rel: bytes(role)})["status"] == "FAIL"))
        # 3) Losing one reciprocal source edge must fail topology.
        src_rel = "data/johto_pilot_source_resources.asm"
        src = (root / src_rel).read_text(encoding="utf-8")
        line = "    db MAP_REGION_JOHTO, JOHTO_ROUTE_41_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_CIANWOOD_CITY_LOCAL_ID\n"
        faults.append(("fault_rejects_missing_reciprocal_connection",
                       _core(root, gold_root, reference_root, {src_rel: src.replace(line, "", 1)})["status"] == "FAIL"))
        for name, ok in faults:
            report["checks"].append({"check": name, "status": "PASS" if ok else "FAIL",
                                     "detail": "negative fault injection must be rejected"})
            if not ok:
                report["errors"].append(name)
        report["status"] = "PASS_STATIC_ONLY" if not report["errors"] else "FAIL"
        report["negative_fault_tests"] = {name: ok for name, ok in faults}
    return report


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", type=Path, default=Path.cwd())
    p.add_argument("--gold-root", type=Path, required=True)
    p.add_argument("--reference-root", type=Path, required=True)
    p.add_argument("--json-out", type=Path)
    a = p.parse_args()
    report = audit(a.project, a.gold_root, a.reference_root)
    payload = json.dumps(report, ensure_ascii=False, indent=2)
    if a.json_out:
        a.json_out.parent.mkdir(parents=True, exist_ok=True)
        a.json_out.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0 if report["status"] == "PASS_STATIC_ONLY" else 1


if __name__ == "__main__":
    raise SystemExit(main())
