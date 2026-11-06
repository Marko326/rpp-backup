#!/usr/bin/env python3
"""REF-336 fail-closed four-center Gold source and runtime contract.

Static-only. Preserves all original active rows, center DOWN carpets, Gold
entry collision, correct per-center return warp, and original Fly unlock policy.
Overrides allow targeted negative fault-injection tests without editing ROM.
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

# nm, center-stable-symbol, source-city-symbol, id, appended-slot,
# original Gold door warp number, exterior source ordinal, x,y, landmark, Fly row.
CENTERS=(
    ('Ecruteak','ECRUTEAK','ECRUTEAK_CITY',160,52,6,4,23,27,21,5),
    ('Olivine','OLIVINE','OLIVINE_CITY',30,53,1,0,13,21,26,6),
    ('Cianwood','CIANWOOD','CIANWOOD_CITY',42,54,3,0,23,43,31,8),
    ('Mahogany','MAHOGANY','MAHOGANY_TOWN',77,55,4,1,15,13,34,7),
)


def audit(root: Path, gold_root: Path|None=None, overrides:dict|None=None)->dict:
    root=Path(root); overrides=overrides or {};checks=[];errors=[]
    def read(rel,binary=False):
        value=overrides.get(rel)
        if value is None:value=(root/rel).read_bytes()
        elif isinstance(value,str):value=value.encode('utf8')
        return value if binary else value.decode('utf8')
    def ck(name,good):
        checks.append({'check':name,'status':'PASS' if good else 'FAIL'})
        if not good:errors.append(name)
    try:
        constants=read('constants/region_map_constants.asm')
        fixed=read('constants/johto_fixed_map_ids.asm')
        slots=read('data/johto_stable_id_slots.asm')
        headers=read('data/johto_header_descriptors.asm')
        assets=read('data/johto_pilot_runtime_assets.asm')
        source=read('data/johto_pilot_source_resources.asm')
        room=read('engine/johto_shared_pokecenter.asm')
        rt=read('engine/johto_pilot_runtime.asm')
        heal=read('engine/johto_gold_healing_machine_337.asm')
        fly=read('engine/johto_pilot_fly_map.asm')
        maps=read('engine/fly_town_map_helpers.asm')
        music=read('engine/menu/options_menu.asm')
        version=read('data/game_version.asm')
        bounds=read('data/johto_vertical_gate_runtime_314.asm')
        ecruteak_map=read('data/johto_corridor_runtime_294.asm')
        mahogany_map=read('data/johto_east_runtime_300.asm')
        rootblk=read('maps/johto_pilot/CherrygrovePokecenter1F.gold.blk',True)
        rootrun=read('maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',True)
        routes=rt.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        before=rt.split('JohtoBatchCenterDoorBeforeStep336::',1)[1].split('JohtoBatchCenterDoorAfterStep336::',1)[0]
        after=rt.split('JohtoBatchCenterDoorAfterStep336::',1)[1]
        guard=room.split('JohtoSharedCenterDownCollision336::',1)[1].split('SetLastBlackoutMapRegional::',1)[0]
        writer=heal.split('AnimateHealingMachineRegional337::',1)[1].split('.johto',1)[0]
        ck('current_game_version_REF338_shared_by_all_builds',
           'GameVersionText::' in version and 'db "REF-349@"' in version)
        ck('frozen_57_maps_and_no_extra_fly_stops',
           'NUM_JOHTO_ACTIVE_MAPS EQU 64' in constants and
           'DEF JOHTO_FLY_TOWN_COUNT EQU 11' in fly and
           'call .isUnlocked\n    jr z, .startRestore' in fly and
           'JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID' not in fly)
        rows=re.findall(r'(?m)^\s*db MAP_REGION_JOHTO, JOHTO_\w+_LOCAL_ID, \d+, MAP_REGION_JOHTO, JOHTO_\w+_LOCAL_ID',routes)
        ck('exact_134_registered_warps',len(rows)==164 and all(any(line.strip()==r for line in rows) for r in (
            'db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID')))
        ck('identical_gold_5x4_template_and_10_nurses',
           len(rootblk)==len(rootrun)==20 and
           room.count('object SPRITE_NURSE, $3, $1, STAY, DOWN, $1')==10 and
           room.count('db JOHTO_POKECENTER')==10)
        # RGBASM's @ advances with every INCBIN. An ASSERT separated from
        # its resource accidentally measures *all* intervening center blobs.
        # This caught the REF-336 Goldenrod assertion that spanned five maps.
        center_names=('Cherrygrove','Route32','Azalea','Violet','Goldenrod',
                      'Mahogany','Cianwood','Olivine','Ecruteak','Blackthorn')
        ck('all_ten_gold_center_size_asserts_immediately_follow_own_blob',
           all(len(read(f'maps/johto_pilot/{nm}Pokecenter1F.gold.blk',True))==20 and
               len(re.findall(
                   rf'(?m)^Johto{nm}PokecenterGoldBlocks::[ \t]*(?:\n[ \t]*)?'
                   rf'INCBIN "maps/johto_pilot/{nm}Pokecenter1F\.gold\.blk"[ \t]*\n'
                   rf'ASSERT @ - Johto{nm}PokecenterGoldBlocks == 5 \* 4[ \t]*$',
                   source))==1 for nm in center_names))
        ck('all_center_exit_maps_must_be_down_on_two_gold_carpets',
           'cp PLAYER_DIR_DOWN' in guard and 'cp 7' in guard and
           'cp 3' in guard and 'cp 4' in guard and
           'ld e, 1' in guard and
           'ASSERT JohtoVerticalGateBoundsProfilesEnd314 - JohtoVerticalGateBoundsProfiles314 == 40' in bounds)
        # The third byte in each outdoor map's runtime warp event is the
        # destination warp ID inside the target center. It is NOT the source
        # ordinal used by JohtoRegisteredWarpRoutes. Both centers must arrive
        # on target warp 0 (left carpet); source ordinals remain Ecruteak=4
        # and Mahogany=1 in the registered route table below.
        ck('ecruteak_entry_targets_left_center_carpet_warp_zero',
           bool(re.search(r'JohtoEcruteakRuntimeObjects::\s+db \$05\s+db 6[^\n]*\n\s+db 18, 0, 2, JOHTO_REGISTERED_WARP_SELECTOR\s+db 19, 0, 3, JOHTO_REGISTERED_WARP_SELECTOR\s+db 26, 35, 0, JOHTO_REGISTERED_WARP_SELECTOR\s+db 27, 35, 1, JOHTO_REGISTERED_WARP_SELECTOR\s+db 27, 23, 0, JOHTO_REGISTERED_WARP_SELECTOR',ecruteak_map)))
        ck('mahogany_entry_targets_left_center_carpet_warp_zero',
           bool(re.search(r'JohtoMahoganyRuntimeObjects::\s+db \$71[^\n]*\n\s+db 2[^\n]*\n\s+db 1, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR[^\n]*\n\s+db 13, 15, 0, JOHTO_REGISTERED_WARP_SELECTOR',mahogany_map)))
        ck('all_four_new_outdoor_door_paths_wired',
           'call JohtoBatchCenterDoorBeforeStep336' in rt and
           'call JohtoBatchCenterDoorAfterStep336' in rt and
           all('cp PLAYER_DIR_UP' in s and 'ld e, '+v in s for s,v in ((before,'1'),(after,'2'))))
        ck('nurse_records_real_local_id_after_success',
           'call WaitForSongToFinish' in heal and
           'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a' in heal and
           'ld [wJohtoLastHealMagic], a' in heal and
           'JOHTO_LAST_HEAL_MAGIC' in heal)
        ck('old_five_ids_and_legacy_gatehouse_preserved',all('cp JOHTO_'+id_+'_POKECENTER_1F_LOCAL_ID' in guard for id_ in
               ('CHERRYGROVE','ROUTE_32','AZALEA','VIOLET','GOLDENROD')) and
           'db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID' in routes and
           'db MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID' in routes)
        for nm,up,town,stable,slot,goldno,ordinal,x,y,landmark,flyrow in CENTERS:
            label='JOHTO_'+up+'_POKECENTER_1F_LOCAL_ID';city='JOHTO_'+town+'_LOCAL_ID'
            asset=read('maps/johto_pilot/'+nm+'Pokecenter1F.gold.blk',True)
            runasset=read('maps/johto_pilot/'+nm+'Pokecenter1F.runtime.blk',True)
            ck(nm+'_unique_gold_source_and_stable_slot',
               f'JOHTO_{up}_POKECENTER_1F_LOCAL_ID EQU {stable}' in fixed+constants or f'JOHTO_{up}_POKECENTER_1F_LOCAL_ID EQU ${stable:02x}' in fixed+constants or
               f'ASSERT {label} == {stable}' in room)
            ck(nm+'_room_resource_header_nurse',
               asset==rootblk and runasset==rootrun and
               f'Johto{nm}PokecenterGoldBlocks:: INCBIN "maps/johto_pilot/{nm}Pokecenter1F.gold.blk"' in source and
               f'dw Johto{nm}PokecenterRuntimeHeader' in headers and
               f'db {label}, JOHTO_POKECENTER, 5, 4' in assets and
               re.search(r'Johto'+nm+r'PokecenterRuntimeObjects::\s+db \$0f\s+db 2\s+db 7, 3, '+str(ordinal)+
                         r', JOHTO_REGISTERED_WARP_SELECTOR\s+db 7, 4, '+str(ordinal)+
                         r', JOHTO_REGISTERED_WARP_SELECTOR\s+db 0[^\n]*\s+db 1\s+object SPRITE_NURSE',room) is not None)
            ck(nm+'_independent_bidirectional_gold_warps',all(routes.count(z)==1 for z in (
               f'db MAP_REGION_JOHTO, {city}, {ordinal}, MAP_REGION_JOHTO, {label}',
               f'db MAP_REGION_JOHTO, {label}, 0, MAP_REGION_JOHTO, {city}',
               f'db MAP_REGION_JOHTO, {label}, 1, MAP_REGION_JOHTO, {city}')))
            ck(nm+'_only_up_exact_exterior_door',
               f'cp {city}\n    jp z, .{nm.lower()}' in before and
               f'cp {city}\n    jp z, .{nm.lower()}' in after and
               f'.{nm.lower()}\n    ld a, [wXCoord]\n    cp {x}\n    ret nz\n    ld a, [wYCoord]\n    cp {y+1}\n    jr z, .allow' in before and
               f'.{nm.lower()}\n    ld a, [wXCoord]\n    cp {x}\n    ret nz\n    ld a, [wYCoord]\n    cp {y}\n    jr z, .allow' in after)
            ck(nm+'_healing_and_bounds_and_fly_mapping',
               f'cp {label}\n    jr z, .johto' in heal and
               f'cp {label}\n' in guard and
               f'cp {label}\n    jp z, .centerCarpetExit' in rt and
               f'db {label}, 10, 8' in bounds and
               f'.{nm.lower()}Heal\n    ld e, {landmark}' in rt and
               f'cp {label}\n    jp z, .start{nm}' in fly and
               f'.start{nm}\n    ld a, {flyrow} ; existing {nm} Fly row' in fly and
               f'johto_map_profile 0, {landmark}, MUSIC_POKECENTER, 0 ; slot{slot}' in rt and
               f'db {landmark} ; slot{slot} {nm} Center' in maps and
               f'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot{slot} {nm} Center' in music)
        if gold_root:
            idx=GoldCollisionIndex(Path(gold_root))
            for nm,up,town,stable,slot,goldno,ordinal,x,y,landmark,flyrow in CENTERS:
                city=nm+'Town' if nm=='Mahogany' else nm+'City'
                cityw=_gold_warp_events(Path(gold_root),city)
                centerw=_gold_warp_events(Path(gold_root),nm+'Pokecenter1F')
                door=[w for w in cityw if w['warp_number']==goldno and w['x']==x and w['y']==y and w['destination'].endswith('POKECENTER_1F')]
                if nm=='Ecruteak':
                    runtime_target=re.search(r'(?m)^\s*db 27, 23, (\d+), JOHTO_REGISTERED_WARP_SELECTOR',ecruteak_map)
                elif nm=='Mahogany':
                    runtime_target=re.search(r'(?m)^\s*db 13, 15, (\d+), JOHTO_REGISTERED_WARP_SELECTOR',mahogany_map)
                else:
                    runtime_target=None
                gold_arrival_id=(door[0]['destination_warp_number']-1) if len(door)==1 else None
                ck(nm+'_Gold_original_door_Warp_and_carpets',
                   idx.role_at(city,x,y)=='DOOR' and len(door)==1 and
                   len(centerw)==3 and all(w['x'] in (3,4) and w['y']==7 and
                     w['destination_warp_number']==goldno for w in centerw[:2]) and
                   all(idx.role_at(nm+'Pokecenter1F',x_,7)=='WARP_CARPET_DOWN' for x_ in (3,4)))
                if runtime_target is not None:
                    ck(nm+'_runtime_arrival_id_matches_Gold_destination_warp',
                       gold_arrival_id is not None and int(runtime_target.group(1))==gold_arrival_id)
    except (OSError,KeyError,IndexError,ValueError,TypeError) as exc:
        errors.append('input_error: '+repr(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,
            'rom_built':False,'phone_accepted':False}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,default=Path('.'))
    p.add_argument('--gold-root',type=Path);a=p.parse_args()
    result=audit(a.project,a.gold_root)
    print(json.dumps(result,ensure_ascii=False,indent=2));raise SystemExit(bool(result['errors']))
