#!/usr/bin/env python3
"""Read-only preflight for RGBDS active-map data-table size ASSERTs.

It does NOT assemble/link ROMs and deliberately does not rewrite any ASM source.
"""
import argparse
import pathlib
import re
import sys

COUNT_RE = re.compile(r'\b(?:DEF\s+)?NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)\b', re.I)
ASSERT_RE = re.compile(
    r'^\s*ASSERT\s+([A-Za-z_][\w.]*)\s*-\s*([A-Za-z_][\w.]*)\s*'
    r'==\s*(?:\(?\s*)?NUM_JOHTO_ACTIVE_MAPS(?:\s*\*\s*(\d+))?\s*\)?(?:\s*;.*)?$',
    re.I | re.M,
)
LABEL_RE = re.compile(r'^\s*([A-Za-z_][\w.]*)::?\s*(?:;.*)?$', re.M)
DATA_RE = re.compile(r'^\s*(db|dw|dl|ds)\s+(.+?)\s*$', re.I)


def unquote_comment(line):
    quote = None
    for i, ch in enumerate(line):
        if ch in ('"', "'"):
            if quote == ch:
                quote = None
            elif quote is None:
                quote = ch
        elif ch == ';' and quote is None:
            return line[:i]
    return line


def split_exprs(src):
    # Count comma-separated operands while preserving quoted strings.
    out, buf, quote, depth = [], [], None, 0
    for ch in src:
        if ch in ('"', "'"):
            quote = None if quote == ch else ch if quote is None else quote
        elif quote is None and ch == '(':
            depth += 1
        elif quote is None and ch == ')':
            depth -= 1
        if ch == ',' and quote is None and depth == 0:
            out.append(''.join(buf).strip()); buf = []
        else:
            buf.append(ch)
    if buf: out.append(''.join(buf).strip())
    if not out or any(not x for x in out):
        raise ValueError('empty or malformed data operand')
    return out


def count_bytes(section):
    n = 0
    for line in section.splitlines():
        line = unquote_comment(line).strip()
        if not line: continue
        m = DATA_RE.match(line)
        if not m:
            raise ValueError('unsupported declaration between table labels: ' + line[:100])
        directive, operands = m.group(1).lower(), split_exprs(m.group(2))
        if directive == 'ds':
            if len(operands) not in (1, 2):
                raise ValueError('unexpected ds operands')
            n += int(operands[0], 0)
        else:
            width = {'db': 1, 'dw': 2, 'dl': 3}[directive]
            for arg in operands:
                if arg.startswith('"') and arg.endswith('"'):
                    n += len(arg[1:-1]) * width
                else:
                    n += width
    return n


def inspect(root):
    const = root / 'constants' / 'region_map_constants.asm'
    if not const.is_file():
        return [f'MISSING: {const.relative_to(root)}']
    match = COUNT_RE.search(const.read_text(encoding='utf-8-sig'))
    if not match:
        return ['MISSING: NUM_JOHTO_ACTIVE_MAPS constant']
    expected_count = int(match.group(1))
    issues = []
    checked = []
    for f in sorted(root.rglob('*.asm')):
        # Avoid checking generated/old copies if put under nested folders.
        if any(x in {'.git', '.venv', '__pycache__'} for x in f.parts):
            continue
        s = f.read_text(encoding='utf-8-sig', errors='replace')
        labels = {m.group(1): m for m in LABEL_RE.finditer(s)}
        for a in ASSERT_RE.finditer(s):
            end, start = a.group(1), a.group(2)
            if start not in labels or end not in labels:
                issues.append(f'{f.relative_to(root)}: unresolved table label: {start}/{end}')
                continue
            first = labels[start].end()
            last = labels[end].start()
            if last <= first:
                issues.append(f'{f.relative_to(root)}: table labels out of order: {start}/{end}')
                continue
            expected_bytes = expected_count * int(a.group(3) or '1')
            try:
                got = count_bytes(s[first:last])
            except (ValueError, OverflowError) as e:
                issues.append(f'{f.relative_to(root)}: cannot safely count {start}: {e}')
                continue
            checked.append((str(f.relative_to(root)), start, got, expected_bytes))
            if got != expected_bytes:
                issues.append(f'{f.relative_to(root)}: {start}: got {got} bytes, expected {expected_bytes} from NUM_JOHTO_ACTIVE_MAPS={expected_count}')
    # These three active-slot tables exist in the current project. Their
    # ASSERTs must not disappear silently if someone removes a declaration.
    # Generic scanning above also checks any additional expression of this form.
    required = {
        ('engine/menu/options_menu.asm', 'JohtoActiveGSCMusic'),
        ('engine/fly_town_map_helpers.asm', 'JohtoPilotTownMapEntries'),
        ('engine/fly_town_map_helpers.asm', 'JohtoPilotTownMapBrowseIndexBySlot'),
    }
    present = {(f, start) for f, start, _got, _expected in checked}
    for file, label in sorted(required - present):
        issues.append(f'MISSING: {file}::{label} length ASSERT could not be verified (do not claim PASS)')
    return issues, checked, expected_count


def selftest():
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        root = pathlib.Path(d)
        (root / 'constants').mkdir()
        (root / 'engine/menu').mkdir(parents=True)
        (root / 'engine/fly_town_map_helpers.asm').write_text(
            'JohtoPilotTownMapEntries::\n'
            ' dw 0, 1, 2, 3, 4, 5\n'
            'JohtoPilotTownMapEntriesEnd::\n'
            'ASSERT JohtoPilotTownMapEntriesEnd - JohtoPilotTownMapEntries == NUM_JOHTO_ACTIVE_MAPS * 4\n'
            'JohtoPilotTownMapBrowseIndexBySlot::\n'
            ' db 0, 1, 2\n'
            'JohtoPilotTownMapBrowseIndexBySlotEnd::\n'
            'ASSERT JohtoPilotTownMapBrowseIndexBySlotEnd - JohtoPilotTownMapBrowseIndexBySlot == NUM_JOHTO_ACTIVE_MAPS\n')
        (root / 'constants/region_map_constants.asm').write_text('DEF NUM_JOHTO_ACTIVE_MAPS EQU 3\n')
        table = root / 'engine/menu/options_menu.asm'
        def write(rows):
            table.write_text('JohtoActiveGSCMusic::\n' + ''.join(f' db {i}\n' for i in rows) +
                             'JohtoActiveGSCMusicEnd::\n'
                             'ASSERT JohtoActiveGSCMusicEnd - JohtoActiveGSCMusic == NUM_JOHTO_ACTIVE_MAPS\n')
        write([1, 2, 3]); assert not inspect(root)[0]
        write([1, 2]); assert any('got 2 bytes, expected 3' in x for x in inspect(root)[0])
        write([1, 2, 3, 4]); assert any('got 4 bytes, expected 3' in x for x in inspect(root)[0])
        table.write_text('JohtoActiveGSCMusic::\n db 1\nJohtoActiveGSCMusicEnd::\n')
        assert any('MISSING:' in x for x in inspect(root)[0])
    print('SELF-TEST PASS: matched, missing row, extra row, removed ASSERT')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=pathlib.Path, default=pathlib.Path('.'))
    p.add_argument('--self-test', action='store_true')
    args = p.parse_args()
    if args.self_test:
        selftest(); return 0
    root = args.root.resolve()
    result = inspect(root)
    if len(result) == 1:
        for i in result[0]: print('FAIL', i)
        return 1
    issues, checked, expected = result
    print(f'NUM_JOHTO_ACTIVE_MAPS={expected}; {len(checked)} table ASSERT(s) checked')
    for f, label, got, target in checked:
        print(f'{"PASS" if got == target else "FAIL"} {f}::{label}: {got}/{target} bytes')
    for issue in issues: print('FAIL', issue)
    return 1 if issues else 0

if __name__ == '__main__':
    sys.exit(main())
