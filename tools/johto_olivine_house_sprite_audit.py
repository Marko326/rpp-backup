#!/usr/bin/env python3
"""Gold Olivine house NPC sprite and movement contract; source-only, no ROM proof."""
from __future__ import annotations
import argparse
from pathlib import Path
import re

SPRITES = ('pokefan_m', 'lass')
SOURCES = (
 'data/mapObjects/JohtoOlivinePunishmentSpeechHouse.asm',
 'constants/sprite_constants.asm', 'data/sprite_sets.asm',
 'engine/overworld/map_sprites.asm', 'color/sprites.asm', 'main.asm',
)


def audit(root: Path, gold: Path) -> list[str]:
    problems=[]
    try:
        files={p: (root/p).read_text() for p in SOURCES}
        gold_house=(gold/'maps/OlivinePunishmentSpeechHouse.asm').read_text()
        gold_sprites=(gold/'data/sprites/sprites.asm').read_text()
        objects=files[SOURCES[0]]
        for x,y,sprite,behavior,range_x,range_y in (
            (1,2,'SPRITE_POKEFAN_M','SPRITEMOVEDATA_SPINRANDOM_SLOW',0,0),
            (5,5,'SPRITE_LASS','SPRITEMOVEDATA_WALK_LEFT_RIGHT',2,0),
        ):
            pat=rf'(?m)^\s*object_event\s+{x},\s*{y},\s*{sprite},\s*{behavior},\s*{range_x},\s*{range_y},'
            if not re.search(pat,gold_house):
                problems.append(f'Gold {sprite} position/movement contract changed')
        gold_house_objs=re.findall(r'(?m)^\s*object_event ',gold_house)
        if len(gold_house_objs)!=2:
            problems.append('original house must have exactly two NPCs')
        expected_obj=(
           r'^\s*object SPRITE_JOHTO_POKEFAN_M, 1, 2, STAY, (?:NONE|DOWN), 1\s*;',
           r'^\s*object SPRITE_JOHTO_LASS, 5, 5, WALK, 2, 2\s*;',
        )
        for pat in expected_obj:
            if not re.search(pat,objects,re.M):
                problems.append('house NPC uses wrong sprite, coordinates, or movement')
        if len(re.findall(r'(?m)^\s*object SPRITE_',objects))!=2:
            problems.append('house must have exactly two NPC objects')
        for idx,tag in ((0x64,'POKEFAN_M'),(0x65,'LASS')):
            if not re.search(rf'(?m)^\s*const SPRITE_JOHTO_{tag}\s*; \${idx:02x}\b',files['constants/sprite_constants.asm']):
                problems.append(f'new sprite ID 0x{idx:02x} must append after existing real 0x63')
        constants=files['constants/sprite_constants.asm'].split('; overworld sprites\n',1)[1].split('; Variable Sprite IDs Here',1)[0]
        declared=re.findall(r'(?m)^\s*const (SPRITE_\w+)',constants)
        for idx,name in ((0x64,'SPRITE_JOHTO_POKEFAN_M'),(0x65,'SPRITE_JOHTO_LASS')):
            if len(declared)<idx or declared[idx-1]!=name:
                problems.append('actual const_value sprite index 0x%02x mismatch: %s'%(idx,name))
        sets=files['data/sprite_sets.asm']
        pointers=sets.split('SpriteSheetPointerTable:',1)[1]
        pointer_names=re.findall(r'(?m)^\s*dw (\w+)\s*$',pointers)
        if len(pointer_names)!=len(declared):
            problems.append('SpriteSheetPointerTable must align exactly to real sprite constant count')
        elif pointer_names[-2:]!=['JohtoPokefanMSprite','JohtoLassSprite']:
            problems.append('new Gold sprite pointers misindexed')
        col_rows=files['color/sprites.asm'].split('SpritePaletteAssignments:',1)[1].split('AnimationTileset1Palettes:',1)[0]
        pal_rows=re.findall(r'(?m)^\s*db (PAL_OW_\w+)',col_rows)
        if len(pal_rows)!=len(declared) or pal_rows[-2:]!=['PAL_OW_BROWN','PAL_OW_RED']:
            problems.append('SpritePaletteAssignments rows must align to actual sprite indices')
        a=sets.split('; sprite set $0b',1)
        if len(a)!=2:
            problems.append('outdoor Johto $0b set missing')
        else:
            outdoor=a[1].split('; sprite set $0c',1)[0]
            wanted=['SPRITE_SAILOR','SPRITE_GAMBLER','SPRITE_BUG_CATCHER','SPRITE_LASS',
                    'SPRITE_FISHER','SPRITE_FISHER2','SPRITE_GIRL','SPRITE_HIKER',
                    'SPRITE_BLACK_HAIR_BOY_1','SPRITE_BALL','SPRITE_BERRY_TREE']
            have=re.findall(r'(?m)^\s*db (SPRITE_\w+)\s*$',outdoor)
            if have!=wanted:problems.append('outdoor Johto $0b sprite set changed')
        a=sets.split('; sprite set $0c',1)
        if len(a)!=2:
            problems.append('independent Olivine house $0c sprite set missing')
        else:
            indoor=a[1].split('SpriteSheetPointerTable:',1)[0]
            have=re.findall(r'(?m)^\s*db (SPRITE_\w+)\s*$',indoor)
            wanted=['SPRITE_SAILOR','SPRITE_GAMBLER','SPRITE_BUG_CATCHER','SPRITE_JOHTO_LASS',
                    'SPRITE_JOHTO_POKEFAN_M','SPRITE_FISHER2','SPRITE_GIRL','SPRITE_HIKER',
                    'SPRITE_BLACK_HAIR_BOY_1','SPRITE_BALL','SPRITE_BERRY_TREE']
            if have!=wanted:problems.append('house $0c set must be 11 slots with Gold NPCs')
        for tag,asmname in [('POKEFAN_M','JohtoPokefanMSprite'),('LASS','JohtoLassSprite')]:
            if not re.search(rf'(?s); SPRITE_JOHTO_{tag}.*?\bdw {asmname}\s+db \$c0\s+db BANK\({asmname}\)', sets):
                problems.append('Gold NPC sprite sheet requires full 12 tiles: '+tag)
        engine=files['engine/overworld/map_sprites.asm']
        engine='\n'.join(line.split(';',1)[0].strip() for line in engine.splitlines())
        if not re.search(r'(?s)cp JOHTO_HOUSE.*?jr z, \.johtoHouseSprites.*?\.johtoHouseSprites\s+ld a, \$0c',engine):
            problems.append('house must select $0c and outdoor remain $0b')
        if not re.search(r'(?s)\.notVarSprite\s+cp a, SPRITE_JOHTO_POKEFAN_M\s+jr z, \.notFourTileSprite\s+cp a, SPRITE_JOHTO_LASS\s+jr z, \.notFourTileSprite',engine):
            problems.append('new 12-tile sprites must bypass legacy >= SPRITE_BALL four-tile path')
        colors=files['color/sprites.asm']
        for idx,name,pal in ((0x64,'POKEFAN_M','BROWN'),(0x65,'LASS','RED')):
            if not re.search(rf'(?m)^\s*; 0x{idx:02x}: SPRITE_JOHTO_{name}.*\n\s*db PAL_OW_{pal}\s*$',colors):
                problems.append('Gold NPC fixed palette mismatch '+name)
        if not re.search(r'(?m)^\s*overworld_sprite PokefanMSpriteGFX, 12, WALKING_SPRITE, PAL_OW_BROWN\s*$',gold_sprites) or not re.search(r'(?m)^\s*overworld_sprite LassSpriteGFX, 12, WALKING_SPRITE, PAL_OW_RED\s*$',gold_sprites):
            problems.append('Gold sprite palette original contract changed')
        main=files['main.asm']
        for name in ('pokefan_m','lass'):
            rpp_file=root/f'gfx/sprites/johto_{name}.png'
            original=gold/f'gfx/sprites/{name}.png'
            if rpp_file.read_bytes()!=original.read_bytes():
                problems.append('Gold source sprite differs: '+name)
            source='gfx/sprites/johto_'+name+'.2bpp'
            if main.count('INCBIN "'+source+'"')!=1:
                problems.append('Gold NPC art must be included exactly once: '+name)
        if 'SECTION "Johto Olivine House NPC Sprites", ROMX' not in main:
            problems.append('Gold sprite art must remain in relocatable ROMX section')
    except (OSError, ValueError) as exc:
        problems.append('required sprite reference missing: '+str(exc))
    return problems

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--rpp',type=Path,required=True);p.add_argument('--gold',type=Path,required=True)
    a=p.parse_args();issues=audit(a.rpp,a.gold)
    print('OLIVINE HOUSE NPC GOLD PARITY', 'PASS' if not issues else 'FAIL',*issues,sep='\n')
    raise SystemExit(bool(issues))
