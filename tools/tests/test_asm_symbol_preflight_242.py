"""MUS-242 regression: resolve RGBDS dot-label branches before delivery.

The real RGBDS linker remains the final authority, run by the project owner.
"""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('asm_symbol_preflight', ROOT / 'tools/asm_symbol_preflight.py')
PREFLIGHT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PREFLIGHT)


class ASMPreflight242Tests(unittest.TestCase):
    def test_actual_music_function_has_valid_local_targets(self):
        source = (ROOT / 'engine/menu/options_menu.asm').read_text(encoding='utf-8')
        self.assertEqual(PREFLIGHT.check_text(source, 'options_menu.asm'), [])
        self.assertIn('jp .legacyStyle ; MUS-242', source)
        self.assertNotIn('jr .rbyFamily', source)

    def test_reproduce_mus241_linker_error_before_fix(self):
        before = '''ResolveMusicStyle::\n    cp MUSIC_STYLE_RND\n    jr z, .johtoRND\n    jr .rbyFamily\n.johtoRND\n    ret\n.legacyStyle\n    ret\n'''
        errors = PREFLIGHT.check_text(before, 'test.asm')
        self.assertEqual(len(errors), 1)
        self.assertIn('ResolveMusicStyle.rbyFamily', errors[0])

    def test_fixed_branch_passes(self):
        fixed = '''ResolveMusicStyle::\n    cp MUSIC_STYLE_RND\n    jr z, .johtoRND\n    jp .legacyStyle\n.johtoRND\n    ret\n.legacyStyle\n    ret\n'''
        self.assertEqual(PREFLIGHT.check_text(fixed), [])

    def test_real_code_mutation_fails(self):
        source = (ROOT / 'engine/menu/options_menu.asm').read_text(encoding='utf-8')
        mutated = source.replace('jp .legacyStyle ; MUS-242', 'jr .rbyFamily ; MUS-242', 1)
        errors = PREFLIGHT.check_text(mutated)
        self.assertTrue(any('ResolveMusicStyle.rbyFamily' in error for error in errors))

    def test_legal_rgbds_bare_labels_and_macro_are_not_false_positive(self):
        source = '''PrintNumber_:\n    jr .hundreds\nhelper: macro\n    jr .name\\@\n.name\\@\nendm\n.hundreds print_digit 100\n    jp .done\n.done\n    ret\n'''
        self.assertEqual(PREFLIGHT.check_text(source), [])

    def test_same_named_local_under_other_global_does_not_resolve(self):
        source = '''First::\n    jr .done\nSecond::\n.done\n    ret\n'''
        errors = PREFLIGHT.check_text(source)
        self.assertEqual(len(errors), 1)
        self.assertIn('First.done', errors[0])

    def test_all_current_asm_sources_pass(self):
        errs = []
        for source in PREFLIGHT.sources(ROOT, []):
            errs.extend(PREFLIGHT.check_text(source.read_text(encoding='utf-8'), str(source.relative_to(ROOT))))
        self.assertEqual(errs, [])


if __name__ == '__main__':
    unittest.main()
