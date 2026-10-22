"""Regression for .235B false-green forest preview and gate arrival audits.

Only mutates in-memory ASM text; never patches gameplay files or builds a ROM.
"""
import os
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE',
                         os.environ.get('JOHTO_GOLD_ROOT', '/missing-Gold')))
sys.path.insert(0, str(ROOT/'tools'))

from johto_rpp_connection_guard import (audit_all_active, audit as connection_audit,
                                        check_native_connection_copy_executor, ConnectionError)
from johto_gatehouse_behavior_audit import (audit as gate_audit,
                                            check_native_gate_arrival_executors)


class AuditKernelHardening235B(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route43.blk').is_file():
            raise RuntimeError('full Gold reference required for connection tests')

    def connection_with_mutated_file(self, relative, before, after):
        target = ROOT/relative
        original = target.read_text(encoding='utf-8')
        self.assertEqual(original.count(before), 1, 'test injection lost its anchor')
        bad = original.replace(before, after, 1)
        read = Path.read_text

        def altered(path, *args, **kwargs):
            if path.resolve() == target:
                return bad
            return read(path, *args, **kwargs)

        with patch.object(Path, 'read_text', altered):
            return audit_all_active(ROOT, GOLD)

    def gate_with_mutated_file(self, relative, before, after):
        original = (ROOT/relative).read_text(encoding='utf-8')
        self.assertEqual(original.count(before), 1, 'test injection lost its anchor')
        return gate_audit(ROOT, GOLD,
                          overrides={relative: original.replace(before, after, 1)})

    def test_current_frozen_render_and_arrival_kernels_pass(self):
        # The copy loop and movement decoder themselves are unchanged. The
        # documented .235B DATA errors must still fail other audited rules.
        self.assertIsNone(check_native_connection_copy_executor(ROOT))
        contract = json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        self.assertIsNone(check_native_gate_arrival_executors(ROOT, contract))

    def test_235b_disjoint_west_footpath_is_not_silently_omitted(self):
        # The real fix now passes; tampering only the manifest must fail.
        result = connection_audit(ROOT, GOLD, 'JohtoRoute43', 'JohtoLakeOfRage',
                                  'Route43', 'LakeOfRage', 'north')
        self.assertEqual(result['status'], 'PASS', result)
        self.assertEqual(result['overlap']['visual_left_border'], 3)
        self.assertEqual(result['actual']['width'], 13)
        manifest = ROOT/'tools/johto_native_maps.json'
        text = manifest.read_text()
        tree = json.loads(text)
        route = next(row for row in tree['maps'] if row['header']=='JohtoRoute43_h')
        route['north_connection_exit_x_tiles'] = [8,9,10,11]
        replacement = json.dumps(tree)
        read = Path.read_text
        def altered(path,*args,**kwargs):
            return replacement if path.resolve()==manifest else read(path,*args,**kwargs)
        with patch.object(Path,'read_text',altered):
            with self.assertRaisesRegex(ConnectionError, 'manifest exits.*runtime fence'):
                connection_audit(ROOT, GOLD, 'JohtoRoute43', 'JohtoLakeOfRage',
                                 'Route43', 'LakeOfRage', 'north')

    def test_closing_gold_west_path_and_rewriting_manifest_still_fails(self):
        # The original .235B manifest already lists only x8..11. A future
        # author might delete the early x0 branch so JSON and ASM agree;
        # independent Gold FLOOR/FLOOR verification must still reject it.
        target = ROOT/'engine/overworld/johto_route33_collision.asm'
        original = target.read_text()
        start = original.index('JohtoRoute43EdgeFence::')
        end = original.index('JohtoLakeOfRageEdgeFence::', start)
        section = original[start:end]
        before=' and a\n jr z, .clear\n cp 8'
        after=' cp 8\n jr c, .blocked\n cp 8'
        self.assertEqual(section.count(before),1)
        bad = original[:start]+section.replace(before,after,1)+original[end:]
        read = Path.read_text
        def altered(path,*args,**kwargs):
            return bad if path.resolve()==target else read(path,*args,**kwargs)
        with patch.object(Path,'read_text',altered):
            with self.assertRaisesRegex(ConnectionError, 'independent Gold FLOOR/FLOOR'):
                connection_audit(ROOT, GOLD, 'JohtoRoute43', 'JohtoLakeOfRage',
                                 'Route43', 'LakeOfRage', 'north')

    def test_235b_paired_collision_only_carpet_cannot_auto_step_off(self):
        self.assertEqual(gate_audit(ROOT, GOLD), [])
        lookup = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        anchor = ' ; Outside Route43 gate\'s paired COLLISION_ONLY carpets (9/10,51)'
        self.assertEqual(lookup.count(anchor), 1)
        bad_lines = (' db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_LOCAL_ID, 51, 9, REGION_NATIVE_MAP_SLOT, D_UP\n'
                     ' db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_LOCAL_ID, 51, 10, REGION_NATIVE_MAP_SLOT, D_UP\n')
        bad = lookup.replace(anchor, bad_lines + anchor)
        errors = gate_audit(ROOT, GOLD, overrides={
            'engine/overworld/region_map_lookup.asm':bad})
        relevant = [e for e in errors if 'paired DOWN collision-only carpet' in e]
        self.assertEqual(len(relevant), 2, errors)

    def test_proposed_visual_strip_fix_passes_without_touching_project(self):
        result = connection_audit(ROOT, GOLD, 'JohtoRoute43', 'JohtoLakeOfRage',
                                  'Route43', 'LakeOfRage', 'north')
        self.assertEqual(result['status'], 'PASS', result)
        self.assertEqual(result['overlap']['visual_left_border'], 3)
        self.assertEqual(result['actual']['width'], 13)
        # Returning to the .235B header must be caught, even though the
        # seam's walkable cells and all other map geometry remain identical.
        header = ROOT/'data/mapHeaders/JohtoRoute43.asm'
        old = header.read_text()
        before = ('dw JohtoLakeOfRageBlocks + 2 + JOHTO_LAKE_OF_RAGE_WIDTH * (JOHTO_LAKE_OF_RAGE_HEIGHT - 3)\n'
                  ' dw wOverworldMap\n db JOHTO_ROUTE_43_WIDTH + 3\n')
        after = ('dw JohtoLakeOfRageBlocks + 5 + JOHTO_LAKE_OF_RAGE_WIDTH * (JOHTO_LAKE_OF_RAGE_HEIGHT - 3)\n'
                 ' dw wOverworldMap + 3 + 0\n db JOHTO_ROUTE_43_WIDTH\n')
        self.assertEqual(old.count(before),1)
        mutated = old.replace(before,after,1)
        read = Path.read_text
        def altered(path,*args,**kwargs):
            return mutated if path.resolve()==header else read(path,*args,**kwargs)
        with patch.object(Path,'read_text',altered):
            result = connection_audit(ROOT, GOLD, 'JohtoRoute43', 'JohtoLakeOfRage',
                                      'Route43', 'LakeOfRage', 'north')
        self.assertEqual(result['status'], 'FAIL', result)
        self.assertTrue(any('source_start' in e or 'dest_start' in e or 'width' in e
                            for e in result['issues']),result)

    def test_proposed_no_auto_step_passes_without_touching_project(self):
        self.assertEqual(gate_audit(ROOT,GOLD), [])
        lookup = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        for x in (9,10):
            self.assertNotIn(('db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_LOCAL_ID, '
                              f'51, {x}, REGION_NATIVE_MAP_SLOT, D_UP'), lookup)
        registry=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        gate=next(v for v in registry['active_warp_maps']
                  if v['rpp_map']=='JohtoRoute43MahoganyGate')
        arrivals=next(v for v in gate['gatehouse_runtime']['arrivals']
                      if v['local']=='JOHTO_ROUTE_43_LOCAL_ID')
        self.assertEqual(arrivals['points'], [[51,9,'NONE'],[51,10,'NONE']])
        # An old-style extra step is rejected independently of the manifest.
        anchor = ' ; Outside Route43 gate\'s paired COLLISION_ONLY carpets (9/10,51)'
        self.assertEqual(lookup.count(anchor),1)
        bad = lookup.replace(anchor,
            ' db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_LOCAL_ID, 51, 9, REGION_NATIVE_MAP_SLOT, D_UP\n' + anchor)
        errors=gate_audit(ROOT,GOLD,overrides={
            'engine/overworld/region_map_lookup.asm':bad})
        self.assertTrue(any('paired DOWN collision-only carpet' in e for e in errors), errors)

    def test_reducing_connection_copy_to_two_rows_is_rejected(self):
        result = self.connection_with_mutated_file(
            'home/overworld.asm',
            'LoadNorthSouthConnectionsTileMap::\n\tld c,MAP_BORDER',
            'LoadNorthSouthConnectionsTileMap::\n\tld c,MAP_BORDER - 1')
        self.assertEqual(result['status'], 'FAIL')
        self.assertTrue(any('BLK_COPY_EXECUTOR' in error for error in result['issues']), result)

    def test_removing_actual_north_copy_write_is_rejected(self):
        result = self.connection_with_mutated_file(
            'home/overworld.asm',
            'ld b,a\n.innerLoop\n\tld a,[hli]\n\tld [de],a',
            'ld b,a\n.innerLoop\n\tld a,[hli]\n\tnop')
        self.assertEqual(result['status'], 'FAIL')
        self.assertTrue(any('BLK_COPY_EXECUTOR' in error for error in result['issues']), result)

    def test_east_west_copy_width_corruption_is_rejected(self):
        result = self.connection_with_mutated_file(
            'home/overworld.asm',
            'LoadEastWestConnectionsTileMap::\n\tpush hl\n\tpush de\n\tld c,MAP_BORDER',
            'LoadEastWestConnectionsTileMap::\n\tpush hl\n\tpush de\n\tld c,MAP_BORDER - 1')
        self.assertEqual(result['status'], 'FAIL')
        self.assertTrue(any('BLK_COPY_EXECUTOR' in error for error in result['issues']), result)

    def test_gate_default_up_step_without_profile_is_rejected(self):
        errors = self.gate_with_mutated_file(
            'engine/overworld/region_map_lookup.asm',
            'GetJohtoWarpArrivalStep::\n\tld e, 0',
            'GetJohtoWarpArrivalStep::\n\tld e, D_UP')
        self.assertTrue(any('NATIVE_ARRIVAL_EXECUTOR' in error for error in errors), errors)

    def test_gate_arrival_lookup_was_disabled_is_rejected(self):
        errors = self.gate_with_mutated_file(
            'engine/overworld/region_map_lookup.asm',
            '\tld e, [hl]\n\tret\n.skipFive',
            '\tld e, 0\n\tret\n.skipFive')
        self.assertTrue(any('NATIVE_ARRIVAL_EXECUTOR' in error for error in errors), errors)

    def test_gate_postwarp_fallback_control_flow_is_rejected(self):
        errors = self.gate_with_mutated_file(
            'engine/overworld/npc_movement.asm',
            '\tjr nz, .stepFromProfile', '\tjr z, .stepFromProfile')
        self.assertTrue(any('NATIVE_ARRIVAL_EXECUTOR' in error for error in errors), errors)

    def test_implicit_johto_gate_door_step_is_rejected(self):
        errors = self.gate_with_mutated_file(
            'engine/overworld/doors.asm',
            'DoorTileIDPointers:\n',
            'DoorTileIDPointers:\n\tdbw JOHTO_GATE, GateDoorTileIDs\n')
        self.assertTrue(any('NATIVE_ARRIVAL_EXECUTOR' in error for error in errors), errors)


if __name__ == '__main__':
    unittest.main()
