#!/usr/bin/env python3
"""Offline safety gate for one-slot, region/local Johto map expansion.

This is not an RGBDS compile or a substitute for an in-game connection test.
A new Johto local map must be added to all key tables before being exposed.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
INPUTS = (
    'constants/map_constants.asm', 'constants/region_map_constants.asm',
    'data/map_header_pointers.asm', 'data/map_header_banks.asm',
    'data/map_songs.asm', 'data/hide_show_data.asm',
    'data/johto_map_headers.asm', 'engine/overworld/region_map_lookup.asm',
    'home/overworld.asm', 'engine/town_map.asm', 'engine/menu/options_menu.asm',
    'engine/overworld/map_name_sign.asm', 'wram.asm', 'main.asm',
)


def entries(text, start, end, prefix):
    block = text.split(start, 1)[1].split(end, 1)[0]
    return re.findall(rf'^\s*{prefix}\s+([^;\n]+)', block, re.M)


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
    locals_ = re.findall(r'^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\d+)\s*$', keys, re.M)
    n = re.search(r'\bDEF NUM_JOHTO_MAPS EQU (\d+)', keys)
    if not n:
        return errors + ['missing Johto local ID count']
    count = int(n.group(1))
    indices = [int(x) for _, x in locals_]
    if indices != list(range(count)):
        errors.append('Johto local map IDs are not contiguous and unique')

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
    indices_table = entries(sources['engine/town_map.asm'], 'JohtoNativeTownMapIndices::',
                            'JohtoNativeTownMapIndicesEnd::', r'db')
    # One db row may hold several comma-separated indices.
    nindices = sum(len(row.split(',')) for row in indices_table)
    if nindices != count:
        errors.append(f'native Town Map index count {nindices} != {count}')
    map_entries = entries(sources['engine/town_map.asm'], 'JohtoNativeTownMapEntries::',
                          'JohtoNativeTownMapEntriesEnd::', r'dw')
    if len(map_entries) != count:
        errors.append(f'native Town Map name count {len(map_entries)} != {count}')

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
