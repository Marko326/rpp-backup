#!/usr/bin/env python3
"""Check native Gold-to-RPP doorway arrivals against final map collision.

This is a static contract, NOT emulation. Each newly enabled native doorway
must be reviewed and declared here before being described as playable. An
unresolved Gold Warp, item event or native engine behavior is not auto-opened.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

INPUTS = (
    'engine/overworld/region_map_lookup.asm',
    'engine/overworld/npc_movement.asm',
    'main.asm',
    'home/overworld.asm',
    'engine/overworld/player_state.asm',
    'data/mapObjects/JohtoRoute32.asm',
    'data/mapObjects/JohtoUnionCave1F.asm',
    'maps/JohtoRoute32.blk',
    'maps/JohtoUnionCave1F.blk',
    'gfx/blocksets/johto.bst',
    'gfx/blocksets/johto_union_cave.bst',
    'gfx/tilesets/johto.tilecoll',
    'gfx/tilesets/johto_union_cave.tilecoll',
    'data/warp_tile_ids.asm',
)

# source label, final RPP map, alias, local, incoming source, Gold map,
# Gold Warp x/y, map width (32x32 blocks), and RPP tileset.
ENDPOINTS = (
    ('outside', 'JohtoRoute32', 'JOHTO_ROUTE_32',
     'JOHTO_ROUTE_32_LOCAL_ID', 'REGION_NATIVE_MAP_SLOT',
     'Route32', 6, 79, 10, 'johto'),
    ('cave', 'JohtoUnionCave1F', 'REGION_NATIVE_MAP_SLOT',
     'JOHTO_UNION_CAVE_1F_LOCAL_ID', 'JOHTO_ROUTE_32',
     'UnionCave1F', 17, 3, 10, 'johto_union_cave'),
)
MOVE = {'D_UP': (0, -1), 'D_DOWN': (0, 1),
        'D_LEFT': (-1, 0), 'D_RIGHT': (1, 0)}


def profiles(source: str) -> list[tuple[str, str, int, int, str, str]]:
    match = re.search(r'(?ms)^GetJohtoWarpArrivalStep::.*?^\.profiles\s*\n(.*?)(?=^GetJohtoCaveMapChangeSFX::)', source)
    if not match:
        raise ValueError('missing native arrival profiles')
    result = []
    sentinel = False
    for line in match[1].splitlines():
        code = line.split(';', 1)[0].strip()
        if not code:
            continue
        m = re.fullmatch(r'db\s+(.+)', code)
        if not m:
            raise ValueError('unsupported arrival profile syntax: ' + code)
        fields = [v.strip() for v in m[1].split(',')]
        if fields == ['$ff']:
            sentinel = True
            break
        if len(fields) != 6:
            raise ValueError('arrival profile must have six fields: ' + code)
        alias, local, y, x, source_alias, direction = fields
        if not y.isdecimal() or not x.isdecimal():
            raise ValueError('arrival coordinates must be literal')
        if direction not in MOVE:
            raise ValueError('unsupported native arrival direction: ' + direction)
        result.append((alias, local, int(y), int(x), source_alias, direction))
    if not sentinel:
        raise ValueError('native arrival profiles missing terminator')
    return result


def registered_warp(source: str, x: int, y: int) -> bool:
    return any(int(yy) == y and int(xx) == x for yy, xx in
               re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*0\s*,\s*REGION_WARP_ESCAPE\b', source))


def walkable(root: Path, name: str, tileset: str, width: int, x: int, y: int) -> bool:
    if x < 0 or y < 0:
        return False
    layout = (root / ('maps/' + name + '.blk')).read_bytes()
    if y // 2 * width + x // 2 >= len(layout):
        return False
    blocks = (root / ('gfx/blocksets/' + tileset + '.bst')).read_bytes()
    allowed = set((root / ('gfx/tilesets/' + tileset + '.tilecoll')).read_bytes()[:-1])
    bid = layout[(y // 2) * width + x // 2]
    if bid * 16 + 15 >= len(blocks):
        return False
    quadrant = y % 2 * 2 + x % 2
    start = bid * 16 + quadrant // 2 * 8 + quadrant % 2 * 2
    return all(blocks[start + dy * 4 + dx] in allowed for dy in (0, 1) for dx in (0, 1))


def gold_warps(gold: Path, name: str) -> set[tuple[int, int]]:
    src = (gold / 'maps' / (name + '.asm')).read_text()
    return {(int(x), int(y)) for x, y in
            re.findall(r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,', src)}


def _doorway_program(source: str, start: str, end: str) -> tuple[list[str], dict[str, int]]:
    """Parse the small, deliberate subset used by Route32's collision guards.

    Do not treat a preserved string as evidence that the branch can be reached.
    Any new opcode must be explicitly modelled before this audit can pass.
    """
    if source.count(start + '::') != 1 or source.count(end + '::') != 1:
        raise ValueError('ambiguous/missing doorway routine: ' + start)
    body = source.split(start + '::', 1)[1].split(end + '::', 1)[0]
    instructions: list[str] = []
    labels: dict[str, int] = {}
    for raw in body.splitlines():
        code = raw.split(';', 1)[0].strip()
        if not code:
            continue
        if re.fullmatch(r'\.[A-Za-z_][A-Za-z_0-9]*', code):
            if code in labels:
                raise ValueError('duplicate doorway branch label: ' + code)
            labels[code] = len(instructions)
        elif re.fullmatch(r'[a-z][a-z0-9]*::?', code, re.I):
            raise ValueError('unexpected global label in doorway routine: ' + code)
        else:
            instructions.append(re.sub(r'\s+', ' ', code))
    return instructions, labels


def _simulate_doorway(source: str, name: str, end: str,
                      x: int, y: int, direction: str) -> bool:
    instructions, labels = _doorway_program(source, name, end)
    registers = {'[wXCoord]': x, '[wYCoord]': y,
                 '[wPlayerDirection]': direction}
    a = None
    zero = False
    carry = False
    pc = 0
    for _ in range(80):
        if pc >= len(instructions):
            raise ValueError(name + ' falls through without returning')
        opcode = instructions[pc]
        pc += 1
        if opcode.startswith('ld a, '):
            operand = opcode[6:].strip()
            if operand not in registers:
                raise ValueError(name + ' has unmodelled load: ' + opcode)
            a = registers[operand]
        elif opcode.startswith('cp '):
            operand = opcode[3:]
            value = int(operand) if operand.isdecimal() else operand
            zero = a == value
        elif opcode.startswith('jr '):
            parts = [p.strip() for p in opcode[3:].split(',')]
            if len(parts) == 1:
                jump = True
                target = parts[0]
            elif len(parts) == 2 and parts[0] in {'z', 'nz'}:
                jump = zero if parts[0] == 'z' else not zero
                target = parts[1]
            else:
                raise ValueError(name + ' has unmodelled jump: ' + opcode)
            if target not in labels:
                raise ValueError(name + ' jumps outside routine: ' + target)
            if jump:
                pc = labels[target]
        elif opcode == 'scf':
            carry = True
        elif opcode == 'and a':
            carry = False
            zero = a == 0
        elif opcode == 'ret':
            return carry
        else:
            raise ValueError(name + ' has unmodelled opcode: ' + opcode)
    raise ValueError(name + ' does not terminate in 80 steps')


def check_route32_doorway(source: str) -> list[str]:
    """Exercise both returns for canonical and adversarial doorway inputs."""
    failures = []
    cases = (
        (6, 80, 'PLAYER_DIR_UP', True),
        (6, 80, 'PLAYER_DIR_DOWN', False),
        (6, 80, 'PLAYER_DIR_LEFT', False),
        (6, 80, 'PLAYER_DIR_RIGHT', False),
        (5, 80, 'PLAYER_DIR_UP', False),
        (7, 80, 'PLAYER_DIR_UP', False),
        (6, 79, 'PLAYER_DIR_UP', False),
        (6, 81, 'PLAYER_DIR_UP', False),
    )
    for x, y, direction, expected in cases:
        try:
            actual = _simulate_doorway(source, 'JohtoRoute32CaveEntranceCheck',
                                       'JohtoRoute32CaveWarpTileCheck', x, y, direction)
        except ValueError as exc:
            failures.append(str(exc))
            break
        if actual != expected:
            failures.append(f'Route32 cave entrance branch rejects/allows wrong input: '
                            f'({x},{y}) {direction}: expected {expected}, got {actual}')
    for x, y, expected in ((6, 79, True), (6, 80, False), (5, 79, False),
                           (7, 79, False), (6, 78, False)):
        try:
            actual = _simulate_doorway(source, 'JohtoRoute32CaveWarpTileCheck',
                                       'GetJohtoWarpArrivalStep', x, y, 'PLAYER_DIR_UP')
        except ValueError as exc:
            failures.append(str(exc))
            break
        if actual != expected:
            failures.append(f'Route32 cave Warp tile branch mismatch: ({x},{y}) '
                            f'expected {expected}, got {actual}')
    return failures


def audit(root: Path, gold: Path | None = None) -> list[str]:
    """Verify Kanto-style collision exit plus the one necessary outdoor step.

    Source/collision assertions are not a substitute for handset testing.
    """
    errors = []
    try:
        runtime = (root / INPUTS[0]).read_text()
        arrivals = profiles(runtime)
        movement = (root / INPUTS[1]).read_text()
        player = (root / INPUTS[4]).read_text()
        overworld = (root / INPUTS[3]).read_text()
        tile_ids = (root / INPUTS[-1]).read_text()
        outside = (root / 'data/mapObjects/JohtoRoute32.asm').read_text()
        cave = (root / 'data/mapObjects/JohtoUnionCave1F.asm').read_text()
    except (ValueError, OSError) as exc:
        return [str(exc)]

    errors.extend(check_route32_doorway(runtime))

    expected = ('JOHTO_ROUTE_32', 'JOHTO_ROUTE_32_LOCAL_ID',
                79, 6, 'REGION_NATIVE_MAP_SLOT', 'D_DOWN')
    expected33 = ('REGION_NATIVE_MAP_SLOT', 'JOHTO_ROUTE_33_LOCAL_ID',
                  9, 11, 'REGION_NATIVE_MAP_SLOT', 'D_DOWN')
    if arrivals != [expected, expected33]:
        errors.append('Route32 and Route33 each require exact outdoor arrival step, cave cannot auto-step')
    if (not registered_warp(outside, 6, 79)
            or not registered_warp(cave, 17, 3)
            or not registered_warp(cave, 17, 31)):
        errors.append('original Gold cave and Route32 Warp coordinates must remain registered')
    if not walkable(root, 'JohtoRoute32', 'johto', 10, 6, 80):
        errors.append('Route32 automatic step destination is not walkable')
    if (not walkable(root, 'JohtoUnionCave1F', 'johto_union_cave', 10, 17, 3)
            or walkable(root, 'JohtoUnionCave1F', 'johto_union_cave', 10, 17, 4)
            or not walkable(root, 'JohtoUnionCave1F', 'johto_union_cave', 10, 17, 31)
            or walkable(root, 'JohtoUnionCave1F', 'johto_union_cave', 10, 17, 32)):
        errors.append('cave must have walkable Warp (17,3) with a solid south wall (17,4)')
    if gold is not None:
        for name, pos in (('Route32', (6, 79)), ('UnionCave1F', (17, 3)),
                          ('UnionCave1F', (17, 31)), ('Route33', (11, 9))):
            try:
                if pos not in gold_warps(gold, name):
                    errors.append(name + ': Warp not found in original Gold map')
            except OSError:
                errors.append(name + ': Gold Warp source unavailable')

    door = movement.split('PlayerStepOutFromDoor:', 1)[-1].split('_EndNPCMovementScript:', 1)[0]
    if (not re.search(r'callab GetJohtoWarpArrivalStep[\s\S]*?ld a, e[\s\S]*?jr nz, \.stepFromProfile', door)
            or not re.search(r'\.stepFromProfile\s+push af[\s\S]*?pop af\s+ld \[wSimulatedJoypadStatesEnd\], a', door)
            or 'call IsPlayerStandingOnDoorTile' not in door):
        errors.append('native outdoor arrival and original RPP door step dispatch mismatch')
    if ('ld a, [wCurRegion]' not in runtime.split('GetJohtoWarpArrivalStep::', 1)[-1].split('GetJohtoCaveMapChangeSFX::', 1)[0]
            or 'ld a, [wWarpedFromWhichMap]' not in runtime.split('GetJohtoWarpArrivalStep::', 1)[-1].split('GetJohtoCaveMapChangeSFX::', 1)[0]):
        errors.append('outdoor arrival must guard region and incoming source')

    if not re.search(r'JohtoUnionCaveWarpTileIDs:\s*db\s+\$FF', tile_ids):
        errors.append('Union Cave floor must not be a step-on Warp')
    if 'GetJohtoWalkOnWarpAllowed' in runtime + player:
        errors.append('old cave direction-filtered step-on Warp path remains')
    warp_step = player.split('IsPlayerStandingOnDoorTileOrWarpTile:', 1)[-1].split('INCLUDE "data/warp_tile_ids.asm"', 1)[0]
    if ('callba JohtoRoute32CaveWarpTileCheck' not in warp_step
            or 'callba JohtoRoute33CaveWarpTileCheck' not in warp_step
            or not re.search(r'call IsInArray\s+jr nc, \.done[\s\S]*?ld hl, wd736\s+res 2, \[hl\]\s+scf', warp_step)):
        errors.append('Route32 must step onto exact Warp; standard Warp floor check must remain')

    face = player.split('IsPlayerFacingEdgeOfMap:', 1)[-1].split('IsWarpTileInFrontOfPlayer:', 1)[0]
    down = face.split('\n.facingDown\n', 1)[-1].split('\n.facingUp\n', 1)[0]
    for token in ('cp REGION_NATIVE_MAP_SLOT', 'cp MAP_REGION_JOHTO',
                  'cp JOHTO_UNION_CAVE_1F_LOCAL_ID', 'cp 17', 'cp 3', 'cp 31',
                  'jr z, .setCarry', '.normalDownEdge', 'ld a, [wCurMapHeight]'):
        if token not in down:
            errors.append('missing targeted Union Cave DOWN collision guard: ' + token)
    if not re.search(r'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\s+jr nz, \.normalDownEdge\s+ld a, c\s+cp 17\s+jr nz, \.normalDownEdge\s+ld a, b\s+cp 3\s+jr z, \.setCarry[\s\S]*?cp 31\s+jr z, \.setCarry', down):
        errors.append('cave DOWN collision Warp must require exact x=17,y=3/31')
    extra = overworld.split('ExtraWarpCheck::', 1)[-1].split('MapEntryAfterBattle::', 1)[0]
    if 'ld hl, IsPlayerFacingEdgeOfMap' not in extra or 'cp JOHTO_UNION_CAVE' in extra:
        errors.append('cave must use original RPP facing-edge collision check')
    collision = overworld.split('CollisionCheckOnLand::', 1)[-1].split('CheckTilePassable::', 1)[0]
    if ('JohtoRoute32CaveEntranceCheck' not in collision
            or 'call CheckTilePassable' not in collision):
        errors.append('Route32 must enter the exact mouth despite its solid graphic')
    status = player.split('IsPlayerStandingOnWarp:', 1)[-1].split('CheckForceBikeOrSurf:', 1)[0]
    if not re.search(r'ld hl, wd736\s+set 2, \[hl\]', status):
        errors.append('entering cave must arm the standing-on-warp collision flag')
    if 'JohtoUnionCaveExitCheck' in runtime + extra:
        errors.append('obsolete UP exit route remains')
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp', type=Path, required=True)
    parser.add_argument('--gold', type=Path)
    args = parser.parse_args()
    failures = audit(args.rpp, args.gold)
    for item in failures:
        print('ERROR:', item)
    print('native Warp arrival audit:', 'FAIL' if failures else 'PASS')
    return 1 if failures else 0


if __name__ == '__main__':
    raise SystemExit(main())
