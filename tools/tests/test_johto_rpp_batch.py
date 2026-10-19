#!/usr/bin/env python3
"""Synthetic-source regression checks; never builds a ROM."""
import hashlib
import json
from pathlib import Path
import re
import sys
import subprocess
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_rpp_batch import batch
from johto_rpp_validate import verify, write_reports, render_previews


class JohtoBatchInventoryTest(unittest.TestCase):
    def test_all_tilesets_inventory_does_not_mutate_project(self):
        project = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            gold = root / 'gold'
            out = root / 'out'
            for subdir in ('data/maps', 'constants', 'data/tilesets', 'maps'):
                (gold / subdir).mkdir(parents=True, exist_ok=True)
            names = ['Route29', 'NewBarkTown', 'Route30',
                     'CherrygroveCity'] + [f'TestRoad{i}' for i in range(16)]
            other = ['ExampleHouse', 'AnotherHouse', 'ExampleCave']
            defs = []
            dims = []
            for name in names + other:
                johto = name in names
                tileset = ('TILESET_JOHTO' if johto else
                           'TILESET_CAVE' if name == 'ExampleCave' else
                           'TILESET_HOUSE')
                width, height = ((30, 9) if name == 'Route29' else
                                 (10, 9) if name == 'NewBarkTown' else (1, 1))
                defs.append(f'\tmap {name}, {tileset}, ROUTE, LANDMARK\n')
                const = re.sub(r'(?<!^)(?=[A-Z])', '_', name).upper()
                dims.append(f'\tmap_const {const}, {width}, {height}\n')
                if name not in ('ExampleHouse', 'AnotherHouse'):
                    (gold / 'maps' / (name + '.blk')).write_bytes(
                        bytes([0]) * width * height)
                (gold / 'maps' / (name + '.asm')).write_text(
                    ('TestFruitTree:\n\tfruittree FRUITTREE_ROUTE_29\n'
                     '\tobject_event 1, 1, SPRITE_FRUIT_TREE, STAY, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, TestFruitTree, -1\n')
                    if name == 'Route30' else '', encoding='utf-8')
            (gold / 'maps/House1.blk').write_bytes(b'\0')
            block_definitions = [f'{name}_Blocks:\n\tINCBIN "maps/{name}.blk"\n'
                                 for name in names + ['ExampleCave']]
            block_definitions += [
                'ExampleHouse_Blocks:\nAnotherHouse_Blocks:\n\tINCBIN "maps/House1.blk"\n']
            (gold / 'data/maps/blocks.asm').write_text('\n'.join(block_definitions))
            (gold / 'data/maps/maps.asm').write_text(''.join(defs))
            (gold / 'constants/map_constants.asm').write_text(''.join(dims))
            (gold / 'data/maps/attributes.asm').write_text(
                '\tmap_attributes Route30, ROUTE_30, $00, 0\n'
                '\tconnection east, Route29, ROUTE_29, 0\n')
            reference_blocks = bytearray((project / 'gfx/blocksets/johto.bst').read_bytes()[:2048])
            reference_blocks[6*16:7*16] = bytes([7])*16
            (gold / 'data/tilesets/johto_metatiles.bin').write_bytes(reference_blocks)
            (gold / 'data/tilesets/johto_collision.asm').write_text(
                '\n'.join(['\ttilecoll FLOOR, FLOOR, FLOOR, FLOOR ; 0'] * 128))
            (gold / 'data/tilesets/house_metatiles.bin').write_bytes(
                (project / 'gfx/blocksets/house.bst').read_bytes())
            (gold / 'data/tilesets/cave_metatiles.bin').write_bytes(bytes(2048))
            protected = ['gfx/blocksets/johto.bst',
                         'maps/JohtoRoute29.blk', 'maps/NewBarkTown.blk',
                         'data/johto_map_headers.asm']
            before = {path: hashlib.sha256((project/path).read_bytes()).digest()
                      for path in protected}
            result = batch(gold, project, out)
            self.assertEqual(result['maps'], 20)
            self.assertEqual(result['staged'], 20)
            self.assertEqual(result['full_gold_map_count'], 23)
            self.assertEqual(result['gold_tileset_count'], 3)
            catalog = json.loads((out/'full_gold_inventory.json').read_text())
            self.assertEqual(catalog['tilesets']['TILESET_JOHTO']['map_count'], 20)
            self.assertEqual(catalog['tilesets']['TILESET_HOUSE']['map_count'], 2)
            self.assertEqual(catalog['maps'][-3]['source_layout'], 'maps/House1.blk')
            self.assertEqual(catalog['maps'][-3]['shared_layout_with'], ['AnotherHouse'])
            self.assertEqual(catalog['maps'][-2]['shared_layout_with'], ['ExampleHouse'])
            self.assertIn('maps/House1.blk', (out/'shared_blocks_index.csv').read_text(encoding='utf-8-sig'))
            self.assertEqual(catalog['tilesets']['TILESET_HOUSE']['staged_unverified_map_count'], 2)
            self.assertEqual(catalog['tilesets']['TILESET_CAVE']['staged_unverified_map_count'], 0)
            self.assertTrue((out/'unverified_shared_metatiles_maps/ExampleHouse.blk').exists())
            self.assertTrue(catalog['tilesets']['TILESET_JOHTO']['artwork_and_collision_verified'])
            self.assertFalse(catalog['tilesets']['TILESET_HOUSE']['artwork_and_collision_verified'])
            plan = json.loads((out/'import_plan.json').read_text())
            self.assertEqual([v['name'] for v in plan['maps'][:2]],
                             ['NewBarkTown', 'Route29'])
            self.assertTrue(all(x['requires_native_region_map_support']
                                for x in plan['maps'][2:]))
            events = json.loads((out/'full_gold_events_locations.json').read_text())
            self.assertEqual(len(events['Route30']['objects']), 1)
            # Run the actual all-in-one CLI, not just its imported helpers.
            cli = [sys.executable, str(project/'tools/johto_rpp_pipeline.py'),
                   '--gold-root', str(gold), '--project', str(project),
                   '--output', str(out), '--preview-limit', '3']
            proc = subprocess.run(cli, capture_output=True, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            self.assertTrue((out/'verification/previews/Route29.png').exists())
            first = {p.relative_to(out): hashlib.sha256(p.read_bytes()).digest()
                     for p in out.rglob('*') if p.is_file()}
            self.assertEqual(batch(gold, project, out)['full_gold_map_count'], 23)
            second = {p.relative_to(out): hashlib.sha256(p.read_bytes()).digest()
                      for p in out.rglob('*') if p.is_file()}
            self.assertEqual(first, second)
            # An independent verifier rejects unsafe staged output rather
            # than trusting the converter's own summary.
            audit = verify(out, gold, project)
            self.assertEqual(audit['status'], 'OFFLINE_REVIEW_ONLY', [(x['name'], x['issues']) for x in audit['maps'] if x['static_status'] == 'FAIL'] + audit['problems'])
            self.assertEqual(audit['summary']['static_fail'], 0)
            self.assertEqual(audit['summary']['maps'], 23)
            self.assertEqual(audit['readiness']['compiled_rom'], 'NOT_RUN')
            render_previews(out, gold, project, audit, 4)
            write_reports(out, audit)
            self.assertTrue((out/'verification/previews/NewBarkTown.png').exists())
            self.assertTrue(any(row.get('preview') for row in audit['maps']))
            cmd = [sys.executable, str(project/'tools/johto_rpp_pipeline.py'),
                   '--gold-root', str(gold), '--project', str(project),
                   '--output', str(out), '--audit-only', '--preview-limit', '2']
            check = subprocess.run(cmd, text=True, capture_output=True)
            self.assertEqual(check.returncode, 0, check.stderr + check.stdout)
            self.assertTrue((out/'verification/index.html').exists())
            self.assertIn('通过 ≠ 游戏可运行',
                          (out/'verification/index.html').read_text())
            candidate_path = out/'candidate_maps/Route30.blk'
            untouched = candidate_path.read_bytes()
            candidate_path.write_bytes(bytes([255]))
            corrupt = verify(out, gold, project)
            self.assertEqual(corrupt['status'], 'FAILED')
            self.assertIn('candidate_block_index_overflow', [
                i['code'] for r in corrupt['maps'] if r['name'] == 'Route30'
                for i in r['issues']])
            candidate_path.write_bytes(untouched)
            events_path = out/'full_gold_events_locations.json'
            preserved_events = events_path.read_bytes()
            bad_events = json.loads(preserved_events)
            bad_events['Route30']['objects'][0]['x'] = 999
            events_path.write_text(json.dumps(bad_events))
            self.assertEqual(verify(out, gold, project)['status'], 'FAILED')
            events_path.write_bytes(preserved_events)
            inventory_path = out/'full_gold_inventory.json'
            original_inventory = inventory_path.read_bytes()
            changed_inventory = json.loads(original_inventory)
            changed_inventory['maps'][-3]['source_layout'] = 'maps/ExampleHouse.blk'
            inventory_path.write_text(json.dumps(changed_inventory))
            self.assertIn('source_layout_reference_mismatch',
                          [i['code'] for row in verify(out, gold, project)['maps']
                           for i in row['issues']])
            inventory_path.write_bytes(original_inventory)
            protected_map = out/'candidate_maps/Route29.blk'
            original_ref = protected_map.read_bytes()
            protected_map.write_bytes(bytes([1]) + original_ref[1:])
            bad_ref = verify(out, gold, project)
            self.assertIn('reference_map_mutated', [
                i['code'] for r in bad_ref['maps'] if r['name'] == 'Route29'
                for i in r['issues']])
            protected_map.write_bytes(original_ref)
            self.assertEqual(verify(out, gold, project)['status'], 'OFFLINE_REVIEW_ONLY')
            (gold/'data/tilesets/house_metatiles.bin').write_bytes(bytes(2048))
            batch(gold, project, out)
            self.assertFalse((out/'unverified_shared_metatiles_maps/ExampleHouse.blk').exists())
            after = {path: hashlib.sha256((project/path).read_bytes()).digest()
                     for path in protected}
            self.assertEqual(before, after)




class ReusableMapRuntimeReview(unittest.TestCase):
    def test_native_map_runtime_review_is_structural_only(self):
        from johto_rpp_pipeline import review_rpp_integration
        root = Path(__file__).resolve().parents[2]
        check = review_rpp_integration(root, 'JohtoRoute33',
                                        {'map': 'Route33', 'evidence': {'warp_events': 1}})
        self.assertEqual(check['errors'], [])
        self.assertEqual(check['rpp_active_warps'], 1)
        self.assertTrue(check['warp_contract_present'])
        self.assertEqual(check['registration']['registration_strategy'], 'native')
        self.assertEqual(check['native_feature_metadata']['fly'], 'FORBIDDEN')
        self.assertTrue(check['fly_destination_is_not_fly_use'])
        self.assertFalse(check['runtime_approved'])

    def test_warp_contract_mismatch_is_a_blocker(self):
        from johto_rpp_pipeline import review_rpp_integration
        from unittest.mock import patch
        root = Path(__file__).resolve().parents[2]
        info = {'map': 'Route33', 'evidence': {'warp_events': 1}}
        with patch('johto_rpp_pipeline.rpp_warps', return_value=[]):
            result = review_rpp_integration(root, 'JohtoRoute33', info)
        self.assertIn('active Warp count differs from existing door contract', result['errors'])
        self.assertEqual(result['status'], 'STRUCTURAL_ERRORS')
        self.assertFalse(result['runtime_approved'])

    def test_registration_failure_cannot_be_reported_as_ready(self):
        from johto_rpp_pipeline import review_rpp_integration
        from unittest.mock import patch
        root = Path(__file__).resolve().parents[2]
        info = {'map': 'Route33', 'evidence': {'warp_events': 1}}
        with patch('johto_rpp_pipeline.audit_registration',
                   return_value={'failed_checks':['MAIN_HEADER_INCLUDE']}):
            result = review_rpp_integration(root, 'JohtoRoute33', info)
        self.assertIn('MAIN_HEADER_INCLUDE', result['errors'])
        self.assertEqual(result['status'], 'STRUCTURAL_ERRORS')



class SharedProjectGateNotMapApproval(unittest.TestCase):
    def test_shared_gate_is_reused_and_does_not_approve_field_moves(self):
        from johto_rpp_pipeline import run_project_static_gate
        from unittest.mock import patch
        with patch('johto_map_release_audit.audit_project', return_value={
            'status': 'PASS', 'errors': [], 'tests': 349, 'skipped': 0,
            'build_performed': False}) as audit:
            result = run_project_static_gate(Path('/rpp'), Path('/gold'),
                                             {'errors': [], 'status': 'STATIC_STRUCTURE_PRESENT_REVIEW_RUNTIME'})
        audit.assert_called_once_with(Path('/rpp'), Path('/gold'),
                                      expected_version=None, run_tests=True)
        self.assertEqual(result['status'], 'PROJECT_STATIC_PASS_MAP_RUNTIME_PENDING')
        self.assertFalse(result['map_specific_runtime_verified'])
        self.assertFalse(result['field_moves_approved'])
        self.assertFalse(result['phone_accepted'])

    def test_shared_pass_cannot_hide_map_structure_error(self):
        from johto_rpp_pipeline import run_project_static_gate
        from unittest.mock import patch
        with patch('johto_map_release_audit.audit_project', return_value={
            'status': 'PASS', 'errors': [], 'tests': 349, 'skipped': 0,
            'build_performed': False}):
            result = run_project_static_gate(Path('/rpp'), Path('/gold'),
                                             {'errors': ['bad Warp']})
        self.assertEqual(result['status'], 'STATIC_FAIL')
        self.assertIn('MAP_STRUCTURE: bad Warp', result['errors'])

    def test_failed_project_gate_cannot_be_called_runtime_ready(self):
        from johto_rpp_pipeline import run_project_static_gate
        from unittest.mock import patch
        with patch('johto_map_release_audit.audit_project', return_value={
            'status': 'FAIL', 'errors': ['Gold missing'], 'tests': 0, 'skipped': 0,
            'build_performed': False}):
            result = run_project_static_gate(Path('/rpp'), Path('/gold'), None)
        self.assertEqual(result['status'], 'STATIC_FAIL')
        self.assertIn('Gold missing', result['errors'])



class GoldMapOnboardingSignals(unittest.TestCase):
    def test_field_moves_are_distinct_and_never_automatically_approved(self):
        from johto_rpp_pipeline import make_map_onboarding
        with tempfile.TemporaryDirectory() as td:
            gold = Path(td)
            (gold/'data/maps').mkdir(parents=True)
            (gold/'maps').mkdir()
            (gold/'data/maps/maps.asm').write_text(
                'map ExampleRoad, TILESET_JOHTO_MODERN, ROUTE, LANDMARK_A\n'
                'map ExampleCave, TILESET_CAVE, CAVE, LANDMARK_B\n'
                'map ExampleCity, TILESET_JOHTO_MODERN, TOWN, LANDMARK_C\n')
            for name in ('ExampleRoad', 'ExampleCave', 'ExampleCity'):
                (gold/'maps'/f'{name}.asm').write_text(
                    'warp_event 1, 2, TARGET, 1\nobject_event 1, 1, SPRITE, DATA\n')
            art = {'width': 10, 'height': 9, 'tileset': 'johto_modern'}
            geometry = {'collision_roles': {'FLOOR': 120}, 'special_cells': [],
                        'hops': [], 'unsafe_hop_candidates': []}
            def statuses(name, labels):
                result = make_map_onboarding(gold, name, art, {**geometry, 'collision_roles': labels})
                self.assertFalse(result['runtime_approved'])
                return {x['id']: x for x in result['checks']}
            road = statuses('ExampleRoad', {'FLOOR': 120})
            self.assertEqual(road['fly_use']['status'], 'REVIEW_REQUIRED')
            self.assertEqual(road['fly_destination']['status'], 'NOT_APPLICABLE')
            self.assertEqual(road['surf']['status'], 'NOT_APPLICABLE')
            self.assertEqual(road['dig_escape_rope']['status'], 'NOT_APPLICABLE')
            cave = statuses('ExampleCave', {'FLOOR': 50, 'WATER': 70})
            self.assertEqual(cave['fly_use']['status'], 'NOT_APPLICABLE')
            self.assertEqual(cave['surf']['status'], 'REVIEW_REQUIRED')
            self.assertEqual(cave['dig_escape_rope']['status'], 'REVIEW_REQUIRED')
            city = statuses('ExampleCity', {'FLOOR': 120})
            self.assertEqual(city['fly_destination']['status'], 'REVIEW_REQUIRED')
            self.assertFalse(any(x['runtime_approved'] for x in city.values()))

    def test_unregistered_gold_environment_fails_closed(self):
        from johto_rpp_pipeline import make_map_onboarding
        with tempfile.TemporaryDirectory() as td:
            gold=Path(td)
            (gold/'data/maps').mkdir(parents=True)
            (gold/'data/maps/maps.asm').write_text('')
            with self.assertRaises(ValueError):
                make_map_onboarding(gold, 'FakeRoad',
                    {'width': 1, 'height': 1, 'tileset': 'johto_modern'},
                    {'collision_roles': {}, 'special_cells': [], 'hops': [],
                     'unsafe_hop_candidates': []})




class ReviewedGoldGeometryTests(unittest.TestCase):
    """Map-independent regression contract: Gold inputs, runtime mask and safe hops."""
    @classmethod
    def setUpClass(cls):
        import os
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
        if not (cls.gold/'maps/Route33.blk').is_file():
            raise AssertionError('full Gold source required')

    def setUp(self):
        import shutil
        from johto_indoor_collision_adapter import audit_reviewed_geometry
        self.audit = audit_reviewed_geometry
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for rel in ('tools/johto_gold_geometry_contracts.json',
                    'maps/JohtoRoute33.blocked_mask.bin'):
            dst = self.root/rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(Path(__file__).resolve().parents[2]/rel, dst)
        self.specfile = self.root/'tools/johto_gold_geometry_contracts.json'
        self.maskfile = self.root/'maps/JohtoRoute33.blocked_mask.bin'

    def _mutate(self, change):
        data = json.loads(self.specfile.read_text())
        change(data['maps'][0])
        self.specfile.write_text(json.dumps(data))
        self.assertTrue(self.audit(self.root,self.gold))

    def test_gold_exact_mask_and_reviewed_role_counts(self):
        self.assertEqual(self.audit(self.root,self.gold), [])
        spec = json.loads(self.specfile.read_text())['maps'][0]
        self.assertEqual((spec['width_cells'],spec['height_cells']), (20,18))
        self.assertEqual((spec['blocked_count'],spec['walkable_count']), (182,178))
        self.assertEqual(sum(spec['collision_roles'].values()), 360)

    def test_all_seven_safe_hops_are_preserved(self):
        spec = json.loads(self.specfile.read_text())['maps'][0]
        self.assertEqual({tuple(h) for h in spec['hops']},
                         {(9,10,-1,0),(9,11,-1,0),(9,12,-1,0),
                          (9,12,0,1),(10,12,0,1),(11,12,0,1),(12,12,0,1)})
        self.assertEqual(self.audit(self.root,self.gold), [])

    def test_image_collision_aliases_require_coordinate_guard(self):
        spec = json.loads(self.specfile.read_text())['maps'][0]
        self.assertEqual(spec['ambiguous_visual_ids'], ['05','3C','3E'])
        self.assertEqual(self.audit(self.root,self.gold), [])

    def test_blocked_cave_cell_cannot_be_approved(self):
        spec = json.loads(self.specfile.read_text())['maps'][0]
        self.assertEqual(spec['required_blocked_special_cells'], [[11,9,'CAVE']])
        self.assertEqual(self.audit(self.root,self.gold), [])

    def test_mask_bit_mutation_is_rejected(self):
        raw = bytearray(self.maskfile.read_bytes())
        raw[20] ^= 4
        self.maskfile.write_bytes(raw)
        self.assertTrue(self.audit(self.root,self.gold))

    def test_wrong_hop_landing_mutation_is_rejected(self):
        self._mutate(lambda s: s['hops'][0].__setitem__(0, s['hops'][0][0]+1))

    def test_removed_collision_role_is_rejected(self):
        self._mutate(lambda s: s['collision_roles'].pop('UP_WALL'))

    def test_fake_runtime_approval_is_rejected(self):
        self._mutate(lambda s: s.__setitem__('review_only', False))

    def test_unregistered_map_mask_cannot_silently_disappear(self):
        self.maskfile.unlink()
        self.assertTrue(self.audit(self.root,self.gold))

    def test_runtime_asset_must_not_live_under_tools(self):
        self._mutate(lambda s: s.__setitem__('rpp_blocked_mask',
                                            'tools/geometry/Route33.blocked_mask.bin'))



class AzaleaGoldCandidateTests(unittest.TestCase):
    """Next-map source regression, using the shared converter; no runtime approval."""
    @classmethod
    def setUpClass(cls):
        import os
        from johto_indoor_tiles_converter import stage_preserved_gold_tileset
        from johto_indoor_collision_adapter import plan_gold_quadrant_collision
        cls.stage = staticmethod(stage_preserved_gold_tileset)
        cls.geometry = staticmethod(plan_gold_quadrant_collision)
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
        cls.rpp = Path(__file__).resolve().parents[2]
        if not (cls.gold / 'maps/AzaleaTown.blk').is_file():
            raise AssertionError('full Gold source required for Azalea candidate')

    def test_staged_map_matches_gold_without_new_tileset(self):
        with tempfile.TemporaryDirectory() as td:
            art = self.stage(self.gold, Path(td), 'AzaleaTown', 'johto_modern')
            candidate = self.rpp / 'maps/JohtoAzaleaTown.blk'
            self.assertEqual(candidate.read_bytes(),
                             (self.gold / 'maps/AzaleaTown.blk').read_bytes())
            self.assertEqual(candidate.read_bytes(),
                             (Path(td) / 'preserved_gold_art_candidate/AzaleaTown.blk').read_bytes())
            self.assertEqual((art['width'], art['height']), (20, 9))
            self.assertTrue(art['candidate_only'])
            self.assertFalse(art['engine_implementation'])
            self.assertEqual((self.rpp / 'gfx/blocksets/johto_modern.bst').read_bytes(),
                             (Path(td) / 'preserved_gold_art_candidate/johto_modern.bst').read_bytes())

    def test_two_cell_gold_hops_are_not_rejected_by_third_wall(self):
        geometry, mask = self.geometry(self.gold, 'AzaleaTown', 'johto_modern')
        self.assertEqual((geometry['width_cells'], geometry['height_cells']), (40, 18))
        self.assertEqual(len(mask), 90)
        self.assertEqual((geometry['blocked_count'], geometry['walkable_count']), (447, 273))
        self.assertEqual(len(geometry['hops']), 10)
        self.assertEqual(geometry['unsafe_hop_candidates'], [])
        self.assertIn((10, 6), {(h['x'], h['y']) for h in geometry['hops']})
        self.assertFalse(geometry['runtime_ready'])


if __name__ == '__main__':
    unittest.main()
