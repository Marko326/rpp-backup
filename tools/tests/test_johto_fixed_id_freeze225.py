"""Negative injection tests: frozen Johto IDs and no premature sparse activation."""
import csv
import io
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_fixed_id_audit import audit, ROSTER, REGISTRY, CONSTANTS, RESERVED_ASM, MAKEFILE, HEADERS


class FixedIdFreeze225(unittest.TestCase):
    def mutate(self, relative, before, after, expected):
        original = (ROOT / relative).read_text(encoding='utf-8')
        self.assertIn(before, original)
        altered = original.replace(before, after, 1)
        self.assertNotEqual(original, altered)
        result = audit(ROOT, {relative: altered})
        self.assertTrue(any(expected in err for err in result), result)

    def test_baseline_and_all_222_roster_entries(self):
        self.assertEqual([], audit(ROOT))
        with (ROOT / ROSTER).open(encoding='utf8') as f:
            rows = list(csv.DictReader(f))
        self.assertEqual(222, len(rows))
        self.assertEqual(list(range(222)), [int(x['id']) for x in rows])
        self.assertEqual(222, len({x['gold_name'] for x in rows}))
        self.assertEqual(('Route37', 'EcruteakCity', 'Route38EcruteakGate',
                          'Route42EcruteakGate'),
                         (rows[21]['gold_name'], rows[22]['gold_name'],
                          rows[23]['gold_name'], rows[62]['gold_name']))

    def test_roster_reassignment_is_rejected(self):
        self.mutate(ROSTER, '23,$17,Route38EcruteakGate',
                    '23,$17,Route42EcruteakGate', 'frozen stable-ID/name/owner')

    def test_swapping_west_east_owners_is_rejected(self):
        self.mutate(ROSTER, '62,$3E,Route42EcruteakGate,东线B',
                    '62,$3E,Route42EcruteakGate,西线A', 'wrong owner')

    def test_duplicate_gold_name_is_rejected(self):
        self.mutate(ROSTER, '22,$16,EcruteakCity',
                    '22,$16,Route37', 'duplicate Gold map name')

    def test_gap_in_frozen_numbers_is_rejected(self):
        self.mutate(ROSTER, '62,$3E,Route42EcruteakGate',
                    '61,$3E,Route42EcruteakGate', 'nonunique/out-of-order')

    def test_reserved_255_id_is_rejected(self):
        self.mutate(ROSTER, '221,$DD,', '255,$FF,', 'reserved stable ID')

    def test_old_legacy_map_symbol_cannot_move(self):
        self.mutate(CONSTANTS, 'DEF JOHTO_ROUTE_36_LOCAL_ID EQU 16',
                    'DEF JOHTO_ROUTE_36_LOCAL_ID EQU 17', 'ASM ID constant missing/wrong')

    def test_active_registry_cannot_reuse_old_id(self):
        data = json.loads((ROOT / REGISTRY).read_text())
        data['maps'][20]['local_id'] = 19
        failures = audit(ROOT, {REGISTRY: json.dumps(data)})
        self.assertTrue(any('duplicate stable ID' in e or 'active slot table mismatch' in e or 'historical stable ID' in e for e in failures), failures)

    def test_duplicate_east_62_registration_rejected(self):
        data = json.loads((ROOT / REGISTRY).read_text())
        self.assertEqual([23,24,62,63,64], [m['local_id'] for m in data['maps'][-5:]])
        data['maps'].append(dict(data['maps'][-2]))
        errors = audit(ROOT, {REGISTRY: json.dumps(data)})
        self.assertTrue(any('duplicate stable ID' in e for e in errors), errors)

    def test_route37_and_ecruteak_are_active_but_next_map_reserved(self):
        data = json.loads((ROOT / REGISTRY).read_text())
        self.assertEqual(28, len(data['maps']))
        self.assertEqual([23,24,62,63,64], [m['local_id'] for m in data['maps'][-5:]])
        self.assertIn('DEF JOHTO_ECRUTEAK_CITY_LOCAL_ID EQU 22',
                      (ROOT / RESERVED_ASM).read_text(encoding='utf8'))
        self.assertIn('JohtoRoute37_h', (ROOT / HEADERS).read_text(encoding='utf8'))
        self.assertIn('JohtoEcruteakCity_h', (ROOT / HEADERS).read_text(encoding='utf8'))
        self.assertEqual([], audit(ROOT))

    def test_all_reserved_ids_exist_in_assembler_input(self):
        import re
        region = (ROOT / CONSTANTS).read_text(encoding='utf8')
        self.assertIn('INCLUDE "constants/johto_fixed_map_ids.asm"', region)
        asm = (ROOT / RESERVED_ASM).read_text(encoding='utf8')
        with (ROOT / ROSTER).open(encoding='utf8') as f:
            rows = list(csv.DictReader(f))
        observed = re.findall(r'(?m)^DEF (JOHTO_\w+_LOCAL_ID) EQU (\d+)\s*;', asm)
        self.assertEqual(201, len(observed))
        self.assertEqual([('JOHTO_' + r['gold_const_symbol'] + '_LOCAL_ID', r['id'])
                          for r in rows[21:]], observed)

    def test_missing_asm_reservation_is_rejected(self):
        self.mutate(RESERVED_ASM,
                    'DEF JOHTO_ROUTE_37_LOCAL_ID EQU 21',
                    'DEF JOHTO_ROUTE_37_LOCAL_ID EQU 26',
                    'frozen ASM reservation missing/wrong: JOHTO_ROUTE_37_LOCAL_ID')

    def test_duplicate_asm_reservation_is_rejected(self):
        src = (ROOT / RESERVED_ASM).read_text(encoding='utf8')
        modified = src + '\nDEF JOHTO_ROUTE_37_LOCAL_ID EQU 21\n'
        results = audit(ROOT, {RESERVED_ASM: modified})
        self.assertTrue(any('unique symbol mismatch' in e for e in results), results)

    def test_reserved_asm_symbol_name_cannot_be_swapped(self):
        self.mutate(RESERVED_ASM,
                    'DEF JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID EQU 62',
                    'DEF JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID EQU 62',
                    'frozen ASM reservation')

    def test_reservations_must_be_in_real_asm_include_tree(self):
        self.mutate(CONSTANTS,
                    'INCLUDE "constants/johto_fixed_map_ids.asm"',
                    '; INCLUDE disabled for test',
                    'frozen Johto ASM reservation INCLUDE')

    def test_makefile_build_preflight_must_not_be_removed(self):
        self.mutate(MAKEFILE,
                    '$(pokered_obj) $(pokeblue_obj): | johto-id-preflight',
                    '# removed build ID preflight',
                    'fixed ID preflight missing')

    def test_accidental_number_in_active_constants_not_allowed(self):
        src = (ROOT / CONSTANTS).read_text(encoding='utf8')
        src += '\nDEF JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID EQU 62\n'
        failures = audit(ROOT, {CONSTANTS: src})
        self.assertTrue(any('defined twice' in e for e in failures), failures)

    def test_fake_next_gate_header_not_sufficient_for_activation(self):
        data = json.loads((ROOT / REGISTRY).read_text())
        data['maps'].append({
            'local_id': 65, 'local_symbol': 'JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID',
            'header': 'JohtoRoute43MahoganyGate_h', 'bank': 'BANK(JohtoRoute43MahoganyGate_h)'})
        failures = audit(ROOT, {REGISTRY: json.dumps(data)})
        self.assertTrue(any('missing actual map asset maps/JohtoRoute43MahoganyGate.blk' in e
                            for e in failures), failures)

    def test_wrong_live_header_is_rejected(self):
        self.mutate(HEADERS, 'dw JohtoRuinsOfAlphOutside_h ; local $14',
                    'dw JohtoRoute36_h ; local $14', 'Header pointer order')

    def test_contract_absence_fails_closed(self):
        missing = ROOT / 'tools/johto_fixed_ids.csv'
        self.assertTrue(missing.is_file())
        self.assertTrue(any('contract missing/unreadable' in e
                            for e in audit(ROOT / 'path-does-not-exist')))

    def test_release_audit_exposes_fixed_id_errors_even_without_gold(self):
        from johto_map_release_audit import audit_project
        import tempfile
        # Do not run a gold-backed unittest sweep: this is only a wiring check.
        with tempfile.TemporaryDirectory() as temp:
            result = audit_project(ROOT, Path(temp), run_tests=False)
        # Missing Gold is expected; fixed ID hook must still exist in the gate.
        self.assertEqual('FAIL', result['status'])
        src = (ROOT / 'tools/johto_map_release_audit.py').read_text()
        self.assertIn("errors.extend('FIXED_ID: '+e for e in fixed_id_audit(root, gold_root=gold))", src)


    def test_original_gold_crosswalk_is_frozen(self):
        from johto_fixed_id_audit import GOLD_REFERENCE, _parse_gold_source
        import os
        env_path = os.environ.get('JOHTO_GOLD_ROOT') or os.environ.get('JOHTO_GOLD_SOURCE')
        # Release gate supplies a real Gold root. Unit tests without external
        # Gold skip only this independent reread, never claim source PASS.
        if not env_path:
            self.skipTest('Set JOHTO_GOLD_ROOT to rerun Gold original crosswalk')
        gold = Path(env_path)
        if not gold.is_dir():
            self.fail(f'Gold source path missing: {gold}')
        with (ROOT / GOLD_REFERENCE).open(encoding='utf-8') as f:
            gold_rows = list(csv.DictReader(f))
        self.assertEqual(gold_rows, _parse_gold_source(gold))
        self.assertEqual([], audit(ROOT, gold_root=gold))

    def test_gold_source_verification_is_never_claimed_without_gold(self):
        import contextlib
        import io
        from unittest.mock import patch
        from johto_fixed_id_audit import main
        output = io.StringIO()
        with patch('sys.argv', ['johto_fixed_id_audit.py', '--project', str(ROOT)]):
            with contextlib.redirect_stdout(output):
                result = main()
        self.assertEqual(0, result)
        self.assertIn('external Gold source comparison NOT RUN', output.getvalue())
        self.assertNotIn('cross-checked against supplied Gold source', output.getvalue())

    def test_gold_source_verification_reports_real_comparison(self):
        import contextlib
        import io
        import os
        from unittest.mock import patch
        from johto_fixed_id_audit import main
        source = os.environ.get('JOHTO_GOLD_ROOT') or os.environ.get('JOHTO_GOLD_SOURCE')
        if not source:
            self.skipTest('Gold path required to verify external source comparison')
        output = io.StringIO()
        with patch('sys.argv', ['johto_fixed_id_audit.py', '--project', str(ROOT), '--gold', source]):
            with contextlib.redirect_stdout(output):
                result = main()
        self.assertEqual(0, result)
        self.assertIn('368 original Gold maps cross-checked', output.getvalue())
        self.assertNotIn('NOT RUN', output.getvalue())

    def test_gold_pair_tampering_fails_even_without_gold_directory(self):
        self.mutate(ROSTER, '21,$15,Route37,共同起步,Violet,10,',
                    '21,$15,Route37,共同起步,Violet,11,', 'original Gold pair/size/group mismatch')

    def test_original_gold_reference_change_detected(self):
        from johto_fixed_id_audit import GOLD_REFERENCE
        self.mutate(GOLD_REFERENCE, '1,1,Olivine,OlivinePokecenter1F',
                    '1,1,Olivine,OlivineGym', 'frozen Gold 368-map reference')

    def test_private_branch_paths_allow_only_owned_assets(self):
        from johto_branch_file_guard import check_paths
        self.assertEqual([], check_paths('A', [
            'maps/JohtoRoute38.blk', 'data/mapHeaders/JohtoRoute38EcruteakGate.asm',
            'scripts/JohtoOlivineCity.asm']))
        self.assertEqual([], check_paths('B', [
            'maps/JohtoRoute42.blk', 'scripts/JohtoRoute42EcruteakGate.asm']))
        for item in ('tools/johto_native_maps.json', 'main.asm',
                     'data/mapObjects/JohtoEcruteakCity.asm',
                     'scripts/JohtoRoute42.asm', '../maps/JohtoRoute38.blk'):
            self.assertTrue(check_paths('A', [item]), item)
        self.assertTrue(check_paths('B', ['maps/JohtoRoute38.blk']))


if __name__ == '__main__':
    unittest.main()
