"""REF-338 Surf/forest border bug: full Gold active-map negative tests."""
from __future__ import annotations
import os, sys, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gold_outdoor_border_audit_339 import audit
GOLD=Path(os.environ.get('GOLD_SOURCE_ROOT','/mnt/data/ref338_visual_sources'))

@unittest.skipUnless((GOLD/'data/maps/attributes.asm').exists(),'requires real Gold attributes')
class ActiveGoldBorders339(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.clean=audit(ROOT,GOLD)
    def check_mutation(self,path,old,new,expected_map):
        src=(ROOT/path).read_text()
        self.assertEqual(src.count(old),1,path)
        result=audit(ROOT,GOLD,{path:src.replace(old,new,1)})
        self.assertEqual('FAIL',result['status'])
        self.assertTrue(any(expected_map+':' in e for e in result['errors']),result['errors'])
    def test_full_57_active_maps_and_all_shared_borders(self):
        r=self.clean
        self.assertEqual('PASS_STATIC_ONLY',r['status'],r['errors'])
        self.assertEqual(57,r['active_maps'])
        self.assertEqual(57,len(r['rows']))
        self.assertGreaterEqual(r['outdoor_shared_count'],25)
        self.assertTrue(all(row['verdict']=='PASS' for row in r['rows'] if row['tileset']=='JOHTO_PILOT'))
    def test_cherrygrove_142_surf_viewports_in_block_buffer(self):
        r=self.clean
        self.assertEqual(142,r['water_viewports'])
        self.assertEqual(4260,r['viewport_blocks'])
        self.assertGreater(r['outside_viewport_blocks'],700)
        self.assertEqual('$35',next(x for x in r['rows'] if x['map']=='CherrygroveCity')['runtime_border'])
    def test_all_six_previous_wrong_borders_rejected(self):
        cases=[
            ('data/johto_pilot_map_headers.asm','JohtoPilotCherrygroveRuntimeObjects::\n    db $35','JohtoPilotCherrygroveRuntimeObjects::\n    db $05','CherrygroveCity'),
            ('data/johto_west_runtime_297.asm','JohtoOlivineRuntimeObjects::\n    db $35','JohtoOlivineRuntimeObjects::\n    db $05','OlivineCity'),
            ('data/johto_west_sea_runtime_299.asm','JohtoRoute40RuntimeObjects::\n    db $35','JohtoRoute40RuntimeObjects::\n    db $05','Route40'),
            ('data/johto_west_sea_runtime_299.asm','JohtoRoute41RuntimeObjects::\n    db $35','JohtoRoute41RuntimeObjects::\n    db $05','Route41'),
            ('data/johto_west_sea_runtime_299.asm','JohtoCianwoodRuntimeObjects::\n    db $35','JohtoCianwoodRuntimeObjects::\n    db $05','CianwoodCity'),
            ('data/johto_east_runtime_300.asm','JohtoMahoganyRuntimeObjects::\n    db $71','JohtoMahoganyRuntimeObjects::\n    db $05','MahoganyTown'),
        ]
        for args in cases:
            with self.subTest(map=args[-1]): self.check_mutation(*args)
    def test_mature_ilex_border_cannot_be_replaced_by_raw_gold_id(self):
        self.check_mutation('data/johto_south_runtime.asm',
            'JohtoSouthIlexForestRuntimeObjects::\n    db $00',
            'JohtoSouthIlexForestRuntimeObjects::\n    db $05','IlexForest')
    def test_map_background_fill_source_is_required(self):
        path='home/overworld.asm';src=(ROOT/path).read_text()
        self.assertIn('ld a,[wMapBackgroundTile]',src)
        result=audit(ROOT,GOLD,{path:src.replace('ld a,[wMapBackgroundTile]','xor a ; broken fill',1)})
        self.assertIn('out-of-map border fill or post-load renderer changed',result['errors'])
    def test_none_of_existing_surf_contracts_or_existing_center_tables_changed(self):
        self.assertEqual('PASS_STATIC_ONLY',self.clean['status'])
        for name in ['Route29','Route30','Route31','Route32','VioletCity','Route34','Route35','Route42','Route43','Route44','BlackthornCity']:
            row=next(x for x in self.clean['rows'] if x['map']==name)
            self.assertIn(row['verdict'],('PASS','REMAP_IDENTICAL'),name)

if __name__=='__main__':unittest.main()
