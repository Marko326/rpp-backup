#!/usr/bin/env python3
"""Fail-closed preflight for *all active* Johto map-name popups.

Checks the stable-ID runtime roster, the neutral-gate filter, each named
landmark dispatch and literal, and the Town Map name table used for Save/Continue.
This is an ASM source audit; it does not emulate the ROM.

Usage: python tools/johto_map_name_sign_audit.py --project .
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

CONTRACT = 'tools/johto_map_name_sign_contracts.json'


def section(source: str, label: str, end: str) -> str:
    start_match = re.search(r'(?m)^' + re.escape(label) + r'(?:::?)?\s*$', source)
    if not start_match:
        raise ValueError(f'missing label: {label}')
    end_match = re.search(r'(?m)^' + re.escape(end) + r'(?:::?)?\s*$', source[start_match.end():])
    if not end_match:
        raise ValueError(f'missing terminating label: {end}')
    return source[start_match.end():start_match.end() + end_match.start()]


def name_text(value: str) -> str:
    return ' '.join(value.removesuffix('@').replace('_', ' ').split()).casefold()


def audit(root: Path) -> dict:
    root = Path(root)
    errors: list[str] = []
    checks: list[dict] = []

    def check(label: str, condition: bool, message: str) -> None:
        checks.append({'check': label, 'status': 'PASS' if condition else 'FAIL', 'detail': message})
        if not condition:
            errors.append(f'{label}: {message}')

    try:
        contract = json.loads((root / CONTRACT).read_text(encoding='utf-8'))
        sign = (root / 'engine/overworld/map_name_sign.asm').read_text(encoding='utf-8')
        fly = (root / 'engine/fly_town_map_helpers.asm').read_text(encoding='utf-8')
        map_names = (root / 'text/map_names.asm').read_text(encoding='utf-8')
        assets = (root / 'data/johto_pilot_runtime_assets.asm').read_text(encoding='utf-8')
        constants = (root / 'constants/region_map_constants.asm').read_text(encoding='utf-8')
        fixed = (root / 'constants/johto_fixed_map_ids.asm').read_text(encoding='utf-8')
        maps = contract['active_maps']
        assert contract['schema'] == 'johto-map-sign-contract-v1'
        assert isinstance(maps, list)
        desc = section(assets, 'JohtoPilotRuntimeResourceDescriptors', 'JohtoPilotRuntimeResourceDescriptorsEnd')
        active = re.findall(r'(?m)^\s*db\s+(JOHTO_\w+_LOCAL_ID)\s*,', desc)
        count = int(re.search(r'DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)', constants).group(1))
        all_ids = set(re.findall(r'(?m)^\s*DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+', fixed + '\n' + constants))
        ids = [m['id'] for m in maps]
        check('active_map_coverage', len(active) == count and ids == active and
              len(set(ids)) == len(ids) and all(i in all_ids for i in ids),
              f'active source slots={len(active)}, contract slots={len(ids)}, count={count}; '
              'each newly activated map must have exactly one sign policy')
        for m in maps:
            check('contract_policy_' + m['id'],
                  set(m) == ({'id', 'role', 'name', 'town_map_name'} if m.get('role') == 'named'
                             else {'id', 'role', 'town_map_name'}) and
                  m.get('role') in ('neutral', 'named') and
                  (m['id'].endswith('_GATE_LOCAL_ID') == (m.get('role') == 'neutral')),
                  'active gate must be neutral; all other maps need an explicit named policy')

        neutral = section(sign, '.IsNeutralMap', '.legacyNeutralMap')
        resolve = section(sign, '.ResolvePhysicalLandmark', '.resolveLegacyLandmark')
        sign_texts = dict(re.findall(r'(?m)^\s*(\.Johto\w+Name):\s*db\s+"([^"\n]+)"', sign))
        town_texts = dict(re.findall(r'(?m)^\s*(JohtoPilot\w+Name)::?\s*\n?\s*db\s+"([^"\n]+)"', fly + '\n' + map_names))
        entries = section(fly, 'JohtoPilotTownMapEntries', 'JohtoPilotTownMapEntriesEnd')
        town_labels = re.findall(r'(?m)^\s*dw\s+(JohtoPilot\w+Name)\s*$', entries)
        check('town_map_slot_count', len(town_labels) == len(active),
              'Town Map/Save/Continue name entries must match active slot count')

        guard = (re.search(r'(?s)ld a,\s*\[wCurMap\]\s*cp JOHTO_RUNTIME_MAP_HANDLE\s*jr nz, \.legacyNeutralMap'
                           r'.*?ld a,\s*\[wCurRegion\]\s*cp MAP_REGION_JOHTO\s*jr nz, \.legacyNeutralMap'
                           r'.*?ld a,\s*\[wCurLocalMapID\]', neutral) is not None)
        resolve_guard = (re.search(r'(?s)ld a,\s*\[wCurMap\]\s*cp JOHTO_RUNTIME_MAP_HANDLE\s*j[pr] nz, \.resolveLegacyLandmark'
                                   r'.*?ld a,\s*\[wCurRegion\]\s*cp MAP_REGION_JOHTO\s*j[pr] nz, \.resolveLegacyLandmark'
                                   r'.*?ld a,\s*\[wCurLocalMapID\]', resolve) is not None)
        check('region_handle_guard', guard and resolve_guard,
              'both neutral filter and native name resolver must use region + $FC handle + stable ID')

        neutral_symbols = re.findall(r'(?m)^\s*cp\s+(JOHTO_\w+_LOCAL_ID)\s*\n\s*ret z\b', neutral)
        neutral_expected = [m['id'] for m in maps if m.get('role') == 'neutral']
        check('all_neutral_gates', set(neutral_symbols) == set(neutral_expected) and
              len(neutral_symbols) == len(neutral_expected),
              f'neutral IDs in ASM={neutral_symbols}; required={neutral_expected}')

        dispatch = dict(re.findall(r'(?m)^\s*cp\s+(JOHTO_\w+_LOCAL_ID)\s*\n\s*j[pr] z,\s*(\.johto\w+)\s*$', resolve))
        named_expected = [m['id'] for m in maps if m.get('role') == 'named']
        check('all_named_dispatches', set(dispatch) == set(named_expected) and
              len(dispatch) == len(named_expected),
              f'named stable-ID branches={list(dispatch)}; required={named_expected}')

        label_targets: dict[str, str] = {}
        # Standalone local target labels, including the final .johtoRoute32 fallthrough.
        for target, label in re.findall(r'(?m)^(\.johto\w+)\s*\n\s*ld hl,\s*(\.Johto\w+Name)\s*$', resolve):
            label_targets[target] = label

        for slot, entry in enumerate(maps):
            ident = entry['id']
            if slot >= len(town_labels):
                check('town_name_' + ident, False, 'missing Town Map/Save entry for slot')
                continue
            town_label = town_labels[slot]
            town_name = town_texts.get(town_label)
            check('town_name_' + ident, town_name is not None and
                  name_text(town_name) == name_text(entry['town_map_name']),
                  f'slot {slot} uses {town_label}={town_name!r}, expected {entry["town_map_name"]!r}')
            if entry['role'] == 'named':
                label = label_targets.get(dispatch.get(ident, ''))
                actual_name = sign_texts.get(label)
                check('popup_name_' + ident, actual_name is not None and
                      name_text(actual_name) == name_text(entry['name']) and
                      name_text(actual_name) == name_text(town_name or ''),
                      f'dispatch={dispatch.get(ident)}, label={label}, popup={actual_name!r}, '
                      f'Town Map={town_name!r}, expected={entry["name"]!r}; no Johto fallback')
            else:
                check('neutral_has_no_named_dispatch_' + ident, ident not in dispatch,
                      f'gate {ident} must inherit previous landmark, not display fallback Johto')

        init = section(sign, '.mapChanged', '.resolveLandmark')
        check('neutral_popup_inherits_previous',
              re.search(r'call \.IsNeutralMap\s*jr nz, \.resolveLandmark', init) is not None and
              re.search(r'jp nz, \.cancel', init) is not None and
              re.search(r'call \.ResolvePhysicalLandmark\s*jp \.storeWithoutShowing', init) is not None,
              'neutral transitions must cancel popup, and Continue inside gate must not display fallback')
    except (OSError, ValueError, TypeError, KeyError, AssertionError, AttributeError) as exc:
        check('read_and_parse', False, str(exc))

    return {'schema': 'johto-map-sign-audit-v1', 'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'errors': errors, 'checks': checks, 'runtime_verified': False, 'rom_built': False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path.cwd())
    parser.add_argument('--json-out', type=Path)
    args = parser.parse_args()
    report = audit(args.project)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'status': report['status'], 'checked': len(report['checks']),
                      'errors': report['errors']}, ensure_ascii=False, indent=2))
    return 0 if not report['errors'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
