"""SURF-AUD-001: fail-closed, reusable Surf contract and shore-path checks."""
from pathlib import Path
import json
import os
import re
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_preflight import ENTRYPOINTS, check_project

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None


class SurfPreflight(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.contract = json.loads((ROOT / 'tools/johto_surf_contracts.json').read_text())
        paths = list(ENTRYPOINTS) + ['engine/johto_violet_field_skills.asm',
                 'maps/johto_pilot/NewBarkTown.runtime.blk',
                 'maps/johto_pilot/CherrygroveCity.runtime.blk',
                 'maps/johto_pilot/VioletCity.runtime.blk',
                 'maps/johto_pilot/Route30.runtime.blk',
                 'maps/johto_pilot/Route31.runtime.blk',
                 'maps/johto_pilot/Route32.runtime.blk',
                 'maps/johto_pilot/RuinsOfAlphOutside.runtime.blk',
                 'maps/johto_pilot/UnionCave1F.runtime.blk',
                 'gfx/blocksets/johto_union_cave.bst',
                 'gfx/tilesets/johto_union_cave.tilecoll',
                 'gfx/blocksets/johto.bst', 'gfx/tilesets/johto.tilecoll']
        for path in paths:
            dest = self.root / path
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / path, dest)

    def change(self, path, before, after):
        f = self.root / path
        original = f.read_text()
        self.assertIn(before, original)
        f.write_text(original.replace(before, after, 1))

    def assert_has_error(self, needle, gold=None):
        errors = check_project(self.root, self.contract, gold)
        self.assertTrue(any(needle in err for err in errors), errors)

    def test_current_shore_and_water_contract(self):
        self.assertEqual([], check_project(self.root, self.contract, GOLD))

    def test_cherrygrove_water_table_is_exact_gold_and_bounded(self):
        asm = (self.root / 'engine/johto_violet_field_skills.asm').read_text()
        block = asm.split('JohtoCherrygroveGoldWaterCells::', 1)[1].split(
            'JohtoCherrygroveGoldWaterCellsEnd::', 1)[0]
        cells = [(int(y), int(x)) for y, x in re.findall(
            r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*$', block)]
        self.assertEqual(142, len(cells))
        self.assertEqual(142, len(set(cells)))
        self.assertTrue(all(0 <= y < 18 and 0 <= x < 40 for y, x in cells))
        self.assertIn('cp JOHTO_CHERRYGROVE_LOCAL_ID', asm)

    def test_missing_c_register_reload_is_rejected(self):
        self.change('home/overworld.asm',
                    '\tld a, [wTileInFrontOfPlayer]\n\tld c, a\n\tjp .checkIfNextTileIsPassable',
                    '\tjp .checkIfNextTileIsPassable')
        self.assert_has_error('disembark must restore')

    def test_reversed_water_carry_is_rejected(self):
        self.change('home/overworld.asm',
                    '\tjr nc, .johtoSurfNotWater\n\tjp z, .noCollision',
                    '\tjr nc, .johtoSurfNotWater\n\tjp nz, .noCollision')
        self.assert_has_error('disembark must restore')

    def test_wrong_field_move_carry_is_rejected(self):
        self.change('engine/overworld/field_moves.asm',
                    'callab JohtoVioletWaterAhead\n\tret c',
                    'callab JohtoVioletWaterAhead\n\tret nc')
        self.assert_has_error('carry polarity/dispatch incorrect')

    def test_wrong_surfboard_carry_is_rejected(self):
        self.change('engine/items/items.asm',
                    'callab JohtoVioletWaterAhead\n\tjr c, .shoreOrWater',
                    'callab JohtoVioletWaterAhead\n\tjr nc, .shoreOrWater')
        self.assert_has_error('carry polarity/dispatch incorrect')

    def test_missing_surfboard_entry_is_rejected(self):
        self.change('engine/items/items.asm',
                    'callab JohtoVioletWaterAhead', 'callab MissingSurfQuery')
        self.assert_has_error('missing JohtoVioletWaterAhead call')

    def test_missing_field_move_entry_is_rejected(self):
        self.change('engine/overworld/field_moves.asm',
                    'callab JohtoVioletWaterAhead', 'callab MissingSurfQuery')
        self.assert_has_error('missing JohtoVioletWaterAhead call')

    def test_future_map_without_contract_is_rejected(self):
        self.change('engine/items/items.asm',
                    'callab JohtoVioletWaterAhead',
                    'callab JohtoRoute33WaterAhead\n\tcallab JohtoVioletWaterAhead')
        self.assert_has_error('unregistered JohtoRoute33WaterAhead')

    def test_wrong_map_id_guard_is_rejected(self):
        self.change('engine/johto_violet_field_skills.asm',
                    'JohtoVioletIsActive::\n\tld a, [wCurMap]',
                    'JohtoVioletIsActive::\n\tld a, [wCurMap]\n\t; mutation guard')
        self.change('engine/johto_violet_field_skills.asm',
                    'cp JOHTO_VIOLET_CITY_LOCAL_ID\n\tjp nz, .no',
                    'cp JOHTO_ROUTE_32_LOCAL_ID\n\tjp nz, .no')
        self.assert_has_error('map-scope predicate')

    def test_duplicate_water_cell_is_rejected(self):
        self.change('engine/johto_violet_field_skills.asm',
                    '\tdb 0, 11', '\tdb 0, 10')
        self.assert_has_error('duplicate water coordinates')

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_cherrygrove_water_swap_is_rejected_by_gold_comparison(self):
        path = self.root / 'engine/johto_violet_field_skills.asm'
        source = path.read_text()
        before = 'JohtoCherrygroveGoldWaterCells::\n\tdb 0, 34'
        after = 'JohtoCherrygroveGoldWaterCells::\n\tdb 0, 33'
        self.assertIn(before, source)
        path.write_text(source.replace(before, after, 1))
        self.assert_has_error('Gold water mismatch', GOLD)

    @unittest.skipIf(GOLD is None, 'GOLD_SOURCE_ROOT not set; optional Gold asset comparison')
    def test_water_cell_swap_detected_even_when_count_unchanged(self):
        self.change('engine/johto_violet_field_skills.asm',
                    '\tdb 0, 10', '\tdb 0, 9')
        self.assert_has_error('Gold water mismatch', GOLD)


if __name__ == '__main__':
    unittest.main()
