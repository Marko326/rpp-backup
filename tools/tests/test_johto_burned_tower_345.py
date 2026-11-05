"""REF-345 negative tests; no ROM build, and no RPP project mutation."""
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from burned_tower_legacy_fixture import restore_closed_stage

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import johto_burned_tower_345 as stage

GOLD_ROOT = Path(os.environ['RPP_GOLD_ROOT']) if os.environ.get('RPP_GOLD_ROOT') else None


@unittest.skipUnless(GOLD_ROOT and GOLD_ROOT.is_dir(), 'set RPP_GOLD_ROOT to an extracted pokegold source')
class BurnedTowerStageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = stage.resolve_gold_root(GOLD_ROOT)
        cls.contract, cls.assets = stage._contract(cls.gold)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        paths = list(self.assets) + [str(stage.CONTRACT),
                 'constants/region_map_constants.asm', 'data/johto_stable_id_slots.asm',
                 'engine/johto_pilot_runtime.asm', 'data/game_version.asm']
        for rel in paths:
            out = self.root / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(stage.ROOT / rel, out)
        restore_closed_stage(self.root)

    def test_gold_reference_and_frozen_stage(self):
        self.assertEqual([], stage.verify(self.gold, self.root))
        self.assertEqual((14, 6), tuple(len(m['warp_events']) for m in self.contract['maps']))
        self.assertEqual([w['trigger'] for w in self.contract['maps'][1]['warp_events'][:5]],
                         ['ARRIVAL_ONLY_OR_SPECIAL_REVIEW'] * 5)

    def test_reject_collision_mutation(self):
        path = self.root / 'maps/johto_pilot/BurnedTower1F.gold_roles.bin'
        b = bytearray(path.read_bytes())
        b[0] ^= 1
        path.write_bytes(b)
        self.assertTrue(any('not byte-identical' in msg for msg in stage.verify(self.gold, self.root)))

    def test_reject_corrupted_pit_to_ladder_route(self):
        path = self.root / stage.CONTRACT
        contract = json.loads(path.read_text())
        contract['maps'][0]['warp_events'][2]['role'] = 'LADDER'
        path.write_text(json.dumps(contract))
        self.assertTrue(any('warp contract mismatch' in msg for msg in stage.verify(self.gold, self.root)))

    def test_reject_unproven_basement_return(self):
        path = self.root / stage.CONTRACT
        contract = json.loads(path.read_text())
        contract['maps'][1]['warp_events'][0]['trigger'] = 'STEP_IN_IMMEDIATE'
        path.write_text(json.dumps(contract))
        self.assertTrue(any('warp contract mismatch' in msg for msg in stage.verify(self.gold, self.root)))

    def test_reject_premature_activation(self):
        path = self.root / 'data/johto_stable_id_slots.asm'
        s = path.read_text()
        before = next(line for line in s.splitlines() if '; $b0-$bf' in line)
        after = before.replace('JOHTO_INVALID_ACTIVE_SLOT', '61', 2)
        path.write_text(s.replace(before, after))
        self.assertTrue(any('must remain inactive' in msg for msg in stage.verify(self.gold, self.root)))

    def test_reject_wrong_tower_art(self):
        p = self.root / 'gfx/tilesets/johto_burned_tower_1f.png'
        p.write_bytes(p.read_bytes() + b'bad')
        self.assertTrue(any('not byte-identical' in msg for msg in stage.verify(self.gold, self.root)))


if __name__ == '__main__':
    unittest.main()
