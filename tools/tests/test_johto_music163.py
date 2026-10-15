"""MUS-5.62.163: map-song continuity/cache regression (static, not audio QA)."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def source(path):
    return (ROOT / path).read_text(encoding='utf-8')


class JohtoMusicContinuation(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.style = source('engine/menu/options_menu.asm')
        cls.overworld = source('home/overworld.asm')
        cls.audio = source('home/audio.asm')
        cls.songtable = source('data/map_songs.asm')
        cls.wram = source('wram.asm')
        cls.helper = cls.style.split('CheckJohtoMusicSceneTransition::', 1)[1].split('JohtoSceneGSCMap:', 1)[0]

    def test_same_legacy_song_can_have_distinct_gsc_scenes(self):
        # Real counterexample: both Cherrygrove and Violet are CITIES1, but
        # the map-specific GSC songs are different. This is not an invented song.
        songs = re.findall(r'^\s*db\s+(MUSIC_[A-Z0-9_]+)\s*,\s*0\b', self.songtable, re.M)
        self.assertEqual(songs[0xce], 'MUSIC_CITIES1')
        self.assertEqual(songs[0xf9], 'MUSIC_CITIES1')
        scene = self.style.split('JohtoSceneGSCMap:', 1)[1].split('db $ff', 1)[0]
        self.assertIn('JOHTO_CHERRYGROVE_CITY,    MUSIC_GBP_GSC_CHERRYGROVE_CITY', scene)
        self.assertIn('JOHTO_VIOLET_CITY,         MUSIC_GBP_GSC_VIOLET_CITY', scene)
        self.assertRegex(self.audio, r'ld a, \[wLastMusicSoundID\]\s*\n\s*cp b')

    def test_call_after_ordinary_header_music_load_and_bank_restore(self):
        loader = self.overworld.split('LoadMapHeader::', 1)[1].split('CopyMapConnectionHeader::', 1)[0]
        self.assertTrue(re.search(r'ld \[wMapMusicSoundID\],a.*?pop af\s*\n\s*ld \[H_LOADEDROMBANK\],a\s*\n\s*ld \[MBC1RomBank\],a.*?callba CheckJohtoMusicSceneTransition\s*\n\s*ret', loader, re.S))
        self.assertNotIn('ld [wLastMap]', self.helper)
        self.assertNotIn('ld [wWarpedFromWhichMap]', self.helper)

    def test_cache_compares_mapped_gsc_song_and_only_invalidates_in_gsc_rnd(self):
        for token in ('call LookupJohtoMapGSCMusic', 'wLastJohtoMusicSceneID',
                      'wJohtoMusicSceneMagic', 'call ReadMusicStyleState',
                      'MUSIC_STYLE_GSC', 'MUSIC_STYLE_RND',
                      'wWalkBikeSurfState', 'wLastMusicSoundID'):
            self.assertIn(token, self.helper)
        self.assertRegex(self.helper, r'cp c\s*\n\s*ret z')
        self.assertRegex(self.helper, r'cp MUSIC_STYLE_GSC\s*\n\s*jr z,\.checkWalking\s*\n\s*cp MUSIC_STYLE_RND\s*\n\s*ret nz')
        self.assertRegex(self.helper, r'ld a,\[wWalkBikeSurfState\]\s*\n\s*and a\s*\n\s*ret nz')
        self.assertNotIn('call Random', self.helper)

    def test_unknown_scenes_and_kanto_invalidate_scene_cache(self):
        # A Kanto -> Johto return must not trust an older matching Johto cache.
        self.assertRegex(self.helper, r'cp MAP_REGION_JOHTO\s*\n\s*jr z,\.johto\s*\n\s*xor a\s*\n\s*ld \[wJohtoMusicSceneMagic\],a')
        self.assertRegex(self.helper, r'call LookupJohtoMapGSCMusic\s*\n\s*and a\s*\n\s*jr nz,\.recognized\s*\n\s*ld \[wJohtoMusicSceneMagic\],a')

    def test_cache_lives_in_existing_reserve_no_sram_layout_shift(self):
        region = self.wram.split('wMusicStyle:: ds 1', 1)[1].split('wNumSigns::', 1)[0]
        self.assertRegex(region, r'wMusicStyleMagic0:: ds 1\s*\n\s*wMusicStyleMagic1:: ds 1')
        self.assertRegex(region, r'wLastJohtoMusicSceneID:: ds 1\s*\n\s*wJohtoMusicSceneMagic:: ds 1\s*\n\s*ds 16')
        self.assertNotIn('wLastJohtoMusicSceneID', source('data/map_songs.asm'))

    def test_state_transition_matrix(self):
        # Behavior model matching helper and existing audio's raw-ID cache.
        def should_restart(previous_gsc, next_gsc, old_rby, new_rby,
                           style, walking=True, recognized=True, prior_region='johto'):
            old_cache_valid = prior_region == 'johto' and previous_gsc is not None
            scene_changed = recognized and (not old_cache_valid or previous_gsc != next_gsc)
            invalidate = scene_changed and style in ('GSC', 'RND') and walking
            return old_rby != new_rby or invalidate
        cherrygrove, violet = 'CHERRYGROVE', 'VIOLET'
        for style in ('GSC', 'RND'):
            self.assertTrue(should_restart(cherrygrove, violet, 'CITIES1', 'CITIES1', style))
            self.assertTrue(should_restart(violet, violet, 'CITIES1', 'CITIES1', style, prior_region='kanto'))
            self.assertFalse(should_restart('ROUTE30', 'ROUTE30', 'ROUTES3', 'ROUTES3', style))
        for style in ('RBY', 'RBY+C'):
            self.assertFalse(should_restart(cherrygrove, violet, 'CITIES1', 'CITIES1', style))
        self.assertFalse(should_restart(cherrygrove, violet, 'CITIES1', 'CITIES1', 'GSC', walking=False))

    def test_version_no_warp_or_graphics_changes(self):
        self.assertIn('MUS-5.62.163@', source('data/game_version.asm'))
        self.assertIn('db $0d', source('data/mapObjects/JohtoRoute31VioletGate.asm'))
        self.assertIn('GetJohtoGateMusicSourceMap::', self.overworld)


if __name__ == '__main__':
    unittest.main()
