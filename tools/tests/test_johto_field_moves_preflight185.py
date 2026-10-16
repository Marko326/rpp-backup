"""The existing Johto field-move exclusions must reject unsafe quick enables."""
from pathlib import Path
import os
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_field_moves_preflight import audit  # noqa: E402

FILES = ('engine/overworld/field_moves.asm', 'engine/items/items.asm',
         'home/overworld.asm', 'engine/special_warps.asm',
         'engine/menu/start_sub_menus.asm', 'tools/johto_native_maps.json')


class FieldMovePreflight185(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold-source'))
        if not (cls.gold / 'data/tilesets/cave_collision.asm').is_file():
            raise AssertionError('Field Move preflight requires the complete Gold source')

    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in FILES:
            p = self.root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, p)

    def mutate(self, relative: str, original: str, changed: str):
        p = self.root / relative
        text = p.read_text()
        self.assertIn(original, text)
        p.write_text(text.replace(original, changed, 1))

    def test_baseline_is_not_prematurely_enabled(self):
        self.assertEqual(audit(self.root, self.gold), [])

    def test_incorrect_escape_permission_is_rejected(self):
        self.mutate('engine/items/items.asm', 'db FOREST,CEMETERY',
                    'db JOHTO_UNION_CAVE,FOREST,CEMETERY')
        self.assertIn('EscapeRopeTilesets', ' '.join(audit(self.root, self.gold)))

    def test_incorrect_surf_permission_is_rejected(self):
        self.mutate('engine/overworld/field_moves.asm', 'db OVERWORLD\n',
                    'db JOHTO_UNION_CAVE\n\tdb OVERWORLD\n')
        self.assertIn('WaterTilesets2', ' '.join(audit(self.root, self.gold)))

    def test_surfboard_other_water_list_is_also_protected(self):
        self.mutate('engine/items/items.asm', 'db OVERWORLD,FOREST,GYM',
                    'db JOHTO,OVERWORLD,FOREST,GYM')
        self.assertIn('WaterTilesets', ' '.join(audit(self.root, self.gold)))

    def test_unsupported_capability_cannot_be_marked_allowed(self):
        self.mutate('tools/johto_native_maps.json', '"surf": "DEFERRED"',
                    '"surf": "ALLOWED"')
        self.assertIn('no other runtime permission reviewed', ' '.join(audit(self.root, self.gold)))

    def test_wrong_dig_return_chain_is_not_silently_accepted(self):
        self.mutate('engine/special_warps.asm', 'ld a, [wLastBlackoutMap]',
                    'ld a, [wLastMap]')
        self.assertIn('legacy return route', ' '.join(audit(self.root, self.gold)))


if __name__ == '__main__':
    unittest.main()
