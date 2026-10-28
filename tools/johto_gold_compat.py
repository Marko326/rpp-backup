#!/usr/bin/env python3
"""Resolve and compare the two supported pret pokegold source layouts.

This is a read-only source compatibility check. It never builds or links ROMs.
The pret upstream source remains the canonical semantic reference; MUS is
accepted as a modified source profile only when the map/warp/collision data
needed by migration tools remains compatible.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

PROFILES = ("auto", "pret", "mus")
CORE_FILES = (
    "main.asm",
    "Makefile",
    ".rgbds-version",
    "data/maps/maps.asm",
    "data/maps/attributes.asm",
    "data/maps/blocks.asm",
    "constants/map_constants.asm",
    "gfx/tilesets.asm",
    "engine/overworld/tile_events.asm",
    "engine/overworld/player_movement.asm",
    "home/map.asm",
    "engine/overworld/events.asm",
    "engine/overworld/scripting.asm",
)
ENGINE_MARKERS = {
    "engine/overworld/tile_events.asm": ("CheckWarpCollision::", "CheckDirectionalWarp::"),
    "engine/overworld/player_movement.asm": ("DoPlayerMovement::", ".EdgeWarps:"),
    "home/map.asm": ("CheckWarpTile::", "WarpCheck::", "GetWarpDestCoords::"),
    "engine/overworld/events.asm": ("CheckTileEvent:", "WarpToNewMapScript:"),
    "engine/overworld/scripting.asm": ("Script_warp:", "Script_warpcheck:"),
}


class GoldCompatibilityError(ValueError):
    """A source root is missing, ambiguous, unsupported, or inconsistent."""


def _is_gold_root(path: Path) -> bool:
    return path.is_dir() and all((path / name).is_file() for name in CORE_FILES)


def detect_gold_profile(root: Path) -> str:
    """Identify the supported source variant without using the folder name."""
    root = Path(root).resolve()
    version_file = root / "data/game_version.asm"
    if version_file.is_file():
        version_text = version_file.read_text(encoding="utf-8", errors="replace")
        if re.search(r"\bMUS-\d+\.\d+\.\d+\b", version_text):
            return "mus"
    context = root / "RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt"
    if context.is_file():
        text = context.read_text(encoding="utf-8", errors="replace")
        if "MUS-1.0.1" in text or "MUS-1.0.0" in text:
            return "mus"
    return "pret"


def resolve_gold_root(path: Path, expected_profile: str = "auto", *, require_core: bool = True) -> Path:
    """Accept a source root or a parent containing exactly one source root.

    For safety, archives are not extracted implicitly. Extract a ZIP first;
    both the nested pret archive layout and the flat MUS layout are supported.
    """
    if expected_profile not in PROFILES:
        raise GoldCompatibilityError(
            f"未知 Gold profile {expected_profile!r}; 可选值: {', '.join(PROFILES)}")
    candidate = Path(path).expanduser().resolve()
    if not candidate.exists():
        raise GoldCompatibilityError(f"Gold 路径不存在: {candidate}")
    if not candidate.is_dir():
        raise GoldCompatibilityError(
            f"Gold 输入必须是已解压的目录，不自动解压或修改压缩包: {candidate}")
    def acceptable(child: Path) -> bool:
        if _is_gold_root(child):
            return True
        if require_core:
            return False
        return any((child / marker).is_file() for marker in (
            "data/maps/blocks.asm", "data/maps/attributes.asm", "data/maps/maps.asm"))

    if acceptable(candidate):
        root = candidate
    else:
        children = [child for child in sorted(candidate.iterdir()) if acceptable(child)]
        if len(children) == 1:
            root = children[0]
        elif not children:
            missing = [name for name in CORE_FILES if not (candidate / name).is_file()]
            raise GoldCompatibilityError(
                f"找不到 Gold 源码根目录: {candidate}; 缺少标志文件: {', '.join(missing[:8])}")
        else:
            raise GoldCompatibilityError(
                "目录内存在多个 Gold 源码根目录，请分别指定其中一个: "
                + ", ".join(str(child) for child in children))
    detected = detect_gold_profile(root)
    if expected_profile != "auto" and detected != expected_profile:
        raise GoldCompatibilityError(
            f"Gold profile 不匹配: 要求 {expected_profile}，实际检测为 {detected} ({root})")
    return root


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise GoldCompatibilityError(f"缺少必要源码: {path}")
    return path.read_text(encoding="utf-8", errors="replace")


def _block_sources(root: Path) -> dict[str, str]:
    text = _read(root, "data/maps/blocks.asm")
    label_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)_Blocks:{1,2}$")
    incbin_re = re.compile(r'^INCBIN\s+"(maps/[A-Za-z0-9_./-]+\.blk)"$')
    pending: list[str] = []
    result: dict[str, str] = {}
    for line_no, original in enumerate(text.splitlines(), 1):
        line = original.split(";", 1)[0].strip()
        if not line:
            continue
        label = label_re.fullmatch(line)
        if label:
            pending.append(label.group(1))
            continue
        incbin = incbin_re.fullmatch(line)
        if incbin:
            rel = Path(incbin.group(1))
            if rel.is_absolute() or ".." in rel.parts or not rel.parts or rel.parts[0] != "maps":
                raise GoldCompatibilityError(f"不安全的 Gold layout 路径: {rel}")
            if pending:
                for name in pending:
                    if name in result:
                        raise GoldCompatibilityError(f"重复 Gold blocks 标签: {name}")
                    result[name] = str(rel)
                pending.clear()
            continue
        if pending:
            raise GoldCompatibilityError(
                f"未解析的 Gold blocks 标签: data/maps/blocks.asm:{line_no}: {pending}")
    if pending:
        raise GoldCompatibilityError(f"文件结尾仍有未解析的 blocks 标签: {pending}")
    if not result:
        raise GoldCompatibilityError("data/maps/blocks.asm 中没有可解析的地图布局")
    return result


def inspect_gold_source(path: Path, expected_profile: str = "auto") -> dict:
    root = resolve_gold_root(path, expected_profile)
    maps_text = _read(root, "data/maps/maps.asm")
    attrs_text = _read(root, "data/maps/attributes.asm")
    map_names = re.findall(r"^\s*map\s+(\w+)\s*,\s*TILESET_\w+\s*,", maps_text, re.M)
    attr_names = re.findall(r"^\s*map_attributes\s+(\w+)\s*,", attrs_text, re.M)
    map_set, attr_set = set(map_names), set(attr_names)
    dimensions = re.findall(
        r"^\s*map_const\s+(\w+)\s*,\s*(\d+)\s*,\s*(\d+)",
        _read(root, "constants/map_constants.asm"), re.M)
    connections = len(re.findall(r"^\s*connection\s+(?:north|south|west|east)\s*,", attrs_text, re.M))
    warp_count = 0
    map_script_count = 0
    missing_map_scripts = []
    for map_name in sorted(map_set):
        script = root / "maps" / f"{map_name}.asm"
        if not script.is_file():
            missing_map_scripts.append(map_name)
            continue
        text = script.read_text(encoding="utf-8", errors="replace")
        warp_count += len(re.findall(
            r"^\s*warp_event\s+\d+\s*,\s*\d+\s*,\s*[A-Z][A-Z_0-9]*\s*,\s*-?\d+\b",
            text, re.M))
        map_script_count += 1
    blocks = _block_sources(root)
    collision_files = sorted((root / "data/tilesets").glob("*_collision.asm"))
    missing_layouts = sorted(set(blocks.values()) - {
        p.relative_to(root).as_posix() for p in (root / "maps").rglob("*.blk")})
    errors = []
    if missing_layouts:
        errors.append(f"布局文件缺失: {missing_layouts[:8]}")
    if len(map_names) != len(map_set):
        errors.append("maps.asm 含重复地图注册")
    if len(attr_names) != len(attr_set):
        errors.append("attributes.asm 含重复地图属性")
    if map_set != attr_set:
        errors.append(
            f"地图注册/属性不一致: 仅 maps={sorted(map_set-attr_set)[:5]}, "
            f"仅 attributes={sorted(attr_set-map_set)[:5]}")
    if missing_map_scripts:
        errors.append(f"注册地图缺少地图脚本: {missing_map_scripts[:8]}")
    if not dimensions or not blocks or not collision_files or not warp_count:
        errors.append("地图尺寸、布局、碰撞表或 Warp 资源不完整")
    marker_report = {}
    for rel, markers in ENGINE_MARKERS.items():
        text = _read(root, rel)
        missing = [marker for marker in markers if marker not in text]
        marker_report[rel] = {"required": list(markers), "missing": missing}
        if missing:
            errors.append(f"{rel} 缺少引擎标记: {', '.join(missing)}")
    rgbds_version = (root / ".rgbds-version").read_text(encoding="utf-8").strip()
    return {
        "root": str(root),
        "profile": detect_gold_profile(root),
        "rgbds_version": rgbds_version,
        "registered_maps": len(map_names),
        "attribute_maps": len(attr_names),
        "dimension_constants": len(dimensions),
        "block_aliases": len(blocks),
        "map_script_files": map_script_count,
        "warp_events": warp_count,
        "direct_connections": connections,
        "collision_tables": len(collision_files),
        "engine_markers": marker_report,
        "status": "PASS_SOURCE_COMPATIBILITY" if not errors else "FAIL",
        "errors": errors,
    }


def _semantic_inventory(root: Path) -> dict:
    maps_text = _read(root, "data/maps/maps.asm")
    attrs_text = _read(root, "data/maps/attributes.asm")
    maps = sorted(set(re.findall(r"^\s*map\s+(\w+)\s*,\s*TILESET_\w+\s*,", maps_text, re.M)))
    attrs = sorted(set(re.findall(r"^\s*map_attributes\s+(\w+)\s*,", attrs_text, re.M)))
    dims = sorted(re.findall(
        r"^\s*map_const\s+(\w+)\s*,\s*(\d+)\s*,\s*(\d+)",
        _read(root, "constants/map_constants.asm"), re.M))
    connections = {}
    current = None
    for raw in attrs_text.splitlines():
        line = raw.split(";", 1)[0].strip()
        m = re.match(r"^map_attributes\s+(\w+)\s*,", line)
        if m:
            current = m.group(1)
        m = re.fullmatch(
            r"connection\s+(north|south|west|east),\s*(\w+),\s*(\w+),\s*([+-]?\d+)", line)
        if m and current is not None:
            connections[f"{current}:{m.group(1)}"] = [m.group(2), m.group(3), int(m.group(4))]
    warps = {}
    for map_name in maps:
        script = root / "maps" / f"{map_name}.asm"
        if not script.is_file():
            continue
        records = re.findall(
            r"^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z_0-9]*)\s*,\s*(-?\d+)\b",
            script.read_text(encoding="utf-8", errors="replace"), re.M)
        if records:
            warps[map_name] = [list(row) for row in records]
    collision = {
        p.name: hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted((root / "data/tilesets").glob("*_collision.asm"))
    }
    blocks = _block_sources(root)
    # A matching INCBIN path is not sufficient: an updated source can keep
    # the same filename while changing the bytes used by map conversion.
    layout_files = sorted(set(blocks.values()))
    missing_layouts = [name for name in layout_files if not (root / name).is_file()]
    if missing_layouts:
        raise GoldCompatibilityError(f"地图布局资源缺失: {missing_layouts[:8]}")
    layout_sha = {
        rel: hashlib.sha256((root / rel).read_bytes()).hexdigest()
        for rel in layout_files
    }
    tile_assets = sorted(
        [p for p in (root / "gfx/tilesets").rglob("*") if p.is_file()] +
        [p for p in (root / "data/tilesets").rglob("*") if p.is_file()]
    )
    tile_sha = {
        p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in tile_assets
    }
    return {"map_names": maps, "attribute_names": attrs, "dimensions": dims,
            "connections": connections, "warps": warps, "collision_sha256": collision,
            "block_sources": blocks, "layout_sha256": layout_sha,
            "tileset_assets_sha256": tile_sha}


def compare_gold_sources(first: Path, second: Path,
                         first_profile: str = "auto", second_profile: str = "auto") -> dict:
    a = resolve_gold_root(first, first_profile)
    b = resolve_gold_root(second, second_profile)
    first_audit = inspect_gold_source(a, first_profile)
    second_audit = inspect_gold_source(b, second_profile)
    left, right = _semantic_inventory(a), _semantic_inventory(b)
    differences = {}
    for field in left:
        if left[field] == right[field]:
            continue
        av, bv = left[field], right[field]
        if isinstance(av, dict) and isinstance(bv, dict):
            only_a = sorted(set(av) - set(bv))
            only_b = sorted(set(bv) - set(av))
            changed = sorted(k for k in set(av) & set(bv) if av[k] != bv[k])
            differences[field] = {"only_first": only_a[:12], "only_second": only_b[:12],
                                  "changed": changed[:12], "difference_count": len(only_a)+len(only_b)+len(changed)}
        else:
            differences[field] = {"first_count": len(av), "second_count": len(bv)}
    # Dynamic event behavior can diverge without changing warp_event entries.
    # Report differences separately; they are not silently treated as identical
    # nor incorrectly classified as map-layout incompatibility.
    script_changes = sorted(
        name for name in set(left["map_names"]) & set(right["map_names"])
        if (a / "maps" / f"{name}.asm").read_bytes() !=
           (b / "maps" / f"{name}.asm").read_bytes()
    )
    return {
        "map_script_files_differ": script_changes,
        "script_behavior_equivalence_not_proven": bool(script_changes),
        "first": {"root": str(a), "profile": detect_gold_profile(a),
                  "rgbds_version": (a / ".rgbds-version").read_text().strip(),
                  "source_audit_status": first_audit["status"]},
        "second": {"root": str(b), "profile": detect_gold_profile(b),
                   "rgbds_version": (b / ".rgbds-version").read_text().strip(),
                   "source_audit_status": second_audit["status"]},
        "semantic_categories_compared": sorted(left),
        "compatible_for_migration_reference": (not differences and
            first_audit["status"] == "PASS_SOURCE_COMPATIBILITY" and
            second_audit["status"] == "PASS_SOURCE_COMPATIBILITY"),
        "differences": differences,
        "note": "比较地图、连接、warp、碰撞源码、实际 .blk 数据和 tileset 资源；事件脚本完整行为及 ROM 构建/运行不属于通过范围。",
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gold-root", required=True, type=Path,
                        help="已解压的 Gold/MUS 根目录，或只包含一个项目根的父目录")
    parser.add_argument("--profile", choices=PROFILES, default="auto",
                        help="auto 自动识别；pret/MUS 可用于严格校验项目身份")
    parser.add_argument("--compare-root", type=Path,
                        help="可选：与另一份 Gold/MUS 源码比较迁移关键语义")
    parser.add_argument("--compare-profile", choices=PROFILES, default="auto")
    parser.add_argument("--json-out", type=Path, help="可选 JSON 报告；必须写到源码目录之外")
    args = parser.parse_args(argv)
    try:
        source = inspect_gold_source(args.gold_root, args.profile)
        report = {"schema": "johto-gold-source-compat-v1", "source": source}
        if args.compare_root:
            comparison = compare_gold_sources(args.gold_root, args.compare_root,
                                              args.profile, args.compare_profile)
            report["comparison"] = comparison
        if args.json_out:
            out = args.json_out.expanduser().resolve()
            source_roots = [Path(source["root"]).resolve()]
            if args.compare_root:
                source_roots.append(resolve_gold_root(args.compare_root, args.compare_profile))
            if any(out == root or root in out.parents for root in source_roots):
                raise GoldCompatibilityError("--json-out 必须放在源码目录之外")
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(report, ensure_ascii=False, indent=2))
        if source["status"] != "PASS_SOURCE_COMPATIBILITY":
            return 1
        if args.compare_root and not report["comparison"]["compatible_for_migration_reference"]:
            return 2
        return 0
    except (GoldCompatibilityError, OSError, ValueError) as exc:
        parser.exit(2, f"Gold compatibility check failed: {exc}\n")


if __name__ == "__main__":
    raise SystemExit(main())
