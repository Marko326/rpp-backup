"""Gold-backed AzaleaTown map onboarding and negative source checks.

No emulator or ROM compilation. These are independent, fail-closed
source/connection regression checks and cannot certify phone behavior.
"""
from pathlib import Path
import os
import sys
import tempfile
import shutil
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_indoor_collision_adapter import plan_gold_quadrant_collision
from johto_rpp_connection_guard import audit as connection_audit


class AzaleaRuntime195(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
        if not (cls.gold / 'maps/AzaleaTown.blk').is_file():
            raise AssertionError('Gold full source required')

    def test_original_map_and_position_mask(self):
        self.assertEqual((ROOT / 'maps/JohtoAzaleaTown.blk').read_bytes(),
                         (self.gold / 'maps/AzaleaTown.blk').read_bytes())
        r,mask=plan_gold_quadrant_collision(self.gold,'AzaleaTown','johto_modern')
        self.assertEqual((r['width_cells'], r['height_cells'], len(mask)),(40,18,90))
        self.assertEqual((r['blocked_count'],r['walkable_count']),(447,273))
        self.assertEqual(mask, (ROOT / 'maps/JohtoAzaleaTown.blocked_mask.bin').read_bytes())
        self.assertEqual(len(r['hops']),9)
        self.assertEqual([(v['x'],v['y']) for v in r['unsafe_hop_candidates']],[(10,6)])

    def test_both_gold_edges_and_registered_targets(self):
        for edge in [('JohtoRoute33','JohtoAzaleaTown','Route33','AzaleaTown','west'),
                     ('JohtoAzaleaTown','JohtoRoute33','AzaleaTown','Route33','east')]:
            observed = connection_audit(ROOT,self.gold,*edge)
            self.assertEqual(observed['status'],'PASS',observed)
        mapping=(ROOT / 'engine/overworld/region_map_lookup.asm').read_text()
        self.assertIn('db JOHTO_ROUTE_33_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID',mapping)
        self.assertIn('db JOHTO_AZALEA_TOWN_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',mapping)

    def test_cross_tileset_existing_path_and_modern_fast_path(self):
        code=(ROOT/'home/overworld.asm').read_text()
        section=code.split('.loadNewMap ; load the connected map that was entered',1)[1].split('.didNotEnterConnectedMap',1)[0]
        self.assertIn('ld a, [wCurMapTileset]\n\tcp JOHTO_MODERN\n\tjr z, .ordinaryConnection',section)
        self.assertIn('jp z, .route33TilesetReload',section)
        self.assertIn('cp JOHTO_MODERN\n\tjp z, .route33TilesetReload',code)

    def test_unopened_interior_warps_stay_closed(self):
        data=(ROOT/'data/mapObjects/JohtoAzaleaTown.asm').read_text()
        self.assertIn('db $00 ; no interior/Well/forest Warps opened',data)
        geo,_=plan_gold_quadrant_collision(self.gold,'AzaleaTown','johto_modern')
        specials={(s['x'],s['y'],s['role']) for s in geo['special_cells']}
        self.assertIn((31,7,'CAVE'),specials)
        self.assertIn((9,5,'DOOR'),specials)
        self.assertIn('db $01 ; Union Cave 1F entry',
                      (ROOT/'data/mapObjects/JohtoRoute33.asm').read_text())

    def test_map_edge_guards_and_safe_hops(self):
        code=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        section=code.split('JohtoAzaleaEdgeFence::',1)[1].split('JohtoRoute33CanStepAhead::',1)[0]
        self.assertIn('cp 14',section)
        self.assertIn('cp 16',section)
        self.assertIn('Route34 remains closed',section)
        self.assertIn('JohtoAzaleaBlockedRows::\n\tINCBIN "maps/JohtoAzaleaTown.blocked_mask.bin"',code)
        ledges=(ROOT/'engine/overworld/ledges.asm').read_text()
        rows=ledges.split('\n.azaleaHops\n',1)[1].split('db $ff',1)[0]
        self.assertEqual(rows.count('PLAYER_DIR_DOWN'),9)
        self.assertNotIn('db 10, 6, PLAYER_DIR_DOWN',rows)

    def test_bad_east_connection_width_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            # Copy the minimum source contract required by the existing
            # generic checker; no duplicate connection arithmetic here.
            root=Path(folder)
            required=('constants/map_constants.asm','constants/region_map_constants.asm',
                      'data/johto_map_headers.asm','data/mapHeaders/JohtoAzaleaTown.asm',
                      'data/mapHeaders/JohtoRoute33.asm','maps/JohtoAzaleaTown.blk',
                      'maps/JohtoRoute33.blk')
            for rel in required:
                target=root/rel;target.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,target)
            header=root/'data/mapHeaders/JohtoAzaleaTown.asm'
            text=header.read_text()
            self.assertIn('db JOHTO_ROUTE_33_HEIGHT',text)
            header.write_text(text.replace('db JOHTO_ROUTE_33_HEIGHT',
                                           'db JOHTO_ROUTE_33_HEIGHT + 1',1))
            result=connection_audit(root,self.gold,'JohtoAzaleaTown','JohtoRoute33',
                                    'AzaleaTown','Route33','east')
            self.assertEqual(result['status'],'FAIL',result)


if __name__=='__main__':
    unittest.main()
