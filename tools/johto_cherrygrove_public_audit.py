#!/usr/bin/env python3
"""Gold-exact Cherrygrove PC/Mart source and live route checks (never ROM proof)."""
from __future__ import annotations
import json
from pathlib import Path
import re
import sys

PUBLIC = (
  ('Mart',122,55,3,23,'JohtoOlivineMartBlocks','JOHTO_OLIVINE_MART',
   ((2,7),(3,7)), (
    ('SPRITE_JOHTO_CLERK',1,3,'STAY','RIGHT'),
    ('SPRITE_JOHTO_COOLTRAINER_M',7,6,'WALK','2'),
    ('SPRITE_JOHTO_YOUNGSTER_RED',2,5,'STAY','DOWN'))),
  ('Pokecenter1F',123,56,4,29,'JohtoOlivinePokecenter1FBlocks','JOHTO_OLIVINE_POKECENTER',
   ((3,7),(4,7)), (
    ('SPRITE_JOHTO_NURSE',3,1,'STAY','DOWN'),
    ('SPRITE_JOHTO_FISHER_RED',2,3,'STAY','UP'),
    ('SPRITE_JOHTO_GENTLEMAN',8,6,'STAY','UP'),
    ('SPRITE_JOHTO_TEACHER_GREEN',1,6,'STAY','RIGHT'))),
)

def audit(root: Path, gold: Path, overrides=None) -> list[str]:
    root,gold=Path(root),Path(gold)
    overrides=overrides or {}
    errors=[]
    def src(r, origin=False):
        return overrides[r] if not origin and r in overrides else ((gold if origin else root)/r).read_text()
    def check(ok,msg):
        if not ok: errors.append(msg)
    try:
        cfg=json.loads(src('tools/johto_native_maps.json'))['maps']
        head=src('data/johto_map_headers.asm');city=src('data/mapObjects/JohtoCherrygroveCity.asm')
        gcity=src('maps/CherrygroveCity.asm',True)
        warp=src('engine/overworld/region_map_lookup.asm')
        fence=src('engine/overworld/johto_route33_collision.asm')
        passive=src('engine/overworld/johto_passive_house_npc.asm')
        header=src('main.asm'); const=src('constants/sprite_constants.asm')
        pointers=src('data/sprite_sets.asm'); palettes=src('color/sprites.asm')
        sprites=src('engine/overworld/map_sprites.asm')
        texts=src('scripts/JohtoCherrygrovePublicText.asm')
        office=src('home/overworld.asm')
    except (OSError,ValueError) as e: return ['missing source: '+str(e)]
    check('DEF NUM_JOHTO_MAPS EQU 57' in src('constants/region_map_constants.asm') and len(cfg)==57,
          'new map count must be exactly 57')
    target=warp.split('NativeRegionWarpTargets::',1)[-1].split('NativeRegionWarpTargetsEnd::',1)[0]
    arrivals=warp.split('GetJohtoWarpArrivalStep::',1)[-1].split('GetJohtoCaveMapChangeSFX::',1)[0]
    directional=fence.split('JohtoGateCollisionDirectionAllowed::',1)[-1].split('JohtoNativeCanStepAhead::',1)[0]
    passage=fence.split('JohtoCherrygroveHouseDoorStepAllowed::',1)[-1].split('JohtoRoute29GateStepAllowed::',1)[0]
    for name,stable,slot,warp_id,x,blocks,tileset,exits,people in PUBLIC:
        prefix='JohtoCherrygrove'+name
        symbol='JOHTO_CHERRYGROVE_'+ ('MART' if name=='Mart' else 'POKECENTER_1F')+'_LOCAL_ID'
        obj=src('data/mapObjects/'+prefix+'.asm')
        hdr=src('data/mapHeaders/'+prefix+'.asm')
        gobj=src('maps/Cherrygrove'+name+'.asm',True)
        row=cfg[slot]
        check(row.get('local_id')==stable and row.get('header')==prefix+'_h',prefix+' stable ID/slot')
        check(f'dw {prefix}_h' in head and f'db BANK({prefix}_h)' in head,prefix+' header registration')
        check(f'dw {blocks}, {prefix}TextPointers' in hdr and f'db {tileset}' in hdr,prefix+' shared Gold layout binding')
        check(f'INCLUDE "data/mapHeaders/{prefix}.asm"' in header and f'INCLUDE "data/mapObjects/{prefix}.asm"' in header,prefix+' ROM includes')
        check(f'{prefix}TextPointers:' in texts and 'JohtoCherrygrovePassiveNoText' in texts,prefix+' NPC no-script table')
        check(f'db 3, {x}, 0, REGION_WARP_ESCAPE' in city,prefix+' outdoor warp')
        check(re.search(rf'(?m)^\s*warp_event\s+{x},\s*3,\s*CHERRYGROVE_{"MART" if name=="Mart" else "POKECENTER_1F"},\s*{2 if name=="Mart" else 1}\b',gcity) is not None,prefix+' Gold city entry')
        check(f'db JOHTO_CHERRYGROVE_LOCAL_ID, {warp_id}, 0, MAP_REGION_JOHTO, {symbol}' in target,prefix+' runtime source Warp target')
        for lane,(xx,yy) in enumerate(exits):
            check(f'db {yy}, {xx}, {warp_id}, REGION_WARP_ESCAPE' in obj,prefix+f' exit lane {lane}')
            check(f'db {symbol}, {lane}, {warp_id}, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID' in target,prefix+f' return resolver lane {lane}')
            check(re.search(rf'(?m)^\s*warp_event\s+{xx},\s*{yy},\s*CHERRYGROVE_CITY,\s*\d+',gobj),prefix+f' Gold return lane {lane}')
        check(f'db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, 3, {x}, REGION_NATIVE_MAP_SLOT, D_DOWN' in arrivals,prefix+' return door auto-step')
        check('cp '+str(x) in passage and 'cp '+str(x) in directional,prefix+' live door collision and direction')
        check('cp '+symbol in fence and 'cp '+symbol in passive,prefix+' interior gate/no-dialogue selector')
        check(re.search(rf'(?m)^\s*db \$0{len(people)}\s*$',obj),prefix+' Gold NPC count')
        npc=re.findall(r'(?m)^\s*object\s+([^;\n]+)',obj)
        check(len(npc)==len(people),prefix+' object count')
        for i,expected in enumerate(people):
            if i>=len(npc): break
            args=[t.strip() for t in npc[i].split(',')]
            check(len(args)==6,prefix+f' NPC{i} must have 6 macro arguments')
            check(args[:5]==[expected[0],str(expected[1]),str(expected[2]),expected[3],expected[4]],prefix+f' NPC{i} sprite/position/move')
            check(re.search(rf'(?m)^\s*object_event\s+{expected[1]},\s*{expected[2]},',gobj),prefix+f' Gold NPC{i} position')
            check('const '+expected[0] in const,prefix+f' NPC{i} sprite constant')
        check(re.search(r'(?m)^\s*db \$02\s*$',obj) is not None and 'db $03\n db 7' not in obj,prefix+' exactly two outdoor exits, no upper floor')
        check('db $00 ; no BG events' in obj,prefix+' no BG scripts')
    for sprite,art,pal in (('FISHER_RED','JohtoFisherSprite','RED'),('TEACHER_GREEN','JohtoTeacherSprite','GREEN'),('GENTLEMAN','JohtoGentlemanSprite','BLUE'),('COOLTRAINER_M','JohtoCooltrainerMSprite','BLUE')):
        sid='SPRITE_JOHTO_'+sprite
        check('cp a, '+sid in sprites and 'const '+sid in const,sprite+' loaded as 12-tile Gold sprite')
        check('dw '+art in pointers and 'BANK('+art+')' in pointers,sprite+' original Gold sprite art pointer')
        check(re.search(r'; '+sid+r':[^\n]*\n\s*db PAL_OW_'+pal,palettes) is not None,sprite+' Gold palette')
    for name in ('gentleman','cooltrainer_m'):
        b=(root/'gfx/sprites'/('johto_'+name+'.png')).read_bytes()
        check(b==(gold/'gfx/sprites'/(name+'.png')).read_bytes(),name+' exact Gold PNG art')
    check('cp JOHTO_CHERRYGROVE_LOCAL_ID' in office and 'callba JohtoCherrygroveHouseDoorStepAllowed' in office,'native city live collision path')
    return errors

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--rpp',type=Path,required=True);p.add_argument('--gold',type=Path,required=True)
    z=p.parse_args();errors=audit(z.rpp,z.gold)
    print(json.dumps({'status':'PASS' if not errors else 'FAIL','errors':errors,'built_rom':False,'phone_verified':False},indent=2))
    sys.exit(bool(errors))
