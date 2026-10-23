#!/usr/bin/env python3
"""Single non-building release gate for native Johto map tools and regressions.

This gate requires a complete Gold checkout and zero skipped tests. It checks
static contracts only; no ROM is built and no phone acceptance is implied.
"""
import argparse
import csv
from johto_gold_cells import decode_cells
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from johto_gold_door_audit import inspect as gold_door_inspect
from johto_door_onboarding_audit import audit as door_onboarding_audit
from johto_gatehouse_behavior_audit import audit as gatehouse_behavior_audit
from johto_region_id_audit import audit as region_audit
from johto_fixed_id_audit import audit as fixed_id_audit
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
from johto_rpp_connection_guard import audit_all_active
from johto_ilex_gate_runtime_audit import audit as ilex_gate_audit, audit_ilex_forest as forest_p17_audit
from johto_roof_reference_audit import audit as roof_audit
from johto_rom0_collision_audit import audit as rom0_collision_audit
from johto_east_exterior_runtime_audit import audit as east_exterior_runtime_audit
from johto_adjacent_pair_runtime_audit import audit as adjacent_pair_runtime_audit
from rom0_list_menu_bank_audit import audit as rom0_list_menu_bank_audit

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
                 'gfx/tilesets/forest.png',
                 'data/maps/roofs.asm', 'gfx/tilesets/roofs.pal',
                 'gfx/tilesets/roofs/new_bark.png')

# Explicitly pinned modules: a deleted test file must NEVER make this gate greener.
# To retire/rename a test, change this list in the same reviewed tool commit.
REQUIRED_TEST_MODULES = frozenset('''
test_johto_entrance_semantics169 test_johto_gate157_collision
test_johto_gate159_gold_art test_johto_gate_audit
test_johto_indoor_border_adapter test_johto_indoor_manifest
test_johto_indoor_stage3 test_johto_indoor_stage4
test_johto_indoor_stage5 test_johto_indoor_stage6
test_johto_olivine_house_240dev test_johto_olivine_house_npc_floor_240dev
test_johto_olivine_house_sprite_parity_240dev test_johto_house_furniture_240dev
test_johto_indoor_toolchain test_johto_masked_step_audit test_johto_tileset_index_audit test_johto_gold_cells test_johto_map_release_audit
test_johto_mapname158 test_johto_music161 test_johto_music163
test_johto_music_final_audit test_johto_region_id170 test_johto_fixed_id_freeze225
test_johto_route32_ladder166 test_johto_route32_p1b
test_johto_route32_p1c test_johto_rpp_asset_audit
test_johto_rpp_batch test_johto_adjacent_pair_pipeline_233 test_johto_route43_lake_235 test_johto_route43_gate_236 test_johto_route29_route46_gate_240 test_johto_route29_gate_runtime_240a test_johto_national_park_gates test_johto_route32_ruins_gate_239 test_johto_park_portal_runtime_239a test_johto_audit_kernel_hardening_235b test_johto_rpp_connection_guard
test_johto_rpp_contract167 test_johto_rpp_export_audit168
test_johto_rpp_validator_unit test_johto_union_cave171
test_johto_union_cave172 test_johto_union_cave173
test_johto_union_cave174 test_johto_warp_approach176
test_johto_warp_arrival175 test_johto_warp_topology
test_johto_gold_door_audit test_johto_door_onboarding_audit test_johto_gatehouse_behavior_hardening224
test_johto_town_map_bike181 test_johto_full_town_map182 test_johto_field_moves_preflight185
test_johto_cave_escape188 test_johto_surf_geometry186 test_johto_surf_runtime187
test_johto_route32_surf188 test_johto_ruins_surf224
test_johto_route33_runtime191
test_johto_fly_destinations196 test_johto_mahogany_town_228 test_johto_goldenrod_p19
test_johto_roof_reference_audit test_johto_roof_mapgroups_p19d test_johto_goldenrod_visual_p19c
test_johto_gold_collision_cardinality test_johto_ilex_gold_reference test_johto_ilex_south_gate197
test_johto_union_cave_exit192 test_johto_ilex_forest_p17 test_ledge_pause_209
test_johto_rom0_collision_dispatch224 test_rom0_list_menu_bank225
test_johto_ledge_full_217 test_johto_ruins_ledge224 test_johto_route35_goldenrod_gate224 test_johto_route37_stage test_johto_east_corridor_240 test_johto_east_exterior_runtime_239
'''.split())

# A module with a dummy test is not a replacement for critical negative checks.
REQUIRED_TEST_IDS = frozenset('''
test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_unbuilt_olivine_warp_cannot_be_activated
test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_olivine_house_door_warp_cannot_be_retargeted
test_johto_olivine_house_240dev.OlivineHouse240DEV.test_city_outdoor_warp_must_not_move
test_johto_olivine_house_240dev.OlivineHouse240DEV.test_house_reverse_warp_and_sibling_exit_protected
test_johto_house_furniture_240dev.TestGoldHouseFurniture.test_reject_room_guard_removed
test_johto_house_furniture_240dev.TestGoldHouseFurniture.test_reject_attempt_to_unblock_right_bookshelf
test_johto_route29_gate_runtime_240a.Route29GateRuntime240A.test_real_legacy_step_into_gold_door
test_johto_route29_gate_runtime_240a.Route29GateRuntime240A.test_legacy_preview_reads_actual_route46_bank
test_johto_route29_gate_runtime_240a.Route29GateRuntime240A.test_wrong_runtime_steps_are_rejected
test_johto_route29_gate_runtime_240a.Route29GateRuntime240A.test_wrong_preview_bank_and_edge_are_rejected
test_johto_east_corridor_240.EastCorridorPreflight240.test_five_gold_sources_checked_ice_path_still_sealed
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_verified_runtime_and_all_gold_connections
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_modified_gold_route44_block_caught
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_corrupt_blocked_mask_caught
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_route44_fly_destination_cannot_be_enabled
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_blackthorn_fly_cannot_disappear
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_cliff_takeoff_missing_detected
test_johto_east_exterior_runtime_239.EastLiveRuntime239.test_cave_cannot_falsely_activate
test_johto_east_corridor_240.EastCorridorPreflight240.test_changing_gold_cave_destination_is_rejected
test_johto_east_corridor_240.EastCorridorPreflight240.test_wrong_source_seam_offset_is_rejected
test_johto_east_corridor_240.EastCorridorPreflight240.test_runtime_tileset_visual_drift_is_rejected
test_johto_east_corridor_240.EastCorridorPreflight240.test_no_fake_runtime_approval_is_possible
test_johto_east_corridor_240.EastCorridorPreflight240.test_corrupted_staged_collision_mask_is_rejected
test_johto_park_portal_runtime_239a.ParkPortal239A.test_actual_source_matches
test_johto_park_portal_runtime_239a.ParkPortal239A.test_missing_right_entrance_is_caught
test_johto_park_portal_runtime_239a.ParkPortal239A.test_grass_marker_mutation
test_johto_park_portal_runtime_239a.ParkPortal239A.test_bike_permission_mutation
test_johto_park_portal_runtime_239a.ParkPortal239A.test_fly_permission_mutation
test_johto_route32_ruins_gate_239.RuinsGate239.test_two_lane_warps
test_johto_route32_ruins_gate_239.RuinsGate239.test_directional_collision
test_johto_route32_ruins_gate_239.RuinsGate239.test_immediate_return
test_johto_route32_ruins_gate_239.RuinsGate239.test_exterior_border_loads
test_johto_route32_ruins_gate_239.RuinsGate239.test_neutral_map_name
test_johto_route32_ruins_gate_239.RuinsGate239.test_gold_art_tile_palette
test_johto_route32_ruins_gate_239.RuinsGate239.test_runtime_rgb_kanto_isolation
test_johto_route32_ruins_gate_239.RuinsGate239.test_legacy_gate_regression
test_johto_national_park_gates.StaticParkGates.test_35_two_lane_warps
test_johto_national_park_gates.StaticParkGates.test_35_directional_collision
test_johto_national_park_gates.StaticParkGates.test_35_immediate_return
test_johto_national_park_gates.StaticParkGates.test_35_exterior_border_loads
test_johto_national_park_gates.StaticParkGates.test_35_neutral_map_name
test_johto_national_park_gates.StaticParkGates.test_35_gold_art_tile_palette
test_johto_national_park_gates.StaticParkGates.test_35_runtime_rgb_kanto_isolation
test_johto_national_park_gates.StaticParkGates.test_35_legacy_gate_regression
test_johto_national_park_gates.StaticParkGates.test_36_two_lane_warps
test_johto_national_park_gates.StaticParkGates.test_36_directional_collision
test_johto_national_park_gates.StaticParkGates.test_36_immediate_return
test_johto_national_park_gates.StaticParkGates.test_36_exterior_border_loads
test_johto_national_park_gates.StaticParkGates.test_36_neutral_map_name
test_johto_national_park_gates.StaticParkGates.test_36_gold_art_tile_palette
test_johto_national_park_gates.StaticParkGates.test_36_runtime_rgb_kanto_isolation
test_johto_national_park_gates.StaticParkGates.test_36_legacy_gate_regression
test_johto_route43_lake_235.Route43Lake235.test_235d_single_gold_door_first_step_warps_without_second_up
 test_johto_route43_lake_235.Route43Lake235.test_235d_self_consistent_wrong_door_contract_fails_gold_reference
test_johto_route43_lake_235.Route43Lake235.test_235b_every_gold_floor_seam_lane_runs_both_collision_layers
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_closing_gold_west_path_and_rewriting_manifest_still_fails
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_235b_disjoint_west_footpath_is_not_silently_omitted
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_235b_paired_collision_only_carpet_cannot_auto_step_off
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_proposed_visual_strip_fix_passes_without_touching_project
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_proposed_no_auto_step_passes_without_touching_project
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_current_frozen_render_and_arrival_kernels_pass
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_reducing_connection_copy_to_two_rows_is_rejected
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_removing_actual_north_copy_write_is_rejected
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_east_west_copy_width_corruption_is_rejected
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_gate_default_up_step_without_profile_is_rejected
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_gate_arrival_lookup_was_disabled_is_rejected
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_gate_postwarp_fallback_control_flow_is_rejected
test_johto_audit_kernel_hardening_235b.AuditKernelHardening235B.test_implicit_johto_gate_door_step_is_rejected
test_rom0_list_menu_bank225.Rom0ListMenuBank225.test_original_menu_stream_and_bank_exit_graph
test_rom0_list_menu_bank225.Rom0ListMenuBank225.test_wrong_entry_bank_is_blocked
test_rom0_list_menu_bank225.Rom0ListMenuBank225.test_restoring_bank_inside_romx_is_blocked
test_rom0_list_menu_bank225.Rom0ListMenuBank225.test_cancel_carry_flag_must_not_be_lost
test_rom0_list_menu_bank225.Rom0ListMenuBank225.test_bank1_swap_jumps_must_stay_connected
test_johto_fixed_id_freeze225.FixedIdFreeze225.test_baseline_and_all_222_roster_entries
test_johto_fixed_id_freeze225.FixedIdFreeze225.test_duplicate_east_62_registration_rejected
 test_johto_sparse_active_slot.SparseActiveSlotContract.test_id_62_cannot_alias_slot_22
 test_johto_sparse_active_slot.SparseActiveSlotContract.test_sparse_62_to_slot_25_without_dummy_maps
 test_johto_sparse_active_slot.SparseActiveSlotContract.test_16bit_music_and_town_offsets_are_mandatory
 test_johto_sparse_active_slot.SparseActiveSlotContract.test_corrupt_save_and_invalid_warp_reset_must_stay
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_original_all_11_native_ids_dispatch_and_generic_fallback
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_removing_single_rom0_farcall_is_rejected
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_carry_bit_abi_cannot_be_replaced_with_and
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_unknown_native_map_must_fall_back_to_generic_collision
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_no_native_map_can_use_wrong_collision_mask
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_missing_ruins_exact_id_must_fail
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_unconditional_native_branch_must_fail
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_legacy_map_32_seam_must_remain
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_moving_romx_dispatch_to_unrelated_bank_is_rejected
test_johto_rom0_collision_dispatch224.Rom0CollisionDispatch224.test_rom0_new_per_map_chain_is_rejected
test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_route35_carpet_step_on_bug_is_rejected
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_route35_warp_collision_direction_mutation_fails
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_route34_gold_carpet_step_on_branch_mutation_fails
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_vertical_gate_south_carpet_step_on_self_consistency_fails_gold
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_route34_outdoor_carpet_step_on_self_consistency_fails_gold
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_gold_carpet_direction_cannot_be_rewritten_with_manifest_and_asm
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_gold_arrival_carpet_never_receives_automatic_step
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_azalea_horizontal_gate_wrong_direction_fails
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_north_gate_arrival_removed_fails
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_unexpected_south_gate_arrival_fails
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_missing_border_load_path_fails
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_missing_gate_contract_is_blocked
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_unrecognized_selector_opcode_fails_closed
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_native_warp_to_wrong_gate_is_rejected
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_moving_arrival_into_wall_is_rejected
 test_johto_gatehouse_behavior_hardening224.GatehouseBehaviorHardening224.test_changed_gold_gate_metatile_layout_fails
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_wrong_route35_lane_target_fails
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_city_warp_removal_fails
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_wrong_native_branch_fails
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_unknown_gate_door_step_rejected
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_city_arrival_autostep_removed_is_detected
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_city_arrival_wrong_direction_is_detected
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_route35_default_forest_border_must_be_replaced
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_route35_collision_direction_and_blocked_wall_mandatory
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_route35_preview_wrong_row_or_wall_detected
test_johto_route35_goldenrod_gate224.GoldenrodNorthGate224.test_route35_south_border_load_hooks_must_be_on_both_paths

test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_exact_gold_inventory_of_all_eight_johto_ledge_maps
test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_azalea_sign_jump_lands_at_second_cell_despite_third_wall
test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_deleted_gold_azalea_hop_is_rejected
test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_wrong_azalea_direction_is_rejected
test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_gold_route31_pair_mutation_is_rejected
test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_modern_map_dispatch_mutation_is_rejected
test_johto_ledge_full_217.JohtoLedgeGoldCoverage217.test_absent_gold_source_never_returns_green
test_johto_ruins_ledge224.RuinsOutsideLedges224.test_every_safe_gold_direction_is_registered
 test_johto_ruins_ledge224.RuinsOutsideLedges224.test_upper_cliff_can_land_on_another_cliff_top
 test_johto_ruins_ledge224.RuinsOutsideLedges224.test_unsafe_gold_hop_is_exactly_one_blocked_landing
 test_johto_ruins_ledge224.RuinsOutsideLedges224.test_deleting_legal_jump_fails
 test_johto_ruins_ledge224.RuinsOutsideLedges224.test_wrong_direction_fails
 test_johto_ruins_ledge224.RuinsOutsideLedges224.test_unsafe_wall_landing_added_fails
 test_johto_ruins_ledge224.RuinsOutsideLedges224.test_ruins_map_id_dispatch_mutation_fails
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_new_outdoor_map_without_a_roof_group_fails_closed
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_route34_going_green_again_is_rejected
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_one_wrong_original_roof_rgb_is_rejected
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_corrupted_original_roof_tiles_are_rejected
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_swapping_violet_and_azalea_roof_sources_is_rejected
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_wrong_roof_source_bank_is_rejected
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_wrong_group_dispatch_branch_is_rejected
test_johto_roof_reference_audit.RoofGoldReferenceGate.test_wrong_base_roof_tile_offset_is_rejected
test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_route39_three_tier_downhill_is_proven_by_full_source_chain
 test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_chained_ledge_negative_intermediate_wall_and_final_landing
 test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_nonadjacent_pair_is_rejected_before_writing_files
 test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_gold_seam_mutation_is_rejected_even_if_both_maps_exist
 test_johto_adjacent_pair_pipeline_233.AdjacentPairPipeline233.test_staged_rpp_game_resources_match_gold_and_generated_masks
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_all_active_connections_must_match_gold
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_route35_north_preview_reaches_three_visual_border_columns
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_route32_reachable_north_preview_matches_gold_and_runtime_fence
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_route32_missing_preview_fails_global_guard
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_route32_fake_or_missing_reachable_gate_is_rejected
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_short_visual_strip_is_rejected_by_full_guard
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_bad_legacy_connection_is_rejected_globally
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_cross_bank_map_is_rejected_before_delivery
 test_johto_rpp_connection_guard.RealConnectionCoverage.test_enabled_connection_cannot_be_omitted_from_discovery
 test_johto_map_release_audit.MapReleaseGateTest.test_actual_connection_failure_blocks_release_before_unittests
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
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_ledge_repaused_rejected
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_ledge_wrong_jump_count_rejected
 test_johto_ilex_forest_p17.ForestRuntimeP17.test_negative_ledge_missing_corner_direction_rejected
 test_ledge_pause_209.ForestCommonLedgeCandidate.test_forest_uses_native_tile_pairs_and_common_dispatch
 test_ledge_pause_209.ForestCommonLedgeCandidate.test_forest_does_not_change_common_input_count
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
test_johto_goldenrod_p19.GoldenrodP19.test_gold_two_way_connection_offsets
test_johto_region_id170.NativeMapIDExpansion.test_same_length_wrong_header_identity_is_rejected
test_johto_gold_door_audit.GoldDoorReferenceTests.test_bad_destination_index_is_rejected
test_johto_gold_door_audit.GoldDoorReferenceTests.test_gold_baseline_inventory
test_johto_gold_door_audit.GoldDoorReferenceTests.test_all_gold_gate_warps_have_collision_derived_trigger_rules
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
test_johto_ruins_surf224.RuinsSurf224.test_original_gold_water_all_48_cells
 test_johto_ruins_surf224.RuinsSurf224.test_disabled_ruins_surf_dispatch_fails
 test_johto_ruins_surf224.RuinsSurf224.test_badge_gate_ruins_removed_fails
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
 test_johto_fly_destinations196.JohtoFlyDestinations196.test_deferred_ecruteak_must_not_claim_fly_allowed
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


def audit_new_native_map_signs(root: Path, gold: Path) -> list[str]:
    """Enforce complete Gold read-sign coverage for newly onboarded local IDs >=22.

    Gold BG_EVENT_ITEM is not a sign. Indoor/door events use independent audits.
    This is a source inspection: it cannot claim that a ROM displays the text.
    """
    errors = []
    try:
        entries = json.loads((root / 'tools/johto_native_maps.json').read_text())['maps']
    except (OSError, ValueError, KeyError) as exc:
        return [f'cannot load native map registry for Gold signs: {exc}']
    for entry in entries:
        if entry['local_id'] < 22:
            continue  # historical native maps have their own reviewed stage contracts
        mapname = entry['header'].removeprefix('Johto').removesuffix('_h')
        goldfile = gold / 'maps' / (mapname + '.asm')
        if not goldfile.is_file():
            errors.append(f'{mapname}: missing Gold sign-event source')
            continue
        goldtext = goldfile.read_text()
        coords = [(int(x), int(y)) for x, y in re.findall(
            r'(?m)^\s*bg_event\s+(\d+),\s*(\d+),\s*BGEVENT_READ\b', goldtext)]
        if not coords:
            continue
        objfile = root / 'data/mapObjects' / f'Johto{mapname}.asm'
        scriptfile = root / 'scripts' / f'Johto{mapname}.asm'
        if not objfile.is_file() or not scriptfile.is_file():
            errors.append(f'{mapname}: Gold sign object/script missing')
            continue
        obj = objfile.read_text()
        asm = scriptfile.read_text()
        # A native object header holds tileset ID, warp count, text count,
        # followed by exactly that many (y,x,text ID) records.
        lines = obj.splitlines()
        heads = [(i, int(m.group(1), 16)) for i, line in enumerate(lines)
                 if (m := re.match(r'\s*db\s+\$([\da-fA-F]{2})\s*(?:;.*)?$', line))]
        if len(heads) < 3:
            errors.append(f'{mapname}: cannot inspect native object sign count')
            continue
        sign_count = heads[2][1]
        startline = heads[2][0] + 1
        found = []
        for line in lines[startline:startline + sign_count]:
            m = re.match(r'\s*db\s+(\d+),\s*(\d+),\s*(\d+)\b', line)
            if m:
                found.append(tuple(map(int, m.groups())))
        # This Gold room has two NPC text entries before its two bookshelf
        # text entries.  RPP TextPredef IDs 3/4 are correct; do not force 1/2.
        prefix = 2 if mapname == 'OlivinePunishmentSpeechHouse' else 0
        gold_coords = [(y,x,prefix+i+1) for i,(x,y) in enumerate(coords)]
        if sign_count != len(coords) or found != gold_coords:
            errors.append(f'{mapname}: Gold BGEVENT_READ signs differ: '
                          f'{len(coords)} expected at {gold_coords}, got {found}')
        pointer_block = re.search(rf'Johto{re.escape(mapname)}TextPointers:\s*([\s\S]*?)(?:\n\S|\Z)', asm)
        pointers = re.findall(r'(?m)^\s*dw\s+([A-Za-z_0-9]+)',
                              pointer_block[1] if pointer_block else '')
        if (len(pointers) != prefix+len(coords)
                or any(p + ':' not in asm for p in pointers[prefix:])):
            errors.append(f'{mapname}: Gold sign text pointers missing/incomplete')
    return errors


def audit_new_native_field_move_roles(root: Path, gold: Path) -> list[str]:
    """For new maps, compare actual Gold quadrant roles with declared abilities.

    An ID reservation is not a playable map. Existing IDs <22 follow earlier
    reviewed contracts. Unknown future tilesets fail closed for explicit review.
    """
    errors=[]
    try:
        entries=json.loads((root/'tools/johto_native_maps.json').read_text())['maps']
        with (root/'tools/johto_fixed_ids.csv').open(newline='') as f:
            rows={row['gold_name']: row for row in csv.DictReader(f)}
        runtime=(root/'engine/overworld/johto_union_cave_surf.asm').read_text()
    except (OSError, ValueError, KeyError) as exc:
        return [f'native Gold capability audit cannot load sources: {exc}']
    for entry in entries:
        if entry['local_id']<22:
            continue
        name=entry['header'].removeprefix('Johto').removesuffix('_h')
        try:
            original=rows[name]
            header=(root/f'data/mapHeaders/Johto{name}.asm').read_text()
            match=re.search(r'(?m)^\s*db\s+(JOHTO(?:_MODERN|_UNION_CAVE|_ILEX_FOREST)?)\s*$',header)
            if not match:
                # Indoor/gate specialist audits handle field-move eligibility.
                # For an outdoor map, unknown tileset cannot be silently ignored.
                if 'db SOUTH' in header or 'db NORTH' in header or 'db EAST' in header or 'db WEST' in header:
                    errors.append(f'{name}: outdoor tileset needs reviewed Field Moves decoder')
                continue
            tileset=match[1]
            if tileset != 'JOHTO':
                errors.append(f'{name}: new {tileset} native map needs explicit Gold Field Moves review')
                continue
            width,height=int(original['width_blocks']),int(original['height_blocks'])
            cells=decode_cells((gold/f'maps/{name}.blk').read_bytes(),
                 (gold/'data/tilesets/johto_metatiles.bin').read_bytes(),
                 (gold/'data/tilesets/johto_collision.asm').read_text(),width,height)
            roles={c['role'] for c in cells}
            status=entry['feature_status']
            for move,role in (('surf','WATER'),('cut','CUT_TREE')):
                expected='ALLOWED' if role in roles else 'DEFERRED'
                if status.get(move)!=expected:
                    errors.append(f'{name}: Gold {role} requires {move}={expected}, not {status.get(move)}')
            # FIELD-MOVES-38: Headbutt is deliberately disabled for Route38
            # at the user's request, but every Gold cell remains an exact,
            # fail-closed deferred contract (not a blank capability check).
            headbutt = [(c['y'],c['x']) for c in cells if c['role']=='HEADBUTT_TREE']
            deferred = entry.get('deferred_gold_moves', {})
            deferred_cells = deferred.get('headbutt_tree_yx')
            enabled = any(
                f'IsJohto{stem}HeadbuttTreeAhead::' in runtime
                for stem in (name, name.removesuffix('City')))
            if deferred_cells is not None:
                if deferred_cells != [list(cell) for cell in headbutt]:
                    errors.append(f'{name}: DEFERRED Headbutt coordinates differ from Gold')
                if enabled:
                    errors.append(f'{name}: deferred Headbutt was accidentally enabled')
            elif headbutt and not enabled:
                errors.append(f'{name}: Gold HEADBUTT_TREE requires handler or exact deferred cell contract')
            gold_events=(gold/f'maps/{name}.asm').read_text()
            if re.search(r'(?m)^\s*callback\s+MAPCALLBACK_NEWMAP\s*,\s*\w*Flypoint\w*',gold_events):
                if status.get('fly')!='ALLOWED':
                    errors.append(f'{name}: Gold Flypoint callback requires visited Fly destination')
        except (OSError, ValueError, KeyError) as exc:
            errors.append(f'{name}: cannot verify Gold Field Moves: {exc}')
    return errors


def audit_project(root: Path, gold: Path, expected_version: str | None = None,
                  run_tests: bool = True) -> dict:
    errors = []
    root, gold = root.resolve(), gold.resolve()
    errors.extend(verify_gold(gold))
    errors.extend('FIXED_ID: '+e for e in fixed_id_audit(root, gold_root=gold))
    errors.extend('ROM0_COLLISION: '+e for e in rom0_collision_audit(root))
    errors.extend('EAST_RUNTIME: '+e for e in east_exterior_runtime_audit(root,gold,connections=False))
    errors.extend('ADJACENT_PAIR_RUNTIME: '+e for e in adjacent_pair_runtime_audit(root,gold))
    errors.extend('ROM0_LIST_MENU: '+e for e in rom0_list_menu_bank_audit(root))
    errors.extend('ILEX_GATE: '+v for v in ilex_gate_audit(root,gold))
    if not any(e.startswith('Gold source missing:') for e in errors):
        errors.extend('ROOF: '+v for v in roof_audit(root,gold))
    errors.extend('ILEX_FOREST_P17: '+v for v in forest_p17_audit(root,gold))
    if not (root / 'data/game_version.asm').is_file():
        errors.append('RPP game_version.asm is missing')
    else:
        game_version = (root / 'data/game_version.asm').read_text(encoding='utf-8')
        match = re.search(r'^\s*db\s+"([A-Z]+-\d+\.\d+\.\d+[A-Z]?)@"', game_version, re.M)
        if not match:
            errors.append('cannot read game version from game_version.asm')
        elif expected_version is not None and match.group(1) != expected_version:
            errors.append(f'wrong RPP baseline version: {match.group(1)} != {expected_version}')
    for relative in ('tools/johto_native_maps.json',
                     'tools/johto_door_contracts.json'):
        if not (root / relative).is_file():
            errors.append(f'required tracked Johto audit contract missing: {relative}')
    # CONN-5.62.221: audit real headers, NOT just tests of the guard itself.
    # Run before unittest discovery so any broken registered edge blocks release.
    connections = audit_all_active(root, gold) if not errors else None
    if connections is not None:
        errors.extend('CONNECTION_DISCOVERY: ' + issue for issue in connections['issues'])
        for edge in connections['edges']:
            if edge['status']!='PASS':
                label = (edge.get('current','?')+' '+edge.get('direction','?')+' -> '+edge.get('target','?')
                         if 'current' in edge else str(edge.get('edge')))
                errors.extend('CONNECTION: '+label+': '+err for err in edge['issues'])
    # Independent visual and gate checks must both report findings. Older
    # releases skipped gate diagnostics as soon as a connection failed, which
    # hid a second, unrelated .235B auto-step regression in one run.
    if connections is not None:
        errors.extend('GATEHOUSE_RUNTIME: ' + e for e in gatehouse_behavior_audit(root,gold))
    additional_required_ids = set()
    if not errors:
        onboard_errors, additional_required_ids = door_onboarding_audit(root, gold)
        errors.extend('DOOR_ONBOARDING: ' + e for e in onboard_errors)
        errors.extend('GOLD_DOOR: ' + e for e in gold_door_inspect(gold)['errors'])
        errors.extend('REGION: ' + e for e in region_audit(root))
        errors.extend('WARP: ' + e for e in warp_audit(root, gold))
        errors.extend('TOWN_BIKE: ' + e for e in town_bike_audit(root, gold))
        errors.extend('FIELD_MOVES: ' + e for e in field_move_audit(root, gold))
        errors.extend('MAP_SIGNS: ' + e for e in audit_new_native_map_signs(root, gold))
        errors.extend('NEW_MAP_MOVES: ' + e for e in audit_new_native_field_move_roles(root, gold))
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
        env = dict(os.environ, JOHTO_GOLD_SOURCE=str(gold), JOHTO_GOLD_ROOT=str(gold), PYTHONDONTWRITEBYTECODE='1')
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
            'active_connections': {'status': connections['status'],
                                   'checked': len(connections['edges'])} if connections else None,
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
