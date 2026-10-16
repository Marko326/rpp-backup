#!/usr/bin/env python3
"""Single non-building release gate for native Johto map tools and regressions.

This gate requires a complete Gold checkout and zero skipped tests. It checks
static contracts only; no ROM is built and no phone acceptance is implied.
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from johto_gold_door_audit import inspect as gold_door_inspect
from johto_door_onboarding_audit import audit as door_onboarding_audit
from johto_region_id_audit import audit as region_audit
from johto_warp_arrival_audit import audit as warp_audit
from johto_town_map_bike_audit import audit as town_bike_audit

GOLD_REQUIRED = ('maps/Route32.asm', 'maps/UnionCave1F.asm',
                 'data/tilesets/johto_collision.asm',
                 'data/maps/landmarks.asm', 'engine/events/overworld.asm',
                 'gfx/pokegear/johto.bin')

# Explicitly pinned modules: a deleted test file must NEVER make this gate greener.
# To retire/rename a test, change this list in the same reviewed tool commit.
REQUIRED_TEST_MODULES = frozenset('''
test_johto_entrance_semantics169 test_johto_gate157_collision
test_johto_gate159_gold_art test_johto_gate_audit
test_johto_indoor_border_adapter test_johto_indoor_manifest
test_johto_indoor_stage3 test_johto_indoor_stage4
test_johto_indoor_stage5 test_johto_indoor_stage6
test_johto_indoor_toolchain test_johto_map_release_audit
test_johto_mapname158 test_johto_music161 test_johto_music163
test_johto_music_final_audit test_johto_region_id170
test_johto_route32_ladder166 test_johto_route32_p1b
test_johto_route32_p1c test_johto_rpp_asset_audit
test_johto_rpp_batch test_johto_rpp_connection_guard
test_johto_rpp_contract167 test_johto_rpp_export_audit168
test_johto_rpp_validator_unit test_johto_union_cave171
test_johto_union_cave172 test_johto_union_cave173
test_johto_union_cave174 test_johto_warp_approach176
test_johto_warp_arrival175 test_johto_warp_topology
test_johto_gold_door_audit test_johto_door_onboarding_audit
test_johto_town_map_bike181 test_johto_full_town_map182
'''.split())

# A module with a dummy test is not a replacement for critical negative checks.
REQUIRED_TEST_IDS = frozenset('''
test_johto_full_town_map182.JohtoFullTownMap182.test_options_scoped_labels_unique_and_mutation_is_caught
test_johto_warp_arrival175.JohtoWarpArrivalContract.test_unconditional_reject_after_correct_direction_fails
test_johto_warp_arrival175.JohtoWarpArrivalContract.test_unconditional_accept_after_x_guard_fails
test_johto_warp_arrival175.JohtoWarpArrivalContract.test_reintroducing_cave_auto_step_fails
test_johto_warp_approach176.UnionCaveApproach.test_collision_exit_and_sideways_safety
test_johto_warp_topology.WarpTopologyTests.test_swapped_doors_must_fail_not_silently_pass
test_johto_gate157_collision.Route31VioletNativeGate.test_walkable_gate_portal_does_not_auto_warp
test_johto_region_id170.NativeMapIDExpansion.test_same_length_wrong_header_identity_is_rejected
test_johto_gold_door_audit.GoldDoorReferenceTests.test_bad_destination_index_is_rejected
test_johto_gold_door_audit.GoldDoorReferenceTests.test_gold_baseline_inventory
test_johto_door_onboarding_audit.DoorOnboardingTests.test_unregistered_new_map_warp_is_rejected
test_johto_door_onboarding_audit.DoorOnboardingTests.test_existing_contract_count_drift_is_rejected
test_johto_town_map_bike181.JohtoTownMapBike181.test_gold_landmarks_and_cave_bike_match
test_johto_town_map_bike181.JohtoTownMapBike181.test_route32_raw_gold_coords_without_macro_offset_must_fail
test_johto_town_map_bike181.JohtoTownMapBike181.test_missing_union_cave_bike_whitelist_must_fail
test_johto_town_map_bike181.JohtoTownMapBike181.test_map_geography_change_outside_ui_panels_must_fail
test_johto_full_town_map182.JohtoFullTownMap182.test_all_45_gold_landmarks_in_original_order
test_johto_full_town_map182.JohtoFullTownMap182.test_a_different_unsupported_gold_landmark_cannot_move
'''.split())


def discovered_test_ids(output: str) -> set[str]:
    # unittest -v displays actual discovered and executed tests. This proves
    # discovery, unlike assuming a missing module was collected by `discover`.
    return set(re.findall(r'(?m)^test_\w+\s+\((test_[\w.]+)\)\s+\.\.\.', output))



def verify_gold(gold: Path) -> list[str]:
    return [f'Gold source missing: {path}' for path in GOLD_REQUIRED
            if not (gold / path).is_file()]


def inspect_test_output(result: subprocess.CompletedProcess,
                        *, enforce_manifest: bool = False,
                        additional_required_ids: set[str] | None = None) -> list[str]:
    output = (result.stdout or '') + '\n' + (result.stderr or '')
    errors = []
    match = re.search(r'Ran\s+(\d+)\s+tests?', output)
    n = int(match.group(1)) if match else 0
    if not n:
        errors.append('test runner did not confirm a nonempty suite')
    if re.search(r'\bskipped\s*=\s*[1-9]\d*', output):
        errors.append('Gold-backed or other tests were skipped')
    if result.returncode:
        errors.append(f'unittest failed with exit code {result.returncode}')
    if enforce_manifest:
        found = discovered_test_ids(output)
        modules = {test_id.split('.')[0] for test_id in found}
        missing_modules = sorted(REQUIRED_TEST_MODULES - modules)
        missing_ids = sorted((REQUIRED_TEST_IDS | (additional_required_ids or set())) - found)
        if missing_modules:
            errors.append('required test modules not discovered: ' + ', '.join(missing_modules))
        if missing_ids:
            errors.append('required test IDs not executed: ' + ', '.join(missing_ids))
        if n != len(found):
            errors.append(f'unittest discovery mismatch: runner says {n} tests, '
                          f'verbose log contains {len(found)} distinct test IDs')
    return errors


def audit_project(root: Path, gold: Path, expected_version: str | None = None,
                  run_tests: bool = True) -> dict:
    errors = []
    root, gold = root.resolve(), gold.resolve()
    errors.extend(verify_gold(gold))
    if not (root / 'data/game_version.asm').is_file():
        errors.append('RPP game_version.asm is missing')
    else:
        game_version = (root / 'data/game_version.asm').read_text(encoding='utf-8')
        match = re.search(r'^\s*db\s+"([A-Z]+-\d+\.\d+\.\d+)@"', game_version, re.M)
        if not match:
            errors.append('cannot read game version from game_version.asm')
        elif expected_version is not None and match.group(1) != expected_version:
            errors.append(f'wrong RPP baseline version: {match.group(1)} != {expected_version}')
    additional_required_ids = set()
    if not errors:
        onboard_errors, additional_required_ids = door_onboarding_audit(root, gold)
        errors.extend('DOOR_ONBOARDING: ' + e for e in onboard_errors)
        errors.extend('GOLD_DOOR: ' + e for e in gold_door_inspect(gold)['errors'])
        errors.extend('REGION: ' + e for e in region_audit(root))
        errors.extend('WARP: ' + e for e in warp_audit(root, gold))
        errors.extend('TOWN_BIKE: ' + e for e in town_bike_audit(root, gold))
    test_count = 0
    skipped = None
    if not errors and run_tests:
        env = dict(os.environ, JOHTO_GOLD_SOURCE=str(gold), PYTHONDONTWRITEBYTECODE='1')
        result = subprocess.run([sys.executable, '-m', 'unittest', 'discover',
                                 '-s', 'tools/tests', '-v'], cwd=root, env=env,
                                capture_output=True, text=True, check=False)
        output = result.stdout + '\n' + result.stderr
        match = re.search(r'Ran\s+(\d+)\s+tests?', output)
        test_count = int(match.group(1)) if match else 0
        skips = re.search(r'\bskipped\s*=\s*(\d+)', output)
        skipped = int(skips.group(1)) if skips else 0
        errors.extend(inspect_test_output(result, enforce_manifest=True,
                                          additional_required_ids=additional_required_ids))
        if errors:
            print(output[-5000:], file=sys.stderr)
    return {'status': 'FAIL' if errors else 'PASS', 'errors': errors,
            'tests': test_count, 'skipped': skipped,
            'build_performed': False, 'phone_accepted_by_this_gate': False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp', required=True, type=Path)
    parser.add_argument('--gold', required=True, type=Path)
    parser.add_argument('--expect-version', help='optional exact game version guard')
    args = parser.parse_args()
    report = audit_project(args.rpp, args.gold, args.expect_version)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
