#!/usr/bin/env python3
"""Cross-town Cherrygrove House1 source/runtime contract (STATIC, not ROM proof).

The Gold three-house group is deliberately different from Olivine's scripted
houses: 3 city Warp positions, 6 inside exits, 5 visible NPCs, and NO story.
Mutation tests exercise the actual audit instead of weakening old gate tests.
"""
import argparse
import json
import re
from pathlib import Path

ROOMS = (
    ('CherrygroveGymSpeechHouse', 'JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID',
     'CHERRYGROVE_GYM_SPEECH_HOUSE', 124, 52, 17, 7,
     (('SPRITE_JOHTO_POKEFAN_M', 2, 3), ('SPRITE_JOHTO_BUG_CATCHER_RED', 5, 5))),
    ('GuideGentsHouse', 'JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID',
     'GUIDE_GENTS_HOUSE', 125, 53, 25, 9,
     (('SPRITE_JOHTO_GRAMPS', 2, 3),)),
    ('CherrygroveEvolutionSpeechHouse', 'JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID',
     'CHERRYGROVE_EVOLUTION_SPEECH_HOUSE', 126, 54, 31, 11,
     (('SPRITE_JOHTO_LASS_GREEN', 3, 5), ('SPRITE_JOHTO_YOUNGSTER_RED', 2, 5))),
)


def audit(project: Path, gold: Path, overrides=None):
    root, gold = Path(project), Path(gold)
    overrides = overrides or {}
    errors = []
    def src(path, gold_src=False):
        if not gold_src and path in overrides:
            return overrides[path]
        return ((gold if gold_src else root) / path).read_text(encoding='utf-8')
    def binary(path): return (root / path).read_bytes()
    def check(ok, reason):
        if not ok: errors.append(reason)
    try:
        city = src('data/mapObjects/JohtoCherrygroveCity.asm')
        gold_city = src('maps/CherrygroveCity.asm', gold_src=True)
        lookup = src('engine/overworld/region_map_lookup.asm')
        header_table = src('data/johto_map_headers.asm')
        sprite_set = src('data/sprite_sets.asm')
        sprite_pals = src('color/sprites.asm')
        sprite_ids = src('constants/sprite_constants.asm')
        sprites = src('engine/overworld/map_sprites.asm')
        fence = src('engine/overworld/johto_route33_collision.asm')
        passive = src('engine/overworld/johto_passive_house_npc.asm')
        main = src('main.asm')
        cfg = json.loads(src('tools/johto_native_maps.json'))
        old_house_layout = binary('maps/JohtoOlivinePunishmentSpeechHouse.blk')
        old_house_mask = binary('maps/JohtoOlivinePunishmentSpeechHouse.blocked_mask.bin')
    except (OSError, ValueError) as exc:
        return ['missing source or invalid manifest: '+str(exc)]
    check('DEF NUM_JOHTO_MAPS EQU 57' in src('constants/region_map_constants.asm'),
          'active Johto count must be 57')
    check([r.get('local_id') for r in cfg['maps'][52:55]] == [124, 125, 126]
          and [r.get('local_id') for r in cfg['maps'][55:57]] == [122, 123] and len(cfg['maps']) == 57, 'new stable IDs or dense slots drifted')
    check(re.search(r'(?m)^\s*db\s+\$05\s*;.*Gold', city) is not None,
          'exactly 3 Cherrygrove ordinary-house and 2 public-building exterior Warps must be enabled')
    city_entries = re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*REGION_WARP_ESCAPE', city)
    check(city_entries == [('7','17','0'),('9','25','0'),('11','31','0'),('3','23','0'),('3','29','0')],
          'city Warps do not match Gold 3/4/5 plus Gold Mart/PC doors')
    try:
        sheet = sprite_set.split('; sprite set $0c:',1)[1].split('SpriteSheetPointerTable:',1)[0]
        sheet_ids = re.findall(r'^\s*db\s+(SPRITE_\w+)', sheet, re.M)
    except IndexError:
        sheet_ids = []
    check(len(sheet_ids)==11 and sheet_ids[-2:]==['SPRITE_BALL','SPRITE_BERRY_TREE'],
          'House1 sprite VRAM set must be nine 12-tile NPCs plus two small objects')
    for name, symbol, gold_name, stable, slot, x, y, people in ROOMS:
        prefix = 'Johto'+name
        path = 'data/mapObjects/'+prefix+'.asm'
        try:
            obj=src(path)
            gsrc=src('maps/'+name+'.asm',gold_src=True)
            local_layout=binary('maps/'+prefix+'.blk')
            local_mask=binary('maps/'+prefix+'.blocked_mask.bin')
        except OSError as exc:
            errors.append(name+': source or packed assets missing: '+str(exc))
            continue
        check(re.search(rf'(?m)^\s*warp_event\s+{x},\s*{y},\s*{gold_name},\s*1\b',gold_city) is not None,
              name+': Gold city exterior source changed')
        check(re.findall(r'(?m)^\s*warp_event\s+(\d+),\s*(\d+),\s*CHERRYGROVE_CITY,\s*(\d+)',gsrc)
              == [('2','7',str(slot-49)),('3','7',str(slot-49))],
              name+': Gold room 2-lane exits changed')
        check(local_layout == old_house_layout and len(local_layout)==16,
              name+': compact House1 graphic block mapping differs from accepted Olivine House1')
        check(local_mask == old_house_mask and len(local_mask)==8,
              name+': compact House1 collision mask drifted')
        check(f'dw {prefix}_h' in header_table and f'db BANK({prefix}_h)' in header_table,
              name+': missing header/bank')
        check(f'dw {prefix}_h ; stable {symbol} -> slot {slot}' in header_table,
              name+': active header slot or stable ID drift')
        check(f'db {y}, {x}, 0, REGION_WARP_ESCAPE' in city,
              name+': city door missing')
        for exit_x in (2,3):
            check(f'db 7, {exit_x}, {slot-52}, REGION_WARP_ESCAPE' in obj,
                  name+': missing exit lane '+str(exit_x))
        city_local='JOHTO_CHERRYGROVE_LOCAL_ID'
        check(lookup.count(f'db {city_local}, {slot-52}, 0, MAP_REGION_JOHTO, {symbol}')==1,
              name+': city→room native resolver wrong')
        for lane in (0,1):
            check(lookup.count(f'db {symbol}, {lane}, {slot-52}, MAP_REGION_JOHTO, {city_local}')==1,
                  name+': room→city native resolver wrong lane '+str(lane))
        check(f'db REGION_NATIVE_MAP_SLOT, JOHTO_CHERRYGROVE_LOCAL_ID, {y}, {x}, REGION_NATIVE_MAP_SLOT, D_DOWN' in lookup,
              name+': outdoor arrival must match native Cherrygrove $FC/local 2')
        native_targets = lookup.split('NativeRegionWarpTargets::', 1)[1].split('NativeRegionWarpTargetsEnd::', 1)[0]
        check(native_targets.count(f'db {city_local}, {slot-52}, 0, MAP_REGION_JOHTO, {symbol}') == 1,
              name+': native city→room Warp target missing')
        explicit_targets = lookup.split('ExplicitWarpRegionTargets::', 1)[1].split('NativeRegionWarpTargets::', 1)[0]
        check('db JOHTO_CHERRYGROVE_CITY,' not in explicit_targets,
              name+': legacy $CE city Warp resolver must not remain active')
        check(f'cp {symbol}' in fence and f'cp {symbol}' in passive,
              name+': direction/step or passive A-key guard absent')
        check(f'INCLUDE "data/mapHeaders/{prefix}.asm"' in main
              and f'INCLUDE "data/mapObjects/{prefix}.asm"' in main
              and f'INCLUDE "scripts/{prefix}.asm"' in main,
              name+': room not linked in ROM')
        check(re.search(rf'(?m)^\s*db\s+\${len(people):02x}\s*;.*Gold',obj) is not None,
              name+': wrong NPC count')
        npc_rows = re.findall(r'(?m)^\s*object\s+([^;\n]+)',obj)
        check(len(npc_rows)==len(people),name+': Gold NPC number changed')
        for idx, (want_id,xx,yy) in enumerate(people):
            if idx >= len(npc_rows): break
            args=[a.strip() for a in npc_rows[idx].split(',')]
            check(len(args)==6, name+f': NPC {idx} macro MUST have 6 args (7 turns it into an item)')
            check(args[:3]==[want_id,str(xx),str(yy)],name+f': NPC {idx} sprite or spawn differs')
            check(bool(re.search(rf'(?m)^\s*object_event\s+{xx},\s*{yy},',gsrc)),
                  name+f': Gold NPC {idx} location source changed')
            check(want_id in sheet_ids and f'const {want_id}' in sprite_ids,
                  name+f': NPC {idx} not in House1 sprite sheet or constant table')
        check('db $00 ; background events postponed' in obj,
              name+': events must remain deferred')
        if slot == 54:
            check('SPRITE_JOHTO_LASS_GREEN' in sprite_pals and
                  re.search(r'; SPRITE_JOHTO_LASS_GREEN:[^\n]*\n\s*db PAL_OW_GREEN',sprite_pals),
                  'Evolution Lass must be Gold green, not Olivine red')
            check('dw JohtoLassSprite\n\tdb $c0\n\tdb BANK(JohtoLassSprite)' in sprite_set,
                  'green Lass sprite alias must reference original Gold graphic')
            check('cp a, SPRITE_JOHTO_LASS_GREEN' in sprites,
                  'green Lass alias must be classified as 12-tile sprite')
    # Data tables alone are insufficient: validate all four live caller paths.
    overworld = src('home/overworld.asm')
    warp_loop = overworld.split('CheckWarpsNoCollisionLoop::', 1)[-1].split('CheckWarpsCollision::', 1)[0]
    checker = overworld.split('IsJohtoSouthGatePortal::', 1)[-1].split('MapEntryAfterBattle::', 1)[0]
    land = overworld.split('CollisionCheckOnLand::', 1)[-1].split('; function that checks if the tile in front', 1)[0]
    door = fence.split('JohtoCherrygroveHouseDoorStepAllowed::', 1)[-1].split('JohtoRoute29GateStepAllowed::', 1)[0]
    # Exact Gold door Warps with UP approach, before native portal dispatch.
    city_handle = warp_loop.find('cp REGION_NATIVE_MAP_SLOT')
    city_region = warp_loop.find('cp MAP_REGION_JOHTO', city_handle)
    city_local = warp_loop.find('cp JOHTO_CHERRYGROVE_LOCAL_ID', city_region)
    city_up = warp_loop.find('cp PLAYER_DIR_UP', city_local)
    city_transfer = warp_loop.find('jp WarpFound1', city_up)
    city_portal = warp_loop.find('call IsJohtoSouthGatePortal', city_up)
    check(min(city_handle, city_region, city_local, city_up, city_transfer, city_portal) >= 0
          and city_handle < city_region < city_local < city_up < city_transfer < city_portal,
          'live native Cherrygrove Warp must transfer before generic portal dispatch')
    native_handle = land.find('cp REGION_NATIVE_MAP_SLOT')
    native_region = land.find('cp MAP_REGION_JOHTO', native_handle)
    native_local = land.find('cp JOHTO_CHERRYGROVE_LOCAL_ID', native_region)
    door_call = land.find('callba JohtoCherrygroveHouseDoorStepAllowed', native_local)
    generic_pair = land.find('call CheckForJumpingAndTilePairCollisions', door_call)
    check(min(native_handle, native_region, native_local, door_call, generic_pair) >= 0
          and native_handle < native_region < native_local < door_call < generic_pair
          and 'jp c, .noCollision' in land,
          'live native city collision path must bypass generic tile-pair rejection before generic check')
    check('.legacyCherrygroveHouseDoor' not in checker,
          'obsolete $CE gate path must not shadow direct transfer')
    check(all(f'cp {x}' in door for x in (17, 25, 31)) and
          all(f'cp {y}' in door for y in (8,10,12)) and
          'cp PLAYER_DIR_UP' in door,
          'native city entrance must allow only correct coordinates and UP approach')
    check('cp JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID' in checker
          and 'cp JOHTO_CHERRYGROVE_EVOLUTION_SPEECH_HOUSE_LOCAL_ID + 1' in checker,
          'interior down-facing exit carpets must use collision-only selector')
    # Each door exact, and at the original x/y (not just one blanket "UP").
    check('jp z, .cherrygroveHouseDoors' in fence and
          '.cherrygroveHouseDoors' in fence and
          'cp 17' in fence.split('\n.cherrygroveHouseDoors\n',1)[-1].split('\n.houseExitDown\n',1)[0],
          'Cherrygrove door direction guard missing')
    check('db $00' in src('data/mapObjects/JohtoCherrygroveEvolutionSpeechHouse.asm') and
          'jp z, .houseExitDown' in fence,
          'House1 exit/down guard missing')
    return errors

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--rpp',type=Path,required=True);p.add_argument('--gold',type=Path,required=True)
    args=p.parse_args();err=audit(args.rpp,args.gold)
    print(json.dumps({'status':'FAIL' if err else 'PASS','errors':err,'built_rom':False,'phone_verified':False},ensure_ascii=False,indent=2))
    raise SystemExit(bool(err))
