#!/usr/bin/env python3
"""MAP-293 fail-closed source onboarding for Route37/Ecruteak and westward candidates.

Checks *immutable staged input*, not playability. A stage manifest must never be
mistaken for a runtime header/warp/bank/collision approval.  Optional Gold root
allows original source byte and reciprocal offset comparison.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

MANIFEST = 'data/johto_next_corridor_293_manifest.json'
MAPS = (
    ('Route37', 21, 10, 9, 'johto', 'maps/Route37.blk', 'c07e00002261aa23b2f6405c0941c6d1a0d47ad0cfb23ea4e434d57db5178c88'),
    ('EcruteakCity', 22, 20, 18, 'johto', 'maps/EcruteakCity.blk', '4c6c7cfa7cb52167f6f806c6ca96746adf9cffc6719499c3ef125f41fe22bbf6'),
    ('Route38EcruteakGate', 23, 5, 4, 'gate', 'maps/EastWestGate.blk', '4345b9806ded35bc2b76429a281e9391c0c614597f4ccf547a89edee84d5160c'),
    ('Route38', 24, 20, 9, 'johto', 'maps/Route38.blk', '432d51119b446a2fcbc14f21f24882d1c600373a634e82b98ae6d089af7b04e1'),
)
SEAMS = (
    ('Route36', 'Route37', 'north', 10), ('Route37', 'Route36', 'south', -10),
    ('Route37', 'EcruteakCity', 'north', -5), ('EcruteakCity', 'Route37', 'south', 5),
    ('EcruteakCity', 'Route38', 'west', 5), ('Route38', 'EcruteakCity', 'east', -5),
)
OPPOSITE = {'north':'south','south':'north','east':'west','west':'east'}

def audit(project: Path, gold_root: Path | None = None, *, overrides: dict[str, bytes] | None = None) -> dict:
    root = Path(project)
    gold = Path(gold_root) if gold_root is not None else None
    overrides = overrides or {}
    checks: list[dict] = []
    errors: list[str] = []
    warnings: list[str] = []
    def check(name: str, condition: bool, detail: str = '') -> None:
        checks.append({'check':name, 'status':'PASS' if condition else 'FAIL', 'detail':detail})
        if not condition: errors.append(name + (': '+detail if detail else ''))
    def read(path: str) -> bytes:
        if path in overrides:return overrides[path]
        return (root/path).read_bytes()
    try:
        m = json.loads(read(MANIFEST))
        check('stage_schema', m.get('schema') == 'johto-next-corridor-source-gate-v1')
        check('stage_not_runtime_approved', m.get('runtime_approved') is False and m.get('active_map_count_unchanged') == 26)
        rows = m['maps']
        check('four_maps_fixed_stable_order', [r['map'] for r in rows] == [n for n,*_ in MAPS])
        if len(rows) != len(MAPS):raise ValueError('stage records not exactly four')
        for rec, (name, stable_id, w, h, tileset, goldfile, goldhash) in zip(rows, MAPS):
            check(name+'_identity', (rec['map'],rec['stable_id'],rec['width'],rec['height'],rec['gold_tileset'],rec['gold_source']) ==
                  (name,stable_id,w,h,tileset,goldfile) and rec.get('runtime_approved') is False)
            paths = rec['assets']
            check(name+'_candidate_asset_keys', 'gold_blk' in paths and 'gold_collision_candidate' in paths)
            for kind, info in paths.items():
                rel = info['path']; expected = f'maps/johto_pilot/candidates293/{name}.'
                check(name+'_'+kind+'_isolated_path', rel.startswith(expected) and '..' not in Path(rel).parts)
                try:data = read(rel)
                except OSError:check(name+'_'+kind+'_exists',False,rel);continue
                check(name+'_'+kind+'_sha256', len(data)==info['bytes'] and hashlib.sha256(data).hexdigest() == info['sha256'],rel)
                if kind=='gold_blk':check(name+'_gold_frozen_sha', len(data)==w*h and hashlib.sha256(data).hexdigest()==goldhash)
                if kind=='gold_collision_candidate':check(name+'_gold_mask_dimensions',len(data)==((2*w+7)//8)*(2*h))
                if kind=='npc_mature_mask':check(name+'_npc_mask_dimensions',len(data)==((2*w+7)//8)*(2*h))
            if 'gold_collision_candidate' in paths and 'npc_mature_mask' in paths:
                candidate=read(paths['gold_collision_candidate']['path'])
                npc=read(paths['npc_mature_mask']['path'])
                equal = candidate == npc
                check(name+'_mask_comparison_recorded', rec.get('npc_vs_gold_mask_equal') is equal)
                if not equal:warnings.append(name+': NPC mature passability mask differs from raw Gold candidate; must inspect per-cell before runtime activation')
            if gold is not None:
                source = gold/goldfile
                check(name+'_gold_reference_present', source.is_file(),str(source))
                if source.is_file():
                    check(name+'_gold_reference_equal', read(paths['gold_blk']['path']) == source.read_bytes())
        actual_seams=[(s['source'],s['target'],s['direction'],s['offset']) for s in m['seams']]
        check('six_source_seams_exact', actual_seams == list(SEAMS))
        check('source_seams_bidirectional', all((b,a,OPPOSITE[d],-ofs) in actual_seams for a,b,d,ofs in actual_seams))
        # Existing game must remain exactly the 26 accepted maps: candidate
        # source files must not be interpreted as approval to activate a new ID.
        constants = read('constants/region_map_constants.asm').decode()
        headers = read('data/johto_header_descriptors.asm').decode()
        links = read('data/johto_pilot_source_resources.asm').decode()
        check('staging_does_not_advance_game_version',re.search(r'^DEF NUM_JOHTO_ACTIVE_MAPS EQU (?:26|28)$',constants,re.M) is not None)
        body=headers.split('JohtoHeaderDescriptors::',1)[1].split('JohtoHeaderDescriptorsEnd::',1)[0]
        check('staging_not_registered_in_live_headers', all(name+'RuntimeHeader' not in body for name,*_ in MAPS) if 'NUM_JOHTO_ACTIVE_MAPS EQU 26' in constants else (all('Johto'+name+'RuntimeHeader' in body for name in ('Route37','Ecruteak')) and not any('Johto'+name+'RuntimeHeader' in body for name in ('Route38','Route38EcruteakGate'))))
        connection_body=links.split('JohtoPilotSourceConnections::',1)[1].split('JohtoPilotSourceConnectionsEnd::',1)[0]
        check('no_unapproved_live_connection',not any('JOHTO_ROUTE_38_LOCAL_ID' in line for line in connection_body.splitlines() if line.strip().startswith('db ')) if 'NUM_JOHTO_ACTIVE_MAPS EQU 28' in constants else not any('JOHTO_ROUTE_37_LOCAL_ID' in line or 'JOHTO_ECRUTEAK_CITY_LOCAL_ID' in line or 'JOHTO_ROUTE_38_LOCAL_ID' in line for line in connection_body.splitlines() if line.strip().startswith('db ')))
        if gold is not None:
            reg=(gold/'data/maps/maps.asm')
            attr=(gold/'data/maps/attributes.asm')
            check('gold_registration_tables_present',reg.is_file() and attr.is_file())
            if reg.is_file() and attr.is_file():
                maps=reg.read_text();attrs=attr.read_text()
                for name,_,_,_,t,_,_ in MAPS:
                    check('gold_'+name+'_tileset', re.search(r'^\s*map\s+'+re.escape(name)+r'\s*,\s*TILESET_'+t.upper()+r'\s*,',maps,re.M) is not None)
                for a,b,d,ofs in SEAMS:
                    section=re.search(r'(?ms)^\s*map_attributes\s+'+re.escape(a)+r'\s*,.*?(?=^\s*map_attributes\b|\Z)',attrs)
                    rule = re.search(r'^\s*connection\s+'+re.escape(d)+r'\s*,\s*'+re.escape(b)+r'\s*,\s*[A-Z_0-9]+\s*,\s*'+re.escape(str(ofs))+r'\s*$',section.group() if section else '',re.M)
                    check('gold_seam_'+a+'_'+d+'_'+b,rule is not None,f'offset={ofs}')
        else:
            warnings.append('No Gold directory provided: bundled SHA-256 verified, external Gold origin comparison not executed')
        check('not_a_playable_release', m.get('runtime_approved') is False and len(m.get('blocked_until_full_runtime_review',[])) >= 6)
    except (ValueError, KeyError, TypeError, UnicodeError, OSError, IndexError) as exc:
        check('stage_source_parse', False, str(exc))
    return {'status':'PASS_SOURCE_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,'warnings':warnings,
            'runtime_approved':False,'build_performed':False}

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--project',type=Path,default=Path('.'))
    ap.add_argument('--gold-root',type=Path)
    ap.add_argument('--json-out',type=Path)
    args=ap.parse_args()
    report=audit(args.project,args.gold_root)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True,exist_ok=True)
        args.json_out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'status':report['status'],'passed':sum(x['status']=='PASS' for x in report['checks']),
          'failed':len(report['errors']),'warnings':report['warnings'],'errors':report['errors']},ensure_ascii=False,indent=2))
    raise SystemExit(bool(report['errors']))
