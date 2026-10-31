#!/usr/bin/env python3
"""Developer-owned Surf edit-check; NEVER hooked to the player's ROM Makefile.

Run immediately after changing ANY Johto map, field skill or collision dispatch,
and again before creating a patch. Requires original Gold for independent checks;
no ROM build, no game modification, no background process. Demonstrates that
critical missing-input failures are rejected through in-memory fault injection.
This is static verification, NOT a device emulator.

  python tools/johto_surf_dev_check_296.py --project . --gold-root /path/to/pokegold-master
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
from johto_surf_build_gate_296 import audit, HOME
from johto_surf_coverage_audit import read_active_maps


def review(project: Path, gold_root: Path) -> dict:
    project, gold_root = Path(project), Path(gold_root)
    result = audit(project, gold_root)
    faults = {}
    # A new map requires deliberate review, irrespective of whether the developer
    # remembered to add Surf entries. This catches maps with unknown water status.
    active = read_active_maps(project)
    fake = {'map':'__UnreviewedMap296__','stable_id':254,
            'source_asset':active[-1]['source_asset'],'exact_gold':False}
    new_map = audit(project, gold_root, active_override=active+[fake])
    faults['new_map_unreviewed_rejected'] = (
        new_map['status']=='FAIL' and
        any('NEW ACTIVE MAP NOT SURF-REVIEWED' in x for x in new_map['errors']))
    # Break the REAL ROM0->ROMX Surf movement handoff, rather than adding an
    # inert comment. The auditor must reject this before any map is released.
    text=(project/HOME).read_text(encoding='utf8')
    needle='callab JohtoOverworldSurfDecision'
    if needle not in text:
        faults['broken_move_handoff_rejected']=False
    else:
        broken=text.replace(needle,'nop ; fault-injected for developer check',1)
        probe=audit(project,gold_root,overrides={HOME:broken})
        faults['broken_move_handoff_rejected'] = (
            probe['status']=='FAIL' and
            any('ROM0 does not consume Gold swim/shore flags' in x for x in probe['errors']))
    return {
        'status':'PASS_STATIC_ONLY' if result['status']=='PASS_STATIC_ONLY' and all(faults.values()) else 'FAIL',
        'active_maps':result.get('active_maps'),
        'water_maps':result.get('water_maps'),
        'errors':result.get('errors',[])+[f'negative self-test failed: {name}' for name, ok in faults.items() if not ok],
        'fault_injection':faults,
        'developer_executed':True,
        'rom_built':False,'device_verified':False,
    }


def main() -> int:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project',type=Path,default=Path.cwd())
    ap.add_argument('--gold-root',type=Path,required=True,
                    help='Independent Gold source is mandatory for developer signoff')
    ap.add_argument('--json-out',type=Path,help='Optional review evidence for handoff')
    args=ap.parse_args()
    try:
        record=review(args.project,args.gold_root)
    except (OSError,ValueError,KeyError,IndexError,TypeError) as exc:
        record={'status':'FAIL','errors':[str(exc)],'developer_executed':True,
                'rom_built':False,'device_verified':False}
    if args.json_out:
        args.json_out.write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('TOOL-296 DEVELOPER SURF REVIEW:',record['status'])
    print('Active maps:',record.get('active_maps'),'Water maps:',record.get('water_maps'))
    for msg in record.get('errors',[]): print('  FAIL:',msg)
    for test,passed in record.get('fault_injection',{}).items():
        print('  FAULT-INJECTION:',test,'PASS' if passed else 'FAIL')
    print('This check is for the developer before delivering a patch; it never builds or plays the ROM.')
    return 0 if record['status']=='PASS_STATIC_ONLY' else 1

if __name__=='__main__': raise SystemExit(main())
