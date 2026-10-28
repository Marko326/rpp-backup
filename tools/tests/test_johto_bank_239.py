"""Guard the PAL-5.62.239 ROMX relocation that fixes the bank $3d link overflow.

This is a read-only source check, NOT a substitute for rgblink or a fresh MAP.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def check_bank_layout(main: str, home: str, menu: str, sign: str) -> None:
    required = {
        'Menu Shortcut Helpers': ['HandleBagStartShortcut', 'QuickSwapPartyMonWithFirst'],
        'Map Name Sign': ['LoadMapNameSignGFX', 'PrimeMapNameSignForWarpPad', 'UpdateMapNameSign'],
    }
    for section, labels in required.items():
        row = rf'(?m)^SECTION\s+"{re.escape(section)}"\s*,\s*ROMX\s*(?:;[^\n]*)?$'
        if len(re.findall(row, main)) != 1:
            raise AssertionError(f'{section} must be ONE floating ROMX section (no fixed bank)')
        for name in labels:
            if not re.search(rf'(?m)^\s*call(?:ab|ba)\s+{name}\b', home):
                raise AssertionError(f'{name} must use bank-aware external call from home.asm')
    for name in required['Menu Shortcut Helpers']:
        if not re.search(rf'(?m)^{name}::', menu):
            raise AssertionError(f'missing menu helper {name}')
    for name in required['Map Name Sign']:
        if not re.search(rf'(?m)^{name}::', sign):
            raise AssertionError(f'missing map-sign helper {name}')
    # The new local name strings must remain inside the single moved section.
    for name in ['JohtoNewBarkName', 'JohtoVioletName', 'JohtoRoute31Name']:
        if not re.search(rf'(?m)^\.{name}:', sign):
            raise AssertionError(f'missing section-local sign text {name}')


class Bank39Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / 'main.asm').read_text()
        cls.home = (ROOT / 'home.asm').read_text() + '\n' + (ROOT / 'home/overworld.asm').read_text()
        cls.menu = (ROOT / 'engine/menu/menu_shortcuts.asm').read_text()
        cls.sign = (ROOT / 'engine/overworld/map_name_sign.asm').read_text()

    def test_floating_sections_have_bank_aware_callers(self):
        check_bank_layout(self.main, self.home, self.menu, self.sign)

    def test_fixed_bank_regression_is_detected(self):
        for section in ['Menu Shortcut Helpers', 'Map Name Sign']:
            broken = self.main.replace(
                f'SECTION "{section}", ROMX',
                f'SECTION "{section}", ROMX, BANK[$3D]', 1)
            with self.assertRaisesRegex(AssertionError, section):
                check_bank_layout(broken, self.home, self.menu, self.sign)

    def test_unbanked_call_regression_is_detected(self):
        broken = self.home.replace('callba HandleBagStartShortcut', 'call HandleBagStartShortcut', 1)
        with self.assertRaisesRegex(AssertionError, 'HandleBagStartShortcut'):
            check_bank_layout(self.main, broken, self.menu, self.sign)

if __name__ == '__main__':
    unittest.main()
