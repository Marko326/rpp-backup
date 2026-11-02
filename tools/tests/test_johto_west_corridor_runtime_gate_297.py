"""MAP-297 negative mutations for the new west corridor acceptance gate."""
import re
import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_west_corridor_runtime_gate_297 import audit

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None


class WestCorridor297(unittest.TestCase):
    def test_current_corridor_passes(self):
        r = audit(ROOT, GOLD)
        self.assertEqual('PASS_STATIC_ONLY', r['status'], r['errors'])
        self.assertGreaterEqual(len(r['checks']), 30)
        self.assertFalse(r['rom_built'])
        self.assertFalse(r['phone_verified'])

    def mutate_text(self, rel, old, new, expected):
        s = (ROOT/rel).read_text(encoding='utf8')
        self.assertIn(old, s)
        r = audit(ROOT, GOLD, text_overrides={rel: s.replace(old, new, 1)})
        self.assertEqual('FAIL', r['status'], r)
        self.assertTrue(any(expected in e for e in r['errors']), r['errors'])

    def test_missing_route39_olivine_seam_fails(self):
        self.mutate_text('data/johto_pilot_source_resources.asm',
            '    db MAP_REGION_JOHTO, JOHTO_ROUTE_39_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID\n',
            '', 'six_bidirectional_source_seams')

    def test_olivine_building_warp_cannot_be_enabled_silently(self):
        self.mutate_text('data/johto_west_runtime_297.asm',
            '    db 0 ; all 11 Gold building/port Warps remain sealed',
            '    db 1 ; incorrectly enabled an unreviewed building warp',
            'olivine_interiors_sealed')

    def test_olivine_surf_dispatch_is_required(self):
        self.mutate_text('engine/johto_violet_field_skills.asm',
            '    cp JOHTO_OLIVINE_CITY_LOCAL_ID\n    jp z, .westSea',
            '    cp JOHTO_OLIVINE_CITY_LOCAL_ID\n    jp z, .legacy',
            'olivine_spatial_surf')

    def test_release_version_cannot_drift(self):
        self.mutate_text('data/game_version.asm', re.search(r'REF-\d+@', (ROOT/'data/game_version.asm').read_text()).group(0), 'MAP-5.62.297@',
                         'release_and_active_count')


if __name__ == '__main__':
    unittest.main()
