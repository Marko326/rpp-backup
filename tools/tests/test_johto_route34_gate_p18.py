"""P18 independent Gold source contracts; NONE are emulated CPU or phone claims."""
import sys, unittest, re
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_indoor_common import gold_warps, rpp_warps
from johto_indoor_tiles_converter import build_mapping
from johto_indoor_collision_adapter import plan_gold_quadrant_collision

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(__file__).resolve().parents[2] / '_NONEXISTENT_GOLD'
# Gold source must be supplied explicitly; no silent skip or remote fetch.
import os
if os.environ.get('JOHTO_GOLD_ROOT'):
    GOLD = Path(os.environ['JOHTO_GOLD_ROOT']).resolve()


def source(name):return (ROOT/name).read_text(encoding='utf8')
def require_gold():
    if not (GOLD/'maps/Route34.blk').is_file():
        raise RuntimeError('Set JOHTO_GOLD_ROOT to original pokegold-master for P18 tests')

class NorthGateP18(unittest.TestCase):
    @classmethod
    def setUpClass(cls): require_gold()

    def test_gold_warp_pair_graph(self):
        assert len(gold_warps(GOLD, 'Route34IlexForestGate')) == 4
        gate = rpp_warps(ROOT,'JohtoRoute34IlexForestGate')
        route = rpp_warps(ROOT,'JohtoRoute34')
        forest = rpp_warps(ROOT,'JohtoIlexForest')
        self.assertEqual([(w['x'],w['y'],w['dest_id']) for w in gate],[(4,0,0),(5,0,1),(4,7,2),(5,7,2)])
        self.assertEqual([(w['x'],w['y'],w['dest_id']) for w in route],[(13,37,0),(14,37,1)])
        self.assertEqual((forest[2]['x'],forest[2]['y'],forest[2]['dest_id']),(1,5,2))
        s=source('engine/overworld/region_map_lookup.asm')
        rows=[x.strip() for x in s.splitlines() if x.strip().startswith('db JOHTO_') and 'MAP_REGION_JOHTO' in x]
        expected=(
            'JOHTO_ILEX_FOREST_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',
            'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 2, 2, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID',
            'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 3, 2, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID',
            'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID',
            'JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_34_LOCAL_ID',
            'JOHTO_ROUTE_34_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',
            'JOHTO_ROUTE_34_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID')
        for r in expected:self.assertTrue(any(r in x for x in rows),r)

    def test_collision_direction_only(self):
        a=source('home/overworld.asm')
        gate=a.split('CheckWarpsCollision::',1)[1].split('CheckWarpsNoCollisionRetry1::')[0]
        self.assertIn('callba JohtoGateCollisionDirectionAllowed',gate)
        self.assertIn('push bc',gate)
        self.assertIn('pop hl',gate)
        self.assertIn('jr nc, .retry2',gate)
        extra=a.split('ExtraWarpCheck::',1)[1].split('IsJohtoSouthGatePortal::',1)[0]
        self.assertIn('callba JohtoInternalDoorFacingCheck',extra)
        c=source('engine/overworld/johto_route33_collision.asm')
        for t in ('JohtoGateCollisionDirectionAllowed::','JohtoInternalDoorFacingCheck::',
                  'JohtoRoute34GateCanStepAhead::','JohtoRoute34GateBlockedRows',
                  'cp JOHTO_ILEX_FOREST_LOCAL_ID','cp JOHTO_ROUTE_34_LOCAL_ID',
                  'PLAYER_DIR_UP','PLAYER_DIR_DOWN'):
            self.assertIn(t,c)

    def test_immediate_return_and_exact_one_step_after_warp(self):
        a=source('home/overworld.asm')
        still=a.split('CheckWarpsNoCollisionLoop::')[1].split('CheckWarpsCollision::')[0]
        self.assertIn('call IsJohtoSouthGatePortal',still)
        self.assertIn('callba JohtoNorthGateStepWarpAllowed',still)
        self.assertIn('jp c, WarpFound1',still)
        self.assertIn('jp CheckWarpsNoCollisionRetry2',still)
        self.assertNotIn('StartSimulatingJoypadStates',still)
        for n in ['JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID','JOHTO_ROUTE_34_LOCAL_ID']:
            self.assertIn('cp '+n,a.split('IsJohtoSouthGatePortal::')[1].split('MapEntryAfterBattle::')[0])
        self.assertNotIn('GetJohtoWarpArrivalStep',a.split('WarpFound2::')[1].split('CheckMapConnections::')[0])
        self.assertIn('JohtoNorthGateStepWarpAllowed::',source('engine/overworld/johto_route33_collision.asm'))
        self.assertIn('callab GetJohtoWarpArrivalStep',source('engine/overworld/npc_movement.asm'))

    def test_loading_and_terrain_preserved(self):
        self.assertEqual((ROOT/'maps/JohtoRoute34.blk').read_bytes(),(GOLD/'maps/Route34.blk').read_bytes())
        self.assertEqual((ROOT/'gfx/blocksets/johto_modern.bst').read_bytes(),(GOLD/'data/tilesets/johto_modern_metatiles.bin').read_bytes())
        _,m=plan_gold_quadrant_collision(GOLD,'Route34','johto_modern')
        self.assertEqual((ROOT/'maps/JohtoRoute34.blocked_mask.bin').read_bytes(),m)
        _,m=plan_gold_quadrant_collision(GOLD,'Route34IlexForestGate','gate')
        self.assertEqual((ROOT/'maps/JohtoRoute34IlexForestGate.blocked_mask.bin').read_bytes(),m)
        h=source('data/mapHeaders/JohtoRoute34.asm')
        self.assertIn('db $00',h) # Goldenrod, Azalea connections NOT opened

    def test_gate_neutral_only(self):
        a=source('engine/overworld/map_name_sign.asm').rsplit('.IsNeutralMap\n',1)[1].split('.NeutralMapList')[0]
        self.assertIn('cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID',a)
        self.assertNotIn('cp JOHTO_ROUTE_34_LOCAL_ID',a)
        self.assertIn('cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',a)

    def test_source_pixel_palette_exact(self):
        a,converted=build_mapping(ROOT,GOLD,'Route34IlexForestGate','gate','johto_gate')
        self.assertEqual(a['exact_mapped'],9)
        self.assertEqual(a['unmapped'],[])
        self.assertEqual((ROOT/'maps/JohtoRoute34IlexForestGate.blk').stat().st_size,20)
        self.assertIsNotNone(converted)
        # New slots are above the 23 old slots; old compact IDs preserved.
        self.assertEqual((ROOT/'gfx/blocksets/johto_gate.bst').stat().st_size,19*16)
        pal=source('color/tilesets/johto_gate.asm')
        self.assertEqual(len(re.findall('tilepal 0,',pal)),12)

    def test_kanto_rgb_unchanged(self):
        # Gold expansion does not alter general Kanto 'gate' palette, tileset or collisions.
        for f in ('gfx/tilesets/gate.tilecoll', 'gfx/tilesets/gate.t1.png',
                  'gfx/blocksets/gate.bst','color/tilesets/gate.asm','color/data/map_palettes.asm'):
            self.assertTrue((ROOT/f).is_file())
        self.assertIn('JohtoGate_Block,   JohtoGate_GFX,   Gate_Coll',source('data/tileset_headers.asm'))
        self.assertIn('JohtoRoute34GateCanStepAhead',source('home/overworld.asm'))

    def test_old_gate_and_ledges_unchanged(self):
        a=source('engine/overworld/ledges.asm')
        self.assertIn('JohtoIlexForestLedgeTiles',a)
        self.assertIn('.ilexForest',a)
        self.assertIn('JohtoIlexAzaleaGateObject:',source('data/mapObjects/JohtoIlexAzaleaGate.asm'))
        self.assertIn('JohtoRoute31VioletGateObject:',source('data/mapObjects/JohtoRoute31VioletGate.asm'))
        self.assertIn('JohtoRoute31VioletGate_h:',source('data/mapHeaders/JohtoRoute31VioletGate.asm'))
        self.assertEqual([(w['x'],w['y']) for w in rpp_warps(ROOT,'JohtoIlexAzaleaGate')],
                         [(9,4),(9,5),(0,4),(0,5)])

if __name__=='__main__':unittest.main()
