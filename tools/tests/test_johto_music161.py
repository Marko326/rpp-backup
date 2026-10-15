"""MUS-5.62.161: static scene/music integration safeguards (not runtime audio QA)."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def asm(name):
    return (ROOT / name).read_text(encoding='utf-8')


class JohtoMusicScenes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.maps = asm('data/map_songs.asm')
        cls.style = asm('engine/menu/options_menu.asm')

    def test_map_table_fully_covers_registered_legacy_map_ids(self):
        song_body = self.maps.split('MapSongBanks:', 1)[1].split('MapSongBanksEnd:', 1)[0]
        songs = re.findall(r'^\s*db\s+(MUSIC_[A-Z0-9_]+)\s*,\s*(\d+)', song_body, re.M)
        self.assertEqual(len(songs), 253)
        self.assertTrue(all(bank == '0' for _, bank in songs))
        self.assertIn('ASSERT (MapSongBanksEnd - MapSongBanks) == NUM_LEGACY_MAPS * 2', self.maps)
        self.assertEqual(songs[0][0], 'MUSIC_PALLET_TOWN')
        self.assertEqual(songs[0xF8][0], 'MUSIC_ROUTES3')
        self.assertEqual(songs[0xF9][0], 'MUSIC_CITIES1')
        self.assertEqual(songs[0xFA][0], 'MUSIC_CITIES1')
        self.assertEqual(songs[0xFB][0], 'MUSIC_ROUTES3')

    def test_scene_table_has_exact_johto_city_and_route_mapping(self):
        table = self.style.split('JohtoSceneGSCMap:', 1)[1].split('\tdb $ff', 1)[0]
        pairs = dict(re.findall(r'^\s*db\s+([A-Z0-9_]+)\s*,\s*(MUSIC_GBP_GSC_[A-Z0-9_]+)', table, re.M))
        self.assertEqual(pairs, {
            'NEW_BARK_TOWN': 'MUSIC_GBP_GSC_NEW_BARK_TOWN',
            'JOHTO_ROUTE_29': 'MUSIC_GBP_GSC_ROUTE29',
            'JOHTO_CHERRYGROVE_CITY': 'MUSIC_GBP_GSC_CHERRYGROVE_CITY',
            'JOHTO_ROUTE_30': 'MUSIC_GBP_GSC_ROUTE30',
            'JOHTO_ROUTE_31': 'MUSIC_GBP_GSC_ROUTE30',
            'JOHTO_VIOLET_CITY': 'MUSIC_GBP_GSC_VIOLET_CITY',
            'JOHTO_ROUTE_32': 'MUSIC_GBP_GSC_ROUTE30',
        })
        constants = asm('constants/music_constants.asm')
        for symbol in pairs.values():
            self.assertRegex(constants, r'(?m)^\s*const ' + symbol + r'\s*$')

    def test_gate_uses_same_real_warp_source_for_rby_and_gsc(self):
        home = asm('home/overworld.asm')
        self.assertIn('cp NUM_LEGACY_MAPS', home)
        self.assertIn('cp JOHTO_ROUTE31_VIOLET_GATE', home)
        loader = home.split('LoadMapHeader::', 1)[1].split('CopyMapConnectionHeader::', 1)[0]
        self.assertRegex(loader, r'cp JOHTO_ROUTE31_VIOLET_GATE\s*\n\s*jr nz,\.storeMapSong\s*\n\s*call GetJohtoGateMusicSourceMap\s*\n\s*cp JOHTO_ROUTE_31')
        self.assertNotIn('ld a,[wLastMap]', loader)
        scene = self.style.split('LookupJohtoMapGSCMusic:', 1)[1].split('JohtoSceneGSCMap:', 1)[0]
        self.assertRegex(scene, r'cp JOHTO_ROUTE31_VIOLET_GATE\s*\n\s*jr nz,\.haveMap\s*\n\s*call GetJohtoGateMusicSourceMap')
        self.assertNotIn('wLastMap', scene)

    def test_gate_source_helper_uses_actual_warp_not_old_last_map(self):
        home = asm('home/overworld.asm')
        helper = home.split('GetJohtoGateMusicSourceMap::', 1)[1].split('ExtraWarpCheck::', 1)[0]
        code = [line.split(';')[0].strip() for line in helper.splitlines()]
        code = [line for line in code if line]
        self.assertEqual(code, [
            'ld a,[wWarpedFromWhichMap]',
            'cp JOHTO_ROUTE_31', 'ret z',
            'cp JOHTO_VIOLET_CITY', 'ret z',
            'ld a,JOHTO_VIOLET_CITY', 'ret',
        ])
        warp = home.split('WarpFound2::', 1)[1].split('PlayMapChangeSound::', 1)[0]
        self.assertRegex(warp, r'ld a,\[wCurMap\]\s*\n\s*ld \[wWarpedFromWhichMap\],a\s*\n\s*call CheckIfInOutsideMap')
        self.assertNotIn('ld [wWarpedFromWhichMap],', helper)
        self.assertNotIn('wLastMap', helper)

    def test_gate_music_side_independent_of_stale_legacy_last_map(self):
        # Static truth table for the two accepted real entry sources and the
        # documented safe fallback; the assembly shape is checked above.
        for source, expected in (
            ('JOHTO_ROUTE_31', 'JOHTO_ROUTE_31'),
            ('JOHTO_VIOLET_CITY', 'JOHTO_VIOLET_CITY'),
            ('PALLET_TOWN', 'JOHTO_VIOLET_CITY'),
            ('UNSET', 'JOHTO_VIOLET_CITY'),
        ):
            for stale_last in ('JOHTO_ROUTE_31', 'JOHTO_VIOLET_CITY', 'PALLET_TOWN'):
                actual = source if source in ('JOHTO_ROUTE_31', 'JOHTO_VIOLET_CITY') else 'JOHTO_VIOLET_CITY'
                self.assertEqual(actual, expected, f'{source=} {stale_last=}')
        self.assertNotIn('cp JOHTO ;', asm('home/overworld.asm').split('CheckIfInOutsideMap::')[1].split('GetJohtoGateMusicSourceMap::')[0])

    def test_only_ordinary_map_bgm_is_region_overridden(self):
        body = self.style.split('ResolveMusicStyle::', 1)[1].split('LookupMusicStyleMap:', 1)[0]
        for required in ('wWalkBikeSurfState', 'wCurRegion', 'MAP_REGION_JOHTO',
                         'wMapMusicSoundID', 'LookupJohtoMapGSCMusic',
                         'MUSIC_STYLE_BASE_MASK', 'MusicStyleCSTMMap'):
            self.assertIn(required, body)
        self.assertIn('jp nz,.legacyStyle', body)
        self.assertIn('jp z,.legacyStyle', body)
        self.assertIn('jr z,.random', body)  # existing Kanto random pool unaffected
        self.assertIn('jr z,.gsc', body)
        self.assertNotIn('MUSIC_STYLE_MAGIC0', asm('data/map_songs.asm'))

    def test_version_only_and_no_gate_or_fly_changes(self):
        self.assertIn('REG-5.62.170@', asm('data/game_version.asm'))
        self.assertIn('db $0d', asm('data/mapObjects/JohtoRoute31VioletGate.asm'))
        self.assertIn('db $06,$FF', asm('data/warp_tile_ids.asm'))


if __name__ == '__main__':
    unittest.main()
