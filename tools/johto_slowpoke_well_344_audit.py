#!/usr/bin/env python3
"""REF-344: independent Gold/source contract for the next shared cave floor.

Read-only: verifies B2F source, 1:1 reusable cave metatile conversion,
Gold-collision tables, two-way ladders, Strength boulder and active registry.
Not a ROM build or hardware test. Supports injectable source edits for regressions.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

MAP = 'SlowpokeWellB2F'
WELL = 'data/johto_union_cave_runtime.asm'
FIELD = 'engine/johto_violet_field_skills.asm'
ROUTES = 'engine/johto_pilot_runtime.asm'


def check(root: Path, gold_root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    overrides = overrides or {}
    errs = []
    def source(path: str) -> str:
        val = overrides.get(path)
        return val if isinstance(val, str) else (root / path).read_text()
    def binary(path: str) -> bytes:
        val = overrides.get(path)
        return val if isinstance(val, bytes) else (root / path).read_bytes()
    def require(ok: bool, what: str):
        if not ok:
            errs.append(what)
    def body(s: str, start: str, end: str) -> str:
        if start not in s or end not in s:
            errs.append('missing block ' + start)
            return ''
        return s.split(start, 1)[1].split(end, 1)[0]

    cave = source(WELL)
    field = source(FIELD)
    runtime = source(ROUTES)
    gold = binary('maps/johto_pilot/SlowpokeWellB2F.gold.blk')
    runtime_map = binary('maps/johto_pilot/SlowpokeWellB2F.runtime.blk')
    original = (gold_root / 'maps/SlowpokeWellB2F.blk').read_bytes()
    require(len(gold) == 90 and gold == original, 'B2F source must be original Gold 10x9')
    require(len(runtime_map) == 90, 'B2F runtime blocks need 90 metatiles')
    # Ensure every Gold source block has the same Gold->RPP conversion on every
    # prior tested cave floor; disallow ad-hoc mappings on the new floor.
    mapping = {}
    for n in ('UnionCave1F','UnionCaveB1F','UnionCaveB2F','SlowpokeWellB1F'):
        gs = binary(f'maps/johto_pilot/{n}.gold.blk')
        rs = binary(f'maps/johto_pilot/{n}.runtime.blk')
        for g, r in zip(gs, rs):
            if g in mapping and mapping[g] != r:
                errs.append(f'legacy cave metatile conversion ambiguous: {g:02x}')
            mapping[g] = r
    require(len(gold) == len(runtime_map) and all(mapping.get(g) == r for g, r in zip(gold, runtime_map)),
            'B2F must reuse existing Gold->RPP cave block conversion')

    roles = {}
    for line in (gold_root/'data/tilesets/cave_collision.asm').read_text().splitlines():
        m = re.search(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})', line)
        if m:
            roles[int(m[2],16)] = [q.strip() for q in m[1].split(',')]
    require(len(roles) == 64, 'original Gold cave collision roles must be available')
    if len(gold) == 90 and len(roles) == 64:
        cell = {(y,x):roles[gold[y//2*10+x//2]][y%2*2+x%2]
                for y in range(18) for x in range(20)}
        def coords(name):
            text = body(field, name+'::',name+'End::')
            entries = re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+)\s*$',text)
            return [(int(a),int(b)) for a,b in entries]
        for label, role, size in (
                ('JohtoSlowpokeWellB2FGoldWaterCells','WATER',100),
                ('JohtoSlowpokeWellB2FUpWallCells','UP_WALL',31)):
            expected = sorted((y,x) for (y,x), v in cell.items() if v == role)
            actual = coords(label)
            require(actual == expected and len(expected) == size,
                    f'{label}: exact ordered Gold {role} mismatch')
        require(cell[11,9] == 'LADDER', 'B2F ladder (9,11) must be Gold LADDER')
        # Exercise all 644 Gold-walkable directional moves and 400 Surf
        # neighbor transitions with the exact shared cave adapter policy.
        # This is a static behavioral model, NOT a ROM execution trace.
        blockset = binary('gfx/blocksets/johto_union_cave.bst')
        pass_tiles = set(binary('gfx/tilesets/johto_union_cave.tilecoll')) - {255}
        land = {'FLOOR','LADDER','WARP_CARPET_DOWN','UP_WALL','HOP_RIGHT'}
        land_checks = surf_checks = 0
        land_errors, surf_errors = [], []
        for y in range(18):
            for x in range(20):
                current = cell[y,x]
                for direction, dx, dy in (('UP',0,-1),('DOWN',0,1),('LEFT',-1,0),('RIGHT',1,0)):
                    tx, ty = x+dx, y+dy
                    inside = 0 <= tx < 20 and 0 <= ty < 18
                    target = cell[ty,tx] if inside else 'OFF'
                    visual_pass = False
                    if inside:
                        rblock = runtime_map[ty//2*10+tx//2]
                        visual_tile = blockset[rblock*16+((ty%2)*2+1)*4+(tx%2)*2]
                        visual_pass = visual_tile in pass_tiles
                    if current in land:
                        expected = (inside and target in land and
                                    not (direction=='UP' and current=='UP_WALL') and
                                    not (direction=='DOWN' and target=='UP_WALL'))
                        actual = (inside and not (direction=='UP' and current=='UP_WALL') and
                                  ((direction!='DOWN') if target=='UP_WALL' else visual_pass))
                        land_checks += 1
                        if expected != actual:
                            land_errors.append((x,y,direction,target))
                    if current == 'WATER':
                        expected = ('water' if target=='WATER' else
                                    'land' if inside and target in land and not
                                    (target=='UP_WALL' and direction=='DOWN') else 'block')
                        actual = ('water' if target=='WATER' else
                                  'land' if inside and ((target=='UP_WALL' and direction!='DOWN') or
                                                        (target!='UP_WALL' and visual_pass)) else 'block')
                        surf_checks += 1
                        if expected != actual:
                            surf_errors.append((x,y,direction,target))
        require(land_checks==644 and not land_errors, 'B2F Gold land-direction parity failed: '+str(land_errors[:4]))
        require(surf_checks==400 and not surf_errors, 'B2F Gold Surf-shore parity failed: '+str(surf_errors[:4]))
    # No shared engine fork. Ensure one cave profile serves all five floors.
    require('db JOHTO_UNION_CAVE\n    db JOHTO_SLOWPOKE_WELL_B2F_HEIGHT' in cave,
            'B2F must reuse existing JohtoUnion Cave tileset/profile')
    require('object SPRITE_BOULDER, 3, 2, STAY, BOULDER_MOVEMENT_BYTE_2, $1' in cave,
            'Gold B1F boulder requires legacy Strength movement byte')
    original_b1f = (gold_root/'maps/SlowpokeWellB1F.asm').read_text()
    require(bool(re.search(r'(?m)^\s*object_event\s+3,\s*2,\s*SPRITE_BOULDER',original_b1f)),
            'Gold B1F boulder coordinate not proven')
    # Check the four immediate push targets using the *existing* cave tile
    # whitelist used by RBY Strength. This does not claim arbitrary long
    # routes / UP_WALL boulder behavior match Gold without a gameplay test.
    b1gold = binary('maps/johto_pilot/SlowpokeWellB1F.gold.blk')
    b1run = binary('maps/johto_pilot/SlowpokeWellB1F.runtime.blk')
    bst = binary('gfx/blocksets/johto_union_cave.bst')
    whitelist = set(binary('gfx/tilesets/johto_union_cave.tilecoll')) - {255}
    for x, y, expect in ((3,1,False),(3,3,True),(2,2,True),(4,2,True)):
        off=y//2*10+x//2
        gr=roles[b1gold[off]][y%2*2+x%2]
        r=b1run[off]
        tile=bst[r*16+(y%2*2+1)*4+(x%2)*2]
        require((gr == 'FLOOR') == expect and (tile in whitelist) == expect,
                f'B1F Strength immediate Gold/legacy passability disagreement at {(x,y)}')
    b1 = body(cave,'JohtoSlowpokeWellB1FRuntimeObjects::','; REF-344: Gold Slowpoke Well B2F')
    b2 = cave.split('JohtoSlowpokeWellB2FRuntimeObjects::',1)[-1]
    for text,what in (
        ('db 11, 7, 0, JOHTO_REGISTERED_WARP_SELECTOR','B1F down ladder'),
        ('db 2 ; Gold #1 back to Azalea, Gold #2 down to B2F','B1F warp count'),
    ):
        require(text in b1, what)
    for text,what in (
        ('db 11, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR','B2F up ladder'),
        ('db 1','B2F warp count'),
        ('db 0 ; Gym Guide and Rain Dance TM events deferred','B2F NPC events still deferred'),
    ):
        require(text in b2, what)
    route_rows = [x.strip().split(';',1)[0].strip() for x in
                  body(runtime,'JohtoRegisteredWarpRoutes::','JohtoRegisteredWarpRoutesEnd::').splitlines()
                  if x.strip().startswith('db ')]
    require(len(route_rows) == 144 and len(set(route_rows)) == 144,
            'expected 144 nonduplicated registered warp routes')
    for row in (
        'db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID',
        'db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID',
    ):
        require(route_rows.count(row) == 1,'missing B1F<->B2F reciprocal registered route')
    require('DEF NUM_JOHTO_ACTIVE_MAPS EQU 61' in source('constants/region_map_constants.asm'),
            'active maps must total 61')
    require('DEF JOHTO_PILOT_SOURCE_COUNT EQU 61' in source('data/johto_pilot_source_resources.asm'),
            'Gold source maps must total 61')
    require(' 59, 60,' in source('data/johto_stable_id_slots.asm'),
            'Gold physical ID185 should route to compact slot60')
    require('cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID' in source('engine/johto_land_collision_gateway_272.asm'),
            'B2F must enter the existing cave collision gateway')
    require('cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID' in field,
            'B2F must enter Gold cave water and direction helper')
    require('jr .loop\n.slowpokeB2fWater' in field,
            'B1F water must not fall through into B2F water table')
    require('cp JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID\n\tjr z, .wellHeight' in field,
            'both short well floors must use the exact 18-cell bound')
    require('BOULDER_MOVEMENT_BYTE_2' in source('engine/overworld/push_boulder.asm'),
            'must use the preexisting RBY Strength pushing engine')
    require('cp BOULDER_MOVEMENT_BYTE_2' in source('engine/overworld/field_moves.asm'),
            'boulder interaction must use existing field-move dispatcher')
    return errs


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path,default=Path.cwd())
    p.add_argument('--gold-root',type=Path,required=True)
    args=p.parse_args()
    errors=check(args.project,args.gold_root)
    print(json.dumps({'status':'PASS_STATIC_ONLY' if not errors else 'FAIL',
                      'checked':'B2F Gold conversion, 644 land moves + 400 Surf transitions, 100 WATER, 31 UP_WALL, both ladders, Strength object, 61 maps, 144 routes',
                      'errors':errors,'rom_built':False,'phone_verified':False},ensure_ascii=False,indent=2))
    return int(bool(errors))

if __name__=='__main__': raise SystemExit(main())
