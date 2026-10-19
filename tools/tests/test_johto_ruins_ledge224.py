"""Ruins Outside: review each real Gold ledge, including consecutive levels.

Mutations use a temporary source overlay; never edit the developer's tree.
Passing these source contracts is not a substituted emulator/phone test.
"""
from pathlib import Path
import os
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from ledge_regression_audit import audit, coordinate_hops, expected_gold_hops, mask_blocked
from johto_indoor_collision_adapter import plan_gold_quadrant_collision

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
NAME = 'JohtoRuinsOfAlphOutside'


class RuinsOutsideLedges224(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD / 'maps/RuinsOfAlphOutside.blk').is_file():
            raise AssertionError('Gold RuinsOfAlphOutside source is mandatory')
        cls.src = (ROOT / 'engine/overworld/ledges.asm').read_text()

    @staticmethod
    def mask():
        data = (ROOT / 'maps/JohtoRuinsOfAlphOutside.blocked_mask.bin').read_bytes()
        if len(data) != 108:
            raise AssertionError('Ruins mask must be 20 x 36 cells / 3 bytes per row')
        return data

    def gold_geometry(self):
        plan, _ = plan_gold_quadrant_collision(GOLD, 'RuinsOfAlphOutside', 'johto')
        return plan

    def test_every_safe_gold_direction_is_registered(self):
        result = audit(ROOT, GOLD)
        self.assertEqual(result['errors'], [], result['errors'])
        self.assertEqual(result['totals']['ruins_coordinate_rules'], 16)
        expected = expected_gold_hops(GOLD, 'RuinsOfAlphOutside', 'johto')
        self.assertEqual(coordinate_hops(self.src, '.ruinsHops'), expected)
        self.assertEqual(len(expected), 16)

    def test_upper_cliff_can_land_on_another_cliff_top(self):
        plan = self.gold_geometry()
        allowed = {(h['x'], h['y'], h['dx'], h['dy']) for h in plan['hops']}
        self.assertEqual({(x, 30, 0, 1) for x in (5,6,7,8)} & allowed,
                         {(x,30,0,1) for x in (5,6,7,8)})
        mask = self.mask()
        for x in (5,6,7,8):
            self.assertFalse(mask_blocked(mask,x,30,20))
            self.assertTrue(mask_blocked(mask,x,31,20))
            self.assertFalse(mask_blocked(mask,x,32,20))  # HOP landing
            self.assertTrue(mask_blocked(mask,x,33,20))
            self.assertFalse(mask_blocked(mask,x,34,20))  # second landing
        self.assertNotIn((9,30,0,1),allowed)

    def test_unsafe_gold_hop_is_exactly_one_blocked_landing(self):
        plan = self.gold_geometry()
        self.assertEqual([(h['x'],h['y'],h['dx'],h['dy'])
                          for h in plan['unsafe_hop_candidates']],[(9,30,0,1)])
        mask = self.mask()
        self.assertFalse(mask_blocked(mask,9,30,20))
        self.assertTrue(mask_blocked(mask,9,31,20))
        self.assertTrue(mask_blocked(mask,9,32,20))
        self.assertNotIn((9,30,0,1),coordinate_hops(self.src,'.ruinsHops'))

    def test_every_registered_jump_has_a_two_cell_safe_landing(self):
        mask = self.mask()
        for x,y,dx,dy in coordinate_hops(self.src,'.ruinsHops'):
            self.assertFalse(mask_blocked(mask,x,y,20),(x,y,dx,dy))
            self.assertTrue(mask_blocked(mask,x+dx,y+dy,20),(x,y,dx,dy))
            self.assertFalse(mask_blocked(mask,x+2*dx,y+2*dy,20),(x,y,dx,dy))

    def mutated_audit(self,old,new):
        self.assertIn(old,self.src)
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)
            for dirname in ('maps','gfx','data','constants','tools'):
                (root/dirname).symlink_to(ROOT/dirname,target_is_directory=True)
            path=root/'engine/overworld/ledges.asm'
            path.parent.mkdir(parents=True)
            path.write_text(self.src.replace(old,new,1))
            return audit(root,GOLD)['errors']

    def test_deleting_legal_jump_fails(self):
        errors=self.mutated_audit('\tdb 5, 30, PLAYER_DIR_DOWN\n','')
        self.assertTrue(any(NAME+': Gold HOP missing=' in e and '(5, 30, 0, 1)' in e for e in errors),errors)

    def test_wrong_direction_fails(self):
        errors=self.mutated_audit('db 8, 32, PLAYER_DIR_RIGHT','db 8, 32, PLAYER_DIR_LEFT')
        self.assertTrue(any(NAME+': Gold HOP missing=' in e for e in errors),errors)

    def test_unsafe_wall_landing_added_fails(self):
        errors=self.mutated_audit('\tdb 10, 30, PLAYER_DIR_DOWN',
                                  '\tdb 9, 30, PLAYER_DIR_DOWN\n\tdb 10, 30, PLAYER_DIR_DOWN')
        self.assertTrue(any(NAME+': Gold HOP missing=' in e and '(9, 30, 0, 1)' in e for e in errors),errors)

    def test_ruins_map_id_dispatch_mutation_fails(self):
        errors=self.mutated_audit('cp JOHTO_RUINS_OF_ALPH_LOCAL_ID\n\tret nz',
                                  'cp JOHTO_ROUTE_35_LOCAL_ID\n\tret nz')
        self.assertTrue(any('ledge runtime dispatcher changed' in e for e in errors),errors)

    def test_shared_jump_executor_preserved(self):
        self.assertIn('ld hl, .ruinsHops\n\tjp .modernHopLookup',self.src)
        self.assertIn('call StartSimulatingJoypadStates',self.src)
        self.assertIn('ld a, $2\n\tld [wSimulatedJoypadStatesIndex], a',self.src)
        self.assertIn('cp REGION_NATIVE_MAP_SLOT\n\tjr nz, .johtoLegacy',self.src)
        self.assertIn('cp MAP_REGION_JOHTO\n\tret nz',self.src)


if __name__ == '__main__':
    unittest.main()
