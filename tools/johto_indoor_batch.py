#!/usr/bin/env python3
"""Run a bounded set of independent indoor converter jobs (OFFLINE ONLY).

JSON manifest schema:
 {"schema":"johto-indoor-batch-v1", "jobs":[
  {"id":"gate31", "gold_room":"Route31VioletGate",
   "rpp_room":"JohtoRoute31VioletGate",
   "outdoor":["JohtoVioletCity","JohtoRoute31"],
   "gold_tileset":"gate","rpp_tileset":"gate",
   "reference_room":"Route15Gate1F","strict_pairs":true}]}

No input is treated as code, never patches game files, rejects path traversal.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from johto_indoor_common import ConversionError, dump, safe_roots
from johto_indoor_pipeline import pipeline

_REQUIRED = {'id', 'gold_room', 'rpp_room', 'outdoor', 'gold_tileset',
             'rpp_tileset', 'reference_room', 'strict_pairs'}
_SAFE_ID = re.compile(r'[A-Za-z][A-Za-z0-9_]{0,63}\Z')


def validate_jobs(manifest: dict) -> list[dict]:
    if not isinstance(manifest, dict) or set(manifest) != {'schema', 'jobs'} or manifest['schema'] != 'johto-indoor-batch-v1':
        raise ConversionError('批处理 manifest 版本/字段非法')
    jobs = manifest['jobs']
    if not isinstance(jobs, list) or not (1 <= len(jobs) <= 32):
        raise ConversionError('批处理必须包含 1–32 个任务')
    used = set()
    for job in jobs:
        if not isinstance(job, dict) or set(job) != _REQUIRED:
            raise ConversionError('任务字段不完整或包含未知字段')
        for key in ('id', 'gold_room', 'rpp_room', 'gold_tileset', 'rpp_tileset', 'reference_room'):
            if not isinstance(job[key], str) or not _SAFE_ID.fullmatch(job[key]):
                raise ConversionError(f'非法名称字段: {key}')
        if job['id'] in used:
            raise ConversionError('批处理任务 id 重复')
        used.add(job['id'])
        outdoors = job['outdoor']
        if (not isinstance(outdoors, list) or not 1 <= len(outdoors) <= 8 or
                len(outdoors) != len(set(outdoors)) or
                not all(isinstance(x, str) and _SAFE_ID.fullmatch(x) for x in outdoors)):
            raise ConversionError('室外地图列表非法或重复')
        if type(job['strict_pairs']) is not bool:
            raise ConversionError('strict_pairs 必须为布尔值')
    return jobs


def run_batch(rpp: Path, gold: Path, out: Path, manifest: dict) -> dict:
    jobs = validate_jobs(manifest)
    rpp, gold, out = safe_roots(rpp, gold, out)
    results = []
    for job in jobs:
        target = out/job['id']
        summary = pipeline(rpp, gold, target, gold_room=job['gold_room'],
                           rpp_room=job['rpp_room'], outdoor=tuple(job['outdoor']),
                           gold_tileset=job['gold_tileset'], rpp_tileset=job['rpp_tileset'],
                           reference_room=job['reference_room'], strict_pairs=job['strict_pairs'])
        results.append({'id': job['id'], 'directory': job['id'],
                        'import_allowed': False, 'blockers': summary['blockers'],
                        'warp_graph': summary['warp_graph']})
    report = {'schema': 'johto-indoor-batch-result-v1',
              'jobs': results, 'game_sources_changed': False,
              'import_allowed': False, 'gameplay_tested': False}
    dump(out, 'batch_summary.json', report)
    return report


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('rpp', 'gold', 'output', 'manifest'):
        ap.add_argument('--'+name, type=Path, required=True)
    args = ap.parse_args(argv)
    raw = json.loads(args.manifest.read_text(encoding='utf-8'))
    report = run_batch(args.rpp, args.gold, args.output, raw)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
