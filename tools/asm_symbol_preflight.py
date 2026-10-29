#!/usr/bin/env python3
"""Fail-fast RGBDS source preflight for RPP patch delivery.

Static pass: validate scoped dot-label targets of JR/JP/CALL in ASM sources.
This catches accidental references such as `jr .rbyFamily` when the enclosing
function only defines `.legacyStyle` (MUS-241 linker regression).

It is deliberately NOT a replacement for RGBDS: macros, conditional assembly,
link-time externals, relative branch reach, ROM bank placement and MAP layout
must be checked with the real toolchain on the user's device.

    python tools/asm_symbol_preflight.py
    python tools/asm_symbol_preflight.py --build   # opt-in, user's own RGBDS

Do not call --build in an AI code-review environment: project rules reserve ROM
assembly/linking to the owner. A preflight with no --build never writes assets.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# Scan one file at a time; dot labels in RGBDS are relative to nearest global.
GLOBAL_DEF = re.compile(r'^\s*([A-Za-z_][\w@#]*)(?:::|:)(?=\s|$)')
LOCAL_DEF = re.compile(r'^\s*(\.[A-Za-z_][\w@#]*)(?:(?:::|:)|(?=\s|$))')
# Check branch/call operand labels. These must be defined in the same scope.
BRANCH = re.compile(r'^\s*(jr|jp|call)\b\s+(?:nz|z|nc|c)\s*,\s*(\.[A-Za-z_][\w@#]*)\b|^\s*(jr|jp|call)\b\s+(\.[A-Za-z_][\w@#]*)\b', re.I)
MACRO_START = re.compile(r'^\s*(?:MACRO\b|[A-Za-z_][\w@#]*:?\s+MACRO\b)', re.I)
MACRO_END = re.compile(r'^\s*ENDM\b', re.I)


def without_comment(line: str) -> str:
    """Strip ';' comments while retaining literal semicolons in strings."""
    quote = None
    escaped = False
    for index, char in enumerate(line):
        if quote:
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'"):
            quote = char
        elif char == ';':
            return line[:index]
    return line


def check_text(text: str, filename: str = '<source>') -> list[str]:
    """Report undefined local branches; avoid errors from macro template bodies."""
    scopes = {}
    global_scope = '<file-start>'
    macro_depth = 0
    for line_number, raw in enumerate(text.splitlines(), 1):
        line = without_comment(raw).strip()
        if MACRO_START.match(line):
            macro_depth += 1
            continue
        if macro_depth:
            if MACRO_END.match(line):
                macro_depth -= 1
            continue
        global_match = GLOBAL_DEF.match(line)
        if global_match:
            global_scope = global_match.group(1)
        local_match = LOCAL_DEF.match(line)
        if local_match:
            scopes.setdefault(global_scope, {'labels': set(), 'refs': []})['labels'].add(local_match.group(1))
        branch = BRANCH.match(line)
        if branch:
            name = branch.group(2) or branch.group(4)
            if name and '\\' not in name:
                scopes.setdefault(global_scope, {'labels': set(), 'refs': []})['refs'].append((line_number, name, line))
    errors = []
    for scope, details in scopes.items():
        for line_number, name, statement in details['refs']:
            if name not in details['labels']:
                errors.append(f'{filename}:{line_number}: undefined RGBDS local label {scope}{name}: {statement}')
    return errors


def sources(root: Path, requested: list[str]) -> list[Path]:
    if requested:
        return [root / name for name in requested]
    # Exclude vendor sources, generated output and exported historical material.
    ignored = {'RPP_PROJECT_CONTEXT', 'RPP_COMMIT_RESTORE', 'extras', '.git', 'music_ref'}
    return sorted(p for p in root.rglob('*.asm') if not set(p.relative_to(root).parts) & ignored)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', nargs='*', help='specific project-relative ASM paths (default: all project ASM files)')
    parser.add_argument('--build', action='store_true', help='opt-in local Red/Blue plus two TEST RGBDS builds and MAP')
    parser.add_argument('--rgbds-prefix', default='', help='optional RGBDS tool directory prefix, e.g. ./rgbds-0.5.2/')
    args = parser.parse_args(argv)
    files = sources(ROOT, args.files)
    if not files:
        print('FAIL: no ASM files found', file=sys.stderr)
        return 2
    errors = []
    for f in files:
        if not f.is_file():
            errors.append(f'{f.relative_to(ROOT)}: file missing')
            continue
        try:
            errors.extend(check_text(f.read_text(encoding='utf-8'), str(f.relative_to(ROOT))))
        except (OSError, UnicodeError) as exc:
            errors.append(f'{f}: {exc}')
    if errors:
        print('FAIL: ASM local-symbol preflight', file=sys.stderr)
        for issue in errors:
            print('  ' + issue, file=sys.stderr)
        return 1
    print(f'PASS: {len(files)} ASM files checked for undefined local branch labels')
    if args.build:
        required = ('make', 'rgbasm', 'rgblink', 'rgbfix')
        prefix = args.rgbds_prefix
        def found(name):
            return (Path(prefix + name).is_file() if prefix else shutil.which(name))
        missing = [name for name in required if not found(name)]
        if missing:
            print('FAIL: local RGBDS build tools missing: ' + ', '.join(missing), file=sys.stderr)
            return 2
        print('Building Red + Blue + TEST Red + TEST Blue + MAP (ROMs will be written).', flush=True)
        cmd = ['make', '-B', 'red', 'blue', 'test-red', 'test-blue', 'map']
        if prefix:
            cmd.append('RGBDS=' + prefix)
        proc = subprocess.run(cmd, cwd=ROOT, check=False)
        if proc.returncode:
            print(f'FAIL: RGBDS build/link returned {proc.returncode}', file=sys.stderr)
            return proc.returncode
        for name in ('rppred.gbc', 'rppblue.gbc', 'rppredtest.gbc', 'rppbluetest.gbc', 'rppred.map', 'rppblue.map'):
            if not (ROOT / 'patches' / name).is_file():
                print('FAIL: build success but missing patches/' + name, file=sys.stderr)
                return 3
        print('PASS: local Red/Blue official and test ROMs, and official MAP builds completed')
    else:
        print('NOTE: static only; no RGBDS link, MAP, ROM or gameplay validation performed.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
