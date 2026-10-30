"""Static guard for Johto Save/Continue names crossing ROM banks.

The project forbids assistant ROM builds. These tests inspect the actual ASM
contract, not a simulated game runtime; phone/ROM validation remains separate.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class JohtoSaveLocationTests(unittest.TestCase):
    def test_both_continue_and_save_call_same_safe_helper(self):
        menu = read("engine/menu/main_menu.asm")
        self.assertEqual(menu.count("callba GetCurrentMapNameForSaveScreen"), 2)
        self.assertNotIn("callba GetMapNameForSaveScreen", menu)

    def test_helper_is_in_floating_johto_browse_bank(self):
        main = read("main.asm")
        self.assertRegex(main, r'SECTION "Johto Gold Town Map Browse", ROMX\s+INCLUDE "engine/johto_pilot_town_map_browse.asm"')
        browse = read("engine/johto_pilot_town_map_browse.asm")
        helper = browse.split("GetCurrentMapNameForSaveScreen::", 1)[1].split("; Gold original browse order", 1)[0]
        self.assertIn("cp JOHTO_RUNTIME_MAP_HANDLE", helper)
        self.assertIn("cp MAP_REGION_JOHTO", helper)
        self.assertIn("callab JohtoPilotGetTownMapLandmark", helper)
        self.assertIn("call LoadJohtoBrowseEntry", helper)
        self.assertIn("ld hl, wBuffer", helper)
        self.assertIn('ld [hl], " "', helper)
        self.assertIn("callab GetMapNameForSaveScreen", helper)
        # Do not feed a cross-bank HL into the old direct-name copy routine.
        self.assertNotIn("call LoadTownMapEntry", helper)

    def test_active_slot_names_fit_save_continue_line(self):
        runtime = read("engine/johto_pilot_runtime.asm")
        section = runtime.split("JohtoPilotMapProfiles::", 1)[1].split("JohtoPilotMapProfilesEnd::", 1)[0]
        landmark_ids = [int(i) for i in re.findall(r"johto_map_profile\s+[01],\s*(\d+),", section)]
        self.assertEqual(landmark_ids, [0, 1, 2, 3, 4, 2, 5, 4, 7, 7, 8])
        browse = read("engine/johto_pilot_town_map_browse.asm")
        entries = browse.split("JohtoBrowseEntries:", 1)[1].split("JohtoBrowseEntriesEnd:", 1)[0]
        labels = re.findall(r"^\s*dw (\w+)\s*$", entries, flags=re.M)
        self.assertEqual(len(labels), 45)
        for i in set(landmark_ids):
            name = labels[i]
            match = re.search(r"^" + re.escape(name) + r':\s*db "([^"]+)@"', browse, flags=re.M)
            self.assertIsNotNone(match, name)
            text = match.group(1).replace("_", " ")
            self.assertLessEqual(len(text), 16, (i, text))

    def test_original_kanto_lookup_and_test_version_remain(self):
        town = read("engine/town_map.asm")
        self.assertIn("GetMapNameForSaveScreen:", town)
        self.assertIn("call LoadTownMapEntry", town.split("GetMapNameForSaveScreen:", 1)[1])
        version = read("data/game_version.asm")
        # Location regression persists across future official feature prefixes.
        match = re.search(r'db "(?:[A-Z][A-Z0-9]{1,7})-5\.62\.(\d+)@"', version)
        self.assertIsNotNone(match)
        self.assertGreaterEqual(int(match.group(1)), 240)
        self.assertIn('db "TEST-231@"', version)


if __name__ == "__main__":
    unittest.main()
