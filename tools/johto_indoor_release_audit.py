#!/usr/bin/env python3
"""TOOLS.006: deterministic, read-only release gate for the OFFLINE converter.

A PASS means the *tooling* can be committed independently. It does not approve
any Gold->RPP game integration, gameplay, warp state, collisions, or colors.
The output root must be fresh, outside both source trees.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

from johto_indoor_batch import run_batch, validate_jobs
from johto_indoor_common import ConversionError, dump, safe_roots
from johto_indoor_manifest import verify_manifest
from johto_warp_reference_profiles import profile, compare

DEFAULT_JOBS = [
    {'id': 'gate31_route15', 'gold_room': 'Route31VioletGate',
     'rpp_room': 'JohtoRoute31VioletGate',
     'outdoor': ['JohtoVioletCity', 'JohtoRoute31'],
     'gold_tileset': 'gate', 'rpp_tileset': 'gate',
     'reference_room': 'Route15Gate1F', 'strict_pairs': True},
    {'id': 'gate31_route11', 'gold_room': 'Route31VioletGate',
     'rpp_room': 'JohtoRoute31VioletGate',
     'outdoor': ['JohtoVioletCity', 'JohtoRoute31'],
     'gold_tileset': 'gate', 'rpp_tileset': 'gate',
     'reference_room': 'Route11Gate1F', 'strict_pairs': True},
]


def protected_fingerprint(root: Path, *, rpp: bool) -> dict[str, str]:
    """Snapshot *all* relevant source files, not just a curated list."""
    result = {}
    for file in sorted(root.rglob('*')):
        relative = file.relative_to(root)
        parts = relative.parts
        if any(x in ('.git', '__pycache__', '.pytest_cache') for x in parts):
            continue
        if rpp and (parts[0] == 'tools' or parts[0] == 'pokegold-master'):
            continue
        if file.is_symlink():
            raise ConversionError(f'源码中存在符号链接，需要人工确认: {file}')
        if file.is_file():
            result[str(relative)] = hashlib.sha256(file.read_bytes()).hexdigest()
    return result


def compare_manifests(a: dict, b: dict) -> bool:
    """Ignore staging locations; compare exact source and output hashes."""
    return (a.get('configuration') == b.get('configuration') and
            a.get('sources') == b.get('sources') and
            a.get('generated_files') == b.get('generated_files'))


def probe_tamper(rpp: Path, gold: Path, target: Path) -> bool:
    """Ensure a mutated report fails, then restore it byte-for-byte."""
    path = target / '00_summary.json'
    original = path.read_bytes()
    try:
        path.write_bytes(original + b'\n')
        return not verify_manifest(rpp, gold, target)['valid']
    finally:
        path.write_bytes(original)


def run_tests(rpp: Path, gold: Path) -> dict:
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', JOHTO_GOLD_SOURCE=str(gold))
    proc = subprocess.run([sys.executable, '-B', '-m', 'unittest', 'discover',
                           '-s', 'tools/tests', '-p', 'test_johto*.py', '-q'],
                          cwd=rpp, env=env, text=True, capture_output=True)
    import re
    match = re.search(r'Ran (\d+) tests?', proc.stdout + '\n' + proc.stderr)
    skipped = re.search(r'skipped=(\d+)', proc.stdout + '\n' + proc.stderr)
    skipped_count = int(skipped[1]) if skipped else 0
    return {'passed': proc.returncode == 0 and match is not None and skipped_count == 0,
            'test_count': int(match[1]) if match else 0,
            'skipped_count': skipped_count,
            'returncode': proc.returncode,
            'output_tail': (proc.stderr + '\n' + proc.stdout)[-1600:]}


def release_audit(rpp: Path, gold: Path, out: Path, *, jobs: list[dict] | None = None,
                  execute_tests: bool = True) -> dict:
    rpp, gold, out = safe_roots(rpp, gold, out)
    jobs = DEFAULT_JOBS if jobs is None else jobs
    validate_jobs({'schema': 'johto-indoor-batch-v1', 'jobs': jobs})
    before_rpp = protected_fingerprint(rpp, rpp=True)
    before_gold = protected_fingerprint(gold, rpp=False)
    test_report = run_tests(rpp, gold) if execute_tests else {'passed': False, 'test_count': 0,
                                                         'reason': 'NOT_RUN'}
    manifest = {'schema': 'johto-indoor-batch-v1', 'jobs': jobs}
    first = run_batch(rpp, gold, out / 'run_a', manifest)
    second = run_batch(rpp, gold, out / 'run_b', manifest)
    proofs = []
    for job in jobs:
        a = out / 'run_a' / job['id']
        b = out / 'run_b' / job['id']
        first_valid = verify_manifest(rpp, gold, a)
        second_valid = verify_manifest(rpp, gold, b)
        a_manifest = json.loads((a/'07_source_manifest.json').read_text(encoding='utf8'))
        b_manifest = json.loads((b/'07_source_manifest.json').read_text(encoding='utf8'))
        summary = json.loads((a/'00_summary.json').read_text(encoding='utf8'))
        plan = json.loads((a/'11_conversion_plan_validation.json').read_text(encoding='utf8'))
        deterministic = compare_manifests(a_manifest, b_manifest)
        tamper_detected = probe_tamper(rpp, gold, b)
        restored_valid = verify_manifest(rpp, gold, b)['valid']
        proofs.append({'id': job['id'], 'source_manifest_valid': first_valid['valid'] and second_valid['valid'],
                       'bit_reproducible_outputs': deterministic,
                       'tamper_detected': tamper_detected, 'restored_manifest_valid': restored_valid,
                       'warp_graph': summary['warp_graph'],
                       'conversion_plan_structural_valid': plan['structural_valid'],
                       'import_allowed': False, 'gameplay_tested': False,
                       'known_blockers': summary['blockers']})
    # Additional existing RPP reference shapes: inspect only, no Gold rooms claimed.
    references = {}
    target_profile = profile(rpp, 'JohtoRoute31VioletGate')
    for reference in ('Route15Gate1F', 'Route11Gate1F', 'Route16Gate1F', 'Route18Gate1F'):
        references[reference] = compare(profile(rpp, reference), target_profile)
    after_rpp = protected_fingerprint(rpp, rpp=True)
    after_gold = protected_fingerprint(gold, rpp=False)
    source_read_only = before_rpp == after_rpp and before_gold == after_gold
    all_proofs = all(row['source_manifest_valid'] and row['bit_reproducible_outputs'] and
                     row['tamper_detected'] and row['restored_manifest_valid'] and
                     row['conversion_plan_structural_valid'] for row in proofs)
    ready = bool(test_report['passed'] and all_proofs and source_read_only)
    report = {'schema': 'johto-indoor-tools-release-gate-v1',
              'tool_commit_candidate': ready,
              'gameplay_integration_ready': False, 'import_allowed': False,
              'gameplay_tested': False, 'game_sources_changed': not source_read_only,
              'tests': test_report, 'jobs': proofs, 'reference_shape_checks': references,
              'distinct_converted_gold_rooms': len({j['gold_room'] for j in jobs}),
              'scope_note': '不同 RPP 门型对照不等于多张 Gold 房间端到端转换验收',
              'status': 'TOOL_ONLY_READY_FOR_GIT_REVIEW' if ready else 'BLOCK_TOOL_COMMIT'}
    dump(out, 'release_audit.json', report)
    return report


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for item in ('rpp', 'gold', 'output'):
        ap.add_argument('--'+item, type=Path, required=True)
    ap.add_argument('--manifest', type=Path, help='optional batch job config')
    ap.add_argument('--skip-tests', action='store_true', help='diagnostics only, always fails commit gate')
    args = ap.parse_args(argv)
    try:
        jobs = None
        if args.manifest:
            raw = json.loads(args.manifest.read_text(encoding='utf8'))
            jobs = validate_jobs(raw)
        report = release_audit(args.rpp, args.gold, args.output, jobs=jobs,
                               execute_tests=not args.skip_tests)
    except (ConversionError, OSError, ValueError, KeyError) as error:
        ap.error(str(error))
    print(json.dumps({'status': report['status'], 'tests': report['tests']['test_count'],
                      'jobs': len(report['jobs']), 'game_sources_changed': report['game_sources_changed']},
                     ensure_ascii=False))
    return 0 if report['tool_commit_candidate'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
