"""Union Cave 1F entrance plus current multi-floor registration regressions.

Review-only tests: do not link or claim to have executed a ROM.
"""
from pathlib import Path
import os
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_pilot_migration_audit import audit_project
from johto_surf_preflight import water_coordinates, check_project
from johto_gold_door_audit import GoldCollisionIndex
import json

GOLD = Path(os.getenv('GOLD_SOURCE_ROOT') or os.getenv('JOHTO_GOLD_SOURCE') or '/__missing__')


class UnionCave260(unittest.TestCase):
    def setUp(self):
        self.runtime = (ROOT/'engine/johto_pilot_runtime.asm').read_text()
        self.cave = (ROOT/'data/johto_union_cave_runtime.asm').read_text()
        self.route = (ROOT/'data/johto_route32_runtime.asm').read_text()

    def test_reserved_id_and_own_cave_tileset(self):
        constants = (ROOT/'constants/region_map_constants.asm').read_text()
        self.assertGreaterEqual(int(re.search(r'NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)', constants).group(1)), 13)
        self.assertIn('DEF JOHTO_UNION_CAVE_1F_LOCAL_ID EQU 8', constants)
        tilesets = (ROOT/'data/tileset_headers.asm').read_text()
        self.assertIn('tileset JohtoUnionCave_Block, JohtoUnionCave_GFX, JohtoUnionCave_Coll, $FF,$FF,$FF, $FF, CAVE', tilesets)
        self.assertIn('JohtoUnionCave_Coll:: INCBIN "gfx/tilesets/johto_union_cave.tilecoll"', (ROOT/'home.asm').read_text())
        self.assertIn('ASSERT BANK(JohtoUnionCave_Coll) == 0', tilesets)

    def test_three_floor_routes_preserve_both_surface_exits_and_stairs(self):
        body=self.runtime.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        cave_ids=('JOHTO_UNION_CAVE_1F_LOCAL_ID',
                  'JOHTO_UNION_CAVE_B1F_LOCAL_ID',
                  'JOHTO_UNION_CAVE_B2F_LOCAL_ID')
        rows=[x.split(';')[0].strip() for x in body.splitlines()
              if any(local in x.split(';')[0] for local in cave_ids)]
        self.assertEqual([
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B2F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B2F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_B1F_LOCAL_ID',
        ],rows)
        self.assertIn('db 3, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR',self.cave)
        self.assertIn('db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR',self.cave)
        self.assertIn('db 79, 6, 0, JOHTO_REGISTERED_WARP_SELECTOR',self.route)
        self.assertIn('db 9, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                      (ROOT/'data/johto_route33_runtime.asm').read_text())

    def test_cave_arrival_and_warp_collision_follow_current_floor_semantics(self):
        def code_only(source):
            return '\n'.join(line.split(';',1)[0].strip()
                             for line in source.splitlines()
                             if line.split(';',1)[0].strip())

        cave_ids=('JOHTO_UNION_CAVE_1F_LOCAL_ID',
                  'JOHTO_UNION_CAVE_B1F_LOCAL_ID',
                  'JOHTO_UNION_CAVE_B2F_LOCAL_ID')
        arrival = self.runtime.split('JohtoPilotGateArrivalStep::',1)[1].split('JohtoPilotGateDoorApproachAllowed::',1)[0]
        for local in cave_ids:
            self.assertRegex(arrival, rf'cp {local}\s+ret z')
        self.assertNotIn('ld [wPlayerDirection], a', arrival)
        self.assertNotIn('ld [wPlayerMovingDirection], a', arrival)
        self.assertNotIn('ld [wSpriteStateData1 + 9], a', arrival)

        approach = self.runtime.split('JohtoPilotGateDoorApproachAllowed::',1)[1].split('JohtoPilotGateDoorWarpMatched::',1)[0]
        for local in (*cave_ids, 'JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID',
                      'JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID'):
            self.assertRegex(approach, rf'cp {local}\s+ret z')

        matched = self.runtime.split('JohtoPilotGateDoorWarpMatched::',1)[1].split('JohtoPilotGateExteriorCollisionAllowed::',1)[0]
        matched_code = code_only(matched)
        for local, label in (
            ('JOHTO_UNION_CAVE_1F_LOCAL_ID', '.unionCave1FWarpMatched342'),
            ('JOHTO_UNION_CAVE_B1F_LOCAL_ID', '.unionCaveB1FWarpMatched342'),
            ('JOHTO_UNION_CAVE_B2F_LOCAL_ID', '.unionCaveB2FWarpMatched342'),
        ):
            self.assertRegex(matched_code, rf'cp {local}\s+jr z, {re.escape(label)}')
        self.assertRegex(matched_code, r'(?s)\.unionCave1FWarpMatched342\s+ld a, \[wXCoord\]\s+cp 17\s+jr z, \.unionCaveDirectional342\s+jr \.unionCaveLadder342')
        self.assertRegex(matched_code, r'(?s)\.unionCaveB1FWarpMatched342\s+ld a, \[wXCoord\]\s+cp 3\s+jr nz, \.unionCaveLadder342\s+ld a, \[wYCoord\]\s+cp 3\s+jr z, \.unionCaveDirectional342\s+cp 11\s+jr z, \.unionCaveDirectional342\s+jr \.unionCaveLadder342')
        self.assertRegex(matched_code, r'(?s)\.unionCaveB2FWarpMatched342\s+\.unionCaveLadder342\s+ld e, 2\s+ret')
        self.assertRegex(matched_code, r'(?s)\.unionCaveDirectional342\s+ld e, 1\s+ret')

        collision = code_only(self.runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1])
        self.assertIn('cp JOHTO_UNION_CAVE_1F_LOCAL_ID\njr z, .unionCaveExit', collision)
        for local in ('JOHTO_UNION_CAVE_B1F_LOCAL_ID',
                      'JOHTO_UNION_CAVE_B2F_LOCAL_ID',
                      'JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID',
                      'JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID'):
            self.assertIn(f'cp {local}\njr z, .unionCaveNoCollisionWarp342', collision)
        self.assertRegex(collision, r'(?s)\.unionCaveNoCollisionWarp342\s+ld e, 0\s+ret')
        self.assertRegex(collision, r'(?s)\.unionCaveExit\s+ld e, 0\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wXCoord\]\s+cp 17\s+ret nz\s+ld a, \[wYCoord\]\s+cp 3\s+jr z, \.yes\s+cp 31\s+ret nz\s+jr \.yes')

        warp_tiles = (ROOT/'data/warp_tile_ids.asm').read_text()
        warp_section = warp_tiles.split('JohtoUnionCaveWarpTileIDs:',1)[1].split('INCLUDE "data/johto_south_warp_tile_ids.asm"',1)[0]
        warp_data = re.search(r'(?m)^\s*db\s+([^;\n]+)', warp_section)
        self.assertIsNotNone(warp_data)
        self.assertEqual(
            ['$0e', '$0f', '$10', '$11', '$16', '$17', '$18', '$19',
             '$20', '$21', '$22', '$23', '$24', '$25', '$26', '$27', '$ff'],
            [value.strip().lower() for value in warp_data.group(1).split(',')],
        )
        self.assertNotIn('$12', warp_data.group(1).lower())

    def test_cave_bike_whitelist(self):
        self.assertIn('JOHTO_UNION_CAVE', (ROOT/'data/bike_riding_tilesets.asm').read_text())
        self.assertNotIn('JOHTO_GATE', (ROOT/'data/bike_riding_tilesets.asm').read_text())
        if GOLD.is_dir():
            idx = GoldCollisionIndex(GOLD)
            self.assertEqual('WARP_CARPET_DOWN', idx.role_at('UnionCave1F',17,3))
            self.assertEqual('WALL',idx.role_at('UnionCave1F',17,4))

    def test_cave_gold_water_scope_and_surf_shore(self):
        contract = json.loads((ROOT/'tools/johto_surf_contracts.json').read_text())
        entry = next(e for e in contract['maps'] if e['gold_map'] == 'UnionCave1F')
        asm = (ROOT/entry['routine_file']).read_text()
        coords = water_coordinates(asm, entry['water_table'], entry['water_end'])
        self.assertEqual(64, len(coords))
        self.assertIn('call JohtoUnionCaveWaterAhead\n\tret c', asm)
        overworld = (ROOT/'home/overworld.asm').read_text()
        self.assertIn('callab JohtoOverworldSurfDecision', overworld)
        self.assertIn('cp JOHTO_UNION_CAVE\n\tjp z, .unionCave', asm)
        self.assertRegex(asm, r'(?s)\.unionCave\s+;[^\n]*\n\s+;[^\n]*\n\s+call JohtoUnionCaveWaterAhead')
        if GOLD.is_dir():
            source = {(c['y'],c['x']) for c in GoldCollisionIndex(GOLD).cells('UnionCave1F').values() if c['role']=='WATER'}
            self.assertEqual(source, coords)
        self.assertEqual([], check_project(ROOT, contract, GOLD if GOLD.is_dir() else None))

    def test_current_migration_contract_passes(self):
        report = audit_project(ROOT, GOLD if GOLD.is_dir() else None)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])


if __name__ == '__main__':
    unittest.main()
