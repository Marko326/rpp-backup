"""SAV-244 static contract for old-save tileset-pointer recovery.

No emulator or ROM linker is run: tests guard the branch semantics and an
intentional regression injection. The owner validates Continue in-game.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def read(name):
    return (ROOT / name).read_text(encoding="utf-8")


def old_save_branch(overworld):
    header = overworld.split("LoadMapHeader::", 1)[1].split("CopyMapConnectionHeader::", 1)[0]
    return header.split("\tbit 7,b", 1)[1].split("\n.readMapHeader\n", 1)[0]


class TestSaveTilesetReload244(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.overworld = read("home/overworld.asm")
        cls.save = read("engine/save.asm")
        cls.tilesets = read("engine/overworld/tileset_header.asm")

    def test_continue_sets_old_save_flag(self):
        self.assertRegex(self.save, r"ld hl, wCurMapTileset\s+set 7, \[hl\]")

    def test_old_save_rebuilds_pointers_without_reading_rom_map_header(self):
        code = old_save_branch(self.overworld)
        self.assertRegex(code, r"^\s*jr z, \.readMapHeader")
        self.assertNotIn("ret nz", code)
        for statement in (
            "ld a, [wDestinationWarpID]", "push af", "ld a, $ff",
            "ld [wDestinationWarpID], a", "predef LoadTilesetHeader",
            "pop af", "ret",
        ):
            self.assertIn(statement, code)
        self.assertLess(code.index("push af"), code.index("predef LoadTilesetHeader"))
        self.assertLess(code.index("predef LoadTilesetHeader"), code.index("pop af"))
        self.assertLess(code.index("pop af"), code.rindex("ld [wDestinationWarpID], a"))
        self.assertTrue(self.overworld.index(".readMapHeader") < self.overworld.index(".kantoHeader"))

    def test_tileset_predef_copies_pointer_block_and_guard_prevents_relocation(self):
        self.assertIn("ld de, wTilesetBank", self.tilesets)
        self.assertIn("ld c, $b", self.tilesets)
        self.assertIn("ld a, [wDestinationWarpID]", self.tilesets)
        self.assertRegex(self.tilesets, r"cp \$ff\s+jr z, \.done")
        self.assertIn("call LoadDestinationWarpPosition", self.tilesets)

    def test_johto_identity_and_kanto_paths_still_exist(self):
        header = self.overworld.split("LoadMapHeader::", 1)[1].split("CopyMapConnectionHeader::", 1)[0]
        for token in ("callab JohtoPilotSyncMapIdentity", "callab ResolveJohtoHeaderDescriptor",
                      "callab GetKantoMapHeaderPointer", "callba MarkTownVisitedAndLoadMissableObjects"):
            self.assertIn(token, header)
        self.assertIn("callba JohtoValidateSavedRegionState", self.save)

    def test_regression_injection_catches_the_previous_direct_return(self):
        code = old_save_branch(self.overworld)
        bad = code.replace("jr z, .readMapHeader", "ret nz", 1).replace("predef LoadTilesetHeader", "; removed", 1)
        self.assertIn("ret nz", bad)
        self.assertNotIn("predef LoadTilesetHeader", bad)
        self.assertNotEqual(bad, code)
        # The pre-change SAV branch returned directly without any pointer reload.
        def guarded(branch):
            return ("jr z, .readMapHeader" in branch
                    and "predef LoadTilesetHeader" in branch
                    and branch.count("ld [wDestinationWarpID], a") == 2)
        self.assertTrue(guarded(code))
        self.assertFalse(guarded(bad))

    def test_version_is_updated_without_moving_test_branch(self):
        version = read("data/game_version.asm")
        official = re.search(r'db "(?:[A-Z][A-Z0-9]{1,7})-5\.62\.(\d+)@"', version)
        self.assertIsNotNone(official)
        self.assertGreaterEqual(int(official.group(1)), 244)
        self.assertIn('db "TEST-231@"', version)


if __name__ == "__main__":
    unittest.main()
