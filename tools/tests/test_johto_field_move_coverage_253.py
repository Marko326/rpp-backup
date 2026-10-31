"""ROUTES-253: complete field-move coverage over all active Johto maps."""
from pathlib import Path
import os
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_field_move_coverage_audit import audit, _ledge_table_for_map
from johto_gold_door_audit import GoldCollisionIndex

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None


class JohtoFieldMoveCoverage253(unittest.TestCase):
    @unittest.skipIf(GOLD is None, 'Gold reference root required for complete source inventory')
    def test_all_active_water_cut_and_hop_cells_are_registered(self):
        result = audit(ROOT, GOLD)
        self.assertEqual('PASS', result['status'], result['errors'])
        self.assertEqual({'active_maps': 21, 'water_cells': 1098, 'cut_trees': 8, 'hop_cells': 116},
                         result['totals'])
        rows = {row['map']: row for row in result['rows']}
        self.assertEqual((8, 'REGISTERED'), (rows['NewBarkTown']['water_cells'], rows['NewBarkTown']['surf']))
        self.assertEqual((2, 'REGISTERED', 35, 'REGISTERED'),
                         (rows['Route29']['cut_trees'], rows['Route29']['cut'],
                          rows['Route29']['hop_cells'], rows['Route29']['ledge']))
        self.assertEqual((1, 'REGISTERED', 6, 'REGISTERED', 'JohtoPilotRoute31LedgeTiles'),
                         (rows['Route32']['cut_trees'], rows['Route32']['cut'],
                          rows['Route32']['hop_cells'], rows['Route32']['ledge'],
                          rows['Route32']['ledge_table']))
        self.assertEqual((14, 16, 'REGISTERED', 'JohtoAlphSouthHops'),
                         (rows['RuinsOfAlphOutside']['hop_cells'],
                          rows['RuinsOfAlphOutside']['safe_hop_directions'],
                          rows['RuinsOfAlphOutside']['ledge'],
                          rows['RuinsOfAlphOutside']['ledge_table']))
        self.assertEqual((6, 7, 'REGISTERED', 'JohtoRoute33Hops'),
                         (rows['Route33']['hop_cells'], rows['Route33']['safe_hop_directions'],
                          rows['Route33']['ledge'], rows['Route33']['ledge_table']))
        self.assertFalse(result['runtime_verified'])
        self.assertFalse(result['rom_built'])
        self.assertFalse(result['phone_accepted'])

    @unittest.skipIf(GOLD is None, 'Gold reference root required for water/collision comparison')
    def test_newbark_water_is_exact_gold_and_not_walkable_without_surf(self):
        gold = GoldCollisionIndex(GOLD)
        water = {(c['y'], c['x']) for c in gold.cells('NewBarkTown').values()
                 if c['role'] == 'WATER'}
        self.assertEqual({(y, x) for y in (6, 7, 8, 9) for x in (18, 19)}, water)
        runtime = (ROOT / 'maps/johto_pilot/NewBarkTown.runtime.blk').read_bytes()
        blockset = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        passable = set((ROOT / 'gfx/tilesets/johto.tilecoll').read_bytes()) - {0xff}
        self.assertEqual(10 * 9, len(runtime))
        for y, x in water:
            block = runtime[(y // 2) * 10 + x // 2]
            art = blockset[block * 16:(block + 1) * 16]
            row, col = (y % 2) * 2, (x % 2) * 2
            visual = {art[(row + dy) * 4 + col + dx]
                      for dy in range(2) for dx in range(2)}
            self.assertFalse(visual & passable, (x, y, visual & passable))

    def test_route32_requires_its_own_map_guard(self):
        source = (ROOT / 'engine/overworld/ledges.asm').read_text()
        self.assertEqual('JohtoPilotRoute31LedgeTiles', _ledge_table_for_map(source, 'Route32'))
        broken = source.replace('cp JOHTO_ROUTE_32_LOCAL_ID\n\tjr z, .route31PairTable',
                                'cp JOHTO_ROUTE_33_LOCAL_ID\n\tjr z, .route31PairTable', 1)
        self.assertIsNone(_ledge_table_for_map(broken, 'Route32'))

    def test_cut_tree_route_table_covers_each_route_tree(self):
        source = (ROOT / 'engine/johto_violet_field_skills.asm').read_text()
        self.assertIn('db JOHTO_ROUTE_29_LOCAL_ID, 9, 30, $63', source)
        self.assertIn('db JOHTO_ROUTE_29_LOCAL_ID, 11, 21, $5f', source)
        self.assertIn('db JOHTO_ROUTE_30_LOCAL_ID, 6, 8, $67', source)
        self.assertIn('db JOHTO_ROUTE_31_LOCAL_ID, 5, 13, $5f', source)
        self.assertIn('db JOHTO_ROUTE_31_LOCAL_ID, 10, 25, $5b', source)
        self.assertIn('db JOHTO_ROUTE_32_LOCAL_ID, 19, 10, $63', source)
        self.assertIn('(x=36,y=19)', source)  # Violet's separate map-local Cut helper.


if __name__ == '__main__':
    unittest.main()
