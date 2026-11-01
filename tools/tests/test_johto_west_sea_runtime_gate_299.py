"""MAP-299 regression coverage for Route40 -> Route41 -> Cianwood outdoors."""
from pathlib import Path
import os
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_west_sea_runtime_gate_299 import audit

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
REFERENCE = Path(os.environ['JOHTO_RPP_REFERENCE_SOURCE']) if os.environ.get('JOHTO_RPP_REFERENCE_SOURCE') else None


@unittest.skipIf(GOLD is None or REFERENCE is None,
                 'Gold and mature NPC reference roots required for MAP-299 identity checks')
class WestSea299(unittest.TestCase):
    def test_current_west_sea_candidate_and_fault_injections_pass(self):
        report = audit(ROOT, GOLD, REFERENCE, run_fault_tests=True)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])
        self.assertGreaterEqual(len(report['checks']), 64)
        self.assertEqual({
            'fault_rejects_missing_unsafe_surf_edge': True,
            'fault_rejects_role_grid_drift': True,
            'fault_rejects_missing_reciprocal_connection': True,
        }, report['negative_fault_tests'])
        self.assertFalse(report['rom_built'])
        self.assertFalse(report['phone_verified'])


if __name__ == '__main__':
    unittest.main()
