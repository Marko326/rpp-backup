"""SOURCE-only release blocker for the first adjacent Johto pair.

The existing converter remains the source of map binaries.  This audits that
those exact resources also have a real, bidirectional runtime registration;
Gold warp doors stay sealed and the water bitmap is not enlarged by hand.
New consecutive batches can add a data-driven spec, not relax this contract.
"""
import json
from pathlib import Path
import re
from johto_gold_cells import decode_cells
from johto_indoor_collision_adapter import plan_gold_quadrant_collision


def audit(root: Path, gold: Path, overrides=None) -> list[str]:
    root, gold = Path(root), Path(gold)
    overrides = overrides or {}
    errors = []

    def content(rel):
        value = overrides.get(rel)
        return (root / rel).read_bytes() if value is None else (value.encode() if isinstance(value, str) else value)

    try:
        registry = content('data/johto_map_headers.asm').decode()
        constants = content('constants/region_map_constants.asm').decode()
        runtime = content('engine/overworld/region_map_lookup.asm').decode()
        ledges = content('engine/overworld/ledges.asm').decode()
        surf = content('engine/overworld/johto_union_cave_surf.asm').decode()
        fly = content('engine/johto_fly_town_map.asm').decode()
        headers = {n: content(f'data/mapHeaders/Johto{n}.asm').decode()
                   for n in ('Route38', 'Route39', 'OlivineCity')}
        objects = {n: content(f'data/mapObjects/Johto{n}.asm').decode()
                   for n in ('Route39', 'OlivineCity')}
        capabilities = json.loads(content('tools/johto_native_maps.json'))['maps']
        if 'DEF NUM_JOHTO_MAPS EQU 33' not in constants:
            errors.append('pair requires 33 physical active headers')
        for name, stable, slot in (('Route39', 25, 28), ('OlivineCity', 26, 29)):
            if f'dw Johto{name}_h ; stable ID{stable} -> slot{slot}' not in registry:
                errors.append(f'{name} stable ID -> dense active slot corrupted')
            if f'Johto{name}_h:' not in headers[name] or f'dw Johto{name}Blocks' not in headers[name]:
                errors.append(f'{name} has no real header and source blocks')
            if not any(x['local_id']==stable and x['header']==f'Johto{name}_h'
                       for x in capabilities):
                errors.append(f'{name} identity/capabilities missing')
        seams = (
            ('JOHTO_ROUTE_38_LOCAL_ID',2,'JOHTO_ROUTE_39_LOCAL_ID'),
            ('JOHTO_ROUTE_39_LOCAL_ID',3,'JOHTO_ROUTE_38_LOCAL_ID'),
            ('JOHTO_ROUTE_39_LOCAL_ID',1,'JOHTO_OLIVINE_CITY_LOCAL_ID'),
            ('JOHTO_OLIVINE_CITY_LOCAL_ID',0,'JOHTO_ROUTE_39_LOCAL_ID'),
        )
        for origin, direction, target in seams:
            line=f'db {origin}, {direction}, MAP_REGION_JOHTO, {target}'
            if len(re.findall(r'^\s*'+re.escape(line)+r'\s*$',runtime,re.M)) != 1:
                errors.append(f'missing/duplicate actual runtime connection {origin} -> {target}')
        for name, flag in (('Route38','WEST | EAST'),('Route39','SOUTH | EAST'),('OlivineCity','NORTH | WEST')):
            if not re.search(r'(?m)^\s*db '+re.escape(flag)+r'\s*$',headers[name]):
                errors.append(f'{name} live physical edge flag differs')

        for name, width, height, expected_water in (('Route39',10,18,None),('OlivineCity',20,18,406)):
            base=f'maps/Johto{name}'
            if content(base+'.blk') != (gold/'maps'/f'{name}.blk').read_bytes():
                errors.append(f'{name} tile blocks differ from original Gold')
            geometry, blocked = plan_gold_quadrant_collision(gold,name,'johto')
            if content(base+'.blocked_mask.bin') != blocked:
                errors.append(f'{name} collision mask differs from converter Gold evidence')
            stride=(width*2+7)//8
            if len(blocked)!=height*2*stride:
                errors.append(f'{name} impossible Gold mask dimensions')
                continue
            # No warp data points at an unimplemented room.  The original
            # Gold Warp tile is solid in RPP until that room really exists.
            events=(gold/'maps'/f'{name}.asm').read_text()
            gold_warps=[tuple(map(int,z)) for z in re.findall(
                    r'(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,',events)]
            if len(gold_warps)!=(2 if name=='Route39' else 11):
                errors.append(f'{name} Gold indoor warp inventory changed')
            for x,y in gold_warps:
                if not (0<=x<width*2 and 0<=y<height*2) or not blocked[y*stride+x//8] & (1<<(x%8)):
                    errors.append(f'{name} unbuilt Gold warp entrance opened at ({x},{y})')
            obj=objects[name].splitlines()
            if not re.search(r'(?m)^\s*db \$00\s*; no (?:dummy Warp|active Warp)',objects[name]):
                errors.append(f'{name} unbuilt indoor warp has active dummy registration')
            if expected_water is not None:
                cells=decode_cells((gold/'maps'/f'{name}.blk').read_bytes(),
                    (gold/'data/tilesets/johto_metatiles.bin').read_bytes(),
                    (gold/'data/tilesets/johto_collision.asm').read_text(),width,height)
                water=bytearray(stride*height*2)
                positions=[(c['x'],c['y']) for c in cells if c['role']=='WATER']
                for x,y in positions:water[y*stride+x//8] |= 1<<(x%8)
                if len(positions)!=expected_water or content(base+'.water_mask.bin')!=water:
                    errors.append(f'{name} Surf bitmap widened/drifted from Gold {expected_water} WATER cells')
                if 'jp z, IsJohtoOlivineWaterAhead' not in surf or 'JohtoOlivineWaterRows::' not in surf:
                    errors.append('Olivine Surf runtime not connected')
                if ('cp JOHTO_OLIVINE_CITY_LOCAL_ID' not in surf or
                    'cp JOHTO_ROUTE_40_LOCAL_ID' not in surf):
                    errors.append('Olivine badge/SURF usage not permitted explicitly')
        gold_hops,_=plan_gold_quadrant_collision(gold,'Route39','johto')
        hop_section=re.split(r'(?m)^\.route39Hops\s*$',ledges,maxsplit=1)[-1].split('db $ff',1)[0]
        raw=re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*,\s*PLAYER_DIR_(UP|DOWN|LEFT|RIGHT)\s*$',hop_section)
        dirset={(0,-1):'UP',(0,1):'DOWN',(-1,0):'LEFT',(1,0):'RIGHT'}
        expected={(str(h['x']),str(h['y']),dirset[(h['dx'],h['dy'])]) for h in gold_hops['hops']}
        if set(raw)!=expected or len(raw)!=len(expected) or len(raw)!=20:
            errors.append('Route39 executable 20 Gold jump directions missing/changed')
        if 'ld a, JOHTO_OLIVINE_CITY_LOCAL_ID' not in fly or 'cp 9\n\tjr c, .nextReady' not in fly:
            errors.append('Olivine Fly cursor/physical ID not active')
    except (OSError,IndexError,KeyError,ValueError,TypeError) as exc:
        errors.append(f'adjacent runtime source audit failed closed: {exc}')
    return errors
