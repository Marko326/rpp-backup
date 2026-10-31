"""ALPH-SOUTH-002 static acceptance: opened south carpet corridor, sealed north."""
from pathlib import Path
import os
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_coverage_audit import read_active_maps
from johto_pilot_migration_audit import audit_project as migration_audit
from johto_ruins_stage_audit import audit as resource_audit
from johto_warp_arrival_audit import audit as warp_audit

GOLD = Path(os.environ.get('GOLD_SOURCE_ROOT','/mnt/data/RUINS_GOLD_REF/REFERENCES/Gold/pokegold-master'))

class AlphSouthRuntime254(unittest.TestCase):
    def test_south_slots_preserved_when_north_activated(self):
        records = read_active_maps(ROOT)
        self.assertEqual(28, len(records))
        self.assertEqual([(9,102,'Route32RuinsOfAlphGate'),(10,20,'RuinsOfAlphOutside')],
                         [(r['slot'],r['stable_id'],r['map']) for r in records[9:11]])
        self.assertEqual([(11,19,'Route36RuinsOfAlphGate'),(12,16,'Route36')], [(r['slot'],r['stable_id'],r['map']) for r in records[11:13]])
        self.assertEqual((13,8,'UnionCave1F'), (records[13]['slot'],records[13]['stable_id'],records[13]['map']))
        self.assertEqual((14,9,'Route33'), (records[14]['slot'],records[14]['stable_id'],records[14]['map']))
        self.assertTrue({10,11,12,13,14,15}.issubset({r['stable_id'] for r in records}))

    def test_gold_stage_and_runtime_layouts(self):
        self.assertEqual([], resource_audit(ROOT,GOLD if GOLD.is_dir() else None))
        for name in ('RuinsOfAlphOutside','Route32RuinsOfAlphGate'):
            self.assertEqual((ROOT/f'maps/johto_staged/{name}.candidate.blk').read_bytes(),
                             (ROOT/f'maps/johto_pilot/{name}.runtime.blk').read_bytes())

    def test_same_bank_scripts_and_warp_object_counts(self):
        src=(ROOT/'data/johto_ruins_south_runtime.asm').read_text()
        self.assertIn('dw JohtoPilotAlphSouthGateMapScript',src)
        self.assertIn('JohtoPilotAlphSouthGateMapScript::',src)
        self.assertIn('dw JohtoPilotAlphOutsideMapScript',src)
        self.assertIn('JohtoPilotAlphOutsideMapScript::',src)
        self.assertIn('db 4\n    db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR',src)
        self.assertIn('South pair plus Gold north door #9',src)
        self.assertIn('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID', (ROOT/'engine/johto_pilot_runtime.asm').read_text())

    @unittest.skipUnless(GOLD.is_dir(),'Gold reference unavailable')
    def test_migration_table_and_gold_contract(self):
        result=migration_audit(ROOT,GOLD)
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result['errors'])

    @unittest.skipUnless(GOLD.is_dir(),'Gold reference unavailable')
    def test_warp_return_pair_and_old_gate_unchanged(self):
        result=warp_audit(ROOT,GOLD)
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result['errors'])

    def test_version_only_changed_on_runtime_activation(self):
        version=(ROOT/'data/game_version.asm').read_text()
        import re
        match = re.search(r'db \"[A-Z0-9]{3,5}-5\.62\.(\d+)@\"', version)
        self.assertIsNotNone(match, 'release label should use functional prefix')
        self.assertGreaterEqual(int(match.group(1)), 254)
        self.assertIn('TEST-231@',version)
        main=(ROOT/'main.asm').read_text()
        self.assertIn('SECTION "Johto Ruins South Runtime", ROMX, BANK[$49]', main)

if __name__=='__main__': unittest.main()
