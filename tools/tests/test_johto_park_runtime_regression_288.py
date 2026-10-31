"""Negative fixture tests ensure the real live Park runtime is guarded."""
import os
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_park_runtime_regression_audit_288 import audit
NPC=Path(os.environ['NPC_SOURCE_ROOT']) if os.environ.get('NPC_SOURCE_ROOT') else None

class Park288Regressions(unittest.TestCase):
    def setUp(self):
        self.assertEqual('PASS_STATIC_ONLY',audit(ROOT,NPC)['status'])
    def reject(self,path,old,new,expected):
        value=(ROOT/path).read_text()
        self.assertIn(old,value)
        failed=audit(ROOT,NPC,{path:value.replace(old,new,1)})
        self.assertIn(expected,failed['errors'],failed)
    def test_park_border_fallback_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_NATIONAL_PARK_LOCAL_ID\n    jp z, .southClosedEdge',
                    'cp JOHTO_NATIONAL_PARK_LOCAL_ID\n    jp z, .southGoldenrodEdge',
                    'all_three_park_maps_guarded_before_movement')
    def test_south_gate_border_fallback_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID\n    jp z, .southClosedEdge',
                    'cp JOHTO_ROUTE_35_NATIONAL_PARK_GATE_LOCAL_ID\n    jp z, .southRoute35Edge',
                    'all_three_park_maps_guarded_before_movement')
    def test_east_gate_unguarded_rejected(self):
        self.reject('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID\n    jp z, .southClosedEdge',
                    'cp JOHTO_ROUTE_36_NATIONAL_PARK_GATE_LOCAL_ID\n    jp z, .route36Edge',
                    'all_three_park_maps_guarded_before_movement')
    def test_east_mature_dispatch_removed_rejected(self):
        self.reject('engine/johto_south_geometry.asm',
                    'call JohtoParkEastGateMatureStep','call JohtoSouthSpatialRoleAhead',
                    'east_gate_runtime_calls_mature_mask')
    def test_mature_mask_corruption_rejected(self):
        path='maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin'
        original=(ROOT/path).read_bytes()
        changed=bytes([original[0]^1])+original[1:]
        self.assertIn('east_gate_mature_mask_exact_16_bytes',audit(ROOT,NPC,{path:changed})['errors'])
    def test_long_grass_pallet_rule_removed_rejected(self):
        self.reject('data/tileset_headers.asm',
                    'JohtoPilot_Coll, $FF,$FF,$FF, $04, OUTDOOR ; FIX-288',
                    'JohtoPilot_Coll, $FF,$FF,$FF, $FF, OUTDOOR ; FIX-288',
                    'park_grass_four_gold_tiles')
    def test_four_grass_tiles_required_rejected(self):
        self.reject('engine/overworld/movement.asm','cp $4b','cp $4c','park_grass_four_gold_tiles')
    def test_npc_grass_priority_required_rejected(self):
        self.reject('engine/overworld/movement.asm',
                    '\tcall GetGrassSpritePriority\n\tld [hl], a',
                    '\txor a\n\tld [hl], a',
                    'both_player_and_npc_grass_priority')
    def test_wrong_east_gate_outbound_direction_rejected(self):
        self.reject('engine/johto_south_portals.asm',
                    '.parkEastGate\n    ld a, [wPlayerDirection]\n    cp PLAYER_DIR_LEFT',
                    '.parkEastGate\n    ld a, [wPlayerDirection]\n    cp PLAYER_DIR_UP',
                    'park_dual_gate_exact_outward_approaches')
    def test_registered_warp_and_collector_required_rejected(self):
        self.reject('data/johto_park_runtime_286.asm',
                    'db 4, 9, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                    'db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                    'correct_park_gate_warp_layout')
    def test_old_287_fails_new_regression(self):
        old=ROOT.parent/'work287'
        if old.is_dir():
            mask=(ROOT/'maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin').read_bytes()
            report=audit(old,changes={'maps/johto_pilot/Route36NationalParkGate.mature_blocked_mask.bin':mask})
            self.assertIn('all_three_park_maps_guarded_before_movement',report['errors'])
            self.assertNotEqual('PASS_STATIC_ONLY',report['status'])

if __name__=='__main__':unittest.main()
