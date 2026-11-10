"""REF-342 Union Cave LADDER vs directional carpet regression tests."""
from pathlib import Path
from unittest.mock import patch
import sys, unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_union_cave_warp_trigger_342_audit import check

class UnionCaveWarpTrigger342(unittest.TestCase):
    def test_contract_passes(self):
        r=check(ROOT)
        self.assertEqual('PASS_STATIC_ONLY',r['status'],r['errors'])

    def mutate(self, old, new, expected):
        original=Path.read_text
        target=(ROOT/'engine/johto_pilot_runtime.asm').resolve()
        def inject(path,*args,**kwargs):
            text=original(path,*args,**kwargs)
            if path.resolve()==target:
                self.assertIn(old,text)
                return text.replace(old,new,1)
            return text
        with patch.object(Path,'read_text',inject):
            r=check(ROOT)
        self.assertEqual('FAIL',r['status'])
        self.assertIn(expected,r['errors'])

    def test_ladder_cannot_be_downgraded_to_directional(self):
        self.mutate('.unionCaveLadder342\n    ld e, 2', '.unionCaveLadder342\n    ld e, 1', 'ladder_mode_is_immediate')

    def test_b1f_collision_guard_is_required(self):
        self.mutate('cp JOHTO_UNION_CAVE_B1F_LOCAL_ID\n    jr z, .unionCaveB1FRuinsExit366',
                    'cp JOHTO_UNION_CAVE_B1F_LOCAL_ID\n    jr z, .unionCaveExit',
                    'b1f_ruins_down_collision_guard')

    def test_b2f_collision_guard_is_required(self):
        self.mutate('cp JOHTO_UNION_CAVE_B2F_LOCAL_ID\n    jr z, .unionCaveNoCollisionWarp342',
                    'cp JOHTO_UNION_CAVE_B2F_LOCAL_ID\n    jr z, .unionCaveExit',
                    'b2f_collision_denied')

if __name__=='__main__': unittest.main()
