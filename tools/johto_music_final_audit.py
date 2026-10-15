#!/usr/bin/env python3
"""Read-only Johto music registry / playback-priority audit (MUS phase 3).

Covers the currently registered maps, music lookups, the border gate and
existing style/special-state priorities.  It is NOT ROM build/audio QA.

Usage: python -B tools/johto_music_final_audit.py --rpp /path/to/rpp
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

# Reviewed Johto music scenes.  These are *independent expected values*,
# not a copy of JohtoSceneGSCMap; a valid-but-wrong track is a regression.
# RBY for the gate is the Violet-side default; entry from Route 31 overrides it.
EXPECTED_SCENES = {
    'NEW_BARK_TOWN': ('MUSIC_PALLET_TOWN', 'MUSIC_GBP_GSC_NEW_BARK_TOWN'),
    'JOHTO_ROUTE_29': ('MUSIC_ROUTES1', 'MUSIC_GBP_GSC_ROUTE29'),
    'JOHTO_CHERRYGROVE_CITY': ('MUSIC_CITIES1', 'MUSIC_GBP_GSC_CHERRYGROVE_CITY'),
    'JOHTO_ROUTE_30': ('MUSIC_ROUTES3', 'MUSIC_GBP_GSC_ROUTE30'),
    'JOHTO_ROUTE_31': ('MUSIC_ROUTES3', 'MUSIC_GBP_GSC_ROUTE30'),
    'JOHTO_VIOLET_CITY': ('MUSIC_CITIES1', 'MUSIC_GBP_GSC_VIOLET_CITY'),
    'JOHTO_ROUTE31_VIOLET_GATE': ('MUSIC_CITIES1', None),
}

# Important GB Player IDs must point at the intended music *identity*,
# not merely any non-null Music_* pointer.  This doesn't replace ROM audio QA.
EXPECTED_GSC_POINTERS = {
    'MUSIC_GBP_GSC_NEW_BARK_TOWN': 'Music_NewBarkTown',
    'MUSIC_GBP_GSC_ROUTE29': 'Music_Route29',
    'MUSIC_GBP_GSC_CHERRYGROVE_CITY': 'Music_CherrygroveCity',
    'MUSIC_GBP_GSC_ROUTE30': 'Music_Route30',
    'MUSIC_GBP_GSC_VIOLET_CITY': 'Music_VioletCity',
}


def asm_tokens(body: str) -> list[str]:
    """Strip comments/whitespace, preserve instructions and label order."""
    return [re.sub(r'\s+', '', line.split(';', 1)[0]).lower()
            for line in body.splitlines() if line.split(';', 1)[0].strip()]


def has_sequence(haystack: list[str], expected: list[str]) -> bool:
    return any(haystack[i:i + len(expected)] == expected
               for i in range(len(haystack) - len(expected) + 1))


FILES = (
    'constants/map_constants.asm',
    'data/johto_map_headers.asm',
    'data/map_songs.asm',
    'constants/music_constants.asm',
    'crysaudio/gb_player_pointers.asm',
    'constants/region_map_constants.asm',
    'engine/menu/options_menu.asm',
    'home/overworld.asm',
    'home/audio.asm',
    'wram.asm',
)


def section(src: str, start: str, end: str) -> str:
    return src.split(start, 1)[1].split(end, 1)[0]


def symbols(src: str, op: str) -> list[str]:
    return re.findall(r'(?m)^\s*' + re.escape(op) + r'\s+([A-Za-z_][A-Za-z_0-9]*)', src)


def audit(root: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Return errors and a human-readable per-map music inventory; never write."""
    root = Path(root)
    errors: list[str] = []
    src: dict[str, str] = {}
    for rel in FILES:
        p = root / rel
        if not p.is_file() or p.is_symlink():
            errors.append(f'missing/unsafe source: {rel}')
            continue
        try:
            src[rel] = p.read_text(encoding='utf-8')
        except (OSError, UnicodeError) as exc:
            errors.append(f'unreadable {rel}: {exc}')
    if errors:
        return errors, []

    maps = symbols(src['constants/map_constants.asm'], 'mapconst')
    songs_src = src['data/map_songs.asm']
    songs = re.findall(r'(?m)^\s*db\s+(MUSIC_[A-Z0-9_]+)\s*,\s*(\d+)\s*(?:;[^\n]*)?$',
                       section(songs_src, 'MapSongBanks:', 'MapSongBanksEnd:'))
    if len(maps) != len(songs):
        errors.append(f'map/song table length mismatch: {len(maps)} maps vs {len(songs)} songs')
    if len(maps) >= 0xfe:
        errors.append('legacy map IDs would collide with region warp escape $FE')
    if 'ASSERT (MapSongBanksEnd - MapSongBanks) == NUM_LEGACY_MAPS * 2' not in songs_src:
        errors.append('map song build-time length ASSERT missing')

    johto_src = src['data/johto_map_headers.asm']
    try:
        aliases = re.findall(r'(?m)^\s*db\s+([A-Z][A-Z0-9_]*)\s*(?:;[^\n]*)?$',
                             section(johto_src, 'JohtoMapLegacyAliases::', 'JohtoMapLegacyAliasesEnd::'))
        headers = symbols(section(johto_src, 'JohtoMapHeaderPointers::',
                                  'JohtoMapHeaderPointersEnd::'), 'dw')
    except IndexError:
        return errors + ['Johto header/alias registry missing'], []
    if not aliases or len(aliases) != len(set(aliases)):
        errors.append('Johto aliases missing or duplicate')
    if len(aliases) != len(headers):
        errors.append('Johto aliases and header pointer counts differ')

    styles = src['engine/menu/options_menu.asm']
    try:
        scene_src = section(styles, 'JohtoSceneGSCMap:', '\tdb $ff')
        pairs = re.findall(r'(?m)^\s*db\s+([A-Z][A-Z0-9_]+)\s*,\s*(MUSIC_GBP_GSC_[A-Z0-9_]+)',
                           scene_src)
        scene_map = dict(pairs)
        if len(scene_map) != len(pairs):
            errors.append('duplicate Johto GSC scene mapping')
    except IndexError:
        return errors + ['JohtoSceneGSCMap missing/unterminated'], []
    gate = 'JOHTO_ROUTE31_VIOLET_GATE'
    unexpected = sorted(set(scene_map) - (set(aliases) - {gate}))
    if unexpected:
        errors.append('scene mapping references unregistered/non-physical Johto maps: ' + ', '.join(unexpected))
    missing = sorted((set(aliases) - {gate}) - set(scene_map))
    if missing:
        errors.append('registered Johto scene missing GSC counterpart: ' + ', '.join(missing))
    if gate not in aliases:
        errors.append('Route31/Violet gate is not in Johto legacy aliases')

    music_consts = [name for name in symbols(src['constants/music_constants.asm'], 'const')
                    if name.startswith('MUSIC_')]
    pointers = symbols(src['crysaudio/gb_player_pointers.asm'], 'tbp')
    try:
        first_gbp = music_consts.index('MUSIC_GBP_GSC_ROUTE36')
    except ValueError:
        errors.append('GB Player music ID boundary missing')
        first_gbp = len(music_consts)
    if len(music_consts) - first_gbp != len(pointers):
        errors.append(f'GBP song IDs/pointers differ: {len(music_consts)-first_gbp} vs {len(pointers)}')
    if first_gbp != 48:
        errors.append('expected original 48 RBY song IDs before GBP expansion')
    for m, (_, expected_gsc) in EXPECTED_SCENES.items():
        if expected_gsc and m in scene_map and scene_map[m] != expected_gsc:
            errors.append(f'{m}: GSC scene mismatch; expected {expected_gsc}, got {scene_map[m]}')

    for track, expected_pointer in EXPECTED_GSC_POINTERS.items():
        if track not in music_consts:
            errors.append(f'{track}: expected GSC music ID missing')
            continue
        idx = music_consts.index(track) - first_gbp
        if not 0 <= idx < len(pointers):
            errors.append(f'{track}: GSC pointer index outside table')
        elif pointers[idx] != expected_pointer:
            errors.append(f'{track}: GSC pointer identity mismatch; expected {expected_pointer}, got {pointers[idx]}')

    for m, track in pairs:
        if track not in music_consts:
            errors.append(f'{m}: music constant {track} missing')
            continue
        i = music_consts.index(track) - first_gbp
        if not (0 <= i < len(pointers)) or not pointers[i].startswith('Music_'):
            errors.append(f'{m}: GSC music {track} has no GBP audio pointer')

    result: list[dict[str, str]] = []
    for alias in aliases:
        if alias not in maps:
            errors.append(f'Johto alias missing mapconst: {alias}')
            continue
        idx = maps.index(alias)
        if idx >= len(songs):
            errors.append(f'{alias} (${idx:02X}) lacks a music entry')
            continue
        rby, bank = songs[idx]
        expected = EXPECTED_SCENES.get(alias)
        if expected and rby != expected[0]:
            errors.append(f'{alias}: RBY scene mismatch; expected {expected[0]}, got {rby}')
        if rby not in music_consts[:first_gbp] or bank != '0':
            errors.append(f'{alias}: base table must contain a valid RBY song and zero bank')
        if alias == gate:
            gsc = 'INHERIT_FROM_WARP_SOURCE'
        else:
            gsc = scene_map.get(alias, 'MISSING')
        result.append({'map': alias, 'legacy_id': f'${idx:02X}', 'rby': rby, 'gsc': gsc})

    overworld = src['home/overworld.asm']
    try:
        source_helper = section(overworld, 'GetJohtoGateMusicSourceMap::', 'ExtraWarpCheck::')
        get_gate = section(styles, 'LookupJohtoMapGSCMusic:', 'CheckJohtoMusicSceneTransition::')
        loader = section(overworld, 'LoadMapHeader::', 'CopyMapConnectionHeader::')
        scene_cache = section(styles, 'CheckJohtoMusicSceneTransition::', 'JohtoSceneGSCMap:')
        resolver = section(styles, 'ResolveMusicStyle::', 'LookupMusicStyleMap:')
    except IndexError:
        return errors + ['missing gate/music resolver/cache/loader functions'], result
    # Limit the RBY check to the gate-song decision rather than the much larger
    # loader (which may legitimately use wLastMap for non-music map logic).
    rby_gate = loader.split('cp JOHTO_ROUTE31_VIOLET_GATE', 1)[-1].split('.storeMapSong', 1)[0]
    for name, body in [('gate source', source_helper), ('GSC gate lookup', get_gate), ('RBY gate lookup', rby_gate)]:
        if 'wLastMap' in body:
            errors.append(f'{name}: stale wLastMap dependency')
    if 'wWarpedFromWhichMap' not in source_helper:
        errors.append('gate music source no longer uses actual Warp source')
    if 'call GetJohtoGateMusicSourceMap' not in get_gate or 'call GetJohtoGateMusicSourceMap' not in loader:
        errors.append('RBY/GSC gate music source is not shared')
    if 'cp NUM_LEGACY_MAPS' not in loader:
        errors.append('LoadMapHeader lacks music table bounds check')
    if not (loader.find('ld [wMapMusicSoundID],a') < loader.find('callba CheckJohtoMusicSceneTransition')):
        errors.append('scene-cache transition must follow map-song loading')
    if 'callba CheckJohtoMusicSceneTransition' not in loader:
        errors.append('map loader does not refresh scene cache')
    if 'call Random' in scene_cache or 'wWalkBikeSurfState' not in scene_cache:
        errors.append('scene transition must not reroll random or interrupt bike/surf')
    if not all(x in scene_cache for x in ('wLastMusicSoundID', 'wJohtoMusicSceneMagic',
                                           'wLastJohtoMusicSceneID', 'MUSIC_STYLE_GSC', 'MUSIC_STYLE_RND')):
        errors.append('scene cache does not cover GSC/RND raw-ID continuity')
    # Validate the actual guarded *write*, not mere occurrences of symbols.
    # The cache invalidation belongs on the walking path after the style test.
    guarded_cache = ['.checkwalking', 'lda,[wwalkbikesurfstate]', 'anda',
                     'retnz', 'xora', 'ld[wlastmusicsoundid],a', 'ret']
    if not has_sequence(asm_tokens(scene_cache), guarded_cache):
        errors.append('scene cache invalidation sequence no longer clears the music ID under the walking guard')
    for token in ('wCurRegion', 'MAP_REGION_JOHTO', 'wMapMusicSoundID',
                  'wWalkBikeSurfState', 'LookupJohtoMapGSCMusic', 'MUSIC_STYLE_RND',
                  'MUSIC_STYLE_GSC_CUSTOM_BIT', 'MUSIC_STYLE_RBY_CUSTOM_BIT'):
        if token not in resolver:
            errors.append(f'music style resolver lost guard: {token}')
    audio = src['home/audio.asm']
    if 'MUSIC_BIKE_RIDING' not in audio or 'MUSIC_SURFING' not in audio:
        errors.append('default music no longer has bike/surf special-state selection')
    # Preserve special-state priority and branch polarity.  These exact
    # instructions are reviewed invariants, not a generic emulator of LR35902.
    try:
        default_audio = section(audio, 'PlayDefaultMusicCommon::', '\n.next\n')
    except IndexError:
        default_audio = ''
    bike_surf = ['lda,[wwalkbikesurfstate]', 'anda', 'jrz,.walking',
                 'cp$2', 'jrz,.surfing', 'lda,music_bike_riding',
                 'jr.next', '.surfing', 'lda,music_surfing']
    if not has_sequence(asm_tokens(default_audio), bike_surf):
        errors.append('bike/surf branch semantics changed: check walking, $2 surfing and bicycle priority')
    ram = src['wram.asm']
    if not re.search(r'wLastJohtoMusicSceneID:: ds 1\s*wJohtoMusicSceneMagic:: ds 1\s*ds 16', ram):
        errors.append('Johto music cache no longer fits its original reserved WRAM space')
    return errors, result


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp', type=Path, default=Path('.'))
    args = parser.parse_args(argv)
    errors, rows = audit(args.rpp)
    for entry in rows:
        print(f"{entry['legacy_id']} {entry['map']}: {entry['rby']} -> {entry['gsc']}")
    if errors:
        for e in errors:
            print('FAIL:', e)
        return 1
    print(f'PASS: {len(rows)} Johto maps registered; static music rules consistent. NOT runtime audio QA.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
