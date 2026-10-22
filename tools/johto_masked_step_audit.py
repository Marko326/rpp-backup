#!/usr/bin/env python3
"""Execute supported RPP masked-step caller branches against real Gold portals.

Not an emulator: runs the actual caller's supported ASM operations to the
existing mask lookup, then models the shared mask's spatial bit test. Unknown
opcodes/symbols/call targets fail closed. Only maps with an active Warp and a
matching native masked-step caller are eligible; other maps remain NOT_TESTED.
"""
from __future__ import annotations
import json
from pathlib import Path
import re

from johto_indoor_common import ConversionError, rpp_warps
from johto_indoor_collision_adapter import plan_gold_quadrant_collision, ROLE_SEMANTICS
from johto_rpp_asset_audit import tileset_key, layout_inventory
from johto_gold_cells import decode_cells

DIRECTIONS = {'UP': (0,-1), 'DOWN': (0,1), 'LEFT': (-1,0), 'RIGHT': (1,0)}


def parse_caller(source: str, symbol: str):
    match = re.search(r'^'+re.escape(symbol)+r'::\s*$', source, re.M)
    if not match:
        raise ConversionError(f'Cannot find ASM caller {symbol}')
    remaining = source[match.end():]
    next_global = re.search(r'(?m)^[A-Za-z]\w*::\s*$', remaining)
    if next_global:
        remaining = remaining[:next_global.start()]
    program, labels = [], {}
    for raw in remaining.splitlines():
        line = raw.split(';',1)[0].strip()
        if not line:
            continue
        if re.fullmatch(r'\.[A-Za-z]\w*:?', line):
            labels[line.rstrip(':')] = len(program)
        elif re.fullmatch(r'[A-Za-z]\w*:', line):
            break
        else:
            program.append(line)
    if not program or not labels:
        raise ConversionError(f'ASM caller has no instructions/local branches: {symbol}')
    return program, labels


def compare_literal(expr: str, width: int, local_symbol: str, height: int):
    expr = expr.strip()
    if expr == 'REGION_NATIVE_MAP_SLOT' or expr == 'MAP_REGION_JOHTO' or expr == local_symbol:
        return expr
    # Adjacent gate callers compare two valid native-map symbols before the mask.
    # Keep their actual identities distinct, not cast to a generic truthy value.
    if re.fullmatch(r'JOHTO_[A-Z0-9_]+_LOCAL_ID', expr):
        return expr
    if expr.startswith('PLAYER_DIR_') and expr[11:] in DIRECTIONS:
        return expr
    if re.fullmatch(r'\d+', expr):
        return int(expr)
    if re.fullmatch(r'JOHTO_[A-Z0-9_]+_WIDTH\s*\*\s*2\s*-\s*1', expr):
        return width-1
    if re.fullmatch(r'JOHTO_[A-Z0-9_]+_WIDTH\s*\*\s*2', expr):
        return width
    if re.fullmatch(r'JOHTO_[A-Z0-9_]+_HEIGHT\s*\*\s*2\s*-\s*1', expr):
        return height - 1
    raise ConversionError(f'Unsupported ASM compare/operand: {expr}')


def trace_masked_step(program, labels, mask: bytes, width: int, height: int,
                      local_symbol: str, x: int, y: int, direction: str, gold_cut_cells=None):
    registers = {'wCurMap': 'REGION_NATIVE_MAP_SLOT',
                 'wCurRegion': 'MAP_REGION_JOHTO',
                 'wCurLocalMapID': local_symbol,
                 'wXCoord': x, 'wYCoord': y,
                 'wPlayerDirection': 'PLAYER_DIR_'+direction}
    a, zero, carry, pc = 0, False, False, 0
    for tick in range(160):
        if not (0 <= pc < len(program)):
            raise ConversionError('ASM fell outside a caller without ret')
        op = program[pc].strip()
        pc += 1
        loaded = re.fullmatch(r'ld\s+a\s*,\s*\[(w\w+)\]', op)
        if loaded:
            key = loaded[1]
            if key not in registers:
                raise ConversionError('Unknown ASM source register: '+key)
            a = registers[key]
            continue
        if op.startswith('ld '):
            if re.fullmatch(r'ld\s+(hl|d|e)\s*,\s*[\w*+\- ]+', op):
                continue  # register preparation; compare the actual mask below
            raise ConversionError('Unsupported ASM load: '+op)
        m = re.fullmatch(r'cp\s+(.+)', op)
        if m:
            val = compare_literal(m[1],width,local_symbol,height)
            if isinstance(a,int) != isinstance(val,int):
                raise ConversionError('Symbol-vs-number ASM compare: '+op)
            zero = (a == val)
            carry = (a < val)
            continue
        if op == 'and a':
            carry = False
            zero = a == 0
            continue
        if op == 'scf':
            carry = True
            continue
        if op == 'call JohtoIlexForestCutTreeCleared':
            # The real helper consults a mutable live block at Forest (8,25).
            # It can only return carry for a player directly facing that tree.
            # Portals elsewhere cannot hit it; do not invent a RAM state for
            # the dynamic Cut target, or silently allow arbitrary calls.
            dx,dy=DIRECTIONS[direction]
            if local_symbol != 'JOHTO_ILEX_FOREST_LOCAL_ID':
                raise ConversionError('Cut helper called outside its forest scope')
            if (x+dx,y+dy)==(8,25):
                raise ConversionError('Dynamic live Cut block requires runtime state')
            carry = False
            continue
        if op == 'call JohtoRoute42CutTreeCleared':
            # Exact Gold Cut-target scope, not a blanket emulator stub.
            if local_symbol != 'JOHTO_ROUTE_42_LOCAL_ID':
                raise ConversionError('Route42 Cut helper outside Route42 scope')
            dx,dy=DIRECTIONS[direction]
            if (x+dx,y+dy)==(24,13):
                raise ConversionError('Dynamic live Cut block requires runtime state')
            carry = False
            continue
        if op == 'call JohtoRoute43LakeCutTreeCleared':
            # Use the *current Gold source* rather than a special-case map
            # list. The live Cut change can only affect authentic Gold Cut
            # quadrants, so refuse to speculate on mutable RAM at those cells.
            if gold_cut_cells is None:
                raise ConversionError('Gold Cut cells required to trace shared Cut helper')
            dx,dy=DIRECTIONS[direction]
            if (x+dx,y+dy) in gold_cut_cells:
                raise ConversionError('Dynamic live Gold Cut block requires runtime state')
            carry=False
            continue
        m = re.fullmatch(r'(jr|jp)\s+(?:(z|nz|c|nc)\s*,\s*)?([.\w]+)', op)
        if m:
            _, cond, dest = m.groups()
            branch = (cond is None or (cond=='z' and zero) or
                      (cond=='nz' and not zero) or (cond=='c' and carry) or
                      (cond=='nc' and not carry))
            if not branch:
                continue
            if dest == 'JohtoModernMaskedStep':
                dx,dy=DIRECTIONS[direction]
                tx,ty=x+dx,y+dy
                if not (0 <= tx < width and 0 <= ty < height):
                    return True, 'shared-mask-boundary'
                stride=(width+7)//8
                if len(mask)!=height*stride:
                    raise ConversionError('Runtime mask size is inconsistent')
                blocked=bool(mask[ty*stride+tx//8] & (1 << (tx%8)))
                return blocked, 'shared-mask'
            if dest not in labels:
                raise ConversionError('Unknown ASM jump target: '+dest)
            pc=labels[dest]
            continue
        if op=='ret':
            return carry, 'caller-ret'
        raise ConversionError('Unsupported ASM operation: '+op)
    raise ConversionError('ASM caller loop exceeds static trace budget')


def gate_mat_path_errors(rpp: Path, manifest: dict, overrides: dict | None = None) -> list[str]:
    """Strict two-lane EAST/WEST gate carpet movement and collision checks.

    Read each registered native gate's ACTUAL caller and blocked mask. Gold's
    WARP_CARPET role must not be interpreted as a wall in the vertical lane,
    but only an outward-facing collision is allowed to trigger a Warp. This
    deliberately does not generalize to NORTH/SOUTH STEP_ON gates.
    """
    root = Path(rpp)
    errors = []
    sources = {p.name:p.read_text() for p in (root/'engine/overworld').glob('johto_*collision.asm')}
    native = json.loads((root/'tools/johto_native_maps.json').read_text())['maps']
    by_id = {row['local_symbol']:row['header'].removesuffix('_h') for row in native}
    constants = {}
    for source in ('constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm'):
        constants.update({name:int(value) for name,value in re.findall(
            r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+)\s+EQU\s+(\d+)',
            (root/source).read_text())})
    for entry in manifest['active_warp_maps']:
        if entry.get('family') != 'GATE_INDOOR' or entry.get('arrival_step_review',{}).get('layout') != 'EAST_WEST_PAIR':
            continue
        contract = entry.get('gatehouse_runtime',{})
        if contract.get('mode') == 'LEGACY_COLLISION':
            continue  # the accepted Route31 gate uses the separate old-engine executor
        if contract.get('mode') != 'NATIVE_GATE':
            errors.append(entry['rpp_map']+' has unrecognized east/west runtime')
            continue
        approaches = contract['approaches']
        groups = {}
        for row in approaches:
            key = (row['map_local'], int(row['x']))
            groups.setdefault(key,[]).append(row)
        for (local,x), rows in groups.items():
            name = by_id.get(local)
            if not name:
                errors.append(entry['rpp_map']+' unregistered gate carpet map '+local)
                continue
            mask_file = 'maps/'+name+'.blocked_mask.bin'
            if not (root/mask_file).is_file():
                # Accepted native Ilex-Azalea indoor gate uses generic engine
                # rather than a JohtoModernMaskedStep special caller.
                if name == 'JohtoIlexAzaleaGate':
                    continue
                errors.append('no real runtime carpet mask for '+name)
                continue
            symbol = ('JohtoAzaleaCanStepAhead' if name == 'JohtoAzaleaTown'
                      else name+'CanStepAhead')
            matching = [(path,text) for path,text in sources.items()
                        if re.search(r'(?m)^'+re.escape(symbol)+r'::',text)]
            if len(matching) != 1:
                errors.append('missing unique executable masked-step caller '+symbol)
                continue
            srcpath, source = matching[0]
            source = (overrides or {}).get('engine/overworld/'+srcpath, source)
            if not re.search(r'(?m)^'+re.escape(symbol)+r'::',source):
                errors.append('masked-step caller disappeared '+symbol)
                continue
            if mask_file not in source:
                errors.append(symbol+' no longer references expected mask file')
                continue
            header = (root/('data/mapHeaders/'+name+'.asm')).read_text()
            dim = re.search(r'(?m)^\s*db\s+(JOHTO_[A-Z0-9_]+|\d+)\s*,\s*(JOHTO_[A-Z0-9_]+|\d+)\s*$',header)
            if not dim:
                errors.append('missing map dimensions '+name)
                continue
            def dimension(v):return int(v) if v.isdecimal() else constants[v]
            height,width = dimension(dim[1])*2,dimension(dim[2])*2
            mask=(overrides or {}).get(mask_file, (root/mask_file).read_bytes())
            if len(mask) != height*((width+7)//8):
                errors.append('invalid gate mask dimensions '+name)
                continue
            try:
                program,labels=parse_caller(source,symbol)
            except ConversionError as exc:
                errors.append(name+' cannot decode real masked-step caller '+str(exc))
                continue
            rows=sorted(rows,key=lambda v:int(v['y']))
            if len(rows)!=2 or int(rows[1]['y'])!=int(rows[0]['y'])+1 or rows[0]['direction']!=rows[1]['direction']:
                errors.append(name+' east/west gate has no exact adjacent carpet pair at x'+str(x))
                continue
            upper,lower=(int(row['y']) for row in rows)
            outward=rows[0]['direction']
            if outward not in ('LEFT','RIGHT'):
                errors.append(name+' east/west carpet must have horizontal exit facing')
                continue
            inward='RIGHT' if outward=='LEFT' else 'LEFT'
            near_x=x+1 if outward=='LEFT' else x-1
            # 2 vertical moves + both approaches from the room + both
            # collision-only attempted exits. The collision must remain
            # BLOCK so CheckWarpsCollision can process the Warp.
            cases=[(x,upper,'DOWN',False),(x,lower,'UP',False)]
            for y in (upper,lower):
                cases += [(near_x,y,outward,False),(x,y,outward,True)]
            for cx,cy,direction,expected_blocked in cases:
                try:
                    blocked,_=trace_masked_step(program,labels,mask,width,height,
                                                 local,cx,cy,direction)
                    if blocked!=expected_blocked:
                        errors.append(f'{name} ({cx},{cy}) {direction}: carpet WALK/EDGE '
                                      f'expected {"BLOCK" if expected_blocked else "ALLOW"}, '
                                      f'actual {"BLOCK" if blocked else "ALLOW"}')
                except ConversionError as exc:
                    errors.append(name+' carpet executor unsupported: '+str(exc))
    return errors


def audit(rpp: Path, gold: Path) -> dict:
    """Cross-reference active Warp targets with registered Gold source and ASM."""
    root, gold = Path(rpp),Path(gold)
    native = json.loads((root/'tools/johto_native_maps.json').read_text())['maps']
    contracts = json.loads((root/'tools/johto_door_contracts.json').read_text())['active_warp_maps']
    registered = {m['name']: m for m in layout_inventory(gold)}
    entries = []
    errors = []
    eligible_maps = 0
    for contract in contracts:
        rpp_name,gold_name=contract['rpp_map'],contract['gold_map']
        local = [m for m in native if m.get('header')==rpp_name+'_h']
        if len(local)!=1 or gold_name not in registered:
            continue  # Other map types handled by existing independent audits.
        symbol_base = ('JohtoRoute34Gate' if rpp_name in
                       ('JohtoRoute34IlexForestGate','JohtoRoute35GoldenrodGate') else 'JohtoRuinsGate' if rpp_name=='JohtoRoute36RuinsGate' else 'JohtoRuinsOfAlph' if rpp_name=='JohtoRuinsOfAlphOutside' else 'JohtoAzalea' if rpp_name=='JohtoAzaleaTown' else rpp_name)
        matching_sources=[]
        for source_path in sorted((root/'engine/overworld').glob('johto_*collision.asm')):
            src=source_path.read_text()
            for symbol in re.findall(r'(?m)^(Johto\w+CanStepAhead)::',src):
                if symbol_base == symbol[:-len('CanStepAhead')]:
                    matching_sources.append((symbol,src))
        # Prefer the most specific existing masked caller: the new Gate name
        # shares the Route34 prefix, but must NOT be audited as the road.
        if matching_sources:
            longest=max(len(symbol) for symbol,_ in matching_sources)
            matching_sources=[(symbol,src) for symbol,src in matching_sources
                              if len(symbol)==longest]
        if len(matching_sources)!=1:
            continue  # No uniquely attributable caller; not falsely certified.
        caller,source=matching_sources[0]
        if 'jp JohtoModernMaskedStep' not in source:
            continue
        warps=rpp_warps(root,rpp_name)
        if not warps:
            continue
        eligible_maps+=1
        gold_set=tileset_key(registered[gold_name]['tileset'])
        # Gold HOP_RIGHT sources on Route38 are walkable approach cells;
        # this exact independently registered exception is never generalized.
        roles = ({'FLOOR','TALL_GRASS','HOP_DOWN','HOP_LEFT',
                  'HOP_DOWN_LEFT','HOP_DOWN_RIGHT','HOP_RIGHT'}
                 if gold_name == 'Route38' else None)
        geom, generated_mask = plan_gold_quadrant_collision(
            gold,gold_name,gold_set,walkable_roles=roles)
        active={(w['x'],w['y']) for w in warps}
        # Require the ASM-referenced binary to match the Gold-derived mask.
        body = re.search(r'(?m)^'+re.escape(caller.split('CanStepAhead')[0])
                         +r'BlockedRows::\s*\n\s*INCBIN\s+"([^"]+)"',source)
        if not body:
            raise ConversionError(f'ASM mask source is missing: {rpp_name}')
        runtime_mask=((root/'maps/JohtoRoute35GoldenrodGate.blocked_mask.bin').read_bytes()
                      if rpp_name=='JohtoRoute35GoldenrodGate' else (root/body[1]).read_bytes())
        if len(runtime_mask)!=len(generated_mask):
            raise ConversionError(f'Runtime mask length differs from Gold source: {rpp_name}')
        # A released map can conservatively block Gold hop starting cells.
        # Allow ONLY added blocking at actually enumerated Gold hop sites;
        # never permit an unexplained bit flip or newly opened obstacle.
        hop_sites={(h['x'],h['y']) for h in
                   geom['hops']+geom['unsafe_hop_candidates']}
        width=geom['width_cells']
        stride=geom['mask_row_bytes']
        # Gold walk-into-carpet is the authoritative exception where its
        # generic collision raster marks a genuinely active warp tile solid.
        # Only exact Gold portal cells with an active RPP warp can be opened.
        gold_carpet_warps={(e['to_x'],e['to_y']) for e in geom['portal_edges']
            if (e['to_x'],e['to_y']) in active and
            e['to_role'].startswith('WARP_CARPET_') and
            e['source_semantics'] in ('ordinary','portal')}
        for y in range(geom['height_cells']):
            for x in range(width):
                bit=1 << (x%8)
                idx=y*stride+x//8
                was=bool(generated_mask[idx]&bit)
                now=bool(runtime_mask[idx]&bit)
                if was!=now and not ((not was and now and (x,y) in hop_sites) or
                    (was and not now and (x,y) in gold_carpet_warps)):
                    raise ConversionError(f'Unexplained Gold/runtime mask mismatch: {rpp_name} ({x},{y})')
        program,labels=parse_caller(source,caller)
        # Only the shared new Cut helper needs exact mutable Cut sites.
        # Old callers retain their pre-existing strict execution model.
        gold_cut_cells=None
        if 'call JohtoRoute43LakeCutTreeCleared' in program:
            gold_cut_cells={(c['x'],c['y']) for c in decode_cells(
                (gold/'maps'/f'{gold_name}.blk').read_bytes(),
                (gold/'data/tilesets'/f'{gold_set}_metatiles.bin').read_bytes(),
                (gold/'data/tilesets'/f'{gold_set}_collision.asm').read_text(),
                geom['width_cells']//2,geom['height_cells']//2)
                if c['role']=='CUT_TREE'}
        movement=[e for e in geom['portal_edges'] if
                  (e['to_x'],e['to_y']) in active and
                  e['source_semantics'] in ('ordinary', 'portal')]
        for e in movement:
            role=e['to_role']
            # Carpets: valid ordinary/paired approaches must be traversable.
            # Cave: both directions remain explicit REVIEW; Gold CAVE role
            # alone cannot prove how RPP should trigger its warp.
            expected = ('ALLOW' if role.startswith('WARP_CARPET_') else
                        'REVIEW_DIRECTION')
            # Distinguish moving on a carpet from TRIGGERING its Warp.
            # The latter is handled independently by the collision direction
            # executor and must never change Gold WALK to expected BLOCK.
            try:
                blocked, origin=trace_masked_step(program,labels,runtime_mask,
                    geom['width_cells'],geom['height_cells'], local[0]['local_symbol'],
                    e['from_x'],e['from_y'],e['direction'],gold_cut_cells=gold_cut_cells)
                row={ 'rpp_map':rpp_name,'gold_map':gold_name,
                      'from':[e['from_x'],e['from_y']],
                      'to':[e['to_x'],e['to_y']],
                      'direction':e['direction'],'expected':expected,
                      'actual':'BLOCK' if blocked else 'ALLOW',
                      'branch':origin,'status':('FAIL' if (expected=='ALLOW' and blocked or expected=='BLOCK' and not blocked)
                            else 'REVIEW_REQUIRED' if expected=='REVIEW_DIRECTION' else 'PASS')}
            except ConversionError as exc:
                row={'rpp_map':rpp_name,'gold_map':gold_name,
                     'from':[e['from_x'],e['from_y']],
                     'to':[e['to_x'],e['to_y']],
                     'direction':e['direction'],'expected':expected,
                     'status':'FAIL','error':str(exc)}
            entries.append(row)
            if row['status']=='FAIL':
                errors.append(f"{rpp_name} {row['from']} {row['direction']} -> {row['to']}: "
                              + row.get('error', 'expected ALLOW, executed BLOCK'))
    errors.extend(gate_mat_path_errors(root, {'active_warp_maps':contracts}))
    return {'schema':'rpp-masked-step-source-execution-v2',
            'masked_caller_maps_checked':eligible_maps,
            'movement_edges_executed':len(entries),
            'movement_edges_required_allow':sum(e['expected']=='ALLOW' for e in entries),
            'failures':errors,'edges':entries,
            'status':'FAIL' if errors else 'SOURCE_BRANCH_CHECK_ONLY',
            'phone_verified':False,'compiled_rom':False}
