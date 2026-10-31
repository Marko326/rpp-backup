"""UNION-260: fail-closed Gold Union Cave 1F registration / portal tests.

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
        self.assertIn('DEF NUM_JOHTO_ACTIVE_MAPS EQU 26', constants)
        self.assertIn('DEF JOHTO_UNION_CAVE_1F_LOCAL_ID EQU 8', constants)
        tilesets = (ROOT/'data/tileset_headers.asm').read_text()
        self.assertIn('tileset JohtoUnionCave_Block, JohtoUnionCave_GFX, JohtoUnionCave_Coll, $FF,$FF,$FF, $FF, CAVE', tilesets)
        self.assertIn('JohtoUnionCave_Coll:: INCBIN "gfx/tilesets/johto_union_cave.tilecoll"', (ROOT/'home.asm').read_text())
        self.assertIn('ASSERT BANK(JohtoUnionCave_Coll) == 0', tilesets)

    def test_two_cave_exits_both_bidirectional_and_down_only(self):
        body=self.runtime.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        rows=[x.split(';')[0].strip() for x in body.splitlines()
              if 'JOHTO_UNION_CAVE_1F_LOCAL_ID' in x.split(';')[0]]
        self.assertEqual([
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',
        ],rows)
        self.assertIn('db 3, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR',self.cave)
        self.assertIn('db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR',self.cave)
        self.assertIn('db 79, 6, 0, JOHTO_REGISTERED_WARP_SELECTOR',self.route)
        self.assertIn('db 9, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR',
                      (ROOT/'data/johto_route33_runtime.asm').read_text())
        self.assertNotIn('JOHTO_UNION_CAVE_B1F_LOCAL_ID',body)

    def test_cave_arrival_no_step_and_exact_down_collision_only(self):
        arrival = self.runtime.split('JohtoPilotGateArrivalStep::',1)[1].split('JohtoPilotGateDoorApproachAllowed::',1)[0]
        self.assertRegex(arrival, r'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\s+ret z')
        self.assertNotIn('.caveFacing', arrival)
        self.assertNotIn('ld [wPlayerDirection], a', arrival)
        self.assertNotIn('ld [wPlayerMovingDirection], a', arrival)
        self.assertNotIn('ld [wSpriteStateData1 + 9], a', arrival)
        self.assertNotIn('.unionCaveLanding', arrival)
        self.assertRegex(arrival, r'(?s)\.route32CaveLanding\s+ld a, \[wXCoord\]\s+cp 6\s+ret nz\s+ld a, \[wYCoord\]\s+cp 79\s+ret nz\s+jr \.down')
        for start, end in [('JohtoPilotGateDoorApproachAllowed::','JohtoPilotGateDoorWarpMatched::'),
                           ('JohtoPilotGateDoorWarpMatched::','JohtoPilotGateExteriorCollisionAllowed::')]:
            part = self.runtime.split(start,1)[1].split(end,1)[0]
            self.assertRegex(part, r'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\s+ret z')
            self.assertNotIn('.unionCaveMouth', part)
        collision = self.runtime.split('JohtoPilotGateCollisionExitAllowed::',1)[1]
        self.assertRegex(collision, r'(?s)\.unionCaveExit\s+;[^\n]*\n\s+;[^\n]*\n\s+ld e, 0\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wXCoord\]\s+cp 17\s+ret nz\s+ld a, \[wYCoord\]\s+cp 3\s+jr z, \.yes\s+cp 31\s+ret nz\s+jr \.yes')
        warp_tiles = (ROOT/'data/warp_tile_ids.asm').read_text()
        self.assertRegex(warp_tiles, r'JohtoUnionCaveWarpTileIDs:\s*db \$ff')

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
