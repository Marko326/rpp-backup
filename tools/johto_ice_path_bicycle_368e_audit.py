#!/usr/bin/env python3
"""REF-368E: check actual Bicycle item/SELECT/sprite paths on all five Ice Path maps.

Checks the authored LR35902 control flow and every Gold role cell, not a ROM
execution or proof of on-device sprite/music. Existing ride state must survive
stairs; fresh mounting is restricted to FLOOR (plus 1F exit carpet).
"""
from __future__ import annotations

import argparse
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import re

FLOORS = {
    'IcePath1F': ('JOHTO_ICE_PATH_1F_LOCAL_ID', '.icePathBike', 'JohtoIcePath1FBikeFloorAllowed367J', 'JohtoIcePath1FRoleAt367F', 'ice_path_1f_runtime_367e.asm', (40, 36), {0, 5}),
    'IcePathB1F': ('JOHTO_ICE_PATH_B1F_LOCAL_ID', '.icePathB1FBike', 'JohtoIcePathB1FBikeFloorAllowed367K', 'JohtoIcePathB1FRoleAt367K', 'ice_path_b1f_runtime_367k.asm', (20, 36), {0}),
    'IcePathB2FMahoganySide': ('JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID', '.icePathB2FMahoganyBike', 'JohtoIcePathB2FMahoganyBikeFloorAllowed368A', 'JohtoIcePathB2FMahoganyRoleAt368A', 'ice_path_b2f_mahogany_runtime_368a.asm', (20, 18), {0}),
    'IcePathB2FBlackthornSide': ('JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID', '.icePathB2FBlackthornBike', 'JohtoIcePathB2FBlackthornBikeFloorAllowed368C', 'JohtoIcePathB2FBlackthornRoleAt368C', 'ice_path_b2f_blackthorn_runtime_368c.asm', (10, 18), {0}),
    'IcePathB3F': ('JOHTO_ICE_PATH_B3F_LOCAL_ID', '.icePathB3FBike', 'JohtoIcePathB3FBikeFloorAllowed368B', 'JohtoIcePathB3FRoleAt368B', 'ice_path_b3f_runtime_368b.asm', (20, 18), {0}),
}
# Sanity-check totals from the pinned Gold source reference; catches accidental
# truncation, wrong Gold floor selection and incorrect ICE/FLOOR role offsets.
GOLD_FLOOR_COUNTS = {
    'IcePath1F': (815, 234, 3),
    'IcePathB1F': (251, 44, 0),
    'IcePathB2FMahoganySide': (44, 304, 0),
    'IcePathB2FBlackthornSide': (36, 91, 0),
    'IcePathB3F': (75, 0, 0),
}


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> tuple[list[str], dict[str, int]]:
    root = Path(root)
    overrides = overrides or {}
    errors: list[str] = []
    allowed_counts: dict[str, int] = {}

    def raw(path: str) -> bytes:
        v = overrides.get(path)
        return (root / path).read_bytes() if v is None else v.encode() if isinstance(v, str) else v

    def source(path: str) -> str:
        return raw(path).decode('utf-8')

    def check(ok: bool, message: str) -> None:
        if not ok:
            errors.append(message)

    refs = json.loads(source('docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'))['assets']
    public = source('home/rom0_relief_349.asm')
    entry = public.split('IsBikeRidingAllowed::', 1)[-1].split('\n.legacyBike\n', 1)[0]
    entry_clean = re.sub(r';[^\n]*', '', entry)
    check('cp JOHTO_RUNTIME_MAP_HANDLE' in entry_clean and
          re.search(r'ld a, \[wCurRegion\]\s+dec a\s+jr nz, \.legacyBike', entry_clean) is not None and
          'ld a, [wCurLocalMapID]' in entry, 'Bicycle public map/Johto guard missing')
    check('JOHTO_ICE_PATH' not in source('data/bike_riding_tilesets.asm'),
          'Ice Path globally whitelisted without checking live FLOOR role')

    bag = source('engine/items/items.asm')
    bag_action = bag.split('ItemUseBicycle:', 1)[-1].split('PlayBikeToggleMusicIfEnabled:', 1)[0]
    check('callab IsBikeRidingAllowed' in bag_action and
          'jp nc,NoCyclingAllowedHere' in bag_action and
          'ld [wWalkBikeSurfState],a ; change player state to walking' in bag_action and
          'ld [wWalkBikeSurfState],a ; change player state to bicycling' in bag_action,
          'Bicycle Bag use must permit mount and dismount through public check')
    shortcut = source('engine/overworld/bike_shortcut.asm')
    check('farcall IsBikeRidingAllowed' in shortcut.split('TryRideBike::', 1)[-1] and
          'call TryRideBike' in shortcut.split('TryFishOrRideBike::', 1)[-1],
          'Bicycle SELECT shortcut no longer consults public bike permission')
    load_sprite = source('home/overworld.asm')
    load_sprite_clean = re.sub(r';[^\n]*', '', load_sprite)
    check(bool(re.search(r'\.ridingBike\s+callab IsBikeRidingAllowed\s+jr c, \.determineGraphics', load_sprite_clean)),
          'Map transition bicycle sprite refresh no longer checks public entry')

    for map_name, (map_id, label, helper, role_func, asm_file, (width, height), allowed_roles) in FLOORS.items():
        path = 'data/johto_ice_path_stage/' + asm_file
        asm = source(path)
        role_path = 'data/johto_ice_path_stage/' + map_name + '.roles.bin'
        roles = raw(role_path)
        check(len(roles) == width * height, f'{map_name}: Gold role map dimensions changed')
        check(sha256(roles).hexdigest() == refs[role_path]['sha256'],
              f'{map_name}: Gold role bytes differ from pinned source')
        counts = Counter(roles)
        check((counts[0], counts[2], counts[5]) == GOLD_FLOOR_COUNTS[map_name],
              f'{map_name}: FLOOR/ICE/CARPET role counts changed')
        # This enumerates *all* cells, not just a handpicked walkable position.
        allowed_counts[map_name] = sum(int(role in allowed_roles) for role in roles)
        check(allowed_counts[map_name] > 0 and
              all((role in allowed_roles) == (role == 0 or (map_name == 'IcePath1F' and role == 5))
                  for role in roles), f'{map_name}: bicycle tile whitelist incorrect')
        check(f'INCBIN "{role_path}"' in asm and f'{role_func}::' in asm,
              f'{map_name}: Gold role reader missing from runtime')
        check(bool(re.search(r'cp ' + re.escape(map_id) + r'\s+jp z, ' + re.escape(label) + r'\b', entry)),
              f'{map_name}: public bike-ID dispatch missing')
        # Between local labels, the mount branch must honour already-riding state
        # even when arriving on ICE/LADDER from another floor.
        wrapper_match = re.search(r'(?ms)^' + re.escape(label) + r'\s*\n(.*?)(?=^\.[A-Za-z]|^INCLUDE|\Z)', public)
        wrapper = wrapper_match.group(1) if wrapper_match else ''
        check(bool(re.search(r'ld a, \[wWalkBikeSurfState\]\s+cp 1\s+jr z, \.allowed\s+callab '
                             + re.escape(helper) + r'\s+ret', wrapper)),
              f'{map_name}: mounted player must remain on bicycle after stair transition')
        helper_match = re.search(r'(?ms)^' + re.escape(helper) + r'::\s*\n(.*?)(?=^[A-Za-z_][\w]*::|\Z)', asm)
        body = helper_match.group(1) if helper_match else ''
        reader = re.search(r'push bc\s+push hl\s+ld a, \[wYCoord\]\s+ld b, a\s+'
                           r'ld a, \[wXCoord\]\s+ld c, a\s+call '
                           + re.escape(role_func) + r'\s+pop hl\s+pop bc', body)
        check(bool(reader), f'{map_name}: bicycle must inspect current cell, not facing cell / wrong map')
        if map_name == 'IcePath1F':
            valid = re.search(r'and a[^\n]*\s+jr z, \.allowed\s+cp 5[^\n]*\s+jr z, \.allowed\s+and a[^\n]*\s+ret\s+\.allowed\s+scf\s+ret', body)
        else:
            valid = re.search(r'and a\s+jr nz, \.no\s+scf\s+ret\s+\.no\s+and a\s+ret', body)
        check(bool(valid), f'{map_name}: bike fresh-mount flag does not match Gold FLOOR permission')

    return errors, allowed_counts


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    problems, counts = audit(args.root)
    for name, count in counts.items():
        print(f'{name}: {count} mounting cells (existing bike retained on transfers)')
    for problem in problems:
        print('FAIL:', problem)
    if not problems:
        print('PASS: all five live Ice Path floors have public Bag/SELECT bicycle and sprite transitions; every Gold cell checked')
    raise SystemExit(bool(problems))
