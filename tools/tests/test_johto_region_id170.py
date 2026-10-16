"""Region-map expansion safety and mutation checks (no ROM build)."""
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_region_id_audit import INPUTS, audit  # noqa: E402


class NativeMapIDExpansion(unittest.TestCase):
    def test_registered_legacy_and_native_maps_remain_distinct(self):
        self.assertEqual(audit(ROOT), [])

    def mutate(self, rel, before, after, expected):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in INPUTS:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, target)
            path = root / rel
            text = path.read_text(encoding='utf-8')
            self.assertIn(before, text)
            path.write_text(text.replace(before, after, 1), encoding='utf-8')
            issues = audit(root)
            self.assertTrue(any(expected in issue for issue in issues), issues)

    def test_same_length_wrong_header_identity_is_rejected(self):
        self.mutate('data/johto_map_headers.asm',
                    'dw JohtoRoute29_h ; local $01',
                    'dw JohtoRoute30_h ; local $01',
                    'local 1 header identity mismatch')

    def test_bank_swap_is_rejected_even_if_counts_match(self):
        self.mutate('data/johto_map_headers.asm',
                    'db BANK(JohtoRoute29_h)',
                    'db BANK(JohtoRoute30_h)',
                    'local 1 bank identity mismatch')

    def test_a_future_local_requires_explicit_contract(self):
        self.mutate('constants/region_map_constants.asm',
                    'DEF NUM_JOHTO_MAPS EQU 9',
                    'DEF JOHTO_FIXTURE_LOCAL_ID EQU 9\nDEF NUM_JOHTO_MAPS EQU 10',
                    'identity contract count')

    def test_native_slot_is_not_a_kanto_map(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'cp REGION_NATIVE_MAP_SLOT\n\tjr z, .invalid',
                    'cp REGION_NATIVE_MAP_SLOT\n\tnop\n\tnop', 'Kanto resolver')

    def test_abandoned_region_save_must_not_reset_native_map(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'SyncLegacyMapRegions::\n\t; A virtual map is keyed by the saved (region, local) pair. Legacy\n\t; map IDs remain authoritative for every pre-existing map/save.\n\tld a, [wCurMap]\n\tcp REGION_NATIVE_MAP_SLOT',
                    'SyncLegacyMapRegions::\n\t; removed native guard\n\tld a, [wCurMap]\n\tcp $fb',
                    'save migration')

    def test_missing_southward_connection_dispatch_fails(self):
        self.mutate('home/overworld.asm', 'callab SelectNativeMapConnection',
                    'callab LegacyMapIDToRegionKey', 'four map connection directions')

    def test_lastmap_must_restore_local_id(self):
        self.mutate('home/overworld.asm', 'ld a,[wLastLocalMapID]',
                    'ld a,[wCurLocalMapID]', 'LAST_MAP')

    def test_missing_map_names_are_fatal(self):
        self.mutate('engine/town_map.asm', 'dw JohtoUnionCaveTownMapName\nJohtoNativeTownMapEntriesEnd::',
                    'JohtoNativeTownMapEntriesEnd::', 'Town Map name count')

    def test_missing_gsc_row_is_fatal(self):
        self.mutate('engine/menu/options_menu.asm',
                    'db MUSIC_GBP_GSC_UNION_CAVE\nJohtoNativeGSCMusicEnd::',
                    'JohtoNativeGSCMusicEnd::', 'GSC music table count')

    def test_missing_save_local_byte_is_fatal(self):
        self.mutate('wram.asm', 'wLastLocalMapID::', 'wDeletedLastLocalMapID::',
                    'persistent current/last native local ID')

    def test_future_native_map_must_register_all_local_tables(self):
        self.mutate('constants/region_map_constants.asm',
                    'DEF NUM_JOHTO_MAPS EQU 9', 'DEF NUM_JOHTO_MAPS EQU 10',
                    'local map IDs')

    def test_virtual_map_cannot_consume_new_real_legacy_id(self):
        self.mutate('data/johto_map_headers.asm',
                    'db REGION_NATIVE_MAP_SLOT\nJohtoMapLegacyAliasesEnd::',
                    'db JOHTO_ROUTE_31\nJohtoMapLegacyAliasesEnd::',
                    'local 8 must use the shared virtual handle')

    def test_fixture_can_register_a_tenth_local_without_consuming_old_id(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in INPUTS:
                dst = root / name
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, dst)
            edits = {
                'constants/region_map_constants.asm': [
                    ('DEF NUM_JOHTO_MAPS EQU 9',
                     'DEF JOHTO_FIXTURE_LOCAL_ID EQU 9\nDEF NUM_JOHTO_MAPS EQU 10')],
                'data/johto_map_headers.asm': [
                    ('JohtoMapHeaderPointersEnd::', '\tdw JohtoUnionCave1F_h ; fixture\nJohtoMapHeaderPointersEnd::'),
                    ('JohtoMapHeaderBanksEnd::', '\tdb BANK(JohtoUnionCave1F_h)\nJohtoMapHeaderBanksEnd::'),
                    ('JohtoMapLegacyAliasesEnd::', '\tdb REGION_NATIVE_MAP_SLOT\nJohtoMapLegacyAliasesEnd::'),
                    ('JohtoNativeMapSongBanksEnd::', '\tdb MUSIC_DUNGEON2, 0 ; fixture\nJohtoNativeMapSongBanksEnd::')],
                'engine/menu/options_menu.asm': [
                    ('JohtoNativeGSCMusicEnd::', '\tdb MUSIC_GBP_GSC_UNION_CAVE ; fixture\nJohtoNativeGSCMusicEnd::')],
                'engine/town_map.asm': [
                    ('db 0, 1, 2, 3, 4, 5, 5, 7, 9', 'db 0, 1, 2, 3, 4, 5, 5, 7, 9, 9'),
                    ('JohtoNativeTownMapEntriesEnd::',
                     '\tdb 140, 92\n\tdw JohtoUnionCaveTownMapName\nJohtoNativeTownMapEntriesEnd::')],
            }
            for rel, pairs in edits.items():
                path = root / rel
                text = path.read_text(encoding='utf-8')
                for before, after in pairs:
                    self.assertIn(before, text)
                    text = text.replace(before, after, 1)
                path.write_text(text, encoding='utf-8')
            self.assertIn('identity contract count', ' '.join(audit(root)))
            manifest_path = root / 'tools/johto_native_maps.json'
            manifest = json.loads(manifest_path.read_text())
            fixture = dict(manifest['maps'][-1])
            fixture.update(local_id=9, local_symbol='JOHTO_FIXTURE_LOCAL_ID')
            fixture['feature_status'] = {key: 'DEFERRED' for key in fixture['feature_status']}
            manifest['maps'].append(fixture)
            manifest_path.write_text(json.dumps(manifest))
            self.assertEqual(audit(root), [])
            self.assertNotIn('mapconst JOHTO_FIXTURE',
                             (root / 'constants/map_constants.asm').read_text())

    def test_no_map_creation_inside_engine_expansion(self):
        self.assertFalse((ROOT / 'maps/JohtoRoute33.blk').exists())
        self.assertTrue((ROOT / 'maps/JohtoUnionCave1F.blk').exists())


if __name__ == '__main__':
    unittest.main()
