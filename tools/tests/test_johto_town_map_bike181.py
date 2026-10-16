"""Gold-backed Town Map/Union Cave bike regression, including mutation checks."""
from pathlib import Path
from tempfile import TemporaryDirectory
import os
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_town_map_bike_audit import audit  # noqa: E402

RPP_FILES = ('engine/town_map.asm', 'data/town_map_entries.asm',
             'data/bike_riding_tilesets.asm', 'data/mapHeaders/JohtoUnionCave1F.asm',
             'home/overworld.asm', 'tools/johto_native_maps.json',
             'gfx/tilemaps/johto_map.kmp')
GOLD_FILES = ('data/maps/landmarks.asm', 'engine/events/overworld.asm',
              'gfx/pokegear/johto.bin')


class JohtoTownMapBike181(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        value = os.environ.get('JOHTO_GOLD_SOURCE')
        if not value:
            raise RuntimeError('Gold source mandatory for 181 town/bike suite')
        cls.gold = Path(value)
        if not all((cls.gold / rel).is_file() for rel in GOLD_FILES):
            raise RuntimeError('Gold source incomplete for 181 town/bike suite')

    def test_gold_landmarks_and_cave_bike_match(self):
        self.assertEqual(audit(ROOT, self.gold), [])

    def mutate(self, rel, before, after, expected, *, source='rpp'):
        with TemporaryDirectory() as tmp:
            rpp = Path(tmp) / 'rpp'
            gold = Path(tmp) / 'gold'
            for item in RPP_FILES:
                target = rpp / item
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / item, target)
            for item in GOLD_FILES:
                target = gold / item
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(self.gold / item, target)
            p = (rpp if source == 'rpp' else gold) / rel
            text = p.read_text()
            self.assertIn(before, text)
            p.write_text(text.replace(before, after, 1))
            issues = audit(rpp, gold)
            self.assertTrue(any(expected in problem for problem in issues), issues)

    def test_map_geography_change_outside_ui_panels_must_fail(self):
        with TemporaryDirectory() as tmp:
            rpp = Path(tmp) / 'rpp'
            gold = Path(tmp) / 'gold'
            for rel in RPP_FILES:
                dest = rpp / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / rel, dest)
            for rel in GOLD_FILES:
                dest = gold / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(self.gold / rel, dest)
            path = rpp / 'gfx/tilemaps/johto_map.kmp'
            content = bytearray(path.read_bytes())
            content[10 * 20 + 8] ^= 1
            path.write_bytes(content)
            self.assertTrue(any('geographic tile mismatch' in e for e in audit(rpp, gold)))

    def test_route31_wrong_marker_must_fail(self):
        self.mutate('engine/town_map.asm', '\tdb  76, 104 ; Route31Name\n\tdw JohtoRoute31TownMapName',
                    '\tdb  76, 100 ; Route31Name\n\tdw JohtoRoute31TownMapName',
                    'JohtoRoute31TownMapName ordinary Town Map')

    def test_route32_raw_gold_coords_without_macro_offset_must_fail(self):
        self.mutate('engine/town_map.asm', '\tdb 108,  92 ; Route32Name\n\tdw JohtoRoute32TownMapName',
                    '\tdb  92,  84 ; Route32Name\n\tdw JohtoRoute32TownMapName',
                    'JohtoRoute32TownMapName ordinary Town Map')

    def test_union_cave_wrong_native_marker_must_fail(self):
        self.mutate('engine/town_map.asm', '\tdb 140, 92\n\tdw JohtoUnionCaveTownMapName',
                    '\tdb 124, 84\n\tdw JohtoUnionCaveTownMapName',
                    'native local 8')

    def test_missing_union_cave_bike_whitelist_must_fail(self):
        self.mutate('data/bike_riding_tilesets.asm', ',JOHTO_UNION_CAVE,$FF', ',$FF',
                    'Union Cave tileset must appear')

    def test_wrong_union_cave_header_tileset_must_fail(self):
        self.mutate('data/mapHeaders/JohtoUnionCave1F.asm', '\tdb JOHTO_UNION_CAVE',
                    '\tdb JOHTO_GATE', 'Union Cave header')

    def test_gold_landmark_changes_cannot_be_silently_accepted(self):
        self.mutate('data/maps/landmarks.asm', 'landmark  84,  92, Route32Name',
                    'landmark  88,  92, Route32Name',
                    'JohtoRoute32TownMapName ordinary Town Map', source='gold')

    def test_cave_bike_registration_must_match_runtime_table(self):
        self.mutate('tools/johto_native_maps.json', '"bike": "ALLOWED"',
                    '"bike": "FORBIDDEN"', 'Union Cave bike capability')


if __name__ == '__main__':
    unittest.main()
