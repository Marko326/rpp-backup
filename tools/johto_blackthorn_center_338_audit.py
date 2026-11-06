#!/usr/bin/env python3
"""REF-338 Blackthorn City Pokémon Center, source-only fail-closed audit.

Verifies both distinct warp indices (source event ordinal, destination carpet
index) and a strict Gold Gold-facing door/room contract. No ROM is assembled.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
try:
    from johto_gold_door_audit import GoldCollisionIndex
    from johto_warp_arrival_audit import _gold_warp_events
except ImportError:
    from tools.johto_gold_door_audit import GoldCollisionIndex
    from tools.johto_warp_arrival_audit import _gold_warp_events

CENTER='JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID'
CITY='JOHTO_BLACKTHORN_CITY_LOCAL_ID'

def audit(root:Path,gold_root:Path|None=None,overrides:dict|None=None)->dict:
    root=Path(root); overrides=overrides or {}; checks=[]; errors=[]
    def data(name, binary=False):
        v=overrides.get(name)
        if v is None: v=(root/name).read_bytes()
        elif isinstance(v,str): v=v.encode('utf8')
        return v if binary else v.decode('utf8')
    def ck(name,good):
        checks.append({'check':name,'status':'PASS' if good else 'FAIL'})
        if not good: errors.append(name)
    try:
        constants=data('constants/region_map_constants.asm')
        fixed=data('constants/johto_fixed_map_ids.asm')
        slots=data('data/johto_stable_id_slots.asm')
        descriptors=data('data/johto_header_descriptors.asm')
        assets=data('data/johto_pilot_runtime_assets.asm')
        source=data('data/johto_pilot_source_resources.asm')
        room=data('engine/johto_shared_pokecenter.asm')
        city=data('data/johto_blackthorn_runtime_326.asm')
        routes=data('engine/johto_pilot_runtime.asm')
        fly=data('engine/johto_pilot_fly_map.asm')
        mapdata=data('engine/fly_town_map_helpers.asm')
        heal=data('engine/johto_gold_healing_machine_337.asm')
        bounds=data('data/johto_vertical_gate_runtime_314.asm')
        music=data('engine/menu/options_menu.asm')
        version=data('data/game_version.asm')
        golden=data('maps/johto_pilot/BlackthornPokecenter1F.gold.blk',True)
        runtime=data('maps/johto_pilot/BlackthornPokecenter1F.runtime.blk',True)
        sample=data('maps/johto_pilot/CherrygrovePokecenter1F.gold.blk',True)
        sample_run=data('maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',True)
        routes_section=routes.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        down_section=room.split('JohtoSharedCenterDownCollision336::',1)[1].split('SetLastBlackoutMapRegional::',1)[0]
        before=routes.split('JohtoBatchCenterDoorBeforeStep336::',1)[1].split('JohtoBatchCenterDoorAfterStep336::',1)[0]
        after=routes.split('JohtoBatchCenterDoorAfterStep336::',1)[1]
        ck('version_only_REF338', 'db "REF-349@"' in version and 'GameVersionText::' in version)
        ck('stable_id85_appended_slot56_map57',
           f'DEF {CENTER} EQU 85' in fixed and
           'NUM_JOHTO_ACTIVE_MAPS EQU 64' in constants and
           bool(re.search(r'(?m)^\s*db .*\b56\b.*\$50-\$5f',slots)) and
           f'dw JohtoBlackthornPokecenterRuntimeHeader' in descriptors and
           f'db {CENTER}, JOHTO_POKECENTER, 5, 4' in assets and
           'NUM_JOHTO_ACTIVE_MAPS == 64' in assets)
        ck('gold_5x4_shared_layout_and_adjacent_size_assert',
           len(golden)==len(runtime)==20 and golden==sample and runtime==sample_run and
           bool(re.search(r'(?m)^JohtoBlackthornPokecenterGoldBlocks::\s*INCBIN "maps/johto_pilot/BlackthornPokecenter1F\.gold\.blk"\s*\nASSERT @ - JohtoBlackthornPokecenterGoldBlocks == 5 \* 4$',source)) and
           f'db MAP_REGION_JOHTO, {CENTER}, 5, 4' in source)
        ck('blackthorn_exterior_only_gold_door_destination_zero',
           bool(re.search(r'JohtoBlackthornRuntimeObjects::\s*db \$71[^\n]*\s*db 1[^\n]*\s*db 29, 21, 0, JOHTO_REGISTERED_WARP_SELECTOR[^\n]*\s*db 0[^\n]*\s*db 0',city)))
        ck('one_source_three_distinct_routes_and_134_total',
           all(routes_section.count(row)==1 for row in (
               f'db MAP_REGION_JOHTO, {CITY}, 0, MAP_REGION_JOHTO, {CENTER}',
               f'db MAP_REGION_JOHTO, {CENTER}, 0, MAP_REGION_JOHTO, {CITY}',
               f'db MAP_REGION_JOHTO, {CENTER}, 1, MAP_REGION_JOHTO, {CITY}')) and
           len(re.findall(r'(?m)^\s*db MAP_REGION_JOHTO, JOHTO_\w+_LOCAL_ID, \d+, MAP_REGION_JOHTO, JOHTO_\w+_LOCAL_ID',routes_section))==164)
        ck('two_gold_carpet_room_exits_and_nurse_no_upstairs',
           bool(re.search(r'JohtoBlackthornPokecenterRuntimeObjects::\s*db \$0f\s*db 2\s*db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR\s*db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR\s*db 0[^\n]*\s*db 1\s*object SPRITE_NURSE, \$3, \$1, STAY, DOWN, \$1',room)) and
           f'ASSERT {CENTER} == 85' in room)
        ck('door_before_step_only_from_below_up',
           f'cp {CITY}\n    jp z, .blackthorn' in before and
           '.blackthorn\n    ld a, [wXCoord]\n    cp 21\n    ret nz\n    ld a, [wYCoord]\n    cp 30\n    jr z, .allow' in before and
           'cp PLAYER_DIR_UP' in before)
        ck('door_after_step_uses_exact_21_29',
           f'cp {CITY}\n    jp z, .blackthorn' in after and
           '.blackthorn\n    ld a, [wXCoord]\n    cp 21\n    ret nz\n    ld a, [wYCoord]\n    cp 29\n    jr z, .allow' in after and
           'cp PLAYER_DIR_UP' in after)
        ck('carpet_exits_only_down_without_side_teleport',
           f'cp {CENTER}\n    ret nz' in down_section and
           'cp PLAYER_DIR_DOWN' in down_section and 'cp 7' in down_section and
           'cp 3' in down_section and 'cp 4' in down_section and
           f'db {CENTER}, 10, 8' in bounds)
        ck('healing_actual_center_id_and_landmark39',
           f'cp {CENTER}\n    jr z, .johto' in heal and
           'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a' in heal and
           f'cp {CENTER}\n    jp z, .blackthornHeal' in routes and
           '.blackthornHeal\n    ld e, 39' in routes)
        ck('town_map_music_and_fly_existing_row_only',
           'DEF JOHTO_FLY_TOWN_COUNT EQU 11' in fly and
           f'cp {CENTER}\n    jp z, .startBlackthorn' in fly and
           '.startBlackthorn\n    ld a, 10 ; existing Blackthorn City Fly row' in fly and
           'call .isUnlocked\n    jr z, .startRestore' in fly and
           'db 60, 140 ; slot56 Blackthorn Center' in mapdata and
           'db 39 ; slot56 Blackthorn Center' in mapdata and
           'johto_map_profile 0, 39, MUSIC_POKECENTER, 0 ; slot56 Blackthorn Center' in routes and
           'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot56 Blackthorn Center' in music)
        ck('older_nine_centers_preserved',
           room.count('object SPRITE_NURSE, $3, $1, STAY, DOWN, $1')==10 and
           room.count('db JOHTO_POKECENTER')==10 and
           f'cp {CENTER}\n' in down_section)
        if gold_root:
            gold_root=Path(gold_root)
            gold_city=_gold_warp_events(gold_root,'BlackthornCity')
            gold_center=_gold_warp_events(gold_root,'BlackthornPokecenter1F')
            idx=GoldCollisionIndex(gold_root)
            gold_doors=[w for w in gold_city if w['warp_number']==5 and w['x']==21 and w['y']==29 and w['destination']=='BLACKTHORN_POKECENTER_1F']
            ck('gold_exact_5th_door_dest_1_and_two_exit_return_5',
               len(gold_doors)==1 and gold_doors[0]['destination_warp_number']==1 and
               idx.role_at('BlackthornCity',21,29)=='DOOR' and
               len(gold_center)==3 and
               all(w['x']==3+i and w['y']==7 and w['destination']=='BLACKTHORN_CITY' and w['destination_warp_number']==5 and idx.role_at('BlackthornPokecenter1F',3+i,7)=='WARP_CARPET_DOWN' for i,w in enumerate(gold_center[:2])) and
               golden==(gold_root/'maps/Pokecenter1F.blk').read_bytes())
    except (OSError,IndexError,KeyError,TypeError,ValueError) as e:
        errors.append('input_error: '+repr(e))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,'rom_built':False,'phone_accepted':False}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,default=Path('.'));p.add_argument('--gold-root',type=Path)
    a=p.parse_args();r=audit(a.project,a.gold_root)
    print(json.dumps(r,ensure_ascii=False,indent=2));raise SystemExit(0 if not r['errors'] else 1)
