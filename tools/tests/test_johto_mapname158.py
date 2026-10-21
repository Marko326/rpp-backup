"""MAPSIGN-5.62.158: Gate must inherit the prior map-name landmark.

Source-only tests: the sign state machine itself is not emulator tested here.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Route31VioletTransitSign(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sign = (ROOT / 'engine/overworld/map_name_sign.asm').read_text()
        cls.maps = (ROOT / 'data/town_map_entries.asm').read_text()

    def test_gate_is_neutral_like_kanto_gates(self):
        neutral = self.sign.split('.NeutralMapList\n', 1)[1].split('\tdb $ff', 1)[0]
        self.assertIn('JOHTO_ROUTE31_VIOLET_GATE', neutral)
        self.assertEqual(len(re.findall(r'\bJOHTO_ROUTE31_VIOLET_GATE\b', neutral)), 1)
        self.assertIn('ROUTE_15_GATE_1F', neutral)
        self.assertIn('ROUTE_15_GATE_2F', neutral)
        self.assertNotIn('JOHTO_ROUTE_31', neutral)
        self.assertNotIn('JOHTO_VIOLET_CITY', neutral)

    def test_neutral_entries_do_not_replace_landmark_or_display_popup(self):
        branch = self.sign.split('\n.mapChanged\n', 1)[1].split('\n.resolveLandmark\n', 1)[0]
        self.assertIn('call .IsNeutralMap', branch)
        self.assertIn('jp nz, .cancel', branch)
        self.assertIn('jp .storeWithoutShowing', branch)

    def test_town_map_registration_is_unchanged(self):
        # This location still needs a real map ID for the engine and safe save/map lookup.
        self.assertRegex(self.maps, r'(?m)^\s*IMAP JOHTO_ROUTE31_VIOLET_GATE,\s*116,\s*94,\s*JohtoVioletName')
        self.assertRegex(self.maps, r'(?m)^\s*IMAP JOHTO_ROUTE_31,\s*116,\s*94,\s*JohtoRoute31TownMapName')
        self.assertRegex(self.maps, r'(?m)^\s*IMAP JOHTO_VIOLET_CITY,\s*116,\s*94,\s*JohtoVioletName')

    def test_legacy_gate_warp_and_fly_sources_unchanged(self):
        self.assertRegex((ROOT/'data/game_version.asm').read_text(), r'db "[A-Z]+-5\.62\.\d+[A-Z]?@"')
        self.assertIn('JOHTO_ROUTE31_VIOLET_GATE', (ROOT/'data/mapObjects/JohtoRoute31.asm').read_text())
        self.assertIn('JOHTO_ROUTE31_VIOLET_GATE', (ROOT/'data/mapObjects/JohtoVioletCity.asm').read_text())


if __name__ == '__main__':
    unittest.main()
