"""Standalone negative regression cases for Route32 roadside center."""
from pathlib import Path
import unittest
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.johto_route32_center_333_audit import audit

ROOT = Path(__file__).resolve().parents[2]


def overridden(rel, old, new):
    source=(ROOT/rel).read_text(encoding='utf8')
    if source.count(old) < 1:
        raise AssertionError(f'{rel} missing expected mutation source')
    return {rel:source.replace(old,new,1)}


class Route32Center333(unittest.TestCase):
    def test_frozen_contract(self):
        report=audit(ROOT)
        self.assertEqual(report['status'], 'PASS_STATIC_ONLY', report['errors'])

    def test_closed_outdoor_door_caught(self):
        overrides=overridden('engine/johto_pilot_runtime.asm',
            'cp PLAYER_DIR_UP\n    jr z, .route32NorthDoor',
            'cp PLAYER_DIR_UP\n    jr z, .route32Cave')
        self.assertIn('north_door_post_step_warp_and_cave_preserved',audit(ROOT,overrides=overrides)['errors'])

    def test_return_misdirected_to_cherrygrove_caught(self):
        overrides=overridden('engine/johto_pilot_runtime.asm',
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',
            'db MAP_REGION_JOHTO, JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_LOCAL_ID')
        self.assertIn('three_exact_registered_routes',audit(ROOT,overrides=overrides)['errors'])

    def test_heal_stamping_cherrygrove_caught(self):
        overrides=overridden('engine/johto_gold_healing_machine_337.asm',
            'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a',
            'ld a, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ld [wJohtoLastHealLocalID], a')
        self.assertIn('healing_stamps_actual_center_not_cherrygrove',audit(ROOT,overrides=overrides)['errors'])

    def test_added_fly_stop_caught(self):
        overrides=overridden('engine/johto_pilot_fly_map.asm',
            'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID',
            'JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID') if 'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID' in (ROOT/'engine/johto_pilot_fly_map.asm').read_text() else {
                'engine/johto_pilot_fly_map.asm':(ROOT/'engine/johto_pilot_fly_map.asm').read_text()+'\n; JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID\n'}
        self.assertIn('town_map_uses_route32_without_new_fly',audit(ROOT,overrides=overrides)['errors'])

    def test_carpet_warp_cardinality_caught(self):
        overrides=overridden('engine/johto_shared_pokecenter.asm',
            'db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR',
            'db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR')
        self.assertIn('indoor_carpet_two_returns_to_route32',audit(ROOT,overrides=overrides)['errors'])


if __name__=='__main__':
    unittest.main()
