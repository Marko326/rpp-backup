#!/usr/bin/env python3
"""REF-369H: audit B1F push-target coordinates, map collision, and Gold roles.

The stock GetTileTwoStepsInFrontOfPlayer sets DE to the *current boulder*
(player+one map cell) while C contains the screen tile *beyond* the boulder.
The previous Ice Path wrapper wrongly used DE as the final target.  This
source gate checks the live path and a reference 20x36 Gold map-role model.
No ROM is assembled and no mobile runtime behavior is claimed.
"""
from __future__ import annotations
import argparse
from pathlib import Path

B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
PLAYER = 'engine/overworld/player_state.asm'
ROLES = 'data/johto_ice_path_stage/IcePathB1F.roles.bin'
WIDTH, HEIGHT = 20, 36
GOLD_BOULDERS = ((11, 7), (7, 8), (8, 9), (17, 7))
GOLD_PITS = ((11, 2), (4, 7), (5, 12), (12, 13))
DIRECTION_OFFSETS = {'down': (0, 1), 'up': (0, -1), 'left': (-1, 0), 'right': (1, 0)}


def target_cell(boulder_x: int, boulder_y: int, direction: str):
    dx, dy = DIRECTION_OFFSETS[direction]
    return boulder_x + dx, boulder_y + dy


def reference_allowed(roles: bytes, boulder_x: int, boulder_y: int,
                      direction: str, filled_pits: frozenset[tuple[int, int]] = frozenset()) -> bool:
    x, y = target_cell(boulder_x, boulder_y, direction)
    if not (0 <= x < WIDTH and 0 <= y < HEIGHT):
        return False
    role = roles[y * WIDTH + x]
    return role in (0, 2) or role == 3 and (x, y) in GOLD_PITS and (x, y) not in filled_pits


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root=Path(root)
    overrides=overrides or {}
    def read(name: str) -> str:
        return str(overrides[name]) if name in overrides else (root/name).read_text()
    def blob(name: str) -> bytes:
        v=overrides.get(name)
        return v if isinstance(v,bytes) else (root/name).read_bytes()
    problems=[]
    def check(cond, why):
        if not cond: problems.append(why)
    src=read(B1)
    engine=read(PLAYER)
    try:
        path=src.split('JohtoIcePathB1FCheckPush369B::',1)[1].split('\n.blocked\n',1)[0]
    except IndexError:
        return ['live Ice Path B1F push entry or .blocked handler missing']
    # Compare instructions, not comments, so each of four facing directions is
    # mandatory and ordered.  This rejects the old faulty immediate DE lookup.
    instr=[line.strip().split(';',1)[0].strip() for line in path.splitlines()]
    instr=[line for line in instr if line]
    expected=[
        'predef GetTileTwoStepsInFrontOfPlayer',
        'ld b, d', 'ld c, e', 'ld a, [$ffdb]',
        'bit 0, a', 'jr nz, .targetDown',
        'bit 1, a', 'jr nz, .targetUp',
        'bit 2, a', 'jr nz, .targetLeft',
        'bit 3, a', 'jr nz, .targetRight',
        'jp .blocked',
        '.targetDown', 'inc b', 'jr .checkTarget',
        '.targetUp', 'dec b', 'jr .checkTarget',
        '.targetLeft', 'dec c', 'jr .checkTarget',
        '.targetRight', 'inc c',
        '.checkTarget', 'call JohtoIcePathB1FRoleAt367K',
    ]
    check(instr[:len(expected)]==expected,
          'push target must advance DE/current-boulder one more cell in every direction before Gold role lookup')
    check('GetTileTwoStepsInFrontOfPlayer:\n' in engine and
          'inc d\n\tjr .storeTile' in engine and 'dec d\n\tjr .storeTile' in engine and
          'inc e\n.storeTile' in engine and 'dec e\n\tjr .storeTile' in engine,
          'stock predef map coordinate ABI changed; re-audit push target displacement')
    check('callab JohtoIcePathB1FCheckPush369B' in engine and
          'cp JOHTO_ICE_PATH_B1F_LOCAL_ID' in engine,
          'real Strength push dispatcher no longer reaches Ice Path collision')
    check(all(needle in path for needle in (
        'and a ; FLOOR', 'cp 2 ; Gold ICE', 'cp 3 ; Gold PIT',
        'ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]',
        'jr nz, .blocked\n.checkSprites',
        'callba CheckForBoulderCollisionWithSprites', 'jr c, .blocked')),
        'target Gold WALL/ICE/PIT/filled PIT or object collision protection changed')
    check('    ld a, $ff\n    ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a' in src and
          '    xor a\n    ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a' in src,
          'stock Strength push result must be written on both reject and accept')
    roles=blob(ROLES)
    check(len(roles)==WIDTH*HEIGHT, 'B1F Gold collision-role table size changed')
    if len(roles)==WIDTH*HEIGHT:
        check(all(roles[y*WIDTH+x]==0 for x,y in GOLD_BOULDERS),
              'boulders should initially stand on Gold FLOOR; old-bug diagnostic invalid')
        check(all(roles[y*WIDTH+x]==3 for x,y in GOLD_PITS),
              'four original Gold PIT cell roles changed')
        # This reproduces the user's real bug with four concrete examples:
        # the old implementation examined the FLOOR under the stone, but the
        # actual next tile was a fixed WALL, in each directional branch.
        for x,y,direction in [(11,7,'left'),(7,8,'up'),(8,9,'down'),(17,7,'down')]:
            check(not reference_allowed(roles,x,y,direction),
                  f'Gold fixed-wall push barrier lost at ({x},{y}) {direction}')
        check(reference_allowed(roles,11,7,'right'),
              'legal FLOOR push must stay possible after correction')
        for x,y in GOLD_PITS:
            check(not reference_allowed(roles,x,y-1,'down',frozenset({(x,y)})),
                  f'filled Gold PIT {x,y} must reject a new stone')
        # Guarantee off-map moves cannot wrap around into an in-bounds role.
        for x,y,direction in [(0,0,'up'),(0,0,'left'),(WIDTH-1,HEIGHT-1,'down'),
                              (WIDTH-1,HEIGHT-1,'right')]:
            check(not reference_allowed(roles,x,y,direction),
                  'off-map push was accepted')
    check('db "REF-369@"' in read('data/game_version.asm'),
          'current development version label REF-369@ missing')
    return problems


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    errs=audit(parser.parse_args().root)
    for e in errs:print('FAIL:',e)
    if not errs:print('PASS: live B1F target=stone+direction, Gold wall/pit/ICE and sprite blocking; static only')
    raise SystemExit(bool(errs))
