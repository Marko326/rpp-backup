"""DEV-317 Route43 Gold seam-preview regression tests; source-only."""
import os
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_route43_visual_preview_audit_317 import audit

ROOT = Path(__file__).resolve().parents[2]
GOLD = os.environ.get('GOLD_SOURCE_ROOT')

@unittest.skipUnless(GOLD, 'set GOLD_SOURCE_ROOT to the uploaded Gold reference checkout')
class TestRoute43VisualPreview317(unittest.TestCase):
    def test_gold_preview_contract(self):
        result = audit(ROOT, Path(GOLD))
        self.assertEqual(result['errors'], [])
        self.assertEqual(result['status'], 'PASS_STATIC_ONLY')

    def test_mutation_missing_south_preview_fails(self):
        filename = 'data/johto_route43_runtime_315.asm'
        raw = (ROOT / filename).read_text()
        self.assertIn('db NORTH | SOUTH', raw)
        result = audit(ROOT, Path(GOLD), {filename: raw.replace('db NORTH | SOUTH', 'db NORTH')})
        self.assertIn('Gold_NORTH_SOUTH_preview_flags', result['errors'])

    def test_mutation_wrong_south_source_fails(self):
        filename = 'data/johto_route43_runtime_315.asm'
        raw = (ROOT / filename).read_text()
        self.assertIn('dw JohtoMahoganyBlocks', raw)
        result = audit(ROOT, Path(GOLD), {filename: raw.replace('dw JohtoMahoganyBlocks', 'dw JohtoRoute43Blocks', 1)})
        self.assertIn('Gold_MahoganyTown_south_preview_source_exact_90B', result['errors'])

    def test_mutation_preview_asset_fails(self):
        filename = 'maps/johto_pilot/LakeOfRage.preview.blk'
        raw = bytearray((ROOT / filename).read_bytes())
        raw[0] ^= 1
        result = audit(ROOT, Path(GOLD), {filename: bytes(raw)})
        self.assertIn('Gold_LakeOfRage_preview_source_exact_360B', result['errors'])

    def test_mutation_open_physical_seam_fails(self):
        filename = 'data/johto_pilot_source_resources.asm'
        raw = (ROOT / filename).read_text()
        needle = 'JohtoPilotSourceConnections::\n'
        injected = raw.replace(needle, needle +
            '    db MAP_REGION_JOHTO, JOHTO_ROUTE_43_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_MAHOGANY_TOWN_LOCAL_ID\n', 1)
        result = audit(ROOT, Path(GOLD), {filename: injected})
        self.assertIn('only_Lake_physical_Route43_seam_registered', result['errors'])

if __name__ == '__main__':
    unittest.main()
