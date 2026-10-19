"""R32-5.62.165 P1-C: inspect real map records and safe return gates."""
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rpp_connection_guard import audit
from johto_indoor_collision_adapter import plan_gold_quadrant_collision


class Route32ConnectionTests(unittest.TestCase):
    def test_south_violet_route32_bounded_strip(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for original connection truth')
        result = audit(ROOT, GOLD, 'JohtoVioletCity', 'JohtoRoute32', 'VioletCity', 'Route32', 'south')
        self.assertEqual(result['status'], 'PASS', result)
        self.assertEqual(result['actual']['width'], 10)
        self.assertEqual(result['actual']['source_start'], 0)
        self.assertEqual(result['actual']['dest_start'], 549)
        self.assertEqual(result['actual']['arrive_y'], 0)

    def test_north_route32_violet_bounded_strip(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for original connection truth')
        result = audit(ROOT, GOLD, 'JohtoRoute32', 'JohtoVioletCity', 'Route32', 'VioletCity', 'north')
        self.assertEqual(result['status'], 'PASS', result)
        self.assertEqual(result['actual']['width'], 13)
        self.assertEqual(result['overlap']['visual_right_border'], 3)
        self.assertEqual(result['actual']['source_start'], 300)
        self.assertEqual(result['actual']['dest_start'], 3)
        self.assertEqual(result['actual']['arrive_y'], 35)

    def test_exact_two_tile_gates_leave_other_boundaries_blocked(self):
        source = (ROOT / 'main.asm').read_text(encoding='utf8')
        city = source.split('JohtoVioletCityCollisionFence::', 1)[1].split('SECTION "Johto Route 32 Edge Guard"', 1)[0]
        route = source.split('JohtoRoute32CollisionFence::', 1)[1].split('SECTION "Johto Route 29 Display Name"', 1)[0]
        self.assertIn('.south\n\tld a, [wYCoord]\n\tcp JOHTO_VIOLET_CITY_HEIGHT * 2 - 1', city)
        self.assertIn('.north\n\tld a, [wYCoord]\n\tand a\n\tjr nz, .allowed', route)
        for guard in (city, route):
            self.assertIn('\tcp 14\n\tjr c, .blocked\n\tcp 16\n\tjr nc, .blocked', guard)
        # Route32 remains sealed; only Violet's two Gold Route36 rows open.
        self.assertIn('.west\n\tld a, [wXCoord]\n\tand a\n\tjr z, .blocked', route)
        self.assertIn('.west\n\tld a, [wXCoord]\n\tand a\n\tjr nz, .allowed', city)
        self.assertIn('\tcp 8\n\tjr z, .allowed\n\tcp 9\n\tjr z, .allowed\n\tjr .blocked', city)
        self.assertIn('cp JOHTO_ROUTE_32_HEIGHT * 2 - 1', route)
        self.assertIn('cp JOHTO_VIOLET_CITY_WIDTH * 2 - 1', city)

    def test_gates_respect_saved_route31_visual_gate_and_route33_still_closed(self):
        violet = (ROOT / 'data/mapHeaders/JohtoVioletCity.asm').read_text(encoding='utf8')
        route32 = (ROOT / 'data/mapHeaders/JohtoRoute32.asm').read_text(encoding='utf8')
        objects = (ROOT / 'data/mapObjects/JohtoRoute32.asm').read_text(encoding='utf8')
        self.assertIn('db SOUTH | WEST | EAST', violet)
        self.assertIn('dw JohtoRoute36Blocks + JOHTO_ROUTE_36_WIDTH - 3', violet)
        self.assertIn('db JOHTO_ROUTE_31', violet)
        self.assertIn('db NORTH', route32)
        self.assertIn('JOHTO_ROUTE_33_WIDTH', route32)
        self.assertNotIn('JOHTO_AZALEA_TOWN', route32)
        self.assertIn('db $01 ; the original cave-mouth Warp only', objects)

    def test_route36_both_gold_connections_are_exact(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for Route36 seams')
        for current, target, gold_cur, gold_target, direction in (
                ('JohtoVioletCity', 'JohtoRoute36', 'VioletCity', 'Route36', 'west'),
                ('JohtoRoute36', 'JohtoVioletCity', 'Route36', 'VioletCity', 'east')):
            result = audit(ROOT, GOLD, current, target, gold_cur, gold_target, direction)
            self.assertEqual(result['status'], 'PASS', result)
            self.assertEqual(result['actual']['height'], 9)
            self.assertEqual(result['actual']['arrive_x'], 59 if direction == 'west' else 0)

    def test_route36_visual_connection_strips_share_rom_bank(self):
        # R36-5.62.218: old engine copies neighboring strips from the
        # CURRENT map bank; a cross-bank source pointer corrupts the border.
        source = (ROOT / 'main.asm').read_text(encoding='utf8')
        self.assertIn('SECTION "Johto Violet City Map", ROMX, BANK[JOHTO_ROM_BANK]', source)
        self.assertIn('SECTION "Johto Route36 Map", ROMX, BANK[JOHTO_ROM_BANK]', source)
        loader = (ROOT / 'home/overworld.asm').read_text(encoding='utf8')
        connection_loader = loader.split('LoadTileBlockMap::', 1)[1].split('LoadNorthSouthConnectionsTileMap::', 1)[0]
        for side in ('westConnection', 'eastConnection'):
            side_code = connection_loader.split('.' + side + '\n', 1)[1]
            self.assertIn('call SwitchToMapRomBank', side_code.split('call LoadEastWestConnectionsTileMap', 1)[0])

    def test_route36_gold_mask_keeps_unbuilt_gates_closed(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for Route36 quadrant truth')
        gold, mask = plan_gold_quadrant_collision(GOLD, 'Route36', 'johto')
        self.assertEqual((gold['width_cells'], gold['height_cells']), (60, 18))
        self.assertEqual((gold['blocked_count'], gold['walkable_count']), (810, 270))
        self.assertEqual(gold['hops'] + gold['unsafe_hop_candidates'], [])
        self.assertEqual((ROOT / 'maps/JohtoRoute36.blocked_mask.bin').read_bytes(), mask)
        self.assertEqual((ROOT / 'maps/JohtoRoute36.blk').read_bytes(),
                         (GOLD / 'maps/Route36.blk').read_bytes())
        self.assertEqual([(c['x'], c['y']) for c in gold['special_cells']],
                         [(18, 8), (18, 9), (47, 13), (48, 13), (47, 17)])
        for x, y in [(18, 8), (18, 9), (47, 13), (48, 13), (47, 17)]:
            self.assertTrue(mask[y * 8 + x // 8] & (1 << (x % 8)), (x, y))
        for x, y in [(59, 8), (59, 9), (35, 9)]:
            self.assertFalse(mask[y * 8 + x // 8] & (1 << (x % 8)), (x, y))

    def test_route36_all_used_gold_blocks_match_johto_art_at_same_id(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for pixel/byte comparison')
        from johto_rpp_asset_audit import load_png_tiles, gfx_signatures
        used = set((GOLD / 'maps/Route36.blk').read_bytes())
        self.assertEqual(len(used), 27)
        gold_blocks = (GOLD / 'data/tilesets/johto_metatiles.bin').read_bytes()
        rpp_blocks = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        gold_tiles = load_png_tiles(GOLD / 'gfx/tilesets/johto.png')
        rpp_tiles = load_png_tiles(ROOT / 'gfx/tilesets/johto.png')
        for block_id in used:
            gold_block = gold_blocks[block_id * 16:(block_id + 1) * 16]
            rpp_block = rpp_blocks[block_id * 16:(block_id + 1) * 16]
            self.assertEqual(rpp_block, gold_block, f'metatile {block_id:#04x}')
            self.assertEqual(gfx_signatures(rpp_block, rpp_tiles)[0],
                             gfx_signatures(gold_block, gold_tiles)[0],
                             f'pixel art {block_id:#04x}')

    def test_route36_gate_warps_and_unbuilt_neighbors_stay_deferred(self):
        objects = (ROOT / 'data/mapObjects/JohtoRoute36.asm').read_text()
        header = (ROOT / 'data/mapHeaders/JohtoRoute36.asm').read_text()
        collision = (ROOT / 'engine/overworld/johto_route33_collision.asm').read_text()
        self.assertIn('db $00 ; National Park / Ruins of Alph gates are not yet registered', objects)
        self.assertIn('db $00 ; no NPC objects; Sudowoodo event deferred for free passage', objects)
        self.assertNotIn('object SPRITE_SUDOWOODO', objects)
        scripts = (ROOT / 'scripts/JohtoRoute36.asm').read_text()
        self.assertNotIn('JohtoRoute36TreeText', scripts)
        self.assertIn('db SOUTH | EAST', header)
        self.assertNotIn('db NORTH |', header)
        self.assertIn('dw JohtoRoute35Blocks', header)
        self.assertIn('JohtoRoute36EdgeFence::', collision)
        self.assertIn('JohtoRoute36BlockedRows::', collision)
        self.assertIn('jp JohtoModernMaskedStep', collision)

    def test_route35_gold_map_geometry_and_art(self):
        # R35-5.62.219: use existing Gold converter and shared JOHTO art.
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for Route35 truth')
        from johto_rpp_asset_audit import load_png_tiles, gfx_signatures
        gold, mask = plan_gold_quadrant_collision(GOLD, 'Route35', 'johto')
        self.assertEqual((gold['width_cells'], gold['height_cells']), (20, 36))
        self.assertEqual((gold['blocked_count'], gold['walkable_count']), (392, 328))
        self.assertEqual(gold['hops'] + gold['unsafe_hop_candidates'], [])
        self.assertEqual((ROOT/'maps/JohtoRoute35.blocked_mask.bin').read_bytes(), mask)
        gold_blk = (GOLD/'maps/Route35.blk').read_bytes()
        self.assertEqual((ROOT/'maps/JohtoRoute35.blk').read_bytes(), gold_blk)
        self.assertEqual(len(gold_blk), 180)
        blocks = (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes()
        ours = (ROOT/'gfx/blocksets/johto.bst').read_bytes()
        gold_tiles = load_png_tiles(GOLD/'gfx/tilesets/johto.png')
        rpp_tiles = load_png_tiles(ROOT/'gfx/tilesets/johto.png')
        for block in set(gold_blk):
            chunk = blocks[block*16:(block+1)*16]
            self.assertEqual(ours[block*16:(block+1)*16], chunk)
            self.assertEqual(gfx_signatures(chunk, gold_tiles)[0],
                             gfx_signatures(chunk, rpp_tiles)[0])

    def test_route35_gold_cut_is_exactly_one_quadrant(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for Route35 Cut review')
        from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
        mapping=(GOLD/'maps/Route35.blk').read_bytes()
        roles,_=collision_labels(GOLD, 'johto', gold_resource_aliases(GOLD))
        cut={(2*(i//10)+q//2, 2*(i%10)+q%2)
             for i,block in enumerate(mapping)
             for q,role in enumerate(roles[block].split(','))
             if role.strip()=='CUT_TREE'}
        self.assertEqual(cut,{(6,17)})
        source=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        facing=source.split('JohtoRoute35CutTreeFacing:',1)[1].split('\n.no\n',1)[0]
        for token in ('cp JOHTO_ROUTE_35_LOCAL_ID', 'cp 17', 'cp 16',
                      'cp 18', 'cp 5', 'cp 7', 'cp 6', 'PLAYER_DIR_UP',
                      'PLAYER_DIR_DOWN', 'PLAYER_DIR_LEFT', 'PLAYER_DIR_RIGHT'):
            self.assertIn(token,facing)

    def test_route35_gold_cut_clone_and_surf_cells(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for Route35 field moves')
        from johto_route32_surf_geometry import gold_cells
        self.assertEqual(gold_cells(GOLD, 'Route35'),
                         {(y,x) for y in range(24,32) for x in range(4,8)})
        original = (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes()
        blocks = (ROOT/'gfx/blocksets/johto.bst').read_bytes()
        self.assertEqual(len(blocks), 138*16)
        old = original[0x5b*16:(0x5b+1)*16]
        clone = bytearray(old)
        for pos in (2,3,6,7):
            clone[pos] = 5
        self.assertEqual(blocks[0x89*16:0x8a*16], bytes(clone))
        self.assertEqual(blocks[0x5b*16:0x5c*16], old)
        r35=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        self.assertIn('JohtoRoute35CutTreeInFront::',r35)
        self.assertIn('JohtoRoute35CutTreeCleared::',r35)
        self.assertIn('JohtoRoute35RemoveCutTree::',r35)
        self.assertIn('call JohtoRoute35CutTreeCleared\n\tjr c, .allowed',r35)
        forest=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        self.assertIn('JohtoCutFacingBlockPointer::',forest)
        self.assertIn('cp JOHTO_ROUTE_35_LOCAL_ID',forest)
        field=(ROOT/'engine/overworld/field_moves.asm').read_text()
        cut=(ROOT/'engine/overworld/cut.asm').read_text()
        self.assertIn('callba JohtoRoute35CutTreeInFront',field)
        self.assertIn('callba JohtoRoute35CutTreeInFront',cut)
        self.assertIn('callba JohtoRoute35RemoveCutTree',cut)

    def test_route35_gold_connections_and_safe_deferred_exits(self):
        if not GOLD.is_dir():
            self.skipTest('Gold source needed for Route35 connections')
        for cur, target, refcur, reftarget, direction in (
                ('JohtoRoute36','JohtoRoute35','Route36','Route35','south'),
                ('JohtoRoute35','JohtoRoute36','Route35','Route36','north')):
            checked = audit(ROOT, GOLD, cur, target, refcur, reftarget, direction)
            self.assertEqual(checked['status'], 'PASS', checked)
            self.assertEqual(checked['actual']['width'],
                             13 if direction == 'north' else 10)
        main = (ROOT/'main.asm').read_text()
        collision = (ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        objects = (ROOT/'data/mapObjects/JohtoRoute35.asm').read_text()
        header = (ROOT/'data/mapHeaders/JohtoRoute35.asm').read_text()
        selector = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        self.assertIn('SECTION "Johto Route35 Map", ROMX, BANK[JOHTO_ROM_BANK]', main)
        self.assertIn('db NORTH', header)
        self.assertNotIn('db SOUTH |', header)
        self.assertIn('db $02 ; south Goldenrod gate #1/#2; National Park still deferred', objects)
        self.assertIn('db 33, 9, 0, REGION_WARP_ESCAPE', objects)
        self.assertIn('db 33, 10, 1, REGION_WARP_ESCAPE', objects)
        self.assertIn('db $00 ; do not spawn placeholder NPCs or blocking objects', objects)
        self.assertIn('JohtoRoute35EdgeFence::', collision)
        self.assertIn('JohtoRoute35CanStepAhead::', collision)
        self.assertIn('cp 17\n\tjr z, .clear', collision)
        self.assertIn('cp JOHTO_ROUTE_35_HEIGHT * 2 - 1', collision)
        self.assertIn('db JOHTO_ROUTE_36_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID', selector)
        self.assertIn('db JOHTO_ROUTE_35_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID', selector)


if __name__ == '__main__':
    unittest.main()
