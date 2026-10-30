"""FIX-256: restore Gold's coordinate/direction whitelist for Ruins ledges.

Source/static checks only; RGBDS linkage and phone behavior require user testing.
"""
import os
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gold_door_audit import GoldCollisionIndex
from johto_field_move_coverage_audit import (
    _coordinate_hop_entries, _gold_safe_hop_directions, _ledge_table_for_map,
)

GOLD = Path(os.environ.get('GOLD_SOURCE_ROOT', '')) if os.environ.get('GOLD_SOURCE_ROOT') else None

EXPECTED_RUINS_HOPS = {
    (2, 18, 'DOWN'),
    (5, 30, 'DOWN'), (5, 30, 'LEFT'),
    (6, 30, 'DOWN'), (7, 30, 'DOWN'), (8, 30, 'DOWN'),
    (10, 30, 'DOWN'), (10, 30, 'RIGHT'),
    (2, 32, 'DOWN'), (3, 32, 'DOWN'), (4, 32, 'DOWN'),
    (5, 32, 'DOWN'), (6, 32, 'DOWN'), (7, 32, 'DOWN'),
    (8, 32, 'DOWN'), (8, 32, 'RIGHT'),
}


def _select_router_is_safe(source):
    body = source.split('\n.checkIfSelectIsPressed\n', 1)[-1].split('\n.selectButtonNotPressed\n', 1)[0]
    return bool(re.search(r'push af\s+farcall TryFishOrRideBike[^\n]*\n\s*pop bc\s+ld a, b\s+jp c, OverworldLoop', body))


class AlphSouthFieldHotfix256(unittest.TestCase):
    def test_select_fix_from_255_is_preserved(self):
        src = (ROOT / 'home/overworld.asm').read_text()
        self.assertTrue(_select_router_is_safe(src))
        self.assertFalse(_select_router_is_safe(src.replace('pop bc\n\tld a, b', 'pop bc', 1)))
        self.assertIn('.selectButtonNotPressed\n\tbit 3,a ; start button', src)

    def test_ruins_dispatch_uses_coordinate_table_not_generic_pairs(self):
        src = (ROOT / 'engine/overworld/ledges.asm').read_text()
        self.assertEqual('JohtoAlphSouthHops', _ledge_table_for_map(src, 'RuinsOfAlphOutside'))
        self.assertEqual('JohtoPilotRoute31LedgeTiles', _ledge_table_for_map(src, 'Route31'))
        self.assertEqual('JohtoPilotRoute31LedgeTiles', _ledge_table_for_map(src, 'Route32'))
        broken = src.replace('cp JOHTO_RUINS_OF_ALPH_LOCAL_ID\n\tjr z, .ruinsHopTable',
                             'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjr z, .ruinsHopTable', 1)
        self.assertIsNone(_ledge_table_for_map(broken, 'RuinsOfAlphOutside'))
        self.assertNotIn('JohtoAlphSouthLedgeTiles', src)
        self.assertIn('ld a, [wXCoord]', src)
        self.assertIn('ld a, [wYCoord]', src)
        self.assertIn('ld a, [wPlayerDirection]', src)

    def test_ruins_direction_table_matches_old_gold_branch(self):
        src = (ROOT / 'engine/overworld/ledges.asm').read_text()
        entries = _coordinate_hop_entries(src, 'JohtoAlphSouthHops')
        self.assertEqual(EXPECTED_RUINS_HOPS, entries)
        # Composite corners permit different directions from the same source:
        self.assertIn((5, 30, 'LEFT'), entries)
        self.assertIn((5, 30, 'DOWN'), entries)
        self.assertIn((10, 30, 'RIGHT'), entries)
        self.assertIn((8, 32, 'RIGHT'), entries)

    @unittest.skipUnless(GOLD is not None and GOLD.is_dir(), 'Gold reference root unavailable')
    def test_ruins_table_matches_all_and_only_safe_gold_directions(self):
        cells = GoldCollisionIndex(GOLD).cells('RuinsOfAlphOutside')
        src = (ROOT / 'engine/overworld/ledges.asm').read_text()
        actual = _coordinate_hop_entries(src, 'JohtoAlphSouthHops')
        expected = _gold_safe_hop_directions(cells)
        self.assertEqual(16, len(expected))
        self.assertEqual(expected, actual)

    @unittest.skipUnless(GOLD is not None and GOLD.is_dir(), 'Gold reference root unavailable')
    def test_unsafe_ninth_down_jump_is_excluded(self):
        cells = GoldCollisionIndex(GOLD).cells('RuinsOfAlphOutside')
        self.assertEqual('HOP_DOWN', cells[(9, 30)]['role'])
        self.assertEqual('WALL', cells[(9, 32)]['role'])
        src = (ROOT / 'engine/overworld/ledges.asm').read_text()
        entries = _coordinate_hop_entries(src, 'JohtoAlphSouthHops')
        self.assertNotIn((9, 30, 'DOWN'), entries)

    def test_other_maps_pair_tables_are_unchanged(self):
        src = (ROOT / 'engine/overworld/ledges.asm').read_text()
        route29 = src.split('JohtoPilotRoute29LedgeTiles:\n', 1)[1].split('JohtoPilotRoute31LedgeTiles:', 1)[0]
        route31 = src.split('JohtoPilotRoute31LedgeTiles:\n', 1)[1].split('JohtoAlphSouthHops:', 1)[0]
        self.assertIn('db SPRITE_FACING_LEFT,  $05,$3B,D_LEFT', route29)
        self.assertIn('db SPRITE_FACING_RIGHT, $05,$20,D_RIGHT', route29)
        self.assertIn('db SPRITE_FACING_DOWN,  $06,$21,D_DOWN', route29)
        self.assertIn('db SPRITE_FACING_RIGHT, $06,$30,D_RIGHT', route31)
        self.assertIn('db SPRITE_FACING_DOWN,  $06,$21,D_DOWN', route31)

    def test_version_and_test_label(self):
        src = (ROOT / 'data/game_version.asm').read_text()
        self.assertIn('db "FIX-5.62.256@"', src)
        self.assertIn('db "TEST-231@"', src)


if __name__ == '__main__':
    unittest.main()
