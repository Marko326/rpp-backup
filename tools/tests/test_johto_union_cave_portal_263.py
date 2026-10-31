#!/usr/bin/env python3
"""Fault injection for Union Cave 1F Gold DOWN carpet / bike contract."""
from pathlib import Path
import os
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_union_cave_portal_audit import audit, REQUIRED

GOLD = Path(os.getenv('GOLD_SOURCE_ROOT') or os.getenv('JOHTO_GOLD_SOURCE') or '/__missing__')


class UnionCavePortal263(unittest.TestCase):
    def test_reference_and_runtime_contract(self):
        report = audit(ROOT, GOLD if GOLD.is_dir() else None)
        self.assertEqual('PASS_STATIC_ONLY', report['status'], report['errors'])
        self.assertGreaterEqual(len(report['checks']), 9)

    def test_failure_injections(self):
        runtime = 'engine/johto_pilot_runtime.asm'
        bike = 'data/bike_riding_tilesets.asm'
        cases = [
            ('wrong_exit_direction', runtime,
             'cp PLAYER_DIR_DOWN\n    ret nz\n    ld a, [wXCoord]\n    cp 17',
             'cp PLAYER_DIR_UP\n    ret nz\n    ld a, [wXCoord]\n    cp 17',
             'cave_exit_down_collision_from_exact_carpet'),
            ('unwanted_cave_autostep', runtime,
             'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    ret z',
             'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    jr z, .down',
             'cave_interior_no_arrival_autostep'),
            ('force_down_on_arrival', runtime,
             'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    ret z',
             'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    jr z, .forceCaveDown\n.forceCaveDown\n    ld a, PLAYER_DIR_DOWN\n    ld [wPlayerDirection], a\n    ret',
             'cave_interior_no_arrival_autostep'),
            ('force_up_on_arrival', runtime,
             'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    ret z',
             'cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    jr z, .forceCaveUp\n.forceCaveUp\n    ld a, PLAYER_DIR_UP\n    ld [wPlayerDirection], a\n    ret',
             'cave_interior_no_arrival_autostep'),
            ('cave_step_on_unlocked', runtime,
             '    ; The cave interior is collision-only: never STEP_ON or override walls.\n    cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    ret z',
             '    ; The cave interior is collision-only: never STEP_ON or override walls.\n    cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    jp z, .unionCaveMouth',
             'cave_not_step_on_collision_override'),
            ('remove_cave_bike', bike, ',JOHTO_UNION_CAVE,JOHTO_MODERN,JOHTO_ILEX_FOREST,JOHTO_PARK,$FF', ',$FF',
             'union_cave_bike_gold_reference_policy'),
            ('remove_reverse_warp', runtime,
             '    db MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',
             '    ; reverse warp accidentally missing',
             'bidirectional_north_south_routes'),
            # FIX-264: previous .263 passed static tests but never reached
            # CheckWarpsCollision: ExtraWarpCheck rejected the cave FIRST.
            ('missing_cave_from_extra_warp_predicate', runtime,
             '    cp JOHTO_UNION_CAVE_1F_LOCAL_ID\n    jp z, JohtoPilotGateCollisionExitAllowed\n    cp JOHTO_ROUTE_32_LOCAL_ID',
             '    cp JOHTO_ROUTE_32_LOCAL_ID',
             'executable_cave_prewrap_to_final_guard'),
            ('preflight_calls_wrong_predicate', 'home/overworld.asm',
             '    callab JohtoPilotGateExteriorCollisionAllowed',
             '    callab JohtoPilotGateDoorWarpMatched',
             'extra_warp_calls_registered_predicate_and_sets_carry'),
            ('preflight_does_not_set_carry', 'home/overworld.asm',
             '    scf\n    ret\n.legacyExtraWarp',
             '    and a\n    ret\n.legacyExtraWarp',
             'extra_warp_calls_registered_predicate_and_sets_carry'),
            ('cave_flag_not_armed_after_entry', 'home/overworld.asm',
             '\tcp JOHTO_UNION_CAVE\n\tjr nz,.noJohtoCarpetArrival',
             '\tcp JOHTO_UNION_CAVE\n\tjr z,.noJohtoCarpetArrival',
             'cave_warp_flag_rearmed_on_map_entry'),
            ('warp_rearm_call_missing', 'home/overworld.asm',
             'callba IsPlayerStandingOnWarp',
             'callba JohtoPilotGateDoorWarpMatched',
             'cave_warp_flag_rearmed_on_map_entry'),
            ('cave_on_carpet_must_not_auto_warp', 'home/overworld.asm',
             '\tcp JOHTO_UNION_CAVE\n\tjp z,CheckWarpsNoCollisionRetry2',
             '\t; cave skip accidentally removed',
             'cave_carpet_no_step_on_warp_even_with_prewrap_enabled'),
            ('collision_not_reached_on_carry', 'home/overworld.asm',
             'jp c,CheckWarpsCollision', 'jp nc,CheckWarpsCollision',
             'collision_loop_reached_only_after_extra_carry'),
            ('final_guard_not_called', 'home/overworld.asm',
             'callab JohtoPilotGateCollisionExitAllowed',
             'callab JohtoPilotGateDoorWarpMatched',
             'collision_loop_reached_only_after_extra_carry'),
            ('break_route32_safe_step', runtime,
             '.route32CaveLanding\n    ld a, [wXCoord]\n    cp 6',
             '.route32CaveLanding\n    ld a, [wXCoord]\n    cp 5',
             'route32_outside_safety_step'),
        ]
        with tempfile.TemporaryDirectory() as temp:
            tmp = Path(temp)
            for rel in REQUIRED:
                dest = tmp / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / rel, dest)
            for title, rel, old, new, failed_check in cases:
                with self.subTest(title=title):
                    path = tmp / rel
                    original = path.read_text()
                    self.assertIn(old, original, title)
                    path.write_text(original.replace(old, new, 1))
                    try:
                        report = audit(tmp)
                        self.assertEqual('FAIL', report['status'], title)
                        failed = [x['check'] for x in report['checks'] if x['status'] == 'FAIL']
                        self.assertIn(failed_check, failed, (title, report))
                    finally:
                        path.write_text(original)


if __name__ == '__main__':
    unittest.main()
