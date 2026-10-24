"""Regression guard: public-building ASM macro invocations need leading whitespace.

This is a *syntax-shape* check, not a replacement for rgbasm/linking.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
FILES = (
    'constants/sprite_constants.asm',
    'constants/tilesets.asm',
    'data/johto_map_headers.asm',
    'data/tileset_headers.asm',
    'engine/overworld/map_sprites.asm',
    'engine/town_map.asm',
    'color/tilesets/johto_olivine_pokecenter.asm',
    'color/tilesets/johto_olivine_mart.asm',
    'color/tilesets/johto_olivine_cafe.asm',
)
BAD_DIRECTIVE = re.compile(r'^(const|tileset|tilepal|db|dw|cp)\s+')


class RgbdsIndentationContract(unittest.TestCase):
    def test_public_asm_has_no_column_zero_invocations(self):
        errors = []
        for file in FILES:
            for number, line in enumerate((ROOT/file).read_text().splitlines(), 1):
                if BAD_DIRECTIVE.match(line):
                    errors.append(f'{file}:{number}: {line}')
        self.assertEqual(errors, [], 'RGBDS macro/opcode invocations must be indented')

    def test_generators_emit_indented_macro_calls(self):
        installer = (ROOT/'tools/install_olivine_public_runtime.py').read_text()
        generator = (ROOT/'tools/johto_olivine_public_runtime.py').read_text()
        self.assertIn('palette_lines.append(f"\\ttilepal 0, {values}")', generator)
        for token in (
            'const JOHTO_OLIVINE_POKECENTER',
            'const SPRITE_JOHTO_NURSE',
            'tileset JohtoOlivinePokecenter_Block',
            'cp a, SPRITE_JOHTO_NURSE',
        ):
            self.assertIn('\\t'+token, installer)


if __name__ == '__main__':
    unittest.main()
