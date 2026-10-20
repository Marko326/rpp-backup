#!/usr/bin/env python3
"""Gold-sourced region/local Fly destination gate; not a ROM or gameplay test."""
import argparse
import json
from pathlib import Path
import re

# Only the reviewed Fly destinations can appear in the menu. A physically
# registered city may explicitly defer Fly, but it must retain the original
# Gold flypoint identity and cannot be selectable in the current menu.
REVIEWED = (
 ('NEW_BARK_TOWN', 'JOHTO_NEW_BARK_LOCAL_ID', 'NEW_BARK_TOWN', 'NEW_BARK_TOWN_WIDTH', 'NEW_BARK', (13,6), 'newBarkName'),
 ('CHERRYGROVE_CITY', 'JOHTO_CHERRYGROVE_LOCAL_ID', 'JOHTO_CHERRYGROVE_CITY', 'JOHTO_CHERRYGROVE_CITY_WIDTH', 'CHERRYGROVE', (29,4), 'cherrygroveName'),
 ('VIOLET_CITY', 'JOHTO_VIOLET_CITY_LOCAL_ID', 'JOHTO_VIOLET_CITY', 'JOHTO_VIOLET_CITY_WIDTH', 'VIOLET', (31,26), 'violetName'),
 ('AZALEA_TOWN', 'JOHTO_AZALEA_TOWN_LOCAL_ID', 'JOHTO_AZALEA_FLY_SELECTOR', 'JOHTO_AZALEA_TOWN_WIDTH', 'AZALEA', (15,10), 'azaleaName'),
 ('GOLDENROD_CITY', 'JOHTO_GOLDENROD_CITY_LOCAL_ID', 'JOHTO_GOLDENROD_FLY_SELECTOR', 'JOHTO_GOLDENROD_CITY_WIDTH', 'GOLDENROD', (15,28), 'goldenrodName'),
 ('ECRUTEAK_CITY', 'JOHTO_ECRUTEAK_CITY_LOCAL_ID', 'JOHTO_GOLDENROD_FLY_SELECTOR', 'JOHTO_ECRUTEAK_CITY_WIDTH', 'ECRUTEAK', (23,28), 'ecruteakName'),
)
FILES=('tools/johto_native_maps.json','engine/johto_fly_town_map.asm',
'engine/overworld/missable_objects.asm','engine/fly_town_map_helpers.asm',
'engine/special_warps.asm','constants/region_map_constants.asm',
'constants/event_constants.asm','home/overworld.asm','wram.asm')
GOLD_FILES=('data/maps/flypoints.asm','data/maps/spawn_points.asm','data/maps/landmarks.asm')
GOLD_ROM_NAMES=('NewBarkTownName','CherrygroveCityName','VioletCityName','AzaleaTownName','GoldenrodCityName','EcruteakCityName')


def section(text, start, finish):
    # Anchor at labels. A string reference to .entries must not masquerade as
    # its definition. Take the first closing label after the opening label.
    def positions(s):
        return list(re.finditer(r'(?m)^[ \t]*'+re.escape(s)+r'[ \t]*$',text))
    beginnings=positions(start)
    if len(beginnings)!=1: raise ValueError('Fly ASM label missing/duplicate: '+start)
    endings=[m for m in positions(finish) if m.start()>beginnings[0].end()]
    if not endings: raise ValueError('Fly ASM closing label missing: '+finish)
    return text[beginnings[0].end():endings[0].start()]


def gold_native_key(local, fly):
    if not local.startswith('JOHTO_') or not local.endswith('_LOCAL_ID'): return None
    stem=local[6:-9]
    return next((x for x in (stem,stem+'_TOWN',stem+'_CITY') if x in fly),None)


def audit(root:Path,gold:Path)->list[str]:
    errs=[]
    try:
        s={f:(root/f).read_text(encoding='utf8') for f in FILES}
        g={f:(gold/f).read_text(encoding='utf8') for f in GOLD_FILES}
        maps=json.loads(s[FILES[0]])['maps']
    except (OSError,ValueError,TypeError,KeyError) as ex:
        return ['Fly data or original Gold missing; gate fails closed: '+str(ex)]
    flyrows=re.findall(r'^\s*db\s+LANDMARK_([A-Z0-9_]+)\s*,\s*SPAWN_([A-Z0-9_]+)',g[GOLD_FILES[0]],re.M)
    fly=dict(flyrows)
    if len(fly)!=len(flyrows) or 'AZALEA_TOWN' not in fly:
        errs.append('Gold flypoint inventory incomplete or duplicated')
    active=[]
    for m in maps:
        try:
            local=m['local_symbol']; expected=gold_native_key(local,fly)
            declared=m.get('gold_fly_landmark','MISSING')
            state=m['feature_status']['fly']
            if declared!=expected: errs.append(f'{local}: missing/wrong original Gold Fly landmark')
            if expected:
                if state == 'ALLOWED':
                    active.append(m)
                elif state != 'DEFERRED':
                    errs.append(f'{local}: invalid Gold Fly destination state {state}')
                else:
                    errs.append(f'{local}: unreviewed Fly deferral; explicit rollout review required')
            elif state not in ('DEFERRED','FORBIDDEN'):
                errs.append(f'{local}: road/cave is not a valid Fly destination')
        except (KeyError,TypeError): errs.append('corrupt native Fly registry entry')
    if len(active)!=len(REVIEWED) or {m.get('gold_fly_landmark') for m in active}!={x[0] for x in REVIEWED}:
        errs.append('missing/unreviewed ALLOWED Gold Fly city requires reviewed full integration')
    menu=s['engine/johto_fly_town_map.asm']; miss=s['engine/overworld/missable_objects.asm']
    helper=s['engine/fly_town_map_helpers.asm']; warp=s['engine/special_warps.asm']
    events=s['constants/event_constants.asm']; region=s['constants/region_map_constants.asm']
    try:
        entries=section(menu,'.entries','.destinations')
        dest=section(menu,'.destinations','.newBarkName')
        special=section(helper,'SpecialFlyWarpData:','db $ff')
        copy=section(helper.split('TryLoadSpecialFlyWarpData::',1)[1],'.found','.copyFlyWarp')
    except (ValueError,IndexError) as ex:
        return errs+[str(ex)]
    names=re.findall(r'^\s*db\s+(\d+)\s*,\s*(\d+)\s*\n\s*dw\s+\.([A-Za-z]+Name)',entries,re.M)
    destrows=re.findall(r'^\s*db\s+([A-Z0-9_, ]+)\s*$',dest,re.M)
    selectors=[x.strip() for x in destrows[0].split(',')] if len(destrows)==1 else []
    if len(names)!=len(REVIEWED) or len(selectors)!=len(REVIEWED): errs.append('Fly selector/menu count mismatch')
    for i,(landmark,local,selector,width,spawn,xy,menu_name) in enumerate(REVIEWED):
        match=[m for m in active if m.get('gold_fly_landmark')==landmark]
        if len(match)!=1 or match[0].get('local_symbol')!=local:
            errs.append(landmark+': wrong physical Johto map identity')
        if fly.get(landmark)!=spawn: errs.append(landmark+': missing/changed Gold flypoint')
        gold_spawns=re.findall(r'^\s*spawn\s+'+landmark+r'\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*$',g[GOLD_FILES[1]],re.M)
        if gold_spawns!=[(str(xy[0]),str(xy[1]))]:
            errs.append(landmark+': wrong Gold original landing')
        coords=re.findall(r'^\s*landmark\s+(-?\d+)\s*,\s*(-?\d+)\s*,\s*'+GOLD_ROM_NAMES[i]+r'\s*$',g[GOLD_FILES[2]],re.M)
        if len(coords)!=1 or i>=len(names) or names[i]!=(str(int(coords[0][1])+16),str(int(coords[0][0])+8),menu_name):
            errs.append(landmark+': menu cursor does not match Gold town map')
        if i>=len(selectors) or selectors[i]!=selector:
            errs.append(landmark+': Fly menu selector mismatch')
        destmap='REGION_NATIVE_MAP_SLOT' if i>=3 else selector
        if landmark=='ECRUTEAK_CITY':
            pattern=r'JohtoEcruteakFlyWarpData:\s*db\s+REGION_NATIVE_MAP_SLOT\s*FLYWARP_DATA\s+'+width+r'\s*,\s*'+str(xy[1])+r'\s*,\s*'+str(xy[0])
            if not re.search(pattern,helper): errs.append('ECRUTEAK_CITY: missing dedicated Fly landing record')
        else:
            pattern=r'^\s*db\s+'+selector+r'\s*,\s*'+destmap+r'\s*\n\s*FLYWARP_DATA\s+'+width+r'\s*,\s*'+str(xy[1])+r'\s*,\s*'+str(xy[0])+r'\s*$'
            if not re.search(pattern,special,re.M): errs.append(landmark+': missing/unsafe fly warp')
        flag='EVENT_JOHTO_FLY_'+('NEW_BARK','CHERRYGROVE','VIOLET','AZALEA','GOLDENROD','ECRUTEAK')[i]
        for text,kind,operand in ((menu,'read','bit'),(miss,'write','set')):
            pattern=r'ld hl, wEventFlags \+ '+flag+r' / 8\s+'+operand+' '+flag+r' % 8, \[hl\]'
            if not re.search(pattern,text): errs.append(landmark+': missing persistent '+kind)
        if not re.search(r'^\s*ASSERT '+flag+r' == \$'+format((0x450 if landmark=='ECRUTEAK_CITY' else 0x453+i),'x')+r'\s*$',events,re.M):
            errs.append(landmark+': save layout changed')
    # Transition semantics, not only textual presence of the destination.
    required=(
     (menu,r'\.next\s+ld a, \[wWhichTownMapLocation\]\s+inc a\s+cp 6'),
     (menu,r'\.previous\s+.*?ld a, 5\s+\.previousReady'),
     (menu,r'\.findForward\s+ld b, 6\s+\.forwardLoop.*?inc a\s+cp 6'),
     (menu,r'\.findBackward\s+ld b, 6\s+\.backwardLoop.*?ld a, 5'),
     (menu,r'\.accept\s+call \.isCurrentUnlocked\s+jp z, \.inputLoop'),
     (menu,r'\.findForward.*?call \.isCurrentUnlocked.*?\.findBackward.*?call \.isCurrentUnlocked'),
     (miss,r'cp REGION_NATIVE_MAP_SLOT\s+jr nz, \.notJohtoAzalea\s+ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.notJohtoAzalea\s+ld a, \[wCurLocalMapID\]\s+cp JOHTO_AZALEA_TOWN_LOCAL_ID'),
     (s['home/overworld.asm'],r'LoadMapHeader::.*?callab SyncLegacyMapRegions\s+callba MarkTownVisitedAndLoadMissableObjects'),
     (warp,r'cp REGION_NATIVE_MAP_SLOT\s+jr nz, \.legacyFlyTileset\s+ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.legacyFlyTileset\s+ld a, \[wCurLocalMapID\]\s+cp JOHTO_AZALEA_TOWN_LOCAL_ID\s+jr z, \.nativeModern\s+cp JOHTO_GOLDENROD_CITY_LOCAL_ID\s+jr z, \.nativeModern\s+cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\s+jr z, \.johtoTileset\s+jr \.legacyFlyTileset\s+\.nativeModern\s+ld a, JOHTO_MODERN'),
     (warp,r'\.storeTileset\s+ld \[wCurMapTileset\], a\s+.*?xor a\s+\.done\s+ld \[wYOffsetSinceLastSpecialWarp\], a\s+ld \[wXOffsetSinceLastSpecialWarp\], a'),
     (region,r'DEF JOHTO_AZALEA_FLY_SELECTOR EQU \$fd'),
     (events,r'ASSERT EVENT_JOHTO_FLY_AZALEA < 139 \* 8'),
     (events,r'ASSERT EVENT_JOHTO_FLY_GOLDENROD < 139 \* 8'),
     (warp,r'callab TryLoadSpecialFlyWarpData'),
     (warp,r'ld a, \[wLastBlackoutMap\]'),
    )
    for text,pattern in required:
        if not re.search(pattern,text,re.S): errs.append('Fly runtime path removed/changed: '+pattern[:60])
    for piece in ('cp REGION_NATIVE_MAP_SLOT','ld [wCurRegion], a','ld [wCurLocalMapID], a',
                  'ld [wLastRegion], a','ld [wLastLocalMapID], a','JOHTO_AZALEA_TOWN_LOCAL_ID','JOHTO_GOLDENROD_CITY_LOCAL_ID','JOHTO_ECRUTEAK_CITY_LOCAL_ID','cp JOHTO_GOLDENROD_FLY_SELECTOR'):
        if piece not in copy: errs.append('native Fly region/local restoration missing: '+piece)
    if len(re.findall(r'^\s*db\s+\w+\s*,\s*REGION_NATIVE_MAP_SLOT\b',special,re.M))!=2:
        errs.append('shared $FC must resolve from the two reviewed unique Fly selectors')
    # Previous Fly candidate read wWhichTownMapLocation ($cd3d) after the
    # travel animation had reused that global scratch. Both towns have the
    # same $FE selector; demand a stable, separately-written physical ID.
    accepted=re.split(r'(?m)^\.accept\s*$',menu,maxsplit=1)[-1].split('\n.cancel\n',1)[0]
    selector=re.split(r'(?m)^\.regularScan\s*$',helper.split('TryLoadSpecialFlyWarpData::',1)[-1],maxsplit=1)[0]
    physical=re.split(r'(?m)^\.goldenrodOrEcruteak\s*$',helper,maxsplit=1)[-1].split('\n.storeNativeLocal\n',1)[0]
    for text,token,context in (
        (s['wram.asm'],'wJohtoFlySelectedLocalID:: ; d7ab','dedicated fixed WRAM byte'),
        (accepted,'ld a, JOHTO_ECRUTEAK_CITY_LOCAL_ID','Ecruteak accept physical ID'),
        (accepted,'ld a, JOHTO_GOLDENROD_CITY_LOCAL_ID','Goldenrod accept physical ID'),
        (accepted,'ld [wJohtoFlySelectedLocalID], a','accepted selection handoff'),
        (accepted,'ld [wDestinationMap], a','accepted legacy selector handoff'),
        (selector,'cp JOHTO_GOLDENROD_FLY_SELECTOR','Fly-only selector dispatch'),
        (selector,'ld a, [wJohtoFlySelectedLocalID]','warp dispatch physical ID'),
        (selector,'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID','Ecruteak warp dispatch'),
        (selector,'ld hl, JohtoEcruteakFlyWarpData','Ecruteak warp data'),
        (physical,'ld a, [wJohtoFlySelectedLocalID]','physical landing map'),
        (physical,'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID','Ecruteak landing map')):
        if token not in text: errs.append('Ecruteak Fly selection handoff missing '+context)
    if 'wWhichTownMapLocation' in selector or 'wWhichTownMapLocation' in physical:
        errs.append('Ecruteak Fly warp must not read reused $cd3d menu cursor')
    if 'wEventFlags::' not in s['wram.asm']:
        errs.append('no original persistent event bit storage')
    try:
        mask=(root/'maps/JohtoAzaleaTown.blocked_mask.bin').read_bytes()
        def blocked(x,y): return bool(mask[y*5+x//8]&(1<<(x%8)))
        if len(mask)!=90 or any(blocked(x,10) for x in (14,15,16)):
            errs.append('Azalea Fly spawn or walking neighbors blocked')
    except (OSError,IndexError) as ex: errs.append('Fly arrival mask missing/broken: '+str(ex))
    try:
        mask=(root/'maps/JohtoGoldenrodCity.blocked_mask.bin').read_bytes()
        def blocked_goldenrod(x,y): return bool(mask[y*5+x//8]&(1<<(x%8)))
        if len(mask)!=180 or any(blocked_goldenrod(x,y) for (x,y) in ((15,28),(14,28),(16,28),(15,29))):
            errs.append('Goldenrod Fly spawn or walking neighbors blocked')
    except (OSError,IndexError) as ex: errs.append('Goldenrod arrival mask missing/broken: '+str(ex))
    try:
        mask=(root/'maps/JohtoEcruteakCity.blocked_mask.bin').read_bytes()
        def blocked_e(x,y): return bool(mask[y*5+x//8] & (1<<(x%8)))
        if len(mask)!=180 or any(blocked_e(x,y) for x,y in ((23,28),(22,28),(24,28),(23,29))):
            errs.append('Ecruteak Fly spawn and walking neighbors blocked')
    except (OSError,IndexError) as ex: errs.append('Ecruteak Fly arrival mask missing/broken: '+str(ex))
    return errs

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--rpp',type=Path,required=True);a.add_argument('--gold',type=Path,required=True)
    args=a.parse_args();errors=audit(args.rpp,args.gold)
    print(json.dumps({'status':'FAIL' if errors else 'PASS','errors':errors,'built_rom':False,'phone_verified':False},indent=2,ensure_ascii=False))
    raise SystemExit(bool(errors))
