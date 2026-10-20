#!/usr/bin/env python3
"""Offline safety gate for one-slot, region/local Johto map expansion.

This is not an RGBDS compile or a substitute for an in-game connection test.
A new Johto local map must be added to all key tables before being exposed.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
INPUTS = (
    'constants/map_constants.asm', 'constants/region_map_constants.asm',
    'constants/johto_fixed_map_ids.asm',
    'data/map_header_pointers.asm', 'data/map_header_banks.asm',
    'data/map_songs.asm', 'data/hide_show_data.asm',
    'data/johto_map_headers.asm', 'engine/overworld/region_map_lookup.asm',
    'home/overworld.asm', 'engine/town_map.asm',
    'engine/overworld/johto_town_map_helpers.asm', 'engine/menu/options_menu.asm',
    'engine/overworld/map_name_sign.asm', 'wram.asm', 'main.asm',
    'tools/johto_native_maps.json',
)


def entries(text, start, end, prefix):
    block = text.split(start, 1)[1].split(end, 1)[0]
    return re.findall(rf'^\s*{prefix}\s+([^;\n]+)', block, re.M)



FEATURES = ('town_map_background', 'fly', 'bike', 'surf', 'dig',
            'escape_rope', 'cut', 'strength', 'npc', 'warp')
FEATURE_STATES = {'ALLOWED', 'FORBIDDEN', 'DEFERRED', 'NOT_APPLICABLE'}
EVIDENCE = {'STATIC_PASS', 'GOLD_REFERENCE_PENDING', 'PHONE_PENDING', 'USER_ACCEPTED'}


def _asm_rows(source, begin, end, directive):
    return [v.split(';', 1)[0].strip() for v in entries(source, begin, end, directive)]


def check_native_identity(sources, local_symbols, count, tables, gsc):
    """Check EACH local against an explicit registry, not just table lengths.

    The registry is an independent, reviewed expectation. A new map must
    register its identity and staged capabilities before release auditing.
    """
    errors = []
    try:
        manifest = json.loads(sources['tools/johto_native_maps.json'])
    except (ValueError, TypeError) as exc:
        return ['invalid Johto map identity contract: ' + str(exc)]
    if manifest.get('schema_version') != 1 or not isinstance(manifest.get('maps'), list):
        return ['invalid Johto map identity contract schema']
    maps = manifest['maps']
    if len(maps) != count:
        errors.append(f'Johto identity contract count {len(maps)} != {count}; register new map')
    town = sources['engine/town_map.asm']
    town_indices = [v.strip() for row in _asm_rows(sources['engine/overworld/johto_town_map_helpers.asm'], 'JohtoNativeTownMapIndices::',
                            'JohtoNativeTownMapIndicesEnd::', 'db') for v in row.split(',')]
    block = town.split('JohtoNativeTownMapEntries::', 1)[-1].split('JohtoNativeTownMapEntriesEnd::', 1)[0]
    positions = re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*(?:;[^\n]*)?$', block)
    names = _asm_rows(town, 'JohtoNativeTownMapEntries::', 'JohtoNativeTownMapEntriesEnd::', 'dw')
    observed = {
        'header': [v.split(';', 1)[0].strip() for v in tables['header pointers']],
        'bank': [v.split(';', 1)[0].strip() for v in tables['header banks']],
        'legacy_alias': [v.split(';', 1)[0].strip() for v in tables['legacy aliases']],
        'rby_music': [v.split(';', 1)[0].strip() for v in tables['RBY map songs']],
        'gsc_music': [v.split(';', 1)[0].strip() for v in gsc],
        'town_map_index': town_indices,
        'town_map_name': names,
        'town_map_xy': positions,
    }
    for i, spec in enumerate(maps):
        if not isinstance(spec, dict):
            errors.append(f'Johto local {i} has no valid identity contract')
            continue
        if spec.get('local_id') != i or i >= len(local_symbols) or spec.get('local_symbol') != local_symbols[i][0]:
            errors.append(f'Johto local {i} ID/symbol mismatch in identity contract')
        flags = spec.get('feature_status')
        if (not isinstance(flags, dict) or set(flags) != set(FEATURES)
                or any(status not in FEATURE_STATES for status in flags.values())):
            errors.append(f'Johto local {i} has incomplete/invalid feature review statuses')
        if spec.get('identity_evidence') not in EVIDENCE:
            errors.append(f'Johto local {i} missing identity review evidence')
        for name, rows in observed.items():
            if i >= len(rows):
                continue  # A separate count check reports truncated tables.
            actual = rows[i]
            if name == 'rby_music':
                actual = [v.strip() for v in actual.split(',')]
            elif name == 'town_map_index':
                try:
                    actual = int(actual, 0)
                except ValueError:
                    errors.append(f'Johto local {i} has invalid Town Map index: {actual}')
                    continue
            elif name == 'town_map_xy':
                actual = [int(v) for v in actual]
            if actual != spec.get(name):
                errors.append(f'Johto local {i} {name} identity mismatch: '
                              f'expected {spec.get(name)!r}, found {actual!r}')
    return errors


def audit(root=ROOT):
    sources = {name: (root / name).read_text(encoding='utf-8') for name in INPUTS}
    errors = []
    const = sources['constants/map_constants.asm']
    keys = sources['constants/region_map_constants.asm']
    table = sources['data/johto_map_headers.asm']
    resolver = sources['engine/overworld/region_map_lookup.asm']
    home = sources['home/overworld.asm']

    if not re.search(r'mapconst\s+REGION_NATIVE_MAP_SLOT,\s*0,\s*0\s*;\s*\$FC', const, re.I):
        errors.append('missing $FC virtual legacy map handle')
    if 'DEF REGION_WARP_ESCAPE EQU $fe' not in keys or 'ASSERT REGION_NATIVE_MAP_SLOT == $fc' not in keys:
        errors.append('virtual and warp escape map IDs are not distinct/reserved')
    if 'DEF NUM_LEGACY_MAPS EQU const_value' not in const:
        errors.append('legacy table bound missing')
    if not re.search(r'\bmapconst\s+JOHTO_ROUTE_32,\s*45,\s*10\s*;\s*\$FB', const):
        errors.append('existing Route32 legacy alias has moved')
    local_defs = keys + '\n' + sources['constants/johto_fixed_map_ids.asm']
    locals_ = re.findall(r'^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\d+)(?:\s*;[^\n]*)?$', local_defs, re.M)
    n = re.search(r'\bDEF NUM_JOHTO_MAPS EQU (\d+)', keys)
    if not n:
        return errors + ['missing Johto local ID count']
    count = int(n.group(1))
    indices = [int(x) for _, x in locals_]
    manifest = json.loads(sources['tools/johto_native_maps.json'])
    by_name = {name: int(id_) for name, id_ in locals_}
    active_locals = [(item.get('local_symbol'), str(item.get('local_id')))
                     for item in manifest.get('maps', []) if isinstance(item, dict)]
    if (len(active_locals) != count
            or len({int(i) for _, i in active_locals}) != count
            or any(by_name.get(name) != int(i) for name, i in active_locals)
            or [int(i) for _, i in active_locals[:23]] != list(range(23))):
        errors.append('Johto active slot registry has duplicate, missing, or moved stable IDs')

    johto_sets = {
        'header pointers': ('JohtoMapHeaderPointers::', 'JohtoMapHeaderPointersEnd::', r'dw'),
        'header banks': ('JohtoMapHeaderBanks::', 'JohtoMapHeaderBanksEnd::', r'db'),
        'legacy aliases': ('JohtoMapLegacyAliases::', 'JohtoMapLegacyAliasesEnd::', r'db'),
        'RBY map songs': ('JohtoNativeMapSongBanks::', 'JohtoNativeMapSongBanksEnd::', r'db'),
    }
    records = {}
    for name, (begin, end, prefix) in johto_sets.items():
        values = entries(table, begin, end, prefix)
        records[name] = values
        if len(values) != count:
            errors.append(f'Johto {name} table count {len(values)} != {count}')
    aliases = records['legacy aliases']
    for index, value in enumerate(aliases):
        name = value.strip().split()[0]
        if index >= 8 and name != 'REGION_NATIVE_MAP_SLOT':
            errors.append(f'Johto local {index} must use the shared virtual handle, not a new alias')
        if index < 8 and name == 'REGION_NATIVE_MAP_SLOT':
            errors.append(f'legacy Johto local {index} alias was removed')
    gsc = entries(sources['engine/menu/options_menu.asm'], 'JohtoNativeGSCMusic::',
                  'JohtoNativeGSCMusicEnd::', r'db')
    if len(gsc) != count:
        errors.append(f'native GSC music table count {len(gsc)} != {count}')
    indices_table = entries(sources['engine/overworld/johto_town_map_helpers.asm'], 'JohtoNativeTownMapIndices::',
                            'JohtoNativeTownMapIndicesEnd::', r'db')
    # One db row may hold several comma-separated indices.
    nindices = sum(len(row.split(',')) for row in indices_table)
    if nindices != count:
        errors.append(f'native Town Map index count {nindices} != {count}')
    map_entries = entries(sources['engine/town_map.asm'], 'JohtoNativeTownMapEntries::',
                          'JohtoNativeTownMapEntriesEnd::', r'dw')
    if len(map_entries) != count:
        errors.append(f'native Town Map name count {len(map_entries)} != {count}')
    errors.extend(check_native_identity(sources, active_locals, count, records, gsc))

    for rel, start, end, kind in [
        ('data/map_header_pointers.asm', 'MapHeaderPointers::', 'MapHeaderPointersEnd:', 'dw'),
        ('data/map_header_banks.asm', 'MapHeaderBanks:', 'MapHeaderBanksEnd:', 'db'),
        ('data/map_songs.asm', 'MapSongBanks:', 'MapSongBanksEnd:', 'db'),
        ('data/hide_show_data.asm', 'MapHSPointers:', 'MapHSPointersEnd:', 'dw'),
    ]:
        source = sources[rel]
        if end not in source:  # Header arrays have no explicit end marker historically.
            rows = re.findall(rf'^\s*{kind}\s+', source, re.M)
            if not rows:
                errors.append(f'{rel} missing map array')
            else:
                last = re.findall(rf'^\s*{kind}\s+([^;\n]+)', source, re.M)[-1]
                if rel == 'data/map_header_pointers.asm' and 'JohtoRoute32_h' not in last:
                    errors.append('native fallback header is missing')
                if rel == 'data/map_header_banks.asm' and 'BANK(JohtoRoute32_h)' not in last:
                    errors.append('native fallback header bank is missing')
        else:
            values = entries(source, start, end, kind)
            # For map songs, only consider pairs in the native table, not total bytes.
            if len(values) != 253:
                errors.append(f'{rel} legacy+sentinel table count {len(values)} != 253')
    if 'cp REGION_NATIVE_MAP_SLOT\n\tjr z, .invalid' not in resolver:
        errors.append('Kanto resolver allows the shared native handle as Kanto')
    if 'cp REGION_NATIVE_MAP_SLOT' not in resolver.split('SyncLegacyMapRegions::',1)[1].split('.badNative',1)[0]:
        errors.append('save migration loses native physical map key')
    if 'wCurLocalMapID' not in sources['wram.asm'] or 'wLastLocalMapID' not in sources['wram.asm']:
        errors.append('persistent current/last native local ID missing')
    for requirement in ('callab SelectNativeMapConnection', 'callab GetJohtoNativeMapSong',
                        'callab ResolveRegionMapHeader'):
        if requirement not in home:
            errors.append(f'overworld missing {requirement}')
    if home.count('callab SelectNativeMapConnection') != 4:
        errors.append('not all four map connection directions convert native map keys')
    if 'ld a,[wLastLocalMapID]' not in home or 'ld [wLastLocalMapID],a' not in home:
        errors.append('LAST_MAP does not restore native source map')
    if 'jp z, JohtoNativeCollisionFence' not in sources['main.asm']:
        errors.append('native maps have no safe collision fence')
    if 'cp REGION_NATIVE_MAP_SLOT\n\tjr z, .native' not in sources['engine/town_map.asm']:
        errors.append('native map name lookup falls into legacy pointer table')
    if 'wMapNameSignLastNativeLocalID' not in sources['engine/overworld/map_name_sign.asm']:
        errors.append('native maps share a stale map-name identity')
    if 'JohtoNativeGSCMusic' not in sources['engine/menu/options_menu.asm']:
        errors.append('GSC native local music not mapped')
    return errors


if __name__ == '__main__':
    problems = audit()
    if problems:
        for problem in problems:
            print('ERROR:', problem)
        raise SystemExit(1)
    print('PASS: legacy handles and native Johto region/local tables are internally consistent')
