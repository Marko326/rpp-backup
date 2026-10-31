"""FIX-261: table-length ASSERT regressions without assembling any ROM."""
from pathlib import Path
import os
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from johto_table_assert_preflight import inspect


class ActiveMapTableAssert261(unittest.TestCase):
    FILES = (
        "constants/region_map_constants.asm",
        "engine/menu/options_menu.asm",
        "engine/fly_town_map_helpers.asm",
    )

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for rel in self.FILES:
            target = self.root / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, target)

    def tearDown(self):
        self.tmp.cleanup()

    def mutate(self, rel, old, new):
        path = self.root / rel
        src = path.read_text()
        self.assertIn(old, src)
        path.write_text(src.replace(old, new, 1))

    def check_fails(self, detail):
        issues, tables, active = inspect(self.root)
        self.assertEqual(active, 26)
        self.assertTrue(issues, tables)
        self.assertTrue(any(detail in x for x in issues), issues)

    def test_real_current_tables_all_match(self):
        issues, tables, active = inspect(self.root)
        self.assertEqual(26, active)
        self.assertFalse(issues, issues)
        self.assertEqual(3, len(tables))
        self.assertIn(("engine/menu/options_menu.asm", "JohtoActiveGSCMusic", 26, 26), tables)

    def test_gold_union_cave_mapped_to_final_slot(self):
        music = (self.root / "engine/menu/options_menu.asm").read_text()
        rows = music.split("JohtoActiveGSCMusic::", 1)[1].split("JohtoActiveGSCMusicEnd::", 1)[0]
        song_rows = [line.split(';')[0].strip() for line in rows.splitlines() if line.strip().startswith('db ')]
        self.assertEqual("db MUSIC_GBP_GSC_UNION_CAVE", song_rows[13])
        gold_root = os.environ.get("GOLD_SOURCE_ROOT")
        if gold_root:
            gold = (Path(gold_root) / "data/maps/maps.asm").read_text()
            self.assertIn("map UnionCave1F, TILESET_CAVE, CAVE, LANDMARK_UNION_CAVE, MUSIC_UNION_CAVE,", gold)

    def test_missing_cave_song_fails_before_assembly(self):
        self.mutate("engine/menu/options_menu.asm",
                    "    db MUSIC_GBP_GSC_UNION_CAVE      ; slot13: ID 8 Union Cave 1F (Gold MUSIC_UNION_CAVE)\n", "")
        self.check_fails("got 25 bytes, expected 26")

    def test_extra_song_fails(self):
        self.mutate("engine/menu/options_menu.asm", "JohtoActiveGSCMusicEnd::",
                    " db MUSIC_GBP_GSC_UNION_CAVE\nJohtoActiveGSCMusicEnd::")
        self.check_fails("got 27 bytes, expected 26")

    def test_missing_music_assert_fails(self):
        self.mutate("engine/menu/options_menu.asm",
                    "ASSERT JohtoActiveGSCMusicEnd - JohtoActiveGSCMusic == NUM_JOHTO_ACTIVE_MAPS", "")
        self.check_fails("MISSING: engine/menu/options_menu.asm::JohtoActiveGSCMusic")

    def test_missing_town_map_assert_fails(self):
        self.mutate("engine/fly_town_map_helpers.asm",
                    "ASSERT JohtoPilotTownMapBrowseIndexBySlotEnd - JohtoPilotTownMapBrowseIndexBySlot == NUM_JOHTO_ACTIVE_MAPS", "")
        self.check_fails("MISSING: engine/fly_town_map_helpers.asm::JohtoPilotTownMapBrowseIndexBySlot")

    def test_missing_town_map_index_fails(self):
        s = (self.root / "engine/fly_town_map_helpers.asm").read_text()
        self.assertIn('JohtoPilotTownMapBrowseIndexBySlot:', s)
        # Drop a single db item, independent of the popup name contract.
        import re
        start = s.index('JohtoPilotTownMapBrowseIndexBySlot:')
        stop = s.index('JohtoPilotTownMapBrowseIndexBySlotEnd:')
        head, body, tail = s[:start], s[start:stop], s[stop:]
        m = re.search(r'(?m)^(\s*db\s+)([\d, ]+)\s*(;.*)?$', body)
        self.assertIsNotNone(m)
        operands = m.group(2).strip().split(',')
        self.assertGreater(len(operands), 1)
        replacement = m.group(1) + ','.join(operands[:-1]) + (m.group(3) or '')
        body = body[:m.start()] + replacement + body[m.end():]
        (self.root / "engine/fly_town_map_helpers.asm").write_text(head+body+tail)
        self.check_fails("JohtoPilotTownMapBrowseIndexBySlot")


if __name__ == "__main__":
    unittest.main()
