"""Fail closed when ROM0 Surf dispatch grows or its banked result ABI regresses."""
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_rom0_space_preflight import inspect


class Rom0Budget262(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in ('home/overworld.asm', 'home.asm', 'main.asm',
                    'engine/johto_violet_field_skills.asm', 'macros/asm_macros.asm',
                    'patches/rppred.map'):
            dst = self.root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT/rel, dst)

    def mutate(self, rel, original, bad):
        path = self.root/rel
        text = path.read_text()
        self.assertIn(original, text)
        path.write_text(text.replace(original, bad, 1))
        report = inspect(self.root)
        self.assertEqual('FAIL', report['status'], report)
        return report

    def test_rom0_is_smaller_and_unbanked_collisions_remain(self):
        report = inspect(self.root)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report)
        self.assertEqual(23, report['metrics']['rom0_gateway_bytes'])
        self.assertGreaterEqual(report['metrics']['estimated_rom0_bytes_released'], 150)
        self.assertEqual(31, report['metrics']['previous_map_rom0_slack_bytes'])
        self.assertTrue(any('new rgblink' in message or 'rgblink' in message
                            for message in report['warnings']))

    def test_missing_rom0_shore_tile_reload_rejected(self):
        report = self.mutate('home/overworld.asm',
                             '\tld a, [wTileInFrontOfPlayer]\n\tld c, a\n\tjp .checkIfNextTileIsPassable',
                             '\tjp .checkIfNextTileIsPassable')
        self.assertIn('shore C register restore', str(report['issues']))

    def test_water_flag_inversion_rejected(self):
        report = self.mutate('home/overworld.asm',
                             '\tjp z, .noCollision\n\tjp .stopSurfing',
                             '\tjp nz, .noCollision\n\tjp .stopSurfing')
        self.assertIn('C/Z routing', str(report['issues']))

    def test_gold_floor_exception_must_remain(self):
        report = self.mutate('engine/johto_violet_field_skills.asm',
                             '\tjp c, .floorShore\n\tjp .shore',
                             '\tjp c, .shore\n\tjp .shore')
        self.assertIn('four-way flag contract', str(report['issues']))

    def test_union_cave_water_must_be_checked(self):
        report = self.mutate('engine/johto_violet_field_skills.asm',
                             '\tcall JohtoUnionCaveWaterAhead\n.waterOrShore',
                             '\tcall JohtoRuinsWaterAhead\n.waterOrShore')
        self.assertIn('UnionCave', str(report['issues']))

    def test_bank48_cannot_be_moved_to_unchecked_bank(self):
        report = self.mutate('main.asm',
                             'SECTION "Johto Violet Field Skills", ROMX, BANK[$48]',
                             'SECTION "Johto Violet Field Skills", ROMX, BANK[$03]')
        self.assertIn('Bank $48', str(report['issues']))

    def test_collision_table_must_not_be_moved_to_romx(self):
        report = self.mutate('home.asm',
                             'JohtoUnionCave_Coll:: INCBIN "gfx/tilesets/johto_union_cave.tilecoll"',
                             '; moved improperly to ROMX')
        self.assertIn('JohtoUnionCave_Coll', str(report['issues']))

    def test_bank_restore_must_preserve_flags(self):
        report = self.mutate('home.asm',
                             '.Return\n\tpop bc\n\tld a,b',
                             '.Return\n\tpop bc\n\tand a\n\tld a,b')
        self.assertIn('preserve C/Z', str(report['issues']))


if __name__ == '__main__':
    unittest.main()
