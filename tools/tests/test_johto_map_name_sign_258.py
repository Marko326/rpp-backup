"""Regression/fault-injection: missing any future Johto gate or route popup must fail."""
from __future__ import annotations
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_map_name_sign_audit import audit
from johto_pilot_migration_audit import audit_project

FILES = (
    'tools/johto_map_name_sign_contracts.json',
    'engine/overworld/map_name_sign.asm',
    'engine/fly_town_map_helpers.asm',
    'text/map_names.asm',
    'data/johto_pilot_runtime_assets.asm',
    'constants/region_map_constants.asm',
    'constants/johto_fixed_map_ids.asm',
)


class MapNameSign258Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for relative in FILES:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)

    def tearDown(self):
        self.tmp.cleanup()

    def mutate(self, relative: str, old: str, new: str) -> None:
        path = self.root / relative
        source = path.read_text(encoding='utf-8')
        self.assertIn(old, source, f'fixture has changed: {old}')
        path.write_text(source.replace(old, new, 1), encoding='utf-8')

    def expect_fails(self, name: str):
        report = audit(self.root)
        self.assertEqual(report['status'], 'FAIL')
        self.assertTrue(any(name in error for error in report['errors']), report['errors'])

    def test_all_active_map_signs_and_save_names_pass(self):
        report = audit(self.root)
        self.assertEqual(report['status'], 'PASS_STATIC_ONLY', report['errors'])
        self.assertEqual(len([c for c in report['checks'] if c['check'].startswith('town_name_')]), 21)

    def test_missing_north_gate_reproduces_257_bug(self):
        self.mutate('engine/overworld/map_name_sign.asm',
                    '\tcp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n\tret z\n', '')
        self.expect_fails('all_neutral_gates')

    def test_losing_a_previously_working_south_gate_also_fails(self):
        self.mutate('engine/overworld/map_name_sign.asm',
                    '\tcp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID\n\tret z\n', '')
        self.expect_fails('all_neutral_gates')

    def test_added_runtime_slot_without_contract_fails_closed(self):
        self.mutate('data/johto_pilot_runtime_assets.asm',
                    'JohtoPilotRuntimeResourceDescriptors::',
                    'JohtoPilotRuntimeResourceDescriptors::\n    db JOHTO_ROUTE_37_LOCAL_ID, 0, 0, 0')
        self.expect_fails('active_map_coverage')

    def test_contract_missing_existing_route_fails_closed(self):
        path = self.root / 'tools/johto_map_name_sign_contracts.json'
        data = json.loads(path.read_text())
        data['active_maps'] = [m for m in data['active_maps'] if m['id'] != 'JOHTO_ROUTE_36_LOCAL_ID']
        path.write_text(json.dumps(data), encoding='utf-8')
        self.expect_fails('active_map_coverage')

    def test_new_route_missing_popup_dispatch_fails(self):
        self.mutate('engine/overworld/map_name_sign.asm',
                    '\tcp JOHTO_ROUTE_36_LOCAL_ID\n\tjr z, .johtoRoute36', '')
        self.expect_fails('all_named_dispatches')

    def test_popup_jumps_to_generic_johto_fallback_fails(self):
        self.mutate('engine/overworld/map_name_sign.asm',
                    '\tld hl, .JohtoRoute36Name', '\tld hl, .JohtoUnknownName')
        self.expect_fails('popup_name_JOHTO_ROUTE_36_LOCAL_ID')

    def test_wrong_popup_literal_fails_even_if_dispatch_is_present(self):
        self.mutate('engine/overworld/map_name_sign.asm',
                    '.JohtoRoute36Name: db "Route 36@"', '.JohtoRoute36Name: db "Johto@"')
        self.expect_fails('popup_name_JOHTO_ROUTE_36_LOCAL_ID')

    def test_save_and_town_map_label_mismatch_fails(self):
        self.mutate('engine/fly_town_map_helpers.asm',
                    'JohtoPilotRoute36Name:: db "Route 36@"',
                    'JohtoPilotRoute36Name:: db "Johto@"')
        self.expect_fails('town_name_JOHTO_ROUTE_36_LOCAL_ID')

    def test_region_guard_removed_fails(self):
        self.mutate('engine/overworld/map_name_sign.asm',
                    '\tcp MAP_REGION_JOHTO\n\tjr nz, .legacyNeutralMap',
                    '\tcp MAP_REGION_JOHTO\n\tnop')
        self.expect_fails('region_handle_guard')

    def test_neutral_gate_misclassified_as_road_fails(self):
        path = self.root / 'tools/johto_map_name_sign_contracts.json'
        data = json.loads(path.read_text())
        gate = next(m for m in data['active_maps'] if m['id'] == 'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID')
        gate['role'] = 'named'
        gate['name'] = 'Route 36'
        path.write_text(json.dumps(data), encoding='utf-8')
        self.expect_fails('contract_policy_JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID')

    def test_integrated_migration_report_contains_sign_check(self):
        # Check the main audit has been wired up: use full project rather than
        # replacing dozens of unrelated Gold/map assets in this small fixture.
        report = audit_project(ROOT)
        self.assertEqual(report['status'], 'PASS_STATIC_ONLY', report['errors'])
        self.assertTrue(any(c['check'] == 'johto_map_sign_all_neutral_gates' for c in report['checks']))


if __name__ == '__main__':
    unittest.main()
