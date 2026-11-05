from pathlib import Path
import sys, unittest
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_dungeon_batch_preflight import _trigger, DUNGEON_GROUPS

class DungeonBatchPreflightUnitTests(unittest.TestCase):
    def test_trigger_classes_are_not_collapsed(self):
        self.assertEqual('STEP_IN_IMMEDIATE', _trigger('LADDER')['kind'])
        self.assertEqual({'kind':'DIRECTIONAL_COLLISION','direction':'DOWN'},
                         _trigger('WARP_CARPET_DOWN'))
        self.assertEqual('STEP_IN_IMMEDIATE', _trigger('PIT')['kind'])
        self.assertEqual('ARRIVAL_ONLY_OR_SPECIAL_REVIEW', _trigger('FLOOR')['kind'])

    def test_inventory_covers_major_johto_dungeon_families(self):
        self.assertEqual({'Union Cave','Slowpoke Well','Mount Mortar','Ice Path',
                          'Whirl Islands','Dark Cave','Dragons Den','Burned Tower'},
                         set(DUNGEON_GROUPS))
        self.assertGreaterEqual(sum(map(len, DUNGEON_GROUPS.values())), 28)

if __name__ == '__main__':
    unittest.main()
