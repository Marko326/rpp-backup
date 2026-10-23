#!/usr/bin/env python3
"""Gold House1 collision-standard-interaction parity check for a *single* indoor map.

Independent Gold sources are House1.blk + house_collision.asm +
OlivinePunishmentSpeechHouse.asm. This is a static/source contract, not RGBDS,
a running radio service, or proof of A-button behavior in an emulator.
"""
from __future__ import annotations
from pathlib import Path
import argparse
import re

ROOM='OlivinePunishmentSpeechHouse'
EXPECTED={(0,3):'TOWN_MAP',(0,5):'WINDOW',(1,2):'TV',(1,7):'RADIO'}
EXPECTED_RPP={
 (0,3):'JohtoIndoorTownMapText',
 (0,5):'MyReflectionText',
 (1,2):'JohtoIndoorTVText',
 (1,7):'JohtoIndoorRadioText',
}

def collision_cells(gold: Path):
    block=(gold/'maps/House1.blk').read_bytes()
    if len(block)!=16: raise ValueError('Gold House1 4x4 block data missing')
    src=(gold/'data/tilesets/house_collision.asm').read_text()
    entries={}
    for group, n in re.findall(r'(?m)^\s*tilecoll\s+([^;\n]+);\s*([0-9a-f]{2})',src,re.I):
        entries[int(n,16)]=tuple(x.strip() for x in group.split(','))
    if len(entries)!=64 or any(len(r)!=4 for r in entries.values()):
        raise ValueError('Gold house tilecoll table differs from 64x4')
    return {(y,x):entries[block[y//2*4+x//2]][(y%2)*2+x%2]
            for y in range(8) for x in range(8)}

def front(x,y,facing):
    offsets={'UP':(0,-1),'DOWN':(0,1),'LEFT':(-1,0),'RIGHT':(1,0)}
    dx,dy=offsets[facing]
    return y+dy,x+dx

def audit(rpp: Path, gold: Path):
    errors=[]
    try:
        cells=collision_cells(gold)
        specials={p:t for p,t in cells.items() if t in ('TOWN_MAP','WINDOW','TV','RADIO')}
        if specials!=EXPECTED:
            errors.append(f'Gold original actual furniture changed: {specials}')
        original=(gold/f'maps/{ROOM}.asm').read_text()
        if len(re.findall(r'(?m)^\s*bg_event\s+',original))!=2 or not all(
            re.search(rf'(?m)^\s*bg_event\s+{x},\s*1,\s*BGEVENT_READ,\s*{ROOM}Bookshelf',original)
            for x in (0,1)):
            errors.append('Gold bookcase BG events must be exactly (0,1), (1,1)')
        if not re.search(r'(?m)^\s*object_event\s+1,\s*2,\s*SPRITE_POKEFAN_M,',original):
            errors.append('Gold father at (1,2) blocking second bookshelf changed')
        roomobj=(rpp/f'data/mapObjects/Johto{ROOM}.asm').read_text()
        if len(re.findall(r'(?m)^\s*db\s+1,\s*[01],\s*[34]\s*$',roomobj))!=2:
            errors.append('RPP must keep exactly both original bookshelf sign events')
        if not re.search(r'(?m)^\s*object SPRITE_JOHTO_POKEFAN_M, 1, 2,',roomobj):
            errors.append('RPP must preserve father at (1,2), do not unblock right bookshelf')
        collision=(rpp/'engine/overworld/johto_indoor_furniture.asm').read_text()
        if not all(re.search(r'\b'+s+r'\b',collision) for s in (
            'REGION_NATIVE_MAP_SLOT','MAP_REGION_JOHTO',
            'JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID','JOHTO_HOUSE',
            'wCurMap','wCurRegion','wCurLocalMapID','wCurMapTileset',
            'wXCoord','wYCoord','wSpriteStateData1','SPRITE_FACING_UP','SPRITE_FACING_DOWN',
            'SPRITE_FACING_LEFT','SPRITE_FACING_RIGHT')):
            errors.append('room/tileset/facing/position safeguards missing')
        if not re.search(r'(?s)JohtoIndoorFurniturePredef::.*?ld \[\$ffdb\], a.*?\.lookUp.*?JohtoOlivineHouseFurnitureCells:',collision):
            errors.append('dedicated predef result and front-cell lookup missing')
        part=collision.split('JohtoOlivineHouseFurnitureCells:',1)[1]
        found={}
        for y,x,label in re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+)\s*\n\s*db_tx_pre\s+(\w+)\b',part):
            key=(int(y),int(x))
            if key in found: errors.append('duplicated furniture coordinate '+str(key))
            found[key]=label
        if found != EXPECTED_RPP:
            errors.append(f'furniture lookup should cover exactly four Gold collision cells: {found}')
        if re.search(r'db_tx_pre\s+.*(Magazine|PictureBook)',part) or len(found)!=4:
            errors.append('bookcases must remain BG events, not generic tile interactions')
        hidden=(rpp/'engine/hidden_object_functions3.asm').read_text()
        home=(rpp/'home.asm').read_text();main=(rpp/'main.asm').read_text()
        if not re.search(r'(?s)PrintBookshelfText:\s*;.*?callba JohtoIndoorFurniturePredef\s+ld a, \[\$ffdb\]\s+and a\s+jr z, \.oldBookshelfPath.*?call PrintPredefTextID.*?ld \[\$ffdb\], a.*?\.oldBookshelfPath.*?BookshelfTileIDs',hidden):
            errors.append('A-button furniture must run before old bookcase fallback and return consumed state')
        if not re.search(r'(?s)CheckForHiddenObjectOrBookshelfOrCardKeyDoor::.*?call CheckForHiddenObject.*?callba PrintBookshelfText',home):
            errors.append('hidden item priority before house furniture changed')
        if 'SECTION "Johto Indoor Furniture", ROMX\nINCLUDE "engine/overworld/johto_indoor_furniture.asm"' not in main:
            errors.append('furniture lookup needs its own relocatable ROM section')
        for label in ('JohtoIndoorTownMapText','JohtoIndoorTVText','JohtoIndoorRadioText'):
            if f'add_tx_pre {label}' not in home or f'\n{label}:\n' not in hidden:
                errors.append('predef text not registered or implemented: '+label)
        if not re.search(r'(?s)JohtoIndoorTownMapText:\s*TX_FAR _JohtoIndoorTownMapPrompt\s*TX_BLINK\s*TX_ASM\s*jp TownMapOpenScript',hidden):
            errors.append('town map must use actual existing DisplayTownMap pathway')
        if not re.search(r'(?s)TownMapOpenScript:.*?callba DisplayTownMap',hidden):
            errors.append('shared map command not connected')
        if 'add_tx_pre MyReflectionText' not in home:
            errors.append('window should reuse original reflection text')
        dialogs=(rpp/'text.asm').read_text()
        for s in ('_JohtoIndoorTVText::','_JohtoIndoorRadioText::','_JohtoIndoorTownMapPrompt::'):
            if dialogs.count(s)!=1:errors.append('new normal interaction text missing: '+s)
        if 'special' in (rpp/'engine/overworld/johto_indoor_furniture.asm').read_text().split('JohtoIndoorFurniturePredef::',1)[1].split('JohtoOlivineHouseFurnitureCells:',1)[0].lower():
            errors.append('house generic interactions must not add scene/event/story actions')
        # Reachability of the left shelf from (0,2) and second shelf standing
        # spot occupied by original father at (1,2); preserve rather than cheat.
        if cells[1,0]!='BOOKSHELF' or cells[1,1]!='BOOKSHELF' or cells[2,0]!='FLOOR':
            errors.append('original two shelf collision/left approach changed')
        if front(0,2,'UP')!=(1,0) or front(1,2,'UP')!=(1,1):
            errors.append('bookshelf approach reasoning invalid')
        if not re.search(r'(?m)^\s*dw JohtoOlivinePunishmentSpeechHouseMagazineText\s*$',
                         (rpp/'scripts/JohtoOlivinePunishmentSpeechHouse.asm').read_text()):
            errors.append('old magazine event text changed')
    except (OSError,ValueError,IndexError) as ex:
        errors.append('Gold/RPP furniture sources unavailable: '+str(ex))
    return errors

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--rpp',type=Path,required=True);p.add_argument('--gold',type=Path,required=True)
    a=p.parse_args();problems=audit(a.rpp,a.gold)
    print('JOHTO HOUSE FURNITURE', 'PASS' if not problems else 'FAIL',*problems,sep='\n')
    raise SystemExit(bool(problems))
