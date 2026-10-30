"""Gold-backed staging guard: no premature Ruins/Route36 activation."""
import json
from pathlib import Path
import unittest
from tools.johto_ruins_stage_audit import audit, validate_asset_hashes, ROOT, CONTRACT


class RuinsStageTests(unittest.TestCase):
    def test_offline_contract_and_hashes(self):
        issues = audit(ROOT)
        self.assertFalse(issues, issues)

    def test_gold_warp_targets_if_reference_available(self):
        import os
        gold = os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('GOLD_SOURCE_ROOT')
        if gold and Path(gold).is_dir():
            self.assertFalse(audit(ROOT, gold), 'Gold original warp directions changed')

    def test_negative_hash_guard(self):
        contract = json.loads((ROOT / CONTRACT).read_text())
        bad = json.loads(json.dumps(contract))
        bad['assets']['RuinsOfAlphOutside']['gold_sha256'] = '0'*64
        self.assertTrue(any('changed' in msg for msg in validate_asset_hashes(ROOT,bad)))

    def test_north_gate_is_not_prematurely_activated(self):
        contract = json.loads((ROOT / CONTRACT).read_text())
        self.assertFalse(contract['runtime_approved'])
        self.assertEqual(contract['active_map_count_must_remain'],11)
        self.assertNotIn('candidate_file', contract['assets']['Route36RuinsOfAlphGate'])
        self.assertNotIn('candidate_file', contract['assets']['Route36'])


if __name__ == '__main__':
    unittest.main()
