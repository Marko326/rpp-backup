#!/usr/bin/env python3
"""Gold-backed park sprite/field-move and legacy Route32 gate ingress audit.

Static source + actual ASM control-flow checks only, never ROM/phone evidence.
"""
from pathlib import Path
from collections import defaultdict
import json
import re

LOCAL_GATE = 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'
LEGACY_ROUTE = 'JOHTO_ROUTE_32'


def source_grass(gold: Path):
    blocks = (gold/'maps/NationalPark.blk').read_bytes()
    metatiles = (gold/'data/tilesets/park_metatiles.bin').read_bytes()
    collisions = (gold/'data/tilesets/park_collision.asm').read_text()
    rows = [[s.strip() for s in row.split(',')]
            for row in re.findall(r'(?m)^\s*tilecoll\s+([^;\n]+)', collisions)]
    if len(blocks)!=20*27 or len(metatiles)!=64*16 or len(rows)!=64 or any(len(x)!=4 for x in rows):
        raise ValueError('Gold Park source geometry invalid')
    source = defaultdict(set)
    counts = defaultdict(int)
    for y in range(54):
        for x in range(40):
            b=blocks[(y//2)*20+x//2]
            role=rows[b][(y%2)*2+(x%2)]
            offset=b*16+(y%2)*8+(x%2)*2
            source[role].update(metatiles[offset+i] for i in (0,1,4,5))
            counts[role]+=1
    return source, counts


def explicit_entries(lookup: str):
    table=lookup.split('ExplicitWarpRegionTargets::',1)[1].split('\nASSERT JOHTO_NEW_BARK_LOCAL_ID',1)[0]
    return [(s,int(a),int(b),d) for s,a,b,d in re.findall(
        r'(?m)^\s*db\s+(JOHTO_[A-Z0-9_]+),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s*(JOHTO_[A-Z0-9_]+)', table)]


def audit(root: Path, gold: Path, overrides=None):
    root, gold=Path(root), Path(gold)
    overrides=overrides or {}
    def read(path):
        return overrides.get(path,(root/path).read_text())
    errs=[]
    try:
        roles,counts=source_grass(gold)
        if counts['TALL_GRASS']!=176 or roles['TALL_GRASS']!={4}:
            errs.append('Gold normal Park grass differs from 176 x tile $04')
        long=roles['LONG_GRASS']
        if counts['LONG_GRASS']!=176 or long!={0x3a,0x3b,0x4a,0x4b}:
            errs.append('Gold long Park grass differs from four verified graphic IDs')
        if any(roles[n] & (long | {4}) for n in roles if n not in ('LONG_GRASS','TALL_GRASS')):
            errs.append('Grass ID occurs in an unrelated Gold Park collision role')
        hdr=read('data/tileset_headers.asm')
        if not re.search(r'(?m)^\s*tileset JohtoPark_Block, JohtoPark_GFX, JohtoModern_Coll,\s*\$FF,\s*\$FF,\s*\$FF,\s*\$04,\s*OUTDOOR',hdr):
            errs.append('Park grass does not register Gold tall grass marker $04')
        sprites=read('engine/overworld/movement.asm')
        part=sprites.split('GetGrassSpritePriority::',1)[1].split('UnusedReadSpriteDataFunction:',1)[0]
        # Exact reviewed predicate, shared by player and NPC. Reject drift in
        # the four branch targets, including wrong tileset and inverted direction.
        if not re.search(r'ld a, \[wGrassTile\]\s+cp c\s+jr z, \.inGrass\s+'
             r'ld a, \[wCurMapTileset\]\s+cp JOHTO_PARK\s+jr nz, \.notInGrass\s+'
             r'ld a, c\s+cp \$3a\s+jr z, \.inGrass\s+cp \$3b\s+jr z, \.inGrass\s+'
             r'cp \$4a\s+jr z, \.inGrass\s+cp \$4b\s+jr z, \.inGrass\s+'
             r'\.notInGrass\s+xor a\s+ret\s+\.inGrass\s+ld a, \$80\s+ret',part,re.S):
            errs.append('Gold Park four-tile long-grass priority predicate changed')
        if len(re.findall(r'(?m)^\s*call GetGrassSpritePriority\s*$',sprites))!=2 or not all(
                'call GetGrassSpritePriority' in sprites.split(label,1)[1].split(stop,1)[0]
                for label,stop in (('UpdatePlayerSprite:', 'UnusedReadSpriteDataFunction:'),
                                    ('UpdateNPCSprite:','UpdateSpriteImage:'))):
            errs.append('player or NPC lower OAM priority path bypasses grass predicate')
        sprite_set=read('engine/overworld/map_sprites.asm')
        if not re.search(r'cp JOHTO_PARK[^\n]*\n\s+jr z, \.johtoSprites',sprite_set):
            errs.append('Park outdoor sprite set is not loaded as reviewed Johto sprites')
        bike=read('data/bike_riding_tilesets.asm').split('BikeRidingTilesets::',1)[1].split('$FF',1)[0]
        bike_set={x.strip() for x in re.findall(r'(?m)^\s*db\s+(.+)',bike)[0].split(',')}
        if 'JOHTO_PARK' not in bike_set or bike_set.intersection({'JOHTO_PARK_GATE','JOHTO_RUINS_GATE'}):
            errs.append('Park should permit bicycle but indoor gates should dismount')
        fly=read('engine/menu/start_sub_menus.asm').split('\n.fly\n',1)[1].split('\n.canFly\n',1)[0]
        if not re.search(r'cp JOHTO_PARK[^\n]*\n\s+jr z, \.canFly',fly) or not re.search(
           r'cp JOHTO_MODERN\s+jr z, \.canFly\s+call CheckIfInOutsideMap',fly):
            errs.append('Park outdoor Fly-use authorization missing or legacy guard changed')
        for forbidden in ('JOHTO_PARK_GATE','JOHTO_RUINS_GATE'):
            if re.search(r'cp '+forbidden+r'[^\n]*\n\s+jr z, \.canFly',fly):
                errs.append('Gate cannot authorize field Fly: '+forbidden)
        entries=json.loads(read('tools/johto_native_maps.json'))['maps']
        active={x['local_id']:x for x in entries}
        for local in (102,103,104,105):
            p=active[local]
            if p.get('fly_use_status')!=('ALLOWED' if local==103 else 'FORBIDDEN'):
                errs.append(f'local {local} field Fly-use capability incorrect')
            if p['gold_fly_landmark'] is not None or p['feature_status']['fly']!='FORBIDDEN':
                errs.append(f'local {local} cannot be a Fly destination')
            if p['feature_status']['bike']!=('ALLOWED' if local==103 else 'FORBIDDEN'):
                errs.append(f'local {local} bike capability incorrect')
        if ('LANDMARK_NATIONAL_PARK' in (gold/'data/maps/flypoints.asm').read_text() or
            'LANDMARK_ROUTE_32_RUINS_OF_ALPH_GATE' in (gold/'data/maps/flypoints.asm').read_text()):
            errs.append('Gold fly destination source changed; review needed')
        indexes=read('engine/overworld/johto_town_map_helpers.asm').split('JohtoNativeTownMapIndices::',1)[1].split('JohtoNativeTownMapIndicesEnd::',1)[0]
        # All four physical local IDs use the exact Gold 45-landmark index, not a fly index.
        for local,index,name,xy in ((103,18,'JohtoBrowseNationalParkName',(76,60)),
                                    (104,17,'JohtoBrowseRoute35Name',(92,60)),
                                    (105,19,'JohtoBrowseRoute36Name',(76,72)),
                                    (102,7,'JohtoRoute32TownMapName',(108,92))):
            m=active[local]
            if m['town_map_index']!=index or m['town_map_name']!=name or tuple(m['town_map_xy'])!=xy:
                errs.append(f'local {local} has wrong Gold normal Town Map landmark')
        if not re.search(r'db 18, 17, 19\s*;',indexes) or not re.search(r'(?m)^\s*db 7\s*;',indexes):
            errs.append('normal Town Map slot indices not registered correctly')
        town=read('engine/town_map.asm').split('JohtoNativeTownMapEntries::',1)[1].split('JohtoNativeTownMapEntriesEnd::',1)[0]
        for xy,name in (((76,60),'JohtoBrowseNationalParkName'),((92,60),'JohtoBrowseRoute35Name'),
                        ((76,72),'JohtoBrowseRoute36Name'),((108,92),'JohtoRoute32TownMapName')):
            if not re.search(r'db\s+'+str(xy[0])+r',\s*'+str(xy[1])+r'[^\n]*\n\s*dw '+name+r'\b',town):
                errs.append('normal Town Map entry missing: '+name)
        neutral=read('engine/overworld/map_name_sign.asm').split('.IsNeutralMap\n',1)[1].split('\n.legacyMap\n',1)[0]
        for symbol in ('JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID',
                       'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID',
                       'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID'):
            if not re.search(r'cp '+symbol+r'\s+ret z',neutral):
                errs.append('gate popup must retain previous outdoor place name: '+symbol)
        if re.search(r'cp JOHTO_NATIONAL_PARK_LOCAL_ID\s+ret z',neutral):
            errs.append('park outdoor popup must not be neutral')
        lookup=read('engine/overworld/region_map_lookup.asm')
        rows=explicit_entries(lookup)
        expected={(LEGACY_ROUTE,0,0,'JOHTO_UNION_CAVE_1F_LOCAL_ID'),
                  (LEGACY_ROUTE,1,2,LOCAL_GATE),(LEGACY_ROUTE,2,3,LOCAL_GATE)}
        existing=[x for x in rows if x[0]==LEGACY_ROUTE]
        if len(existing)!=3 or set(existing)!=expected:
            errs.append('legacy Route32 explicit warp dispatch missing/wrong; may fall through to Vermilion ferry')
        # Verify actual 0-based source Warp indices against source objects,
        # and Gold right-mouth destination map/warp order, not a copied JSON.
        obj=read('data/mapObjects/JohtoRoute32.asm').split('JohtoRoute32Object:',1)[1]
        objrows=re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*REGION_WARP_ESCAPE',obj)
        if objrows[:3]!=[('79','6','0'),('2','4','2'),('3','4','3')]:
            errs.append('Route32 original cave and two right-side source Warp slots changed')
        golden=(gold/'maps/Route32RuinsOfAlphGate.asm').read_text()
        if not re.findall(r'(?m)^\s*warp_event\s+9,\s*([45]),\s*ROUTE_32,\s*([23])',golden)==[('4','2'),('5','3')]:
            errs.append('original Gold east gate target topology changed')
        if not re.search(r'cp REGION_NATIVE_MAP_SLOT\s+jp z, ResolveNativeRegionWarp',lookup):
            errs.append('source legacy/native route dispatch no longer separates paths')
    except (OSError,ValueError,KeyError,IndexError,TypeError) as exc:
        errs.append('Park/Route32 static audit cannot establish original Gold evidence: '+str(exc))
    return errs

if __name__=='__main__':
    import argparse
    ap=argparse.ArgumentParser();ap.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);ap.add_argument('--gold',type=Path,required=True)
    args=ap.parse_args()
    fails=audit(args.root,args.gold)
    for fail in fails:print('FAIL',fail)
    print('PASS' if not fails else f'FAIL ({len(fails)} errors)')
    raise SystemExit(bool(fails))
