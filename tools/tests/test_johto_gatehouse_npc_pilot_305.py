"""REF-305 regression for native counter dialogue and Gold-red Ecruteak Officers."""
from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from johto_gatehouse_npc_pilot_305 import audit, fault_tests

GOLD_ROOT_RAW = os.environ.get("JOHTO_GOLD_SOURCE") or os.environ.get("GOLD_SOURCE_ROOT")
GOLD = Path(GOLD_ROOT_RAW) if GOLD_ROOT_RAW else None


class GatehouseNpcPilot305(unittest.TestCase):
    def test_current_two_gatehouse_npcs_use_native_counter_and_gold_red(self):
        report = audit(ROOT, GOLD)
        self.assertEqual("PASS_STATIC_ONLY", report["status"], report["errors"])
        self.assertFalse(report["rom_built"])
        self.assertFalse(report["device_verified"])
        names = {row["check"] for row in report["checks"]}
        self.assertIn("id23_one_officer_object", names)
        self.assertIn("id62_one_officer_object", names)
        self.assertIn("id23_south_approach_geometry", names)
        self.assertIn("id62_south_approach_geometry", names)
        self.assertIn("id23_counter_tile_long_range_path", names)
        self.assertIn("id62_counter_tile_long_range_path", names)
        self.assertIn("johto_officer_alias_has_gold_red_palette", names)
        self.assertIn("global_kanto_guard_palette_unchanged", names)
        self.assertIn("west_east_dialogue_isolation", names)
        self.assertIn("one_shared_rom_version_ref317", names)

    def test_up_facing_probe_uses_lower_left_not_upper_left(self):
        from johto_gatehouse_npc_pilot_305 import _counter_front_tile_id, GATES
        for gate in GATES:
            self.assertEqual(0x0E, _counter_front_tile_id(ROOT, gate, None))
            blockmap = (ROOT / 'maps/johto_pilot' / (gate['gold_map']+'.runtime.blk')).read_bytes()
            blockset = (ROOT / 'gfx/blocksets/johto_gate.bst').read_bytes()
            block = blockmap[1*5 + 2]
            self.assertEqual(3, block)
            self.assertEqual(0x00, blockset[block*16 + 10])
            self.assertEqual(0x0E, blockset[block*16 + 14])
            self.assertNotEqual(blockset[block*16 + 10], blockset[block*16 + 14])

    def test_interaction_palette_and_sprite_fault_injections_are_rejected(self):
        faults = fault_tests(ROOT, GOLD)
        self.assertGreaterEqual(len(faults), 14)
        self.assertTrue(all(faults.values()), faults)


    @unittest.skipIf(GOLD is None, "set JOHTO_GOLD_SOURCE or GOLD_SOURCE_ROOT")
    def test_both_officers_match_original_gold_maps_and_palette(self):
        report = audit(ROOT, GOLD)
        self.assertEqual("PASS_STATIC_ONLY", report["status"], report["errors"])
        names = {row["check"] for row in report["checks"]}
        for stable_id in (23, 62):
            self.assertIn(f"id{stable_id}_gold_officer_source", names)
            self.assertIn(f"id{stable_id}_gold_simple_text_script", names)
        self.assertIn("gold_day_pal_npc_red_reference", names)


if __name__ == "__main__":
    unittest.main()
