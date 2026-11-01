"""FIX-302 regression, now sharing REF-303 target-carpet ASM and profile table."""
from __future__ import annotations
import os
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gatehouse_behavior_audit import _constants, audit_active_gatehouse_carpet_walkability
from johto_gatehouse_shared_runtime_303 import scan, evaluate, structural_check
GOLD=Path(os.environ['JOHTO_GOLD_SOURCE']) if os.environ.get('JOHTO_GOLD_SOURCE') else None

class GateCarpet302(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.constants=_constants(ROOT)
        cls.west=(ROOT/'engine/johto_south_geometry.asm').read_text()
        cls.east=(ROOT/'data/johto_east_runtime_300.asm').read_text()

    def test_shared_runtime_and_exact_profiles(self):
        self.assertTrue(structural_check(self.west,self.east,self.east,self.constants))
        for gate,filename in ((23,'Route38EcruteakGate'),(62,'Route42EcruteakGate')):
            roles=(ROOT/'maps/johto_pilot'/f'{filename}.roles.bin').read_bytes()
            count,errs=scan(self.east,self.constants,gate,roles)
            self.assertEqual(172,count)
            self.assertEqual([],errs)

    def test_profile_lookup_is_map_specific(self):
        for invalid in (0,6,11,13,18,19,102,104,105,255):
            got=evaluate(self.east,self.constants,invalid,0,3,'DOWN')
            self.assertEqual((1,False),got)

    def test_inbound_lane_switch_and_solid_wall(self):
        for gate in (23,62):
            for x in (0,9):
                for y,d in ((3,'DOWN'),(4,'DOWN'),(5,'UP'),(6,'UP')):
                    self.assertEqual((0,True),evaluate(self.east,self.constants,gate,x,y,d))
            self.assertEqual((1,False),evaluate(self.east,self.constants,gate,2,3,'DOWN'))

    def test_negative_profile_drift_is_caught(self):
        for gate,symbol in ((23,'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID'),
                            (62,'JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID')):
            broken=self.east.replace(f'db {symbol}, 0, 9, 4, 5',f'db {symbol}, 0, 8, 4, 5',1)
            self.assertNotEqual(self.east,broken)
            roles=(ROOT/'maps/johto_pilot'/(( 'Route38EcruteakGate' if gate==23 else 'Route42EcruteakGate')+'.roles.bin')).read_bytes()
            _,failures=scan(broken,self.constants,gate,roles)
            self.assertTrue(failures)

    def test_negative_branch_drift_is_caught(self):
        broken=self.east.replace('    cp PLAYER_DIR_DOWN\n    jr z, .down',
                                  '    cp PLAYER_DIR_DOWN\n    jr z, .up',1)
        self.assertNotEqual(broken,self.east)
        roles=(ROOT/'maps/johto_pilot/Route42EcruteakGate.roles.bin').read_bytes()
        _,errs=scan(broken,self.constants,62,roles)
        self.assertTrue(any('DOWN' in e for e in errs),errs)

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_gatehouse_profile_registry_fault_injections(self):
        import json
        relative='tools/johto_gatehouse_profiles_303.json'
        source=(ROOT/relative).read_text()
        data=json.loads(source)
        # No park cycling, no swapped collision strategies and no missing IDs.
        for mutate in ('park_bike', 'backend', 'missing'):
            bad=json.loads(source)
            if mutate=='park_bike':
                next(r for r in bad['active_gatehouses'] if r['stable_id']==105)['bike_allowed']=True
            elif mutate=='backend':
                next(r for r in bad['active_gatehouses'] if r['stable_id']==23)['collision_strategy']='legacy_gate_tilecoll'
            else:
                bad['active_gatehouses']=[r for r in bad['active_gatehouses'] if r['stable_id']!=62]
            report=audit_active_gatehouse_carpet_walkability(
                ROOT,GOLD,text_overrides={relative:json.dumps(bad)})
            with self.subTest(mutation=mutate):
                self.assertEqual('FAIL',report['status'])
                self.assertTrue(report['errors'])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_all_active_gates_static_contracts(self):
        result=audit_active_gatehouse_carpet_walkability(ROOT,GOLD)
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result['errors'])
        self.assertEqual((10,32),(result['gatehouses_checked'],result['carpets_checked']))
        self.assertEqual({23:172,62:172},result['source_simulated_moves'])

if __name__=='__main__': unittest.main()
