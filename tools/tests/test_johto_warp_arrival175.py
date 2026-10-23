"""Kanto-style cave collision return regression contracts.

Historical filename kept for discovery compatibility; old automatic cave-step
assertions were an implementation detail, not an accepted gameplay behavior.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
import os
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_warp_arrival_audit import INPUTS, audit, profiles, walkable  # noqa: E402


class JohtoWarpArrivalContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        raw = os.environ.get('JOHTO_GOLD_SOURCE')
        cls.gold = Path(raw) if raw else None

    def test_cave_no_auto_step_and_north_gate_safe_profiles(self):
        self.assertEqual(audit(ROOT, self.gold), [])
        src = (ROOT / INPUTS[0]).read_text()
        actual=profiles(src)
        self.assertEqual(actual[9:11], [
            ('JOHTO_ROUTE_32', 'JOHTO_ROUTE_32_LOCAL_ID', 79, 6,
             'REGION_NATIVE_MAP_SLOT', 'D_DOWN'),
            ('REGION_NATIVE_MAP_SLOT', 'JOHTO_ROUTE_33_LOCAL_ID', 9, 11,
             'REGION_NATIVE_MAP_SLOT', 'D_DOWN')])
        self.assertEqual(len(actual), 23)
        # New Route29/Route46 gate arrivals occupy three deliberately
        # prepended rows; keep the old cave and north-gate rows unchanged.
        self.assertEqual(actual[:3], [
            ('REGION_NATIVE_MAP_SLOT', 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 0, 4,
             'REGION_NATIVE_MAP_SLOT', 'D_DOWN'),
            ('REGION_NATIVE_MAP_SLOT', 'JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID', 0, 5,
             'REGION_NATIVE_MAP_SLOT', 'D_DOWN'),
            ('JOHTO_ROUTE_29', 'JOHTO_ROUTE_29_LOCAL_ID', 1, 27,
             'REGION_NATIVE_MAP_SLOT', 'D_DOWN')])
        self.assertFalse(any('JOHTO_UNION_CAVE_1F_LOCAL_ID' in row for row in actual))
        self.assertTrue(walkable(ROOT, 'JohtoUnionCave1F', 'johto_union_cave', 10, 17, 3))
        self.assertFalse(walkable(ROOT, 'JohtoUnionCave1F', 'johto_union_cave', 10, 17, 4))
        self.assertTrue(walkable(ROOT, 'JohtoRoute32', 'johto', 10, 6, 80))

    def mutate(self, name, before, after, expected):
        with TemporaryDirectory() as td:
            root = Path(td)
            for rel in INPUTS:
                target = root / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / rel, target)
            p = root / name
            src = p.read_text()
            self.assertIn(before, src)
            p.write_text(src.replace(before, after, 1))
            errors = audit(root, self.gold)
            self.assertTrue(any(expected in value for value in errors), errors)

    def test_unconditional_reject_after_correct_direction_fails(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'cp PLAYER_DIR_UP\n\tjr nz, .blocked\n\tscf',
                    'cp PLAYER_DIR_UP\n\tjr nz, .blocked\n\tjr .blocked\n\tscf',
                    'Route32 cave entrance branch')

    def test_unconditional_accept_after_x_guard_fails(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'cp 6\n\tjr nz, .blocked\n\tld a, [wYCoord]',
                    'cp 6\n\tjr nz, .blocked\n\tscf\n\tret\n\tld a, [wYCoord]',
                    'Route32 cave entrance branch')

    def test_reintroducing_cave_auto_step_fails(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    '\tdb $ff\n\n; Native cave entrances use',
                    ('\tdb REGION_NATIVE_MAP_SLOT, JOHTO_UNION_CAVE_1F_LOCAL_ID, 3, 17, '
                     'JOHTO_ROUTE_32, D_UP\n\tdb $ff\n\n; Native cave entrances use'),
                    'Only reviewed gate DOWN arrivals')

    def test_wrong_outdoor_direction_fails(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    '79, 6, REGION_NATIVE_MAP_SLOT, D_DOWN',
                    '79, 6, REGION_NATIVE_MAP_SLOT, D_UP',
                    'Only reviewed gate DOWN arrivals')

    def test_unregistered_cave_warp_fails(self):
        self.mutate('data/mapObjects/JohtoUnionCave1F.asm',
                    'db 3, 17, 0, REGION_WARP_ESCAPE',
                    'db 3, 16, 0, REGION_WARP_ESCAPE',
                    'original Gold cave and Route32 Warp coordinates')

    def test_cave_floor_step_on_returns_fails(self):
        self.mutate('data/warp_tile_ids.asm',
                    'JohtoUnionCaveWarpTileIDs:\n\tdb $FF',
                    'JohtoUnionCaveWarpTileIDs:\n\tdb 0,$FF',
                    'floor must not be a step-on Warp')

    def test_missing_cave_collision_coordinate_fails(self):
        self.mutate('engine/overworld/player_state.asm',
                    '\tcp 17\n\tjr nz, .normalDownEdge',
                    '\tcp 16\n\tjr nz, .normalDownEdge',
                    'exact x=17,y=3')

    def test_cave_collision_wrong_map_guard_fails(self):
        self.mutate('engine/overworld/player_state.asm',
                    '\tcp JOHTO_UNION_CAVE_1F_LOCAL_ID\n\tjr nz, .normalDownEdge',
                    '\tcp JOHTO_ROUTE_32_LOCAL_ID\n\tjr nz, .normalDownEdge',
                    'missing targeted Union Cave DOWN collision guard')


if __name__ == '__main__':
    unittest.main()
