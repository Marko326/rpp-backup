"""Prevent regression of P6-GATE-005 neutral signs and native map identity."""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_pilot_migration_audit import check_johto_gate_name_sign

SOURCE = (ROOT / 'engine/overworld/map_name_sign.asm').read_text(encoding='utf-8')

class GateSignRegression(unittest.TestCase):
    def test_current_gate_neutral_with_johto_names(self):
        self.assertTrue(check_johto_gate_name_sign(SOURCE))

    def test_missing_gate_neutral_flag_is_rejected(self):
        bad = SOURCE.replace('cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID\n\tret z',
                             'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID\n\tret nz', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))

    def test_missing_region_guard_is_rejected(self):
        bad = SOURCE.replace('cp MAP_REGION_JOHTO\n\tjr nz, .legacyNeutralMap',
                             'cp MAP_REGION_KANTO\n\tjr nz, .legacyNeutralMap', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))

    def test_kanto_fc_fallback_is_rejected(self):
        bad = SOURCE.replace('jp nz, .resolveLegacyLandmark',
                             'jp z, .resolveLegacyLandmark', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))

    def test_unconditional_legacy_fallback_is_rejected(self):
        bad = SOURCE.replace('jp nz, .resolveLegacyLandmark',
                             'jp .resolveLegacyLandmark', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))

    def test_wrong_name_bank_is_rejected(self):
        bad = SOURCE.replace('jp z, .copyLocalName',
                             'jp nz, .copyLocalName', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))


    def test_route32_uses_its_own_landmark_name(self):
        match = re.search(r'(?ms)^\.ResolvePhysicalLandmark\s*$\n(.*?)(?=^\.ResolveKnownFloor\s*$)', SOURCE)
        self.assertIsNotNone(match)
        resolve = match.group(1)
        self.assertIn("cp JOHTO_ROUTE_32_LOCAL_ID\n\tjr z, .johtoRoute32", resolve)
        self.assertIn('.johtoRoute32\n\tld hl, .JohtoRoute32Name', resolve)
        self.assertIn('.JohtoRoute32Name:      db "Route 32@"', SOURCE)

    def test_route32_uses_route31_hop_pairs(self):
        ledges = (ROOT / 'engine/overworld/ledges.asm').read_text(encoding='utf-8')
        self.assertRegex(ledges, r'cp JOHTO_ROUTE_31_LOCAL_ID\s+jr z, \.route31PairTable\s+cp JOHTO_ROUTE_32_LOCAL_ID\s+jr z, \.route31PairTable')
        self.assertRegex(ledges, r'cp JOHTO_RUINS_OF_ALPH_LOCAL_ID\s+jr z, \.ruinsHopTable')
        self.assertIn('JohtoPilotRoute31LedgeTiles', ledges)
        self.assertIn('JohtoAlphSouthHops', ledges)

    def test_gate_keeps_existing_warp_movement(self):
        movement = (ROOT / 'engine/overworld/npc_movement.asm').read_text()
        runtime = (ROOT / 'engine/johto_pilot_runtime.asm').read_text()
        self.assertIn('callab JohtoPilotGateArrivalStep', movement)
        self.assertIn('JohtoPilotGateArrivalStep::', runtime)
        self.assertIn('ld e, 0\n    ld a, [wCurMap]',runtime)
        self.assertIn('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', runtime)
        self.assertIn('JohtoPilotGateCollisionExitAllowed::', runtime)

if __name__ == '__main__':
    unittest.main()
