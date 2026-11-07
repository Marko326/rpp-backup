#!/usr/bin/env python3
"""DEV-320 read-only Gold ID66 door/carpet and Route43 movement regression.

Checks Gold collision roles, exact BeforeStep/AfterStep movement profiles, the
collision-only outward Warp, and historical seam invariants. The bounded movement
trace is a source-contract model, not a ROM CPU or device simulation.
Overrides are used only by negative fault-injection tests.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_coverage_audit import read_active_maps

GATE = 'JOHTO_ROUTE_43_GATE_LOCAL_ID'
ROUTE = 'JOHTO_ROUTE_43_LOCAL_ID'
ID65 = 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID'
SEL = 'JOHTO_REGISTERED_WARP_SELECTOR'


def audit(root: Path, gold_root: Path, overrides: dict[str, str | bytes] | None = None) -> dict:
    root, gold_root = Path(root), Path(gold_root)
    overrides = overrides or {}
    checks: list[dict] = []
    def test(name: str, condition: bool) -> None:
        checks.append({'name': name, 'passed': bool(condition)})
    def blob(name: str) -> bytes:
        val = overrides.get(name)
        return val.encode() if isinstance(val, str) else val if isinstance(val, bytes) else (root/name).read_bytes()
    def text(name: str) -> str:
        return blob(name).decode('utf8')
    def section(s: str, begin: str, end: str) -> str:
        return s.split(begin, 1)[1].split(end, 1)[0]
    def warp_rows(s: str) -> list[tuple[int,int,int]]:
        return [(int(y),int(x),int(dest)) for y,x,dest in re.findall(r'^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*'+SEL, s, re.M)]

    gold = GoldCollisionIndex(gold_root)
    gate_block = blob('maps/johto_pilot/Route43Gate.runtime.blk')
    gate_gold = blob('maps/johto_pilot/Route43Gate.gold.blk')
    id65_block = blob('maps/johto_pilot/Route43MahoganyGate.runtime.blk')
    id65_gold = blob('maps/johto_pilot/Route43MahoganyGate.gold.blk')
    route_gold = blob('maps/johto_pilot/Route43.gold.blk')
    route_runtime = blob('maps/johto_pilot/Route43.runtime.blk')
    roles = blob('maps/johto_pilot/Route43.roles.bin')
    gate_src = text('data/johto_route43_gate_319.asm')
    route_src = text('data/johto_route43_runtime_315.asm')
    vertical = text('data/johto_vertical_gate_runtime_314.asm')
    runtime = text('engine/johto_pilot_runtime.asm')
    source = text('data/johto_pilot_source_resources.asm')
    resource = text('data/johto_pilot_runtime_assets.asm')
    ids = text('data/johto_stable_id_slots.asm')
    region = text('constants/region_map_constants.asm')
    header = text('data/johto_header_descriptors.asm')
    music = text('engine/menu/options_menu.asm')
    town = text('engine/fly_town_map_helpers.asm')
    name = text('engine/overworld/map_name_sign.asm')
    main = text('main.asm')
    home = text('home/overworld.asm')
    home_code = '\n'.join(line.split(';', 1)[0] for line in home.splitlines())

    gold_gold = (gold_root/'maps'/'NorthSouthGate.blk').read_bytes()
    test('Gold_shared_NorthSouthGate_5x4', len(gate_gold)==20 and gate_gold==id65_gold==gold_gold)
    test('RPP_Gold_gate_runtime_identical_to_approved_ID65', len(gate_block)==20 and gate_block==id65_block)
    test('Route43_art_remains_original', route_gold==route_runtime==(gold_root/'maps/Route43.blk').read_bytes())
    test('ID66_stable_ID_66', 'DEF JOHTO_ROUTE_43_GATE_LOCAL_ID EQU 66' in text('constants/johto_fixed_map_ids.asm'))
    active_count_match = re.search(r'DEF NUM_JOHTO_ACTIVE_MAPS EQU (\d+)', region)
    active_count = int(active_count_match.group(1)) if active_count_match else -1
    test('slot40_ID66_preserved_append_safe', active_count >= 41 and
         'db 37, 38, 40, 39,' in ids and 'ASSERT NUM_JOHTO_ACTIVE_MAPS ==' in ids)
    test('ID66_width_height_5x4', 'DEF JOHTO_ROUTE43_GATE_WIDTH EQU 5' in region and 'DEF JOHTO_ROUTE43_GATE_HEIGHT EQU 4' in region)
    test('header_descriptor_appended', bool(re.search(r'dw JohtoRoute43RuntimeHeader\s+db BANK\(JohtoRoute43RuntimeHeader\)\s+dw JohtoRoute43GateRuntimeHeader\s+db BANK\(JohtoRoute43GateRuntimeHeader\)',header)))
    test('resource_descriptor_appended', 'JohtoRoute43GateRuntimeDescriptor::' in resource and
         'dw JohtoRoute43GateBlocks' in section(resource,'JohtoRoute43GateRuntimeDescriptor::','JohtoPilotRuntimeResourceDescriptorsEnd::') and
         'jp z, .route43Gate' in resource and '.route43Gate\n    ld hl, JohtoRoute43GateRuntimeDescriptor' in resource)
    test('source_descriptor_appended', re.search(r'DEF JOHTO_PILOT_SOURCE_COUNT EQU (\d+)', source) is not None and
         'JohtoRoute43GateGoldBlocks:: INCBIN "maps/johto_pilot/Route43Gate.gold.blk"' in source and
         'dw JohtoRoute43GateGoldBlocks' in section(source,'JohtoPilotSourceRecords::','JohtoPilotSourceRecordsEnd::'))
    # The live map roster loader validates the exact source/runtime order.
    try:
        active = read_active_maps(root) if not overrides else []
        test('active_registry_slot40_ID66', not overrides or (len(active)>=41 and active[40]['stable_id']==66 and active[40]['slot']==40 and active[40]['map']=='Route43Gate'))
    except (ValueError,KeyError,FileNotFoundError):
        test('active_registry_slot40_ID66',False)
    gh = section(gate_src,'JohtoRoute43GateRuntimeHeader::','JohtoRoute43GateHeaderEnd::')
    gobjects = section(gate_src,'JohtoRoute43GateRuntimeObjects::','\n    db 0 ; signs')
    robjects = section(route_src,'JohtoRoute43RuntimeObjects::','\n    db 3 ; Gold Route43 signs')
    test('header_Bank53_stays_together', all(t in main for t in (
         'INCLUDE "data/johto_route43_gate_319.asm"','SECTION "Johto East Runtime 300", ROMX, BANK[$53]')) and
         'db JOHTO_GATE' in gh and 'db 0 ; enclosed gatehouse' in gh and
         'ASSERT BANK(JohtoRoute43GateRuntimeHeader) == BANK(JohtoRoute43GateBlocks)' in gate_src)
    test('Gold_Route43_5_original_warps', 'db 5 ; Gold Route43 warps #1..#5' in robjects and
         warp_rows(robjects)==[(51,9,2),(51,10,3),(35,17,2),(31,17,0),(31,18,1)])
    test('Gold_ID66_4_original_warps', 'db 4 ; Gold #1/#2' in gobjects and
         warp_rows(gobjects)==[(0,4,3),(0,5,4),(7,4,2),(7,5,2)])
    test('Gold_Route43_collision_role_kinds',
         [gold.role_at('Route43',x,y) for x,y in ((17,35),(17,31),(18,31))] ==
         ['DOOR','WARP_CARPET_DOWN','WARP_CARPET_DOWN'])
    test('Gold_ID66_collision_role_kinds',
         [gold.role_at('Route43Gate',x,y) for x,y in ((4,0),(5,0),(4,7),(5,7))] ==
         ['DOOR','DOOR','WARP_CARPET_DOWN','WARP_CARPET_DOWN'])
    # Gold classifies WARP_CARPET_DOWN as LAND_TILE. Route43's coarse role
    # grid deliberately stays fail-closed at the north pair; exact BeforeStep
    # profiles open only Gold re-entry/lane-switch directions, while E=3 keeps
    # a lateral lane change out of the collision-only Warp path.
    carpet_permission = (gold_root/'data/collision/collision_permissions.asm').read_text()
    test('Gold_WARP_CARPET_DOWN_is_LAND_TILE', bool(re.search(
         r'(?m)^\s*db\s+LAND_TILE\s*;\s*COLL_WARP_CARPET_DOWN\b', carpet_permission)))
    test('Route43_north_carpet_role_grid_fail_closed', len(roles)==1080 and
         roles[35*20+17]==1 and all(roles[31*20+x]==1 for x in (17,18)) and
         all(roles[51*20+x]==0 for x in (9,10)))
    test('Route43_north_carpet_surrounding_walls_stay_solid', len(roles)==1080 and
         all(roles[y*20+x]==1 for x,y in ((16,31),(19,31),(17,32),(18,32))))
    test('Route43_water_untouched', len(roles)==1080 and sum(c==2 for c in roles)==72)
    gold_entrances = re.findall(r'warp_event\s+(\d+),\s*(\d+),\s*ROUTE_43_GATE,\s*(\d+)',(gold_root/'maps/Route43.asm').read_text())
    test('original_Gold_outdoor_warp_ordinal_contract',gold_entrances==[('17','35','3'),('17','31','1'),('18','31','2')])
    warp_tbl = section(runtime,'JohtoRegisteredWarpRoutes::','JohtoRegisteredWarpRoutesEnd::')
    source_rows = re.findall(r'^\s*db MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID), (\d+), MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID)',warp_tbl,re.M)
    expected = {(ROUTE,str(i),GATE) for i in (2,3,4)} | {(GATE,str(i),ROUTE) for i in range(4)}
    test('registered_seven_exact_ID66_route_pairs',{r for r in source_rows if GATE in (r[0],r[2])}==expected)
    test('old_ID65_warp_pairs_preserved',all((ROUTE,str(i),ID65) in source_rows for i in (0,1)))
    test('gate_has_no_unregistered_indoor_entrance','db 0 ; signs\n    db 0 ; Rocket' in gate_src)

    before = section(vertical,'JohtoVerticalGateBeforeStepProfiles314::','JohtoVerticalGateBeforeStepProfilesEnd314::')
    after = section(vertical,'JohtoVerticalGateAfterStepProfiles314::','JohtoVerticalGateAfterStepProfilesEnd314::')
    arrival = section(vertical,'JohtoVerticalGateArrivalProfiles314::','JohtoVerticalGateArrivalProfilesEnd314::')
    bounds = section(vertical,'JohtoVerticalGateBoundsProfiles314::','JohtoVerticalGateBoundsProfilesEnd314::')
    pre_rows = re.findall(r'^\s*db (JOHTO_\w+_LOCAL_ID), (PLAYER_DIR_\w+), (\d+), (\d+)',before,re.M)
    post_rows = re.findall(r'^\s*db (JOHTO_\w+_LOCAL_ID), (PLAYER_DIR_\w+), (\d+), (\d+), (\d+)',after,re.M)
    arrival_rows = re.findall(r'^\s*db (JOHTO_\w+_LOCAL_ID), (\d+), (\d+), (D_\w+)',arrival,re.M)
    required_pre={(GATE,'PLAYER_DIR_DOWN',str(x),'6') for x in (4,5)} | {(GATE,'PLAYER_DIR_UP',str(x),'1') for x in (4,5)} | {(ROUTE,'PLAYER_DIR_UP','17','36')}
    north_reentry_pre={(ROUTE,'PLAYER_DIR_DOWN',str(x),'30') for x in (17,18)}
    north_lane_pre={(ROUTE,'PLAYER_DIR_RIGHT','17','31'),(ROUTE,'PLAYER_DIR_LEFT','18','31')}
    required_post={(GATE,'PLAYER_DIR_DOWN',str(x),'7','1') for x in (4,5)} | {(GATE,'PLAYER_DIR_UP',str(x),'0','2') for x in (4,5)} | {(ROUTE,'PLAYER_DIR_UP','17','35','2')} | {(ROUTE,'PLAYER_DIR_DOWN',str(x),'31','1') for x in (17,18)}
    north_lane_post={(ROUTE,'PLAYER_DIR_RIGHT','18','31','3'),(ROUTE,'PLAYER_DIR_LEFT','17','31','3')}
    test('Gold_before_step_profiles_include_ID66_reentry_and_lane_changes',
         required_pre <= set(pre_rows) and north_reentry_pre <= set(pre_rows) and north_lane_pre <= set(pre_rows))
    test('Gold_after_step_profiles_include_collision_and_lane_change_results',
         required_post <= set(post_rows) and north_lane_post <= set(post_rows))
    test('door_vs_carpet_1_or_2', (ROUTE,'PLAYER_DIR_UP','17','35','1') not in post_rows and
         all((ROUTE,'PLAYER_DIR_DOWN',str(x),'31','2') not in post_rows for x in (17,18)))
    test('Route43_north_carpet_warp_is_DOWN_only',
         all((ROUTE,'PLAYER_DIR_DOWN',str(x),'31','1') in post_rows for x in (17,18)) and
         all((ROUTE,direction,str(x),'31','1') not in post_rows
             for x in (17,18) for direction in ('PLAYER_DIR_UP','PLAYER_DIR_LEFT','PLAYER_DIR_RIGHT')))
    east_runtime = text('data/johto_east_runtime_300.asm')
    spatial_step = section(east_runtime,'JohtoEastSpatialStep::','\n; REF-303')
    test('Route43_walkability_uses_live_spatial_role_grid',
         'call JohtoEastSpatialRoleAhead' in spatial_step and
         'jr z, .allow' in spatial_step and 'cp 1' in spatial_step)
    land_collision = section(home_code,'CollisionCheckOnLand::','\nCheckTilePassable::')
    test('Route43_north_carpet_override_runs_before_role_grid_collision',
         'callab JohtoPilotGateDoorApproachAllowed' in land_collision and
         'callab JohtoOverworldSouthLandDecision' in land_collision and
         land_collision.index('callab JohtoPilotGateDoorApproachAllowed') <
         land_collision.index('callab JohtoOverworldSouthLandDecision') and
         'callab JohtoVerticalGateBeforeStep314' in runtime)
    # The two carpet quadrants render as tile $40 in the live JohtoPilot blockset.
    # That tile must not enter the generic STEP_ON warp list: only the registered
    # DOWN collision profile may transfer the player into ID66.
    blockset = blob('gfx/blocksets/johto.bst')
    north_carpet_visuals = (blockset[0x0c*16 + 15], blockset[0x0d*16 + 13]) if len(blockset) >= 0x0e*16 else ()
    warp_tile_src = text('data/warp_tile_ids.asm')
    pilot_warp_section = section(warp_tile_src,'JohtoPilotWarpTileIDs:','JohtoHouseWarpTileIDs:')
    pilot_warp_ids = [int(token.strip().replace('$','0x'),0)
                      for row in re.findall(r'(?m)^\s*db\s+([^;\n]+)',pilot_warp_section)
                      for token in row.split(',')]
    test('Route43_north_carpet_visuals_not_generic_STEP_ON_warps',
         north_carpet_visuals == (0x40,0x40) and all(tile not in pilot_warp_ids for tile in north_carpet_visuals))
    collision_exit = section(vertical,'JohtoVerticalGateCollisionExit314::','\n; Gold door landing')
    test('Route43_collision_exit_accepts_only_collision_carpet_result',
         'call JohtoVerticalGateAfterStep314' in collision_exit and
         'cp 1' in collision_exit and 'ret z' in collision_exit and
         'callab JohtoVerticalGateCollisionExit314' in runtime)
    test('south_ID65_carpet_keeps_collision_return',
         all((ROUTE,'PLAYER_DIR_DOWN',str(x),'51') not in pre_rows for x in (9,10)) and
         all((ROUTE,'PLAYER_DIR_DOWN',str(x),'51','1') in post_rows for x in (9,10)))
    test('north_ID66_lane_change_not_collision_exit',
         all(row in post_rows for row in north_lane_post) and
         all((ROUTE,direction,str(x),'31','1') not in post_rows
             for x in (17,18) for direction in ('PLAYER_DIR_UP','PLAYER_DIR_LEFT','PLAYER_DIR_RIGHT')) and
         'cp 1' in collision_exit)
    test('lane_change_result_suppresses_step_on_warp',
         re.search(r'cp 2\s+jr z, \.northGoldStepOnDoor\s+and a\s+jr z, \.noRegisteredGateDoor\s+pop bc\s+pop hl\s+jp CheckWarpsNoCollisionRetry2', home_code) is not None)
    pre_set=set(pre_rows)
    def can_step(x,y,direction):
        dx,dy={'PLAYER_DIR_UP':(0,-1),'PLAYER_DIR_DOWN':(0,1),
               'PLAYER_DIR_LEFT':(-1,0),'PLAYER_DIR_RIGHT':(1,0)}[direction]
        tx,ty=x+dx,y+dy
        role=gold.role_at('Route43',tx,ty)
        if role=='FLOOR': return True
        if role=='WARP_CARPET_DOWN': return (ROUTE,direction,str(x),str(y)) in pre_set
        return False
    movement_trace={
        'reenter_west_carpet':can_step(17,30,'PLAYER_DIR_DOWN'),
        'reenter_east_carpet':can_step(18,30,'PLAYER_DIR_DOWN'),
        'switch_west_to_east':can_step(17,31,'PLAYER_DIR_RIGHT'),
        'switch_east_to_west':can_step(18,31,'PLAYER_DIR_LEFT'),
        'walk_up_from_west':can_step(17,31,'PLAYER_DIR_UP'),
        'walk_up_from_east':can_step(18,31,'PLAYER_DIR_UP'),
        'outer_west_rail_stays_blocked':not can_step(17,31,'PLAYER_DIR_LEFT'),
        'outer_east_rail_stays_blocked':not can_step(18,31,'PLAYER_DIR_RIGHT'),
        'south_edge_stays_blocked':not can_step(17,31,'PLAYER_DIR_DOWN'),
    }
    test('ID66_user_reported_movement_sequence',all(movement_trace.values()))
    test('arrival_auto_down_on_three_solid_doors',all((GATE,str(x),'0','D_DOWN') in arrival_rows for x in (4,5)) and
         (ROUTE,'17','35','D_DOWN') in arrival_rows and
         all((ROUTE,str(x),'31','D_DOWN') not in arrival_rows for x in (17,18)))
    test('ID66_closed_NSEW_bounds', 'db JOHTO_ROUTE_43_GATE_LOCAL_ID, 10, 8' in bounds and
         'ASSERT JohtoVerticalGateBoundsProfilesEnd314 - JohtoVerticalGateBoundsProfiles314 == 7' in vertical)
    test('profile_bytes_accounted',all(s in vertical for s in ('== 57','== 81','== 25','== 7')))
    test('shared_engine_dispatch_ID66', 'cp JOHTO_ROUTE_43_GATE_LOCAL_ID\n    ret z' in runtime and
         'JohtoVerticalGateBeforeStep314' in runtime and 'JohtoVerticalGateAfterStep314' in runtime)
    test('gate_music_source_record_and_validation', 'cp JOHTO_ROUTE_43_GATE_LOCAL_ID\n    jr nz, .notGateMusicEntry' in runtime and
         '.route43GateMusic\n    ld a, [wJohtoGateMusicSourceLocalID]' in runtime and
         '.route43GateMusic\n    ld a, [wJohtoGateMusicSourceLocalID]' in music)
    test('one_new_neutral_map_music_profile','johto_map_profile 0, 35, MUSIC_ROUTES1, 0 ; slot40' in runtime and
         'db MUSIC_GBP_GSC_LAKE_OF_RAGE ; slot40 Route43Gate' in music)
    test('neutral_map_name', 'cp JOHTO_ROUTE_43_GATE_LOCAL_ID\n\tret z' in name)
    test('TownMap_41st_slot', 'slot40 Route43Gate' in town and
         re.search(r'JohtoPilotTownMapBrowseIndexBySlot:\s+db [^\n]*, 35, 35',town) is not None)
    test('old_visual_seams_preserved_and_Lake_not_a_warp', 'db NORTH | SOUTH' in route_src and
         'JOHTO_LAKE_OF_RAGE_LOCAL_ID' not in warp_tbl)
    test('Rocket_toll_and_TM36_not_faked', 'db 0 ; Rocket and Officer events' in gate_src and
         'Gold 1000-yen Rocket toll/scene and Officer TM36 are NOT ported' in gate_src)
    version_match = re.search(r'(?m)^\s*db "REF-(\d{3})([A-Z]?)@"$', text('data/game_version.asm'))
    test('version_label_keeps_fixed_width', version_match is not None and len(f"REF-{version_match.group(1)}{version_match.group(2)}") <= 8)
    errors=[c['name'] for c in checks if not c['passed']]
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks_total':len(checks),
            'checks_passed':len(checks)-len(errors),'errors':errors,'checks':checks,
            'rom_built':False,'phone_verified':False, 'scene_toll_implemented':False}


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path.cwd())
    parser.add_argument('--gold-root',type=Path,required=True)
    parser.add_argument('--json-out',type=Path)
    args=parser.parse_args()
    result=audit(args.root,args.gold_root)
    if args.json_out:
        args.json_out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(f'ID66 DEV-320 {result["status"]}: {result["checks_passed"]}/{result["checks_total"]}')
    if result['errors']: print('Failed:', ', '.join(result['errors']))
    return 0 if not result['errors'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
