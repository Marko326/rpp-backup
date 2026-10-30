"""ROM0 budget refactor regression: real source paths, synthetic MAP gates.

No RGBDS or ROM builds.  The old MAP is intentionally treated as stale.
"""
from pathlib import Path
import sys
import tempfile
import unittest
import shutil

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rom0_space_preflight import inspect

SOURCE_FILES = (
    'home/overworld.asm', 'home.asm', 'main.asm',
    'engine/johto_violet_field_skills.asm', 'macros/asm_macros.asm',
)

class Rom0BudgetPreflight262(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in SOURCE_FILES:
            target = self.root / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, target)

    def edit(self, rel, old, new):
        p = self.root / rel
        s = p.read_text()
        self.assertEqual(1, s.count(old), f'fixture drift in {rel}: {old}')
        p.write_text(s.replace(old, new, 1))

    def write_map(self, label='CollisionCheckOnWater.johtoSurfNotWater', slack='0080'):
        p = self.root / 'patches/rppred.map'
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text('ROM0 bank #0:\n SECTION: $0150-$3eee ($3d9f bytes) ["Main"]\n'
                     f' $0f0c = {label}\n SLACK: ${slack} bytes\nROMX bank #1:\n')

    def test_source_only_passes_without_rom_link_claim(self):
        got = inspect(self.root)
        self.assertEqual('PASS_STATIC_ONLY', got['status'], got['issues'])
        self.assertEqual(23, got['metrics']['rom0_gateway_bytes'])
        self.assertTrue(any('user-side rgblink' in x for x in got['warnings']))

    def test_missing_banked_call_fails(self):
        self.edit('home/overworld.asm', 'callab JohtoOverworldSurfDecision', 'callab JohtoVioletWaterAhead')
        self.assertEqual('FAIL', inspect(self.root)['status'])

    def test_lost_shore_tile_restore_fails(self):
        self.edit('home/overworld.asm', '.johtoSurfNotWater\n\tjr nz, .legacySurfTile',
                  '.johtoSurfNotWater\n\tjr z, .legacySurfTile')
        self.assertEqual('FAIL', inspect(self.root)['status'])

    def test_wrong_banked_section_fails(self):
        self.edit('main.asm', 'SECTION "Johto Violet Field Skills", ROMX, BANK[$48]',
                  'SECTION "Johto Violet Field Skills", ROM0')
        self.assertEqual('FAIL', inspect(self.root)['status'])

    def test_unsafe_collision_pointer_relocation_fails(self):
        self.edit('home.asm', 'JohtoUnionCave_Coll:: INCBIN', 'MovedUnionCave_Coll:: INCBIN')
        self.assertEqual('FAIL', inspect(self.root)['status'])

    def test_old_map_must_not_be_accepted_as_new_build(self):
        self.write_map(label='CollisionCheckOnWater.checkNewBarkSurf', slack='001f')
        got = inspect(self.root)
        self.assertEqual('PASS_STATIC_ONLY', got['status'])
        self.assertFalse(got['metrics']['rom0_map_is_from_new_dispatcher'])
        self.assertEqual('FAIL', inspect(self.root, require_fresh_map=True)['status'])

    def test_fresh_map_capacity_policy(self):
        self.write_map(slack='003f')
        self.assertEqual('FAIL', inspect(self.root, require_fresh_map=True)['status'])
        self.write_map(slack='0080')
        self.assertEqual('PASS_STATIC_ONLY', inspect(self.root, require_fresh_map=True)['status'])

if __name__ == '__main__':
    unittest.main()
