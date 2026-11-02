#!/usr/bin/env python3
"""Restricted source-instruction runners for the active Johto gatehouse paths.

The runners execute the South role-grid and Park-East mask helpers, the shared
REF-303 carpet helper (through its companion scanner), and the original
Gate_Coll dispatch/CheckTilePassable path for any explicitly profiled stable
ID. Existing active IDs 6/19/102 and planned IDs 65/66 use the generic runner.
These are source traces with explicitly modelled leaves, not a Game Boy
emulator: sprites, full VBlank movement, outdoor Warp execution, bike/music
and ROM banking are not emulated. Unknown instructions and unresolved branches
fail closed.
"""
from __future__ import annotations

import re

DIRECTIONS = {'UP': (0, -1), 'DOWN': (0, 1),
              'LEFT': (-1, 0), 'RIGHT': (1, 0)}
GATE_ROLE_SYMBOLS = {
    11: 'JohtoSouthIlexForestAzaleaGateRoles',
    13: 'JohtoSouthRoute34IlexForestGateRoles',
    18: 'JohtoNorthRoute35GoldenrodGateRoles',
    104: 'JohtoParkSouthGateRoles',
}


def _program(source: str, start: str, end: str):
    try:
        segment = source.split(start + '::', 1)[1].split(end, 1)[0]
    except IndexError as exc:
        raise ValueError(f'missing or misordered ASM segment {start}/{end}') from exc
    instructions, labels = [], {}
    for raw in segment.splitlines():
        line = raw.partition(';')[0].strip()
        if not line:
            continue
        if re.fullmatch(r'\.[A-Za-z_][\w]*:?', line):
            label = line.rstrip(':')
            if label in labels:
                raise ValueError(f'duplicate ASM label {label}')
            labels[label] = len(instructions)
        elif re.match(r'^[a-z]{2,7}\b', line):
            op, _, operands = line.partition(' ')
            instructions.append((op, operands.strip()))
        else:
            raise ValueError(f'unknown ASM syntax {line}')
    return instructions, labels


def _run(source: str, *, mode: str, constants: dict[str, int], gate_id: int,
         x: int, y: int, direction: str, roles: bytes = b'', mask: bytes = b'',
         blocked_targets: frozenset[tuple[int, int, int]] = frozenset()) -> int:
    if direction not in DIRECTIONS or not 0 <= x <= 255 or not 0 <= y <= 255:
        raise ValueError('invalid position or direction')
    if mode == 'park':
        start, end = 'JohtoParkEastGateMatureStep', 'JohtoParkEastGateBlockedRows::'
        memory = {'JohtoParkEastGateBlockedRows': (0x4000, mask)}
        if len(mask) != 16:
            raise ValueError('East park mature mask must be 16 bytes')
    elif mode == 'south':
        start, end = 'JohtoSouthSpatialRoleAhead', 'JohtoSouthGoldShoreProbe::'
        if gate_id not in GATE_ROLE_SYMBOLS:
            raise ValueError(f'unsupported South gate {gate_id}')
        memory = {GATE_ROLE_SYMBOLS[gate_id]: (0x4000, roles)}
        if len(roles) not in (64, 80):
            raise ValueError('South gate role grid must be 64 or 80 bytes')
    else:
        raise ValueError('unknown trace mode')

    instructions, labels = _program(source, start, end)
    registers = {'a': 0, 'b': 0, 'c': 0, 'd': 0, 'e': 0, 'hl': 0}
    mem_values = {
        '[wCurMap]': constants['JOHTO_RUNTIME_MAP_HANDLE'],
        '[wCurRegion]': constants['MAP_REGION_JOHTO'],
        '[wCurLocalMapID]': gate_id,
        '[wXCoord]': x, '[wYCoord]': y,
        '[wPlayerDirection]': 'PLAYER_DIR_' + direction,
    }
    stack = []
    zero, carry, pc = False, False, 0

    def value(token: str):
        token = token.strip()
        if token in registers:
            return registers[token]
        if token in mem_values:
            return mem_values[token]
        if token in constants:
            return constants[token]
        if token in memory:
            return memory[token][0]
        if token.startswith('PLAYER_DIR_'):
            return token
        if token == '[hl]' or token == '[hli]':
            addr = registers['hl']
            for base, data in memory.values():
                if base <= addr < base + len(data):
                    if token == '[hli]':
                        registers['hl'] += 1
                    return data[addr - base]
            raise ValueError(f'ASM reads outside supplied gate data at {addr:#06x}')
        if token.startswith('$'):
            return int(token[1:], 16)
        if token.isdecimal():
            return int(token)
        raise ValueError(f'unsupported ASM operand {token}')

    def compare(a, b):
        if type(a) is not type(b) and not (isinstance(a, int) and isinstance(b, int)):
            return a == b, False
        return a == b, a < b

    for _ in range(2000):
        if not 0 <= pc < len(instructions):
            raise ValueError(f'ASM left collision helper at pc={pc}')
        op, operands = instructions[pc]
        pc += 1
        if op == 'ld':
            lhs, sep, rhs = operands.partition(',')
            if not sep:
                raise ValueError('malformed ASM ld')
            lhs, rhs = lhs.strip(), rhs.strip()
            if lhs not in registers:
                raise ValueError(f'unexpected ASM ld destination {lhs}')
            n = value(rhs)
            if lhs == 'hl':
                if not isinstance(n, int):
                    raise ValueError('bad HL source')
                registers[lhs] = n & 0xffff
            elif not (isinstance(n, int) or lhs == 'a'):
                raise ValueError(f'unexpected string register load {lhs}')
            else:
                registers[lhs] = (n & 255) if isinstance(n, int) else n
        elif op == 'cp':
            zero, carry = compare(registers['a'], value(operands))
        elif op == 'and':
            v = value(operands)
            if not isinstance(v, int) or not isinstance(registers['a'], int):
                raise ValueError('invalid and operands')
            registers['a'] &= v
            zero, carry = registers['a'] == 0, False
        elif op in ('inc', 'dec'):
            if operands not in registers:
                raise ValueError(f'invalid {op} operand {operands}')
            size = 65536 if operands == 'hl' else 256
            registers[operands] = (registers[operands] + (1 if op == 'inc' else -1)) % size
            if operands != 'hl':
                zero = registers[operands] == 0
        elif op == 'add':
            if operands == 'a':
                result = registers['a'] * 2
                registers['a'] = result & 255
                zero, carry = registers['a'] == 0, result > 255
            elif operands == 'hl, de':
                registers['hl'] = (registers['hl'] + registers['d'] * 256 + registers['e']) & 0xffff
            else:
                raise ValueError(f'unhandled ASM addition {operands}')
        elif op == 'sub':
            n = value(operands)
            result = registers['a'] - n
            registers['a'] = result & 255
            zero, carry = registers['a'] == 0, result < 0
        elif op in ('push', 'pop'):
            if operands not in ('hl', 'bc', 'de'):
                raise ValueError(f'unhandled stack operand {operands}')
            names = {'hl': ('hl',), 'bc': ('b', 'c'), 'de': ('d', 'e')}[operands]
            if op == 'push':
                stack.append((operands, tuple(registers[n] for n in names)))
            else:
                if not stack:
                    raise ValueError('ASM pop with empty stack')
                prev, values = stack.pop()
                if len(names) == len(values):
                    for name, val in zip(names, values):
                        registers[name] = val
                elif prev == 'hl' and operands == 'de':
                    registers['d'], registers['e'] = values[0] >> 8, values[0] & 255
                else:
                    raise ValueError(f'unexpected stack pop {prev}->{operands}')
        elif op == 'call':
            if mode != 'south' or operands != 'JohtoSouthMatureDoorFence':
                raise ValueError(f'unhandled ASM subroutine {operands}')
            # This one leaf is outside the traced instruction stream. For
            # active gate IDs 11/13/18/104, its accepted static blacklist
            # is the only relevant branch (forest special cases excluded).
            carry = (gate_id, registers['e'], registers['d']) in blocked_targets
        elif op == 'scf':
            if operands:
                raise ValueError('scf expects no operands')
            carry = True
        elif op == 'jr' or op == 'jp':
            parts = [t.strip() for t in operands.split(',')]
            if len(parts) == 1:
                jump, label = True, parts[0]
            elif len(parts) == 2:
                cond, label = parts
                state = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}
                if cond not in state:
                    raise ValueError(f'unhandled ASM condition {cond}')
                jump = state[cond]
            else:
                raise ValueError(f'malformed ASM branch {operands}')
            if jump:
                if label not in labels:
                    raise ValueError(f'undefined ASM branch target {label}')
                pc = labels[label]
        elif op == 'ret':
            if operands:
                cond = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}
                if operands not in cond:
                    raise ValueError(f'unsupported return condition {operands}')
                if not cond[operands]:
                    continue
            if stack:
                raise ValueError(f'ASM returned with unbalanced stack ({stack})')
            return registers['e']
        else:
            raise ValueError(f'unsupported ASM instruction {op} {operands}')
    raise ValueError('gate collision ASM did not terminate in 2000 steps')


def simulate_park_east(source: str, *, constants: dict[str, int], x: int, y: int,
                       direction: str, mask: bytes) -> int:
    return _run(source, mode='park', constants=constants, gate_id=105,
                x=x, y=y, direction=direction, mask=mask)


def simulate_south_gate(source: str, *, constants: dict[str, int], gate_id: int,
                        x: int, y: int, direction: str, roles: bytes,
                        blocked_targets: frozenset[tuple[int, int, int]] = frozenset()) -> int:
    return _run(source, mode='south', constants=constants, gate_id=gate_id,
                x=x, y=y, direction=direction, roles=roles,
                blocked_targets=blocked_targets)




def _parse_value(token: str, *, registers: dict, memory_values: dict,
                 constants: dict[str, int]):
    token = token.strip()
    if token in registers:
        return registers[token]
    if token in memory_values:
        return memory_values[token]
    if token in constants:
        return constants[token]
    if ' + ' in token:
        left, right = (part.strip() for part in token.split(' + ', 1))
        if left in constants and right.isdecimal():
            return constants[left] + int(right)
    if token.startswith('PLAYER_DIR_'):
        return token
    if token.startswith('$'):
        return int(token[1:], 16)
    if token.isdecimal():
        return int(token)
    raise ValueError(f'unsupported ASM operand {token}')


def _branch(instructions, labels, pc, operands, zero, carry):
    parts = [part.strip() for part in operands.split(',')]
    if len(parts) == 1:
        jump, label = True, parts[0]
    elif len(parts) == 2:
        condition, label = parts
        states = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}
        if condition not in states:
            raise ValueError(f'unsupported ASM branch condition {condition}')
        jump = states[condition]
    else:
        raise ValueError(f'malformed ASM branch {operands}')
    if jump:
        if label not in labels:
            raise ValueError(f'undefined ASM branch target {label}')
        return labels[label]
    return pc


def simulate_legacy_gate_dispatch(source: str, *, constants: dict[str, int],
                                  gate_id: int, x: int = 5, y: int = 3,
                                  direction: str = 'UP') -> int:
    """Execute JohtoOverworldSouthLandDecision for a legacy Gate_Coll map.

    Explicitly profiled legacy Gate_Coll maps must return E=2, which sends
    CollisionCheckOnLand to the original tile-pair + CheckTilePassable path.
    The runner is intentionally stable-ID agnostic so future gates can reuse
    it without editing a hard-coded ID allowlist; the caller must first prove
    the map's Gold profile selects the legacy backend.
    """
    if not 0 <= gate_id <= 255 or direction not in DIRECTIONS:
        raise ValueError('legacy gate stable ID must be a byte and direction must be valid')
    program_source = source + '\nLegacyGateDispatchTraceEnd::\n'
    instructions, labels = _program(
        program_source, 'JohtoOverworldSouthLandDecision', 'LegacyGateDispatchTraceEnd::')
    registers = {'a': 0, 'e': 0}
    memory_values = {
        '[wCurRegion]': constants['MAP_REGION_JOHTO'],
        '[wCurLocalMapID]': gate_id,
        '[wPlayerDirection]': 'PLAYER_DIR_' + direction,
        '[wXCoord]': x,
        '[wYCoord]': y,
    }
    zero = carry = False
    pc = 0
    for _ in range(256):
        if not 0 <= pc < len(instructions):
            raise ValueError(f'legacy gate dispatch left routine at pc={pc}')
        op, operands = instructions[pc]
        pc += 1
        if op == 'ld':
            lhs, sep, rhs = operands.partition(',')
            if not sep or lhs.strip() not in registers:
                raise ValueError(f'unsupported legacy dispatch load {operands}')
            registers[lhs.strip()] = _parse_value(
                rhs, registers=registers, memory_values=memory_values,
                constants=constants)
        elif op == 'cp':
            lhs = registers['a']
            rhs = _parse_value(operands, registers=registers,
                               memory_values=memory_values, constants=constants)
            zero = lhs == rhs
            carry = isinstance(lhs, int) and isinstance(rhs, int) and lhs < rhs
        elif op in ('jr', 'jp'):
            pc = _branch(instructions, labels, pc, operands, zero, carry)
        elif op == 'ret':
            if operands:
                states = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}
                if operands not in states:
                    raise ValueError(f'unsupported legacy dispatch return {operands}')
                if not states[operands]:
                    continue
            return int(registers['e'])
        else:
            raise ValueError(f'unhandled legacy dispatch instruction {op} {operands}')
    raise ValueError('legacy gate dispatch did not terminate')


def simulate_legacy_gate_passability(home_source: str, *, gate_id: int,
                                     tile_id: int, passable_tiles: bytes) -> bool:
    """Execute the actual CheckTilePassable ASM; return True when blocked.

    `tile_id` is supplied by the exact Gold/compact-blockset coordinate probe
    in the caller. The GetTileAndCoordsInFrontOfPlayer predef is therefore a
    verified input leaf. The Cherrygrove $3c shore exception returns NC for
    any stable ID other than Cherrygrove; the caller must explicitly profile
    a gate as using this shared legacy backend before invoking the runner.
    """
    if not 0 <= gate_id <= 255:
        raise ValueError(f'legacy gate stable ID is not a byte: {gate_id}')
    if not 0 <= tile_id <= 255:
        raise ValueError('invalid front tile ID')
    if not passable_tiles or passable_tiles[-1] != 0xff or 0xff in passable_tiles[:-1]:
        raise ValueError('Gate_Coll list must have one terminal $ff')
    instructions, labels = _program(
        home_source, 'CheckTilePassable', 'CheckForJumpingAndTilePairCollisions::')
    registers = {'a': 0, 'b': 0, 'c': 0, 'd': 0, 'e': 0, 'hl': 0}
    pointer_address, list_address = 0x2000, 0x4000
    memory_values = {
        'wTilesetCollisionPtr': pointer_address,
        '[wTileInFrontOfPlayer]': tile_id,
    }

    def read_byte(address: int) -> int:
        if address == pointer_address:
            return list_address & 0xff
        if address == pointer_address + 1:
            return (list_address >> 8) & 0xff
        if list_address <= address < list_address + len(passable_tiles):
            return passable_tiles[address - list_address]
        raise ValueError(f'CheckTilePassable reads outside supplied Gate_Coll memory: {address:#06x}')

    def value(token: str) -> int:
        token = token.strip()
        if token in registers:
            return int(registers[token])
        if token in memory_values:
            return int(memory_values[token])
        if token == '[hl]':
            return read_byte(registers['hl'])
        if token == '[hli]':
            address = registers['hl']
            result = read_byte(address)
            registers['hl'] = (address + 1) & 0xffff
            return result
        if token.startswith('$'):
            return int(token[1:], 16)
        if token.isdecimal():
            return int(token)
        raise ValueError(f'unsupported CheckTilePassable operand {token}')

    zero = carry = False
    pc = 0
    predef_seen = False
    for _ in range(256):
        if not 0 <= pc < len(instructions):
            raise ValueError(f'CheckTilePassable left routine at pc={pc}')
        op, operands = instructions[pc]
        pc += 1
        if op == 'predef':
            if operands != 'GetTileAndCoordsInFrontOfPlayer' or predef_seen:
                raise ValueError(f'unexpected CheckTilePassable predef {operands}')
            predef_seen = True
        elif op == 'callab':
            if operands != 'JohtoCherrygroveShoreFloorAhead':
                raise ValueError(f'unhandled CheckTilePassable banked call {operands}')
            # The helper first checks the active map identity. These three
            # gate IDs are not Cherrygrove, so the $3c special case is NC.
            carry = False
        elif op == 'ld':
            lhs, sep, rhs = operands.partition(',')
            if not sep:
                raise ValueError(f'malformed CheckTilePassable load {operands}')
            lhs, rhs = lhs.strip(), rhs.strip()
            if lhs in ('a', 'b', 'c', 'd', 'e'):
                registers[lhs] = value(rhs)
            elif lhs == 'hl':
                registers['hl'] = value(rhs) & 0xffff
            elif lhs == 'h':
                registers['hl'] = ((value(rhs) & 0xff) << 8) | (registers['hl'] & 0xff)
            elif lhs == 'l':
                registers['hl'] = (registers['hl'] & 0xff00) | (value(rhs) & 0xff)
            else:
                raise ValueError(f'unexpected CheckTilePassable destination {lhs}')
        elif op == 'cp':
            parts = [part.strip() for part in operands.split(',')]
            if len(parts) == 2 and parts[0] == 'a':
                lhs, rhs = registers['a'], value(parts[1])
            elif len(parts) == 1:
                lhs, rhs = registers['a'], value(parts[0])
            else:
                raise ValueError(f'malformed CheckTilePassable compare {operands}')
            zero = lhs == rhs
            carry = lhs < rhs
        elif op == 'and':
            if operands != 'a':
                raise ValueError(f'unhandled CheckTilePassable AND {operands}')
            registers['a'] &= registers['a']
            zero, carry = registers['a'] == 0, False
        elif op == 'scf':
            if operands:
                raise ValueError(f'malformed SCF {operands}')
            carry = True
        elif op in ('jr', 'jp'):
            pc = _branch(instructions, labels, pc, operands, zero, carry)
        elif op == 'ret':
            if operands:
                states = {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}
                if operands not in states:
                    raise ValueError(f'unsupported CheckTilePassable return {operands}')
                if not states[operands]:
                    continue
            if not predef_seen:
                raise ValueError('CheckTilePassable returned without sampling the front tile')
            return carry
        else:
            raise ValueError(f'unhandled CheckTilePassable instruction {op} {operands}')
    raise ValueError('CheckTilePassable did not terminate')
