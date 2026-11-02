#!/usr/bin/env python3
"""Current maintained source gate: static ASM checks, migration audit and all tests.

This does NOT assemble/link a ROM or substitute for device acceptance. Older
DEV/REF milestone scripts can still be run separately for targeted diagnosis;
this is the preferred single entrypoint for a received project archive.

Usage:
    python tools/validate_current_project.py
    python tools/validate_current_project.py --gold-root /path/to/pokegold-master
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def run_command(label: str, command: list[str], env: dict[str, str]) -> tuple[str, int, str]:
    try:
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                text=True, errors='replace', check=False)
        return label, result.returncode, result.stdout + result.stderr
    except OSError as exc:
        return label, 127, str(exc)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gold-root', type=Path,
                        help='optional original pokegold-master tree; strengthens the Gold source audit')
    parser.add_argument('--skip-pytest', action='store_true',
                        help='only run static and migration checks')
    parser.add_argument('--jobs', type=int, default=4,
                        help='parallel pytest groups (1-4, default 4)')
    args = parser.parse_args(argv)
    if not 1 <= args.jobs <= 4:
        parser.error('--jobs must be from 1 to 4')
    env = os.environ.copy()
    if args.gold_root:
        if not args.gold_root.is_dir():
            parser.error(f'--gold-root does not exist: {args.gold_root}')
        env['GOLD_SOURCE_ROOT'] = str(args.gold_root.resolve())
        # Some historical Gold-backed tests use the older Johto-specific name.
        # Export both aliases so --gold-root actually enables, rather than skips,
        # every relevant source/warp/collision test in the grouped pytest run.
        env['JOHTO_GOLD_SOURCE'] = str(args.gold_root.resolve())
    checks = [
        ('ASM local-symbol preflight', [sys.executable, 'tools/asm_symbol_preflight.py']),
        ('active table-length preflight', [sys.executable, 'tools/johto_table_assert_preflight.py', '--root', '.']),
        ('current migration audit', [sys.executable, 'tools/johto_pilot_migration_audit.py', '--project', '.'] +
            (['--gold-root', str(args.gold_root.resolve())] if args.gold_root else [])),
    ]
    for label, command in checks:
        name, code, output = run_command(label, command, env)
        print(f'[{"PASS" if code == 0 else "FAIL"}] {name}', flush=True)
        print(output.rstrip(), flush=True)
        if code:
            print('Source gate failed; remaining checks were not reported as passing.', file=sys.stderr)
            return 1
    if not args.skip_pytest:
        test_files = sorted(str(p.relative_to(ROOT)) for p in (ROOT/'tools/tests').glob('test_*.py'))
        if not test_files:
            print('[FAIL] No pytest test files found', file=sys.stderr)
            return 1
        # Group independently to keep individual pytest processes bounded.
        groups = [test_files[i:i + 19] for i in range(0, len(test_files), 19)]
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = {
                pool.submit(run_command, f'pytest group {idx + 1}/{len(groups)}',
                            [sys.executable, '-m', 'pytest', '-q', '--tb=short', *files], env): idx
                for idx, files in enumerate(groups)
            }
            outputs = [None] * len(groups)
            for future in as_completed(futures):
                outputs[futures[future]] = future.result()
        failed = False
        for name, code, output in outputs:
            print(f'[{"PASS" if code == 0 else "FAIL"}] {name}', flush=True)
            print(output.rstrip(), flush=True)
            failed |= bool(code)
        if failed:
            print('FAIL: at least one pytest group failed', file=sys.stderr)
            return 1
    print('PASS: source/test checks only; ROM link, fresh MAP, and device test remain required.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
