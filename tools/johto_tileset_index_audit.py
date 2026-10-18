#!/usr/bin/env python3
"""Check every RPP tileset table entry and executable 16-bit index formula.

This is a source-level, bounded SM83 arithmetic trace, not a ROM emulator or
ROM-bank/layout check. Unknown instructions and malformed table data fail closed.
It tests all current IDs and separately exercises future 8-bit IDs for aliasing.
"""
from __future__ import annotations
from pathlib import Path
import re


class ResourceIndexError(ValueError):
    pass


def _lines(text: str) -> list[str]:
    return [line.split(';', 1)[0].strip() for line in text.splitlines()
            if line.split(';', 1)[0].strip()]


def _check_macro_expansion(root: Path) -> None:
    """Confirm that the assembler macros still emit the assumed byte strides."""
    text = (root/'macros/data_macros.asm').read_text()
    def macro(name: str) -> list[str]:
        found = re.search(r'(?m)^'+re.escape(name)+r': MACRO\s*$', text)
        if not found:
            raise ResourceIndexError(f'{name} macro missing')
        return _lines(re.split(r'(?im)^ENDM\s*$', text[found.end():], maxsplit=1)[0])
    headers = macro('tileset')
    # BANK byte + three pointers + three counter tiles + grass + permission.
    expected_headers = [r'db BANK(\2)', r'dw \1, \2, \3',
                        r'db \4, \5, \6', r'db \7', r'db \8']
    if headers != expected_headers:
        raise ResourceIndexError('tileset assembler macro changed: 12-byte stride is unproven')
    tilepal = macro('tilepal')
    expected_tilepal = [r'x = \1 << 3', 'rept _NARG +- 1',
                        r'db (x | PAL_BG_\2)', 'shift', 'endr']
    if tilepal != expected_tilepal:
        raise ResourceIndexError('tilepal macro changed: 8 emitted bytes per row unproven')


def _count_table_rows(root: Path) -> tuple[list[str], int]:
    constants = _lines((root/'constants/tilesets.asm').read_text())
    names = [m[1] for line in constants
             if (m := re.fullmatch(r'const\s+([A-Z_0-9]+)', line))]
    if not names or len(names) > 256 or len(names) != len(set(names)):
        raise ResourceIndexError('Tileset constants are empty, duplicated, or exceed 8-bit IDs')
    if not any(line == 'const_value = 0' for line in constants):
        raise ResourceIndexError('Tileset constants no longer start at zero')
    hdr = _lines((root/'data/tileset_headers.asm').read_text())
    headers = [line for line in hdr if line.startswith('tileset ')]
    if len(headers) != len(names):
        raise ResourceIndexError(f'Tileset header rows {len(headers)} != constants {len(names)}')
    for index, row in enumerate(headers):
        parts = [p.strip() for p in row[len('tileset '):].split(',')]
        if len(parts) != 8 or any(not p for p in parts):
            raise ResourceIndexError(f'Tileset header {index} is not an 8-argument 12-byte record')
    palette_sets = _lines((root/'color/data/map_palette_sets.asm').read_text())
    if 'MapPaletteSets:' not in palette_sets:
        raise ResourceIndexError('MapPaletteSets label missing')
    pal_rows = palette_sets[palette_sets.index('MapPaletteSets:')+1:]
    if len(pal_rows) != 8*len(names) or not all(re.fullmatch(r'db\s+[\w$]+', x) for x in pal_rows):
        raise ResourceIndexError(f'MapPaletteSets must have 8 entries per tileset ({len(names)} IDs)')
    assignment = _lines((root/'color/data/map_palette_assignments.asm').read_text())
    if 'MapPaletteAssignments:' not in assignment:
        raise ResourceIndexError('MapPaletteAssignments label missing')
    assignments = assignment[assignment.index('MapPaletteAssignments:')+1:]
    includes = []
    for line in assignments:
        match = re.fullmatch(r'INCLUDE\s+"(color/tilesets/[\w]+\.asm)"', line)
        if not match:
            raise ResourceIndexError(f'Unexpected MapPaletteAssignments data directive: {line}')
        includes.append(match[1])
    if len(includes) != len(names):
        raise ResourceIndexError(f'MapPaletteAssignments includes {len(includes)} != tilesets {len(names)}')
    for index, rel in enumerate(includes):
        rows = _lines((root/rel).read_text())
        if len(rows) != 12:
            raise ResourceIndexError(f'{rel}: expected 12 tilepal rows, got {len(rows)}')
        for row in rows:
            m = re.fullmatch(r'tilepal\s+0\s*,\s*(.+)', row)
            if not m or len([v for v in m[1].split(',') if v.strip()]) != 8:
                raise ResourceIndexError(f'{rel}: malformed eight-tile palette row: {row}')
    return names, len(includes)


def _header_ops(text: str) -> list[str]:
    if text.count('LoadTilesetHeader:') != 1:
        raise ResourceIndexError('LoadTilesetHeader entry missing or ambiguous')
    entry = _lines(text.split('LoadTilesetHeader:', 1)[1].split('.copyTilesetHeaderLoop', 1)[0])
    try:
        start = entry.index('ld a, [wCurMapTileset]')
        stop = entry.index('ld de, Tilesets')
    except ValueError as exc:
        raise ResourceIndexError('Cannot find tileset header ID and table base') from exc
    if entry[stop+1:stop+3] != ['add hl, de', 'ld de, wTilesetBank']:
        raise ResourceIndexError('Tileset header table base/copy pointer was changed')
    return entry[start:stop]


def _trace_header(ops: list[str], tileset_id: int) -> int:
    r = dict(a=0, l=0, h=0, d=0, e=0)
    for op in ops:
        if op == 'ld a, [wCurMapTileset]':
            r['a'] = tileset_id
        elif (m := re.fullmatch(r'ld\s+([lhde])\s*,\s*([ahlde]|\d+)', op)):
            r[m[1]] = r[m[2]] if m[2] in r else int(m[2])
        elif op == 'add hl, hl' or op == 'add hl, de':
            hl = r['h']*256+r['l']
            other = hl if op.endswith('hl') else r['d']*256+r['e']
            value = (hl+other) & 0xffff
            r['h'], r['l'] = divmod(value, 256)
        else:
            raise ResourceIndexError(f'Unsupported tileset header ASM: {op}')
    return r['h']*256+r['l']


def _pal_set_ops(text: str) -> list[str]:
    start = text.find('ld a,b ; Get wCurMapTileset')
    if start < 0:
        raise ResourceIndexError('MapPaletteSets ID entry not found')
    # Continue through table addition, so changing the base pointer cannot pass.
    body = _lines(text[start:].split('ld d,h', 1)[0])
    if body[-2:] != ['ld hl, MapPaletteSets', 'add hl,de']:
        raise ResourceIndexError('MapPaletteSets base/offset use is unrecognized')
    return body


def _trace_pal_set(ops: list[str], tileset_id: int) -> int:
    r = dict(a=0, d=0, e=0)
    carry = 0
    for op in ops:
        if op == 'ld a,b':
            r['a'] = tileset_id
        elif op == 'push af' or op == 'ld hl, MapPaletteSets' or op == 'add hl,de':
            continue
        elif (m := re.fullmatch(r'ld\s+([de])\s*,\s*([a]|\d+)', op)):
            r[m[1]] = r[m[2]] if m[2] in r else int(m[2])
        elif op in ('sla e', 'rl d'):
            reg = op[-1]
            new_carry = (r[reg] >> 7) & 1
            r[reg] = ((r[reg] << 1) | (carry if op.startswith('rl ') else 0)) & 255
            carry = new_carry
        else:
            raise ResourceIndexError(f'Unsupported palette set ASM: {op}')
    return r['d']*256+r['e']


def _assignment_ops(text: str) -> tuple[list[str], dict[str,int]]:
    if '; Start copying palette assignments' not in text:
        raise ResourceIndexError('Palette assignment block marker missing')
    fragment = text.split('; Start copying palette assignments', 1)[1]
    fragment = fragment.split('push hl\n\tpop de', 1)[0]
    program, labels = [], {}
    for line in _lines(fragment):
        if re.fullmatch(r'\.[\w]+:?', line):
            labels[line.rstrip(':')] = len(program)
        else:
            program.append(line)
    if program[-2:] != ['ld bc, MapPaletteAssignments', 'add hl,bc']:
        raise ResourceIndexError('Palette assignments base/offset use unrecognized')
    return program,labels


def _trace_assignment(program: list[str], labels: dict[str,int], tileset_id: int) -> int:
    a = tileset_id
    c = 0
    hl = 0
    de = 0
    z = False
    pc = 0
    for _ in range(1024):
        if pc >= len(program):
            return hl
        op = program[pc]
        pc += 1
        if op == 'pop af':
            a = tileset_id
        elif op == 'ld hl,$0000':
            hl = 0
        elif op == 'cp $00':
            z = (a == 0)
        elif op == 'ld c,a':
            c = a
        elif (m := re.fullmatch(r'ld de,\$([0-9a-fA-F]{4})',op)):
            de = int(m[1], 16)
        elif op == 'add hl,de':
            hl = (hl+de) & 65535
        elif op == 'dec c':
            c = (c-1) & 255
            z = c == 0
        elif (m := re.fullmatch(r'jr (z|nz),\s*(\.[\w]+)',op)):
            if (z if m[1] == 'z' else not z):
                if m[2] not in labels:
                    raise ResourceIndexError(f'Palette assignment branch target absent: {m[2]}')
                pc = labels[m[2]]
        elif op in ('ld bc, MapPaletteAssignments', 'add hl,bc'):
            continue  # table base is symbol-resolved only at link time
        else:
            raise ResourceIndexError(f'Unsupported palette assignment ASM: {op}')
    raise ResourceIndexError('Palette assignment ASM loop failed to terminate')


def audit(root: Path) -> dict:
    root = Path(root)
    _check_macro_expansion(root)
    names, _ = _count_table_rows(root)
    h_ops = _header_ops((root/'engine/overworld/tileset_header.asm').read_text())
    pal_src = (root/'color/loadpalettes.asm').read_text()
    s_ops = _pal_set_ops(pal_src)
    a_ops, a_labels = _assignment_ops(pal_src)
    verified_ids = list(range(len(names)))
    # Check future arithmetic independently of resource availability. Do NOT
    # claim these unregistered IDs have a header, art or valid runtime bank.
    arithmetic_ids = sorted(set(verified_ids + [63,127,255]))
    for i in arithmetic_ids:
        offsets = (_trace_header(h_ops,i), _trace_pal_set(s_ops,i),
                   _trace_assignment(a_ops,a_labels,i))
        expected = (i*12, i*8, i*96)
        if offsets != expected:
            raise ResourceIndexError(f'Tileset ID {i}: traced offsets {offsets} != {expected}')
    return {
        'status': 'SOURCE_ARITHMETIC_AND_TABLE_SHAPE_ONLY',
        'registered_tilesets':len(names),
        'registered_ids_verified':len(verified_ids),
        'future_ids_arithmetic_only':[63,127,255],
        'last_registered':{'id':len(names)-1,'name':names[-1],
                           'header_offset':(len(names)-1)*12,
                           'palette_set_offset':(len(names)-1)*8,
                           'palette_assignment_offset':(len(names)-1)*96},
        'rom_bank_layout_verified':False,'vram_budget_verified':False,
        'compiled_rom':False,'phone_verified':False,
    }
