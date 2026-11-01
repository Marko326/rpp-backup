"""FIX-302: execute current ASM collision branches for inbound gate carpets."""
from __future__ import annotations
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gatehouse_behavior_audit import (
    _constants, _scan_horizontal_gate_moves, audit_active_gatehouse_carpet_walkability,
)

GOLD = Path(os.environ['JOHTO_GOLD_SOURCE']) if os.environ.get('JOHTO_GOLD_SOURCE') else None


class GateCarpet302(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.constants = _constants(ROOT)
        cls.west = (ROOT / 'engine/johto_south_geometry.asm').read_text()
        cls.east = (ROOT / 'data/johto_east_runtime_300.asm').read_text()

    @classmethod
    def scan(cls, *, west: bool, source: str | None = None):
        if west:
            code = (source or cls.west).split('JohtoWestCarpetSpatialStep::', 1)[1].split('JohtoParkEastGateMatureStep::', 1)[0]
            name, ident = 'Route38EcruteakGate', 23
        else:
            code = (source or cls.east).split('JohtoEastGateCarpetLaneStep300::', 1)[1].split('JohtoRoute42CutClearedAhead300:', 1)[0]
            name, ident = 'Route42EcruteakGate', 62
        roles = (ROOT / 'maps/johto_pilot' / f'{name}.roles.bin').read_bytes()
        return _scan_horizontal_gate_moves(
            code, stable_id=ident, roles=roles, constants=cls.constants, western=west)

    def test_both_horizontal_gatehouses_allow_all_on_map_steps(self):
        for west in (True, False):
            with self.subTest(west=west):
                count, errors = self.scan(west=west)
                self.assertGreaterEqual(count, 170)
                self.assertEqual([], errors)

    def test_missing_upper_floor_entry_is_caught_in_both_gates(self):
        for west in (True, False):
            with self.subTest(west=west):
                src = self.west if west else self.east
                needle = '    cp 3\n    jr z, .approachUpper' if west else '    cp 3\n    jr z, .vertical'
                self.assertIn(needle, src)
                broken = src.replace(needle, needle.replace('cp 3', 'cp 2'), 1)
                count, errors = self.scan(west=west, source=broken)
                self.assertGreater(count, 170)
                self.assertTrue(any('(0,3) DOWN' in x for x in errors), errors)
                self.assertTrue(any('(9,3) DOWN' in x for x in errors), errors)

    def test_missing_lower_floor_entry_is_caught_in_both_gates(self):
        for west in (True, False):
            with self.subTest(west=west):
                src = self.west if west else self.east
                needle = '    cp 6\n    jr z, .approachLower' if west else '    cp 6\n    jr z, .vertical'
                self.assertIn(needle, src)
                broken = src.replace(needle, needle.replace('cp 6', 'cp 7'), 1)
                _, errors = self.scan(west=west, source=broken)
                self.assertTrue(any('(0,6) UP' in x for x in errors), errors)
                self.assertTrue(any('(9,6) UP' in x for x in errors), errors)

    def test_missing_lateral_entry_is_caught(self):
        east = self.east.replace('    cp 8\n    jr nz, .no', '    cp 7\n    jr nz, .no', 1)
        self.assertNotEqual(east, self.east)
        _, errors = self.scan(west=False, source=east)
        self.assertTrue(any('(8,4) RIGHT' in x for x in errors), errors)
        west = self.west.replace('.gateLeft\n    ld a, [wXCoord]\n    cp 1',
                                 '.gateLeft\n    ld a, [wXCoord]\n    cp 2', 1)
        self.assertNotEqual(west, self.west)
        _, errors = self.scan(west=True, source=west)
        self.assertTrue(any('(1,4) LEFT' in x for x in errors), errors)

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE to original Gold tree')
    def test_full_active_gatehouse_audit_and_faults(self):
        result = audit_active_gatehouse_carpet_walkability(ROOT, GOLD)
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result['errors'])
        self.assertEqual((10, 32), (result['gatehouses_checked'], result['carpets_checked']))
        self.assertGreaterEqual(result['source_simulated_moves'][23], 170)
        self.assertGreaterEqual(result['source_simulated_moves'][62], 170)
        for rel, src, old, new in (
            ('engine/johto_south_geometry.asm', self.west,
             '    cp 3\n    jr z, .approachUpper', '    cp 2\n    jr z, .approachUpper'),
            ('data/johto_east_runtime_300.asm', self.east,
             '    cp 6\n    jr z, .vertical', '    cp 7\n    jr z, .vertical'),
        ):
            with self.subTest(rel=rel):
                self.assertIn(old, src)
                bad = audit_active_gatehouse_carpet_walkability(
                    ROOT, GOLD, text_overrides={rel: src.replace(old, new, 1)})
                self.assertEqual('FAIL', bad['status'])
                self.assertTrue(bad['errors'])


if __name__ == '__main__':
    unittest.main()
