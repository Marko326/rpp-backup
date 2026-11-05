#!/usr/bin/env python3
"""REF-348 Burned Tower static spatial/warp/activation contract (no RGBDS build).

The Gold warp XY values are frozen independently of the RPP object records
(Y,X).  Source maps may optionally be supplied via --gold for additional
cross-checking; the locked byte-role grids remain the primary local proof.
"""
import argparse
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GOLD_1F = [(9,15),(10,15), (5,4),(5,5),(5,6),(4,6),(15,4),(15,5),
           (10,7),(5,14),(4,14),(14,14),(15,14), (7,15)]
GOLD_B1F = [(3,3),(17,7),(10,8),(3,13),(17,14),(7,15)]
GOLD_TARGETS_1F = [5,5,0,0,0,0,1,1,2,3,3,4,4,5]
GOLD_TARGETS_B1F = [2,6,8,9,11,13]


def require(ok, what):
    if not ok:
        raise AssertionError(what)


def get_records(code, symbol, count):
    body = code.split(symbol+':',1)[1].split('; Role IDs',1)[0] if symbol=='JohtoBurnedTowerB1FRuntimeObjects' else code.split(symbol+'::',1)[1].split('    db 0 ; no signs',1)[0]
    found=[]
    for line in body.splitlines():
        m=re.search(r'^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR',line)
        if m: found.append(tuple(map(int,m.groups())))
    require(len(found)==count,f'{symbol} record cardinality: {len(found)} != {count}')
    return found


def audit(root=ROOT, gold=None):
    read=lambda name:(root/name).read_text()
    one=read('data/johto_burned_tower/REF347_1f_runtime.asm')
    below=read('data/johto_burned_tower/REF348_b1f_runtime.asm')
    rec1=get_records(one,'JohtoBurnedTower1FRuntimeObjects',14)
    recb=get_records(below,'JohtoBurnedTowerB1FRuntimeObjects',6)
    require([(x,y) for y,x,_ in rec1]==GOLD_1F,'1F Gold XY warp order / YX conversion')
    require([dest for _,_,dest in rec1]==GOLD_TARGETS_1F,'1F destination ordinal semantics')
    require([(x,y) for y,x,_ in recb]==GOLD_B1F,'B1F Gold XY landing order / YX conversion')
    require([dest for _,_,dest in recb]==GOLD_TARGETS_B1F,'B1F Gold destination ordinal semantics')
    r1=(root/'maps/johto_pilot/BurnedTower1F.gold_roles.bin').read_bytes()
    rb=(root/'maps/johto_pilot/BurnedTowerB1F.gold_roles.bin').read_bytes()
    require(len(r1)==len(rb)==360,'Gold roles grid width/height')
    role=lambda b,xy: b[xy[1]*20+xy[0]]
    require(all(role(r1,xy)==2 for xy in GOLD_1F[2:13]),'11 PIT role positions')
    require(role(r1,GOLD_1F[13])==1,'1F ladder')
    require(all(role(r1,xy)==4 for xy in GOLD_1F[:2]),'two directional carpets')
    require(role(rb,GOLD_B1F[5])==5,'B1F ladder')
    require(Counter(rb)[6]==26,'B1F Gold UP_WALL count')
    # Trigger grid must reflect the same 12 (Y,X) pairs, never be hardcoded from
    # a copied cave; traps and the real ladder share step-in semantics.
    code=below.split('.OneFStepInWarpCells\n',1)[-1].split('; Gold FallIntoMapScript',1)[0]
    numbers=[int(n) for n in re.findall(r'\b\d+\b', '\n'.join(x.split(';')[0] for x in code.splitlines() if x.strip().startswith('db ')))]
    pairs=list(zip(numbers[::2],numbers[1::2]))
    require(pairs==[(y,x) for x,y in GOLD_1F[2:]],'step-in PIT/ladder dispatch table')
    runtime=read('engine/johto_pilot_runtime.asm')
    route=runtime.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
    for ordinal in range(2,14):
        require(f'JOHTO_BURNED_TOWER_1F_LOCAL_ID, {ordinal}, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_B1F_LOCAL_ID' in route, f'missing 1F route {ordinal}')
    require('JOHTO_BURNED_TOWER_B1F_LOCAL_ID, 5, MAP_REGION_JOHTO, JOHTO_BURNED_TOWER_1F_LOCAL_ID' in route,'missing B1F ladder reverse route')
    for ordinal in range(5):
        require(f'JOHTO_BURNED_TOWER_B1F_LOCAL_ID, {ordinal}, MAP_REGION_JOHTO' not in route, f'B1F arrival {ordinal} improperly active')
    require('callab JohtoPilotResolveWarpDestination' not in below.split('JohtoBurnedTowerMaybeFallWarp::',1)[1].split('JohtoEnterMapAnimationDispatcher::',1)[0], 'fall helper resolves destination twice')
    require('set 7, [hl]' in below and 'callab JohtoBurnedTowerMaybeFallWarp' in read('home/overworld.asm'), 'fall flag and call chain')
    require('callba CheckForCollisionWhenPushingBoulderLegacy' in below and 'callab JohtoBurnedTowerB1FCheckForCollisionWhenPushingBoulder' in read('engine/overworld/player_state.asm'), 'reuse Strength collision entry')
    require('xor $fe' in below and 'ld [hSCY], a' in below, 'reuse elevator SCY shaking waveform')
    require('INCLUDE "data/johto_burned_tower/REF348_b1f_runtime.asm"' in read('main.asm'), 'B1F runtime included')
    require('DEF NUM_JOHTO_ACTIVE_MAPS EQU 63' in read('constants/region_map_constants.asm'), '63 active maps')
    for name in ('data/johto_pilot_runtime_assets.asm','data/johto_stable_id_slots.asm'):
        require('ASSERT NUM_JOHTO_ACTIVE_MAPS == 63' in read(name),f'{name} stale cardinality')
    # Compile-blocking contracts must cover all new dense active slots.
    fly=read('engine/fly_town_map_helpers.asm')
    town=fly.split('JohtoPilotTownMapEntries::',1)[1].split('JohtoPilotTownMapEntriesEnd::',1)[0]
    require(len(re.findall(r'^\s*dw\s+\w+',town,re.M))==63,'63 Town Map coordinate/name entries')
    browse=fly.split('JohtoPilotTownMapBrowseIndexBySlot:',1)[1].split('JohtoPilotTownMapBrowseIndexBySlotEnd:',1)[0]
    bvalues=[int(v) for v in re.findall(r'\d+', '\n'.join(line.split(';',1)[0] for line in browse.splitlines()))]
    require(len(bvalues)==63 and bvalues[-1]==21,'63 Town Map browse indices; B1F Ecruteak')
    music=read('engine/menu/options_menu.asm').split('JohtoActiveGSCMusic::',1)[1].split('JohtoActiveGSCMusicEnd::',1)[0]
    music_entries=re.findall(r'^\s*db\s+(MUSIC_GBP_GSC_\w+)',music,re.M)
    require(len(music_entries)==63 and music_entries[-1]=='MUSIC_GBP_GSC_BURNED_TOWER','63 music entries; B1F Burned Tower')
    require('== 65 * 16' in below,'B1F graphics must account for 31 trimmed blank tiles')
    require('db "REF-348@"' in read('data/game_version.asm'), 'ROM version tag')
    require('JOHTO_BURNED_TOWER_B1F + 1' in read('color/data/map_palette_assignments.asm'), 'B1F palette assignments')
    require('JOHTO_BURNED_TOWER_B1F + 1' in read('color/data/map_palette_sets.asm'), 'B1F palette set')
    require('JOHTO_BURNED_TOWER_B1F + 1' in read('data/warp_tile_ids.asm'), 'B1F warp pointer')
    require('JohtoBurnedTowerB1F_Coll::' in read('home.asm'), 'B1F ROM0 collision tiles')
    require('JOHTO_BURNED_TOWER_B1F_LOCAL_ID\n\tjp z, .johtoBurnedTower' in read('engine/overworld/map_name_sign.asm'), 'B1F location name')
    hoptext=read('engine/overworld/ledges.asm').split('JohtoBurnedTowerB1FGoldHops:',1)[1].split('JohtoRoute33Hops:',1)[0]
    hops=[(int(x),int(y)) for x,y in re.findall(r'db\s*(\d+),\s*(\d+),\s*PLAYER_DIR_',hoptext)]
    require(len(hops)==30 and all(role(rb,xy) in (1,2,3,4) for xy in hops),'30 Gold hop direction sources')
    if gold:
        for filename, expected in [('BurnedTower1F.asm',GOLD_1F),('BurnedTowerB1F.asm',GOLD_B1F)]:
            script=(gold/filename).read_text()
            event_text=script.split('def_warp_events',1)[1].split('def_coord_events',1)[0]
            coords=[tuple(map(int,m.groups())) for m in re.finditer(r'^\s*warp_event\s+(\d+),\s*(\d+),', event_text,re.M)]
            require(coords==expected,f'{filename} Gold source warp coordinates')
    return 'REF348 audit PASS: 11 PIT, 5 arrival-only, 2 ladders, Strength, 30 hops, tilesets, 63-map registry'

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=ROOT);p.add_argument('--gold',type=Path)
    a=p.parse_args();print(audit(a.root,a.gold))
