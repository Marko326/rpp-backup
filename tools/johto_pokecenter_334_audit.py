#!/usr/bin/env python3
"""DEV-334 static, fail-closed Cherrygrove Pokecenter admission review.

Independent of Red/Blue RGBDS linking, actual mobile behavior and save-game
migration. All comparisons target executable source, not comments.
"""
from __future__ import annotations
from pathlib import Path
import re, hashlib, json

def audit(root: Path) -> dict:
    root=Path(root)
    issues=[]; checks=[]
    def read(path):return (root/path).read_text(encoding='utf-8')
    def code(path):return '\n'.join(line.split(';',1)[0].rstrip() for line in read(path).splitlines())
    def verify(name, ok):
        checks.append({'check':name,'status':'PASS' if ok else 'FAIL'})
        if not ok:issues.append(name)
    try:
        room=code('engine/johto_shared_pokecenter.asm')
        land=code('engine/johto_land_collision_gateway_272.asm')
        runtime=code('engine/johto_pilot_runtime.asm')
        city=code('data/johto_pilot_map_headers.asm')
        slots=code('data/johto_stable_id_slots.asm')
        wram=code('wram.asm')
        old=code('engine/overworld/set_blackout_map.asm')
        home=code('home/overworld.asm')
        mapui=code('engine/town_map.asm')
        header=code('data/johto_header_descriptors.asm')
        assets=code('data/johto_pilot_runtime_assets.asm')
        names=code('engine/fly_town_map_helpers.asm')
        healed=code('engine/overworld/healing_machine.asm')
        gold=code('engine/johto_gold_healing_machine_337.asm')
        orig=room.split('SetLastBlackoutMapRegional::',1)[1]
        center=room.split('JohtoSharedPokecenterRuntimeObjects::',1)[1].split('JohtoRoute32PokecenterRuntimeObjects::',1)[0]
        routing=runtime.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        predicate=runtime.split('JohtoPilotGateDoorWarpMatched::',1)[1].split('JohtoPilotGateCollisionExitAllowed::',1)[0]
        land=land.split('JohtoOverworldSouthLandDecision::',1)[1].split('\n.southMaps\n',1)[0]
        verify('stable_slot_47', 'NUM_JOHTO_ACTIVE_MAPS EQU 64' in code('constants/region_map_constants.asm') and
               bool(re.search(r'\b47\s*,\s*JOHTO_INVALID_ACTIVE_SLOT\s*,\s*5\s*,',slots)) and
               'dw JohtoSharedPokecenterRuntimeHeader' in header and
               'db BANK(JohtoSharedPokecenterRuntimeHeader)' in header)
        verify('shared_gold_template',
               'INCBIN "maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk"' in room and
               '== JOHTO_SHARED_POKECENTER_WIDTH * JOHTO_SHARED_POKECENTER_HEIGHT' in room and
               'db JOHTO_POKECENTER' in room and 'JOHTO_POKECENTER, 5, 4' in assets and
               len((root/'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk').read_bytes())==20)
        verify('nurse_shared_healing', 'TX_POKECENTER_NURSE' in room and
               'object SPRITE_NURSE, $3, $1, STAY, DOWN, $1' in center and
               'db 2\n    db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR\n    db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR' in center and
               'db 0\n    db 1' in center)
        verify('city_two_independent_doors',
               'db 9, 25, 0, JOHTO_REGISTERED_WARP_SELECTOR' in city and
               'db 3, 29, 0, JOHTO_REGISTERED_WARP_SELECTOR' in city and
               'db 2\n    db 9, 25, 0' in city)
        verify('three_exact_registered_warps',
               all(routing.count(row)==1 for row in (
                'db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID',
                'db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID',
                'db MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID')))
        verify('land_exact_up_approach',all(t in land for t in (
               'cp JOHTO_CHERRYGROVE_LOCAL_ID','cp PLAYER_DIR_UP','cp 25','cp 10',
               'cp 29','cp 4','.cherryGuideApproach')) and land.count('ld e, 0')>=3)
        verify('warp_actual_immediate_entry',all(t in predicate for t in (
               'cp JOHTO_CHERRYGROVE_LOCAL_ID','jp z, .cherrygroveGoldDoor',
               '.cherrygroveGoldDoor','cp PLAYER_DIR_UP','cp 9','cp 25',
               'cp 3','cp 29')) and
               bool(re.search(r'\.allowCherry\s+ld e,\s*2\s+ret', predicate)) and
               all(t in home for t in ('callab JohtoPilotGateDoorWarpMatched',
               'cp 2','jp WarpFound1')))
        gold_entry=gold.split('AnimateHealingMachineRegional337::',1)[1].split('\n.johto\n',1)[0]
        gold_success=gold.split('\n.johto\n',1)[1].split('\n.copyOne\n',1)[0]
        verify('healing_only_after_yes_animation',
               'callab JohtoRecordSuccessfulCenterHeal335' not in healed and
               'JohtoRecordSuccessfulCenterHeal335::' not in room and
               'callba AnimateHealingMachineRegional337' in code('engine/overworld/pokecenter.asm') and
               'jr nz, .declinedHealing' in code('engine/overworld/pokecenter.asm') and
               'ret z' in orig.split('.kanto',1)[0] and
               'cp JOHTO_RUNTIME_MAP_HANDLE' in gold_entry and
               'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID' in gold_entry and
               'call WaitForSongToFinish' in gold_success and
               gold_success.find('ld [wJohtoLastHealLocalID], a') > gold_success.find('call WaitForSongToFinish') and
               'ld a, JOHTO_LAST_HEAL_MAGIC\n    ld [wJohtoLastHealMagic], a' in gold_success)
        verify('kanto_healing_preserved',
               'callab SetLastBlackoutMapRegional' in old and
               all(t in orig for t in ('ld a, [wLastMap]','ld [wLastBlackoutMap], a',
               'db SAFARI_ZONE_REST_HOUSE_2, SAFARI_ZONE_REST_HOUSE_3, SAFARI_ZONE_REST_HOUSE_4, -1')))
        verify('old_save_sentinel',
               'wJohtoLastHealMagic::' in wram and 'wJohtoLastHealLocalID::' in wram and
               'DEF JOHTO_LAST_HEAL_MAGIC EQU $a6' in code('constants/region_map_constants.asm'))
        helper=runtime.split('JohtoPilotGetLastHealLandmarkOrPlayer::',1)[1].split('JohtoPilotLoadMapMusic::',1)[0]
        verify('town_start_heal_or_player_fallback',all(t in helper for t in (
               'ld a, [wJohtoLastHealMagic]','cp JOHTO_LAST_HEAL_MAGIC',
               'ld a, [wJohtoLastHealLocalID]','cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID',
               'ld e, 2','jp JohtoPilotGetTownMapLandmark')) and
               'callab JohtoPilotGetLastHealLandmarkOrPlayer' in mapui)
        verify('profile_music_and_map_labels',
               'johto_map_profile 0, 2, MUSIC_POKECENTER, 0' in runtime and
               'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot47 interior center tune' in read('engine/menu/options_menu.asm') and
               'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot48 Route32 Center (no Fly destination)' in read('engine/menu/options_menu.asm') and
               'dw JohtoPilotCherrygroveName' in names and
               'dw JohtoSharedPokecenterRuntimeHeader' in header)
        verify('source_is_gold_5x4_and_dry',
               len((root/'maps/johto_pilot/CherrygrovePokecenter1F.gold.blk').read_bytes())==20 and
               'INCBIN "maps/johto_pilot/CherrygrovePokecenter1F.gold.blk"' in code('data/johto_pilot_source_resources.asm'))
    except (OSError,ValueError,IndexError) as e:issues.append('read_and_parse: '+str(e))
    return {'status':'PASS_STATIC_ONLY' if not issues else 'FAIL',
            'checks':checks,'errors':issues,'rom_built':False,'device_accepted':False}

if __name__=='__main__':
    import argparse
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=Path.cwd());args=ap.parse_args()
    result=audit(args.project)
    print(json.dumps(result,indent=2));raise SystemExit(bool(result['errors']))
