#!/usr/bin/env python3
"""Gold asset/warp audit covering ALPH-NORTH-001 live south/north corridors.

All four Gold staged maps are now active; incomplete indoor entrances remain blocked. This read-only audit does not report user-device acceptance.
Usage: python tools/johto_ruins_stage_audit.py [--gold-root /.../pokegold-master]
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = 'tools/johto_ruins_stage_contract.json'
GOLD_EVENT_NAMES = {
    'Route32': 'Route32.asm', 'RuinsOfAlphOutside': 'RuinsOfAlphOutside.asm',
    'Route32RuinsOfAlphGate': 'Route32RuinsOfAlphGate.asm',
    'Route36RuinsOfAlphGate': 'Route36RuinsOfAlphGate.asm',
    'Route36': 'Route36.asm',
}
GOLD_MAP_CONSTANTS = {
    'Route32': 'ROUTE_32', 'RuinsOfAlphOutside': 'RUINS_OF_ALPH_OUTSIDE',
    'Route32RuinsOfAlphGate': 'ROUTE_32_RUINS_OF_ALPH_GATE',
    'Route36RuinsOfAlphGate': 'ROUTE_36_RUINS_OF_ALPH_GATE',
    'Route36': 'ROUTE_36',
}


def _bytes(root, rel):
    return (root / rel).read_bytes()


def validate_asset_hashes(root, contract):
    issues = []
    for name, row in contract['assets'].items():
        for filekey, digestkey in (('staged_file', 'gold_sha256'),
                                    ('candidate_file', 'candidate_sha256')):
            if filekey not in row:
                continue
            try:
                data = _bytes(root, row[filekey])
            except OSError:
                issues.append(f'{name}: missing {row[filekey]}')
                continue
            if len(data) != row['size'] or hashlib.sha256(data).hexdigest() != row[digestkey]:
                issues.append(f'{name}: changed {row[filekey]} (size/hash)')
    return issues


def _warps(text):
    # Gold uses zero-based x,y and one-based destination warp numbers.
    return [(int(x), int(y), dest.strip(), int(warp)-1)
            for x,y,dest,warp in re.findall(
                r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z0-9_]+)\s*,\s*(\d+)\b', text)]


def audit(project=ROOT, gold_root=None):
    project = Path(project)
    record = json.loads((project / CONTRACT).read_text(encoding='utf-8'))
    issues = validate_asset_hashes(project, record)
    if record['status'] != 'NORTH_ROUTE_RUNTIME_STATIC_PENDING_BUILD' or record['runtime_approved'] or record['build_performed']:
        issues.append('runtime approval/build status was prematurely changed')
    if record['main_version_unchanged'] != 'MAP-5.62.257':
        issues.append('expected MAP-5.62.254 for southern runtime candidate')
    constants = (project / 'constants/region_map_constants.asm').read_text()
    if not re.search(r'(?m)^DEF NUM_JOHTO_ACTIVE_MAPS EQU 15$', constants):
        issues.append('unexpected current active count')
    stable_text = (project / 'data/johto_stable_id_slots.asm').read_text()
    dbpart = stable_text.split('JohtoStableIDToActiveSlot::')[1].split('JohtoStableIDToActiveSlotEnd::')[0]
    slots = []
    for ln in dbpart.splitlines():
        ln = ln.split(';')[0].strip()
        if ln.startswith('db '):
            slots.extend(x.strip() for x in ln[3:].split(','))
    if len(slots) != 256:
        issues.append(f'stable slot array length {len(slots)} !=256')
    else:
        for row in record['maps']:
            active_slot = {'RuinsOfAlphOutside': '10', 'Route32RuinsOfAlphGate': '9', 'Route36RuinsOfAlphGate':'11', 'Route36':'12'}.get(row['name'], 'JOHTO_INVALID_ACTIVE_SLOT')
            if slots[row['stable_id']] != active_slot:
                issues.append(f'{row["name"]}: slot mismatch (expected {active_slot})')
    if 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID EQU 102' not in (project/'constants/johto_fixed_map_ids.asm').read_text():
        issues.append('Route32 ruins gate stable ID changed')
    # All four source maps are live. Freeze explicit north mapping, but preserve south IDs.
    runtime_main = (project / 'main.asm').read_text()
    north_source = (project / 'data/johto_ruins_north_runtime.asm').read_text()
    for symbol in ('JohtoPilotAlphNorthGateRuntimeHeader', 'JohtoPilotRoute36RuntimeHeader'):
        if symbol + '::' not in north_source or symbol not in runtime_main and 'Johto Ruins North Runtime' not in runtime_main:
            issues.append(f'northern runtime missing {symbol}')
    for name in ('Route36', 'Route36RuinsOfAlphGate'):
        if (project/f'maps/johto_pilot/{name}.runtime.blk').read_bytes() != _bytes(project,record['assets'][name]['candidate_file']):
            issues.append(f'{name}: live runtime differs from candidate')
    assets = record['assets']
    gate_candidate = _bytes(project, assets['Route32RuinsOfAlphGate']['candidate_file'])
    if gate_candidate != _bytes(project, 'maps/johto_pilot/Route31VioletGate.runtime.blk'):
        issues.append('southern gate compact candidate differs from approved EastWestGate layout')
    gold_gate = _bytes(project, assets['Route32RuinsOfAlphGate']['staged_file'])
    if gold_gate != _bytes(project, 'maps/johto_pilot/Route31VioletGate.gold.blk'):
        issues.append('two EastWestGate Gold sources do not agree')
    ruins_gold = _bytes(project, assets['RuinsOfAlphOutside']['staged_file'])
    ruins_compact = _bytes(project, assets['RuinsOfAlphOutside']['candidate_file'])
    allowed_remaps = {0x5a:0x86, 0x50:0x8a, 0x56:0x85, 0x51:0x88}
    if not all(old == new or allowed_remaps.get(old) == new for old, new in zip(ruins_gold, ruins_compact)):
        issues.append('unexpected compact block conversion in ruins candidate')
    if len(ruins_gold)!=len(ruins_compact):
        issues.append('ruins source/candidate length differs')
    # Require staged assets to remain disconnected from live included .asm sources.
    for path in project.rglob('*.asm'):
        # Ignore staged and docs; live INCBIN must never consume these files.
        for line in path.read_text(errors='replace').splitlines():
            if line.lstrip().startswith(('INCBIN ', 'INCLUDE ')) and 'maps/johto_staged/' in line:
                issues.append(f'live ASM unexpectedly references staged resource: {path.relative_to(project)}')
    if gold_root:
        gold_root = Path(gold_root)
        for name,row in assets.items():
            try:
                gold = (gold_root / 'maps' / row['gold_block_file']).read_bytes()
                if gold != _bytes(project,row['staged_file']):
                    issues.append(f'{name}: bytes differ from Gold {row["gold_block_file"]}')
            except OSError:
                issues.append(f'{name}: missing Gold source')
        parsed = {name: _warps((gold_root/'maps'/src).read_text())
                  for name,src in GOLD_EVENT_NAMES.items()}
        for link in record['future_link_review']:
            w = parsed[link['from']]
            n = link['warp_ordinal']
            expected = (link['coordinate_xy'][0],link['coordinate_xy'][1],
                        GOLD_MAP_CONSTANTS[link['to']],link['destination_gold_warp_ordinal'])
            if n >= len(w) or w[n] != expected:
                issues.append(f'Gold warp mismatch: {link["from"]}[{n}] expected {expected}, got {w[n] if n < len(w) else None}')
        # Safety: all eleven ruins external warps must be either reviewed or explicitly blocked.
        reviewed = {x['warp_ordinal'] for x in record['future_link_review'] if x['from']=='RuinsOfAlphOutside'}
        blocked = {i for x in record['blocked_until_indoor_maps_live']
                   if x['name']=='RuinsOfAlphOutside' for i in x['gold_warp_ordinals']}
        if reviewed | blocked != set(range(len(parsed['RuinsOfAlphOutside']))):
            issues.append('ruins has unknown warp ordinal without explicit review/block record')
    return issues


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,default=ROOT)
    parser.add_argument('--gold-root',type=Path)
    args=parser.parse_args()
    problems=audit(args.project,args.gold_root)
    if problems:
        for p in problems: print('FAIL:',p)
        raise SystemExit(1)
    print('PASS: 4 Gold source layouts; all four runtime-registered; 13 active maps; static audit only')


if __name__=='__main__':
    main()
