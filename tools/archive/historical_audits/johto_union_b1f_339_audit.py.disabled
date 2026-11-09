#!/usr/bin/env python3
"""REF-339 Union Cave B1F single-floor, source-only acceptance gate.

Does not build/link ROM or claim live gameplay validation. Requires exact
active-slot and Warp source ordinals; B2F and Ruins exits MUST stay disabled.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path


def check(root: Path, gold: Path | None = None) -> dict:
    problems = []
    passes = 0

    def require(name: str, ok: bool):
        nonlocal passes
        if ok:
            passes += 1
        else:
            problems.append(name)

    def read(name: str):
        return (root / name).read_text(encoding='utf-8')

    def after(body, label, end=None):
        part = body.split(label, 1)
        assert len(part) == 2, label
        return part[1].split(end, 1)[0] if end is not None else part[1]

    const = read('constants/region_map_constants.asm')
    require('active_count_58', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 58' in const)
    version = read('data/game_version.asm')
    require('version_REF339', 'db "REF-339@"' in version)
    slots = read('data/johto_stable_id_slots.asm')
    slots70 = re.search(r'(?m)^\s*db\s+([^;\n]+);\s*\$70-\$7f', slots)
    ids = [v.strip() for v in slots70[1].split(',')] if slots70 else []
    require('stable_B1F114_slot57', len(ids) == 16 and ids[2] == '57')
    require('B2F115_not_active', len(ids) == 16 and ids[3] == 'JOHTO_INVALID_ACTIVE_SLOT')
    hdr = after(read('data/johto_header_descriptors.asm'), 'JohtoHeaderDescriptors::', 'JohtoHeaderDescriptorsEnd::')
    header_rows = re.findall(r'(?m)^\s*(dw|db)\s+(.*?)\s*$', '\n'.join(row.split(';')[0] for row in hdr.splitlines()))
    require('all_58_headers_dw_bank', len(header_rows) == 116 and all(
        header_rows[i] == ('dw', header_rows[i][1]) and header_rows[i+1] == ('db', 'BANK('+header_rows[i][1]+')')
        for i in range(0, len(header_rows), 2)))
    require('B1F_header_appended', len(header_rows) == 116 and header_rows[-2:] == [
        ('dw', 'JohtoUnionCaveB1FRuntimeHeader'), ('db', 'BANK(JohtoUnionCaveB1FRuntimeHeader)')])
    assets = read('data/johto_pilot_runtime_assets.asm')
    source = read('data/johto_pilot_source_resources.asm')
    require('58_runtime_source_records', 'ASSERT NUM_JOHTO_ACTIVE_MAPS == 58' in assets and 'DEF JOHTO_PILOT_SOURCE_COUNT EQU 58' in source)
    require('b1f_only_descriptor', 'JohtoUnionCaveB1FRuntimeDescriptor::' in assets and 'JohtoUnionCaveB2FRuntimeDescriptor::' not in assets)
    require('b1f_source_registered', 'JohtoUnionCaveB1FGoldBlocks::' in source and 'JohtoUnionCaveB2FGoldBlocks::' not in source)
    cave = read('data/johto_union_cave_runtime.asm')
    obj1 = after(cave, 'JohtoUnionCave1FRuntimeObjects::', 'JohtoUnionCaveB1FRuntimeBlocks::')
    objb = after(cave, 'JohtoUnionCaveB1FRuntimeObjects::')
    rows = lambda x: [tuple(map(int, m.groups())) for m in re.finditer(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR', x)]
    require('1f_stair_ordinals_2_3', rows(obj1) == [(3,17,2),(31,17,0),(19,5,2),(33,3,3)])
    require('b1f_gold_ordinal_0_1_disabled', rows(objb) == [(3,3,3),(11,3,4),(19,7,2),(33,3,3)])
    require('B2F_data_not_included', 'JohtoUnionCaveB2FRuntimeHeader' not in cave and not (root / 'maps/johto_pilot/UnionCaveB2F.runtime.blk').exists())
    routes = after(read('engine/johto_pilot_runtime.asm'), 'JohtoRegisteredWarpRoutes::', 'JohtoRegisteredWarpRoutesEnd::')
    route_rows = re.findall(r'(?m)^\s*db\s+MAP_REGION_JOHTO\s*,\s*(JOHTO_\w+)\s*,\s*(\d+)\s*,\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_\w+)', routes)
    st = 'JOHTO_UNION_CAVE_1F_LOCAL_ID'; sb='JOHTO_UNION_CAVE_B1F_LOCAL_ID'
    new_routes = [(a,int(b),c) for a,b,c in route_rows if a == sb or c == sb]
    require('four_safe_routes_only', new_routes == [(st,2,sb),(st,3,sb),(sb,2,st),(sb,3,st)])
    require('no_b2f_or_ruins_route', not any(a == sb and b in (0,1,4) for a,b,c in new_routes) and 'JOHTO_UNION_CAVE_B2F_LOCAL_ID' not in routes)
    require('registered_warps_138', len(re.findall(r'(?m)^\s*db\s+MAP_REGION_', routes)) == 138)
    blockset = (root / 'gfx/blocksets/johto_union_cave.bst').read_bytes()
    root1f=(root/'maps/johto_pilot/UnionCave1F.runtime.blk').read_bytes()
    b1f=(root/'maps/johto_pilot/UnionCaveB1F.runtime.blk').read_bytes()
    require('blockset_40_valid', len(blockset)==40*16 and max(root1f)<34 and max(b1f)<40)
    # Gold cave border $09 is a repeating floor texture; NPC-243 used a black
    # opaque stand-in at RPP block $21. RPP tile $05 is the same Gold texture
    # as tile $16, but remains impassable (unlike the walkable duplicate $06).
    cave_objects = read('data/johto_union_cave_runtime.asm')
    border_objects = re.findall(r'(?m)^\s*db\s+\$21\s*;.*cave border', cave_objects)
    passable_tiles = (root/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes()
    border_pattern = blockset[0x21*16:0x22*16]
    require('1f_and_b1f_use_same_border_slot', len(border_objects) == 2)
    require('border_21_matches_gold_09_solid_duplicate',
            border_pattern == bytes([5] * 16) and 5 not in passable_tiles
            and 0x21 not in root1f and 0x21 not in b1f)
    require('maps_10x18', len(b1f)==180 and len(root1f)==180)
    require('collision_tilecount_21', len((root/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes())==21)
    require('b1f_gold_music', 'db MUSIC_GBP_GSC_UNION_CAVE ; slot57 Union Cave B1F' in read('engine/menu/options_menu.asm'))
    require('b1f_gold_ledge', 'db 12, 10, PLAYER_DIR_RIGHT\n    db 12, 11, PLAYER_DIR_RIGHT' in read('engine/overworld/ledges.asm'))
    water=after(read('engine/johto_violet_field_skills.asm'), 'JohtoUnionCaveB1FGoldWaterCells::', 'JohtoUnionCaveB1FGoldWaterCellsEnd::')
    coords=[(int(y),int(x)) for y,x in re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\b',water)]
    require('60_water_cells_unique', len(coords)==60 and len(set(coords))==60)
    require('b1f_has_independent_water_table', 'ld hl, JohtoUnionCaveB1FGoldWaterCells' in read('engine/johto_violet_field_skills.asm'))
    if gold is not None:
        gold_b1f=(gold/'maps/UnionCaveB1F.blk').read_bytes()
        require('gold_b1f_exact_source', (root/'maps/johto_pilot/UnionCaveB1F.gold.blk').read_bytes()==gold_b1f)
        gold_metatiles = (gold/'data/tilesets/cave_metatiles.bin').read_bytes()
        require('gold_cave_09_repeating_tile_22', gold_metatiles[9*16:10*16] == bytes([22] * 16))
        from PIL import Image
        gold_png = Image.open(gold/'gfx/tilesets/cave.png').convert('RGBA')
        runtime_png = Image.open(root/'gfx/tilesets/johto_union_cave.png').convert('RGBA')
        gold_tile = gold_png.crop((6*8,1*8,7*8,2*8))   # Gold tile $16 / 22
        runtime_tile = runtime_png.crop((5*8,0*8,6*8,1*8)) # RPP tile $05
        require('gold09_runtime_border_pixels_equal', gold_tile.tobytes() == runtime_tile.tobytes())
        coll={}
        for line in (gold/'data/tilesets/cave_collision.asm').read_text().splitlines():
            m=re.search(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})',line)
            if m: coll[int(m[2],16)]=[r.strip() for r in m[1].split(',')]
        water_expected=set()
        hops_expected=set()
        for y in range(36):
            for x in range(20):
                bid=gold_b1f[(y//2)*10+x//2]
                role=coll[bid][(y%2)*2+x%2]
                if role=='WATER': water_expected.add((y,x))
                if role=='HOP_RIGHT': hops_expected.add((x,y))
        require('gold_water_60_parity', set(coords)==water_expected)
        require('gold_right_hop_2_parity', hops_expected=={(12,10),(12,11)})
    return {'status':'PASS_STATIC_ONLY' if not problems else 'FAIL',
            'passed':passes,'failed':len(problems),'errors':problems,
            'rom_built':False,'phone_verified':False}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project', type=Path, default=Path('.'));p.add_argument('--gold-root',type=Path)
    args=p.parse_args()
    try: result=check(args.project.resolve(), args.gold_root.resolve() if args.gold_root else None)
    except Exception as exc: result={'status':'FAIL','errors':[str(exc)],'passed':0,'failed':1,'rom_built':False,'phone_verified':False}
    print(json.dumps(result,ensure_ascii=False,indent=2))
    raise SystemExit(result['status']!='PASS_STATIC_ONLY')
