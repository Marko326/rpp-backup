"""MAP-300 regression coverage for Ecruteak east gate -> Route42 -> Mahogany."""
from pathlib import Path
import os
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_east_runtime_gate_300 import audit, fault_tests

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
REFERENCE_ROOT = (os.environ.get('JOHTO_RPP_EAST_STAGE77_SOURCE')
                  or os.environ.get('JOHTO_RPP_REFERENCE_SOURCE')
                  or os.environ.get('NPC_SOURCE_ROOT'))
REFERENCE = Path(REFERENCE_ROOT) if REFERENCE_ROOT else None


@unittest.skipIf(GOLD is None or REFERENCE is None,
                 'Gold and stage-77 NPC reference roots required for MAP-300 identity checks')
class EastRuntime300(unittest.TestCase):
    def test_current_east_candidate_and_fault_injections_pass(self):
        report = audit(ROOT, GOLD, REFERENCE)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])
        self.assertGreaterEqual(len(report['checks']), 83)
        self.assertEqual({
            'seam_y8_open_rejected': True,
            'role_grid_drift_rejected': True,
            'missing_reciprocal_gate_warp_rejected': True,
            'east_gate_bike_allowance_required': True,
            'ecruteak_east_collision_exit_required': True,
            'ecruteak_both_portals_dispatch_required': True,
            'east_gate_right_carpet_approach_required': True,
            'east_gate_inbound_handler_required': True,
            'east_gate_profile_exact': True,
            'mahogany_preview_gold_byte_drift_rejected': True,
            'mahogany_preview_wrong_source_row_rejected': True,
            'mahogany_preview_wrong_copy_width_rejected': True,
        }, fault_tests(ROOT, GOLD, REFERENCE))
        self.assertFalse(report['rom_built'])
        self.assertFalse(report['device_verified'])


if __name__ == '__main__':
    unittest.main()
