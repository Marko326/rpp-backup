"""REF346 test: gold-safe inactive runtime resources and 5 arrival-only warps."""
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from burned_tower_legacy_fixture import restore_closed_stage

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import johto_burned_tower_runtime_346 as mod

GOLD = Path(os.environ['RPP_GOLD_ROOT']) if os.environ.get('RPP_GOLD_ROOT') else None
ROOT = mod.ROOT


class RuntimeCandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD or not (GOLD / 'maps/BurnedTower1F.blk').exists():
            raise unittest.SkipTest('set RPP_GOLD_ROOT to reference Gold directory')

    def setUp(self):
        t = tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root = Path(t.name)
        core = ['docs/REF345_BURNED_TOWER_GOLD_CONTRACT.json',
                'constants/region_map_constants.asm',
                'data/johto_stable_id_slots.asm',
                'engine/johto_pilot_runtime.asm',
                'data/game_version.asm', 'main.asm']
        for name, art in zip(mod.FLOORS, mod.STAGING):
            core += [f'maps/johto_pilot/{name}.gold_roles.bin',
                     f'maps/johto_pilot/{name}.gold.blk',
                     f'maps/johto_pilot/{name}.runtime.blk',
                     f'gfx/blocksets/{art}.bst',
                     f'gfx/tilesets/{art}.png',
                     f'color/tilesets/{art}.gold_palette.asm']
        core += [str(mod.PLAN), str(mod.CANDIDATE), str(mod.ROUTES)]
        core += [f'color/tilesets/{art}.asm' for art in mod.STAGING]
        for filename in core:
            target = self.root / filename
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / filename, target)
        restore_closed_stage(self.root)

    def test_frozen_gold_and_candidate(self):
        self.assertEqual([], mod.verify(self.root, GOLD))

    def test_pit_to_five_distinct_safe_landings(self):
        plan = mod.build_plan(self.root)
        self.assertEqual(11, len(plan['pit_to_arrival']))
        self.assertEqual([0, 1, 2, 3, 4], sorted({p['target_ordinal'] for p in plan['pit_to_arrival']}))
        self.assertEqual(16, sum(w['trigger'] != 'ARRIVAL_ONLY_OR_SPECIAL_REVIEW' for w in plan['warp_candidate_records']) + 1)
        basement = plan['floor_resources'][1]
        self.assertEqual(29, sum(n for name, n in basement['role_counts'].items() if name.startswith('HOP')))
        self.assertEqual({'BROWN', 'GRAY'}, set(basement['used_palette_families']))

    def test_reject_double_registration_of_arrival(self):
        file = self.root / 'docs/REF345_BURNED_TOWER_GOLD_CONTRACT.json'
        data = json.loads(file.read_text())
        data['maps'][1]['warp_events'][0]['trigger'] = 'STEP_IN_IMMEDIATE'
        file.write_text(json.dumps(data))
        self.assertTrue(any('arrival-only' in e for e in mod.verify(self.root)))

    def test_reject_pit_target_pointing_at_ladder(self):
        file = self.root / 'docs/REF345_BURNED_TOWER_GOLD_CONTRACT.json'
        data = json.loads(file.read_text())
        data['maps'][0]['warp_events'][2]['destination_warp'] = 6
        file.write_text(json.dumps(data))
        self.assertTrue(any('PIT would land' in e for e in mod.verify(self.root)))

    def test_reject_wrong_palette_family(self):
        file = self.root / 'color/tilesets/johto_burned_tower_b1f.gold_palette.asm'
        source = file.read_text()
        file.write_text(source.replace('BROWN', 'WATER', 1))
        self.assertTrue(any('Gold meta/palettes changed' in e for e in mod.verify(self.root)))

    def test_reject_candidate_assembly_drift(self):
        file = self.root / mod.CANDIDATE
        file.write_text(file.read_text().replace('db 6 ; preserve all Gold ordinals', 'db 1 ; preserve all Gold ordinals'))
        self.assertTrue(any('candidate differs' in e for e in mod.verify(self.root)))

    def test_reject_premature_linking(self):
        file = self.root / 'main.asm'
        file.write_text(file.read_text() + '\nINCLUDE "data/johto_burned_tower/REF346_runtime_candidate.asm"\n')
        self.assertTrue(any('accidentally linked' in e for e in mod.verify(self.root)))

    def test_reject_premature_registration(self):
        file = self.root / 'constants/region_map_constants.asm'
        file.write_text(file.read_text().replace('NUM_JOHTO_ACTIVE_MAPS EQU 61', 'NUM_JOHTO_ACTIVE_MAPS EQU 63'))
        self.assertTrue(any('fail-closed registry' in e for e in mod.verify(self.root)))


if __name__ == '__main__':
    unittest.main()
