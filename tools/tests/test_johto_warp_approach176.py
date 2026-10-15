"""Regression guard: do not restore the obsolete walk-on cave-exit mechanism.

Historical filename retained; test expectations now follow the Kanto-style
collision return implemented after comparing Victory Road.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_warp_arrival_audit import INPUTS, audit  # noqa: E402


class UnionCaveApproach(unittest.TestCase):
    def test_collision_exit_and_sideways_safety(self):
        self.assertEqual(audit(ROOT), [])
        tiles = (ROOT / 'data/warp_tile_ids.asm').read_text()
        self.assertIn('JohtoUnionCaveWarpTileIDs:\n\tdb $FF', tiles)
        self.assertIn('JohtoGateWarpTileIDs:\n\tdb $FF', tiles)
        state = (ROOT / 'engine/overworld/player_state.asm').read_text()
        down = state.split('\n.facingDown\n', 1)[1].split('\n.facingUp\n', 1)[0]
        for check in ('cp REGION_NATIVE_MAP_SLOT', 'cp MAP_REGION_JOHTO',
                      'cp JOHTO_UNION_CAVE_1F_LOCAL_ID',
                      'cp 17', 'cp 3', 'jr z, .setCarry'):
            self.assertIn(check, down)
        lookup = (ROOT / 'engine/overworld/region_map_lookup.asm').read_text()
        self.assertNotIn('GetJohtoWalkOnWarpAllowed', lookup)
        self.assertNotIn('GetJohtoWalkOnWarpAllowed', state)
        self.assertIn('callba JohtoRoute32CaveWarpTileCheck', state)
        self.assertIn('GATE-5.62.157', state)

    def mutate(self, rel, before, after, expected):
        with TemporaryDirectory() as td:
            root = Path(td)
            for name in INPUTS:
                dest = root / name
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, dest)
            p = root / rel
            src = p.read_text()
            self.assertIn(before, src)
            p.write_text(src.replace(before, after, 1))
            self.assertTrue(any(expected in e for e in audit(root)), audit(root))

    def test_wrong_exit_y_cannot_pass(self):
        self.mutate('engine/overworld/player_state.asm',
                    '\tcp 3\n\tjr z, .setCarry',
                    '\tcp 2\n\tjr z, .setCarry',
                    'exact x=17,y=3')

    def test_wrong_direction_router_cannot_pass(self):
        self.mutate('home/overworld.asm',
                    '\tld hl, IsPlayerFacingEdgeOfMap',
                    '\tld hl, IsWarpTileInFrontOfPlayer',
                    'original RPP facing-edge collision check')

    def test_no_collision_flag_cannot_pass(self):
        self.mutate('engine/overworld/player_state.asm',
                    '\tset 2, [hl] ; standing on warp flag\n\tret',
                    '\tres 2, [hl] ; standing on warp flag\n\tret',
                    'standing-on-warp collision flag')


if __name__ == '__main__':
    unittest.main()
