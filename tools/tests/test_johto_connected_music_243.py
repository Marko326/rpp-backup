"""MUS-243: a directly connected Johto map must not restart identical BGM.

These are static source contracts plus a small, deliberately explicit state
matrix. They never build/link a ROM and cannot replace on-device playback tests.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

def source(path):
    return (ROOT / path).read_text(encoding="utf-8")

def connect_keep(source_scene, target_scene, source_map_id, target_map_id,
                 live_id, movement, bike_off, region="johto", handle=True):
    """The decision encoded by home/overworld.asm at .loadNewMap.

    State values describe the actual cached *requested* source track, not an
    emulator audio position; a forced restart must remain possible if missing.
    """
    if region != "johto" or not handle or not source_scene:
        return False
    if source_scene != target_scene or source_map_id != target_map_id:
        return False
    if movement == "walking" or (movement == "bike" and bike_off):
        expected = source_map_id
    elif movement == "bike":
        expected = "MUSIC_BIKE_RIDING"
    elif movement == "surf":
        expected = "MUSIC_SURFING"
    else:
        return False
    return live_id == expected

class TestJohtoConnectedMusic243(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.overworld = source("home/overworld.asm")
        cls.options = source("engine/menu/options_menu.asm")
        cls.profiles = source("engine/johto_pilot_runtime.asm")
        cls.version = source("data/game_version.asm")

    def seam_code(self):
        return self.overworld.split(".loadNewMap ; load the connected map that was entered", 1)[1].split(".didNotEnterConnectedMap", 1)[0]

    def test_only_seam_path_owns_guard_and_previous_profile_snapshot(self):
        code = self.seam_code()
        self.assertIn("ld a, [wLastJohtoMusicSceneID]", code)
        self.assertIn("ld a, [wMapMusicSoundID]", code)
        self.assertRegex(code, r"push bc\s+call LoadMapHeader\s+pop bc")
        self.assertEqual(code.count("call PlayDefaultMusicFadeOutCurrent"), 1)
        self.assertNotIn("call Random", code)
        self.assertIn(".keepConnectedMapMusic", code)
        self.assertLess(code.index(".keepConnectedMapMusic"), code.index("ld b, SET_PAL_OVERWORLD"))
        self.assertNotIn(".keepConnectedMapMusic", self.overworld.split("LoadMapData::", 1)[1].split("CheckMapConnections::", 1)[0])

    def test_guard_checks_both_gold_scene_and_requested_rby_track(self):
        code = self.seam_code()
        for fragment in [
            "cp MAP_REGION_JOHTO", "cp JOHTO_RUNTIME_MAP_HANDLE",
            "ld a, b\n\tand a", "ld a, [wLastJohtoMusicSceneID]\n\tcp b",
            "ld a, [wMapMusicSoundID]\n\tcp c", "ld a, [wLastMusicSoundID]",
            "cp MUSIC_BIKE_RIDING", "cp MUSIC_SURFING",
            "bit MUSIC_STYLE_BIKE_SONG_OFF_BIT, a",
        ]:
            self.assertIn(fragment, code)

    def test_transition_cache_is_updated_in_map_header_before_guard(self):
        code = self.seam_code()
        self.assertLess(code.index("call LoadMapHeader"), code.index("ld a, [wLastJohtoMusicSceneID]", code.index("call LoadMapHeader")))
        header = self.overworld.split("LoadMapHeader::",1)[1].split("CopyMapConnectionHeader::",1)[0]
        self.assertIn("callba CheckJohtoMusicSceneTransition", header)

    def test_both_route_profiles_and_gold_ids_are_same(self):
        self.assertIn("johto_map_profile 1, 3, MUSIC_ROUTES1, 0     ; 3 Route30", self.profiles)
        self.assertIn("johto_map_profile 1, 4, MUSIC_ROUTES1, 0     ; 4 Route31", self.profiles)
        self.assertIn("db MUSIC_GBP_GSC_ROUTE30         ; slot 3:", self.options)
        self.assertIn("db MUSIC_GBP_GSC_ROUTE30         ; slot 4:", self.options)
        self.assertIn('PAL-5.62.243@', self.version)

    def test_same_music_walking_and_bike_off_both_directions(self):
        for a,b in [(3,4),(4,3)]:
            for mode in ("walking", "bike"):
                with self.subTest(a=a,b=b,mode=mode):
                    self.assertTrue(connect_keep("route30", "route30", "ROUTES1", "ROUTES1", "ROUTES1", mode, True))

    def test_bike_song_on_and_surf_have_their_own_live_cache(self):
        self.assertTrue(connect_keep("route30","route30","ROUTES1","ROUTES1","MUSIC_BIKE_RIDING","bike",False))
        self.assertTrue(connect_keep("route30","route30","ROUTES1","ROUTES1","MUSIC_SURFING","surf",False))
        self.assertFalse(connect_keep("route30","route30","ROUTES1","ROUTES1","ROUTES1","bike",False))

    def test_different_song_or_invalid_cache_never_suppresses_restart(self):
        for vals in [
            ("route30", "violet", "ROUTES1", "CITIES1", "ROUTES1", "walking", False),
            ("route30", "route30", "ROUTES1", "ROUTES1", 0, "walking", False),
            (0, "route30", "ROUTES1", "ROUTES1", "ROUTES1", "walking", False),
            ("route30", "route30", "ROUTES1", "ROUTES1", "MUSIC_BIKE_RIDING", "walking", False),
            ("route30", "route30", "ROUTES1", "ROUTES1", "ROUTES1", "unknown", False),
        ]:
            self.assertFalse(connect_keep(*vals), vals)

    def test_kanto_and_warp_are_not_overridden(self):
        self.assertFalse(connect_keep("route30","route30","ROUTES1","ROUTES1","ROUTES1","walking",False,region="kanto"))
        self.assertFalse(connect_keep("route30","route30","ROUTES1","ROUTES1","ROUTES1","walking",False,handle=False))
        self.assertNotIn(".keepConnectedMapMusic", self.overworld.split("LoadMapData::",1)[1].split("; HAX: Padding",1)[0])

    def test_fault_injection_missing_scene_guard_detected(self):
        bad = self.seam_code().replace("ld a, [wLastJohtoMusicSceneID]\n\tcp b", "ld a, b\n\tcp b", 1)
        self.assertNotIn("ld a, [wLastJohtoMusicSceneID]\n\tcp b", bad)
        self.assertIn("ld a, [wLastJohtoMusicSceneID]\n\tcp b", self.seam_code())

if __name__ == "__main__":
    unittest.main()
