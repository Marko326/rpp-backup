"""Gold-source complete ledge coverage and negative mutation regression.

Counts alone cannot catch a missing or mislocated Gold jump. Native RPP
Route31 is 20 blocks wide; an old audit accidentally decoded it as 10.
"""
from pathlib import Path
import os
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from ledge_regression_audit import audit, expected_gold_hops, coordinate_hops
from johto_indoor_collision_adapter import plan_gold_quadrant_collision

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))


class JohtoLedgeGoldCoverage217(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD / 'maps/AzaleaTown.blk').is_file():
            raise AssertionError('complete Gold reference source is mandatory')
        cls.src = (ROOT / 'engine/overworld/ledges.asm').read_text()

    def mutated_audit(self, original, altered):
        """Overlay only the edited ledge file, never mutate the project."""
        self.assertIn(original, self.src)
        with tempfile.TemporaryDirectory() as folder:
            tmp = Path(folder)
            for name in ('maps', 'gfx', 'data'):
                (tmp / name).symlink_to(ROOT / name, target_is_directory=True)
            (tmp / 'constants').symlink_to(ROOT / 'constants', target_is_directory=True)
            (tmp / 'tools').symlink_to(ROOT / 'tools', target_is_directory=True)
            path = tmp / 'engine/overworld/ledges.asm'
            path.parent.mkdir(parents=True)
            path.write_text(self.src.replace(original, altered, 1))
            return audit(tmp, GOLD)

    def test_exact_gold_inventory_of_all_eight_johto_ledge_maps(self):
        result = audit(ROOT, GOLD)
        self.assertEqual(result['errors'], [], result['errors'])
        self.assertEqual(result['totals']['johto_native_pair_approaches'], 95)
        self.assertEqual(result['totals']['modern_coordinate_rules'], 17)
        self.assertEqual(len(expected_gold_hops(GOLD, 'Route31', 'johto')), 14)
        self.assertEqual(len(expected_gold_hops(GOLD, 'AzaleaTown', 'johto_modern')), 10)
        self.assertEqual(coordinate_hops(self.src, '.azaleaHops'),
                         expected_gold_hops(GOLD, 'AzaleaTown', 'johto_modern'))

    def test_azalea_sign_jump_lands_at_second_cell_despite_third_wall(self):
        geom, mask = plan_gold_quadrant_collision(GOLD, 'AzaleaTown', 'johto_modern')
        actual = {(v['x'], v['y'], v['dx'], v['dy']) for v in geom['hops']}
        self.assertIn((10, 6, 0, 1), actual)
        self.assertEqual(geom['unsafe_hop_candidates'], [])
        stride = geom['mask_row_bytes']
        blocked = lambda x, y: bool(mask[y * stride + x//8] & (1 << x%8))
        self.assertFalse(blocked(10, 6))
        self.assertTrue(blocked(10, 7))
        self.assertFalse(blocked(10, 8))
        self.assertTrue(blocked(10, 9))

    def test_deleted_gold_azalea_hop_is_rejected(self):
        result = self.mutated_audit('\tdb 10, 6, PLAYER_DIR_DOWN\n', '')
        self.assertTrue(any('JohtoAzaleaTown: Gold HOP missing=' in e and
                            '(10, 6, 0, 1)' in e for e in result['errors']), result['errors'])

    def test_wrong_azalea_direction_is_rejected(self):
        result = self.mutated_audit('db 10, 6, PLAYER_DIR_DOWN',
                                    'db 10, 6, PLAYER_DIR_LEFT')
        self.assertTrue(any('JohtoAzaleaTown: Gold HOP missing=' in e and
                            'extra=' in e for e in result['errors']), result['errors'])

    def test_modern_map_dispatch_mutation_is_rejected(self):
        result = self.mutated_audit('cp JOHTO_AZALEA_TOWN_LOCAL_ID\n\tret nz',
                                    'cp JOHTO_ROUTE_33_LOCAL_ID\n\tret nz')
        self.assertTrue(any('ledge runtime dispatcher changed' in e for e in result['errors']),
                        result['errors'])

    def test_gold_route31_pair_mutation_is_rejected(self):
        result = self.mutated_audit('db SPRITE_FACING_RIGHT, $06,$30,D_RIGHT',
                                    'db SPRITE_FACING_RIGHT, $06,$31,D_RIGHT')
        self.assertTrue(any('JohtoRoute31: Gold HOP missing=' in e for e in result['errors']),
                        result['errors'])

    def test_absent_gold_source_never_returns_green(self):
        result = audit(ROOT, GOLD / 'missing-reference')
        self.assertTrue(any('complete Gold source is required' in e for e in result['errors']))


if __name__ == '__main__':
    unittest.main()
