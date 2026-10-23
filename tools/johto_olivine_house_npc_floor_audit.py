#!/usr/bin/env python3
"""Check house-only NPC walkable graphic IDs vs Gold-cell collision mask.

This is not an RGBDS/link/phone test. The player and NPC collision paths differ:
players use JohtoModernMaskedStep; NPCs use wTilesetCollisionPtr.
"""
from pathlib import Path
import argparse
import re

HOUSE = 'JohtoOlivinePunishmentSpeechHouse'


def audit(root: Path, gold: Path) -> list[str]:
    errors: list[str] = []
    try:
        tilecoll = (root/'gfx/tilesets/johto_house.tilecoll').read_bytes()
        expected = bytes((0x01, 0x10, 0x12, 0xFF))
        if tilecoll != expected:
            errors.append('house-only NPC collision whitelist must equal 01 10 12 FF')
        tile_ids = set(tilecoll[:-1])
        mask = (root/f'maps/{HOUSE}.blocked_mask.bin').read_bytes()
        blocks = (root/f'maps/{HOUSE}.blk').read_bytes()
        bst = (root/'gfx/blocksets/johto_house.bst').read_bytes()
        if len(mask) != 8 or len(blocks) != 16 or len(bst) % 16:
            errors.append('house mask/blockset dimensions incorrect')
        else:
            # A sprite stands on the lower-left 8x8 tile of a Gold 16x16 cell.
            # The house 4x4 .blk maps blocks of 4x4 graphic 8x8 tiles.
            for y in range(8):
                for x in range(8):
                    i = blocks[(y//2)*4+(x//2)]*16 + (((y%2)*2+1)*4+(x%2)*2)
                    if i >= len(bst):
                        errors.append('house blockset index out of bounds')
                        continue
                    graphic_id=bst[i]
                    blocked=bool(mask[y] & (1<<x))
                    if (graphic_id in tile_ids) == blocked:
                        errors.append(f'NPC/passable mask conflict ({x},{y}) graphic ${graphic_id:02x}')
            # Original daughter at 5,5. If either adjacent floor cannot be
            # stepped on, she may turn left/right but cannot translate.
            for x in (4,5,6):
                i=blocks[(5//2)*4+(x//2)]*16+(((5%2)*2+1)*4+(x%2)*2)
                if bst[i] not in tile_ids:
                    errors.append(f'Gold daughter horizontal floor blocked at ({x},5)')
        header=(root/'data/tileset_headers.asm').read_text()
        if not re.search(r'(?m)^\s*tileset JohtoHouse_Block,\s*JohtoHouse_GFX,\s*JohtoHouse_Coll,',header):
            errors.append('house tileset not bound to its own NPC collision list')
        collision=(root/'data/collision.asm').read_text()
        if 'JohtoHouse_Coll:: INCBIN "gfx/tilesets/johto_house.tilecoll"' not in collision:
            errors.append('isolated house NPC collision list not included')
        engine=(root/'engine/overworld/movement.asm').read_text()
        if not re.search(r'CanWalkOntoTile:.*?\[wTilesetCollisionPtr\].*?\.tilePassableLoop.*?cp c',engine,re.S):
            errors.append('NPC engine collision flow not verified')
        if 'cp JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID' not in (root/'engine/overworld/johto_route33_collision.asm').read_text():
            errors.append('separate player Gold-cell mask path missing')
        objects=(root/f'data/mapObjects/{HOUSE}.asm').read_text()
        if not re.search(r'(?m)^\s*object SPRITE_JOHTO_LASS, 5, 5, WALK, 2, 2\b',objects):
            errors.append('daughter must be configured for horizontal walking')
        if len(re.findall(r'(?m)^\s*db 1, [01], [34]\s*$',objects))!=2:
            errors.append('house must register both original shelves only')
        gold_room=(gold/'maps/OlivinePunishmentSpeechHouse.asm').read_text()
        gold_bg=re.findall(r'(?m)^\s*bg_event\s+(\d+),\s*(\d+),\s*BGEVENT_READ,\s*(\S+)',gold_room)
        if [(int(x),int(y)) for x,y,_ in gold_bg]!=[(0,1),(1,1)]:
            errors.append('Gold only has two bookshelf BG events, not a town-map event')
        if len(re.findall(r'(?m)^\s*object_event ',gold_room))!=2:
            errors.append('Gold original NPC count unexpectedly changed')
    except (OSError, IndexError) as exc:
        errors.append('house floor source missing: '+str(exc))
    return errors

if __name__ == '__main__':
    p=argparse.ArgumentParser(); p.add_argument('--rpp',type=Path,required=True);p.add_argument('--gold',type=Path,required=True)
    a=p.parse_args();issues=audit(a.rpp,a.gold)
    print('OLIVINE HOUSE NPC FLOOR', 'PASS' if not issues else 'FAIL',*issues,sep='\n')
    raise SystemExit(bool(issues))
