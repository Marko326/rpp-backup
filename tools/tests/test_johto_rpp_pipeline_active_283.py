"""Catch old 6-map pipeline review table and unintended pre-activation."""
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_rpp_pipeline import current_rpp_active_map_contract,review_rpp_integration


class ActiveMapReviewerTests(unittest.TestCase):
    def test_current_23_maps_have_real_descriptor_and_stable_slot(self):
        registered=current_rpp_active_map_contract(ROOT)
        self.assertEqual(28,len(registered))
        self.assertEqual(('GoldenrodCity',15), registered['JohtoSouthGoldenrodCityRuntimeHeader'])
        self.assertEqual(('Route34',14), registered['JohtoSouthRoute34RuntimeHeader'])
        self.assertEqual(('Route36',16), registered['JohtoPilotRoute36RuntimeHeader'])
        self.assertEqual(('Route35',17), registered['JohtoNorthRoute35RuntimeHeader'])
        self.assertEqual(('Route35GoldenrodGate',18), registered['JohtoNorthRoute35GoldenrodGateRuntimeHeader'])

    def test_pipeline_reviews_current_south_and_north_maps(self):
        for header,name in [('JohtoSouthGoldenrodCityRuntimeHeader','GoldenrodCity'),
                            ('JohtoSouthRoute34RuntimeHeader','Route34'),
                            ('JohtoPilotRoute36RuntimeHeader','Route36'),
                            ('JohtoNorthRoute35RuntimeHeader','Route35'),
                            ('JohtoNorthRoute35GoldenrodGateRuntimeHeader','Route35GoldenrodGate')]:
            with self.subTest(header=header):
                result=review_rpp_integration(ROOT,header,{'map':name})
                self.assertEqual('STATIC_STRUCTURE_PRESENT_REVIEW_RUNTIME',result['status'],result)
                self.assertTrue(result['registered_active_map'])
                self.assertFalse(result['runtime_approved'])

    def test_unregistered_fake_route35_headers_are_rejected(self):
        for header,name in [('JohtoSouthRoute35RuntimeHeader','Route35'),
                            ('JohtoSouthRoute35GoldenrodGateRuntimeHeader','Route35GoldenrodGate')]:
            with self.subTest(header=header):
                report=review_rpp_integration(ROOT,header,{'map':name})
                self.assertEqual('STRUCTURAL_ERRORS',report['status'])
                self.assertFalse(report['registered_active_map'])

    def test_reviewer_must_reject_corrupt_descriptor_or_slot(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            for p in ('data/johto_header_descriptors.asm','constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm',
                      'data/johto_stable_id_slots.asm'):
                (root/p).parent.mkdir(parents=True,exist_ok=True)
                shutil.copy(ROOT/p,root/p)
            descriptors=root/'data/johto_header_descriptors.asm'
            original=descriptors.read_text()
            descriptors.write_text(original.replace('dw JohtoSouthGoldenrodCityRuntimeHeader',
                                                    'dw JohtoSouthRoute35RuntimeHeader',1))
            with self.assertRaisesRegex(ValueError,'header descriptors differ'):
                current_rpp_active_map_contract(root)
            descriptors.write_text(original)
            slots=root/'data/johto_stable_id_slots.asm'
            slots.write_text(slots.read_text().replace(', 20 ; $00-$0f',', 0 ; $00-$0f',1))
            with self.assertRaisesRegex(ValueError,'stable-ID slot mismatch'):
                current_rpp_active_map_contract(root)


if __name__=='__main__':
    unittest.main()
