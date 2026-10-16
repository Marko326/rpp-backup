#!/usr/bin/env python3
"""Static Gold-grounded Johto landmark and Union Cave bicycle audit.

This validates source tables and a real bike permission path, not ROM behavior.
It deliberately does not certify the rendered map background or phone behavior.
"""
from pathlib import Path
import argparse
import json
import re

ROOT = Path(__file__).resolve().parents[1]

# Gold names are deliberately independent of RPP's current coordinates.
# Coordinates from Gold `landmark x, y, Name` are transformed by Gold's
# `MACRO landmark` (x + 8, y + 16), then swapped to RPP's `db y, x` order.
GOLD_LANDMARKS = {
    'JohtoNewBarkName': 'NewBarkTownName',
    'JohtoRoute29TownMapName': 'Route29Name',
    'JohtoCherrygroveName': 'CherrygroveCityName',
    'JohtoRoute30TownMapName': 'Route30Name',
    'JohtoRoute31TownMapName': 'Route31Name',
    'JohtoVioletName': 'VioletCityName',
    'JohtoAzaleaName': 'AzaleaTownName',
    'JohtoGoldenrodName': 'GoldenrodCityName',
    'JohtoEcruteakName': 'EcruteakCityName',
    'JohtoOlivineName': 'OlivineCityName',
    'JohtoCianwoodName': 'CianwoodCityName',
    'JohtoMahoganyName': 'MahoganyTownName',
    'JohtoBlackthornName': 'BlackthornCityName',
    'JohtoRoute32TownMapName': 'Route32Name',
    'JohtoUnionCaveTownMapName': 'UnionCaveName',
}


def table_rows(source: str, begin: str, end: str) -> list[tuple[str, tuple[int, int]]]:
    part = source.split(begin, 1)[1].split(end, 1)[0]
    return [(name, (int(y), int(x))) for y, x, name in re.findall(
        r'^\s*db\s+(\d+)\s*,\s*(\d+)\s*(?:;[^\n]*)?\n\s*dw\s+(\w+)',
        part, re.M)]


def audit(root: Path, gold: Path) -> list[str]:
    errors = []
    try:
        town = (root / 'engine/town_map.asm').read_text()
        route32 = (root / 'data/town_map_entries.asm').read_text()
        bike = (root / 'data/bike_riding_tilesets.asm').read_text()
        header = (root / 'data/mapHeaders/JohtoUnionCave1F.asm').read_text()
        home = (root / 'home/overworld.asm').read_text()
        identities = json.loads((root / 'tools/johto_native_maps.json').read_text())
        landmarks = (gold / 'data/maps/landmarks.asm').read_text()
        gold_bike = (gold / 'engine/events/overworld.asm').read_text()
        rpp_tilemap = (root / 'gfx/tilemaps/johto_map.kmp').read_bytes()
        gold_tilemap = (gold / 'gfx/pokegear/johto.bin').read_bytes()
    except (OSError, ValueError) as exc:
        return [f'town map/bike source missing or invalid: {exc}']
    # Gold has a trailing $FF terminator; RPP stores exactly 20x18 tile IDs.
    # The top-left (name panel) and lower-right (regional label) are intentional
    # RPP interface customizations. Every other tile position is map geography.
    if len(rpp_tilemap) != 360 or len(gold_tilemap) != 361 or gold_tilemap[-1] != 0xff:
        errors.append('Johto map tilemap geometry must be 20x18; Gold requires FF terminator')
    else:
        for pos, (value, original) in enumerate(zip(rpp_tilemap, gold_tilemap)):
            row, col = divmod(pos, 20)
            ui = (row in (0, 1, 2) and col <= 12) or (row == 16 and 14 <= col <= 18)
            if not ui and value != original:
                errors.append(f'Johto Town Map geographic tile mismatch at (x={col}, y={row}): '
                              f'RPP=${value:02X}, Gold=${original:02X}')
    if not re.search(r'(?m)^MACRO landmark\s*\n;[^\n]*\n\s*db\s+\\1\s*\+\s*8,\s*\\2\s*\+\s*16', landmarks):
        errors.append('Gold landmark macro offset (+8,+16) changed; review parser')
    gold_positions = {}
    for x, y, name in re.findall(
            r'^\s*landmark\s+(-?\d+)\s*,\s*(-?\d+)\s*,\s*(\w+)',
            landmarks, re.M):
        gold_positions[name] = (int(y) + 16, int(x) + 8)
    try:
        rows = table_rows(town, 'JohtoTownMapEntries:', 'JohtoTownMapEntriesEnd:')
        native = table_rows(town, 'JohtoNativeTownMapEntries::',
                            'JohtoNativeTownMapEntriesEnd::')
    except IndexError:
        return errors + ['RPP Town Map landmark tables missing']
    # Compare every original Gold Johto landmark, in the same order,
    # including unreached routes/caves. These are NOT Fly availability flags.
    gold_rows = re.findall(
        r'^\s*landmark\s+(-?\d+)\s*,\s*(-?\d+)\s*,\s*(\w+)',
        landmarks, re.M)[1:46]
    if len(gold_rows) != 45 or len(rows) != 45:
        errors.append('Johto ordinary Town Map landmark set/count mismatch (expected all 45 Gold landmarks)')
    inverse_names = {gold: rpp for rpp, gold in GOLD_LANDMARKS.items()}
    for index, (gx, gy, gold_name) in enumerate(gold_rows):
        expected_name = inverse_names.get(gold_name, 'JohtoBrowse' + gold_name)
        expected_pos = (int(gy) + 16, int(gx) + 8)
        if index >= len(rows):
            break
        actual_name, actual_pos = rows[index]
        if actual_name != expected_name:
            errors.append(f'Gold landmark order/index {index}: expected {expected_name}, found {actual_name}')
        if actual_pos != expected_pos:
            errors.append(f'{actual_name} ordinary Town Map (y,x)={actual_pos}, Gold={expected_pos}')
    for idx, name in [(7, 'JohtoRoute32TownMapName'),
                      (8, 'JohtoUnionCaveTownMapName')]:
        expected = gold_positions.get(GOLD_LANDMARKS[name])
        if idx >= len(native) or native[idx][0] != name or native[idx][1] != expected:
            errors.append(f'native local {idx} Town Map position/name differs from Gold {expected}')
        maps = identities.get('maps', [])
        if idx >= len(maps) or maps[idx].get('town_map_xy') != list(expected or ()):
            errors.append(f'native local {idx} independent map identity coordinate mismatch')
    match = re.search(r'(?m)^\s*IMAP\s+JOHTO_ROUTE_32,\s*(\d+),\s*(\d+),\s*JohtoRoute32TownMapName', route32)
    expected32 = gold_positions.get('Route32Name')
    if not match or (int(match[1]), int(match[2])) != expected32:
        errors.append('Route32 legacy Town Map entry is not at Gold landmark')
    if not re.search(r'(?m)^\s*db\s+JOHTO_UNION_CAVE\s*$', header):
        errors.append('Union Cave header does not select dedicated JOHTO_UNION_CAVE tileset')
    whitelist = bike.split('BikeRidingTilesets::', 1)[-1].split('\n', 2)[1]
    ids = [x.strip() for x in whitelist.split(';', 1)[0].replace('db ', '', 1).split(',')]
    if ids.count('JOHTO_UNION_CAVE') != 1 or not ids or ids[-1] != '$FF':
        errors.append('Union Cave tileset must appear exactly once before bike table terminator')
    if 'JOHTO_GATE' in ids:
        errors.append('Johto gate tileset must not inherit cave bike permission')
    if not re.search(r'IsBikeRidingAllowed::[\s\S]*?ld hl, BikeRidingTilesets\s*\n\.loop[\s\S]*?jr z, \.allowed', home):
        errors.append('RPP bike eligibility no longer checks the bike tileset table')
    if (not re.search(r'\.CheckEnvironment:\s*\n\s*call GetMapEnvironment[\s\S]*?cp CAVE\s*\n\s*jr z, \.ok', gold_bike)
            or not re.search(r'\.ok\s*\n\s*call GetPlayerTilePermission\s*\n\s*and \$f', gold_bike)):
        errors.append('Gold cave bicycle environment/floor permission proof missing')
    if len(identities.get('maps', [])) <= 8 or identities['maps'][8]['feature_status']['bike'] != 'ALLOWED':
        errors.append('Union Cave bike capability is not registered as ALLOWED')
    return errors


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rpp', type=Path, default=ROOT)
    p.add_argument('--gold', type=Path, required=True)
    a = p.parse_args()
    problems = audit(a.rpp, a.gold)
    print(json.dumps({'status': 'FAIL' if problems else 'PASS', 'errors': problems}, ensure_ascii=False))
    return 1 if problems else 0


if __name__ == '__main__':
    raise SystemExit(main())
