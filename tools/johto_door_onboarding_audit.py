#!/usr/bin/env python3
"""Fail closed when a new RPP Johto Warp is enabled without a reviewed contract."""
from pathlib import Path
import json
import re
from johto_gatehouse_behavior_audit import valid_contract

GATEHOUSE_GUIDE = 'docs/JOHTO_GATEHOUSE_READ_FIRST.md'
GATEHOUSE_PROOFS = ('two_lane_warps', 'directional_collision', 'immediate_return',
                    'exterior_border_loads', 'neutral_map_name',
                    'gold_art_tile_palette', 'runtime_rgb_kanto_isolation',
                    'legacy_gate_regression')
GATEHOUSE_REVIEW_STATES = ('PHONE_PENDING', 'PHONE_ACCEPTED')
# The north-gate .213/.214 regression came from assuming BOTH entrance ends
# should auto-step. Explicitly review each side of every indoor gate; compass
# orientation does not determine the post-warp movement by itself.
GATE_LAYOUT_SIDES = {
    'EAST_WEST_PAIR': frozenset(('west', 'east')),
    'NORTH_SOUTH_PAIR': frozenset(('north', 'south')),
}
ARRIVAL_STEP_OPTIONS = frozenset(('NONE', 'D_UP', 'D_DOWN', 'D_LEFT', 'D_RIGHT'))


def validate_gate_arrival_policy(spec: dict) -> list[str]:
    name = spec.get('rpp_map', 'unknown')
    policy = spec.get('arrival_step_review')
    if not isinstance(policy, dict):
        return [f'{name} missing arrival_step_review; cannot default to both sides auto-step']
    layout = policy.get('layout')
    sides = GATE_LAYOUT_SIDES.get(layout)
    if not sides:
        return [f'{name} unsupported arrival layout (custom multi-exit must be separately reviewed): {layout}']
    observed = policy.get('by_gate_side')
    if not isinstance(observed, dict) or set(observed) != sides:
        return [f'{name} arrival_step_review must specify each side: {sorted(sides)}']
    if any(step not in ARRIVAL_STEP_OPTIONS for step in observed.values()):
        return [f'{name} has unreviewed arrival auto-step mode: {observed}']
    if not isinstance(policy.get('basis'), str) or len(policy['basis'].strip()) < 25:
        return [f'{name} missing arrival-step evidence (Gold destination, collision and source route)']
    return []


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


def audit_warp_capabilities(root: Path) -> list[str]:
    """Reject explicitly forbidden Warps that are enabled in real map objects.

    DEFERRED has historically been used for unreviewed metadata, so do not
    globally relabel it. Only a direct FORBIDDEN/active contradiction is fatal.
    """
    path = root / 'tools/johto_native_maps.json'
    try:
        maps = json.loads(path.read_text())['maps']
        errors = []
        for spec in maps:
            if spec['feature_status']['warp'] != 'FORBIDDEN':
                continue
            stem = spec['header'].removesuffix('_h')
            objects = root / 'data/mapObjects' / (stem + '.asm')
            if objects.is_file() and warp_count(objects):
                errors.append(f'{stem} has active Warp but native map status is FORBIDDEN')
        return errors
    except (OSError, ValueError, KeyError, TypeError) as exc:
        return [f'native Warp capability contract unreadable: {exc}']


def audit(root: Path, gold: Path) -> tuple[list[str], set[str]]:
    errors, required_ids = [], set()
    try:
        data = json.loads((root / 'tools/johto_door_contracts.json').read_text())
        if data['schema'] != 'rpp-native-door-onboarding-v1':
            raise ValueError('unsupported door contract schema')
        contracts = data['active_warp_maps']
    except (OSError, ValueError, KeyError, TypeError) as exc:
        return [f'door contract unreadable: {exc}'], required_ids
    # The handbook is a source-controlled requirement, not a conversation memory.
    guide = root / GATEHOUSE_GUIDE
    try:
        prose = guide.read_text(encoding='utf-8')
        if not all(marker in prose for marker in (
            '## A. 两格门口的行为合同', '## B. 外面建筑完整',
            '## C. 室内素材与调色', '## D. 地图提示',
            '## E. 强制准入', '## F. P16 的失败样本')):
            errors.append(f'gatehouse mandatory guide incomplete: {GATEHOUSE_GUIDE}')
    except OSError:
        errors.append(f'gatehouse mandatory guide missing: {GATEHOUSE_GUIDE}')
    if data.get('gatehouse_guide') != GATEHOUSE_GUIDE or data.get('gatehouse_proof_categories') != list(GATEHOUSE_PROOFS):
        errors.append('gatehouse global onboarding contract/guide missing or outdated')
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
            if family in ('GATE_INDOOR', 'GATE_OUTDOOR') and entry.get('gatehouse_guide') != GATEHOUSE_GUIDE:
                errors.append(f'{name} gate missing mandatory gatehouse_guide')
            if family == 'GATE_INDOOR':
                errors.extend(validate_gate_arrival_policy(entry))
                errors.extend(valid_contract(entry))
                # Review the complete gate, not only the Warp pair. A copied gate
                # must explicitly prove neutral-sign and Gold palette coverage.
                for key in ('neutral_name_sign_test_id', 'gold_palette_test_id'):
                    proof = entry.get(key)
                    if not isinstance(proof, str) or not proof.startswith('test_') or proof not in tests:
                        errors.append(f'{name} gate lacks required {key} in executed tests')
                proofs = entry.get('gatehouse_proof_ids')
                if not isinstance(proofs, dict) or set(proofs) != set(GATEHOUSE_PROOFS):
                    errors.append(f'{name} gate missing mandatory gatehouse proof categories')
                else:
                    ids = list(proofs.values())
                    if any(not isinstance(v, str) or not v.startswith('test_') or v not in tests for v in ids) or len(set(ids)) != len(ids):
                        errors.append(f'{name} gate proof ids missing from executed test list / duplicated')
                    else:
                        required_ids.update(ids)
                for status_name in ('phone_door_status', 'phone_visual_status'):
                    if entry.get(status_name) not in GATEHOUSE_REVIEW_STATES:
                        errors.append(f'{name} gate missing reviewed {status_name}')
                palette_status = entry.get('runtime_palette_status')
                if palette_status not in ('PHONE_PENDING', 'PHONE_ACCEPTED'):
                    errors.append(f'{name} gate lacks reviewed runtime palette status')
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
    errors.extend(audit_warp_capabilities(root))
    return errors, required_ids
