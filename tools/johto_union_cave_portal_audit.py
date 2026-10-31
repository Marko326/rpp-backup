#!/usr/bin/env python3
"""Static/fail-closed audit of the FIRST active Union Cave 1F entrance.

Gold: Route32 (6,79) is CAVE, UnionCave1F (17,3) is a DOWN carpet
with a solid south wall at (17,4). RPP cave exit is COLLISION_ONLY
while standing on (17,3), not a STEP_ON door and not an auto-step.

This is not RGBDS or an emulator. With --gold-root it also verifies the
actual source collision roles independently of the RPP implementation.
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

REQUIRED = (
    'engine/johto_pilot_runtime.asm',
    'data/johto_union_cave_runtime.asm',
    'data/johto_route32_runtime.asm',
    'data/johto_route33_runtime.asm',
    'data/bike_riding_tilesets.asm',
    'data/warp_tile_ids.asm',
    'engine/overworld/doors.asm',
    'home/overworld.asm',
)


def _section(text: str, start: str, end: str | None) -> str:
    prefix = text.split(start + '::', 1)
    if len(prefix) != 2:
        raise ValueError('missing/duplicate start label ' + start)
    rest = prefix[1]
    if end:
        pair = rest.split(end + '::', 1)
        if len(pair) != 2:
            raise ValueError('missing/duplicate end label ' + end)
        return pair[0]
    return rest


def _instructions(src: str) -> str:
    """Strip comments and blank lines so predicates are checked as code."""
    return '\n'.join(line.strip() for line in src.splitlines()
                     if line.split(';', 1)[0].strip()
                     for line in [line.split(';', 1)[0]])


# Numeric stable IDs are taken from the frozen map registry.
# Using exact numeric CP semantics here prevents new south-map range guards
# from being mistaken for unreachable legacy cave branches.
_TRACE_LOCAL_IDS = {
    'JOHTO_UNION_CAVE_1F_LOCAL_ID': 8, 'JOHTO_ROUTE_33_LOCAL_ID': 9,
    'JOHTO_AZALEA_TOWN_LOCAL_ID': 10, 'JOHTO_ILEX_AZALEA_GATE_LOCAL_ID': 11,
    'JOHTO_ILEX_FOREST_LOCAL_ID': 12, 'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID': 13,
    'JOHTO_ROUTE_34_LOCAL_ID': 14, 'JOHTO_GOLDENROD_CITY_LOCAL_ID': 15,
}
def _trace_cp_operands(a, operand):
    def numeric(value):
        if isinstance(value, int): return value
        if value in _TRACE_LOCAL_IDS: return _TRACE_LOCAL_IDS[value]
        m = re.fullmatch(r'(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s*\+\s*(\d+)', str(value))
        if m and m[1] in _TRACE_LOCAL_IDS: return _TRACE_LOCAL_IDS[m[1]] + int(m[2])
        return None
    aa, bb = numeric(a), numeric(operand)
    if aa is not None and bb is not None:
        return aa == bb, aa < bb
    return a == operand, False


def _trace_cave_exit_predicates(runtime: str, direction: str, x: int, y: int,
                                local: str = 'JOHTO_UNION_CAVE_1F_LOCAL_ID') -> int:
    """Execute the actual cave path in both ROMX predicates, not a prose contract.

    Only a deliberately tiny set of RGBDS instructions is understood. Unknown
    instructions, labels, branches, nonterminating paths must raise (fail closed).
    This is NOT a CPU or ROM emulator and cannot replace user hardware tests.
    """
    functions = ('JohtoPilotGateExteriorCollisionAllowed',
                 'JohtoPilotGateCollisionExitAllowed')
    program, labels = [], {}
    for name in functions:
        source = _instructions(_section(runtime, name,
                               'JohtoPilotGateCollisionExitAllowed' if name == functions[0] else None))
        labels[name] = len(program)
        for line in source.splitlines():
            if re.fullmatch(r'\.[A-Za-z_][A-Za-z0-9_.]*:?', line):
                labels[name + line.rstrip(':')] = len(program)
            else:
                program.append((name, line))
    state = {'wCurMap': 'JOHTO_RUNTIME_MAP_HANDLE',
             'wCurRegion': 'MAP_REGION_JOHTO',
             'wCurLocalMapID': local, 'wPlayerDirection': direction,
             'wXCoord': x, 'wYCoord': y}
    registers = {'a': None, 'e': None}
    zero = False
    carry = False
    pc = labels[functions[0]]
    for _ in range(180):
        if not (0 <= pc < len(program)):
            raise ValueError('predicate fell outside known code')
        scope, line = program[pc]
        pc += 1
        op, _, arg = line.partition(' ')
        op = op.lower()
        arg = arg.strip()
        if op == 'ld':
            dest, sep, val = arg.partition(',')
            if not sep or dest.strip() not in registers:
                raise ValueError('unsupported ld ' + line)
            dest, val = dest.strip(), val.strip()
            if val.startswith('[') and val.endswith(']'):
                val = state[val[1:-1]]
            elif val in registers:
                val = registers[val]
            elif val.isdecimal():
                val = int(val)
            elif val.startswith('$'):
                val = int(val[1:], 16)
            else:
                raise ValueError('unsupported ld value ' + line)
            registers[dest] = val
        elif op == 'cp':
            value = int(arg) if arg.isdecimal() else arg
            zero, carry = _trace_cp_operands(registers['a'], value)
        elif op in ('jp', 'jr', 'ret'):
            args = [a.strip() for a in arg.split(',')] if arg else []
            condition = None
            if args and args[0] in ('z', 'nz', 'c', 'nc'):
                condition = args.pop(0)
            take = condition is None or {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}[condition]
            if take:
                if op == 'ret':
                    if args:
                        raise ValueError('unsupported ret args')
                    return registers['e']
                if len(args) != 1:
                    raise ValueError('unsupported branch ' + line)
                label = scope + args[0] if args[0].startswith('.') else args[0]
                if label not in labels:
                    raise ValueError('unknown branch target ' + label)
                pc = labels[label]
        elif op == 'and' and arg == 'a':
            zero = not registers['a']
            carry = False
        else:
            raise ValueError('unsupported predicate instruction ' + line)
    raise ValueError('predicate ran for more than 180 instructions')


def _trace_arrival_step(runtime: str, local: str, x: int, y: int) -> tuple[object, bool]:
    """Execute the small verified arrival decision, including its actual branches.

    Detect any write to the three facing registers rather than trusting a
    marker/comment. No emulation of the ROM or sprite renderer is implied.
    """
    source = _instructions(_section(runtime, 'JohtoPilotGateArrivalStep',
                                    'JohtoPilotGateDoorApproachAllowed'))
    program, labels = [], {}
    for line in source.splitlines():
        if re.fullmatch(r'\.[A-Za-z_][A-Za-z0-9_.]*:?', line):
            labels[line.rstrip(':')] = len(program)
        else:
            program.append(line)
    state = {'wCurMap': 'JOHTO_RUNTIME_MAP_HANDLE',
             'wCurRegion': 'MAP_REGION_JOHTO',
             'wCurLocalMapID': local, 'wXCoord': x, 'wYCoord': y,
             'wPlayerDirection': 'PLAYER_DIR_UP',
             'wPlayerMovingDirection': 'PLAYER_DIR_UP',
             'wSpriteStateData1 + 9': 'SPRITE_FACING_UP'}
    registers = {'a': None, 'e': None}
    zero = False
    carry = False
    pc = 0
    for _ in range(80):
        if not (0 <= pc < len(program)):
            raise ValueError('arrival exited source without ret')
        line = program[pc]
        pc += 1
        op, _, arg = line.partition(' ')
        op, arg = op.lower(), arg.strip()
        if op == 'ld':
            dest, sep, val = arg.partition(',')
            if not sep:
                raise ValueError('invalid arrival ld: ' + line)
            dest, val = dest.strip(), val.strip()
            if dest.startswith('['):
                # For this no-step profile even a "helpful" forced UP is a
                # regression: the engine already has the player's heading.
                raise ValueError('arrival must not change player state: ' + line)
            if dest not in registers:
                raise ValueError('unknown arrival register: ' + line)
            if val.startswith('[') and val.endswith(']'):
                val = state[val[1:-1]]
            elif val in registers:
                val = registers[val]
            elif val.isdecimal():
                val = int(val)
            elif val != 'D_DOWN':
                raise ValueError('unsupported arrival operand: ' + line)
            registers[dest] = val
        elif op == 'cp':
            test = int(arg) if arg.isdecimal() else arg
            zero, carry = _trace_cp_operands(registers['a'], test)
        elif op == 'and' and arg == 'a':
            zero = not registers['a']
            carry = False
        elif op in ('jr', 'jp', 'ret'):
            args = [v.strip() for v in arg.split(',')] if arg else []
            cond = args.pop(0) if args and args[0] in ('z', 'nz', 'c', 'nc') else None
            take = cond is None or {'z': zero, 'nz': not zero, 'c': carry, 'nc': not carry}[cond]
            if take:
                if op == 'ret':
                    if args:
                        raise ValueError('unsupported arrival return: ' + line)
                    return registers['e'], True
                if len(args) != 1 or args[0] not in labels:
                    raise ValueError('unregistered arrival jump: ' + line)
                pc = labels[args[0]]
        else:
            raise ValueError('unknown arrival instruction: ' + line)
    raise ValueError('arrival exceeded 80 instructions')


def audit(root: Path, gold_root: Path | None = None) -> dict:
    root = Path(root).resolve()
    checks, errors = [], []

    def check(name: str, ok: bool, detail: str):
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
        if not ok:
            errors.append(name + ': ' + detail)

    try:
        files = {key: (root / key).read_text(encoding='utf-8') for key in REQUIRED}
        runtime = files[REQUIRED[0]]
        arrival = _instructions(_section(runtime, 'JohtoPilotGateArrivalStep', 'JohtoPilotGateDoorApproachAllowed'))
        approach = _instructions(_section(runtime, 'JohtoPilotGateDoorApproachAllowed', 'JohtoPilotGateDoorWarpMatched'))
        step_on = _instructions(_section(runtime, 'JohtoPilotGateDoorWarpMatched', 'JohtoPilotGateExteriorCollisionAllowed'))
        collision = _instructions(_section(runtime, 'JohtoPilotGateCollisionExitAllowed', None))
        cave_exit = collision.split('.unionCaveExit', 1)[1].split('.northGateBottom', 1)[0]
        routes = _instructions(_section(runtime, 'JohtoRegisteredWarpRoutes', 'JohtoRegisteredWarpRoutesEnd'))
        bike = _instructions(_section(files['data/bike_riding_tilesets.asm'], 'BikeRidingTilesets', None))
        cave_objects = _instructions(_section(files['data/johto_union_cave_runtime.asm'], 'JohtoUnionCave1FRuntimeObjects', None))
        route_objects = _instructions(_section(files['data/johto_route32_runtime.asm'], 'JohtoPilotRoute32RuntimeObjects', None))
        route33_objects = _instructions(_section(files['data/johto_route33_runtime.asm'], 'JohtoRoute33RuntimeObjects', 'JohtoRoute33BlockedCells'))
        exterior = _instructions(_section(runtime, 'JohtoPilotGateExteriorCollisionAllowed', 'JohtoPilotGateCollisionExitAllowed'))
        extra = _instructions(_section(files['home/overworld.asm'], 'ExtraWarpCheck', 'MapEntryAfterBattle'))
        home = _instructions(files['home/overworld.asm'])
    except (OSError, ValueError, IndexError) as exc:
        return {'schema': 'johto-union-cave-portal-audit-v1', 'status': 'FAIL',
                'checks': checks, 'errors': [str(exc)], 'rom_built': False}

    # The Gold cave arrives from Route32 facing UP. E=0 makes the stock
    # PlayerStepOutFromDoor skip simulation, and the existing movement engine
    # retains the incoming direction. A forced UP is as wrong architecturally
    # as a forced DOWN: neither cave arrival should write player facing state.
    check('cave_interior_no_arrival_autostep',
          bool(re.search(r'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\s+ret z', arrival)) and
          not re.search(r'(?m)^\.caveFacing\b', arrival) and
          not re.search(r'ld \[w(?:PlayerDirection|PlayerMovingDirection|SpriteStateData1 \+ 9)\]', arrival) and
          not re.search(r'\b(?:PLAYER_DIR_(?:UP|DOWN)|SPRITE_FACING_(?:UP|DOWN))\b', arrival),
          'Gold cave carpet returns E=0 and preserves the incoming UP facing; no auto-step or forced sprite direction')
    try:
        route32 = 'JOHTO_ROUTE_32_LOCAL_ID'
        cave = 'JOHTO_UNION_CAVE_1F_LOCAL_ID'
        probes = [(cave, 17, 3, 0), (cave, 17, 2, 0),
                  (route32, 6, 79, 'D_DOWN'), (route32, 6, 80, 0),
                  ('JOHTO_ROUTE_33_LOCAL_ID', 11, 9, 'D_DOWN'),
                  ('JOHTO_ROUTE_33_LOCAL_ID', 11, 10, 0),
                  ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', 4, 0, 'D_DOWN'),
                  ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', 4, 7, 0),
                  ('JOHTO_RUINS_OF_ALPH_LOCAL_ID', 7, 5, 'D_DOWN')]
        arrivals = [(_trace_arrival_step(runtime, m, x, y), expect)
                    for m, x, y, expect in probes]
        check('executable_cave_arrival_preserves_direction',
              all(actual == (expected, True) for actual, expected in arrivals),
              f'executed cave, Route32 and existing DOOR arrival profiles: {arrivals}')
    except (ValueError, KeyError, TypeError) as exc:
        check('executable_cave_arrival_preserves_direction', False, str(exc))
    check('route32_outside_safety_step',
          bool(re.search(r'(?s)\.route32CaveLanding\s+ld a, \[wXCoord\]\s+cp 6\s+ret nz\s+ld a, \[wYCoord\]\s+cp 79\s+ret nz\s+jr \.down', arrival)),
          'only outdoor Route32 (6,79) needs arrival D_DOWN to safe (6,80)')
    for label, body in [('cave_not_step_on_collision_override', approach),
                        ('cave_not_step_on_warp', step_on)]:
        check(label,
              bool(re.search(r'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\s+ret z', body)) and
              '.unionCaveMouth' not in body,
              'cave interior warp must not bypass wall or trigger on step-on from (17,4)')

    # An old .263 checked the *final* warp guard but forgot that the
    # ExtraWarpCheck preflight is executed FIRST. This source would statically
    # pass and still never exit on hardware. Check the entire preflight chain.
    check('cave_prewrap_dispatch_reaches_final_guard',
          bool(re.search(r'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\s+jp z, JohtoPilotGateCollisionExitAllowed', exterior)),
          'cave ID must reach final exact-coordinate guard FROM the ExtraWarpCheck predicate')
    check('extra_warp_calls_registered_predicate_and_sets_carry',
          bool(re.search(r'cp JOHTO_RUNTIME_MAP_HANDLE.*?cp MAP_REGION_JOHTO.*?'
                         r'callab JohtoPilotGateExteriorCollisionAllowed\s+'
                         r'ld a, e\s+and a\s+jr z, \.legacyExtraWarp\s+scf\s+ret',
                         extra, re.S)),
          'ExtraWarpCheck must turn a permitted ROMX predicate into carry=1 (otherwise no collision Warp)')
    enter = home.split('EnterMap::', 1)[1].split('callab UpdateSeafoamEntranceSource', 1)[0]
    check('cave_warp_flag_rearmed_on_map_entry',
          bool(re.search(r'cp JOHTO_UNION_CAVE\s+jr nz,\.noJohtoCarpetArrival\s+'
                         r'\.armJohtoCarpetArrival\s+ld hl,wd736\s+res 2,\[hl\]\s+'
                         r'callba IsPlayerStandingOnWarp', enter)) and
          all(x in enter for x in ('cp JOHTO_HOUSE', 'cp JOHTO_GATE', 'cp JOHTO_SOUTH_GATE')),
          'EnterMap must arm cave carpet and the explicit south gates, then call standing-on-warp')
    no_collision = home.split('CheckWarpsNoCollision::',1)[1].split('call ExtraWarpCheck',1)[0]
    check('cave_carpet_no_step_on_warp_even_with_prewrap_enabled',
          bool(re.search(r'cp JOHTO_UNION_CAVE\s+jp z,CheckWarpsNoCollisionRetry2\s+'
                         r'push hl\s+push bc\s*$',no_collision, re.M)) and
          all(x in no_collision for x in ('cp JOHTO_HOUSE','cp JOHTO_GATE', 'cp JOHTO_SOUTH_GATE')),
          'CAVE must skip no-collision Warp even when new south-gate tilesets are present')
    check('collision_loop_reached_only_after_extra_carry',
          bool(re.search(r'bit 2,\[hl\].*?call ExtraWarpCheck.*?jp c,CheckWarpsCollision', home, re.S)) and
          bool(re.search(r'CheckWarpsCollision::.*?callab JohtoPilotGateCollisionExitAllowed\s+'
                         r'ld a, e\s+pop bc\s+pop hl\s+and a\s+jr z, \.retry2',
                         files['home/overworld.asm'], re.S)),
          'movement collision -> armed warp flag -> preflight carry -> final matching Warp')
    try:
        positive = _trace_cave_exit_predicates(runtime, 'PLAYER_DIR_DOWN', 17, 3)
        wrong = [(_trace_cave_exit_predicates(runtime, d, x, y), d, x, y)
                 for d, x, y in [('PLAYER_DIR_UP', 17, 3),
                                 ('PLAYER_DIR_LEFT', 17, 3),
                                 ('PLAYER_DIR_RIGHT', 17, 3),
                                 ('PLAYER_DIR_DOWN', 16, 3),
                                 ('PLAYER_DIR_DOWN', 18, 3),
                                 ('PLAYER_DIR_DOWN', 17, 2),
                                 ('PLAYER_DIR_DOWN', 17, 4)]]
        south = _trace_cave_exit_predicates(runtime, 'PLAYER_DIR_DOWN', 17, 31)
        south_wrong = [(_trace_cave_exit_predicates(runtime, d, x, y),d,x,y)
                       for d,x,y in [('PLAYER_DIR_UP',17,31),('PLAYER_DIR_LEFT',17,31),
                                      ('PLAYER_DIR_DOWN',16,31),('PLAYER_DIR_DOWN',17,30),
                                      ('PLAYER_DIR_DOWN',17,32)]]
        wrong_map = _trace_cave_exit_predicates(runtime, 'PLAYER_DIR_DOWN', 17, 3,
                                                'JOHTO_ROUTE_32_LOCAL_ID')
        check('executable_cave_prewrap_to_final_guard',
              positive == 1 and south == 1 and all(r == 0 for r, _, _, _ in wrong+south_wrong) and wrong_map == 0,
              f'actual ROMX predicate trace allowed={positive}; rejected={wrong}; wrong_map={wrong_map}')
    except (ValueError, KeyError, TypeError) as exc:
        check('executable_cave_prewrap_to_final_guard', False, str(exc))

    check('cave_exit_down_collision_from_exact_carpet',
          bool(re.search(r'(?s)ld e, 0\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wXCoord\]\s+cp 17\s+ret nz\s+ld a, \[wYCoord\]\s+cp 3\s+jr z, \.yes\s+cp 31\s+ret nz\s+jr \.yes', cave_exit)) and
          'PLAYER_DIR_UP' not in cave_exit,
          'only DOWN collision from cave (17,3) or (17,31) may exit; all other coordinates/directions denied')

    warp_row = re.findall(r'(?m)^db\s+3,\s*17,\s*2,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', cave_objects)
    south_warp = re.findall(r'(?m)^db\s+31,\s*17,\s*0,\s*JOHTO_REGISTERED_WARP_SELECTOR\b', cave_objects)
    check('only_gold_north_south_cave_warps_open',
          len(warp_row)==1 and len(south_warp)==1 and
          bool(re.search(r'(?m)^db\s+2\s*$', cave_objects)),
          'cave runtime exposes only north ordinal0 and south ordinal1')
    check('source_route32_warp',
          bool(re.search(r'db 79, 6, 0, JOHTO_REGISTERED_WARP_SELECTOR', route_objects)),
          'Route32 Gold CAVE (6,79) has registered entrance')
    check('source_route33_warp',
          bool(re.search(r'db 9, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR', route33_objects)),
          'Route33 Gold CAVE (11,9) maps to southern cave ordinal1')
    route_rows = [l.strip() for l in routes.splitlines()
                  if l.strip().startswith('db ') and 'JOHTO_UNION_CAVE_1F_LOCAL_ID' in l]
    check('bidirectional_north_south_routes', route_rows == [
              'db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
              'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',
              'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',
              'db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
          ], 'four precise routes in Gold-verified ordinal order; B1F/B2F closed')
    check('cave_warp_only_by_coordinate_collision',
          bool(re.search(r'JohtoUnionCaveWarpTileIDs:\s+db \$ff\b', files['data/warp_tile_ids.asm'], re.I)) and
          'JOHTO_UNION_CAVE,' not in files['engine/overworld/doors.asm'],
          'no global step-on warp tiles or ordinary DOOR fallback for cave tileset')
    bike_row = re.search(r'(?m)^db\s+([^\n]+)', bike)
    ids = [x.strip() for x in bike_row.group(1).split(',')] if bike_row else []
    check('union_cave_bike_gold_reference_policy',
          ids.count('JOHTO_UNION_CAVE') == 1 and 'JOHTO_GATE' not in ids and
          ids[-1:] == ['$FF'],
          'old NPC-5.62.243 permits cycling in Union Cave; leave ordinary gate/house restrictions unchanged')

    if gold_root is not None:
        try:
            gold = GoldCollisionIndex(Path(gold_root))
            roles = {(m, x, y): gold.role_at(m, x, y)
                     for m, x, y in [('Route32', 6, 79), ('UnionCave1F', 17, 3), ('UnionCave1F', 17, 4), ('UnionCave1F',17,31), ('UnionCave1F',17,32),('Route33',11,9)]}
            check('gold_cave_collision_roles', roles == {
                ('Route32', 6, 79): 'CAVE',
                ('UnionCave1F', 17, 3): 'WARP_CARPET_DOWN',
                ('UnionCave1F', 17, 4): 'WALL',
                ('UnionCave1F',17,31): 'WARP_CARPET_DOWN',
                ('UnionCave1F',17,32): 'WALL', ('Route33',11,9): 'CAVE'}, f'Gold actual source collisions: {roles}')
        except (OSError, ValueError) as exc:
            check('gold_cave_collision_roles', False, str(exc))

    return {'schema': 'johto-union-cave-portal-audit-v1',
            'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks': checks, 'errors': errors, 'rom_built': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--gold-root', type=Path)
    args = parser.parse_args()
    result = audit(args.root, args.gold_root)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    raise SystemExit(bool(result['errors']))
