"""REF-310: Audit the 10 active Gold gatehouse palettes, not their geometry.

Gold reference is optional for local standalone checks; when supplied, every
Gold original Gate palette tag, color, and active compact tile is cross-checked.
This is source-level only; no ROM build or rendered device colors are asserted.
"""
from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path

GOLD_INDOOR = {
    'GRAY': [(30,28,26), (19,19,19), (13,13,13), (7,7,7)],
    'RED': [(30,28,26), (31,19,24), (30,10,6), (7,7,7)],
    'GREEN': [(18,24,9), (15,20,1), (9,13,0), (7,7,7)],
    'WATER': [(30,28,26), (15,16,31), (9,9,31), (7,7,7)],
    'BROWN': [(26,24,17), (21,17,7), (16,13,3), (7,7,7)],
}
PALETTES = {'GRAY':'INDOOR_GRAY', 'RED':'INDOOR_RED', 'GREEN':'JOHTO_GATE_GOLD_GREEN',
            'WATER':'INDOOR_BLUE', 'BROWN':'JOHTO_GATE_GOLD_BROWN'}
PARK_IDS = {104, 105}


def palette_tags(text):
    return [item.strip() for line in text.splitlines() if line.strip().startswith('tilepal ')
            for item in line.split(';',1)[0].split(',')[1:]]


def color_bands(text):
    out={}; name=None
    for line in text.splitlines():
        hit=re.match(r'\s*;\s*0x[0-9a-fA-F]+:\s*(\w+)',line)
        if hit: name=hit.group(1); out[name]=[]
        m=re.match(r'\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',line)
        if m and name: out[name].append(tuple(int(x) for x in m.groups()))
    return out


def palette_sets(text):
    entries=[]
    for line in text.splitlines():
        line=line.split(';',1)[0].strip()
        if line.startswith('db '): entries.extend(x.strip() for x in line[3:].split(','))
    return entries


def audit(root, gold=None):
    root=Path(root)
    checks=[]; errors=[]
    def ck(label, ok, detail=''):
        checks.append({'check':label,'status':'PASS' if ok else 'FAIL'})
        if not ok: errors.append(f'{label}: {detail}')
    manifest=json.loads((root/'tools/johto_gatehouse_profiles_303.json').read_text())
    profiles=manifest['active_gatehouses']
    ids={g['stable_id'] for g in profiles}
    ck('ten_gatehouses_and_park_ids',len(profiles)==13 and len(ids)==13 and
       {g['stable_id'] for g in profiles if g['gold_environment']=='INDOOR'}==PARK_IDS)
    source=(root/'data/johto_pilot_runtime_assets.asm').read_text()
    ck('park_gate_runtime_tileset_registration',
       'db JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID, JOHTO_PARK_GATE' in source and
       'db JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID, JOHTO_PARK_GATE' in source)
    ck('ordinary_gate_runtime_count',sum(bool(re.search(r'\bdb\s+JOHTO_\w+_LOCAL_ID,\s+JOHTO_GATE\b',line))
          for line in source.splitlines()) == len(ids-PARK_IDS))
    defs=(root/'color/data/map_palette_sets.asm').read_text()
    full=palette_sets(defs)
    ck('palette_set_stride',len(full)==38*8, f'{len(full)} entries')
    standard=full[30*8:31*8]; park=full[36*8:37*8]
    ck('both_gate_tilesets_share_exact_gold_colors',standard==park and
       all(park[{'GRAY':0,'RED':1,'GREEN':2,'WATER':3,'BROWN':5}[tag]]==sym
           for tag,sym in PALETTES.items()),f'standard={standard}, park={park}')
    cm=color_bands((root/'color/data/map_palettes.asm').read_text())
    for tag,pal in PALETTES.items():
        ck(f'gold_indoor_rgb_{tag.lower()}',cm.get(pal)==GOLD_INDOOR[tag],f'{pal}: {cm.get(pal)}')
    park_tags=palette_tags((root/'color/tilesets/johto_park_gate.asm').read_text())
    normal_tags=palette_tags((root/'color/tilesets/johto_gate.asm').read_text())
    ck('two_tile_maps_are_complete',len(park_tags)==96 and len(normal_tags)==96)
    ck('park_gate_tileset_uses_gold_indoor',
       'tileset JohtoParkGate_Block, JohtoParkGate_GFX, Gate_Coll, $FF,$FF,$FF, $FF, INDOOR'
        in (root/'data/tileset_headers.asm').read_text())
    if gold is not None:
        gold=Path(gold)
        base=gold/'gfx/tilesets'
        gold_tags=palette_tags((base/'gate_palette_map.asm').read_text())
        ck('park_96_tiles_match_gold_tags',park_tags==gold_tags,
           'park tileset tag sequence differs from Gold')
        ck('gold_original_96_tag_count',len(gold_tags)==96)
        ck('park_gate_art_equals_original_gold',
           (root/'gfx/tilesets/johto_park_gate.png').read_bytes()==(base/'gate.png').read_bytes())
        # Compare *drawn tile artwork*, not compact index IDs, because JOHTO_GATE reorders
        # the original tiles; matching same-pixel duplicate tiles must not be ambiguous.
        from PIL import Image
        def split_tiles(path):
            im=Image.open(path).convert('L')
            return [im.crop((x,y,x+8,y+8)).tobytes()
                    for y in range(0,im.height,8) for x in range(0,im.width,8)]
        original=split_tiles(base/'gate.png')
        compact=split_tiles(root/'gfx/tilesets/johto_gate.png')
        bad=[]
        for i,tile in enumerate(compact):
            matches=[idx for idx,gold_tile in enumerate(original) if gold_tile==tile]
            if not matches or any(gold_tags[idx]!=normal_tags[i] for idx in matches):
                bad.append(i)
        ck('ordinary_gate_compact_art_tags_match_gold',not bad and len(compact)==96,
           f'wrong/missing compact tile indices: {bad}')
        gold_pal=(base/'bg_tiles.pal').read_text()
        indoor=gold_pal.split('; indoor',1)[-1].split('; overworld water',1)[0]
        rows={line.split(';')[-1].strip():[tuple(map(int,t)) for t in re.findall(r'(\d+),\s*(\d+),\s*(\d+)',line)]
              for line in indoor.splitlines() if line.strip().startswith('RGB ')}
        for tag in PALETTES:
            ck(f'gold_reference_indoor_{tag.lower()}',rows.get(tag.lower())==GOLD_INDOOR[tag])
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,
            'active_gatehouse_ids':sorted(ids),'park_gate_ids':sorted(PARK_IDS),
            'gold_source_compared':gold is not None,'rom_built':False,'device_verified':False}


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[1])
    p.add_argument('--gold-root',type=Path,default=None)
    p.add_argument('--json-out',type=Path,default=None)
    args=p.parse_args()
    gold=args.gold_root or os.getenv('JOHTO_GOLD_SOURCE') or os.getenv('GOLD_SOURCE_ROOT')
    result=audit(args.project,gold)
    if args.json_out:
        args.json_out.parent.mkdir(parents=True,exist_ok=True)
        args.json_out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'status':result['status'],'checks':len(result['checks']),'errors':result['errors'],
                      'gold_source_compared':result['gold_source_compared']},ensure_ascii=False))
    return 0 if not result['errors'] else 1

if __name__=='__main__':
    raise SystemExit(main())
