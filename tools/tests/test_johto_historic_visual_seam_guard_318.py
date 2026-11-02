"""Historical Goldenrod/Azalea/Route35/Route43 regressions and fault injection.

Set GOLD_SOURCE_ROOT to the real uploaded pokegold checkout. Never generate
an invented Gold baseline just to make the tests pass.
"""
from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_historic_visual_seam_guard_318 import audit


@unittest.skipUnless(os.environ.get('GOLD_SOURCE_ROOT'), 'requires actual GOLD_SOURCE_ROOT')
class HistoricVisualSeamGuard318(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ['GOLD_SOURCE_ROOT'])
        if not (cls.gold / 'maps/Route43.blk').is_file():
            raise AssertionError('GOLD_SOURCE_ROOT is not the full real pokegold checkout')

    def reject(self, file: str, old: str, new: str, expected: str):
        raw = (ROOT / file).read_text(encoding='utf-8')
        self.assertIn(old, raw, file)
        changed = raw.replace(old, new, 1)
        self.assertNotEqual(raw, changed)
        result = audit(ROOT, self.gold, {file: changed})
        self.assertEqual('FAIL', result['status'], result['errors'])
        self.assertIn(expected, result['errors'])

    def test_route44_east_preview_must_not_fall_back_to_tree_border(self):
        self.reject('data/johto_route44_runtime_324.asm',
                    'db WEST | EAST ; DEV-326 Gold physical seam; IcePath cave still sealed',
                    'db WEST ; wrong tree-wall regression',
                    'route44_east_gold_preview_not_tree_border')

    def test_route44_east_source_bytes_must_match_original_gold(self):
        path='maps/johto_pilot/BlackthornCity.east_preview.blk'
        raw=(ROOT/path).read_bytes()
        changed=bytearray(raw);changed[9*20+2]^=1
        result=audit(ROOT, self.gold, {path:bytes(changed)})
        self.assertIn('route44_east_gold_preview_not_tree_border', result['errors'])

    def test_full_historical_visual_chain(self):
        result = audit(ROOT, self.gold)
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result['errors'])
        self.assertGreaterEqual(result['checks_total'], 30)
        self.assertFalse(result['rom_built'])
        self.assertFalse(result['phone_verified'])

    def test_azalea_west_roof_half_not_lost(self):
        self.reject('engine/johto_ilex_mature_runtime_275.asm',
                    'ld [hl], $08 ; Gold LEFT roof half',
                    'ld [hl], $00 ; lost roof half', 'azalea_two_west_facade_halves')

    def test_azalea_west_facade_half_not_lost(self):
        self.reject('engine/johto_ilex_mature_runtime_275.asm',
                    'ld [hl], $1c ; Gold LEFT facade half',
                    'ld [hl], $00 ; lost facade half', 'azalea_two_west_facade_halves')

    def test_azalea_border_not_blank(self):
        self.reject('data/johto_south_runtime.asm',
                    'db $05 ; NPC-243 accepted Gold Azalea outdoor forest border',
                    'db $00 ; accidentally blanked', 'azalea_outdoor_border_05')

    def test_post_load_hook_must_reach_old_fixes(self):
        self.reject('data/johto_east_runtime_300.asm',
                    'callab PatchJohtoSouthBordersAfterBlockLoad',
                    'callab PatchJohtoMahoganyNorthBorder300', 'preview_post_load_full_dispatch')

    def test_goldenrod_city_border_not_blank(self):
        self.reject('data/johto_south_runtime.asm',
                    'db $35 ; NPC-243 accepted Gold Goldenrod outdoor border',
                    'db $00 ; wrong border', 'goldenrod_outdoor_border_35')

    def test_goldenrod_top_three_rows_must_match_real_gold(self):
        self.reject('engine/johto_ilex_mature_runtime_275.asm',
                    'db $05, $05, $58, $59, $01, $78, $44, $05, $05, $05',
                    'db $05, $05, $58, $59, $01, $78, $44, $05, $05, $00',
                    'goldenrod_north_three_gold_rows')

    def test_route34_border_not_blank(self):
        self.reject('data/johto_south_runtime.asm',
                    'db $05 ; FIX-279: Gold Route34 outdoor border is trees, not blank $00',
                    'db $00 ; wrong border', 'route34_outdoor_border_05')

    def test_route34_four_lanes_not_shrunk_to_two(self):
        self.reject('engine/johto_south_geometry.asm',
                    'cp 12 ; FIX-279: Gold has four contiguous north seam columns 8..11',
                    'cp 10 ; wrongly shrunk to two lanes',
                    'route34_four_walkable_columns_not_two')

    def test_goldenrod_reciprocal_four_lanes(self):
        self.reject('engine/johto_south_geometry.asm',
                    'cp 22 ; FIX-279: reciprocal Goldenrod south columns 18..21',
                    'cp 20 ; wrongly shrunk to two lanes',
                    'goldenrod_four_walkable_columns_not_two')

    def test_route34_city_neighbor_pointer_offset(self):
        self.reject('data/johto_south_runtime.asm',
                    'dw JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 5',
                    'dw JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 6',
                    'route34_north_to_city_display_offset')

    def test_route35_south_different_tileset_preview(self):
        self.reject('engine/johto_ilex_mature_runtime_275.asm',
                    'db $12, $15, $01, $46, $16, $1e, $44, $01, $01, $12',
                    'db $12, $15, $01, $46, $16, $1e, $44, $01, $01, $00',
                    'route35_south_tileset_safe_three_rows')

    def test_route35_north_13_columns_not_10(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10',
                    'db JOHTO_ROUTE35_WIDTH ; missing three columns',
                    'route35_north_thirteen_visible_columns')

    def test_route35_north_mirror_must_be_in_same_bank(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'ASSERT BANK(JohtoRoute35NorthRoute36Mirror) == BANK(JohtoNorthRoute35RuntimeHeader)',
                    '; removed bank constraint', 'route35_north_bank_safe_source_mirror')

    def test_route43_show_south_neighbor_even_while_sealed(self):
        # Emulates the very omission that produced the user-observed forest.
        file = 'data/johto_route43_runtime_315.asm'
        self.assertEqual((ROOT / 'maps/johto_pilot/Route43.runtime.blk').read_bytes(),
                         (self.gold / 'maps/Route43.blk').read_bytes())
        self.reject(file, 'db NORTH | SOUTH', 'db 0 ; neighbor preview lost',
                    'route43_Gold_NORTH_SOUTH_preview_flags')

    def test_route43_down_carpet_must_not_skip_collision(self):
        file = 'data/johto_vertical_gate_runtime_314.asm'
        raw = (ROOT / file).read_text()
        marker = 'JohtoVerticalGateBeforeStepProfiles314::\n'
        self.assertIn(marker, raw)
        corrupt = raw.replace(marker, marker +
            '    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 9, 51\n', 1)
        result = audit(ROOT, self.gold, {file: corrupt})
        self.assertEqual('FAIL', result['status'])
        self.assertIn('route43_south_ID65_carpet_keeps_collision_return', result['errors'])

    def test_gold_source_corruption_is_detected(self):
        file = 'maps/johto_pilot/AzaleaTown.runtime.blk'
        data = bytearray((ROOT / file).read_bytes())
        data[4] ^= 1
        result = audit(ROOT, self.gold, {file: bytes(data)})
        self.assertEqual('FAIL', result['status'])
        self.assertIn('gold_AzaleaTown_runtime_bytes', result['errors'])


if __name__ == '__main__':
    unittest.main()
