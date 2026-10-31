#!/usr/bin/env python3
"""MAP-294 fail-closed live Route36 -> Route37 -> Ecruteak contract.

This checks actual ASM dispatch, byte sources, bank-local scripts/mirrors,
precise allowed edge positions and reviewed display strips; not emulator proof.
"""
from __future__ import annotations
import re
from pathlib import Path

def audit(root:Path,gold_root:Path|None=None,changes:dict|None=None):
    root=Path(root); changes=changes or {}; checks=[]; errors=[]
    def read(rel,binary=False):
        if rel in changes:
            raw=changes[rel]
            return (raw if isinstance(raw,bytes) else raw.encode()) if binary else (raw.decode() if isinstance(raw,bytes) else raw)
        return (root/rel).read_bytes() if binary else (root/rel).read_text()
    def ck(name,condition):
        checks.append({'check':name,'status':'PASS' if condition else 'FAIL'})
        if not condition:errors.append(name)
    try:
        region=read('constants/region_map_constants.asm'); ids=read('constants/johto_fixed_map_ids.asm')
        headers=read('data/johto_header_descriptors.asm')
        slots=read('data/johto_stable_id_slots.asm')
        corridor=read('data/johto_corridor_runtime_294.asm')
        ru36=read('data/johto_ruins_north_runtime.asm')
        source=read('data/johto_pilot_source_resources.asm')
        land=read('engine/johto_land_collision_gateway_272.asm')
        edge=read('engine/johto_pilot_runtime.asm')
        tile=read('engine/johto_south_geometry.asm')
        main=read('main.asm')
        version=read('data/game_version.asm')
        ck('version_and_28_active', ('MAP-5.62.294@' in version or 'FIX-5.62.295@' in version) and 'TEST-231@' in version and
           'NUM_JOHTO_ACTIVE_MAPS EQU 28' in region and 'JOHTO_ROUTE_37_LOCAL_ID EQU 21' in ids and
           'JOHTO_ECRUTEAK_CITY_LOCAL_ID EQU 22' in ids)
        ck('two_real_headers_and_active_slots', all(x in headers for x in
           ('dw JohtoRoute37RuntimeHeader','dw JohtoEcruteakRuntimeHeader')) and
           'db 12, 22, 21, 11, 10, 26, 27,' in slots)
        pairs=(('Route37',90),('EcruteakCity',360))
        for name,n in pairs:
            blk=read(f'maps/johto_pilot/{name}.runtime.blk',True)
            base=read(f'maps/johto_pilot/{name}.gold.blk',True)
            ck(name+'_gold_unchanged',len(blk)==n and blk==base and
               (gold_root is None or base==(Path(gold_root)/'maps'/f'{name}.blk').read_bytes()))
        ck('bank_local_scripts_and_mirrors',all(x in corridor for x in (
           'JohtoCorridorLocalScript::',
           'ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoCorridorLocalScript)',
           'ASSERT BANK(JohtoEcruteakRuntimeHeader) == BANK(JohtoCorridorLocalScript)',
           'ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoRoute37NorthEcruteakMirror)',
           'ASSERT BANK(JohtoRoute37RuntimeHeader) == BANK(JohtoRoute37SouthRoute36Mirror)',
           'INCBIN "maps/johto_pilot/Route36.runtime.blk"',
           'INCBIN "maps/johto_pilot/EcruteakCity.runtime.blk"')) and
           'BANK[$51]' in main and 'data/johto_corridor_runtime_294.asm' in main and
           corridor.count('dw JohtoCorridorLocalScript')==2 and 'dw JohtoSouthScript' not in corridor)
        ck('real_land_dispatch_for_both',all(re.search(r'cp '+x+r'\s+jp z, \.activeSouthMap',land) for x in
           ('JOHTO_ROUTE_37_LOCAL_ID','JOHTO_ECRUTEAK_CITY_LOCAL_ID')) and
           'callab JohtoSouthSpatialStep' in land and 'cp JOHTO_ROUTE_36_LOCAL_ID\n    jp z, .activeSouthMap' not in land)
        ck('closed_edges_dispatch_and_single_exit',all(x in edge for x in (
           'callab JohtoCorridor37Edge','callab JohtoCorridorEcruteakEdge')) and
           all(x in corridor for x in ('JohtoCorridor37Edge::','JohtoCorridorEcruteakEdge::',
              'cp 7','cp 8','cp 13 ; align with Route36 north x25..32','cp 17','cp 18','ld e, 1')) and
           'JOHTO_ROUTE_37_LOCAL_ID' in tile and 'JOHTO_ECRUTEAK_CITY_LOCAL_ID' in tile)
        ck('four_reciprocal_routes_and_no_unreviewed_west_east',all(source.count(x)==1 for x in (
           'JOHTO_ROUTE_36_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID',
           'JOHTO_ROUTE_37_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID',
           'JOHTO_ROUTE_37_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID',
           'JOHTO_ECRUTEAK_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID')) and
           not re.search(r'JOHTO_ECRUTEAK_CITY_LOCAL_ID, (?:WEST|EAST),',source))
        ck('north_south_header_mirrors_and_exact_preview',all(x in corridor for x in (
           'db JOHTO_ROUTE37_WIDTH + MAP_BORDER ; Gold north preview',
           'db JOHTO_ROUTE37_WIDTH + MAP_BORDER ; Gold south preview',
           'dw JohtoRoute37NorthEcruteakMirror + JOHTO_ECRUTEAK_WIDTH * (JOHTO_ECRUTEAK_HEIGHT - 3) + 5',
           'dw JohtoRoute37SouthRoute36Mirror + 10',
           'ASSERT JohtoRoute37HeaderEnd - JohtoRoute37RuntimeHeader == 34',
           'ASSERT JohtoEcruteakHeaderEnd - JohtoEcruteakRuntimeHeader == 23')) and
           'JohtoRoute36NorthRoute37Mirror' in ru36 and
           'ASSERT JohtoPilotRoute36RuntimeHeaderEnd - JohtoPilotRoute36RuntimeHeader == 45' in ru36)
        roles=read('maps/johto_pilot/EcruteakCity.roles.bin',True)
        ck('ecruteak_mature_roles_and_surf',len(roles)==40*36 and 1 in roles and 2 in roles and
           'JOHTO_ECRUTEAK_CITY_LOCAL_ID' in tile)
        # Check actual ledge call-path, not merely existence of Gold role bytes.
        hop=read('engine/overworld/ledges.asm')
        for ident, label, takeoffs in (
            ('JOHTO_ROUTE_37_LOCAL_ID','JohtoRoute37GoldHops',6),
            ('JOHTO_ECRUTEAK_CITY_LOCAL_ID','JohtoEcruteakGoldHops',6)):
            marker='cp '+ident+'\n\tjp z, .'+('route37Gold' if '37' in ident else 'ecruteakGold')
            tab=re.search(r'(?ms)^'+label+r':\s*\n(.*?)(?=^Johto\w+GoldHops:|^JohtoAlphSouthHops:)',hop)
            entries=re.findall(r'(?m)^\s*db \d+, \d+, PLAYER_DIR_(?:DOWN|LEFT|RIGHT)\s*$',tab.group(1)) if tab else []
            ck(label+'_live_dispatch_and_ledge_guard',marker in hop and
               hop.count('cp '+ident)>=2 and len(entries)==takeoffs and
               'JohtoSouthHopLandingGuard::' in hop)
        ck('ecruteak_water_20_live_spatial_surf',roles.count(2)==20 and
           'JohtoEcruteakRoles:: INCBIN "maps/johto_pilot/EcruteakCity.roles.bin"' in tile and
           'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID' in tile and
           'JohtoSouthGoldWaterProbe' in read('engine/johto_violet_field_skills.asm'))
        ck('town_and_fly_integration', 'JohtoPilotEcruteakName' in read('engine/fly_town_map_helpers.asm') and
           'JOHTO_ECRUTEAK_CITY_LOCAL_ID' in read('engine/overworld/map_name_sign.asm') and
           'JOHTO_ECRUTEAK_CITY_LOCAL_ID' in read('engine/johto_pilot_runtime.asm'))
    except (OSError,ValueError) as e:
        ck('runtime_sources_readable',False);errors.append(str(e))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors}

if __name__=='__main__':
 import argparse,json
 p=argparse.ArgumentParser();p.add_argument('--project',default='.');p.add_argument('--gold-root');a=p.parse_args()
 result=audit(Path(a.project),Path(a.gold_root) if a.gold_root else None)
 print(json.dumps(result,indent=2));exit(0 if not result['errors'] else 1)
