#!/usr/bin/env python3
"""MAP-286: executable-source audit of Park, two gates and Route35/36 continuity.

Gold .blk bytes, RPP runtime descriptors, exact reciprocal Warp ordinals,
directional collisions, park-only art, music/bicycle and legacy 36 Ruins
ordinals are inspected. This is NOT a ROM build or device-play proof.
"""
from __future__ import annotations
from pathlib import Path
import argparse
import json
import re

MAPS={
    'NationalPark':('NationalPark',540,2160),
    'Route35NationalParkGate':('Route35NationalParkGate',16,64),
    'Route36NationalParkGate':('Route36NationalParkGate',20,80),
}

def audit(root:Path,gold_root:Path|None=None,changes:dict|None=None)->dict:
    root=Path(root);gold_root=Path(gold_root) if gold_root else None
    changes=changes or {};checks=[];errors=[]
    def read(rel,binary=False):
        obj=changes.get(rel)
        if obj is None: obj=(root/rel).read_bytes() if binary else (root/rel).read_text()
        if binary: return obj if isinstance(obj,bytes) else obj.encode()
        return obj.decode() if isinstance(obj,bytes) else obj
    def ck(name,good):
        checks.append({'check':name,'status':'PASS' if good else 'FAIL'})
        if not good: errors.append(name)
    try:
        c=read('constants/region_map_constants.asm')
        ids=read('constants/johto_fixed_map_ids.asm')
        version=read('data/game_version.asm')
        headers=read('data/johto_header_descriptors.asm')
        src=read('data/johto_pilot_source_resources.asm')
        code=read('data/johto_park_runtime_286.asm')
        park=read('engine/johto_south_geometry.asm')
        portals=read('engine/johto_south_portals.asm')
        gateway=read('engine/johto_land_collision_gateway_272.asm')
        reg=read('engine/johto_pilot_runtime.asm')
        old=read('data/johto_ruins_north_runtime.asm')
        bike=read('data/bike_riding_tilesets.asm')
        ptrs=read('data/warp_tile_ids.asm')
        main=read('main.asm')
        colors=read('color/data/map_palette_sets.asm')
        music=read('tools/johto_gate_music_bike_contracts.json')
        doors=json.loads(read('tools/johto_pilot_door_contracts.json'))
        ck('version_286_and_26_active', re.search(r'(?:FIX|MAP)-5\.62\.(?:288|289|290|294|295)@',version) is not None and 'TEST-231@' in version
            and re.search(r'NUM_JOHTO_ACTIVE_MAPS EQU (?:26|28)\b', c) is not None and '== NUM_JOHTO_ACTIVE_MAPS * JOHTO_HEADER_DESCRIPTOR_BYTES' in headers)
        ck('frozen_stable_ids_and_dimensions',all(x in ids for x in (
            'JOHTO_NATIONAL_PARK_LOCAL_ID EQU 103',
            'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID EQU 104',
            'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID EQU 105'))
            and all(x in c for x in ('JOHTO_NATIONAL_PARK_WIDTH EQU 20',
                                      'JOHTO_ROUTE35_PARK_GATE_WIDTH EQU 4',
                                      'JOHTO_ROUTE36_PARK_GATE_WIDTH EQU 5')))
        for name,(gold_name,block_size,role_size) in MAPS.items():
            actual=read(f'maps/johto_pilot/{name}.gold.blk',True)
            runtime=read(f'maps/johto_pilot/{name}.runtime.blk',True)
            roles=read(f'maps/johto_pilot/{name}.roles.bin',True)
            ck(f'{name}_source_runtime_exact',len(actual)==len(runtime)==block_size and actual==runtime
                and (not gold_root or actual==(gold_root/'maps'/f'{gold_name}.blk').read_bytes()))
            ck(f'{name}_role_bytes',len(roles)==role_size and all(x in (0,1,2) for x in roles))
        ck('park_unique_tileset_and_gate_metatiles', all(x in code for x in (
            'JohtoParkRuntimeHeader::\n    db JOHTO_PARK',
            'JohtoParkSouthGateRuntimeHeader::\n    db JOHTO_PARK_GATE',
            'JohtoParkEastGateRuntimeHeader::\n    db JOHTO_PARK_GATE',
            'JohtoPark_GFX:: INCBIN "gfx/tilesets/johto_park.2bpp"',
            'JohtoParkGate_GFX:: INCBIN "gfx/tilesets/johto_park_gate.2bpp"'))
            and all((root/x).is_file() for x in (
                'gfx/tilesets/johto_park.png','gfx/tilesets/johto_park_gate.png',
                'gfx/blocksets/johto_park.bst','gfx/blocksets/johto_park_gate.bst')))
        ck('new_warp_pointer_table_in_bounds', 'dw JohtoParkWarpTileIDs' in ptrs and
            'dw JohtoParkGateWarpTileIDs' in ptrs and '(JOHTO_PARK_GATE + 1) * 2' in ptrs)
        ck('park_and_gate_bank50_mounted', 'SECTION "Johto Park Runtime 286", ROMX, BANK[$50]' in main
           and 'INCLUDE "data/johto_park_runtime_286.asm"' in main)
        ck('new_headers_in_final_active_slots', all(x in headers for x in (
            'dw JohtoParkRuntimeHeader','dw JohtoParkSouthGateRuntimeHeader','dw JohtoParkEastGateRuntimeHeader'))
           and 'JohtoParkGoldBlocks' in src and 'JohtoParkEastGateGoldBlocks' in src)
        ck('park_and_gates_reach_land_collision', all(f'cp {x}' in gateway for x in (
            'JOHTO_NATIONAL_PARK_LOCAL_ID','JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID',
            'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID')))
        ck('park_original_gold_roles_reachable', all(x in park for x in (
            '.NationalPark','JohtoParkRoles:: INCBIN "maps/johto_pilot/NationalPark.roles.bin"',
            '.SouthParkGate','.EastParkGate')))
        ck('park_two_directional_gate_entrances',all(x in portals for x in (
            '.parkSouthGate','.parkEastGate','cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID',
            'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID',
            'cp JOHTO_NATIONAL_PARK_LOCAL_ID')))
        def rows(section_name,next_name):
            body=code.split(section_name+'::',1)[-1].split(next_name+'::',1)[0]
            return re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*JOHTO_REGISTERED_WARP_SELECTOR',body)
        ck('park_object_destinations_exact', rows('JohtoParkRuntimeObjects','JohtoParkSouthGateBlocks')==
            [('18','33','0'),('19','33','1'),('47','10','0'),('47','11','1')])
        ck('south_gate_object_destinations_exact',rows('JohtoParkSouthGateRuntimeObjects','JohtoParkEastGateBlocks')==
            [('0','3','2'),('0','4','3'),('7','3','2'),('7','4','2')])
        ck('east_gate_object_destinations_exact',rows('JohtoParkEastGateRuntimeObjects','JohtoParkEastGateRuntimeObjectsEnd')==
            [('4','0','0'),('5','0','1'),('4','9','2'),('5','9','3')])
        # Cross the authentic 36 Ruins #3/#4 as source ordinals0/1; Park source2/3 only.
        ck('old_route36_ruins_warps_preserved', all(x in old for x in (
            'db 13, 47, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 13, 48, 1, JOHTO_REGISTERED_WARP_SELECTOR')) and
            'db 8, 18, 2, JOHTO_REGISTERED_WARP_SELECTOR' in old and
            'db 9, 18, 3, JOHTO_REGISTERED_WARP_SELECTOR' in old)
        ck('park_music_gate_reuse_and_bike_rules',all(x in reg for x in (
            'cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID',
            'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID')) and
            'JOHTO_PARK,$FF' in bike and 'JOHTO_PARK_GATE,$FF' not in bike and
            'MAP-286' in colors and 'Route35NationalParkGate' in music)
        ck('park_not_unlocked_as_fly_city', 'JOHTO_NATIONAL_PARK_LOCAL_ID' not in read('engine/fly_town_map_helpers.asm'))
        ck('park_transfers_registered',sum('JOHTO_NATIONAL_PARK_LOCAL_ID' in l or
            'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID' in l or
            'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID' in l
            for l in reg.splitlines() if l.strip().startswith('db MAP_REGION_JOHTO'))>=15)
        ck('both_gate_contracts_present',len(doors['gatehouse_activation_policy']['active_gatehouse_contracts'])==8)
    except (OSError,ValueError,KeyError) as e:
        ck('audit_inputs_complete',False)
        errors.append(str(e))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,
            'rom_built':False,'phone_accepted':False}

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=Path.cwd());ap.add_argument('--gold-root',type=Path)
    args=ap.parse_args();result=audit(args.project,args.gold_root)
    print(json.dumps({'status':result['status'],'checks':len(result['checks']),'errors':result['errors']},ensure_ascii=False,indent=2))
    raise SystemExit(0 if result['status']=='PASS_STATIC_ONLY' else 1)
