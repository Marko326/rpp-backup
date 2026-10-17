"""MUS phase 3: adversarial checks for future Johto map/music additions."""
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_music_final_audit import FILES, audit  # noqa: E402


class JohtoMusicFinalAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.errors, cls.rows = audit(ROOT)

    def test_current_registry_has_seven_scenes_and_source_inheriting_gate(self):
        self.assertEqual(self.errors, [])
        self.assertEqual(len(self.rows), 8)
        gate, = (v for v in self.rows if v['map'] == 'JOHTO_ROUTE31_VIOLET_GATE')
        self.assertEqual(gate['legacy_id'], '$FA')
        self.assertEqual(gate['gsc'], 'INHERIT_FROM_WARP_SOURCE')
        self.assertEqual(sum(v['gsc'].startswith('MUSIC_GBP_GSC_') for v in self.rows), 7)

    def mutation(self, rel, before, after, expected):
        # Copy only the ten read-only inputs; never mutate the real RPP sources.
        with TemporaryDirectory() as folder:
            tmp = Path(folder)
            for source in FILES:
                target = tmp / source
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / source, target)
            path = tmp / rel
            original = path.read_text(encoding='utf-8')
            self.assertIn(before, original)
            path.write_text(original.replace(before, after, 1), encoding='utf-8')
            errors, _ = audit(tmp)
            self.assertTrue(any(expected in e for e in errors), errors)

    def test_missing_song_row_is_rejected(self):
        self.mutation('data/map_songs.asm',
                      'db MUSIC_CITIES1, 0 ; JOHTO_VIOLET_CITY ($F9), Pewter family',
                      '; removed', 'map/song table length mismatch')

    def test_missing_gsc_scene_is_rejected(self):
        self.mutation('engine/menu/options_menu.asm',
                      'db JOHTO_VIOLET_CITY,         MUSIC_GBP_GSC_VIOLET_CITY',
                      '; scene missing', 'registered Johto scene missing GSC counterpart')

    def test_gate_must_not_use_stale_lastmap(self):
        self.mutation('home/overworld.asm',
                      'ld a,[wWarpedFromWhichMap]',
                      'ld a,[wLastMap]', 'stale wLastMap dependency')

    def test_gate_rby_gsc_must_share_source(self):
        self.mutation('engine/menu/options_menu.asm',
                      'call GetJohtoGateMusicSourceMap ; same source as LoadMapHeader BGM',
                      'ld a,JOHTO_VIOLET_CITY', 'RBY/GSC gate music source is not shared')

    def test_rom_music_pointer_count_must_match(self):
        self.mutation('crysaudio/gb_player_pointers.asm',
                      'tbp Music_VioletCity', '; missing pointer',
                      'GBP song IDs/pointers differ')

    def test_unknown_future_map_requires_scene_mapping(self):
        self.mutation('data/johto_map_headers.asm',
                      'db REGION_NATIVE_MAP_SLOT ; Route33 has no legacy alias\nJohtoMapLegacyAliasesEnd::',
                      'db PALLET_TOWN ; Route33 has no legacy alias\nJohtoMapLegacyAliasesEnd::',
                      'native locals must share the virtual map handle')

    def test_audio_special_priority_cannot_disappear(self):
        self.mutation('home/audio.asm', 'MUSIC_SURFING', 'MUSIC_UNUSED_SURF',
                      'default music no longer has bike/surf')

    def test_legal_but_wrong_gsc_scene_is_rejected(self):
        self.mutation('engine/menu/options_menu.asm',
                      'db JOHTO_VIOLET_CITY,         MUSIC_GBP_GSC_VIOLET_CITY',
                      'db JOHTO_VIOLET_CITY,         MUSIC_GBP_GSC_ROUTE29',
                      'GSC scene mismatch')

    def test_legal_but_wrong_gsc_pointer_is_rejected(self):
        self.mutation('crysaudio/gb_player_pointers.asm',
                      'tbp Music_VioletCity', 'tbp Music_Route29',
                      'GSC pointer identity mismatch')

    def test_bike_surf_wrong_branch_polarity_is_rejected(self):
        self.mutation('home/audio.asm', 'jr z, .surfing', 'jr nz, .surfing',
                      'bike/surf branch semantics changed')

    def test_cache_must_actually_clear_old_music_id(self):
        self.mutation('engine/menu/options_menu.asm',
                      'ld [wLastMusicSoundID],a ; same RBY ID may no longer mean same GSC song',
                      'ld a,[wLastMusicSoundID] ; same RBY ID may no longer mean same GSC song',
                      'scene cache invalidation sequence')

    def test_rby_music_identity_is_not_interchangeable(self):
        self.mutation('data/map_songs.asm',
                      'db MUSIC_CITIES1, 0 ; JOHTO_VIOLET_CITY ($F9), Pewter family',
                      'db MUSIC_ROUTES3, 0 ; JOHTO_VIOLET_CITY ($F9), Pewter family',
                      'RBY scene mismatch')

    def test_map_loader_cannot_drop_bounds_check(self):
        self.mutation('home/overworld.asm', 'cp NUM_LEGACY_MAPS', 'cp $ff',
                      'music table bounds check')

    def test_cache_no_random_reroll_or_wram_expansion(self):
        self.mutation('engine/menu/options_menu.asm',
                      'CheckJohtoMusicSceneTransition::',
                      'CheckJohtoMusicSceneTransition::\n\tcall Random',
                      'scene transition must not reroll random')
        self.mutation('wram.asm', 'wJohtoMusicSceneMagic:: ds 1\n\tds 16',
                      'wJohtoMusicSceneMagic:: ds 1\n\tds 17',
                      'original reserved WRAM space')


if __name__ == '__main__':
    unittest.main()
