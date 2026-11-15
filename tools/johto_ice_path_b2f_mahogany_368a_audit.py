#!/usr/bin/env python3
"""REF-368A Gold B2F Mahogany walk-only pilot, registered stair and sealed arrivals.

Source tests only; never treats static PASS as a ROM/phone acceptance.
"""
from __future__ import annotations
import argparse
from collections import Counter, deque
import json
from pathlib import Path
import re

MAP = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
ROLES = 'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin'
BLOCK = 'maps/johto_ice_path_stage/IcePathB2FMahoganySide.runtime.blk'
GOLD = 'maps/johto_ice_path_stage/IcePathB2FMahoganySide.gold.blk'
CONTRACT = 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'
START = (17, 1)
SEALED = ((9, 11), (11, 4), (4, 6), (4, 12), (12, 12))


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    errors: list[str] = []
    def get(path: str) -> bytes:
        item = overrides.get(path)
        return (root / path).read_bytes() if item is None else item.encode() if isinstance(item, str) else item
    def txt(path: str) -> str:
        return get(path).decode('utf-8')
    def check(passed: bool, description: str) -> None:
        if not passed:
            errors.append(description)
    asm = txt(MAP)
    names = json.loads(txt(CONTRACT))['maps']
    gold = next(m for m in names if m['name'] == 'IcePathB2FMahoganySide')
    check((gold['stable_id'], gold['width_cells'], gold['height_cells']) == (96, 20, 18),
          'B2F Mahogany Gold stable ID/dimensions wrong')
    check(len(get(BLOCK)) == 90 and get(BLOCK) == get(GOLD),
          'B2F Mahogany runtime Gold 10x9 block bytes altered')
    roles = get(ROLES)
    check(len(roles) == 360 and Counter(roles) == Counter({2: 304, 0: 44, 1: 10, 4: 2}),
          'B2F Mahogany 20x18 role population wrong')
    if len(roles) == 360:
        for x, y, want in [(17, 1, 4), (9, 11, 4), (11, 4, 2), (4, 6, 2), (4, 12, 2), (12, 12, 2)]:
            check(roles[y * 20 + x] == want, f'B2F Gold stair/arrival role wrong at {(x,y)}')
        # Normal walking from the sole B1F entrance must reach its return.
        # The other ladder stays impassable and all ICE slots remain walkable.
        queue, visited = deque([START]), {START}
        while queue:
            x, y = queue.popleft()
            for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
                xx, yy = x + dx, y + dy
                if not 0 <= xx < 20 or not 0 <= yy < 18 or (xx, yy) in visited:
                    continue
                role = roles[yy * 20 + xx]
                if role not in (0, 2) and (xx, yy) != START:
                    continue
                visited.add((xx, yy)); queue.append((xx, yy))
        check(len(visited) > 30 and (8, 9) in visited,
              'B2F Gold ICE walking preview is not traversable from the stair')
    required = (
        'JohtoIcePathB2FMahoganyRuntimeHeader368A::',
        'JohtoIcePathB2FMahoganyObjects368A::',
        'JohtoIcePathB2FMahoganyLandDecision368A::',
        'JohtoIcePathB2FMahoganyBikeFloorAllowed368A::',
        'INCBIN "maps/johto_ice_path_stage/IcePathB2FMahoganySide.runtime.blk"',
        'INCBIN "data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin"',
        'ASSERT JohtoIcePathB2FMahoganyRuntimeHeader368AEnd - JohtoIcePathB2FMahoganyRuntimeHeader368A == 12',
        'ASSERT BANK(JohtoIcePathB2FMahoganyRuntimeHeader368A) == BANK(JohtoIcePathB2FMahoganyRuntimeBlocks368A)',
    )
    for item in required:
        check(item in asm, f'B2F Mahogany native runtime missing: {item}')
    obj = asm.split('JohtoIcePathB2FMahoganyObjects368A::', 1)[-1].split('JohtoIcePathB2FMahoganyRoleAt368A::', 1)[0]
    rows = re.findall(r'(?m)^\s*db\s+(\$ff|\d+),\s*(\$ff|\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR\s*$',
                      '\n'.join(line.split(';')[0] for line in obj.splitlines()))
    expected = [('1', '17', '1'), ('11', '9', '0'), ('4', '11', '2'),
                ('6', '4', '3'), ('12', '4', '4'), ('12', '12', '5')]
    check(rows == expected and 'db 6 ; Gold six ordinals: #1/#2 are exit ladders; #3-#6 arrival-only ICE' in obj,
          'B2F Mahogany Gold six-ordinal warp table wrong; B3F/ICE return may leak')
    check('db 4 ; Gold lower-floor rocks appear only after their B1F PIT is filled' in obj and
          len(re.findall(r'(?m)^\s*object SPRITE_BOULDER,',obj)) == 4 and
          all(f'object SPRITE_BOULDER, {x}, {y}, STAY, NONE, ${i}' in obj for i,(x,y) in
              enumerate([(11,3),(4,7),(3,12),(12,13)],1)),
          'B2F Gold dropped boulder positions/count must match four Gold objects')
    check('JohtoIcePathB2FMahoganySyncLanded369B::' in asm and
          'jp JohtoIcePathB2FMahoganySyncLanded369B' in asm,
          'B2F boulder objects lack saved hole-occupancy visibility control')
    decision = asm.split('JohtoIcePathB2FMahoganyLandDecision368A::', 1)[-1].split('JohtoIcePathB2FMahoganyBikeFloorAllowed368A::', 1)[0]
    for needle in ('call JohtoIcePathB2FMahoganyRoleAhead368A', 'cp 2 ; Gold ICE',
                   'cp 4 ; Gold ladder', 'cp 17', 'cp 1', 'ld e, 0', 'ret nz'):
        check(needle in decision, f'B2F Mahogany collision gate missing {needle}')
    check('cp 9' in decision and 'cp 11' in decision and '.b3fLadder' in decision,
          'B2F return ladders must be only (17,1)/(9,11)')
    bike = asm.split('JohtoIcePathB2FMahoganyBikeFloorAllowed368A::', 1)[-1]
    check('call JohtoIcePathB2FMahoganyRoleAt368A' in bike and 'and a' in bike and
          'jr nz, .no' in bike and 'scf' in bike, 'B2F bike must allow only Gold FLOOR')
    entry = txt('home/rom0_relief_349.asm')
    check('cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID\n\tjp z, .icePathB2FMahoganyBike' in entry and
          'callab JohtoIcePathB2FMahoganyBikeFloorAllowed368A' in entry,
          'B2F bike public item entry missing')
    land = txt('engine/johto_land_collision_gateway_272.asm')
    check('cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID' in land and
          'callab JohtoIcePathB2FMahoganyLandDecision368A' in land,
          'B2F live land-collision gateway missing')
    headers = txt('data/johto_header_descriptors.asm')
    assets = txt('data/johto_pilot_runtime_assets.asm')
    source = txt('data/johto_pilot_source_resources.asm')
    slot = txt('data/johto_stable_id_slots.asm')
    check('dw JohtoIcePathB2FMahoganyRuntimeHeader368A' in headers and
          'JohtoIcePathB2FMahoganyRuntimeDescriptor::' in assets and
          'JohtoIcePathB2FMahoganySourceGoldBlocks368A::' in source and
          'INCLUDE "data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm"' in txt('main.asm'),
          'B2F map/header/resource/main ASM not fully registered')
    check('db 67, 69, 68' in slot and
          'DEF NUM_JOHTO_ACTIVE_MAPS EQU 70' in txt('constants/region_map_constants.asm'),
          'B2F Mahogany ID96 retains dense slot67 in active 70 map roster')
    pilot = txt('engine/johto_pilot_runtime.asm')
    for source_id, index, dest_id in [
            ('JOHTO_ICE_PATH_B1F_LOCAL_ID', 1, 'JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID'),
            ('JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID', 0, 'JOHTO_ICE_PATH_B1F_LOCAL_ID')]:
        check(f'db MAP_REGION_JOHTO, {source_id}, {index}, MAP_REGION_JOHTO, {dest_id}' in pilot,
              f'B1F/B2F reciprocal route missing {source_id}#{index}')
    b1f = txt('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm')
    check('db 3, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR' in b1f and '.ladder17' in b1f,
          'B1F Gold #2 source (17,3) not opened with actual walk permission')
    check('cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID ; Gold LADDER arrival stands still' in pilot and
          'cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID\n    jp z, .icePathB2FMahoganyWarp369S' in pilot,
          'B2F ladder arrival or step-in dispatch not wired')
    sign = txt('engine/overworld/map_name_sign.asm')
    check('cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID' in sign and
          '.johtoIcePathB2F\n    ld hl, .JohtoIcePathName\n    ld b, $82' in sign,
          'B2F location card must display Ice Path B2F')
    check('db 54, 138 ; slot67 Ice Path B2F Mahogany Side\n    dw JohtoPilotIcePathName' in
          txt('engine/fly_town_map_helpers.asm') and
          'db 38 ; slot67 Ice Path B2F Mahogany Side Gold landmark' in
          txt('engine/fly_town_map_helpers.asm'),
          'B2F Save/Continue/Town Map slot or name missing')
    check('JohtoIcePathB2FBlackthornRuntimeHeader368C' in headers and 'JohtoIcePathB3F' in headers,
          'final Ice Path region/B3F header not active')
    check('db "REF-369@"' in txt('data/game_version.asm'),
          'B2F live map should carry current REF-369B@ development label')
    return errors


def main() -> int:
    p = argparse.ArgumentParser(); p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1]); a=p.parse_args()
    bad=audit(a.root)
    for problem in bad: print('FAIL:', problem)
    if not bad: print('PASS: B2F Mahogany exact Gold 10x9, ICE walk-only, 6 ordinals (2 outgoing ladders, 4 receive-only PIT cells), B1F return, map/card/bike public gates')
    return bool(bad)


if __name__ == '__main__':
    raise SystemExit(main())
