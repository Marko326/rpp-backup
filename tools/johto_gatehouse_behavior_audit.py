#!/usr/bin/env python3
"""Fail-closed gatehouse *execution-path* contracts for all enabled Johto gates.

Not a GB emulator. Evaluates the supported actual ASM predicate instructions,
not simply the presence of string tokens, on every declared gate mouth in all
four directions. A changed instruction we cannot interpret is a failure, never
an implicit PASS. Runtime animation/VRAM still requires built-ROM verification.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from johto_gate_rgb_audit import verify as verify_gate_rgb
from johto_gate_audit import verify_gold_gate_palette_map
from johto_gold_door_audit import (GATE_CARPETS,
                                   GATE_SOLID_DOORS, gold_gate_approach_rule,
                                   gold_gate_arrival_step, gold_collision_index)
from johto_indoor_tiles_converter import build_mapping
from johto_warp_arrival_audit import profiles as parse_arrival_profiles
from johto_masked_step_audit import gate_mat_path_errors

MANIFEST = 'tools/johto_door_contracts.json'
ASM = 'engine/overworld/johto_route33_collision.asm'
LOOKUP = 'engine/overworld/region_map_lookup.asm'
HOME = 'home/overworld.asm'
MODES = {'STEP_ON', 'COLLISION_ONLY', 'LEGACY_COLLISION'}
DIRECTIONS = ('UP', 'DOWN', 'LEFT', 'RIGHT')


def get_text(root: Path, path: str, overrides: dict | None) -> str:
    return (overrides[path] if overrides and path in overrides
            else (root / path).read_text(encoding='utf-8'))


def predicate(source: str, name: str, map_id: str, x: int, y: int, direction: str,
              const_values: dict | None = None,
              region: str = 'MAP_REGION_JOHTO',
              alias: str = 'REGION_NATIVE_MAP_SLOT') -> bool:
    """Small strict executor for ASM gate direction predicates; returns carry.

    No arbitrary calls/branch targets, numbers-as-symbols or opcode fallthrough.
    Keeps exactly the runtime map-local and direction inputs; trace both allowed
    and denied examples to reject a reversed conditional branch.
    """
    m = re.search(r'(?m)^' + re.escape(name) + r'::\s*$', source)
    if not m:
        raise ValueError('runtime gate predicate missing: ' + name)
    remainder = source[m.end():]
    nxt = re.search(r'(?m)^[A-Za-z]\w*::\s*$', remainder)
    if nxt:
        remainder = remainder[:nxt.start()]
    prog: list[str] = []
    labels = {'.entry': 0}
    for raw in remainder.splitlines():
        stmt = raw.split(';', 1)[0].strip()
        if not stmt:
            continue
        if re.fullmatch(r'\.[A-Za-z]\w*:?', stmt):
            label = stmt.removesuffix(':')
            if label in labels:
                raise ValueError('duplicate ASM branch label: ' + label)
            labels[label] = len(prog)
        elif re.fullmatch(r'[A-Za-z]\w*:', stmt):
            break
        else:
            prog.append(stmt)
    ram = {'wCurMap': alias, 'wCurRegion': region, 'wCurLocalMapID': map_id,
           'wXCoord': x, 'wYCoord': y, 'wPlayerDirection': 'PLAYER_DIR_' + direction}
    if const_values:
        ram['wCurLocalMapID'] = const_values[map_id]
    a, b, z, c, pc = None, None, False, False, 0
    for _ in range(220):
        if not 0 <= pc < len(prog):
            raise ValueError(f'{name} ran past subroutine without RET')
        op = prog[pc]
        pc += 1
        m = re.fullmatch(r'ld a, \[(w\w+)\]', op)
        if m:
            if m[1] not in ram:
                raise ValueError('unmodeled ASM RAM access: '+op)
            a = ram[m[1]]
            continue
        if op == 'ld b, a':
            b = a
            continue
        m = re.fullmatch(r'ld a, (PLAYER_DIR_(?:UP|DOWN|LEFT|RIGHT))', op)
        if m:
            a = m[1]
            continue
        m = re.fullmatch(r'cp\s+([\w$]+)', op)
        if m:
            target = b if m[1] == 'b' else (const_values[m[1]] if const_values and m[1] in const_values
                       else int(m[1], 16) if m[1].startswith('$')
                       else int(m[1]) if m[1].isdecimal() else m[1])
            if a is None or target is None or (isinstance(a, int) != isinstance(target, int)):
                raise ValueError('invalid symbolic ASM comparison: ' + op)
            z = a == target
            c = a < target
            continue
        if op == 'and a':
            c = False
            z = a == 0
            continue
        if op == 'scf':
            c = True
            continue
        m = re.fullmatch(r'(?:jr|jp)\s+(?:(z|nz|c|nc),\s*)?(\.\w+)', op)
        if m:
            flag, dest = m.groups()
            take = (flag is None or (flag == 'z' and z) or (flag == 'nz' and not z)
                    or (flag == 'c' and c) or (flag == 'nc' and not c))
            if take:
                if dest not in labels:
                    raise ValueError('unknown ASM gate jump: ' + dest)
                pc = labels[dest]
            continue
        if op == 'ret':
            return c
        if op in ('ret z', 'ret nz', 'ret c', 'ret nc'):
            flag = op[4:]
            if (flag == 'z' and z) or (flag == 'nz' and not z) or (flag == 'c' and c) or (flag == 'nc' and not c):
                return c
            continue
        raise ValueError('unsupported ASM gate predicate instruction: '+op)
    raise ValueError('ASM predicate execution did not terminate: ' + name)



def object_warps(text: str, name: str) -> list[tuple[int, int, int, str]]:
    """All registered Y/X/slot/destination cells, including overwritten tests."""
    lines = [row.split(';', 1)[0].strip() for row in text.splitlines()]
    lines = [row for row in lines if row]
    label = name + 'Object:'
    if label not in lines:
        raise ValueError('missing RPP object label: '+label)
    rows=lines[lines.index(label)+1:]
    if len(rows)<2:
        raise ValueError('incomplete RPP warp header '+name)
    length=rows[1]
    if not re.fullmatch(r'db\s+(?:\$[0-9a-fA-F]+|\d+)',length):
        raise ValueError('bad Warp count: '+length)
    count=int(length.split()[-1].replace('$','0x'),0)
    records=[]
    for row in rows[2:2+count]:
        found=re.fullmatch(r'db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([A-Z0-9_]+)',row)
        if not found:
            raise ValueError('malformed Warp entry '+name+': '+row)
        records.append((int(found[1]),int(found[2]),int(found[3]),found[4]))
    if len(records)!=count or len({(y,x) for y,x,_,_ in records})!=count:
        raise ValueError('incomplete or duplicate Warp entry '+name)
    return records


def landing_mask_errors(root: Path, destinations: list, id_to_stem: dict,
                        overrides: dict | None = None, gold: Path | None = None) -> list[str]:
    """Read actual masks: one forced step must stay on valid floor in bounds."""
    errors=[]
    width_definitions=get_text(root,'constants/region_map_constants.asm',overrides)
    constants={name:int(value) for name,value in re.findall(
        r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+)\s+EQU\s+(\d+)\s*$',width_definitions)}
    for d in destinations:
        if all(item[2]=='NONE' for item in d['points']):
            continue
        # Route29 still uses the original $F4 legacy map alias. Its
        # movement path does not consume a Johto native blocked-mask BIN.
        # Review the one forced step against Gold's REAL destination-floor
        # collision instead of demanding a nonexistent native mask file.
        if d['alias'] == 'JOHTO_ROUTE_29' and d['local'] == 'JOHTO_ROUTE_29_LOCAL_ID':
            if gold is None:
                errors.append('legacy Route29 step requires original Gold collision evidence')
                continue
            from johto_gold_door_audit import gold_collision_index
            source = gold_collision_index(Path(gold))
            for y,x,direction in d['points']:
                if (y,x,direction) != (1,27,'D_DOWN') or (source.role_at('Route29',x,y) != 'DOOR'
                    or source.role_at('Route29',x,y+1) != 'FLOOR'):
                    errors.append(f'legacy Route29 landing/auto-step invalid: {(x,y,direction)}')
            continue
        stem=id_to_stem.get(d['local'])
        if stem is None:
            # Legacy alias route31 does not use the native arrival executor.
            if d['local'].startswith('JOHTO_ROUTE31_VIOLET_GATE'):
                continue
            errors.append('no registered destination identity '+d['local'])
            continue
        header=get_text(root,'data/mapHeaders/'+stem+'.asm',overrides)
        dims=re.search(r'(?m)^\s*db\s+([A-Z0-9_]+|\d+)\s*,\s*([A-Z0-9_]+|\d+)\s*$',header)
        if not dims:
            errors.append('cannot determine map dimensions '+stem)
            continue
        def get_size(x):
            return int(x) if x.isdecimal() else constants[x]
        height_blocks,width_blocks=map(get_size,dims.groups())
        width,height=width_blocks*2,height_blocks*2
        stride=(width+7)//8
        mask_path='maps/'+stem+'.blocked_mask.bin'
        mask=(overrides[mask_path] if overrides and mask_path in overrides
              else (root/mask_path).read_bytes())
        if len(mask)!=stride*height:
            errors.append(stem+' blocked mask does not match map dimensions')
            continue
        offsets={'D_UP':(0,-1),'D_DOWN':(0,1),'D_LEFT':(-1,0),'D_RIGHT':(1,0)}
        for y,x,direction in d['points']:
            if direction=='NONE':
                continue
            dx,dy=offsets[direction]
            tx,ty=int(x)+dx,int(y)+dy
            if not (0<=tx<width and 0<=ty<height):
                errors.append(stem+f' forced arrival step goes out of bounds ({tx},{ty})')
            elif mask[ty*stride+tx//8] & (1<<(tx%8)):
                errors.append(stem+f' forced arrival step lands in blocked terrain ({tx},{ty})')
    return errors


def gold_approach_collision_errors(root: Path, gold: Path, gates: list,
                                   overrides: dict | None = None) -> list[str]:
    """Independently bind every approach trigger to Gold's actual collision.

    Gold directional carpets are standable and trigger only when the player
    collides toward their encoded direction. Solid DOOR tiles are the distinct
    step-on/automatic-down family. This checks every active gate approach on
    every side, including outdoor mouths, rather than only north-facing single
    doors; a JSON+ASM change cannot redefine the Gold source semantics.
    """
    errors = []
    native = json.loads(get_text(root, 'tools/johto_native_maps.json', overrides))['maps']
    stems = {row['local_symbol']: row['header'].removesuffix('_h') for row in native}
    index = gold_collision_index(Path(gold))
    for gate in gates:
        contract = gate.get('gatehouse_runtime', {})
        if not isinstance(contract, dict):
            continue
        for entry in contract.get('approaches', []):
            local = entry['map_local']
            stem = stems.get(local)
            if local == contract.get('local_id'):
                gold_map = gate.get('gold_map')
            elif stem:
                # Native Johto outdoor headers mirror the Gold map name after
                # the Johto prefix is removed (e.g. JohtoRoute34 -> Route34).
                gold_map = stem.removeprefix('Johto')
            else:
                gold_map = None
            x, y = int(entry['x']), int(entry['y'])
            if not gold_map:
                errors.append(f'{gate["rpp_map"]} cannot map {local} ({x},{y}) to Gold source')
                continue
            try:
                role = index.role_at(gold_map, x, y)
            except (OSError, ValueError, KeyError, IndexError) as exc:
                errors.append(f'{gate["rpp_map"]} Gold collision role unavailable for '
                              f'{gold_map} ({x},{y}): {exc}')
                continue
            trigger = entry.get('trigger')
            mode = contract.get('mode')
            expected = gold_gate_approach_rule(role, mode)
            if expected is None:
                errors.append(f'{gate["rpp_map"]} Warp approach {gold_map} '
                              f'({x},{y}) has unsupported Gold collision role {role}; '
                              'review as a special entrance instead of guessing STEP_ON')
                continue
            expected_trigger, expected_direction = expected
            if trigger != expected_trigger:
                detail = ('Gold carpets are standable and direction-collision triggered'
                          if role in GATE_CARPETS else
                          'Gold solid DOOR uses its distinct step-on behavior')
                role_label = 'Gold single solid DOOR' if role == 'DOOR' else f'Gold {role}'
                errors.append(f'{gate["rpp_map"]} {role_label} at {gold_map} '
                              f'({x},{y}) must be {expected_trigger}, not {trigger}; {detail}')
            if entry.get('direction') != expected_direction:
                errors.append(f'{gate["rpp_map"]} Gold {role} at {gold_map} '
                              f'({x},{y}) requires {expected_direction}, not '
                              f'{entry.get("direction")}; direction is encoded by Gold collision')
    return errors


def gold_solid_north_door_errors(root: Path, gold: Path, gates: list,
                                 overrides: dict | None = None) -> list[str]:
    """Backward-compatible name; now checks every Gold-backed approach role."""
    return gold_approach_collision_errors(root, gold, gates, overrides)


def gold_arrival_step_errors(root: Path, gold: Path, gates: list,
                             overrides: dict | None = None) -> list[str]:
    """Check post-Warp simulated movement against the Gold destination tile.

    Gold's ordinary DOOR/DOOR_79/STAIRCASE/CAVE destination tiles force one
    step DOWN after map load. Directional carpets do not. This keeps that
    movement on the destination side of the Warp, never on the source carpet.
    """
    errors = []
    native = json.loads(get_text(root, 'tools/johto_native_maps.json', overrides))['maps']
    stems = {row['local_symbol']: row['header'].removesuffix('_h') for row in native}
    index = gold_collision_index(Path(gold))
    for gate in gates:
        contract = gate.get('gatehouse_runtime', {})
        if not isinstance(contract, dict):
            continue
        for arrival in contract.get('arrivals', []):
            local = arrival.get('local')
            if local == contract.get('local_id'):
                gold_map = gate.get('gold_map')
            else:
                stem = stems.get(local)
                gold_map = stem.removeprefix('Johto') if stem else None
            if not gold_map:
                errors.append(f'{gate["rpp_map"]} cannot map arrival destination {local} to Gold source')
                continue
            for y, x, step in arrival.get('points', []):
                try:
                    role = index.role_at(gold_map, int(x), int(y))
                except (OSError, ValueError, KeyError, IndexError) as exc:
                    errors.append(f'{gate["rpp_map"]} Gold arrival collision role unavailable for '
                                  f'{gold_map} ({x},{y}): {exc}')
                    continue
                expected = gold_gate_arrival_step(role)
                if expected is None:
                    errors.append(f'{gate["rpp_map"]} Warp arrival {gold_map} ({x},{y}) '
                                  f'has unsupported Gold collision role {role}; review arrival movement')
                    continue
                if step != expected:
                    errors.append(f'{gate["rpp_map"]} Gold arrival {gold_map} ({x},{y}) '
                                  f'role={role} requires {expected}, not {step}')
    return errors


def valid_contract(spec: dict) -> list[str]:
    name = spec.get('rpp_map', '?')
    runtime = spec.get('gatehouse_runtime')
    if not isinstance(runtime, dict):
        return [name + ' missing mandatory executable gatehouse_runtime contract']
    errors = []
    layout = spec.get('arrival_step_review', {}).get('layout')
    expected_sides = ({'NORTH_SOUTH_PAIR': {'north', 'south'},
                       'EAST_WEST_PAIR': {'west', 'east'}}).get(layout)
    if not expected_sides or set(runtime.get('warp_sides', {})) != expected_sides:
        errors.append(name + ' warp-side layout does not match the reviewed orientation')
    if runtime.get('border_policy') not in ('APPROVED_NORMAL', 'AZALEA_WEST_PATCH', 'GOLDENROD_ROUTE35_PAIR'):
        errors.append(name+' missing mandatory outdoor border render policy')
    if runtime.get('mode') not in ('NATIVE_GATE', 'LEGACY_COLLISION'):
        errors.append(name + ' missing reviewed runtime execution mode')
    if not isinstance(runtime.get('approaches'), list) or not runtime['approaches']:
        errors.append(name + ' missing outdoor and indoor direction/trigger contract')
    if not isinstance(runtime.get('arrivals'), list) or not runtime['arrivals']:
        errors.append(name + ' missing arrival-step contract for both sides')
    if runtime.get('mode') == 'NATIVE_GATE' and (not isinstance(runtime.get('native_routes'), list) or not runtime['native_routes']):
        errors.append(name + ' missing exact bidirectional native Warp routes')
    return errors


def check_native_gate_arrival_executors(root, doc, overrides=None):
    """Verify actual arrival decoding AND the post-Warp movement fallback.

    Metadata/table matching alone had a demonstrated false PASS when the
    default result of GetJohtoWarpArrivalStep was changed to D_UP. Freeze the
    small, reviewed dispatch/control-flow kernels here; changes require an
    explicit executable-contract review rather than a new self-declared JSON
    expectation. Comments and formatting do not affect the opcode contract.
    """
    def normalized(source):
        return [re.sub(r'\s+', '', code)
                for line in source.splitlines()
                if (code := line.split(';', 1)[0].strip())]

    def check_kernel(path, start, stop, reference):
        source = get_text(root, path, overrides)
        if source.count(start) != 1 or source.count(stop) != 1:
            raise ValueError('cannot isolate reviewed arrival executor: ' + start)
        actual = normalized(source.split(start, 1)[1].split(stop, 1)[0])
        wanted = normalized(reference)
        if actual != wanted:
            ix = next((i for i in range(min(len(actual), len(wanted)))
                       if actual[i] != wanted[i]), min(len(actual), len(wanted)))
            got = actual[ix] if ix < len(actual) else '<missing>'
            want = wanted[ix] if ix < len(wanted) else '<end>'
            raise ValueError(f'executable gate arrival kernel drift {start} '
                             f'instruction {ix}: actual={got}, reviewed={want}')

    check_kernel('engine/overworld/region_map_lookup.asm',
                 'GetJohtoWarpArrivalStep::', '\n.profiles\n', """
        ld e, 0
        ld a, [wCurRegion]
        cp MAP_REGION_JOHTO
        ret nz
        ld a, [wCurMap]
        ld b, a
        ld a, [wCurLocalMapID]
        ld c, a
        ld hl, .profiles
        .loop
        ld a, [hli]
        cp $ff
        ret z
        cp b
        jr nz, .skipFive
        ld a, [hli]
        cp c
        jr nz, .skipFour
        ld a, [hli]
        ld d, a
        ld a, [wYCoord]
        cp d
        jr nz, .skipThree
        ld a, [hli]
        ld d, a
        ld a, [wXCoord]
        cp d
        jr nz, .skipTwo
        ld a, [hli]
        ld d, a
        ld a, [wWarpedFromWhichMap]
        cp d
        jr nz, .skipOne
        ld e, [hl]
        ret
        .skipFive
        inc hl
        .skipFour
        inc hl
        .skipThree
        inc hl
        .skipTwo
        inc hl
        .skipOne
        inc hl
        jr .loop
    """)
    check_kernel('engine/overworld/npc_movement.asm',
                 'PlayerStepOutFromDoor:', '_EndNPCMovementScript:', """
        ld hl, wd730
        res 1, [hl]
        callab GetJohtoWarpArrivalStep
        ld a, e
        and a
        jr nz, .stepFromProfile
        call IsPlayerStandingOnDoorTile
        jr nc, .notStandingOnDoor
        ld a, D_DOWN
        .stepFromProfile
        push af
        ld a, $fc
        ld [wJoyIgnore], a
        ld hl, wd736
        set 1, [hl]
        ld a, $1
        ld [wSimulatedJoypadStatesIndex], a
        pop af
        ld [wSimulatedJoypadStatesEnd], a
        xor a
        ld [wSpriteStateData1 + 2], a
        call StartSimulatingJoypadStates
        ret
        .notStandingOnDoor
        xor a
        ld [wWastedByteCD3A], a
        ld [wSimulatedJoypadStatesIndex], a
        ld [wSimulatedJoypadStatesEnd], a
        ld hl, wd736
        res 0, [hl]
        res 1, [hl]
        ld hl, wd730
        res 7, [hl]
        ret
    """)
    # NONE only means no table row. Verify that the shared RPP door-tile
    # fallback cannot silently turn it into D_DOWN for a Johto gate.
    doors = get_text(root, 'engine/overworld/doors.asm', overrides)
    try:
        door_dispatch = doors.split('DoorTileIDPointers:', 1)[1].split('OverworldDoorTileIDs:', 1)[0]
    except IndexError as e:
        raise ValueError('missing door fallback tileset dispatch table') from e
    if re.search(r'(?m)^\s*dbw\s+JOHTO_GATE\s*,', door_dispatch):
        raise ValueError('JOHTO_GATE now uses implicit door D_DOWN fallback; review every NONE arrival')
    for entry in doc['active_warp_maps']:
        if entry.get('family') != 'GATE_INDOOR':
            continue
        name = entry['rpp_map']
        header = get_text(root, 'data/mapHeaders/'+name+'.asm', overrides)
        reviewed_tilesets = {
            'JohtoRoute35NationalParkGate': 'JOHTO_PARK_GATE',
            'JohtoRoute36NationalParkGate': 'JOHTO_PARK_GATE',
            'JohtoRoute32RuinsOfAlphGate': 'JOHTO_RUINS_GATE',
        }
        expected = reviewed_tilesets.get(name, 'JOHTO_GATE')
        if not re.search(r'(?m)^\s*db\s+'+expected+r'\s*$', header):
            raise ValueError(name+' no longer uses the reviewed no-fallback gate tileset')
        if re.search(r'(?m)^\s*dbw\s+'+expected+r'\s*,', door_dispatch):
            raise ValueError(name+' has implicit door D_DOWN fallback via '+expected)


def audit(root: Path, gold: Path, overrides: dict | None = None,
          manifest: dict | None = None) -> list[str]:
    root = Path(root)
    errors = []
    try:
        doc = (manifest if manifest is not None else
               json.loads(get_text(root, MANIFEST, overrides)))
        gates = [v for v in doc['active_warp_maps'] if v.get('family') == 'GATE_INDOOR']
        if not gates:
            return ['no enabled indoor gates discovered; refusing vacuous PASS']
        collisions = get_text(root, ASM, overrides)
        lookup = get_text(root, LOOKUP, overrides)
        home = get_text(root, HOME, overrides)
        ids = {}
        for symbols in ('constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm'):
            ids.update({name:int(number) for name,number in re.findall(
                r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\d+)',
                get_text(root, symbols, overrides))})
        profiles = parse_arrival_profiles(lookup)
        raw_routes = lookup.split('NativeRegionWarpTargets::',1)[1].split('SelectNativeMapConnection::',1)[0]
        route_rows = re.findall(r'(?m)^\s*db\s+([A-Z0-9_]+),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s*([A-Z0-9_]+)\s*$', raw_routes)
        native_routes = {(src,int(i),int(target),dst) for src,i,target,dst in route_rows}
    except (ValueError, KeyError, OSError, TypeError) as e:
        return ['gatehouse behavior prerequisite unreadable: ' + str(e)]
    actual = {(alias, local, y, x, source): direction
              for alias, local, y, x, source, direction in profiles}
    if len(actual) != len(profiles):
        errors.append('duplicate arrival profiles could shadow each other')
    try:
        check_native_gate_arrival_executors(root, doc, overrides)
    except (ValueError, KeyError, OSError, TypeError) as exc:
        errors.append('NATIVE_ARRIVAL_EXECUTOR: '+str(exc))
    # Paired collision-only mats are already valid standing Warp positions.
    # An automatic step OFF either mat breaks the established immediate
    # reverse-entry contract: the first reverse key merely walks back onto
    # the mat, without colliding through the doorway. A one-lane *solid*
    # external door remains a separate reviewed case (e.g. Mahogany y1).
    for gate in gates:
        runtime = gate.get('gatehouse_runtime', {})
        if not isinstance(runtime, dict):
            continue
        grouped = {}
        for approach in runtime.get('approaches', []):
            if approach.get('trigger') == 'COLLISION_ONLY':
                key = (approach['map_local'], approach['direction'])
                grouped.setdefault(key, []).append(approach)
        for (local, direction), positions in grouped.items():
            if len(positions) < 2:
                continue
            coords = {(int(row['y']), int(row['x'])) for row in positions}
            if len(coords) < 2:
                continue
            for y, x in sorted(coords):
                active_steps = [(a, src, move) for a, l, yy, xx, src, move in profiles
                                if l == local and yy == y and xx == x]
                for alias, source, move in active_steps:
                    errors.append(f'{gate["rpp_map"]} {local} ({x},{y}) '
                                  f'paired {direction} collision-only carpet has '
                                  f'unexpected auto-step {move}; immediate reverse would only return to carpet')
    # Distinguish moving on carpet (ordinary movement) from colliding with
    # the edge (Warp trigger). The Gold gate guide explicitly requires both.
    errors.extend(gate_mat_path_errors(root, doc, overrides))
    try:
        errors.extend(gold_approach_collision_errors(root, Path(gold), gates, overrides))
        errors.extend(gold_arrival_step_errors(root, Path(gold), gates, overrides))
    except (ValueError, KeyError, OSError, TypeError) as exc:
        errors.append('independent Gold gate collision/arrival classification failed: '+str(exc))
    for entry in gates:
        errors.extend(valid_contract(entry))
        if not isinstance(entry.get('gatehouse_runtime'), dict):
            continue
        name = entry['rpp_map']
        contract = entry['gatehouse_runtime']
        try:
            # Compare ACTUAL registered indoor Warp cell + target slot multiset,
            # rather than only checking a warp count or declared shape.
            records = object_warps(get_text(root,'data/mapObjects/'+name+'.asm',overrides),name)
            exp = [(int(y), int(x), int(slot), alias)
                   for points in contract['warp_sides'].values()
                   for y, x, slot, alias in points]
            if sorted(records) != sorted(exp):
                errors.append(name + ' actual Warp coordinate/slot/target differs from reviewed contract')
            # Original Gold coordinates are independent of the reviewed RPP
            # JSON. A manifest rewritten to match a corrupt Warp file is not
            # sufficient: the original source must still agree.
            original = (gold/'maps'/(entry['gold_map']+'.asm')).read_text(encoding='utf-8')
            gold_cells = {(int(y),int(x)) for x,y in re.findall(
                r'(?m)^\s*warp_event\s+(\d+),\s*(\d+),',original)}
            if {(y,x) for y,x,_,_ in exp} != gold_cells:
                errors.append(name + ' indoor Warp geometry differs from independent original Gold')
            # Verify all four room block layouts against Gold through the
            # independently validated source-to-compact metatile converter.
            actual_blocks = (root/'maps'/(name+'.blk')).read_bytes()
            if name in ('JohtoRoute35NationalParkGate','JohtoRoute36NationalParkGate'):
                # This is the Gold FULL-ID gate tileset, not the previously
                # accepted compact JOHTO_GATE. Compare actual independent
                # source pixels, 256 metatile quarters, carpet layout, and
                # first 96 palette labels. Every mismatch is release-blocking.
                source = Path(gold)
                metatiles = (source/'data/tilesets/gate_metatiles.bin').read_bytes()
                rpp_table = (root/'gfx/blocksets/johto_park_gate.bst').read_bytes()
                if rpp_table[:1024] != metatiles or rpp_table[1024:] != bytes(16):
                    errors.append(name+' Gold FULL-ID gate blockset/border differs from original')
                if (root/'gfx/tilesets/johto_park_gate.png').read_bytes() != (source/'gfx/tilesets/gate.png').read_bytes():
                    errors.append(name+' Gold full gate pixels differ from source')
                source_pal = (source/'gfx/tilesets/gate_palette_map.asm').read_text().splitlines()[:12]
                actual_pal = (root/'color/tilesets/johto_park_gate.asm').read_text().splitlines()
                if actual_pal != source_pal:
                    errors.append(name+' Gold FULL-ID gate source palette tags differ')
                gold_blocks = (source/'maps'/(entry['gold_map']+'.blk')).read_bytes()
                if actual_blocks != gold_blocks:
                    errors.append(name+' Gold full gate map block positions differ from original')
            elif name == 'JohtoRoute32RuinsOfAlphGate':
                from johto_gold_sources import gold_block_sources
                source = Path(gold)
                if (root/'gfx/blocksets/johto_ruins_gate.bst').read_bytes() != (source/'data/tilesets/gate_metatiles.bin').read_bytes():
                    errors.append(name+' Gold gate blockset differs from original')
                if (root/'gfx/tilesets/johto_ruins_gate.png').read_bytes() != (source/'gfx/tilesets/gate.png').read_bytes():
                    errors.append(name+' Gold gate pixels differ from original')
                if (root/'color/tilesets/johto_ruins_gate.asm').read_text().splitlines() != (source/'gfx/tilesets/gate_palette_map.asm').read_text().splitlines()[:12]:
                    errors.append(name+' Gold gate palette tags differ from original')
                gold_blocks = (source/gold_block_sources(source)[entry['gold_map']]).read_bytes()
                if actual_blocks != gold_blocks:
                    errors.append(name+' original Gold shared EastWestGate layout differs')
            else:
                mapping, gold_blocks = build_mapping(root, Path(gold), entry['gold_map'], 'gate','johto_gate')
                if mapping['exact_mapped'] != mapping['used_unique_blocks'] or actual_blocks != gold_blocks:
                    errors.append(name+' actual gate house metatile layout differs from Gold reference')
            if contract.get('mode') == 'NATIVE_GATE':
                gate_id = contract['local_id']
                expected_routes = {tuple([v[0],int(v[1]),int(v[2]),v[3]])
                                   for v in contract['native_routes']}
                actual_gate_routes = {v for v in native_routes if v[0] == gate_id or v[3] == gate_id}
                if actual_gate_routes != expected_routes:
                    errors.append(name + ' native Warp routes changed (missing, extra or redirected)')
                # Every listed source slot must refer to a real matching
                # source-object Warp. This catches phantom routes through an
                # otherwise plausible table row.
                local_maps = {v['local_symbol']:v['header'].removesuffix('_h')
                              for v in json.loads(get_text(root,'tools/johto_native_maps.json',overrides))['maps']}
                for source_id, slot, target_slot, dest_id in expected_routes:
                    stem = local_maps.get(source_id)
                    if not stem:
                        raise ValueError('unregistered native source map: '+source_id)
                    actual_warps = object_warps(
                        get_text(root,'data/mapObjects/'+stem+'.asm',overrides),stem)
                    if slot >= len(actual_warps):
                        errors.append(name + ' routed source Warp index outside '+stem)
                    elif actual_warps[slot][2] != target_slot:
                        errors.append(name+' source Warp destination slot inconsistent '+stem)
                    if dest_id == gate_id and source_id != gate_id and slot < len(actual_warps):
                        y0,x0,_,_ = actual_warps[slot]
                        matching=[v for v in contract['approaches'] if
                                  v['map_local']==source_id and (v['y'],v['x'])==(y0,x0)]
                        if len(matching)!=1:
                            errors.append(name+' missing exactly one outside approach for '+stem+f' ({x0},{y0})')
            sides = contract['warp_sides']
            if sum(len(v) for v in sides.values()) != len(records) or any(len(v) != 2 for v in sides.values()):
                errors.append(name + ' must have two reviewed Warp lanes on each side')
            if contract.get('mode') == 'NATIVE_GATE':
                indoor_approaches={(v['y'],v['x']) for v in contract['approaches']
                                   if v['map_local']==contract['local_id']}
                if indoor_approaches != {(y,x) for y,x,_,_ in exp}:
                    errors.append(name+' indoor Warp tiles not fully covered by directional probes')
            if contract.get('mode') == 'LEGACY_COLLISION' and name != 'JohtoRoute31VioletGate':
                errors.append(name + ' cannot claim legacy collision engine without manual code review')
            for approach in contract['approaches']:
                local, x, y = approach['map_local'], int(approach['x']), int(approach['y'])
                if contract.get('mode') == 'NATIVE_GATE' and local in (
                        'JOHTO_ECRUTEAK_CITY_LOCAL_ID',
                        'JOHTO_ROUTE_38_LOCAL_ID',
                        'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID',
                        'JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID',
                        'JOHTO_ROUTE_42_LOCAL_ID',
                        'JOHTO_MAHOGANY_TOWN_LOCAL_ID',
                        'JOHTO_ROUTE_43_LOCAL_ID',
                        'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID') and not predicate(
                        home, 'IsJohtoSouthGatePortal',local,x,y,'LEFT', ids):
                    errors.append(f'{name} {local} ({x},{y}) bypasses the HOME Warp selector')
                if contract.get('mode') == 'NATIVE_GATE' and local in (
                        'JOHTO_ECRUTEAK_CITY_LOCAL_ID',
                        'JOHTO_ROUTE_38_LOCAL_ID',
                        'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID',
                        'JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID',
                        'JOHTO_ROUTE_42_LOCAL_ID',
                        'JOHTO_MAHOGANY_TOWN_LOCAL_ID',
                        'JOHTO_ROUTE_43_LOCAL_ID',
                        'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID'):
                    if predicate(home,'IsJohtoSouthGatePortal',local,x,y,'LEFT',ids,
                                 region='MAP_REGION_KANTO') or predicate(
                            home,'IsJohtoSouthGatePortal',local,x,y,'LEFT',ids,
                            alias='JOHTO_ROUTE_31'):
                        errors.append(f'{name} {local} HOME gate selector leaks across region/map alias')
                wanted = approach['direction']
                mode = approach['trigger']
                if wanted not in DIRECTIONS or mode not in MODES:
                    raise ValueError(name+' bad direction/trigger mode')
                if mode == 'LEGACY_COLLISION':
                    if contract.get('mode') != 'LEGACY_COLLISION':
                        errors.append(name + ' legacy approach in native gate')
                    continue
                if not re.fullmatch(r'JOHTO_[A-Z0-9_]+_LOCAL_ID', local):
                    raise ValueError(name+' invalid map-local identity '+local)
                # A non-edge Route38 outside mouth must pass the real ROMX
                # ExtraWarpCheck predicate, not merely HOME portal selection
                # and the collision-direction check. Requiring the contract
                # flag prevents a future patch from silently dropping probes.
                if local == 'JOHTO_ROUTE_38_LOCAL_ID' and name == 'JohtoRoute38EcruteakGate' and not approach.get('outside_guard'):
                    errors.append(name + f' Route38 interior outside mouth ({x},{y}) missing mandatory EXTRA_WARP proof')
                for direction in DIRECTIONS:
                    step = predicate(collisions, 'JohtoNorthGateStepWarpAllowed',local,x,y,direction)
                    coll = predicate(collisions, 'JohtoGateCollisionDirectionAllowed',local,x,y,direction)
                    desired_step = mode == 'STEP_ON' and direction == wanted
                    desired_coll = direction == wanted
                    if step != desired_step:
                        errors.append(f'{name} {local} ({x},{y}) {direction} STEP_ON actual={step} wanted={desired_step}')
                    if coll != desired_coll:
                        errors.append(f'{name} {local} ({x},{y}) {direction} COLLISION actual={coll} wanted={desired_coll}')
                    if approach.get('outside_guard'):
                        checked = predicate(collisions, 'JohtoInternalDoorFacingCheck',local,x,y,direction)
                        if checked != desired_coll:
                            errors.append(f'{name} {local} ({x},{y}) {direction} EXTRA_WARP actual={checked} wanted={desired_coll}')
            # An arrival includes every mouth on both sides; NONE must mean
            # absence of an executable table row, not just a prose statement.
            for destination in contract['arrivals']:
                alias = destination['alias']
                local = destination['local']
                source_alias = destination['from']
                expected_points = {(int(y),int(x)): direction for y,x,direction in destination['points']}
                seen = {(y,x):direction for a,l,y,x,s,direction in profiles
                        if (a,l,s)==(alias,local,source_alias) and (y,x) in expected_points}
                actual_for_map = {(y,x):direction for a,l,y,x,s,direction in profiles
                                  if (a,l,s)==(alias,local,source_alias)}
                for point,direction in expected_points.items():
                    active_dir = seen.get(point, 'NONE')
                    if active_dir != direction:
                        errors.append(f'{name} {local} arrival {point} actual={active_dir} wanted={direction}')
                if destination.get('exact_map_profiles'):
                    should = {p:d for p,d in expected_points.items() if d!='NONE'}
                    if actual_for_map != should:
                        errors.append(name+' arrival profile table contains unexpected/omitted rows for '+local)
            # Cross-check arrival_step_review: the prose metadata cannot
            # claim one side is NONE while executable profiles move it.
            if contract.get('mode')=='NATIVE_GATE':
                side_decisions = entry['arrival_step_review']['by_gate_side']
                for side, cells in sides.items():
                    for y,x,_,_ in cells:
                        found = next((t for t in contract['arrivals'] if t['local']==contract['local_id']),None)
                        rows = {(int(yy),int(xx)):move for yy,xx,move in found['points']} if found else {}
                        if rows.get((y,x))!=side_decisions[side]:
                            errors.append(name+' reviewed arrival direction disagrees with its '+side+' side')
            errors.extend(landing_mask_errors(root,contract['arrivals'],
                           {v['local_symbol']:v['header'].removesuffix('_h') for v in
                            json.loads(get_text(root,'tools/johto_native_maps.json',overrides))['maps']},overrides,gold))
            # Prevent the manifest being used to silently neutralize a new
            # side: each indoor warp tile must have an arrival decision.
            indoor = next((e for e in contract['arrivals'] if e['local']==contract.get('local_id')), None)
            if contract['mode'] == 'NATIVE_GATE' and (indoor is None or
                 {(int(y),int(x)) for y,x,d in indoor['points']} !=
                 {(y,x) for y,x,_,_ in exp}):
                errors.append(name + ' arrival-step contract omits an indoor Warp tile')
        except (OSError, ValueError, KeyError, IndexError, StopIteration, TypeError) as exc:
            errors.append(name+' gate behavior cannot be verified: '+str(exc))
    # No unrelated stable IDs may enter the specialized gate Warp path.
    # This is intentionally a runtime predicate probe, not an ASM token search.
    for local in ('JOHTO_ROUTE_37_LOCAL_ID', 'JOHTO_ROUTE_39_LOCAL_ID',
                  'JOHTO_UNION_CAVE_1F_LOCAL_ID',
                  'JOHTO_LAKE_OF_RAGE_LOCAL_ID'):
        try:
            if predicate(home,'IsJohtoSouthGatePortal',local,0,0,'LEFT',ids):
                errors.append('non-gate ID incorrectly selected by HOME Warp dispatcher: '+local)
        except (ValueError, KeyError) as exc:
            errors.append('cannot interpret HOME gate selector: '+str(exc))
    # The same gate asset pipeline is shared across all enabled indoor gates.
    # Do not pass a corrupted tile/palette bank just because the door acts right.
    if not overrides:
        try:
            errors.extend('GOLD_GATE_RGB: '+v for v in verify_gate_rgb(root,Path(gold)))
            errors.extend('GOLD_GATE_PALETTE: '+v for v in verify_gold_gate_palette_map(root,Path(gold)))
        except (OSError, ValueError, KeyError, IndexError) as exc:
            errors.append('gate Gold art source cannot be verified: '+str(exc))
    # Verify the real runtime executors actually consume the predicates and
    # arrival profiles; a correct unused helper must never score PASS.
    standing=home.split('CheckWarpsNoCollisionLoop::',1)[-1].split('CheckWarpsCollision::',1)[0]
    collided=home.split('CheckWarpsCollision::',1)[-1].split('CheckWarpsNoCollisionRetry1::',1)[0]
    extra=home.split('ExtraWarpCheck::',1)[-1].split('IsJohtoSouthGatePortal::',1)[0]
    npc=get_text(root,'engine/overworld/npc_movement.asm',overrides)
    for flag,okay in (
        ('step-on Warp executor', all(t in standing for t in ('callba JohtoNorthGateStepWarpAllowed','jp c, WarpFound1'))),
        ('collision Warp executor', all(t in collided for t in ('callba JohtoGateCollisionDirectionAllowed','jr nc, .retry2'))),
        ('outside doorway facing executor', 'callba JohtoInternalDoorFacingCheck' in extra),
        ('post-Warp step executor', all(t in npc for t in ('callab GetJohtoWarpArrivalStep','call StartSimulatingJoypadStates'))),
    ):
        if not okay:errors.append('shared gate runtime missing '+flag)
    # The two loading paths MUST both perform the shared ROMX border patch
    # after the metatile buffer is filled. This checks the actual call sites.
    hook = 'callba PatchJohtoMapBordersAfterBlockLoad'
    before_load = home.split('LoadMapData::',1)[-1].split('; HAX: Padding',1)[0]
    connected = home.split('.ordinaryConnection\n',1)[-1].split('.didNotEnterConnectedMap',1)[0]
    if any(part.count(hook)!=1 or 'call LoadTileBlockMap' not in part or
           part.index('call LoadTileBlockMap')>part.index(hook)
           for part in (before_load,connected)) or home.count(hook)!=2:
        errors.append('gate exterior preview must run after block load on BOTH load paths')
    section = collisions.split('PatchJohtoMapBordersAfterBlockLoad::',1)[-1].split('PatchJohtoAzaleaWestGateBorder::',1)[0]
    if not (re.search(r'call PatchJohtoAzaleaWestGateBorder\s+call PatchJohtoGoldenrodNorthBorder\s+call PatchJohtoMahoganyNorthBorder\s+jp PatchJohtoRoute35SouthBorder',section)):
        errors.append('shared exterior border renderer lost one side or changed call order')
    if 'SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]' not in get_text(root,'main.asm',overrides):
        errors.append('gate border render routines must remain in ROMX Bank 43')
    return errors


if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--rpp',type=Path,default=Path('.'))
    parser.add_argument('--gold',type=Path,required=True)
    ns=parser.parse_args()
    issues=audit(ns.rpp,ns.gold)
    for issue in issues:print('FAIL',issue)
    if issues:raise SystemExit(1)
    print('PASS: all enabled gatehouse runtime selectors, Warp cells, arrival profiles and both border load paths (STATIC ASM EXECUTION)')
