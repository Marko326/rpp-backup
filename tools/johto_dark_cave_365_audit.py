#!/usr/bin/env python3
"""REF-365: independent Gold Dark Cave same-floor / field-move source preflight.

Run: python tools/johto_dark_cave_365_audit.py --root . [--gold-root /.../pokegold-master]
This is source + topology verification, NOT a ROM build or emulator acceptance.
"""
from __future__ import annotations
import argparse,collections,json,re
from pathlib import Path

CAVE_MAPS={
 'DarkCaveVioletEntrance':{'id':190,'w':40,'h':36,'water':64,'hops':26,'warps':[(3,15,6),(17,1,7),(35,33,6)]},
 'DarkCaveBlackthornEntrance':{'id':99,'w':30,'h':36,'water':120,'hops':14,'warps':[(23,3,6),(3,25,6)]},
}
ROLE={'FLOOR':0,'WALL':1,'WATER':2,'UP_WALL':3,'HOP_DOWN':4,'HOP_DOWN_LEFT':4,'HOP_DOWN_RIGHT':4,'HOP_LEFT':5,'WARP_CARPET_DOWN':6,'CAVE':7}
ROUTES=[('JOHTO_ROUTE_31_LOCAL_ID',2,'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID'),
        ('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',0,'JOHTO_ROUTE_31_LOCAL_ID'),
        ('JOHTO_ROUTE_46_LOCAL_ID',2,'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID'),
        ('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',2,'JOHTO_ROUTE_46_LOCAL_ID'),
        ('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',1,'JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID'),
        ('JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID',1,'JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID'),
        ('JOHTO_ROUTE_45_LOCAL_ID',0,'JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID'),
        ('JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID',0,'JOHTO_ROUTE_45_LOCAL_ID')]



def blackthorn_role_offset(cave_source: str, y: int, x: int) -> int | None:
 """Interpret the actual 30*y+x LR35902 arithmetic, rejecting unsupported ops.

 Deliberately recognizes only the instructions needed for this table lookup:
 an illegal `sbc hl, de` (or any unknown new opcode) returns None.
 No ROM assembly or execution is performed.
 """
 try:
  block = cave_source.split('JohtoDarkCaveRoleAt::',1)[1].split('\n.blackthorn\n',1)[1].split('\n.wall\n',1)[0]
  block = block.split('    push de\n',1)[1].split('    ld de, JohtoDarkCaveBlackthornGoldRoles',1)[0]
 except IndexError:
  return None
 registers={'b':y,'c':x,'h':0,'l':0,'d':0,'e':0}
 ops=0
 for line in block.splitlines():
  instruction=line.split(';',1)[0].strip().lower()
  if not instruction: continue
  if instruction=='add hl, hl':
   v=((registers['h']<<8)|registers['l'])*2 & 0xffff
   registers['h'],registers['l']=v>>8,v&255
  elif instruction=='add hl, de':
   v=(((registers['h']<<8)|registers['l'])+((registers['d']<<8)|registers['e']))&0xffff
   registers['h'],registers['l']=v>>8,v&255
  else:
   import re
   matched=re.fullmatch(r'ld ([lhde]), ([bchlde]|0)',instruction)
   if not matched: return None
   dst,src=matched.groups()
   registers[dst]=0 if src=='0' else registers[src]
  ops+=1
 if ops!=15: return None  # Reject missing instructions or truncated lookup.
 return (registers['h']<<8)|registers['l']

def audit(root:Path,gold_root:Path|None=None)->dict:
 root=Path(root);errors=[];checks=[]
 def ck(label,pred):
  checks.append({'check':label,'status':'PASS' if pred else 'FAIL'})
  if not pred:errors.append(label)
 def load(path):return (root/path).read_text()
 try:
  tiles={int(m.group(2),16):[t.strip() for t in m.group(1).split(',')]
    for m in re.finditer(r'tilecoll\s+([^;]+);\s*([\da-fA-F]{2})',load('data/johto_dark_cave_stage/cave_collision.gold.asm'))}
  all_roles={}
  for name,spec in CAVE_MAPS.items():
   w,h=spec['w'],spec['h']
   gold=(root/f'maps/johto_pilot/{name}.gold.blk').read_bytes()
   live=(root/f'maps/johto_pilot/{name}.runtime.blk').read_bytes()
   ck(name+'_unchanged_gold_blocks', gold==live and len(gold)==(w//2)*(h//2))
   if gold_root is not None:
    ck(name+'_gold_reference_match',gold==(gold_root/'maps'/f'{name}.blk').read_bytes())
   expected=[]
   for y in range(h):
    for x in range(w):
     tile=tiles[gold[(y//2)*(w//2)+(x//2)]][2*(y%2)+(x%2)]
     expected.append(ROLE.get(tile,-1))
   actual=list((root/f'data/johto_dark_cave_stage/{name}.roles.bin').read_bytes())
   all_roles[name]=actual
   ck(name+'_Gold_role_exact',actual==expected and -1 not in expected)
   ck(name+'_water_exact',actual.count(2)==spec['water'])
   ck(name+'_hops_exact',actual.count(4)+actual.count(5)==spec['hops'])
   ck(name+'_warp_role_exact',all(actual[y*w+x]==role for x,y,role in spec['warps']))
   ck(name+'_all_coordinate_bounds',all(0<=x<w and 0<=y<h for x,y,_ in spec['warps']))
  constants=load('constants/region_map_constants.asm')
  ck('65_active_maps','DEF NUM_JOHTO_ACTIVE_MAPS EQU 65' in constants)
  route=load('engine/johto_pilot_runtime.asm')
  warp=route.split('JohtoRegisteredWarpRoutes::')[1].split('JohtoRegisteredWarpRoutesEnd::')[0]
  parsed=[(m.group(1),int(m.group(2)),m.group(3)) for m in re.finditer(
    r'(?m)^\s*db MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID), (\d+), MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID)',warp)]
  ck('eight_cave_registered_routes',all(x in parsed for x in ROUTES))
  ck('168_unique_warp_routes',len(parsed)==168 and len({r[:2] for r in parsed})==168)
  for a,b,c in ROUTES:
   ck('warp_'+a+'_'+str(b),any(x==a and y==b and z==c for x,y,z in parsed))
  vio=load('data/johto_dark_cave_stage/REF349_stage2_runtime.asm')
  ck('Violet_Gold_ordinal1_step_in','db 1, 17, 1, JOHTO_REGISTERED_WARP_SELECTOR' in vio)
  ck('Blackthorn_Gold_two_warps',all(q in vio for q in ('db 3, 23, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 25, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR')))
  ck('Blackthorn_no_Rock_Smash_objects', 'JohtoDarkCaveBlackthornObjects:\n    db $09' in vio and 'db 0 ; no signs or Rock Smash objects' in vio)
  ck('Route45_single_Gold_warp', 'db 5, 2, 0, JOHTO_REGISTERED_WARP_SELECTOR' in load('data/johto_south_chain_runtime_328.asm'))
  cave=load('engine/johto_dark_cave_stage2.asm')
  ck('two_independent_role_tables',all(x in cave for x in ('JohtoDarkCaveGoldRoles','JohtoDarkCaveBlackthornGoldRoles','add hl, de ; 30y')))
  ck('blackthorn_LR35902_legal_30y_stride',all(blackthorn_role_offset(cave,y,x)==30*y+x for y in range(36) for x in range(30)))
  ck('shared_land_surf_bike_flash',all(x in cave for x in ('JohtoDarkCaveBikeFloorAllowed349::','JohtoDarkCaveSurfDecision::','JohtoFlashEligibility349::','JohtoDarkCaveRoleAt::')) and cave.count('JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID')>=6)
  ck('shore_forbids_CAVE_from_water', 'ret ; WALL and open CAVE transfer tile are not shoreline' in cave) # role7 excluded from shoreline
  ledges=load('engine/overworld/ledges.asm')
  for name,table in [('DarkCaveVioletEntrance','JohtoDarkCaveGoldHops'),('DarkCaveBlackthornEntrance','JohtoDarkCaveBlackthornGoldHops')]:
   start=ledges.split(table+':',1)[1]
   body=start.split('db $ff',1)[0]
   coords=[]
   for x,y,d in re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(PLAYER_DIR_DOWN|PLAYER_DIR_LEFT)',body):coords.append((int(x),int(y),int(d=='PLAYER_DIR_DOWN')))
   data=all_roles[name];w=CAVE_MAPS[name]['w']
   expected={(i%w,i//w,int(r==4)) for i,r in enumerate(data) if r in (4,5)}
   ck(name+'_exact_directed_ledge_table',set(coords)==expected and len(coords)==len(expected))
  ck('blackthorn_ledge_dispatch','JohtoDarkCaveBlackthornGoldHops' in ledges and '.darkCaveBlackthorn' in ledges)
  ck('new_floor_edge_guard','ld b, JOHTO_DARK_CAVE_BLACKTHORN_WIDTH * 2 - 1' in route)
  ck('inside_entrance_CAVE_step_in',all(x in route for x in ('cp 17','cp 1','ld e, 2','; Gold (17,1) is a CAVE tile entered from below')))
  # REF-365C: map permission alone is not enough. IsBikeRidingAllowed
  # must dispatch both stable cave IDs into the Gold FLOOR_TILE checker.
  bike=load('home/rom0_relief_349.asm').split('IsBikeRidingAllowed::',1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"',1)[0]
  bike_dispatch=bike.split('\n.legacyBike\n',1)[0]
  ck('bike_dispatched_for_both_dark_cave_ids',all(re.search(r'cp\s+'+x+r'\s+jp z, \.darkCaveBike',bike_dispatch) for x in ('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID','JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID')))
  ck('bike_checks_Gold_floor_only','callab JohtoDarkCaveBikeFloorAllowed349' in bike and 'cp 1\n\tjr z, .allowed' in bike)
  # Match the actual arrival hook, not the portal table: a returned internal
  # CAVE cell must step onto Violet floor (17,2), while three outdoor carpets
  # and Blackthorn's (3,25) carpet remain stationary.
  arrival=route.split('JohtoPilotGateArrivalStep::',1)[1].split('JohtoPilotGateDoorApproachAllowed::',1)[0]
  violet_arrival=arrival.split('\n.oldArrival\n',1)[1].split('\n.notVioletCaveArrival365C\n',1)[0] if '\n.notVioletCaveArrival365C\n' in arrival else ''
  violet_arrival='\n'.join(line.split(';',1)[0] for line in violet_arrival.splitlines() if not line.lstrip().startswith(';'))
  ck('Violet_internal_CAVE_arrival_step_down',bool(re.search(r'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\s+jr nz, \.notVioletCaveArrival365C\s+ld a, \[wXCoord\]\s+cp 17\s+ret nz\s+ld a, \[wYCoord\]\s+cp 1\s+ret nz\s+ld e, D_DOWN\s+ret',violet_arrival)))
  ck('Blackthorn_carpets_no_auto_step','cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n    ret z' in arrival)
  ck('arrival_does_not_depend_on_long_JR','jp z, .gateTop' in arrival)
  ck('Violet_internal_landing_is_safe_Gold_floor',all_roles['DarkCaveVioletEntrance'][1*40+17]==7 and all_roles['DarkCaveVioletEntrance'][2*40+17]==0)
  ck('Blackthorn_internal_carpet_south_is_wall',all_roles['DarkCaveBlackthornEntrance'][25*30+3]==6 and all_roles['DarkCaveBlackthornEntrance'][26*30+3]==1)
  ck('Blackthorn_DOWN_exit_direction_guard','JohtoDarkCaveDownCarpet349::' in route and 'cp PLAYER_DIR_DOWN' in route and '.internalCarpet365' in route)
  ck('palette_transition_keeps_flash','jr z, .copyDark365' in route and 'ld a, [wMapPalOffset]' in route)
  ck('Flash_two_regions','JohtoFlashEligibility349::' in cave and 'cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID' in cave)
  ck('route45_entry_and_exit_auto_step',all(x in load('data/johto_vertical_gate_runtime_314.asm') for x in ('JOHTO_ROUTE_45_LOCAL_ID, PLAYER_DIR_UP, 2, 6','JOHTO_ROUTE_45_LOCAL_ID, PLAYER_DIR_UP, 2, 5, 2','JOHTO_ROUTE_45_LOCAL_ID, 2, 5, D_DOWN')))
  ck('route45_shared_vertical_gate_allowlist','cp JOHTO_ROUTE_45_LOCAL_ID ; REF-365 exterior Gold cave-mouth profiles' in route.split('JohtoPilotIsVerticalGatePairMap314::',1)[1].split('JohtoPilotGateArrivalStep::',1)[0])
  items=load('engine/items/items.asm');fly=load('engine/fly_town_map_helpers.asm')
  ck('Rope_and_Dig_both_reuse_eligibility','ItemUseEscapeRope:' in items and 'call CanUseEscapeRope' in items and 'callab JohtoDarkCaveEscapeAllowed365' in items)
  ck('Rope_no_heal_center_for_cave',all(x in fly for x in ('TryLoadSpecialFlyWarpData::','callab JohtoDarkCaveEscapeAllowed365','callab JohtoDarkCaveApplyEscape365')))
  ck('Save_Continue_persistent_origin','EVENT_9D6 / 8' in cave and 'EVENT_9D7 % 8' in cave and 'wEventFlags + JOHTO_DARK_CAVE_ANCHOR_BYTE' in cave)
  ck('outdoor_source_only','cp JOHTO_ROUTE_31_LOCAL_ID' in cave and 'cp JOHTO_ROUTE_46_LOCAL_ID' in cave and 'cp JOHTO_ROUTE_45_LOCAL_ID' in cave and 'interior transfer MUST NOT rewrite' in cave)
  ck('all_three_legal_rope_destinations',all(x in cave for x in ('FLYWARP_DATA JOHTO_ROUTE_31_WIDTH, 6, 34','FLYWARP_DATA JOHTO_ROUTE_46_WIDTH, 6, 14','FLYWARP_DATA JOHTO_ROUTE_45_WIDTH, 6, 2')))
  ck('old_save_no_origin_denies_rope','jr z, .deny ; old save/invalid origin' in cave)
  ck('no_rock_smash_runtime_hook',not re.search(r'JohtoDarkCaveRockSmash|JohtoDarkCaveBreakableRock',cave))
  ck('REF365_version', 'REF-365@' in load('data/game_version.asm'))
  ck('main_65_slot_descriptors',all(x in load('data/johto_header_descriptors.asm') for x in ('dw JohtoDarkCaveBlackthornRuntimeHeader','NUM_JOHTO_ACTIVE_MAPS')))
 except (OSError,IndexError,ValueError,KeyError,AssertionError) as exc:
  errors.append(f'ERROR loading/parsing reference: {exc}')
 return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','passed':len(checks)-len([x for x in checks if x['status']=='FAIL']),'failed':len(errors),'errors':errors,'checks':checks}

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--root',default='.');ap.add_argument('--gold-root');ap.add_argument('--json-out');a=ap.parse_args()
 res=audit(Path(a.root),Path(a.gold_root) if a.gold_root else None)
 if a.json_out:Path(a.json_out).write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'status':res['status'],'passed':res['passed'],'failed':res['failed'],'errors':res['errors']},ensure_ascii=False,indent=2))
 raise SystemExit(0 if not res['errors'] else 1)
