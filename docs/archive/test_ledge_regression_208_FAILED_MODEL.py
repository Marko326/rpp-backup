"""ILEX .208: shared ledge action and landing regression gate.

Static ASM inspection plus a deliberately small overworld-frame state model.
This is not a CPU emulator or substitute for player/ROM acceptance.
"""
from pathlib import Path
import hashlib
from unittest.mock import patch
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import ledge_regression_audit
from ledge_regression_audit import audit, pairs


class Ledge208(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.home = (ROOT / 'home/overworld.asm').read_text()
        cls.anim = (ROOT / 'engine/overworld/player_animations.asm').read_text()
        cls.ledges = (ROOT / 'engine/overworld/ledges.asm').read_text()

    def test_all_installed_ledge_data_inventory(self):
        result = audit(ROOT)
        self.assertEqual(result['errors'], [], result)
        self.assertEqual(result['totals']['johto_native_pair_approaches'], 95)
        self.assertEqual(result['totals']['modern_coordinate_rules'], 16)
        self.assertGreater(result['totals']['kanto_overworld_maps_checked'], 100)

    def test_future_ledge_route_requires_explicit_audit_registration(self):
        modified = self.ledges.replace('\n.johto\n',
                                       '\n.johto\n\tcp JOHTO_ROUTE_99\n', 1)
        errors = ledge_regression_audit.registration_errors(modified)
        self.assertTrue(any('native router' in error for error in errors), errors)
        modified = self.ledges.replace('\n.route33Hops\n',
                                       '\n.newMapHops\n\tdb $ff\n.route33Hops\n', 1)
        errors = ledge_regression_audit.registration_errors(modified)
        self.assertTrue(any('coordinate HOP router' in error for error in errors), errors)

    def test_wrong_forest_jump_contract_is_rejected(self):
        altered = set(ledge_regression_audit.FOREST_ACTIONS)
        altered.remove((23, 22, -1, 0))
        with patch.object(ledge_regression_audit, 'FOREST_ACTIONS', altered):
            result = audit(ROOT)
        self.assertTrue(any('Forest' in error for error in result['errors']), result)

    def test_forest_b_speed_remains_disabled_without_changing_legacy_branch(self):
        section = self.home.split('.normalPlayerSpriteAdvancement', 1)[1]
        self.assertIn('cp JOHTO_ILEX_FOREST', section)
        self.assertIn('bit 6, a\n\tjr nz, .notRunning', section)
        self.assertLess(section.index('cp JOHTO_ILEX_FOREST'),
                        section.index('.checkRunningButton'))
        self.assertIn('and B_BUTTON', section)

    def test_legacy_pair_tables_unchanged(self):
        kanto = pairs(self.ledges, 'LedgeTiles')
        route29 = pairs(self.ledges, 'JohtoRoute29LedgeTiles')
        route31 = pairs(self.ledges, 'JohtoRoute31LedgeTiles')
        self.assertEqual([(x[1], x[2]) for x in kanto],
                         [(0x2c,0x37),(0x39,0x36),(0x39,0x37),
                          (0x2c,0x27),(0x39,0x27),(0x2c,0x0d),
                          (0x2c,0x1d),(0x39,0x0d)])
        self.assertEqual([(x[1], x[2]) for x in route29],
                         [(5,0x3b),(5,0x20),(5,0x21),(6,0x21)])
        self.assertEqual([(x[1], x[2]) for x in route31],
                         [(5,0x3b),(5,0x20),(6,0x30),(5,0x21),(6,0x21)])
        # No new coordinate-trigger Ilex interpreter, only three native pairs.
        self.assertEqual([(x[1], x[2]) for x in pairs(self.ledges,'JohtoIlexForestLedgeTiles')],
                         [(5,0x40),(5,0x41),(5,0x42)])
        self.assertNotIn('.ilexHops', self.ledges)

    def test_common_animator_prevents_early_finish_when_forced_steps_pending(self):
        # The wrapper is in ROM0 because the historical animation bank is full.
        # It checks both the real walking step AND the simulated input index
        # before delegating to the unchanged RPP banked animator.
        wrapper = self.home.split('HandleMidJump::',1)[1].split('EnterMap::',1)[0]
        for token in ('ld a, [wWalkCounter]', 'jr nz, .animate',
                      'ld a, [wd730]', 'bit 7, a',
                      'ld a, [wSimulatedJoypadStatesIndex]',
                      'ret nz', 'jpba _HandleMidJump'):
            self.assertIn(token, wrapper)
        self.assertLess(wrapper.index('ld a, [wWalkCounter]'),
                        wrapper.index('ld a, [wSimulatedJoypadStatesIndex]'))
        self.assertLess(wrapper.index('ret nz'), wrapper.index('jpba _HandleMidJump'))
        # This regression intentionally ensures there is no Forest-only gate:
        # all RPP and Johto ledges get the same queue-aware animator contract.
        self.assertNotIn('JOHTO_ILEX_FOREST', wrapper)

    def test_common_landing_barrier_has_correct_control_flow(self):
        section = self.home.split('OverworldLoopLessDelay::', 1)[1].split('callba SafariZoneCheck',1)[0]
        self.assertLess(section.index('call HandleMidJump'), section.index('call JoypadOverworld'))
        self.assertIn('ld a, [wSimulatedJoypadStatesIndex]\n\tand a\n\tjr nz, .ledgeInputReady',section)
        self.assertIn('call UpdateSprites\n\tjp OverworldLoop',section)
        # A pending forced step reaches Joypad; the final pending==0 frame
        # remains in the native animation until wd736.6 really clears.
        self.assertNotIn('cp JOHTO_ILEX_FOREST_LOCAL_ID', section)
        self.assertNotIn('ld [wSimulatedJoypadStatesIndex], a', section)
        self.assertLess(section.index('ld a, [wSimulatedJoypadStatesIndex]'),
                        section.index('call JoypadOverworld'))

    def test_unchanged_legacy_animation_and_jump_distance_contract(self):
        # Animation ROMX bank is known full: never edit _HandleMidJump here.
        code = self.anim.split('_HandleMidJump:', 1)[1].split('Ledge60FPS:',1)[0]
        self.assertEqual(hashlib.sha256(code.encode()).hexdigest(),
                         'fcc10cf7dbd9ab35ecb8f53bedd9a20003438ffcf4598fd95b6f7e53636e599b')
        section = self.ledges.split('.foundMatch',1)[1].split('JohtoIlexForestLedgeTiles:',1)[0]
        self.assertIn('cp JOHTO_ILEX_FOREST',section)
        self.assertIn('ld a, $2\n\tjr nz, .hopCountReady\n\tdec a',section)
        self.assertIn('ld [wSimulatedJoypadStatesIndex], a',section)

    @staticmethod
    def _frame_model(simulated_extra, animation_period, protected, start_phase=0):
        """Small discrete frame model, not a Game Boy CPU or ROM emulator.

        The first actual 16-pixel step is already underway when HandleLedges
        queues the remaining simulated direction presses. On each new frame:
        animation update -> (possibly) simulated Joypad -> movement update.
        """
        remaining = simulated_extra
        walk_counter = 16
        position = 0
        animation = 0
        jump = True
        premature = False
        idle_frames = 0
        for frame in range(256):
            if not jump:
                break
            # The _HandleMidJump wrapper refuses to finish while there is
            # another queued forced cell but no actual movement underway.
            animator_allowed = not (protected and walk_counter == 0 and remaining > 0)
            if animator_allowed:
                if animation >= 16:
                    if walk_counter == 0:
                        premature = remaining != 0
                        jump = False
                        break
                elif (frame + start_phase) % animation_period == 0:
                    animation += 1
            if walk_counter == 0:
                if remaining > 0:
                    remaining -= 1  # JoypadOverworld consumes the queued input
                    walk_counter = 16
                else:
                    # Shared barrier: don't dispatch another real direction
                    # while native jumping flag wd736.6 remains set.
                    idle_frames += 1
                    continue
            walk_counter -= 1
            if walk_counter == 0:
                position += 1
        return (position, remaining, jump, premature, idle_frames)

    def test_adversarial_frame_model_proves_old_single_cell_failure(self):
        # Old .207 behavior *can* end during the frame between cell 1 and
        # queued cell 2. Capture a red-case witness in this model.
        result = self._frame_model(1, 1, protected=False)
        self.assertEqual(result[:4], (1, 1, False, True))
        for extra in (1, 2):
            for period in (1, 2, 3, 4):
                for phase in range(period):
                    with self.subTest(extra=extra,period=period,phase=phase):
                        pos, pending, still_jumping, early, waits = self._frame_model(
                            extra, period, protected=True, start_phase=phase)
                        self.assertEqual(pos, extra + 1)
                        self.assertEqual(pending, 0)
                        self.assertFalse(still_jumping)
                        self.assertFalse(early)
                        self.assertLess(waits, 90)

    def test_jump_finish_does_not_erase_simulation_until_last_step(self):
        loop = self.home.split('OverworldLoopLessDelay::',1)[1].split('call JoypadOverworld',1)[0]
        self.assertNotIn('xor a\n\tld [wWastedByteCD3A], a',loop)
        self.assertNotIn('ld [wSimulatedJoypadStatesEnd + 1], a',loop)
        # RPP banked handler is still responsible for ending the ledge flag
        # and scripted joypad control only after all forced moves are complete.
        self.assertIn('res 6, [hl]', self.anim.split('_HandleMidJump:',1)[1])
        self.assertIn('res 7, [hl]', self.anim.split('_HandleMidJump:',1)[1])


if __name__ == '__main__':
    unittest.main()
