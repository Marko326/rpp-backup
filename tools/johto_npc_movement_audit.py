#!/usr/bin/env python3
"""Gold-to-RPP movement parity audit (static; does not prove runtime ROM behavior).

The RPP object macro encodes WALK axis but not radius. Six enabled Johto walkers
have source-verified Gold spawn/radius bounds in a Johto-only ROMX helper;
other maps, including early Route29 placeholders, must not be claimed as
converted. A new walking NPC without an audited entry fails closed.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Mapping

# Only known naming differences. A newly added unmatched Johto map must be
# reviewed and added here, or this audit fails instead of silently skipping it.
GOLD_MAP_ALIASES = {
    "JohtoIlexAzaleaGate": "IlexForestAzaleaGate",
    "JohtoRoute36RuinsGate": "Route36RuinsOfAlphGate",
}

STANDING = {
    "SPRITEMOVEDATA_STANDING_DOWN": "DOWN",
    "SPRITEMOVEDATA_STANDING_UP": "UP",
    "SPRITEMOVEDATA_STANDING_LEFT": "LEFT",
    "SPRITEMOVEDATA_STANDING_RIGHT": "RIGHT",
}
WALKING = {
    "SPRITEMOVEDATA_WALK_LEFT_RIGHT": 2,
    "SPRITEMOVEDATA_WALK_UP_DOWN": 1,
}
# This equivalence is already used by the project's passive-NPC conversion:
# Gold's slow random turning is represented by RPP STAY,NONE.
SPECIAL_EQUIVALENCES = {
    "SPRITEMOVEDATA_SPINRANDOM_SLOW": ("STAY", "NONE"),
}

# Explicit map-identity to patrol-table key pairing; do not infer identity
# from a tileset (both MARTs share tileset) or from the global $FC map handle.
PATROL_MAP_IDS = {
    "JohtoCherrygroveMart": "JOHTO_CHERRYGROVE_MART_LOCAL_ID",
    "JohtoOlivineMart": "JOHTO_OLIVINE_MART_LOCAL_ID",
    "JohtoOlivinePokecenter1F": "JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID",
    "JohtoOlivineCafe": "JOHTO_OLIVINE_CAFE_LOCAL_ID",
    "JohtoOlivinePunishmentSpeechHouse": "JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID",
    "JohtoCherrygroveGymSpeechHouse": "JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID",
}


def parse_patrol_table(asm: str) -> tuple[dict[str, tuple[int, int, int]], list[str]]:
    """Parse the assembler's runtime limits: map => (Gold spawn, radius, min+4/max+4).

    The expression grammar is deliberately small; accidentally changing the
    ASM table syntax must fail audit until the parser and tests are reviewed.
    """
    entries: dict[str, tuple[int, int, int]] = {}
    errors: list[str] = []
    for line in asm.splitlines():
        match = re.match(
            r"^\s*db\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s*,\s*"
            r"(\d+)\s*\+\s*4\s*-\s*(\d+)\s*,\s*"
            r"(\d+)\s*\+\s*4\s*\+\s*(\d+)\b", line)
        if not match:
            continue
        name, lower_origin, minus, upper_origin, plus = match.groups()
        x0, r0, x1, r1 = map(int, (lower_origin, minus, upper_origin, plus))
        if name in entries:
            errors.append(f"duplicate Johto patrol map entry {name}")
        if x0 != x1 or r0 != r1:
            errors.append(f"asymmetric Johto patrol bounds {name}: {line.strip()}")
        entries[name] = x0, r0, (x0 + 4 - r0) * 256 + (x1 + 4 + r1)
    return entries, errors





def _asm_ops(asm: str) -> list[str]:
    """Normalize the actual source instructions, excluding comments/spacing.

    This is a deliberately restricted static assembler inspection, NOT a CPU
    emulator or a replacement for ROM testing. Unknown comparator opcodes
    are rejected until the auditor gains an explicit interpretation for them.
    """
    return [re.sub(r"\s+", " ", line.split(";", 1)[0].strip().lower())
            for line in asm.splitlines() if line.split(";", 1)[0].strip()]


def _ordered_ops(ops: list[str], sequence: list[str]) -> bool:
    """Require a sequence in order, not necessarily adjacent (comments stripped)."""
    pos = 0
    for token in sequence:
        try:
            pos = ops.index(token, pos) + 1
        except ValueError:
            return False
    return True


def _compare_destination(ops: list[str], next_cell: int, lo: int, hi: int) -> str:
    """Evaluate the actual restricted LR35902 compare branch instructions.

    Reads the source from .compare through .allow. This makes `jr c` ->
    `jr nc` mutations observable; a hand-coded Python `lo <= x <= hi`
    would *not* test the assembler source and produced the previous blind spot.
    """
    carry = zero = False
    for opcode in ops:
        if opcode in ('cp b', 'cp c'):
            operand = lo if opcode == 'cp b' else hi
            carry = next_cell < operand
            zero = next_cell == operand
            continue
        match = re.fullmatch(r'(jr|jp)\s+(?:(c|nc|z|nz)\s*,\s*)?(\.allow|\.blocked)', opcode)
        if match:
            _jump, condition, dest = match.groups()
            taken = (condition is None or (condition == 'c' and carry)
                     or (condition == 'nc' and not carry)
                     or (condition == 'z' and zero)
                     or (condition == 'nz' and not zero))
            if taken:
                return dest
            continue
        raise ValueError(f'unsupported patrol compare instruction: {opcode}')
    return '.allow'  # falling through directly into .allow


def validate_runtime_patrol_contract(asm: str, table: dict[str, tuple[int, int, int]]) -> list[str]:
    """Check map guards, state transitions, and branch outcomes against Gold.

    The compare segment is interpreted over *all* 256 byte values for each
    patrol bound. The other instructions are conservatively checked for key
    source invariants; these checks are not full LR35902 execution proof.
    """
    errors: list[str] = []
    ops = _asm_ops(asm)
    try:
        prefix = ops[:ops.index('.lookup')]
        compare = ops[ops.index('.compare') + 1:ops.index('.allow')]
        allowed = ops[ops.index('.allow') + 1:ops.index('.blocked')]
        blocked = ops[ops.index('.blocked') + 1:ops.index('.bounds')]
    except ValueError as exc:
        return [f'Johto patrol runtime control-flow labels missing: {exc}']
    expected_guards = [
        'checkjohtonpcpatrolbounds::', 'push de',
        'ld a, [wcurmap]', 'cp region_native_map_slot', 'jr nz, .allow',
        'ld a, [wcurregion]', 'cp map_region_johto', 'jr nz, .allow',
        'ld a, [wcurspritemovement2]', 'cp 1', 'jr z, .checkwalker',
        'cp 2', 'jr nz, .allow', '.checkwalker',
        'ld h, wspritestatedata2 / $100', 'ld a, [h_currentspriteoffset]',
        'add 6', 'ld l, a', 'ld a, [hl]', 'cp walk', 'jr nz, .allow',
        'ld a, [wcurlocalmapid]', 'ld c, a', 'ld hl, .bounds',
    ]
    if not _ordered_ops(prefix, expected_guards):
        errors.append('Johto patrol runtime map/region/WALK guards or local-map lookup changed; review helper branch flow')
    expected_lookup = [
        '.lookup', 'ld a, [hli]', 'cp $ff', 'jr z, .allow',
        'cp c', 'jr z, .found', 'inc hl', 'inc hl', 'jr .lookup',
        '.found', 'ld a, [hli]', 'ld b, a', 'ld c, [hl]',
    ]
    if not _ordered_ops(ops, expected_lookup):
        errors.append('Johto patrol runtime map table search or bounds extraction changed')
    # Horizontal step uses E; vertical step uses D and falls through.
    try:
        arm = ops[ops.index('.found'):ops.index('.compare')]
    except ValueError:
        arm = []
    if not _ordered_ops(arm, [
        'ld a, [wcurspritemovement2]', 'cp 2', 'jr nz, .vertical',
        'inc l', 'ld a, [hl]', 'add e', 'jr .compare',
        '.vertical', 'ld a, [hl]', 'add d',
    ]):
        errors.append('Johto patrol runtime next-coordinate axis/delta calculation changed')
    if allowed != ['pop de', 'and a', 'ret']:
        errors.append('Johto patrol allow path must restore DE and clear carry before return')
    if not _ordered_ops(blocked, [
        'pop de', 'ld h, wspritestatedata1 / $100',
        'ld a, [h_currentspriteoffset]', 'inc a', 'ld l, a',
        'ld [hl], 2', 'inc l', 'inc l', 'xor a', 'ld [hli], a',
        'inc l', 'ld [hl], a', 'inc h', 'ld a, [h_currentspriteoffset]',
        'add 8', 'ld l, a', 'call random', 'ld a, [hrandomadd]',
        'and $7f', 'ld [hl], a', 'scf', 'ret',
    ]):
        errors.append('Johto patrol blocked path no longer matches Kanto delayed-step/carry contract')
    if not blocked[-2:] == ['scf', 'ret']:
        errors.append('Johto patrol blocked path must set carry immediately before returning')
    try:
        for name, (_start, _radius, bounds) in table.items():
            lo, hi = divmod(bounds, 256)
            for next_cell in range(256):
                actual = _compare_destination(compare, next_cell, lo, hi)
                expected = '.allow' if lo <= next_cell <= hi else '.blocked'
                if actual != expected:
                    errors.append(
                        f'{name}: patrol compare branch incorrect at next=${next_cell:02x},'
                        f' expected {expected} for ${lo:02x}..${hi:02x}, got {actual}'
                    )
                    break
    except ValueError as exc:
        errors.append(f'Johto patrol compare assembly cannot be semantically audited: {exc}')
    return errors


def _without_comment(line: str) -> str:
    return line.split(";", 1)[0].strip()


def _int_token(value: str) -> int:
    value = value.strip()
    if value.startswith("$"):
        return int(value[1:], 16)
    if value.lower().startswith("0x"):
        return int(value, 16)
    return int(value, 10)


def _gold_objects(text: str, label: str, errors: list[str]) -> dict[tuple[int, int], list[list[str]]]:
    objects: dict[tuple[int, int], list[list[str]]] = {}
    for line_no, raw in enumerate(text.splitlines(), 1):
        line = _without_comment(raw)
        if not re.match(r"^object_event\s+", line):
            continue
        fields = [field.strip() for field in re.sub(r"^object_event\s+", "", line).split(",")]
        if len(fields) < 6:
            errors.append(f"{label}:{line_no}: malformed Gold object_event; need coordinates, movement and two range fields")
            continue
        try:
            coord = (_int_token(fields[0]), _int_token(fields[1]))
        except ValueError:
            errors.append(f"{label}:{line_no}: unsupported Gold NPC coordinate {fields[0:2]}")
            continue
        objects.setdefault(coord, []).append(fields)
    return objects


def _rpp_objects(text: str, label: str, errors: list[str]) -> dict[tuple[int, int], list[list[str]]]:
    objects: dict[tuple[int, int], list[list[str]]] = {}
    for line_no, raw in enumerate(text.splitlines(), 1):
        line = _without_comment(raw)
        if not re.match(r"^object\s+", line):
            continue
        fields = [field.strip() for field in re.sub(r"^object\s+", "", line).split(",")]
        if len(fields) < 6:
            errors.append(f"{label}:{line_no}: malformed RPP object; expected sprite,x,y,movement,axis-or-facing,text-id")
            continue
        try:
            coord = (_int_token(fields[1]), _int_token(fields[2]))
        except ValueError:
            errors.append(f"{label}:{line_no}: unsupported RPP NPC coordinate {fields[1:3]}")
            continue
        # Keep the original line number for useful diagnostics without changing
        # the common field layout used by the comparator.
        fields.append(str(line_no))
        objects.setdefault(coord, []).append(fields)
    return objects


def _movement_issues(gold_fields: list[str], rpp_fields: list[str], label: str,
                     coord: tuple[int, int], patrol_entry: tuple[int, int, int] | None) -> list[str]:
    issues: list[str] = []
    gold_mode = gold_fields[3]
    rpp_mode = rpp_fields[3].upper()
    rpp_arg = rpp_fields[4].upper()
    x, y = coord

    if gold_mode in STANDING:
        expected_facing = STANDING[gold_mode]
        if rpp_mode != "STAY" or rpp_arg != expected_facing:
            issues.append(
                f"{label} ({x},{y}): Gold {gold_mode} requires RPP STAY,{expected_facing}; "
                f"found {rpp_mode},{rpp_arg}"
            )
        return issues

    if gold_mode in SPECIAL_EQUIVALENCES:
        expected_mode, expected_arg = SPECIAL_EQUIVALENCES[gold_mode]
        if rpp_mode != expected_mode or rpp_arg != expected_arg:
            issues.append(
                f"{label} ({x},{y}): Gold {gold_mode} requires RPP {expected_mode},{expected_arg}; "
                f"found {rpp_mode},{rpp_arg}"
            )
        return issues

    if gold_mode in WALKING:
        expected_axis = WALKING[gold_mode]
        if rpp_mode != "WALK":
            issues.append(
                f"{label} ({x},{y}): Gold {gold_mode} requires RPP WALK axis={expected_axis}; "
                f"found {rpp_mode},{rpp_arg}"
            )
        else:
            try:
                actual_axis = _int_token(rpp_arg)
            except ValueError:
                actual_axis = -999
            if actual_axis != expected_axis:
                issues.append(
                    f"{label} ({x},{y}): Gold {gold_mode} requires RPP WALK axis={expected_axis}; "
                    f"found axis token {rpp_arg}"
                )
        try:
            range_x, range_y = _int_token(gold_fields[4]), _int_token(gold_fields[5])
        except ValueError:
            issues.append(
                f"{label} ({x},{y}): cannot parse Gold patrol range {gold_fields[4:6]}"
            )
        else:
            start = x if expected_axis == 2 else y
            radius = range_x if expected_axis == 2 else range_y
            if (expected_axis == 2 and range_y != 0) or (expected_axis == 1 and range_x != 0):
                issues.append(f"{label} ({x},{y}): two-axis Gold patrol cannot use the one-axis RPP limit")
            if patrol_entry is None:
                if range_x or range_y:
                    issues.append(f"{label} ({x},{y}): Gold {gold_mode} patrol range=({range_x},{range_y}) "
                                  "has no reviewed Johto runtime patrol-bound entry")
            elif patrol_entry != (start, radius, (start + 4 - radius) * 256 + (start + 4 + radius)):
                issues.append(f"{label} ({x},{y}): Gold patrol origin={start}, radius={radius}; "
                              f"Johto runtime bound table contains {patrol_entry}")
        return issues

    issues.append(
        f"{label} ({x},{y}): unsupported Gold movement behavior {gold_mode}; "
        "add a reviewed RPP equivalence before this NPC can pass movement audit"
    )
    return issues


def audit(root: Path, gold: Path, overrides: Mapping[str, str] | None = None) -> list[str]:
    """Compare every current Johto RPP object against its Gold map counterpart.

    `overrides` supports deterministic fault injection: normal RPP paths as keys,
    and `gold/<relative path>` for Gold-source mutations. It does not modify files.
    """
    root, gold = Path(root), Path(gold)
    overrides = overrides or {}
    errors: list[str] = []
    object_dir = root / "data/mapObjects"
    if not object_dir.is_dir():
        return ["data/mapObjects directory is missing"]

    map_files = sorted(object_dir.glob("Johto*.asm"))
    if not map_files:
        return ["no Johto map-object files found; movement audit cannot run"]

    runtime_rel = "engine/overworld/johto_npc_patrol_bounds.asm"
    runtime_path = root / runtime_rel
    if runtime_rel in overrides:
        runtime = overrides[runtime_rel]
    elif runtime_path.is_file():
        runtime = runtime_path.read_text(encoding="utf-8")
    else:
        runtime = ""
        errors.append(f"{runtime_rel}: runtime patrol-bound table missing")
    patrol_table, parse_errors = parse_patrol_table(runtime)
    errors.extend(parse_errors)
    if runtime:
        errors.extend(validate_runtime_patrol_contract(runtime, patrol_table))
    main_path = root / "main.asm"
    if main_path.is_file() or "main.asm" in overrides:
        main_asm = overrides.get("main.asm", main_path.read_text() if main_path.is_file() else "")
        if not re.search(r'(?m)^\s*SECTION\s+"Johto NPC Patrol Bounds",\s*ROMX\s*$', main_asm) or not re.search(
            r'(?m)^\s*INCLUDE\s+"engine/overworld/johto_npc_patrol_bounds.asm"\s*$', main_asm
        ):
            errors.append("main.asm: Johto patrol helper ROMX SECTION/INCLUDE is missing")
    engine_path = root / "engine/overworld/movement.asm"
    if engine_path.is_file():
        engine = overrides.get("engine/overworld/movement.asm", engine_path.read_text())
        can_walk = engine.split("CanWalkOntoTile:", 1)[-1].split("GetTileSpriteStandsOn:", 1)[0]
        opcodes = _asm_ops(can_walk)
        expected_hook = ['.notscripted', 'push bc', 'callab checkjohtonpcpatrolbounds',
                         'pop bc', 'ret c', 'ld a, [wtilesetcollisionptr]']
        if not _ordered_ops(opcodes, expected_hook):
            errors.append("engine/overworld/movement.asm: Johto patrol check is not on Kanto NPC movement path")
    table_keys_seen: set[str] = set()
    for rpp_path in map_files:
        stem = rpp_path.stem
        gold_name = GOLD_MAP_ALIASES.get(stem, stem.removeprefix("Johto"))
        gold_rel = f"maps/{gold_name}.asm"
        gold_path = gold / gold_rel
        if not gold_path.is_file() and "gold/" + gold_rel not in overrides:
            errors.append(
                f"{rpp_path.relative_to(root).as_posix()}: Gold source {gold_rel} is missing; "
                "add an explicit reviewed name alias in GOLD_MAP_ALIASES (do not silently skip)"
            )
            continue
        try:
            gold_text = overrides.get("gold/" + gold_rel, gold_path.read_text(encoding="utf-8") if gold_path.is_file() else "")
            rpp_text = overrides.get(rpp_path.relative_to(root).as_posix(), rpp_path.read_text(encoding="utf-8"))
        except OSError as exc:
            errors.append(f"{rpp_path.name}: cannot read movement source: {exc}")
            continue

        gold_by_coord = _gold_objects(gold_text, gold_rel, errors)
        rpp_by_coord = _rpp_objects(rpp_text, rpp_path.relative_to(root).as_posix(), errors)
        label = rpp_path.relative_to(root).as_posix()
        map_table_key = PATROL_MAP_IDS.get(stem)
        if map_table_key is not None:
            table_keys_seen.add(map_table_key)
        walk_count = sum(r[3].upper() == "WALK" for rows in rpp_by_coord.values() for r in rows)
        if map_table_key is not None and walk_count != 1:
            errors.append(f"{label}: patrol-map contract requires exactly one WALK NPC, found {walk_count}")
        for coord, rpp_rows in rpp_by_coord.items():
            gold_rows = gold_by_coord.get(coord, [])
            if not gold_rows:
                errors.append(
                    f"{label} ({coord[0]},{coord[1]}): RPP NPC has no Gold object_event at the same coordinate; "
                    "movement parity cannot be checked (review the source mapping or custom-NPC contract)"
                )
                continue
            for index, rpp_row in enumerate(rpp_rows):
                if index >= len(gold_rows):
                    errors.append(
                        f"{label} ({coord[0]},{coord[1]}): RPP has more NPC objects than Gold at this coordinate; "
                        "movement parity cannot be paired"
                    )
                    continue
                entry = patrol_table.get(map_table_key) if map_table_key else None
                errors.extend(_movement_issues(gold_rows[index], rpp_row, label, coord, entry))
    # A removed/misnamed runtime row must fail, and a row that no current
    # activated map references must not silently remain active.
    for key in sorted(table_keys_seen - patrol_table.keys()):
        errors.append(f"{runtime_rel}: missing active patrol entry {key}")
    for key in sorted(patrol_table.keys() - table_keys_seen):
        errors.append(f"{runtime_rel}: unreferenced patrol entry {key}")
    return errors


def main() -> int:
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rpp", type=Path, required=True)
    parser.add_argument("--gold", type=Path, required=True)
    args = parser.parse_args()
    errors = audit(args.rpp, args.gold)
    print(json.dumps({
        "status": "PASS" if not errors else "FAIL",
        "maps_scanned": len(list((args.rpp / "data/mapObjects").glob("Johto*.asm"))),
        "errors": errors,
        "built_rom": False,
        "phone_verified": False,
    }, ensure_ascii=False, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
