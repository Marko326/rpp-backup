"""Reject ROM0 growth via per-map native doorway identity branches."""
from pathlib import Path
import os, sys, unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import audit, predicate

class Rom0RuinsRelief224(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold=Path(os.environ['JOHTO_GOLD_SOURCE'])
    def test_home_dispatch_is_shared_and_no_local_id_chain(self):
        home=(ROOT/'home/overworld.asm').read_text()
        extra=home.split('ExtraWarpCheck::',1)[1].split('IsJohtoSouthGatePortal::',1)[0]
        self.assertIn('cp REGION_NATIVE_MAP_SLOT',extra)
        self.assertIn('cp MAP_REGION_JOHTO',extra)
        self.assertIn('callba JohtoInternalDoorFacingCheck',extra)
        self.assertLess(extra.index('cp MAP_REGION_JOHTO'),extra.index('callba JohtoInternalDoorFacingCheck'))
        self.assertLess(extra.index('callba JohtoInternalDoorFacingCheck'),extra.index('\n.ordinaryCheck\n'))
        self.assertNotIn('cp JOHTO_',extra.split('\n.ordinaryCheck\n',1)[0], 'ROM0 must not grow an exact-map chain again')
        romx=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text().split('JohtoInternalDoorFacingCheck::',1)[1].split('JohtoRuinsCanStepAhead::',1)[0]
        for name in ('JOHTO_ILEX_FOREST_LOCAL_ID','JOHTO_ROUTE_34_LOCAL_ID','JOHTO_GOLDENROD_CITY_LOCAL_ID','JOHTO_ROUTE_35_LOCAL_ID','JOHTO_ROUTE_36_LOCAL_ID','JOHTO_RUINS_OF_ALPH_LOCAL_ID'):
            self.assertIn('cp '+name,romx)
        self.assertIn('.denied\n\tand a\n\tret',romx)

    def test_unrelated_johto_maps_cannot_become_doors(self):
        # HOME now calls the ROMX predicate for every Johto-native map.
        # Denial for all other local maps is essential, not assumed.
        romx=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        for map_id in ('JOHTO_NEW_BARK_TOWN_LOCAL_ID',
                       'JOHTO_ROUTE_29_LOCAL_ID', 'JOHTO_ROUTE_31_LOCAL_ID',
                       'JOHTO_ROUTE_32_LOCAL_ID', 'JOHTO_ROUTE_33_LOCAL_ID',
                       'JOHTO_ROUTE_35_GOLDENROD_GATE_LOCAL_ID',
                       'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'):
            for direction in ('UP','DOWN','LEFT','RIGHT'):
                self.assertFalse(predicate(romx, 'JohtoInternalDoorFacingCheck',
                                           map_id, 7, 5, direction),
                                 (map_id, direction))
    def test_actual_contracts_still_pass(self):
        self.assertEqual([],audit(ROOT,self.gold))
    def test_removing_dispatch_cannot_pass(self):
        key='home/overworld.asm'
        source=(ROOT/key).read_text()
        self.assertIn('callba JohtoInternalDoorFacingCheck',source)
        damaged=source.replace('callba JohtoInternalDoorFacingCheck','xor a\n\tret',1)
        errors=audit(ROOT,self.gold,{key:damaged})
        self.assertTrue(any('outside doorway facing executor' in e for e in errors),errors)
