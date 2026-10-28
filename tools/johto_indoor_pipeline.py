#!/usr/bin/env python3
"""Run the second-batch MUS -> current-PAL indoor review pipeline.

For now the supported runtime contract is the already-enabled GuideGentsHouse
(ID 125). The tool stages Gold art/geometry candidates, compares current RPP
art, emits collision/registration/arrival/gatehouse reports, and fingerprints
inputs. It never writes to the project tree, assembles ROMs, or marks gameplay
approved. Outputs must be a new empty directory outside both source trees.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

from johto_gold_door_audit import inspect as inspect_gold
from johto_indoor_common import ConversionError, dump, safe_roots, sha
from johto_indoor_tiles_converter import build_mapping, stage_dedicated_gold_tileset
from johto_indoor_collision_adapter import check as check_collision
from johto_indoor_registration_generator import generate as audit_registration
from johto_pilot_migration_audit import audit_project
from johto_rpp_pipeline import stage_gold_map_candidate
from johto_warp_arrival_audit import audit as audit_arrival
from johto_gatehouse_behavior_audit import audit as audit_gatehouses

SUPPORTED_RUNTIME = {
    'GuideGentsHouse': {
        'gold_tileset': 'house',
        'rpp_tileset': 'johto_house',
        'rpp_header': 'JohtoGuideGentsHouseRuntimeHeader',
    }
}


def _hash_file(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file() or path.is_symlink():
        raise ConversionError(f'cannot fingerprint missing/symlink source: {relative}')
    return sha(path.read_bytes())


def _write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def run(project: Path, gold: Path, output: Path, *, gold_map: str = 'GuideGentsHouse') -> dict:
    project, gold = Path(project).resolve(), Path(gold).resolve()
    # Use the shared strict guard before creating anything. It rejects output
    # inside/equal to either source tree and refuses a non-empty old report dir.
    project, gold, output = safe_roots(project, gold, output)
    if gold_map not in SUPPORTED_RUNTIME:
        raise ConversionError(
            f'{gold_map} has no current PAL runtime contract yet; this second-batch '
            'pipeline currently accepts GuideGentsHouse only. Use johto_rpp_pipeline.py '
            'for a source-only candidate until a map-specific contract is reviewed.')
    spec = SUPPORTED_RUNTIME[gold_map]
    output.mkdir(parents=True, exist_ok=True)

    summary_checks = []
    hard_errors: list[str] = []

    # 1. Existing current-PAL static audit against MUS, the sole Gold source.
    pilot = audit_project(project, gold)
    _write_json(output / '01_current_pal_static_audit.json', pilot)
    summary_checks.append({'check': 'current_pal_static_audit', 'status': pilot['status'],
                           'detail': f"checks={pilot.get('metrics', {}).get('check_count', len(pilot.get('checks', [])))}; errors={len(pilot.get('errors', []))}"})
    if pilot.get('status') != 'PASS_STATIC_ONLY':
        hard_errors.extend('current_pal_static_audit: ' + str(e) for e in pilot.get('errors', []))

    # 2. Full Gold door/Warp source inventory from MUS.
    gold_report = inspect_gold(gold, include_events=True)
    _write_json(output / '02_mus_gold_door_inventory.json', gold_report)
    summary_checks.append({'check': 'mus_gold_door_inventory',
                           'status': 'PASS' if not gold_report.get('errors') else 'FAIL',
                           'detail': f"maps={gold_report.get('stats', {}).get('registered_maps')}; warps={gold_report.get('stats', {}).get('warp_events')}"})
    if gold_report.get('errors'):
        hard_errors.extend('mus_gold_door_inventory: ' + str(e) for e in gold_report['errors'])

    # 3. Source-only candidate staging. This deliberately keeps candidate files
    # separate from the project's maps/ and gfx/ trees.
    candidate_dir = output / '03_gold_candidate'
    candidate = stage_gold_map_candidate(project, gold, candidate_dir, gold_map,
                                         spec['gold_tileset'], spec['rpp_header'],
                                         runtime_gate=True)
    _write_json(output / '03_candidate_summary.json', candidate)
    summary_checks.append({'check': 'gold_map_candidate', 'status': candidate['status'],
                           'detail': f"source layout matches Gold={candidate.get('staged_blk_matches_gold')}; runtime_approved={candidate.get('runtime_approved')}"})
    if candidate.get('errors'):
        hard_errors.extend('gold_map_candidate: ' + str(e) for e in candidate['errors'])

    # 4. Pixel-exact art mapping against the selected current RPP tileset.
    art_dir = output / '04_art_mapping'
    art_dir.mkdir(parents=True, exist_ok=False)
    art, converted = build_mapping(project, gold, gold_map,
                                   spec['gold_tileset'], spec['rpp_tileset'])
    _write_json(art_dir / 'indoor_art.json', art)
    if converted is not None:
        (art_dir / f'{gold_map}.pixel_candidate.blk').write_bytes(converted)
    else:
        # If exact reuse fails, preserve a separate Gold-art candidate. It is
        # explicitly not a drop-in runtime tileset and stays outside the project.
        isolated = stage_dedicated_gold_tileset(gold, art_dir, gold_map, spec['gold_tileset'])
        _write_json(art_dir / 'isolated_original_art.json', isolated)
    summary_checks.append({'check': 'pixel_exact_art_mapping', 'status': art['status'],
                           'detail': f"used blocks={art.get('used_unique_blocks')}; unmapped={len(art.get('unmapped', []))}"})

    # 5. Collision mapping is evidence-only. Special door/carpet roles remain
    # review-required even when pixel artwork matches exactly.
    collision_dir = output / '05_collision_review'
    collision_dir.mkdir(parents=True, exist_ok=False)
    collision = check_collision(project, gold, art, spec['rpp_tileset'])
    collision['source_map'] = gold_map
    collision['gold_tileset'] = spec['gold_tileset']
    collision['rpp_tileset'] = spec['rpp_tileset']
    _write_json(collision_dir / 'indoor_collision.json', collision)
    summary_checks.append({'check': 'collision_semantics', 'status': collision['status'],
                           'detail': f"issues={len(collision.get('issues', []))}; auto_approve={collision.get('auto_approve')}"})

    # 6. Current project registration, exact Warp arrival and Gold gate inventory.
    registration = audit_registration(project, gold_map)
    _write_json(output / '06_registration_review.json', registration)
    summary_checks.append({'check': 'current_registration', 'status': registration['status'],
                           'detail': f"checks={len(registration.get('checks', []))}; errors={len(registration.get('errors', []))}"})
    if registration.get('status') != 'PRESENT_STATIC_ONLY':
        hard_errors.extend('current_registration: ' + str(e) for e in registration.get('errors', []))

    arrival = audit_arrival(project, gold)
    _write_json(output / '07_warp_arrival_audit.json', arrival)
    summary_checks.append({'check': 'warp_arrival_contract', 'status': arrival['status'],
                           'detail': f"checks={len(arrival.get('checks', []))}; errors={len(arrival.get('errors', []))}"})
    if arrival.get('status') != 'PASS_STATIC_ONLY':
        hard_errors.extend('warp_arrival_contract: ' + str(e) for e in arrival.get('errors', []))

    gatehouse = audit_gatehouses(project, gold)
    _write_json(output / '08_gatehouse_behavior_audit.json', gatehouse)
    summary_checks.append({'check': 'gold_gatehouse_semantics', 'status': gatehouse['status'],
                           'detail': f"Gold gate maps={gatehouse.get('gold_gate_inventory', {}).get('maps')}; warps={gatehouse.get('gold_gate_inventory', {}).get('warp_events')}"})
    if gatehouse.get('status') != 'PASS_REFERENCE_ONLY':
        hard_errors.extend('gold_gatehouse_semantics: ' + str(e) for e in gatehouse.get('errors', []))

    # 9. Fingerprint only the sources that directly determine this pipeline's
    # result, plus the tool/test files. This makes later reports reproducible.
    project_inputs = [
        'main.asm', 'constants/region_map_constants.asm', 'constants/johto_fixed_map_ids.asm',
        'data/johto_stable_id_slots.asm', 'data/johto_header_descriptors.asm',
        'data/johto_pilot_runtime_assets.asm', 'data/johto_pilot_source_resources.asm',
        'data/johto_pilot_map_headers.asm', 'data/johto_indoor_house.asm',
        'engine/johto_pilot_runtime.asm', 'home/overworld.asm', 'home.asm',
        'engine/overworld/npc_movement.asm', 'engine/overworld/doors.asm',
        'data/warp_tile_ids.asm', 'tools/johto_indoor_pipeline.py',
        'tools/johto_indoor_collision_adapter.py', 'tools/johto_indoor_registration_generator.py',
        'tools/johto_warp_arrival_audit.py', 'tools/johto_gatehouse_behavior_audit.py',
        'tools/johto_pilot_door_contracts.json', 'tools/johto_indoor_common.py',
        'tools/johto_indoor_tiles_converter.py', 'tools/johto_rpp_pipeline.py',
        'tools/johto_gold_door_audit.py', 'tools/johto_pilot_migration_audit.py',
        'tools/tests/test_johto_indoor_pipeline.py',
        'maps/johto_pilot/CherrygroveCity.runtime.blk',
        'maps/johto_pilot/GuideGentsHouse.runtime.blk',
        'gfx/blocksets/johto.bst', 'gfx/blocksets/johto_house.bst',
        'gfx/tilesets/johto.tilecoll', 'gfx/tilesets/johto_house.tilecoll',
        'gfx/tilesets/johto_house.png',
    ]
    gold_inputs = [
        'main.asm', 'constants/map_constants.asm', 'data/maps/maps.asm',
        'data/maps/blocks.asm', 'data/maps/attributes.asm',
        'maps/CherrygroveCity.asm', 'maps/GuideGentsHouse.asm',
        'data/tilesets/johto_collision.asm', 'data/tilesets/johto_metatiles.bin',
        'data/tilesets/house_collision.asm', 'data/tilesets/house_metatiles.bin',
        'gfx/tilesets/johto.png', 'gfx/tilesets/house.png',
    ]
    # The gate inventory walks all registered Gold map scripts and their
    # tileset metadata, so fingerprint those actual inputs rather than only
    # the two representative maps.
    gold_inputs.extend(str(p.relative_to(gold)) for p in sorted((gold / 'maps').glob('*.asm')))
    gold_inputs.extend(str(p.relative_to(gold)) for p in sorted((gold / 'data/tilesets').glob('*.asm')))
    gold_inputs.extend(str(p.relative_to(gold)) for p in sorted((gold / 'data/tilesets').glob('*.bin')))
    gold_inputs = list(dict.fromkeys(gold_inputs))
    fingerprints = {
        'schema': 'johto-indoor-source-fingerprint-v1',
        'reference_name': 'MUS-1.0.1',
        'project_sources': {rel: _hash_file(project, rel) for rel in project_inputs},
        'gold_sources': {rel: _hash_file(gold, rel) for rel in gold_inputs},
    }
    _write_json(output / '09_source_fingerprints.json', fingerprints)

    review_required = True  # collision semantics, ROM/MAP and phone tests remain explicit gates
    status = 'FAIL' if hard_errors else 'OFFLINE_REVIEW_REQUIRED'
    result = {
        'schema': 'johto-indoor-pipeline-v1',
        'status': status,
        'project': str(project),
        'gold_reference': {'name': 'MUS-1.0.1', 'root': str(gold)},
        'map': gold_map,
        'runtime_target': spec,
        'checks': summary_checks,
        'errors': hard_errors,
        'collision_review_required': bool(collision.get('issues')),
        'art_status': art.get('status'),
        'registration_status': registration.get('status'),
        'arrival_status': arrival.get('status'),
        'gatehouse_reference_status': gatehouse.get('status'),
        'candidate_runtime_approved': False,
        'rom_built': False,
        'runtime_verified': False,
        'phone_accepted': False,
        'output_isolated': True,
        'note': 'OFFLINE_REVIEW_REQUIRED is a successful report generation, not a playable/compiled ROM approval.',
    }
    _write_json(output / '00_pipeline_summary.json', result)
    lines = [
        '# P6 Indoor Pipeline — MUS-1.0.1 → PAL current pilot', '',
        f'- Status: **{status}**',
        f'- Gold source: `{gold}`',
        f'- RPP project: `{project}`',
        f'- Map: `{gold_map}` / stable ID 125',
        '- ROM compiled: **no**',
        '- Phone accepted: **no**',
        '', '## Checks', '',
        '| Check | Status | Detail |', '|---|---|---|',
    ]
    lines.extend(f"| {row['check']} | {row['status']} | {row['detail'].replace('|', '/')} |" for row in summary_checks)
    lines += ['', '## Boundary', '',
              'The candidate .blk/.bst/PNG files are isolated review artifacts. Do not copy them into the project automatically.',
              'Collision roles DOOR/WARP_CARPET_DOWN require the arrival/trigger contract; pixel equality does not approve collision, palette, VRAM or ROM-bank integration.',
              'Run the listed phone tests on a newly built Red/Blue ROM before marking the map accepted.', '']
    (output / 'README.md').write_text('\n'.join(lines), encoding='utf-8')
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--gold-root', type=Path, required=True,
                        help='MUS-1.0.1 source root; pret is not required')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--gold-map', default='GuideGentsHouse')
    args = parser.parse_args(argv)
    try:
        result = run(args.project, args.gold_root, args.output, gold_map=args.gold_map)
    except (OSError, ValueError, ConversionError) as exc:
        parser.error(str(exc))
    print(json.dumps({'status': result['status'], 'checks': len(result['checks']),
                      'errors': len(result['errors']), 'output': str(args.output.resolve()),
                      'rom_built': result['rom_built'], 'phone_accepted': result['phone_accepted']}, ensure_ascii=False))
    return 1 if result['status'] == 'FAIL' else 0


if __name__ == '__main__':
    raise SystemExit(main())
