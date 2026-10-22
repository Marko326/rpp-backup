#!/usr/bin/env python3
"""Original-Gold Route35/Goldenrod gate contract; static source checks only.

Checks actual Warp graph and map identity rather than equal row counts.
Does NOT execute GB CPU instructions or certify arrival step timing on a phone.
"""
from pathlib import Path
import json
import re

NEW = 'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID'
SRC = ('JOHTO_ROUTE_35_LOCAL_ID', 'JOHTO_GOLDENROD_CITY_LOCAL_ID', NEW)
GRAPH = (
    ('JohtoRoute35', 33, 9, 0, NEW, 0),
    ('JohtoRoute35', 33, 10, 1, NEW, 1),
    ('JohtoGoldenrodCity', 1, 19, 2, NEW, 0),
    ('JohtoRoute35GoldenrodGate', 0, 4, 0, 'JOHTO_ROUTE_35_LOCAL_ID', 0),
    ('JohtoRoute35GoldenrodGate', 0, 5, 1, 'JOHTO_ROUTE_35_LOCAL_ID', 1),
    ('JohtoRoute35GoldenrodGate', 7, 4, 0, 'JOHTO_GOLDENROD_CITY_LOCAL_ID', 2),
    ('JohtoRoute35GoldenrodGate', 7, 5, 0, 'JOHTO_GOLDENROD_CITY_LOCAL_ID', 3),
)
# Source map, 0-based source warp, 0-based dest warp, source local key, dest local key
LOCALS = {'JohtoRoute35': SRC[0], 'JohtoGoldenrodCity': SRC[1], 'JohtoRoute35GoldenrodGate': SRC[2]}
WARP_LINE = re.compile(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*REGION_WARP_ESCAPE\b')
REGION_LINE = re.compile(r'(?m)^\s*db\s+([\w]+),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s*([\w]+)\b')


def source(root, name, overrides=None):
    if overrides and name in overrides:
        return overrides[name]
    return (root/name).read_text(encoding='utf8')


def gate_graph_errors(root: Path, overrides=None):
    problems=[]
    by_map={}
    for stem in LOCALS:
        raw=source(root,f'data/mapObjects/{stem}.asm',overrides)
        entries=[tuple(map(int,m)) for m in WARP_LINE.findall(raw)]
        by_map[stem]=entries
        count_expected={'JohtoGoldenrodCity':1,'JohtoRoute35':3,'JohtoRoute35GoldenrodGate':4}[stem]
        if len(entries)!=count_expected:
            problems.append(f'{stem} expected {count_expected} native Warp entries; got {len(entries)}')
    actual_routes=set()
    lookup=source(root,'engine/overworld/region_map_lookup.asm',overrides)
    portion=lookup.split('NativeRegionWarpTargets::',1)[-1].split('SelectNativeMapConnection::',1)[0]
    registrations={(a,int(b),int(c),d) for a,b,c,d in REGION_LINE.findall(portion)}
    for stem,y,x,target_slot,dest_local,source_slot in GRAPH:
        entries=by_map[stem]
        try:
            index=next(i for i,(yy,xx,ss) in enumerate(entries) if yy==y and xx==x and ss==target_slot)
        except StopIteration:
            problems.append(f'{stem} missing Gold Warp ({x},{y}) -> dest slot {target_slot}')
            continue
        route=(LOCALS[stem],index,target_slot,dest_local)
        actual_routes.add(route)
        if route not in registrations:
            problems.append(f'{stem} warp slot {index}: native routing missing/wrong {route}')
    # Park doorway is an additive, separately reviewed Route35 Warp #2.
    # Keep the original Goldenrod gate #0/#1 and all seven old routes exact.
    park_new=('JOHTO_ROUTE_35_LOCAL_ID', 2, 2, 'JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID')
    if by_map['JohtoRoute35'][2] != (5,3,2) or park_new not in registrations:
        problems.append('Route35 new park gate must use only Gold Warp #3 at (3,5)')
    legacy_routes={entry for entry in registrations if entry[0] in SRC and entry!=park_new}
    if legacy_routes!=actual_routes:
        problems.append('original seven Goldenrod gate routes changed or duplicated')
    return problems


def gate_gold_geometry_errors(root: Path, gold: Path):
    from johto_indoor_collision_adapter import plan_gold_quadrant_collision
    from johto_indoor_tiles_converter import build_mapping
    problems=[]
    gold_maps={
        'Route35':[(9,33,'ROUTE_35_GOLDENROD_GATE',1),(10,33,'ROUTE_35_GOLDENROD_GATE',2)],
        'GoldenrodCity':[(19,1,'ROUTE_35_GOLDENROD_GATE',3)],
        'Route35GoldenrodGate':[(4,0,'ROUTE_35',1),(5,0,'ROUTE_35',2),
                                  (4,7,'GOLDENROD_CITY',13),(5,7,'GOLDENROD_CITY',13)],
    }
    events=re.compile(r'(?m)^\s*warp_event\s+(\d+),\s*(\d+),\s*([\w]+),\s*(\d+)')
    for stem,required in gold_maps.items():
        entries={(int(x),int(y),dest,int(slot)) for x,y,dest,slot in events.findall((gold/'maps'/f'{stem}.asm').read_text())}
        if not set(required)<=entries:
            problems.append(f'Gold original {stem} changed or source incomplete')
    a,candidate=build_mapping(root,gold,'Route35GoldenrodGate','gate','johto_gate')
    if candidate != (root/'maps/JohtoRoute35GoldenrodGate.blk').read_bytes():
        problems.append('Gold gate compact block layout mismatch')
    _,mask=plan_gold_quadrant_collision(gold,'Route35GoldenrodGate','gate')
    if mask!=(root/'maps/JohtoRoute35GoldenrodGate.blocked_mask.bin').read_bytes():
        problems.append('Gold gate collision role mask mismatch')
    if a['exact_mapped']!=a['used_unique_blocks']:
        problems.append('Gold original gate has an unmapped block')
    return problems


def gate_dispatch_errors(root: Path, overrides=None):
    problems=[]
    collision=source(root,'engine/overworld/johto_route33_collision.asm',overrides)
    home=source(root,'home/overworld.asm',overrides)
    neutral=source(root,'engine/overworld/map_name_sign.asm',overrides)
    tables=source(root,'data/johto_map_headers.asm',overrides)
    constants=source(root,'constants/region_map_constants.asm',overrides)
    if 'DEF '+NEW+' EQU 18' not in constants or not __import__('re').search(r'DEF NUM_JOHTO_MAPS EQU (\d+)', constants) or int(__import__('re').search(r'DEF NUM_JOHTO_MAPS EQU (\d+)', constants)[1]) < 19:
        problems.append('native Goldenrod gate must remain local ID 18 with at least 19 total maps')
    for label in ('JohtoRoute35GoldenrodGate_h', 'BANK(JohtoRoute35GoldenrodGate_h)'):
        if label not in tables:problems.append('native map pointers and banks missing '+label)
    # HOME uses a compact sparse range instead of spelling out each ID.
    # Test the executable carry predicate, including denied neighboring IDs.
    from johto_gatehouse_behavior_audit import predicate
    numbers = {}
    for path in ('constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm'):
        numbers.update({k:int(v) for k,v in re.findall(
            r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\d+)',
            source(root,path,overrides))})
    for local in (NEW,'JOHTO_ROUTE_35_LOCAL_ID','JOHTO_GOLDENROD_CITY_LOCAL_ID'):
        try:
            if not predicate(home,'IsJohtoSouthGatePortal',local,0,0,'LEFT',numbers):
                problems.append('HOME gate dispatch excludes exact local '+local)
        except (ValueError,KeyError) as exc:
            problems.append('HOME gate dispatch interpreter failed: '+str(exc))
    for local in ('JOHTO_ROUTE_37_LOCAL_ID','JOHTO_ROUTE_39_LOCAL_ID'):
        try:
            if predicate(home,'IsJohtoSouthGatePortal',local,0,0,'LEFT',numbers):
                problems.append('HOME gate dispatch leaks to non-gate '+local)
        except (ValueError,KeyError) as exc:
            problems.append('HOME gate dispatch interpreter failed: '+str(exc))
    from johto_rom0_collision_audit import audit as native_collision_audit
    if native_collision_audit(root,overrides):
        problems.append('home warp/movement dispatch omits CheckTilePassable::')
    for label in ('JohtoNorthGateStepWarpAllowed::','JohtoGateCollisionDirectionAllowed::','JohtoRoute34GateCanStepAhead::'):
        section=collision.split(label,1)[1].split('\n\n',1)[0]
        if NEW not in section:problems.append('collision/warp dispatch omits '+label)
    # Branch semantics, not just string presence. A backwards jump must FAIL.
    branch_patterns = (
        ('JohtoNorthGateStepWarpAllowed::', 'JohtoGateCollisionDirectionAllowed::',
         rf'cp {NEW}\s+jr z, \.gateVertical'),
        ('JohtoGateCollisionDirectionAllowed::','JohtoInternalDoorFacingCheck::',
         rf'cp {NEW}\s+(?:jr|jp) z, \.northGate'),
        ('JohtoRoute34GateCanStepAhead::','JohtoRoute34GateBlockedRows::',
         rf'cp {NEW}\s+jp nz, \.blocked'),
    )
    for first,last,expression in branch_patterns:
        section=collision.split(first,1)[1].split(last,1)[0]
        if not re.search(expression,section):
            problems.append('wrong Gold gate dispatch direction/branch at '+first)
    if 'cp '+NEW not in neutral.split('.IsNeutralMap',1)[1].split('.NeutralMapList',1)[0]:
        problems.append('neutral gate name sign missing')
    return problems




def border_refresh_hook_errors(root: Path, overrides=None):
    """Verify both redraw paths call one ROMX dispatcher (no per-map HOME calls).

    The dispatcher lives with its callees in bank $43; this is not a ROM CPU
    execution test, but prevents reverting the exact HOME overflow pattern.
    """
    home = source(root, 'home/overworld.asm', overrides)
    col = source(root, 'engine/overworld/johto_route33_collision.asm', overrides)
    main = source(root, 'main.asm', overrides)
    problems = []
    label = 'PatchJohtoMapBordersAfterBlockLoad'
    hook = 'callba ' + label
    expected = ('\tcall PatchJohtoAzaleaWestGateBorder\n'
                '\tcall PatchJohtoGoldenrodNorthBorder\n'
                '\tcall PatchJohtoMahoganyNorthBorder\n'
                '\tjp PatchJohtoRoute35SouthBorder')
    if home.count(hook) != 2:
        problems.append('ROM0: exactly two shared border dispatcher far-calls required')
    for path_name, piece in (
        ('full', home.split('LoadMapData::',1)[-1].split('LoadCurrentMapView',1)[0]),
        ('connected', home.split('.ordinaryConnection\n',1)[-1].split('.didNotEnterConnectedMap',1)[0]),
    ):
        if (piece.count(hook) != 1 or
            'call LoadTileBlockMap' not in piece or
            piece.index('call LoadTileBlockMap') > piece.find(hook)):
            problems.append('ROM0: '+path_name+' map-block-load must precede one border dispatcher')
    for old in ('PatchJohtoAzaleaWestGateBorder', 'PatchJohtoGoldenrodNorthBorder',
                'PatchJohtoRoute35SouthBorder'):
        if 'callba '+old in home:
            problems.append('ROM0: redundant direct far-call to '+old)
    if col.count(label+'::') != 1 or expected not in col.split(label+'::',1)[-1].split('; GATE-5.62.202:',1)[0]:
        problems.append('ROMX: border dispatcher must call west/north/Mahogany/south in the registered order')
    try:
        sec = main.split('SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]',1)[1].split('SECTION ',1)[0]
    except IndexError:
        sec = ''
    if ('INCLUDE "engine/overworld/johto_route33_collision.asm"' not in sec or
        'INCLUDE "engine/overworld/johto_goldenrod_roof_gfx.asm"' not in sec):
        problems.append('ROMX: border dispatcher and callees must share bank $43')
    return problems


def gate_video_regression_errors(root: Path, gold: Path, overrides=None):
    """Fail-closed at the two mistakes observed in the user's 224 phone video.

    Route35's SOUTH Gold connection provides a *visual* buffer even though
    actual crossing remains through the gate Warp; the OUTSIDE destination
    additionally needs DOWN auto step, exactly as the accepted Forest gate.
    """
    root, gold = Path(root), Path(gold)
    problems = []
    attrs = (gold/'data/maps/attributes.asm').read_text(encoding='utf8')
    if not re.search(r'(?m)^\s*connection south, GoldenrodCity, GOLDENROD_CITY, -5\s*$',attrs):
        problems.append('Gold Route35 SOUTH visual connection (-5) not confirmed')
    lookup = source(root,'engine/overworld/region_map_lookup.asm',overrides)
    try:
        step = lookup.split('GetJohtoWarpArrivalStep::',1)[1].split('GetJohtoCaveMapChangeSFX::',1)[0]
        rows = step.split('.profiles',1)[1]
    except IndexError:
        return problems+['missing gate arrival-step profile table']
    for location in ('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 4',
                     'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 5',
                     'JOHTO_GOLDENROD_CITY_LOCAL_ID, 1, 19'):
        expected = r'(?m)^\s*db REGION_NATIVE_MAP_SLOT, '+re.escape(location)+r', REGION_NATIVE_MAP_SLOT, D_DOWN\s*$'
        if len(re.findall(expected,rows))!=1:
            problems.append('missing/misconfigured DOWN arrival step at '+location)
    if re.search(r'(?m)^\s*db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 7, [45],',rows):
        problems.append('unexpected Gate south y7 simulated-step profile')
    npc = source(root,'engine/overworld/npc_movement.asm',overrides)
    if not re.search(r'PlayerStepOutFromDoor:[\s\S]*?callab GetJohtoWarpArrivalStep[\s\S]*?call StartSimulatingJoypadStates',npc):
        problems.append('destination step profile not consumed by real runtime')

    collision = source(root,'engine/overworld/johto_route33_collision.asm',overrides)
    try:
        part = collision.split('PatchJohtoRoute35SouthBorder::',1)[1].split('; Shared 16x16 Gold block mask',1)[0]
    except IndexError:
        return problems+['missing display-only Route35 south visual border patch']
    for token in ('cp REGION_NATIVE_MAP_SLOT','cp MAP_REGION_JOHTO',
                  'cp JOHTO_ROUTE_35_LOCAL_ID','ld b, JOHTO_ROUTE_35_WIDTH'):
        if token not in part:problems.append('Route35 south patch identity/width guard missing: '+token)
    for row in range(3):
        expected = ('ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE_35_HEIGHT'
                    + (' + '+str(row) if row else '')
                    + ') * (JOHTO_ROUTE_35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER')
        if expected not in part:problems.append(f'bad Route35 south border WRAM offset row {row}')

    # The two RPP tilesets are NOT byte-identical. Exact metatile matches
    # are preferred; $06 pavement and $67 building edge are not representable
    # in the older JOHTO blockset, so their reviewed preview substitutes are
    # neutral ground and a compatible roof. Do NOT use same-number indexing.
    city = (gold/'maps/GoldenrodCity.blk').read_bytes()
    classic = (root/'gfx/blocksets/johto.bst').read_bytes()
    modern = (root/'gfx/blocksets/johto_modern.bst').read_bytes()
    if len(city) != 20*18 or len(classic)%16 or len(modern)%16:
        return problems+['incomplete Gold city layout or RPP metatile data']
    replacements={0x06:0x01,0x67:0x12}
    def old_compatible(id):
        body=modern[id*16:(id+1)*16]
        equal=[i for i in range(len(classic)//16) if classic[i*16:(i+1)*16] == body]
        if equal:return id if id in equal else equal[0]
        if id not in replacements:raise ValueError('new cross-tileset block needs art review: '+hex(id))
        return replacements[id]
    for row in range(3):
        try:
            expected=bytes(old_compatible(k) for k in city[20*row+5:20*row+15])
        except ValueError as exc:
            problems.append(str(exc));continue
        match=re.search(r'(?m)^\s*\.row'+str(row)+r'\s*\n\s*db\s+([^;\n]+)',part)
        if not match:
            problems.append(f'Route35 south preview row {row} missing')
            continue
        try:actual=bytes(int(item.strip().replace('$','0x'),16) for item in match.group(1).split(','))
        except ValueError:actual=b''
        if actual!=expected:
            problems.append(f'Route35 south preview row {row} differs from Gold-derived converted layout')
        if 0x05 in actual:
            problems.append(f'Route35 south preview row {row} contains forest border')
    problems.extend(border_refresh_hook_errors(root, overrides))
    return problems


def gate_carpet_trigger_errors(root: Path, overrides=None):
    """The outdoor Route 35 mat is occupiable, NOT a step-on warp trigger.

    A DOWN press *from* the carpet must hit the blocked doorway and then use
    the existing collision-only Warp handler. The same Gold source audit now
    applies to Route34's y37 carpets and every vertical gate's indoor south
    carpet; only the solid north-facing DOOR stays step-on.
    """
    errors = []
    asm = source(root, 'engine/overworld/johto_route33_collision.asm', overrides)
    home = source(root, 'home/overworld.asm', overrides)
    lookup = source(root, 'engine/overworld/region_map_lookup.asm', overrides)
    try:
        step_on = asm.split('JohtoNorthGateStepWarpAllowed::',1)[1].split('JohtoGateCollisionDirectionAllowed::',1)[0]
        collision = asm.split('JohtoGateCollisionDirectionAllowed::',1)[1].split('JohtoInternalDoorFacingCheck::',1)[0]
        facing = asm.split('JohtoInternalDoorFacingCheck::',1)[1]
        passable = asm.split('JohtoRoute35CanStepAhead::',1)[1].split('JohtoRoute35BlockedRows::',1)[0]
        standing = home.split('CheckWarpsNoCollisionLoop::',1)[1].split('CheckWarpsCollision::',1)[0]
        collided = home.split('CheckWarpsCollision::',1)[1].split('CheckWarpsNoCollisionRetry1::',1)[0]
        extra = home.split('ExtraWarpCheck::',1)[1].split('IsJohtoSouthGatePortal::',1)[0]
        profiles = lookup.split('GetJohtoWarpArrivalStep::',1)[1].split('GetJohtoCaveMapChangeSFX::',1)[0]
    except IndexError:
        return ['missing executable doorway trigger / collision / arrival routine']

    # A presence-only test missed the prior bug. This must verify the outdoor
    # route is not dispatched to the step-on helper, even while the valid gate,
    # city, and Forest north-gate helpers are still recognized.
    # Gold Route35 has two independent entrances: south carpet (9/10,33)
    # collision-only, and north DOOR (3,5) genuine STEP_ON. Verify both the
    # map dispatch target and the narrow coordinates so a blanket step-on
    # branch cannot smuggle the southern carpet into the door executor.
    route35_step_dispatch = re.search(
        r'cp JOHTO_ROUTE_35_LOCAL_ID\s*(?:jp|jr) z, (\.\w+)', step_on)
    route35_park_handler = re.search(
        r'(?s)\.parkRoute35Door\s*\n\s*ld a, \[wXCoord\]\s*cp 3'
        r'\s*(?:jr|jp) nz, \.deny\s*ld a, \[wYCoord\]\s*cp 5'
        r'\s*(?:jr|jp) z, \.up\s*(?:jr|jp) \.deny', step_on)
    if (not route35_step_dispatch or route35_step_dispatch.group(1) != '.parkRoute35Door'
            or not route35_park_handler or step_on.count('cp JOHTO_ROUTE_35_LOCAL_ID') != 1):
        errors.append('Route35 carpet accidentally uses immediate step-on Warp (must be collision-only)')
    if re.search(r'(?m)^\s*cp JOHTO_ROUTE_34_LOCAL_ID\s*$', step_on):
        errors.append('Route34 Gold WARP_CARPET_DOWN still uses immediate step-on Warp')
    for term in ('cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',
                 'cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID'):
        if term not in step_on:
            errors.append('solid north DOOR step-on branch missing: '+term)
    if ('cp JOHTO_ROUTE_34_LOCAL_ID' not in collision or
        '.route34Carpet' not in collision):
        errors.append('Route34 Gold WARP_CARPET_DOWN must be routed through collision-only guard')
    if ('set 2,[hl]' not in standing or
        'call IsJohtoSouthGatePortal' not in standing or
        'callba JohtoNorthGateStepWarpAllowed' not in standing or
        'jp c, WarpFound1' not in standing or
        'jp CheckWarpsNoCollisionRetry2' not in standing):
        errors.append('step-on executor no longer arms carpet without transferring on denial')
    if ('call IsJohtoSouthGatePortal' not in collided or
        'callba JohtoGateCollisionDirectionAllowed' not in collided or
        'jr nc, .retry2' not in collided):
        errors.append('Route35 collision-only Warp guard not in collision path')
    if ('callba JohtoInternalDoorFacingCheck' not in extra or
        'cp JOHTO_ROUTE_35_LOCAL_ID' not in facing):
        errors.append('Route35 collision doorway facing check not dispatched by ExtraWarpCheck')
    # Route35 also has a real north park entrance; scope this check to the old
    # Goldenrod branch so valid UP on the park door cannot mask regressions.
    route35_collision = (collision.split('\n.route35Goldenrod\n', 1)[1]
                         .split('\n.route34Carpet\n', 1)[0]
                         if '\n.route35Goldenrod\n' in collision else '')
    # RGBDS accepts both JR and JP conditional branches. Match the actual
    # coordinate/direction guard rather than pinning the audit to one opcode;
    # the previous JR-only expression rejected the valid JP implementation.
    route35_down_guard = re.search(
        r'(?s)ld a, \[wYCoord\]\s*cp 33\s*(?:jr|jp) nz, \.denied'
        r'\s*ld a, \[wXCoord\]\s*cp 9\s*(?:jr|jp) z, \.down'
        r'\s*cp 10\s*(?:jr|jp) z, \.down\s*(?:jr|jp) \.denied',
        route35_collision)
    if not route35_down_guard or '.up' in route35_collision:
        errors.append('Route35 collision Warp must require y33, x9/10 and DOWN')
    if not re.search(r'(?s)\.route35SouthInterior\s*\n.*?cp 33.*?cp 9.*?cp 10.*?\.route35Down\s*\n.*?cp PLAYER_DIR_DOWN', facing):
        errors.append('Route35 ExtraWarpCheck must require y33, x9/10 and DOWN')
    if (not re.search(r'(?s)\.southGateApproach\s*\n\s*ld a, \[wPlayerDirection\]\s*\n\s*cp PLAYER_DIR_DOWN.*?cp 9.*?cp 10',passable) or
        'cp 32' not in passable or 'cp 33' not in passable or
        '.southGateLaneLeft' not in passable):
        errors.append('Route35 carpet must remain walkable from y32 and sideways along y33')
    # The second DOWN from y33 must collide with y34, otherwise no collision
    # handler runs and entering the gate becomes impossible. Check both lanes.
    mask_key = 'maps/JohtoRoute35.blocked_mask.bin'
    mask = overrides[mask_key] if overrides and mask_key in overrides else (Path(root)/mask_key).read_bytes()
    stride = (20+7)//8
    for x in (9,10):
        if len(mask) != 36*stride or not (mask[34*stride+x//8] & (1 << (x%8))):
            errors.append(f'Route35 y34 x{x} must remain blocked for collision-only gate entry')
    # Arrival movement is a *separate* question, never remove D_DOWN from
    # the indoor target as a shortcut to fixing premature outdoor transfer.
    for item in ('JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN',
                 'JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN'):
        if item not in profiles:
            errors.append('Gate arrival auto-step changed unexpectedly: '+item)
    return errors



def audit(root: Path, gold: Path, overrides=None):
    root,gold=Path(root),Path(gold)
    return (gate_graph_errors(root, overrides) + gate_dispatch_errors(root, overrides)
            + gate_gold_geometry_errors(root,gold) + gate_video_regression_errors(root,gold,overrides)
            + gate_carpet_trigger_errors(root,overrides))


if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--rpp',type=Path,default=Path('.'))
    parser.add_argument('--gold',type=Path,required=True)
    args=parser.parse_args()
    try: errors=audit(args.rpp,args.gold)
    except (ValueError,KeyError,FileNotFoundError) as exc:errors=[str(exc)]
    for error in errors:print('FAIL',error)
    if errors:raise SystemExit(1)
    print('PASS Route35GoldenrodGate Gold 7-Warp graph + map/tileset/identity/dispatch (STATIC ONLY)')
