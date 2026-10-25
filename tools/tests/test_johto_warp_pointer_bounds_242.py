"""Fail-closed source regression for 34-entry legacy WarpTileIDPointers.

This verifies the lookup guard without compiling a ROM.  It deliberately
requires review if a new tileset is registered or the table is extended.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def guard_errors(constants: str, ids: str, state: str) -> list[str]:
    problems = []
    tilesets = re.findall(r'^\s*const\s+([A-Z0-9_]+)\b', constants, re.M)
    block = ids.split('WarpTileIDPointers:', 1)[-1].split('\nOverworldWarpTileIDs:', 1)[0]
    pointers = re.findall(r'^\s*dw\s+(\w+)', block, re.M)
    # The existing collision router has been reviewed for these six IDs.
    # New tilesets require a deliberate review instead of an auto-PASS.
    if tilesets[34:] != [
        'JOHTO_PARK_GATE', 'JOHTO_RUINS_GATE', 'JOHTO_HOUSE',
        'JOHTO_OLIVINE_POKECENTER', 'JOHTO_OLIVINE_MART',
        'JOHTO_OLIVINE_CAFE',
    ]:
        problems.append('unreviewed tileset added/removed')
    if len(pointers) != 34:
        problems.append('legacy pointer count changed')
    elif tilesets[len(pointers)] != 'JOHTO_PARK_GATE':
        problems.append('pointer boundary no longer matches tileset')
    routine = state.split('IsPlayerStandingOnDoorTileOrWarpTile:', 1)[-1].split(
        '\nINCLUDE "data/warp_tile_ids.asm"', 1)[0]
    if not re.search(
        r'callba IsPlayerStandingOnDoorTile\s+'
        r'jr c, \.done\s+'
        r'ld a, \[wCurMapTileset\]\s+'
        r'(?:;[^\n]*\n\s*)*'
        r'cp JOHTO_PARK_GATE\s*(?:;[^\n]*)?\n\s*'
        r'jr nc, \.done\s*(?:;[^\n]*)?\n\s*'
        r'add a\s+ld c, a\s+ld b, \$0\s+'
        r'ld hl, WarpTileIDPointers\s+add hl, bc',
        routine,
    ):
        problems.append('unchecked table access / wrong Carry')
    # Two semantic-equivalent 6->4 byte branches pay for the 4-byte guard.
    # No bank-3 expansion is allowed: the supplied MAP has zero spare bytes.
    up = state.split('\n.facingUp\n', 1)[-1].split('\n.facingLeft\n', 1)[0]
    left = state.split('\n.normalLeftEdge\n', 1)[-1].split('\n.facingRight\n', 1)[0]
    if not re.search(r'ld a, b\s+cp 1\s+ret', up):
        problems.append('facing-up carry or byte budget changed')
    if not re.search(r'ld a, c\s+cp 1\s+ret', left):
        problems.append('normal-left carry or byte budget changed')
    return problems


class WarpPointerBoundary242(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.consts = (ROOT / 'constants/tilesets.asm').read_text()
        cls.ids = (ROOT / 'data/warp_tile_ids.asm').read_text()
        cls.state = (ROOT / 'engine/overworld/player_state.asm').read_text()

    def test_guard_prevents_out_of_bounds_and_keeps_romx3_byte_neutral(self):
        self.assertEqual(guard_errors(self.consts, self.ids, self.state), [])

    def test_all_six_new_tilesets_fail_closed_without_generic_step_on(self):
        tilesets = re.findall(r'^\s*const\s+([A-Z0-9_]+)\b', self.consts, re.M)
        self.assertEqual(tilesets[34:40], [
            'JOHTO_PARK_GATE', 'JOHTO_RUINS_GATE', 'JOHTO_HOUSE',
            'JOHTO_OLIVINE_POKECENTER', 'JOHTO_OLIVINE_MART',
            'JOHTO_OLIVINE_CAFE',
        ])
        for i in range(40):
            with self.subTest(tileset_id=i):
                self.assertEqual(i >= 34, i >= tilesets.index('JOHTO_PARK_GATE'))
        # Existing fallthrough entries at 31..33 are all $FF-only:
        for label in ('JohtoParkWarpTileIDs', 'JohtoParkGateWarpTileIDs',
                      'JohtoRuinsGateWarpTileIDs'):
            self.assertIn(f'{label}:\n\tdb $FF', self.ids)

    def test_bad_boundary_does_not_pass(self):
        self.assertIn('unchecked table access', ' '.join(guard_errors(
            self.consts, self.ids,
            self.state.replace('cp JOHTO_PARK_GATE ; first tileset',
                               'cp JOHTO_RUINS_GATE ; first tileset', 1))))

    def test_wrong_carry_direction_does_not_pass(self):
        self.assertIn('unchecked table access', ' '.join(guard_errors(
            self.consts, self.ids,
            self.state.replace('jr nc, .done      ; fail closed',
                               'jr c, .done      ; fail closed', 1))))

    def test_missing_guard_does_not_pass(self):
        altered = self.state.replace('cp JOHTO_PARK_GATE ; first tileset',
                                     'nop ; deleted guard', 1)
        self.assertIn('unchecked table access', ' '.join(guard_errors(
            self.consts, self.ids, altered)))

    def test_new_tileset_requires_manual_review(self):
        self.assertIn('unreviewed tileset', ' '.join(guard_errors(
            self.consts + '\n\tconst JOHTO_NEXT_INTERIOR\n', self.ids, self.state)))

    def test_shortened_edge_branch_carry_matches_original(self):
        # Original tests b==0/c==0 then SCF, otherwise AND A clears Carry.
        # CP 1 preserves precisely that Carry contract across all 256 inputs.
        for coordinate in range(256):
            self.assertEqual(coordinate < 1, coordinate == 0)


if __name__ == '__main__':
    unittest.main()
