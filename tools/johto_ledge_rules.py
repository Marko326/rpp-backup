#!/usr/bin/env python3
"""Generate RPP front-of-player ledge barrier tables from Gold collision data.

Consumes johto_collision_converter.py's Gold 16x16-cell JSON. This writes
ROMX front-tile trigger data, not a generic tilecoll/passability table. Each map must
be registered separately by its game-side script and Map ID. Diagonal hops
are expanded into independent cardinal directions according to Gold's facing masks.

Example:
    python tools/johto_ledge_rules.py \
        --input collision_data/Route29_collision.json \
        --output data/generated/johto_route29_ledges.asm \
        --label JohtoRoute29LedgeRules

Batch (data only, no map engine registration):
    python tools/johto_ledge_rules.py \
        --batch-dir collision_data --out-dir /tmp/johto_ledge_tables
"""
import argparse
import json
from pathlib import Path

DIRECTIONS = {
    "HOP_LEFT": (-1, 0, "SPRITE_FACING_LEFT", "D_LEFT"),
    "HOP_RIGHT": (1, 0, "SPRITE_FACING_RIGHT", "D_RIGHT"),
    "HOP_DOWN": (0, 1, "SPRITE_FACING_DOWN", "D_DOWN"),
    "HOP_UP": (0, -1, "SPRITE_FACING_UP", "D_UP"),
}
# Gold uses bit masks, NOT a diagonal jump vector. A corner collision
# permits either of two independent CARDINAL hops from the same launch cell.
# Source of truth: pokegold engine/overworld/player_movement.asm .ledge_table.
COMBINED_DIRECTIONS = {
    "HOP_DOWN_LEFT": ("HOP_DOWN", "HOP_LEFT"),
    "HOP_DOWN_RIGHT": ("HOP_DOWN", "HOP_RIGHT"),
    "HOP_UP_LEFT": ("HOP_UP", "HOP_LEFT"),
    "HOP_UP_RIGHT": ("HOP_UP", "HOP_RIGHT"),
}


def convert(input_path: Path, output_path: Path, label: str) -> tuple[int, int]:
    source = json.loads(input_path.read_text(encoding="utf-8"))
    if source.get("schema") != "johto_collision_overlay_v1":
        raise ValueError(f"Wrong collision-data schema: {input_path}")
    width, height = source["cells"]["width"], source["cells"]["height"]
    hops = [cell for cell in source["special_cells"] if cell["type"].startswith("HOP_")]
    unknown = sorted({cell["type"] for cell in hops} - set(DIRECTIONS) - set(COMBINED_DIRECTIONS))
    if unknown:
        raise ValueError(f"Unknown hop collisions: {unknown}")
    combined = [cell for cell in hops if cell["type"] in COMBINED_DIRECTIONS]
    if width >= 255 or height >= 255:
        raise ValueError("ROM table uses byte-sized x/y: map is too big")
    coords = set()
    for cell in hops:
        x, y = cell["x"], cell["y"]
        if not (0 <= x < width and 0 <= y < height):
            raise ValueError(f"Out-of-bounds hop cell: {cell}")
        if (x, y) in coords:
            raise ValueError(f"Conflicting hop collision: {cell}")
        coords.add((x, y))
    # A Gold HOP_* cell is the safe launch cell at the cliff lip. For
    # HOP_DOWN_LEFT etc, Gold accepts EITHER direction, not diagonal movement.
    # Generate one separate RPP two-step hop for each permitted direction.
    barriers = set()
    converted = []
    for cell in sorted(hops, key=lambda item: (item["y"], item["x"])):
        kinds = COMBINED_DIRECTIONS.get(cell["type"], (cell["type"],))
        for kind in kinds:
            dx, dy, facing, joy = DIRECTIONS[kind]
            x, y = cell["x"], cell["y"]
            bx, by = x + dx, y + dy
            lx, ly = x + 2 * dx, y + 2 * dy
            if not (0 <= bx < width and 0 <= by < height):
                raise ValueError(f"Jump barrier outside map: {cell} in {kind}")
            if not (0 <= lx < width and 0 <= ly < height):
                raise ValueError(f"Jump landing outside map: {cell} in {kind}")
            if (bx, by) in barriers:
                raise ValueError(f"Jump barrier collision at ({bx},{by}): {cell} in {kind}")
            barriers.add((bx, by))
            converted.append((bx, by, facing, joy, cell["type"], x, y, lx, ly))
    # Reuse the original RPP HandleLedges hopping animation/sound/two-step
    # simulation. This table only classifies the front-of-player barrier.
    # Reverse or side entry into the same tile is forbidden in the normal
    # collision path. No independent Johto movement action is generated.
    lines = [
        "; MAP-5.62.132: Gold HOP_* launch => RPP front barrier position.",
        "; Compound HOP_DOWN_LEFT/RIGHT means two independent cardinal hops.",
        "; Record: barrier_x, barrier_y, required_facing, required_joypad_input.",
        "; Source is one cell before barrier; two-step hop lands one cell beyond.",
        "; Any ordinary entry into a listed barrier cell is blocked.",
        label + ":",
    ]
    for bx, by, facing, joy, kind, x, y, lx, ly in converted:
        lines.append(f"\tdb {bx}, {by}, {facing}, {joy} ; {kind} launch ({x},{y}) landing ({lx},{ly})")
    lines.append("\tdb $ff ; terminator")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return len(converted), len(combined)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--input", type=Path)
    group.add_argument("--batch-dir", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--out-dir", type=Path)
    parser.add_argument("--label")
    args = parser.parse_args()
    if args.input:
        if not args.output or not args.label:
            parser.error("--input needs --output and --label")
        n, d = convert(args.input, args.output, args.label)
        print(f"{args.input.stem}: {n} cardinal hop actions, including {d} compound corner cells")
    else:
        if not args.out_dir:
            parser.error("--batch-dir needs --out-dir")
        total_rules, total_diagonals, count = 0, 0, 0
        for inp in sorted(args.batch_dir.glob("*_collision.json")):
            name = inp.stem.removesuffix("_collision")
            label = "Johto" + name + "LedgeRules"
            n, d = convert(inp, args.out_dir / (name + "_ledges.asm"), label)
            total_rules += n
            total_diagonals += d
            count += 1
        print(f"{count} maps: {total_rules} cardinal hop actions, including {total_diagonals} compound corner cells")


if __name__ == "__main__":
    main()
