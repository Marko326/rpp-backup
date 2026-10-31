#!/usr/bin/env python3
"""Read-only runtime contract for Gold Route35/36 and Route36/Violet seams.

This validates actual header strips, bank-safe mirrored block data, map
identity routing, and exact exits; it is not a ROM build or emulator.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

CONNECTIONS=(
    ('JOHTO_ROUTE_35_LOCAL_ID','NORTH','JOHTO_ROUTE_36_LOCAL_ID'),
    ('JOHTO_ROUTE_36_LOCAL_ID','SOUTH','JOHTO_ROUTE_35_LOCAL_ID'),
    ('JOHTO_ROUTE_36_LOCAL_ID','EAST','JOHTO_VIOLET_CITY_LOCAL_ID'),
    ('JOHTO_VIOLET_CITY_LOCAL_ID','WEST','JOHTO_ROUTE_36_LOCAL_ID'),
)

def audit(root:Path,gold_root:Path|None=None,npc_root:Path|None=None,changes:dict|None=None):
    root=Path(root);changes=changes or {};checks=[];errors=[]
    def get(path,binary=False):
        v=changes.get(path)
        if v is None: v=(root/path).read_bytes() if binary else (root/path).read_text()
        return v if binary and isinstance(v,bytes) else (v.encode() if binary else (v.decode() if isinstance(v,bytes) else v))
    def ck(label,good):
        checks.append({'check':label,'status':'PASS' if good else 'FAIL'})
        if not good:errors.append(label)
    def chunk(s,a,b):return s.split(a,1)[1].split(b,1)[0]
    try:
        route36=get('data/johto_ruins_north_runtime.asm')
        route35=get('data/johto_north_runtime_283.asm')
        violet=get('data/johto_pilot_map_headers.asm')
        source=get('data/johto_pilot_source_resources.asm')
        guard=get('engine/johto_pilot_runtime.asm')
        geom=get('engine/johto_south_geometry.asm')
        home=get('home/overworld.asm')
        main=get('main.asm')
        version=get('data/game_version.asm')
        mr36=get('maps/johto_pilot/Route36.runtime.blk',True)
        mr35=get('maps/johto_pilot/Route35.runtime.blk',True)
        mrv=get('maps/johto_pilot/VioletCity.runtime.blk',True)
        ck('gold_original_block_bytes_270_180_360',len(mr36)==270 and len(mr35)==180 and len(mrv)==360 and all(get(f'maps/johto_pilot/{name}.runtime.blk',True)==get(f'maps/johto_pilot/{name}.gold.blk',True) for name in ('Route36','Route35')) and
            sum(a!=b for a,b in zip(mrv,get('maps/johto_pilot/VioletCity.gold.blk',True)))==2)
        if gold_root:
            g=Path(gold_root)
            ck('reference_gold_source_bytes',all(get(f'maps/johto_pilot/{name}.gold.blk',True)==(g/'maps'/f'{name}.blk').read_bytes() for name in ('Route36','Route35','VioletCity')))
            a=(g/'data/maps/attributes.asm').read_text()
            ck('gold_source_connection_topology',all(x in a for x in ('connection north, Route36, ROUTE_36, 0','connection south, Route35, ROUTE_35, 0','connection east, VioletCity, VIOLET_CITY, 0','connection west, Route36, ROUTE_36, 0')))
        if npc_root:
            nr=Path(npc_root)
            mask36=(nr/'maps/JohtoRoute36.blocked_mask.bin').read_bytes()
            mask35=(nr/'maps/JohtoRoute35.blocked_mask.bin').read_bytes()
            def blocked(mask,w,x,y):return bool(mask[y*((w+7)//8)+x//8]&(1<<(x%8)))
            ck('npc_mature_exact_seam_passable_lanes',len(mask36)==144 and len(mask35)==108 and
                all(not blocked(mask36,60,17,y) for y in (16,17)) and
                all(not blocked(mask35,20,17,y) for y in (0,1)) and
                all(blocked(mask36,60,x,17) for x in (16,18,19,20)) and
                all(not blocked(mask36,60,59,y) for y in (8,9)))
        ck('registered_exact_four_and_route37_still_closed',
           all(source.count(f'db MAP_REGION_JOHTO, {a}, {d}, MAP_REGION_JOHTO, {b}')==1 for a,d,b in CONNECTIONS) and
           'DEF JOHTO_PILOT_SOURCE_CONNECTION_COUNT EQU 20' in source and
           'JOHTO_ROUTE_37_LOCAL_ID' not in chunk(source,'JohtoPilotSourceConnections::','JohtoPilotSourceConnectionsEnd::'))
        # The engine copies strips after SwitchToMapRomBank, not a farcall to target.
        ck('connection_loader_uses_source_map_bank',
           'call SwitchToMapRomBank' in home and 'LoadNorthSouthConnectionsTileMap::' in home and 'LoadEastWestConnectionsTileMap::' in home)
        ck('all_four_neighbor_mirrors_are_real_same_bank_payloads',all(x in route36 for x in (
                'JohtoRoute36SouthRoute35Mirror::','INCBIN "maps/johto_pilot/Route35.runtime.blk"',
                'JohtoRoute36EastVioletMirror::','INCBIN "maps/johto_pilot/VioletCity.runtime.blk"',
                'ASSERT BANK(JohtoRoute36SouthRoute35Mirror) == BANK(JohtoPilotRoute36RuntimeHeader)',
                'ASSERT BANK(JohtoRoute36EastVioletMirror) == BANK(JohtoPilotRoute36RuntimeHeader)')) and
           all(x in route35 for x in ('JohtoRoute35NorthRoute36Mirror::','INCBIN "maps/johto_pilot/Route36.runtime.blk"',
                'ASSERT BANK(JohtoRoute35NorthRoute36Mirror) == BANK(JohtoNorthRoute35RuntimeHeader)')) and
           all(x in violet for x in ('JohtoVioletWestRoute36Mirror::','INCBIN "maps/johto_pilot/Route36.runtime.blk"',
                'ASSERT BANK(JohtoVioletWestRoute36Mirror) == BANK(JohtoPilotVioletRuntimeHeader)')) and
           all(x in main for x in ('BANK[$43]','BANK[$4A]','BANK[$4C]')))
        h36=chunk(route36,'JohtoPilotRoute36RuntimeHeader::','JohtoPilotRoute36RuntimeHeaderEnd::')
        h35=chunk(route35,'JohtoNorthRoute35RuntimeHeader::','JohtoNorthRoute35HeaderEnd::')
        hv=chunk(violet,'JohtoPilotVioletRuntimeHeader::','JohtoPilotVioletRuntimeHeaderEnd::')
        ck('route36_south_and_east_header_11_byte_records',all(t in h36 for t in (
                'db SOUTH | EAST','dw JohtoRoute36SouthRoute35Mirror',
                'dw wOverworldMap + (JOHTO_ROUTE_36_HEIGHT + 3) * (JOHTO_ROUTE_36_WIDTH + 6) + 3',
                'dw JohtoRoute36EastVioletMirror',
                'dw wOverworldMap + 3 * (JOHTO_ROUTE_36_WIDTH + 6) + JOHTO_ROUTE_36_WIDTH + 3',
                'db JOHTO_VIOLET_CITY_WIDTH')) and
           'ASSERT JohtoPilotRoute36RuntimeHeaderEnd - JohtoPilotRoute36RuntimeHeader == 34' in route36)
        ck('route35_north_header_same_bank_copy',all(t in h35 for t in (
                'db NORTH','dw JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)',
                'db JOHTO_ROUTE36_WIDTH' if False else 'db JOHTO_ROUTE_36_WIDTH',
                'db JOHTO_ROUTE_36_HEIGHT * 2 - 1',
                'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10')) and
           'ASSERT JohtoNorthRoute35HeaderEnd - JohtoNorthRoute35RuntimeHeader == 23' in route35)
        # Old NPC ILEX-223 visual seam regression: the Route35 north strip
        # must copy 10 map columns plus 3 right-side border preview columns.
        # This is a screen-only extension; it does NOT widen the x=17 exit.
        # The loader always writes three rows with the width from the header.
        # Its target starts at buffer col3; 3+13 is exactly the 16-column
        # map-with-border buffer width (Route35 width10 + six border cols).
        preview_width=10+3
        buffer_width=10+2*3
        src_row=(9-3)
        source_start=src_row*30
        preview_bytes=[mr36[(src_row+r)*30:(src_row+r)*30+preview_width]
                       for r in range(3)]
        header_preview= 'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10' in h35
        ck('route35_north_thirteen_column_right_preview',header_preview and
           'dw wOverworldMap + 3' in h35 and
           'dw JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)' in h35 and
           preview_width==13 and 3+preview_width==buffer_width and
           source_start+2*30+preview_width<=len(mr36) and
           len(preview_bytes)==3 and all(len(row)==13 for row in preview_bytes) and
           all(row[10:13]==mr36[(src_row+r)*30+10:(src_row+r)*30+13] for r,row in enumerate(preview_bytes)))
        # Read source/dest from live header and reject a generic constant or
        # accidentally widened 14+ column expression even when script 'passes'.
        declared=re.findall(r'^\s*db\s+JOHTO_ROUTE35_WIDTH\s*\+\s*MAP_BORDER\b',h35,re.M)
        ck('route35_north_display_buffer_exact_capacity',len(declared)==1 and
           'db JOHTO_ROUTE_36_WIDTH' in h35 and
           'ld a,[wNorthConnectionStripWidth]' in home and
           'ld [hNorthSouthConnectionStripWidth],a' in home and
           'call LoadNorthSouthConnectionsTileMap' in home and
           'ld c,MAP_BORDER' in chunk(home,'LoadNorthSouthConnectionsTileMap::','LoadEastWestConnectionsTileMap::'))
        if gold_root:
            ck('route35_north_preview_gold_bytes',
               all(preview_bytes[r] == (Path(gold_root)/'maps/Route36.blk').read_bytes()[(src_row+r)*30:(src_row+r)*30+13] for r in range(3)))
        ck('violet_west_header_retains_south_route32_east_route31',all(t in hv for t in (
                'db SOUTH | WEST | EAST','dw JohtoPilotRoute32RuntimeBlocks',
                'dw JohtoVioletWestRoute36Mirror + JOHTO_ROUTE_36_WIDTH - 3',
                'dw JohtoPilotRoute31RuntimeBlocks', 'db JOHTO_ROUTE_36_WIDTH * 2 - 1')) and
           'ASSERT JohtoPilotVioletRuntimeHeaderEnd - JohtoPilotVioletRuntimeHeader == 45' in violet)
        r36=chunk(guard,'.route36Edge','.northGateEdge')
        rv=chunk(guard,'\n.violet\n','\n.route32\n')
        r35=chunk(geom,'\n.route35\n','\n.route35Gate\n')
        ck('route36_only_two_gold_boundary_lanes',all(s in r36 for s in (
                'cp JOHTO_ROUTE_36_WIDTH * 2 - 1','cp 8\n    ret z\n    cp 9\n    ret z',
                'cp JOHTO_ROUTE_36_HEIGHT * 2 - 1','cp 17\n    ret z',
                '.route36Up','and a\n    ret nz\n    jp .closed')))
        ck('route35_single_mature_north_lane',all(s in r35 for s in ('cp PLAYER_DIR_UP','cp 17 ; only Gold mature collision lane','ret z','jp .closed')))
        ck('violet_only_gold_west_two_rows_and_old_gate_unchanged',all(s in rv for s in (
                'cp PLAYER_DIR_LEFT','cp 8\n    ret z\n    cp 9\n    ret z','cp PLAYER_DIR_RIGHT',
                'cp 14','cp 16')))
        ck('existing_park_and_ruins_warps_unchanged',all(s in route36 for s in (
                'db 13, 47, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                'db 13, 48, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                'db 8, 18, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                'db 9, 18, 3, JOHTO_REGISTERED_WARP_SELECTOR')))
        ck('in_rom_version_and_test_label', 'FIX-5.62.290@' in version and 'TEST-231@' in version)
    except (KeyError,IndexError,OSError,ValueError) as e:errors.append('audit_source_exception: '+str(e))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors}

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--project',type=Path,default=Path('.'))
    parser.add_argument('--gold-root',type=Path)
    parser.add_argument('--npc-root',type=Path)
    a=parser.parse_args();r=audit(a.project,a.gold_root,a.npc_root)
    print(json.dumps(r,ensure_ascii=False,indent=2));raise SystemExit(bool(r['errors']))
