#!/usr/bin/env python3
"""Fail-closed path ownership gate for west/east Johto short-lived branches.

Run on the actual changed-file list; this never modifies the repository.
Public/common files, even if needed to connect a private map, belong to C.
"""
from __future__ import annotations
import argparse
import csv
from pathlib import Path
from johto_fixed_id_audit import ROOT, ROSTER


def check_paths(owner: str, paths: list[str], root: Path = ROOT) -> list[str]:
    if owner not in ('A', 'B', 'C'):
        return ['unknown branch role; specify A, B, or C']
    if owner == 'C':
        # Common integration has final write ownership, but still runs ID and
        # other release gates. No assertion that C's changes are harmless.
        return []
    try:
        with (Path(root) / ROSTER).open(encoding='utf-8-sig', newline='') as f:
            rows = list(csv.DictReader(f))
    except (OSError, UnicodeError):
        return ['frozen roster missing; cannot validate private paths']
    allowed_names = {r['gold_name'] for r in rows
                     if r['owner'] == ('西线A' if owner == 'A' else '东线B')}
    owned_paths = set()
    for name in allowed_names:
        prefix = 'Johto' + name
        owned_paths.update((f'maps/{prefix}.blk',
                            f'maps/{prefix}.blocked_mask.bin',
                            f'data/mapHeaders/{prefix}.asm',
                            f'data/mapObjects/{prefix}.asm',
                            f'scripts/{prefix}.asm',
                            f'text/{prefix}.asm'))
    errors = []
    for original in paths:
        # Neither dot segments nor absolute paths are valid; use repository
        # relative POSIX paths so requests cannot escape the whitelist.
        name = original.replace('\\', '/')
        if (not name or name.startswith('/') or
                any(part in ('.', '..', '') for part in name.split('/'))):
            errors.append(f'{owner}: unsafe changed-file path {original!r}')
        elif name not in owned_paths:
            errors.append(f'{owner}: non-owned/shared file {name} (submit to C)')
    return errors


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--owner', required=True, choices=['A','B','C'])
    p.add_argument('--project', type=Path, default=ROOT)
    p.add_argument('--changed', action='append', default=[], help='repository-relative changed path, repeatable')
    p.add_argument('--changed-list', type=Path, help='UTF-8 file with one changed path per line')
    args = p.parse_args()
    paths = list(args.changed)
    if args.changed_list:
        paths += [line for line in args.changed_list.read_text(encoding='utf-8').splitlines() if line]
    if not paths:
        p.error('no changed files provided; cannot prove ownership')
    issues = check_paths(args.owner, paths, args.project)
    for error in issues:
        print('FAIL:', error)
    if issues:
        return 1
    print(f'PASS: {len(paths)} path(s) within role {args.owner} ownership')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
