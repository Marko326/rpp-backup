"""Gate-283: check the Gold source gate fails closed, not a runnable Route35 claim."""
import importlib.util
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import johto_route35_source_contract_283 as mod


@unittest.skipIf('NUM_JOHTO_ACTIVE_MAPS EQU 28' in (ROOT/'constants/region_map_constants.asm').read_text(),
                 'old .282 source staging contract; Route35 now protected by live runtime audit')
class Route35SourceGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.gold = Path(self.tmp.name)/'gold'
        for directory in ('maps', 'data/maps', 'constants'):
            (self.gold/directory).mkdir(parents=True, exist_ok=True)
        self.shared = (ROOT/'maps/johto_pilot/Route34IlexForestGate.gold.blk').read_bytes()
        (self.gold/'maps/NorthSouthGate.blk').write_bytes(self.shared)
        self.preview=bytes.fromhex('05055859017844050505 414141420c0d40414141 01010146080944010101')
        (self.gold/'maps/Route35.blk').write_bytes(bytes([0x05])*150+self.preview)
        (self.gold/'data/maps/blocks.asm').write_text('''
Route34IlexForestGate_Blocks:
Route35GoldenrodGate_Blocks:
    INCBIN "maps/NorthSouthGate.blk"
Route35_Blocks:
    INCBIN "maps/Route35.blk"
''')
        (self.gold/'constants/map_constants.asm').write_text('''
map_const ROUTE_35, 10, 18
map_const ROUTE_35_GOLDENROD_GATE, 5, 4
''')
        (self.gold/'data/maps/attributes.asm').write_text('''
map_attributes GoldenrodCity, GOLDENROD_CITY, $35
    connection north, Route35, ROUTE_35, 5
map_attributes Route35, ROUTE_35, $05
    connection north, Route36, ROUTE_36, 0
    connection south, GoldenrodCity, GOLDENROD_CITY, -5
map_attributes Route36, ROUTE_36, $05
    connection south, Route35, ROUTE_35, 0
''')
        (self.gold/'maps/GoldenrodCity.asm').write_text('warp_event 19, 1, ROUTE_35_GOLDENROD_GATE, 3\n')
        (self.gold/'maps/Route35GoldenrodGate.asm').write_text('''
warp_event 4, 0, ROUTE_35, 1
warp_event 5, 0, ROUTE_35, 2
warp_event 4, 7, GOLDENROD_CITY, 13
warp_event 5, 7, GOLDENROD_CITY, 13
''')
        (self.gold/'maps/Route35.asm').write_text('''
warp_event 9, 33, ROUTE_35_GOLDENROD_GATE, 1
warp_event 10, 33, ROUTE_35_GOLDENROD_GATE, 2
warp_event 3, 5, ROUTE_35_NATIONAL_PARK_GATE, 3
''')
        self.proj = Path(self.tmp.name)/'project'
        for path in ('constants/region_map_constants.asm', 'data/game_version.asm',
                     'data/johto_south_runtime.asm',
                     'engine/johto_ilex_mature_runtime_275.asm',
                     'maps/johto_pilot/Route34IlexForestGate.gold.blk',
                     'maps/johto_pilot/Route36RuinsOfAlphGate.gold.blk',
                     'maps/johto_staged/Route35GoldenrodGate.gold.blk'):
            (self.proj/path).parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(ROOT/path,self.proj/path)
        c=self.proj/'constants/region_map_constants.asm'
        c.write_text(c.read_text().replace('NUM_JOHTO_ACTIVE_MAPS EQU 26', 'NUM_JOHTO_ACTIVE_MAPS EQU 21'))
        v=self.proj/'data/game_version.asm'
        v.write_text(v.read_text().replace('FIX-5.62.290', 'FIX-5.62.282'))


    def test_project_source_keeps_gate_inactive(self):
        report=mod.inspect_project(self.proj)
        self.assertEqual(21,report['active_maps'])
        self.assertFalse(report['runtime_enabled'])

    def test_project_gate_assets_are_identical(self):
        self.assertEqual(20,mod.inspect_project(self.proj)['gate_shared_bytes'])

    def test_gold_metadata_passes_source_contract_only(self):
        report=mod.inspect_gold(self.gold,self.proj)
        self.assertEqual(180,report['route35_bytes'])
        self.assertFalse(report['runtime_approved'])
        self.assertFalse(report['national_park_exit_open'])

    def test_refuse_missing_road_layout(self):
        (self.gold/'maps/Route35.blk').unlink()
        with self.assertRaises((ValueError,FileNotFoundError)):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_short_road_layout(self):
        (self.gold/'maps/Route35.blk').write_bytes(bytes([5])*179)
        with self.assertRaisesRegex(ValueError,'180'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_preview_mismatch(self):
        src=self.gold/'maps/Route35.blk'
        data=bytearray(src.read_bytes())
        data[-1]=0x05
        src.write_bytes(data)
        with self.assertRaisesRegex(ValueError,'preview'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_invalid_road_block(self):
        (self.gold/'maps/Route35.blk').write_bytes(bytes([5])*179+b'\xff')
        with self.assertRaisesRegex(ValueError,'180'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_gate_shared_data_mutation(self):
        src=self.gold/'maps/NorthSouthGate.blk'
        src.write_bytes(bytes([1])+src.read_bytes()[1:])
        with self.assertRaisesRegex(ValueError,'source mismatch'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_gate_destination_mismatch(self):
        src=self.gold/'maps/Route35GoldenrodGate.asm'
        src.write_text(src.read_text().replace('ROUTE_35, 2', 'ROUTE_36, 2'))
        with self.assertRaisesRegex(ValueError,'warp contract'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_premature_park_gate(self):
        src=self.gold/'maps/Route35.asm'
        src.write_text(src.read_text().replace('ROUTE_35_NATIONAL_PARK_GATE','GOLDENROD_CITY'))
        with self.assertRaisesRegex(ValueError,'warp contract'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_connection_offset_mutation(self):
        src=self.gold/'data/maps/attributes.asm'
        src.write_text(src.read_text().replace('ROUTE_35, 5','ROUTE_35, 0'))
        with self.assertRaisesRegex(ValueError,'seam wrong'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_source_label_alias_change(self):
        src=self.gold/'data/maps/blocks.asm'
        src.write_text(src.read_text().replace('Route35GoldenrodGate_Blocks:', 'Route35NationalParkGate_Blocks:'))
        with self.assertRaisesRegex(ValueError,'must reuse'):
            mod.inspect_gold(self.gold,self.proj)

    def test_refuse_premature_project_map_activation(self):
        p=self.proj/'constants/region_map_constants.asm'
        p.write_text(p.read_text().replace('NUM_JOHTO_ACTIVE_MAPS EQU 21','NUM_JOHTO_ACTIVE_MAPS EQU 23'))
        with self.assertRaisesRegex(ValueError,'registration changed'):
            mod.inspect_project(self.proj)

    def test_refuse_project_shared_gold_mutation(self):
        p=self.proj/'maps/johto_staged/Route35GoldenrodGate.gold.blk'
        p.write_bytes(bytes([0x01])+p.read_bytes()[1:])
        with self.assertRaisesRegex(ValueError,'differs'):
            mod.inspect_project(self.proj)

    def test_refuse_project_wrong_version(self):
        p=self.proj/'data/game_version.asm'
        p.write_text(p.read_text().replace('FIX-5.62.282','FIX-5.62.284'))
        with self.assertRaisesRegex(ValueError,'FIX-5.62.282'):
            mod.inspect_project(self.proj)


if __name__=='__main__':
    unittest.main()
