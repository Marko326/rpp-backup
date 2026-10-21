"""Historical .209 pause; .217 shared dispatcher accepted on phone, static tests still matter."""
from pathlib import Path
import re
import unittest
import sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from ledge_regression_audit import audit, pairs, FOREST_ACTIONS, mask_blocked

class ForestCommonLedgeCandidate(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.home=(ROOT/'home/overworld.asm').read_text()
        cls.ledges=(ROOT/'engine/overworld/ledges.asm').read_text()

    def test_forest_uses_native_tile_pairs_and_common_dispatch(self):
        dispatch=self.ledges.split('\n.ilexForest\n',1)[1].split('\n.route33\n',1)[0]
        instructions=[s.strip() for s in dispatch.splitlines() if s.strip() and not s.lstrip().startswith(';')]
        self.assertEqual(instructions,['ld hl, JohtoIlexForestLedgeTiles','jp .checkPairs'])
        self.assertRegex(self.ledges,r'cp JOHTO_ILEX_FOREST\n\tjp z, \.ilexForest')

    def test_forest_does_not_change_common_input_count(self):
        tail=self.ledges.split('\n.foundMatch\n',1)[1].split('\nJohtoIlexForestLedgeTiles:',1)[0]
        self.assertIn('call StartSimulatingJoypadStates',tail)
        self.assertIn('ld a, $2\n\tld [wSimulatedJoypadStatesIndex], a',tail)
        self.assertNotIn('cp JOHTO_ILEX_FOREST',tail)

    def test_common_jump_bypasses_mask_during_midair(self):
        land=self.home.split('.checkLandCollision\n',1)[1].split('CheckTilePassable::',1)[0]
        self.assertIn('bit 6,a ; is the player jumping?',land)
        self.assertIn('jr nz,.noCollision',land)
        self.assertIn('call CheckForJumpingAndTilePairCollisions',land)
        self.assertIn('call CheckTilePassable',land)

    def test_common_animation_restored_without_207_208_gate(self):
        wrapper=self.home.split('HandleMidJump::',1)[1].split('EnterMap::',1)[0]
        self.assertIn('jpba _HandleMidJump',wrapper)
        self.assertNotIn('wWalkCounter',wrapper)
        before=self.home.split('OverworldLoopLessDelay::',1)[1].split('call JoypadOverworld',1)[0]
        self.assertIn('call nz, HandleMidJump',before)
        self.assertNotIn('wSimulatedJoypadStatesIndex',before)
        self.assertNotIn('.ledgeInputReady',before)

    def test_legacy_tables_remain(self):
        self.assertEqual(len(pairs(self.ledges,'LedgeTiles')),8)
        self.assertEqual(len(pairs(self.ledges,'JohtoRoute29LedgeTiles')),4)
        self.assertEqual(len(pairs(self.ledges,'JohtoRoute31LedgeTiles')),5)
        self.assertEqual(len(pairs(self.ledges,'JohtoIlexForestLedgeTiles')),3)
        self.assertIn('.route33Hops',self.ledges)
        self.assertIn('.azaleaHops',self.ledges)

    def test_forest_hop_front_cells_still_blocked_for_regular_walking(self):
        mask=(ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
        self.assertEqual(len(mask),216)
        for x,y,dx,dy in FOREST_ACTIONS:
            self.assertTrue(mask_blocked(mask,x+dx,y+dy), (x,y,dx,dy))
            self.assertFalse(mask_blocked(mask,x,y), (x,y,dx,dy))
            self.assertFalse(mask_blocked(mask,x+2*dx,y+2*dy), (x,y,dx,dy))
        collision=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        self.assertIn('jp JohtoModernMaskedStep',collision)

    def test_cut_existing_engine_is_preserved(self):
        self.assertIn('TryCut:',(ROOT/'engine/overworld/field_moves.asm').read_text())
        self.assertIn('Cut2::',(ROOT/'engine/overworld/cut.asm').read_text())
        self.assertIn('AnimCut:',(ROOT/'engine/overworld/cut2.asm').read_text())
        self.assertIn('Cut and other NPCs deferred',(ROOT/'data/mapObjects/JohtoIlexForest.asm').read_text())

    def test_issue_and_warning_are_visible(self):
        issue=(ROOT/'docs/ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md').read_text()
        self.assertIn('ILEX-LEDGE-001',issue)
        self.assertIn('CUT',issue)
        self.assertIn('ROM 和实机待验',issue)
        current = (ROOT/'data/game_version.asm').read_text()
        match = __import__('re').search(r'SPID-5\.62\.(\d+)@', current)
        self.assertIsNotNone(match)
        self.assertGreaterEqual(int(match[1]), 230)

    def test_map_audit_retains_geometry_inventory_without_claiming_runtime(self):
        data=audit(ROOT)
        self.assertEqual(data['errors'],[], data['errors'])
        self.assertEqual(data['totals']['johto_native_pair_approaches'],95)
        self.assertEqual(data['totals']['modern_coordinate_rules'],35)
        self.assertEqual(data['totals']['route38_coordinate_rules'],24)

if __name__=='__main__':
    unittest.main()
