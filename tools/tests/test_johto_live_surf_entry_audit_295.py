"""FIX-295 negative Surf runtime-path checks; Gold sourced, no ROM link."""
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_live_surf_entry_audit_295 import audit, SURF, ENTRY, ITEMS, SPATIAL
GOLD=Path(__import__('os').environ.get('GOLD_SOURCE_ROOT') or
          __import__('os').environ.get('JOHTO_GOLD_SOURCE') or '/mnt/data/reference/REFERENCES/Gold/pokegold-master')
@unittest.skipUnless(GOLD.is_dir(),'Full Gold original required for all-active-map water audit')
class SurfLive295(unittest.TestCase):
    def check_mutation(self,rel,before,after,expected):
        s=(ROOT/rel).read_text(encoding='utf8')
        self.assertIn(before,s)
        result=audit(ROOT,GOLD,{rel:s.replace(before,after,1)})
        self.assertEqual(result['status'],'FAIL',result)
        self.assertTrue(any(expected in x for x in result['errors']),result)
    def test_complete_chain(self):
        result=audit(ROOT,GOLD)
        self.assertEqual(result['status'],'PASS_STATIC_ONLY',result)
        self.assertEqual({row['map'] for row in result['role_backed_pilot_water_maps']},
                         {'EcruteakCity','Route35'})
    def test_ecruteak_movement_missing(self):
        self.check_mutation(SURF,'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .southModern',
                            'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .legacy',
                            'EcruteakCity: WATER role present')
    def test_route35_movement_missing(self):
        self.check_mutation(SURF,'cp JOHTO_ROUTE_35_LOCAL_ID\n    jp z, .southModern',
                            'cp JOHTO_ROUTE_35_LOCAL_ID\n    jp z, .legacy',
                            'Route35: WATER role present')
    def test_false_comment_not_sufficient(self):
        s=(ROOT/SURF).read_text(); self.assertIn('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID',s)
        modified=s.replace('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .southModern',
                           'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .legacy\n; cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n; jp z, .southModern')
        result=audit(ROOT,GOLD,{SURF:modified})
        self.assertTrue(any('EcruteakCity: WATER role present' in x for x in result['errors']), result)
    def test_unreachable_branch_after_fallback(self):
        s=(ROOT/SURF).read_text()
        branch='    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .southModern\n'
        self.assertIn(branch,s)
        altered=s.replace(branch,'',1).replace('\tjp .legacy\n.violet',
              '\tjp .legacy\n'+branch+'.violet',1)
        result=audit(ROOT,GOLD,{SURF:altered})
        self.assertTrue(any('EcruteakCity: WATER role present' in x for x in result['errors']),result)
    def test_entry_a_button(self):
        self.check_mutation(ENTRY,'callab JohtoVioletWaterAhead\n\tret c',
                            'callab JohtoVioletWaterAhead\n\tret nc',
                            'IsSurfTile: A-button')
    def test_entry_item(self):
        self.check_mutation(ITEMS,'callab JohtoVioletWaterAhead\n\tjr c, .shoreOrWater',
                            'callab JohtoVioletWaterAhead\n\tjr nc, .shoreOrWater',
                            'Surfboard/item water entry missing')
    def test_entry_water_probe(self):
        self.check_mutation(SURF,'callab JohtoSouthGoldWaterProbe\n    ret c',
                            'callab JohtoSouthGoldWaterProbe\n    ret nc',
                            'shared Gold water probe not reachable')
    def test_water_move_probe(self):
        self.check_mutation(SURF,'callab JohtoSouthGoldWaterProbe\n    jp c, .water',
                            'callab JohtoSouthGoldWaterProbe\n    jp nc, .water',
                            'Gold water and safe shore branch broken')
    def test_shore_probe(self):
        self.check_mutation(SURF,'callab JohtoSouthGoldShoreProbe\n    jp c, .floorShore',
                            'callab JohtoSouthGoldShoreProbe\n    jp nc, .floorShore',
                            'Gold water and safe shore branch broken')
    def test_spatial_water_probe(self):
        self.check_mutation(SPATIAL,'JohtoSouthGoldWaterProbe::\n    push bc\n    push de\n    push hl\n    call JohtoSouthSpatialRoleAhead\n    ld a, e\n    cp 2',
                            'JohtoSouthGoldWaterProbe::\n    push bc\n    push de\n    push hl\n    call JohtoSouthSpatialRoleAhead\n    ld a, e\n    cp 1',
                            'JohtoSouthGoldWaterProbe: missing live role=2')
if __name__=='__main__': unittest.main()
