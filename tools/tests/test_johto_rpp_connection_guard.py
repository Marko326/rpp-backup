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
from johto_rpp_connection_guard import audit, ConnectionError, constant_expr, audit_all_active, discover_active_edges


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
        (self.rpp/'main.asm').write_text(
            'DEF JOHTO_ROM_BANK EQU $40\n'
            'SECTION "R30", ROMX, BANK[JOHTO_ROM_BANK]\n'
            'INCLUDE "data/mapHeaders/JohtoRoute30.asm"\n'
            'SECTION "R31", ROMX, BANK[JOHTO_ROM_BANK]\n'
            'INCLUDE "data/mapHeaders/JohtoRoute31.asm"\n'
            'SECTION "Violet", ROMX, BANK[JOHTO_ROM_BANK]\n'
            'INCLUDE "data/mapHeaders/JohtoVioletCity.asm"\n')
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
        end=data.index('\tdb JOHTO_CHERRYGROVE_CITY',start)
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


class RealConnectionCoverage(unittest.TestCase):
    """Enforce actual native-Johto edge inventory, not synthetic guard tests."""
    @classmethod
    def setUpClass(cls):
        import os
        cls.rpp=Path(__file__).resolve().parents[2]
        cls.gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        if not (cls.gold/'data/maps/attributes.asm').is_file():
            raise AssertionError('complete Gold sources required for connection release gate')

    def test_all_active_connections_must_match_gold(self):
        edges=discover_active_edges(self.rpp)
        self.assertEqual(len(edges),22)  # .223 roads plus .217 Goldenrod/Route34 bidirectional seam
        result=audit_all_active(self.rpp,self.gold)
        self.assertEqual(result['status'],'PASS',result)
        self.assertEqual(len(result['edges']),len(edges))

    def test_merged_route34_goldenrod_seam_must_remain_audited(self):
        import json
        # .223 alone had 20 connections. Two more from .217 cannot disappear.
        actual=audit(self.rpp,self.gold,'JohtoRoute34','JohtoGoldenrodCity',
                     'Route34','GoldenrodCity','north')
        self.assertEqual(actual['status'],'PASS',actual)
        self.assertEqual(actual['overlap']['visual_right_border'],0)
        self.assertIn(('JohtoRoute34','JohtoGoldenrodCity','Route34','GoldenrodCity','north'),
                      discover_active_edges(self.rpp))
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            shutil.copytree(self.rpp/'constants',dest/'constants')
            shutil.copytree(self.rpp/'maps',dest/'maps')
            shutil.copy2(self.rpp/'main.asm',dest/'main.asm')
            shutil.copy2(self.rpp/'data/johto_map_headers.asm',dest/'data/johto_map_headers.asm')
            (dest/'tools').mkdir()
            f=dest/'tools/johto_native_maps.json'
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',f)
            (dest/'engine/overworld').mkdir(parents=True)
            shutil.copy2(self.rpp/'engine/overworld/johto_route33_collision.asm',
                         dest/'engine/overworld/johto_route33_collision.asm')
            manifest=json.loads(f.read_text())
            entry=next(x for x in manifest['maps'] if x['header']=='JohtoRoute34_h')
            entry.pop('north_connection_exit_x_tiles')
            f.write_text(json.dumps(manifest))
            bad=audit_all_active(dest,self.gold)
            self.assertEqual(bad['status'],'FAIL',bad)
            self.assertTrue(any(e.get('edge',())[0]=='JohtoRoute34'
                                for e in bad['edges'] if e.get('status')=='FAIL'),bad)

    def test_route35_north_preview_reaches_three_visual_border_columns(self):
        # Route35's only legal north exit is x=17 (block 8); its viewport
        # sees Route36 x=10..12 to the right of the 10-column Gold overlap.
        actual = audit(self.rpp, self.gold, 'JohtoRoute35','JohtoRoute36',
                       'Route35','Route36','north')
        self.assertEqual(actual['status'], 'PASS', actual)
        self.assertEqual(actual['actual']['width'], 13)
        self.assertEqual(actual['overlap']['visual_right_border'], 3)
        route36=(self.rpp/'maps/JohtoRoute36.blk').read_bytes()
        self.assertEqual([list(route36[row*30+10:row*30+13])
                          for row in (6,7,8)],
                         [[0x01,0x02,0x03], [0x01,0x01,0x01],
                          [0x05,0x05,0x05]])
        # Simulate the existing 3-row loader, no custom conversion engine.
        stride=16
        north_border=bytearray([0x05]*3*stride)
        for row in range(3):
            start=(6+row)*30
            north_border[3+row*stride:3+row*stride+13]=route36[start:start+13]
        self.assertEqual([list(north_border[row*stride+13:row*stride+16])
                          for row in range(3)],
                         [[0x01,0x02,0x03], [0x01,0x01,0x01],
                          [0x05,0x05,0x05]])

    def test_short_visual_strip_is_rejected_by_full_guard(self):
        # The old 10-column geometry passed, but left the screen's right
        # margin as default trees while Route36 had road tiles there.
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            shutil.copytree(self.rpp/'constants',dest/'constants')
            shutil.copytree(self.rpp/'maps',dest/'maps')
            shutil.copy2(self.rpp/'main.asm',dest/'main.asm')
            shutil.copy2(self.rpp/'data/johto_map_headers.asm',dest/'data/johto_map_headers.asm')
            (dest/'engine/overworld').mkdir(parents=True)
            shutil.copy2(self.rpp/'engine/overworld/johto_route33_collision.asm',
                         dest/'engine/overworld/johto_route33_collision.asm')
            (dest/'tools').mkdir()
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',dest/'tools/johto_native_maps.json')
            h=dest/'data/mapHeaders/JohtoRoute35.asm'
            text=h.read_text()
            self.assertIn('db JOHTO_ROUTE_35_WIDTH + 3', text)
            h.write_text(text.replace('db JOHTO_ROUTE_35_WIDTH + 3',
                                     'db JOHTO_ROUTE_35_WIDTH',1))
            report=audit_all_active(dest,self.gold)
            self.assertEqual(report['status'],'FAIL')
            self.assertTrue(any(e.get('current')=='JohtoRoute35'
                                and any('width:' in issue for issue in e['issues'])
                                for e in report['edges']),report)

    def test_route32_reachable_north_preview_matches_gold_and_runtime_fence(self):
        actual=audit(self.rpp,self.gold,'JohtoRoute32','JohtoVioletCity',
                     'Route32','VioletCity','north')
        self.assertEqual(actual['status'],'PASS',actual)
        self.assertEqual(actual['actual']['width'],13)
        self.assertEqual(actual['overlap']['visual_right_border'],3)
        # Gold y=0 north gate x14/15 is passable; adjacent x16..19 is not.
        from johto_indoor_collision_adapter import plan_gold_quadrant_collision
        _,mask=plan_gold_quadrant_collision(self.gold,'Route32','johto')
        self.assertEqual([bool(mask[x//8] & (1<<(x%8)))
                          for x in range(14,20)], [False,False,True,True,True,True])
        gold=(self.gold/'maps/VioletCity.blk').read_bytes()
        rpp=(self.rpp/'maps/JohtoVioletCity.blk').read_bytes()
        self.assertEqual([list(rpp[row*20+10:row*20+13]) for row in (15,16,17)],
                         [list(gold[row*20+10:row*20+13]) for row in (15,16,17)])
        self.assertEqual([list(gold[row*20+10:row*20+13]) for row in (15,16,17)],
                         [[1,1,1],[5,5,5],[5,5,5]])
        # Simulate the existing row copier, no alternate map generator.
        dest=bytearray([5]*3*16)
        for row in range(3):
            dest[3+row*16:3+row*16+13]=gold[(15+row)*20:(15+row)*20+13]
        self.assertEqual([list(dest[row*16+13:row*16+16]) for row in range(3)],
                         [[1,1,1],[5,5,5],[5,5,5]])

    def test_route32_missing_preview_fails_global_guard(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            shutil.copytree(self.rpp/'constants',dest/'constants')
            shutil.copytree(self.rpp/'maps',dest/'maps')
            shutil.copy2(self.rpp/'main.asm',dest/'main.asm')
            shutil.copy2(self.rpp/'data/johto_map_headers.asm',dest/'data/johto_map_headers.asm')
            (dest/'tools').mkdir()
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',dest/'tools/johto_native_maps.json')
            (dest/'engine/overworld').mkdir(parents=True)
            shutil.copy2(self.rpp/'engine/overworld/johto_route33_collision.asm',
                         dest/'engine/overworld/johto_route33_collision.asm')
            header=dest/'data/mapHeaders/JohtoRoute32.asm'
            original=header.read_text()
            self.assertIn('db JOHTO_ROUTE_32_WIDTH + 3',original)
            header.write_text(original.replace('db JOHTO_ROUTE_32_WIDTH + 3',
                                               'db JOHTO_ROUTE_32_WIDTH',1))
            result=audit_all_active(dest,self.gold)
            self.assertEqual(result['status'],'FAIL')
            self.assertTrue(any(e.get('current')=='JohtoRoute32'
                                and any('width:' in issue for issue in e['issues'])
                                for e in result['edges']),result)

    def test_route32_fake_or_missing_reachable_gate_is_rejected(self):
        import json
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            shutil.copytree(self.rpp/'constants',dest/'constants')
            shutil.copytree(self.rpp/'maps',dest/'maps')
            shutil.copy2(self.rpp/'main.asm',dest/'main.asm')
            shutil.copy2(self.rpp/'data/johto_map_headers.asm',dest/'data/johto_map_headers.asm')
            (dest/'tools').mkdir()
            f=dest/'tools/johto_native_maps.json'
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',f)
            for bogus in ([16,17], None):
                manifest=json.loads((self.rpp/'tools/johto_native_maps.json').read_text())
                item=next(x for x in manifest['maps'] if x['header']=='JohtoRoute32_h')
                if bogus is None:
                    item.pop('north_connection_exit_x_tiles')
                else:
                    item['north_connection_exit_x_tiles']=bogus
                f.write_text(json.dumps(manifest))
                report=audit_all_active(dest,self.gold)
                self.assertEqual(report['status'],'FAIL')
                self.assertTrue(any(e.get('edge',())[0]=='JohtoRoute32'
                                    for e in report['edges'] if e.get('status')=='FAIL'),report)

    def test_bad_legacy_connection_is_rejected_globally(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            # Copy the real project header tree and manifest to test discovery.
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            (dest/'tools').mkdir()
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',dest/'tools/johto_native_maps.json')
            shutil.copy2(self.rpp/'main.asm',dest/'main.asm')
            shutil.copy2(self.rpp/'data/johto_map_headers.asm',dest/'data/johto_map_headers.asm')
            p=dest/'data/mapHeaders/JohtoRoute30.asm'
            s=p.read_text()
            start=s.index('\tdb JOHTO_CHERRYGROVE_CITY\n')
            end=s.index('\tdw JohtoRoute30Object',start)
            p.write_text(s[:start]+'\tSOUTH_MAP_CONNECTION JOHTO_ROUTE_30, JOHTO_CHERRYGROVE_CITY, -5, 0, JohtoCherrygroveCityBlocks\n'+s[end:])
            # Actual audit needs all project constants and map blocks.
            shutil.copytree(self.rpp/'constants',dest/'constants')
            shutil.copytree(self.rpp/'maps',dest/'maps')
            result=audit_all_active(dest,self.gold)
            self.assertEqual(result['status'],'FAIL')
            self.assertTrue(any(e.get('current')=='JohtoRoute30' and e.get('status')=='FAIL'
                                for e in result['edges']),result)

    def test_cross_bank_map_is_rejected_before_delivery(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            shutil.copytree(self.rpp/'constants',dest/'constants')
            shutil.copytree(self.rpp/'maps',dest/'maps')
            shutil.copy2(self.rpp/'main.asm',dest/'main.asm')
            shutil.copy2(self.rpp/'data/johto_map_headers.asm',dest/'data/johto_map_headers.asm')
            (dest/'tools').mkdir()
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',dest/'tools/johto_native_maps.json')
            main=dest/'main.asm'
            source=main.read_text()
            original='SECTION "Johto Route35 Map", ROMX, BANK[JOHTO_ROM_BANK]'
            self.assertIn(original,source)
            main.write_text(source.replace(original,
                'SECTION "Johto Route35 Map", ROMX, BANK[$44]',1))
            report=audit_all_active(dest,self.gold)
            self.assertEqual(report['status'],'FAIL')
            self.assertTrue(any('ROM bank mismatch' in issue for edge in report['edges']
                                for issue in edge['issues']),report)

    def test_enabled_connection_cannot_be_omitted_from_discovery(self):
        with tempfile.TemporaryDirectory() as tmp:
            dest=Path(tmp)
            shutil.copytree(self.rpp/'data/mapHeaders',dest/'data/mapHeaders')
            (dest/'tools').mkdir()
            shutil.copy2(self.rpp/'tools/johto_native_maps.json',dest/'tools/johto_native_maps.json')
            path=dest/'data/mapHeaders/JohtoRoute36.asm'
            s=path.read_text()
            self.assertIn('dw JohtoRoute35Blocks',s)
            path.write_text(s.replace('dw JohtoRoute35Blocks','dw UnknownPlaceholder',1))
            with self.assertRaisesRegex(ConnectionError,'enumerate all active'):
                discover_active_edges(dest)


if __name__=='__main__':
    unittest.main()
