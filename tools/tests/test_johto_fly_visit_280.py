"""FIX-280 negative controls for reserved Fly targets and valid visited landings."""
import os
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_fly_visit_audit_280 import audit


class FlyVisit280(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
        cls.rel = 'engine/johto_pilot_fly_map.asm'
        cls.fly = (ROOT/cls.rel).read_text(encoding='utf-8')

    def wrong(self, old, new, expected, file=None):
        file = file or self.rel
        source = self.fly if file==self.rel else (ROOT/file).read_text(encoding='utf-8')
        self.assertIn(old, source)
        changed = source.replace(old, new, 1)
        result = audit(ROOT, self.gold, {file: changed})
        self.assertEqual(result['status'], 'FAIL')
        self.assertIn(expected, '\n'.join(result['errors']))

    def test_real_source_is_consistent(self):
        report=audit(ROOT, self.gold)
        self.assertEqual(report['status'], 'PASS_STATIC_ONLY', report['errors'])
        if self.gold:
            self.assertEqual(len(report['checks']), 50)

    def test_reject_missing_active_check(self):
        self.wrong('callab GetJohtoActiveSlot', 'callab UnsafeFlyMapSelector',
                   'flight_requires_both_active_and_visited')

    def test_reject_missing_saved_unlock_check(self):
        self.wrong('and [hl]\n\tret', 'or [hl]\n\tret',
                   'flight_requires_both_active_and_visited')

    def test_reject_changed_landmark_event(self):
        self.wrong('EVENT_JOHTO_FLY_GOLDENROD / 8', 'EVENT_JOHTO_FLY_MAHOGANY / 8',
                   'eleven_fly_registry_rows')

    def test_reject_moved_teleport_to_wall(self):
        if not self.gold:
            self.skipTest('Gold source required to prove the target tile is a wall')
        self.wrong('FLYWARP_DATA 20, 28, 15', 'FLYWARP_DATA 20, 0, 0',
                   'gold_walkable_landing_GOLDENROD')

    def test_reject_bypassed_city_visit_hook(self):
        self.wrong('callab JohtoPilotRecordFlyVisit', 'callab InvalidFlyVisitHook',
                   'map_load_only_records_real_johto_towns', 'home/overworld.asm')

    def test_release_version_matches_project_headings(self):
        version=(ROOT/'data/game_version.asm').read_text(encoding='utf-8')
        self.assertRegex(version, r'(?m)^\s*db "TEST-231@"$')
        match=re.search(r'(?m)^\s*db "((?:FIX|MAP)-5\.62\.\d+)@"$',version)
        self.assertIsNotNone(match)
        for doc in ('README.md','FEATURES.md','TODO.md','PROJECT_DELIVERY_RULES.md','RPP_DEVELOPMENT_PITFALLS.md'):
            lines=(ROOT/doc).read_text(encoding='utf-8').splitlines()
            title=lines[0]
            phase_intro=(title.startswith('## TOOL-5.62.') or title.startswith('## CLEAN-5.62.')) and match.group(1) in '\n'.join(lines[:15])
            self.assertTrue(match.group(1) in title or title.startswith('## MAP-5.62.286') or phase_intro, doc)

if __name__ == '__main__':
    unittest.main()
