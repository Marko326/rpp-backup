"""Mutation regression for accepted south-map NPC-243 movement contracts."""
import sys
import shutil
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_south_mature_preflight_271 import audit
ROOT = Path(__file__).resolve().parents[2]

class Mature271(unittest.TestCase):
    def test_accepted_contract(self):
        self.assertEqual([], audit(ROOT))

    def test_registered_gate_carpet_blacklist_regression(self):
        with tempfile.TemporaryDirectory() as folder:
            temp = Path(folder)
            paths = ('tools/johto_pilot_door_contracts.json',
                     'data/johto_south_runtime.asm', 'engine/johto_south_geometry.asm',
                     'engine/johto_south_portals.asm', 'home/overworld.asm',
                     'maps/johto_pilot/AzaleaTown.roles.bin',
                     'maps/johto_pilot/Route34.roles.bin',
                     'maps/johto_pilot/GoldenrodCity.roles.bin',
                     'maps/johto_pilot/IlexForest.roles.bin')
            for path in paths:
                (temp/path).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT/path, temp/path)
            self.assertEqual([], audit(temp))
            path = temp/'engine/johto_south_geometry.asm'
            code = path.read_text()
            for coord in ('13, 37', '14, 37'):
                path.write_text(code.replace('    db JOHTO_ROUTE_34_LOCAL_ID, 13, 41',
                                             f'    db JOHTO_ROUTE_34_LOCAL_ID, {coord}\n    db JOHTO_ROUTE_34_LOCAL_ID, 13, 41', 1))
                self.assertTrue(audit(temp), f'blacklisting {coord} must fail')
            path.write_text(code)
            path = temp/'engine/johto_south_portals.asm'
            path.write_text(path.read_text().replace('cp PLAYER_DIR_DOWN\n    ret nz\n    ld a, [wYCoord]\n    cp 37',
                                                     'cp PLAYER_DIR_LEFT\n    ret nz\n    ld a, [wYCoord]\n    cp 37', 1))
            self.assertTrue(any('DOWN collision' in x for x in audit(temp)))

    def test_registered_south_warp_must_not_overlap_closed_door(self):
        with tempfile.TemporaryDirectory() as folder:
            temp = Path(folder)
            paths = ('tools/johto_pilot_door_contracts.json',
                     'data/johto_south_runtime.asm', 'engine/johto_south_geometry.asm',
                     'engine/johto_south_portals.asm', 'home/overworld.asm',
                     'maps/johto_pilot/AzaleaTown.roles.bin',
                     'maps/johto_pilot/Route34.roles.bin',
                     'maps/johto_pilot/GoldenrodCity.roles.bin',
                     'maps/johto_pilot/IlexForest.roles.bin')
            for path in paths:
                (temp/path).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT/path, temp/path)
            self.assertEqual([], audit(temp))
            import json
            p = temp/'tools/johto_pilot_door_contracts.json'
            contracts = json.loads(p.read_text())
            gate = next(x for x in contracts['south_batch_routes'] if
                        x['id'] == 'Route34_0_to_Route34IlexForestGate')
            gate['source_xy'] = [13, 41]
            p.write_text(json.dumps(contracts))
            self.assertTrue(any('registered south Warp conflicts' in x for x in audit(temp)))

    def test_dropped_door_or_midjump_protection_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            temp = Path(folder)
            paths = ('tools/johto_pilot_door_contracts.json',
                     'data/johto_south_runtime.asm', 'engine/johto_south_geometry.asm',
                     'engine/johto_south_portals.asm',
                     'home/overworld.asm', 'maps/johto_pilot/AzaleaTown.roles.bin',
                     'maps/johto_pilot/Route34.roles.bin',
                     'maps/johto_pilot/GoldenrodCity.roles.bin',
                     'maps/johto_pilot/IlexForest.roles.bin')
            for path in paths:
                (temp/path).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT/path, temp/path)
            self.assertEqual([], audit(temp))
            p = temp/'engine/johto_south_geometry.asm'
            original = p.read_text()
            p.write_text(original.replace('db JOHTO_GOLDENROD_CITY_LOCAL_ID, 19, 1',
                                          'db JOHTO_GOLDENROD_CITY_LOCAL_ID, 19, 2',1))
            self.assertTrue(any('24 exact' in x for x in audit(temp)))
            p.write_text(original)
            p = temp/'home/overworld.asm'
            original = p.read_text()
            p.write_text(original.replace('cp JOHTO_ILEX_FOREST\n\tjr nz, .checkRunningButton',
                                          'cp JOHTO_MODERN\n\tjr nz, .checkRunningButton',1))
            self.assertTrue(any('mid-jump' in x for x in audit(temp)))
            p.write_text(original)
            p = temp/'data/johto_south_runtime.asm'
            p.write_text(p.read_text().replace('db $05 ; NPC-243 accepted Gold Azalea outdoor forest border',
                                              'db $00 ; incorrect',1))
            self.assertTrue(any('border' in x for x in audit(temp)))

if __name__=='__main__':
    unittest.main()
