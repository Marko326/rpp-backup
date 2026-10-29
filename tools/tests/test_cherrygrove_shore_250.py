"""CHERRY-250: Gold FLOOR shoreline must allow both Surf landing and walking.

The failure existed with a perfectly correct WATER table; these tests check
Gold FLOOR -> compact visual tile -> runtime collision, then both movement paths.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
import copy
import json
import os
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_preflight import check_project, gold_shore_floor_mismatch

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None


class GoldShoreFloor250(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        files = (
            'home/overworld.asm', 'engine/overworld/field_moves.asm',
            'engine/items/items.asm', 'engine/johto_violet_field_skills.asm',
            'maps/johto_pilot/CherrygroveCity.runtime.blk',
            'maps/johto_pilot/VioletCity.runtime.blk',
            'gfx/blocksets/johto.bst', 'gfx/tilesets/johto.tilecoll',
        )
        for file in files:
            dest = self.root / file
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / file, dest)
        self.contract = json.loads((ROOT / 'tools/johto_surf_contracts.json').read_text())
        self.cherry = self.contract['maps'][0]
        self.assertEqual('CherrygroveCity', self.cherry['gold_map'])

    def change(self, path, before, after):
        f = self.root / path
        source = f.read_text()
        self.assertIn(before, source)
        f.write_text(source.replace(before, after, 1))

    def assert_fails(self, phrase, *, use_gold=False):
        errors = check_project(self.root, self.contract, GOLD if use_gold else None)
        self.assertTrue(any(phrase in error for error in errors), errors)

    def test_registered_shore_contract_passes_statics(self):
        self.assertEqual([], check_project(self.root, self.contract))

    @unittest.skipIf(GOLD is None, 'Gold reference needed for source collision audit')
    def test_gold_floor_but_runtime_blocked_exact_eight(self):
        expected = {(y, x) for y in (12, 13) for x in (4, 5, 6, 7)}
        self.assertEqual(expected, gold_shore_floor_mismatch(self.root, GOLD, self.cherry))
        self.assertEqual([], check_project(self.root, self.contract, GOLD))

    @unittest.skipIf(GOLD is None, 'Gold reference needed to discover omission')
    def test_old_water_only_contract_now_fails_before_delivery(self):
        # This reproduces CHERRY-249's false green: all 142 WATER cells correct,
        # but Surf had no legal FLOOR transition on the west rock platform.
        old = copy.deepcopy(self.contract)
        old['maps'][0].pop('shore_floor_exception')
        errors = check_project(self.root, old, GOLD)
        self.assertTrue(any('MISSING_SHORE_PASSABILITY' in e for e in errors), errors)

    def test_remove_surf_landing_hook_rejected(self):
        self.change('home/overworld.asm',
                    '\tcallab JohtoCherrygroveShoreFloorAhead\n\tjp c, .stopSurfing',
                    '\t; BUG: missing landing allowance')
        self.assert_fails('missing disembark path')

    def test_remove_normal_walk_hook_rejected(self):
        self.change('home/overworld.asm',
                    '\tcallab JohtoCherrygroveShoreFloorAhead\n\tjr nc, .normalTilePassability',
                    '\t; BUG: missing walking allowance')
        self.assert_fails('missing normal walking')

    def test_remove_region_guard_rejected(self):
        self.change('engine/johto_violet_field_skills.asm',
                    '\tcall JohtoCherrygroveIsActive\n\tjp nc, .noFloor',
                    '\t; BUG: bypass map identity guard')
        self.assert_fails('missing active-map/coordinate')

    def test_global_tile_whitelist_regression_rejected(self):
        path = self.root / 'gfx/tilesets/johto.tilecoll'
        original = path.read_bytes()
        self.assertNotIn(0x3c, original)
        path.write_bytes(original[:-1] + bytes((0x3c, 0xff)))
        self.assert_fails('forbidden global passability')

    @unittest.skipIf(GOLD is None, 'Gold reference needed for cell-level mutation')
    def test_wrong_shore_cell_rejected_even_when_count_matches(self):
        self.change('engine/johto_violet_field_skills.asm',
                    'JohtoCherrygroveShoreFloorCells::\n\tdb 12, 4',
                    'JohtoCherrygroveShoreFloorCells::\n\tdb 11, 4')
        self.assert_fails('Gold FLOOR shoreline mismatch', use_gold=True)


if __name__ == '__main__':
    unittest.main()
