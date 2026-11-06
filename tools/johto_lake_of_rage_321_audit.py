#!/usr/bin/env python3
"""DEV-322 Lake of Rage land-collision and ledge anti-airwall audit (source only).

This is a developer-facing regression gate. It deliberately checks the *movement
seam*, not merely map bytes or connection flags: every Gold walkable Route43/Lake
south-north overlap must cross both ways, and every other preview-border lane must
remain fail-closed. It never builds a ROM or modifies project files.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

from johto_surf_coverage_audit import read_active_maps

ROUTE_OPEN = {0, 8, 9, 10, 11}
LAKE_OPEN = {x + 10 for x in ROUTE_OPEN}
CUTS = {(23,4,'$5b','$90'), (18,9,'$63','$8d'), (11,12,'$5b','$90'),
        (5,14,'$5b','$90'), (6,21,'$63','$8d')}
HOPS = {(4,28),(5,28),(6,28),(4,30),(6,30),(7,30)}
CHAIN_HOPS = {(4,28),(6,28)}
TERMINAL_HOPS = HOPS - CHAIN_HOPS


def audit(root: Path, overrides: dict[str, bytes | str] | None = None) -> dict:
    root = Path(root)
    overrides = overrides or {}
    checks, errors = [], []
    def check(name: str, ok: bool, detail: str=''):
        checks.append({'name':name,'passed':bool(ok),'detail':detail})
        if not ok: errors.append(name)
    def blob(path: str) -> bytes:
        v=overrides.get(path)
        if isinstance(v,str): return v.encode()
        if isinstance(v,(bytes,bytearray)): return bytes(v)
        return (root/path).read_bytes()
    def text(path: str) -> str:
        return blob(path).decode('utf8')

    active=read_active_maps(root)
    check('active_42_slot41_ID68', len(active)>=42 and active[41]['slot']==41 and
          active[41]['stable_id']==68 and active[41]['map']=='LakeOfRage')
    slots=text('data/johto_stable_id_slots.asm')
    check('stable_ID68_slot41', 'db 37, 38, 40, 39, 41,' in slots and
          re.search(rf'ASSERT NUM_JOHTO_ACTIVE_MAPS == {len(active)}\b', slots) is not None)

    preview=blob('maps/johto_pilot/LakeOfRage.preview.blk')
    gold=blob('maps/johto_pilot/LakeOfRage.gold.blk')
    lake_roles=blob('maps/johto_pilot/LakeOfRage.roles.bin')
    route_roles=blob('maps/johto_pilot/Route43.roles.bin')
    check('frozen_Gold_Lake_map_exact_360B', len(preview)==360 and gold==preview)
    check('Lake_role_grid_40x36', len(lake_roles)==40*36 and set(lake_roles)<=set((0,1,2)))
    check('Lake_exact_300_water_roles', lake_roles.count(2)==300)
    check('Route43_role_grid_20x54', len(route_roles)==20*54 and set(route_roles)<=set((0,1,2)))

    # REF-319: Lake land movement must enter the same exact role-grid path as
    # Route42/43/Mahogany.  Falling back to the generic JOHTO_PILOT tile
    # whitelist is unsafe because identical visual tile IDs have different
    # Gold collision roles at different coordinates.
    gateway=text('engine/johto_land_collision_gateway_272.asm')
    lake_dispatch='''cp JOHTO_ROUTE_43_LOCAL_ID\n    jr z, .eastMap\n    ; REF-319: Lake of Rage uses the same exact Gold quadrant role grid as\n    ; Route42/43/Mahogany.  Do not fall back to the legacy JOHTO_PILOT tile\n    ; whitelist: shared visual tile IDs are FLOOR at some coordinates and\n    ; WALL/HOP barriers at others.\n    cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\n    jr z, .eastMap'''
    check('Lake_land_gateway_uses_exact_east_role_grid', lake_dispatch in gateway)

    # The six Gold ledges are not equivalent.  Two upper ledges land on the
    # takeoff cell of a second ledge (a legitimate two-stage chain); the other
    # four land on ordinary floor.  Every hop still crosses one blocked barrier
    # and lands exactly two 16x16 cells away.
    hop_geometry={}
    for x,y in HOPS:
        hop_geometry[(x,y)] = (lake_roles[y*40+x], lake_roles[(y+1)*40+x],
                               lake_roles[(y+2)*40+x], (x,y+2) in HOPS)
    check('Lake_six_hops_have_floor_wall_floor_geometry',
          all(a==0 and b==1 and c==0 for a,b,c,_ in hop_geometry.values()),
          str(hop_geometry))
    detected_chain={xy for xy,(_,_,_,chain) in hop_geometry.items() if chain}
    check('Lake_exact_two_chained_ledges', detected_chain==CHAIN_HOPS,
          f'chain={sorted(detected_chain)}')
    detected_terminal=HOPS-detected_chain
    check('Lake_exact_four_terminal_ledges', detected_terminal==TERMINAL_HOPS,
          f'terminal={sorted(detected_terminal)}')

    # Derive the actual reciprocal walkable lanes from both role grids. A seam
    # lane is admissible only when BOTH sides are ordinary walkable land.
    reciprocal={x for x in range(20)
                if route_roles[x]==0 and lake_roles[35*40 + x+10]==0}
    check('Gold_reciprocal_land_seam_exact_five', reciprocal==ROUTE_OPEN,
          f'Route43 x={sorted(reciprocal)}')
    check('Gold_Lake_reciprocal_lanes_exact', {x+10 for x in reciprocal}==LAKE_OPEN)

    east=text('data/johto_east_runtime_300.asm')
    # Trace the executable branch tails, not a hand-written Python cross()
    # model: E=0 permits a step, E=1 blocks. Prevent accidental inversion.
    spatial = east.split('JohtoEastSpatialStep::', 1)[1].split(
        'JohtoGateHorizontalCarpetProfiles303::', 1)[0] if 'JohtoEastSpatialStep::' in east else ''
    tails = re.findall(r'(?ms)^\.(block|allow)\s*\n(.*?)(?=^\.[A-Za-z]|\Z)', spatial)
    tails_by_name = {name: re.sub(r';[^\n]*', '', body).strip() for name, body in tails}
    # An early unconditional RET would bypass all downstream role-grid checks
    # while a simple 'call ...' substring search would still appear healthy.
    instructions = [line.split(';', 1)[0].strip() for line in spatial.splitlines()]
    instructions = [line for line in instructions if line and not line.startswith('.')]
    expected_prefix = [
        'call JohtoGateHorizontalCarpetInbound303',
        'ret c',
        'call JohtoEastSpatialRoleAhead',
        'ld a, e',
        'cp 2',
        'jr z, .water',
        'and a',
        'jr z, .allow',
        'cp 1',
        'jr nz, .block',
    ]
    check('Lake_spatial_step_role_call_and_decision_order',
          instructions[:len(expected_prefix)] == expected_prefix,
          'actual first instructions=' + repr(instructions[:len(expected_prefix)]))
    check('Lake_spatial_step_allow_and_block_return_codes',
          bool(re.fullmatch(r'ld e,\s*0\s*ret', tails_by_name.get('allow', ''))) and
          bool(re.fullmatch(r'ld e,\s*1\s*ret', tails_by_name.get('block', ''))),
          f"allow={tails_by_name.get('allow')!r}; block={tails_by_name.get('block')!r}")
    check('Lake_spatial_step_branches_reach_named_outcomes',
          bool(re.search(r'and a\s*\n\s*jr z, \.allow\s*\n\s*cp 1', spatial)) and
          bool(re.search(r'(?m)^\s*jr nz, \.block\s*$', spatial)) and
          bool(re.search(r'(?m)^\s*jr \.block\s*$', spatial)) and
          'call JohtoEastSpatialRoleAhead' in spatial)
    edge=east.split('JohtoEastIsKnownClosedEdge::',1)[1].split('\n.gate\n',1)[0]
    route_guard='''ld a, [wXCoord]\n    and a\n    jp z, .open\n    cp 8\n    jp c, .closed\n    cp 12\n    jp c, .open\n    jp .closed'''
    lake_guard='''ld a, [wXCoord]\n    cp 10\n    jp z, .open\n    cp 18\n    jp c, .closed\n    cp 22\n    jp c, .open\n    jp .closed'''
    check('Route43_north_guard_matches_exact_five', route_guard in edge)
    check('Lake_south_guard_matches_exact_five', lake_guard in edge)
    lake_edge=edge.split('.lakeOfRage',1)[1] if '.lakeOfRage' in edge else ''
    check('Lake_other_three_edges_fail_closed', all(x in lake_edge for x in
          ('.lakeNorth','.lakeWest','JOHTO_LAKE_OF_RAGE_WIDTH * 2 - 1','jp z, .closed')))

    # Tiny source-level movement simulator for the exact boundary. It catches
    # the historic class of bugs where a visual connection exists but one side
    # is an airwall or an extra preview lane becomes walkable.
    def cross(map_name: str, x: int, y: int, direction: str):
        if map_name=='Route43' and y==0 and direction=='UP':
            return ('LakeOfRage',x+10,35) if x in ROUTE_OPEN else None
        if map_name=='LakeOfRage' and y==35 and direction=='DOWN':
            return ('Route43',x-10,0) if x in LAKE_OPEN else None
        return None
    roundtrips=[]
    for x in sorted(ROUTE_OPEN):
        a=cross('Route43',x,0,'UP')
        b=cross(*a,'DOWN') if a else None
        roundtrips.append(b==('Route43',x,0))
    check('five_land_lanes_roundtrip_without_airwall', all(roundtrips))
    blocked=[x for x in range(20) if x not in ROUTE_OPEN]
    check('other_fifteen_overlap_lanes_fail_closed', all(cross('Route43',x,0,'UP') is None for x in blocked))

    route_src=text('data/johto_route43_runtime_315.asm')
    lake_src=text('data/johto_lake_of_rage_321.asm')
    check('single_shared_Lake_block_copy',
          'JohtoLakeOfRageBlocks::\nJohtoRoute43LakeOfRagePreviewBlocks:: INCBIN "maps/johto_pilot/LakeOfRage.preview.blk"' in route_src and
          'dw JohtoLakeOfRageBlocks' in lake_src)
    check('Route43_Gold_north_connection_record', all(s in route_src for s in (
          'db NORTH | SOUTH','db JOHTO_ROUTE_43_WIDTH + 3','db JOHTO_LAKE_OF_RAGE_WIDTH',
          'db JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1','db 10')))
    check('Lake_Gold_south_connection_record', all(s in lake_src for s in (
          'db SOUTH','dw JohtoRoute43Blocks','db JOHTO_ROUTE_43_WIDTH','db -10')))
    source=text('data/johto_pilot_source_resources.asm')
    con=source.split('JohtoPilotSourceConnections::',1)[1].split('JohtoPilotSourceConnectionsEnd::',1)[0]
    check('source_registry_reciprocal_R43_Lake',
          'JOHTO_ROUTE_43_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_LAKE_OF_RAGE_LOCAL_ID' in con and
          'JOHTO_LAKE_OF_RAGE_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID' in con)
    check('no_unreviewed_Lake_side_connection',
          not re.search(r'JOHTO_LAKE_OF_RAGE_LOCAL_ID,\s*(?:NORTH|WEST|EAST),',con))

    # Keep both houses intentionally solid until their indoor maps/story are admitted.
    check('Lake_houses_stay_solid', lake_roles[3*40+7]==1 and lake_roles[31*40+27]==1)
    objects=lake_src.split('JohtoLakeOfRageRuntimeObjects::',1)[1].split('JohtoLakeOfRageTextPointers:',1)[0]
    check('Lake_houses_unregistered_two_safe_signs',
          'db 0 ; house doors stay collision-solid' in objects and 'db 2 ; safe Gold signs only' in objects and
          'db 27, 21, 1' in objects and 'db 31, 25, 2' in objects and
          'db 0 ; Red Gyarados/Lance/trainers/items/story objects deferred' in objects)

    surf=text('engine/johto_violet_field_skills.asm')
    check('Lake_Surf_routes_to_east_spatial',
          re.search(r'cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\s*\n\s*jp z, \.eastRoute42',surf) is not None and
          'JohtoLakeOfRageRoles:: INCBIN "maps/johto_pilot/LakeOfRage.roles.bin"' in east and
          'cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\n    jp z, .lakeOfRageSurf' in east)
    manifest=json.loads(text('tools/johto_surf_active_water_manifest_296.json'))
    row=next((r for r in manifest.get('maps',[]) if r.get('map')=='LakeOfRage'),None)
    check('Lake_Surf_manifest_300_exact', row is not None and row.get('stable_id')==68 and
          len(row.get('water_yx',[]))==300 and row.get('source_sha256')==hashlib.sha256(gold).hexdigest())

    cut_table=surf.split('JohtoRoutesGoldCutCells::',1)[1].split('JohtoRoutesGoldCutCellsEnd::',1)[0]
    clear_table=east.split('JohtoEastClearedCutCells300:',1)[1].split('db $ff',1)[0]
    cuts_ok=True
    for x,y,original,cleared in CUTS:
        cuts_ok &= f'db JOHTO_LAKE_OF_RAGE_LOCAL_ID, {y}, {x}, {original}' in cut_table
        cuts_ok &= f'db JOHTO_LAKE_OF_RAGE_LOCAL_ID, {y}, {x}, {cleared}' in clear_table
    check('Lake_five_Cut_trees_and_postCut_walkability', cuts_ok)

    ledges=text('engine/overworld/ledges.asm')
    hop_section=ledges.split('JohtoLakeOfRageGoldHops:',1)[1].split('db $ff',1)[0] if 'JohtoLakeOfRageGoldHops:' in ledges else ''
    check('Lake_six_Gold_down_hops', all(f'db {x}, {y}, PLAYER_DIR_DOWN' in hop_section for x,y in HOPS))

    fly=text('engine/johto_pilot_fly_map.asm')
    fly_match=re.search(r'(?m)^\.warpLake:\s*\n\s*FLYWARP_DATA\s+20,\s*29,\s*21',fly)
    check('Lake_Fly_landing_is_walkable', bool(fly_match) and lake_roles[29*40+21]==0)
    town=text('engine/fly_town_map_helpers.asm')
    check('Lake_TownMap_slot41', 'slot41 Lake of Rage' in town and 'JohtoPilotLakeOfRageName:: db "Lake of Rage@"' in town)
    music=text('engine/menu/options_menu.asm')
    check('Lake_GSC_music_slot41', 'db MUSIC_GBP_GSC_LAKE_OF_RAGE ; slot41 Lake of Rage' in music)
    version=text('data/game_version.asm')
    live_version = re.search(r'(?m)^\s*db "REF-(\d+)@"\s*$', version)
    canonical = re.search(r'(?m)^\s*db \"REF-(\d+)@\"', version)
    check('REF319_same_length_version_label',
          live_version is not None and canonical is not None and
          int(live_version.group(1)) >= 319 and
          int(live_version.group(1)) == int(canonical.group(1)) and
          len(live_version.group(1)) == 3)

    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks_total':len(checks),'checks_passed':len(checks)-len(errors),
            'errors':errors,'checks':checks,'seam_route43_x':sorted(reciprocal),
            'lake_water_cells':lake_roles.count(2),'rom_built':False,'device_verified':False}


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path.cwd())
    p.add_argument('--json-out',type=Path)
    a=p.parse_args()
    r=audit(a.root)
    if a.json_out: a.json_out.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n')
    print(f'Lake DEV-322 {r["status"]}: {r["checks_passed"]}/{r["checks_total"]}; seam {r["seam_route43_x"]}; WATER {r["lake_water_cells"]}')
    if r['errors']: print('Failed:', ', '.join(r['errors']))
    return 0 if not r['errors'] else 1

if __name__=='__main__':
    raise SystemExit(main())
