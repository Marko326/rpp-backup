#!/usr/bin/env python3
"""REF-369S Gold Ice Path one-way player PIT, receiver safety and fall-animation audit.

Source-only: does not execute the ROM. The B2F receiver ICE entries have real
coordinates but must never be treated as outgoing warps, even if the player
steps back onto them or collides while standing at that coordinate.
"""
from __future__ import annotations
from pathlib import Path
import argparse
import json
import re

B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
B2 = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
PILOT = 'engine/johto_pilot_runtime.asm'
FALL = 'data/johto_burned_tower/REF348_b1f_runtime.asm'
CONTRACT = 'tools/johto_warp_field_entry_contracts.json'
PITS = [(11, 2), (4, 7), (5, 12), (12, 13)]
LANDINGS = [(11, 4), (4, 6), (4, 12), (12, 12)]


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    def read(path: str) -> str:
        item = overrides.get(path)
        if item is None: return (root / path).read_text()
        return item.decode() if isinstance(item, bytes) else item
    def binary(path: str) -> bytes:
        item = overrides.get(path)
        return (root / path).read_bytes() if item is None else item.encode() if isinstance(item, str) else item
    errors = []
    def ck(ok: bool, label: str) -> None:
        if not ok: errors.append(label)

    b1, b2, pilot, fall = map(read, (B1, B2, PILOT, FALL))
    roles1 = binary('data/johto_ice_path_stage/IcePathB1F.roles.bin')
    roles2 = binary('data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin')
    ck(len(roles1) == 720 and [(x,y) for y in range(36) for x in range(20) if roles1[y*20+x] == 3] == PITS,
       'exact four Gold B1F player PIT roles altered')
    ck(len(roles2) == 360 and all(roles2[y*20+x] == 2 for x,y in LANDINGS),
       'four Gold B2F receive-only landing tiles must be ICE')
    ck(all(land not in [(11,3),(4,7),(3,12),(12,13)] for land in LANDINGS),
       'B2F player landing must not overlap a deposited stone object')
    obj1 = b1.split('JohtoIcePathB1FObjects367K::',1)[-1].split('JohtoIcePathB1FRoleAt367K::',1)[0]
    obj2 = b2.split('JohtoIcePathB2FMahoganyObjects368A::',1)[-1].split('JohtoIcePathB2FMahoganyRoleAt368A::',1)[0]
    def coords(asm: str) -> list[tuple[int,int,int]]:
        clean = '\n'.join(line.split(';',1)[0] for line in asm.splitlines())
        return [(int(x),int(y),int(o)) for y,x,o in re.findall(
            r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR\s*$', clean)]
    src1, src2 = coords(obj1), coords(obj2)
    ck(len(src1) == 8 and src1[2:6] == [(x,y,i+2) for i,(x,y) in enumerate(PITS)],
       'B1F four PIT warp source coordinates or destination ordinals are wrong')
    ck(len(src2) == 6 and src2[2:6] == [(x,y,i+2) for i,(x,y) in enumerate(LANDINGS)],
       'B2F four receive-only player landing coordinates or ordinals are wrong')
    land = b1.split('JohtoIcePathB1FLandDecision367K::',1)[-1].split('JohtoIcePathB1FBikeFloorAllowed367K::',1)[0]
    ck(bool(re.search(r'cp 3\s*; PIT:[^\n]*\n\s*jp z, \.allow',land)),
       'B1F player collision must accept only exact Gold PIT terrain')
    # The source needs four routes, but the destination MUST never register returns.
    from_id = 'JOHTO_ICE_PATH_B1F_LOCAL_ID'
    to_id = 'JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID'
    for ordinal in range(2,6):
        row = f'db MAP_REGION_JOHTO, {from_id}, {ordinal}, MAP_REGION_JOHTO, {to_id}'
        back = f'db MAP_REGION_JOHTO, {to_id}, {ordinal}, MAP_REGION_JOHTO, {from_id}'
        ck(row in pilot and pilot.count(row+'\n') == 1,
           f'Gold PIT source route #{ordinal+1} missing or duplicated')
        ck(back not in pilot, f'B2F landing #{ordinal+1} illegally returns to B1F')
    mode = pilot.split('.icePathB2FMahoganyWarp369S',1)[-1].split('.icePathLadderOrCarpet367K',1)[0]
    ck('cp 1' in mode and 'cp 17' in mode and 'cp 11' in mode and 'cp 9' in mode and
       'ld e, 1 ; exact arrival-only ICE' in mode and
       'jp z, .unionCaveLadder342' in mode,
       'B2F warp mode must allow only two ladders, never receiver ICE sources')
    guard = pilot.split('\n.legacyGuard\n',1)[-1].split('\n.unionCaveB1FRuinsExit366\n',1)[0]
    ck('cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID' in guard and
       'ld e, 0 ; B2F Gold PIT ICE arrival can never act as a source warp' in guard,
       'B2F receiver-only collision must reject outbound warp')
    fall_func = fall.split('JohtoBurnedTowerMaybeFallWarp::',1)[-1].split('JohtoEnterMapAnimationDispatcher::',1)[0]
    ice = fall_func.split('\n.icePath369S\n',1)[-1].split('\n.fall\n',1)[0]
    ck('cp JOHTO_ICE_PATH_B1F_LOCAL_ID\n    jr z, .icePath369S' in fall_func and bool(re.search(
       r'ld a, \[wWarpedFromWhichWarp\]\s+cp 2\s+ret c\s+cp 6\s+ret nc\s+'
       r'ld a, \[wDestinationWarpID\]\s+cp 2\s+ret c\s+cp 6\s+ret nc', ice)),
       'player PIT fall flag must arm only for four B1F Gold source/destination ordinals')
    ck('set 7, [hl]' in fall_func and 'jp PlaySilentMapChange369V' in fall_func and
       'GBFadeOutToWhite' not in fall_func and
       'call GBFadeInFromBlack' in fall and
       'call JohtoBurnedTowerFallEntryAnim' in fall and
       'res 7, [hl]' in fall and 'res 0, [hl]' in fall and 'res 1, [hl]' in fall,
       'Ice Path PIT must reuse ordinary black cave transition plus fall movement; clear warp flags')
    ck('callab JohtoBurnedTowerMaybeFallWarp' in read('home/overworld.asm'),
       'Gold player PIT fall must be dispatched before registered warp changes source')
    ck('ld [wIcePathSlideHeading], a' in read('engine/overworld/clear_variables.asm'),
       'B2F ICE landing must not inherit an old sliding heading')
    contract=json.loads(read(CONTRACT))
    for i,((x,y),(a,b)) in enumerate(zip(PITS,LANDINGS),2):
        ck(any(row.get('from')==from_id and row.get('ordinal')==i and row.get('to')==to_id and
               row.get('departure')==[x,y] and row.get('landing')==[a,b] and
               row.get('step')=='NONE' and row.get('new_route_review') is True
               for row in contract['critical_arrivals']),
           f'PIT {i+1} must have explicit safe receive-only warp field review')
    ck('db "REF-369@"' in read('data/game_version.asm'), 'development version not REF-369@')
    return errors


if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);a=ap.parse_args()
    e=audit(a.root)
    for s in e:print('FAIL:',s)
    if not e:print('PASS_SOURCE_ONLY: Gold Ice Path four one-way player PITs, safe ICE landings, shared fall animation, no reverse warp')
    raise SystemExit(bool(e))
