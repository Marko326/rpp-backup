#!/usr/bin/env python3
"""Batch stage Gold maps, then independently audit the staging area.

No game files are modified. Output is intentionally NOT importable into RPP.
"""
import argparse
import json
from pathlib import Path
from johto_rpp_batch import batch
from johto_rpp_validate import verify, write_reports, render_previews


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gold-root', type=Path, required=True)
    ap.add_argument('--project', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--preview-limit', type=int, default=12, help='preview maps; 0 disables')
    ap.add_argument('--audit-only', action='store_true', help='validate existing staged output')
    args = ap.parse_args()
    # Defense against accidentally wiping the project with staging outputs.
    # Unlike the legacy .135 script, this wrapper enforces disjoint trees.
    if args.output.is_symlink():
        ap.error('--output must not be a symlink')
    project = args.project.resolve()
    gold = args.gold_root.resolve()
    output = args.output.resolve()
    if output == project or project in output.parents or output in project.parents:
        ap.error('--output must be separate from the RPP project tree')
    if output == gold or gold in output.parents or output in gold.parents:
        ap.error('--output must be separate from the Gold source tree')
    if not args.audit_only:
        outcome = batch(args.gold_root, args.project, args.output)
        print('stage:', json.dumps(outcome, ensure_ascii=False))
    report = verify(args.output, args.gold_root, args.project)
    render_previews(args.output, args.gold_root, args.project, report, args.preview_limit)
    write_reports(args.output, report)
    print('audit:', json.dumps({**report['summary'], 'status': report['status']}, ensure_ascii=False))
    print('HTML:', args.output / 'verification' / 'index.html')
    if report['status'] == 'FAILED':
        return 2
    print('Offline static checks complete; this is NOT a compiled/playable ROM.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
