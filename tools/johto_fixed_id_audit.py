#!/usr/bin/env python3
"""Fail-closed gate for the frozen Johto stable local-ID roster.

The 222-slot roster comes from the reviewed handoff, not from dynamic map
registration.  This gate deliberately does *not* activate reserved maps or
implement sparse-ID runtime lookup; it blocks accidental activation before
such a migration is independently reviewed and accepted.
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ROSTER = 'tools/johto_fixed_ids.csv'
REGISTRY = 'tools/johto_native_maps.json'
CONSTANTS = 'constants/region_map_constants.asm'
RESERVED_ASM = 'constants/johto_fixed_map_ids.asm'
MAKEFILE = 'Makefile'
HEADERS = 'data/johto_map_headers.asm'
FROZEN_SHA256 = 'ec21c01f7b25444c5ed6ed96e78135789e71c12d317065ea59188c5f87440046'
GOLD_REFERENCE = 'tools/johto_gold_map_reference.csv'
GOLD_REFERENCE_SHA256 = 'ca8a930a57204add426da40f65d54b5068cabb066590a6509a0d19389eb947a7'
COLUMNS = ('id', 'id_hex', 'gold_name', 'owner', 'gold_group',
           'gold_group_id', 'gold_map_id', 'gold_const_symbol',
           'width_blocks', 'height_blocks', 'status', 'original_class', 'original_symbol')
GOLD_COLUMNS = ('gold_group_id', 'gold_map_id', 'gold_group', 'gold_name',
                'gold_const_symbol', 'width_blocks', 'height_blocks')
OWNERS = ((0, 20, '既有'), (21, 22, '共同起步'),
          (23, 61, '西线A'), (62, 101, '东线B'),
          (102, 191, '共用C'), (192, 221, '后期C'))


def _read(root: Path, rel: str, overrides: dict[str, str]) -> str:
    if rel in overrides:
        return overrides[rel]
    return (root / rel).read_text(encoding='utf-8-sig')


def _parse_gold_source(gold_root: Path) -> list[dict[str, str]]:
    """Reconstruct original 1-based Gold group/map numbers from its two tables.

    Checking both maps.asm order and map_constants.asm dimensions avoids the
    common mistake of interpreting the RPP stable local ID as a Gold pair.
    """
    maps_path = gold_root / 'data/maps/maps.asm'
    const_path = gold_root / 'constants/map_constants.asm'
    maps = maps_path.read_text(encoding='utf-8')
    constants = const_path.read_text(encoding='utf-8')
    groups = re.findall(r'(?m)^\s*dw\s+MapGroup_(\w+)\s*;\s*\d+',
                        maps.split('MapGroupPointers::', 1)[1].split('assert_table_length', 1)[0])
    map_groups: dict[str, list[str]] = {}
    current = None
    for line in maps.splitlines():
        m = re.match(r'^MapGroup_(\w+):', line)
        if m:
            current = m.group(1)
            map_groups[current] = []
        m = re.match(r'^\s*map\s+([A-Za-z0-9_]+)\s*,', line)
        if m:
            if current is None:
                raise ValueError('Gold map entry occurs without a mapgroup')
            map_groups[current].append(m.group(1))
    const_groups: dict[str, list[tuple[str, str, str]]] = {}
    current = None
    for line in constants.splitlines():
        m = re.match(r'^\s*newgroup\s+([A-Z0-9_]+)', line)
        if m:
            current = m.group(1)
            const_groups[current] = []
        m = re.match(r'^\s*map_const\s+([A-Z0-9_]+),\s*(\d+),\s*(\d+)', line)
        if m:
            if current is None:
                raise ValueError('Gold map constant without a group')
            const_groups[current].append(m.groups())
    if (len(groups) != 26 or len(map_groups) != len(groups) or
            list(map_groups) != groups or len(const_groups) != len(groups)):
        raise ValueError('Gold group ordering/count differs from expected 26 groups')
    result = []
    for g_idx, (group_name, (const_name, const_rows)) in enumerate(
            zip(groups, const_groups.items()), 1):
        if group_name.replace('_', '').upper() != const_name.replace('_', '').upper():
            raise ValueError(f'Gold group ordering mismatch at {g_idx}: {group_name}')
        if len(const_rows) != len(map_groups[group_name]):
            raise ValueError(f'Gold map number/size count mismatch in {group_name}')
        for m_idx, (map_name, (symbol, width, height)) in enumerate(
                zip(map_groups[group_name], const_rows), 1):
            result.append(dict(zip(GOLD_COLUMNS,
                 (str(g_idx), str(m_idx), group_name, map_name,
                  symbol, width, height))))
    if len(result) != 368 or len({r['gold_name'] for r in result}) != len(result):
        raise ValueError(f'Gold 368-map corpus changed, found {len(result)} entries')
    return result


def audit(root: Path = ROOT, overrides: dict[str, str] | None = None,
          gold_root: Path | None = None) -> list[str]:
    """Return blocking errors; no Gold input or ROM compile is required."""
    overrides = overrides or {}
    errors = []
    try:
        raw = {name: _read(Path(root), name, overrides)
               for name in (ROSTER, GOLD_REFERENCE, REGISTRY, CONSTANTS, RESERVED_ASM, MAKEFILE, HEADERS)}
    except (OSError, UnicodeError) as exc:
        return [f'fixed local-ID contract missing/unreadable: {exc}']

    if hashlib.sha256(raw[GOLD_REFERENCE].encode('utf-8').rstrip(b'\n') + b'\n').hexdigest() != GOLD_REFERENCE_SHA256:
        errors.append('frozen Gold 368-map reference CSV changed; C review required')
    greader = csv.DictReader(io.StringIO(raw[GOLD_REFERENCE]))
    if tuple(greader.fieldnames or ()) != GOLD_COLUMNS:
        return errors + ['Gold original ID reference column schema drifted']
    gold_ref = list(greader)
    if len(gold_ref) != 368 or len({r['gold_name'] for r in gold_ref}) != 368:
        errors.append('Gold reference must have 368 distinct maps')
    expected_reference = {r['gold_name']: r for r in gold_ref}
    for i, item in enumerate(gold_ref):
        try:
            g = int(item['gold_group_id'])
            n = int(item['gold_map_id'])
            w = int(item['width_blocks'])
            h = int(item['height_blocks'])
        except (ValueError, TypeError):
            errors.append(f'Gold reference row {i}: bad original numeric ID/size')
            continue
        if not 1 <= g <= 26 or not 1 <= n <= 255 or min(w, h) <= 0:
            errors.append(f'Gold reference row {i}: invalid original ID/dimensions')
    if gold_root is not None:
        try:
            actual = _parse_gold_source(Path(gold_root))
        except (ValueError, OSError, IndexError, UnicodeError) as exc:
            errors.append(f'Gold original ID cross-check unavailable/invalid: {exc}')
        else:
            if actual != gold_ref:
                first = next(((i, a, b) for i, (a, b) in enumerate(zip(actual, gold_ref))
                              if a != b), None)
                errors.append(f'Gold original 368-map cross-check mismatch: {first}')

    reader = csv.DictReader(io.StringIO(raw[ROSTER]))
    if tuple(reader.fieldnames or ()) != COLUMNS:
        return ['fixed roster column schema drifted']
    rows = list(reader)
    if len(rows) != 222:
        errors.append(f'frozen roster must contain 222 rows, found {len(rows)}')
    canonical = '\n'.join(
        f'{r["id"]}:{r["gold_name"]}:{r["owner"]}:{r["original_symbol"]}:'
        f'{r["gold_group_id"]}:{r["gold_map_id"]}:{r["gold_const_symbol"]}:'
        f'{r["width_blocks"]}:{r["height_blocks"]}' for r in rows).encode('utf-8')
    if hashlib.sha256(canonical).hexdigest() != FROZEN_SHA256:
        errors.append('frozen stable-ID/name/owner roster changed; C review required')

    seen_names = set()
    for pos, row in enumerate(rows):
        try:
            id_ = int(row['id'])
        except (ValueError, TypeError):
            errors.append(f'roster row {pos}: invalid local ID')
            continue
        if id_ != pos or id_ >= 255:
            errors.append(f'roster row {pos}: nonunique/out-of-order/reserved stable ID {id_}')
        if row['id_hex'] != f'${id_:02X}':
            errors.append(f'roster row {pos}: bad hex ID')
        name = row['gold_name']
        if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', name):
            errors.append(f'roster row {pos}: invalid Gold map name {name!r}')
        if name in seen_names:
            errors.append(f'roster row {pos}: duplicate Gold map name {name}')
        seen_names.add(name)
        reference = expected_reference.get(name)
        if reference is None:
            errors.append(f'roster row {pos}: Gold map name absent from 368 original IDs: {name}')
        elif any(row[key] != reference[key] for key in GOLD_COLUMNS):
            errors.append(f'roster row {pos}: original Gold pair/size/group mismatch for {name}')
        expected_owner = next((owner for lo, hi, owner in OWNERS if lo <= id_ <= hi), None)
        if row['owner'] != expected_owner:
            errors.append(f'roster row {pos}: wrong owner {row["owner"]!r}')
        if row['status'] != ('已登记' if id_ < 21 else '规划'):
            errors.append(f'roster row {pos}: roster status must describe baseline, not activation')

    try:
        contract = json.loads(raw[REGISTRY])
        active = contract['maps']
        assert isinstance(active, list)
        assert contract['schema_version'] == 1
    except (ValueError, TypeError, KeyError, AssertionError) as exc:
        return errors + [f'active map registry invalid: {exc}']
    const = raw[CONSTANTS]
    reserved = raw[RESERVED_ASM]
    # A/B get unique ASM symbols before implementation without enlarging the
    # runtime arrays. The inclusion is part of the actual assembler input.
    if const.count('INCLUDE "constants/johto_fixed_map_ids.asm"') != 1:
        errors.append('frozen Johto ASM reservation INCLUDE missing or duplicated')
    for symbol, value in (
            ('JOHTO_FROZEN_LOCAL_ID_COUNT', 222),
            ('JOHTO_RESERVED_FIRST_LOCAL_ID', 21),
            ('JOHTO_RESERVED_LAST_LOCAL_ID', 221),
            ('JOHTO_UNASSIGNED_FIRST_LOCAL_ID', 222)):
        if len(re.findall(r'(?m)^DEF\s+' + symbol + r'\s+EQU\s+' + str(value) + r'\s*$', reserved)) != 1:
            errors.append(f'frozen ASM reservation boundary incorrect: {symbol}')
    if not re.search(r'(?m)^DEF\s+JOHTO_INVALID_LOCAL_ID\s+EQU\s+\$ff\s*$', reserved):
        errors.append('frozen ASM invalid local ID sentinel changed')
    def defs(code: str):
        return re.findall(r'(?m)^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\d+)\s*(?:;[^\n]*)?$', code)
    reservation_meta = {"JOHTO_RESERVED_FIRST_LOCAL_ID", "JOHTO_RESERVED_LAST_LOCAL_ID",
                        "JOHTO_UNASSIGNED_FIRST_LOCAL_ID"}
    defined = [(name, number) for name, number in defs(reserved)
               if name not in reservation_meta]
    if len(defined) != len(rows) - 21 or len({name for name, _ in defined}) != len(defined):
        errors.append('frozen ASM reservation count/unique symbol mismatch')
    actual_reservations = {name: int(number) for name, number in defined}
    expected_reservations = {'JOHTO_' + row['gold_const_symbol'] + '_LOCAL_ID': int(row['id'])
                             for row in rows[21:] if row['id'].isdigit()}
    for symbol, number in expected_reservations.items():
        if actual_reservations.get(symbol) != number:
            errors.append(f'frozen ASM reservation missing/wrong: {symbol} expected {number}')
    for symbol in actual_reservations.keys() - expected_reservations.keys():
        errors.append(f'unknown/unallocated fixed ASM map symbol: {symbol}')
    # The common Makefile enforces the reservation gate even during parallel
    # normal ROM builds. This tool itself never invokes make or links a ROM.
    makefile = raw[MAKEFILE]
    if ('$(pokered_obj) $(pokeblue_obj): | johto-id-preflight' not in makefile or
            'python3 tools/johto_fixed_id_audit.py --project .' not in makefile):
        errors.append('fixed ID preflight missing from normal ROM build prerequisites')
    count_match = re.search(r'(?m)^DEF NUM_JOHTO_MAPS EQU (\d+)\s*$', const)
    if not count_match:
        errors.append('NUM_JOHTO_MAPS count missing')
    elif int(count_match.group(1)) != len(active):
        errors.append('NUM_JOHTO_MAPS count disagrees with actual active registry')

    # The original engine uses local ID directly as an array offset.  Until C
    # ships a COMPLETE, independently tested sparse lookup, a high ID with gaps
    # cannot be activated, even though it is reserved for the right branch.
    if len(active) > 23:
        errors.append('sparse-ID runtime not implemented/accepted: no expansion past 21,22')
    symbols = dict((key, int(value)) for key, value in re.findall(
        r'(?m)^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\d+)\s*$', const))
    if len(symbols) != len(re.findall(
        r'(?m)^DEF\s+JOHTO_\w+_LOCAL_ID\s+EQU\s+\d+\s*$', const)):
        errors.append('duplicate Johto local-ID ASM constant symbol')
    expected_symbols = set()
    for slot, spec in enumerate(active):
        if not isinstance(spec, dict):
            errors.append(f'active map #{slot}: invalid registry item')
            continue
        id_ = spec.get('local_id')
        if not isinstance(id_, int) or isinstance(id_, bool) or not 0 <= id_ < 255:
            errors.append(f'active map #{slot}: invalid/reserved physical local ID')
            continue
        if id_ >= len(rows):
            errors.append(f'active map #{slot}: local ID {id_} not in frozen roster')
            continue
        row = rows[id_]
        if id_ != slot:
            errors.append(f'active map #{slot}: sparse ID {id_} forbidden until runtime migration')
        sym = spec.get('local_symbol')
        if not isinstance(sym, str) or not sym.endswith('_LOCAL_ID'):
            errors.append(f'active map #{slot}: bad local ASM symbol')
            continue
        expected_symbols.add(sym)
        asm_id = symbols.get(sym) if id_ < 21 else actual_reservations.get(sym)
        if asm_id != id_:
            errors.append(f'active map #{slot}: ASM ID constant missing/wrong for {sym}')
        if id_ >= 21 and sym != 'JOHTO_' + row['gold_const_symbol'] + '_LOCAL_ID':
            errors.append(f'active map #{slot}: wrong frozen ASM map symbol for {row["gold_name"]}')
        if id_ < 21:
            if sym != row['original_symbol']:
                errors.append(f'active map #{slot}: historical 0-20 symbol changed')
        elif (spec.get('header') != f'Johto{row["gold_name"]}_h'
              or spec.get('bank') != f'BANK(Johto{row["gold_name"]}_h)'):
            errors.append(f'active map #{slot}: header identity disagrees with frozen {row["gold_name"]}')

    for sym in symbols.keys() & actual_reservations.keys():
        errors.append(f'ASM map symbol defined twice in active/reserved files: {sym}')
    for sym in symbols.keys() - expected_symbols:
        errors.append(f'unregistered/preallocated Johto local-ID constant {sym}')
    # A map must never be made to look active by changing its table cardinality
    # while omitting the audited registry, even in Gold-free preflight checks.
    main_asm = _read(Path(root), 'main.asm', overrides)
    for slot, item in enumerate(active[21:], start=21):
        if not isinstance(item, dict) or not isinstance(item.get('local_id'), int):
            continue
        id_ = item['local_id']
        if not 0 <= id_ < len(rows):
            continue
        name = 'Johto' + rows[id_]['gold_name']
        for rel in (f'maps/{name}.blk', f'data/mapHeaders/{name}.asm',
                    f'data/mapObjects/{name}.asm', f'scripts/{name}.asm'):
            if not (Path(root) / rel).is_file() and rel not in overrides:
                errors.append(f'active map #{slot}: missing actual map asset {rel}')
            if f'\"{rel}\"' not in main_asm:
                errors.append(f'active map #{slot}: missing ROM include for {rel}')
    if len(active) > 0:
        headers = re.findall(r'(?m)^\s*dw\s+(\w+_h)\s*(?:;[^\n]*)?$',
                             raw[HEADERS].split('JohtoMapHeaderPointers::', 1)[-1]
                                         .split('JohtoMapHeaderPointersEnd::', 1)[0])
        if headers != [item.get('header') for item in active if isinstance(item, dict)]:
            errors.append('live Header pointer order differs from audited identity registry')
    return errors


def main() -> int:
    import argparse
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project', type=Path, default=ROOT)
    ap.add_argument('--gold', type=Path, default=None,
                    help='pokegold-master root for independent 368-map source check')
    args = ap.parse_args()
    issues = audit(args.project, gold_root=args.gold)
    for item in issues:
        print('FAIL:', item)
    if issues:
        return 1
    if args.gold is None:
        print('PASS: 222 RPP stable IDs frozen in ASM + CSV; 368-entry Gold reference CSV integrity checked; '
              'external Gold source comparison NOT RUN; sparse activation blocked')
    else:
        print('PASS: 222 RPP stable IDs frozen in ASM + CSV; '
              '368 original Gold maps cross-checked against supplied Gold source; '
              'sparse activation blocked')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
