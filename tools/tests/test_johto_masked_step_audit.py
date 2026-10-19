"""Gold-backed limited ASM execution: fail-closed, not ROM/phone testing."""
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT/'pokegold-master')))
sys.path.insert(0, str(ROOT/'tools'))
from johto_masked_step_audit import audit, parse_caller, trace_masked_step
from johto_indoor_common import ConversionError

class SharedMaskedSourceAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise unittest.SkipTest('Gold source required')

    def test_active_masked_maps_include_new_route34_edges(self):
        result = audit(ROOT, GOLD)
        self.assertEqual(result['masked_caller_maps_checked'], 11)
        self.assertEqual(result['movement_edges_executed'], 56)
        self.assertEqual(result['movement_edges_required_allow'], 39)
        self.assertEqual(result['status'], 'SOURCE_BRANCH_CHECK_ONLY')
        self.assertEqual(result['failures'], [])
        self.assertFalse(result['phone_verified'])

    def test_forest_ordinary_floor_down_to_carpet_is_allowed(self):
        result=audit(ROOT,GOLD)
        rows=[e for e in result['edges'] if e['gold_map']=='IlexForest' and
              e['from']==[3,41] and e['to']==[3,42] and e['direction']=='DOWN']
        self.assertEqual(len(rows),1)
        self.assertEqual(rows[0]['expected'], 'ALLOW')
        self.assertEqual(rows[0]['actual'], 'ALLOW')
        self.assertEqual(rows[0]['status'], 'PASS')

    def test_forest_north_approach_is_exact_and_lower_wall_remains_blocked(self):
        source=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        program, labels=parse_caller(source,'JohtoIlexForestCanStepAhead')
        mask=(ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
        cases=(
            (3,41,'DOWN',False), # real reported failure, now expected walkable
            (3,42,'UP',False),   # reverse onto ordinary floor
            (3,42,'DOWN',False), # between upper and lower carpet
            (3,43,'UP',False),   # lower back to upper carpet
            (2,42,'RIGHT',False),# sideways toward upper carpet
            (2,43,'RIGHT',False),# sideways toward lower carpet
            (3,43,'DOWN',True),  # wall below the lower carpet stays closed
            (3,44,'UP',True),    # blocked approach from the wall below
        )
        for x,y,direction,expected_blocked in cases:
            with self.subTest(x=x,y=y,direction=direction):
                blocked,_=trace_masked_step(program,labels,mask,30,54,
                    'JOHTO_ILEX_FOREST_LOCAL_ID',x,y,direction)
                self.assertEqual(blocked,expected_blocked)

    def test_forest_missing_north_rule_mutation_caught_by_branch_execution(self):
        source=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        program,labels=parse_caller(source,'JohtoIlexForestCanStepAhead')
        # A real rule's wrong starting row must change behavior even though
        # PLAYER_DIR_DOWN remains elsewhere in the ASM.
        altered=[op.replace('cp 41','cp 40') for op in program]
        mask=(ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
        blocked,_=trace_masked_step(altered,labels,mask,30,54,
            'JOHTO_ILEX_FOREST_LOCAL_ID',3,41,'DOWN')
        self.assertTrue(blocked)

    def test_azalea_four_carpet_approaches_pass(self):
        result=audit(ROOT,GOLD)
        cases=[e for e in result['edges'] if e['gold_map']=='AzaleaTown']
        self.assertEqual(len(cases),4)
        self.assertEqual({e['status'] for e in cases}, {'PASS'})

    def test_cave_direction_is_not_falsely_assumed_bidirectional(self):
        result=audit(ROOT,GOLD)
        cases=[e for e in result['edges'] if e['gold_map']=='Route33']
        self.assertEqual(len(cases),2)
        self.assertEqual({e['status'] for e in cases}, {'REVIEW_REQUIRED'})
        self.assertEqual({e['actual'] for e in cases}, {'ALLOW','BLOCK'})

    def test_unknown_opcode_is_not_silently_accepted(self):
        with self.assertRaises(ConversionError):
            trace_masked_step(['mul a'], {}, bytes(54), 20, 18,
                'JOHTO_ROUTE_33_LOCAL_ID', 11, 10, 'UP')

    def test_dynamic_cut_cell_is_not_falsely_simulated(self):
        source=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        program,labels=parse_caller(source,'JohtoIlexForestCanStepAhead')
        mask=(ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
        with self.assertRaisesRegex(ConversionError,'Dynamic live Cut block'):
            trace_masked_step(program,labels,mask,30,54,
                'JOHTO_ILEX_FOREST_LOCAL_ID',8,24,'DOWN')

    def test_unrecognized_call_still_fails_closed(self):
        source=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        program,labels=parse_caller(source,'JohtoIlexForestCanStepAhead')
        mutated=[op.replace('call JohtoIlexForestCutTreeCleared',
                            'call UnknownRuntimeHelper') for op in program]
        mask=(ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
        with self.assertRaisesRegex(ConversionError,'Unsupported ASM operation'):
            trace_masked_step(mutated,labels,mask,30,54,
                'JOHTO_ILEX_FOREST_LOCAL_ID',3,42,'UP')

    def test_forest_wrong_direction_mutation_is_detected(self):
        source=(ROOT/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
        original, labels=parse_caller(source,'JohtoIlexForestCanStepAhead')
        # A mutation of an existing source branch cannot be papered over by
        # seeing PLAYER_DIR_RIGHT somewhere else in the file.
        changed=[op.replace('cp PLAYER_DIR_RIGHT','cp PLAYER_DIR_UP') for op in original]
        mask=(ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
        blocked, _=trace_masked_step(changed,labels,mask,30,54,
            'JOHTO_ILEX_FOREST_LOCAL_ID',2,42,'RIGHT')
        self.assertTrue(blocked)
