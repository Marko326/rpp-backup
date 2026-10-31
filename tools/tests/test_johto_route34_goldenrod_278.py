"""Active north-of-Ilex road/city seam: source and fault-injection tests."""
from pathlib import Path
import os
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_route34_goldenrod_audit_278 import audit

FILES = (
    'data/johto_south_runtime.asm',
    'engine/johto_ilex_mature_runtime_275.asm',
    'home/overworld.asm',
    'data/johto_pilot_source_resources.asm',
    'engine/johto_south_geometry.asm',
    'engine/johto_pilot_runtime.asm',
    'engine/johto_south_portals.asm',
    'constants/region_map_constants.asm',
    'maps/johto_pilot/Route34.roles.bin',
    'maps/johto_pilot/Route34.runtime.blk',
    'maps/johto_pilot/Route34.gold.blk',
    'maps/johto_pilot/GoldenrodCity.roles.bin',
    'maps/johto_pilot/GoldenrodCity.runtime.blk',
    'maps/johto_pilot/GoldenrodCity.gold.blk',
)


class Route34Goldenrod278(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'project'
        for rel in FILES:
            dest = self.root / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / rel, dest)
        # Gold reference is optional in standalone tests. Never manufacture a
        # pseudo-Gold project to claim a real source verification passed.
        real_gold = Path(os.environ.get('GOLD_SOURCE_ROOT', '/__no_gold__'))
        self.gold = (Path(self.tmp.name) / 'gold') if real_gold.is_dir() else None
        if self.gold is not None:
            for rel in ('data/maps/attributes.asm', 'maps/Route34.blk', 'maps/GoldenrodCity.blk', 'maps/Route35.blk'):
                dest = self.gold / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(real_gold / rel, dest)

    def result(self):
        return audit(self.root, self.gold)

    def mutate(self, rel, before: bytes, after: bytes, check):
        if rel.startswith('gold/') and self.gold is None:
            self.skipTest('actual Gold reference not configured')
        p = (self.gold if rel.startswith('gold/') else self.root) / rel.removeprefix('gold/')
        raw = p.read_bytes()
        self.assertIn(before, raw)
        p.write_bytes(raw.replace(before, after, 1))
        result = self.result()
        self.assertEqual('FAIL', result['status'], result)
        self.assertIn(check, result['errors'], result)
        p.write_bytes(raw)

    def test_current_pair_is_wired_and_walkable(self):
        result = self.result()
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result)
        self.assertGreaterEqual(len(result['checks']), 12)
        self.assertFalse(result['rom_built'])
        self.assertFalse(result['phone_accepted'])

    def test_valid_jp_and_jr_closure_variants_both_keep_four_lanes(self):
        # The user's device uses longer JP jumps where the earlier assistant
        # candidate used JR. Both are valid when the edge contract is intact.
        p = self.root / 'engine/johto_south_geometry.asm'
        raw = p.read_bytes()
        first = b'cp 12 ; FIX-279: Gold has four contiguous north seam columns 8..11\n    ret c\n    jp .closed'
        second = b'cp 22 ; FIX-279:'
        self.assertIn(first, raw)
        self.assertIn(second, raw)
        changed = raw.replace(first, first.replace(b'jp .closed', b'jr .closed'), 1)
        pos = changed.index(second)
        target = b'    ret c\n    jr .closed'
        k = changed.find(target, pos)
        self.assertNotEqual(-1, k)
        changed = changed[:k] + target.replace(b'jr .closed', b'jp .closed') + changed[k + len(target):]
        p.write_bytes(changed)
        self.assertEqual('PASS_STATIC_ONLY', self.result()['status'])

    def test_gold_connection_offset_regression(self):
        self.mutate('gold/data/maps/attributes.asm', b'GOLDENROD_CITY, -5',
                    b'GOLDENROD_CITY, -4', 'gold_reciprocal_seam_offsets')

    def test_route34_header_offset_regression(self):
        self.mutate('data/johto_south_runtime.asm',
                    b'JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 5',
                    b'JohtoSouthGoldenrodCityBlocks + 20 * (18 - 3) + 6',
                    'route34_north_runtime_connection')

    def test_goldenrod_header_offset_regression(self):
        self.mutate('data/johto_south_runtime.asm',
                    b'JohtoSouthRoute34Blocks\n    dw wOverworldMap + (18 + 3) * (20 + 6) + 3 + 5',
                    b'JohtoSouthRoute34Blocks\n    dw wOverworldMap + (18 + 3) * (20 + 6) + 3 + 6',
                    'goldenrod_south_runtime_connection')

    def test_north_four_lane_fence_must_not_shrink(self):
        self.mutate('engine/johto_south_geometry.asm',
                    b'cp 12 ; FIX-279:',
                    b'cp 10 ; FIX-279:',
                    'route34_north_gold_four_lanes')


    def test_city_south_four_lane_fence_must_not_shrink(self):
        self.mutate('engine/johto_south_geometry.asm',
                    b'cp 22 ; FIX-279:', b'cp 20 ; FIX-279:',
                    'goldenrod_south_gold_four_lanes')

    def test_route34_exterior_tree_border_not_blank(self):
        self.mutate('data/johto_south_runtime.asm',
                    b'db $05 ; FIX-279: Gold Route34',
                    b'db $00 ; FIX-279: Gold Route34',
                    'route34_gold_tree_border')

    def test_goldenrod_north_buffer_must_match_gold(self):
        self.mutate('engine/johto_ilex_mature_runtime_275.asm',
                    b'db $05, $05, $58, $59, $01, $78, $44, $05, $05, $05',
                    b'db $05, $05, $58, $59, $00, $78, $44, $05, $05, $05',
                    'route35_gold_three_buffer_rows')

    def test_north_preview_must_be_called_after_blockmap(self):
        self.mutate('home/overworld.asm',
                    b'callab PatchJohtoSouthBordersAfterBlockLoad',
                    b'callab PatchJohtoAzaleaWestGateBorder',
                    'north_preview_runs_after_full_and_connection_load')

    def test_north_preview_must_not_replace_azalea_fix(self):
        self.mutate('engine/johto_ilex_mature_runtime_275.asm',
                    b'call PatchJohtoAzaleaWestGateBorder\n    call PatchJohtoGoldenrodNorthBorder\n    jp PatchJohtoRoute35SouthBorder',
                    b'call PatchJohtoGoldenrodNorthBorder\n    call PatchJohtoGoldenrodNorthBorder\n    jp PatchJohtoRoute35SouthBorder',
                    'preserve_azalea_then_north_preview_same_romx_bank')

    def test_route35_stays_closed_not_a_real_map_connection(self):
        self.mutate('data/johto_south_runtime.asm',
                    b'JohtoSouthGoldenrodCityRuntimeHeader::\n    db JOHTO_MODERN\n    db 18, 20',
                    b'JohtoSouthGoldenrodCityRuntimeHeader::\n    db JOHTO_MODERN\n    db 18, 20\n    db NORTH',
                    'goldenrod_north_preview_address_and_guard')

    def test_gate_return_warp_ordinal(self):
        self.mutate('data/johto_south_runtime.asm',
                    b'db 37, 14, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                    b'db 37, 14, 3, JOHTO_REGISTERED_WARP_SELECTOR',
                    'gate_to_route34_two_warps')

    def test_path_cut_by_new_collision_wall(self):
        p = self.root / 'maps/johto_pilot/Route34.roles.bin'
        data = bytearray(p.read_bytes())
        # A solid horizontal barrier must make the walk-only route fail.
        for x in range(20):
            data[24 * 20 + x] = 1
        p.write_bytes(data)
        report = self.result()
        self.assertIn('route34_gate_to_goldenrod_walk_path', report['errors'], report)

    def test_live_gate_carpet_must_not_be_sealed(self):
        for x in (13, 14):
            with self.subTest(x=x):
                self.mutate('engine/johto_south_geometry.asm',
                            b'    db JOHTO_ROUTE_34_LOCAL_ID, 13, 41',
                            f'    db JOHTO_ROUTE_34_LOCAL_ID, {x}, 37\n    db JOHTO_ROUTE_34_LOCAL_ID, 13, 41'.encode(),
                            'route34_registered_carpet_not_collision_blacklisted')

    def test_gate_carpet_down_direction_only(self):
        self.mutate('engine/johto_south_portals.asm',
                    b'cp PLAYER_DIR_DOWN\n    ret nz\n    ld a, [wYCoord]\n    cp 37',
                    b'cp PLAYER_DIR_LEFT\n    ret nz\n    ld a, [wYCoord]\n    cp 37',
                    'route34_carpet_warp_down_only')

    def test_city_street_blocked(self):
        p = self.root / 'maps/johto_pilot/GoldenrodCity.roles.bin'
        data = bytearray(p.read_bytes())
        for x in range(40):
            data[30 * 40 + x] = 1
        p.write_bytes(data)
        report = self.result()
        self.assertIn('goldenrod_entry_to_city_street', report['errors'], report)


if __name__ == '__main__':
    unittest.main()
