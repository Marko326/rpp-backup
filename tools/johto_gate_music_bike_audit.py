#!/usr/bin/env python3
"""Fail closed for ALL active Johto gates: inherited BGM and Gold bike policy.

Reads the active map roster, Warp contracts and code, rather than a frozen
single-gate assertion. When --gold-root is provided it independently checks
Gold map environment classifications, including indoor-gate exceptions.
Static source validation is not an emulator or a test of audio playback time.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

POLICY='tools/johto_gate_music_bike_contracts.json'
GOLD_MAPS='data/maps/maps.asm'


def audit(root: Path, gold: Path | None = None, overrides: dict[str,str] | None = None) -> dict:
    root=Path(root)
    overrides=overrides or {}
    errors=[]; checks=[]
    def check(name, good, detail):
        checks.append({'check':name, 'status':'PASS' if good else 'FAIL', 'detail':detail})
        if not good: errors.append(name+': '+detail)
    def get(rel):
        return overrides[rel] if rel in overrides else (root/rel).read_text(encoding='utf-8')
    try:
        contract=json.loads(get(POLICY)); doors=json.loads(get('tools/johto_pilot_door_contracts.json'))
        signs=json.loads(get('tools/johto_map_name_sign_contracts.json'))
        home=get('home/overworld.asm'); runtime=get('engine/johto_pilot_runtime.asm')
        opt=get('engine/menu/options_menu.asm'); audio=get('home/audio.asm')
        assets=get('data/johto_pilot_runtime_assets.asm')
        active_names=re.findall(r'(?m)^\s*db\s+(JOHTO_\w+_LOCAL_ID)\s*,',
             assets.split('JohtoPilotRuntimeResourceDescriptors::',1)[1].split('JohtoPilotRuntimeResourceDescriptorsEnd::',1)[0])
        gate_rows=doors['gatehouse_activation_policy']['active_gatehouse_contracts']
        ids=get('constants/region_map_constants.asm')+'\n'+get('constants/johto_fixed_map_ids.asm')
        symbols=dict((k, int(v[1:],16) if v.startswith('$') else int(v)) for k,v in
            re.findall(r'(?m)^\s*DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)\b',ids))
        name_by_value={v:k for k,v in symbols.items()}
        active_neutral={x['id'] for x in signs['active_maps'] if x['role']=='neutral'}
        registered={name_by_value[x['stable_id']]: x for x in gate_rows if x['stable_id'] in name_by_value}
        policies=contract['active_gates']; expected={p['id'] for p in policies}
        check('active_gold_gate_coverage', contract.get('schema')=='johto-gate-music-bike-v1' and
              set(registered)==active_neutral==expected and expected.issubset(set(active_names)) and
              len(policies)==len(expected),
              f'neutral={sorted(active_neutral)}, door contracts={sorted(registered)}, music/bike policies={sorted(expected)}')
        check('explicit_gate_contract', doors['gatehouse_activation_policy']['require_explicit_contract_before_activation'] is True and
              all(p['music']=='inherit_source_no_restart' and isinstance(p.get('bike_allowed'),bool)
                  and p['gold_environment'] in ('GATE','INDOOR') for p in policies),
              'every active gate needs explicit music, bike and Gold environment declarations')
        for p in policies:
            symbol=p['id']; gate=registered.get(symbol,{}); stable=symbols.get(symbol)
            arriving={w.get('source_stable_id') for w in gate.get('warp_contracts',[]) if w.get('target_stable_id')==stable}
            source_symbols={name_by_value.get(i) for i in arriving}
            check('entry_sources_'+symbol, set(p['sources'])==source_symbols and
                  len(p['sources'])==2 and set(p['sources']).issubset(set(active_names)),
                  f'Warp sources={source_symbols}, policy sources={p["sources"]}')
            check('gate_policy_'+symbol, gate.get('gold_map')==p.get('gold_map') and
                  p['bike_allowed']==(p['gold_environment']=='GATE'),
                  f'Gold map={gate.get("gold_map")}, environment={p["gold_environment"]}, bike={p["bike_allowed"]}')
        if gold is not None:
            gold_maps=(Path(gold)/GOLD_MAPS).read_text(encoding='utf-8')
            env=dict(re.findall(r'(?m)^\s*map\s+(\w+)\s*,\s*\w+\s*,\s*(\w+)\s*,',gold_maps))
            for p in policies:
                check('gold_environment_'+p['id'], env.get(p['gold_map'])==p['gold_environment'],
                      f"Gold {p['gold_map']}={env.get(p['gold_map'])}; expected={p['gold_environment']}")
            for name in contract['negative_gold_gates']:
                check('indoor_exception_'+name, env.get(name)=='INDOOR',
                      f'Gold environment must be INDOOR, not automatically bike-enabled: {env.get(name)}')
        bike=home.split('IsBikeRidingAllowed::',1)[1].split('\n.legacyBike\n',1)[0]
        bike_ids=re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)\s*\n\s*jr z,\s*\.allowed',bike)
        permitted={p['id'] for p in policies if p['bike_allowed']}
        check('bike_every_eligible_gate',len(bike_ids)==len(permitted) and set(bike_ids)==permitted,
              f'allowed stable IDs={bike_ids}; Gold GATE={sorted(permitted)}')
        check('bike_region_and_handle_guard',bool(re.search(r'cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.legacyBike\s+ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.legacyBike\s+ld a, \[wCurLocalMapID\]',bike)),
              'only region-scoped Johto native maps may enter the gate exception')
        check('bike_no_global_gate_tileset', 'JOHTO_GATE' not in get('data/bike_riding_tilesets.asm') and
              'JOHTO_HOUSE' not in get('data/bike_riding_tilesets.asm'),
              'never grant bike permission by gate artwork or to ordinary houses')
        warp=runtime.split('.toJohto\n',1)[1].split('\n.notGateMusicEntry\n',1)[0]
        warp_code='\n'.join(row.split(';',1)[0] for row in warp.splitlines())
        recorded=re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)\s*\n\s*jr (?:z, \.recordGateSource|nz, \.notGateMusicEntry)',warp)
        check('capture_every_gate_source',set(recorded)==expected and len(recorded)==len(expected) and
              'ld a, c\n    ld [wJohtoGateMusicSourceLocalID], a' in warp and
              'wLastMap' not in warp_code and 'wWarpedFromWhichMap' not in warp_code,
              f'capture gates={recorded} before shared $FC destination overwrites source')
        loader=runtime.split('JohtoPilotLoadMapMusic::',1)[1].split('; Outdoor boundary contract',1)[0]
        gsc=opt.split('LookupJohtoMapGSCMusic:',1)[1].split('JohtoActiveGSCMusic::',1)[0]
        checked_sources=set(re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)',loader)) - expected
        gsc_sources=set(re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)',gsc)) - expected
        correct_sources={sid for p in policies for sid in p['sources']}
        for name,code in [('rby',loader),('gsc',gsc)]:
            gate_symbols=set(re.findall(r'cp\s+(JOHTO_\w+GATE_LOCAL_ID)',code))
            # The South Gate's symbol ends in GATE_LOCAL_ID, as do the other two.
            check(name+'_gate_dispatch',gate_symbols==expected and all('cp '+x in code for x in expected),
                  f'gate identities={gate_symbols}, required={expected}')
            check(name+'_entry_source_whitelist', all('cp '+x in code for x in correct_sources) and
                  code.count('wJohtoGateMusicSourceLocalID')==len(policies),
                  'each gate must check both of its real Gold-connected source sides')
        # Guard *which* two neighbours each gate accepts, not just the global
        # union. Swapping a Ruins source into the Violet gate must fail.
        def gate_branches(code, variant):
            if variant == 'rby':
                return {
                    'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID':code.split('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',1)[1].split('\n.southGate\n',1)[0],
                    'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID':code.split('\n.southGate\n',1)[1].split('\n.violetGate\n',1)[0],
                    'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID':code.split('\n.violetGate\n',1)[1].split('\n.sourceValid\n',1)[0],
                }
            return {
                'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID':code.split('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',1)[1].split('\n.southGate\n',1)[0],
                'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID':code.split('\n.southGate\n',1)[1].split('\n.violetGate\n',1)[0],
                'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID':code.split('\n.violetGate\n',1)[1].split('\n.gateDefault\n',1)[0],
            }
        for variant,code in [('rby',loader),('gsc',gsc)]:
            pieces=gate_branches(code,variant)
            for p in policies:
                found=re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)',pieces[p['id']])
                check(variant+'_exact_sources_'+p['id'],set(found)==set(p['sources']) and
                      len(found)==len(p['sources']) and
                      pieces[p['id']].count('wJohtoGateMusicSourceLocalID')==1,
                      f'gate {p["id"]} may inherit only {p["sources"]}; source comparisons={found}')
        check('rby_gate_source_profile',checked_sources==correct_sources and
              re.search(r'\.sourceValid\s+ld e, a\s+call JohtoPilotGetMapProfile\s+inc hl\s+inc hl\s+ld a, \[hli\]\s+ld \[wMapMusicSoundID\], a',loader) is not None,
              'RBY map BGM and bank are inherited from validated entering source profile')
        check('gsc_gate_source_profile',gsc_sources==correct_sources and
              '.gateDefault' in gsc and 'ld a, [wCurLocalMapID]' in gsc and
              'callab GetJohtoActiveSlot' in gsc and 'JohtoActiveGSCMusic' in gsc and
              'MUSIC_GBP_GSC_ROUTE36' not in gsc,
              'GSC/GSCC/RND resolve entering source stable ID, with Gold default on old-save Continue')
        music_rows=opt.split('JohtoActiveGSCMusic::',1)[1].split('JohtoActiveGSCMusicEnd::',1)[0]
        defaults={6:('7','MUSIC_GBP_GSC_ROUTE30'),102:('9','MUSIC_GBP_GSC_ROUTE30'),19:('11','MUSIC_GBP_GSC_ROUTE36')}
        check('gsc_gate_fallbacks', all(re.search(r'(?m)^\s*db\s+'+re.escape(value)+r'\s*;\s*slot\s*'+slot+r':',music_rows)
                  for slot,value in defaults.values()),
              'uninitialized source on Continue uses original Gold gate scene, not a random neighbour')
        scene=opt.split('CheckJohtoMusicSceneTransition::',1)[1].split('; Legacy RBY ID ->',1)[0]
        check('music_cursor_kept_on_same_scene', 'cp c\n\tret z' in scene and
              'ld [wLastJohtoMusicSceneID], a' in scene and
              'ld [wLastMusicSoundID], a' in scene and
              re.search(r'ld a, \[wLastMusicSoundID\]\s+cp b\s*;[^\n]*\n\s*ret z',audio) is not None,
              'same scene must not invalidate the playing song or restart playback')
    except (OSError,KeyError,ValueError,TypeError,AttributeError,IndexError) as exc:
        check('parse_and_read',False,str(exc))
    return {'schema':'johto-gate-music-bike-audit-v1','status':'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'errors':errors,'checks':checks,'gold_checked':gold is not None,'runtime_verified':False}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project',type=Path,default=Path.cwd())
    parser.add_argument('--gold-root',type=Path)
    parser.add_argument('--json-out',type=Path)
    args=parser.parse_args()
    result=audit(args.project,args.gold_root)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True,exist_ok=True)
        args.json_out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'status':result['status'],'checks':len(result['checks']),'errors':result['errors']},ensure_ascii=False,indent=2))
    return int(bool(result['errors']))

if __name__=='__main__': raise SystemExit(main())
