#!/usr/bin/env python3
"""REF-368F live Ice Path slide wiring contract, not a ROM/phone simulation.

Validates hooks against actual overworld step/joypad/collision order, checks
far-bank coordinate ABI and Gold ICE locations, and rejects unsafe modifications.
"""
from __future__ import annotations
import argparse
from collections import Counter
from pathlib import Path
import re

MAPS = {
    'IcePath1F': ('ice_path_1f_runtime_367e.asm', 'JohtoIcePath1FIsIce368F', 'JohtoIcePath1FRoleAt367F', (40, 36)),
    'IcePathB1F': ('ice_path_b1f_runtime_367k.asm', 'JohtoIcePathB1FIsIce368F', 'JohtoIcePathB1FRoleAt367K', (20, 36)),
    'IcePathB2FMahoganySide': ('ice_path_b2f_mahogany_runtime_368a.asm', 'JohtoIcePathB2FMahoganyIsIce368F', 'JohtoIcePathB2FMahoganyRoleAt368A', (20, 18)),
    'IcePathB2FBlackthornSide': ('ice_path_b2f_blackthorn_runtime_368c.asm', 'JohtoIcePathB2FBlackthornIsIce368F', 'JohtoIcePathB2FBlackthornRoleAt368C', (10, 18)),
    'IcePathB3F': ('ice_path_b3f_runtime_368b.asm', 'JohtoIcePathB3FIsIce368F', 'JohtoIcePathB3FRoleAt368B', (20, 18)),
}
EXPECTED_ICE = (234, 44, 304, 91, 0)


def audit(root: Path, overrides: dict[str, str] | None = None) -> tuple[list[str], dict[str, int]]:
    root = Path(root)
    overrides = overrides or {}
    errors: list[str] = []
    counts: dict[str, int] = {}

    def get(path: str) -> str:
        if path in overrides:
            return overrides[path]
        return (root / path).read_text(encoding='utf-8')

    def ck(cond: bool, message: str) -> None:
        if not cond:
            errors.append(message)

    def section(txt: str, label: str, next_label: str | None = None) -> str:
        start = txt.find(label + '::')
        if start < 0:
            return ''
        end = txt.find(next_label + '::', start+len(label)+2) if next_label else -1
        return txt[start:end if end >= 0 else None]

    home = get('home/overworld.asm')
    slide = get('engine/johto_ice_path_slide_368f.asm')
    wram = get('wram.asm')
    clear = get('engine/overworld/clear_variables.asm')
    main = get('main.asm')
    validate = get('tools/validate_current_project.py')
    movement = get('engine/overworld/movement.asm')
    facing = get('data/facing.asm')

    ck('db "REF-369@"' in get('data/game_version.asm'), 'development game version not advanced to REF-368@')
    ck('SECTION "Johto Ice Path Auto Slide 368F", ROMX' in main and
       'INCLUDE "engine/johto_ice_path_slide_368f.asm"' in main and
       'ice_path_slide_state_367d.asm"' not in main,
       'live controller must be linked in floating ROMX without linking dormant duplicate grids')
    ck('wIcePathSlideHeading::\nwUnusedD5A3:: ; d67c\n\tds 1' in wram and
       'wIcePathSlideHeading::\n\tds 1' not in wram,
       'slide direction must use the established clear-on-map-entry $D67C byte without shifting WRAM')
    ck('ld [wIcePathSlideHeading], a' in clear and
       'callba ClearVariablesOnEnterMap' in home.split('EnterMap::', 1)[-1].split('OverworldLoop::', 1)[0],
       'map changes/warp arrivals must clear sliding state')
    ck(bool(re.search(r'call JoypadOverworld[^\n]*\n\s*;[^\n]*\n\s*;[^\n]*\n\s*callab JohtoIcePathInjectSlideInput368F\s+callba SafariZoneCheck',home)),
       'slide input must be injected after script/real Joypad at the completed-step boundary')
    ck(bool(re.search(r'ld a,\[wWalkCounter\]\s+and a\s+jp nz,CheckMapConnections[^\n]*\n;[^\n]*\n\s*;[^\n]*\n\s*callab JohtoIcePathArmAfterStep368F',home)),
       'slide state must arm only after AdvancePlayerSprite finishes the real walk')
    col = home.split('CollisionCheckOnLand::', 1)[-1].split('CheckTilePassable::', 1)[0]
    ck(bool(re.search(r'\.collision\s+;[^\n]*\n\s*;[^\n]*\n\s*xor a\s+ld \[wIcePathSlideHeading\], a',col)),
       'normal collision failure must disarm ICE, avoiding infinite wall/sprite pushing')
    ck(bool(re.search(r'\.battleOccurred\s+.*?ld \[hJoyHeld\],a\s+ld \[wIcePathSlideHeading\],a',home,re.S)),
       'battle/script entry must disarm ICE movement')
    arm=section(slide,'JohtoIcePathArmAfterStep368F','JohtoIcePathInjectSlideInput368F')
    inj=section(slide,'JohtoIcePathInjectSlideInput368F','JohtoIcePathPlayerOnIce368F')
    read=section(slide,'JohtoIcePathPlayerOnIce368F')
    ck(all(t in arm for t in ('bit 7, a ; scripted movement', 'bit 6, a ; jumping',
                               'cp 2 ; Surf', 'call JohtoIcePathPlayerOnIce368F',
                               'ld a, [wPlayerMovingDirection]', 'ld [wIcePathSlideHeading], a')) and
       all('cp PLAYER_DIR_'+d in arm for d in ('UP','DOWN','LEFT','RIGHT')),
       'arm state must validate actual step direction, ICE, Surf and scripted/ledge state')
    ck(all(t in inj for t in ('ld a, [wIcePathSlideHeading]', 'ret z',
                                'bit 7, a ; scripts', 'bit 6, a', 'cp 2',
                                'ld a, [wCurOpponent]', 'call JohtoIcePathPlayerOnIce368F',
                                'ld [hJoyHeld], a', 'ld [hJoyPressed], a',
                                'ld [hJoyReleased], a', 'ld [wIcePathSlideHeading], a')),
       'input injection must preserve idle input, suppress menus in slide, clear interrupted state')
    for key in ('RIGHT','LEFT','UP','DOWN'):
        ck(bool(re.search(r'cp PLAYER_DIR_'+key+r'\s+jr z, \.'+key.lower(),inj)) or
           (key == 'DOWN' and 'cp PLAYER_DIR_DOWN' in inj and 'ld a, D_DOWN' in inj),
           f'invalid remembered direction test for {key}')
        ck('ld a, D_'+key in inj, f'{key} heading must map to matching joypad bit')
    ck('cp JOHTO_RUNTIME_MAP_HANDLE' in read and 'cp MAP_REGION_JOHTO' in read and
       all('cp '+ident in read for ident in ('JOHTO_ICE_PATH_1F_LOCAL_ID',
           'JOHTO_ICE_PATH_B1F_LOCAL_ID','JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID',
           'JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID','JOHTO_ICE_PATH_B3F_LOCAL_ID')),
       'live ICE role reader missing region+handle guard or an active floor')
    ck('callab JohtoIcePath' in read and not re.search(
       r'ld a, \[wYCoord\]\s+ld b, a\s+ld a, \[wXCoord\]\s+ld c, a\s+callab',read),
       'cross-bank role dispatch must not put coordinates in B (callab overwrites B)')
    ck('johto_ice_path_slide_368f_audit.py' in validate,
       'maintained project validator must call live slide audit')

    # Gold ICE uses a fixed-foot sliding pose: movement and facing still update,
    # but the normal walking-frame counter/index must not cycle. Bike animation
    # remains untouched because an already-mounted rider can enter the cave.
    sprite = movement.split('UpdatePlayerSprite:', 1)[-1].split('; Sprite foot occlusion', 1)[0]
    moving = sprite.split('\n.moving\n', 1)[-1].split('\n.animateMovingSprite\n', 1)[0]
    ck(sprite.find('ld [wSpriteStateData1 + 9], a') < sprite.find('\n.moving\n') and
       all(t in moving for t in (
           'ld a, [wWalkBikeSurfState]', 'and a', 'jr nz, .animateMovingSprite',
           'ld a, [wIcePathSlideHeading]', 'jr z, .animateMovingSprite',
           'ld [wSpriteStateData1 + 7], a', 'ld [wSpriteStateData1 + 8], a',
           'jr .calcImageIndex')) and
       '.animateMovingSprite\n\tld a, [wd736]' in sprite and
       '.calcImageIndex\n\tld a, [wSpriteStateData1 + 8]' in sprite,
       'walking ICE slide must hold a fixed-foot frame while preserving facing/position; bike animation must remain normal')
    facing_table = facing.split('SpriteFacingAndAnimationTable:', 1)[-1].split('\nSpriteFacingDownAndStanding:', 1)[0]
    facing_rows = [line.strip() for line in facing_table.splitlines() if line.strip().startswith('dw ')]
    fixed_rows = (0, 4, 8, 12)
    ck(len(facing_rows) >= 16 and all('AndStanding' in facing_rows[i] for i in fixed_rows) and
       all('AndWalking' in facing_rows[i] for i in (1, 5, 9, 13)),
       'neutral frame index 0 must resolve to a standing pose for all four facings')

    for i,(name,(file,wrapper,role,(width,height))) in enumerate(MAPS.items()):
        asm=get('data/johto_ice_path_stage/'+file)
        block=section(asm,wrapper)
        ck(bool(re.search(r'push bc\s+ld a, \[wYCoord\]\s+ld b, a\s+'
                          r'ld a, \[wXCoord\]\s+ld c, a\s+call '+role+
                          r'\s+cp 2\s+pop bc[^\n]*\s+ret',block)),
           f'{name}: role wrapper must load coordinates AFTER bank switch and return ICE via Z')
        ck('callab '+wrapper in read, f'{name}: live role dispatcher missing wrapper')
        role_path = root / 'data/johto_ice_path_stage' / (name+'.roles.bin')
        roles=role_path.read_bytes()
        counts[name]=Counter(roles)[2]
        ck(len(roles)==width*height and counts[name]==EXPECTED_ICE[i],
           f'{name}: Gold ICE grid dimensions/count mismatch')
    ck(sum(counts.values())==673, '673 live ICE cells were not all checked')
    return errors, counts


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    args=p.parse_args()
    errors, counts=audit(args.root)
    print('ICE roles:',', '.join(f'{k}={v}' for k,v in counts.items()))
    for e in errors: print('FAIL:',e)
    if not errors: print('PASS: live slide step/input/map/bank/collision wiring; ROM/mobile execution still unverified')
    return bool(errors)

if __name__=='__main__':
    raise SystemExit(main())
