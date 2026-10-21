"""Independent Gold-backed regression contract for native Route38 / west gate.

Does not build ROM, trigger a phone Warp, or approve a missing Gold feature.
"""
import json
import os
from pathlib import Path
import re
import unittest

from johto_gatehouse_behavior_audit import object_warps, predicate
from johto_map_release_audit import audit_new_native_field_move_roles
from johto_indoor_tiles_converter import build_mapping
from johto_indoor_collision_adapter import plan_gold_quadrant_collision

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/nonexistent'))

def read(path):
    return (ROOT / path).read_text()


class WestRoute38Gate228(unittest.TestCase):
    def setUp(self):
        self.assertTrue((GOLD / 'maps/Route38EcruteakGate.asm').is_file(), 'Gold source is mandatory')

    def test_gold_warp_geometry_and_native_graph(self):
        ids = [('JohtoRoute38', 'Route38', [(8, 35, 0), (9, 35, 1)]),
               ('JohtoEcruteakCity', 'EcruteakCity', [(18, 0, 2), (19, 0, 3)]),
               ('JohtoRoute38EcruteakGate', 'Route38EcruteakGate',
                [(4, 0, 0), (5, 0, 1), (4, 9, 0), (5, 9, 1)])]
        for stem, gold, expected in ids:
            actual = object_warps(read(f'data/mapObjects/{stem}.asm'), stem)
            for y, x, slot in expected:
                self.assertIn((y, x, slot, 'REGION_WARP_ESCAPE'), actual)
            source = (GOLD / 'maps' / (gold + '.asm')).read_text()
            goldcells = {(int(y), int(x)) for x, y in re.findall(r'(?m)^\s*warp_event\s+(\d+),\s*(\d+),', source)}
            for y, x, _ in expected:
                self.assertIn((y, x), goldcells)
        source = read('engine/overworld/region_map_lookup.asm')
        rows = re.findall(r'(?m)^\s*db\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)', source)
        actual = {(a, int(b), int(c), d) for a, b, c, d in rows}
        gate = 'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID'
        expected = {(src, a, b, dst) for src, a, b, dst in [
            ('JOHTO_ROUTE_38_LOCAL_ID',0,0,gate), ('JOHTO_ROUTE_38_LOCAL_ID',1,1,gate),
            ('JOHTO_ECRUTEAK_CITY_LOCAL_ID',0,2,gate), ('JOHTO_ECRUTEAK_CITY_LOCAL_ID',1,3,gate),
            (gate,0,0,'JOHTO_ROUTE_38_LOCAL_ID'),(gate,1,1,'JOHTO_ROUTE_38_LOCAL_ID'),
            (gate,2,0,'JOHTO_ECRUTEAK_CITY_LOCAL_ID'),(gate,3,1,'JOHTO_ECRUTEAK_CITY_LOCAL_ID')]}
        self.assertEqual({row for row in actual if row[0] == gate or row[3] == gate}, expected)

    def test_four_direction_gate_predictions(self):
        source = read('engine/overworld/johto_route33_collision.asm')
        for local, x, ys, expect in [
            ('JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID',0,(4,5),'LEFT'),
            ('JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID',9,(4,5),'RIGHT'),
            ('JOHTO_ROUTE_38_LOCAL_ID',35,(8,9),'RIGHT'),
            ('JOHTO_ECRUTEAK_CITY_LOCAL_ID',0,(18,19),'LEFT')]:
            for y in ys:
                for direction in ('LEFT','RIGHT','UP','DOWN'):
                    self.assertEqual(predicate(source,'JohtoGateCollisionDirectionAllowed',local,x,y,direction),direction==expect)
                    self.assertFalse(predicate(source,'JohtoNorthGateStepWarpAllowed',local,x,y,direction))
        self.assertIn('JohtoRoute38CanStepAhead::',source)
        self.assertIn('JohtoRoute38EcruteakGateCanStepAhead::',source)

    def test_no_unwanted_arrival_step_profiles(self):
        source=read('engine/overworld/region_map_lookup.asm')
        profiles=source.split('.profiles',1)[-1].split('; Native cave entrances',1)[0]
        self.assertNotIn('JOHTO_ROUTE_38_LOCAL_ID', profiles)
        self.assertNotIn('JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID', profiles)
        # Ecruteak is a preexisting destination with a separate Fly position.
        self.assertIn('GetJohtoWarpArrivalStep',source)

    def test_route38_edge_and_visual_connections(self):
        city=read('data/mapHeaders/JohtoEcruteakCity.asm')
        road=read('data/mapHeaders/JohtoRoute38.asm')
        self.assertIn('db SOUTH | WEST',city)
        self.assertIn('db WEST | EAST',road)
        self.assertIn('JohtoRoute39Blocks + JOHTO_ROUTE_39_WIDTH - 3',road)
        self.assertIn('JohtoRoute38Blocks + JOHTO_ROUTE_38_WIDTH - 3',city)
        self.assertIn('JohtoEcruteakCityBlocks + JOHTO_ECRUTEAK_CITY_WIDTH * 5',road)
        source=read('engine/overworld/johto_route33_collision.asm')
        self.assertIn('JohtoRoute38EdgeFence::',source)
        self.assertIn('JohtoEcruteakCityEdgeFence::',source)
        self.assertIn('JohtoRoute38BlockedRows::',source)
        self.assertIn('JohtoRoute38EcruteakGateBlockedRows::',source)
        self.assertIn('maps/JohtoRoute38.blocked_mask.bin',source)
        self.assertEqual((ROOT/'maps/JohtoRoute38.blocked_mask.bin').stat().st_size,90)
        self.assertEqual((ROOT/'maps/JohtoRoute38EcruteakGate.blocked_mask.bin').stat().st_size,16)
        self.assertEqual(read('data/mapObjects/JohtoRoute38.asm').count('REGION_WARP_ESCAPE'),2)

    def test_neutral_gate_sign_only(self):
        source=read('engine/overworld/map_name_sign.asm')
        section=source.split('\n.IsNeutralMap\n',1)[-1].split('\n.legacyMap\n',1)[0]
        self.assertIn('cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID\n\tret z',section)
        self.assertNotIn('cp JOHTO_ROUTE_38_LOCAL_ID',section)
        self.assertNotIn('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID',section)

    def test_gate_pixel_exact_and_route38_layout(self):
        mapping, candidate = build_mapping(ROOT,GOLD,'Route38EcruteakGate','gate','johto_gate')
        self.assertEqual(mapping['unmapped'],[])
        self.assertEqual(candidate,(ROOT/'maps/JohtoRoute38EcruteakGate.blk').read_bytes())
        self.assertEqual(len(candidate),20)
        original = (GOLD/'maps/Route38.blk').read_bytes()
        road = (ROOT/'maps/JohtoRoute38.blk').read_bytes()
        self.assertEqual(len(road),180)
        self.assertEqual(road,original)  # no unofficial graphic remapping
        gold_geom, gold_mask = plan_gold_quadrant_collision(GOLD,'Route38','johto',walkable_roles=json.loads(read('tools/johto_gold_geometry_contracts.json'))['maps'][-1]['walkable_roles'])
        self.assertEqual(gold_mask,(ROOT/'maps/JohtoRoute38.blocked_mask.bin').read_bytes())
        self.assertEqual(gold_geom['unsafe_hop_candidates'],[])

    def test_gate_palette_not_changed_for_kanto(self):
        # Gate uses JOHTO_GATE, not the shared Kanto GATE blockset or palettes.
        self.assertIn('db JOHTO_GATE',read('data/mapHeaders/JohtoRoute38EcruteakGate.asm'))
        ref=read('data/mapHeaders/JohtoRoute31VioletGate.asm')
        self.assertIn('db JOHTO_GATE',ref)
        self.assertTrue((ROOT/'gfx/blocksets/gate.bst').is_file())
        self.assertTrue((ROOT/'gfx/blocksets/johto_gate.bst').is_file())

    def test_original_older_gate_contracts_preserved(self):
        assert_files=['data/mapHeaders/JohtoRoute31VioletGate.asm',
                      'data/mapObjects/JohtoRoute31VioletGate.asm',
                      'data/mapHeaders/JohtoRoute35GoldenrodGate.asm',
                      'data/mapObjects/JohtoRoute35GoldenrodGate.asm']
        for path in assert_files:
            self.assertIn('Object',read(path))
        source=read('engine/overworld/johto_route33_collision.asm')
        for sym in ('JohtoGateCollisionDirectionAllowed::','JohtoNorthGateStepWarpAllowed::',
                    'JohtoRoute35CanStepAhead::','JohtoRoute34GateCanStepAhead::'):
            self.assertIn(sym,source)

    def test_gold_headbutt_deferred_exact_cell_contract(self):
        entries=json.loads(read('tools/johto_native_maps.json'))['maps']
        expected=entries[24]['deferred_gold_moves']['headbutt_tree_yx']
        self.assertEqual(len(expected),24)
        from johto_gold_cells import decode_cells
        cells=decode_cells((GOLD/'maps/Route38.blk').read_bytes(),
            (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
            (GOLD/'data/tilesets/johto_collision.asm').read_text(),20,9)
        self.assertEqual(expected,[[c['y'],c['x']] for c in cells if c['role']=='HEADBUTT_TREE'])
        self.assertFalse([issue for issue in audit_new_native_field_move_roles(ROOT,GOLD) if issue.startswith('Route38:')])
        # Negative proof: removing one Gold cell from the deferred list fails closed.
        from unittest.mock import patch
        original=json.loads(read('tools/johto_native_maps.json'))
        original['maps'][24]['deferred_gold_moves']['headbutt_tree_yx']=expected[:-1]
        orig_read=Path.read_text
        def fake_read(path,*args,**kwargs):
            if str(path).endswith('/tools/johto_native_maps.json'):
                return json.dumps(original)
            return orig_read(path,*args,**kwargs)
        with patch.object(Path,'read_text',fake_read):
            issues=audit_new_native_field_move_roles(ROOT,GOLD)
        self.assertTrue(any('DEFERRED Headbutt coordinates differ from Gold' in issue for issue in issues))

    def test_no_new_headbutt_or_surf_permission(self):
        status=json.loads(read('tools/johto_native_maps.json'))['maps'][24]['feature_status']
        self.assertEqual(status['surf'],'DEFERRED')
        self.assertEqual(status['cut'],'DEFERRED')
        self.assertNotIn('JOHTO_ROUTE_38_LOCAL_ID',read('engine/overworld/johto_union_cave_surf.asm'))
        source=read('engine/overworld/ledges.asm')
        self.assertIn('.route38Hops',source)
        self.assertEqual(source.split('\n.route38Hops\n',1)[1].split('db $ff',1)[0].count('PLAYER_DIR_'),24)

if __name__=='__main__':
    unittest.main()
