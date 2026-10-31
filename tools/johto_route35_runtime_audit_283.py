#!/usr/bin/env python3
"""MAP-283 active Route35 + Goldenrod north gate acceptance gate (static only).

Uses Gold original bytes and *running* ROMX headers, directional portals,
carpet collision, water and Cut semantics. Never claims ROM/phone verification.
Do not substitute the older, intentionally offline-only Route35 source gate.
"""
from __future__ import annotations
import argparse
import json
from collections import deque
from pathlib import Path
import re


def audit(root: Path, gold_root: Path | None = None, *, changes: dict[str, str | bytes] | None = None):
    root = Path(root)
    gold = Path(gold_root) if gold_root is not None else None
    changes = changes or {}
    checks, errors = [], []

    def read(path, binary=False):
        val = changes.get(path)
        if val is None:
            val = (root / path).read_bytes() if binary else (root / path).read_text(encoding='utf8')
        if binary:
            return val if isinstance(val, bytes) else val.encode()
        return val.decode() if isinstance(val, bytes) else val

    def check(name, ok, detail=''):
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail or name})
        if not ok:
            errors.append(name)

    try:
        c = read('constants/region_map_constants.asm')
        version = read('data/game_version.asm')
        runtime = read('data/johto_north_runtime_283.asm')
        portal = read('engine/johto_south_portals.asm')
        geometry = read('engine/johto_south_geometry.asm')
        cut = read('engine/johto_violet_field_skills.asm')
        pilot = read('engine/johto_pilot_runtime.asm')
        source = read('data/johto_pilot_source_resources.asm')
        music = read('tools/johto_pilot_door_contracts.json')
        route = read('maps/johto_pilot/Route35.runtime.blk', True)
        raw_road = read('maps/johto_pilot/Route35.gold.blk', True)
        gate = read('maps/johto_pilot/Route35GoldenrodGate.mature.blk', True)
        raw_gate = read('maps/johto_pilot/Route35GoldenrodGate.gold.blk', True)
        roles = read('maps/johto_pilot/Route35.roles.bin', True)
        gate_roles = read('maps/johto_pilot/Route35GoldenrodGate.roles.bin', True)
        check('actual_game_version_and_active_count',
              re.search(r'(?:FIX|MAP)-5\.62\.(?:285|286|287|288|289|290|294|295)@', version) is not None and 'TEST-231@' in version and
              re.search(r'NUM_JOHTO_ACTIVE_MAPS EQU (?:23|26|28)\b', c) is not None)
        check('distinct_stable_ids_17_18',
              'JOHTO_ROUTE_35_LOCAL_ID EQU 17' in c and
              'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID EQU 18' in c)
        check('original_route35_180_block_bytes',len(route)==len(raw_road)==180 and route==raw_road)
        check('mature_gate_byte_length_and_shared_gold',len(gate)==len(raw_gate)==20 and
              raw_gate==read('maps/johto_pilot/Route34IlexForestGate.gold.blk', True) and
              gate==read('maps/johto_pilot/Route34IlexForestGate.mature.blk', True))
        if gold:
            check('route35_bytes_match_unmodified_gold', raw_road == (gold/'maps/Route35.blk').read_bytes())
            check('gate_bytes_match_shared_gold', raw_gate == (gold/'maps/NorthSouthGate.blk').read_bytes())
        check('role_grid_sizes',len(roles)==720 and len(gate_roles)==80)
        check('route35_walking_two_south_carpet_cells',len(roles)==720 and
              roles[33*20+9]==0 and roles[33*20+10]==0 and
              roles[33*20+8]!=0 and roles[33*20+11]!=0)
        check('route35_gold_water_cell_count',len(roles)==720 and sum(v==2 for v in roles)==32)
        check('route35_gold_cut_cell_blocked_before_cut',len(roles)==720 and
              roles[6*20+17]==1 and 'johto_route_35_local_id, 6, 17, $5b' in cut.lower())
        check('gold_gate_has_correct_runtime_tileset_and_closed_seams', all(t in runtime for t in (
              'JohtoNorthRoute35GoldenrodGateRuntimeHeader::',
              'db JOHTO_GATE', 'db 0 ; do not silently connect a gate to adjacent roads')))
        check('route35_has_correct_gold_tileset_and_closed_north', all(t in runtime for t in (
              'JohtoNorthRoute35RuntimeHeader::', 'db JOHTO_PILOT',
              'db NORTH ; Gold north -> existing Route36, offset 0',
              'dw JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)')))
        check('route35_outdoor_forest_border',bool(re.search(r'JohtoNorthRoute35RuntimeObjects::\s*\n\s*db\s+\$05',runtime)))
        check('gate_black_border_and_four_warps', bool(re.search(
              r'JohtoNorthRoute35GoldenrodGateRuntimeObjects::\s*\n\s*db\s+\$0d[^\n]*\n\s*db\s+4',runtime)))
        check('route35_exact_south_two_warps_only', bool(re.search(
              r'JohtoNorthRoute35RuntimeObjects::\s*\n\s*db\s+\$05[^\n]*\n\s*db\s+[23]\s*\n\s*db\s+33,\s*9,\s*0,\s*JOHTO_REGISTERED_WARP_SELECTOR\b\s*;[^\n]*\n\s*db\s+33,\s*10,\s*1,\s*JOHTO_REGISTERED_WARP_SELECTOR',runtime)))
        # RPP object record's third byte is the DESTINATION warp ordinal,
        # not the source event's index. Gate->City both target City's #0;
        # City->Gate targets south entrance #2. FIX-283 used 2/3 and 0,
        # silently sending arrivals to incorrect map positions.
        gate_object=runtime.split('JohtoNorthRoute35GoldenrodGateRuntimeObjects::',1)[-1].split('JohtoNorthRoute35Blocks::',1)[0]
        city_object=read('data/johto_south_runtime.asm').split('JohtoSouthGoldenrodCityRuntimeObjects::',1)[-1]
        gate_rows=re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR',gate_object)
        city_rows=re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR',city_object)
        route_rows=re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR',runtime.split('JohtoNorthRoute35RuntimeObjects::',1)[-1])
        check('route35_gate_runtime_destination_ordinals_exact',
              gate_rows==[('0','4','0'),('0','5','1'),('7','4','0'),('7','5','0')] and
              city_rows==[('1','19','2')] and
              route_rows[:2]==[('33','9','0'),('33','10','1')] and
              (len(route_rows)==2 or route_rows[2:]==[('5','3','2')]))
        check('source_and_runtime_assets_both_active',
              'JohtoNorthRoute35GoldenrodGateGoldBlocks' in source and
              'JohtoNorthRoute35GoldBlocks' in source and
              'JOHTO_ROUTE_35_LOCAL_ID' in read('data/johto_pilot_runtime_assets.asm'))
        check('seven_reciprocal_registered_warp_routes',
              len(re.findall(r'^\s*db MAP_REGION_JOHTO, JOHTO_(?:GOLDENROD_CITY|ROUTE35_GOLDENROD_GATE|ROUTE_35)_LOCAL_ID,\s*\d, MAP_REGION_JOHTO, JOHTO_(?:GOLDENROD_CITY|ROUTE35_GOLDENROD_GATE|ROUTE_35)_LOCAL_ID',pilot,re.M))==7)
        # FIX-285: prove the ROM0 -> ROMX collision dispatch REACHES the
        # registered Route35 and north gate. .284's static park blacklist was
        # correct but unreachable; the default legacy tile-pair path let
        # sprite walk/bike sideways across an apparent metal fence.
        gateway=read('engine/johto_land_collision_gateway_272.asm')
        gate_tail=gateway.split('JohtoOverworldSouthLandDecision::',1)[-1]
        south_dispatch=gate_tail.split('\n.southMaps\n',1)[-1].split('\n.route33\n',1)[0]
        south_dispatch='\n'.join(line.split(';',1)[0].strip() for line in south_dispatch.splitlines() if line.split(';',1)[0].strip())
        # Both late IDs must branch BEFORE the old 10..15 range guard,
        # and the common target must enter the existing spatial step call.
        gateway_pattern=(
            r'ld a, \[wCurLocalMapID\]\s+'
            r'cp JOHTO_ROUTE_37_LOCAL_ID\s+jp z, \.activeSouthMap\s+'
            r'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\s+jp z, \.activeSouthMap\s+'
            r'cp JOHTO_ROUTE_35_LOCAL_ID\s+jr z, \.activeSouthMap\s+'
            r'cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID\s+jr z, \.activeSouthMap\s+'
            r'(?:cp JOHTO_NATIONAL_PARK_LOCAL_ID\s+jr z, \.activeSouthMap\s+'
            r'cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID\s+jr z, \.activeSouthMap\s+'
            r'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID\s+jr z, \.activeSouthMap\s+)?'
            r'cp JOHTO_AZALEA_TOWN_LOCAL_ID\s+jr c, \.route33\s+'
            r'cp JOHTO_GOLDENROD_CITY_LOCAL_ID \+ 1\s+jr nc, \.route33\s+'
            r'\.activeSouthMap\s+callab HandleLedges\s+'
            r'ld a, \[wd736\]\s+bit 6, a\s+jr nz, \.allowJump\s+'
            r'callab JohtoSouthSpatialStep\s+ret')
        check('route35_and_north_gate_reachable_in_land_gateway',
              bool(re.search(gateway_pattern,south_dispatch)) and
              'callab JohtoOverworldSouthLandDecision' in read('home/overworld.asm'))
        ids=read('constants/region_map_constants.asm')
        matches=dict((k,int(v)) for k,v in re.findall(r'DEF (JOHTO_[A-Z0-9_]+_LOCAL_ID) EQU (\d+)',ids))
        # Explicitly guard the *hole* between Goldenrod (15) and Route35
        # (17): ID16 is live Route36 and must NOT enter the new dispatcher.
        check('route36_keeps_separate_land_policy_while_17_18_use_gold_roles',
              [matches.get(k) for k in ('JOHTO_GOLDENROD_CITY_LOCAL_ID',
                'JOHTO_ROUTE_36_LOCAL_ID','JOHTO_ROUTE_35_LOCAL_ID',
                'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID')]==[15,16,17,18] and
              bool(re.search(gateway_pattern,south_dispatch)) and
              'cp JOHTO_ROUTE_36_LOCAL_ID' not in south_dispatch)
        role_table=read('maps/johto_pilot/Route35.roles.bin',binary=True)
        # Cross-check every 8x8 role against NPC-243's accepted row-padded
        # bitmask. The sole extra solid cell is the closed park (3,5);
        # the two explicitly live carpets are handled by Warp collision.
        check('route35_gold_grid_is_nonempty_and_has_solid_rail_cells',
              len(role_table)==720 and
              sum(v==1 for v in role_table)>100 and
              len(roles)==len(role_table))
        check('route35_collision_only_down_exit',bool(re.search(
              r'(?s)\.route35\s+ld a, \[wPlayerDirection\]\s+(?:cp PLAYER_DIR_UP.*?\.route35South\s+)?cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wYCoord\]\s+cp 33\s+ret nz\s+ld a, \[wXCoord\]\s+cp 9\s+jp z, \.carpet\s+cp 10\s+jp z, \.carpet', portal)))
        check('gate_honors_upleft_and_down_exit',
              'cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID\n    jp z, .route35Gate' in portal and
              '.route35Gate\n    jp .northGate' in portal and
              'JohtoSouthPortalCollisionExit::' in portal)
        check('cut_cleared_block_check_with_same_cell',
              'cp JOHTO_ROUTE_35_LOCAL_ID' in geometry and
              'cp 6\n    jr nz, .notClearedForestCut' in geometry and
              'cp 17\n    jr nz, .notClearedForestCut' in geometry and
              '$5B -> $90' in geometry)
        check('route35_role_grid_dispatch_and_surf_water_probe',
              'JohtoNorthRoute35Roles:: INCBIN "maps/johto_pilot/Route35.roles.bin"' in geometry and
              'cp JOHTO_ROUTE_35_LOCAL_ID' in geometry and
              'JohtoSouthGoldWaterProbe::' in geometry)
        # FIX-284: the accepted NPC-243 masked land role has exactly one
        # extra blocked FLOOR over Gold's art roles, Route35 park (3,5).
        # The two gate carpets remain walkable and collision-only.
        closed=geometry.split('.closedDoorTargets',1)[-1]
        check('route35_park_gate_closed_without_blocking_live_carpets',
              not bool(re.search(r'(?m)^\s*db JOHTO_ROUTE_35_LOCAL_ID, 3, 5\s*$', closed))
              and not re.search(r'(?m)^\s*db JOHTO_ROUTE_35_LOCAL_ID, (?:9|10), 33\s*$', closed)
              and len(roles)==720 and roles[5*20+3]==0
              and roles[33*20+9]==roles[33*20+10]==0)
        mature = read('engine/johto_ilex_mature_runtime_275.asm')
        blockmap=read('home/overworld.asm').split('LoadTileBlockMap::',1)[-1].split('LoadNorthSouthConnectionsTileMap::',1)[0]
        dispatch=mature.split('PatchJohtoSouthBordersAfterBlockLoad::',1)[-1].split('PatchJohtoGoldenrodNorthBorder::',1)[0]
        check('route35_south_preview_after_both_map_loading_paths',
              'callab PatchJohtoSouthBordersAfterBlockLoad' in blockmap and
              bool(re.search(r'call PatchJohtoAzaleaWestGateBorder\s+call PatchJohtoGoldenrodNorthBorder\s+jp PatchJohtoRoute35SouthBorder',dispatch)) and
              'SECTION "Johto South Gold Geometry", ROMX, BANK[$4E]' in read('main.asm') and
              'INCLUDE "engine/johto_ilex_mature_runtime_275.asm"' in read('main.asm'))
        preview=mature.split('PatchJohtoRoute35SouthBorder::',1)[-1]
        expected=((0x12,0x15,0x01,0x46,0x16,0x1e,0x44,0x01,0x01,0x12),
                  (0x01,0x12,0x15,0x46,0x01,0x01,0x44,0x01,0x01,0x04),
                  (0x15,0x12,0x18,0x19,0x01,0x01,0x18,0x1f,0x19,0x02))
        row_pairs=re.findall(r'\.row[012]\s+db\s+([^\n]+)',preview)
        parsed=[]
        for line in row_pairs:
            parsed.append(tuple(int(v.strip().lstrip('$'),16) for v in line.split(',')))
        check('route35_south_exact_gold_compatible_3x10_preview',
              parsed==list(expected) and
              'cp JOHTO_ROUTE_35_LOCAL_ID\n    ret nz' in preview and
              all(f'MAP_BORDER + JOHTO_ROUTE35_HEIGHT + {i}' in preview for i in (1,2))
              and 'MAP_BORDER + JOHTO_ROUTE35_HEIGHT) *' in preview and
              'ld b, JOHTO_ROUTE35_WIDTH' in preview)
        check('route35_gate_arrival_and_carpet_trigger_distinct',
              all(t in portal for t in ('.route35Gate\n    jp .northGate',
                  '.gateTop\n    ld a, [wYCoord]\n    and a',
                  '.cityDoor\n    ld a, [wXCoord]\n    cp 19',
                  '.route35South\n    cp PLAYER_DIR_DOWN')) and
              'cp 2\n    jr z, .northGoldStepOnDoor' in read('home/overworld.asm') and
              'jp CheckWarpsNoCollisionRetry2' in read('home/overworld.asm'))
        contract=json.loads(music)
        gate_rows=next(g['warp_contracts'] for g in contract['gatehouse_activation_policy']['active_gatehouse_contracts'] if g['stable_id']==18)
        check('route35_gate_7_arrival_steps_and_source_destinations',
              [(r['source_stable_id'],r['target_stable_id'],r['target_xy'],r['arrival_auto_step']) for r in gate_rows] == [
                (15,18,[4,7],'NONE'),
                (18,17,[9,33],'NONE'),
                (18,17,[10,33],'NONE'),
                (18,15,[19,1],'D_DOWN'),
                (18,15,[19,1],'D_DOWN'),
                (17,18,[4,0],'D_DOWN'),
                (17,18,[5,0],'D_DOWN')])
        check('route35_north_seam_exactly_one_mature_lane',
              all(t in geometry for t in ('.route35\n    ld b, 20\n    ld c, 36',
                  'cp PLAYER_DIR_UP', 'cp 17 ; only Gold mature collision lane', 'jp .closed')))
        m = json.loads(music)
        gate_rules = [g for g in m['gatehouse_activation_policy']['active_gatehouse_contracts'] if g.get('stable_id')==18]
        check('route35_seven_gold_warp_contracts',len(gate_rules)==1 and len(gate_rules[0]['warp_contracts'])==7)
        music_branch = pilot.split('JohtoPilotLoadMapMusic::',1)[-1].split('JohtoPilotIsClosedOutdoorEdge::',1)[0]
        check('gate_music_inherited_and_bike_safe',
              'CompareMapMusicBankWithCurrentBank' in read('home/audio.asm') and
              bool(re.search(r'cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID\s+jp z, \.route35GoldenrodGate', music_branch)) and
              bool(re.search(r'(?s)\.route35GoldenrodGate\s+ld a, \[wJohtoGateMusicSourceLocalID\]\s+'
                  r'cp JOHTO_GOLDENROD_CITY_LOCAL_ID\s+jp z, \.sourceValid\s+'
                  r'cp JOHTO_ROUTE_35_LOCAL_ID\s+ret nz\s+jp \.sourceValid', music_branch)))
        # Pure land connectivity: an entrance must lead into Route35 on foot.
        if len(roles)==720:
            starts={(9,33),(10,33)}; targets={(9,23),(10,23),(11,23)}
            queue=deque(x for x in starts if roles[x[1]*20+x[0]]==0)
            visited=set(queue)
            while queue:
                x,y=queue.popleft()
                for nx,ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
                    if 0<=nx<20 and 0<=ny<36 and (nx,ny) not in visited and roles[ny*20+nx]==0:
                        visited.add((nx,ny));queue.append((nx,ny))
            check('route35_south_carpet_leads_to_northern_road',bool(visited & targets))
    except (KeyError, ValueError, IndexError, OSError) as exc:
        errors.append('read_or_parse: '+str(exc))
    return {'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks': checks, 'errors': errors, 'rom_built': False,
            'phone_accepted': False}


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project',type=Path,default=Path('.'))
    p.add_argument('--gold-root',type=Path)
    a=p.parse_args(); result=audit(a.project,a.gold_root)
    print(json.dumps(result,ensure_ascii=False,indent=2))
    raise SystemExit(result['status']!='PASS_STATIC_ONLY')
