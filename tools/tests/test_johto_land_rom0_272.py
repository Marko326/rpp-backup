"""Regression tests for fixed-bank south land gateway (static only)."""
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_land_rom0_preflight_272 import inspect, byte_length

class LandRom0Gateway272(unittest.TestCase):
    def test_gateway_size_and_bank_contract(self):
        result=inspect(ROOT)
        self.assertEqual(result['status'],'PASS_STATIC_ONLY',result['errors'])
        self.assertGreaterEqual(result['metrics']['source_bytes_released'],80)
    def test_old_source_pattern_fails(self):
        # Fixture-free negative: the exact old pattern is prohibited in ROM0.
        text=(ROOT/'home/overworld.asm').read_text()
        self.assertNotIn('callab JohtoSouthSpatialStep',text)
        self.assertNotIn('callab JohtoRoute33StepPolicy',text)
    def test_instruction_sizer_fails_closed(self):
        with self.assertRaises(ValueError):byte_length('unknown instruction')
    def test_actual_return_codes(self):
        text=(ROOT/'engine/johto_land_collision_gateway_272.asm').read_text()
        self.assertIn('ld e, 2',text)
        self.assertIn('ld e, 0',text)
        self.assertIn('callab JohtoSouthSpatialStep',text)
        self.assertIn('callab JohtoRoute33StepPolicy',text)
if __name__=='__main__': unittest.main()
