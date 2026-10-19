"""R32-5.62.165 P1-B/C: self-contained Route32 and Violet connection."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class Route32StagingTests(unittest.TestCase):
    def src(self, path):
        return (ROOT / path).read_text(encoding='utf-8')

    def test_gold_size_and_shared_blockset(self):
        blocks = (ROOT / 'maps/JohtoRoute32.blk').read_bytes()
        shared = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        self.assertEqual(len(blocks), 450)
        self.assertEqual(len(shared), 139 * 16)  # Route35 Cut $89 + Ruins cliff $8A; original 137 unchanged
        self.assertLess(max(blocks), 137)
        self.assertEqual(blocks[68], 0x83)
        self.assertEqual(blocks[404], 0x88)

    def test_registered_id_and_bank_tables(self):
        mapconst = self.src('constants/map_constants.asm')
        self.assertRegex(mapconst, r'(?m)^\s*mapconst JOHTO_ROUTE_32,\s*45,\s*10 ; \$FB')
        self.assertIn('DEF JOHTO_ROUTE_32_LOCAL_ID EQU 7', self.src('constants/region_map_constants.asm'))
        for f in ('data/map_header_pointers.asm', 'data/map_header_banks.asm',
                  'data/johto_map_headers.asm', 'data/map_songs.asm'):
            self.assertIn('JOHTO_ROUTE_32', self.src(f)) if f.endswith('map_songs.asm') else self.assertIn('JohtoRoute32', self.src(f))

    def test_connected_north_only_and_invalid_warps_still_sealed(self):
        header = self.src('data/mapHeaders/JohtoRoute32.asm')
        violet = self.src('data/mapHeaders/JohtoVioletCity.asm')
        objects = self.src('data/mapObjects/JohtoRoute32.asm')
        self.assertRegex(header, r'(?m)^\s*db NORTH \| SOUTH$')
        self.assertRegex(violet, r'(?m)^\s*db SOUTH \| WEST \| EAST$')
        self.assertRegex(objects, r'(?m)^\s*db \$01 ; the original cave-mouth Warp only')
        self.assertIn('dw JohtoRoute33Blocks', header) ; self.assertNotIn('SOUTH_MAP_CONNECTION', header)
        self.assertIn('jp z, JohtoRoute32CollisionFence', self.src('main.asm'))

    def test_region_ledge_music_and_names(self):
        lookup = self.src('engine/overworld/region_map_lookup.asm')
        self.assertIn('cp JOHTO_ROUTE_32\n\tjr z, .route32', lookup)
        self.assertNotIn('jr z, .route32:', lookup)
        self.assertIn('cp JOHTO_ROUTE_32', self.src('engine/overworld/ledges.asm'))
        self.assertIn('JohtoRoute32TownMapName: db "Route 32@"', self.src('engine/town_map.asm'))
        self.assertIn('JOHTO_ROUTE_32,            MUSIC_GBP_GSC_ROUTE30', self.src('engine/menu/options_menu.asm'))
        self.assertRegex(self.src('data/game_version.asm'), r'db \"[A-Z]+-5\.62\.\d+@\"')

    def test_hide_show_table_is_bounded(self):
        s = self.src('data/hide_show_data.asm')
        block = s.split('MapHSPointers:', 1)[1].split('MapHSPointersEnd:', 1)[0]
        self.assertEqual(len(re.findall(r'(?m)^\s*dw MapHS\w+', block)), 253)
        self.assertIn('NUM_LEGACY_MAPS * 2', s)


if __name__ == '__main__':
    unittest.main()
