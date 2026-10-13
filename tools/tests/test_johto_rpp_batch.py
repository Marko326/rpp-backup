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
            (gold / 'data/tilesets/johto_metatiles.bin').write_bytes(
                (project / 'gfx/blocksets/johto.bst').read_bytes()[:2048])
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


if __name__ == '__main__':
    unittest.main()
