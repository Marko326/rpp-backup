"""FIX-289 double-entry map boundary regressions + mutation rejection."""
import unittest
from pathlib import Path
from tools.johto_route36_seam_audit_289 import audit
ROOT=Path(__file__).resolve().parents[2]
class Route36Seam289(unittest.TestCase):
    def test_candidate(self):
        self.assertEqual([],audit(ROOT)['errors'])
    def reject(self,rel,old,new,key):
        actual=(ROOT/rel).read_text();self.assertIn(old,actual)
        result=audit(ROOT,changes={rel:actual.replace(old,new,1)})
        self.assertIn(key,result['errors'],result['errors'])
    def test_route35_north_width_10_rejected(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10',
                    'db JOHTO_ROUTE35_WIDTH ; only ten overlapping columns',
                    'route35_north_thirteen_column_right_preview')
    def test_route35_north_width_12_rejected(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10',
                    'db JOHTO_ROUTE35_WIDTH + 2 ; only twelve',
                    'route35_north_display_buffer_exact_capacity')
    def test_route35_north_width_14_overflow_rejected(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10',
                    'db JOHTO_ROUTE35_WIDTH + 4 ; exceeds right border',
                    'route35_north_display_buffer_exact_capacity')
    def test_route35_north_wrong_source_row_rejected(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)',
                    'JohtoRoute35NorthRoute36Mirror + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 2)',
                    'route35_north_thirteen_column_right_preview')
    def test_route35_north_wrong_destination_col_rejected(self):
        self.reject('data/johto_north_runtime_283.asm',
                    'dw wOverworldMap + 3',
                    'dw wOverworldMap + 4',
                    'route35_north_thirteen_column_right_preview')
    def test_route35_north_exit_not_widened(self):
        self.reject('engine/johto_south_geometry.asm',
                    'cp 17 ; only Gold mature collision lane (Route35 x17 -> Route36 x17)',
                    'cp 18 ; widened lane unintentionally',
                    'route35_single_mature_north_lane')
    def test_remove_south_route(self):
        self.reject('data/johto_pilot_source_resources.asm',
                    'JOHTO_ROUTE_36_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID',
                    'JOHTO_ROUTE_36_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID',
                    'registered_exact_six_and_route37_reciprocal')
    def test_violet_west_connection(self):
        self.reject('data/johto_pilot_map_headers.asm','dw JohtoVioletWestRoute36Mirror + JOHTO_ROUTE_36_WIDTH - 3',
                    'dw JohtoPilotRoute36RuntimeBlocks + JOHTO_ROUTE_36_WIDTH - 3',
                    'violet_west_header_retains_south_route32_east_route31')
    def test_wrong_bank_mirror(self):
        self.reject('data/johto_ruins_north_runtime.asm',
                    'ASSERT BANK(JohtoRoute36EastVioletMirror) == BANK(JohtoPilotRoute36RuntimeHeader)',
                    'ASSERT BANK(JohtoRoute36EastVioletMirror) == BANK(JohtoPilotVioletRuntimeHeader)',
                    'all_four_neighbor_mirrors_are_real_same_bank_payloads')
    def test_broad_open_south_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm','cp 17\n    ret z\n    jp .closed\n.route36Left',
                    'ret\n.route36Left','route36_only_two_gold_boundary_lanes')
    def test_broad_open_route35_rejected(self):
        self.reject('engine/johto_south_geometry.asm','cp 17 ; only Gold mature collision lane (Route35 x17 -> Route36 x17)',
                    'cp 18 ; wrongly widened','route35_single_mature_north_lane')
    def test_north_route37_reciprocal_required(self):
        self.reject('data/johto_pilot_source_resources.asm',
                    'JOHTO_ROUTE_36_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID',
                    'JOHTO_ROUTE_36_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_37_LOCAL_ID',
                    'registered_exact_six_and_route37_reciprocal')
    def test_preserve_park_warp(self):
        self.reject('data/johto_ruins_north_runtime.asm',
                    'db 8, 18, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 8, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                    'existing_park_and_ruins_warps_unchanged')
if __name__=='__main__': unittest.main()
