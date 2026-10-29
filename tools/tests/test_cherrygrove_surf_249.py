"""CHERRY-249: Cherrygrove Surf must reuse the existing three Surf paths."""
from pathlib import Path
import os
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gold_door_audit import GoldCollisionIndex


class CherrygroveSurf249(unittest.TestCase):
    def test_map_scope_is_exact_and_not_a_global_tileset_whitelist(self):
        asm = (ROOT / 'engine/johto_violet_field_skills.asm').read_text()
        helper = asm.split('JohtoCherrygroveWaterAhead::', 1)[1].split(
            'JohtoVioletCutTreeAhead::', 1)[0]
        active = asm.split('JohtoCherrygroveIsActive::', 1)[1].split(
            'JohtoCherrygroveWaterAhead::', 1)[0]
        self.assertIn('call JohtoCherrygroveIsActive', helper)
        for token in ('JOHTO_RUNTIME_MAP_HANDLE', 'MAP_REGION_JOHTO',
                      'JOHTO_CHERRYGROVE_LOCAL_ID'):
            self.assertIn(token, active)
        self.assertIn('cp 18', helper)
        self.assertIn('cp 40', helper)
        field_moves = (ROOT / 'engine/overworld/field_moves.asm').read_text()
        field_whitelist = field_moves.split('WaterTilesets2:', 1)[1].split('IsCutTile:', 1)[0]
        items = (ROOT / 'engine/items/items.asm').read_text()
        item_whitelist = items.split('WaterTilesets:', 1)[1].split('ReadSuperRodData:', 1)[0]
        self.assertNotIn('JOHTO_PILOT', field_whitelist)
        self.assertNotIn('JOHTO_PILOT', item_whitelist)

    def test_all_three_existing_surf_entrypoints_call_cherrygrove_helper(self):
        expected = {
            'engine/overworld/field_moves.asm': r'IsSurfTile::?[\s\S]*?callab JohtoCherrygroveWaterAhead\s+ret c',
            'engine/items/items.asm': r'IsNextTileShoreOrWater::?[\s\S]*?callab JohtoCherrygroveWaterAhead\s+jr c, \.shoreOrWater',
            'home/overworld.asm': r'\.checkCherrygroveSurf\s+cp JOHTO_CHERRYGROVE_LOCAL_ID\s+jr nz, \.legacySurfTile\s+callab JohtoCherrygroveWaterAhead\s+jp c, \.noCollision\s+callab JohtoCherrygroveShoreFloorAhead\s+jp c, \.stopSurfing\s+ld a, \[wTileInFrontOfPlayer\]\s+ld c, a\s+jr \.checkIfNextTileIsPassable',
        }
        for filename, pattern in expected.items():
            source = (ROOT / filename).read_text()
            source = '\n'.join(line.split(';', 1)[0].strip() for line in source.splitlines())
            self.assertRegex(source, pattern, filename)

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_table_matches_all_142_gold_water_cells(self):
        index = GoldCollisionIndex(GOLD)
        expected = {(c['y'], c['x']) for c in index.cells('CherrygroveCity').values()
                    if c['role'] == 'WATER'}
        self.assertEqual(142, len(expected))
        asm = (ROOT / 'engine/johto_violet_field_skills.asm').read_text()
        table = asm.split('JohtoCherrygroveGoldWaterCells::', 1)[1].split(
            'JohtoCherrygroveGoldWaterCellsEnd::', 1)[0]
        actual = {(int(y), int(x)) for y, x in re.findall(
            r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*$', table)}
        self.assertEqual(expected, actual)

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_gold_water_does_not_become_walkable_without_surf(self):
        source = GOLD
        pattern = re.compile(r'tilecoll\s+(.+?)\s*;\s*([0-9a-fA-F]+)')
        collision = {}
        for line in (source / 'data/tilesets/johto_collision.asm').read_text().splitlines():
            match = pattern.search(line)
            if match:
                collision[int(match.group(2), 16)] = match.group(1).replace(' ', '').split(',')
        gold_blocks = (source / 'maps/CherrygroveCity.blk').read_bytes()
        runtime_blocks = (ROOT / 'maps/johto_pilot/CherrygroveCity.runtime.blk').read_bytes()
        blockset = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        allowed = set((ROOT / 'gfx/tilesets/johto.tilecoll').read_bytes()) - {0xff}
        self.assertEqual(len(gold_blocks), len(runtime_blocks))
        water_count = 0
        for gold_id, runtime_id in zip(gold_blocks, runtime_blocks):
            self.assertIn(gold_id, collision)
            block = blockset[runtime_id * 16:(runtime_id + 1) * 16]
            for quadrant, role in enumerate(collision[gold_id]):
                if role != 'WATER':
                    continue
                water_count += 1
                row, col = (quadrant // 2) * 2, (quadrant % 2) * 2
                art = {block[(row + dy) * 4 + col + dx]
                       for dx in range(2) for dy in range(2)}
                self.assertFalse(art & allowed, (hex(gold_id), hex(runtime_id), art & allowed))
        self.assertEqual(142, water_count)


if __name__ == '__main__':
    unittest.main()
