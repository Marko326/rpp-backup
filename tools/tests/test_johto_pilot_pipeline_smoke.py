"""Smoke tests for the offline Gold->current-RPP candidate staging modes.

Requires JOHTO_GOLD_SOURCE to point at the user-provided pokegold-master tree.
All outputs are written under a temporary directory, never into the project.
"""
from pathlib import Path
import os
import shutil
import tempfile
import unittest
import sys

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
from johto_gold_connection_reference import check_frozen_gold_source, ConnectionError
from johto_rpp_pipeline import stage_adjacent_pair, stage_gold_map_candidate, review_rpp_integration
from johto_pilot_migration_audit import audit_project


class PilotPipelineSmokeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        configured = os.environ.get("JOHTO_GOLD_SOURCE")
        if not configured or not (Path(configured) / "data/maps/attributes.asm").is_file():
            raise unittest.SkipTest("set JOHTO_GOLD_SOURCE to the provided pokegold-master source")
        cls.gold = Path(configured).resolve()

    def test_route30_route31_pair_is_staged_from_gold_and_not_runtime_approved(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "pair"
            report = stage_adjacent_pair(ROOT, self.gold, out, ("Route30", "Route31"))
            self.assertEqual(report["status"], "OFFLINE_PAIR_REVIEW_REQUIRED")
            self.assertTrue(report["source_geometry_verified"])
            self.assertFalse(report["runtime_approved"])
            self.assertEqual([(x["from"], x["to"], x["gold_offset_blocks"]) for x in report["direct_seams"]],
                             [("Route30", "Route31", -10), ("Route31", "Route30", 10)])
            for row in report["maps"]:
                self.assertTrue(row["staged_blk_matches_gold"])
                self.assertFalse(row["runtime_approved"])

    def test_route30_candidate_matches_current_stable_id_header(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "route30"
            report = stage_gold_map_candidate(
                ROOT, self.gold, out, "Route30", "johto",
                "JohtoPilotRoute30RuntimeHeader", runtime_gate=True)
            self.assertEqual(report["status"], "OFFLINE_REVIEW_REQUIRED")
            self.assertEqual(report["errors"], [])
            self.assertTrue(report["staged_blk_matches_gold"])
            integration = (out / "rpp_integration_review.json").read_text(encoding="utf-8")
            self.assertIn('"stable_local_id": 3', integration)
            self.assertIn('"registered_active_map": true', integration)
            preflight = (out / "rpp_runtime_preflight.json").read_text(encoding="utf-8")
            self.assertIn('PROJECT_STATIC_PASS_MAP_RUNTIME_PENDING', preflight)

    def test_guide_house_candidate_uses_current_header_contract_but_stays_unapproved(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "house"
            report = stage_gold_map_candidate(
                ROOT, self.gold, out, "GuideGentsHouse", "house",
                "JohtoGuideGentsHouseRuntimeHeader", runtime_gate=True)
            self.assertEqual(report["status"], "OFFLINE_REVIEW_REQUIRED")
            self.assertEqual(report["errors"], [])
            self.assertTrue(report["staged_blk_matches_gold"])
            self.assertFalse(report["runtime_approved"])
            self.assertFalse(report["build_performed"])
            integration = (out / "rpp_integration_review.json").read_text(encoding="utf-8")
            self.assertIn('"stable_local_id": 125', integration)
            preflight = (out / "rpp_runtime_preflight.json").read_text(encoding="utf-8")
            self.assertIn('"phone_accepted": false', preflight)
            self.assertIn('PROJECT_STATIC_PASS_MAP_RUNTIME_PENDING', preflight)

    def test_gold_house_and_current_runtime_render_pixel_identically(self):
        report = audit_project(ROOT, self.gold, os.environ.get("JOHTO_RPP_REFERENCE_SOURCE"))
        self.assertEqual(report["status"], "PASS_STATIC_ONLY", report["errors"])
        visual = report["gold_reference"]["house_visual_comparison"]
        self.assertEqual(visual["status"], "PASS", visual)
        self.assertEqual(visual["different_pixels"], 0)
        # The raw block bytes intentionally differ because Gold and RPP use different block IDs.
        self.assertFalse(visual["gold_block_ids_equal_rpp"])

        with tempfile.TemporaryDirectory() as tmp:
            copy = Path(tmp) / "gold"
            (copy / "data/maps").mkdir(parents=True)
            src = (self.gold / "data/maps/attributes.asm").read_text(encoding="utf-8")
            marker = "connection north, Route31, ROUTE_31, -10"
            self.assertIn(marker, src)
            (copy / "data/maps/attributes.asm").write_text(src.replace(marker, marker.replace("-10", "-9"), 1), encoding="utf-8")
            with self.assertRaises(ConnectionError):
                check_frozen_gold_source(copy)

    def test_candidate_header_cannot_be_mislabeled_as_another_gold_map(self):
        onboarding = {"map": "Route30", "evidence": {"warp_events": 2}}
        report = review_rpp_integration(ROOT, "JohtoGuideGentsHouseRuntimeHeader", onboarding)
        self.assertEqual(report["status"], "STRUCTURAL_ERRORS")
        self.assertTrue(any("does not match active RPP header" in error for error in report["errors"]))


if __name__ == "__main__":
    unittest.main()
