"""Gold-wide warp inventory: catch broken Gold references and new source drift."""
import os
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import shutil
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gold_door_audit import inspect, GoldCollisionIndex  # noqa: E402
from johto_warp_reference_profiles import gold_gate_inventory  # noqa: E402


class GoldDoorReferenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path = os.environ.get('JOHTO_GOLD_SOURCE')
        if not path or not Path(path).is_dir():
            raise unittest.SkipTest('Gold source not configured')
        cls.gold = Path(path)

    def test_gold_baseline_inventory(self):
        result = inspect(self.gold)
        self.assertEqual(result['errors'], [])
        self.assertGreaterEqual(result['stats']['warp_events'], 1200)
        self.assertGreaterEqual(result['stats']['registered_maps'], 360)
        self.assertIn('directional_carpet', result['stats']['collision_families'])

    def test_all_gold_gate_warps_have_collision_derived_trigger_rules(self):
        index = GoldCollisionIndex(self.gold)
        gates = index.gate_warp_inventory()
        self.assertEqual(len(gates), 24)
        warp_count = sum(len(gate['warps']) for gate in gates)
        self.assertEqual(warp_count, 100)
        roles = {}
        for gate in gates:
            for warp in gate['warps']:
                role = warp['collision_role']
                roles[role] = roles.get(role, 0) + 1
                if role.startswith('WARP_CARPET_'):
                    self.assertEqual(warp['trigger_contract'], 'COLLISION_ONLY',
                                     (gate['gold_map'], warp))
                    self.assertEqual(warp['collision_direction'], role.removeprefix('WARP_CARPET_'))
                else:
                    self.assertEqual(role, 'DOOR', (gate['gold_map'], warp))
                    self.assertEqual(warp['trigger_contract'], 'STEP_ON',
                                     (gate['gold_map'], warp))
        self.assertEqual(roles, {
            'DOOR': 26,
            'WARP_CARPET_DOWN': 30,
            'WARP_CARPET_LEFT': 22,
            'WARP_CARPET_RIGHT': 22,
        })
        report = gold_gate_inventory(ROOT, self.gold)
        self.assertEqual(report['totals']['gold_gates'], 24)
        self.assertEqual(report['active_approach_check']['status'], 'PASS')
        self.assertEqual(report['active_approach_check']['checked'], 90)
        self.assertEqual(report['active_approach_check']['errors'], [])
        self.assertEqual(report['active_arrival_check']['status'], 'PASS')
        self.assertEqual(report['active_arrival_check']['checked'], 78)
        self.assertEqual(report['active_arrival_check']['errors'], [])

    def make_gold_copy(self, tmp: str) -> Path:
        # Only the audit's relevant source files are required for mutation.
        gold = Path(tmp)
        (gold / 'maps').mkdir()
        (gold / 'data/maps').mkdir(parents=True)
        (gold / 'constants').mkdir()
        (gold / 'engine/overworld').mkdir(parents=True)
        (gold / 'home').mkdir()
        for rel in ('data/maps/attributes.asm', 'data/maps/maps.asm',
                    'constants/map_constants.asm', 'constants/collision_constants.asm',
                    'engine/overworld/tile_events.asm', 'engine/overworld/player_movement.asm',
                    'home/map.asm', 'engine/overworld/events.asm',
                    'engine/overworld/scripting.asm'):
            shutil.copy2(self.gold / rel, gold / rel)
        for f in (self.gold / 'maps').glob('*.asm'):
            shutil.copy2(f, gold / 'maps' / f.name)
        return gold

    def test_bad_destination_index_is_rejected(self):
        with TemporaryDirectory() as tmp:
            copy = self.make_gold_copy(tmp)
            f = copy / 'maps/Route31VioletGate.asm'
            text = f.read_text()
            self.assertIn('VIOLET_CITY, 8', text)
            f.write_text(text.replace('VIOLET_CITY, 8', 'VIOLET_CITY, 99', 1))
            errors = inspect(copy)['errors']
            self.assertTrue(any('destination index invalid' in e for e in errors), errors)

    def test_coordinate_beyond_gold_map_is_rejected(self):
        with TemporaryDirectory() as tmp:
            copy = self.make_gold_copy(tmp)
            f = copy / 'maps/UnionCave1F.asm'
            text = f.read_text()
            self.assertIn('warp_event 17,  3, ROUTE_32, 4', text)
            f.write_text(text.replace('warp_event 17,  3, ROUTE_32, 4',
                                      'warp_event 99,  3, ROUTE_32, 4', 1))
            self.assertTrue(any('out of map bounds' in e for e in inspect(copy)['errors']))

    def test_missing_collision_family_is_rejected(self):
        with TemporaryDirectory() as tmp:
            copy = self.make_gold_copy(tmp)
            f = copy / 'constants/collision_constants.asm'
            f.write_text(f.read_text().replace('COLL_CAVE              EQU', 'COLL_ZAVE              EQU', 1))
            self.assertTrue(any('COLL_CAVE' in e for e in inspect(copy)['errors']))


if __name__ == '__main__':
    unittest.main()
