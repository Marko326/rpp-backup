"""R32-5.62.165 P1-C: inspect real map records and safe return gates."""
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rpp_connection_guard import audit


class Route32ConnectionTests(unittest.TestCase):
    def test_south_violet_route32_bounded_strip(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for original connection truth')
        result = audit(ROOT, GOLD, 'JohtoVioletCity', 'JohtoRoute32', 'VioletCity', 'Route32', 'south')
        self.assertEqual(result['status'], 'PASS', result)
        self.assertEqual(result['actual']['width'], 10)
        self.assertEqual(result['actual']['source_start'], 0)
        self.assertEqual(result['actual']['dest_start'], 549)
        self.assertEqual(result['actual']['arrive_y'], 0)

    def test_north_route32_violet_bounded_strip(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for original connection truth')
        result = audit(ROOT, GOLD, 'JohtoRoute32', 'JohtoVioletCity', 'Route32', 'VioletCity', 'north')
        self.assertEqual(result['status'], 'PASS', result)
        self.assertEqual(result['actual']['width'], 10)
        self.assertEqual(result['actual']['source_start'], 300)
        self.assertEqual(result['actual']['dest_start'], 3)
        self.assertEqual(result['actual']['arrive_y'], 35)

    def test_exact_two_tile_gates_leave_other_boundaries_blocked(self):
        source = (ROOT / 'main.asm').read_text(encoding='utf8')
        city = source.split('JohtoVioletCityCollisionFence::', 1)[1].split('SECTION "Johto Route 32 Edge Guard"', 1)[0]
        route = source.split('JohtoRoute32CollisionFence::', 1)[1].split('SECTION "Johto Route 29 Display Name"', 1)[0]
        self.assertIn('.south\n\tld a, [wYCoord]\n\tcp JOHTO_VIOLET_CITY_HEIGHT * 2 - 1', city)
        self.assertIn('.north\n\tld a, [wYCoord]\n\tand a\n\tjr nz, .allowed', route)
        for guard in (city, route):
            self.assertIn('\tcp 14\n\tjr c, .blocked\n\tcp 16\n\tjr nc, .blocked', guard)
            self.assertIn('.west\n\tld a, [wXCoord]\n\tand a\n\tjr z, .blocked', guard)
        self.assertIn('cp JOHTO_ROUTE_32_HEIGHT * 2 - 1', route)
        self.assertIn('cp JOHTO_VIOLET_CITY_WIDTH * 2 - 1', city)

    def test_gates_respect_saved_route31_visual_gate_and_route33_still_closed(self):
        violet = (ROOT / 'data/mapHeaders/JohtoVioletCity.asm').read_text(encoding='utf8')
        route32 = (ROOT / 'data/mapHeaders/JohtoRoute32.asm').read_text(encoding='utf8')
        objects = (ROOT / 'data/mapObjects/JohtoRoute32.asm').read_text(encoding='utf8')
        self.assertIn('db SOUTH | EAST', violet)
        self.assertIn('db JOHTO_ROUTE_31', violet)
        self.assertIn('db NORTH', route32)
        self.assertNotIn('JOHTO_ROUTE_33', route32)
        self.assertIn('db $01 ; the original cave-mouth Warp only', objects)


if __name__ == '__main__':
    unittest.main()
