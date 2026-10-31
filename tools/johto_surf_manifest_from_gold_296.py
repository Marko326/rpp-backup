#!/usr/bin/env python3
"""Create a *review candidate* Surf manifest from the real Gold source.

Only --write explicitly updates the locked manifest. Ordinary Makefile
preflight never invokes this script or auto-approves a newly activated map.
Updating the manifest never exempts water-bearing maps from live Surf checks.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from johto_surf_coverage_audit import read_active_maps
from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_build_gate_296 import MANIFEST


def generate(root: Path, gold_root: Path) -> dict:
    root = Path(root)
    gold = GoldCollisionIndex(gold_root)
    entries = []
    for m in read_active_maps(root):
        name = m['map']
        cells = gold.cells(name)
        path = m['source_asset']
        content = (root/path).read_bytes()
        if m['exact_gold'] and content != (gold.gold/'maps'/gold.block_files[name]).read_bytes():
            raise ValueError(name+': source .blk does not match Gold original')
        water = sorted((v['y'],v['x']) for v in cells.values() if v['role']=='WATER')
        entries.append({'map':name,'stable_id':m['stable_id'],'source_asset':path,
                        'source_sha256':hashlib.sha256(content).hexdigest(),
                        'water_yx':[list(p) for p in water]})
    return {'schema_version':1,
            'source':'GoldCollisionIndex original Gold + frozen active source SHA256',
            'policy':'Every active map must match; changes require Gold-verified reapproval, never auto-fix or silently skip',
            'maps':entries}


def main() -> int:
    cli=argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--root',type=Path,default=Path.cwd())
    cli.add_argument('--gold-root',required=True,type=Path)
    cli.add_argument('--write',action='store_true',help='explicitly replace checked-in manifest (requires Gold)')
    args=cli.parse_args()
    try:
        data=generate(args.root,args.gold_root)
        target=args.root/MANIFEST
        result=json.dumps(data,ensure_ascii=False,indent=2)+'\n'
        if args.write:
            target.write_text(result,encoding='utf8')
            print(f'WROTE {target}; NOW rerun Surf build gate. Manifest alone does NOT activate Surf.')
        else:
            print(result)
            print('PREVIEW ONLY: use --write after review; game code is never modified.')
    except (OSError,ValueError,KeyError) as exc:
        print('SURF MANIFEST REJECTED:',exc)
        return 1
    return 0
if __name__=='__main__': raise SystemExit(main())
