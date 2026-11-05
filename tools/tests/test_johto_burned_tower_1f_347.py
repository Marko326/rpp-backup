"""REF-347 historical 1F contract, with explicit REF-348 activation checks."""
from __future__ import annotations
from collections import Counter, deque
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

def read(rel):
    return (ROOT / rel).read_text()

class TestBurnedTower1F347(unittest.TestCase):
    def setUp(self):
        self.roles = (ROOT / 'maps/johto_pilot/BurnedTower1F.gold_roles.bin').read_bytes()
        self.rt = read('data/johto_burned_tower/REF347_1f_runtime.asm')

    @property
    def active_maps(self):
        return int(re.search(r'DEF NUM_JOHTO_ACTIVE_MAPS EQU (\d+)', read('constants/region_map_constants.asm')).group(1))

    def test_gold_role_grid_and_stage_specific_pits(self):
        self.assertEqual(len(self.roles), 360)
        self.assertEqual(Counter(self.roles), {0:150, 1:1, 2:11, 3:196, 4:2})
        self.assertIn('cp 4 ; Gold WARP_CARPET_DOWN', self.rt)
        # REF-348 deliberately opens the 1F PIT and LADDER cells; REF-347 kept
        # both closed.  Their Gold role locations never change.
        if self.active_maps == 63:
            self.assertIn('cp 2 ; Gold PIT, active step-in trigger', self.rt)
            self.assertIn('cp 1 ; Gold LADDER, active step-in trigger', self.rt)
        self.assertIn('cp 20', self.rt)
        self.assertIn('cp 18', self.rt)
        # All four directions: never allow WALL/PIT/LADDER as a destination.
        for y in range(18):
            for x in range(20):
                for dx,dy in ((0,-1),(0,1),(-1,0),(1,0)):
                    xx,yy=x+dx,y+dy
                    allow=(0 <= xx < 20 and 0 <= yy < 18 and self.roles[yy*20+xx] in (0,4))
                    if allow:
                        self.assertNotIn(self.roles[yy*20+xx], (1,2,3))

    def test_no_softlock_and_two_exits(self):
        seen={(9,15)}
        q=deque(seen)
        while q:
            x,y=q.popleft()
            for dx,dy in ((0,-1),(0,1),(-1,0),(1,0)):
                tx,ty=x+dx,y+dy
                if 0<=tx<20 and 0<=ty<18 and self.roles[ty*20+tx] in (0,4) and (tx,ty) not in seen:
                    q.append((tx,ty));seen.add((tx,ty))
        self.assertEqual(len(seen), 151)
        self.assertIn((10,15),seen)

    def test_only_enter_exit_routes(self):
        self.assertIn('db 14 ; Gold order: two DOWN carpets, eleven PITs, one lower ladder' if self.active_maps == 63 else 'db 2 ; only paired DOWN-only exit carpets', self.rt)
        self.assertIn('db 15, 9, 5, JOHTO_REGISTERED_WARP_SELECTOR',self.rt)
        self.assertIn('db 15, 10, 5, JOHTO_REGISTERED_WARP_SELECTOR',self.rt)
        active_routes=read('engine/johto_pilot_runtime.asm').split('JohtoRegisteredWarpRoutes::')[1].split('JohtoRegisteredWarpRoutesEnd::')[0]
        entries=[line for line in active_routes.splitlines() if re.match(r'\s*db MAP_REGION_JOHTO,',line)]
        self.assertEqual(len(entries),160 if self.active_maps == 63 else 147)
        # Source registration is distinct from destination mentions.  B1F's
        # first five ordinals are always destination-only, even in REF-348.
        sources = [re.match(r'\s*db MAP_REGION_JOHTO, (\w+), (\d+), MAP_REGION_JOHTO,', line)
                   for line in entries]
        sources = [(m[1], int(m[2])) for m in sources if m]
        self.assertEqual(sum(local == 'JOHTO_BURNED_TOWER_1F_LOCAL_ID'
                             for local, _ in sources),14 if self.active_maps == 63 else 2)
        basement = [ordinal for local, ordinal in sources if local == 'JOHTO_BURNED_TOWER_B1F_LOCAL_ID']
        self.assertEqual(basement, [5] if self.active_maps == 63 else [])
        city=read('data/johto_corridor_runtime_294.asm')
        self.assertIn('db 6 ; REF-347',city)
        self.assertIn('db 5, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR',city)

    def test_registry_and_tileset(self):
        self.assertIn(f'DEF NUM_JOHTO_ACTIVE_MAPS EQU {self.active_maps}', read('constants/region_map_constants.asm'))
        self.assertIn(self.active_maps, (62, 63))
        slots=read('data/johto_stable_id_slots.asm')
        self.assertIn('JOHTO_INVALID_ACTIVE_SLOT, 61, 62' if self.active_maps == 63 else 'JOHTO_INVALID_ACTIVE_SLOT, 61, JOHTO_INVALID_ACTIVE_SLOT', slots)
        self.assertIn('tileset JohtoBurnedTower1F_Block', read('data/tileset_headers.asm'))
        self.assertIn('INCLUDE "color/tilesets/johto_burned_tower_1f.asm"', read('color/data/map_palette_assignments.asm'))
        self.assertIn('INCLUDE "data/johto_burned_tower/REF347_1f_runtime.asm"',read('main.asm'))
        self.assertNotIn('REF346_runtime_candidate.asm',read('main.asm'))
        self.assertEqual(read('data/game_version.asm').count('REF-348@' if self.active_maps == 63 else 'REF-347@'),1)
        if self.active_maps == 63:
            self.assertIn('dw JohtoBurnedTowerB1FRuntimeHeader', read('data/johto_header_descriptors.asm'))
        else:
            self.assertNotIn('dw JohtoBurnedTowerB1FRuntimeHeader', read('data/johto_header_descriptors.asm'))

    def test_active_slot_compilation_preflight(self):
        # A new active slot must extend BOTH Town Map tables and music. The
        # former REF-347 candidate compiled with three failing length ASSERTs.
        from tools.johto_table_assert_preflight import inspect
        issues, checked, expected = inspect(ROOT)
        self.assertEqual(expected, self.active_maps)
        self.assertFalse(issues, issues)
        self.assertEqual(len(checked), 3)
        slots = read('data/johto_stable_id_slots.asm')
        self.assertNotRegex(slots, r'\bdb\s+db\b')
        town_map = read('engine/fly_town_map_helpers.asm')
        self.assertIn('db 60, 76 ; slot61 Burned Tower 1F', town_map)
        self.assertIn('db 21 ; slot61 Burned Tower 1F', town_map)
        if self.active_maps == 63:
            self.assertIn('db 21 ; slot62 Burned Tower B1F', town_map)
            self.assertIn('db 60, 76 ; slot62 Burned Tower B1F', town_map)
        self.assertIn('MUSIC_GBP_GSC_BURNED_TOWER ; slot61',
                      read('engine/menu/options_menu.asm'))
        if self.active_maps == 63:
            self.assertIn('MUSIC_GBP_GSC_BURNED_TOWER ; slot62', read('engine/menu/options_menu.asm'))

    def test_tile_passthrough_is_safe(self):
        coll=(ROOT/'gfx/tilesets/johto_burned_tower_1f.tilecoll').read_bytes()
        self.assertEqual(len(coll),12)
        self.assertEqual(coll[-1],0xff)
        self.assertEqual(len(set(coll)),12)
        import json
        plan=json.loads((ROOT/'docs/REF346_BURNED_TOWER_ROUTE_PLAN.json').read_text())
        self.assertEqual(list(coll[:-1]),plan['floor_resources'][0]['fallback_passable_tile_ids'])
        pal=read('color/data/map_palette_sets.asm')
        self.assertIn('Gold Burned Tower 1F TOWER/DAY.', pal)
        self.assertIn('OUTDOOR_YELLOW, OUTDOOR_BROWN',pal)

    def test_hooks_keep_exit_direction_specific(self):
        routes=read('engine/johto_pilot_runtime.asm')
        self.assertIn('JohtoBurnedTowerCityBeforeStep',routes)
        self.assertIn('JohtoBurnedTowerCityAfterStep',routes)
        self.assertGreaterEqual(routes.count('JohtoBurnedTower1FDownCarpet'),2)
        self.assertIn('JohtoBurnedTower1FLandDecision',read('engine/johto_land_collision_gateway_272.asm'))
        self.assertIn('JohtoBurnedTower1FDownCarpet::',self.rt)
        self.assertIn('cp PLAYER_DIR_DOWN',self.rt)

if __name__=='__main__': unittest.main()
