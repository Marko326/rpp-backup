"""Regression tests for the current stable-ID pilot migration audit."""
from pathlib import Path
import os
import shutil
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
import sys
sys.path.insert(0, str(TOOLS))
from johto_pilot_migration_audit import audit_project


REQUIRED_FILES = (
    "constants/region_map_constants.asm", "constants/johto_fixed_map_ids.asm",
    "data/johto_header_descriptors.asm", "data/johto_pilot_runtime_assets.asm",
    "data/johto_pilot_source_resources.asm", "data/johto_pilot_map_headers.asm",
    "data/johto_stable_id_slots.asm", "data/warp_tile_ids.asm",
    "data/johto_indoor_house.asm", "data/johto_gate_runtime.asm", "data/johto_ruins_south_runtime.asm", "engine/johto_pilot_runtime.asm",
    "home/overworld.asm", "home.asm", "engine/overworld/doors.asm",
    "engine/overworld/npc_movement.asm", "engine/overworld/map_name_sign.asm", "engine/fly_town_map_helpers.asm",
    "engine/johto_pilot_town_map_browse.asm", "text/map_names.asm",
    "gfx/tilesets/johto.tilecoll",
    "gfx/tilesets/johto_house.tilecoll",
    "color/data/map_palette_assignments.asm", "color/data/map_palette_sets.asm",
    "color/data/map_palette_constants.asm", "color/data/map_palettes.asm",
    "color/tilesets/johto_gate.asm",
    "maps/johto_pilot/NewBarkTown.gold.blk", "maps/johto_pilot/NewBarkTown.runtime.blk",
    "maps/johto_pilot/Route29.gold.blk", "maps/johto_pilot/Route29.runtime.blk",
    "maps/johto_pilot/CherrygroveCity.gold.blk", "maps/johto_pilot/CherrygroveCity.runtime.blk",
    "maps/johto_pilot/Route30.gold.blk", "maps/johto_pilot/Route30.runtime.blk",
    "maps/johto_pilot/Route31.gold.blk", "maps/johto_pilot/Route31.runtime.blk",
    "maps/johto_pilot/GuideGentsHouse.reference.blk", "maps/johto_pilot/GuideGentsHouse.runtime.blk",
    "maps/johto_pilot/VioletCity.gold.blk", "maps/johto_pilot/VioletCity.runtime.blk",
    "maps/johto_pilot/Route31VioletGate.gold.blk", "maps/johto_pilot/Route31VioletGate.runtime.blk",
    "maps/johto_pilot/Route32.gold.blk", "maps/johto_pilot/Route32.runtime.blk",
    "maps/johto_pilot/Route32RuinsOfAlphGate.gold.blk", "maps/johto_pilot/Route32RuinsOfAlphGate.runtime.blk",
    "maps/johto_pilot/RuinsOfAlphOutside.gold.blk", "maps/johto_pilot/RuinsOfAlphOutside.runtime.blk",
)


class PilotMigrationAuditTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.project = Path(self.tmp.name) / "project"
        self.project.mkdir()
        for relative in REQUIRED_FILES:
            source = ROOT / relative
            target = self.project / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)

    def tearDown(self):
        self.tmp.cleanup()

    def run_audit(self):
        return audit_project(self.project)

    def mutate(self, relative, old, new):
        path = self.project / relative
        text = path.read_text(encoding="utf-8")
        self.assertIn(old, text, f"fixture marker missing: {old}")
        path.write_text(text.replace(old, new, 1), encoding="utf-8")

    def test_current_pilot_baseline_passes_static_audit(self):
        report = self.run_audit()
        self.assertEqual(report["status"], "PASS_STATIC_ONLY", report["errors"])
        self.assertEqual(report["errors"], [])
        self.assertFalse(report["runtime_verified"])
        self.assertFalse(report["rom_built"])
        self.assertFalse(report["phone_accepted"])

    def test_stale_active_map_count_assert_fails_before_assembly(self):
        self.mutate("data/johto_stable_id_slots.asm",
                    "ASSERT NUM_JOHTO_ACTIVE_MAPS == 11",
                    "ASSERT NUM_JOHTO_ACTIVE_MAPS == 6")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("rgbds_literal_active_count_asserts" in e for e in report["errors"]))

    def test_other_literal_active_map_assert_fails_before_assembly(self):
        self.mutate("data/johto_pilot_runtime_assets.asm",
                    "ASSERT NUM_JOHTO_ACTIVE_MAPS == 11",
                    "ASSERT NUM_JOHTO_ACTIVE_MAPS == 6")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("rgbds_literal_active_count_asserts" in e for e in report["errors"]))

    def test_missing_new_town_map_entry_fails_before_assembly(self):
        self.mutate("engine/fly_town_map_helpers.asm",
                    "    ; Slot 8: Route32 (stable ID 7), Gold landmark index 7.\n    db 108, 92\n    dw JohtoPilotRoute32Name\n", "")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("active_slot_town_map_tables" in e for e in report["errors"]))

    def test_missing_new_browse_index_fails_before_assembly(self):
        self.mutate("engine/fly_town_map_helpers.asm",
                    "db 0, 1, 2, 3, 4, 2, 5, 4, 7",
                    "db 0, 1, 2, 3, 4, 2, 5, 4")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("active_slot_town_map_tables" in e for e in report["errors"]))

    def test_wrong_new_browse_index_fails_before_assembly(self):
        self.mutate("engine/fly_town_map_helpers.asm",
                    "db 0, 1, 2, 3, 4, 2, 5, 4, 7",
                    "db 0, 1, 2, 3, 4, 2, 5, 4, 6")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("active_slot_town_map_tables" in e for e in report["errors"]))

    def test_wrong_new_town_map_coords_fails_before_assembly(self):
        self.mutate("engine/fly_town_map_helpers.asm",
                    "    db 108, 92\n    dw JohtoPilotRoute32Name",
                    "    db 104, 92\n    dw JohtoPilotRoute32Name")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("active_slot_town_map_tables" in e for e in report["errors"]))

    def test_wrong_new_town_map_name_fails_before_assembly(self):
        self.mutate("engine/fly_town_map_helpers.asm",
                    'JohtoPilotRoute32Name:: db "Route 32@"',
                    'JohtoPilotRoute32Name:: db "Route 33@"')
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("active_slot_town_map_tables" in e for e in report["errors"]))

    def test_missing_stable_router_assert_fails(self):
        self.mutate("data/johto_stable_id_slots.asm",
                    "ASSERT NUM_JOHTO_ACTIVE_MAPS == 11", "")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("rgbds_literal_active_count_asserts" in e for e in report["errors"]))

    def test_missing_route30_south_record_fails(self):
        self.mutate("data/johto_pilot_map_headers.asm",
                    "    db JOHTO_RUNTIME_MAP_HANDLE\n    ; Existing SOUTH: Gold -5 source offset;",
                    "    ; Existing SOUTH: Gold -5 source offset;")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("route30_connection_header" in error for error in report["errors"]))

    def test_missing_reverse_route31_connection_fails(self):
        self.mutate("data/johto_pilot_source_resources.asm",
                    "    db MAP_REGION_JOHTO, JOHTO_ROUTE_31_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_30_LOCAL_ID\n",
                    "")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("source_connection_topology" in error for error in report["errors"]))

    def test_wrong_registered_door_coordinate_fails(self):
        self.mutate("data/johto_pilot_map_headers.asm",
                    "db 9, 25, 0, JOHTO_REGISTERED_WARP_SELECTOR",
                    "db 9, 24, 0, JOHTO_REGISTERED_WARP_SELECTOR")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("door_object_coordinates" in error for error in report["errors"]))

    def test_indoor_carpet_must_not_be_step_on_warp(self):
        self.mutate("data/warp_tile_ids.asm",
                    "JohtoHouseWarpTileIDs:\n    ; Gold WARP_CARPET_DOWN",
                    "JohtoHouseWarpTileIDs:\n    db $12,$FF\n    ; Gold WARP_CARPET_DOWN")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("door_tile_trigger_classes" in error for error in report["errors"]))

    def test_wrong_automatic_step_direction_fails(self):
        self.mutate("engine/overworld/npc_movement.asm",
                    "ld a, D_DOWN", "ld a, D_UP")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("departure_auto_step_down" in error for error in report["errors"]))

    def test_door_upper_tile_must_remain_passable(self):
        (self.project / "gfx/tilesets/johto.tilecoll").write_bytes(bytes([3, 4, 5, 6, 0x40, 0x5B, 0xFF]))
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("collision_list_contents" in error for error in report["errors"]))

    def test_registered_warp_table_must_keep_both_room_exits(self):
        self.mutate("engine/johto_pilot_runtime.asm",
                    "db MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID\n",
                    "")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("registered_warp_routes" in error for error in report["errors"]))

    def test_sparse_id_125_must_map_to_dense_slot_5(self):
        self.mutate("data/johto_stable_id_slots.asm",
                    "JOHTO_INVALID_ACTIVE_SLOT, 5, JOHTO_INVALID_ACTIVE_SLOT, JOHTO_INVALID_ACTIVE_SLOT ; $70-$7f",
                    "JOHTO_INVALID_ACTIVE_SLOT, 4, JOHTO_INVALID_ACTIVE_SLOT, JOHTO_INVALID_ACTIVE_SLOT ; $70-$7f")
        report = self.run_audit()
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue(any("stable_id_sparse_router" in error for error in report["errors"]))


if __name__ == "__main__":
    unittest.main()
