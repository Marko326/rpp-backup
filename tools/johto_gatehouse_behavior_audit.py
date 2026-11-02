#!/usr/bin/env python3
"""Audit Gold gatehouse collision semantics and current stable-ID Johto activation contracts.

The Gold inventory is sourced only from the supplied MUS-1.0.1 tree. Current
RPP gate activation is read from its stable-ID table and explicit per-gate contracts. This is a static audit: a
Gold role/contract match does not prove a built ROM behaves correctly.
"""
from __future__ import annotations
import argparse
import json
import re
from collections import Counter
from pathlib import Path

from johto_gold_door_audit import (
    GATE_CARPETS, GATE_SOLID_DOORS, GoldCollisionIndex, gold_gate_approach_rule,
    gold_gate_arrival_step, inspect as inspect_gold,
)
from johto_warp_arrival_audit import audit as audit_warp_arrival, _gold_warp_events
from johto_gatehouse_shared_runtime_303 import scan as scan_shared303, structural_check as check_shared303
from johto_gatehouse_step_trace_308 import (
    DIRECTIONS, simulate_south_gate, simulate_park_east,
    simulate_legacy_gate_dispatch, simulate_legacy_gate_passability,
)

CONTRACT_PATH = 'tools/johto_pilot_door_contracts.json'
EXPECTED_ROLES = {
    'DOOR': 26,
    'WARP_CARPET_DOWN': 30,
    'WARP_CARPET_LEFT': 22,
    'WARP_CARPET_RIGHT': 22,
}


def _check(checks: list[dict], errors: list[str], name: str, ok: bool, detail: str) -> None:
    checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
    if not ok:
        errors.append(f'{name}: {detail}')


def _constants(root: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    for relative in ('constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm'):
        text = (root / relative).read_text(encoding='utf-8')
        for name, value in re.findall(r'(?m)^\s*DEF\s+([A-Za-z_][A-Za-z_0-9]*)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)\b', text):
            result[name] = int(value[1:], 16) if value.startswith('$') else int(value)
    return result


def _active_stable_ids(root: Path) -> set[int]:
    constants = _constants(root)
    slot_text = (root / 'data/johto_stable_id_slots.asm').read_text(encoding='utf-8')
    num_match = re.search(r'(?m)^\s*DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)\b',
                          (root / 'constants/region_map_constants.asm').read_text(encoding='utf-8'))
    if not num_match:
        raise ValueError('NUM_JOHTO_ACTIVE_MAPS missing')
    active_count = int(num_match[1])
    active: set[int] = set()
    rows = 0
    for line in slot_text.splitlines():
        code, sep, comment = line.partition(';')
        range_match = re.search(r'\$([0-9a-fA-F]{2})\s*-\s*\$([0-9a-fA-F]{2})', comment)
        m = re.match(r'\s*db\s+(.+)$', code)
        if not range_match or not m:
            continue
        start, end = int(range_match[1], 16), int(range_match[2], 16)
        tokens = [x.strip() for x in m[1].split(',')]
        if len(tokens) != end - start + 1:
            raise ValueError(f'stable slot row length mismatch at {comment.strip()}')
        rows += len(tokens)
        for index, token in enumerate(tokens):
            if token == 'JOHTO_INVALID_ACTIVE_SLOT':
                continue
            if token in constants:
                slot = constants[token]
            elif token.startswith('$'):
                slot = int(token[1:], 16)
            elif token.isdecimal():
                slot = int(token)
            else:
                raise ValueError(f'unresolved active slot token: {token}')
            if slot < active_count:
                active.add(start + index)
    if rows != 256:
        raise ValueError(f'stable slot table has {rows} entries, expected 256')
    return active


def _gate_ids(root: Path) -> dict[int, list[str]]:
    constants = _constants(root)
    result: dict[int, list[str]] = {}
    for name, value in constants.items():
        if 'GATE' in name and name.endswith('_LOCAL_ID'):
            result.setdefault(value, []).append(name)
    return result



def _simulate_gate_asm_step(source: str, *, local_id: int, x: int, y: int,
                            direction: str, roles: bytes, constants: dict[str, int],
                            western: bool) -> tuple[int, bool]:
    """Execute the small real ASM collision routine, not a copied Python policy.

    Only instructions used by these two gatehouse routines are supported;
    unexpected instructions fail the audit rather than being ignored. The sole
    mocked call is the mature role lookup, which reads the shipped role bytes.
    This is a source-level instruction simulation, not an emulator/ROM build.
    """
    labels: dict[str, int] = {}
    ins: list[tuple[str, str]] = []
    for raw_line in source.splitlines():
        line = raw_line.split(';', 1)[0].strip()
        if not line:
            continue
        if re.fullmatch(r'\.[A-Za-z_][A-Za-z_0-9]*:?', line):
            labels[line.rstrip(':')] = len(ins)
        else:
            op, _, operand = line.partition(' ')
            ins.append((op.lower(), operand.strip()))
    if not ins or not labels:
        raise ValueError('empty or unparseable gate ASM')

    offsets = {'UP': (0, -1), 'DOWN': (0, 1), 'LEFT': (-1, 0), 'RIGHT': (1, 0)}
    if direction not in offsets:
        raise ValueError(f'invalid direction {direction}')
    dx, dy = offsets[direction]
    values = {
        '[wCurLocalMapID]': local_id, '[wXCoord]': x, '[wYCoord]': y,
        '[wPlayerDirection]': 'PLAYER_DIR_' + direction,
        '[wWalkBikeSurfState]': 0,
    }

    def val(token: str):
        token = token.strip()
        if token in values:
            return values[token]
        if token in ('a', 'e'):
            return {'a': a, 'e': e}[token]
        if token in constants:
            return constants[token]
        if token.startswith('PLAYER_DIR_'):
            return token
        if token.isdecimal():
            return int(token)
        if token.startswith('$'):
            return int(token[1:], 16)
        raise ValueError(f'unsupported gate ASM operand: {token}')

    a, e, zero, carry, pc = 0, 0, False, False, 0
    for _ in range(300):
        if not 0 <= pc < len(ins):
            raise ValueError(f'gate ASM branched outside helper: {pc}')
        op, operand = ins[pc]
        pc += 1
        if op == 'ld':
            reg, rhs = (t.strip() for t in operand.split(',', 1))
            if reg == 'a':
                a = val(rhs)
            elif reg == 'e':
                e = val(rhs)
            else:
                raise ValueError(f'gate ASM writes unexpected register: {reg}')
        elif op == 'cp':
            target = val(operand)
            zero = a == target
            carry = (a < target) if isinstance(a, int) and isinstance(target, int) else False
        elif op == 'and' and operand == 'a':
            zero = a == 0
            carry = False
        elif op == 'scf' and not operand:
            carry = True
        elif op in ('jr', 'jp'):
            parts = [t.strip() for t in operand.split(',')]
            if len(parts) == 1:
                yes, target = True, parts[0]
            elif len(parts) == 2:
                condition, target = parts
                yes = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}.get(condition)
                if yes is None:
                    raise ValueError(f'unsupported gate ASM branch: {operand}')
            else:
                raise ValueError(f'invalid gate ASM jump: {operand}')
            if yes:
                if target not in labels:
                    raise ValueError(f'undefined gate ASM branch: {target}')
                pc = labels[target]
        elif op == 'call' and western and operand == 'JohtoSouthSpatialRoleAhead':
            tx, ty = x + dx, y + dy
            e = roles[ty * 10 + tx] if 0 <= tx < 10 and 0 <= ty < 8 else 1
        elif op == 'ret' and not operand:
            return e, carry
        else:
            raise ValueError(f'unsupported gate ASM instruction: {op} {operand}')
    raise ValueError('gate ASM did not terminate in 300 steps')


def _scan_horizontal_gate_moves(source: str, *, stable_id: int, roles: bytes,
                                constants: dict[str, int], western: bool) -> tuple[int, list[str]]:
    """Check all legal on-map steps, including all 12 inbound carpet moves."""
    failures: list[str] = []
    checked = 0
    carpet = {(x, y) for x in (0, 9) for y in (4, 5)}
    deltas = {'UP': (0, -1), 'DOWN': (0, 1), 'LEFT': (-1, 0), 'RIGHT': (1, 0)}
    for y in range(8):
        for x in range(10):
            if roles[y * 10 + x] != 0 and (x, y) not in carpet:
                continue   # players cannot be standing inside solid walls
            for direction, (dx, dy) in deltas.items():
                tx, ty = x + dx, y + dy
                if not (0 <= tx < 10 and 0 <= ty < 8):
                    continue   # outdoor seam / Warp collision is another guard
                target = (tx, ty)
                expected = roles[ty * 10 + tx] == 0 or target in carpet
                e, carry = _simulate_gate_asm_step(
                    source, local_id=stable_id, x=x, y=y, direction=direction,
                    roles=roles, constants=constants, western=western)
                actual = (e == 0) if western else (carry and e == 0 or
                           (not carry and roles[ty * 10 + tx] == 0))
                checked += 1
                if bool(actual) != bool(expected):
                    failures.append(f'({x},{y}) {direction} -> ({tx},{ty}): '
                                    f'expected={expected}, got={actual} (e={e}, C={carry})')
    return checked, failures


# Gold's original door/carpet collision roles are traversable floor cells;
# triggering a Warp is a separate direction/edge decision. PCs, counters and
# walls are never floors, even when their 8x8 graphics look walkable.
GATE_WALKABLE_GOLD_ROLES = frozenset({'FLOOR', 'DOOR'}) | GATE_CARPETS


def _audit_gatehouse_full_walk_grid(*, gold_index: GoldCollisionIndex, gold_map: str,
                                    stable_id: int, strategy: str,
                                    descriptor: tuple[str, int, int] | None,
                                    read_bytes, passable_tiles: set[int],
                                    gate_blockset: bytes) -> tuple[int, int, list[str]]:
    """Compare *every* interior cell and legal neighbouring step with Gold.

    This decodes the selected RPP collision DATA backend, not the ASM CPU:
    legacy gates use their real lower-left 8x8 Gate_Coll probe; south gates
    use their own Gold role grid; Park East uses its separately accepted 2B/row
    blocking mask, with its four carpet exceptions.  The result does NOT prove
    source dispatch, outward Warp timing, or actual phone/ROM behaviour.
    """
    if descriptor is None:
        return 0, 0, ['missing runtime descriptor for full-grid audit']
    _, block_width, block_height = descriptor
    width, height = block_width * 2, block_height * 2
    original = gold_index.cells(gold_map)
    if len(original) != width * height or any(
            (x, y) not in original for y in range(height) for x in range(width)):
        return 0, 0, [f'Gold/RPP room dimensions differ: {width}x{height}']

    if strategy == 'legacy_gate_tilecoll':
        blocks = read_bytes(f'maps/johto_pilot/{gold_map}.runtime.blk')
        if len(blocks) != block_width * block_height:
            return 0, 0, ['legacy block map has incorrect dimensions']

        def walkable(x: int, y: int) -> bool:
            block = blocks[(y // 2) * block_width + x // 2]
            # 32x32 block contains sixteen 8x8 tiles. The legacy reader
            # samples the bottom-left tile of the target 16x16 quadrant.
            offset = block * 16 + ((y % 2) * 2 + 1) * 4 + (x % 2) * 2
            if offset >= len(gate_blockset):
                raise ValueError('legacy block points beyond JOHTO_GATE blockset')
            return gate_blockset[offset] in passable_tiles

    elif strategy == 'south_gold_role_grid':
        roles = read_bytes(f'maps/johto_pilot/{gold_map}.roles.bin')
        if len(roles) != width * height:
            return 0, 0, ['south role grid has incorrect dimensions']

        def walkable(x: int, y: int) -> bool:
            return roles[y * width + x] == 0

    elif strategy == 'park_east_mature_helper':
        # This is intentionally NOT Route36NationalParkGate.roles.bin: its
        # legacy converter wrongly blocked several valid indoor floor cells.
        mask = read_bytes(f'maps/johto_pilot/{gold_map}.mature_blocked_mask.bin')
        if (width, height) != (10, 8) or len(mask) != 16:
            return 0, 0, ['Park East needs its independent 10x8, 2-byte/row mask']

        def walkable(x: int, y: int) -> bool:
            if x in (0, 9) and y in (4, 5):
                return True
            return not bool(mask[y * 2 + (x // 8)] & (1 << (x % 8)))

    else:
        return 0, 0, ['unsupported backend for full-grid comparison']

    errors: list[str] = []
    real: dict[tuple[int, int], bool] = {}
    expected: dict[tuple[int, int], bool] = {}
    for y in range(height):
        for x in range(width):
            expected[(x, y)] = original[(x, y)]['role'] in GATE_WALKABLE_GOLD_ROLES
            real[(x, y)] = walkable(x, y)
            if real[(x, y)] != expected[(x, y)]:
                errors.append(f'cell ({x},{y}) Gold {original[(x,y)]["role"]} '
                              f'expected walkable={expected[(x,y)]}, backend={real[(x,y)]}')
    # Test the four cardinal target directions from each actually reachable
    # floor cell, including sideways movement between adjacent carpets.
    moves = 0
    for (x, y), can_stand in expected.items():
        if not can_stand:
            continue
        for direction, (dx, dy) in {'UP':(0,-1), 'DOWN':(0,1),
                                     'LEFT':(-1,0), 'RIGHT':(1,0)}.items():
            target = (x + dx, y + dy)
            if target not in expected:
                continue  # Border/outward Warp is audited separately.
            moves += 1
            if real[target] != expected[target] and len(errors) < 24:
                errors.append(f'move ({x},{y}) {direction} -> {target}: '
                              f'Gold={expected[target]} backend={real[target]}')
    return width * height, moves, errors[:24]



def _audit_gatehouse_source_walk(*, gold_index: GoldCollisionIndex, gold_map: str,
                                 stable_id: int, strategy: str, source: str,
                                 constants: dict[str, int], read_bytes,
                                 blocked_targets: frozenset[tuple[int, int, int]]) -> tuple[int, list[str]]:
    """Trace the actual South/park-East ASM operations for all interior moves.

    The four South gates execute JohtoSouthSpatialRoleAhead's target,
    bounds, grid-index and role lookup. The mature-door fence is a leaf
    backed by the parsed blacklist; on those gate IDs it has no overrides.
    Park East fully executes its mature mask helper, including all bit shifts.
    The external ROM0 dispatch, outdoor Warp, sprite and Bike engines are
    checked by separate static contracts, not emulated here.
    """
    if strategy not in ('south_gold_role_grid', 'park_east_mature_helper'):
        return 0, []
    cells = gold_index.cells(gold_map)
    roles = (read_bytes(f'maps/johto_pilot/{gold_map}.roles.bin')
             if strategy == 'south_gold_role_grid' else b'')
    mask = (read_bytes(f'maps/johto_pilot/{gold_map}.mature_blocked_mask.bin')
            if strategy == 'park_east_mature_helper' else b'')
    checked, failures = 0, []
    for (x, y), cell in cells.items():
        if cell['role'] not in GATE_WALKABLE_GOLD_ROLES:
            continue
        for direction, (dx, dy) in DIRECTIONS.items():
            target = (x + dx, y + dy)
            if target not in cells:
                continue  # crossing the outdoor seam is another pathway
            if strategy == 'south_gold_role_grid':
                result = simulate_south_gate(
                    source, constants=constants, gate_id=stable_id,
                    x=x, y=y, direction=direction, roles=roles,
                    blocked_targets=blocked_targets)
            else:
                result = simulate_park_east(
                    source, constants=constants, x=x, y=y,
                    direction=direction, mask=mask)
            expected = cells[target]['role'] in GATE_WALKABLE_GOLD_ROLES
            checked += 1
            if (result == 0) != expected and len(failures) < 20:
                failures.append(f'ASM ({x},{y}) {direction} -> {target}: '
                                f'Gold walkable={expected}, returned E={result}')
    return checked, failures


def _audit_gatehouse_legacy_source_walk(*, gold_index: GoldCollisionIndex,
                                        gold_map: str, stable_id: int,
                                        descriptor: tuple[str, int, int] | None,
                                        read_bytes, constants: dict[str, int],
                                        gateway_source: str, home_source: str,
                                        player_state_source: str,
                                        tileset_headers: str,
                                        collision_source: str) -> tuple[int, list[str]]:
    """Trace any explicitly profiled legacy Gate_Coll gatehouse.

    Existing IDs 6/19/102 and future Gold-compatible vertical gates share the
    original CheckTilePassable + Gate_Coll backend. The caller must supply an
    explicit JOHTO_GATE descriptor/profile; this function deliberately avoids
    a fixed stable-ID allowlist so future gatehouses can use the same verifier.
    It executes the actual South dispatcher (which must return E=2), then the
    actual CheckTilePassable instruction loop for each reachable room target.
    It does not emulate sprites, the full movement scheduler, door/Warp
    execution or a built ROM.
    """
    errors: list[str] = []
    if descriptor is None or descriptor[0] != 'JOHTO_GATE':
        return 0, [f'legacy gate must retain JOHTO_GATE descriptor, got {descriptor}']
    _, block_width, block_height = descriptor
    width, height = block_width * 2, block_height * 2
    cells = gold_index.cells(gold_map)
    if len(cells) != width * height:
        return 0, [f'legacy Gold dimensions mismatch: {len(cells)} vs {width}x{height}']
    runtime = read_bytes(f'maps/johto_pilot/{gold_map}.runtime.blk')
    blockset = read_bytes('gfx/blocksets/johto_gate.bst')
    passable = read_bytes('gfx/tilesets/gate.tilecoll')
    if len(runtime) != block_width * block_height:
        return 0, [f'legacy runtime block length {len(runtime)} != {block_width}x{block_height}']
    if not blockset or len(blockset) % 16:
        return 0, ['JOHTO_GATE blockset has invalid 16-tile metatile stride']
    if not passable or passable[-1] != 0xff or 0xff in passable[:-1]:
        return 0, ['Gate_Coll list must contain exactly one terminal $ff']

    try:
        dispatch = simulate_legacy_gate_dispatch(
            gateway_source, constants=constants, gate_id=stable_id)
    except ValueError as exc:
        return 0, [f'legacy dispatch ASM trace failed: {exc}']
    if dispatch != 2:
        errors.append(f'legacy dispatch returned E={dispatch}, expected E=2 generic fallback')

    caller = home_source.split('CollisionCheckOnLand::', 1)[-1].split('CheckTilePassable::', 1)[0]
    required_caller = (
        'callab JohtoOverworldSouthLandDecision', 'cp 2',
        'jr z, .nonRoute33Tiles', 'ld hl,TilePairCollisionsLand',
        'call CheckForJumpingAndTilePairCollisions', 'call CheckTilePassable',
    )
    if not all(token in caller for token in required_caller):
        errors.append('CollisionCheckOnLand no longer routes E=2 through legacy tile-pair/CheckTilePassable')
    if 'predef GetTileAndCoordsInFrontOfPlayer' not in home_source.split(
            'CheckTilePassable::', 1)[-1].split('CheckForJumpingAndTilePairCollisions::', 1)[0]:
        errors.append('CheckTilePassable no longer samples the actual front tile')
    for token in ('aCoord 8, 11', 'aCoord 8, 7', 'aCoord 6, 9', 'aCoord 10, 9'):
        if token not in player_state_source:
            errors.append(f'GetTileAndCoordsInFrontOfPlayer probe offset missing: {token}')
    land_pairs = home_source.split('TilePairCollisionsLand::', 1)[-1].split(
        'TilePairCollisionsWater::', 1)[0]
    if 'JOHTO_GATE' in land_pairs:
        errors.append('JOHTO_GATE unexpectedly gained a legacy tile-pair collision override')
    if not re.search(r'(?m)^\s*tileset\s+JohtoGate_Block\s*,\s*JohtoGate_GFX\s*,\s*Gate_Coll\s*,',
                     tileset_headers):
        errors.append('JOHTO_GATE tileset no longer points to Gate_Coll')
    if not re.search(r'(?m)^\s*Gate_Coll::\s*INCBIN\s+"gfx/tilesets/gate\.tilecoll"',
                     collision_source):
        errors.append('Gate_Coll no longer resolves to gfx/tilesets/gate.tilecoll')

    checked = 0
    sampled_targets: set[tuple[int, int]] = set()
    for (x, y), source_cell in cells.items():
        if source_cell['role'] not in GATE_WALKABLE_GOLD_ROLES:
            continue
        for direction, (dx, dy) in DIRECTIONS.items():
            tx, ty = x + dx, y + dy
            if (tx, ty) not in cells:
                continue  # Outdoor seam / outward Warp is audited independently.
            bx, by = tx // 2, ty // 2
            block_id = runtime[by * block_width + bx]
            # GetTileAndCoordsInFrontOfPlayer uses the bottom-left 8x8 tile
            # of the target 16x16 quadrant for all four player facings.
            probe_offset = ((ty & 1) * 2 + 1) * 4 + (tx & 1) * 2
            probe_index = block_id * 16 + probe_offset
            if probe_index >= len(blockset):
                errors.append(f'legacy probe ({tx},{ty}) resolves outside JOHTO_GATE blockset')
                continue
            tile_id = blockset[probe_index]
            try:
                blocked = simulate_legacy_gate_passability(
                    home_source, gate_id=stable_id, tile_id=tile_id,
                    passable_tiles=passable)
            except ValueError as exc:
                errors.append(f'legacy CheckTilePassable trace failed at ({tx},{ty}): {exc}')
                return checked, errors[:24]
            expected = cells[(tx, ty)]['role'] in GATE_WALKABLE_GOLD_ROLES
            if (not blocked) != expected and len(errors) < 24:
                errors.append(f'legacy ASM ({x},{y}) {direction} -> ({tx},{ty}) '
                              f'tile=${tile_id:02x}: Gold walkable={expected}, blocked={blocked}')
            sampled_targets.add((tx, ty))
            checked += 1
    expected_targets = {coord for coord, cell in cells.items()
                        if cell['role'] in GATE_WALKABLE_GOLD_ROLES}
    if not expected_targets.issubset(sampled_targets):
        missing = sorted(expected_targets - sampled_targets)
        errors.append(f'legacy ASM trace did not sample every Gold walkable target cell: {missing[:8]}')
    return checked, errors[:24]


def audit_active_gatehouse_carpet_walkability(
        project: Path, gold: Path, *, text_overrides: dict[str, str] | None = None,
        byte_overrides: dict[str, bytes] | None = None) -> dict:
    """Audit the real walkability path for every currently active gatehouse.

    This deliberately goes beyond checking Warp rows. Each active gatehouse is
    assigned one explicit collision strategy: legacy Gate_Coll probe, the
    South Gold-role grid, the West carpet helper, the Park East mature-mask
    helper, or the East Gate lane helper. Unknown/new gatehouses fail closed.
    """
    root, gold = Path(project).resolve(), Path(gold).resolve()
    text_overrides = text_overrides or {}
    byte_overrides = byte_overrides or {}
    errors: list[str] = []
    results: list[dict] = []
    results_checked: dict[int, int] = {}
    decoded_cells: dict[int, int] = {}
    decoded_moves: dict[int, int] = {}
    asm_traced_moves: dict[int, int] = {}

    def txt(relative: str) -> str:
        return text_overrides[relative] if relative in text_overrides else (root / relative).read_text(encoding='utf-8')

    def raw(relative: str) -> bytes:
        return byte_overrides[relative] if relative in byte_overrides else (root / relative).read_bytes()

    def fail(message: str) -> None:
        errors.append(message)

    registry_path = 'tools/johto_gatehouse_profiles_303.json'
    policy: dict[int, str] = {}


    try:
        constants = _constants(root)
        contract = json.loads(txt(CONTRACT_PATH))
        registry = json.loads(txt(registry_path))
        music = json.loads(txt('tools/johto_gate_music_bike_contracts.json'))
        if registry.get('schema') != 'johto-active-gatehouse-profiles-v1':
            fail('invalid shared gatehouse profile schema')
        profile_rows = registry.get('active_gatehouses', [])
        if len(profile_rows) != 13 or len({row.get('stable_id') for row in profile_rows}) != len(profile_rows):
            fail('shared profiles must list 13 unique active gatehouse IDs')
        profile_by_id = {row['stable_id']: row for row in profile_rows}
        policy = {row['stable_id']:row['collision_strategy'] for row in profile_rows}
        bike_policy = {row['gold_map']:row for row in music['active_gates']}
        gold_maps = (gold/'data/maps/maps.asm').read_text(encoding='utf-8')
        gold_env = dict(re.findall(r'(?m)^\s*map\s+(\w+)\s*,\s*\w+\s*,\s*(\w+)\s*,', gold_maps))
        active_ids = sorted(set(_gate_ids(root)).intersection(_active_stable_ids(root)))
        gate_contracts = {
            row.get('stable_id'): row
            for row in contract.get('gatehouse_activation_policy', {}).get('active_gatehouse_contracts', [])
            if isinstance(row, dict)
        }
        index = GoldCollisionIndex(gold)
        runtime_assets = txt('data/johto_pilot_runtime_assets.asm')
        descriptors: dict[int, tuple[str, int, int]] = {}
        descriptor_re = re.compile(
            r'(?m)^\s*db\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s*,\s*(JOHTO_[A-Z0-9_]+)\s*,\s*([A-Z0-9_]+|\d+)\s*,\s*([A-Z0-9_]+|\d+)\s*(?:;[^\n]*)?$'
        )
        for symbol, tileset, width_token, height_token in descriptor_re.findall(runtime_assets):
            if symbol not in constants:
                continue
            width = constants.get(width_token, int(width_token) if width_token.isdecimal() else -1)
            height = constants.get(height_token, int(height_token) if height_token.isdecimal() else -1)
            descriptors[constants[symbol]] = (tileset, width, height)

        south = txt('engine/johto_south_geometry.asm')
        south_gateway = txt('engine/johto_land_collision_gateway_272.asm')
        east = txt('data/johto_east_runtime_300.asm')
        east_gateway = txt('engine/johto_land_collision_gateway_272.asm')
        shared_wiring_ok = check_shared303(south, east, east, constants)
        tileset_headers = txt('data/tileset_headers.asm')
        collision_source = txt('data/collision.asm')
        player_state = txt('engine/overworld/player_state.asm')
        home_source = txt('home/overworld.asm')
        closed_targets_text = south.split('.closedDoorTargets', 1)[1].split('JohtoSouthAzaleaTownRoles::', 1)[0]
        closed_targets = set()
        for symbol, x, y in re.findall(
                r'(?m)^\s*db\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s*,\s*(\d+)\s*,\s*(\d+)\s*$',
                closed_targets_text):
            if symbol in constants:
                closed_targets.add((constants[symbol], int(x), int(y)))

        if set(active_ids) != set(gate_contracts):
            fail(f'active gatehouse/contract mismatch: active={active_ids}, contracts={sorted(gate_contracts)}')
        if set(active_ids) != set(policy):
            fail(f'carpet collision policy must explicitly cover every active gatehouse: active={active_ids}, policy={sorted(policy)}')
        allowed_policies = {
            'legacy_gate_tilecoll': {6, 19, 65, 66, 74, 102},
            'south_gold_role_grid': {11, 13, 18, 104},
            'west_carpet_lane_helper': {23},
            'east_carpet_lane_helper': {62},
            'park_east_mature_helper': {105},
        }
        for method, expected_ids in allowed_policies.items():
            got = {stable_id for stable_id, strategy in policy.items() if strategy == method}
            if got != expected_ids:
                fail(f'collision backend {method} unexpected stable IDs {sorted(got)}')

        # The legacy tile-collision reader probes the lower-left 8x8 tile of
        # the target 16x16 cell (GetTileAndCoordsInFrontOfPlayer's aCoord 6/8/10,
        # row 9/11 offsets). Confirm those actual probe tiles are in Gate_Coll.
        legacy_ids = {6, 19, 65, 66, 74, 102}
        if not all(token in player_state for token in ('aCoord 8, 11', 'aCoord 8, 7', 'aCoord 6, 9', 'aCoord 10, 9')):
            fail('legacy Gate_Coll probe geometry no longer matches GetTileAndCoordsInFrontOfPlayer')
        if not re.search(r'(?m)^\s*tileset\s+JohtoGate_Block\s*,\s*JohtoGate_GFX\s*,\s*Gate_Coll\s*,', tileset_headers):
            fail('JOHTO_GATE no longer uses the ROM0 Gate_Coll list')
        if not re.search(r'(?m)^\s*Gate_Coll::\s*INCBIN\s+"gfx/tilesets/gate\.tilecoll"', collision_source):
            fail('Gate_Coll INCBIN source changed or is missing')
        passable_bytes = raw('gfx/tilesets/gate.tilecoll')
        if not passable_bytes or passable_bytes[-1] != 0xff or 0xff in passable_bytes[:-1]:
            fail('Gate_Coll passable list has an invalid terminator')
        passable_tiles = set(passable_bytes[:-1])
        gate_blockset = raw('gfx/blocksets/johto_gate.bst')

        south_role_labels = {
            11: '.IlexForestAzaleaGate',
            13: '.Route34IlexForestGate',
            18: '.Route35Gate',
            104: '.SouthParkGate',
        }

        for stable_id in active_ids:
            gate = gate_contracts.get(stable_id)
            if gate is None:
                continue
            gold_map = gate.get('gold_map')
            profile = profile_by_id.get(stable_id, {})
            source_bike = bike_policy.get(gold_map, {})
            if profile.get('gold_map') != gold_map:
                fail(f'ID{stable_id} profile Gold map mismatch')
            environment = gold_env.get(gold_map)
            if (profile.get('gold_environment') != environment or
                source_bike.get('gold_environment') != environment or
                profile.get('bike_allowed') != (environment == 'GATE') or
                source_bike.get('bike_allowed') != profile.get('bike_allowed')):
                fail(f'ID{stable_id} Gold environment or bike profile drift')
            layout = profile.get('layout')
            if layout not in ('horizontal_ew','vertical_ns','park_south_ns','park_east_ew'):
                fail(f'ID{stable_id} unknown layout {layout}')
            if ('ew' in layout) != (stable_id in (6,11,23,62,102,105)):
                fail(f'ID{stable_id} layout orientation drift')
            rows = gate.get('warp_contracts', [])
            carpets = []
            for row in rows:
                if row.get('source_stable_id') != stable_id:
                    continue
                xy = row.get('source_xy')
                if not isinstance(xy, list) or len(xy) != 2:
                    continue
                x, y = xy
                role = index.role_at(gold_map, x, y)
                if role in GATE_CARPETS:
                    carpets.append((x, y, role))
            if not carpets:
                fail(f'ID{stable_id} {gold_map}: no registered Gold carpet cells in its own warp contract')
                results.append({'stable_id': stable_id, 'gold_map': gold_map,
                                'policy': policy.get(stable_id, 'MISSING'), 'carpets': 0, 'status': 'FAIL'})
                continue

            strategy = policy.get(stable_id)
            gate_errors: list[str] = []
            if strategy == 'legacy_gate_tilecoll':
                legacy_symbol = next((name for name, value in constants.items()
                                      if value == stable_id and name.endswith('_LOCAL_ID') and 'GATE' in name), None)
                if legacy_symbol and re.search(rf'(?m)^\s*cp\s+{re.escape(legacy_symbol)}\s*$', south_gateway):
                    gate_errors.append(f'{legacy_symbol} unexpectedly bypasses its legacy Gate_Coll strategy')
                descriptor = descriptors.get(stable_id)
                if descriptor is None or descriptor[0] != 'JOHTO_GATE':
                    gate_errors.append(f'expected JOHTO_GATE descriptor, got {descriptor}')
                else:
                    _, block_width, block_height = descriptor
                    runtime = raw(f'maps/johto_pilot/{gold_map}.runtime.blk')
                    if block_width <= 0 or block_height <= 0 or len(runtime) != block_width * block_height:
                        gate_errors.append(f'legacy runtime block map size mismatch: {len(runtime)} vs {block_width}x{block_height}')
                    else:
                        for x, y, role in carpets:
                            bx, by = x // 2, y // 2
                            if bx >= block_width or by >= block_height:
                                gate_errors.append(f'carpet {(x, y)} is outside the legacy runtime block map')
                                continue
                            block_id = runtime[by * block_width + bx]
                            qx, qy = (x & 1) * 2, (y & 1) * 2
                            probe_index = block_id * 16 + (qy + 1) * 4 + qx
                            if probe_index >= len(gate_blockset):
                                gate_errors.append(f'carpet {(x, y)} resolves beyond JOHTO_GATE blockset')
                                continue
                            probe_tile = gate_blockset[probe_index]
                            if probe_tile not in passable_tiles:
                                gate_errors.append(f'carpet {(x, y)} {role}: Gate_Coll probe tile ${probe_tile:02x} is not passable')
                try:
                    count, bad = _audit_gatehouse_legacy_source_walk(
                        gold_index=index, gold_map=gold_map, stable_id=stable_id,
                        descriptor=descriptor, read_bytes=raw, constants=constants,
                        gateway_source=south_gateway, home_source=home_source,
                        player_state_source=player_state,
                        tileset_headers=tileset_headers, collision_source=collision_source)
                    asm_traced_moves[stable_id] = count
                    gate_errors.extend('legacy source trace ' + err for err in bad)
                except (OSError, ValueError, IndexError) as exc:
                    gate_errors.append(f'legacy source trace failed: {exc}')

            elif strategy == 'south_gold_role_grid':
                descriptor = descriptors.get(stable_id)
                if descriptor is None:
                    gate_errors.append('missing runtime descriptor')
                else:
                    _, block_width, block_height = descriptor
                    role_width, role_height = block_width * 2, block_height * 2
                    roles = raw(f'maps/johto_pilot/{gold_map}.roles.bin')
                    if len(roles) != role_width * role_height:
                        gate_errors.append(f'role grid size mismatch: {len(roles)} vs {role_width}x{role_height}')
                    else:
                        for x, y, role in carpets:
                            if roles[y * role_width + x] != 0:
                                gate_errors.append(f'carpet {(x, y)} {role}: Gold role grid blocks the live carpet')
                            if (stable_id, x, y) in closed_targets:
                                gate_errors.append(f'carpet {(x, y)} {role}: mature closed-door fence blacklists a live carpet')
                symbol = next((name for name, value in constants.items()
                               if value == stable_id and name.endswith('_LOCAL_ID') and 'GATE' in name), None)
                label = south_role_labels[stable_id]
                if symbol is None or not re.search(
                        rf'(?m)^\s*cp\s+{re.escape(symbol)}\s*\n\s*jp z,\s*{re.escape(label)}\s*$', south):
                    gate_errors.append(f'JohtoSouthSpatialRoleAhead dispatch missing for {symbol}/{label}')
                if 'callab JohtoSouthSpatialStep' not in south_gateway:
                    gate_errors.append('ROM0 land gateway no longer dispatches JohtoSouthSpatialStep')
                if stable_id in (11, 13):
                    range_guard = ('cp JOHTO_AZALEA_TOWN_LOCAL_ID\n    jr c, .route33' in south_gateway and
                                   'cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1\n    jr nc, .route33' in south_gateway)
                    if not range_guard or not (constants.get('JOHTO_AZALEA_TOWN_LOCAL_ID', 999) <= stable_id <=
                                               constants.get('JOHTO_GOLDENROD_CITY_LOCAL_ID', -1)):
                        gate_errors.append('ROM0 gateway no longer routes this South gate ID through the active South spatial range')
                elif stable_id in (18, 104):
                    explicit_symbol = ('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID' if stable_id == 18 else
                                       'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID')
                    if not re.search(rf'(?m)^\s*cp\s+{re.escape(explicit_symbol)}\s*\n\s*jr z, \.activeSouthMap\s*$', south_gateway):
                        gate_errors.append(f'ROM0 gateway explicit activeSouthMap dispatch missing for {explicit_symbol}')

            elif strategy == 'west_carpet_lane_helper':
                roles = raw(f'maps/johto_pilot/{gold_map}.roles.bin')
                if len(roles) != 80 or not all(roles[y*10+x] == 1 for x in (0,9) for y in (4,5)):
                    gate_errors.append('West mature roles must retain four solid carpet markers')
                if not shared_wiring_ok:
                    gate_errors.append('shared West/East profile dispatch or exact table differs')
                if 'callab JohtoGateHorizontalCarpetInbound303' not in south:
                    gate_errors.append('West gate no longer calls shared ROMX movement engine')
                if 'callab JohtoSouthSpatialStep' not in south_gateway:
                    gate_errors.append('missing South land movement gateway')
                if len(roles) == 80:
                    count, bad = scan_shared303(east, constants, stable_id, roles)
                    results_checked[stable_id] = count
                    gate_errors.extend('West shared carpet walk ' + err for err in bad[:12])

            elif strategy == 'park_east_mature_helper':
                roles = raw(f'maps/johto_pilot/{gold_map}.roles.bin')
                if len(roles) != 80:
                    gate_errors.append(f'Park East role grid size mismatch: {len(roles)} != 80')
                helper = south.split('JohtoParkEastGateMatureStep::', 1)[1].split('JohtoParkEastGateBlockedRows::', 1)[0]
                required = ('cp 9', '.maybeCarpet', 'cp 4', 'cp 5', '.pass')
                if not all(token in helper for token in required):
                    gate_errors.append('Park East mature helper no longer opens only its four registered carpet cells')
                if 'call JohtoParkEastGateMatureStep' not in south:
                    gate_errors.append('JohtoSouthSpatialStep no longer dispatches Park East Gate to its mature helper')
                if not re.search(r'(?m)^\s*cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID\s*\n\s*jr z, \.activeSouthMap\s*$', south_gateway):
                    gate_errors.append('ROM0 gateway no longer routes Park East Gate through the South spatial collision path')

            elif strategy == 'east_carpet_lane_helper':
                roles = raw(f'maps/johto_pilot/{gold_map}.roles.bin')
                if len(roles) != 80 or not all(roles[y*10+x] == 1 for x in (0,9) for y in (4,5)):
                    gate_errors.append('East mature roles must retain four solid carpet markers')
                if not shared_wiring_ok:
                    gate_errors.append('shared West/East profile dispatch or exact table differs')
                if 'callab JohtoEastSpatialStep' not in east_gateway:
                    gate_errors.append('East gate ROM0 gateway missing')
                if len(roles) == 80:
                    count, bad = scan_shared303(east, constants, stable_id, roles)
                    results_checked[stable_id] = count
                    gate_errors.extend('East shared carpet walk ' + err for err in bad[:12])

            else:
                gate_errors.append(f'no carpet movement strategy registered for stable ID {stable_id}')

            # REF-307: audit complete floor/wall geometry for the eight gates
            # not covered by the 303 ASM instruction simulator. This is not a
            # claim that their collision ASM has been emulated or phone-tested.
            if stable_id not in (23, 62):
                try:
                    cell_count, move_count, walk_errors = _audit_gatehouse_full_walk_grid(
                        gold_index=index, gold_map=gold_map, stable_id=stable_id,
                        strategy=strategy, descriptor=descriptors.get(stable_id),
                        read_bytes=raw, passable_tiles=passable_tiles,
                        gate_blockset=gate_blockset)
                    decoded_cells[stable_id] = cell_count
                    decoded_moves[stable_id] = move_count
                    gate_errors.extend('full-grid ' + e for e in walk_errors)
                except (OSError, ValueError, IndexError) as exc:
                    gate_errors.append(f'full-grid decoder failed: {exc}')

            # DEV-308: execute the shipped instructions for all room-internal
            # moves on the four South gate grids and the special Park East
            # bitmap helper. The three legacy Gate_Coll maps still use the
            # original tile-probe data audit; they are not re-labelled traced.
            if strategy in ('south_gold_role_grid', 'park_east_mature_helper'):
                try:
                    count, bad = _audit_gatehouse_source_walk(
                        gold_index=index, gold_map=gold_map,
                        stable_id=stable_id, strategy=strategy,
                        source=south, constants=constants, read_bytes=raw,
                        blocked_targets=frozenset(closed_targets))
                    asm_traced_moves[stable_id] = count
                    gate_errors.extend('source trace ' + e for e in bad)
                except (OSError, ValueError, IndexError) as exc:
                    gate_errors.append(f'ASM source trace failed: {exc}')

            if gate_errors:
                errors.extend(f'ID{stable_id} {gold_map}: {message}' for message in gate_errors)
            results.append({'stable_id': stable_id, 'gold_map': gold_map,
                            'policy': strategy, 'carpets': len(carpets),
                            'status': 'FAIL' if gate_errors else 'PASS',
                            'details': gate_errors})

    except (OSError, ValueError, KeyError, TypeError, IndexError, AttributeError) as exc:
        errors.append(f'carpet movement audit could not complete: {exc}')

    return {
        'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
        'gatehouses_checked': len(results),
        'carpets_checked': sum(row.get('carpets', 0) for row in results),
        'source_simulated_moves': results_checked,
        'data_decoded_cells': decoded_cells,
        'data_decoded_moves': decoded_moves,
        'asm_traced_moves': asm_traced_moves,
        'results': results,
        'errors': errors,
        'runtime_verified': False,
        'rom_built': False,
        'phone_accepted': False,
    }

def audit(project: Path, gold: Path) -> dict:
    project, gold = Path(project).resolve(), Path(gold).resolve()
    checks: list[dict] = []
    errors: list[str] = []
    try:
        contract_path = project / CONTRACT_PATH
        if not contract_path.is_file() or contract_path.is_symlink():
            raise FileNotFoundError(f'missing current door contract: {CONTRACT_PATH}')
        contract = json.loads(contract_path.read_text(encoding='utf-8'))
        gold_summary = inspect_gold(gold)
        index = GoldCollisionIndex(gold)
        inventory = index.gate_warp_inventory()
        active_ids = _active_stable_ids(project)
        gate_ids = _gate_ids(project)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        return {'schema': 'johto-gatehouse-behavior-audit-v1', 'status': 'FAIL',
                'checks': checks, 'errors': [str(exc)], 'runtime_verified': False,
                'rom_built': False, 'phone_accepted': False}

    _check(checks, errors, 'gold_source_integrity', not gold_summary.get('errors'),
           f"MUS source errors={len(gold_summary.get('errors', []))}; "
           f"registered maps={gold_summary.get('stats', {}).get('registered_maps')}")
    total_warps = sum(len(row['warps']) for row in inventory)
    roles = Counter(warp['collision_role'] for row in inventory for warp in row['warps'])
    _check(checks, errors, 'gold_gate_inventory_size',
           len(inventory) == 24 and total_warps == 100,
           f'gate maps={len(inventory)}, warp events={total_warps}')
    _check(checks, errors, 'gold_gate_collision_role_counts', dict(roles) == EXPECTED_ROLES,
           f'expected={EXPECTED_ROLES}; actual={dict(roles)}')

    semantic_errors = []
    for row in inventory:
        for warp in row['warps']:
            role = warp['collision_role']
            if role in GATE_SOLID_DOORS:
                expected_trigger, expected_direction = 'STEP_ON', 'UP'
                expected_arrival = 'D_DOWN'
            elif role in GATE_CARPETS:
                expected_trigger = 'COLLISION_ONLY'
                expected_direction = role.removeprefix('WARP_CARPET_')
                expected_arrival = 'NONE'
            else:
                semantic_errors.append(f"{row['gold_map']} {warp}: unsupported gate collision role")
                continue
            rule = gold_gate_approach_rule(role, 'COLLISION_ONLY')
            actual_arrival = gold_gate_arrival_step(role)
            if not rule or rule != (expected_trigger, expected_direction) or actual_arrival != expected_arrival:
                semantic_errors.append(f"{row['gold_map']} {warp}: trigger={rule}, arrival={actual_arrival}")
            if warp.get('trigger_contract') != expected_trigger:
                semantic_errors.append(f"{row['gold_map']} {warp}: inventory trigger {warp.get('trigger_contract')} != {expected_trigger}")
            if expected_trigger == 'COLLISION_ONLY' and warp.get('collision_direction') != expected_direction:
                semantic_errors.append(f"{row['gold_map']} {warp}: direction {warp.get('collision_direction')} != {expected_direction}")
    _check(checks, errors, 'gold_gate_trigger_and_arrival_semantics', not semantic_errors,
           f'validated {total_warps} gates; semantic errors={semantic_errors[:8]}')

    _check(checks, errors, 'contract_schema',
           contract.get('schema') == 'johto-pilot-door-contracts-v1' and
           contract.get('gold_reference') == 'MUS-1.0.1',
           f"schema={contract.get('schema')}, reference={contract.get('gold_reference')}")
    routes = contract.get('active_routes', [])
    _check(checks, errors, 'active_house_contract_count',
           len(routes) == 3 and {row.get('id') for row in routes} == {
               'cherrygrove_to_guide_house', 'guide_house_left_exit', 'guide_house_right_exit'},
           f'current enabled doorway contract rows={len(routes)}')
    phone_tests = contract.get('required_phone_tests', [])
    _check(checks, errors, 'phone_test_contract', len(phone_tests) >= 5 and
           contract.get('evidence_boundary', {}).get('phone_accepted') is False,
           f'phone test cases={len(phone_tests)}; contract does not claim acceptance')

    gate_ids_by_value = _gate_ids(project)
    active_gate_ids = sorted(set(gate_ids_by_value).intersection(active_ids))
    gate_contracts = contract.get('gatehouse_activation_policy', {}).get('active_gatehouse_contracts', [])
    contract_ids = {row.get('stable_id') for row in gate_contracts if isinstance(row, dict)}
    missing_contracts = [value for value in active_gate_ids if value not in contract_ids]
    extra_contracts = sorted(contract_ids - set(active_gate_ids))
    _check(checks, errors, 'no_uncontracted_gatehouse_activation',
           not missing_contracts and not extra_contracts,
           f'active gate IDs={active_gate_ids}; missing contracts={missing_contracts}; inactive contracts={extra_contracts}')
    gate_contracts_by_id = {row.get('stable_id'): row for row in gate_contracts if isinstance(row, dict)}

    carpet_movement = audit_active_gatehouse_carpet_walkability(project, gold)
    _check(checks, errors, 'active_gatehouse_carpet_walkability',
           carpet_movement.get('status') == 'PASS_STATIC_ONLY',
           f"gatehouses={carpet_movement.get('gatehouses_checked')}, "
           f"registered carpet cells={carpet_movement.get('carpets_checked')}; "
           f"errors={carpet_movement.get('errors', [])[:8]}")
    errors.extend('carpet_movement_audit: ' + e for e in carpet_movement.get('errors', []))

    # Keep the already accepted Route31/Violet horizontal gate contract exact.
    gate_errors = []
    gate_contract = gate_contracts_by_id.get(6)
    if gate_contract is None:
        gate_errors.append('missing stable ID 6 contract')
    else:
        if gate_contract.get('gold_map') != 'Route31VioletGate' or gate_contract.get('runtime_tileset') != 'JOHTO_GATE':
            gate_errors.append('wrong Route31/Violet gate reference/tileset')
        got = gate_contract.get('warp_contracts', [])
        expected = [
            ('route31_0', 4, 0, [4, 6], 'LEFT', 'COLLISION_ONLY', 6, 2, [9, 4]),
            ('route31_1', 4, 1, [4, 7], 'LEFT', 'COLLISION_ONLY', 6, 3, [9, 5]),
            ('violet_0', 5, 0, [39, 24], 'RIGHT', 'COLLISION_ONLY', 6, 0, [0, 4]),
            ('violet_1', 5, 1, [39, 25], 'RIGHT', 'COLLISION_ONLY', 6, 1, [0, 5]),
            ('gate_to_violet_0', 6, 0, [0, 4], 'LEFT', 'COLLISION_ONLY', 5, 0, [39, 24]),
            ('gate_to_violet_1', 6, 1, [0, 5], 'LEFT', 'COLLISION_ONLY', 5, 1, [39, 25]),
            ('gate_to_route31_0', 6, 2, [9, 4], 'RIGHT', 'COLLISION_ONLY', 4, 0, [4, 6]),
            ('gate_to_route31_1', 6, 3, [9, 5], 'RIGHT', 'COLLISION_ONLY', 4, 1, [4, 7]),
        ]
        records = [(r.get('id'), r.get('source_stable_id'), r.get('source_warp_ordinal'),
                    r.get('source_xy'), r.get('direction'), r.get('trigger'),
                    r.get('target_stable_id'), r.get('target_warp_ordinal'), r.get('target_xy')) for r in got]
        if records != expected or any(r.get('arrival_auto_step') != 'NONE' for r in got):
            gate_errors.append('ID6 contract differs from its eight Gold directional routes')
        try:
            gold_route = _gold_warp_events(gold, 'Route31')[:2]
            gold_city = [r for r in _gold_warp_events(gold, 'VioletCity') if r['destination']=='ROUTE_31_VIOLET_GATE']
            gold_gate = _gold_warp_events(gold, 'Route31VioletGate')
            if [(r['x'],r['y'],r['destination_warp_number']) for r in gold_route] != [(4,6,3),(4,7,4)]:
                gate_errors.append('MUS Route31 entry mismatch')
            if [(r['x'],r['y'],r['destination_warp_number']) for r in gold_city] != [(39,24,1),(39,25,2)]:
                gate_errors.append('MUS Violet City entry mismatch')
            if [(r['x'],r['y'],r['destination_warp_number']) for r in gold_gate] != [(0,4,8),(0,5,9),(9,4,1),(9,5,2)]:
                gate_errors.append('MUS gate return mismatch')
            gold_sources = (
                ('Route31',4,6),('Route31',4,7),
                ('VioletCity',39,24),('VioletCity',39,25),
                ('Route31VioletGate',0,4),('Route31VioletGate',0,5),
                ('Route31VioletGate',9,4),('Route31VioletGate',9,5),
            )
            for row, (map_name,x,y) in zip(got, gold_sources):
                role = index.role_at(map_name,x,y)
                actual_rule = gold_gate_approach_rule(role,'COLLISION_ONLY')
                if actual_rule != (row.get('trigger'),row.get('direction')):
                    gate_errors.append(f'MUS collision mismatch {map_name}({x},{y}): {role} -> {actual_rule}')
                if row.get('arrival_auto_step') != gold_gate_arrival_step(role):
                    gate_errors.append(f'MUS arrival mismatch {map_name}({x},{y})')
            source = (project/'data/johto_gate_runtime.asm').read_text()
            object_rows = re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR',source)
            if object_rows != [('4','0','0'),('5','0','1'),('4','9','0'),('5','9','1')]:
                gate_errors.append('ID6 runtime object warp positions/target indices mismatch')
        except (OSError, ValueError) as exc:
            gate_errors.append(str(exc))
    _check(checks, errors, 'active_gatehouse_exact_contract', not gate_errors,
           f'ID6 Route31/Violet gate: four doorway pairs, eight Gold routes; errors={gate_errors}')

    # The newly active South Gate is horizontal like the accepted Violet gate,
    # but its source Gold warp numbers differ from compact runtime ordinals:
    # Route32's enabled Gold warps are #2/#3, while its compact object rows are 0/1;
    # Ruins' enabled Gold warps are #10/#11, while its compact object rows are 0/1.
    south_errors = []
    south = gate_contracts_by_id.get(102)
    if south is None:
        south_errors.append('missing stable ID 102 contract')
    else:
        if south.get('gold_map') != 'Route32RuinsOfAlphGate' or south.get('runtime_tileset') != 'JOHTO_GATE':
            south_errors.append('wrong South Gate Gold map or runtime tileset')
        if south.get('runtime_object_file') != 'data/johto_ruins_south_runtime.asm' or south.get('runtime_object_label') != 'JohtoPilotAlphSouthGateRuntimeObjects':
            south_errors.append('wrong South Gate runtime object source')
        got = south.get('warp_contracts', [])
        expected = [
            ('route32_to_south_gate_0', 7, 0, [4, 2], 'LEFT', 'COLLISION_ONLY', 102, 2, [9, 4]),
            ('route32_to_south_gate_1', 7, 1, [4, 3], 'LEFT', 'COLLISION_ONLY', 102, 3, [9, 5]),
            ('south_gate_to_ruins_0', 102, 0, [0, 4], 'LEFT', 'COLLISION_ONLY', 20, 0, [13, 20]),
            ('south_gate_to_ruins_1', 102, 1, [0, 5], 'LEFT', 'COLLISION_ONLY', 20, 1, [13, 21]),
            ('south_gate_to_route32_0', 102, 2, [9, 4], 'RIGHT', 'COLLISION_ONLY', 7, 0, [4, 2]),
            ('south_gate_to_route32_1', 102, 3, [9, 5], 'RIGHT', 'COLLISION_ONLY', 7, 1, [4, 3]),
            ('ruins_to_south_gate_0', 20, 0, [13, 20], 'RIGHT', 'COLLISION_ONLY', 102, 0, [0, 4]),
            ('ruins_to_south_gate_1', 20, 1, [13, 21], 'RIGHT', 'COLLISION_ONLY', 102, 1, [0, 5]),
        ]
        records = [(r.get('id'), r.get('source_stable_id'), r.get('source_warp_ordinal'),
                    r.get('source_xy'), r.get('direction'), r.get('trigger'),
                    r.get('target_stable_id'), r.get('target_warp_ordinal'), r.get('target_xy')) for r in got]
        if records != expected or any(r.get('arrival_auto_step') != 'NONE' for r in got):
            south_errors.append('ID102 contract differs from the eight horizontal Gold routes')
        gold_destination = {7: 'ROUTE_32', 20: 'RUINS_OF_ALPH_OUTSIDE', 102: 'ROUTE_32_RUINS_OF_ALPH_GATE'}
        stable_symbol = {value: name for name, value in _constants(project).items()
                         if name.endswith('_LOCAL_ID')}
        runtime_route_source = (project/'engine/johto_pilot_runtime.asm').read_text()
        route_body = runtime_route_source.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        actual_routes = set(re.findall(r'(?m)^\s*db\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_[A-Z0-9_]+)',route_body))
        try:
            for row in got:
                source_map = row.get('source_gold_map')
                source_number = row.get('source_gold_warp_number_one_based')
                target_map = row.get('target_gold_map')
                target_number = row.get('target_gold_warp_number_one_based')
                events = _gold_warp_events(gold, source_map)
                if not isinstance(source_number, int) or source_number < 1 or source_number > len(events):
                    south_errors.append(f'{row.get("id")}: invalid Gold source warp number')
                    continue
                event = events[source_number - 1]
                expected_event = (row.get('source_xy', [None,None])[0], row.get('source_xy', [None,None])[1],
                                  gold_destination.get(row.get('target_stable_id')), target_number)
                actual_event = (event['x'], event['y'], event['destination'], event['destination_warp_number'])
                if actual_event != expected_event:
                    south_errors.append(f'{row.get("id")}: Gold warp {actual_event} != {expected_event}')
                role = index.role_at(source_map, *row.get('source_xy', [None,None]))
                rule = gold_gate_approach_rule(role, row.get('trigger'))
                if rule != (row.get('trigger'), row.get('direction')) or gold_gate_arrival_step(role) != row.get('arrival_auto_step'):
                    south_errors.append(f'{row.get("id")}: Gold collision/arrival {role} -> {rule}')
                source_symbol = stable_symbol.get(row.get('source_stable_id'))
                target_symbol = stable_symbol.get(row.get('target_stable_id'))
                route = (source_symbol, str(row.get('source_warp_ordinal')), target_symbol)
                if None in route or route not in actual_routes:
                    south_errors.append(f'{row.get("id")}: registered runtime route missing {route}')
            object_file = (project / south['runtime_object_file']).read_text()
            object_body = object_file.split(south['runtime_object_label'] + '::',1)[1].split('JohtoPilotAlphOutsideRuntimeHeader::',1)[0]
            object_rows = re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR',object_body)
            expected_object_rows = [(str(r['source_xy'][1]), str(r['source_xy'][0]), str(r['target_warp_ordinal']))
                                    for r in got if r.get('source_stable_id') == 102]
            if object_rows != expected_object_rows:
                south_errors.append(f'South Gate object rows {object_rows} != {expected_object_rows}')
        except (OSError, ValueError, KeyError, TypeError, IndexError) as exc:
            south_errors.append(str(exc))
    _check(checks, errors, 'active_south_gate_exact_contract', not south_errors,
           f'ID102 South Gate: 8 Gold/runtime directional routes, no auto-step; errors={south_errors[:8]}')

    # DEV-328/329: the Route29/46 vertical gate is a separate exact Gold
    # contract. Validate all seven reciprocal arcs, including the Route29
    # STEP_ON DOOR and both Route46 collision-only DOWN carpets.
    south_gate_errors = []
    south_gate = gate_contracts_by_id.get(74)
    south_gate_expected = [
        ('Route29_to_Gate', 1, 0, [27, 1], 'UP', 'STEP_ON', 74, 2, [4, 7]),
        ('Route46_0_to_Gate', 73, 0, [7, 33], 'DOWN', 'COLLISION_ONLY', 74, 0, [4, 0]),
        ('Route46_1_to_Gate', 73, 1, [8, 33], 'DOWN', 'COLLISION_ONLY', 74, 1, [5, 0]),
        ('Gate_0_to_Route46', 74, 0, [4, 0], 'UP', 'STEP_ON', 73, 0, [7, 33]),
        ('Gate_1_to_Route46', 74, 1, [5, 0], 'UP', 'STEP_ON', 73, 1, [8, 33]),
        ('Gate_2_to_Route29', 74, 2, [4, 7], 'DOWN', 'COLLISION_ONLY', 1, 0, [27, 1]),
        ('Gate_3_to_Route29', 74, 3, [5, 7], 'DOWN', 'COLLISION_ONLY', 1, 0, [27, 1]),
    ]
    if south_gate is None or south_gate.get('gold_map') != 'Route29Route46Gate':
        south_gate_errors.append('missing or wrong ID74 Route29Route46Gate contract')
    else:
        rows = south_gate.get('warp_contracts', [])
        actual = [(r.get('id'), r.get('source_stable_id'), r.get('source_warp_ordinal'),
                   r.get('source_xy'), r.get('direction'), r.get('trigger'),
                   r.get('target_stable_id'), r.get('target_warp_ordinal'), r.get('target_xy'))
                  for r in rows]
        if actual != south_gate_expected:
            south_gate_errors.append(f'ID74 seven-route contract differs: {actual}')
        for row in rows:
            try:
                source_event = _gold_warp_events(gold, row['source_gold_map'])[
                    row['source_gold_warp_number_one_based'] - 1]
                target_event = _gold_warp_events(gold, row['target_gold_map'])[
                    row['target_gold_warp_number_one_based'] - 1]
                source_role = index.role_at(row['source_gold_map'], *row['source_xy'])
                target_role = index.role_at(row['target_gold_map'], *row['target_xy'])
                trigger = 'STEP_ON' if source_role == 'DOOR' else 'COLLISION_ONLY'
                direction = 'UP' if source_role == 'DOOR' else 'DOWN'
                arrival = 'D_DOWN' if target_role == 'DOOR' else 'NONE'
                if ([source_event['x'], source_event['y']] != row['source_xy'] or
                    source_event['destination'].replace('_', '') != row['target_gold_map'].upper().replace('_', '') or
                    [target_event['x'], target_event['y']] != row['target_xy'] or
                    source_role != row['source_gold_collision_role'] or
                    row.get('trigger') != trigger or row.get('direction') != direction or
                    row.get('arrival_auto_step') != arrival):
                    south_gate_errors.append(f"{row.get('id')}: Gold role/Warp/arrival mismatch")
            except (IndexError, KeyError, ValueError, TypeError) as exc:
                south_gate_errors.append(f"{row.get('id')}: {exc}")
    _check(checks, errors, 'active_route29_46_gate_exact_contract', not south_gate_errors,
           f'ID74 seven Gold Warp arcs and directional semantics; errors={south_gate_errors[:8]}')

    # Runtime direction guard is separate from the static object contract:
    # the existing RPP CheckWarpsCollision matches a coordinate alone.
    try:
        gate_runtime = (project/'engine/johto_pilot_runtime.asm').read_text()
        overworld = (project/'home/overworld.asm').read_text()
        direction_body = gate_runtime.split('JohtoPilotGateCollisionExitAllowed::', 1)[1]
        collision_body = overworld.split('CheckWarpsCollision::', 1)[1].split('CheckWarpsNoCollisionRetry1::', 1)[0]
        pass_direction = all(x in direction_body for x in (
            'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID',
            'cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID',
            'cp PLAYER_DIR_LEFT', 'cp PLAYER_DIR_RIGHT',
            'cp JOHTO_ROUTE31_VIOLET_GATE_WIDTH * 2 - 1',
            'cp 4', 'cp 5', 'ld e, 1')) and \
            all(x in collision_body for x in ('callab JohtoPilotGateCollisionExitAllowed',
                'jr z, .retry2', 'push bc', 'pop bc', 'push hl', 'pop hl'))
    except (OSError, IndexError) as exc:
        pass_direction = False
    _check(checks, errors, 'gate_collision_direction_guard', pass_direction,
           'matched gate collision exit requires outward facing direction and correct pair of carpet cells')

    _check(checks, errors, 'future_gatehouse_fail_closed_policy',
           contract.get('gatehouse_activation_policy', {}).get('require_explicit_contract_before_activation') is True,
           'a gatehouse must have an explicit contract before its stable ID is activated')

    # REF-305: the shared carpet engine does not own NPC identity. Keep the
    # two Ecruteak Officers under a separate map-local object/text audit.
    from johto_gatehouse_npc_pilot_305 import audit as audit_gatehouse_npc_pilot_305
    npc_report = audit_gatehouse_npc_pilot_305(project, gold)
    _check(checks, errors, 'ecruteak_gatehouse_npc_pilot',
           npc_report.get('status') == 'PASS_STATIC_ONLY',
           f"NPC audit={npc_report.get('status')}; errors={npc_report.get('errors', [])[:5]}")
    errors.extend('npc_audit: ' + e for e in npc_report.get('errors', []))

    arrival = audit_warp_arrival(project, gold)
    _check(checks, errors, 'current_house_arrival_audit', arrival.get('status') == 'PASS_STATIC_ONLY',
           f"arrival audit={arrival.get('status')}; errors={arrival.get('errors', [])[:5]}")
    errors.extend('arrival_audit: ' + e for e in arrival.get('errors', []))

    return {'schema': 'johto-gatehouse-behavior-audit-v1',
            'status': 'PASS_REFERENCE_ONLY' if not errors else 'FAIL',
            'project': str(project), 'gold_reference': str(gold),
            'checks': checks, 'errors': errors,
            'gold_gate_inventory': {'maps': len(inventory), 'warp_events': total_warps,
                                    'collision_roles': dict(roles)},
            'current_active_map_ids': sorted(active_ids),
            'current_active_gate_ids': active_gate_ids,
            'future_gatehouse_contracts': gate_contracts,
            'arrival_audit_status': arrival.get('status'),
            'carpet_movement_audit': carpet_movement,
            'runtime_verified': False, 'rom_built': False, 'phone_accepted': False,
            'note': 'Gold reference semantics and current source contracts passed; no ROM/runtime behavior is inferred.'}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--gold-root', type=Path, required=True,
                        help='MUS-1.0.1 Gold reference source root')
    parser.add_argument('--json-out', type=Path, required=True)
    args = parser.parse_args(argv)
    report = audit(args.project, args.gold_root)
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    passed = sum(x['status'] == 'PASS' for x in report['checks'])
    print(json.dumps({'status': report['status'], 'checks': len(report['checks']),
                      'passed': passed, 'failed': len(report['errors']),
                      'runtime_verified': False, 'phone_accepted': False}, ensure_ascii=False))
    return 0 if report['status'] == 'PASS_REFERENCE_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
