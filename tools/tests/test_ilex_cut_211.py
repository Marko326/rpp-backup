"""MAP-5.62.211: source contract for current map-expansion Cut permission.
Static proof only, not CPU emulator / successful ROM link or phone playtest.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]

class IlexCutSurfParity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.field=(ROOT/'engine/overworld/field_moves.asm').read_text()
        cls.menu=(ROOT/'engine/menu/start_sub_menus.asm').read_text()
        cls.forest=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        cls.surf=(ROOT/'engine/overworld/johto_union_cave_surf.asm').read_text()
        cls.badge=cls.forest.split('JohtoCutBadgeAllowed::',1)[1]

    def test_surf_policy_stays_original(self):
        s=self.surf.split('JohtoSurfBadgeAllowed::',1)[1].split('JohtoSurfStartOnWater::',1)[0]
        self.assertIn('cp JOHTO_UNION_CAVE',s)
        self.assertIn('cp JOHTO_ROUTE_32',s)
        self.assertIn('wObtainedKantoBadges',s)
        self.assertNotIn('wObtainedJohtoBadges',s)

    def test_cut_has_two_routes_one_helper(self):
        a=self.field.split('TryCut:',1)[1].split('HandleBoulderInteraction::',1)[0]
        b=self.menu.split('\n.cut\n',1)[1].split('\n.surf\n',1)[0]
        self.assertEqual(a.count('callba JohtoCutBadgeAllowed'),1)
        self.assertEqual(b.count('callba JohtoCutBadgeAllowed'),1)
        self.assertIn('jr nc, .cannotCut',a)
        self.assertIn('jp nc, .newBadgeRequired',b)
        self.assertIn('ld d, CUT\n\tcall HasPartyMove',a)
        self.assertIn('predef UsedCut',b)
        self.assertNotIn('wObtainedJohtoBadges',a+b)

    def test_policy_exact_map_exception_then_old_kanto(self):
        s=self.badge
        for check in ('cp JOHTO_ILEX_FOREST', 'cp REGION_NATIVE_MAP_SLOT',
                      'cp MAP_REGION_JOHTO', 'cp JOHTO_ILEX_FOREST_LOCAL_ID'):
            self.assertIn(check,s)
        exception=s.split('\n.kanto\n',1)[0]
        self.assertTrue(exception.rstrip().endswith('scf\n\tret'))
        self.assertNotIn('wObtainedJohtoBadges',s)
        self.assertRegex(s,r'(?s)\.kanto\n\tld a, \[wObtainedKantoBadges\]\n\tbit 1, a ; CASCADE_BADGE.*?jr z, \.denied')
        self.assertTrue(s.rstrip().endswith('and a\n\tret'))

    def test_forest_collision_cut_target_and_ledge_pause_preserved(self):
        cut=(ROOT/'engine/overworld/cut.asm').read_text()
        ledges=(ROOT/'engine/overworld/ledges.asm').read_text()
        self.assertIn('callba JohtoIlexForestRemoveCutTree',cut)
        self.assertIn('call JohtoIlexForestCutTreeCleared',self.forest)
        self.assertIn('cp $2d',self.forest)
        self.assertIn('INCBIN "maps/JohtoIlexForest.blocked_mask.bin"',self.forest)
        branch=ledges.split('\n.ilexForest\n',1)[1].split('\n.route33\n',1)[0]
        instructions=[s.strip() for s in branch.splitlines() if s.strip() and not s.lstrip().startswith(';')]
        self.assertEqual(instructions,['ret'])

    def test_doc_only_requires_map_playtest_not_farfetchd_story(self):
        doc=(ROOT/'docs/ILEX_CUT_211_MAP_EXPANSION_CONTRACT.md').read_text()
        self.assertIn('剧情不作为',doc)
        self.assertIn('手机实测',doc)
        self.assertIn('Cut 招式',doc)

if __name__=='__main__': unittest.main()
