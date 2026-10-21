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
         'engine/menu/start_sub_menus.asm', 'tools/johto_native_maps.json',
         'constants/tilesets.asm', 'tools/johto_deferred_field_moves.json', 'maps/JohtoRoute42.water_mask.bin',
         'engine/overworld/headbutt.asm', 'engine/overworld/johto_union_cave_surf.asm')


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

    def test_modern_tileset_surf_global_enable_is_rejected(self):
        self.mutate('engine/overworld/field_moves.asm', 'db OVERWORLD\n',
                    'db JOHTO_MODERN\n\tdb OVERWORLD\n')
        self.assertIn('JOHTO_MODERN', ' '.join(audit(self.root, self.gold)))

    def test_modern_tileset_escape_global_enable_is_rejected(self):
        self.mutate('engine/items/items.asm', 'db FOREST,CEMETERY',
                    'db JOHTO_MODERN,FOREST,CEMETERY')
        self.assertIn('JOHTO_MODERN', ' '.join(audit(self.root, self.gold)))

    def test_new_johto_tileset_is_not_silently_surf_enabled(self):
        p = self.root / 'constants/tilesets.asm'
        p.write_text(p.read_text() + '\n\tconst JOHTO_COAST ; future water map\n')
        self.mutate('engine/overworld/field_moves.asm', 'db OVERWORLD\n',
                    'db JOHTO_COAST\n\tdb OVERWORLD\n')
        self.assertIn('JOHTO_COAST', ' '.join(audit(self.root, self.gold)))

    def test_non_prefixed_native_tileset_also_checked(self):
        p = self.root / 'constants/tilesets.asm'
        p.write_text(p.read_text() + '\n\tconst COASTAL ; native Johto suffix\n')
        self.mutate('engine/items/items.asm', 'db FOREST,CEMETERY',
                    'db COASTAL,FOREST,CEMETERY')
        self.assertIn('COASTAL', ' '.join(audit(self.root, self.gold)))

    def test_missing_johto_registry_fails_closed(self):
        self.mutate('constants/tilesets.asm', 'const JOHTO        ;',
                    'const NOT_JOHTO  ;')
        self.assertIn('tileset registry', ' '.join(audit(self.root, self.gold)))

    def test_unsupported_capability_cannot_be_marked_allowed(self):
        self.mutate('tools/johto_native_maps.json', '"surf": "DEFERRED"',
                    '"surf": "ALLOWED"')
        self.assertIn('no other runtime permission reviewed', ' '.join(audit(self.root, self.gold)))

    def test_ecruteak_tree_location_mutation_is_rejected(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
                    '\tdb 0, 4\n', '\tdb 0, 3\n')
        self.assertIn('Gold 50 cells', ' '.join(audit(self.root,self.gold)))

    def test_ecruteak_headbutt_party_menu_cannot_be_omitted(self):
        self.mutate('engine/overworld/headbutt.asm',
                    'callba IsJohtoEcruteakHeadbuttTreeAhead',
                    'callba IsJohtoRuinsWaterAhead')
        self.assertIn('party-menu Headbutt', ' '.join(audit(self.root,self.gold)))

    def test_ecruteak_cut_cannot_be_claimed_without_cut_trees(self):
        import json
        p=self.root/'tools/johto_native_maps.json'
        data=json.loads(p.read_text())
        data['maps'][22]['feature_status']['cut']='ALLOWED'
        p.write_text(json.dumps(data))
        self.assertIn('Cut status', ' '.join(audit(self.root,self.gold)))

    def test_wrong_dig_return_chain_is_not_silently_accepted(self):
        self.mutate('engine/special_warps.asm', 'ld a, [wLastBlackoutMap]',
                    'ld a, [wLastMap]')
        self.assertIn('legacy return route', ' '.join(audit(self.root, self.gold)))


if __name__ == '__main__':
    unittest.main()
