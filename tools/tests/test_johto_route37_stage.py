"""Route37 Gold geometry, staged north border and ID21 negative regression.

This is static candidate acceptance only; it is not a ROM/phone result.
"""
from pathlib import Path
import json
import os
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
sys.path.insert(0, str(ROOT / 'tools'))
from johto_indoor_collision_adapter import plan_gold_quadrant_collision
from ledge_regression_audit import audit as ledge_audit, coordinate_hops, expected_gold_hops
from johto_rpp_connection_guard import audit as connection_audit


class Route37Stage(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD / 'maps/Route37.blk').is_file():
            raise AssertionError('complete original Gold Route37 source required')

    def test_gold_geometry_blockset_and_mask_exact(self):
        src = (ROOT / 'maps/JohtoRoute37.blk').read_bytes()
        self.assertEqual(len(src), 90)  # 10x9 blocks
        self.assertEqual(src, (GOLD / 'maps/Route37.blk').read_bytes())
        gold_blockset = (GOLD / 'data/tilesets/johto_metatiles.bin').read_bytes()
        rpp_blockset = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        for block_id in set(src):
            self.assertEqual(rpp_blockset[16*block_id:16*(block_id+1)],
                             gold_blockset[16*block_id:16*(block_id+1)])
        plan, mask = plan_gold_quadrant_collision(GOLD, 'Route37', 'johto')
        self.assertEqual((plan['width_cells'], plan['height_cells']), (20, 18))
        self.assertEqual((ROOT / 'maps/JohtoRoute37.blocked_mask.bin').read_bytes(), mask)

    def test_gold_jump_table_exact_and_safe(self):
        asm = (ROOT / 'engine/overworld/ledges.asm').read_text()
        self.assertEqual(coordinate_hops(asm, '.route37Hops'),
                         expected_gold_hops(GOLD, 'Route37', 'johto'))
        self.assertEqual(len(coordinate_hops(asm, '.route37Hops')), 6)
        self.assertEqual(ledge_audit(ROOT, GOLD)['totals']['route37_coordinate_rules'], 6)

    def test_deleting_a_jump_is_detected(self):
        asm = (ROOT / 'engine/overworld/ledges.asm').read_text()
        before = '\tdb 12, 2, PLAYER_DIR_DOWN\n'
        self.assertIn(before, asm)
        with tempfile.TemporaryDirectory() as folder:
            project = Path(folder)
            for directory in ('maps', 'gfx', 'data', 'constants', 'tools'):
                (project / directory).symlink_to(ROOT / directory, target_is_directory=True)
            target = project / 'engine/overworld/ledges.asm'
            target.parent.mkdir(parents=True)
            target.write_text(asm.replace(before, '', 1), encoding='utf8')
            self.assertTrue(any('JohtoRoute37: Gold HOP missing=' in message
                                for message in ledge_audit(project, GOLD)['errors']))

    def test_south_two_way_and_north_stays_sealed(self):
        route36 = (ROOT / 'data/mapHeaders/JohtoRoute36.asm').read_text()
        route37 = (ROOT / 'data/mapHeaders/JohtoRoute37.asm').read_text()
        collision = (ROOT / 'engine/overworld/johto_route33_collision.asm').read_text()
        self.assertIn('db NORTH | SOUTH | EAST', route36)
        self.assertIn('db SOUTH\n', route37)
        self.assertNotIn('db NORTH |', route37)
        self.assertIn('JohtoRoute37EdgeFence::', collision)
        self.assertIn('JohtoRoute37CanStepAhead::', collision)
        for args in (('JohtoRoute36','JohtoRoute37','Route36','Route37','north'),
                     ('JohtoRoute37','JohtoRoute36','Route37','Route36','south')):
            self.assertEqual(connection_audit(ROOT, GOLD, *args)['status'], 'PASS')

    def test_21_registered_and_22_still_reserved(self):
        registry = json.loads((ROOT / 'tools/johto_native_maps.json').read_text())
        self.assertEqual(len(registry['maps']), 22)
        self.assertEqual(registry['maps'][21]['local_symbol'], 'JOHTO_ROUTE_37_LOCAL_ID')
        self.assertEqual(registry['maps'][21]['identity_evidence'], 'STATIC_PASS')
        self.assertNotIn('JohtoEcruteakCity_h',
                         (ROOT / 'data/johto_map_headers.asm').read_text())


if __name__ == '__main__':
    unittest.main()
