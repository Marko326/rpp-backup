#!/usr/bin/env python3
"""FIX-267: protect 16-bit tileset/palette indexing through JOHTO_MODERN (ID 32).

This is a static source/arithmetical preflight, NOT ROM execution.
"""
from pathlib import Path
import argparse
import json
import re


def inspect(header: str, palette: str, max_id: int = 32) -> dict:
    def normalized(txt):
        return re.sub(r";[^\n]*", "", txt).lower()
    h = normalized(header).split('loadtilesetheader:', 1)[-1].split('.copytilesetheaderloop', 1)[0]
    p = normalized(palette).split('loadtilesetpalette:', 1)[-1].split('.nextpalette', 1)[0]
    # Verify the actual ordered instruction path, not only an assertion that 32*12=384.
    header_pattern = (r'ld a,\s*\[wcurmaptileset\]\s*ld l,\s*a\s*ld h,\s*0\s*'
        r'add hl,\s*hl\s*add hl,\s*hl\s*ld d,\s*h\s*ld e,\s*l\s*'
        r'add hl,\s*hl\s*add hl,\s*de\s*ld de,\s*tilesets\s*'
        r'add hl,\s*de\s*ld de,\s*wtilesetbank')
    palette_pattern = (r'ld a,\s*b\s*push af\s*ld l,\s*a\s*ld h,\s*0\s*'
        r'add hl,\s*hl\s*add hl,\s*hl\s*add hl,\s*hl\s*'
        r'ld de,\s*mappalettesets\s*add hl,\s*de\s*ld d,\s*h\s*ld e,\s*l')
    h_ok = bool(re.search(header_pattern, h))
    p_ok = bool(re.search(palette_pattern, p))
    checks = {
        'tileset_header_16bit_path':h_ok,
        'palette_set_16bit_path':p_ok,
        'all_33_tileset_record_offsets':h_ok and all(((i << 2) + (i << 3)) == i * 12 for i in range(max_id+1)),
        'all_33_palette_record_offsets':p_ok and all((i << 3) == i * 8 for i in range(max_id+1)),
        'route33_header_high_byte':h_ok and (max_id * 12) == 0x180,
        'route33_palette_high_byte':p_ok and (max_id * 8) == 0x100,
    }
    return {'status':'PASS_STATIC_ONLY' if all(checks.values()) else 'FAIL', 'checks':checks,
            'route33_header_offset':'0x0180', 'route33_palette_offset':'0x0100',
            'rom_built':False}


def audit(root:Path):
    h=(root/'engine/overworld/tileset_header.asm').read_text()
    p=(root/'color/loadpalettes.asm').read_text()
    return inspect(h,p)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('.'))
    args=parser.parse_args()
    result=audit(args.root)
    print(json.dumps(result,indent=2))
    raise SystemExit(result['status'] != 'PASS_STATIC_ONLY')
