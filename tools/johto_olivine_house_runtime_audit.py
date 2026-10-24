#!/usr/bin/env python3
"""Olivine house source-only contract against Gold; NOT ROM/phone acceptance.

One exact door is opened, never all city houses. Never infer physical movement
from a syntactically valid Warp alone; mask, facing and landing need evidence.
"""
from __future__ import annotations
import argparse
import hashlib
import re
from pathlib import Path
from PIL import Image
from johto_indoor_tiles_converter import strict_2bpp

HOUSE='JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID'
CITY='JOHTO_OLIVINE_CITY_LOCAL_ID'



def audit_portal_short_branches(home: str, *, entry: str = 'IsJohtoSouthGatePortal::',
                                end: str = 'MapEntryAfterBattle::') -> list[str]:
    """Check actual GB instruction offsets for the ROM0 portal selector.

    This is deliberately a small, fail-closed instruction-size audit of ONE
    function, not a claim to replace RGBDS or validate the whole ROM.
    If that function grows a new instruction, teach the auditor its size first.
    """
    try:
        source = home.split(entry, 1)[1].split(end, 1)[0]
    except IndexError:
        return ['ROM0 portal selector function boundaries missing']
    labels: dict[str, int] = {}
    jumps: list[tuple[int, str]] = []
    pc = 0
    for raw in source.splitlines():
        line = raw.split(';', 1)[0].strip()
        if not line:
            continue
        if line.endswith(':') or (line.startswith('.') and ' ' not in line):
            label = line.rstrip(':')
            if label in labels:
                return ['duplicate portal selector label: ' + label]
            labels[label] = pc
            continue
        match = re.fullmatch(r'(ld|cp|jr|jp|and|ret|scf)\s*(.*)', line, re.I)
        if not match:
            return ['unrecognized ROM0 portal instruction: ' + line]
        op, operand = match.group(1).lower(), match.group(2).strip()
        if op == 'ld':
            if re.fullmatch(r'b\s*,\s*a', operand, re.I):
                length = 1
            elif re.fullmatch(r'a\s*,\s*\[(wCurMap|wCurRegion|wCurLocalMapID|wXCoord|wYCoord|wPlayerDirection)\]', operand, re.I):
                length = 3
            elif re.fullmatch(r'a\s*,\s*[A-Za-z_][A-Za-z_0-9]*', operand):
                length = 2
            else:
                return ['unrecognized ROM0 portal LD size: ' + line]
        elif op == 'cp':
            if operand.lower() == 'b':
                length = 1
            elif not re.fullmatch(r'[A-Za-z_][A-Za-z_0-9]*|\d+|\$[\da-fA-F]+', operand):
                return ['unrecognized ROM0 portal CP size: ' + line]
            else:
                length = 2
        elif op in ('jr', 'jp'):
            if not re.fullmatch(r'(?:(?:nz|z|nc|c)\s*,\s*)?\.?[A-Za-z_][A-Za-z_0-9]*', operand, re.I):
                return ['unrecognized ROM0 portal branch: ' + line]
            length = 2 if op == 'jr' else 3
            if op == 'jr':
                jumps.append((pc + length, operand.split(',')[-1].strip()))
        elif op in ('and', 'ret', 'scf'):
            if (op == 'and' and operand != 'a') or (op in ('ret', 'scf') and operand):
                return ['unrecognized ROM0 portal one-byte instruction: ' + line]
            length = 1
        pc += length
    errors = []
    for after, target in jumps:
        if target not in labels:
            errors.append('ROM0 portal JR unresolved label: ' + target)
        else:
            offset = labels[target] - after
            if not -128 <= offset <= 127:
                errors.append(f'ROM0 portal JR out of range: {target}, signed offset {offset}')
    return errors


def audit(root: Path, gold: Path) -> list[str]:
    errors=[]
    try:
        original_city=(gold/'maps/OlivineCity.asm').read_text()
        original_room=(gold/'maps/OlivinePunishmentSpeechHouse.asm').read_text()
        if not re.search(r'(?m)^\s*warp_event\s+29,\s*11,\s*OLIVINE_PUNISHMENT_SPEECH_HOUSE,\s*1\b',original_city):
            errors.append('Gold original city house door (29,11) changed')
        for x in (2,3):
            if not re.search(rf'(?m)^\s*warp_event\s+{x},\s*7,\s*OLIVINE_CITY,\s*5\b',original_room):
                errors.append(f'Gold original house exit ({x},7) changed')
        for x,y in [(1,2),(5,5)]:
            if not re.search(rf'(?m)^\s*object_event\s+{x},\s*{y},',original_room):
                errors.append(f'Gold original house NPC ({x},{y}) changed')
        for x,y in [(0,1),(1,1)]:
            if not re.search(rf'(?m)^\s*bg_event\s+{x},\s*{y},',original_room):
                errors.append(f'Gold original house bookshelf ({x},{y}) changed')
        const=(root/'constants/johto_fixed_map_ids.asm').read_text()
        if not re.search(rf'(?m)^DEF {HOUSE} EQU 34\b',const):
            errors.append('frozen house local ID must remain 34')
        nmap=(root/'data/mapObjects/JohtoOlivineCity.asm').read_text()
        if not re.search(r'(?m)^\s*db\s+\$03\s*; three Gold-proven ordinary houses',nmap):
            errors.append('city must register exactly THREE independently routed indoor Warps')
        if re.findall(r'(?m)^\s*db\s+11,\s*29,\s*0,\s*REGION_WARP_ESCAPE',nmap)!=['db 11, 29, 0, REGION_WARP_ESCAPE']:
            # Accept formatting but reject duplicates by separate cardinality.
            if len(re.findall(r'(?m)^\s*db\s+11,\s*29,\s*0,\s*REGION_WARP_ESCAPE',nmap))!=1:
                errors.append('city door (29,11) must be registered once')
        house_obj=(root/'data/mapObjects/JohtoOlivinePunishmentSpeechHouse.asm').read_text()
        for x in (2,3):
            if not re.search(rf'(?m)^\s*db\s+7,\s*{x},\s*0,\s*REGION_WARP_ESCAPE',house_obj):
                errors.append(f'house exit ({x},7) must return to city Warp 0')
        if len(re.findall(r'(?m)^\s*object\s+SPRITE_',house_obj))!=2:
            errors.append('room must preserve 2 original NPCs')
        if len(re.findall(r'(?m)^\s*db\s+1,\s*[01],\s*[34]',house_obj))!=2:
            errors.append('room must preserve 2 bookshelves')
        home=(root/'home/overworld.asm').read_text()
        errors.extend(audit_portal_short_branches(home))
        collision_for_branches=(root/'engine/overworld/johto_route33_collision.asm').read_text()
        errors.extend(audit_portal_short_branches(collision_for_branches,
            entry='JohtoNorthGateStepWarpAllowed::', end='JohtoGateCollisionDirectionAllowed::'))
        selector = home.split('IsJohtoSouthGatePortal::',1)[1].split('MapEntryAfterBattle::',1)[0]
        selector = '\n'.join(line.split(';',1)[0] for line in selector.splitlines())
        if (not re.search(r'cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\s+jr c, \.maybeHouse', selector)
            or not re.search(r'\.maybeHouse\s+cp '+CITY+r'\s+jr z, \.yes\s+cp '+HOUSE+r'\s+jr z, \.yes\s+cp JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID\s+jr z, \.yes\s+cp JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID\s+jr z, \.yes\s+jr \.notGate',selector)):
            errors.append('ROM0 Olivine sparse selector must preserve each House1 ID and short branch ranges')
        lookup=(root/'engine/overworld/region_map_lookup.asm').read_text()
        target_rows=re.findall(rf'(?m)^\s*db\s+({CITY}|{HOUSE}),\s*([01]),\s*0,\s*MAP_REGION_JOHTO,\s*({CITY}|{HOUSE})\s*$',lookup)
        if sorted(target_rows)!=sorted([(CITY,'0',HOUSE),(HOUSE,'0',CITY),(HOUSE,'1',CITY)]):
            errors.append('native Warp resolver must provide exact 3 reciprocal rows')
        col=(root/'engine/overworld/johto_route33_collision.asm').read_text()
        # The three exterior doors are exact Gold coordinates, and are walkable
        # only when approached from the tile immediately below, facing north.
        for token in ('cp 29', 'cp 25', 'cp 13', 'cp 12', 'cp 16', '.firstHouseDoor', '.westConnection'):
            if token not in col.split('JohtoOlivineCityCanStepAhead::',1)[1].split('JohtoOlivineCityBlockedRows::',1)[0]:
                errors.append('Olivine multi-house outdoor door step mask missing: '+token)
        selector_north=col.split('JohtoNorthGateStepWarpAllowed::',1)[1].split('JohtoGateCollisionDirectionAllowed::',1)[0]
        if not all(token in selector_north for token in ('cp '+CITY, '.olivineHouseDoor',
                '.olivineNorthDoors', 'cp 11', 'cp 15', 'cp 29', 'cp 25', 'cp 13')):
            errors.append('Olivine three Gold DOOR cells require registered STEP_ON and UP')
        exit_selector=col.split('JohtoGateCollisionDirectionAllowed::',1)[1].split('.route32RuinsGate',1)[0]
        for mid in (HOUSE, 'JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID', 'JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID'):
            if not re.search(r'cp '+mid+r'\s+jp z, \.houseExitDown',exit_selector):
                errors.append('House1 exit-down selector missing: '+mid)
        if not re.search(r'(?s)\.houseExitDown\s+ld a, \[wYCoord\]\s+cp 7\s+jp nz, \.denied\s+ld a, \[wXCoord\]\s+cp 2\s+jp z, \.down\s+cp 3\s+jp z, \.down', col):
            errors.append('house two WARP_CARPET_DOWN exit lanes missing')
        mask=(root/'maps/JohtoOlivinePunishmentSpeechHouse.blocked_mask.bin').read_bytes()
        if len(mask)!=8 or any(mask[7] & (1<<x) for x in (2,3)):
            errors.append('house exit carpets must be walkable in exact 8x8 mask')
        if mask[:2]!=bytes([255,135]):
            errors.append('house north walls/furniture collision unexpected')
        # .2bpp is intentionally ignored by Git and generated from the tracked PNG.
        # Validate the PNG's fixed 96-slot encoding against the known-good historic asset;
        # if a local build artifact exists, it must match byte-for-byte.
        house_png=root/'gfx/tilesets/johto_house.png'
        with Image.open(house_png) as image:
            if image.mode!='L' or image.size!=(64,96) or not set(image.tobytes()) <= {0,85,170,255}:
                errors.append('Gold house PNG must be a 4-shade grayscale 8x12 tile atlas')
            encoded=strict_2bpp(image,96)
        if len(encoded)!=1536 or hashlib.sha256(encoded).hexdigest()!='141ed8ac9fc3b774aca51d426212239e9175b1dc4aede9e491f331d97538b1a9':
            errors.append('Gold house PNG no longer reproduces the historic fixed 96-slot 2bpp bytes')
        built=root/'gfx/tilesets/johto_house.2bpp'
        if built.exists() and built.read_bytes()!=encoded:
            errors.append('generated Gold house .2bpp differs from its tracked PNG source')
        makefile=(root/'Makefile').read_text()
        if not re.search(r'(?m)^gfx/tilesets/johto_house\.2bpp: gfx/tilesets/johto_house\.png\n\t\$\(RGBGFX\) -o \$@ \$<\n\t@test .*1536',makefile):
            errors.append('Gold house needs an explicit no-trim 96-slot PNG -> 2bpp Makefile rule')
        if len((root/'maps/JohtoOlivinePunishmentSpeechHouse.blk').read_bytes())!=16 or len((root/'gfx/blocksets/johto_house.bst').read_bytes())!=208:
            errors.append('Gold house isolated block/layout dimensions changed')
        if 'JohtoHouse_GFX: INCBIN "gfx/tilesets/johto_house.2bpp"' not in (root/'main.asm').read_text():
            errors.append('house gfx not included in ROM source')
        if len(re.findall(r'(?m)^\s*dw JohtoOlivinePunishmentSpeechHouseDadText\s*$',(root/'scripts/JohtoOlivinePunishmentSpeechHouse.asm').read_text()))!=1:
            errors.append('NPC script text pointer missing')
    except (ValueError,OSError) as exc:
        errors.append('required Gold/RPP house source missing: '+str(exc))
    return errors


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--rpp',type=Path,required=True)
    parser.add_argument('--gold',type=Path,required=True)
    args=parser.parse_args()
    err=audit(args.rpp,args.gold)
    print('OLIVINE HOUSE STATIC', 'PASS' if not err else 'FAIL',*err,sep='\n')
    raise SystemExit(bool(err))
