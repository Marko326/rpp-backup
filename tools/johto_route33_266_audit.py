#!/usr/bin/env python3
"""R33-266 independent Gold source and live-RPP southern cave contract.

Checks exact binary art, collision matrix, precision exceptions and reverse
Warp rows. Read-only; never claims linking, ROM execution or phone acceptance.
"""
from __future__ import annotations
from pathlib import Path
import argparse, json, re, sys
from PIL import Image
from johto_gold_door_audit import GoldCollisionIndex
from johto_indoor_tiles_converter import strict_2bpp
from johto_field_move_coverage_audit import _coordinate_hop_entries, _gold_safe_hop_directions



def audit(root:Path, gold:Path)->dict:
    root,gold=Path(root),Path(gold)
    checks=[];issues=[]
    def check(name,ok,detail):
        checks.append({'name':name,'result':'PASS' if ok else 'FAIL','detail':detail})
        if not ok: issues.append(f'{name}: {detail}')
    def get(path): return (root/path).read_bytes()
    def text(path): return (root/path).read_text()
    try:
        gold_blocks=(gold/'maps/Route33.blk').read_bytes()
        check('gold_map_full_original',len(gold_blocks)==90 and get('maps/johto_pilot/Route33.gold.blk')==gold_blocks
              and get('maps/johto_pilot/Route33.runtime.blk')==gold_blocks,'Gold Route33 10x9 exact block IDs')
        gold_modern=(gold/'data/tilesets/johto_modern_metatiles.bin').read_bytes()
        check('independent_gold_metatiles',len(gold_modern)==2048 and get('gfx/blocksets/johto_modern.bst')==gold_modern,
              '128 independent Gold modern metatiles, no Johto pilot art reuse')
        png=gold/'gfx/tilesets/johto_modern.png'
        converted=strict_2bpp(Image.open(png),96)
        source_converted=strict_2bpp(Image.open(root/'gfx/tilesets/johto_modern.png'),96)
        check('gold_tileset_png_source',len(converted)==1536 and source_converted==converted,
              '96 Gold tiles verified from tracked PNG source; .2bpp is ignored build output')
        check('gold_tilepal',text('color/tilesets/johto_modern.asm')==
              (gold/'gfx/tilesets/johto_modern_palette_map.asm').read_text(),
              '12 rows of Gold johto_modern tilepal')
        index=GoldCollisionIndex(gold); cells=index.cells('Route33')
        allowed={'FLOOR','TALL_GRASS','HOP_DOWN','HOP_LEFT','HOP_DOWN_LEFT'}
        mask=bytes(0 if cells[(x,y)]['role'] in allowed else 1 for y in range(18) for x in range(20))
        check('full_gold_terrain_collision', len(mask)==360 and sum(mask)==182 and
              get('maps/johto_pilot/Route33.blocked_mask.bin')==mask,'360 Gold 16x16 collision roles; 182 solid / 178 walkable')
        check('precise_cave_entrance',index.role_at('Route33',11,9)=='CAVE' and
              index.role_at('UnionCave1F',17,31)=='WARP_CARPET_DOWN' and
              index.role_at('UnionCave1F',17,32)=='WALL','north Route33 CAVE to 1F south DOWN-carpet')
        asm=text('engine/johto_pilot_runtime.asm');live=text('data/johto_route33_runtime.asm');warp=text('data/johto_union_cave_runtime.asm')
        rows=asm.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        for tag,row in [('south_to_route33','db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID'),
                        ('route33_to_south','db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID')]:
            check(tag, rows.count(row)==1, 'exact registered source ordinal and target ID')
        check('south_cave_warp',warp.count('db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR')==1,'Gold cave south y31 x17')
        check('route33_warp',live.count('db 9, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR')==1,'Route33 y9 x11 to cave south ordinal1')
        arrive=asm.split('JohtoPilotGateArrivalStep::')[1].split('JohtoPilotGateDoorApproachAllowed::')[0]
        check('route33_outdoor_arrival_safe_step',bool(re.search(r'(?s)\.route33CaveLanding\s+ld a, \[wXCoord\]\s+cp 11\s+ret nz\s+ld a, \[wYCoord\]\s+cp 9\s+ret nz\s+jr \.down',arrive))
              and 'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    ret z' in arrive,'only outdoor 11,9 auto-steps south; cave interior stationary')
        approach=asm.split('JohtoPilotGateDoorApproachAllowed::')[1].split('JohtoPilotGateDoorWarpMatched::')[0]
        matched=asm.split('JohtoPilotGateDoorWarpMatched::')[1].split('JohtoPilotGateExteriorCollisionAllowed::')[0]
        check('guarded_route33_approach',bool(re.search(r'(?s)\.route33Cave\s+.*?cp PLAYER_DIR_UP\s+ret nz\s+.*?cp 11\s+ret nz\s+.*?cp 10\s+ret nz\s+jp \.allow',approach)),
              'only (11,10) UP may step onto cave')
        check('guarded_route33_step_on_warp',bool(re.search(r'(?s)\.route33Cave\s+.*?cp PLAYER_DIR_UP\s+ret nz\s+.*?cp 11\s+ret nz\s+.*?cp 9\s+ret nz\s+jp \.yesDoor',matched)),
              'only (11,9) UP triggers registered entry Warp')
        field=text('engine/overworld/ledges.asm'); actual=_coordinate_hop_entries(field,'JohtoRoute33Hops'); expected=_gold_safe_hop_directions(cells)
        check('all_and_only_directed_gold_hops',len(actual)==7 and actual==expected,
              f'actual={sorted(actual)} expected={sorted(expected)}')
        check('grass_visual_role', len([x for x in cells.values() if x['role']=='TALL_GRASS'])==12 and
              'JohtoModern_Coll, $FF,$FF,$FF, $04, OUTDOOR' in text('data/tileset_headers.asm'),
              '12 Gold grass cells and shared RPG grass sprite priority tile $04')
        check('outdoor_bike', 'JOHTO_UNION_CAVE,JOHTO_MODERN,JOHTO_ILEX_FOREST,$FF' in text('data/bike_riding_tilesets.asm'),
              'Route33 outdoor bike list; ordinary gate not widened')
        check('route33_no_unsafe_global_tiles', get('gfx/tilesets/johto_modern.tilecoll')==b'\xff' and
              'callab JohtoOverworldSouthLandDecision' in text('home/overworld.asm') and
              'callab JohtoRoute33StepPolicy' in text('engine/johto_land_collision_gateway_272.asm'),
              'all walkability from exact Gold coordinates, no globally passable wall art')
        check('sealed_unreleased_edges', '.route33ClosedEdge' in asm and
              'JOHTO_UNION_CAVE_B1F_LOCAL_ID' not in rows and 'JOHTO_ROUTE_32_LOCAL_ID, 3' not in rows,
              'B1F and Route32/33 seam remain gated; Azalea outdoor seam is now separately registered')
    except (OSError,KeyError,ValueError,IndexError) as exc:
        issues.append(str(exc))
    return {'status':'PASS_STATIC_ONLY' if not issues else 'FAIL', 'checks':checks,'errors':issues,'rom_built':False,'phone_accepted':False}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('.'))
    parser.add_argument('--gold-root',type=Path,required=True)
    args=parser.parse_args(); result=audit(args.root,args.gold_root)
    print(json.dumps(result,ensure_ascii=False,indent=2))
    raise SystemExit(bool(result['errors']))
