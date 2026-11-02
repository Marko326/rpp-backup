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
from johto_gatehouse_step_trace_308 import simulate_park_east, simulate_south_gate
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
        for invalid in (0,6,11,13,18,19,65,74,102,104,105,255):
            got=evaluate(self.east,self.constants,invalid,0,3,'DOWN')
            self.assertEqual((1,False),got)

    def test_inbound_lane_switch_and_solid_wall(self):
        for gate in (23,62):
            for x in (0,9):
                for y,d in ((3,'DOWN'),(4,'DOWN'),(5,'UP'),(6,'UP')):
                    self.assertEqual((0,True),evaluate(self.east,self.constants,gate,x,y,d))
            self.assertEqual((1,False),evaluate(self.east,self.constants,gate,2,3,'DOWN'))

    def test_shared_10x8_gate_role_dimensions_and_park_exception(self):
        # Compact only the repeated role-grid dimensions in Bank $4E.
        # Neither the gate's own HL pointer nor its collision backend changes.
        for label, symbol in (
            ('.IlexForestAzaleaGate', 'JohtoSouthIlexForestAzaleaGateRoles'),
            ('.Route34IlexForestGate', 'JohtoSouthRoute34IlexForestGateRoles'),
            ('.Route35Gate', 'JohtoNorthRoute35GoldenrodGateRoles'),
            ('.Route38Gate', 'JohtoRoute38EcruteakGateRoles'),
        ):
            with self.subTest(gate=label):
                self.assertIn(f'{label}\n    ld hl, {symbol}\n    jp .gate10x8\n', self.west)
        self.assertIn('.EastParkGate\n    ld hl, JohtoParkEastGateRoles\n', self.west)
        self.assertIn('.gate10x8\n    ld b, 10\n    ld c, 8\n\n.common', self.west)
        # Park South is genuinely 8x8: never send it through the 10x8 tail.
        self.assertIn('.SouthParkGate\n    ld hl, JohtoParkSouthGateRoles\n'
                      '    ld b, 8\n    ld c, 8\n    jp .common', self.west)

    def test_shared_10x8_wrong_width_is_detected_by_real_asm_trace(self):
        source=self.west
        broken=source.replace('.gate10x8\n    ld b, 10', '.gate10x8\n    ld b, 9', 1)
        self.assertNotEqual(broken,source)
        roles=(ROOT/'maps/johto_pilot/IlexForestAzaleaGate.roles.bin').read_bytes()
        args=dict(constants=self.constants,gate_id=11,x=8,y=1,
                  direction='RIGHT',roles=roles)
        # Target (9,1) is a wall, not an off-map cell; a width of 9 would
        # accidentally return E=0 via the existing off-map handoff.
        self.assertEqual(1,simulate_south_gate(source,**args))
        self.assertEqual(0,simulate_south_gate(broken,**args))
        if GOLD is not None:
            report=audit_active_gatehouse_carpet_walkability(
                ROOT,GOLD,text_overrides={'engine/johto_south_geometry.asm':broken})
            self.assertEqual('FAIL',report['status'])
            self.assertTrue(any('ID11' in err and 'source trace' in err
                                for err in report['errors']),report['errors'][:10])

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

    def test_park_east_real_asm_lane_swaps_and_walls(self):
        mask=(ROOT/'maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin').read_bytes()
        for x in (0,9):
            for y,d in ((4,'DOWN'),(5,'UP')):
                self.assertEqual(0,simulate_park_east(
                    self.west,constants=self.constants,x=x,y=y,
                    direction=d,mask=mask))
        for x,d in ((0,'LEFT'),(9,'RIGHT')):
            self.assertEqual(1,simulate_park_east(
                self.west,constants=self.constants,x=x,y=4,
                direction=d,mask=mask))
        self.assertEqual(1,simulate_park_east(
            self.west,constants=self.constants,x=5,y=1,
            direction='DOWN',mask=mask))  # park room counter

    def test_park_east_real_asm_fault_injection(self):
        mask=(ROOT/'maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin').read_bytes()
        segment=self.west.split('JohtoParkEastGateMatureStep::',1)[1].split('JohtoParkEastGateBlockedRows::',1)[0]
        self.assertIn('    cp 9\n    jr nz, .mask',segment)
        broken=self.west.replace(segment,segment.replace('    cp 9\n    jr nz, .mask',
                                                        '    cp 8\n    jr nz, .mask',1),1)
        self.assertNotEqual(self.west,broken)
        self.assertEqual(0,simulate_park_east(
            self.west,constants=self.constants,x=8,y=4,
            direction='RIGHT',mask=mask))
        self.assertEqual(1,simulate_park_east(
            broken,constants=self.constants,x=8,y=4,
            direction='RIGHT',mask=mask))

    def test_south_gate_real_asm_fault_injection(self):
        roles=(ROOT/'maps/johto_pilot/IlexForestAzaleaGate.roles.bin').read_bytes()
        needle='    cp PLAYER_DIR_DOWN\n    jp z, .south'
        self.assertIn(needle,self.west)
        broken=self.west.replace(needle,'    cp PLAYER_DIR_DOWN\n    jp z, .north',1)
        # Point (x5,y2) facing DOWN must consult row 3, not row 1.
        self.assertNotEqual(self.west,broken)
        from johto_gatehouse_behavior_audit import _audit_gatehouse_source_walk
        from johto_gold_door_audit import GoldCollisionIndex
        # The outer test also checks the expected Gold direction and target.
        checked, errors = _audit_gatehouse_source_walk(
            gold_index=GoldCollisionIndex(GOLD) if GOLD else None,
            gold_map='IlexForestAzaleaGate',stable_id=11,
            strategy='south_gold_role_grid',source=broken,
            constants=self.constants,
            read_bytes=lambda rel:(ROOT/rel).read_bytes(),
            blocked_targets=frozenset()) if GOLD else (0, [])
        if GOLD:
            self.assertEqual(172,checked)
            self.assertTrue(errors)
        else:
            # Without Gold source, at least prove it changes the actual ASM step.
            diffs=[]
            for y in range(1,7):
                for x in range(1,9):
                    a=simulate_south_gate(self.west,constants=self.constants,gate_id=11,
                                          x=x,y=y,direction='DOWN',roles=roles)
                    b=simulate_south_gate(broken,constants=self.constants,gate_id=11,
                                          x=x,y=y,direction='DOWN',roles=roles)
                    if a!=b:diffs.append((x,y))
            self.assertTrue(diffs)

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_source_trace_legacy_and_new_gate_counts(self):
        result=audit_active_gatehouse_carpet_walkability(ROOT,GOLD)
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result['errors'])
        self.assertEqual({6:172,11:172,13:218,18:218,19:218,65:218,66:218,74:218,
                          102:172,104:186,105:225},
                         {int(k):v for k,v in result['asm_traced_moves'].items()})

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_full_gate_audit_catches_changed_park_asm_not_just_mask(self):
        relative='engine/johto_south_geometry.asm'
        original=self.west
        segment=original.split('JohtoParkEastGateMatureStep::',1)[1].split('JohtoParkEastGateBlockedRows::',1)[0]
        needle='    cp 9\n    jr nz, .mask'
        self.assertIn(needle, segment)
        broken=original.replace(segment,segment.replace(needle,'    cp 8\n    jr nz, .mask',1),1)
        report=audit_active_gatehouse_carpet_walkability(
            ROOT,GOLD,text_overrides={relative:broken})
        self.assertEqual('FAIL',report['status'])
        self.assertTrue(any('ID105' in err and 'source trace' in err for err in report['errors']),
                        report['errors'][:10])

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
        self.assertEqual((13,38),(result['gatehouses_checked'],result['carpets_checked']))
        self.assertEqual({23:172,62:172},result['source_simulated_moves'])
        self.assertEqual({6:80,11:80,13:80,18:80,19:80,65:80,66:80,74:80,102:80,104:64,105:80},
                         result['data_decoded_cells'])
        self.assertEqual({6:172,11:172,13:218,18:218,19:218,65:218,66:218,74:218,102:172,104:186,105:225},
                         result['data_decoded_moves'])
        # The park south room is 8x8, not a stretched copy of the 10x8
        # east park gate; each one keeps its own original walkability data.
        self.assertNotEqual(result['data_decoded_cells'][104],result['data_decoded_cells'][105])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_legacy_gate_interior_floor_fault_is_detected(self):
        relative='gfx/tilesets/gate.tilecoll'
        source=(ROOT/relative).read_bytes()
        self.assertIn(0x02,source[:-1])
        # Unlike the old carpet-only check, this catches an internal floor
        # made solid while all 32 registered Warp carpets stay unchanged.
        broken=bytes(value for value in source if value != 0x02)
        report=audit_active_gatehouse_carpet_walkability(
            ROOT,GOLD,byte_overrides={relative:broken})
        self.assertEqual('FAIL',report['status'])
        self.assertTrue(any('ID6 Route31VioletGate' in e and 'full-grid' in e
                            for e in report['errors']),report['errors'][:10])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_south_gates_interior_floor_faults_are_detected(self):
        for name,gate,x,y in (('IlexForestAzaleaGate',11,5,2),
                                ('Route34IlexForestGate',13,5,3),
                                ('Route35NationalParkGate',104,6,2)):
            relative=f'maps/johto_pilot/{name}.roles.bin'
            source=bytearray((ROOT/relative).read_bytes())
            width=8 if gate==104 else 10
            self.assertEqual(0,source[y*width+x])
            source[y*width+x]=1
            report=audit_active_gatehouse_carpet_walkability(
                ROOT,GOLD,byte_overrides={relative:bytes(source)})
            with self.subTest(gate=gate):
                self.assertEqual('FAIL',report['status'])
                self.assertTrue(any(f'ID{gate} {name}: full-grid cell ({x},{y})' in e
                                    for e in report['errors']),report['errors'][:10])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_east_park_gate_requires_its_mature_mask_not_art_roles(self):
        relative='maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin'
        source=bytearray((ROOT/relative).read_bytes())
        self.assertEqual(16,len(source))
        x,y=1,5  # Gold FLOOR; the obsolete roles.bin incorrectly blocks it.
        self.assertFalse(source[y*2+x//8] & (1 << (x%8)))
        source[y*2+x//8] |= (1 << (x%8))
        report=audit_active_gatehouse_carpet_walkability(
            ROOT,GOLD,byte_overrides={relative:bytes(source)})
        self.assertEqual('FAIL',report['status'])
        self.assertTrue(any('ID105 Route36NationalParkGate: full-grid cell (1,5)' in e
                            for e in report['errors']),report['errors'][:10])

    @unittest.skipIf(GOLD is None, 'set JOHTO_GOLD_SOURCE')
    def test_east_park_gate_wall_must_not_be_made_passable(self):
        relative='maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin'
        source=bytearray((ROOT/relative).read_bytes())
        x,y=5,2  # Gold COUNTER between two halves of the park gate.
        self.assertTrue(source[y*2+x//8] & (1 << (x%8)))
        source[y*2+x//8] &= ~(1 << (x%8))
        report=audit_active_gatehouse_carpet_walkability(
            ROOT,GOLD,byte_overrides={relative:bytes(source)})
        self.assertEqual('FAIL',report['status'])
        self.assertTrue(any('ID105 Route36NationalParkGate: full-grid cell (5,2)' in e
                            for e in report['errors']),report['errors'][:10])

if __name__=='__main__': unittest.main()
