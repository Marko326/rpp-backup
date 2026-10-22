"""Validate cave-mouth movement behavior missing from Union Cave 1F art audits."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def walkable_at(name, tileset, x, y, width):
    blocks = (ROOT / f'maps/{name}.blk').read_bytes()
    tiles = (ROOT / f'gfx/blocksets/{tileset}.bst').read_bytes()
    walk = set((ROOT / f'gfx/tilesets/{tileset}.tilecoll').read_bytes()[:-1])
    assert len(tiles) % 16 == 0
    metatile = blocks[(y // 2) * width + x // 2]
    block = tiles[metatile * 16:metatile * 16 + 16]
    index = (y % 2) * 2 + (x % 2)
    return all(block[((index // 2) * 2 + dy) * 4 + (index % 2) * 2 + dx] in walk
               for dy in range(2) for dx in range(2))


class CaveEntranceMovement(unittest.TestCase):
    def test_route32_approach_is_walkable_while_gold_cave_tile_is_solid(self):
        # The original warp coordinate (6,79) is blocked by the RPP collision
        # engine. A Warp there can never match the current player coordinates.
        self.assertFalse(walkable_at('JohtoRoute32', 'johto', 6, 79, 10))
        self.assertTrue(walkable_at('JohtoRoute32', 'johto', 6, 80, 10))
        self.assertTrue(walkable_at('JohtoRoute32', 'johto', 6, 82, 10))
        objects = (ROOT / 'data/mapObjects/JohtoRoute32.asm').read_text()
        self.assertEqual(re.findall(r'^\s*db\s+(\d+),\s*(\d+),\s*0,\s*REGION_WARP_ESCAPE', objects, re.M), [('79','6')])

    def test_route32_steps_into_original_gold_doorway(self):
        checks = (ROOT / 'engine/overworld/region_map_lookup.asm').read_text()
        approach = checks.split('JohtoRoute32CaveEntranceCheck::', 1)[1].split('JohtoRoute32CaveWarpTileCheck::',1)[0]
        for expected in ('ld a, [wXCoord]', 'cp 6', 'ld a, [wYCoord]', 'cp 80',
                         'ld a, [wPlayerDirection]', 'cp PLAYER_DIR_UP', 'scf', 'ret'):
            self.assertIn(expected, approach)
        step_on = checks.split('JohtoRoute32CaveWarpTileCheck::',1)[1].split('GetJohtoWarpArrivalStep::',1)[0]
        self.assertIn('cp 79',step_on)
        self.assertNotIn('cp 80',step_on)
        state=(ROOT/'engine/overworld/player_state.asm').read_text()
        target=state.split('IsPlayerStandingOnDoorTileOrWarpTile:',1)[1].split('INCLUDE "data/warp_tile_ids.asm"',1)[0]
        self.assertIn('callba JohtoRoute32CaveWarpTileCheck',target)
        collision=(ROOT/'home/overworld.asm').read_text().split('CollisionCheckOnLand::',1)[1].split('CheckTilePassable::',1)[0]
        self.assertRegex(collision,r'callba JohtoRoute32CaveEntranceCheck\s+jr c, \.noCollision')

    def test_interior_return_tile_is_passable_and_is_registered(self):
        self.assertTrue(walkable_at('JohtoUnionCave1F', 'johto_union_cave', 17, 3, 10))
        self.assertTrue(walkable_at('JohtoUnionCave1F', 'johto_union_cave', 16, 3, 10))
        self.assertIn('db 3, 17, 0, REGION_WARP_ESCAPE',
                      (ROOT / 'data/mapObjects/JohtoUnionCave1F.asm').read_text())
        self.assertRegex((ROOT / 'data/warp_tile_ids.asm').read_text(),
                         r'JohtoUnionCaveWarpTileIDs:\s*db \$FF')

    def test_other_gold_interiors_are_still_disabled(self):
        objects = (ROOT / 'data/mapObjects/JohtoRoute32.asm').read_text()
        self.assertIn('db $03 ; cave slot0 unchanged; Route32 west carpets are slots1/2',objects)
        self.assertIn('db $02\n', (ROOT / 'data/mapObjects/JohtoUnionCave1F.asm').read_text())
        self.assertIn('db 31, 17, 0, REGION_WARP_ESCAPE', (ROOT / 'data/mapObjects/JohtoUnionCave1F.asm').read_text())
        self.assertNotIn('JOHTO_UNION_CAVE_1F', (ROOT / 'constants/map_constants.asm').read_text())


if __name__ == '__main__':
    unittest.main()
