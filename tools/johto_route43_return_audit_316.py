#!/usr/bin/env python3
"""DEV-316 Route43 return-Warp regression gate (Gold verified; never build ROM).

Verify Route43 remains Gold-exact. Gold WARP_CARPET_DOWN is LAND_TILE, but the coarse
north role grid stays fail-closed and uses exact BeforeStep/E3 lane profiles; only DOWN/E=1
may activate the registered collision Warp.
Input overrides are for deterministic fault-injection tests, not game writes.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_coverage_audit import read_active_maps


def audit(root: Path, gold_root: Path, overrides: dict[str, bytes | str] | None = None) -> dict:
    root, gold_root = Path(root), Path(gold_root)
    overrides = overrides or {}
    checks, errors = [], []
    def test(name: str, condition: bool):
        checks.append(dict(name=name, passed=bool(condition)))
        if not condition:
            errors.append(name)
    def blob(relative: str) -> bytes:
        value = overrides.get(relative)
        return value.encode() if isinstance(value, str) else value if value is not None else (root/relative).read_bytes()
    def txt(relative: str) -> str:
        return blob(relative).decode('utf8')

    gold = GoldCollisionIndex(gold_root)
    source=blob('maps/johto_pilot/Route43.gold.blk')
    runtime=blob('maps/johto_pilot/Route43.runtime.blk')
    roles=blob('maps/johto_pilot/Route43.roles.bin')
    original=(gold_root/'maps/Route43.blk').read_bytes()
    ids=txt('constants/region_map_constants.asm')
    live=txt('engine/johto_pilot_runtime.asm')
    route43=txt('data/johto_route43_runtime_315.asm')
    gate=txt('data/johto_route43_mahogany_gate_313.asm')
    vertical=txt('data/johto_vertical_gate_runtime_314.asm')
    east=txt('data/johto_east_runtime_300.asm')
    surf=txt('engine/johto_violet_field_skills.asm')
    warp_section=live.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
    route43_warps=route43.split('JohtoRoute43RuntimeObjects::',1)[1].split('JohtoRoute43TextPointers:',1)[0]
    gate_warps=gate.split('JohtoRoute43MahoganyGateRuntimeObjects::',1)[1]
    gate66=txt('data/johto_route43_gate_319.asm')
    gate66_warps=gate66.split('JohtoRoute43GateRuntimeObjects::',1)[1]
    count_match=re.search(r'DEF NUM_JOHTO_ACTIVE_MAPS EQU (\d+)', ids)
    test('stable_count_at_least_ID66_generation', bool(count_match) and int(count_match.group(1))>=41)
    active=read_active_maps(root)
    test('stable_slot_40_ID66',len(active)>=41 and active[40]['map']=='Route43Gate' and active[40]['slot']==40 and active[40]['stable_id']==66)
    test('exact_Gold_10x27',source==runtime==original and len(source)==270)
    test('Gold_quadrant_grid_20x54',len(roles)==1080 and set(roles)<=set((0,1,2)))
    cells=gold.cells('Route43')
    water={(y,x) for (x,y),v in cells.items() if v['role']=='WATER'}
    registered={(y,x) for y in range(54) for x in range(20) if roles[y*20+x]==2}
    test('Gold_WATER_all_72_exact',len(water)==72 and water==registered)
    test('Gold_south_carpet_pair_walkable',all(gold.role_at('Route43',x,51)=='WARP_CARPET_DOWN' and roles[51*20+x]==0 for x in (9,10)))
    test('Gold_north_carpet_pair_role_grid_fail_closed',all(gold.role_at('Route43',x,31)=='WARP_CARPET_DOWN' and roles[31*20+x]==1 for x in (17,18)))
    permission=(gold_root/'data/collision/collision_permissions.asm').read_text()
    test('Gold_WARP_CARPET_DOWN_is_LAND_TILE',bool(re.search(r'(?m)^\s*db\s+LAND_TILE\s*;\s*COLL_WARP_CARPET_DOWN\b',permission)))
    test('Gold_door_stays_solid',gold.role_at('Route43',17,35)=='DOOR' and roles[35*20+17]==1)
    test('north_carpet_side_walls_stay_solid',all(roles[31*20+x]==1 for x in (16,19)))
    test('Route43_five_Gold_warps',bool(re.search(r'(?m)^\s*db 5 ; Gold Route43 warps',route43_warps)) and
         len(re.findall(r'^\s*db \d+, \d+, \d+, JOHTO_REGISTERED_WARP_SELECTOR',route43_warps,re.M))==5 and
         all(s in route43_warps for s in ('db 51, 9, 2, JOHTO_REGISTERED_WARP_SELECTOR','db 51, 10, 3, JOHTO_REGISTERED_WARP_SELECTOR',
             'db 35, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR','db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 31, 18, 1, JOHTO_REGISTERED_WARP_SELECTOR')))
    test('ID65_four_total_warps',bool(re.search(r'(?m)^\s*db 4 ; Gold lower',gate_warps)) and
         len(re.findall(r'^\s*db \d+, \d+, \d+, JOHTO_REGISTERED_WARP_SELECTOR',gate_warps,re.M))==4)
    test('ID66_four_total_warps',bool(re.search(r'(?m)^\s*db 4 ; Gold #1/#2',gate66_warps)) and
         len(re.findall(r'^\s*db \d+, \d+, \d+, JOHTO_REGISTERED_WARP_SELECTOR',gate66_warps,re.M))==4)
    warp_rows = re.findall(r'(?m)^\s*db MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID), (\d+), MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID)',warp_section)
    expected_routes = ({('JOHTO_MAHOGANY_TOWN_LOCAL_ID','0','JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID')} |
                       {('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID',str(i),'JOHTO_MAHOGANY_TOWN_LOCAL_ID') for i in (0,1)} |
                       {('JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID',str(i),'JOHTO_ROUTE_43_LOCAL_ID') for i in (2,3)} |
                       {('JOHTO_ROUTE_43_LOCAL_ID',str(i),'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID') for i in (0,1)} |
                       {('JOHTO_ROUTE_43_LOCAL_ID',str(i),'JOHTO_ROUTE_43_GATE_LOCAL_ID') for i in (2,3,4)} |
                       {('JOHTO_ROUTE_43_GATE_LOCAL_ID',str(i),'JOHTO_ROUTE_43_LOCAL_ID') for i in range(4)})
    test('registered_bidirectional_warp_routes',expected_routes.issubset(set(warp_rows)))
    test('ID66_registered_Lake_still_closed','JOHTO_ROUTE_43_GATE_LOCAL_ID' in warp_section and 'JOHTO_LAKE_OF_RAGE_LOCAL_ID' not in warp_section)
    before_step=vertical.split('JohtoVerticalGateBeforeStepProfiles314::',1)[1].split('JohtoVerticalGateBeforeStepProfilesEnd314::',1)[0]
    after_step=vertical.split('JohtoVerticalGateAfterStepProfiles314::',1)[1].split('JohtoVerticalGateAfterStepProfilesEnd314::',1)[0]
    test('ID65_DOOR_thresholds_only', all(t in before_step for t in (
         'db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 4, 1',
         'db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 1')))
    test('south_ID65_carpet_keeps_collision_return',
         not re.search(r'(?m)^\s*db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, (?:9|10), 51\s*$', before_step) and
         all(t in after_step for t in (
             'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 9, 51, 1',
             'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 10, 51, 1')) and
         all(roles[52*20+x] == 1 for x in (9,10)))
    test('north_ID66_carpet_reentry_and_lane_change', all(t in before_step for t in (
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 30',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 17, 31',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 18, 31')) and all(t in after_step for t in (
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 31, 1',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 31, 1',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3')) and
         all(roles[32*20+x] == 1 for x in (17,18)))
    collision_exit=vertical.split('JohtoVerticalGateCollisionExit314::',1)[1].split('\n; Gold door landing',1)[0]
    test('north_ID66_lane_change_not_collision_exit',all(t in after_step for t in (
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3')) and
         'cp 1' in collision_exit and 'ret z' in collision_exit)
    collision_exit=vertical.split('JohtoVerticalGateCollisionExit314::',1)[1].split('\n; Gold door landing',1)[0]
    test('north_ID66_lane_change_not_collision_exit',all(t in after_step for t in (
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3',
         'db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3')) and
         'cp 1' in collision_exit and 'ret z' in collision_exit)
    test('arrival_only_gold_DOORS_not_carpets',all(t in vertical for t in (
         'db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 4, 0, D_DOWN',
         'db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 5, 0, D_DOWN',
         'db JOHTO_ROUTE_43_GATE_LOCAL_ID, 4, 0, D_DOWN',
         'db JOHTO_ROUTE_43_GATE_LOCAL_ID, 5, 0, D_DOWN',
         'db JOHTO_ROUTE_43_LOCAL_ID, 17, 35, D_DOWN')) and
         not any(re.search(r'(?m)^\s*db JOHTO_ROUTE_43_LOCAL_ID, '+str(x)+r', '+str(y)+r', D_DOWN',vertical)
                 for x,y in ((9,51),(10,51),(17,31),(18,31))))
    test('finite_NSEW_edges', all(t in east for t in ('.route43North','.route43South','.route43West','JOHTO_ROUTE_43_WIDTH * 2 - 1','JOHTO_ROUTE_43_HEIGHT * 2 - 1')))
    test('Surf_east_probes_reused',all(s in east for s in ('JohtoRoute43Roles:: INCBIN','JohtoEastGoldWaterProbe::','JohtoEastGoldShoreProbe::')) and
         'cp JOHTO_ROUTE_43_LOCAL_ID\n    jp z, .eastRoute42' in surf)
    test('Cut_gold_tree', 'db JOHTO_ROUTE_43_LOCAL_ID, 28, 2, $67' in surf)
    ledge=txt('engine/overworld/ledges.asm')
    test('Gold_8_hop_rows',all(f'db {x}, {y}, PLAYER_DIR_DOWN' in ledge.split('JohtoRoute43GoldHops:',1)[1].split('db $ff',1)[0] for y in (32,34) for x in (12,13,14,15)))
    test('ROMX_bank53_include', 'INCLUDE "data/johto_route43_runtime_315.asm"' in txt('main.asm'))
    town_index = txt('engine/fly_town_map_helpers.asm').split('JohtoPilotTownMapBrowseIndexBySlot:',1)[1].split('JohtoPilotTownMapBrowseIndexBySlotEnd:',1)[0]
    test('town_map_browse_keeps_slot40_ID66', 'slot40 Route43Gate' in txt('engine/fly_town_map_helpers.asm') and len(re.findall(r'\d+',town_index))>=41)
    test('RBY_map_name_and_GSC_music', 'JohtoPilotRoute43Name:: db "Route 43@"' in txt('engine/fly_town_map_helpers.asm') and
         'JohtoActiveGSCMusicEnd::' in txt('engine/menu/options_menu.asm') and
         'db MUSIC_GBP_GSC_LAKE_OF_RAGE ; slot39 Route43' in txt('engine/menu/options_menu.asm') and
         'db MUSIC_GBP_GSC_LAKE_OF_RAGE ; slot40 Route43Gate' in txt('engine/menu/options_menu.asm'))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,
            'active_maps':len(active),'route43_gold_water_cells':len(water),
            'rom_built':False,'phone_verified':False}


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path.cwd())
    parser.add_argument('--gold-root',required=True,type=Path)
    parser.add_argument('--json-out',type=Path)
    options=parser.parse_args()
    result=audit(options.root,options.gold_root)
    if options.json_out:
        options.json_out.write_text(json.dumps(result,indent=2)+'\n')
    print(f"Route43 DEV-316: {result['status']} {len(result['checks'])-len(result['errors'])}/{len(result['checks'])} checks")
    if result['errors']:print('FAILED:',', '.join(result['errors']))
    return 0 if not result['errors'] else 1

if __name__=='__main__':
    raise SystemExit(main())
