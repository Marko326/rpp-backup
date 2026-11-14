#!/usr/bin/env python3
"""REF368D Gold-backed audit: ALL live Ice Path stairs, hop entries and cave field entry.

Only checks source/runtime wiring and exact Gold cell contracts; it cannot
execute ROM movement animation, resolve bank overflows or replace phone tests.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.johto_warp_field_entry_gate import warp_objects, registered_routes

GOLD = 'docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json'
FILES = {
    'IcePath1F': ('data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm', 'JohtoIcePath1FObjects367E'),
    'IcePathB1F': ('data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm', 'JohtoIcePathB1FObjects367K'),
    'IcePathB2FMahoganySide': ('data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm', 'JohtoIcePathB2FMahoganyObjects368A'),
    'IcePathB2FBlackthornSide': ('data/johto_ice_path_stage/ice_path_b2f_blackthorn_runtime_368c.asm', 'JohtoIcePathB2FBlackthornObjects368C'),
    'IcePathB3F': ('data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm', 'JohtoIcePathB3FObjects368B'),
}
# Original source order, with sealed PIT and ICE-arrival-only ordinals retained.
DEST_ORDINAL = {
    'IcePath1F': [0, 1, 0, 6],
    'IcePathB1F': [2, 0, 2, 3, 4, 5, 3, 0],
    'IcePathB2FMahoganySide': [1, 0, 2, 3, 4, 5],
    'IcePathB2FBlackthornSide': [7, 1],
    'IcePathB3F': [1, 1],
}
SEALED = {'IcePathB1F': set(range(2, 6)),
          'IcePathB2FMahoganySide': set(range(2, 6))}
LEDGES = {
    'IcePath1F': ('JohtoIcePath1FGoldHops368D', [(35,16,'PLAYER_DIR_LEFT'),
                   (35,16,'PLAYER_DIR_DOWN'), (36,16,'PLAYER_DIR_DOWN'), (37,16,'PLAYER_DIR_DOWN')]),
    'IcePathB2FBlackthornSide': ('JohtoIcePathBlackthornGoldHops368C',
                   [(5,8,'PLAYER_DIR_LEFT'), (5,8,'PLAYER_DIR_DOWN')] +
                   [(x,8,'PLAYER_DIR_DOWN') for x in range(6,10)]),
}
IDS = {'IcePath1F':'JOHTO_ICE_PATH_1F_LOCAL_ID',
       'IcePathB1F':'JOHTO_ICE_PATH_B1F_LOCAL_ID',
       'IcePathB2FMahoganySide':'JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID',
       'IcePathB2FBlackthornSide':'JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID',
       'IcePathB3F':'JOHTO_ICE_PATH_B3F_LOCAL_ID'}
BIKES = {'IcePath1F':('icePathBike','JohtoIcePath1FBikeFloorAllowed367J'),
         'IcePathB1F':('icePathB1FBike','JohtoIcePathB1FBikeFloorAllowed367K'),
         'IcePathB2FMahoganySide':('icePathB2FMahoganyBike','JohtoIcePathB2FMahoganyBikeFloorAllowed368A'),
         'IcePathB2FBlackthornSide':('icePathB2FBlackthornBike','JohtoIcePathB2FBlackthornBikeFloorAllowed368C'),
         'IcePathB3F':('icePathB3FBike','JohtoIcePathB3FBikeFloorAllowed368B')}

def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    errs = []
    def get(rel: str) -> bytes:
        raw = overrides.get(rel)
        return (root / rel).read_bytes() if raw is None else raw.encode() if isinstance(raw,str) else raw
    def txt(rel: str) -> str: return get(rel).decode('utf-8')
    def ck(condition: bool, message: str):
        if not condition: errs.append(message)
    gold = {m['name']: m for m in json.loads(txt(GOLD))['maps']}
    routes = registered_routes(txt('engine/johto_pilot_runtime.asm'))
    ck(len(routes) == 188 and len(set(routes)) == 188, 'global registered route inventory changed')
    # Verify all 16 original source ordinals, including 8 non-triggering
    # PIT/ICE entries; a duplicate or displaced step-in fails before routing.
    for name, (rel, label) in FILES.items():
        m = gold[name]
        try:
            actual = warp_objects(txt(rel), label)
        except (ValueError, IndexError) as exc:
            errs.append(f'{name} malformed warp table: {exc}')
            continue
        expected = []
        for i, w in enumerate(m['warps']):
            expected.append((255, 255, DEST_ORDINAL[name][i]) if i in SEALED.get(name,set())
                            else (w['x'], w['y'], DEST_ORDINAL[name][i]))
        ck(actual == expected, f'{name} live Warp cell/ordinal differs from Gold (sealed special slots preserved)')
        occupied = [(x,y) for x,y,_ in actual if x != 255 or y != 255]
        ck(len(occupied) == len(set(occupied)), f'{name} duplicate active Warp coordinates')
        roles = get('data/johto_ice_path_stage/' + name + '.roles.bin')
        width, height = m['width_cells'], m['height_cells']
        ck(len(roles) == width*height, f'{name} role grid dimensions bad')
        if len(roles) == width*height:
            for i, w in enumerate(m['warps']):
                if i in SEALED.get(name, set()): continue
                expected_role = {'LADDER':4, 'WARP_CARPET_DOWN':5}.get(w['role'])
                if expected_role is not None:
                    ck(roles[w['y']*width + w['x']] == expected_role,
                       f'{name} live Warp #{i+1} is not on its Gold collision role')
                if w['role'] == 'LADDER':
                    target = w['destination']; dest = w['destination_warp_1_based'] - 1
                    ck(f'MAP_REGION_JOHTO,{IDS[name]},{i},MAP_REGION_JOHTO,{IDS[target]}' in routes,
                       f'{name} Gold ladder #{i+1} missing source router')
                    ck(0 <= dest < len(gold[target]['warps']) and
                       gold[target]['warps'][dest]['role'] == 'LADDER',
                       f'{name} Gold ladder #{i+1} points to non-ladder arrival')
    # B1F #8 source and arrival collide at different, Gold-defined squares.
    b1f = txt(FILES['IcePathB1F'][0])
    stair_gate = b1f.split('JohtoIcePathB1FLandDecision367K::',1)[-1].split('JohtoIcePathB1FBikeFloorAllowed367K::',1)[0]
    m11 = re.search(r'(?ms)^\.ladder11\s*\n(.*?)^\.ladder17\s*$', stair_gate)
    ck(bool(m11 and re.search(r'cp 11\s*;[^\n]*\n\s*jr nz, \.ladder17\s*\n\s*ld a, b\s*\n\s*cp 27\s*\n\s*jr z, \.allow',m11.group(1))),
       'B1F Gold #8 (11,27) LADDER wall/collision not explicitly released')
    # All source HOP quadrants, directions and two-cell landings on both maps.
    ledges = txt('engine/overworld/ledges.asm')
    gateway = txt('engine/johto_land_collision_gateway_272.asm')
    for name,(label,expected) in LEDGES.items():
        m = gold[name]; roles = get('data/johto_ice_path_stage/' + name + '.roles.bin')
        first = ledges.split(label+':',1)
        section = first[1].split('db $ff',1)[0] if len(first)==2 else ''
        actual = [(int(x),int(y),d) for x,y,d in re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(PLAYER_DIR_\w+)\s*$', '\n'.join(line.split(';', 1)[0] for line in section.splitlines()))]
        ck(actual == expected and len(first)==2 and 'db $ff' in first[1],
           f'{name} full Gold directed HOP table missing/wrong')
        if len(roles) != m['width_cells']*m['height_cells']: continue
        for x,y,d in expected:
            width=m['width_cells'];role=roles[y*width+x]
            ck(role==(8 if x in (35,5) and d=='PLAYER_DIR_LEFT' else
                       8 if x in (35,5) else 7), f'{name} Gold HOP quadrant changed')
            nx,ny=(x-2,y) if d=='PLAYER_DIR_LEFT' else (x,y+2)
            ck(0<=nx<width and 0<=ny<m['height_cells'] and roles[ny*width+nx] in (0,2,4),
               f'{name} HOP landing is an air wall or off-map')
    ck('cp JOHTO_ICE_PATH\n    jp z, .icePathGold368D' in ledges and
       'cp JOHTO_ICE_PATH_1F_LOCAL_ID\n    jr z, .icePath1FHops368D' in ledges and
       'ld hl, JohtoIcePath1FGoldHops368D' in ledges and
       'ld hl, JohtoIcePathBlackthornGoldHops368C' in ledges and
       ledges.count('jp .ruinsCoordinateHopLookup') >= 2,
       'Ice Path two-map HOP native HandleLedges dispatcher missing')
    for label,nextlabel,helper in [('.icePath1F','.icePathB1F','JohtoIcePath1FLandDecision367F'),
                                   ('.icePathB2FBlackthorn','.darkCave','JohtoIcePathB2FBlackthornLandDecision368C')]:
        m=re.search(rf'(?ms)^\{label}\s*\n(.*?)^\{nextlabel}\s*$', gateway)
        body=m.group(1) if m else ''
        ck('callab HandleLedges' in body and 'bit 6, a' in body and
           'jr nz, .allowJump' in body and f'callab {helper}' in body and
           body.index('callab HandleLedges') < body.index(f'callab {helper}') if body and f'callab {helper}' in body else False,
           f'{label} HOP not connected to the real player land-gateway before collision')
    # CLEAN REF-368: phone-exported long-branch hotfixes (JR relative range).
    # Do not substitute a short JR merely because both spellings share a label:
    # some older source gates tested only label reachability, not branch span.
    pilot_jumps = txt('engine/johto_pilot_runtime.asm')
    for rel, source, target in (
        ('engine/johto_pilot_runtime.asm', pilot_jumps,
         'cp JOHTO_ICE_PATH_B3F_LOCAL_ID\n    jp z, .unionCaveLadder342'),
        ('engine/johto_land_collision_gateway_272.asm', gateway,
         'callab HandleLedges\n    ld a, [wd736]\n    bit 6, a\n    jp nz, .allowJump\n    callab JohtoEastSpatialStep'),
        ('engine/johto_land_collision_gateway_272.asm', gateway,
         'callab HandleLedges\n    ld a, [wd736]\n    bit 6, a\n    jp nz, .allowJump\n    callab JohtoRoute33StepPolicy'),
        ('engine/overworld/ledges.asm', ledges,
         'cp JOHTO_MODERN\n\tjp z, .route33Modern'),
        ('engine/overworld/ledges.asm', ledges,
         'cp JOHTO_PILOT\n\tjp z, .johtoPilot'),
    ):
        ck(target in source, 'REF-368 user long-jump hotfix not preserved: ' + rel + ': ' + target.split('\n')[-1])
    # PUBLIC bicycle item/shortcut entry, not an unreferenced role helper.
    bike = txt('home/rom0_relief_349.asm')
    bike_dispatch = bike.split('IsBikeRidingAllowed::',1)[-1].split('\n.legacyBike\n',1)[0]
    for name, (label,helper) in BIKES.items():
        ck(bool(re.search(rf'cp {IDS[name]}\s+jp z, \.+{label}\b',bike_dispatch)),
           f'{name} missing public Bicycle map-ID entry')
        part=bike.split('\n.'+label+'\n',1)
        blk=part[1].split('\n.',1)[0] if len(part)==2 else ''
        ck(f'callab {helper}' in blk and 'ld a, [wWalkBikeSurfState]' in blk and
           'jr z, .allowed' in blk,
           f'{name} public Bicycle must retain existing ride / delegate FLOOR-only predicate')
        code = txt(FILES[name][0])
        func=code.split(helper+'::',1)
        ck(len(func)>1 and 'scf' in func[1] and 'and a' in func[1],
           f'{name} Bicycle Gold FLOOR role helper missing')
    # Gold route mouth is CAVE (role=1) and safe landing is FLOOR (role=0).
    outdoor = [('Route44',60,56,7,56,8),('BlackthornCity',40,36,9,36,10)]
    for n,width,ix,iy,ox,oy in outdoor:
        roles=get('maps/johto_pilot/'+n+'.roles.bin')
        ck(roles[iy*width+ix]==1 and roles[oy*width+ox]==0,
           f'{n} Dig/Escape Rope exterior landing not Gold FLOOR below CAVE')
    rope=txt('engine/johto_ice_path_escape_368d.asm')
    ck('INCLUDE "engine/johto_ice_path_escape_368d.asm"' in txt('main.asm') and
       'DEF JOHTO_ICE_PATH_ANCHOR_BYTE EQU EVENT_9CA / 8' in rope and
       'ASSERT (EVENT_9CB % 8) == 3' in rope and 'and $f3' in rope and
       'cp JOHTO_ROUTE_44_LOCAL_ID' in rope and 'cp JOHTO_BLACKTHORN_CITY_LOCAL_ID' in rope and
       'cp $04' in rope and 'cp $08' in rope and 'jp nz, SoftReset' in rope and
       'FLYWARP_DATA JOHTO_ROUTE_44_WIDTH, 8, 56' in rope and
       'FLYWARP_DATA JOHTO_BLACKTHORN_CITY_WIDTH, 10, 36' in rope,
       'Ice Path Dig/Escape Rope save-backed exterior anchor / safe-floor data missing')
    allowed_body = rope.split('JohtoIcePathEscapeAllowed368D::', 1)[-1].split('JohtoIcePathApplyEscape368D::', 1)[0]
    ck(bool(re.search(r'and \$0c\s+cp \$04\s+jr z, \.allow\s+cp \$08\s+jr nz, \.deny', allowed_body)),
       'Ice Path Dig/Escape Rope save-backed exterior anchor must reject empty, mixed and invalid bits')
    for sid in IDS.values():
        ck(sid in rope, 'Ice Path Dig/Escape Rope map not allowed: '+sid)
    items=txt('engine/items/items.asm')
    ck('cp JOHTO_ICE_PATH\n    jr nz, .notIcePathRope368D' in items and
       'callab JohtoIcePathEscapeAllowed368D\n    ret' in items,
       'Ice Path Dig/Escape Rope public item usability not reachable')
    fly=txt('engine/fly_town_map_helpers.asm')
    ck('cp JOHTO_ICE_PATH\n    jr nz, .darkCaveEscape365' in fly and
       'callab JohtoIcePathEscapeAllowed368D' in fly and
       'callab JohtoIcePathApplyEscape368D' in fly,
       'Ice Path accepted rope missing special warp / original exterior return')
    pilot=txt('engine/johto_pilot_runtime.asm')
    ck('cp JOHTO_ICE_PATH_1F_LOCAL_ID\n    jr nz, .notIcePathOrigin368D' in pilot and
       'ld e, c\n    callab JohtoIcePathRememberOutdoorSource368D' in pilot and
       'push hl\n    push bc\n    ld e, c' in pilot,
       'Ice Path outside-only entrance anchor capture missing/unsafe')
    ck('db "REF-368@"' in txt('data/game_version.asm'), 'current Ice Path dev label missing')
    return errs

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);a=p.parse_args()
    errs=audit(a.root)
    for s in errs: print('FAIL:',s)
    if not errs: print('PASS: five Ice Path maps, 12 active Gold stair slots, 10 directed HOPs, public Bicycle, anchored Dig/Escape Rope')
    raise SystemExit(bool(errs))
