#!/usr/bin/env python3
"""Build runtime-ready Olivine public interiors from audited Gold candidates.

The source candidate atlases compact Gold's used 8x8 graphics. Runtime NPC
collision uses the bottom-left 8x8 graphic ID of each 16x16 cell, unlike the
player's exact Gold position mask. When one graphic ID is shared by passable
and blocked cells, this generator duplicates the graphic and the affected
map block(s), preserving pixels while separating NPC-walkable and blocked IDs.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from PIL import Image

ROOMS = {
    "olivine_pokecenter_1f": {
        "map": "JohtoOlivinePokecenter1F",
        "tileset": "johto_olivine_pokecenter",
        "local_id": 30,
        "active_slot": 49,
        "landmark": 26,
    },
    "olivine_cafe": {
        "map": "JohtoOlivineCafe",
        "tileset": "johto_olivine_cafe",
        "local_id": 36,
        "active_slot": 50,
        "landmark": 26,
    },
    "olivine_mart": {
        "map": "JohtoOlivineMart",
        "tileset": "johto_olivine_mart",
        "local_id": 37,
        "active_slot": 51,
        "landmark": 26,
    },
}
SPRITES = ("clerk", "cooltrainer_f", "fisher", "nurse", "sailor", "teacher")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _palette_roles(path: Path) -> list[str]:
    roles: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.search(r"\btilepal\s+0\s*,\s*(.*)$", line)
        if not m:
            continue
        roles.extend(part.strip() for part in m.group(1).split(","))
    if len(roles) != 96:
        raise ValueError(f"{path}: expected 96 palette roles, found {len(roles)}")
    return roles


def _blocked(mask: bytes, width_cells: int, x: int, y: int) -> bool:
    row_bytes = (width_cells + 7) // 8
    return bool(mask[y * row_bytes + x // 8] & (1 << (x % 8)))


def build_room(root: Path, candidate_root: Path, key: str) -> dict:
    spec = ROOMS[key]
    src_dir = candidate_root / key
    provenance = json.loads((src_dir / "provenance.json").read_text(encoding="utf-8"))
    width_blocks, height_blocks = map(int, provenance["dimensions_blocks"])
    width_cells, height_cells = width_blocks * 2, height_blocks * 2
    map_src = (src_dir / f"{spec['map']}.blk").read_bytes()
    mask = (src_dir / f"{spec['map']}.blocked_mask.bin").read_bytes()
    block_src = (src_dir / f"{spec['tileset']}.bst").read_bytes()
    image_src = Image.open(src_dir / f"{spec['tileset']}.png").convert("L")
    palette_src = src_dir / f"{spec['tileset']}.palette_candidate.asm"
    palette_roles = _palette_roles(palette_src)

    if len(map_src) != width_blocks * height_blocks:
        raise ValueError(f"{key}: map size does not match Gold dimensions")
    if len(mask) != height_cells * ((width_cells + 7) // 8):
        raise ValueError(f"{key}: blocked-mask size does not match Gold dimensions")
    if len(block_src) % 16:
        raise ValueError(f"{key}: source blockset is not 16-byte aligned")
    block_count = len(block_src) // 16
    if image_src.width != 64 or image_src.height % 8:
        raise ValueError(f"{key}: compacted atlas must be 8 columns of 8x8 tiles")
    if len(provenance["compacted_source_ids"]) > image_src.width * image_src.height // 64:
        raise ValueError(f"{key}: provenance tile count exceeds atlas")

    # Identify graphics used as the NPC foot tile on passable and blocked
    # 16x16 positions. This is the same lower-left 8x8 cell checked by the
    # legacy NPC collision list; player collision remains mask-based.
    pass_ids: set[int] = set()
    blocked_ids: set[int] = set()
    cell_data: dict[tuple[int, int], tuple[int, int, bool, int]] = {}
    for y in range(height_cells):
        for x in range(width_cells):
            map_block = map_src[(y // 2) * width_blocks + (x // 2)]
            if map_block >= block_count:
                raise ValueError(f"{key}: map references missing source block {map_block}")
            subcell = (y % 2) * 2 + (x % 2)
            offset = map_block * 16 + subcell * 4
            foot_tile = block_src[offset + 2]
            blocked = _blocked(mask, width_cells, x, y)
            cell_data[(x, y)] = (map_block, subcell, blocked, foot_tile)
            (blocked_ids if blocked else pass_ids).add(foot_tile)

    ambiguous = sorted(pass_ids & blocked_ids)
    # Put copies after every source atlas row, not merely after the last
    # referenced tile, so the generated source atlas stays easy to inspect.
    next_tile = image_src.height // 8 * 8
    duplicate_ids: dict[int, int] = {}
    for source_id in ambiguous:
        if next_tile >= 96:
            raise ValueError(f"{key}: no free 8x8 tile slot for collision split")
        duplicate_ids[source_id] = next_tile
        next_tile += 1

    # Build a 96-tile runtime atlas. The empty remainder is white (palette 0),
    # and duplicated foot tiles are exact pixel copies of their Gold sources.
    atlas = Image.new("L", (64, 96), 255)
    atlas.paste(image_src, (0, 0))
    for source_id, duplicate_id in duplicate_ids.items():
        sx, sy = (source_id % 8) * 8, (source_id // 8) * 8
        dx, dy = (duplicate_id % 8) * 8, (duplicate_id // 8) * 8
        atlas.paste(image_src.crop((sx, sy, sx + 8, sy + 8)), (dx, dy))

    # Clone only map blocks that need their passable foot-tile IDs separated
    # from blocked cells. The visual tile is unchanged; blocked cells keep the
    # original ID, while passable cells use the duplicate ID.
    map_out = bytearray(map_src)
    block_out = bytearray(block_src)
    cloned_blocks = 0
    for by in range(height_blocks):
        for bx in range(width_blocks):
            map_index = by * width_blocks + bx
            original_block = map_src[map_index]
            block_bytes = bytearray(block_src[original_block * 16:(original_block + 1) * 16])
            needs_clone = False
            for sub_y in range(2):
                for sub_x in range(2):
                    x, y = bx * 2 + sub_x, by * 2 + sub_y
                    _, subcell, is_blocked, original_tile = cell_data[(x, y)]
                    if not is_blocked and original_tile in duplicate_ids:
                        block_bytes[subcell * 4 + 2] = duplicate_ids[original_tile]
                        needs_clone = True
            if needs_clone:
                new_block_id = len(block_out) // 16
                if new_block_id > 0xFF:
                    raise ValueError(f"{key}: collision-split block IDs exceed byte range")
                block_out.extend(block_bytes)
                map_out[map_index] = new_block_id
                cloned_blocks += 1

    passable_after: set[int] = set()
    blocked_after: set[int] = set()
    for y in range(height_cells):
        for x in range(width_cells):
            block_id = map_out[(y // 2) * width_blocks + (x // 2)]
            subcell = (y % 2) * 2 + (x % 2)
            foot_tile = block_out[block_id * 16 + subcell * 4 + 2]
            (blocked_after if _blocked(mask, width_cells, x, y) else passable_after).add(foot_tile)
    tilecoll = sorted(passable_after) + [0xFF]
    allowed = set(tilecoll[:-1])
    if passable_after - allowed:
        raise ValueError(f"{key}: passable NPC foot tiles missing from collision list")
    if blocked_after & allowed:
        raise ValueError(f"{key}: blocked NPC foot tile is in collision list: {sorted(blocked_after & allowed)}")

    for source_id, duplicate_id in duplicate_ids.items():
        palette_roles[duplicate_id] = palette_roles[source_id]
    palette_lines = ["; Generated from the audited Gold source tile-role map; duplicated foot tiles retain their source palette."]
    for row in range(12):
        values = ", ".join(palette_roles[row * 8:(row + 1) * 8])
        palette_lines.append(f"\ttilepal 0, {values}")
    palette_bytes = ("\n".join(palette_lines) + "\n").encode("utf-8")

    output_files = {
        root / "gfx/tilesets" / f"{spec['tileset']}.png": None,
        root / "gfx/blocksets" / f"{spec['tileset']}.bst": bytes(block_out),
        root / "gfx/tilesets" / f"{spec['tileset']}.tilecoll": bytes(tilecoll),
        root / "maps" / f"{spec['map']}.blk": bytes(map_out),
        root / "maps" / f"{spec['map']}.blocked_mask.bin": mask,
        root / "color/tilesets" / f"{spec['tileset']}.asm": palette_bytes,
    }
    for p, data in output_files.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        if data is not None:
            p.write_bytes(data)
        else:
            atlas.save(p, format="PNG")

    return {
        "map": spec["map"],
        "tileset": spec["tileset"],
        "local_id": spec["local_id"],
        "active_slot": spec["active_slot"],
        "landmark": spec["landmark"],
        "dimensions_blocks": [width_blocks, height_blocks],
        "dimensions_cells": [width_cells, height_cells],
        "source_block_count": block_count,
        "runtime_block_count": len(block_out) // 16,
        "collision_split_blocks": cloned_blocks,
        "ambiguous_foot_graphics": {str(k): v for k, v in duplicate_ids.items()},
        "npc_walkable_foot_tile_ids": sorted(allowed),
        "blocked_foot_tile_ids": sorted(blocked_after),
        "source_hashes": {
            "map": sha256(map_src),
            "blockset": sha256(block_src),
            "mask": sha256(mask),
            "atlas": sha256((src_dir / f"{spec['tileset']}.png").read_bytes()),
            "palette": sha256(palette_src.read_bytes()),
        },
        "runtime_hashes": {
            "map": sha256(bytes(map_out)),
            "blockset": sha256(bytes(block_out)),
            "mask": sha256(mask),
            "tilecoll": sha256(bytes(tilecoll)),
            "atlas": sha256((root / "gfx/tilesets" / f"{spec['tileset']}.png").read_bytes()),
            "palette": sha256(palette_bytes),
        },
    }


def build(root: Path) -> dict:
    candidate_root = root / "tools/olivine_public_candidates"
    results = [build_room(root, candidate_root, key) for key in ROOMS]
    shared = candidate_root / "shared_gold_sprites"
    sprite_map = {
        "clerk": "johto_clerk.png",
        "cooltrainer_f": "johto_cooltrainer_f.png",
        "fisher": "johto_fisher.png",
        "nurse": "johto_nurse.png",
        "sailor": "johto_sailor.png",
        "teacher": "johto_teacher.png",
    }
    for source_name, target_name in sprite_map.items():
        (root / "gfx/sprites" / target_name).write_bytes((shared / f"{source_name}.png").read_bytes())
    # The two Gold Fishing Guru palette IDs and the Lass sprite are already
    # installed by the first-house sample; require their source artwork to match.
    for source_name, target_name in (("fishing_guru", "johto_fishing_guru.png"), ("lass", "johto_lass.png")):
        if (shared / f"{source_name}.png").read_bytes() != (root / "gfx/sprites" / target_name).read_bytes():
            raise ValueError(f"Existing shared Gold sprite differs from source: {target_name}")
    manifest = {
        "source_head": "7465e56938e8910fdd79ad6987559674c4860d6d",
        "version": "OLIV-5.62.241",
        "status": "runtime-development-candidate",
        "maps": results,
        "sprites": {k: sha256((root / "gfx/sprites" / v).read_bytes()) for k, v in sprite_map.items()},
        "deferred_features": [
            "Pokemon Center healing and 2F stair warp",
            "Mart buying and selling",
            "Cafe Strength gift and dialogue events",
        ],
        "safety": "The Pokemon Center 2F stair remains blocked and has no registered Warp.",
    }
    path = root / "tools/olivine_public_runtime_manifest.json"
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return manifest


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--rpp", type=Path, required=True, help="RPP project root")
    ap.add_argument("--check", action="store_true", help="verify generated assets without rewriting")
    args = ap.parse_args()
    root = args.rpp.resolve()
    if args.check:
        import tempfile
        import shutil
        with tempfile.TemporaryDirectory(prefix="olivine-public-runtime-") as tmp:
            temp_root = Path(tmp) / "rpp"
            (temp_root / "tools").mkdir(parents=True)
            (temp_root / "gfx/sprites").mkdir(parents=True)
            shutil.copytree(root / "tools/olivine_public_candidates", temp_root / "tools/olivine_public_candidates")
            for name in ("johto_fishing_guru.png", "johto_lass.png"):
                shutil.copy2(root / "gfx/sprites" / name, temp_root / "gfx/sprites" / name)
            expected = build(temp_root)
            manifest_path = root / "tools/olivine_public_runtime_manifest.json"
            actual = json.loads(manifest_path.read_text(encoding="utf-8"))
            if expected != actual:
                print("FAIL: runtime manifest is not reproducible")
                return 1
            rels = (
                "gfx/tilesets/johto_olivine_pokecenter.png", "gfx/blocksets/johto_olivine_pokecenter.bst", "gfx/tilesets/johto_olivine_pokecenter.tilecoll", "maps/JohtoOlivinePokecenter1F.blk", "maps/JohtoOlivinePokecenter1F.blocked_mask.bin", "color/tilesets/johto_olivine_pokecenter.asm",
                "gfx/tilesets/johto_olivine_mart.png", "gfx/blocksets/johto_olivine_mart.bst", "gfx/tilesets/johto_olivine_mart.tilecoll", "maps/JohtoOlivineMart.blk", "maps/JohtoOlivineMart.blocked_mask.bin", "color/tilesets/johto_olivine_mart.asm",
                "gfx/tilesets/johto_olivine_cafe.png", "gfx/blocksets/johto_olivine_cafe.bst", "gfx/tilesets/johto_olivine_cafe.tilecoll", "maps/JohtoOlivineCafe.blk", "maps/JohtoOlivineCafe.blocked_mask.bin", "color/tilesets/johto_olivine_cafe.asm",
                "gfx/sprites/johto_clerk.png", "gfx/sprites/johto_cooltrainer_f.png", "gfx/sprites/johto_fisher.png", "gfx/sprites/johto_nurse.png", "gfx/sprites/johto_sailor.png", "gfx/sprites/johto_teacher.png",
            )
            for rel in rels:
                if (root / rel).read_bytes() != (temp_root / rel).read_bytes():
                    print(f"FAIL: generated asset differs: {rel}")
                    return 1
        print("PASS: public-building runtime assets reproduce byte-for-byte")
        return 0
    manifest = build(root)
    for room in manifest["maps"]:
        print(f"{room['map']}: {room['dimensions_blocks'][0]}x{room['dimensions_blocks'][1]} blocks; "
              f"{room['runtime_block_count']} blocks; {room['collision_split_blocks']} collision-split blocks; "
              f"{len(room['npc_walkable_foot_tile_ids'])} NPC-walkable foot tiles")
    print(f"Wrote {root/'tools/olivine_public_runtime_manifest.json'}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
