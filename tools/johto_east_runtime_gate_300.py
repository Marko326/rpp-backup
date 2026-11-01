#!/usr/bin/env python3
"""MAP-300 fail-closed static gate for Ecruteak east gate -> Route42 -> Mahogany.

Validates current runtime against original Gold bytes and the mature NPC-5.62.243
stage-77 reference.  Route43/44, Mt Mortar interiors and Mahogany interiors stay
closed. Static only: no ROM build/link or device-play claims.
"""
from __future__ import annotations
import argparse, hashlib, json, re
from pathlib import Path

try:
    from johto_gold_door_audit import GoldCollisionIndex
except ImportError:
    from tools.johto_gold_door_audit import GoldCollisionIndex

try:
    from johto_gatehouse_behavior_audit import _scan_horizontal_gate_moves, _constants
except ImportError:
    from tools.johto_gatehouse_behavior_audit import _scan_horizontal_gate_moves, _constants

MAPS = (
    ("Route42EcruteakGate", "JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID", 62, 5, 4, 0, "JohtoRoute42EcruteakGate"),
    ("Route42", "JOHTO_ROUTE_42_LOCAL_ID", 63, 30, 9, 120, "JohtoRoute42"),
    ("MahoganyTown", "JOHTO_MAHOGANY_TOWN_LOCAL_ID", 64, 10, 9, 0, "JohtoMahoganyTown"),
)
CONNECTIONS = (
    ("JOHTO_ECRUTEAK_CITY_LOCAL_ID", "EAST", "JOHTO_ROUTE_42_LOCAL_ID"),
    ("JOHTO_ROUTE_42_LOCAL_ID", "WEST", "JOHTO_ECRUTEAK_CITY_LOCAL_ID"),
    ("JOHTO_ROUTE_42_LOCAL_ID", "EAST", "JOHTO_MAHOGANY_TOWN_LOCAL_ID"),
    ("JOHTO_MAHOGANY_TOWN_LOCAL_ID", "WEST", "JOHTO_ROUTE_42_LOCAL_ID"),
)
WARP_ROWS = (
    "db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID",
    "db MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID",
)
MAHOGANY_HOPS = {
    (5,4,'DOWN'), (5,4,'LEFT'), (6,4,'DOWN'), (8,4,'DOWN'), (9,4,'DOWN'),
    (14,6,'DOWN'), (15,6,'DOWN'), (2,10,'DOWN'), (3,10,'DOWN'),
    (10,10,'DOWN'), (12,10,'DOWN'), (13,10,'DOWN'),
}


def _roles(blocked: bytes, water: bytes, width: int, height: int) -> bytes:
    row_bytes=(width+7)//8
    if len(blocked)!=row_bytes*height or len(water)!=row_bytes*height:
        raise ValueError(f'mask size mismatch {len(blocked)}/{len(water)} for {width}x{height}')
    out=bytearray()
    for y in range(height):
        for x in range(width):
            i=y*row_bytes+(x>>3); bit=1<<(x&7)
            out.append(2 if water[i]&bit else 1 if blocked[i]&bit else 0)
    return bytes(out)


def _section(text: str, start: str, end: str) -> str:
    return text.split(start,1)[1].split(end,1)[0]


def _asm_db_row(section: str, label: str) -> bytes | None:
    """Read one local-label DB row without accepting a missing/truncated row."""
    match = re.search(
        rf'(?m)^[ \t]*{re.escape(label)}[ \t]*\n[ \t]*db[ \t]+([^\n;]+)',
        section,
    )
    if match is None:
        return None
    values = []
    try:
        for item in match.group(1).split(','):
            token = item.strip()
            if token.startswith('$'):
                value = int(token[1:], 16)
            elif token.lower().startswith('0x'):
                value = int(token, 16)
            else:
                value = int(token, 10)
            if not 0 <= value <= 0xff:
                return None
            values.append(value)
    except ValueError:
        return None
    return bytes(values)


def audit(project: Path, gold_root: Path, reference_root: Path,
          text_overrides: dict[str,str]|None=None,
          byte_overrides: dict[str,bytes]|None=None) -> dict:
    root=Path(project); gold_root=Path(gold_root); ref=Path(reference_root)
    text_overrides=text_overrides or {}; byte_overrides=byte_overrides or {}
    checks=[]; errors=[]
    def ck(name, ok, detail=''):
        checks.append({'check':name,'status':'PASS' if ok else 'FAIL','detail':detail})
        if not ok: errors.append(name + (': '+detail if detail else ''))
    def txt(rel): return text_overrides.get(rel,(root/rel).read_text(encoding='utf8'))
    def raw(rel): return byte_overrides.get(rel,(root/rel).read_bytes())

    try:
        constants=txt('constants/region_map_constants.asm'); fixed=txt('constants/johto_fixed_map_ids.asm')
        version=txt('data/game_version.asm'); slots=txt('data/johto_stable_id_slots.asm')
        source=txt('data/johto_pilot_source_resources.asm'); assets=txt('data/johto_pilot_runtime_assets.asm')
        headers=txt('data/johto_header_descriptors.asm'); east=txt('data/johto_east_runtime_300.asm')
        runtime=txt('engine/johto_pilot_runtime.asm'); surf=txt('engine/johto_violet_field_skills.asm')
        land=txt('engine/johto_land_collision_gateway_272.asm'); ledges=txt('engine/overworld/ledges.asm')
        town=txt('engine/fly_town_map_helpers.asm'); names=txt('engine/overworld/map_name_sign.asm')
        fly=txt('engine/johto_pilot_fly_map.asm'); music=txt('engine/menu/options_menu.asm')
        roof=txt('engine/johto_south_roofs_269.asm'); pal=txt('color/loadpalettes.asm')
        home=txt('home/overworld.asm'); main=txt('main.asm')

        ck('version_302_test233', 'db "FIX-5.62.302@"' in version and 'db "TEST-233@"' in version)
        ck('active_38', re.search(r'(?m)^DEF NUM_JOHTO_ACTIVE_MAPS EQU 38$',constants) is not None)
        ck('bank53_isolated', 'SECTION "Johto East Runtime 300", ROMX, BANK[$53]' in main and
           'INCLUDE "data/johto_east_runtime_300.asm"' in main)
        ck('post_block_border_hook', 'callab PatchJohtoBordersAfterBlockLoad300' in home)
        bike=home.split('IsBikeRidingAllowed::',1)[1].split('\n.legacyBike\n',1)[0]
        bike_ids=('JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID','JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID',
                  'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID','JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
                  'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID','JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID',
                  'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID','JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID')
        ck('bike_gate_allowlist_rom0_size_neutral',
           all(re.search(rf'cp {re.escape(ident)}\s*\n\s*jr z, \.allowed', bike) for ident in bike_ids)
           and 'jp z, .allowed' not in bike,
           'all 8 Johto bike-enabled gates use 2-byte JR; the new East Gate check is offset by shortening the 4 old JP branches')

        # IDs, dimensions, active slots and registrations.
        for index,(name,sym,ident,bw,bh,water_count,mature) in enumerate(MAPS,35):
            allc=fixed+'\n'+constants
            m=re.search(rf'(?m)^DEF {sym} EQU (\$[0-9A-Fa-f]+|\d+)',allc)
            parsed=int(m.group(1)[1:],16) if m and m.group(1).startswith('$') else int(m.group(1)) if m else None
            ck('id_'+name,parsed==ident,f'{parsed} expected {ident}')
            dim=name.upper().replace('ROUTE42ECRUTEAKGATE','ROUTE_42_ECRUTEAK_GATE').replace('ROUTE42','ROUTE_42').replace('MAHOGANYTOWN','MAHOGANY_TOWN')
            ck('dimensions_'+name,
               f'DEF JOHTO_{dim}_WIDTH EQU {bw}' in constants and f'DEF JOHTO_{dim}_HEIGHT EQU {bh}' in constants,
               f'{bw}x{bh} blocks')
            header_label={'Route42EcruteakGate':'JohtoRoute42EcruteakGateRuntimeHeader','Route42':'JohtoRoute42RuntimeHeader','MahoganyTown':'JohtoMahoganyRuntimeHeader'}[name]
            ck('header_'+name, f'dw {header_label}' in headers and f'db BANK({header_label})' in headers)
            ck('runtime_descriptor_'+name, re.search(rf'(?m)^\s*db {sym},',assets) is not None)
            ck('source_descriptor_'+name, re.search(rf'(?m)^\s*db MAP_REGION_JOHTO, {sym},',source) is not None)
        ck('stable_slots_62_64', '35, 36 ; $30-$3f (IDs62/63 gate/Route42)' in slots and
           'db 37, JOHTO_INVALID_ACTIVE_SLOT' in slots)
        ck('future_65_69_inactive', all(x not in assets for x in (
            'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID','JOHTO_ROUTE_43_GATE_LOCAL_ID',
            'JOHTO_ROUTE_43_LOCAL_ID','JOHTO_ROUTE_44_LOCAL_ID')))

        # Asset identity against Gold and exact stage-77 mature reference.
        gold_paths={
            'Route42EcruteakGate':gold_root/'maps/EastWestGate.blk',
            'Route42':gold_root/'maps/Route42.blk',
            'MahoganyTown':gold_root/'maps/MahoganyTown.blk',
        }
        index=GoldCollisionIndex(gold_root)
        for name,sym,ident,bw,bh,water_count,mature in MAPS:
            source_rel=f'maps/johto_pilot/{name}.gold.blk'; runtime_rel=f'maps/johto_pilot/{name}.runtime.blk'
            gold_bytes=gold_paths[name].read_bytes(); ref_map=(ref/'maps'/f'{mature}.blk').read_bytes()
            ck('gold_bytes_'+name,raw(source_rel)==gold_bytes,hashlib.sha256(gold_bytes).hexdigest())
            ck('mature_runtime_'+name,raw(runtime_rel)==ref_map,hashlib.sha256(ref_map).hexdigest())
            blocked=(ref/'maps'/f'{mature}.blocked_mask.bin').read_bytes()
            water_path=ref/'maps'/f'{mature}.water_mask.bin'
            water=water_path.read_bytes() if water_path.exists() else bytes(len(blocked))
            ck('blocked_mask_'+name,raw(f'maps/johto_pilot/{name}.mature_blocked_mask.bin')==blocked)
            if water_count:
                ck('water_mask_'+name,raw(f'maps/johto_pilot/{name}.mature_water_mask.bin')==water)
            expected=_roles(blocked,water,bw*2,bh*2)
            ck('roles_'+name,raw(f'maps/johto_pilot/{name}.roles.bin')==expected)
            cells=index.cells(name)
            gw={(c['y'],c['x']) for c in cells.values() if c['role']=='WATER'}
            ck('gold_water_'+name,len(gw)==water_count,f'{len(gw)} expected {water_count}')
        ck('route42_cut_gold', any(c['x']==24 and c['y']==13 and c['role']=='CUT_TREE' and c['block_id']==0x63
                                  for c in index.cells('Route42').values()))

        # Live horizontal carpet contract.  Warp-table presence alone is not
        # sufficient: the public collision guards must route Ecruteak's east
        # carpet and the Route42 gate pair to the east portal implementation.
        before=_section(east,'JohtoEastPortalBeforeStep::','JohtoEastPortalAfterStep::')
        exitsec=_section(east,'JohtoEastPortalCollisionExit::','JohtoEastIsKnownClosedEdge::')
        ck('east_portal_before_exact', all(x in before for x in (
            'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID','cp PLAYER_DIR_RIGHT','cp 34','cp 26','cp 27',
            'cp JOHTO_ROUTE_42_LOCAL_ID','cp PLAYER_DIR_LEFT','cp 1','cp 8','cp 9',
            'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID')))
        ck('east_gate_right_carpet_before_exact',
           'cp PLAYER_DIR_RIGHT\n    ret nz\n    ld a, [wXCoord]\n    cp 8\n    jr z, .yes' in before)
        ck('east_portal_exit_exact', all(x in exitsec for x in (
            'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID','cp 35','cp 26','cp 27','cp PLAYER_DIR_RIGHT',
            'cp JOHTO_ROUTE_42_LOCAL_ID','cp PLAYER_DIR_LEFT',
            'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID','cp 9')))
        approach=_section(runtime,'JohtoPilotGateDoorApproachAllowed::','JohtoPilotGateDoorWarpMatched::')
        exterior=_section(runtime,'JohtoPilotGateExteriorCollisionAllowed::','JohtoPilotGateCollisionExitAllowed::')
        collision=_section(runtime,'JohtoPilotGateCollisionExitAllowed::','.legacyGuard')
        for label,sec,callee in ((
            'approach',approach,'JohtoEastPortalBeforeStep'),
            ('exterior',exterior,'JohtoEastPortalCollisionExit'),
            ('collision',collision,'JohtoEastPortalCollisionExit')):
            ck('public_east_portal_dispatch_'+label,
               'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jr z, .bothPortalDispatch' in sec and
               'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\n    jr z, .eastPortalDispatch' in sec and
               'cp JOHTO_ROUTE_42_LOCAL_ID\n    jr z, .eastPortalDispatch' in sec and
               ('callab '+callee) in sec)

        # Gate warps and route topology.
        for row in WARP_ROWS: ck('warp_'+str(WARP_ROWS.index(row)),row in runtime,row)
        for a,d,b in CONNECTIONS:
            row=f'db MAP_REGION_JOHTO, {a}, {d}, MAP_REGION_JOHTO, {b}'
            ck(f'connection_{a}_{d}_{b}',row in source,row)
        ck('source_connection_count_40','JOHTO_PILOT_SOURCE_CONNECTION_COUNT EQU 40' in source)
        gate_obj=_section(east,'JohtoRoute42EcruteakGateRuntimeObjects::','JohtoRoute42RuntimeObjects::')
        ck('gate_four_warps','db 4' in gate_obj and all(x in gate_obj for x in ('db 4, 0, 2, JOHTO_REGISTERED_WARP_SELECTOR','db 5, 0, 3, JOHTO_REGISTERED_WARP_SELECTOR','db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR','db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR')))
        route_obj=_section(east,'JohtoRoute42RuntimeObjects::','JohtoMahoganyRuntimeObjects::')
        ck('route42_only_gate_warps','db 2 ; west gate only; all three Mt Mortar cave entries stay sealed' in route_obj)
        mah_obj=_section(east,'JohtoMahoganyRuntimeObjects::','JohtoRoute42EcruteakGateTextPointers:')
        ck('mahogany_no_warps','db 0 ; Mart/house/Gym/Center/Route43 gate all intentionally closed' in mah_obj)

        # Two exact Route42/Mahogany corridors, with y8 closed.
        edge=_section(east,'JohtoEastIsKnownClosedEdge::','JohtoEastGoldWaterProbe::')
        seam_exact=''' .seamY
    cp 4
    jr c, .closed
    cp 8
    jr c, .open
    cp 9
    jr c, .closed
    cp 18
    jr c, .open
    jr .closed'''.lstrip()
        ck('seam_exact_two_corridors_y4_7_y9_17', seam_exact in edge)
        ck('route42_west_gate_only','jr z, .closed ; gate Warp only' in edge)
        ck('mahogany_route44_closed','jr nc, .closed ; Route44 deferred' in edge)
        ck('mahogany_route43_closed','jr z, .closed ; Route43 deferred' in edge)

        # Runtime movement, Surf, Cut and HOPs.
        ck('land_dispatch', all(x in land for x in ('JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID','JOHTO_ROUTE_42_LOCAL_ID','JOHTO_MAHOGANY_TOWN_LOCAL_ID','callab JohtoEastSpatialStep')))
        # FIX-302: inspect actual helper instructions for *inbound* movement,
        # including both plain-floor approaches, lateral entry and lane switch.
        east_step = east.split('JohtoEastSpatialStep::',1)[1].split('JohtoEastGateCarpetLaneStep300::',1)[0]
        lane_helper = _section(east,'JohtoEastGateCarpetLaneStep300::','JohtoRoute42CutClearedAhead300:')
        gate_roles = raw('maps/johto_pilot/Route42EcruteakGate.roles.bin')
        lane_call = ('call JohtoEastGateCarpetLaneStep300' in east_step and
                     'ret c' in east_step and
                     east_step.index('call JohtoEastGateCarpetLaneStep300') < east_step.index('call JohtoEastSpatialRoleAhead'))
        try:
            lane_count, lane_errors = _scan_horizontal_gate_moves(
                lane_helper, stable_id=62, roles=gate_roles,
                constants=_constants(root), western=False)
        except (ValueError, IndexError, KeyError) as exc:
            lane_count, lane_errors = 0, [str(exc)]
        lane_mask = len(gate_roles)==80 and all(gate_roles[y*10+x]==1 for x in (0,9) for y in (4,5))
        ck('east_gate_full_inbound_carpet_movement_required',
           lane_call and lane_mask and lane_count >= 150 and not lane_errors,
           f'call-before-mask={lane_call}, blocked-carpet-mask={lane_mask}, checked={lane_count}, errors={lane_errors[:5]}')
        ck('surf_dispatch', all(x in surf for x in ('cp JOHTO_ROUTE_42_LOCAL_ID','jp z, .eastRoute42','callab JohtoEastGoldWaterProbe','callab JohtoEastUnsafeSurfEdge','callab JohtoEastGoldShoreProbe')))
        ck('surf_initiation','callab JohtoEastGoldWaterProbe\n    ret c' in surf)
        ck('cut_dispatch','db JOHTO_ROUTE_42_LOCAL_ID, 13, 24, $63' in surf and 'JohtoRoute42CutClearedAhead300' in east and 'cp $8d' in east.lower())
        hops_section=_section(ledges,'JohtoMahoganyGoldHops:','JohtoAlphSouthHops:')
        actual={(int(x),int(y),d) for x,y,d in re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*PLAYER_DIR_(DOWN|LEFT|RIGHT)',hops_section)}
        ck('mahogany_12_safe_hops',actual==MAHOGANY_HOPS,f'{sorted(actual)}')

        # Name/Town Map/Fly/music/roof and display-only north preview.
        ck('town_map_entries', all(x in town for x in ('slot35 Route42 east gate inherits Route42 landmark 32','slot36 Route42','slot37 Mahogany Town landmark 34','JohtoPilotRoute42Name:: db "Route 42@"','JohtoPilotMahoganyName:: db "Mahogany Town@"')))
        ck('map_names',all(x in names for x in ('cp JOHTO_ROUTE_42_LOCAL_ID','cp JOHTO_MAHOGANY_TOWN_LOCAL_ID','.JohtoRoute42Name: db "Route 42@"','.JohtoMahoganyName: db "Mahogany Town@"','cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID')))
        ck('mahogany_fly', 'db JOHTO_MAHOGANY_TOWN_LOCAL_ID, EVENT_JOHTO_FLY_MAHOGANY' in fly and 'FLYWARP_DATA 10, 14, 15' in fly)
        ck('music_route42_gate', 'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\n    jp z, .route42GateMusic' in music and 'cp JOHTO_ROUTE_42_LOCAL_ID' in _section(music,'.route42GateMusic','.route35GoldenrodGate'))
        ck('music_slots', all(x in music for x in ('slot35 Route42 Ecruteak Gate','slot36 Route42, original Gold music','slot37 Mahogany Town, original Gold music')))
        ck('roof_art', all(x in roof for x in ('cp JOHTO_ROUTE_42_LOCAL_ID','cp JOHTO_MAHOGANY_TOWN_LOCAL_ID','jp z,.azalea')))
        ck('roof_palette', all(x in pal for x in ('JohtoRoute42RoofPalette300:','RGB 12,19,00','RGB 06,10,00')))
        preview=_section(east,'PatchJohtoMahoganyNorthBorder300::','PatchJohtoBordersAfterBlockLoad300::')
        route43_gold=(gold_root/'maps/Route43.blk').read_bytes()
        route43_mature=(ref/'maps/JohtoRoute43.blk').read_bytes()
        ref_constants=(ref/'constants/region_map_constants.asm').read_text(encoding='utf8')
        route43_width_match=re.search(r'(?m)^DEF JOHTO_ROUTE_43_WIDTH EQU (\d+)$',ref_constants)
        route43_height_match=re.search(r'(?m)^DEF JOHTO_ROUTE_43_HEIGHT EQU (\d+)$',ref_constants)
        route43_width=int(route43_width_match.group(1)) if route43_width_match else 0
        route43_height=int(route43_height_match.group(1)) if route43_height_match else 0
        ck('route43_gold_mature_source_identity',
           len(route43_gold)==270 and route43_gold==route43_mature,
           f'Gold bytes={len(route43_gold)}, mature bytes={len(route43_mature)}')
        ck('route43_mature_preview_geometry',
           route43_width==10 and route43_height==27 and
           len(route43_mature)==route43_width*route43_height,
           f'{route43_width}x{route43_height}, {len(route43_mature)} bytes')
        expected_preview_rows=tuple(
            route43_mature[(route43_height-3+i)*route43_width:(route43_height-2+i)*route43_width]
            for i in range(3)
        ) if route43_width and route43_height>=3 else ()
        actual_preview_rows=tuple(_asm_db_row(preview,f'.row{i}') for i in range(3))
        ck('mahogany_preview_matches_gold_route43_bottom_rows',
           len(expected_preview_rows)==3 and actual_preview_rows==expected_preview_rows,
           'three display-only rows must equal the final three 10-block rows of the Gold/mature Route43 source')
        source_order=re.findall(r'(?m)^\s*ld de, \.(row[0-2])\s*$',preview)
        ck('mahogany_preview_row_source_order',source_order==['row0','row1','row2'],str(source_order))
        ck('mahogany_preview_copy_width_and_wram_rows',
           re.search(r'(?m)^\s*ld b, JOHTO_MAHOGANY_TOWN_WIDTH\s*$',preview) is not None and
           'ld hl, wOverworldMap + MAP_BORDER' in preview and
           'ld hl, wOverworldMap + (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER' in preview and
           'ld hl, wOverworldMap + 2 * (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER' in preview,
           'copy exactly 10 blocks into the three top padded rows; do not touch the playable map')

    except (OSError,ValueError,KeyError,IndexError,TypeError,AttributeError) as exc:
        ck('read_parse',False,str(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','errors':errors,'checks':checks,
            'rom_built':False,'device_verified':False}


def fault_tests(root,gold,ref):
    base=(Path(root)/'data/johto_east_runtime_300.asm').read_text()
    runtime=(Path(root)/'engine/johto_pilot_runtime.asm').read_text()
    role=(Path(root)/'maps/johto_pilot/Route42.roles.bin').read_bytes()
    faults={}
    bad=base.replace('    cp 9\n    jr c, .closed\n','',1)
    faults['seam_y8_open_rejected']=audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad})['status']=='FAIL'
    b=bytearray(role); b[0]^=1
    faults['role_grid_drift_rejected']=audit(root,gold,ref,byte_overrides={'maps/johto_pilot/Route42.roles.bin':bytes(b)})['status']=='FAIL'
    badrt=runtime.replace(WARP_ROWS[-1]+'\n','',1)
    faults['missing_reciprocal_gate_warp_rejected']=audit(root,gold,ref,{'engine/johto_pilot_runtime.asm':badrt})['status']=='FAIL'
    bike_path=root/'home/overworld.asm'; bike=bike_path.read_text(encoding='utf8')
    bike_bad=bike.replace('cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\n    jr z, .allowed',
                          'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\n    jr nz, .allowed',1)
    faults['east_gate_bike_allowance_required']=bike_bad!=bike and audit(root,gold,ref,{'home/overworld.asm':bike_bad})['status']=='FAIL'
    bad_portal=base.replace('    cp 35\n    ret nz\n    ld a, [wYCoord]\n    cp 26',
                            '    cp 34\n    ret nz\n    ld a, [wYCoord]\n    cp 26',1)
    faults['ecruteak_east_collision_exit_required']=bad_portal!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_portal})['status']=='FAIL'
    bad_dispatch=runtime.replace('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jr z, .bothPortalDispatch',
                                 'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jr z, .westPortalDispatch',1)
    faults['ecruteak_both_portals_dispatch_required']=bad_dispatch!=runtime and audit(root,gold,ref,{'engine/johto_pilot_runtime.asm':bad_dispatch})['status']=='FAIL'
    bad_gate=base.replace('    cp 8\n    jr z, .yes\n    ret\n.gateBeforeLeft',
                          '    cp 7\n    jr z, .yes\n    ret\n.gateBeforeLeft',1)
    faults['east_gate_right_carpet_approach_required']=bad_gate!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_gate})['status']=='FAIL'
    bad_lane=base.replace('    call JohtoEastGateCarpetLaneStep300\n    ret c\n', '', 1)
    faults['east_gate_inbound_carpet_helper_required']=bad_lane!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_lane})['status']=='FAIL'
    lane_start='JohtoEastGateCarpetLaneStep300::'
    before_lane,lane_tail=base.split(lane_start,1)
    lane_body,after_lane=lane_tail.split('JohtoRoute42CutClearedAhead300:',1)
    bad_lane_direction=lane_body.replace('cp PLAYER_DIR_DOWN', 'cp PLAYER_DIR_LEFT', 1)
    bad_lane_source=before_lane+lane_start+bad_lane_direction+'JohtoRoute42CutClearedAhead300:'+after_lane
    faults['east_gate_vertical_entry_direction_required']=bad_lane_source!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_lane_source})['status']=='FAIL'
    bad_upper_entry=lane_body.replace('    cp 3\n    jr z, .vertical', '    cp 2\n    jr z, .vertical', 1)
    bad_upper_src=before_lane+lane_start+bad_upper_entry+'JohtoRoute42CutClearedAhead300:'+after_lane
    faults['east_gate_upper_floor_entry_required']=bad_upper_src!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_upper_src})['status']=='FAIL'
    bad_lower_entry=lane_body.replace('    cp 6\n    jr z, .vertical', '    cp 7\n    jr z, .vertical', 1)
    bad_lower_src=before_lane+lane_start+bad_lower_entry+'JohtoRoute42CutClearedAhead300:'+after_lane
    faults['east_gate_lower_floor_entry_required']=bad_lower_src!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_lower_src})['status']=='FAIL'
    bad_preview=base.replace('db $71, $71, $71, $69, $01, $78, $05, $05, $6a, $71',
                             'db $70, $71, $71, $69, $01, $78, $05, $05, $6a, $71',1)
    faults['mahogany_preview_gold_byte_drift_rejected']=bad_preview!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_preview})['status']=='FAIL'
    bad_preview_order=base.replace('    ld de, .row0\n    ld hl, wOverworldMap + MAP_BORDER',
                                   '    ld de, .row1\n    ld hl, wOverworldMap + MAP_BORDER',1)
    faults['mahogany_preview_wrong_source_row_rejected']=bad_preview_order!=base and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_preview_order})['status']=='FAIL'
    preview_start='PatchJohtoMahoganyNorthBorder300::'
    preview_end='PatchJohtoBordersAfterBlockLoad300::'
    before_preview,preview_tail=base.split(preview_start,1)
    preview_body,after_preview=preview_tail.split(preview_end,1)
    bad_preview_body=preview_body.replace('    ld b, JOHTO_MAHOGANY_TOWN_WIDTH',
                                          '    ld b, JOHTO_MAHOGANY_TOWN_WIDTH - 1',1)
    bad_preview_width=before_preview+preview_start+bad_preview_body+preview_end+after_preview
    faults['mahogany_preview_wrong_copy_width_rejected']=bad_preview_body!=preview_body and audit(root,gold,ref,{'data/johto_east_runtime_300.asm':bad_preview_width})['status']=='FAIL'
    return faults


def main():
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('--project',type=Path,default=Path.cwd()); p.add_argument('--gold-root',type=Path,required=True); p.add_argument('--reference-root',type=Path,required=True); p.add_argument('--json-out',type=Path)
    a=p.parse_args(); r=audit(a.project,a.gold_root,a.reference_root); ft=fault_tests(a.project,a.gold_root,a.reference_root); r['negative_fault_tests']=ft
    if not all(ft.values()): r['status']='FAIL'; r['errors'].append('negative fault injection did not fail closed')
    if a.json_out: a.json_out.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'status':r['status'],'checks':len(r['checks']),'failed':len(r['errors']),'faults':ft},ensure_ascii=False,indent=2))
    return 0 if r['status']=='PASS_STATIC_ONLY' else 1
if __name__=='__main__': raise SystemExit(main())
