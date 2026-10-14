"""Regression tests for Gold/RPP signed-offset connection mismatch.

Synthetic, read-only inputs. Designed to run without a Gold checkout.
"""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_rpp_connection_guard import audit, ConnectionError, constant_expr


class JohtoConnectionGuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.project = Path(__file__).resolve().parents[2]

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        root=Path(self.temp.name)
        self.rpp=root/'rpp'
        self.gold=root/'gold'
        for relative in ['constants/map_constants.asm','data/mapHeaders/JohtoRoute30.asm',
                         'data/mapHeaders/JohtoRoute31.asm','maps/JohtoRoute30.blk',
                         'maps/JohtoRoute31.blk']:
            output=self.rpp/relative
            output.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(self.project/relative,output)
        (self.gold/'data/maps').mkdir(parents=True)
        (self.gold/'constants').mkdir()
        (self.gold/'data/maps/attributes.asm').write_text(
            'map_attributes Route30, ROUTE_30, $05, NORTH | SOUTH\n'
            'connection north, Route31, ROUTE_31, -10\n'
            'map_attributes Route31, ROUTE_31, $05, SOUTH | WEST\n'
            'connection south, Route30, ROUTE_30, 10\n')
        (self.gold/'constants/map_constants.asm').write_text(
            'map_const ROUTE_30, 10, 27\nmap_const ROUTE_31, 20, 9\n')

    def tearDown(self):
        self.temp.cleanup()

    def check_north(self):
        return audit(self.rpp,self.gold,'JohtoRoute30','JohtoRoute31',
                     'Route30','Route31','north')

    def check_south(self):
        return audit(self.rpp,self.gold,'JohtoRoute31','JohtoRoute30',
                     'Route31','Route30','south')

    def modify(self, filename, original, replacement):
        file=self.rpp/filename
        source=file.read_text()
        self.assertIn(original,source)
        file.write_text(source.replace(original,replacement,1))

    def test_fixed148_forward_reverse_are_safe(self):
        north=self.check_north()
        south=self.check_south()
        self.assertEqual(north['status'],'PASS',north)
        self.assertEqual(south['status'],'PASS',south)
        self.assertEqual(north['actual']['width'],10)
        self.assertEqual(north['actual']['source_start'],130)
        self.assertEqual(north['actual']['dest_start'],3)
        self.assertEqual(south['actual']['dest_start'],325)

    def test_old147_negative_gold_offset_is_not_safe_as_rpp_macro(self):
        file=self.rpp/'data/mapHeaders/JohtoRoute30.asm'
        data=file.read_text()
        start=data.index('\tdb JOHTO_ROUTE_31\n')
        end=data.index('\tSOUTH_MAP_CONNECTION',start)
        file.write_text(data[:start]+'\tNORTH_MAP_CONNECTION JOHTO_ROUTE_30, JOHTO_ROUTE_31, -10, 0, JohtoRoute31Blocks\n'+data[end:])
        result=self.check_north()
        self.assertEqual(result['status'],'FAIL')
        self.assertEqual(result['actual']['dest_start'],-7)
        self.assertEqual(result['actual']['width'],23)
        self.assertTrue(any('dest_row_0' in x for x in result['issues']))
        self.assertEqual(self.check_south()['status'],'PASS')

    def test_wrong_bounded_copy_width_is_rejected(self):
        self.modify('data/mapHeaders/JohtoRoute30.asm',
                    'db JOHTO_ROUTE_30_WIDTH ; bounded connection-strip width (10 blocks)',
                    'db 11 ; introduced bad width')
        result=self.check_north()
        self.assertEqual(result['status'],'FAIL')
        self.assertTrue(any('width:' in x for x in result['issues']))

    def test_wrong_source_offset_is_rejected(self):
        self.modify('data/mapHeaders/JohtoRoute30.asm',
                    '+ JOHTO_ROUTE_31_WIDTH * (JOHTO_ROUTE_31_HEIGHT - 3) + 10',
                    '+ JOHTO_ROUTE_31_WIDTH * (JOHTO_ROUTE_31_HEIGHT - 3) + 9')
        self.assertEqual(self.check_north()['status'],'FAIL')

    def test_wrong_gold_geometry_is_rejected(self):
        self.modify_gold('connection north, Route31, ROUTE_31, -10',
                         'connection north, Route31, ROUTE_31, -9')
        self.assertEqual(self.check_north()['status'],'FAIL')

    def modify_gold(self, original, replacement):
        p=self.gold/'data/maps/attributes.asm'
        p.write_text(p.read_text().replace(original,replacement))

    def test_disabled_direction_fails(self):
        self.modify('data/mapHeaders/JohtoRoute30.asm','db NORTH | SOUTH','db SOUTH')
        with self.assertRaisesRegex(ConnectionError,'does not enable'):
            self.check_north()

    def test_gold_map_size_mismatch_fails(self):
        p=self.gold/'constants/map_constants.asm'
        p.write_text(p.read_text().replace('ROUTE_31, 20, 9','ROUTE_31, 21, 9'))
        with self.assertRaisesRegex(ConnectionError,'Gold map sizes'):
            self.check_north()

    def test_nonexistent_edge_fails_closed(self):
        with self.assertRaisesRegex(ConnectionError,'Gold expected one'):
            audit(self.rpp,self.gold,'JohtoRoute30','JohtoRoute31',
                  'Route30','Route31','east')


    def setup_east_west(self):
        # City 20x18; Route31 20x9. Geometry is taken from Gold attributes.
        # This is an isolated synthetic test, NOT a change to the live maps.
        constants=self.rpp/'constants/map_constants.asm'
        constants.write_text(constants.read_text()+'\n\tmapconst JOHTO_VIOLET_CITY, 18, 20\n')
        city=self.rpp/'data/mapHeaders/JohtoVioletCity.asm'
        city.write_text('JohtoVioletCity_h:\n\tdb JOHTO\n\tdb JOHTO_VIOLET_CITY_HEIGHT, JOHTO_VIOLET_CITY_WIDTH\n\tdw JohtoVioletCityBlocks, Texts, Auto\n\tdb EAST\n\tdb JOHTO_ROUTE_31\n\tdw JohtoRoute31Blocks + 0\n\tdw wOverworldMap + 335\n\tdb 9\n\tdb JOHTO_ROUTE_31_WIDTH\n\tdb -18\n\tdb 0\n\tdw wOverworldMap + 27\n\tdw JohtoVioletObject\n')
        route=self.rpp/'data/mapHeaders/JohtoRoute31.asm'
        route.write_text('JohtoRoute31_h:\n\tdb JOHTO\n\tdb JOHTO_ROUTE_31_HEIGHT, JOHTO_ROUTE_31_WIDTH\n\tdw JohtoRoute31Blocks, Texts, Auto\n\tdb WEST | SOUTH\n\tdb JOHTO_VIOLET_CITY\n\tdw JohtoVioletCityBlocks + 197\n\tdw wOverworldMap + 78\n\tdb 9\n\tdb JOHTO_VIOLET_CITY_WIDTH\n\tdb 18\n\tdb 39\n\tdw wOverworldMap + 46\n\tdw JohtoRoute31Object\n')
        (self.rpp/'maps/JohtoVioletCity.blk').write_bytes(bytes(20*18))
        attrib=self.gold/'data/maps/attributes.asm'
        attrib.write_text(attrib.read_text()+
            'map_attributes VioletCity, VIOLET_CITY, $05, EAST\n'
            'connection east, Route31, ROUTE_31, 9\n')
        attrib.write_text(attrib.read_text().replace(
            'connection south, Route30, ROUTE_30, 10',
            'connection south, Route30, ROUTE_30, 10\nconnection west, VioletCity, VIOLET_CITY, -9'))
        gold_consts=self.gold/'constants/map_constants.asm'
        gold_consts.write_text(gold_consts.read_text()+
                               'map_const VIOLET_CITY, 20, 18\n')

    def check_east(self):
        return audit(self.rpp,self.gold,'JohtoVioletCity','JohtoRoute31',
                     'VioletCity','Route31','east')

    def check_west(self):
        return audit(self.rpp,self.gold,'JohtoRoute31','JohtoVioletCity',
                     'Route31','VioletCity','west')

    def test_east_west_gold_strip_geometry_pass(self):
        self.setup_east_west()
        a,b=self.check_east(),self.check_west()
        self.assertEqual(a['status'],'PASS',a)
        self.assertEqual(b['status'],'PASS',b)
        self.assertEqual(a['expected']['height'],9)
        self.assertEqual(b['expected']['source_start'],197)

    def test_east_negative_dest_shift_fails(self):
        self.setup_east_west()
        self.modify('data/mapHeaders/JohtoVioletCity.asm',
                    'wOverworldMap + 335', 'wOverworldMap - 7')
        self.assertEqual(self.check_east()['status'],'FAIL')

    def test_west_wrong_copy_height_fails(self):
        self.setup_east_west()
        self.modify('data/mapHeaders/JohtoRoute31.asm','\tdb 9\n\tdb JOHTO_VIOLET_CITY_WIDTH','\tdb 23\n\tdb JOHTO_VIOLET_CITY_WIDTH')
        self.assertEqual(self.check_west()['status'],'FAIL')

    def test_east_legacy_positive_shift_is_safe(self):
        # Do not treat all nonzero legacy macro parameters as unsafe:
        # Gold City EAST -> Route31 +9 is a real 9-row overlap.
        self.setup_east_west()
        h=self.rpp/'data/mapHeaders/JohtoVioletCity.asm'
        s=h.read_text().replace('\tdb JOHTO_ROUTE_31\n',
                    '\tEAST_MAP_CONNECTION JOHTO_VIOLET_CITY, JOHTO_ROUTE_31, 9, 0, JohtoRoute31Blocks\n')
        s=s[:s.index('\tdw JohtoRoute31Blocks + 0')]+s[s.index('\tdw JohtoVioletObject'):]
        h.write_text(s)
        result=self.check_east()
        self.assertEqual(result['status'],'PASS',result)
        self.assertEqual(result['actual']['format'],'legacy_macro')

    def test_west_legacy_height_extra_three_is_unsafe(self):
        # Reverse Route31 WEST -> VioletCity -9 with legacy macro calculates
        # 12 rows (extra +3), while the actual overlap is 9 rows.
        self.setup_east_west()
        h=self.rpp/'data/mapHeaders/JohtoRoute31.asm'
        s=h.read_text().replace('\tdb JOHTO_VIOLET_CITY\n',
                    '\tWEST_MAP_CONNECTION JOHTO_ROUTE_31, JOHTO_VIOLET_CITY, 0, 9, JohtoVioletCityBlocks\n')
        s=s[:s.index('\tdw JohtoVioletCityBlocks + 197')]+s[s.index('\tdw JohtoRoute31Object'):]
        h.write_text(s)
        result=self.check_west()
        self.assertEqual(result['status'],'FAIL',result)
        self.assertEqual(result['actual']['height'],12)
        self.assertEqual(result['expected']['height'],9)

    def test_east_gold_offset_mismatch_fails(self):
        self.setup_east_west()
        self.modify_gold('connection east, Route31, ROUTE_31, 9',
                         'connection east, Route31, ROUTE_31, 8')
        self.assertEqual(self.check_east()['status'],'FAIL')

    def test_west_flag_missing_fails(self):
        self.setup_east_west()
        self.modify('data/mapHeaders/JohtoRoute31.asm','\tdb WEST | SOUTH','\tdb SOUTH')
        with self.assertRaisesRegex(ConnectionError,'does not enable'):
            self.check_west()

    def test_east_legacy_wrong_move_fails(self):
        self.setup_east_west()
        h=self.rpp/'data/mapHeaders/JohtoVioletCity.asm'
        s=h.read_text()
        s=s.replace('\tdb JOHTO_ROUTE_31\n',
                    '\tEAST_MAP_CONNECTION JOHTO_VIOLET_CITY, JOHTO_ROUTE_31, -9, 0, JohtoRoute31Blocks\n')
        s=s[:s.index('\tdw JohtoRoute31Blocks + 0')]+s[s.index('\tdw JohtoVioletObject'):]
        h.write_text(s)
        self.assertEqual(self.check_east()['status'],'FAIL')

    def test_unsafe_expression_rejected(self):
        with self.assertRaises(ConnectionError):
            constant_expr('__import__("os").system("true")',{})

    def test_cli_reports_fail_exit_and_success_exit(self):
        command=[sys.executable,str(self.project/'tools/johto_rpp_connection_guard.py'),
                 '--project',str(self.rpp),'--gold-root',str(self.gold),
                 '--edge','JohtoRoute30','JohtoRoute31','Route30','Route31','north',
                 '--edge','JohtoRoute31','JohtoRoute30','Route31','Route30','south']
        valid=subprocess.run(command,capture_output=True,text=True)
        self.assertEqual(valid.returncode,0,valid.stderr+valid.stdout)
        self.assertIn('"status": "PASS"',valid.stdout)
        self.modify('data/mapHeaders/JohtoRoute30.asm',
                    'db JOHTO_ROUTE_30_WIDTH ; bounded connection-strip width (10 blocks)',
                    'db 23 ; deliberately bad width')
        bad=subprocess.run(command,capture_output=True,text=True)
        self.assertEqual(bad.returncode,2,bad.stderr+bad.stdout)
        self.assertIn('"status": "FAIL"',bad.stdout)


if __name__=='__main__':
    unittest.main()
