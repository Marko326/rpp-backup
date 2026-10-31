#!/usr/bin/env python3
"""FIX-288 read-only Park regressions for black borders, carpet exits,
East Gate mature passability and Park LONG_GRASS sprite priority.

Validates executable dispatch paths, not only Gold source blobs. No ROM build.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

NAMES = (
    'JOHTO_NATIONAL_PARK_LOCAL_ID',
    'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID',
    'JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID',
)
OLD_MASK_SHA256 = 'e319c7cb627cb9b3ec933e4c542b5e7043bef28fe733e5aaefab569b56c76d60'

def audit(root: Path, reference_root: Path | None = None, changes: dict | None = None) -> dict:
    root = Path(root)
    changes = changes or {}
    checks, errors = [], []
    def read(rel, binary=False):
        val = changes.get(rel)
        if val is None:
            val = (root / rel).read_bytes() if binary else (root / rel).read_text()
        return (val if isinstance(val, bytes) else val.encode()) if binary else (val.decode() if isinstance(val, bytes) else val)
    def ck(name, flag):
        checks.append({'check': name, 'status': 'PASS' if flag else 'FAIL'})
        if not flag: errors.append(name)
    try:
        pilot = read('engine/johto_pilot_runtime.asm')
        geom = read('engine/johto_south_geometry.asm')
        portal = read('engine/johto_south_portals.asm')
        gateway = read('engine/johto_land_collision_gateway_272.asm')
        world = read('home/overworld.asm')
        move = read('engine/overworld/movement.asm')
        tiles = read('data/tileset_headers.asm')
        objects = read('data/johto_park_runtime_286.asm')
        version = read('data/game_version.asm')
        mask = read('maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin', True)
        source_roles = read('maps/johto_pilot/Route36NationalParkGate.roles.bin', True)
        ck('version_288_and_stable_test', re.search(r'FIX-5\.62\.(?:288|289|290)@',version) is not None and 'TEST-231@' in version)
        # The actual collision dispatcher runs BEFORE legacy tile-pair checks.
        ck('all_three_park_maps_in_gold_land_gateway', all(f'cp {n}' in gateway for n in NAMES) and
           'callab JohtoSouthSpatialStep' in gateway and 'callab JohtoPilotIsClosedOutdoorEdge' in world)
        # Section before first .southClosedEdge branch: reject refs in music etc.
        boundary = pilot.split('JohtoPilotIsClosedOutdoorEdge::', 1)[1].split('\n.southClosedEdge\n',1)[0]
        ck('all_three_park_maps_guarded_before_movement', all(re.search(
           rf'cp {re.escape(n)}\s*\n\s*jp z, \.southClosedEdge',boundary) for n in NAMES) and
           'callab JohtoSouthIsKnownClosedEdge' in pilot and 'jp nz,.collision' in world)
        ck('park_three_map_dimensions_in_closed_edge_checker', all(re.search(
           rf'cp {re.escape(n)}\s*\n\s*jp z, \.(?:park|parkSouthGate|parkEastGate)', geom.split('JohtoSouthIsKnownClosedEdge::',1)[1]) for n in NAMES)
           and all(x in geom for x in ('ld b, 40\n    ld c, 54','ld b, 8\n    ld c, 8','ld b, 10\n    ld c, 8')))
        ck('registered_carpet_collision_and_no_step_teleport',
           all(f'cp {n}' in pilot.split('JohtoPilotGateExteriorCollisionAllowed::',1)[1].split('.legacyExtra',1)[0] for n in NAMES)
           and all(f'cp {n}' in pilot.split('JohtoPilotGateDoorWarpMatched::',1)[1].split('.oldGateRules',1)[0] for n in NAMES)
           and 'callab JohtoSouthPortalCollisionExit' in pilot
           and 'call ExtraWarpCheck' in world
           and 'CheckWarpsCollision::' in world
           and 'cp JOHTO_PARK_GATE' in world)
        # Both doorways must be collision warps on the OUTWARD input only;
        # standing on or walking between carpets is not an immediate warp.
        after=portal.split('JohtoSouthPortalAfterStep::',1)[1].split('JohtoSouthPortalCollisionExit::',1)[0]
        before=portal.split('JohtoSouthPortalBeforeStep::',1)[1]
        ck('park_dual_gate_exact_outward_approaches',
           all(re.search(rf'(?m)^\.parkSouthGate\n(?:(?!\.parkEastGate).)*?{re.escape(x)}',after,re.S) for x in
               ('cp PLAYER_DIR_UP','cp PLAYER_DIR_DOWN','cp 7','cp 3','cp 4'))
           and all(re.search(rf'(?m)^\.parkEastGate\n(?:(?!\.door).)*?{re.escape(x)}',after,re.S) for x in
               ('cp PLAYER_DIR_LEFT','cp PLAYER_DIR_RIGHT','cp 9','cp 4','cp 5'))
           and all(x in before for x in ('cp PLAYER_DIR_LEFT','cp PLAYER_DIR_RIGHT','cp PLAYER_DIR_UP','cp PLAYER_DIR_DOWN'))
           and 'cp 1' in before and 'cp 8' in before
           and 'cp 6' in before
           and 'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID' in before)
        ck('correct_park_gate_warp_layout', all(x in objects for x in (
            'db 0, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 0, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 7, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 5, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 4, 9, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 5, 9, 3, JOHTO_REGISTERED_WARP_SELECTOR')))
        # Cross-check mature collision mask with the exact accepted old branch.
        digest = hashlib.sha256(mask).hexdigest()
        ck('east_gate_mature_mask_exact_16_bytes', len(mask)==16 and digest==OLD_MASK_SHA256)
        if reference_root:
            old = Path(reference_root)/'maps/JohtoRoute36NationalParkGate.blocked_mask.bin'
            ck('east_gate_mask_matches_npc243', old.is_file() and mask==old.read_bytes())
        def blocked(x,y):return bool(mask[y*2+(x//8)] & (1<<(x%8))) if len(mask)==16 else True
        ck('east_gate_mature_corridor_passable', len(mask)==16 and all(not blocked(x,y) for x,y in ((1,5),(2,5),(3,5),(4,6),(3,7),(1,2),(7,3)))
           and all(source_roles[y*10+x]==1 for x,y in ((1,5),(2,5),(3,5))))
        s = geom.split('JohtoSouthSpatialStep::',1)[1].split('JohtoParkEastGateMatureStep::',1)[0]
        m = geom.split('JohtoParkEastGateMatureStep::',1)[1].split('JohtoParkEastGateBlockedRows::',1)[0]
        ck('east_gate_runtime_calls_mature_mask',
           'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID' in s and
           'call JohtoParkEastGateMatureStep' in s and
           'call JohtoSouthSpatialRoleAhead' in s and
           'ld e, 1' in m and 'ld e, 0' in m and
           'cp 10' in m and 'cp 8' in m and
           'cp 4' in m and 'cp 5' in m and
           'and [hl]' in m and 'and a ; zero bit index' in m and
           'INCBIN "maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin"' in geom)
        ck('bike_walk_same_boundary_and_collision',
           'wWalkBikeSurfState' in geom and
           'callab JohtoOverworldSouthLandDecision' in world and
           'callab JohtoPilotIsClosedOutdoorEdge' in world)
        helper=move.split('GetGrassSpritePriority::',1)[1].split('UnusedReadSpriteDataFunction:',1)[0]
        ck('park_grass_four_gold_tiles', all(re.search(rf'cp \${n}',helper,re.I) for n in ('3a','3b','4a','4b')) and
           'cp JOHTO_PARK' in helper and
           'ld a, [wGrassTile]' in helper and
           'ld a, $80' in helper and
           'tileset JohtoPark_Block, JohtoPark_GFX, JohtoPilot_Coll, $FF,$FF,$FF, $04, OUTDOOR' in tiles)
        ck('both_player_and_npc_grass_priority', move.count('call GetGrassSpritePriority') == 2 and
           'ld [wSpriteStateData2 + 7], a' in move and
           'ld [hl], a' in move)
    except (KeyError,ValueError,OSError,IndexError) as exc:
        ck('audit_inputs_complete',False)
        errors.append(str(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,
            'rom_built':False,'device_verified':False}

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--project',type=Path,default=Path.cwd());a.add_argument('--reference-root',type=Path)
    x=a.parse_args();r=audit(x.project,x.reference_root)
    print(json.dumps({'status':r['status'],'checks':len(r['checks']),'errors':r['errors']},ensure_ascii=False,indent=2))
    raise SystemExit(bool(r['errors']))
