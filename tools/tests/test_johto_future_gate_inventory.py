"""Regression: audit future Gold gates without inventing arrival motion.

Fixture-only tests run without external pokegold checkout. Real complete Gold
inventory must be generated separately from the user's archived Gold source.
"""
from __future__ import annotations
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_warp_reference_profiles import gold_gate_inventory, _gate_edges
from johto_door_onboarding_audit import validate_gate_arrival_policy


def gold_map(*warps: str, extra: str = '') -> str:
    return ('Example_MapEvents:\n\tdef_warp_events\n' +
            ''.join('\twarp_event ' + x + '\n' for x in warps) +
            '\tdef_coord_events\n' + extra)


class FutureGateInventory(unittest.TestCase):
    def test_east_west_pair_and_north_south_pair_are_distinguished(self):
        ew = [dict(x=x, y=y, destination='R', warp_number=1)
              for x in (0, 9) for y in (4, 5)]
        ns = [dict(x=x, y=y, destination='R', warp_number=1)
              for x in (3, 4) for y in (0, 7)]
        self.assertEqual(_gate_edges(ew)[0], 'EAST_WEST_PAIR')
        self.assertEqual(_gate_edges(ns)[0], 'NORTH_SOUTH_PAIR')

    def test_inventory_flags_merging_and_scripted_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            temp = Path(tmp)
            (temp/'gold/maps').mkdir(parents=True)
            (temp/'rpp/tools').mkdir(parents=True)
            (temp/'rpp/tools/johto_door_contracts.json').write_text(json.dumps({
                'active_warp_maps': [{'gold_map': 'ExistingGate', 'rpp_map': 'JohtoExisting',
                                      'family': 'GATE_INDOOR', 'arrival_step_review': {
                                          'layout': 'EAST_WEST_PAIR',
                                          'by_gate_side': {'west':'NONE','east':'NONE'},
                                          'basis': 'Fixture example of reviewed arrival coordinates'}}]}))
            (temp/'gold/maps/ExistingGate.asm').write_text(gold_map(
                '0,4,A,1', '0,5,A,2', '9,4,B,1', '9,5,B,2'))
            (temp/'gold/maps/MergedGate.asm').write_text(gold_map(
                '4,0,ROUTE_A,1', '5,0,ROUTE_A,2',
                '4,7,ROUTE_B,3', '5,7,ROUTE_B,3',
                extra='\tcoord_event 5, 4, SCENE_CHECK, GateCheck\n'))
            (temp/'gold/maps/VictoryRoadGate.asm').write_text(gold_map(
                '4,0,ROUTE_A,1', '5,0,ROUTE_A,2',
                '0,4,ROUTE_B,3', '0,5,ROUTE_B,3',
                '9,4,ROUTE_C,1', '9,5,ROUTE_C,2',
                '4,7,ROUTE_D,1', '5,7,ROUTE_D,1'))
            data = gold_gate_inventory(temp/'rpp', temp/'gold')
            self.assertEqual(data['totals']['gold_gates'], 3)
            byname = {g['gold_map']: g for g in data['gates']}
            self.assertEqual(byname['ExistingGate']['status'], 'ALREADY_REGISTERED_JOHTO')
            self.assertEqual(byname['MergedGate']['status'], 'NOT_REGISTERED_JOHTO_CANDIDATE')
            self.assertIn('TWO_LANES_TO_ONE_DESTINATION', byname['MergedGate']['flags'])
            self.assertIn('SCRIPTED_ACCESS_OR_MOVEMENT', byname['MergedGate']['flags'])
            self.assertEqual(byname['VictoryRoadGate']['layout'], 'COMPLEX_MULTI_EXIT')
            for g in data['gates']:
                self.assertEqual(g['arrival_step_contract'],
                                 'REVIEW_PER_DESTINATION_AND_DIRECTION')

    def test_no_automatic_step_inferred_from_orientation(self):
        p = {'rpp_map': 'NewNorthGate', 'arrival_step_review': {
            'layout': 'NORTH_SOUTH_PAIR', 'by_gate_side': {'north': 'NONE', 'south': 'NONE'},
            'basis': 'Both arrival positions verified independently against Gold collision'}}
        self.assertEqual(validate_gate_arrival_policy(p), [])
        p['arrival_step_review']['by_gate_side']['south'] = 'D_DOWN'
        self.assertEqual(validate_gate_arrival_policy(p), [])
        # Reviewing BOTH directions is allowed when documented; it must never
        # be silently inferred by the tool from compass directions.
        self.assertEqual(p['arrival_step_review']['by_gate_side']['north'], 'NONE')

    def test_missing_side_and_bad_direction_fail_closed(self):
        valid = {'rpp_map': 'G', 'arrival_step_review': {
            'layout': 'EAST_WEST_PAIR',
            'by_gate_side': {'west': 'NONE', 'east': 'NONE'},
            'basis': 'Actual RPP trigger and arrival positions checked in Gold map'}}
        self.assertEqual(validate_gate_arrival_policy(valid), [])
        missing = json.loads(json.dumps(valid))
        missing['arrival_step_review']['by_gate_side'].pop('east')
        self.assertTrue(validate_gate_arrival_policy(missing))
        invalid = json.loads(json.dumps(valid))
        invalid['arrival_step_review']['by_gate_side']['east'] = 'AUTO_BOTH'
        self.assertTrue(validate_gate_arrival_policy(invalid))

    def test_active_215_gate_policy_and_runtime_are_down_only(self):
        contract = json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        active = [e for e in contract['active_warp_maps']
                  if e.get('family') == 'GATE_INDOOR']
        self.assertTrue(active)
        self.assertTrue(all(not validate_gate_arrival_policy(e) for e in active))
        north = next(e for e in active if e['rpp_map']=='JohtoRoute34IlexForestGate')
        self.assertEqual(north['arrival_step_review']['by_gate_side'],
                         {'north':'D_DOWN','south':'NONE'})
        lookup = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        marker = lookup.split('.profiles', 1)[1].split('GetJohtoCaveMapChangeSFX::',1)[0]
        self.assertIn('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, 4, REGION_NATIVE_MAP_SLOT, D_DOWN',marker)
        self.assertIn('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 0, 5, REGION_NATIVE_MAP_SLOT, D_DOWN',marker)
        self.assertNotIn('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 7, 4, REGION_NATIVE_MAP_SLOT, D_UP',marker)
        self.assertNotIn('JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID, 7, 5, REGION_NATIVE_MAP_SLOT, D_UP',marker)


if __name__ == '__main__':
    unittest.main()
