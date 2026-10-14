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

    def test_unsupported_direction_fails_closed(self):
        with self.assertRaisesRegex(ConnectionError,'Only north/south'):
            audit(self.rpp,self.gold,'JohtoRoute30','JohtoRoute31',
                  'Route30','Route31','east')

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
