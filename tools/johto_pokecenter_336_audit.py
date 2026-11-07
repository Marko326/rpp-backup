#!/usr/bin/env python3
"""DEV-336: source-level runtime ingress/egress and counter-talk contract.

Does not compile ROM or execute Game Boy instructions. Prevents the missing
ID37 pointer, accidental step-on carpet, counter script inaccessibility, and
unbounded Gold 5x4 interior from regressing without failing migration audit.
"""
from pathlib import Path
import argparse, json, re

ROOM = 'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID'

def audit(root):
    root=Path(root)
    checks=[];errors=[]
    def ck(name,ok):
        checks.append({'check':name,'status':'PASS' if ok else 'FAIL'})
        if not ok: errors.append(name)
    def read(rel,binary=False):
        p=root/rel
        return p.read_bytes() if binary else p.read_text()
    try:
        tileset=read('data/tileset_headers.asm')
        ptr=read('data/warp_tile_ids.asm')
        room=read('engine/johto_shared_pokecenter.asm')
        runtime=read('engine/johto_pilot_runtime.asm')
        gate=read('data/johto_vertical_gate_runtime_314.asm')
        home=read('home/overworld.asm')
        warp=read('engine/johto_pilot_warp_tiles.asm')
        flyhelpers=read('engine/fly_town_map_helpers.asm')
        npc=read('data/mapObjects/ViridianPokecenter.asm')
        obj=read('engine/overworld/doors.asm')
        version=read('data/game_version.asm')
        blk=read('maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',True)
        bst=read('gfx/blocksets/johto_shared_pokecenter.bst',True)
        # Gold 5x4 block grid; two 16x16 player tiles per 32x32 block.
        # Facing UP at (3,3), GetTileAndCoordsInFrontOfPlayer reads the
        # lower-left 8x8 tile of (3,2): the existing counter tile $15.
        x,y=3,2
        block=blk[(y//2)*5+x//2]
        front=bst[block*16+(y%2)*8+(x%2)*2+4]
        ck('gold_front_counter_lower_left_is_15', len(blk)==20 and len(bst)==256 and front==0x15)
        ck('nurse_and_counter_geometry',
           'object SPRITE_NURSE, $3, $1, STAY, DOWN, $1' in room and
           'object SPRITE_NURSE, $3, $1, STAY, DOWN, $1' in npc and
           'TX_POKECENTER_NURSE' in room and
           room.count('object SPRITE_NURSE, $3, $1, STAY, DOWN, $1') == 10)
        ck('counter_registered_for_long_range_A',
           bool(re.search(r'tileset JohtoSharedPokecenter_Block, JohtoSharedPokecenter_GFX, Pokecenter_Coll, \$15,\$FF,\$FF, \$FF, INDOOR',tileset)) and
           'wTilesetTalkingOverTiles' in home and 'ld d,$20' in home and
           'IsSpriteInFrontOfPlayer2' in home)
        # This is indexed unconditionally by tileset number. One missing
        # dw causes out-of-table reads in the original Warp checker.
        t=ptr.split('WarpTileIDPointers:',1)[1].split('WarpTileIDPointersEnd:',1)[0]
        pointers=re.findall(r'(?m)^\s*dw\s+(\w+)',t)
        ck('all_38_warp_tile_pointer_indices',
           len(pointers)==41 and pointers[6]=='PokecenterWarpTileIDs' and
           pointers[36]=='JohtoParkGateWarpTileIDs' and pointers[37]=='JohtoPokecenterWarpTileIDs' and
           pointers[38]=='JohtoBurnedTower1FWarpTileIDs' and pointers[39]=='JohtoBurnedTowerB1FWarpTileIDs' and pointers[40]=='JohtoDarkCaveWarpTileIDs' and
           '(JOHTO_DARK_CAVE + 1) * 2' in ptr)
        ck('gold_exit_not_generic_step_on',
           bool(re.search(r'(?m)^JohtoPokecenterWarpTileIDs:\s*db\s+\$ff\b',ptr)) and
           'JohtoPokecenterWarpTileIDs' not in obj and
           'IsPlayerStandingOnDoorTileOrWarpTile::' in warp)
        # From matching Warp coordinate: arm wd736 but never fire WarpFound1.
        w=runtime.split('JohtoPilotGateDoorWarpMatched::',1)[1].split('JohtoPilotGateExteriorCollisionAllowed::',1)[0]
        w='\n'.join(line.split(';')[0] for line in w.splitlines())
        ck('exact_room_warps_are_stand_only',
           bool(re.search(r'cp '+ROOM+r'\s+jr z, \.centerCarpetStand',w)) and
           bool(re.search(r'\.centerCarpetStand\s+ld e, 1\s+ret',w)) and
           'cp 2' in home.split('CheckWarpsNoCollisionLoop::',1)[1].split('CheckWarpsCollision::',1)[0] and
           'jp CheckWarpsNoCollisionRetry2' in home)
        c=room.split('JohtoSharedCenterDownCollision336::',1)[1].split('SetLastBlackoutMapRegional::',1)[0]
        ck('exit_guard_has_exact_map_direction_and_two_carpet_cells',
           bool(re.search(r'ld e, 0\s+ld a, \[wCurLocalMapID\]\s+cp '+ROOM+
             r'\s+jr z, \.center\s+cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID\s+ret nz\s+\.center\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+'
             r'ld a, \[wYCoord\]\s+cp 7\s+ret nz\s+ld a, \[wXCoord\]\s+'
             r'cp 3\s+jr z, \.allow\s+cp 4\s+ret nz\s+\.allow\s+ld e, 1\s+ret',c)))
        e=runtime.split('JohtoPilotGateExteriorCollisionAllowed::',1)[1].split('JohtoPilotGateCollisionExitAllowed::',1)[0]
        final=runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1].split('JohtoPilotGateDoorApproachAllowed::',1)[0] if 'JohtoPilotGateDoorApproachAllowed::' in runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1] else runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1]
        ck('extra_warp_entry_calls_guard',
           'callab JohtoPilotGateExteriorCollisionAllowed' in home and
           bool(re.search(r'cp '+ROOM+r'\s+jr z, \.centerCarpetExit',e)) and
           re.search(r'\.centerCarpetExit\s+callab JohtoSharedCenterDownCollision336\s+ret',e) is not None)
        ck('collision_warp_entry_calls_same_guard',
           'callab JohtoPilotGateCollisionExitAllowed' in home and
           bool(re.search(r'cp '+ROOM+r'\s+jr z, \.centerCarpetExit',final)) and
           re.search(r'\.centerCarpetExit\s+callab JohtoSharedCenterDownCollision336\s+ret',final) is not None)
        b=gate.split('JohtoVerticalGateBoundsProfiles314::',1)[1].split('JohtoVerticalGateBoundsProfilesEnd314::',1)[0]
        rows=re.findall(r'(?m)^\s*db\s+(\w+),\s*(\d+),\s*(\d+)',b)
        ck('finite_10x8_Gold_room_boundaries',
           rows == [('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID','10','8'),
                    ('JOHTO_ROUTE_43_GATE_LOCAL_ID','10','8'),
                    ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID','10','8'),
                    (ROOM,'10','8'), ('JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID','10','8'), ('JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID','10','8'),('JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID','10','8')] and
           'JohtoVerticalGateClosedEdge314::' in gate and
           'ld e, 1' in gate.split('JohtoVerticalGateClosedEdge314::',1)[1] and
           '== 40' in gate)
        edge=runtime.split('JohtoPilotIsClosedOutdoorEdge::',1)[1].split('JohtoPilotGetLastHealLandmarkOrPlayer::',1)[0] if 'JohtoPilotGetLastHealLandmarkOrPlayer::' in runtime.split('JohtoPilotIsClosedOutdoorEdge::',1)[1] else runtime.split('JohtoPilotIsClosedOutdoorEdge::',1)[1]
        ck('live_overworld_collision_calls_room_bounds',
           bool(re.search(r'cp '+ROOM+r'\s+jp z, \.verticalGateClosedEdge314',edge)) and
           'callab JohtoVerticalGateClosedEdge314' in edge and
           'callab JohtoPilotIsClosedOutdoorEdge' in home)
        ck('original_kanto_center_and_gold_room_unchanged',
           'object SPRITE_NURSE, $3, $1, STAY, DOWN, $1' in npc and
           'db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR' in room and
           'db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR' in room and
           'INCBIN "maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk"' in room)
        arrival=flyhelpers.split('UpdateSeafoamEntranceSource::',1)[1].split('\n.checkSeafoam\n',1)[0]
        seafoam=flyhelpers.split('\n.checkSeafoam\n',1)[1].split('FindCityFlyLocationFromSpecialAnchor::',1)[0]
        ck('arriving_on_gold_carpet_rearms_collision_only_warp',
           'callab UpdateSeafoamEntranceSource' in home and
           bool(re.search(r'cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.checkSeafoam',arrival)) and
           bool(re.search(r'cp MAP_REGION_JOHTO\s+ret nz',arrival)) and
           bool(re.search(r'cp '+ROOM+r'\s+jr z, \.centerArrival\s+cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID\s+jr z, \.centerArrival\s+cp JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID\s+ret nz',arrival)) and
           bool(re.search(r'\.centerArrival\s+ld hl, wd736\s+res 2, \[hl\]\s+callba IsPlayerStandingOnWarp\s+ret',arrival)) and
           'cp SEAFOAM_ISLANDS_1' in seafoam and 'cp ROUTE_20' in seafoam)
        ck('same_rom_version_all_builds', bool(re.search(r'(?m)^\s*db "REF-(\d{3})[A-Z]?@"$', version)) and int(re.search(r'(?m)^\s*db "REF-(\d{3})[A-Z]?@"$', version).group(1)) >= 349 and
           'GameVersionText::' in version)
    except (IndexError,ValueError,OSError) as exc:
        errors.append('input_error: '+str(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,'rom_built':False,'device_accepted':False}

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=Path('.'))
    ns=ap.parse_args();r=audit(ns.project)
    print(json.dumps(r,ensure_ascii=False,indent=2));raise SystemExit(bool(r['errors']))
