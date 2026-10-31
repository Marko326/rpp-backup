#!/usr/bin/env python3
"""Fail-closed coverage gate for ALL *registered* Johto direct map connections.

This does not auto-repair seams and does not simulate VRAM. It forces every
new directed connection to receive an independently reviewed rendering / edge
contract before the comprehensive audit can pass. It also checks the five N/S narrow-to-wide and two E/W short-to-tall
connections against independently reviewed display-strip/source contracts.
Changing terrain widths or adding an edge without review fails closed.
"""
from __future__ import annotations
import json
import re
from pathlib import Path

# Separate from EXPECTED_CONNECTIONS in the migration audit on purpose.
# Adding an edge to the registry or that list alone is NOT sufficient to pass.
APPROVED = {
    ('NewBarkTown','WEST','Route29'),('Route29','EAST','NewBarkTown'),
    ('Route29','WEST','CherrygroveCity'),('CherrygroveCity','EAST','Route29'),
    ('CherrygroveCity','NORTH','Route30'),('Route30','SOUTH','CherrygroveCity'),
    ('Route30','NORTH','Route31'),('Route31','SOUTH','Route30'),
    ('Route31','WEST','VioletCity'),('VioletCity','EAST','Route31'),
    ('VioletCity','SOUTH','Route32'),('Route32','NORTH','VioletCity'),
    ('Route33','WEST','AzaleaTown'),('AzaleaTown','EAST','Route33'),
    ('Route34','NORTH','GoldenrodCity'),('GoldenrodCity','SOUTH','Route34'),
    ('Route35','NORTH','Route36'),('Route36','SOUTH','Route35'),
    ('Route36','EAST','VioletCity'),('VioletCity','WEST','Route36'),
}
# Distinct Gold offsets mean a blanket 'source width + 3' would be wrong.
# The narrow-to-wider cases each require an explicitly inspected runtime width.
NARROW_SEAM_CONTRACTS = {
    ('Route30','NORTH','Route31'): (
        'data/johto_pilot_map_headers.asm',
        'JohtoPilotRoute30RuntimeHeader::','JohtoPilotRoute30RuntimeHeaderEnd::',
        'db JOHTO_ROUTE_30_WIDTH ; exactly ten columns',
        'dw JohtoPilotRoute31RuntimeBlocks + JOHTO_ROUTE_31_WIDTH * (JOHTO_ROUTE_31_HEIGHT - 3) + 10'),
    ('Route30','SOUTH','CherrygroveCity'): (
        'data/johto_pilot_map_headers.asm',
        'JohtoPilotRoute30RuntimeHeader::','JohtoPilotRoute30RuntimeHeaderEnd::',
        'db JOHTO_ROUTE_30_WIDTH\n    db JOHTO_CHERRYGROVE_WIDTH',
        'dw JohtoPilotCherrygroveRuntimeBlocks + 5'),
    ('Route32','NORTH','VioletCity'): (
        'data/johto_route32_runtime.asm',
        'JohtoPilotRoute32RuntimeHeader::','JohtoPilotRoute32RuntimeHeaderEnd::',
        'db JOHTO_ROUTE_32_WIDTH + 3 ; visual margin needed for city beyond Route32 east edge',
        'dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * (JOHTO_VIOLET_CITY_HEIGHT - 3)'),
    ('Route34','NORTH','GoldenrodCity'): (
        'data/johto_south_runtime.asm',
        'JohtoSouthRoute34RuntimeHeader::','JohtoSouthRoute34HeaderEnd::',
        'db 10\n    db 20',
        'dw JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 5'),
    ('Route35','NORTH','Route36'): (
        'data/johto_north_runtime_283.asm',
        'JohtoNorthRoute35RuntimeHeader::','JohtoNorthRoute35HeaderEnd::',
        'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10',
        'dw JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)'),
}
# Same failure class exists on horizontal transitions when the destination is
# taller than the current map. Review currently active edges explicitly;
# future short-to-tall E/W edges must provide a contract before acceptance.
SIDE_SEAM_CONTRACTS = {
    ('Route31','WEST','VioletCity'): (
        'data/johto_pilot_map_headers.asm',
        'JohtoPilotRoute31RuntimeHeader::','JohtoPilotRoute31RuntimeHeaderEnd::',
        'db JOHTO_ROUTE_31_HEIGHT\n    db JOHTO_VIOLET_CITY_WIDTH',
        'dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * 9 + JOHTO_VIOLET_CITY_WIDTH - 3'),
    ('Route36','EAST','VioletCity'): (
        'data/johto_ruins_north_runtime.asm',
        'JohtoPilotRoute36RuntimeHeader::','JohtoPilotRoute36RuntimeHeaderEnd::',
        'db JOHTO_ROUTE_36_HEIGHT ; map rows (the border is refilled by 3 extra rows)\n    db JOHTO_VIOLET_CITY_WIDTH',
        'dw JohtoRoute36EastVioletMirror'),
}
DIRECTIONS = {'NORTH':'SOUTH','SOUTH':'NORTH','WEST':'EAST','EAST':'WEST'}


def audit(project: Path, active_ids: list[int], layouts: dict[str,tuple[int,int]],
          registry_override: str | None = None, overrides: dict[str,str] | None = None) -> dict:
    p=Path(project); overrides=overrides or {}; errors=[]; checks=[]
    def test(name, ok, detail=''):
        checks.append({'check':name,'status':'PASS' if ok else 'FAIL','detail':detail})
        if not ok: errors.append(name+(': '+detail if detail else ''))
    def read(path):return overrides.get(path, (p/path).read_text())
    try:
        # Both active ID order and map layout insertion order belong to the
        # production migration audit. Fail if that contract itself drifts.
        test('active_id_layout_alignment',len(active_ids)==len(layouts),
             f'IDs={len(active_ids)} layouts={len(layouts)}')
        by_id=dict(zip(active_ids,layouts))
        defs=read('constants/region_map_constants.asm')
        id_by_const={m.group(1):int(m.group(2)) for m in re.finditer(
            r'^DEF\s+(JOHTO_\w+_LOCAL_ID)\s+EQU\s+(\d+)\b',defs,re.M)}
        src=(registry_override if registry_override is not None else
             read('data/johto_pilot_source_resources.asm'))
        body=src.split('JohtoPilotSourceConnections::',1)[1].split('JohtoPilotSourceConnectionsEnd::',1)[0]
        rows=re.findall(r'^\s*db\s+MAP_REGION_JOHTO,\s*(JOHTO_\w+_LOCAL_ID),\s*'
                        r'(NORTH|SOUTH|WEST|EAST),\s*MAP_REGION_JOHTO,\s*'
                        r'(JOHTO_\w+_LOCAL_ID)\s*(?:;.*)?$',body,re.M)
        entries=[]; unrecognized=[]
        for a,d,b in rows:
            if a not in id_by_const or b not in id_by_const or id_by_const[a] not in by_id or id_by_const[b] not in by_id:
                unrecognized.append((a,d,b));continue
            entries.append((by_id[id_by_const[a]],d,by_id[id_by_const[b]]))
        test('all_registry_rows_resolved',not unrecognized and len(rows)==len([
            x for x in body.splitlines() if x.strip().startswith('db MAP_REGION_JOHTO,')]),
            f'unrecognized={unrecognized[:3]} parsed={len(rows)}')
        actual=set(entries)
        test('new_connection_requires_visual_review',not(actual-APPROVED),
             'Unreviewed active seams='+str(sorted(actual-APPROVED)))
        test('approved_connections_not_lost',not(APPROVED-actual),
             'Removed review baseline='+str(sorted(APPROVED-actual)))
        test('registered_seams_unique',len(entries)==len(actual),
             f'registry={len(entries)} unique={len(actual)}')
        test('all_registered_seams_bidirectional',all((b,DIRECTIONS[d],a) in actual
             for a,d,b in actual))
        # Calculate risk *from all active widths*; no per-map selection here.
        risky={(a,d,b) for a,d,b in actual if d in ('NORTH','SOUTH') and layouts[b][0]>layouts[a][0]}
        test('narrow_to_wide_seams_have_review_contracts',not(risky-set(NARROW_SEAM_CONTRACTS)),
             'New narrow-to-wide seams needing viewport/copy-width review: '
             +str(sorted(risky-set(NARROW_SEAM_CONTRACTS))))
        test('risk_contracts_still_registered',not(set(NARROW_SEAM_CONTRACTS)-risky),
             str(sorted(set(NARROW_SEAM_CONTRACTS)-risky)))
        # East/west strips are measured in rows rather than columns. A newly
        # registered edge from a short map into a taller map is also a preview
        # risk, even if there is no N/S narrow-to-wide connection.
        risky_side={(a,d,b) for a,d,b in actual
                    if d in ('EAST','WEST') and layouts[b][1]>layouts[a][1]}
        test('short_to_tall_side_seams_have_review_contracts',
             not(risky_side-set(SIDE_SEAM_CONTRACTS)),
             'New E/W short-to-tall seams requiring strip/offset review: '
             +str(sorted(risky_side-set(SIDE_SEAM_CONTRACTS))))
        test('side_risk_contracts_still_registered',
             not(set(SIDE_SEAM_CONTRACTS)-risky_side),
             str(sorted(set(SIDE_SEAM_CONTRACTS)-risky_side)))
        test('all_high_risk_seams_have_distinct_contracts',
             not(risky.union(risky_side)-(set(NARROW_SEAM_CONTRACTS)|set(SIDE_SEAM_CONTRACTS))))
        for edge,(path,start,end,width,source) in {**NARROW_SEAM_CONTRACTS, **SIDE_SEAM_CONTRACTS}.items():
            text=read(path)
            segment=text.split(start,1)[1].split(end,1)[0]
            test('preview_width_and_source_reviewed_'+edge[0]+'_'+edge[1],
                 segment.count(width)==1 and segment.count(source)==1,
                 f'{edge[0]} {edge[1]} -> {edge[2]} exact reviewed strip length and source offset')
    except (OSError,KeyError,ValueError,IndexError) as e:
        test('coverage_source_parse',False,str(e))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks':checks,'errors':errors}

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--project',type=Path,default=Path('.'))
    args=parser.parse_args()
    try:
        from johto_pilot_migration_audit import EXPECTED_ACTIVE_IDS, MAP_LAYOUTS
    except ImportError:
        from tools.johto_pilot_migration_audit import EXPECTED_ACTIVE_IDS, MAP_LAYOUTS
    result=audit(args.project,EXPECTED_ACTIVE_IDS,MAP_LAYOUTS)
    print(json.dumps(result,ensure_ascii=False,indent=2))
    raise SystemExit(bool(result['errors']))
