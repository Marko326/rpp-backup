"""Positive Gold agreement + negative mutations for the cave's 3 Surf paths."""
import os
from pathlib import Path
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_runtime_audit import audit  # noqa: E402

FILES = ('engine/overworld/johto_union_cave_surf.asm',
         'engine/overworld/field_moves.asm', 'engine/items/items.asm',
         'engine/menu/start_sub_menus.asm', 'home/overworld.asm',
         'tools/johto_native_maps.json', 'main.asm',
         'maps/JohtoUnionCave1F.blk',
         'gfx/blocksets/johto_union_cave.bst',
         'gfx/tilesets/johto_union_cave.tilecoll',
         'maps/JohtoRoute32.blk', 'maps/JohtoRoute35.blk', 'maps/JohtoRuinsOfAlphOutside.blk', 'maps/JohtoEcruteakCity.blk', 'gfx/blocksets/johto.bst',
         'gfx/tilesets/johto.tilecoll')


class CaveSurfRuntime187(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/no-gold'))
        if not (cls.gold / 'maps/UnionCave1F.blk').is_file():
            raise AssertionError('Gold source required for runtime Surf tests')

    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in FILES:
            p = self.root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, p)

    def mutation(self, rel, before, after, expected):
        p = self.root / rel
        text = p.read_text()
        self.assertIn(before, text)
        p.write_text(text.replace(before, after, 1))
        self.assertIn(expected, ' '.join(audit(self.root, self.gold)))

    def test_all_64_gold_cells_exact(self):
        self.assertEqual(audit(self.root, self.gold), [])

    def test_coordinate_alias_drift_fails(self):
        self.mutation('engine/overworld/johto_union_cave_surf.asm',
                      '\tdb 4, 6\n', '\tdb 4, 5\n', 'coordinates differ')

    def test_reversing_surf_movement_water_branch_fails(self):
        self.mutation('home/overworld.asm',
                      '\tjr c, .noCollision ; water:',
                      '\tjr nc, .noCollision ; water:', 'movement water branch')

    def test_missing_party_surf_permission_check_fails(self):
        self.mutation('engine/menu/start_sub_menus.asm',
                      'callba JohtoSurfBadgeAllowed\n\tjp nc, .newBadgeRequired',
                      'callba JohtoSurfBadgeAllowed\n\tjp c, .newBadgeRequired',
                      'party menu shared permission check')

    def test_reintroduced_fog_badge_requirement_fails(self):
        self.mutation('engine/overworld/johto_union_cave_surf.asm',
                      '.johtoAllowed\n\tscf\n\tret\n.kanto',
                      '.johtoAllowed\n\tld a, [wObtainedJohtoBadges]\n\tbit 3, a ; FOG_BADGE\n\tjr z, .denied\n\tscf\n\tret\n.kanto',
                      'staged Johto Surf must not require Fog Badge')

    def test_kanto_soul_badge_rule_cannot_change(self):
        self.mutation('engine/overworld/johto_union_cave_surf.asm',
                      '\tbit 4, a ; SOUL_BADGE', '\tbit 3, a ; SOUL_BADGE',
                      'Kanto Soul Badge preserved')

    def test_missing_bag_surf_guard_fails(self):
        self.mutation('engine/overworld/johto_union_cave_surf.asm',
                      '\tccf ; invert water-ahead carry for Surfboard convention',
                      '\tret ; incorrect polarity', 'Surfboard water-only and carry polarity')

    def test_forbidden_surf_scope_expansion_fails(self):
        self.mutation('tools/johto_native_maps.json',
                      '"surf": "DEFERRED"', '"surf": "ALLOWED"',
                      'status must be DEFERRED')

if __name__ == '__main__':
    unittest.main()
