"""SRF-5.62.187: Route32 original Gold water, plus negative mutations."""
from pathlib import Path
import os
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_route32_surf_geometry import check, gold_cells  # noqa: E402
from johto_surf_runtime_audit import audit  # noqa: E402

FILES = ('engine/overworld/johto_union_cave_surf.asm',
         'engine/overworld/field_moves.asm', 'engine/items/items.asm',
         'home/overworld.asm', 'engine/menu/start_sub_menus.asm',
         'tools/johto_native_maps.json', 'main.asm',
         'maps/JohtoRoute32.blk', 'maps/JohtoRoute35.blk', 'maps/JohtoRuinsOfAlphOutside.blk', 'gfx/blocksets/johto.bst',
         'gfx/tilesets/johto.tilecoll',
         'maps/JohtoUnionCave1F.blk',
         'gfx/blocksets/johto_union_cave.bst',
         'gfx/tilesets/johto_union_cave.tilecoll')


class Route32Surf188(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing'))
        if not (cls.gold / 'maps/Route32.blk').is_file():
            raise AssertionError('Gold Route32 is mandatory')

    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in FILES:
            dest = self.root / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, dest)

    def mutate(self, relative, before, after, expected):
        path = self.root / relative
        data = path.read_text()
        self.assertIn(before, data)
        path.write_text(data.replace(before, after, 1))
        self.assertIn(expected, ' '.join(audit(self.root, self.gold)))

    def test_gold_route32_water_bitset_exact(self):
        self.assertEqual(len(gold_cells(self.gold)), 278)
        self.assertEqual(check(self.root, self.gold), [])
        self.assertEqual(audit(self.root, self.gold), [])

    def test_water_map_mutation_must_fail(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    'db $03, $00, $00 ; y=08',
                    'db $02, $00, $00 ; y=08', 'Route32 Surf Gold water bitset mismatch')

    def test_route32_map_guard_mutation_must_fail(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    '\tcp JOHTO_ROUTE_32\n\tjp nz, .notWater',
                    '\tcp JOHTO_ROUTE_31\n\tjp nz, .notWater',
                    'Route32 Surf runtime missing/changed')

    def test_route32_dispatch_mutation_must_fail(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    '\tjp z, IsJohtoRoute32WaterAhead',
                    '\tjp nz, IsJohtoRoute32WaterAhead',
                    'shared Johto Surf dispatch')

    def test_movement_water_branch_reverse_must_fail(self):
        self.mutate('home/overworld.asm',
                    '\tjr c, .noCollision ; water: keep surfing',
                    '\tjr nc, .noCollision ; water: keep surfing',
                    'Surf movement water branch')

    def test_route32_badge_policy_must_not_leak_other_maps(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    '\tcp JOHTO_ROUTE_32\n\tjr z, .route32',
                    '\tcp JOHTO_ROUTE_32\n\tjr nz, .route32',
                    'staged Route35/Route32/cave badge-free Surf permission')

    def test_bits_over_top_edge_fail(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    'db $00, $00, $00 ; y=86',
                    'db $00, $00, $10 ; y=86',
                    'out-of-map bits')

    def test_route35_water_edge_must_stay_bounded(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    'cp 24\n\tjr c, .notWater\n\tcp 32',
                    'cp 23\n\tjr c, .notWater\n\tcp 32',
                    'Route35 Surf runtime missing/changed')

    def test_route35_native_id_must_not_alias_any_other_route(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    'cp JOHTO_ROUTE_35_LOCAL_ID\n\tjr nz, .notWater',
                    'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjr nz, .notWater',
                    'Route35 Surf runtime missing/changed')

    def test_map_features_reject_other_route_surf(self):
        self.mutate('tools/johto_native_maps.json',
                    '"surf": "DEFERRED"', '"surf": "ALLOWED"',
                    'status must be DEFERRED')


if __name__ == '__main__':
    unittest.main()
