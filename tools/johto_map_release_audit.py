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
from johto_field_moves_preflight import audit as field_move_audit
from johto_fly_destination_audit import audit as fly_destination_audit
from johto_cave_escape_audit import audit as cave_escape_audit
from johto_indoor_collision_adapter import audit_reviewed_geometry
from johto_route33_runtime191 import audit as route33_runtime_audit
from johto_union_cave_exit192_audit import audit as cave_exit192_audit
from johto_surf_geometry_audit import inspect as surf_geometry_inspect
from johto_surf_runtime_audit import audit as surf_runtime_audit
from johto_ilex_gate_runtime_audit import audit as ilex_gate_audit, audit_ilex_forest as forest_p17_audit

GOLD_REQUIRED = ('maps/Route32.asm', 'maps/UnionCave1F.asm',
                 'data/tilesets/johto_collision.asm',
                 'data/maps/landmarks.asm', 'engine/events/overworld.asm',
                 'gfx/pokegear/johto.bin',
                 'data/tilesets/cave_collision.asm',
                 'maps/Route33.blk', 'maps/Route33.asm',
                 'data/tilesets/johto_modern_collision.asm',
                 'data/tilesets/johto_modern_metatiles.bin',
                 'gfx/tilesets/johto_modern.png',
                 'data/maps/flypoints.asm', 'data/maps/spawn_points.asm',
                 'maps/AzaleaTown.blk',
                 'maps/IlexForest.blk', 'maps/IlexForest.asm',
                 'maps/IlexForestAzaleaGate.asm',
                 'data/tilesets/forest_metatiles.bin',
                 'data/tilesets/forest_collision.asm',
                 'gfx/tilesets/forest.png')

# Explicitly pinned modules: a deleted test file must NEVER make this gate greener.
# To retire/rename a test, change this list in the same reviewed tool commit.
REQUIRED_TEST_MODULES = frozenset('''
test_johto_entrance_semantics169 test_johto_gate157_collision
test_johto_gate159_gold_art test_johto_gate_audit
test_johto_indoor_border_adapter test_johto_indoor_manifest
test_johto_indoor_stage3 test_johto_indoor_stage4
test_johto_indoor_stage5 test_johto_indoor_stage6
test_johto_indoor_toolchain test_johto_masked_step_audit test_johto_tileset_index_audit test_johto_gold_cells test_johto_map_release_audit
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
test_johto_town_map_bike181 test_johto_full_town_map182 test_johto_field_moves_preflight185
test_johto_cave_escape188 test_johto_surf_geometry186 test_johto_surf_runtime187
test_johto_route32_surf188
test_johto_route33_runtime191
test_johto_fly_destinations196
test_johto_gold_collision_cardinality test_johto_ilex_gold_reference test_johto_ilex_south_gate197
test_johto_union_cave_exit192 test_johto_ilex_forest_p17
'''.split())

# A module with a dummy test is not a replacement for critical negative checks.
REQUIRED_TEST_IDS = frozenset('''
test_johto_masked_step_audit.SharedMaskedSourceAudit.test_forest_ordinary_floor_down_to_carpet_is_allowed
 test_johto_masked_step_audit.SharedMaskedSourceAudit.test_forest_missing_north_rule_mutation_caught_by_branch_execution
 test_johto_masked_step_audit.SharedMaskedSourceAudit.test_forest_north_approach_is_exact_and_lower_wall_remains_blocked
test_johto_masked_step_audit.SharedMaskedSourceAudit.test_unknown_opcode_is_not_silently_accepted
test_johto_tileset_index_audit.TilesetIndexAudit.test_all_registered_ids_and_future_arithmetic_are_traced
test_johto_tileset_index_audit.TilesetIndexAudit.test_high_byte_carry_mutation_is_rejected
test_johto_tileset_index_audit.TilesetIndexAudit.test_missing_palette_assignment_include_is_rejected
test_johto_tileset_index_audit.TilesetIndexAudit.test_wrong_assignment_stride_is_rejected
test_johto_gold_collision_cardinality.GoldSurplusCollisionEntries.test_extra_gold_collision_entries_do_not_block_candidate
 test_johto_gold_collision_cardinality.GoldSurplusCollisionEntries.test_missing_collision_for_a_graphical_block_is_rejected
 test_johto_gold_collision_cardinality.GoldSurplusCollisionEntries.test_surplus_unreferenced_collision_entries_do_not_change_geometry
 test_johto_ilex_gold_reference.GoldIlexEntryReferences.test_gold_azalea_gate_and_forest_have_bidirectional_pairs
 test_johto_ilex_gold_reference.GoldIlexEntryReferences.test_gold_gate_exact_art_reuses_existing_johto_gate_candidate
 test_johto_ilex_south_gate197.IlexSouthGate197.test_gold_exact_two_way_registered_warps
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_gold_resources_are_from_general_pipeline
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_bidirectional_double_warp_preserves_east
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_wrong_direction_rejected
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_tileset_32_header_and_palette_indices
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_tileset_32_header_overflow_rejected
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_tileset_32_palette_overflow_rejected
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_forest_right_facing_return_rejected
 test_johto_ilex_south_gate197.IlexSouthGate197.test_original_east_pair_stays_in_front
 test_johto_ilex_south_gate197.IlexSouthGate197.test_swapped_gold_gate_pair_is_rejected
 test_johto_ilex_south_gate197.IlexSouthGate197.test_east_warp_count_removal_fails
 test_johto_ilex_south_gate197.IlexSouthGate197.test_wrong_native_region_mapping_rejected
 test_johto_ilex_south_gate197.IlexSouthGate197.test_missing_exact_entry_check_fails
test_johto_full_town_map182.JohtoFullTownMap182.test_options_scoped_labels_unique_and_mutation_is_caught
test_johto_warp_arrival175.JohtoWarpArrivalContract.test_unconditional_reject_after_correct_direction_fails
test_johto_warp_arrival175.JohtoWarpArrivalContract.test_unconditional_accept_after_x_guard_fails
test_johto_warp_arrival175.JohtoWarpArrivalContract.test_reintroducing_cave_auto_step_fails
test_johto_warp_approach176.UnionCaveApproach.test_collision_exit_and_sideways_safety
test_johto_warp_topology.WarpTopologyTests.test_swapped_doors_must_fail_not_silently_pass
test_johto_gate157_collision.Route31VioletNativeGate.test_walkable_gate_portal_does_not_auto_warp
 test_johto_gate159_gold_art.JohtoGoldGateArtwork.test_compact_gate_palette_exactly_matches_gold_source
 test_johto_gate159_gold_art.JohtoGoldGateArtwork.test_palette_tag_mutation_is_detected
 test_johto_ilex_south_gate197.IlexSouthGate197.test_missing_gate_neutral_sign_fails
test_johto_region_id170.NativeMapIDExpansion.test_same_length_wrong_header_identity_is_rejected
test_johto_gold_door_audit.GoldDoorReferenceTests.test_bad_destination_index_is_rejected
test_johto_gold_door_audit.GoldDoorReferenceTests.test_gold_baseline_inventory
test_johto_door_onboarding_audit.WarpCapabilityStatusTests.test_forbidden_active_route33_warp_is_rejected
test_johto_gold_cells.GoldQuadrantDecoder.test_missing_tilecoll_quadrant_fails
test_johto_gold_cells.GoldQuadrantDecoder.test_any_graphic_exceeding_slot_limit_fails
test_johto_door_onboarding_audit.DoorOnboardingTests.test_gate_missing_palette_proof_is_rejected
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_gate_missing_neutral_sign_proof_is_rejected
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_gate_missing_phone_review_status_is_rejected
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_unregistered_new_map_warp_is_rejected
test_johto_door_onboarding_audit.DoorOnboardingTests.test_existing_contract_count_drift_is_rejected
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_mandatory_gatehouse_guide_cannot_be_omitted
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_missing_gatehouse_read_marker_is_rejected
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_removed_gatehouse_proof_id_fails
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_new_gate_without_visual_status_fails
 test_johto_door_onboarding_audit.DoorOnboardingTests.test_outdoor_gate_must_also_reference_handbook
test_johto_town_map_bike181.JohtoTownMapBike181.test_gold_landmarks_and_cave_bike_match
test_johto_town_map_bike181.JohtoTownMapBike181.test_route32_raw_gold_coords_without_macro_offset_must_fail
test_johto_town_map_bike181.JohtoTownMapBike181.test_missing_union_cave_bike_whitelist_must_fail
test_johto_town_map_bike181.JohtoTownMapBike181.test_map_geography_change_outside_ui_panels_must_fail
test_johto_full_town_map182.JohtoFullTownMap182.test_all_45_gold_landmarks_in_original_order
test_johto_full_town_map182.JohtoFullTownMap182.test_a_different_unsupported_gold_landmark_cannot_move
test_johto_field_moves_preflight185.FieldMovePreflight185.test_incorrect_escape_permission_is_rejected
test_johto_cave_escape188.CaveEscape188.test_gold_single_entrance_contract
test_johto_cave_escape188.CaveEscape188.test_blackout_is_not_misrouted
test_johto_cave_escape188.CaveEscape188.test_wrong_region_cannot_dig
test_johto_cave_escape188.CaveEscape188.test_bad_cave_return_landing_cannot_ship
test_johto_field_moves_preflight185.FieldMovePreflight185.test_incorrect_surf_permission_is_rejected
test_johto_surf_geometry186.JohtoSurfGeometry186.test_real_gold_water_geometry_and_wall_aliases
test_johto_surf_geometry186.JohtoSurfGeometry186.test_relabelled_gold_water_is_detected
test_johto_surf_geometry186.JohtoSurfGeometry186.test_accidentally_walkable_water_is_detected
test_johto_surf_runtime187.CaveSurfRuntime187.test_all_64_gold_cells_exact
test_johto_surf_runtime187.CaveSurfRuntime187.test_reversing_surf_movement_water_branch_fails
test_johto_surf_runtime187.CaveSurfRuntime187.test_missing_party_surf_permission_check_fails
 test_johto_surf_runtime187.CaveSurfRuntime187.test_reintroduced_fog_badge_requirement_fails
 test_johto_surf_runtime187.CaveSurfRuntime187.test_kanto_soul_badge_rule_cannot_change
test_johto_route32_surf188.Route32Surf188.test_gold_route32_water_bitset_exact
test_johto_route32_surf188.Route32Surf188.test_water_map_mutation_must_fail
test_johto_route32_surf188.Route32Surf188.test_route32_map_guard_mutation_must_fail
test_johto_route32_surf188.Route32Surf188.test_route32_dispatch_mutation_must_fail
test_johto_rpp_batch.ReviewedGoldGeometryTests.test_mask_bit_mutation_is_rejected
test_johto_rpp_batch.ReviewedGoldGeometryTests.test_wrong_hop_landing_mutation_is_rejected
test_johto_rpp_batch.ReviewedGoldGeometryTests.test_fake_runtime_approval_is_rejected
test_johto_route33_runtime191.Route33Runtime191.test_wrong_route32_seam_is_rejected
test_johto_route33_runtime191.Route33Runtime191.test_route33_sign_cannot_disappear
test_johto_route33_runtime191.Route33Runtime191.test_gold_source_metadata_mutation_is_rejected
test_johto_route33_runtime191.Route33Runtime191.test_violet_to_route32_does_not_white_flash
test_johto_route33_runtime191.Route33Runtime191.test_wrong_route33_grass_tile_is_rejected
test_johto_fly_destinations196.JohtoFlyDestinations196.test_missing_fly_registration_fails
 test_johto_fly_destinations196.JohtoFlyDestinations196.test_new_gold_city_cannot_be_deferred
 test_johto_fly_destinations196.JohtoFlyDestinations196.test_shared_native_slot_is_not_fly_selector
 test_johto_fly_destinations196.JohtoFlyDestinations196.test_unvisited_destination_cannot_be_selected
 test_johto_fly_destinations196.JohtoFlyDestinations196.test_unsafe_landing_must_fail
 test_johto_fly_destinations196.JohtoFlyDestinations196.test_missing_gold_source_fails_closed
 test_johto_route33_runtime191.Route33Runtime191.test_route33_fly_permission_missing_is_rejected
test_johto_route33_runtime191.Route33Runtime191.test_fly_other_outdoor_check_must_remain
test_johto_union_cave_exit192.UnionCaveExit192.test_two_mouths_gold_matched
test_johto_union_cave_exit192.UnionCaveExit192.test_wrong_southern_exit_y_is_rejected
test_johto_union_cave_exit192.UnionCaveExit192.test_wrong_return_route33_safe_point_is_rejected
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
    errors.extend('ILEX_GATE: '+v for v in ilex_gate_audit(root,gold))
    errors.extend('ILEX_FOREST_P17: '+v for v in forest_p17_audit(root,gold))
    if not (root / 'data/game_version.asm').is_file():
        errors.append('RPP game_version.asm is missing')
    else:
        game_version = (root / 'data/game_version.asm').read_text(encoding='utf-8')
        match = re.search(r'^\s*db\s+"([A-Z]+-\d+\.\d+\.\d+)@"', game_version, re.M)
        if not match:
            errors.append('cannot read game version from game_version.asm')
        elif expected_version is not None and match.group(1) != expected_version:
            errors.append(f'wrong RPP baseline version: {match.group(1)} != {expected_version}')
    for relative in ('tools/johto_native_maps.json',
                     'tools/johto_door_contracts.json'):
        if not (root / relative).is_file():
            errors.append(f'required tracked Johto audit contract missing: {relative}')
    additional_required_ids = set()
    if not errors:
        onboard_errors, additional_required_ids = door_onboarding_audit(root, gold)
        errors.extend('DOOR_ONBOARDING: ' + e for e in onboard_errors)
        errors.extend('GOLD_DOOR: ' + e for e in gold_door_inspect(gold)['errors'])
        errors.extend('REGION: ' + e for e in region_audit(root))
        errors.extend('WARP: ' + e for e in warp_audit(root, gold))
        errors.extend('TOWN_BIKE: ' + e for e in town_bike_audit(root, gold))
        errors.extend('FIELD_MOVES: ' + e for e in field_move_audit(root, gold))
        errors.extend('FLY_DESTINATION: ' + e for e in fly_destination_audit(root, gold))
        errors.extend('CAVE_ESCAPE: ' + e for e in cave_escape_audit(root, gold))
        errors.extend('CAVE_EXIT192: ' + e for e in cave_exit192_audit(root, gold))
        errors.extend('REVIEWED_GEOMETRY: ' + e for e in audit_reviewed_geometry(root, gold))
        errors.extend('ROUTE33_RUNTIME: ' + e for e in route33_runtime_audit(root, gold))
        errors.extend('SURF_GEOMETRY: ' + e for e in surf_geometry_inspect(root, gold)['errors'])
        errors.extend('SURF_RUNTIME: ' + e for e in surf_runtime_audit(root, gold))
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
    resource_indexes = None
    try:
        from johto_tileset_index_audit import audit as tileset_index_audit
        resource_indexes = tileset_index_audit(root)
    except (OSError, ValueError) as exc:
        errors.append('TILESET_INDEX_ALL_IDS: '+str(exc))
    eligible_for_full_source_check = not errors
    from johto_masked_step_audit import audit as masked_step_audit
    runtime_step = None
    if eligible_for_full_source_check:
        try:
            runtime_step = masked_step_audit(root, gold)
            errors.extend('MASKED_STEP: '+err for err in runtime_step['failures'])
        except (OSError, ValueError, KeyError) as exc:
            errors.append('MASKED_STEP: source execution unsupported: '+str(exc))
    corpus_summary = None
    if eligible_for_full_source_check:
        import tempfile
        from johto_rpp_pipeline import full_gold_corpus
        with tempfile.TemporaryDirectory(prefix='rpp_gold_corpus_') as tmp:
            corpus_summary = full_gold_corpus(root, gold, Path(tmp)/'source_audit')
        errors.extend('GOLD_FULL_CORPUS: '+item['map']+': '+item['error']
                      for item in corpus_summary['errors'])
    return {'status': 'FAIL' if errors else 'PASS', 'errors': errors,
            'full_gold_corpus': corpus_summary,
            'masked_step_source_audit': runtime_step,
            'tileset_index_all_ids': resource_indexes,
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
