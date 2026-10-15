"""Unit tests for dual-source preflight; live source audit needs --gold path."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('johto_gate_audit',ROOT/'tools/johto_gate_audit.py')
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class TestDualSource(unittest.TestCase):
    def test_requires_both_source_trees(self):
        with tempfile.TemporaryDirectory() as d:
            errors=m.preflight(d,d)
            self.assertTrue(any('RPP MISSING' in e for e in errors))
            self.assertTrue(any('GOLD MISSING' in e for e in errors))
    def test_one_missing_gold_is_blocker(self):
        with tempfile.TemporaryDirectory() as d:
            errors=m.preflight(ROOT,d)
            self.assertTrue(any('GOLD MISSING' in e for e in errors))
    def test_one_missing_rpp_is_blocker(self):
        with tempfile.TemporaryDirectory() as d:
            errors=m.preflight(d,d)
            self.assertTrue(any('RPP MISSING' in e for e in errors))
    def test_export_context_not_required_for_actual_repository(self):
        self.assertNotIn('RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt',m.RPP_REQUIRED)

    def test_gate_requires_walkable_tile_without_auto_warp(self):
        self.assertEqual((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes(),bytes([3,4,5,6,64,255]))
        src = (ROOT/'data/warp_tile_ids.asm').read_text()
        self.assertIn('db $06,$FF',src)
        self.assertNotIn('db $06,$40,$FF',src)

    def test_gold_expected_geometry(self):
        self.assertEqual(len(m.RPP_GATE_ART_ADAPTER),20)
        self.assertEqual(m.GOLD_GATE,[(0,4,'VIOLET_CITY',8),(0,5,'VIOLET_CITY',9),(9,4,'ROUTE_31',1),(9,5,'ROUTE_31',2)])
    def test_warp_mapping_symmetric(self):
        obj=m.RPP_EXPECTED
        self.assertEqual([r[2] for r in obj['JohtoRoute31.asm']],[2,3])
        self.assertEqual([r[2] for r in obj['JohtoVioletCity.asm']],[0,1])
        self.assertEqual([r[2] for r in obj['JohtoRoute31VioletGate.asm']],[0,1,0,1])

if __name__=='__main__': unittest.main()
