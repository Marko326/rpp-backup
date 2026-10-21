"""Route37 Gold geometry, south Route36 and now north Ecruteak ID22 regression.

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
from johto_map_release_audit import audit_new_native_map_signs, audit_new_native_field_move_roles


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

    def test_south_and_north_both_connect_to_correct_maps(self):
        route36 = (ROOT / 'data/mapHeaders/JohtoRoute36.asm').read_text()
        route37 = (ROOT / 'data/mapHeaders/JohtoRoute37.asm').read_text()
        collision = (ROOT / 'engine/overworld/johto_route33_collision.asm').read_text()
        self.assertIn('db NORTH | SOUTH | EAST', route36)
        self.assertIn('db NORTH | SOUTH', route37)
        self.assertIn('JohtoRoute37EdgeFence::', collision)
        self.assertIn('JohtoRoute37CanStepAhead::', collision)
        for args in (('JohtoRoute36','JohtoRoute37','Route36','Route37','north'),
                     ('JohtoRoute37','JohtoRoute36','Route37','Route36','south'),
                     ('JohtoRoute37','JohtoEcruteakCity','Route37','EcruteakCity','north'),
                     ('JohtoEcruteakCity','JohtoRoute37','EcruteakCity','Route37','south')):
            self.assertEqual(connection_audit(ROOT, GOLD, *args)['status'], 'PASS')

    def test_ecruteak_and_both_gate_ids_registered(self):
        registry = json.loads((ROOT / 'tools/johto_native_maps.json').read_text())
        self.assertEqual(len(registry['maps']), 28)
        self.assertEqual([m['local_id'] for m in registry['maps'][-5:]], [23, 24, 62, 63, 64])
        self.assertEqual(registry['maps'][21]['local_symbol'], 'JOHTO_ROUTE_37_LOCAL_ID')
        self.assertEqual(registry['maps'][21]['identity_evidence'], 'STATIC_PASS')
        self.assertEqual(registry['maps'][22]['local_symbol'], 'JOHTO_ECRUTEAK_CITY_LOCAL_ID')
        self.assertIn('JohtoEcruteakCity_h',
                      (ROOT / 'data/johto_map_headers.asm').read_text())

    def test_ecruteak_original_city_geometry_and_all_six_hops(self):
        # The former temporary 2x2 faux facade visibly rendered as
        # stacked, misaligned houses. Keep the exact Gold outdoor seam and
        # close the unfinished Route38 gate using the existing edge fence.
        blocks = (ROOT / 'maps/JohtoEcruteakCity.blk').read_bytes()
        gold_blocks = (GOLD / 'maps/EcruteakCity.blk').read_bytes()
        self.assertEqual(len(blocks), 360)
        self.assertEqual(blocks, gold_blocks)
        # Compute the adapted mask with the project's existing collision tool.
        with tempfile.TemporaryDirectory() as folder:
            temp = Path(folder)
            (temp / 'maps').mkdir()
            (temp / 'maps/EcruteakCity.blk').write_bytes(blocks)
            for dirname in ('data', 'constants'):
                (temp / dirname).symlink_to(GOLD / dirname, target_is_directory=True)
            _, expected_mask = plan_gold_quadrant_collision(temp, 'EcruteakCity', 'johto')
        # Gold's two Ecruteak east door tiles are now open, exactly as the west side was.
        # Reject any other collision relaxation (especially houses and walls).
        expected_mask = bytearray(expected_mask)
        for y in (26, 27):
            expected_mask[y * 5 + 35 // 8] &= ~(1 << (35 % 8))
        self.assertEqual((ROOT / 'maps/JohtoEcruteakCity.blocked_mask.bin').read_bytes(), bytes(expected_mask))
        code=(ROOT / 'engine/overworld/ledges.asm').read_text()
        self.assertEqual(coordinate_hops(code, '.ecruteakHops'),
                         expected_gold_hops(GOLD,'EcruteakCity','johto'))
        self.assertEqual(len(coordinate_hops(code, '.ecruteakHops')), 6)

    def test_all_ecruteak_gold_signs_are_registered(self):
        self.assertEqual(audit_new_native_map_signs(ROOT,GOLD),[])

    def test_missing_gold_sign_fails_existing_release_audit(self):
        with tempfile.TemporaryDirectory() as folder:
            tmp=Path(folder)
            (tmp/'tools').symlink_to(ROOT/'tools', target_is_directory=True)
            (tmp/'scripts').symlink_to(ROOT/'scripts', target_is_directory=True)
            (tmp/'data/mapObjects').mkdir(parents=True)
            original=(ROOT/'data/mapObjects/JohtoEcruteakCity.asm').read_text()
            (tmp/'data/mapObjects/JohtoEcruteakCity.asm').write_text(
                original.replace('db $07 ; all 7 original city signs',
                                 'db $06 ; missing original city sign'))
            failures=audit_new_native_map_signs(tmp,GOLD)
            self.assertTrue(any('EcruteakCity: Gold BGEVENT_READ signs differ' in error
                                for error in failures), failures)

    def test_gold_new_map_field_move_roles(self):
        self.assertEqual(audit_new_native_field_move_roles(ROOT,GOLD),[])

    def test_missing_water_capability_fails_new_map_release_gate(self):
        with tempfile.TemporaryDirectory() as folder:
            tmp=Path(folder)
            (tmp/'tools').mkdir()
            (tmp/'tools/johto_fixed_ids.csv').symlink_to(ROOT/'tools/johto_fixed_ids.csv')
            registry=json.loads((ROOT/'tools/johto_native_maps.json').read_text())
            registry['maps'][22]['feature_status']['surf']='DEFERRED'
            (tmp/'tools/johto_native_maps.json').write_text(json.dumps(registry))
            (tmp/'data').mkdir()
            (tmp/'data/mapHeaders').symlink_to(ROOT/'data/mapHeaders',target_is_directory=True)
            (tmp/'engine/overworld').mkdir(parents=True)
            (tmp/'engine/overworld/johto_union_cave_surf.asm').symlink_to(
                ROOT/'engine/overworld/johto_union_cave_surf.asm')
            errors=audit_new_native_field_move_roles(tmp,GOLD)
            self.assertTrue(any('Gold WATER requires surf=ALLOWED' in e for e in errors),errors)

    def test_ecruteak_unfinished_exits_closed_and_visited_fly_enabled(self):
        city=(ROOT/'data/mapHeaders/JohtoEcruteakCity.asm').read_text()
        self.assertIn('db SOUTH | WEST | EAST',city)
        self.assertNotIn('db NORTH | SOUTH',city)
        obj=(ROOT/'data/mapObjects/JohtoEcruteakCity.asm').read_text()
        self.assertIn('db $04 ; West gate lanes #14/#15 and east gate lanes #1/#2',obj)
        fence=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        src=fence.split('JohtoEcruteakCityEdgeFence::',1)[1].split('JohtoEcruteakCityCanStepAhead::',1)[0]
        self.assertIn('cp 17',src)
        self.assertIn('cp 18',src)
        self.assertIn('jr z, .clear',src)
        registry=json.loads((ROOT/'tools/johto_native_maps.json').read_text())['maps']
        city_row=next(x for x in registry if x['local_symbol']=='JOHTO_ECRUTEAK_CITY_LOCAL_ID')
        self.assertEqual(city_row['feature_status']['fly'],'ALLOWED')
        self.assertEqual(city_row['feature_status']['surf'],'ALLOWED')
        self.assertIn('db $07 ; all 7 original city signs',obj)
        self.assertEqual(city_row['feature_status']['warp'],'ALLOWED')



if __name__ == '__main__':
    unittest.main()
