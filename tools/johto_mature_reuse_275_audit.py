#!/usr/bin/env python3
"""FIX-275 mature NPC-243 equivalence gate: PNG/color, Forest movement,
Cut carry, safe shore, Azalea west border. Static only, no ROM assembly.

Known legacy source: NPC-5.62.243 ILEX-217 / GATE-202; preserved without
replacing current project's region-router or other stable map registrations.
"""
from __future__ import annotations
import hashlib
import re
from pathlib import Path
import argparse

def digest(b:bytes)->str: return hashlib.sha256(b).hexdigest()

def audit(root:Path)->list[str]:
    root=Path(root); errors=[]
    def get(rel): return (root/rel).read_text(encoding='utf8')
    mask=(root/'maps/johto_pilot/IlexForest.mature_blocked_mask.bin').read_bytes()
    # Source baseline frozen by legacy mature NPC branch, not generated Gold roles.
    if len(mask)!=216 or digest(mask)!=MASK_SHA:
        errors.append('forest mature 216-byte blocked mask drift')
    pal=get('color/tilesets/johto_ilex_forest.asm')
    if digest(pal.encode())!=PALETTE_SHA:
        errors.append('forest mature 96-entry tile palette drift')
    mature=get('engine/johto_ilex_mature_runtime_275.asm')
    # FIX-276: RGBDS link failed: runtime used missing legacy map-width names.
    # Local-dot-label preflight cannot detect missing global DEF/EQU symbols.
    constants=get('constants/region_map_constants.asm')
    width_defs=set(re.findall(r'^\s*DEF\s+(JOHTO_[A-Z0-9_]+_WIDTH)\s+EQU\s+', constants, re.M))
    width_refs=set(re.findall(r'\bJOHTO_[A-Z0-9_]+_WIDTH\b', mature))
    for name in sorted(width_refs - width_defs):
        errors.append('undefined mature runtime width constant: '+name)
    for name,expected in (('JOHTO_SOUTH_ILEXFOREST_WIDTH','15'),
                          ('JOHTO_SOUTH_AZALEATOWN_WIDTH','20')):
        if not re.search(r'^\s*DEF\s+'+name+r'\s+EQU\s+'+expected+r'\s*$', constants, re.M):
            errors.append('unexpected/missing Gold map width: '+name)
    for phrase in ('JohtoIlexForestCanStepAhead::','JohtoModernMaskedStep::',
                   'JohtoIlexForestCutTreeCleared::', 'JohtoIlexForestCutTreeFacingTarget:',
                   'INCBIN "maps/johto_pilot/IlexForest.mature_blocked_mask.bin"',
                   'PatchJohtoAzaleaWestGateBorder::'):
        if phrase not in mature: errors.append('missing mature runtime: '+phrase)
    geom=get('engine/johto_south_geometry.asm')
    if not re.search(r'JohtoSouthSpatialStep::(?s:.*?)call JohtoIlexForestCanStepAhead(?s:.*?)\.ordinary',geom):
        errors.append('forest land path does not delegate to mature mask')
    cut=geom.split('.isForestCutBlockCleared',1)[-1] # first occurrence may be call; exact definition below
    if '.isForestCutBlockCleared\n' in geom:
        cut=geom.split('\n.isForestCutBlockCleared\n',1)[1].split('JohtoSouthGoldShoreProbe::',1)[0]
        if 'cp $2d\n    jr z, .cutCleared\n    and a' not in cut:
            errors.append('uncut $0F may return CP-carry as cleared $2D')
    else:
        errors.append('live CUT tile state check missing')
    if not re.search(r'JohtoSouthGoldShoreProbe::(?s:.*?)call JohtoSouthSpatialStep(?s:.*?)scf\s+ret',geom):
        errors.append('Surf landing not delegated to walkable forest land')
    water=re.sub(r";[^\n]*", "", get('engine/johto_violet_field_skills.asm'))
    if not re.search(r'\.southModern\s+callab JohtoSouthGoldWaterProbe\s+jp c, \.water\s+'
                     r'callab JohtoSouthGoldShoreProbe\s+jp c, \.floorShore\s+jp \.shore', water):
        errors.append('Surf can enter but may not be able to return safely')
    main=get('main.asm')
    if 'INCLUDE "engine/johto_ilex_mature_runtime_275.asm"' not in main:
        errors.append('mature banked runtime not in main.asm')
    home=get('home/overworld.asm')
    block=home.split('LoadTileBlockMap::',1)[1].split('LoadNorthSouthConnectionsTileMap::',1)[0]
    if not re.search(r'\.done\s+; FIX-279:(?s:.*?)callab PatchJohtoSouthBordersAfterBlockLoad\s+ret',block):
        errors.append('Azalea outdoor west extension is not applied AFTER blockmap load')
    if not re.search(r'PatchJohtoSouthBordersAfterBlockLoad::\s+call PatchJohtoAzaleaWestGateBorder\s+call PatchJohtoGoldenrodNorthBorder\s+jp PatchJohtoRoute35SouthBorder', mature):
        errors.append('Azalea west border handler lost from common post-blockmap dispatcher')
    if 'jp nz,.noCollision' not in home:
        errors.append('owner-tested JP reverted')
    if any((root/'gfx/tilesets').glob('johto_ilex_forest.2bpp')):
        errors.append('generated 2bpp delivered instead of PNG')
    return errors

# Frozen values from the uploaded NPC-5.62.243 reference, not from current code.
MASK_SHA = '8d219724d41f029d63ce99fa6dabf9ad048dfa6e6e7eb24d5a6345d8695ce7db'
PALETTE_SHA = '44d2218a4051dfbd6b382921a731f692b11e4e3e57dbaaca1abb3cd63f310832'

if __name__=='__main__':
    a=argparse.ArgumentParser(); a.add_argument('--root',type=Path,default=Path.cwd()); o=a.parse_args()
    try: issues=audit(o.root)
    except (OSError,IndexError,ValueError) as exc: issues=[str(exc)]
    if issues:
        print('FAIL: '+ '\nFAIL: '.join(issues)); raise SystemExit(1)
    print('PASS: mature ILEX mask/Cut/palette, safe Surf landing, west border, PNG-only')
