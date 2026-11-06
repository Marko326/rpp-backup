"""CLEAN REF-349: current 164-warp contract still detects a dropped Route46 link.

Historical center audit check identifiers deliberately retain their old names; only
current global totals are updated, and their per-center route checks stay intact.
"""
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_azalea_center_334_audit import audit as azalea
from johto_violet_goldenrod_centers_335_audit import audit as violet_goldenrod
from johto_batch_centers_336_audit import audit as batch_centers
from johto_blackthorn_center_338_audit import audit as blackthorn

AUDITS=(
    (azalea,'registered_113_exact_bidirectional_center_routes'),
    (violet_goldenrod,'new_52_maps_and_119_warps'),
    (batch_centers,'exact_134_registered_warps'),
    (blackthorn,'one_source_three_distinct_routes_and_134_total'),
)
ROUTE46='    db MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\n'

class CurrentCenterCountContract(unittest.TestCase):
    def test_all_four_legacy_center_audits_accept_current_project(self):
        for audit, check in AUDITS:
            with self.subTest(check=check):
                result=audit(ROOT)
                self.assertEqual(result['status'],'PASS_STATIC_ONLY',result['errors'])

    def test_dropping_route46_warp_is_rejected_by_all_four(self):
        path='engine/johto_pilot_runtime.asm'
        source=(ROOT/path).read_text()
        self.assertEqual(source.count(ROUTE46),1)
        broken=source.replace(ROUTE46,'',1)
        for audit, check in AUDITS:
            with self.subTest(check=check):
                report=audit(ROOT,overrides={path:broken})
                self.assertIn(check, report['errors'])

if __name__ == '__main__':
    unittest.main()
