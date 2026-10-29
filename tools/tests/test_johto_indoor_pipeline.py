"""Second-batch regression tests for the current stable-ID indoor pipeline.

Gold-dependent cases use MUS-1.0.1 via JOHTO_GOLD_SOURCE. All candidate outputs
are isolated in temporary directories; these tests never edit game assets.
"""
from __future__ import annotations
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))

from johto_gatehouse_behavior_audit import audit as audit_gatehouses
from johto_indoor_collision_adapter import check as check_collision
from johto_indoor_pipeline import run as run_indoor_pipeline
from johto_indoor_registration_generator import generate as generate_registration
from johto_indoor_tiles_converter import build_mapping
from johto_warp_arrival_audit import audit as audit_arrival


ARRIVAL_FILES = (
    'data/johto_pilot_map_headers.asm', 'data/johto_indoor_house.asm',
    'engine/johto_pilot_runtime.asm', 'home/overworld.asm', 'home.asm',
    'engine/overworld/npc_movement.asm', 'engine/overworld/doors.asm',
    'data/warp_tile_ids.asm', 'tools/johto_pilot_door_contracts.json',
    'maps/johto_pilot/CherrygroveCity.runtime.blk',
    'maps/johto_pilot/GuideGentsHouse.runtime.blk',
    'gfx/blocksets/johto.bst', 'gfx/blocksets/johto_house.bst',
    'gfx/tilesets/johto.tilecoll', 'gfx/tilesets/johto_house.tilecoll',
)
REGISTRATION_FILES = (
    'constants/johto_fixed_map_ids.asm', 'constants/region_map_constants.asm',
    'data/johto_stable_id_slots.asm', 'data/johto_header_descriptors.asm',
    'data/johto_pilot_runtime_assets.asm', 'data/johto_pilot_source_resources.asm',
    'data/johto_pilot_map_headers.asm', 'engine/johto_pilot_runtime.asm',
    'main.asm', 'data/johto_indoor_house.asm', 'home.asm',
    'maps/johto_pilot/GuideGentsHouse.runtime.blk',
    'maps/johto_pilot/GuideGentsHouse.reference.blk',
    'gfx/blocksets/johto_house.bst',
)
GATE_FILES = tuple(dict.fromkeys(ARRIVAL_FILES + (
    'constants/johto_fixed_map_ids.asm', 'constants/region_map_constants.asm',
    'data/johto_stable_id_slots.asm', 'data/johto_gate_runtime.asm',
)))


def copy_files(source_root: Path, target_root: Path, relatives: tuple[str, ...]) -> Path:
    for relative in relatives:
        src = source_root / relative
        dst = target_root / relative
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    return target_root


class IndoorStaticRegistrationTests(unittest.TestCase):
    def test_current_house_registration_passes(self):
        report = generate_registration(ROOT, 'GuideGentsHouse')
        self.assertEqual(report['status'], 'PRESENT_STATIC_ONLY', report['errors'])
        self.assertEqual(len(report['checks']), 14)
        self.assertFalse(report['asm_written'])

    def test_old_six_slot_assert_is_rejected_by_indoor_registration(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, REGISTRATION_FILES)
            p = root / 'data/johto_stable_id_slots.asm'
            source = p.read_text(encoding='utf-8')
            self.assertIn('ASSERT NUM_JOHTO_ACTIVE_MAPS == 9', source)
            p.write_text(source.replace('ASSERT NUM_JOHTO_ACTIVE_MAPS == 9',
                                        'ASSERT NUM_JOHTO_ACTIVE_MAPS == 6'), encoding='utf-8')
            report = generate_registration(root, 'GuideGentsHouse')
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check'] == 'STABLE_ID_SLOT' and x['status'] == 'FAIL'
                                for x in report['checks']))

    def test_missing_header_descriptor_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, REGISTRATION_FILES)
            p = root / 'data/johto_header_descriptors.asm'
            p.write_text(p.read_text().replace('dw JohtoGuideGentsHouseRuntimeHeader\n', ''), encoding='utf-8')
            report = generate_registration(root, 'GuideGentsHouse')
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check'] == 'HEADER_DESCRIPTOR' and x['status'] == 'FAIL'
                                for x in report['checks']))

    def test_unknown_map_does_not_generate_asm_or_fake_pass(self):
        report = generate_registration(ROOT, 'SomeFutureHouse')
        self.assertEqual(report['status'], 'UNSUPPORTED_MAP_REQUIRES_MANUAL_CONTRACT')
        self.assertFalse(report['asm_written'])


class IndoorGoldDependentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        configured = os.environ.get('JOHTO_GOLD_SOURCE')
        if not configured or not (Path(configured) / 'data/maps/maps.asm').is_file():
            raise unittest.SkipTest('set JOHTO_GOLD_SOURCE to MUS-1.0.1 source')
        cls.gold = Path(configured).resolve()

    def test_warp_arrival_contract_passes_against_mus(self):
        report = audit_arrival(ROOT, self.gold)
        self.assertEqual(report['status'], 'PASS_STATIC_ONLY', report['errors'])
        self.assertEqual(len(report['checks']), 17)
        self.assertFalse(report['runtime_verified'])
        self.assertFalse(report['phone_accepted'])
        self.assertEqual(report['gold_roles']['GuideGentsHouse(2,7)'], 'WARP_CARPET_DOWN')

    def test_wrong_room_exit_coordinate_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, ARRIVAL_FILES)
            p = root / 'data/johto_indoor_house.asm'
            p.write_text(p.read_text().replace(
                'db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                'db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR', 1), encoding='utf-8')
            report = audit_arrival(root, self.gold)
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check'] == 'current_warp_coordinates' and x['status'] == 'FAIL'
                                for x in report['checks']))

    def test_wrong_auto_step_direction_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, ARRIVAL_FILES)
            p = root / 'engine/overworld/npc_movement.asm'
            text = p.read_text(encoding='utf-8')
            start = text.index('PlayerStepOutFromDoor:')
            end = text.index('_EndNPCMovementScript:', start)
            body = text[start:end]
            self.assertIn('ld a, D_DOWN', body)
            p.write_text(text[:start] + body.replace('ld a, D_DOWN', 'ld a, D_UP', 1) + text[end:], encoding='utf-8')
            report = audit_arrival(root, self.gold)
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check'] == 'auto_step_outdoor_only' and x['status'] == 'FAIL'
                                for x in report['checks']))

    def test_collision_adapter_uses_the_selected_current_house_tileset(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'collision'
            output.mkdir()
            art, _ = build_mapping(ROOT, self.gold, 'GuideGentsHouse', 'house', 'johto_house')
            report = check_collision(ROOT, self.gold, art, 'johto_house')
            self.assertEqual(report['rpp_tilecoll_file'], 'gfx/tilesets/johto_house.tilecoll')
            self.assertEqual(report['status'], 'COLLISION_REVIEW_REQUIRED')
            self.assertGreater(len(report['issues']), 0)
            self.assertFalse(report['auto_approve'])

    def test_gatehouse_inventory_has_correct_gold_directional_roles(self):
        report = audit_gatehouses(ROOT, self.gold)
        self.assertEqual(report['status'], 'PASS_REFERENCE_ONLY', report['errors'])
        self.assertEqual(report['gold_gate_inventory']['maps'], 24)
        self.assertEqual(report['gold_gate_inventory']['warp_events'], 100)
        self.assertEqual(report['gold_gate_inventory']['collision_roles'], {
            'WARP_CARPET_DOWN': 30, 'DOOR': 26,
            'WARP_CARPET_LEFT': 22, 'WARP_CARPET_RIGHT': 22})
        self.assertEqual(report['current_active_gate_ids'], [6])
        self.assertFalse(report['phone_accepted'])

    def test_activating_gate_id_without_contract_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, GATE_FILES)
            contract = root / 'tools/johto_pilot_door_contracts.json'
            data = json.loads(contract.read_text())
            data['gatehouse_activation_policy']['active_gatehouse_contracts'] = []
            contract.write_text(json.dumps(data), encoding='utf-8')
            report = audit_gatehouses(root, self.gold)
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check'] == 'no_uncontracted_gatehouse_activation' and x['status'] == 'FAIL'
                                for x in report['checks']))

    def test_outdoor_direction_carpet_mislabeled_step_on_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, GATE_FILES)
            contract = root / 'tools/johto_pilot_door_contracts.json'
            data = json.loads(contract.read_text())
            rows = data['gatehouse_activation_policy']['active_gatehouse_contracts'][0]['warp_contracts']
            self.assertEqual(rows[0]['trigger'], 'COLLISION_ONLY')
            rows[0]['trigger'] = 'STEP_ON'
            contract.write_text(json.dumps(data), encoding='utf-8')
            result = audit_gatehouses(root, self.gold)
            self.assertEqual(result['status'], 'FAIL')
            self.assertTrue(any(c['check']=='active_gatehouse_exact_contract' and c['status']=='FAIL'
                                for c in result['checks']))

    def test_mus_gate_outdoor_carpet_roles_are_directional(self):
        from johto_gold_door_audit import GoldCollisionIndex
        index = GoldCollisionIndex(self.gold)
        for map_name,x,y,role in (
            ('Route31',4,6,'WARP_CARPET_LEFT'),
            ('Route31',4,7,'WARP_CARPET_LEFT'),
            ('VioletCity',39,24,'WARP_CARPET_RIGHT'),
            ('VioletCity',39,25,'WARP_CARPET_RIGHT'),
        ):
            self.assertEqual(index.role_at(map_name,x,y),role)

    def test_gate_wrong_warp_position_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, GATE_FILES)
            path = root / 'data/johto_gate_runtime.asm'
            text = path.read_text()
            self.assertIn('db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR', text)
            path.write_text(text.replace('db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                                         'db 4, 8, 0, JOHTO_REGISTERED_WARP_SELECTOR'))
            report = audit_gatehouses(root, self.gold)
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check']=='active_gatehouse_exact_contract' and x['status']=='FAIL'
                                for x in report['checks']))

    def test_gate_missing_collision_facing_guard_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            copy_files(ROOT, root, GATE_FILES)
            path = root / 'home/overworld.asm'
            text = path.read_text()
            self.assertIn('callab JohtoPilotGateCollisionExitAllowed', text)
            path.write_text(text.replace('callab JohtoPilotGateCollisionExitAllowed',
                                         'callab JohtoPilotGateDoorWarpMatched', 1))
            report = audit_gatehouses(root, self.gold)
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(x['check']=='gate_collision_direction_guard' and x['status']=='FAIL'
                                for x in report['checks']))

    def test_complete_indoor_pipeline_is_isolated_and_review_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'report'
            before = (ROOT / 'maps/johto_pilot/GuideGentsHouse.runtime.blk').read_bytes()
            report = run_indoor_pipeline(ROOT, self.gold, output)
            self.assertEqual(report['status'], 'OFFLINE_REVIEW_REQUIRED', report['errors'])
            self.assertEqual(report['errors'], [])
            self.assertFalse(report['candidate_runtime_approved'])
            self.assertFalse(report['rom_built'])
            self.assertFalse(report['phone_accepted'])
            self.assertTrue((output / '00_pipeline_summary.json').is_file())
            self.assertTrue((output / '09_source_fingerprints.json').is_file())
            self.assertTrue((output / '04_art_mapping/GuideGentsHouse.pixel_candidate.blk').is_file())
            self.assertEqual(before, (ROOT / 'maps/johto_pilot/GuideGentsHouse.runtime.blk').read_bytes())


if __name__ == '__main__':
    unittest.main()
