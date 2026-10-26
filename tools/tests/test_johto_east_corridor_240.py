"""Fail-closed original Gold source preflight; IcePath remains unactivated."""
from copy import deepcopy
import json
import os
from pathlib import Path
import unittest

from johto_east_corridor_source_audit import audit, CONTRACT

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE') or os.environ.get('JOHTO_GOLD_ROOT') or '/missing/gold')


@unittest.skipUnless((GOLD / 'data/maps/attributes.asm').is_file(),
                     'Full pokegold-master required for source checks')
class EastCorridorPreflight240(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads(CONTRACT.read_text())
        cls.good = audit(ROOT, GOLD)

    def test_five_gold_sources_checked_ice_path_still_sealed(self):
        self.assertEqual(self.good['status'], 'PASS', self.good['errors'])
        self.assertEqual(self.good['maps_checked'], 5)
        self.assertEqual(self.good['directed_seams_checked'], 8)
        self.assertFalse(self.good['gameplay_ready'])
        self.assertEqual(self.good['scope'], 'OFFLINE_SOURCE_ONLY')
        self.assertEqual([m['stable_local_id'] for m in self.good['maps']],
                         [69, 71, 72, 73, 70])

    def test_route44_gold_cave_exit_has_exact_reciprocal_icepath_warp(self):
        maps = {m['name']: m for m in self.source['maps']}
        self.assertEqual(maps['Route44']['warps'], [
            {'xy': [56, 7], 'target': 'ICE_PATH_1F', 'target_warp': 1}])
        self.assertEqual(maps['IcePath1F']['warps'][0],
                         {'xy': [4, 19], 'target': 'ROUTE_44', 'target_warp': 1})
        self.assertEqual(maps['BlackthornCity']['warp_count'], 8)

    def test_changing_gold_cave_destination_is_rejected(self):
        entries = deepcopy(self.source['maps'][0]['warps'])
        entries[0]['target'] = 'VERMILION_CITY'
        result = audit(ROOT, GOLD, event_override={'Route44': entries})
        self.assertIn('Route44:gold_warp_topology', result['errors'])

    def test_wrong_source_seam_offset_is_rejected(self):
        seam = deepcopy(self.source)
        edge = next(x for x in seam['direct_seams']
                    if x['from'] == 'Route44' and x['to'] == 'BlackthornCity')
        edge['gold_offset_blocks'] = -8
        result = audit(ROOT, GOLD, contract=seam)
        self.assertIn('Route44:BlackthornCity:source_seam', result['errors'])
        self.assertIn('Route44:BlackthornCity:missing_reciprocal_manifest',
                      result['errors'])

    def test_runtime_tileset_visual_drift_is_rejected(self):
        original = bytearray((ROOT / 'gfx/blocksets/johto.bst').read_bytes())
        used = sorted(set((GOLD / 'maps/Route44.blk').read_bytes()))
        original[used[0] * 16] ^= 0xff
        result = audit(ROOT, GOLD, runtime_tileset=bytes(original))
        self.assertIn('Route44:used_metatile_graphics', ' '.join(result['errors']))

    def test_mutated_layout_fingerprint_is_rejected(self):
        contract = deepcopy(self.source)
        contract['maps'][0]['sha256'] = '0' * 64
        result = audit(ROOT, GOLD, contract=contract)
        self.assertIn('Route44:layout_sha256', result['errors'])

    def test_corrupted_staged_collision_mask_is_rejected(self):
        contract = deepcopy(self.source)
        contract['maps'][0]['staged_assets']['mask_sha256'] = 'f' * 64
        result = audit(ROOT, GOLD, contract=contract)
        self.assertIn('Route44:staged_mask_drift', result['errors'])

    def test_corrupted_staged_layout_source_is_rejected(self):
        contract = deepcopy(self.source)
        contract['maps'][0]['staged_assets']['layout'] = 'README.md'
        result = audit(ROOT, GOLD, contract=contract)
        self.assertIn('Route44:staged_layout_drift', result['errors'])

    def test_no_fake_runtime_approval_is_possible(self):
        contract = deepcopy(self.source)
        contract['purpose'] = 'RUNTIME_APPROVED'
        result = audit(ROOT, GOLD, contract=contract)
        self.assertIn('unsafe_runtime_approval', result['errors'])

    def test_formal_version_is_numeric_without_test_suffix(self):
        self.assertEqual(self.good['version'], 'NPC-5.62.243')
        self.assertIn('NPC-5.62.243@', (ROOT / 'data/game_version.asm').read_text())
        self.assertNotIn('239A@', (ROOT / 'data/game_version.asm').read_text())


if __name__ == '__main__':
    unittest.main()
