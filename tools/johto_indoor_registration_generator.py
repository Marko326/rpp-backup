#!/usr/bin/env python3
"""Offline evidence-based RPP map registration audit and review scaffold.

Does not assign map IDs, bank addresses, overwrite existing headers, or emit
assembly for automatic inclusion. Existing registration is checked structurally.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path
from johto_indoor_common import ConversionError, dump, read, rpp_dimensions, safe_roots

REGISTRATION_FILES = [
    'constants/map_constants.asm', 'constants/region_map_constants.asm',
    'data/johto_map_headers.asm', 'data/map_header_banks.asm',
    'data/map_header_pointers.asm', 'main.asm',
]


def _lines(text: str) -> str:
    # Strip ASM comments without mistaking a name in a comment for code.
    return '\n'.join(line.split(';', 1)[0] for line in text.splitlines())


def _matches(text: str, pattern: str) -> int:
    return len(re.findall(pattern, _lines(text), re.M))


def generate(rpp: Path, map_name='JohtoRoute31VioletGate'):
    texts = {f: read(rpp, f) for f in REGISTRATION_FILES}
    path_header = f'data/mapHeaders/{map_name}.asm'
    path_objects = f'data/mapObjects/{map_name}.asm'
    path_script = f'scripts/{map_name}.asm'
    path_blk = f'maps/{map_name}.blk'
    components = {'map_header': (rpp/path_header).is_file(),
                  'object_table': (rpp/path_objects).is_file(),
                  'script': (rpp/path_script).is_file(),
                  'layout': (rpp/path_blk).is_file()}
    checks = []

    def add(code, passed, detail):
        checks.append({'code': code, 'pass': bool(passed), 'detail': detail})

    if components['map_header']:
        header = read(rpp, path_header)
        symbol_match = re.search(r'^\s*db\s+([A-Z_0-9]+)_HEIGHT\s*,\s*\1_WIDTH\b',
                                 _lines(header), re.M)
        symbol = symbol_match[1] if symbol_match else None
        width, height = rpp_dimensions(rpp, map_name) if symbol else (None, None)
        add('MAP_HEADER_DIMENSIONS_DECLARED', bool(symbol), path_header)
        add('MAP_HEADER_OBJECT_TABLE_REF',
            bool(re.search(r'\bdw\s+'+re.escape(map_name)+r'Object\b',_lines(header))), path_header)
        add('MAP_HEADER_BLOCK_LABEL_REF',
            bool(re.search(r'\bdw\s+'+re.escape(map_name)+r'Blocks\b',_lines(header))), path_header)
    else:
        symbol, width, height = None, None, None
        add('MAP_HEADER_DIMENSIONS_DECLARED', False, path_header)
        add('MAP_HEADER_OBJECT_TABLE_REF', False, path_header)
        add('MAP_HEADER_BLOCK_LABEL_REF', False, path_header)

    dims = {'width_blocks': width, 'height_blocks': height} if width is not None else None
    layout_bytes = (rpp/path_blk).read_bytes() if components['layout'] else None
    add('MAP_LAYOUT_LENGTH', dims is not None and layout_bytes is not None
        and len(layout_bytes) == width*height,
        f'{path_blk}: {len(layout_bytes) if layout_bytes is not None else "missing"} bytes'
        + (f'; required {width*height}' if dims else ''))
    if components['object_table']:
        obj = read(rpp,path_objects)
        add('MAP_OBJECT_LABEL', _matches(obj,r'^\s*'+re.escape(map_name)+r'Object\s*:') == 1, path_objects)
    else:
        add('MAP_OBJECT_LABEL', False, path_objects)

    # Require a real one-time include, never a symbol casually mentioned in a comment.
    main = texts['main.asm']
    for code, filename in (('MAIN_HEADER_INCLUDE', path_header),
                           ('MAIN_OBJECT_INCLUDE', path_objects),
                           ('MAIN_SCRIPT_INCLUDE', path_script)):
        add(code, _matches(main,r'^\s*INCLUDE\s+"'+re.escape(filename)+r'"\s*$')==1, filename)
    add('MAIN_BLOCK_LABEL_AND_INCBIN',
        _matches(main,r'^\s*'+re.escape(map_name)+r'Blocks\s*:\s*INCBIN\s+"'
                 +re.escape(path_blk)+r'"\s*$')==1, path_blk)

    add('MAPCONST_REGISTRATION', bool(symbol) and _matches(texts['constants/map_constants.asm'],
         r'^\s*mapconst\s+'+re.escape(symbol)+r'\s*,')==1, symbol or 'unknown')
    add('REGION_LOCAL_ID_SYMBOL', bool(symbol) and _matches(texts['constants/region_map_constants.asm'],
         r'^\s*DEF\s+'+re.escape(symbol)+r'_LOCAL_ID\s+EQU\s+')==1, symbol or 'unknown')
    add('JOHTO_LOCAL_MAP_POINTER',
        _matches(texts['data/johto_map_headers.asm'],
                 r'^\s*dw\s+'+re.escape(map_name)+r'_h\b')==1,
        'data/johto_map_headers.asm')
    add('JOHTO_LOCAL_MAP_BANK',
        _matches(texts['data/johto_map_headers.asm'],
                 r'^\s*db\s+BANK\('+re.escape(map_name)+r'_h\)')==1,
        'data/johto_map_headers.asm')
    add('GLOBAL_MAP_POINTER',
        _matches(texts['data/map_header_pointers.asm'],
                 r'^\s*dw\s+'+re.escape(map_name)+r'_h\b')==1,
        'data/map_header_pointers.asm')
    add('GLOBAL_MAP_BANK',
        _matches(texts['data/map_header_banks.asm'],
                 r'^\s*db\s+BANK\('+re.escape(map_name)+r'_h\)')==1,
        'data/map_header_banks.asm')

    incomplete = [c['code'] for c in checks if not c['pass']]
    refs = {rel:{'has_map_reference': (map_name in _lines(src) or
                                     bool(symbol and symbol in _lines(src)))}
            for rel,src in texts.items()}
    return {'schema': 'johto-registration-plan-v2', 'map': map_name,
            'files':refs, 'components':components, 'dimensions':dims,
            'structural_checks':checks, 'failed_checks':incomplete,
            'status': 'REGISTRATION_REQUIRED' if incomplete else 'PRESENT_REVIEW_DEPENDENCIES',
            'scaffold': {'manual_wiring': ['select and review map-local and global IDs',
                                         'header pointer and target bank placement',
                                         'main.asm include and layout references',
                                         'tile set/animation table and ROM budget',
                                         'reverse Warp target IDs and save compatibility']},
            'warning': 'Structure checks do not certify available ROM bank space, gameplay or save data.'}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('rpp','gold','output'):
        ap.add_argument('--'+name, required=True, type=Path)
    ap.add_argument('--rpp-map',default='JohtoRoute31VioletGate')
    args=ap.parse_args(argv)
    rpp,gold,out=safe_roots(args.rpp,args.gold,args.output)
    result=generate(rpp,args.rpp_map)
    dump(out,'indoor_registration.json',result)
    print('registration:',result['status'], 'failed checks:',len(result['failed_checks']))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
