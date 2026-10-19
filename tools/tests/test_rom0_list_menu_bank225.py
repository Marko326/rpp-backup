"""ROM0 list-menu main loop relocates to bank1 without unsafe bank returns."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from rom0_list_menu_bank_audit import audit

HOME = 'home.asm'
MAIN = 'main.asm'
CORE = 'engine/menu/list_menu_main.asm'
SWAP = 'engine/menu/swap_items.asm'


class Rom0ListMenuBank225(unittest.TestCase):
    def mutate(self, file, before, after, expected):
        original = (ROOT / file).read_text(encoding='utf8')
        self.assertIn(before, original)
        revised = original.replace(before, after, 1)
        self.assertNotEqual(original, revised)
        result = audit(ROOT, {file: revised})
        self.assertTrue(any(expected in line for line in result), result)

    def test_original_menu_stream_and_bank_exit_graph(self):
        self.assertEqual([], audit(ROOT))

    def test_wrong_entry_bank_is_blocked(self):
        self.mutate(HOME, 'ld a, $01\n\tcall BankswitchHome\n\tjp DisplayListMenuID_',
                    'ld a, $03\n\tcall BankswitchHome\n\tjp DisplayListMenuID_', 'HOME entry')

    def test_removing_bank_save_is_blocked(self):
        self.mutate(HOME, '\tcall BankswitchHome\n\tjp DisplayListMenuID_',
                    '\tjp DisplayListMenuID_', 'HOME entry')

    def test_restoring_bank_inside_romx_is_blocked(self):
        self.mutate(CORE, '\tjp ExitListMenuReturnHome',
                    '\tcall BankswitchBack\n\tjp ExitListMenuReturnHome', 'ROMX code must not execute')

    def test_success_must_jump_to_home_restore(self):
        self.mutate(CORE, '\tjp BankswitchBack',
                    '\tret', 'success exit')

    def test_cancel_must_jump_home_not_return_in_romx(self):
        self.mutate(CORE, '\tjp ExitListMenuReturnHome',
                    '\tret', 'Cancel must jump')

    def test_cancel_carry_flag_must_not_be_lost(self):
        self.mutate(HOME, '\tld [wMenuItemToSwap], a\n\tscf\n\tret',
                    '\tld [wMenuItemToSwap], a\t\n\tand a\n\tret', 'Carry=1')

    def test_item_swap_same_bank_source_must_remain(self):
        self.mutate(MAIN, 'SECTION "bank1",ROMX,BANK[$1]',
                    'SECTION "bank1",ROMX,BANK[$2]', 'share the original ROMX bank')

    def test_bank1_include_cannot_disappear(self):
        self.mutate(MAIN, 'INCLUDE "engine/menu/list_menu_main.asm"',
                    '; INCLUDE "engine/menu/list_menu_main.asm"', 'share the original ROMX')

    def test_menu_start_and_select_logic_cannot_change_silently(self):
        self.mutate(CORE, 'callba HandleBagStartShortcut',
                    'callba SwitchBagPocket', 'instruction stream changed')

    def test_wrong_cancel_behavior_rejected(self):
        self.mutate(CORE, '\tld a,CANCELLED_MENU',
                    '\tld a,CHOSE_MENU_ITEM', 'Cancel path instruction stream changed')

    def test_bank1_swap_jumps_must_stay_connected(self):
        self.mutate(SWAP, 'jp nz,DisplayListMenuIDLoop',
                    'jp nz,DisplayPokedex', 'resumes no longer reach')

if __name__ == '__main__':
    unittest.main()
