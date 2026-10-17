"""Generic Gold graphics/collision table size regression; no ROM build.

Gold can intentionally define collisions for IDs beyond the image metatile
count. Review only source-covered block IDs, but fail closed on truncation.
"""
from pathlib import Path
import os
import sys
import tempfile
import unittest
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
from johto_indoor_common import ConversionError
from johto_indoor_tiles_converter import stage_preserved_gold_tileset
from johto_indoor_collision_adapter import plan_gold_quadrant_collision
from johto_rpp_asset_audit import collision_labels, gold_resource_aliases

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(TOOLS.parent / 'pokegold-master')))


@unittest.skipUnless((GOLD / 'maps/IlexForest.blk').is_file(), 'full Gold source required')
class GoldSurplusCollisionEntries(unittest.TestCase):
    def test_extra_gold_collision_entries_do_not_block_candidate(self):
        labels, _ = collision_labels(GOLD, 'forest', gold_resource_aliases(GOLD))
        self.assertEqual(len(labels), 64)  # Original Gold sources, not RPP-derived expectations
        with tempfile.TemporaryDirectory() as temp:
            summary = stage_preserved_gold_tileset(GOLD, Path(temp), 'IlexForest', 'forest')
            self.assertEqual((summary['width'], summary['height']), (15, 27))
            self.assertEqual(summary['used_graphic_count'], 59)
            self.assertTrue(summary['candidate_only'])
            self.assertFalse(summary['engine_implementation'])
        report, mask = plan_gold_quadrant_collision(GOLD, 'IlexForest', 'forest')
        self.assertEqual((report['width_cells'], report['height_cells']), (30, 54))
        self.assertEqual(len(mask), 216)
        self.assertEqual(report['blocked_count'] + report['walkable_count'], 1620)
        self.assertFalse(report['runtime_ready'])

    def test_missing_collision_for_a_graphical_block_is_rejected(self):
        original, src = collision_labels(GOLD, 'forest', gold_resource_aliases(GOLD))
        self.assertEqual(len(original), 64)
        # Gold Forest has 40 actual graphic metatiles. 39 collision records is
        # insufficient even when some of the remaining IDs are not in the map.
        with patch('johto_rpp_asset_audit.collision_labels', return_value=(original[:39], src)):
            with tempfile.TemporaryDirectory() as temp:
                with self.assertRaises(ConversionError):
                    stage_preserved_gold_tileset(GOLD, Path(temp), 'IlexForest', 'forest')
            with self.assertRaises(ConversionError):
                plan_gold_quadrant_collision(GOLD, 'IlexForest', 'forest')

    def test_surplus_unreferenced_collision_entries_do_not_change_geometry(self):
        original, src = collision_labels(GOLD, 'forest', gold_resource_aliases(GOLD))
        baseline, mask = plan_gold_quadrant_collision(GOLD, 'IlexForest', 'forest')
        # Only collision slots after the 40 graphical metatiles can differ;
        # they are not a reason to reject or silently open map cells.
        with patch('johto_rpp_asset_audit.collision_labels', return_value=(original[:40] + ['WALL,WALL,WALL,WALL']*24, src)):
            modified, mutated_mask = plan_gold_quadrant_collision(GOLD, 'IlexForest', 'forest')
        self.assertEqual(mutated_mask, mask)
        self.assertEqual(modified['collision_roles'], baseline['collision_roles'])


if __name__ == '__main__':
    unittest.main()
