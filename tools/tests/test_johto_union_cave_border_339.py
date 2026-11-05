"""REF-339 cave border: Gold tile parity and fail-closed collision.

Runs static-only; no ROM linking or gameplay assertions.
"""
from pathlib import Path
from unittest.mock import patch
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_union_b2f_340_audit import check


class UnionCaveBorder339(unittest.TestCase):
    def test_project_has_gold_border_texture_and_collision(self):
        result = check(ROOT)
        self.assertEqual('PASS_STATIC_ONLY', result['status'], result['errors'])
        self.assertEqual(0, result['failed'])

    def test_old_black_border_block_is_detected(self):
        original = Path.read_bytes
        p = (ROOT/'gfx/blocksets/johto_union_cave.bst').resolve()
        def inject(path):
            data = original(path)
            if path.resolve() == p:
                data = bytearray(data)
                data[0x21*16:0x22*16] = bytes([31]*16)
                return bytes(data)
            return data
        with patch.object(Path, 'read_bytes', inject):
            result = check(ROOT)
        self.assertEqual('FAIL', result['status'])
        self.assertIn('border_21_matches_gold_09_solid_duplicate', result['errors'])

    def test_wrong_passability_or_border_slot_is_detected(self):
        original = Path.read_bytes
        p = (ROOT/'gfx/tilesets/johto_union_cave.tilecoll').resolve()
        def inject(path):
            data = original(path)
            if path.resolve() == p:
                return data[:-1] + bytes([5,255])
            return data
        with patch.object(Path, 'read_bytes', inject):
            result = check(ROOT)
        self.assertEqual('FAIL', result['status'])
        self.assertIn('border_21_matches_gold_09_solid_duplicate', result['errors'])


if __name__=='__main__':
    unittest.main()
