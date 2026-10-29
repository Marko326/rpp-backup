"""ROUTES-251: Gold Route30/31 Surf + precise Cut, static/negative audit.

No RGBDS build/emulator: verifies exact Gold collision data, live visual clones,
entrypoint dispatch and bank-03 preservation. All samples remain user-testable.
"""
from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import re
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_preflight import check_project, water_coordinates

GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
ROUTES = {'Route30': (3, 32, 20, 54), 'Route31': (4, 44, 40, 18)}
TREES = {(3, 6, 8, 0x67), (4, 5, 13, 0x5f), (4, 10, 25, 0x5b)}
CLONES = {0x67: (0x8e, 0, 0), 0x5f: (0x8f, 1, 1), 0x5b: (0x90, 0, 1)}


def gold_cut_table(source: str) -> set[tuple[int, int, int, int]]:
    raw = source.split('JohtoRoutesGoldCutCells::', 1)[1].split(
        'JohtoRoutesGoldCutCellsEnd::', 1)[0]
    found = re.findall(r'(?m)^\s*db\s+JOHTO_ROUTE_(30|31)_LOCAL_ID,\s*(\d+),\s*(\d+),\s*\$([\da-fA-F]+)\b', raw)
    return {(3 if n == '30' else 4, int(y), int(x), int(b, 16)) for n, y, x, b in found}


def clone_blocks(source: str) -> dict[int, bytes]:
    result = {}
    for ident in (0x8e, 0x8f, 0x90):
        raw = source.split(f'JohtoPilotCutClearedBlock{ident:02X}::', 1)[1].split('::', 1)[0]
        b = bytes(int(n, 16) for n in re.findall(r'\$([0-9a-fA-F]{2})', '\n'.join(line for line in raw.splitlines() if line.lstrip().startswith('db '))))
        result[ident] = b
    return result


class JohtoRoutes251(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads((ROOT / 'tools/johto_surf_contracts.json').read_text())
        self.asm = (ROOT / 'engine/johto_violet_field_skills.asm').read_text()

    def test_two_active_routes_registered_and_original_prior_maps_unchanged(self):
        c = {e['gold_map']: e for e in self.contract['maps']}
        self.assertEqual(set(c), {'Route30', 'Route31', 'VioletCity', 'CherrygroveCity'})
        for name, (_id, count, width, height) in ROUTES.items():
            e = c[name]
            self.assertEqual((count, width, height),
                             (e['expected_water_cells'], e['width_cells'], e['height_cells']))
            self.assertEqual('JohtoVioletWaterAhead', e['entrypoint_helper'])
            self.assertEqual('yx_db', e['representation'])
        self.assertNotIn('NewBarkTown', c)
        self.assertNotIn('Route32', c)

    @unittest.skipIf(GOLD is None, 'Gold collision root required')
    def test_gold_water_exact_and_not_walkable_without_surf(self):
        index = GoldCollisionIndex(GOLD)
        metatiles = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        allowed = set((ROOT / 'gfx/tilesets/johto.tilecoll').read_bytes()) - {0xff}
        for name, (_id, count, width, height) in ROUTES.items():
            rows = index.cells(name)
            expected = {(c['y'], c['x']) for c in rows.values() if c['role'] == 'WATER'}
            actual = water_coordinates(self.asm, f'Johto{name}GoldWaterCells', f'Johto{name}GoldWaterCellsEnd')
            self.assertEqual(count, len(expected))
            self.assertEqual(expected, actual, name)
            runtime = (ROOT / f'maps/johto_pilot/{name}.runtime.blk').read_bytes()
            self.assertEqual(width * height // 4, len(runtime))
            for y, x in actual:
                block = runtime[(y // 2) * (width // 2) + x // 2]
                art = metatiles[block * 16:(block + 1) * 16]
                row, col = (y % 2) * 2, (x % 2) * 2
                visual = {art[(row + dy) * 4 + col + dx] for dy in (0, 1) for dx in (0, 1)}
                self.assertFalse(visual & allowed, (name, x, y, visual & allowed))

    def test_surf_three_existing_entrypaths_and_restore_front_tile(self):
        self.assertEqual([], check_project(ROOT, self.contract, GOLD))
        gateway = self.asm.split('JohtoVioletWaterAhead::', 1)[1].split('JohtoCherrygroveIsActive::', 1)[0]
        self.assertRegex(gateway, r'call JohtoRoute30WaterAhead\s+ret c\s+call JohtoRoute31WaterAhead\s+ret c')
        self.assertIn('callab JohtoVioletWaterAhead', (ROOT / 'engine/items/items.asm').read_text())
        self.assertIn('callab JohtoVioletWaterAhead', (ROOT / 'engine/overworld/field_moves.asm').read_text())
        home = (ROOT / 'home/overworld.asm').read_text()
        for name in ROUTES:
            self.assertRegex(home, rf'callab Johto{name}WaterAhead\s+jp c, \.noCollision\s+ld a, \[wTileInFrontOfPlayer\]\s+ld c, a\s+jr \.checkIfNextTileIsPassable')
        self.assertIn('ld a, [wCurLocalMapID] ; previous farcall modifies A', home)

    def test_cut_live_lookup_and_both_entrypaths(self):
        self.assertEqual(TREES, gold_cut_table(self.asm))
        helper = self.asm.split('JohtoRoutesCutTreeAhead::', 1)[1].split('JohtoPilotCutTreeAhead::', 1)[0]
        for needle in ('wCurMap', 'JOHTO_RUNTIME_MAP_HANDLE', 'wCurRegion',
                       'MAP_REGION_JOHTO', 'wCurLocalMapID',
                       'JOHTO_ROUTE_30_LOCAL_ID', 'JOHTO_ROUTE_31_LOCAL_ID',
                       'wXCoord', 'wYCoord', 'SPRITE_FACING_UP', 'SPRITE_FACING_DOWN',
                       'SPRITE_FACING_LEFT', 'SPRITE_FACING_RIGHT',
                       'JohtoRoutesGoldCutCells', 'wCurrentTileBlockMapViewPointer',
                       'push af', 'pop af', 'cp [hl]', 'scf'):
            self.assertIn(needle, helper)
        wrapper = self.asm.split('JohtoPilotCutTreeAhead::', 1)[1]
        self.assertRegex(wrapper, r'call JohtoVioletCutTreeAhead\s+ret c\s+jp JohtoRoutesCutTreeAhead')
        for f in ('engine/overworld/cut.asm', 'engine/overworld/field_moves.asm'):
            self.assertIn('callab JohtoPilotCutTreeAhead', (ROOT / f).read_text())

    @unittest.skipIf(GOLD is None, 'Gold collision root required')
    def test_cut_gold_positions_and_unmodified_runtime_blocks(self):
        index = GoldCollisionIndex(GOLD)
        for name, (ident, _, width, height) in ROUTES.items():
            actual = {(id, y, x, old) for id, y, x, old in TREES if id == ident}
            gold = {(ident, c['y'], c['x'], c['block_id']) for c in index.cells(name).values()
                    if c['role'] == 'CUT_TREE'}
            self.assertEqual(gold, actual)
            runtime = (ROOT / f'maps/johto_pilot/{name}.runtime.blk').read_bytes()
            for _id, y, x, block in actual:
                self.assertEqual(block, runtime[(y // 2) * (width // 2) + x // 2])

    def test_cleared_metatiles_only_remove_cut_quadrant(self):
        metatiles = (ROOT / 'gfx/blocksets/johto.bst').read_bytes()
        source = (ROOT / 'data/johto_pilot_runtime_assets.asm').read_text()
        clones = clone_blocks(source)
        for old_id, (clone_id, qrow, qcol) in CLONES.items():
            clone = clones[clone_id]
            self.assertEqual(16, len(clone))
            original = metatiles[old_id * 16:(old_id + 1) * 16]
            expected = bytearray(original)
            for dy in (0, 1):
                for dx in (0, 1):
                    expected[(qrow * 2 + dy) * 4 + qcol * 2 + dx] = 0x05
            self.assertEqual(expected, clone)
        self.assertIn('JohtoPilot_BlockEnd - JohtoPilot_Block == 145 * 16', source)
        self.assertEqual(141 * 16, len(metatiles))  # untouched original blockset
        swaps = (ROOT / 'engine/overworld/cut.asm').read_text()
        for original, (new, _qr, _qc) in CLONES.items():
            self.assertRegex(swaps, rf'db \${original:02X}, \${new:02X}')
        self.assertRegex(swaps, r'db \$63, \$8D') # Violet retained

    def test_no_bank3_growth_from_new_cut_calls_or_surfboard_calls(self):
        # Bank $03 has only 6 bytes free in the supplied .250 MAP.
        # Both original farcalls remain one apiece; only three swap pairs add 6 B.
        items = (ROOT / 'engine/items/items.asm').read_text()
        shore = items.split('IsNextTileShoreOrWater:', 1)[1].split('ReadSuperRodData:', 1)[0]
        self.assertNotIn('callab JohtoRoute30WaterAhead', shore)
        self.assertNotIn('callab JohtoRoute31WaterAhead', shore)
        cut = (ROOT / 'engine/overworld/cut.asm').read_text()
        body = cut.split('UsedCut:', 1)[1].split('.legacyTileset', 1)[0]
        self.assertEqual(1, body.count('callab'))
        self.assertNotIn('callab JohtoRoutesCutTreeAhead', body)

    @unittest.skipIf(GOLD is None, 'Gold collision root required')
    def test_fault_injection_wrong_cut_coordinate_detected(self):
        index = GoldCollisionIndex(GOLD)
        altered = self.asm.replace('db JOHTO_ROUTE_30_LOCAL_ID, 6, 8, $67',
                                   'db JOHTO_ROUTE_30_LOCAL_ID, 6, 9, $67', 1)
        intended = {(ident, c['y'], c['x'], c['block_id'])
                    for name, (ident, _, _, _) in ROUTES.items()
                    for c in index.cells(name).values() if c['role'] == 'CUT_TREE'}
        self.assertNotEqual(intended, gold_cut_table(altered))
        self.assertEqual(intended, gold_cut_table(self.asm))

    def test_fault_injection_wrong_clone_detected(self):
        source = (ROOT / 'data/johto_pilot_runtime_assets.asm').read_text()
        changed = source.replace('JohtoPilotCutClearedBlock8E::\n\tdb $05, $05, $05',
                                 'JohtoPilotCutClearedBlock8E::\n\tdb $00, $05, $05', 1)
        self.assertNotEqual(source, changed)
        self.assertNotEqual(clone_blocks(source)[0x8e], clone_blocks(changed)[0x8e])

    def test_fault_injection_remove_gateway_is_rejected(self):
        with TemporaryDirectory() as td:
            tmp = Path(td)
            files = ('engine/overworld/field_moves.asm', 'engine/items/items.asm',
                     'home/overworld.asm', 'engine/johto_violet_field_skills.asm',
                     'maps/johto_pilot/CherrygroveCity.runtime.blk',
                     'maps/johto_pilot/VioletCity.runtime.blk',
                     'maps/johto_pilot/Route30.runtime.blk',
                     'maps/johto_pilot/Route31.runtime.blk',
                     'gfx/blocksets/johto.bst', 'gfx/tilesets/johto.tilecoll')
            for rel in files:
                (tmp / rel).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / rel, tmp / rel)
            p = tmp / 'engine/johto_violet_field_skills.asm'
            p.write_text(p.read_text().replace('\tcall JohtoRoute31WaterAhead\n\tret c',
                                               '\t; BUG: missing Route31 dispatch', 1))
            errors = check_project(tmp, self.contract, GOLD)
            self.assertTrue(any('missing carry-safe bank-local dispatch' in e for e in errors), errors)


if __name__ == '__main__':
    unittest.main()
