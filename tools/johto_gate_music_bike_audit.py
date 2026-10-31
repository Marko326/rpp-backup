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



def trace_gate_source(code: str, gate: str, source: str, kind: str) -> str:
    """Execute the branch-only gate dispatcher to its selected source ID.

    This tiny deterministic interpreter deliberately tests actual conditional
    fallthrough, not just whether all the expected CP tokens are mentioned.
    It stops before the regular profile/slot lookup and models only the ASM
    instructions used by the gate-specific source selector.
    """
    start = 'ld a, [wCurLocalMapID]'
    lines = []
    labels = {}
    for raw in code.splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        if line.endswith(':') or (line.startswith('.') and ' ' not in line):
            labels[line.rstrip(':')] = len(lines)
        else:
            lines.append(line)
    start_at = next((i for i in range(len(lines)-1) if lines[i] == start and
                     lines[i+1].startswith('cp JOHTO_')), None)
    if start_at is None:
        raise ValueError('gate selector start missing')
    a = gate
    z = False
    selected = gate
    pc = start_at
    for _ in range(150):
        if pc >= len(lines):
            raise ValueError('gate selector ran off the end')
        ins = lines[pc]
        pc += 1
        if ins == start:
            a = gate
        elif ins == 'ld a, [wJohtoGateMusicSourceLocalID]':
            a = source
        elif ins.startswith('cp '):
            z = (a == ins[3:].strip())
        elif ins.startswith(('jr ', 'jp ')):
            tail = ins[3:].strip()
            if ', ' in tail:
                cond, dest = tail.split(', ', 1)
                jump = (cond == 'z' and z) or (cond == 'nz' and not z)
            else:
                dest, jump = tail, True
            if jump:
                if dest not in labels:
                    raise ValueError('unknown branch label '+dest)
                pc = labels[dest]
        elif ins == 'ret':
            return selected
        elif ins == 'ret nz':
            if not z:
                return selected
        elif ins == 'ret z':
            if z:
                return selected
        elif ins == 'ld e, a':
            # Both dispatchers use E for the selected profile/active-slot.
            if (kind == 'rby' and pc < len(lines) and lines[pc] == 'call JohtoPilotGetMapProfile') or (
                kind == 'gsc' and pc < len(lines) and lines[pc] == 'callab GetJohtoActiveSlot'):
                selected = a
                return selected
        elif ins == 'call JohtoPilotGetMapProfile':
            # Before selector: default loaded from the actual gate profile.
            selected = gate
        elif ins.startswith(('ld ', 'inc ', 'push ', 'pop ')):
            continue
        else:
            raise ValueError('unexpected dispatcher instruction '+ins)
    raise ValueError('gate selector exceeded step limit')

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
        bike_ids=re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)\s*\n\s*(?:jr|jp) z,\s*\.allowed',bike)
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
            end = '.sourceValid' if variant == 'rby' else '.gateDefault'
            return {
                'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID':
                    code.split('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',1)[1].split('\n.southGate\n',1)[0],
                'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID':
                    code.split('\n.southGate\n',1)[1].split('\n.violetGate\n',1)[0],
                'JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID':
                    code.split('\n.violetGate\n',1)[1].split('\n.southForestGate\n',1)[0],
                'JOHTO_ILEX_AZALEA_GATE_LOCAL_ID':
                    code.split('\n.southForestGate\n',1)[1].split('\n.northForestGate\n',1)[0],
                'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID':
                    code.split('\n.northForestGate\n',1)[1].split('\n'+end+'\n',1)[0],
            }
        for variant,code in [('rby',loader),('gsc',gsc)]:
            pieces=gate_branches(code,variant)
            for p in policies:
                found=re.findall(r'cp\s+(JOHTO_\w+_LOCAL_ID)',pieces[p['id']])
                check(variant+'_exact_sources_'+p['id'],set(found)==set(p['sources']) and
                      len(found)==len(p['sources']) and
                      pieces[p['id']].count('wJohtoGateMusicSourceLocalID')==1,
                      f'gate {p["id"]} may inherit only {p["sources"]}; source comparisons={found}')
        # MUS-282: check every permitted entry *and* every wrong neighbour
        # through the real branch graph.  A mere token scan missed the old
        # VioletCity fallthrough into .southForestGate.
        all_sources = correct_sources | {'JOHTO_ROUTE_29_LOCAL_ID', 'JOHTO_ROUTE_33_LOCAL_ID'}
        for variant, code in [('rby', loader), ('gsc', gsc)]:
            for policy in policies:
                gate_id = policy['id']
                for source in sorted(all_sources):
                    expected_source = source if source in policy['sources'] else gate_id
                    try:
                        actual_source = trace_gate_source(code, gate_id, source, variant)
                        valid = actual_source == expected_source
                        detail = f'{gate_id}, source={source}, selected={actual_source}, expected={expected_source}'
                    except ValueError as exc:
                        valid = False
                        detail = str(exc)
                    check(f'{variant}_resolved_source_{gate_id}_{source}', valid, detail)
        # Same-song gate entry should take a no-restart path in all 5 music
        # styles, walking, cycling with Bike Song OFF and Bike Song ON.  When
        # walking from a bike, CP $2 leaves CARRY set. The placeholder bank
        # routine used to RET with that stale carry, skipping the song cache.
        cmpbank = audio.split('CompareMapMusicBankWithCurrentBank:', 1)[1].split('\nUpdateMusic', 1)[0]
        check('music_bank_stub_clears_carry', bool(re.match(r'\s*;[^\n]*\n(?:\s*;[^\n]*\n)*\s*and a\s+ret\b', cmpbank)) and
              re.search(r'\.walking\s+ld a, \[wMapMusicSoundID\]\s+ld b, a\s+call CompareMapMusicBankWithCurrentBank\s+jr c, \.next4', audio) is not None,
              'no stale Carry from Bike Song OFF may bypass the same-song cache')
        check('gate_warp_no_forced_music_restart',
              'call PlayDefaultMusicFadeOutCurrent' in home.split('LoadMapData::',1)[1].split('SwitchToMapRomBank::',1)[0] and
              'call PlayDefaultMusic\n' not in home.split('LoadMapData::',1)[1].split('SwitchToMapRomBank::',1)[0] and
              re.search(r'ld a, \[wLastMusicSoundID\]\s+cp b[^\n]*\n\s*ret z', audio) is not None and
              'ld [wJohtoGateMusicSourceLocalID], a' in runtime,
              'ordinary Warp into a gate must reuse the song cache without a forced restart')
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
