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

GATE_CARPETS = frozenset({
    'WARP_CARPET_DOWN', 'WARP_CARPET_LEFT',
    'WARP_CARPET_UP', 'WARP_CARPET_RIGHT',
})
GATE_SOLID_DOORS = frozenset({'DOOR', 'DOOR_79', 'DOOR_75', 'DOOR_7D'})
GOLD_AUTO_DOWN_ROLES = frozenset({'DOOR', 'DOOR_79', 'STAIRCASE', 'CAVE'})


def gold_gate_approach_rule(role: str, runtime_mode: str) -> tuple[str, str] | None:
    """Canonical approach rule derived from Gold collision semantics."""
    if role in GATE_CARPETS:
        trigger = 'LEGACY_COLLISION' if runtime_mode == 'LEGACY_COLLISION' else 'COLLISION_ONLY'
        return trigger, role.removeprefix('WARP_CARPET_')
    if role in GATE_SOLID_DOORS:
        return 'STEP_ON', 'UP'
    return None


def gold_gate_arrival_step(role: str) -> str | None:
    """Gold's forced-down movement is caused by the destination collision."""
    if role in GOLD_AUTO_DOWN_ROLES:
        return 'D_DOWN'
    if role in GATE_CARPETS:
        return 'NONE'
    return None


def _read(path: Path) -> str:
    return path.read_text(encoding='utf-8')


class GoldCollisionIndex:
    """Decode Gold map-cell collision from the actual .blk and tilecoll data.

    Warp coordinates are 8x8-cell coordinates; .blk entries are 16x16 block
    coordinates, so decode_cells expands each block into four independently
    classified collision cells. Shared Gold block files are resolved through
    data/maps/blocks.asm instead of guessing maps/<map name>.blk.
    """

    def __init__(self, gold: Path):
        self.gold = Path(gold).resolve()
        attrs = _read(self.gold / 'data/maps/attributes.asm')
        consts = _read(self.gold / 'constants/map_constants.asm')
        mapdefs = _read(self.gold / 'data/maps/maps.asm')
        blocks = _read(self.gold / 'data/maps/blocks.asm')
        self.map_const = dict(re.findall(
            r'^\s*map_attributes\s+(\w+)\s*,\s*(\w+)\s*,', attrs, re.M))
        self.dimensions = {name: (int(width), int(height)) for name, width, height in
                           re.findall(r'^\s*map_const\s+(\w+)\s*,\s*(\d+)\s*,\s*(\d+)',
                                      consts, re.M)}
        self.tilesets = {name: tileset for name, tileset, _ in re.findall(
            r'^\s*map\s+(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,', mapdefs, re.M)}
        self.block_files: dict[str, str] = {}
        pending: list[str] = []
        for line in blocks.splitlines():
            label = re.match(r'^([A-Za-z0-9_]+)_Blocks:', line)
            if label:
                pending.append(label.group(1))
            incbin = re.search(r'INCBIN\s+"maps/([^\"]+\.blk)"', line)
            if incbin and pending:
                for name in pending:
                    self.block_files[name] = incbin.group(1)
                pending = []
        self._cells: dict[str, dict[tuple[int, int], dict]] = {}

    def cells(self, map_name: str) -> dict[tuple[int, int], dict]:
        if map_name in self._cells:
            return self._cells[map_name]
        if (map_name not in self.map_const or
                self.map_const.get(map_name) not in self.dimensions):
            raise ValueError(f'Gold map dimensions/attributes missing: {map_name}')
        if map_name not in self.tilesets or map_name not in self.block_files:
            raise ValueError(f'Gold map tileset/block source missing: {map_name}')
        width, height = self.dimensions[self.map_const[map_name]]
        tileset = self.tilesets[map_name].removeprefix('TILESET_').lower()
        layout = (self.gold / 'maps' / self.block_files[map_name]).read_bytes()
        collision = _read(self.gold / f'data/tilesets/{tileset}_collision.asm')
        rows = [tuple(part.strip() for part in row.split(','))
                for row in re.findall(r'\btilecoll\s+([^;\n]+)', collision)]
        if (len(layout) != width * height or not rows or
                any(len(row) != 4 or not all(row) for row in rows) or
                any(block >= len(rows) for block in layout)):
            raise ValueError(f'invalid Gold layout/tilecoll table for {map_name}')
        # Warp/collision coordinates are twice the .blk dimensions. Expand the
        # actual 16x16 block's four 8x8 collision quadrants, without assuming
        # every tileset has a 64/128-entry graphics/metatile table.
        result = {}
        for y in range(height * 2):
            for x in range(width * 2):
                block = layout[(y // 2) * width + x // 2]
                quadrant = (y % 2) * 2 + (x % 2)
                result[(x, y)] = {'x': x, 'y': y, 'block_id': block,
                                  'role': rows[block][quadrant]}
        self._cells[map_name] = result
        return result

    def role_at(self, map_name: str, x: int, y: int) -> str:
        cell = self.cells(map_name).get((int(x), int(y)))
        if cell is None:
            raise ValueError(f'Gold collision coordinate outside map: {map_name} ({x},{y})')
        return cell['role']

    def gate_warp_inventory(self) -> list[dict]:
        """Return all Gold Gate Warp events with independently decoded roles."""
        rows = []
        for path in sorted((self.gold / 'maps').glob('*Gate*.asm')):
            raw = _read(path)
            if 'def_warp_events' not in raw or 'def_coord_events' not in raw:
                continue
            if raw.count('def_warp_events') != 1 or raw.count('def_coord_events') != 1:
                raise ValueError(f'{path.stem}: Gold Warp sections must occur exactly once')
            section = raw.split('def_warp_events', 1)[1].split('def_coord_events', 1)[0]
            warps = [dict(x=int(x), y=int(y), destination=dest, warp_number=int(number))
                     for x, y, dest, number in re.findall(
                         r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z_0-9]*)\s*,\s*(-?\d+)\b',
                         section)]
            for warp in warps:
                warp['collision_role'] = self.role_at(
                    path.stem, warp['x'], warp['y'])
                role = warp['collision_role']
                if role in GATE_SOLID_DOORS:
                    warp['trigger_contract'] = 'STEP_ON'
                elif role in GATE_CARPETS:
                    warp['trigger_contract'] = 'COLLISION_ONLY'
                    warp['collision_direction'] = role.removeprefix('WARP_CARPET_')
                else:
                    warp['trigger_contract'] = 'REVIEW_SPECIAL_COLLISION'
            rows.append({'gold_map': path.stem, 'warps': warps})
        return rows


_GOLD_COLLISION_INDEX_CACHE: dict[str, GoldCollisionIndex] = {}


def gold_collision_index(gold: Path) -> GoldCollisionIndex:
    """Reuse immutable Gold collision tables across repeated audit/test calls."""
    key = str(Path(gold).resolve())
    index = _GOLD_COLLISION_INDEX_CACHE.get(key)
    if index is None:
        index = GoldCollisionIndex(Path(key))
        _GOLD_COLLISION_INDEX_CACHE[key] = index
    return index


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
