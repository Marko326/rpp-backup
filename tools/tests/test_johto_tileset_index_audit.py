"""All registered resource indexes: executable arithmetic and fail-closed mutations."""
from pathlib import Path
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from johto_tileset_index_audit import audit, ResourceIndexError


class TilesetIndexAudit(unittest.TestCase):
    def test_all_registered_ids_and_future_arithmetic_are_traced(self):
        report = audit(ROOT)
        self.assertEqual(report['registered_tilesets'], 36)
        self.assertEqual(report['registered_ids_verified'], 36)
        self.assertEqual(report['last_registered']['header_offset'], 35 * 12)
        self.assertEqual(report['last_registered']['palette_set_offset'], 35 * 8)
        self.assertEqual(report['last_registered']['palette_assignment_offset'], 35 * 96)
        self.assertEqual(report['future_ids_arithmetic_only'], [63, 127, 255])
        self.assertFalse(report['rom_bank_layout_verified'])
        self.assertFalse(report['vram_budget_verified'])
        self.assertFalse(report['compiled_rom'])
        self.assertFalse(report['phone_verified'])

    def mutated_project(self, path, before, after):
        with TemporaryDirectory() as dirname:
            root = Path(dirname)
            required = (
                'macros/data_macros.asm', 'constants/tilesets.asm', 'data/tileset_headers.asm',
                'engine/overworld/tileset_header.asm', 'color/loadpalettes.asm',
                'color/data/map_palette_sets.asm',
                'color/data/map_palette_assignments.asm',
            )
            required += tuple(str(p.relative_to(ROOT)) for p in
                              (ROOT/'color/tilesets').glob('*.asm'))
            for rel in required:
                target = root/rel
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT/rel, target)
            target = root/path
            original = target.read_text()
            self.assertIn(before, original)
            target.write_text(original.replace(before, after, 1))
            with self.assertRaises(ResourceIndexError):
                audit(root)

    def test_header_multiplier_mutation_is_rejected_for_all_ids(self):
        self.mutated_project('engine/overworld/tileset_header.asm',
                             'add hl, de ; id * 12',
                             'add hl, hl ; WRONG multiplier')

    def test_high_byte_carry_mutation_is_rejected(self):
        self.mutated_project('color/loadpalettes.asm',
                             '\tsla e\n\trl d\n\tsla e',
                             '\tsla e\n\tnop\n\tsla e')

    def test_incomplete_palette_set_is_rejected(self):
        self.mutated_project('color/data/map_palette_sets.asm',
                             '\tdb CAVE_LIGHT_BLUE\n\tdb CRYS_TEXTBOX',
                             '\tdb CAVE_LIGHT_BLUE\n; removed palette byte')

    def test_missing_palette_assignment_include_is_rejected(self):
        self.mutated_project('color/data/map_palette_assignments.asm',
                             'INCLUDE "color/tilesets/johto_ilex_forest.asm"',
                             '; accidentally omitted last tileset')

    def test_short_palette_assignment_row_is_rejected(self):
        self.mutated_project('color/tilesets/johto_ilex_forest.asm',
                             'tilepal 0, GRAY, BROWN, BROWN, RED, YELLOW, GREEN, BROWN, YELLOW',
                             'tilepal 0, GRAY, BROWN, BROWN, RED, YELLOW, GREEN, BROWN')

    def test_wrong_assignment_stride_is_rejected(self):
        self.mutated_project('color/loadpalettes.asm',
                             'ld de,$0060', 'ld de,$005f')

    def test_header_macro_stride_drift_is_rejected(self):
        self.mutated_project('macros/data_macros.asm',
                             r'dw \1, \2, \3 ; Block, GFX, Coll',
                             r'db \1, \2, \3 ; broken pointer size')

    def test_tilepal_macro_stride_drift_is_rejected(self):
        self.mutated_project('macros/data_macros.asm',
                             'rept _NARG +- 1', 'rept _NARG +- 2')

    def test_header_record_removed_is_rejected(self):
        self.mutated_project('data/tileset_headers.asm',
                             '\ttileset JohtoIlexForest_Block, JohtoIlexForest_GFX, JohtoIlexForest_Coll, $FF,$FF,$FF, $FF, CAVE',
                             '; last tile header removed')


if __name__ == '__main__':
    unittest.main()
