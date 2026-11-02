#!/usr/bin/env python3
"""DEV-328 fail-closed southern route static/Gold contract.

Geometry, previews, warp directions, masks and gameplay dispatch are distinct
obligations. This is not a linked-ROM or simulator movement test.
"""
from __future__ import annotations
import argparse
import hashlib
import re
from pathlib import Path
from typing import Mapping

BLOCKS = {'Route45':(10,45),'Route46':(10,18),'Route29Route46Gate':(5,4)}
MAP_IDS = {'Route45':72, 'Route46':73, 'Route29Route46Gate':74}
WARP_ROWS = (
    ('JOHTO_ROUTE_29_LOCAL_ID',0,'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID'),
    ('JOHTO_ROUTE_46_LOCAL_ID',0,'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID'),
    ('JOHTO_ROUTE_46_LOCAL_ID',1,'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID'),
    ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID',0,'JOHTO_ROUTE_46_LOCAL_ID'),
    ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID',1,'JOHTO_ROUTE_46_LOCAL_ID'),
    ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID',2,'JOHTO_ROUTE_29_LOCAL_ID'),
    ('JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID',3,'JOHTO_ROUTE_29_LOCAL_ID'),
)
EDGES = (
 ('JOHTO_BLACKTHORN_CITY_LOCAL_ID','SOUTH','JOHTO_ROUTE_45_LOCAL_ID'),
 ('JOHTO_ROUTE_45_LOCAL_ID','NORTH','JOHTO_BLACKTHORN_CITY_LOCAL_ID'),
 ('JOHTO_ROUTE_45_LOCAL_ID','WEST','JOHTO_ROUTE_46_LOCAL_ID'),
 ('JOHTO_ROUTE_46_LOCAL_ID','EAST','JOHTO_ROUTE_45_LOCAL_ID'),
 ('JOHTO_ROUTE_46_LOCAL_ID','SOUTH','JOHTO_ROUTE_29_LOCAL_ID'),
 ('JOHTO_ROUTE_29_LOCAL_ID','NORTH','JOHTO_ROUTE_46_LOCAL_ID'),
)

def audit(root: Path, gold_root: Path|None=None, overrides: Mapping[str, str|bytes]|None=None) -> dict:
    root=Path(root); overrides=overrides or {}; checks=[]; errors=[]
    def get(rel:str)->bytes:
        v=overrides.get(rel)
        return v.encode() if isinstance(v,str) else v if isinstance(v,bytes) else (root/rel).read_bytes()
    def txt(rel):return get(rel).decode('utf8')
    def test(name,okay,detail=''):
        checks.append({'check':name,'status':'PASS' if okay else 'FAIL','detail':detail})
        if not okay: errors.append(name+((' '+detail) if detail else ''))
    try:
        constants=txt('constants/region_map_constants.asm')
        assets=txt('data/johto_pilot_runtime_assets.asm')
        source=txt('data/johto_pilot_source_resources.asm')
        headers=txt('data/johto_header_descriptors.asm')
        gold_src=txt('data/johto_south_chain_runtime_328.asm')
        east=txt('data/johto_east_runtime_300.asm')
        edges=txt('data/johto_pilot_map_headers.asm')
        runtime=txt('engine/johto_pilot_runtime.asm')
        vgate=txt('data/johto_vertical_gate_runtime_314.asm')
        test('exact_current_47_active', bool(re.search(r'(?m)^DEF NUM_JOHTO_ACTIVE_MAPS EQU 47$',constants)))
        test('no_icepath_or_plot_activation', 'JOHTO_ICE_PATH_LOCAL_ID, JOHTO_PILOT_TILESET_ID' not in assets and
             'JohtoIcePathRuntimeHeader' not in headers and 'db 0 ; dialogue deferred, gate traversable' in gold_src)
        test('all_three_headers_registered',all('dw '+s in headers and 'db BANK('+s+')' in headers for s in
             ('JohtoRoute45RuntimeHeader','JohtoRoute46RuntimeHeader','JohtoRoute29Route46GateRuntimeHeader')))
        test('three_runtime_descriptors_and_role_tables',all(x in assets for x in
             ('db JOHTO_ROUTE_45_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_ROUTE_45_WIDTH, JOHTO_ROUTE_45_HEIGHT',
              'db JOHTO_ROUTE_46_LOCAL_ID, JOHTO_PILOT_TILESET_ID, JOHTO_ROUTE_46_WIDTH, JOHTO_ROUTE_46_HEIGHT',
              'db JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, JOHTO_GATE, 5, 4')) and all(
                'maps/johto_pilot/'+m+'.roles.bin' in gold_src for m in ('Route45','Route46')))
        for name,(w,h) in BLOCKS.items():
            orig=get('maps/johto_pilot/'+name+'.gold.blk')
            runtime_asset=get('maps/johto_pilot/'+name+'.runtime.blk')
            test('Gold_source_size_'+name,len(orig)==w*h,f'{len(orig)} vs {w*h}')
            if gold_root:
                origfile='NorthSouthGate' if name=='Route29Route46Gate' else name
                test('Gold_exact_original_'+name,orig==(Path(gold_root)/'maps'/(origfile+'.blk')).read_bytes())
            if name!='Route29Route46Gate':
                test('Gold_runtime_blocks_'+name,orig==runtime_asset)
            else:
                test('converted_gate_tileset_layout',len(runtime_asset)==20 and runtime_asset==get('maps/johto_pilot/Route43Gate.runtime.blk'))
        test('Route46_north_preview_matches_full_source',get('maps/johto_pilot/Route46.north_route29_mirror.blk')==get('maps/johto_pilot/Route46.runtime.blk'))
        test('Route29_south_preview_matches_full_source',get('maps/johto_pilot/Route29.south_route46_mirror.blk')==get('maps/johto_pilot/Route29.runtime.blk'))
        # Gold's connection offset -10 / +10 blocks does not imply a walkable seam.
        route29=edges.split('JohtoPilotRoute29RuntimeHeader::',1)[1].split('JohtoPilotRoute29RuntimeHeaderEnd::',1)[0]
        test('Route29_north_preview_not_default_trees','db NORTH | WEST | EAST' in route29 and
             'dw JohtoRoute46Route29NorthMirror + JOHTO_ROUTE_46_WIDTH * (JOHTO_ROUTE_46_HEIGHT - 3)' in route29 and
             'db JOHTO_ROUTE_46_WIDTH\n    db JOHTO_ROUTE_46_WIDTH' in route29 and
             'ASSERT JohtoPilotRoute29RuntimeHeaderEnd - JohtoPilotRoute29RuntimeHeader == 45' in edges)
        r46=gold_src.split('JohtoRoute46RuntimeHeader::',1)[1].split('JohtoRoute46HeaderEnd::',1)[0]
        test('Route46_south_preview_not_default_trees','db SOUTH | EAST' in r46 and 'dw JohtoRoute29Mirror + 10' in r46)
        test('Route29_to_Route46_is_preview_only','.route46South\n    ld a, [wYCoord]\n    cp JOHTO_ROUTE_46_HEIGHT * 2 - 1\n    jp nc, .closed' in east and 'JohtoVerticalGateClosedEdge314' in vgate)
        test('Gold_border_exact', 'db $71 ; Gold rock border' in gold_src and 'db $05 ; Gold Route46 trees' in gold_src)
        records=source.split('JohtoPilotSourceConnections::',1)[1].split('JohtoPilotSourceConnectionsEnd::',1)[0]
        test('six_independent_directed_source_edges', all(records.count('db MAP_REGION_JOHTO, '+a+', '+d+', MAP_REGION_JOHTO, '+b)==1 for a,d,b in EDGES))
        warp=runtime.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        test('seven_original_gate_warps_exact',all(warp.count('db MAP_REGION_JOHTO, '+a+', '+str(n)+', MAP_REGION_JOHTO, '+b)==1 for a,n,b in WARP_ROWS))
        route29objects=edges.split('JohtoPilotRoute29RuntimeObjects::',1)[1].split('\nJohto',1)[0] if 'JohtoPilotRoute29RuntimeObjects::' in edges else txt('data/johto_pilot_map_objects.asm') if (root/'data/johto_pilot_map_objects.asm').exists() else ''
        test('north_gate_four_carpets','db 4 ; Gold top pair -> Route46; bottom pair -> Route29' in gold_src and all(
              row in gold_src for row in ('db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 0, 5, 1, JOHTO_REGISTERED_WARP_SELECTOR','db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 7, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR')))
        test('Route46_two_north_gate_doors','db 33, 7, 0, JOHTO_REGISTERED_WARP_SELECTOR' in gold_src and 'db 33, 8, 1, JOHTO_REGISTERED_WARP_SELECTOR' in gold_src)
        test('Route29_single_north_gate_door','db 1, 27, 2, JOHTO_REGISTERED_WARP_SELECTOR' in edges)
        role45=get('maps/johto_pilot/Route45.roles.bin');role46=get('maps/johto_pilot/Route46.roles.bin')
        test('Route45_16_Gold_water',len(role45)==1800 and role45.count(2)==16)
        test('Route46_no_water',len(role46)==720 and role46.count(2)==0)
        test('BlackthornRoute45_live_south', all(x in east for x in ('cp JOHTO_BLACKTHORN_CITY_HEIGHT * 2 - 1','jp .southLaneGold','.route45North')))
        test('Route45_Route46_linked_west', all(x in east for x in ('.route45West','.route46East','cp 72','cp 82')))
        test('Route45_Route46_hops_registered',all(x in txt('engine/overworld/ledges.asm') for x in
             ('JohtoRoute45GoldHops:','JohtoRoute46GoldHops:')))
        test('Gold_gate_music_and_bike_source', 'and $f4' in txt('home/overworld.asm') and 'cp JOHTO_MAHOGANY_TOWN_LOCAL_ID' in txt('home/overworld.asm') and
             'cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID' in txt('engine/menu/options_menu.asm') and
             'cp JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID' in runtime)
    except (KeyError,ValueError,IndexError,OSError,UnicodeError) as e:
        test('audit_source_integrity',False,str(e))
    return dict(status='PASS_STATIC_ONLY' if not errors else 'FAIL',checks=checks,errors=errors,
                rom_built=False,device_verified=False)

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--project',type=Path,default=Path.cwd())
    p.add_argument('--gold-root',type=Path)
    a=p.parse_args()
    import json
    r=audit(a.project,a.gold_root)
    print(json.dumps(r,ensure_ascii=False,indent=2))
    raise SystemExit(bool(r['errors']))
