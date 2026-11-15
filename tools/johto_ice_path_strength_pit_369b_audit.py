#!/usr/bin/env python3
"""REF-369B source-level gate for movable Ice Path B1F stones / saved B2F drops.

No ROM is assembled. This checks active ABI, original Gold coordinates,
source-vs-destination event flags, boulder collision and bank3 byte budget.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
B2 = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
PUSH = 'engine/overworld/player_state.asm'


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    def read(name: str) -> str:
        v = overrides.get(name)
        return v.decode() if isinstance(v, bytes) else v if isinstance(v, str) else (root / name).read_text()
    problems: list[str] = []
    def ck(ok: bool, reason: str) -> None:
        if not ok: problems.append(reason)

    b1,b2,engine = read(B1),read(B2),read(PUSH)
    roles1=(root/'data/johto_ice_path_stage/IcePathB1F.roles.bin').read_bytes()
    roles2=(root/'data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin').read_bytes()
    pits=[(11,2),(4,7),(5,12),(12,13)]
    rocks=[(11,7),(7,8),(8,9),(17,7)]
    landed=[(11,3),(4,7),(3,12),(12,13)]
    ck(len(roles1)==720 and all(roles1[y*20+x]==3 for x,y in pits), 'Gold B1F PIT roles/coordinates changed')
    ck(len(roles2)==360 and all(roles2[y*20+x]==2 for x,y in landed), 'Gold B2F ICE landing roles changed')
    for idx,(x,y) in enumerate(rocks,1):
        ck(bool(re.search(rf'(?m)^\s*object\s+SPRITE_BOULDER,\s*{x},\s*{y},\s*STAY,\s*BOULDER_MOVEMENT_BYTE_2,\s*\${idx}\s*$', b1)),
           f'Gold Strength boulder {idx} missing, wrong coordinates or not pushable')
    ck('call JohtoIcePathB1FHideDropped369B' in b1.split('JohtoIcePathB1FScript367K::')[1].split('JohtoIcePathB1FTextPointers367K:')[0] and
       'jp JohtoIcePathB1FCheckStoneDrop369B' in b1, 'B1F boulder completion callback not in live map script')
    ck('bit 7, [hl]' in b1 and 'res 7, [hl]' in b1, 'stock boulder dust completion must be consumed exactly once')
    ck('call CheckBoulderCoords' in b1 and
       'db 2, 11, 7, 4, 12, 5, 13, 12, $ff' in b1,
       'B1F four Gold boulder-drop PIT positions must be detected dynamically')
    ck('ld a, [wCoordIndex]' in b1 and 'ld a, [wBoulderSpriteIndex]' in b1 and
       'db $04, $08, $10, $20' in b1 and 'db $10, $20, $40, $80' in b1,
       'source-boulder identity and destination-hole identity must be saved independently')
    ck('DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED / 8' in b1 and
       'DEF JOHTO_ICE_PATH_PIT_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_PIT_1_FILLED / 8' in b1 and
       'ASSERT JOHTO_ICE_PATH_PIT_FLAGS_369B == 135' in b1 and
       'ASSERT JOHTO_ICE_PATH_STONE_FLAGS_369B == 136' in b1 and
       'EVENT_9D7 / 8 + 1' not in '\n'.join(line.split(';', 1)[0] for line in b1.splitlines()),
       'persistent flags must use the audited D852/D853 slots, never D855')
    ck('JohtoIcePathInitializePitState369B::' in b1 and 'and $c3' in b1 and
       'and $0f' in b1 and 'or JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B' in b1 and
       'call JohtoIcePathInitializePitState369B' in b1 and
       'callab JohtoIcePathInitializePitState369B' in b2,
       'REF-369A one-time save migration must preserve shared event bits on B1F/B2F entry')
    ck('wEventFlags:: ; d7cb\n\tds 139' in read('wram.asm'), 'existing save event flags region must not resize')
    for offset, mask in [(0x10,4),(0x20,5),(0x30,6),(0x40,7)]:
        ck(f'bit {mask}, a' in b1 and f'ld [wSpriteStateData1 + ${offset:02x}], a' not in b1 and
           f'ld [wSpriteStateData2 + ${offset+4:02x}], a' in b1 and
           f'ld [wSpriteStateData2 + ${offset+5:02x}], a' in b1,
           f'B1F source sprite {mask-3} is not hidden on saved fall')
    ck('JohtoIcePathB1FRoleAhead367K::' in b1 and '.blocked' not in b1.split('JohtoIcePathB1FRoleAhead367K::')[1].split('JohtoIcePathB1FLandDecision367K::')[0],
       'moving boulders must not leave immutable walls at their original coordinates')
    ck('callab JohtoIcePathB1FCheckPush369B' in engine and
       'cp JOHTO_ICE_PATH_B1F_LOCAL_ID' in engine and 'callab JohtoBurnedTowerB1FCheckForCollisionWhenPushingBoulder' in engine,
       'Ice Path push collision must be routed without removing Burned Tower branch')
    ck('predef GetTileTwoStepsInFrontOfPlayer' in b1 and 'call JohtoIcePathB1FRoleAt367K' in b1 and
       'cp 2 ; Gold ICE' in b1 and 'cp 3 ; Gold PIT' in b1 and
       'ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]' in b1 and 'jr nz, .blocked\n.checkSprites' in b1,
       'boulder push must check target terrain and reject filled PITs')
    ck('callba CheckForBoulderCollisionWithSprites' in b1 and 'jr c, .blocked' in b1 and
       'scf\n\tsbc a ; A=$ff, carry=1' in engine and 'xor a ; A=0, carry=0' in engine,
       'bank3 -> ROMX sprite collision carry ABI broken or bank3 byte count increased')
    ck('cp 3 ; PIT: Gold B1F has exactly four' in b1 and 'jp z, .allow' in b1.split('cp 3 ; PIT: Gold B1F has exactly four')[1].split('cp 4 ; LADDER')[0],
       'player PIT must enter the registered Gold one-way fall')
    ck('jp JohtoIcePathB2FMahoganySyncLanded369B' in b2 and
       'JohtoIcePathB2FMahoganySyncLanded369B::' in b2,
       'B2F arrival-only rocks must be hidden until source PIT is filled')
    for i,(x,y) in enumerate(landed,1):
        ck(bool(re.search(rf'(?m)^\s*object\s+SPRITE_BOULDER,\s*{x},\s*{y},\s*STAY,\s*NONE,\s*\${i}\s*$',b2)),
           f'Gold B2F deposited static stone {i} missing or move-enabled')
        ck(f'bit {i+1}, a' in b2 and f'ld [wSpriteStateData1 + ${i*16:02x}], a' not in b2 and
           f'ld [wSpriteStateData2 + ${i*16+4:02x}], a' in b2 and
           f'ld [wSpriteStateData2 + ${i*16+5:02x}], a' in b2,
           f'B2F deposited stone {i} visibility is not gated by hole state')
    ck(len(re.findall(r'(?m)^\s*dw JohtoIcePathB2FMahoganyStoneText369A',b2))==4 and
       'db "@"' in b2.split('JohtoIcePathB2FMahoganyStoneText369A:')[1].split('JohtoIcePathB2FMahoganyObjects368A::')[0],
       'lower boulder text IDs have invalid or out-of-table pointers')
    ck('db 4, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR' in b2 and
       'db 12, 12, 5, JOHTO_REGISTERED_WARP_SELECTOR' in b2 and
       '.icePathB2FMahoganyWarp369S' in read('engine/johto_pilot_runtime.asm'),
       'Gold B2F PIT arrival coordinates must be real but never reverse-trigger')
    ck('ld a, GSSFX_BURNED_TOWER_STRENGTH' in b1 and 'ld a, SFX_STRENGTH' not in b1,
       'Gold Strength sound constant must exist in the current sound table')
    ck(any(f'db "{v}"' in read('data/game_version.asm') for v in ('REF-369B@', 'REF-369C@', 'REF-369D@', 'REF-369E@', 'REF-369F@', 'REF-369G@', 'REF-369H@', 'REF-369I@', 'REF-369@')),
       'REF-369B/369C WIP development label missing')
    return problems


def main() -> int:
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    args=parser.parse_args()
    errs=audit(args.root)
    for e in errs: print('FAIL:',e)
    if not errs: print('PASS: four original Gold movable stones, four saved drops, one-way player PIT receivers, no extra BANK0/BANK3 bytes')
    return bool(errs)

if __name__=='__main__': raise SystemExit(main())
