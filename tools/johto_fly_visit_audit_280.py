#!/usr/bin/env python3
"""Independent source/Gold preflight for Johto Fly registration and visited bits.

Ensures active towns have a saved, uniquely keyed, walkable landing and that
inactive Johto towns cannot be selected. Static only; not a ROM/Save emulator.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
try:
    from johto_gold_door_audit import GoldCollisionIndex
except ImportError:
    from tools.johto_gold_door_audit import GoldCollisionIndex

DESTINATIONS = {
    'NEW_BARK': 'NewBarkTown', 'CHERRYGROVE': 'CherrygroveCity',
    'VIOLET': 'VioletCity', 'AZALEA': 'AzaleaTown', 'GOLDENROD': 'GoldenrodCity',
    'ECRUTEAK': 'EcruteakCity', 'OLIVINE': 'OlivineCity',
    'MAHOGANY': 'MahoganyTown', 'CIANWOOD': 'CianwoodCity',
    'LAKE_OF_RAGE': 'LakeOfRage', 'BLACKTHORN': 'BlackthornCity',
}


def audit(root: Path, gold_root: Path | None = None, overrides: dict[str, str] | None = None) -> dict:
    root = Path(root)
    overrides = overrides or {}
    checks, errors = [], []

    def check(name: str, ok: bool, detail: str = ''):
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL', 'detail': detail})
        if not ok:
            errors.append(f'{name}: {detail}')

    def read(name: str):
        return overrides.get(name) if name in overrides else (root/name).read_text(encoding='utf-8')

    try:
        fly = read('engine/johto_pilot_fly_map.asm')
        home = read('home/overworld.asm')
        events = read('constants/event_constants.asm')
        assets = read('data/johto_pilot_runtime_assets.asm')
        constants = read('constants/region_map_constants.asm') + '\n' + read('constants/johto_fixed_map_ids.asm')
        region_ids = dict((s, int(n[1:], 16) if n.startswith('$') else int(n)) for s,n in
                          re.findall(r'(?m)^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)', constants))
        table = fly.split('JohtoPilotFlyDestinations:', 1)[1].split('\n.end:', 1)[0]
        rows = re.findall(r'(?m)^\s*db\s+(JOHTO_\w+_LOCAL_ID)\s*,\s*(EVENT_JOHTO_FLY_\w+)\s*/\s*8\s*,\s*\(1\s*<<\s*\(\2\s*%\s*8\)\)\s*,\s*(\d+)\s*,\s*(\d+)\s*\n\s*dw\s+\.name(\w+)\s*,\s*\.warp(\w+)\s*$', table)
        check('eleven_fly_registry_rows',len(rows)==len(DESTINATIONS)==11 and
              'ASSERT .end - JohtoPilotFlyDestinations == JOHTO_FLY_TOWN_COUNT * 9' in fly and
              'DEF JOHTO_FLY_TOWN_COUNT EQU 11' in fly,
              f'parsed {len(rows)} correctly keyed 9-byte rows')
        active_desc = assets.split('JohtoPilotRuntimeResourceDescriptors::', 1)[1].split('JohtoPilotRuntimeResourceDescriptorsEnd::', 1)[0]
        active_ids = set(re.findall(r'(?m)^\s*db\s+(JOHTO_\w+_LOCAL_ID)\s*,', active_desc))
        names, keys, site_ids = set(), set(), set()
        expected = set(DESTINATIONS)
        gold = GoldCollisionIndex(gold_root) if gold_root is not None else None
        expected_active = set()
        for key, map_name in DESTINATIONS.items():
            symbol = 'JOHTO_' + ({'NEW_BARK':'NEW_BARK','CHERRYGROVE':'CHERRYGROVE',
                'VIOLET':'VIOLET_CITY','AZALEA':'AZALEA_TOWN','GOLDENROD':'GOLDENROD_CITY',
                'ECRUTEAK':'ECRUTEAK_CITY','OLIVINE':'OLIVINE_CITY',
                'MAHOGANY':'MAHOGANY_TOWN','CIANWOOD':'CIANWOOD_CITY',
                'LAKE_OF_RAGE':'LAKE_OF_RAGE','BLACKTHORN':'BLACKTHORN_CITY'}[key]) + '_LOCAL_ID'
            if symbol in active_ids:
                expected_active.add(key)
            row = next((r for r in rows if r[1] == 'EVENT_JOHTO_FLY_' + key), None)
            check('registry_'+key, row is not None and row[0]==symbol and row[4]==row[5] and
                  row[4].upper()==('LAKE' if key=='LAKE_OF_RAGE' else key.replace('_','')) and symbol in region_ids,
                  f'{key} must bind the real physical stable ID, event and matching name/warp')
            if row is None:
                continue
            names.add(row[1]); site_ids.add(row[0]); keys.add(key)
            ev = re.search(r'(?m)^\s*const\s+' + re.escape(row[1]) + r'\s*;\s*current\s*([0-9A-Fa-f]+)\b', events)
            check('saved_event_'+key, ev is not None and re.search(r'(?m)^\s*const\s+'+re.escape(row[1])+r'\b',events) is not None,
                  f'expected one persisted event {row[1]}')
            warp = re.search(r'(?m)^\.warp'+re.escape(row[5])+r':\s*\n\s*FLYWARP_DATA\s+([^,]+),\s*(\d+),\s*(\d+)', fly)
            if not warp:
                check('landing_'+key,False,'missing six-byte FLYWARP_DATA')
                continue
            width,y,x=warp.groups()
            y,x=int(y),int(x)
            check('landing_coordinate_'+key, y>=0 and x>=0 and
                  ((width.strip().isdigit() and int(width.strip()) >= (x+1)//2) or
                   width.strip().startswith('JOHTO_')),
                  f'width={width}, x={x}, y={y}')
            if gold is not None:
                tile = gold.cells(map_name).get((x,y))
                check('gold_walkable_landing_'+key, tile is not None and tile['role'] in ('FLOOR','TALL_GRASS'),
                      f'{map_name} ({x},{y}) role={tile["role"] if tile else None}')
        check('unique_fly_id_and_events',len(rows)==len(site_ids)==len(names)==len(expected) and keys==expected,
              f'{len(site_ids)} unique IDs; {len(names)} unique saved event bits')
        check('active_towns_not_inactive_routes',expected_active=={'NEW_BARK','CHERRYGROVE','VIOLET','AZALEA','GOLDENROD','ECRUTEAK'},
              f'currently active fly towns={sorted(expected_active)}; remaining six are reserved')
        entry = fly.split('LoadJohtoPilotFlyTownMap::', 1)[1].split('JohtoPilotRecordFlyVisit::',1)[0]
        check('flight_requires_both_active_and_visited', all(t in entry for t in (
            '.isUnlocked','callab GetJohtoActiveSlot','cp JOHTO_INVALID_ACTIVE_SLOT',
            'ld hl, wEventFlags','and [hl]','call .isUnlocked','jp z, .input',
            'ld [wJohtoFlySelectedLocalID], a', 'ld a, JOHTO_PILOT_FLY_SELECTOR')),
            'Fly menu must exclude unregistered and unvisited towns; selector cannot be physical map')
        visit = fly.split('JohtoPilotRecordFlyVisit::',1)[1].split('JohtoPilotApplyNewBarkFlyWarp::',1)[0]
        check('map_load_only_records_real_johto_towns', all(t in visit for t in (
            'cp JOHTO_RUNTIME_MAP_HANDLE','cp MAP_REGION_JOHTO',
            'ld a, [wCurLocalMapID]','ld hl, JohtoPilotFlyDestinations',
            'cp b','ld hl, wEventFlags','or [hl]','ld [hl], a',
        )) and 'callab JohtoPilotRecordFlyVisit' in home.split('LoadMapHeader::',1)[1].split('\n.markKantoTown',1)[0],
              'visits must be written by native city header load, not bypassed Kanto path')
        warp_code = fly.split('JohtoPilotApplyNewBarkFlyWarp::', 1)[1].split('JohtoPilotFlyDestinations:', 1)[0]
        check('flight_arrival_rechecks_eligibility',all(t in warp_code for t in (
            'callab GetJohtoActiveSlot','cp JOHTO_INVALID_ACTIVE_SLOT',
            'ld hl, wEventFlags','and [hl]','jp z, SoftReset',
            'ld a, MAP_REGION_JOHTO','ld [wCurRegion], a',
            'ld [wCurLocalMapID], a', 'ld c, 6',
        )), 'Fly transition must recheck saved unlock and map registry')
    except (OSError,ValueError,KeyError,IndexError) as exc:
        check('fly_source_parse',False,str(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('.'))
    parser.add_argument('--gold-root',type=Path)
    args=parser.parse_args()
    report=audit(args.root,args.gold_root)
    print(json.dumps(report,ensure_ascii=False,indent=2))
    raise SystemExit(report['status']=='FAIL')
