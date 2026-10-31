"""ALPH-NORTH-001: Gold-backed north-south gate, direction & auto-step safeguards.

All checks are read-only source tests, not ROM emulator or human acceptance.
"""
from pathlib import Path
import os
import re
import unittest
from tools.johto_ruins_stage_audit import audit as stage_audit

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None


def piece(text, start, end):
    return text.split(start, 1)[1].split(end, 1)[0]


class AlphNorth257(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.edge = (ROOT/'engine/johto_pilot_runtime.asm').read_text()
        cls.north = (ROOT/'data/johto_ruins_north_runtime.asm').read_text()
        cls.south = (ROOT/'data/johto_ruins_south_runtime.asm').read_text()
        cls.home = (ROOT/'home/overworld.asm').read_text()

    def test_stable_map_slots_and_unopened_edges(self):
        const = (ROOT/'constants/region_map_constants.asm').read_text()
        self.assertIn('NUM_JOHTO_ACTIVE_MAPS EQU 28', const)
        self.assertIn('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID EQU 19', const)
        self.assertIn('JOHTO_ROUTE_36_LOCAL_ID EQU 16', const)
        self.assertIn('db NORTH | SOUTH | EAST ; Gold Route37 north; Route35 south; Violet east', self.north)
        self.assertIn('db 4 ; Ruins #3/#4 retain ordinals0/1; Park #1/#2 append 2/3.', self.north)
        self.assertIn('db 0 ; defer signs and original NPC/Sudowoodo events\n    db 0', self.north)
        self.assertEqual([], stage_audit(ROOT, GOLD))

    def test_warp_records_exact_north_doors_and_carpets(self):
        rows=piece(self.edge,'JohtoRegisteredWarpRoutes::','JohtoRegisteredWarpRoutesEnd::')
        for src,idx,dst in (
                ('JOHTO_RUINS_OF_ALPH_LOCAL_ID',2,'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'),
                ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',0,'JOHTO_ROUTE_36_LOCAL_ID'),
                ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',1,'JOHTO_ROUTE_36_LOCAL_ID'),
                ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',2,'JOHTO_RUINS_OF_ALPH_LOCAL_ID'),
                ('JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',3,'JOHTO_RUINS_OF_ALPH_LOCAL_ID'),
                ('JOHTO_ROUTE_36_LOCAL_ID',0,'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'),
                ('JOHTO_ROUTE_36_LOCAL_ID',1,'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID')):
            pattern=f'db MAP_REGION_JOHTO, {src}, {idx}, MAP_REGION_JOHTO, {dst}'
            self.assertEqual(1,rows.count(pattern),pattern)
        self.assertIn('db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR', self.north)
        self.assertIn('db 7, 5, 2, JOHTO_REGISTERED_WARP_SELECTOR', self.north)
        self.assertIn('db 5, 7, 2, JOHTO_REGISTERED_WARP_SELECTOR', self.south)

    def test_gold_direction_approach_and_warp_result(self):
        approach=piece(self.edge,'JohtoPilotGateDoorApproachAllowed::','JohtoPilotGateDoorWarpMatched::')
        matching=piece(self.edge,'JohtoPilotGateDoorWarpMatched::','JohtoPilotGateExteriorCollisionAllowed::')
        for body in (approach,matching):
            self.assertIn('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',body)
            self.assertIn('cp JOHTO_ROUTE_36_LOCAL_ID',body)
            self.assertIn('cp PLAYER_DIR_UP',body)
            self.assertIn('cp PLAYER_DIR_DOWN',body)
            self.assertIn('.northGateTopDoor',body)
            self.assertIn('.route36Alph',body)
            self.assertIn('.ruinsSouth',body)
            # South gate second lane must not run through Route36-specific check.
            self.assertRegex(body, r'(?s)\.ruinsSouth\n.*?cp 20\n\s+jr z, \.allow\n\s+cp 21\n\s+ret nz\n\s+jr \.allow\b')
        self.assertIn('ld e, 2 ; special exact STEP_ON DOOR',matching)
        self.assertIn('ld e, 1',matching)
        self.assertIn('cp 2\n    jr z, .northGoldStepOnDoor',self.home)

    def test_door_auto_step_only_correct_landing(self):
        step=piece(self.edge,'JohtoPilotGateArrivalStep::','JohtoPilotGateDoorApproachAllowed::')
        self.assertIn('ld e, 0',step)
        self.assertIn('cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID',step)
        self.assertIn('cp JOHTO_RUINS_OF_ALPH_LOCAL_ID',step)
        self.assertIn('cp 7\n    ret nz',step)
        self.assertIn('cp 5\n    ret nz',step)
        self.assertIn('cp 4\n    jr z, .down',step)
        self.assertIn('cp 5\n    ret nz',step)
        self.assertIn('ld e, D_DOWN',step)
        self.assertNotIn('cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID',step)
        self.assertNotIn('cp JOHTO_ROUTE_36_LOCAL_ID',step)

    def test_wrong_direction_and_neighboring_tile_fail_closed(self):
        collision=piece(self.edge,'JohtoPilotGateCollisionExitAllowed::','; P6-GATE-005' ) if '; P6-GATE-005' in self.edge else self.edge.split('JohtoPilotGateCollisionExitAllowed::',1)[1]
        self.assertIn('.northGateBottom',collision)
        self.assertIn('cp PLAYER_DIR_DOWN\n    ret nz',collision)
        self.assertRegex(collision,r'(?s)\.northGateBottom\n.*?cp 7\n\s+ret nz\n\s+ld a, \[wXCoord\]\n\s+cp 4\n\s+jr z, \.yes\n\s+cp 5\n\s+ret nz')
        # No source wildcard, no unregistered Route36 national park warp.
        rows=piece(self.edge,'JohtoRegisteredWarpRoutes::','JohtoRegisteredWarpRoutesEnd::')
        self.assertNotIn('JOHTO_ROUTE36_NATIONAL_PARK_GATE_LOCAL_ID',rows)
        self.assertIn('JOHTO_ROUTE_35_LOCAL_ID',rows)
        self.assertNotIn('JOHTO_ROUTE_37_LOCAL_ID',rows)


if __name__=='__main__': unittest.main()
