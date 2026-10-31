#!/usr/bin/env python3
"""Fail-closed audit of the six unregistered South Johto runtime-geometry candidates.

No ROM builder, no Gold reference directory, no mutation of the project.
Candidate masks are bit-packed review artifacts, NOT RPP's per-cell runtime policy.
"""
from __future__ import annotations
import argparse,hashlib,json,re,sys
from pathlib import Path
from johto_ilex_217_geometry import expected_runtime as expected_ilex_runtime

NAMES=('AzaleaTown','IlexForestAzaleaGate','IlexForest',
       'Route34IlexForestGate','Route34','GoldenrodCity')
MASK_ACTIVE=('FLOOR','TALL_GRASS','HOP_DOWN','HOP_LEFT','HOP_DOWN_LEFT','HOP_DOWN_RIGHT')

class VerificationError(ValueError):pass

def sha(data):return hashlib.sha256(data).hexdigest()

def verify(root):
    root=Path(root).resolve()
    manifest=root/'docs/JOHTO_BATCH_SOUTH_268/runtime_geometry_manifest.json'
    j=json.loads(manifest.read_text())
    if j.get('schema')!='johto-south-bulk-runtime-geometry-candidate-v1' or j.get('state')!='GEOMETRY_CANDIDATE_ONLY_UNREGISTERED' or j.get('all_runtime_enabled') is not False:
        raise VerificationError('candidate manifest not sealed as unregistered')
    maps=j['maps']
    if [m['name'] for m in maps]!=list(NAMES):raise VerificationError('map names/order mismatch')
    count=0
    portals={}
    for m in maps:
        name=m['name'];w=m['width'];h=m['height']
        if m['runtime_enabled'] is not False or m['status']!='RUNTIME_GEOMETRY_CANDIDATE_UNREGISTERED':
            raise VerificationError(name+': misleading activation')
        if w<1 or h<1 or w>255 or h>255:raise VerificationError('bad dimensions')
        def read(rel):
            p=Path(rel)
            if p.is_absolute() or '..' in p.parts or p.suffix=='.2bpp':raise VerificationError('unsafe candidate path')
            dst=(root/p).resolve()
            if not dst.is_relative_to(root) or not dst.is_file() or dst.is_symlink():raise VerificationError('missing/unsafe candidate')
            return dst.read_bytes()
        blocks=read(m['candidate_blocks']); mask=read(m['candidate_walk_mask'])
        report_data=read(m['candidate_geometry'])
        if len(blocks)!=w*h or sha(blocks)!=m['sha256'] or blocks!=read('maps/johto_pilot/'+name+'.gold.blk'):
            raise VerificationError(name+': Gold runtime candidate blocks drift')
        if len(mask)!=((w*2+7)//8)*(h*2) or sha(mask)!=m['mask_sha256']:
            raise VerificationError(name+': mask changed')
        if sha(report_data)!=m['candidate_geometry_sha256']:
            raise VerificationError(name+': geometry report changed')
        record=json.loads(report_data)
        g=record['gold_geometry'];warps=record['warps'];portals[name]=warps
        if record['map']!=name or g['width_cells']!=w*2 or g['height_cells']!=h*2 or g['mask_size_bytes']!=len(mask):
            raise VerificationError(name+': geometry not aligned')
        if g.get('runtime_ready') is not False or sorted(g.get('walkable_roles',[]))!=sorted(MASK_ACTIVE):
            raise VerificationError('invalid role/approval contract')
        if sum(g['collision_roles'].values())!=w*h*4 or sum(x.bit_count() for x in mask)!=g['blocked_count']:
            raise VerificationError(name+': per-cell collision count mismatch')
        if len(warps)!=m['gold_warps']:raise VerificationError('warp count does not match Gold')
        for idx,warp in enumerate(warps,1):
            if warp.get('index')!=idx or warp.get('runtime_registered') is not False or warp.get('planned_open') != (warp.get('destination_map') in NAMES):
                raise VerificationError(name+': unsafe warp approval')
            if not 0<=warp['x']<w*2 or not 0<=warp['y']<h*2:
                raise VerificationError(name+': warp out of bounds')
        if sum(x['planned_open'] for x in warps)!=m['proposed_warp_registration_count']:
            raise VerificationError(name+': internal warp candidate count mismatch')
        count+=1
    pairs=[]
    for name,warps in portals.items():
        for warp in warps:
            dest=warp['destination_map']
            if dest in portals:
                ord_=warp['destination_gold_warp'];other=portals[dest]
                if not 1<=ord_<=len(other) or other[ord_-1]['destination_map']!=name:
                    raise VerificationError(name+': Gold warp reciprocity failed')
                pairs.append((name,warp['index'],dest,ord_))
    if len(pairs)!=j['total_internal_warp_candidates'] or len(pairs)!=j['reciprocity_verified_count']:
        raise VerificationError('warp summary drift')
    if re.search(r'DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(?!15\b|21\b)\d+', (root/'constants/region_map_constants.asm').read_text()):
        raise VerificationError('unsafe number of active maps')
    active = 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 21' in (root/'constants/region_map_constants.asm').read_text()
    # Keep the active-map version gate strict while allowing the roof-budget
    # follow-up: the ROMX FIX-270 wrapper must pair with the FIX-270 label.
    roofs = root/'engine/johto_south_roofs_269.asm'
    has_270 = roofs.is_file() and 'JohtoSouthTilesetGfxFinalizer270::' in roofs.read_text()
    version_text = (root/'data/game_version.asm').read_text()
    # Registered active versions must retain the same Gold/ILEX-217 resources.
    # FIX-272 only moves the land-collision dispatcher into ROMX, so the strict
    # 21-map source/warp/clone checks below still apply.
    # FIX-276: avoid hard-coded release allowlists that reject each next patch.
    # Still require the correct runtime era: 21-map candidate with ROMX roof
    # wrapper must be 270+, and without wrapper 269+.
    match=re.search(r'^\s*db\s+"FIX-5\.62\.(\d+)@"', version_text, re.M)
    version_num=int(match.group(1)) if match else None
    if (version_num is None or
        (not active and version_num != 267) or
        (active and version_num < (270 if has_270 else 269))):
        raise VerificationError('game version is inconsistent with the active map count')
    for name in NAMES:
        live = root/'maps/johto_pilot'/f'{name}.runtime.blk'
        if active:
            original=(root/'maps/johto_pilot'/f'{name}.gold.blk').read_bytes()
            expected=expected_ilex_runtime(original) if name=='IlexForest' else original
            if not live.is_file() or live.read_bytes()!=expected:
                raise VerificationError(name+': Gold source staging differs from approved Gold/ILEX-217 clones')
            if version_num >= 273 and name in ('IlexForestAzaleaGate','Route34IlexForestGate'):
                # Gate runtime maps are compacted to the accepted NPC-243
                # JOHTO_GATE blockset.  Never alter the Gold source .runtime.blk.
                import hashlib
                target = root/'maps/johto_pilot'/f'{name}.mature.blk'
                approved = {
                    'IlexForestAzaleaGate': 'cc1cea3fabff7f7b4f1cdde7438a2698cfd6bc71936f887a5a19aa04bb2bde0a',
                    'Route34IlexForestGate': '6bf53a71fb3f112149ddb189469b2aa8a4b346c5d4f6556893748dc1e0f44691',
                }[name]
                if not target.is_file() or hashlib.sha256(target.read_bytes()).hexdigest()!=approved:
                    raise VerificationError(name+': compact mature gate blocks do not match accepted NPC-243')
                text=(root/'data/johto_south_runtime.asm').read_text()
                if f'INCBIN "maps/johto_pilot/{name}.mature.blk"' not in text:
                    raise VerificationError(name+': gate loader ignores mature compact blocks')
        if not active and live.exists():
            raise VerificationError(name+': candidate falsely promoted to runtime map')
    return {'candidates':count,'internal_warp_arcs':len(pairs),'runtime_registered':6 if active else 0}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',default='.')
    a=p.parse_args()
    try: print('PASS',json.dumps(verify(a.root),ensure_ascii=False))
    except (VerificationError,ValueError,OSError,KeyError,TypeError) as ex:
        print('FAIL',str(ex),file=sys.stderr);sys.exit(1)
