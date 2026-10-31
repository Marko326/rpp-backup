"""Discover active Gold water that a per-helper Surf preflight would miss."""
import os
import io
from contextlib import redirect_stdout, redirect_stderr
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import shutil
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_coverage_audit import read_active_maps, audit, main

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None


class CoverageTests(unittest.TestCase):
    def test_actual_live_descriptors_not_staged_assets(self):
        rows = read_active_maps(ROOT)
        self.assertEqual([(r['stable_id'], r['map']) for r in rows], [
            (0, 'NewBarkTown'), (1, 'Route29'), (2, 'CherrygroveCity'),
            (3, 'Route30'), (4, 'Route31'), (125, 'GuideGentsHouse'),
            (5, 'VioletCity'), (6, 'Route31VioletGate'), (7, 'Route32'), (102, 'Route32RuinsOfAlphGate'),
            (20, 'RuinsOfAlphOutside'), (19, 'Route36RuinsOfAlphGate'), (16, 'Route36'), (8, 'UnionCave1F'), (9, 'Route33'), (10, 'AzaleaTown'), (11, 'IlexForestAzaleaGate'),
            (12, 'IlexForest'), (13, 'Route34IlexForestGate'),
            (14, 'Route34'), (15, 'GoldenrodCity'), (18, 'Route35GoldenrodGate'), (17, 'Route35'), (103, 'NationalPark'), (104, 'Route35NationalParkGate'), (105, 'Route36NationalParkGate')])
        self.assertIn('UnionCave1F', [r['map'] for r in rows])

    def test_mutated_active_count_is_rejected(self):
        with TemporaryDirectory() as temp:
            dst = Path(temp)
            files = ('data/johto_pilot_source_resources.asm',
                     'data/johto_pilot_runtime_assets.asm',
                     'constants/region_map_constants.asm',
                     'constants/johto_fixed_map_ids.asm')
            for f in files:
                (dst / f).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / f, dst / f)
            p = dst / 'constants/region_map_constants.asm'
            src = p.read_text()
            self.assertIn('NUM_JOHTO_ACTIVE_MAPS EQU 26', src)
            p.write_text(src.replace('NUM_JOHTO_ACTIVE_MAPS EQU 26',
                                     'NUM_JOHTO_ACTIVE_MAPS EQU 10'))
            with self.assertRaisesRegex(ValueError, 'count'):
                read_active_maps(dst)

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_full_inventory_distinguishes_registered_deferred_and_missing_water(self):
        result = audit(ROOT, GOLD, set())
        self.assertEqual([c['cells'] for c in next(r for r in result['rows'] if r['map']=='CherrygroveCity')['connected_water_areas']], [106, 15, 10, 8, 2, 1])
        self.assertEqual({r['map']: (r['gold_water_cells'], r['status'])
                          for r in result['rows']}, {
            'NewBarkTown': (8, 'REGISTERED'),
            'Route29': (0, 'NO_WATER'),
            'CherrygroveCity': (142, 'REGISTERED'),
            'Route30': (32, 'REGISTERED'),
            'Route31': (44, 'REGISTERED'),
            'GuideGentsHouse': (0, 'NO_WATER'),
            'VioletCity': (140, 'REGISTERED'),
            'Route31VioletGate': (0, 'NO_WATER'),
            'Route32': (278, 'REGISTERED'),
            'Route32RuinsOfAlphGate': (0, 'NO_WATER'),
            'RuinsOfAlphOutside': (48, 'REGISTERED'),
            'Route36RuinsOfAlphGate': (0, 'NO_WATER'),
            'Route36': (0, 'NO_WATER'),
            'UnionCave1F': (64, 'REGISTERED'),
            'Route33': (0, 'NO_WATER'),
            'AzaleaTown': (0, 'NO_WATER'),
            'IlexForestAzaleaGate': (0, 'NO_WATER'),
            'IlexForest': (32, 'REGISTERED'),
            'Route34IlexForestGate': (0, 'NO_WATER'),
            'Route34': (226, 'REGISTERED'),
            'GoldenrodCity': (84, 'REGISTERED'),
            'Route35GoldenrodGate': (0, 'NO_WATER'),
            'Route35': (32, 'REGISTERED'),
            'NationalPark': (0, 'NO_WATER'),
            'Route35NationalParkGate': (0, 'NO_WATER'),
            'Route36NationalParkGate': (0, 'NO_WATER'),
        })

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_require_implemented_cherrygrove_passes(self):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()) as err:
            result = main(['--root', str(ROOT), '--gold', str(GOLD),
                           '--require-map', 'CherrygroveCity'])
        self.assertEqual(0, result)
        self.assertEqual('', err.getvalue())

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_invalid_skipped_map_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'skip map not active'):
            audit(ROOT, GOLD, {'UnionCaveB1F'})

    @unittest.skipIf(GOLD is None, 'Gold reference not supplied')
    def test_source_block_corruption_fails(self):
        # Avoid editing any original project files. Only map data is copied;
        # independently of the Surf code, source Gold identity is enforced.
        with TemporaryDirectory() as temp:
            root = Path(temp)
            paths = ('data/johto_pilot_source_resources.asm',
                     'data/johto_pilot_runtime_assets.asm',
                     'constants/region_map_constants.asm',
                     'constants/johto_fixed_map_ids.asm',
                     'tools/johto_surf_contracts.json',
                     'home/overworld.asm',
                     'engine/overworld/field_moves.asm',
                     'engine/items/items.asm',
                     'engine/johto_violet_field_skills.asm',
                     'maps/johto_pilot/UnionCave1F.runtime.blk',
                     'gfx/blocksets/johto_union_cave.bst',
                     'gfx/tilesets/johto_union_cave.tilecoll',
                     'maps/johto_pilot/NewBarkTown.runtime.blk',
                     'maps/johto_pilot/CherrygroveCity.runtime.blk',
                     'maps/johto_pilot/VioletCity.runtime.blk',
                     'maps/johto_pilot/Route30.runtime.blk',
                     'maps/johto_pilot/Route31.runtime.blk',
                     'maps/johto_pilot/Route32.runtime.blk',
                     'maps/johto_pilot/RuinsOfAlphOutside.runtime.blk',
                     'gfx/blocksets/johto.bst', 'gfx/tilesets/johto.tilecoll')
            paths += tuple(x['source_asset'] for x in read_active_maps(ROOT))
            paths += ('engine/johto_south_geometry.asm',)
            paths += tuple(f'maps/johto_pilot/{name}.gold.blk' for name in ('AzaleaTown','IlexForestAzaleaGate','IlexForest','Route34IlexForestGate','Route34','GoldenrodCity'))
            paths += tuple(f'maps/johto_pilot/{name}.runtime.blk' for name in ('AzaleaTown','IlexForestAzaleaGate','IlexForest','Route34IlexForestGate','Route34','GoldenrodCity'))
            paths += tuple(f'maps/johto_pilot/{name}.roles.bin' for name in ('AzaleaTown','IlexForestAzaleaGate','IlexForest','Route34IlexForestGate','Route34','GoldenrodCity'))
            for f in paths:
                dst = root / f
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / f, dst)
            p = root / 'maps/johto_pilot/CherrygroveCity.gold.blk'
            a = bytearray(p.read_bytes())
            a[0] ^= 1
            p.write_bytes(a)
            with self.assertRaisesRegex(ValueError, 'differs from original Gold'):
                audit(root, GOLD, set())


if __name__ == '__main__':
    unittest.main()
