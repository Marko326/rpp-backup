#!/usr/bin/env python3
"""FIX-287: reject any active native Johto map header whose script is in another ROMX bank.

RunMapScript calls SwitchToMapRomBank then jp hl, rather than a banked call.
Because of this, matching header/script *symbol names* is not sufficient.
This source-level check follows fixed-bank main.asm INCLUDEs and active header
pointers; it is not a ROM build or emulation test.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

SECTION=re.compile(r'^\s*SECTION\s+.*?ROMX\s*,\s*BANK\[\$(\w+)\]')
INCLUDE=re.compile(r'^\s*INCLUDE\s+"([^"]+)"')
LABEL=re.compile(r'(?m)^([A-Za-z]\w+)::?\s*$')
ACTIVE_HEADER=re.compile(r'(?m)^\s*dw\s+(Johto\w+RuntimeHeader)\s*$')
DW=re.compile(r'(?m)^\s*dw\s+([A-Za-z]\w+)\s*(?:;.*)?$')

def audit(root: Path, changes: dict[str,str] | None = None) -> dict:
    root=Path(root); changes=changes or {};checks=[]; errors=[]
    def read(rel):
        return changes.get(rel,(root/rel).read_text())
    def ck(name,okay,detail=''):
        checks.append({'check':name,'status':'PASS' if okay else 'FAIL','detail':detail})
        if not okay:errors.append(f'{name}: {detail}')
    try:
        main=read('main.asm'); desc=read('data/johto_header_descriptors.asm')
        engine=read('home/overworld.asm')
        # A map's header & its script are loaded by the SAME ROMX-bank switch.
        run=engine.split('RunMapScript::',1)[1].split('LoadWalkingPlayerSpriteGraphics::',1)[0]
        ck('map_script_execution_is_unbanked_jump','call SwitchToMapRomBank' in run and 'jp hl' in run and
           run.index('call SwitchToMapRomBank')<run.index('jp hl') and 'ld hl,wMapScriptPtr' in run,'RunMapScript must use current map bank before direct jp hl')
        included={};bank=None
        for line in main.splitlines():
            sec=SECTION.search(line)
            if sec:bank=int(sec.group(1),16)
            inc=INCLUDE.search(line)
            if inc and bank is not None:included[inc.group(1)]=bank
        symbols={}
        for filename,bank in included.items():
            file=root/filename
            if not file.is_file():continue
            source=read(filename)
            for match in LABEL.finditer(source):
                name=match.group(1)
                # Each top-level symbol must resolve to exactly one bank.
                if name in symbols and symbols[name][0]!=bank:
                    errors.append(f'duplicate_bank_symbol: {name}')
                symbols[name]=(bank,filename,source[match.end():])
        headers=ACTIVE_HEADER.findall(desc.split('JohtoHeaderDescriptors::',1)[1].split('JohtoHeaderDescriptorsEnd::',1)[0])
        ck('complete_28_active_map_headers',len(headers)==28 and len(set(headers))==28,
           f'active={len(headers)}')
        for label in headers:
            if label not in symbols:
                ck(f'{label}_script_in_header_bank',False,'map header symbol missing')
                continue
            header_bank,filename,remaining=symbols[label]
            # Runtime header is a fixed-format 12-byte record or connection extension;
            # its first three dw values are blocks, text pointer, map script.
            header_body=remaining.split('RuntimeHeaderEnd',1)[0]
            pointers=DW.findall(header_body)
            script=pointers[2] if len(pointers)>=3 else None
            script_bank=symbols.get(script,(None,))[0]
            ck(f'{label}_script_in_header_bank',script_bank==header_bank,
               f'{label} bank {header_bank:#04x}, script {script} bank {script_bank}')
        ck('park_gate_scripts_local_bank50',all(symbols.get(name,(None,))[0]==0x50 for name in
              ('JohtoParkRuntimeHeader','JohtoParkSouthGateRuntimeHeader',
               'JohtoParkEastGateRuntimeHeader','JohtoParkLocalScript')) and
           all('dw JohtoParkLocalScript' in read('data/johto_park_runtime_286.asm').split(name+'::',1)[1].split('RuntimeHeaderEnd::',1)[0]
               for name in ('JohtoParkRuntimeHeader','JohtoParkSouthGateRuntimeHeader','JohtoParkEastGateRuntimeHeader')),
            'Park and both gate headers must point to local Bank $50 map script')
        ck('park_local_script_ret_and_rom0_call',bool(re.search(
           r'JohtoParkLocalScript::\s*\n\s*call EnableAutoTextBoxDrawing\s*\n\s*ret',
           read('data/johto_park_runtime_286.asm'))), 'Park local map script must be a no-op text box init')
    except (OSError,IndexError,ValueError,KeyError) as exc:
        ck('map_script_audit_inputs',False,str(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,
            'rom_built':False,'device_verified':False}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,default=Path.cwd());a=p.parse_args()
    report=audit(a.project)
    print(json.dumps({'status':report['status'],'checks':len(report['checks']),'errors':report['errors']},indent=2))
    raise SystemExit(bool(report['errors']))
