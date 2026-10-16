#!/usr/bin/env python3
"""Fail closed when a new RPP Johto Warp is enabled without a reviewed contract."""
from pathlib import Path
import json
import re

FAMILIES = frozenset(('GATE_OUTDOOR', 'GATE_INDOOR', 'CAVE_OUTDOOR',
                      'CAVE_INDOOR', 'BUILDING', 'LADDER_STAIRS',
                      'DIRECTIONAL', 'PANEL', 'PIT', 'SCRIPTED'))


def warp_count(path: Path) -> int:
    text = path.read_text(encoding='utf-8')
    statements = [line.split(';', 1)[0].strip() for line in text.splitlines()
                  if line.split(';', 1)[0].strip()]
    if not statements or not statements[0].endswith(':'):
        raise ValueError(f'mapObject missing label: {path.name}')
    fields = []
    for statement in statements[1:]:
        match = re.fullmatch(r'db\s+(\$[0-9a-fA-F]+|\d+)', statement)
        if match:
            val = match.group(1)
            fields.append(int(val[1:], 16) if val.startswith('$') else int(val))
            if len(fields) == 2:
                return fields[1]
        else:
            raise ValueError(f'unsupported Warp header before count in {path.name}: {statement}')
    raise ValueError(f'mapObject missing Warp count: {path.name}')


def audit(root: Path, gold: Path) -> tuple[list[str], set[str]]:
    errors, required_ids = [], set()
    try:
        data = json.loads((root / 'tools/johto_door_contracts.json').read_text())
        if data['schema'] != 'rpp-native-door-onboarding-v1':
            raise ValueError('unsupported door contract schema')
        contracts = data['active_warp_maps']
    except (OSError, ValueError, KeyError, TypeError) as exc:
        return [f'door contract unreadable: {exc}'], required_ids
    seen = set()
    for entry in contracts:
        try:
            name = entry['rpp_map']
            family = entry['family']
            count = entry['warp_count']
            gold_map = entry['gold_map']
            tests = entry['required_test_ids']
            if name in seen:
                errors.append(f'duplicate door contract: {name}')
            seen.add(name)
            if family not in FAMILIES:
                errors.append(f'unsupported entrance family {name}: {family}')
            if not isinstance(count, int) or count < 1:
                errors.append(f'invalid Warp count contract {name}: {count}')
            if not isinstance(tests, list) or not tests or any(not isinstance(t, str) or not t.startswith('test_') for t in tests):
                errors.append(f'no static proof test ids for {name}')
            else:
                required_ids.update(tests)
            if not (gold / 'maps' / f'{gold_map}.asm').is_file():
                errors.append(f'Gold entrance map missing for {name}: {gold_map}')
        except (TypeError, KeyError) as exc:
            errors.append(f'incomplete door contract: {exc}')
    active = {}
    for f in sorted((root / 'data/mapObjects').glob('Johto*.asm')):
        try:
            n = warp_count(f)
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
            continue
        if n:
            active[f.stem] = n
    for name, count in active.items():
        if name not in seen:
            errors.append(f'enabled Johto Warp lacks type/Gold/test contract: {name} ({count} Warp)')
    for entry in contracts:
        if not isinstance(entry, dict) or 'rpp_map' not in entry or 'warp_count' not in entry:
            continue
        actual = active.get(entry['rpp_map'], 0)
        if actual != entry['warp_count']:
            errors.append(f'Johto Warp count/contract mismatch {entry["rpp_map"]}: '
                          f'RPP={actual}, declared={entry["warp_count"]}')
    return errors, required_ids
