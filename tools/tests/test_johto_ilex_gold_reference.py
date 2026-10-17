"""Gold-only proof of Azalea -> gate -> Ilex Forest source topology.

Never infers that these destinations are currently registered in RPP.
"""
import os
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
from johto_indoor_common import gold_warps
from johto_indoor_tiles_converter import build_mapping

RPP = TOOLS.parent
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(RPP / 'pokegold-master')))


@unittest.skipUnless((GOLD / 'maps/IlexForest.asm').is_file(), 'complete Gold source required')
class GoldIlexEntryReferences(unittest.TestCase):
    def test_gold_azalea_gate_and_forest_have_bidirectional_pairs(self):
        town = gold_warps(GOLD, 'AzaleaTown')
        gate = gold_warps(GOLD, 'IlexForestAzaleaGate')
        forest = gold_warps(GOLD, 'IlexForest')
        self.assertEqual((len(town), len(gate), len(forest)), (8, 4, 3))
        expected = [
            (town[6], (2, 10, 'ILEX_FOREST_AZALEA_GATE', 3)),
            (town[7], (2, 11, 'ILEX_FOREST_AZALEA_GATE', 4)),
            (gate[2], (9, 4, 'AZALEA_TOWN', 7)),
            (gate[3], (9, 5, 'AZALEA_TOWN', 8)),
            (gate[0], (0, 4, 'ILEX_FOREST', 2)),
            (gate[1], (0, 5, 'ILEX_FOREST', 3)),
            (forest[1], (3, 42, 'ILEX_FOREST_AZALEA_GATE', 1)),
            (forest[2], (3, 43, 'ILEX_FOREST_AZALEA_GATE', 2)),
        ]
        for record, (x, y, dst, slot) in expected:
            with self.subTest(record=record):
                self.assertEqual((record['x'], record['y'], record['dest_map'], record['dest_id']),
                                 (x, y, dst, slot))
        # Northern gate is not implemented; it may not be treated as a safe exit.
        self.assertEqual((forest[0]['x'], forest[0]['y'], forest[0]['dest_map']),
                         (1, 5, 'ROUTE_34_ILEX_FOREST_GATE'))

    def test_gold_gate_exact_art_reuses_existing_johto_gate_candidate(self):
        plan, candidate = build_mapping(RPP, GOLD, 'IlexForestAzaleaGate',
                                        'gate', 'johto_gate')
        self.assertEqual(plan['status'], 'PIXEL_CANDIDATE_ONLY')
        self.assertEqual((plan['used_unique_blocks'], plan['exact_mapped']), (13, 13))
        self.assertEqual(candidate, (RPP / 'maps/JohtoRoute31VioletGate.blk').read_bytes())
        # Candidate is NOT evidence of active Warp, collision or destination.
        self.assertTrue(plan['can_stage_pixel_exact_candidate'])


if __name__ == '__main__':
    unittest.main()
