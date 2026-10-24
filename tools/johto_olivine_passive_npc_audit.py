#!/usr/bin/env python3
"""Audit passive Olivine NPC conversion against Gold. Static, never ROM proof."""
from pathlib import Path
import re

ROOMS = (
    ('OlivineTimsHouse', 'SPRITE_JOHTO_FISHING_GURU_RED', 'STAY, NONE',
     'SPRITEMOVEDATA_SPINRANDOM_SLOW', 'PAL_NPC_RED'),
    ('OlivineGoodRodHouse', 'SPRITE_JOHTO_FISHING_GURU_GREEN', 'STAY, DOWN',
     'SPRITEMOVEDATA_STANDING_DOWN', 'PAL_NPC_GREEN'),
)

def audit(root: Path, gold: Path) -> list[str]:
    errors = []
    try:
        for name, sprite, behavior, gb, pal in ROOMS:
            origin = (gold/'maps'/f'{name}.asm').read_text()
            obj = (root/'data/mapObjects'/f'Johto{name}.asm').read_text()
            gold_pat = (rf'object_event\s+2,\s*3,\s*SPRITE_FISHING_GURU,\s*{gb},\s*'
                        rf'0,\s*0,\s*-1,\s*-1,\s*{pal},')
            if not re.search(gold_pat, origin):
                errors.append(f'{name}: Gold NPC origin changed')
            if len(re.findall(r'(?m)^\s*object_event ',origin)) != 1:
                errors.append(f'{name}: wrong Gold NPC count')
            if not re.search(rf'(?m)^\s*object {sprite}, 2, 3, {behavior}, 1\b', obj):
                errors.append(f'{name}: sprite, position, motion or text index mismatch')
            if len(re.findall(r'(?m)^\s*object SPRITE_', obj)) != 1 or 'db $01 ; Gold' not in obj:
                errors.append(f'{name}: must register exactly one non-event NPC')
        actual = (root/'gfx/sprites/johto_fishing_guru.png').read_bytes()
        if actual != (gold/'gfx/sprites/fishing_guru.png').read_bytes():
            errors.append('Fishing Guru PNG must match Gold original byte-for-byte')
        sets = (root/'data/sprite_sets.asm').read_text()
        palette = (root/'color/sprites.asm').read_text()
        const = (root/'constants/sprite_constants.asm').read_text()
        graphics = (root/'main.asm').read_text()
        motion = (root/'engine/overworld/map_sprites.asm').read_text()
        sprite_list = re.findall(r'(?m)^\s*const (SPRITE_\w+)',
                const.split('; overworld sprites',1)[1].split('; Variable Sprite IDs Here',1)[0])
        for num, suffix, color in ((0x66,'RED','RED'), (0x67,'GREEN','GREEN')):
            sprite = f'SPRITE_JOHTO_FISHING_GURU_{suffix}'
            if len(sprite_list)<num or sprite_list[num-1] != sprite:
                errors.append(f'{sprite}: fixed ID must be {num:02X}')
            if not re.search(rf'; 0x{num:02x}: {sprite}.*\n\s*db PAL_OW_{color}', palette):
                errors.append(f'{sprite}: Gold palette mismatch')
            if not re.search(rf'cp a, {sprite}\s+jr z, \.notFourTileSprite', motion):
                errors.append(f'{sprite}: 12-tile / 4-tile VRAM misclassification')
        section = sets.split('; sprite set $0c',1)[1].split('SpriteSheetPointerTable:',1)[0]
        want = ['SPRITE_JOHTO_FISHING_GURU_RED', 'SPRITE_JOHTO_FISHING_GURU_GREEN']
        if not all(section.count('db '+w)==1 for w in want):
            errors.append('House $0c sprite sheet must include both Guru palette IDs')
        pointers = sets.split('SpriteSheetPointerTable:',1)[1]
        if pointers.count('dw JohtoFishingGuruSprite') != 2:
            errors.append('Two sprite pointers must reuse one Gold Guru 12-tile asset')
        if graphics.count('JohtoFishingGuruSprite: INCBIN "gfx/sprites/johto_fishing_guru.2bpp"') != 1:
            errors.append('One PNG-derived 12-tile Guru sprite source must be included')
        passive = (root/'engine/overworld/johto_passive_house_npc.asm').read_text()
        handler = (root/'home/overworld.asm').read_text()
        if not re.search(r'callba IsDeferredOlivineHouseNPC\s+jp c, OverworldLoop\s+\n?\s*; Boulder', handler):
            errors.append('NPC A must return before normal dialogue/script/boulder dispatch')
        for needle in ('cp MAP_REGION_JOHTO', 'cp JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID',
                       'cp JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID',
                       'cp 1', 'predef GetTileAndCoordsInFrontOfPlayer',
                       'cp 3', 'cp 2', 'scf', 'and a'):
            if needle not in passive:
                errors.append('Missing no-op NPC guard: '+needle)
        if 'INCLUDE "engine/overworld/johto_passive_house_npc.asm"' not in graphics:
            errors.append('No-op guard never linked')
        # A sign shares the same ID #1 as Tim; the guard must check NPC tile (2,3)
        # to preserve both magazine-bookshelf actions. This isn't a CPU emulator.
        source = passive.split('predef GetTileAndCoordsInFrontOfPlayer',1)[1]
        if not re.search(r'ld a, d\s+cp 3\s+jr nz, \.notPassive\s+ld a, e\s+cp 2',source):
            errors.append('NPC guard must ignore signage while accepting (x2,y3)')
    except (OSError, ValueError, IndexError) as ex:
        errors.append(f'missing passive NPC contract: {ex}')
    return errors

if __name__ == '__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--rpp',type=Path,required=True)
    p.add_argument('--gold',type=Path,required=True);args=p.parse_args()
    issues=audit(args.rpp,args.gold)
    print('JOHTO PASSIVE NPC:', 'PASS' if not issues else 'FAIL',*issues,sep='\n')
    raise SystemExit(bool(issues))
