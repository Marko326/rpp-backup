#!/usr/bin/env python3
"""REF-335 fail-closed, static, Gold-backed audit: Violet + Goldenrod centers.

Read-only. No ROM assembly/linking/emulator claims. Optional Gold reference
confirms original warp coordinates and collision roles.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
try:
    from johto_gold_door_audit import GoldCollisionIndex
    from johto_warp_arrival_audit import _gold_warp_events
except ImportError:
    from tools.johto_gold_door_audit import GoldCollisionIndex
    from tools.johto_warp_arrival_audit import _gold_warp_events

CENTERS = (
    ('Violet', 'VIOLET', 'VIOLET_CITY', 133, 50, 31, 25, 5, 2, 5, 2),
    ('Goldenrod', 'GOLDENROD', 'GOLDENROD_CITY', 146, 51, 15, 27, 7, 1, 15, 4),
)

def audit(root: Path, gold_root: Path | None = None, overrides: dict | None = None) -> dict:
    root=Path(root); overrides=overrides or {}; checks=[]; errors=[]
    def read(p, binary=False):
        data=overrides.get(p)
        if data is None: data=(root/p).read_bytes()
        if isinstance(data,str):data=data.encode()
        return data if binary else data.decode()
    def ck(name,ok):
        checks.append({'check':name,'status':'PASS' if ok else 'FAIL'})
        if not ok:errors.append(name)
    try:
        const=read('constants/region_map_constants.asm')
        stable=read('data/johto_stable_id_slots.asm')
        r=read('engine/johto_pilot_runtime.asm')
        room=read('engine/johto_shared_pokecenter.asm')
        header=read('data/johto_header_descriptors.asm')
        src=read('data/johto_pilot_source_resources.asm')
        assets=read('data/johto_pilot_runtime_assets.asm')
        fly=read('engine/johto_pilot_fly_map.asm')
        names=read('engine/fly_town_map_helpers.asm')
        gate=read('engine/johto_south_portals.asm')
        geo=read('engine/johto_south_geometry.asm')
        violet=read('data/johto_pilot_map_headers.asm')
        south=read('data/johto_south_runtime.asm')
        heal=read('engine/johto_gold_healing_machine_337.asm')
        music=read('engine/menu/options_menu.asm')
        bound=read('data/johto_vertical_gate_runtime_314.asm')
        ck('new_52_maps_and_119_warps', 'NUM_JOHTO_ACTIVE_MAPS EQU 64' in const and
           len(re.findall(r'(?m)^\s*db MAP_REGION_JOHTO, JOHTO_\w+_LOCAL_ID, \d+, MAP_REGION_JOHTO, JOHTO_\w+_LOCAL_ID',r.split('JohtoRegisteredWarpRoutes::')[1].split('JohtoRegisteredWarpRoutesEnd::')[0])) ==164)
        ck('independent_stable_ids_slots_and_headers', all(
            f'ASSERT JOHTO_{up}_POKECENTER_1F_LOCAL_ID == {sid}' in room and
            f'dw Johto{nm}PokecenterRuntimeHeader' in header and
            f'db BANK(Johto{nm}PokecenterRuntimeHeader)' in header and
            f'db JOHTO_{up}_POKECENTER_1F_LOCAL_ID, JOHTO_POKECENTER, 5, 4' in assets
            for nm,up,_,sid,slot,*_ in CENTERS) and
            '$80-$8f (Violet Center ID133 slot50' in stable and '$90-$9f (Goldenrod Center ID146 slot51)' in stable)
        ck('same_gold_5x4_room_no_2f',all(
            read(f'maps/johto_pilot/{nm}Pokecenter1F.gold.blk',True)==read('maps/johto_pilot/CherrygrovePokecenter1F.gold.blk',True) and
            read(f'maps/johto_pilot/{nm}Pokecenter1F.runtime.blk',True)==read('maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',True) and
            f'Johto{nm}PokecenterGoldBlocks:: INCBIN "maps/johto_pilot/{nm}Pokecenter1F.gold.blk"' in src
            for nm,*_ in CENTERS))
        ck('two_independent_nurse_objects',room.count('object SPRITE_NURSE, $3, $1, STAY, DOWN, $1')==10 and
           all(bool(re.search(r'Johto'+nm+r'PokecenterRuntimeObjects::\s+db \$0f\s+db 2\s+db 7, 3, '+str(ord)+r', JOHTO_REGISTERED_WARP_SELECTOR\s+db 7, 4, '+str(ord)+r', JOHTO_REGISTERED_WARP_SELECTOR\s+db 0.*?\s+db 1\s+object SPRITE_NURSE',room,re.S)) for nm,_,_,_,_,_,_,_,ord,_,_ in CENTERS))
        routes=r.split('JohtoRegisteredWarpRoutes::')[1].split('JohtoRegisteredWarpRoutesEnd::')[0]
        ck('six_exact_reciprocal_warps',all(all(routes.count(row)==1 for row in (
            f'db MAP_REGION_JOHTO, JOHTO_{town}_LOCAL_ID, {ord}, MAP_REGION_JOHTO, JOHTO_{up}_POKECENTER_1F_LOCAL_ID',
            f'db MAP_REGION_JOHTO, JOHTO_{up}_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_{town}_LOCAL_ID',
            f'db MAP_REGION_JOHTO, JOHTO_{up}_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_{town}_LOCAL_ID'))
            for nm,up,town,sid,slot,x,y,gold_number,ord,*_ in CENTERS))
        # Both route-34/Ilex south gate and Goldenrod/route-35 north gate
        # predate REF-335. Their four indoor routes each must remain intact.
        ck('goldenrod_two_existing_gatehouses_preserved', all(
            routes.count(f'db MAP_REGION_JOHTO, {gateid}, {ordinal}, MAP_REGION_JOHTO, {dest}')==1
            for gateid, destinations in (
                ('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID', ('JOHTO_ROUTE_34_LOCAL_ID','JOHTO_ROUTE_34_LOCAL_ID','JOHTO_ILEX_FOREST_LOCAL_ID','JOHTO_ILEX_FOREST_LOCAL_ID')),
                ('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID', ('JOHTO_ROUTE_35_LOCAL_ID','JOHTO_ROUTE_35_LOCAL_ID','JOHTO_GOLDENROD_CITY_LOCAL_ID','JOHTO_GOLDENROD_CITY_LOCAL_ID')),
            ) for ordinal,dest in enumerate(destinations)) and
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID' in routes and
            'db MAP_REGION_JOHTO, JOHTO_GOLDENROD_CITY_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID' in routes)
        ck('gold_exterior_objects',
            'db 25, 31, 0, JOHTO_REGISTERED_WARP_SELECTOR' in violet and
            'db 27, 15, 0, JOHTO_REGISTERED_WARP_SELECTOR' in south and
            'db 1, 19, 2, JOHTO_REGISTERED_WARP_SELECTOR' in south)
        ck('violet_up_only_and_north_gate_preserved', all(t in r for t in (
            '.violetCenterBefore', '.violetCenterMatched', 'cp JOHTO_VIOLET_CITY_LOCAL_ID',
            'cp PLAYER_DIR_UP', 'cp 31','cp 25','cp 26')) and
            'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID' in r)
        ck('goldenrod_up_only_and_north_gate_preserved', all(t in gate for t in (
            '.goldenrodCenter', '.goldenrodCenterArrival', 'cp PLAYER_DIR_UP',
            'cp 15','cp 27','cp 28', '.northGate', '.cityDoor')) and
            '.cityDoor\n    ld a, [wXCoord]\n    cp 15\n    jr z, .goldenrodCenterArrival' in gate and
            '.goldenrodCenterArrival\n    ld a, [wYCoord]\n    cp 27\n    jp z, .south' in gate and
            '.goldenrodCenter\n    ld a, [wYCoord]\n    cp 28\n    jp z, .allow' in gate and
            '.goldenrodCenter\n    ld a, [wYCoord]\n    cp 27\n    jp z, .door' in gate and
            'cp JOHTO_GOLDENROD_CITY_LOCAL_ID' in geo and
            'db JOHTO_GOLDENROD_CITY_LOCAL_ID, 15, 27' not in geo)
        guard=room.split('JohtoSharedCenterDownCollision336::')[1].split('SetLastBlackoutMapRegional::')[0]
        ck('shared_down_only_two_carpet_guard', all(f'cp JOHTO_{up}_POKECENTER_1F_LOCAL_ID' in guard for _,up,*_ in CENTERS) and
           all(t in guard for t in ('cp PLAYER_DIR_DOWN','cp 7','cp 3','cp 4')) and
           all(f'db JOHTO_{up}_POKECENTER_1F_LOCAL_ID, 10, 8' in bound for _,up,*_ in CENTERS))
        ck('success_stamps_correct_center', 'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a' in heal and
           all(f'cp JOHTO_{up}_POKECENTER_1F_LOCAL_ID' in heal and f'.{nm.lower()}Heal\n    ld e, {landmark}' in r for nm,up,_,sid,slot,x,y,gold_num,ord,landmark,flyrow in CENTERS))
        ck('fly_is_existing_town_only', 'DEF JOHTO_FLY_TOWN_COUNT EQU 11' in fly and
           all(f'cp JOHTO_{up}_POKECENTER_1F_LOCAL_ID' in fly and f'ld a, {flyrow} ; existing {nm} row' in fly for nm,up,_,sid,slot,x,y,gold_num,ord,landmark,flyrow in CENTERS) and
           'call .isUnlocked\n    jr z, .startRestore' in fly and
           'JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID' not in fly)
        ck('map_and_music_no_new_fly_landmark',all(
            f'johto_map_profile 0, {landmark}, MUSIC_POKECENTER, 0 ; slot{slot}' in r and
            f'db {landmark} ; slot{slot} {nm} Center' in names and
            f'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot{slot} {nm} Center' in music
            for nm,up,_,sid,slot,x,y,gold_num,ord,landmark,*_ in CENTERS))
        if gold_root:
            idx=GoldCollisionIndex(gold_root)
            for nm,up,town,sid,slot,x,y,gold_number,ord,landmark,flyrow in CENTERS:
                events=_gold_warp_events(Path(gold_root),nm+'City' if nm=='Violet' else 'GoldenrodCity')
                src_events=_gold_warp_events(Path(gold_root),nm+'Pokecenter1F')
                ck(nm.lower()+'_gold_source_warp_and_collision',
                   idx.role_at(nm+'City',x,y)=='DOOR' and
                   any(w['warp_number']==gold_number and w['x']==x and w['y']==y and w['destination'].endswith('POKECENTER_1F') for w in events) and
                   len(src_events)==3 and all(w['x'] in (3,4) and w['y']==7 and w['destination_warp_number']==gold_number for w in src_events[:2]) and
                   all(idx.role_at(nm+'Pokecenter1F',x_,7)=='WARP_CARPET_DOWN' for x_ in (3,4)))
    except (OSError,KeyError,ValueError,IndexError,TypeError) as e:
        errors.append('input_error: '+repr(e))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,'rom_built':False,'phone_accepted':False}

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=Path.cwd());ap.add_argument('--gold-root',type=Path)
    a=ap.parse_args(); result=audit(a.project,a.gold_root)
    print(json.dumps(result,ensure_ascii=False,indent=2));raise SystemExit(bool(result['errors']))
