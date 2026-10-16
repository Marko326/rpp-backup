#!/usr/bin/env python3
"""Read-only Gold entrance reference audit.

Enumerate every Gold map warp and source map/collision family. These checks
validate source identity, coordinate bounds and target index integrity.
They deliberately do NOT assert runtime approach direction or player animation.
Those need RPP control-flow, scenario and phone/mGBA acceptance separately.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import argparse
import json
import re

# Categories are separate semantics; never collapse these into one step-on warp.
REQUIRED_COLLISIONS = {
    'door': ('COLL_DOOR', 'COLL_DOOR_79', 'COLL_DOOR_75', 'COLL_DOOR_7D'),
    'cave': ('COLL_CAVE', 'COLL_CAVE_74'),
    'stairs_ladder': ('COLL_STAIRCASE', 'COLL_STAIRCASE_73', 'COLL_LADDER'),
    'directional_carpet': ('COLL_WARP_CARPET_DOWN', 'COLL_WARP_CARPET_UP',
                           'COLL_WARP_CARPET_LEFT', 'COLL_WARP_CARPET_RIGHT'),
    'panel': ('COLL_WARP_PANEL',),
    'pit': ('COLL_PIT', 'COLL_PIT_68'),
}
REQUIRED_ENGINE_MARKERS = {
    'engine/overworld/tile_events.asm':
        ('CheckWarpCollision::', 'CheckDirectionalWarp::', 'CheckWarpFacingDown:', 'GetWarpSFX::'),
    'engine/overworld/player_movement.asm':
        ('DoPlayerMovement::', '.CheckWarp:', '.EdgeWarps:', 'call WarpCheck'),
    'home/map.asm':
        ('CheckWarpTile::', 'WarpCheck::', 'GetDestinationWarpNumber::',
         'GetWarpDestCoords::'),
    'engine/overworld/events.asm':
        ('CheckTileEvent:', 'call CheckWarpTile', 'WarpToNewMapScript:',
         'EdgeWarpScript:'),
    'engine/overworld/scripting.asm':
        ('Script_warp:', 'Script_warpmod:', 'Script_warpcheck:', 'Script_elevator:'),
}
# Representative references are checked exactly, but not the only maps inventoried.
REFERENCE_MAPS = ('Route31VioletGate', 'Route32', 'UnionCave1F',
                  'GoldenrodDeptStoreElevator', 'CeladonDeptStoreElevator',
                  'EcruteakGym', 'FastShip1F', 'RuinsOfAlphOutside',
                  'Route36NationalParkGate')


def _read(path: Path) -> str:
    return path.read_text(encoding='utf-8')


def inspect(gold: Path, *, include_events: bool = False) -> dict:
    errors: list[str] = []
    stats: dict = {}
    event_rows = []
    gold = gold.resolve()
    try:
        attrs = _read(gold / 'data/maps/attributes.asm')
        consts = _read(gold / 'constants/map_constants.asm')
        collision = _read(gold / 'constants/collision_constants.asm')
        mapdefs = _read(gold / 'data/maps/maps.asm')
        maps_dir = gold / 'maps'
        paths = sorted(maps_dir.glob('*.asm'))
    except OSError as exc:
        return {'errors': [f'Gold inventory cannot load: {exc}'], 'stats': {}, 'events': []}

    names = dict(re.findall(r'^\s*map_attributes\s+(\w+)\s*,\s*(\w+)\s*,', attrs, re.M))
    dimensions = {name: (int(w), int(h)) for name, w, h in re.findall(
        r'^\s*map_const\s+(\w+)\s*,\s*(\d+)\s*,\s*(\d+)', consts, re.M)}
    environments = {}
    for name, environment in re.findall(r'^\s*map\s+(\w+)\s*,\s*\w+\s*,\s*(\w+)\s*,', mapdefs, re.M):
        environments[name] = environment
    by_const = {const: name for name, const in names.items()}
    count_by_map = {}
    text_by_map = {}
    for path in paths:
        try:
            text = _read(path)
        except OSError as exc:
            errors.append(str(exc))
            continue
        text_by_map[path.stem] = text
        count_by_map[path.stem] = len(re.findall(r'^\s*warp_event\b', text, re.M))
    if set(names) != set(text_by_map):
        errors.append(f'Gold map registry/scripts disagreement: missing scripts '
                      f'{sorted(set(names)-set(text_by_map))}; extra scripts '
                      f'{sorted(set(text_by_map)-set(names))}')
    if set(names.values()) != set(dimensions):
        errors.append('Gold map dimensions and map attributes disagree')
    if set(names) != set(environments):
        errors.append('Gold map environments and attributes disagree')

    found_collision = dict(re.findall(r'^\s*DEF\s+(COLL_\w+)\s+EQU\s+\$([0-9a-fA-F]{2})', collision, re.M))
    for family, symbols in REQUIRED_COLLISIONS.items():
        for symbol in symbols:
            if symbol not in found_collision:
                errors.append(f'Gold missing collision symbol {symbol} ({family})')
    for relative, markers in REQUIRED_ENGINE_MARKERS.items():
        try:
            src = _read(gold / relative)
        except OSError as exc:
            errors.append(str(exc))
            continue
        for marker in markers:
            if marker not in src:
                errors.append(f'Gold engine reference missing {relative}: {marker}')

    pattern = re.compile(r'^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*(\w+)\s*,\s*(-?\d+)\s*(?:;.*)?$')
    events_total = 0
    special_targets = 0
    for name, text in text_by_map.items():
        for line_number, line in enumerate(text.splitlines(), 1):
            if not re.match(r'^\s*warp_event\b', line):
                continue
            events_total += 1
            match = pattern.match(line)
            if match is None:
                errors.append(f'Gold unparsed Warp syntax: maps/{name}.asm:{line_number}')
                continue
            x_str, y_str, dest, dest_id_str = match.groups()
            x, y, dest_id = int(x_str), int(y_str), int(dest_id_str)
            const = names.get(name)
            width_height = dimensions.get(const)
            if width_height:
                width, height = width_height
                if x >= width * 2 or y >= height * 2:
                    errors.append(f'Gold source Warp out of map bounds: {name}:{line_number} ({x},{y})')
            destination = by_const.get(dest)
            if not destination:
                errors.append(f'Gold Warp destination absent: {name}:{line_number}: {dest}')
            elif dest_id != -1 and not (1 <= dest_id <= count_by_map.get(destination, 0)):
                errors.append(f'Gold Warp destination index invalid: {name}:{line_number}: '
                              f'{dest}[{dest_id}] (has {count_by_map.get(destination, 0)})')
            if dest_id == -1:
                special_targets += 1
            if include_events:
                event_rows.append({'map': name, 'environment': environments.get(name, ''),
                                   'line': line_number, 'x': x, 'y': y,
                                   'target_constant': dest, 'target_map': destination,
                                   'target_warp': dest_id})
    for ref in REFERENCE_MAPS:
        if ref not in text_by_map:
            errors.append('Gold representative entrance map missing: ' + ref)
    scripted = Counter()
    for name, src in text_by_map.items():
        for kind in ('warp', 'warpmod', 'warpcheck', 'warpfacing', 'elevator'):
            scripted[kind] += len(re.findall(r'(?m)^\s*' + kind + r'(?:\s|$)', src))
    stats.update({'registered_maps': len(names), 'map_script_files': len(text_by_map),
                  'maps_with_warps': sum(x > 0 for x in count_by_map.values()),
                  'warp_events': events_total,
                  'scripted_transfer_commands': dict(scripted),
                  'special_target_minus_one': special_targets,
                  'by_environment': dict(sorted(Counter(environments.values()).items())),
                  'collision_families': {family: list(symbols) for family, symbols in REQUIRED_COLLISIONS.items()},
                  'representative_maps': list(REFERENCE_MAPS)})
    return {'errors': errors, 'stats': stats, 'events': event_rows}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gold', required=True, type=Path)
    parser.add_argument('--events-json', type=Path, help='optional full audit inventory output')
    args = parser.parse_args()
    result = inspect(args.gold, include_events=bool(args.events_json))
    if args.events_json:
        args.events_json.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n',
                                    encoding='utf-8')
    print(json.dumps({'status': 'FAIL' if result['errors'] else 'PASS',
                      'errors': result['errors'], 'stats': result['stats']},
                     ensure_ascii=False, indent=2))
    return 1 if result['errors'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
