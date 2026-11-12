#!/usr/bin/env python3
"""REF-367A: fail-closed Gold Ice Path source-resource staging audit.

This is an *inactive* source-data contract, not gameplay verification.  It
recomputes all 8x8 collision roles from the staged Gold block layout and
Gold tilecoll reference; validates every Warp's role and destination ordinal;
and prevents PIT arrival-only ICE tiles being confused with active exits.
It deliberately needs no external Gold checkout for local project validation.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

CONTRACT = 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'
NAMES = ('IcePath1F', 'IcePathB1F', 'IcePathB2FMahoganySide',
         'IcePathB2FBlackthornSide', 'IcePathB3F')
IDS = (70, 95, 96, 97, 98)
GOLD_ROW = re.compile(r'(?m)^\s*tilecoll\s+([^;\n]+)')


def audit(root: Path) -> list[str]:
    problems: list[str] = []
    try:
        contract = json.loads((root / CONTRACT).read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        return [f'contract unreadable: {exc}']

    def check(condition: bool, message: str):
        if not condition:
            problems.append(message)

    check(contract.get('status') == 'STAGED_ONLY_NOT_RUNTIME_ENABLED', 'stage unexpectedly marked active')
    check(contract.get('baseline_head') == 'a95ac8d1ddaf47575bc4f08935033d014bfa58cf',
          'wrong REF-366 baseline HEAD')
    records = contract.get('maps', [])
    check([m.get('name') for m in records] == list(NAMES), 'missing/reordered Gold map definitions')
    check([m.get('stable_id') for m in records] == list(IDS), 'wrong stable IDs')
    check(len(contract.get('assets', {})) == 14, 'expected exact 14 staged source assets')
    for rel, meta in contract.get('assets', {}).items():
        path = root / rel
        check('..' not in Path(rel).parts and not Path(rel).is_absolute(), f'unsafe asset path {rel}')
        if not path.is_file():
            problems.append(f'missing staged asset: {rel}')
            continue
        data = path.read_bytes()
        check(len(data) == meta.get('size'), f'{rel}: wrong byte count')
        check(hashlib.sha256(data).hexdigest() == meta.get('sha256'), f'{rel}: sha256 mismatch')

    rows = [tuple(part.strip() for part in raw.split(','))
            for raw in GOLD_ROW.findall((root / 'data/johto_ice_path_stage/ice_path_collision.gold.asm').read_text(encoding='utf-8'))]
    check(len(rows) == 64 and all(len(row) == 4 for row in rows), 'Gold collision table must contain 64 4-quadrant rows')
    role_names = contract.get('roles', [])
    check(len(role_names) == len(set(role_names)), 'collision role vocabulary duplicates')
    decoded = {}
    for m in records:
        name = m['name']
        w, h = m['width_blocks'], m['height_blocks']
        source = root / f'maps/johto_ice_path_stage/{name}.gold.blk'
        roles_file = root / f'data/johto_ice_path_stage/{name}.roles.bin'
        if not source.is_file() or not roles_file.is_file():
            continue
        blocks, actual = source.read_bytes(), roles_file.read_bytes()
        check((m['width_cells'], m['height_cells']) == (w * 2, h * 2), f'{name}: size mismatch')
        if len(blocks) != w * h or len(actual) != w * h * 4:
            problems.append(f'{name}: wrong block/role data length')
            continue
        computed = bytearray()
        for y in range(h * 2):
            for x in range(w * 2):
                block = blocks[(y // 2)*w+(x // 2)]
                if block >= len(rows):
                    problems.append(f'{name}: undefined block collision {block}')
                    computed.append(255)
                    continue
                role = rows[block][(y % 2)*2 + (x % 2)]
                try:
                    computed.append(role_names.index(role))
                except ValueError:
                    problems.append(f'{name}: unmapped Gold role {role}')
                    computed.append(255)
        check(bytes(computed) == actual, f'{name}: role grid diverges from Gold block/collision')
        counts = Counter(role_names[b] for b in computed if b < len(role_names))
        check(dict(counts) == m.get('role_counts'), f'{name}: Gold collision totals differ')
        decoded[name] = (w*2, h*2, actual)
    check(sum(m['mechanics']['ice_cells'] for m in records) == 673, 'ice total != 673')
    check(sum(m['mechanics']['pit_cells'] for m in records) == 4, 'pit total != 4')
    check(sum(m['mechanics']['ledge_cells'] for m in records) == 8, 'hop total != 8')
    check(sum(m['mechanics']['directional_wall_cells'] for m in records) == 78, 'up-wall total != 78')
    check(sum(len(m['warps']) for m in records) == 22, 'Gold Ice Path must have 22 warp events')
    named = {m['name']:m for m in records}
    reverse_pit_count = 0
    for m in records:
        name = m['name']
        for i, event in enumerate(m['warps']):
            check(event['ordinal0'] == i and event['ordinal1'] == i + 1,
                  f'{name}: source ordinal {i} corrupted')
            if name in decoded:
                w,h,role_grid = decoded[name]
                x,y=event['x'],event['y']
                if x < 0 or y < 0 or x >= w or y >= h:
                    problems.append(f'{name} #{i+1}: warp outside dimensions')
                else:
                    actual = role_names[role_grid[y*w+x]]
                    check(actual == event['role'], f'{name} #{i+1}: collision role wrong')
            if event['role'] == 'WARP_CARPET_DOWN':
                check(event['trigger']=='DIRECTIONAL_COLLISION' and event['direction']=='DOWN', f'{name} #{i+1}: DOWN-only must not be STEP_IN')
            elif event['role'] in {'LADDER', 'PIT', 'CAVE'}:
                check(event['trigger']=='STEP_IN_IMMEDIATE', f'{name} #{i+1}: missing immediate trigger')
            elif event['role'] == 'ICE':
                reverse_pit_count+=1
                check(event['trigger']=='ARRIVAL_ONLY_OR_SPECIAL_REVIEW', f'{name} #{i+1}: ICE arrival-only must not warp upward')
            else:
                problems.append(f'{name} #{i+1}: unexpected role {event["role"]}')
            dest = event['destination']
            if dest in named:
                target = named[dest]['warps']
                d = event['destination_warp_1_based']
                if not 1 <= d <= len(target):
                    problems.append(f'{name} #{i+1}: invalid destination ordinal')
                else:
                    check(target[d-1]['destination']==name and target[d-1]['destination_warp_1_based']==i+1,
                          f'{name} #{i+1}: reciprocal Gold destination mismatch')
    check(reverse_pit_count == 4, 'expected four arrival-only ICE landing warps')
    check(sorted((x['source'],x['x'],x['y'],x['dest_warp_1_based']) for x in contract.get('outside_warps', [])) ==
          [('BlackthornCity', 36, 9, 2), ('Route44', 56, 7, 1)], 'Gold outdoor entry locations changed')
    for x in contract.get('outside_warps', []):
        check(x['role'] == 'CAVE', 'Gold outdoor cave entrance must be CAVE step-in')

    # REF-367K exception: the Gold resources remain verified for all floors;
    # 1F+B1F are walk-only pilots, B2F/B3F still closed. No slide/PIT/Strength.
    region = (root / 'constants/region_map_constants.asm').read_text(encoding='utf-8')
    check('DEF NUM_JOHTO_ACTIVE_MAPS EQU 67' in region,
          'only Ice Path 1F and B1F walk pilots should activate, for 67 maps')
    runtime = (root / 'data/johto_header_descriptors.asm').read_text(encoding='utf-8')
    check('dw JohtoIcePath1FRuntimeHeader367E' in runtime,
          'IcePath1F header not registered')
    check('dw JohtoIcePathB1FRuntimeHeader367K' in runtime, 'Ice Path B1F not activated')
    for closed in ('JohtoIcePathB2F', 'JohtoIcePathB3F'):
        check(closed not in runtime, f'underground map activated too early: {closed}')
    check('db "REF-367@"' in (root / 'data/game_version.asm').read_text(encoding='utf-8'),
          'official CLEAN label mismatch')
    return problems


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    a=p.parse_args()
    errors=audit(a.root)
    if errors:
        for e in errors: print('FAIL:',e)
        print(f'FAIL {len(errors)} errors')
        return 1
    print('PASS: Ice Path 5 maps, 3,060 roles, 22 Warps, 4 PIT and 4 arrival-only ICE; only 1F/B1F walk pilots active; B2F/B3F still sealed')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
