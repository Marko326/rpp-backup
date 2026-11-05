#!/usr/bin/env python3
"""REF-341 Union Cave B2F / same-tileset floor-warp source-only acceptance gate."""
from pathlib import Path
import argparse,json,re

def check(root:Path,gold:Path|None=None):
 p=[]; n=0
 def req(name,ok):
  nonlocal n
  if ok:n+=1
  else:p.append(name)
 def txt(f):return (root/f).read_text()
 def part(s,a,b=None):
  x=s.split(a,1); assert len(x)==2,a
  return x[1].split(b,1)[0] if b else x[1]
 c=txt('constants/region_map_constants.asm'); req('active_count_60','DEF NUM_JOHTO_ACTIVE_MAPS EQU 60' in c)
 req('version_REF343','db "REF-343@"' in txt('data/game_version.asm'))
 slots=txt('data/johto_stable_id_slots.asm'); m=re.search(r'(?m)^\s*db\s+([^;]+);\s*\$70-\$7f',slots); v=[x.strip() for x in m.group(1).split(',')] if m else []
 req('b1f_b2f_slots',len(v)==16 and v[2]=='57' and v[3]=='58')
 hdr=part(txt('data/johto_header_descriptors.asm'),'JohtoHeaderDescriptors::','JohtoHeaderDescriptorsEnd::')
 req('b2f_header_present','dw JohtoUnionCaveB2FRuntimeHeader' in hdr and 'db BANK(JohtoUnionCaveB2FRuntimeHeader)' in hdr)
 src=txt('data/johto_pilot_source_resources.asm'); assets=txt('data/johto_pilot_runtime_assets.asm')
 req('source_runtime_count_60','DEF JOHTO_PILOT_SOURCE_COUNT EQU 60' in src and 'ASSERT NUM_JOHTO_ACTIVE_MAPS == 60' in assets)
 req('b2f_source_registered','JohtoUnionCaveB2FGoldBlocks::' in src and 'JohtoUnionCaveB2FRuntimeDescriptor::' in assets)
 cave=txt('data/johto_union_cave_runtime.asm')
 req('blockset_41','== 41 * 16' in cave and len((root/'gfx/blocksets/johto_union_cave.bst').read_bytes())==41*16)
 req('b2f_runtime_header','JohtoUnionCaveB2FRuntimeHeader::' in cave and 'JohtoUnionCaveB2FRuntimeObjects::' in cave)
 objb1=part(cave,'JohtoUnionCaveB1FRuntimeObjects::','JohtoUnionCaveB2FRuntimeBlocks::')
 objb2=part(cave,'JohtoUnionCaveB2FRuntimeObjects::','JohtoSlowpokeWellB1FRuntimeBlocks::')
 rows=lambda x:[tuple(map(int,m.groups())) for m in re.finditer(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*JOHTO_REGISTERED_WARP_SELECTOR',x)]
 req('b1f_has_five_gold_ordinals',rows(objb1)==[(3,3,3),(11,3,4),(19,7,2),(33,3,3),(31,17,0)])
 req('b2f_single_return',rows(objb2)==[(3,5,4)])
 dungeon=txt('data/dungeon_tilesets.asm')
 req('union_cave_forces_destination_rebuild', re.search(r'(?m)^\s*db\s+[^\n;]*\bJOHTO_UNION_CAVE\b[^\n;]*\$FF\s*$', dungeon) is not None)
 routes=part(txt('engine/johto_pilot_runtime.asm'),'JohtoRegisteredWarpRoutes::','JohtoRegisteredWarpRoutesEnd::')
 rr=re.findall(r'(?m)^\s*db\s+MAP_REGION_JOHTO\s*,\s*(JOHTO_\w+)\s*,\s*(\d+)\s*,\s*MAP_REGION_JOHTO\s*,\s*(JOHTO_\w+)',routes)
 b1='JOHTO_UNION_CAVE_B1F_LOCAL_ID'; b2='JOHTO_UNION_CAVE_B2F_LOCAL_ID'; one='JOHTO_UNION_CAVE_1F_LOCAL_ID'
 related=[(a,int(o),d) for a,o,d in rr if a in (b1,b2) or d in (b1,b2)]
 req('six_cave_floor_routes',related==[(one,2,b1),(one,3,b1),(b1,2,one),(b1,3,one),(b1,4,b2),(b2,0,b1)])
 req('ruins_still_closed',not any(a==b1 and o in (0,1) for a,o,d in related))
 req('registered_warps_142',len(re.findall(r'(?m)^\s*db\s+MAP_REGION_',routes))==142)
 req('townmap_slot58','slot58 Union Cave B2F' in txt('engine/fly_town_map_helpers.asm'))
 req('music_slot58','slot58 Union Cave B2F' in txt('engine/menu/options_menu.asm'))
 req('name_sign_b2f','cp JOHTO_UNION_CAVE_B2F_LOCAL_ID' in txt('engine/overworld/map_name_sign.asm'))
 fs=txt('engine/johto_violet_field_skills.asm')
 water=part(fs,'JohtoUnionCaveB2FGoldWaterCells::','JohtoUnionCaveB2FGoldWaterCellsEnd::')
 coords=[(int(y),int(x)) for y,x in re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)',water)]
 req('b2f_water_168',len(coords)==168 and len(set(coords))==168)
 req('b2f_water_selected','ld hl, JohtoUnionCaveB2FGoldWaterCells' in fs)
 req('b2f_map_size',len((root/'maps/johto_pilot/UnionCaveB2F.runtime.blk').read_bytes())==180)
 req('b2f_runtime_block_range',max((root/'maps/johto_pilot/UnionCaveB2F.runtime.blk').read_bytes())<41)
 # border contract retained across all 3 cave floors
 bst=(root/'gfx/blocksets/johto_union_cave.bst').read_bytes(); tc=(root/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes()
 req('border_21_matches_gold_09_solid_duplicate',bst[0x21*16:0x22*16]==bytes([5]*16) and 5 not in tc)
 req('fixed_nite_palette','JOHTO_UNION_CAVE (31): Gold\'s fixed PALETTE_NITE cave colors.' in txt('color/data/map_palette_sets.asm') and 'db CAVE_GRAY, CAVE_RED, CAVE_GREEN, CAVE_BLUE' in txt('color/data/map_palette_sets.asm'))
 if gold:
  gb=(gold/'maps/UnionCaveB2F.blk').read_bytes(); req('gold_b2f_exact_source',(root/'maps/johto_pilot/UnionCaveB2F.gold.blk').read_bytes()==gb)
  coll={}
  for line in (gold/'data/tilesets/cave_collision.asm').read_text().splitlines():
   m=re.search(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})',line)
   if m:coll[int(m.group(2),16)]=[z.strip() for z in m.group(1).split(',')]
  exp=set()
  for y in range(36):
   for x in range(20):
    bid=gb[(y//2)*10+x//2]; role=coll[bid][(y%2)*2+x%2]
    if role=='WATER':exp.add((y,x))
  req('gold_water_168_parity',set(coords)==exp)
 return {'status':'PASS_STATIC_ONLY' if not p else 'FAIL','passed':n,'failed':len(p),'errors':p,'rom_built':False,'phone_verified':False}

if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--project',type=Path,default=Path('.'));a.add_argument('--gold-root',type=Path);x=a.parse_args();r=check(x.project.resolve(),x.gold_root.resolve() if x.gold_root else None);print(json.dumps(r,ensure_ascii=False,indent=2));raise SystemExit(r['status']!='PASS_STATIC_ONLY')
