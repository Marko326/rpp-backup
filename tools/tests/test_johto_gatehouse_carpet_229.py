"""GATE-5.62.229: executable carpet movement != directional Warp triggering.

Independent regression against the prior .228 phone failure. The tests call
real ASM limited executors/masks and mutate actual production sources. They do
NOT claim ROM or phone verification.
"""
import copy
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/nonexistent'))
sys.path.insert(0, str(ROOT/'tools'))
from johto_masked_step_audit import gate_mat_path_errors
from johto_gatehouse_behavior_audit import audit as gate_audit, predicate, object_warps

CONTRACT = 'tools/johto_door_contracts.json'
COLLISION = 'engine/overworld/johto_route33_collision.asm'
HOME = 'home/overworld.asm'
GATE = 'JohtoRoute38EcruteakGate'
GATE_ID = 'JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID'
CITY_ID = 'JOHTO_ECRUTEAK_CITY_LOCAL_ID'
ROAD_ID = 'JOHTO_ROUTE_38_LOCAL_ID'


def data():
    return json.loads((ROOT/CONTRACT).read_text())


def ids():
    result = {}
    for p in ['constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm']:
        import re
        result.update({name:int(num) for name,num in re.findall(
            r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\d+)',(ROOT/p).read_text())})
    return result


class WestGateCarpet229(unittest.TestCase):
    def test_double_lane_walk_and_outward_collision_are_distinct(self):
        self.assertEqual(gate_mat_path_errors(ROOT,data()),[])

    @unittest.skipUnless(GOLD.is_dir(), 'Gold source mandatory')
    def test_explicit_gold_path_ignores_wrong_environment(self):
        # Release --gold must reach Route32's legacy carpet proof even when
        # inherited shell variables name a stale checkout.
        with patch.dict(os.environ, {'JOHTO_GOLD_SOURCE': '/missing-stale-gold',
                                     'JOHTO_GOLD_ROOT': '/missing-stale-gold'}):
            self.assertEqual(gate_mat_path_errors(ROOT, data(), gold=GOLD), [])
            self.assertEqual(gate_audit(ROOT, GOLD), [])

    @unittest.skipUnless(GOLD.is_dir(), 'Gold source mandatory')
    def test_wrong_explicit_gold_path_is_rejected_despite_valid_environment(self):
        with patch.dict(os.environ, {'JOHTO_GOLD_SOURCE': str(GOLD),
                                     'JOHTO_GOLD_ROOT': str(GOLD)}):
            errors = gate_mat_path_errors(
                ROOT, data(), gold=Path('/missing-explicit-gold'))
        self.assertTrue(any('legacy Route32 exact carpet' in err
                            for err in errors), errors)

    def test_both_lanes_round_trip_through_actual_runtime_dispatch(self):
        manifest = next(a for a in data()['active_warp_maps'] if a['rpp_map']==GATE)
        runtime = manifest['gatehouse_runtime']
        lookup=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        route_section=lookup.split('NativeRegionWarpTargets::',1)[1].split('SelectNativeMapConnection::',1)[0]
        import re
        links={(name,int(source)): (dst,int(target)) for name,source,target,dst in
               re.findall(r'(?m)^\s*db\s+(JOHTO_\w+),\s*(\d+),\s*(\d+),\s*MAP_REGION_JOHTO,\s*(JOHTO_\w+)\s*$',route_section)}
        source=(ROOT/COLLISION).read_text()
        home=(ROOT/HOME).read_text()
        local_to_stem={CITY_ID:'JohtoEcruteakCity',ROAD_ID:'JohtoRoute38',GATE_ID:GATE}
        self.assertEqual(len(runtime['approaches']),8)
        self.assertEqual(len(runtime['native_routes']),8)
        for mouth in runtime['approaches']:
            local=mouth['map_local']
            x,y,face=mouth['x'],mouth['y'],mouth['direction']
            stem=local_to_stem[local]
            warps=object_warps((ROOT/f'data/mapObjects/{stem}.asm').read_text(),stem)
            slot=next(i for i,w in enumerate(warps) if w[:2]==(y,x))
            self.assertTrue(predicate(home,'IsJohtoSouthGatePortal',local,x,y,face,ids()))
            for direction in ('UP','DOWN','LEFT','RIGHT'):
                self.assertEqual(predicate(source,'JohtoGateCollisionDirectionAllowed',local,x,y,direction),direction==face,
                                 f'{stem} {(x,y)} {direction}')
                self.assertFalse(predicate(source,'JohtoNorthGateStepWarpAllowed',local,x,y,direction))
            # Follow actual native table, not only the proposed JSON route.
            target_local,target_slot=links[(local,slot)]
            target_stem=local_to_stem[target_local]
            target_warps=object_warps((ROOT/f'data/mapObjects/{target_stem}.asm').read_text(),target_stem)
            landed=target_warps[target_slot]
            ty,tx=landed[:2]
            reverse_face = 'RIGHT' if face=='LEFT' else 'LEFT'
            self.assertTrue(predicate(home,'IsJohtoSouthGatePortal',target_local,tx,ty,reverse_face,ids()))
            self.assertTrue(predicate(source,'JohtoGateCollisionDirectionAllowed',target_local,tx,ty,reverse_face),
                            f'cannot immediately reverse through {target_stem} {(tx,ty)}')
            # The outside Route38 mouth is NOT at the physical map edge.
            # Returning via collision requires ExtraWarpCheck's *separate*
            # JohtoInternalDoorFacingCheck. The .229 version missed this,
            # although the warp graph and direction checks were green.
            if target_local == ROAD_ID:
                self.assertTrue(predicate(source,'JohtoInternalDoorFacingCheck',target_local,tx,ty,reverse_face),
                                f'actual ExtraWarpCheck would reject Route38 re-entry {(tx,ty)}')
            self.assertEqual(links[(target_local,target_slot)],(local,slot))
            self.assertTrue(any(tuple(p[:2])==(ty,tx) and p[2]=='NONE'
                                for a in runtime['arrivals'] if a['local']==target_local
                                for p in a['points']))

    def test_route38_outside_extra_warp_has_both_lanes_and_rejects_side_scrapes(self):
        source=(ROOT/COLLISION).read_text()
        for y in (8,9):
            for x in (34,35,36):
                for face in ('UP','DOWN','LEFT','RIGHT'):
                    expected=(x==35 and face=='RIGHT')
                    self.assertEqual(
                        predicate(source,'JohtoInternalDoorFacingCheck',ROAD_ID,x,y,face),
                        expected, f'Route38 {(x,y)} {face}')
        for y in (7,10):
            self.assertFalse(predicate(source,'JohtoInternalDoorFacingCheck',ROAD_ID,35,y,'RIGHT'))
        self.assertFalse(predicate(source,'JohtoInternalDoorFacingCheck',CITY_ID,35,8,'RIGHT'))

    @unittest.skipUnless(GOLD.is_dir(),'Gold source mandatory')
    def test_remove_actual_extra_warp_branch_is_caught_even_when_graph_is_intact(self):
        source=(ROOT/COLLISION).read_text()
        old='\tcp JOHTO_ROUTE_38_LOCAL_ID\n\tjp z, .route38Door'
        self.assertIn(old,source)
        broken=source.replace(old,'\tcp JOHTO_ROUTE_38_LOCAL_ID\n\tjp z, .denied',1)
        issues=gate_audit(ROOT,GOLD,overrides={COLLISION:broken})
        self.assertTrue(any('EXTRA_WARP actual=False wanted=True' in e for e in issues),issues)

    @unittest.skipUnless(GOLD.is_dir(),'Gold source mandatory')
    def test_drop_required_extra_warp_proof_field_is_caught(self):
        manifest=data()
        gate=next(v for v in manifest['active_warp_maps'] if v['rpp_map']==GATE)
        for a in gate['gatehouse_runtime']['approaches']:
            if a['map_local']==ROAD_ID:
                a.pop('outside_guard',None)
        issues=gate_audit(ROOT,GOLD,overrides={CONTRACT:json.dumps(manifest)})
        self.assertTrue(any('missing mandatory EXTRA_WARP proof' in e for e in issues),issues)

    def test_228_style_vertical_block_mutation_must_fail(self):
        source=(ROOT/COLLISION).read_text()
        # Remove only the exact gate DOWN lane permit; other rules remain.
        marker='JohtoRoute38EcruteakGateCanStepAhead::'
        a,b=source.split(marker,1)
        old='\tld a, [wYCoord]\n\tcp 4\n\tjr z, .allowed\n\t; Same for the floor immediately above'
        self.assertIn(old,b)
        broken=a+marker+b.replace(old,old.replace('cp 4','cp 44'),1)
        mistakes=gate_mat_path_errors(ROOT,data(),{COLLISION:broken})
        self.assertTrue(any(GATE in err and 'DOWN' in err and 'BLOCK' in err for err in mistakes),mistakes)

    def test_228_style_outward_step_allowed_mutation_must_fail(self):
        source=(ROOT/COLLISION).read_text()
        marker='JohtoRoute38EcruteakGateCanStepAhead::'
        a,b=source.split(marker,1)
        old='\tld a, [wXCoord]\n\tcp 1\n\tjr z, .allowed'
        self.assertIn(old,b)
        broken=a+marker+b.replace(old,'\tld a, [wXCoord]\n\tand a\n\tjr z, .allowed\n'+old,1)
        mistakes=gate_mat_path_errors(ROOT,data(),{COLLISION:broken})
        self.assertTrue(any(GATE in err and 'LEFT' in err and 'ALLOW' in err for err in mistakes),mistakes)

    @unittest.skipUnless(GOLD.is_dir(),'Gold source mandatory')
    def test_missing_home_gate_identity_causes_release_gate_failure(self):
        source=(ROOT/HOME).read_text()
        self.assertIn('cp JOHTO_ROUTE_39_LOCAL_ID',source)
        broken=source.replace('cp JOHTO_ROUTE_39_LOCAL_ID','cp JOHTO_ROUTE_38_LOCAL_ID',1)
        issues=gate_audit(ROOT,GOLD,overrides={HOME:broken})
        self.assertTrue(any('bypasses the HOME Warp selector' in err for err in issues),issues)

    def test_road_side_warp_collision_cannot_become_walk_off_map(self):
        old=(ROOT/'maps/JohtoRoute38.blocked_mask.bin').read_bytes()
        mask=bytearray(old)
        # x36,y8 must remain solid: collision against it triggers the road gate.
        pos=8*5+36//8
        mask[pos]&=~(1<<(36%8))
        mistakes=gate_mat_path_errors(ROOT,data(),{'maps/JohtoRoute38.blocked_mask.bin':bytes(mask)})
        self.assertTrue(any('JohtoRoute38 (35,8) RIGHT' in err for err in mistakes),mistakes)

if __name__=='__main__':
    unittest.main()
