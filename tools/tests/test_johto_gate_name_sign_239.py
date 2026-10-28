"""Prevent regression of P6-GATE-005 neutral signs and native map identity."""
from pathlib import Path
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
        bad = SOURCE.replace('jr nz, .resolveLegacyLandmark',
                             'jr z, .resolveLegacyLandmark', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))

    def test_wrong_name_bank_is_rejected(self):
        bad = SOURCE.replace('jp z, .copyLocalName',
                             'jp nz, .copyLocalName', 1)
        self.assertNotEqual(bad, SOURCE)
        self.assertFalse(check_johto_gate_name_sign(bad))

    def test_gate_keeps_existing_warp_movement(self):
        movement = (ROOT / 'engine/overworld/npc_movement.asm').read_text()
        runtime = (ROOT / 'engine/johto_pilot_runtime.asm').read_text()
        self.assertIn('callab JohtoPilotGateArrivalStep', movement)
        self.assertIn('JohtoPilotGateArrivalStep::\n    ld e, 0\n    ret', runtime)
        self.assertIn('JohtoPilotGateCollisionExitAllowed::', runtime)

if __name__ == '__main__':
    unittest.main()
