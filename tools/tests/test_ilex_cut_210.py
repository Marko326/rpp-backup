"""Gold Ilex Forest CUT_TREE contract for the .210 source candidate.

This does not emulate a Game Boy CPU or certify ROM/link/phone behavior.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class IlexCutContract(unittest.TestCase):
    def test_unique_gold_cut_tree_quadrant(self):
        gold = Path(__file__).parents[4] / "gold" / "pokegold-master"
        # Test is runnable independent of a separately unpacked Gold tree.
        # Canonical original map coordinate and block identity are locked here.
        blk = (ROOT / "maps/JohtoIlexForest.blk").read_bytes()
        self.assertEqual(len(blk), 15 * 27)
        self.assertEqual(blk[12 * 15 + 4], 0x0F)
        self.assertEqual(blk.count(0x0F), 1)

    def test_tree_clone_only_removes_bottom_left_quadrant(self):
        blob = (ROOT / "gfx/blocksets/johto_ilex_forest.bst").read_bytes()
        self.assertEqual(len(blob), 46 * 16)
        src = blob[15 * 16:16 * 16]
        dst = blob[45 * 16:46 * 16]
        self.assertEqual(src[8:10], bytes([0x28, 0x39]))
        self.assertEqual(src[12:14], bytes([0x38, 0x3A]))
        for i in range(16):
            self.assertEqual(dst[i], 0x05 if i in (8, 9, 12, 13) else src[i])
        # Cut target is (8,25); headbutt neighbor (9,25) must be untouched.
        self.assertEqual(dst[10:12], src[10:12])
        self.assertEqual(dst[14:16], src[14:16])

    def test_both_entry_points_reuse_cut2_and_share_map_scoped_permission(self):
        field = (ROOT / "engine/overworld/field_moves.asm").read_text()
        menu = (ROOT / "engine/menu/start_sub_menus.asm").read_text()
        cut = (ROOT / "engine/overworld/cut.asm").read_text()
        self.assertIn("callba JohtoIlexForestCutTreeInFront", field)
        self.assertIn("callba JohtoIlexForestCutTreeInFront", cut)
        self.assertIn("callba JohtoIlexForestRemoveCutTree", cut)
        self.assertIn("farcall Cut2", field)
        self.assertIn("predef UsedCut", menu)
        # Both routes go through one policy (Surf-style), not separate badge bits.
        for s in (field, menu):
            self.assertIn("callba JohtoCutBadgeAllowed", s)
            self.assertNotIn("wObtainedJohtoBadges", s)
        policy = (ROOT / "engine/overworld/johto_ilex_forest_collision.asm").read_text().split("JohtoCutBadgeAllowed::", 1)[1]
        self.assertIn("cp JOHTO_ILEX_FOREST", policy)
        self.assertIn("cp JOHTO_ILEX_FOREST_LOCAL_ID", policy)
        self.assertNotIn("wObtainedJohtoBadges", policy)
        self.assertIn("wObtainedKantoBadges", policy)
        self.assertIn("bit 1, a ; CASCADE_BADGE", policy)

    def test_collision_opens_only_the_cleared_cut_target(self):
        src = (ROOT / "engine/overworld/johto_ilex_forest_collision.asm").read_text()
        self.assertIn("call JohtoIlexForestCutTreeCleared", src)
        self.assertIn("cp $2d", src)
        self.assertIn("cp $0f", src)
        self.assertIn("ld [hl], a", src)
        self.assertIn('INCBIN "maps/JohtoIlexForest.blocked_mask.bin"', src)
        self.assertIn('cp 8', src)
        self.assertIn('cp 25', src)
        self.assertIn("JohtoModernMaskedStep", src)
        # CUT collision remains isolated when Forest uses common HOP tile pairs.
        ledge = (ROOT / "engine/overworld/ledges.asm").read_text()
        branch=ledge.split('\n.ilexForest\n',1)[1].split('\n.route33\n',1)[0]
        instructions=[s.strip() for s in branch.splitlines() if s.strip() and not s.lstrip().startswith(';')]
        self.assertEqual(instructions,['ld hl, JohtoIlexForestLedgeTiles','jp .checkPairs'])

    def test_reuse_old_live_map_pointer_math(self):
        legacy = (ROOT / "engine/overworld/cut.asm").read_text()
        forest = (ROOT / "engine/overworld/johto_ilex_forest_collision.asm").read_text()
        for s in (legacy, forest):
            for needle in ("wCurrentTileBlockMapViewPointer", "wXBlockCoord", "wYBlockCoord", "wSpriteStateData1 + 9"):
                self.assertIn(needle, s)
        self.assertIn("ld a, $2d", forest)

    def test_209_ledge_issue_is_preserved_as_history(self):
        issue = (ROOT / "docs/ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md").read_text()
        self.assertIn("DEFERRED", issue)
        self.assertIn("ILEX-LEDGE-001", issue)
        self.assertIn("SPID-5.62.227@", (ROOT / "data/game_version.asm").read_text())


if __name__ == "__main__":
    unittest.main()
