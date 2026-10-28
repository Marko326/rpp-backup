"""Regression tests for pret/MUS Gold source-root compatibility."""
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
from johto_gold_compat import (
    GoldCompatibilityError,
    compare_gold_sources,
    detect_gold_profile,
    inspect_gold_source,
    resolve_gold_root,
)


CORE_FILES = (
    "main.asm", "Makefile", ".rgbds-version", "data/maps/maps.asm",
    "data/maps/attributes.asm", "data/maps/blocks.asm",
    "constants/map_constants.asm", "gfx/tilesets.asm",
    "engine/overworld/tile_events.asm", "engine/overworld/player_movement.asm",
    "home/map.asm", "engine/overworld/events.asm", "engine/overworld/scripting.asm",
)


def make_source(root: Path, profile: str, rgbds: str = "1.0.0") -> Path:
    for relative in CORE_FILES:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("", encoding="utf-8")
    (root / ".rgbds-version").write_text(rgbds + "\n", encoding="utf-8")
    (root / "data/maps/maps.asm").write_text(
        "map TestTown, TILESET_HOUSE, TOWN, LANDMARK_TEST\n", encoding="utf-8")
    (root / "data/maps/attributes.asm").write_text(
        "map_attributes TestTown, TEST_TOWN, LANDMARK_TEST, MUSIC_NONE\n"
        "\tconnection north, RouteA, ROUTE_A, 0\n", encoding="utf-8")
    (root / "data/maps/blocks.asm").write_text(
        "TestTown_Blocks:\n\tINCBIN \"maps/TestTown.blk\"\n", encoding="utf-8")
    (root / "constants/map_constants.asm").write_text(
        "map_const TEST_TOWN, 1, 1\n", encoding="utf-8")
    (root / "maps/TestTown.blk").parent.mkdir(parents=True, exist_ok=True)
    (root / "maps/TestTown.blk").write_bytes(bytes([0x01, 0x02]))
    (root / "gfx/tilesets").mkdir(parents=True, exist_ok=True)
    (root / "gfx/tilesets/test.bin").write_bytes(bytes([0x01, 0x02]))
    (root / "maps/TestTown.asm").parent.mkdir(parents=True, exist_ok=True)
    (root / "maps/TestTown.asm").write_text(
        "warp_event 1, 2, ROUTE_A, 0\n", encoding="utf-8")
    (root / "data/tilesets/test_collision.asm").parent.mkdir(parents=True, exist_ok=True)
    (root / "data/tilesets/test_collision.asm").write_text("tilecoll FLOOR, FLOOR, FLOOR, FLOOR\n", encoding="utf-8")
    markers = {
        "engine/overworld/tile_events.asm": "CheckWarpCollision::\nCheckDirectionalWarp::\n",
        "engine/overworld/player_movement.asm": "DoPlayerMovement::\n.EdgeWarps:\n",
        "home/map.asm": "CheckWarpTile::\nWarpCheck::\nGetWarpDestCoords::\n",
        "engine/overworld/events.asm": "CheckTileEvent:\nWarpToNewMapScript:\n",
        "engine/overworld/scripting.asm": "Script_warp:\nScript_warpcheck:\n",
    }
    for relative, text in markers.items():
        (root / relative).write_text(text, encoding="utf-8")
    if profile == "mus":
        (root / "data/game_version.asm").write_text('db "MUS-1.0.1@"\n', encoding="utf-8")
        (root / "RPP_PROJECT_CONTEXT").mkdir(parents=True, exist_ok=True)
        (root / "RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt").write_text(
            "项目：MUS-1.0.1\n", encoding="utf-8")
    return root


class GoldCompatTests(unittest.TestCase):
    def test_direct_and_nested_roots_auto_detect_profiles(self):
        with tempfile.TemporaryDirectory() as tmp:
            parent = Path(tmp)
            pret = make_source(parent / "pret" / "pokegold-master", "pret", "1.0.0")
            mus = make_source(parent / "MUS-1.0.1", "mus", "1.0.4")
            self.assertEqual(resolve_gold_root(parent / "pret", "pret"), pret.resolve())
            self.assertEqual(resolve_gold_root(mus, "mus"), mus.resolve())
            self.assertEqual(detect_gold_profile(pret), "pret")
            self.assertEqual(detect_gold_profile(mus), "mus")

    def test_profile_mismatch_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            mus = make_source(Path(tmp) / "MUS", "mus", "1.0.4")
            with self.assertRaises(GoldCompatibilityError):
                resolve_gold_root(mus, "pret")

    def test_source_audit_reports_profile_and_semantic_counts(self):
        with tempfile.TemporaryDirectory() as tmp:
            pret = make_source(Path(tmp) / "pret", "pret")
            report = inspect_gold_source(pret, "pret")
            self.assertEqual(report["status"], "PASS_SOURCE_COMPATIBILITY", report["errors"])
            self.assertEqual(report["registered_maps"], 1)
            self.assertEqual(report["warp_events"], 1)
            self.assertEqual(report["direct_connections"], 1)

    def test_semantically_equal_pret_and_mus_sources_are_compatible(self):
        with tempfile.TemporaryDirectory() as tmp:
            parent = Path(tmp)
            pret = make_source(parent / "pret", "pret", "1.0.0")
            mus = make_source(parent / "MUS", "mus", "1.0.4")
            comparison = compare_gold_sources(pret, mus, "pret", "mus")
            self.assertTrue(comparison["compatible_for_migration_reference"], comparison["differences"])
            self.assertEqual(comparison["first"]["rgbds_version"], "1.0.0")
            self.assertEqual(comparison["second"]["rgbds_version"], "1.0.4")

    def test_semantic_warp_change_is_not_silently_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            parent = Path(tmp)
            pret = make_source(parent / "pret", "pret")
            mus = make_source(parent / "MUS", "mus", "1.0.4")
            (mus / "maps/TestTown.asm").write_text(
                "warp_event 2, 2, ROUTE_A, 0\n", encoding="utf-8")
            comparison = compare_gold_sources(pret, mus)
            self.assertFalse(comparison["compatible_for_migration_reference"])
            self.assertIn("warps", comparison["differences"])

    def test_changed_layout_bytes_are_not_silently_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            pret = make_source(base / "pret", "pret")
            mus = make_source(base / "MUS", "mus")
            (mus / "maps/TestTown.blk").write_bytes(bytes([0x02, 0x01]))
            comparison = compare_gold_sources(pret, mus)
            self.assertFalse(comparison["compatible_for_migration_reference"])
            self.assertIn("layout_sha256", comparison["differences"])

    def test_changed_tileset_assets_are_not_silently_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            pret = make_source(base / "pret", "pret")
            mus = make_source(base / "MUS", "mus")
            (mus / "gfx/tilesets/test.bin").write_bytes(bytes([0x05, 0x06]))
            comparison = compare_gold_sources(pret, mus)
            self.assertFalse(comparison["compatible_for_migration_reference"])
            self.assertIn("tileset_assets_sha256", comparison["differences"])

    def test_missing_referenced_layout_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            pret = make_source(Path(tmp) / "pret", "pret")
            (pret / "maps/TestTown.blk").unlink()
            report = inspect_gold_source(pret)
            self.assertEqual(report["status"], "FAIL")
            self.assertTrue(any("布局文件缺失" in e for e in report["errors"]))

    def test_script_difference_is_reported_separately(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            pret = make_source(base / "pret", "pret")
            mus = make_source(base / "MUS", "mus")
            with (mus / "maps/TestTown.asm").open("a") as f:
                f.write("\n; some event text variation\n")
            comparison = compare_gold_sources(pret, mus)
            self.assertTrue(comparison["compatible_for_migration_reference"])
            self.assertEqual(comparison["map_script_files_differ"], ["TestTown"])
            self.assertTrue(comparison["script_behavior_equivalence_not_proven"])

    def test_multiple_nested_roots_are_rejected_as_ambiguous(self):
        with tempfile.TemporaryDirectory() as tmp:
            parent = Path(tmp)
            make_source(parent / "pret", "pret")
            make_source(parent / "mus", "mus", "1.0.4")
            with self.assertRaises(GoldCompatibilityError):
                resolve_gold_root(parent)


if __name__ == "__main__":
    unittest.main()
