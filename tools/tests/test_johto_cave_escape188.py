"""Gold-backed anti-regression tests for region-safe cave Dig/Escape Rope."""
import os
from pathlib import Path
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_cave_escape_audit import audit  # noqa: E402

INPUTS = ('engine/items/items.asm', 'engine/special_warps.asm',
          'engine/overworld/johto_cave_escape.asm', 'main.asm',
          'tools/johto_native_maps.json',
          'data/mapObjects/JohtoRoute32.asm', 'data/mapObjects/JohtoUnionCave1F.asm')


class CaveEscape188(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold-source'))
        if not (cls.gold / 'home/map.asm').is_file():
            raise AssertionError('complete Gold source required for Cave Escape')

    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in INPUTS:
            p = self.root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, p)

    def mutate(self, rel, old, new):
        p = self.root / rel
        data = p.read_text()
        self.assertIn(old, data)
        p.write_text(data.replace(old, new, 1))
        self.assertNotEqual(audit(self.root, self.gold), [])

    def test_gold_single_entrance_contract(self):
        self.assertEqual(audit(self.root, self.gold), [])

    def test_blackout_is_not_misrouted(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'and (1 << 3) | (1 << 6)', 'and (1 << 6)')

    def test_wrong_region_cannot_dig(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'cp MAP_REGION_JOHTO', 'cp MAP_REGION_KANTO')

    def test_wrong_cave_local_id_cannot_dig(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'cp JOHTO_UNION_CAVE_1F_LOCAL_ID', 'cp JOHTO_ROUTE_32_LOCAL_ID')

    def test_bad_cave_return_landing_cannot_ship(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 80, 6',
                    'FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 79, 6')

    def test_scratch_blackout_destination_cannot_be_reused(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'ld a, JOHTO_ROUTE_32', 'ld a, [wLastBlackoutMap]')

    def test_special_intercept_must_come_before_legacy_blackout(self):
        self.mutate('engine/special_warps.asm',
                    'callba TryLoadJohtoUnionCaveEscapeWarp',
                    'callba CanUseJohtoUnionCaveEscape')

    def test_only_cave_has_dig_and_escape_rope_permission(self):
        self.mutate('tools/johto_native_maps.json',
                    '"dig": "DEFERRED"', '"dig": "ALLOWED"')

    def test_new_tileset_cannot_bypass_native_guard(self):
        self.mutate('engine/items/items.asm',
                    'jr nz,.legacyTileset', 'jr z,.legacyTileset')


if __name__ == '__main__':
    unittest.main()
