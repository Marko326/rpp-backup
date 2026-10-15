"""GATE-5.62.157: offline source-level regression for the native Warp handoff.

These checks deliberately do not claim emulator/runtime input verification.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_indoor_common import (rpp_warps, tile_at, rpp_tileset, warp_tile_ids)


class Route31VioletNativeGate(unittest.TestCase):
    def test_gate_warp_graph_keeps_all_four_pairs(self):
        g = rpp_warps(ROOT, 'JohtoRoute31VioletGate')
        city = rpp_warps(ROOT, 'JohtoVioletCity')
        route = rpp_warps(ROOT, 'JohtoRoute31')
        self.assertEqual([(w['x'], w['y'], w['dest_id']) for w in g],
                         [(0, 4, 0), (0, 5, 1), (9, 4, 0), (9, 5, 1)])
        self.assertEqual([(w['x'], w['y'], w['dest_id']) for w in city],
                         [(39, 24, 0), (39, 25, 1)])
        self.assertEqual([(w['x'], w['y'], w['dest_id']) for w in route],
                         [(4, 6, 2), (4, 7, 3)])

    def test_walkable_gate_portal_does_not_auto_warp(self):
        passable = (ROOT/'gfx/tilesets/johto.tilecoll').read_bytes()
        self.assertIn(0x40, passable[:-1])
        self.assertEqual(passable[-1], 0xff)
        tile_ids = warp_tile_ids(ROOT, 'NewBarkWarpTileIDs')
        self.assertNotIn(0x40, tile_ids)
        self.assertIn(0x06, tile_ids)  # preserve existing special warp pad
        for name in ('JohtoVioletCity', 'JohtoRoute31'):
            for w in rpp_warps(ROOT, name):
                self.assertEqual(tile_at(ROOT, name, w['x'], w['y'], 'johto'), [0x40]*4)

    def test_outdoor_gate_warps_require_a_second_collision_input(self):
        src = (ROOT/'home/overworld.asm').read_text()
        block = src.split('CheckWarpsNoCollisionLoop::', 1)[1].split('CheckWarpsCollision::', 1)[0]
        self.assertIn('set 2,[hl] ; standing on warp flag', block)
        self.assertRegex(block, r'cp JOHTO_ROUTE31_VIOLET_GATE\s*\n\s*jp z,CheckWarpsNoCollisionRetry2')
        self.assertLess(block.index('set 2,[hl]'), block.index('cp JOHTO_ROUTE31_VIOLET_GATE'))
        self.assertIn('call ExtraWarpCheck', block)
        collision = src.split('CheckWarpsCollision::', 1)[1].split('WarpFound2::', 1)[0]
        self.assertIn('ld [wDestinationWarpID],a', collision)
        self.assertIn('jr WarpFound2', collision)

    def test_route31_pseudo_edge_only_for_two_west_gate_lanes(self):
        src = (ROOT/'engine/overworld/player_state.asm').read_text()
        section = src.split('IsPlayerFacingEdgeOfMap:', 1)[1].split('IsWarpTileInFrontOfPlayer:', 1)[0]
        left = section.split('\n.facingLeft\n', 1)[1].split('\n.facingRight\n', 1)[0]
        for condition in ('cp JOHTO_ROUTE_31', 'cp 4', 'cp 6', 'cp 7', '.normalLeftEdge'):
            self.assertIn(condition, left)
        self.assertIn('jr nz, .normalLeftEdge', left)
        self.assertIn('jr z, .setCarry', left)
        self.assertIn('ld a, c\n\tand a\n\tjr z, .setCarry', left)
        # ExtraWarpCheck already calls IsPlayerFacingEdgeOfMap for JOHTO.
        extra = (ROOT/'home/overworld.asm').read_text().split('ExtraWarpCheck::', 1)[1].split('MapEntryAfterBattle::', 1)[0]
        self.assertIn('ld hl, IsPlayerFacingEdgeOfMap', extra)
        self.assertNotIn('cp JOHTO', extra)  # no global direction override

    def test_existing_route15_and_indoor_collision_remain_unchanged(self):
        self.assertEqual(rpp_tileset(ROOT, 'JohtoRoute31VioletGate'), 'GATE')
        self.assertEqual([(w['x'], w['y']) for w in rpp_warps(ROOT, 'Route15Gate1F')[:4]],
                         [(0, 4), (0, 5), (7, 4), (7, 5)])
        self.assertEqual(rpp_tileset(ROOT, 'Route15Gate1F'), 'GATE')

    def test_version_is_a_new_game_function_version(self):
        self.assertIn('GT-5.62.158@', (ROOT/'data/game_version.asm').read_text())


if __name__ == '__main__':
    unittest.main()
