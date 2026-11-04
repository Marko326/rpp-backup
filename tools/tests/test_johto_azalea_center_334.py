"""REF-334 Azalea center: independent negative source mutation checks."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.johto_azalea_center_334_audit import audit

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path('/mnt/data/ref332_reference_gold/pokegold-master')


def changed(rel: str, before: str, after: str):
    src = (ROOT / rel).read_text(encoding='utf8')
    if src.count(before) != 1:
        raise AssertionError(f'non-unique mutation target for {rel}: {before}')
    return {rel: src.replace(before, after)}


class AzaleaCenter334(unittest.TestCase):
    def test_frozen_source_audit(self):
        r = audit(ROOT, GOLD if GOLD.is_dir() else None)
        self.assertEqual('PASS_STATIC_ONLY', r['status'], r['errors'])

    def test_broken_stable_slot_rejected(self):
        o = changed('data/johto_stable_id_slots.asm',
            'JOHTO_INVALID_ACTIVE_SLOT, 49, JOHTO_INVALID_ACTIVE_SLOT',
            'JOHTO_INVALID_ACTIVE_SLOT, 50, JOHTO_INVALID_ACTIVE_SLOT')
        self.assertIn('append_only_slot_and_identity', audit(ROOT,overrides=o)['errors'])

    def test_town_gate_ordinal_does_not_shift(self):
        o = changed('data/johto_south_runtime.asm',
            'db 10, 2, 2, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 10, 2, 1, JOHTO_REGISTERED_WARP_SELECTOR')
        self.assertIn('only_center_door_unlocked_existing_gate_ordinals',audit(ROOT,overrides=o)['errors'])

    def test_warp_destination_cannot_return_route32(self):
        o = changed('engine/johto_pilot_runtime.asm',
            'db MAP_REGION_JOHTO, JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID')
        self.assertIn('registered_113_exact_bidirectional_center_routes',audit(ROOT,overrides=o)['errors'])

    def test_other_closed_town_buildings_stay_closed(self):
        o = changed('engine/johto_south_geometry.asm',
            'db JOHTO_AZALEA_TOWN_LOCAL_ID, 21, 13',
            'db JOHTO_AZALEA_TOWN_LOCAL_ID, 21, 14')
        self.assertIn('door_fence_only_up_and_other_22_closed',audit(ROOT,overrides=o)['errors'])

    def test_no_down_approach_to_door(self):
        source = (ROOT/'engine/johto_south_portals.asm').read_text()
        before, target = source.split('JohtoSouthPortalBeforeStep::', 1)
        self.assertEqual(target.count('cp PLAYER_DIR_UP\n    jr z, .azaleaCenterDoor'), 1)
        o = {'engine/johto_south_portals.asm': before + 'JohtoSouthPortalBeforeStep::' + target.replace(
            'cp PLAYER_DIR_UP\n    jr z, .azaleaCenterDoor',
            'cp PLAYER_DIR_DOWN\n    jr z, .azaleaCenterDoor', 1)}
        self.assertIn('door_approach_before_and_after_step',audit(ROOT,overrides=o)['errors'])

    def test_no_wrong_heal_stamp(self):
        o = changed('engine/johto_gold_healing_machine_337.asm',
            'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a',
            'ld a, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ld [wJohtoLastHealLocalID], a')
        self.assertIn('treatment_success_records_135_not_other_centers',audit(ROOT,overrides=o)['errors'])

    def test_fly_start_denies_new_standalone_fly_stop(self):
        o = changed('engine/johto_pilot_fly_map.asm',
            'DEF JOHTO_FLY_TOWN_COUNT EQU 11',
            'DEF JOHTO_FLY_TOWN_COUNT EQU 12')
        self.assertIn('town_map_music_and_no_extra_fly_stop',audit(ROOT,overrides=o)['errors'])

    def test_fly_start_must_check_unlock(self):
        o = changed('engine/johto_pilot_fly_map.asm',
            'call .isUnlocked\n    jr z, .startRestore',
            'call .isUnlocked\n    jr nz, .startRestore')
        self.assertIn('fly_start_existing_azalea_unlocked_only',audit(ROOT,overrides=o)['errors'])

    def test_no_west_or_east_carpet_exit(self):
        o = changed('engine/johto_shared_pokecenter.asm',
            'cp PLAYER_DIR_DOWN\n    ret nz',
            'cp PLAYER_DIR_RIGHT\n    ret nz')
        self.assertIn('same_down_only_exit_and_finite_bounds',audit(ROOT,overrides=o)['errors'])

    def test_no_warp_swap_at_right_carpet(self):
        path='engine/johto_shared_pokecenter.asm'
        text=(ROOT/path).read_text()
        prefix,body=text.split('JohtoAzaleaPokecenterRuntimeObjects::',1)
        before='db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR'
        self.assertIn(before,body)
        o={path:prefix+'JohtoAzaleaPokecenterRuntimeObjects::'+body.replace(
            before,'db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR',1)}
        self.assertIn('independent_header_and_two_gold_carpets',audit(ROOT,overrides=o)['errors'])


if __name__ == '__main__':
    unittest.main()
