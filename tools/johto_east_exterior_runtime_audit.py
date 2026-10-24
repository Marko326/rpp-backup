#!/usr/bin/env python3
"""Four Gold eastern exteriors: actual runtime contract, never a ROM/phone proof.

Checks the playable asset/collision/edge/fly/field-move path; Gold Ice Path
cannot be opened from this evidence. A staged-source check alone does not count.
"""
import hashlib
import json
import re
from pathlib import Path

from johto_fly_destination_audit import audit as fly_audit
from johto_region_id_audit import audit as region_audit
from johto_rom0_collision_audit import audit as collision_audit
from johto_rpp_connection_guard import audit_all_active

MAPS = (
    ('Route44', 69, 41, 37, 21, True),
    ('BlackthornCity', 71, 42, 39, 47, True),
    ('Route45', 72, 43, 41, 88, True),
    ('Route46', 73, 44, 43, 20, False),
)

def audit(project, gold, *, connections=True, fly=True, overrides=None):
    p, gold = Path(project), Path(gold)
    errors = []
    overrides = overrides or {}
    def read(f): return overrides.get(f, (p/f).read_text(encoding='utf8'))
    def binary(f): return overrides.get(f, (p/f).read_bytes())
    def require(text, token, why):
        if token not in text: errors.append(why)
    try:
        cfg=json.loads(read('tools/johto_native_maps.json'))
        contract=json.loads(read('tools/johto_east_corridor_source_contract.json'))
        tables=read('data/johto_map_headers.asm')
        fence=read('engine/overworld/johto_east_exterior.asm')
        collision=read('engine/overworld/johto_route33_collision.asm')
        surf=read('engine/overworld/johto_union_cave_surf.asm')
        ledge=read('engine/overworld/ledges.asm')
        main=read('main.asm')
        fmenu=read('engine/johto_fly_town_map.asm')
        names=read('engine/town_map.asm')
        idx=read('engine/overworld/johto_town_map_helpers.asm')
        spec={e['name']: e for e in contract['maps']}
        assert read('data/game_version.asm').count('OLIV-5.62.241@')==1
    except (OSError,ValueError,KeyError,AssertionError) as exc:
        return ['Gold eastern live sources unavailable or formal version drift: '+str(exc)]
    # The four eastern slots must be unchanged. The newly registered room is
    # appended in slot 46, not inserted into the historical 45-slot route set.
    if (len(cfg['maps']) != 49 or [x.get('local_id') for x in cfg['maps'][-3:]] != [34,32,35] or
            cfg['maps'][46].get('local_symbol') != 'JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID'):
        errors.append('East runtime must preserve four eastern slots and known indoor slot46 before new batch slots47..48')
    require(main, 'INCLUDE "engine/overworld/johto_east_exterior.asm"','Bank47 collision implementation not included')
    require(main, 'SECTION "Johto East Runtime Hooks", ROMX, BANK[$47]', 'Bank47 implementation not anchored')
    require(collision,'callab JohtoEastCanStepAhead', 'East movement must pass Gold mask via far-call')
    require(main,'callba JohtoEastEdgeFence', 'Seam interception must far-call bank47')
    require(ledge,'callab JohtoEastHopDirection', 'Gold hop movement not wired to real ledge engine')
    for name,mid,slot,landmark,hops,can_surf in MAPS:
        entry=[r for r in cfg['maps'] if r.get('local_id')==mid]
        if len(entry)!=1:
            errors.append(name+': missing or duplicate native ID')
            continue
        row=entry[0]
        if row.get('town_map_index')!=landmark:
            errors.append(name+': wrong original Gold Town Map landmark')
        if row.get('feature_status',{}).get('bike')!='ALLOWED':
            errors.append(name+': bike permit missing')
        if row.get('feature_status',{}).get('surf')!=('ALLOWED' if can_surf else 'DEFERRED'):
            errors.append(name+': Surf permission must match reviewed Gold water')
        if row.get('feature_status',{}).get('warp')!=('ALLOWED' if name=='Route46' else 'FORBIDDEN'):
            errors.append(name+': unreviewed interior/cave Warp status (Route46 south gate is enabled)')
        if name=='Route46':
            obj=read('data/mapObjects/JohtoRoute46.asm')
            if 'db 33, 7, 0, REGION_WARP_ESCAPE' not in obj or 'db 33, 8, 1, REGION_WARP_ESCAPE' not in obj:
                errors.append('Route46: south gate double Warp must remain enabled')
        if row.get('feature_status',{}).get('fly')!=('ALLOWED' if name=='BlackthornCity' else 'FORBIDDEN'):
            errors.append(name+': Fly destination only at original Gold city')
        if row.get('header')!='Johto'+name+'_h':
            errors.append(name+': wrong live map header')
        if f'dw Johto{name}_h' not in tables:
            errors.append(name+': not in live header pointer table')
        if f'Johto{name}Blocks: INCBIN' not in main:
            errors.append(name+': no live Gold map blocks in ROM')
        goldsrc=gold/('maps/'+name+'.blk')
        live='maps/Johto'+name+'.blk'
        try:
            if goldsrc.read_bytes()!=binary(live):errors.append(name+': Gold map layout differs')
        except OSError:errors.append(name+': Gold map source/binary absent')
        mask=spec[name]['staged_assets']['mask']
        try:
            source_mask = binary(mask)
            expected_mask = bytearray(source_mask)
            if name == 'Route45':
                # Gold HOP_RIGHT is an enterable takeoff, while the 16x16
                # source mask treats this artwork as solid. Leave the source
                # stage byte-perfect; normalize only these four Gold-proven
                # positions in the live walking mask, never the wall behind.
                from johto_indoor_collision_adapter import plan_gold_quadrant_collision
                plan, _ = plan_gold_quadrant_collision(gold, name, 'johto')
                reviewed = {(6,20,1,0),(6,21,1,0),(6,64,1,0),(6,65,1,0)}
                found = {(h['x'],h['y'],h['dx'],h['dy']) for h in plan['hops']
                         if (h['x'],h['y']) in {(6,20),(6,21),(6,64),(6,65)}}
                if found != reviewed:
                    errors.append('Route45: reviewed right-facing hop positions changed in Gold source')
                for x,y,dx,dy in reviewed:
                    off = y * 3 + x//8
                    if not (expected_mask[off] & (1<<(x%8))):
                        errors.append('Route45: expected original blocked hop takeoff missing')
                    expected_mask[off] &= ~(1<<(x%8))
            if binary('maps/Johto'+name+'.blocked_mask.bin') != bytes(expected_mask):
                errors.append(name+': live Gold blocked mask differs from Gold source plus reviewed HOP takeoff permissions')
        except (OSError, IndexError, ValueError, KeyError):
            errors.append(name+': Gold mask/source proof missing')
        hoplabel='Johto'+name+'HopList::'
        if hoplabel not in fence:
            errors.append(name+': no runtime ledge list')
        else:
            body=fence.split(hoplabel,1)[1].split('db $ff',1)[0]
            items=re.findall(r'(?m)^\s*db\s+\d+\s*,\s*\d+\s*,\s*PLAYER_DIR_(?:DOWN|LEFT|RIGHT)\s*$',body)
            if len(items)!=hops:errors.append(name+': Gold hop takeoff count changed')
        if can_surf:
            require(surf,'Johto'+name+'WaterRows::',name+': no live Gold Surf mask')
            require(surf,'INCBIN "maps/Johto'+name+'.water_mask.bin"',name+': Surf mask not loaded')
        else:
            if 'Johto'+name+'WaterRows::' in surf:errors.append(name+': Surf opened without Gold water evidence')
    # Physical count/landmark indices are distinct from menu names. Verify
    # the real per-slot player-marker table, not just the manifest values.
    words=re.search(r'JohtoNativeTownMapIndices::(.*?)JohtoNativeTownMapIndicesEnd::',idx,re.S)
    try:
        values=[]
        for line in words.group(1).splitlines():
            line=line.split(';',1)[0].strip()
            if line.startswith('db '):values.extend(int(x.strip()) for x in line[3:].split(','))
        if len(values)!=49 or values[-3:]!=[26,26,26] or [values[slot] for _,_,slot,_,_,_ in MAPS]!=[landmark for _,_,_,landmark,_,_ in MAPS]:
            errors.append('active slot -> Gold Town Map index drift')
    except (ValueError,AttributeError,IndexError) as e:errors.append('Town Map index table unparsable: '+str(e))
    for name,mid,slot,landmark,hops,s in MAPS:
        if 'dw Johto'+ ('BlackthornName' if name=='BlackthornCity' else 'Browse'+name+'Name') not in names:
            errors.append(name+': town-map visible label absent')
    if fmenu.count('EVENT_JOHTO_FLY_BLACKTHORN')!=2:
        errors.append('Blackthorn Fly missing persistent visited gate')
    require(fmenu,'dw .blackthornName','Blackthorn Fly missing menu row')
    if fly:
        errors.extend('Fly: '+x for x in fly_audit(p,gold))
    errors.extend('Collision: '+x for x in collision_audit(p))
    errors.extend('Registry: '+x for x in region_audit(p))
    # Ice Path remains unimplemented; do not disguise entry as traversable.
    if 'JohtoIcePath1F_h' in tables or 'JohtoIcePath1FObject' in main:
        errors.append('Ice Path 1F opened without Gold ice/sliding and B1F exits')
    if connections:
        report=audit_all_active(p,gold)
        if report['status']!='PASS':errors.extend('Seams: '+x for x in report['issues'])
    return errors

if __name__=='__main__':
    import argparse,json
    ap=argparse.ArgumentParser();ap.add_argument('--rpp',type=Path,required=True);ap.add_argument('--gold',type=Path,required=True)
    a=ap.parse_args();err=audit(a.rpp,a.gold)
    print(json.dumps({'status':'FAIL' if err else 'PASS','errors':err,'built_rom':False,'phone_verified':False},ensure_ascii=False,indent=2))
    raise SystemExit(bool(err))
