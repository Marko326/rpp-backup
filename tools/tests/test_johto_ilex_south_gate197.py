"""P16 Gold vs runtime south-gate mapping; explicit negative mutations."""
from pathlib import Path
import os
import sys
import unittest
from tempfile import TemporaryDirectory
import shutil
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_ilex_gate_runtime_audit import audit, FILES
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))

class IlexSouthGate197(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/IlexForestAzaleaGate.asm').is_file():
            raise AssertionError('Gold full source required')
    def test_gold_exact_two_way_registered_warps(self):
        self.assertEqual(audit(ROOT,GOLD),[])
    def test_original_east_pair_stays_in_front(self):
        from johto_indoor_common import rpp_warps
        gate=rpp_warps(ROOT,'JohtoIlexAzaleaGate')
        self.assertEqual([(x['x'], x['y']) for x in gate[:2]], [(9,4),(9,5)])
        self.assertEqual(len(gate),4)
    def mutation(self, path,old,new,reason):
        with TemporaryDirectory() as tmp:
            p=Path(tmp)
            for item in FILES + ('maps/JohtoIlexAzaleaGate.blk','maps/JohtoRoute31VioletGate.blk','maps/JohtoAzaleaTown.blocked_mask.bin'):
                dest=p/item;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/item,dest)
            file=p/path;s=file.read_text()
            self.assertIn(old,s)
            file.write_text(s.replace(old,new,1))
            self.assertTrue(any(reason in e for e in audit(p,GOLD)))
    def test_native_gate_neutral_name_sign_and_route34_townmap_unchanged(self):
        sign=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
        self.assertIn('cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID', sign.split('.IsNeutralMap\n',1)[1])
        self.assertIn('dw JohtoBrowseRoute34Name', (ROOT/'engine/town_map.asm').read_text())

    def test_missing_gate_neutral_sign_fails(self):
        self.mutation('engine/overworld/map_name_sign.asm',
                      'cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID\n\tret z',
                      'cp JOHTO_ROUTE_33_LOCAL_ID\n\tret z', 'map-name popup')
    def test_overbroad_all_native_gate_neutral_fails(self):
        self.mutation('engine/overworld/map_name_sign.asm',
                      'cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID\n\tret z',
                      'cp REGION_NATIVE_MAP_SLOT\n\tret z', 'map-name popup')
    def test_swapped_gold_gate_pair_is_rejected(self):
        self.mutation('data/mapObjects/JohtoAzaleaTown.asm',
                      'db 11, 2, 1, REGION_WARP_ESCAPE',
                      'db 11, 2, 0, REGION_WARP_ESCAPE', 'town gate Warp')
    def test_east_warp_count_removal_fails(self):
        self.mutation('data/mapObjects/JohtoIlexAzaleaGate.asm',
                      'db $04\n\tdb 4, 9', 'db $01\n\tdb 4, 9', 'gate return Warp')
    def test_wrong_native_region_mapping_rejected(self):
        self.mutation('engine/overworld/region_map_lookup.asm',
                      'JOHTO_AZALEA_TOWN_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
                      'JOHTO_AZALEA_TOWN_LOCAL_ID, 1, 1, MAP_REGION_KANTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
                      'native two-way warp')
    def test_missing_exact_entry_check_fails(self):
        self.mutation('home/overworld.asm',
                      'call IsJohtoSouthGatePortal\n\tjr nc, .checkOrdinaryWarpTile',
                      'and a\n\tjr nc, .checkOrdinaryWarpTile',
                      'step-on auto-warp')
    def test_collision_wrong_direction_outside_fails(self):
        self.mutation('home/overworld.asm',
                      'cp PLAYER_DIR_LEFT\n\tjr nz, .retry2',
                      'cp PLAYER_DIR_RIGHT\n\tjr nz, .retry2',
                      'collision Warp')
    def test_collision_wrong_direction_inside_fails(self):
        self.mutation('home/overworld.asm',
                      '.gateReturnsEast\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_RIGHT',
                      '.gateReturnsEast\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_LEFT',
                      'collision Warp')
    def test_no_vertical_pair_walk_fails(self):
        self.mutation('engine/overworld/johto_route33_collision.asm',
                      '.upperCarpet\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_DOWN',
                      '.upperCarpet\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_RIGHT',
                      'gate carpet')
    def test_missing_azalea_collision_edge_fails(self):
        self.mutation('engine/overworld/player_state.asm',
                      'cp JOHTO_AZALEA_TOWN_LOCAL_ID\n\tjr nz, .normalLeftEdge',
                      'cp JOHTO_ROUTE_33_LOCAL_ID\n\tjr nz, .normalLeftEdge',
                      'left collision')
    def test_wrong_border_map_identity_fails(self):
        self.mutation('engine/overworld/johto_route33_collision.asm',
                      'cp JOHTO_AZALEA_TOWN_LOCAL_ID\n\tret nz',
                      'cp JOHTO_ROUTE_33_LOCAL_ID\n\tret nz',
                      'west gate border')
    def test_wrong_border_offset_fails(self):
        self.mutation('engine/overworld/johto_route33_collision.asm',
                      'MAP_BORDER + 4) * (JOHTO_AZALEA_TOWN_WIDTH',
                      'MAP_BORDER + 3) * (JOHTO_AZALEA_TOWN_WIDTH',
                      'west gate border')
    def test_unchecked_border_draw_order_fails(self):
        self.mutation('home/overworld.asm',
                      'callba PatchJohtoAzaleaWestGateBorder',
                      'callba JohtoAzaleaCanStepAhead',
                      'west gate border')
    def test_missing_connected_map_border_refresh_fails(self):
        self.mutation('home/overworld.asm',
                      'callba PatchJohtoAzaleaWestGateBorder\n\tjp OverworldLoopLessDelay',
                      'callba InitMapSprites\n\tjp OverworldLoopLessDelay',
                      'BOTH full Warp and seamless connected-map')
    def test_missing_full_map_border_refresh_fails(self):
        self.mutation('home/overworld.asm',
                      'callba PatchJohtoAzaleaWestGateBorder\n\tcall LoadTilesetTilePatternData',
                      'callba InitMapSprites\n\tcall LoadTilesetTilePatternData',
                      'BOTH full Warp and seamless connected-map')
    def test_duplicate_house_right_roof_detected(self):
        self.mutation('engine/overworld/johto_route33_collision.asm',
                      'ld [hl], $08 ; Gold LEFT roof',
                      'ld [hl], $09 ; Gold LEFT roof',
                      'LEFT Gold building halves')
    def test_duplicate_house_right_wall_detected(self):
        self.mutation('engine/overworld/johto_route33_collision.asm',
                      'ld [hl], $1c ; Gold LEFT facade',
                      'ld [hl], $1e ; Gold LEFT facade',
                      'LEFT Gold building halves')
    def test_bad_gate_map_identity_fails(self):
        self.mutation('home/overworld.asm',
                      'cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID\n\tjr z, .yes',
                      'cp JOHTO_ROUTE_33_LOCAL_ID\n\tjr z, .yes',
                      'source identity')

if __name__ == '__main__':
    unittest.main()
