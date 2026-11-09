"""REF-341 Union Cave same-tileset floor Warp landing regression."""
from pathlib import Path
from unittest.mock import patch
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from johto_union_b2f_340_audit import check


class UnionCaveWarpLanding341(unittest.TestCase):
    def test_union_cave_is_forced_through_destination_rebuild(self):
        result = check(ROOT)
        self.assertEqual("PASS_STATIC_ONLY", result["status"], result["errors"])
        self.assertEqual(0, result["failed"])

    def test_removing_union_cave_from_dungeon_list_is_detected(self):
        original = Path.read_text
        target = (ROOT / "data/dungeon_tilesets.asm").resolve()

        def inject(path, *args, **kwargs):
            text = original(path, *args, **kwargs)
            if path.resolve() == target:
                return re.sub(r",\s*JOHTO_UNION_CAVE(?=,)", "", text, count=1)
            return text

        with patch.object(Path, "read_text", inject):
            result = check(ROOT)
        self.assertEqual("FAIL", result["status"])
        self.assertIn("union_cave_forces_destination_rebuild", result["errors"])


if __name__ == "__main__":
    unittest.main()
