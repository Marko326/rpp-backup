#!/usr/bin/env python3
"""REF-342 Union Cave Gold warp-trigger semantics audit.

Gold CAVE uses two different warp collision classes here:
- LADDER: immediate transfer on the step that ENTERS the warp tile.
- WARP_CARPET_DOWN: stand on the tile; transfer only on the designated DOWN input.
REF-366 opens the two B1F Ruins carpets through DOWN-only collisions.
"""
from pathlib import Path
import argparse, json, re

EXPECTED = {
    'UnionCave1F': {
        (17, 3): 'WARP_CARPET_DOWN', (17, 31): 'WARP_CARPET_DOWN',
        (5, 19): 'LADDER', (3, 33): 'LADDER',
    },
    'UnionCaveB1F': {
        (3, 3): 'WARP_CARPET_DOWN', (3, 11): 'WARP_CARPET_DOWN',
        (7, 19): 'LADDER', (3, 33): 'LADDER', (17, 31): 'LADDER',
    },
    'UnionCaveB2F': {(5, 3): 'LADDER'},
}
WIDTH = 10


def _section(text, a, b):
    return text.split(a, 1)[1].split(b, 1)[0]


def _gold_roles(gold: Path):
    coll = {}
    for line in (gold/'data/tilesets/cave_collision.asm').read_text().splitlines():
        m = re.search(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})', line)
        if m:
            coll[int(m.group(2), 16)] = [v.strip() for v in m.group(1).split(',')]
    out = {}
    for name, coords in EXPECTED.items():
        blk = (gold/'maps'/f'{name}.blk').read_bytes()
        for x, y in coords:
            bid = blk[(y//2)*WIDTH + (x//2)]
            out[(name, x, y)] = coll[bid][(y % 2)*2 + (x % 2)]
    return out


def check(root: Path, gold: Path|None = None):
    errors=[]; passed=0
    def req(name, ok):
        nonlocal passed
        if ok: passed += 1
        else: errors.append(name)

    runtime=(root/'engine/johto_pilot_runtime.asm').read_text()
    matched=_section(runtime, 'JohtoPilotGateDoorWarpMatched::', '; P6-GATE-001: a colliding warp')
    collision=_section(runtime, 'JohtoPilotGateCollisionExitAllowed::', 'JohtoPilotGateExteriorCollisionAllowed') if 'JohtoPilotGateExteriorCollisionAllowed' in runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1] else runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1]
    # Function order currently places CollisionExitAllowed after Exterior; just bound to EOF-safe labels.
    collision=runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1]

    version_text=(root/'data/game_version.asm').read_text()
    vm=re.search(r'(?m)^\s*db "REF-(\d+)[A-Z]?@"',version_text)
    req('version_ref342_or_later', vm is not None and int(vm.group(1)) >= 342)
    req('matched_dispatches_all_three_floors', all(tok in matched for tok in (
        'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    jr z, .unionCave1FWarpMatched342',
        'cp JOHTO_UNION_CAVE_B1F_LOCAL_ID\n    jr z, .unionCaveB1FWarpMatched342',
        'cp JOHTO_UNION_CAVE_B2F_LOCAL_ID\n    jr z, .unionCaveB2FWarpMatched342')))
    req('ladder_mode_is_immediate', '.unionCaveLadder342\n    ld e, 2' in matched)
    req('directional_mode_only_arms', '.unionCaveDirectional342\n    ld e, 1' in matched)
    req('onef_carpet_x17_classification', '.unionCave1FWarpMatched342' in matched and 'cp 17\n    jr z, .unionCaveDirectional342' in matched)
    req('b1f_ruins_carpet_directional_classification', all(tok in matched for tok in (
        'cp 3\n    jr z, .unionCaveDirectional342',
        'cp 11\n    jr z, .unionCaveDirectional342')))
    req('b2f_ladder_classification', '.unionCaveB2FWarpMatched342\n    ; B2F (5,3) is LADDER.\n.unionCaveLadder342' in matched)
    req('b1f_ruins_down_collision_guard', 'cp JOHTO_UNION_CAVE_B1F_LOCAL_ID\n    jr z, .unionCaveB1FRuinsExit366' in collision and '.unionCaveB1FRuinsExit366' in collision and 'cp PLAYER_DIR_DOWN' in collision)
    req('b2f_collision_denied', 'cp JOHTO_UNION_CAVE_B2F_LOCAL_ID\n    jr z, .unionCaveNoCollisionWarp342' in collision)
    req('standing_ladder_collision_returns_zero', '.unionCaveNoCollisionWarp342' in collision and 'ld e, 0\n    ret\n.unionCaveExit' in collision)
    req('onef_directional_exit_still_down_only', all(tok in collision for tok in (
        '.unionCaveExit', 'cp PLAYER_DIR_DOWN', 'cp 17', 'cp 3', 'cp 31')))

    cave=(root/'data/johto_union_cave_runtime.asm').read_text()
    req('runtime_warp_coords_unchanged', all(tok in cave for tok in (
        'db 19, 5, 2, JOHTO_REGISTERED_WARP_SELECTOR',
        'db 33, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR',
        'db 19, 7, 2, JOHTO_REGISTERED_WARP_SELECTOR',
        'db 33, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR',
        'db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR',
        'db 3, 5, 4, JOHTO_REGISTERED_WARP_SELECTOR')))

    routes=_section(runtime, 'JohtoRegisteredWarpRoutes::', 'JohtoRegisteredWarpRoutesEnd::')
    req('ruins_routes_open_exact_gold_ordinal', all(item in routes for item in ('JOHTO_UNION_CAVE_B1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID', 'JOHTO_UNION_CAVE_B1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_RUINS_OF_ALPH_LOCAL_ID', 'JOHTO_RUINS_OF_ALPH_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID', 'JOHTO_RUINS_OF_ALPH_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID')))

    if gold is not None:
        roles=_gold_roles(gold)
        req('gold_collision_roles_exact', all(roles[(name,x,y)] == expected
             for name, cells in EXPECTED.items() for (x,y), expected in cells.items()))

    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL', 'passed':passed,
            'failed':len(errors), 'errors':errors, 'rom_built':False, 'phone_verified':False}

if __name__ == '__main__':
    ap=argparse.ArgumentParser(); ap.add_argument('--project',type=Path,default=Path('.')); ap.add_argument('--gold-root',type=Path)
    a=ap.parse_args(); r=check(a.project.resolve(), a.gold_root.resolve() if a.gold_root else None)
    print(json.dumps(r,ensure_ascii=False,indent=2)); raise SystemExit(r['status']!='PASS_STATIC_ONLY')
