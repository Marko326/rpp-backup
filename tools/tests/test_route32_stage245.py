"""PAL-245: source-anchored, fail-closed first part of south Johto migration.

Route32 remains the stable-ID7 outdoor; the later south ruins gate (ID102) and
Ruins exterior (ID20) are now active. Other interiors and the north gate remain staged.
"""
from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return (ROOT / path).read_text(encoding='utf-8')


def segment(text, begin, end):
    return text.split(begin, 1)[1].split(end, 1)[0]


class Route32Stage245Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.stable = read('data/johto_stable_id_slots.asm')
        cls.headers = read('data/johto_pilot_map_headers.asm')
        cls.r32 = read('data/johto_route32_runtime.asm')
        cls.edge = read('engine/johto_pilot_runtime.asm')
        cls.registry = read('data/johto_pilot_source_resources.asm')

    def test_source_and_compact_map_hashes_are_frozen(self):
        fingerprints = {
            'maps/johto_pilot/Route32.gold.blk': (450, '9eecf71701520e0dfaee1809a5255401ecb2fb5cb497705dd2087fe4552ccb31'),
            'maps/johto_pilot/Route32.runtime.blk': (450, '959532d6d4adacc44156236af6e384afa09380888a2c402c348630f5babfeaaa'),
            'maps/johto_staged/JohtoUnionCave1F.blk': (180, 'cf9b29ea0b73085258e0d7cb267c070c8b21f9de0f059023c5bc5de420278811'),
            'maps/johto_staged/JohtoRoute33.blk': (90, '63f62c2461a010f1369d46fbf304617b1cba28f1fbb91026c7a8f20193ab675d'),
            'maps/johto_staged/JohtoAzaleaTown.blk': (180, 'a1bb573967204e3385b731b4e3c2aaa9ecd0f26bb85d701c096d35b69559476a'),
        }
        for rel, (size, digest) in fingerprints.items():
            with self.subTest(path=rel):
                b = (ROOT/rel).read_bytes()
                self.assertEqual(len(b), size)
                self.assertEqual(hashlib.sha256(b).hexdigest(), digest)
        # Route32 old compact layout only uses registered 0..140 Johto blockset.
        self.assertLessEqual(max((ROOT/'maps/johto_pilot/Route32.runtime.blk').read_bytes()), 140)

    def test_stable_id7_is_slot8_and_south_ruins_are_slots9_10(self):
        self.assertIn('DEF NUM_JOHTO_ACTIVE_MAPS EQU 13', read('constants/region_map_constants.asm'))
        first = next(row for row in segment(self.stable, 'JohtoStableIDToActiveSlot::', 'JohtoStableIDToActiveSlotEnd::').splitlines() if '$00-$0f' in row)
        cells = [x.strip() for x in first.split(';')[0].strip()[3:].split(',')]
        self.assertEqual(cells[5:11], ['6', '7', '8', 'JOHTO_INVALID_ACTIVE_SLOT', 'JOHTO_INVALID_ACTIVE_SLOT', 'JOHTO_INVALID_ACTIVE_SLOT'])
        r = read('data/johto_header_descriptors.asm')
        self.assertIn('dw JohtoPilotRoute32RuntimeHeader\n    db BANK(JohtoPilotRoute32RuntimeHeader)',r)
        self.assertIn('dw JohtoPilotAlphSouthGateRuntimeHeader\n    db BANK(JohtoPilotAlphSouthGateRuntimeHeader)', r)
        self.assertIn('dw JohtoPilotAlphOutsideRuntimeHeader\n    db BANK(JohtoPilotAlphOutsideRuntimeHeader)', r)
        self.assertNotIn('JohtoPilotUnionCaveRuntimeHeader', r)
        self.assertNotIn('JohtoPilotRoute33RuntimeHeader', r)
        self.assertNotIn('JohtoPilotAzaleaRuntimeHeader', r)
        row_60 = next(line for line in self.stable.splitlines() if '$60-$6f' in line)
        vals_60 = [v.strip() for v in row_60.split(';', 1)[0].strip()[3:].split(',')]
        row_10 = next(line for line in self.stable.splitlines() if '$10-$1f' in line)
        vals_10 = [v.strip() for v in row_10.split(';', 1)[0].strip()[3:].split(',')]
        self.assertEqual(vals_60[6], '9')  # stable ID102 -> active slot 9
        self.assertEqual(vals_10[4], '10') # stable ID20 -> active slot 10

    def test_route32_violet_bidirectional_connections(self):
        self.assertIn('JOHTO_VIOLET_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID', self.registry)
        self.assertIn('JOHTO_ROUTE_32_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID', self.registry)
        violet = segment(self.headers, 'JohtoPilotVioletRuntimeHeader::', 'JohtoPilotVioletRuntimeHeaderEnd::')
        self.assertIn('db SOUTH | EAST', violet)
        self.assertIn('dw JohtoPilotRoute32RuntimeBlocks', violet)
        self.assertIn('dw JohtoPilotRoute31RuntimeBlocks', violet)
        self.assertIn('dw wOverworldMap + (JOHTO_VIOLET_CITY_HEIGHT + 3) * (JOHTO_VIOLET_CITY_WIDTH + 6) + 3', violet)
        self.assertIn('== 34', self.headers)
        north = segment(self.r32, 'JohtoPilotRoute32RuntimeHeader::', 'JohtoPilotRoute32RuntimeHeaderEnd::')
        self.assertIn('db NORTH', north)
        self.assertIn('dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * (JOHTO_VIOLET_CITY_HEIGHT - 3)', north)
        self.assertIn('db JOHTO_ROUTE_32_WIDTH + 3', north)
        self.assertIn('db JOHTO_VIOLET_CITY_HEIGHT * 2 - 1', north)
        self.assertIn('ASSERT BANK(JohtoPilotRoute32RuntimeHeader) == BANK(JohtoPilotVioletRuntimeBlocks)', self.r32)

    def test_both_side_entry_tiles_are_actually_passable(self):
        """Opening the edge is useless if the connecting tiles still collide."""
        blocks = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        passable = set((ROOT / 'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
        self.assertIn(0x05, passable)
        for name, width, y_rows in (
            ('VioletCity', 20, (34, 35)),
            ('Route32', 10, (0, 1)),
        ):
            layout = (ROOT / f'maps/johto_pilot/{name}.runtime.blk').read_bytes()
            for y in y_rows:
                for x in (14, 15):
                    with self.subTest(map=name, x=x, y=y):
                        block_id = layout[(y // 2) * width + (x // 2)]
                        # A 16x16 cell uses four adjacent tiles in a 4x4 block.
                        top = (y % 2) * 2
                        left = (x % 2) * 2
                        quad = [blocks[block_id * 16 + (top + row) * 4 + left + col]
                                for row in (0, 1) for col in (0, 1)]
                        self.assertTrue(all(tile in passable for tile in quad),
                                        f'{name} ({y},{x}) has impassable tiles: {quad}')

    def test_only_x14_15_entrance_lane_open_on_both_sides(self):
        violet = segment(self.edge, '\n.violetSouth\n', '\n.route32\n')
        north = segment(self.edge, '\n.route32North\n', '\n.route32South\n')
        for routine in (violet, north):
            self.assertRegex(routine, r'cp 14\s+jp c, .closed\s+cp 16\s+ret c\s+jp .closed')
        south = segment(self.edge, '\n.route32South\n', '\n.route32West\n')
        self.assertIn('cp JOHTO_ROUTE_32_HEIGHT * 2 - 1', south)
        self.assertIn('jp .closed', south)

    def test_south_gate_warps_are_explicit_and_other_exits_stay_closed(self):
        objs = segment(self.r32, 'JohtoPilotRoute32RuntimeObjects::', '\n    db 0 ; NPCs')
        self.assertIn('db 2 ; Gold ruins west gate pair only; center/cave remain closed', objs)
        self.assertIn('db 4 ; Gold signs', objs)
        runtime_routes = segment(self.edge, 'JohtoRegisteredWarpRoutes::', 'JohtoRegisteredWarpRoutesEnd::')
        self.assertEqual(2, runtime_routes.count('JOHTO_ROUTE_32_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID') + runtime_routes.count('JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID'))
        self.assertIn('JOHTO_RUINS_OF_ALPH_LOCAL_ID', runtime_routes)
        self.assertIn('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', runtime_routes)
        self.assertNotIn('JOHTO_UNION_CAVE_1F_LOCAL_ID', runtime_routes)
        self.assertIn('db NORTH\n', self.r32)
        self.assertNotIn('db NORTH | SOUTH\n', self.r32)

    def test_gold_music_and_sav244_recovery_preserved(self):
        options = read('engine/menu/options_menu.asm')
        self.assertIn('db MUSIC_GBP_GSC_ROUTE30         ; slot 8:', options)
        self.assertIn('johto_map_profile 1, 7, MUSIC_ROUTES1, 0', self.edge)
        home = read('home/overworld.asm')
        branch = segment(home, '\tbit 7,b\n\tjr z, .readMapHeader', '\n.readMapHeader')
        self.assertIn('predef LoadTilesetHeader', branch)
        self.assertIn('ld [wDestinationWarpID], a', branch)

    def test_current_discrete_map_headers_and_no_raw_old_aliases(self):
        self.assertIn('db JOHTO_RUNTIME_MAP_HANDLE', self.r32)
        self.assertIn('ASSERT JohtoPilotRoute32RuntimeHeaderEnd - JohtoPilotRoute32RuntimeHeader == 23', self.r32)
        self.assertNotIn('JOHTO_ROUTE_32 ; legacy', self.r32)
        self.assertIn('INCLUDE "data/johto_route32_runtime.asm"', read('main.asm'))


if __name__ == '__main__':
    unittest.main()
