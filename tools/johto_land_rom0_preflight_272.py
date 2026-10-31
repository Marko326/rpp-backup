#!/usr/bin/env python3
"""Static-only ROM0 land gateway budget and banked return-contract preflight.

Does not build/link ROMs. A *fresh* user-generated MAP is mandatory for the
64-byte ROM0 acceptance floor and Home Copy Data placement.
"""
from pathlib import Path
import argparse
import json
import re

BASELINE_271_BYTES = 124  # Measured bytewise from .271's former south dispatch.
MAX_GATEWAY_BYTES = 30
MIN_RELEASED_BYTES = 80

def byte_length(block: str) -> int:
    total = 0
    for raw in block.splitlines():
        line = raw.split(';', 1)[0].strip().lower()
        if not line or line.startswith('.'):
            continue
        if line.startswith('callab '): n = 6
        elif re.fullmatch(r'ld a,\s*\[\s*[^\]]+\]', line): n = 3
        elif re.fullmatch(r'ld a,\s*[a-ehl]', line): n = 1
        elif line.startswith('cp '): n = 2
        elif line.startswith('jr '): n = 2
        elif line.startswith('jp '): n = 3
        elif line.startswith('bit '): n = 2
        elif line == 'and a': n = 1
        else: raise ValueError('unrecognized gateway opcode: ' + line)
        total += n
    return total

def inspect(root: Path) -> dict:
    errors = []
    try:
        home = (root/'home/overworld.asm').read_text()
        main = (root/'main.asm').read_text()
        module = (root/'engine/johto_land_collision_gateway_272.asm').read_text()
        start = home.index('\n.ordinaryGateApproach\n', home.index('CollisionCheckOnLand::')) + 1
        end = home.index('\n.nonRoute33Tiles\n',start) + 1
        dispatch = home[start:end]
        used = byte_length(dispatch)
    except (OSError, ValueError) as exc:
        return {'status':'FAIL','errors':[str(exc)]}
    if used > MAX_GATEWAY_BYTES or BASELINE_271_BYTES-used < MIN_RELEASED_BYTES:
        errors.append(f'ROM0 land gate {used}B; expected <= {MAX_GATEWAY_BYTES}B, released >= {MIN_RELEASED_BYTES}B')
    for fragment in ('callab JohtoOverworldSouthLandDecision', 'cp 2', 'jr z, .nonRoute33Tiles', 'jp z, .noCollision', 'jp .collision'):
        if fragment not in dispatch:
            errors.append('ROM0 gateway missing return-contract branch: '+fragment)
    if 'callab JohtoPilotGateDoorApproachAllowed' not in home[home.index('CollisionCheckOnLand::'):start]:
        errors.append('original gate approach must execute ahead of the land gateway')
    if not re.search(r'SECTION "Johto Land Collision Gateway 272", ROMX, BANK\[\$4F\]\s*\nINCLUDE "engine/johto_land_collision_gateway_272.asm"',main):
        errors.append('gateway code is not declared in ROMX bank $4F')
    for fragment in ('JohtoOverworldSouthLandDecision::', 'ld e, 2', 'cp JOHTO_CHERRYGROVE_LOCAL_ID', 'cp JOHTO_AZALEA_TOWN_LOCAL_ID', 'cp JOHTO_GOLDENROD_CITY_LOCAL_ID + 1', 'cp JOHTO_ROUTE_35_LOCAL_ID', 'cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID', '.activeSouthMap', 'cp JOHTO_ROUTE_33_LOCAL_ID', 'callab HandleLedges', 'callab JohtoSouthSpatialStep', 'callab JohtoRoute33StepPolicy', 'bit 6, a', 'ld e, 0'):
        if fragment not in module:
            errors.append('banked gateway missing: '+fragment)
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL', 'errors':errors,
            'metrics':{'baseline_271_bytes': BASELINE_271_BYTES,'rom0_gateway_bytes':used,
                       'source_bytes_released':BASELINE_271_BYTES-used,'target_bank':'$4F'},
            'warning':'Do not treat an old MAP as a link result for this patch.'}

def main_cli():
    p=argparse.ArgumentParser()
    p.add_argument('--root',type=Path,default=Path('.'))
    args=p.parse_args()
    report=inspect(args.root)
    print(json.dumps(report,indent=2,ensure_ascii=False))
    return 0 if report['status']=='PASS_STATIC_ONLY' else 1
if __name__=='__main__':
    raise SystemExit(main_cli())
