"""Fast independent negative checks for shared Gold quadrant decoding."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gold_cells import decode_cells  # noqa: E402


class GoldQuadrantDecoder(unittest.TestCase):
    def setUp(self):
        self.layout = bytes([0])
        self.metatiles = bytes(128 * 16)
        self.labels = ('tilecoll FLOOR, WALL, TALL_GRASS, HOP_LEFT ; 00\n' +
                       'tilecoll WALL, WALL, WALL, WALL ; unused\n' * 127)

    def test_quadrant_and_grass_pixels(self):
        cells = decode_cells(self.layout, self.metatiles, self.labels, 1, 1)
        self.assertEqual([c['role'] for c in cells],
                         ['FLOOR', 'WALL', 'TALL_GRASS', 'HOP_LEFT'])
        self.assertEqual([c['x'] for c in cells], [0, 1, 0, 1])
        self.assertEqual(len(cells[2]['graphics']), 4)

    def test_missing_tilecoll_quadrant_fails(self):
        with self.assertRaises(ValueError):
            decode_cells(self.layout, self.metatiles,
                         self.labels.replace('FLOOR, WALL, TALL_GRASS, HOP_LEFT',
                                             'FLOOR, WALL, TALL_GRASS'), 1, 1)

    def test_out_of_range_block_fails(self):
        with self.assertRaises(ValueError):
            decode_cells(bytes([128]), self.metatiles, self.labels, 1, 1)

    def test_any_graphic_exceeding_slot_limit_fails(self):
        metatiles = bytearray(self.metatiles)
        metatiles[0] = 96  # a non-bottom graphic must not be silently ignored
        with self.assertRaises(ValueError):
            decode_cells(self.layout, bytes(metatiles), self.labels, 1, 1)


if __name__ == '__main__':
    unittest.main()
