#!/usr/bin/env python3
"""Static, fail-closed Johto Surf preflight; never builds or edits a ROM.

Read the tracked source-water contract, compare it to actual game entrypoints,
check that non-water continues through the original *shore* passability scan,
and optionally compare all water cells against the supplied Gold .blk/tilecoll.

Scope: recognized, registered map-local water helpers. Adding a new map-local
water helper without a source contract fails instead of silently treating it as tested.
This does not prove ROM linkage, CPU register state at runtime or phone behavior.
"""
from __future__ import annotations

import argparse
from collections import deque
import json
import os
from pathlib import Path
import re
import sys

ENTRYPOINTS = {
    'engine/overworld/field_moves.asm': 'IsSurfTile',
    'engine/items/items.asm': 'IsNextTileShoreOrWater',
    'home/overworld.asm': 'CollisionCheckOnWater',
}
CONTRACT = 'tools/johto_surf_contracts.json'


def code_only(source: str) -> str:
    return '\n'.join(line.split(';', 1)[0].strip()
                     for line in source.splitlines())


def local_water_helpers(source: str) -> set[str]:
    return set(re.findall(r'\bcallab\s+(\w*WaterAhead)\b', code_only(source)))


def routine(source: str, label: str) -> str:
    """Limit inspection to one global label without relying on colon style."""
    raw = code_only(source)
    header = re.search(rf'(?m)^{re.escape(label)}::?\s*$', raw)
    if not header:
        raise ValueError(f'global label {label} missing')
    tail = raw[header.end():]
    next_global = re.search(r'(?m)^[A-Za-z_]\w*::?\s*$', tail)
    return tail[:next_global.start()] if next_global else tail


def water_coordinates(source: str, start: str, end: str) -> set[tuple[int, int]]:
    raw = code_only(source)
    m = re.search(rf'(?ms)^{re.escape(start)}::\s*$(.*?)^{re.escape(end)}::\s*$', raw)
    if not m:
        raise ValueError(f'missing water table {start}/{end}')
    rows = []
    for line in m.group(1).splitlines():
        if not line:
            continue
        # Terminator is required, preventing over-read into the next ASM data.
        if re.fullmatch(r'db\s+\$ff', line, re.I):
            continue
        entry = re.fullmatch(r'db\s+(\d+)\s*,\s*(\d+)', line)
        if not entry:
            raise ValueError(f'unknown water table record: {line}')
        rows.append((int(entry.group(1)), int(entry.group(2))))
    if 'db $ff' not in m.group(1).lower():
        raise ValueError(f'{start} lacks $ff terminator')
    if len(rows) != len(set(rows)):
        raise ValueError(f'{start} duplicate water coordinates')
    return set(rows)


def shore_branch_valid(overworld: str, helper: str) -> bool:
    """Check both carry polarity and the C register passed to shoreline scan.

    Match until the next local label, so a register reload in a *different*
    path does not accidentally satisfy this check. Allows a future explicit
    unsafe-edge guard between the water query and shoreline scan.
    """
    block = routine(overworld, 'CollisionCheckOnWater')
    match = re.search(rf'(?m)^callab\s+{re.escape(helper)}\s*$', block)
    if not match:
        return False
    tail = block[match.end():]
    until_label = re.split(r'(?m)^\.[A-Za-z_]\w*:?\s*$', tail, maxsplit=1)[0]
    instructions = [s for s in until_label.splitlines() if s]
    if not instructions or not re.fullmatch(r'(?:jp|jr) c, \.noCollision', instructions[0]):
        return False
    # A non-water path can check additional unsafe edges, but must never
    # jump to the shore scan without first restoring the actual front tile.
    scan = [i for i, s in enumerate(instructions)
            if re.fullmatch(r'(?:jp|jr) \.checkIfNextTileIsPassable', s)]
    if len(scan) != 1 or scan[0] < 3:
        return False
    i = scan[0]
    return (instructions[i - 2] == 'ld a, [wTileInFrontOfPlayer]' and
            instructions[i - 1] == 'ld c, a')



def gold_shore_floor_mismatch(root: Path, gold: Path, entry: dict) -> set[tuple[int, int]]:
    """Gold FLOOR cells sharing a component with landable water-edge FLOOR,
    but rendered by compact tiles absent from current passability whitelist.

    This is deliberately separate from Gold WATER detection. It finds the
    screenshot failure: map-local FLOOR must remain walkable after Surf.
    """
    from johto_gold_door_audit import GoldCollisionIndex
    index = GoldCollisionIndex(gold)
    gold_cells = index.cells(entry['gold_map'])
    if entry['gold_map'] == 'CherrygroveCity':
        layout = 'maps/johto_pilot/CherrygroveCity.runtime.blk'
    elif entry['gold_map'] == 'VioletCity':
        layout = 'maps/johto_pilot/VioletCity.runtime.blk'
    else:
        layout = entry.get('runtime_map')
    if not layout:
        raise ValueError(f"{entry['gold_map']}: missing runtime map for shore audit")
    blocks = (root / layout).read_bytes()
    metatiles = (root / 'gfx/blocksets/johto.bst').read_bytes()
    allowed = set((root / 'gfx/tilesets/johto.tilecoll').read_bytes()) - {0xff}
    width = entry['width_cells'] // 2
    height = entry['height_cells'] // 2
    if len(blocks) != width * height or len(metatiles) % 16:
        raise ValueError('invalid runtime map or blockset size for shore audit')
    failed_floor = set()
    for (x, y), cell in gold_cells.items():
        if cell['role'] != 'FLOOR':
            continue
        block = blocks[(y // 2) * width + (x // 2)]
        row = (y % 2) * 2
        col = (x % 2) * 2
        visual = {metatiles[block * 16 + (row + dy) * 4 + col + dx]
                  for dy in range(2) for dx in range(2)}
        if not (visual & allowed):
            failed_floor.add((y, x))
    def neighbors(y, x):
        return ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1))
    # Only water-exposed components are relevant to this Surf audit; a
    # disconnected cliff wall is not automatically a legal shore.
    seeds = {pos for pos in failed_floor
             if any(gold_cells.get((nx, ny), {}).get('role') == 'WATER'
                    for ny, nx in neighbors(*pos))}
    exposed = set(seeds)
    pending = deque(seeds)
    while pending:
        y, x = pending.popleft()
        for pos in neighbors(y, x):
            if pos in failed_floor and pos not in exposed:
                exposed.add(pos)
                pending.append(pos)
    return exposed


def validate_shore_exception(root: Path, entry: dict, source: str, overworld: str,
                             gold: Path | None) -> list[str]:
    errors = []
    exception = entry.get('shore_floor_exception')
    expected = set()
    if gold:
        try:
            expected = gold_shore_floor_mismatch(root, gold, entry)
        except (OSError, KeyError, ValueError, IndexError) as exc:
            errors.append(f"{entry['gold_map']}: shore geometry audit failed: {exc}")
            return errors
    if not exception:
        if expected:
            errors.append(f"{entry['gold_map']}: MISSING_SHORE_PASSABILITY: "
                          f"{len(expected)} Gold FLOOR cells touch water but runtime "
                          "collision blocks them; register map-local shore-floor exception")
        return errors
    helper = exception['helper']
    try:
        coords = water_coordinates(source, exception['table'], exception['table_end'])
    except (KeyError, ValueError) as exc:
        return [f'{helper}: invalid shore-floor table: {exc}']
    if len(coords) != exception['expected_cells']:
        errors.append(f'{helper}: wrong shore-floor cell count')
    if any(not(0 <= y < entry['height_cells'] and 0 <= x < entry['width_cells'])
           for y, x in coords):
        errors.append(f'{helper}: shore-floor coordinates outside map')
    if gold and coords != expected:
        errors.append(f'{helper}: Gold FLOOR shoreline mismatch: '
                      f'{len(coords-expected)} forbidden, {len(expected-coords)} missing')
    try:
        body = routine(source, helper)
        for needle in ('call '+entry['map_scope_predicate'],
                       'ld hl, '+exception['table'],
                       'wXCoord', 'wYCoord', 'SPRITE_FACING_DOWN',
                       'SPRITE_FACING_UP', 'SPRITE_FACING_LEFT',
                       'SPRITE_FACING_RIGHT'):
            if needle not in body:
                errors.append(f'{helper}: missing active-map/coordinate/lookup guard {needle}')
        for needle in ('push bc', 'push de', 'push hl', 'pop hl', 'pop de', 'pop bc'):
            if needle not in body:
                errors.append(f'{helper}: missing register preservation: {needle}')
    except ValueError as exc:
        errors.append(str(exc))
    surf = routine(overworld, 'CollisionCheckOnWater')
    if not re.search(rf'(?m)^callab\s+{re.escape(entry["water_helper"])}\s*\n'
                     rf'jp c, \.noCollision\s*\ncallab\s+{re.escape(helper)}\s*\n'
                     rf'jp c, \.stopSurfing\s*$', surf):
        errors.append(f'{helper}: missing disembark path for Gold FLOOR shore')
    land = routine(overworld, 'CheckTilePassable')
    if not re.search(rf'(?m)^cp \$3c\s*\njr nz, \.normalTilePassability\s*\n'
                     rf'callab\s+{re.escape(helper)}\s*\n'
                     rf'jr nc, \.normalTilePassability\s*\nand a\s*\nret\s*$', land):
        errors.append(f'{helper}: missing normal walking allowance on shore platform')
    if '$3c' in [f'${x:02x}' for x in
                   (root / 'gfx/tilesets/johto.tilecoll').read_bytes()]:
        errors.append(f'{helper}: forbidden global passability expansion for $3c')
    return errors


def check_project(root: Path, contract: dict, gold: Path | None = None) -> list[str]:
    errors = []
    if contract.get('schema_version') != 1 or not isinstance(contract.get('maps'), list):
        return ['unsupported or missing source Surf contract schema']
    maps = contract['maps']
    declared = set()
    for entry in maps:
        helper = entry.get('water_helper')
        if not isinstance(helper, str) or not re.fullmatch(r'\w+WaterAhead', helper):
            errors.append(f'invalid helper in contract: {helper!r}')
            continue
        if helper in declared:
            errors.append(f'duplicate water helper registration: {helper}')
        declared.add(helper)

    # When a ROM bank has no room for another farcall, a registered
    # entrypoint_helper may forward to the map helper *in its own ROMX bank*.
    # The branch and carry must still be verified, not blindly trusted.
    delegated = {entry['water_helper']: entry['entrypoint_helper']
                 for entry in maps if entry.get('entrypoint_helper')}
    endpoints = {delegated.get(helper, helper) for helper in declared}
    texts = {}
    for filename in ENTRYPOINTS:
        try:
            texts[filename] = (root / filename).read_text(encoding='utf8')
        except OSError as exc:
            errors.append(f'{filename}: {exc}')
    if len(texts) != len(ENTRYPOINTS):
        return errors
    for filename, label in ENTRYPOINTS.items():
        try:
            body = routine(texts[filename], label)
        except ValueError as exc:
            errors.append(f'{filename}: {exc}')
            continue
        actual = local_water_helpers(body)
        missing = endpoints - actual
        undeclared = actual - declared  # the water-movement path may query routes directly
        for helper in sorted(missing):
            errors.append(f'{filename}::{label}: missing {helper} call')
        for helper in sorted(undeclared):
            errors.append(f'{filename}::{label}: unregistered {helper} (add contract first)')
    # The two entry paths use different carry contracts from the active
    # surf query; a route that calls the helper but flips the branch is broken.
    carry_contracts = {
        'engine/overworld/field_moves.asm': r'ret c',
        'engine/items/items.asm': r'(?:jr|jp) c, \.shoreOrWater',
    }
    for entry in maps:
        helper = entry.get('water_helper')
        if helper not in declared:
            continue
        endpoint = delegated.get(helper, helper)
        for filename, expected in carry_contracts.items():
            body = routine(texts[filename], ENTRYPOINTS[filename])
            if not re.search(rf'(?m)^callab\s+{re.escape(endpoint)}\s*\n{expected}\s*$', body):
                errors.append(f'{filename}: {helper} carry polarity/dispatch incorrect')

    for entry in maps:
        helper = entry.get('water_helper')
        if helper not in declared:
            continue
        try:
            asm = (root / entry['routine_file']).read_text(encoding='utf8')
            body = routine(asm, helper)
            # A bank-local gateway must explicitly forward with unchanged
            # carry and without allowing non-water to short-circuit other maps.
            if helper in delegated:
                gateway = delegated[helper]
                if gateway not in declared or entry['routine_file'] != next(
                    (other['routine_file'] for other in maps
                     if other.get('water_helper') == gateway), None
                ):
                    errors.append(f'{helper}: invalid bank-local Surf gateway {gateway}')
                else:
                    gateway_body = routine(asm, gateway)
                    if not re.search(rf'(?m)^call\s+{re.escape(helper)}\s*\nret c\s*$',
                                     gateway_body):
                        errors.append(f'{helper}: missing carry-safe bank-local dispatch in {gateway}')
            predicate = entry['map_scope_predicate']
            if f'call {predicate}' not in body:
                errors.append(f'{helper}: does not invoke map-scope predicate {predicate}')
            predicate_body = routine(asm, predicate)
            for needle in ('wCurMap', 'JOHTO_RUNTIME_MAP_HANDLE',
                           'wCurRegion', 'MAP_REGION_JOHTO', 'wCurLocalMapID',
                           entry['local_id_symbol']):
                if needle not in predicate_body:
                    errors.append(f'{helper}: map-scope predicate {predicate} missing {needle}')
            if entry['representation'] != 'yx_db':
                errors.append(f'{helper}: unrecognized representation {entry["representation"]}')
                continue
            coords = water_coordinates(asm, entry['water_table'], entry['water_end'])
            expected = entry['expected_water_cells']
            if len(coords) != expected:
                errors.append(f'{helper}: {len(coords)} water cells, expected {expected}')
            if any(not (0 <= y < entry['height_cells'] and 0 <= x < entry['width_cells'])
                   for y, x in coords):
                errors.append(f'{helper}: out-of-bounds water coordinate')
            if gold:
                # Reuse the existing Gold asset decoder instead of creating
                # a second interpretation of Gold collision tables.
                from johto_gold_door_audit import GoldCollisionIndex
                index = GoldCollisionIndex(gold)
                source = {(c['y'], c['x']) for c in index.cells(entry['gold_map']).values()
                          if c['role'] == 'WATER'}
                if coords != source:
                    errors.append(f'{helper}: Gold water mismatch: '
                                  f'{len(coords-source)} extra, {len(source-coords)} missing')
        except (KeyError, ValueError, OSError) as exc:
            errors.append(f'{helper}: {exc}')
        if not shore_branch_valid(texts['home/overworld.asm'], helper):
            errors.append(f'{helper}: disembark must restore wTileInFrontOfPlayer '
                          'to C before .checkIfNextTileIsPassable')
        errors.extend(validate_shore_exception(
            root, entry, asm, texts['home/overworld.asm'], gold))

    # A recognized helper appearing in the ASM tree must not evade the audit
    # simply because the contract entry was forgotten.
    for path in (root / 'engine').rglob('*.asm'):
        try:
            labels = set(re.findall(r'(?m)^(\w+WaterAhead)::\s*$',
                                    code_only(path.read_text(encoding='utf8'))))
            for helper in labels - declared:
                if helper.startswith(('Johto', 'IsJohto')):
                    errors.append(f'{path.relative_to(root)}: undeclared water helper {helper}')
        except OSError as exc:
            errors.append(str(exc))
    return errors


def main(argv: list[str] | None = None) -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    cli.add_argument('--gold', type=Path, default=Path(os.environ['GOLD_SOURCE_ROOT'])
                     if os.environ.get('GOLD_SOURCE_ROOT') else None)
    args = cli.parse_args(argv)
    root = args.root.resolve()
    try:
        contract = json.loads((root / CONTRACT).read_text(encoding='utf8'))
        errors = check_project(root, contract, args.gold)
    except (OSError, ValueError) as exc:
        errors = [str(exc)]
    if errors:
        for err in errors:
            print('FAIL:', err, file=sys.stderr)
        return 1
    print('PASS: Surf entrypoints, map scope, water table and shore register flow')
    if args.gold:
        print('PASS: complete Gold WATER cell coordinate comparison')
    else:
        print('NOTE: Gold cross-check not run (use --gold /path/to/pokegold)')
    print('NOTE: Static preflight only; build/ROM/phone behavior not checked')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
