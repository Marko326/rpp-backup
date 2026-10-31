"""PAL241 source/contract tests: Gold music vs $FC stable-ID Johto runtime.

Read-only tests; they do not build, link, run, or emulate any ROM.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

def get(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')

def between(data: str, left: str, right: str) -> str:
    if data.count(left) != 1 or data.count(right) != 1:
        raise AssertionError('missing or ambiguous source marker: ' + left)
    return data.split(left, 1)[1].split(right, 1)[0]


def check_contract(runtime, options, overworld, wram, main, ids):
    # Native $FC must never be treated as one of the old NPC project aliases.
    p = between(runtime, 'JohtoPilotResolveRegisteredWarp::', '; Physical region identity')
    assert 'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID' in p
    assert 'ld [wJohtoGateMusicSourceLocalID], a' in p
    assert p.index('ld [wJohtoGateMusicSourceLocalID], a') < p.index('ld [wCurLocalMapID], a', p.index('\n.toJohto\n'))
    assert 'ld a, c' in p.split('\n.toJohto\n', 1)[1].split('\n.notGateMusicEntry\n', 1)[0]
    assert 'ld a, [wWarpedFromWhichMap]' not in p
    m = between(runtime, 'JohtoPilotLoadMapMusic::', '; Outdoor boundary contract')
    assert 'call JohtoPilotGetMapProfile' in m
    assert 'cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID' in m
    assert 'ld a, [wJohtoGateMusicSourceLocalID]' in m
    for gate in ('JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID',
                 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID',
                 'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'):
        assert 'cp '+gate in m
    assert '.sourceValid' in m and 'call JohtoPilotGetMapProfile' in m
    assert 'ld [wMapMusicSoundID], a' in m and 'ld [wMapMusicROMBank], a' in m
    assert 'ld a, MUSIC_CITIES1' not in m  # inherited via source profile, not hardcoded
    assert 'wLastMap' not in m

    names = re.findall(r'(?m)^\s*db\s+(MUSIC_GBP_\w+|0)\s*;\s*slot\s*(\d+):', between(options, 'JohtoActiveGSCMusic::','JohtoActiveGSCMusicEnd::'))
    expected = [
        'MUSIC_GBP_GSC_NEW_BARK_TOWN','MUSIC_GBP_GSC_ROUTE29',
        'MUSIC_GBP_GSC_CHERRYGROVE_CITY','MUSIC_GBP_GSC_ROUTE30',
        'MUSIC_GBP_GSC_ROUTE30','MUSIC_GBP_GSC_CHERRYGROVE_CITY',
        'MUSIC_GBP_GSC_VIOLET_CITY','MUSIC_GBP_GSC_ROUTE30','MUSIC_GBP_GSC_ROUTE30',
        'MUSIC_GBP_GSC_ROUTE30','MUSIC_GBP_GSC_ROUTE30',
        'MUSIC_GBP_GSC_ROUTE36','MUSIC_GBP_GSC_ROUTE36',
        'MUSIC_GBP_GSC_UNION_CAVE', 'MUSIC_GBP_GSC_ROUTE30',
    ]
    assert [n for n,i in names[:15]] == expected, names
    assert [n for n,i in names[15:]] == ['MUSIC_GBP_GSC_ROUTE36','MUSIC_GBP_GSC_ROUTE36'], names
    assert [int(i) for n,i in names[:15]] == list(range(15))
    assert [int(i) for n,i in names[15:]] == [21,22]
    assert 'NUM_JOHTO_ACTIVE_MAPS' in options.split('JohtoActiveGSCMusicEnd::', 1)[1][:110]
    assert 'JohtoActiveGSCMusic' in between(options,'LookupJohtoMapGSCMusic:', 'JohtoActiveGSCMusic::')
    helper = between(options, 'LookupJohtoMapGSCMusic:', 'JohtoActiveGSCMusic::')
    assert 'callab GetJohtoActiveSlot' in helper
    assert 'cp JOHTO_INVALID_ACTIVE_SLOT' in helper
    assert 'wJohtoGateMusicSourceLocalID' in helper
    assert '.gateDefault' in helper and 'ld a, [wCurLocalMapID]' in helper
    for gate in ('JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID', 'JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID', 'JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID'):
        assert 'cp '+gate in helper
    assert all('cp '+side in helper for side in ('JOHTO_ROUTE_31_LOCAL_ID', 'JOHTO_VIOLET_CITY_LOCAL_ID', 'JOHTO_ROUTE_32_LOCAL_ID', 'JOHTO_RUINS_OF_ALPH_LOCAL_ID', 'JOHTO_ROUTE_36_LOCAL_ID'))
    assert 'wLastMap' not in helper and 'wWarpedFromWhichMap' not in helper

    scene = between(options, 'CheckJohtoMusicSceneTransition::', '; Legacy RBY ID -> corresponding GSC direct-select ID.')
    assert 'call LookupJohtoMapGSCMusic' in scene
    assert 'ld a, [wLastJohtoMusicSceneID]' in scene
    assert 'ld [wLastJohtoMusicSceneID], a' in scene
    assert 'cp MUSIC_STYLE_GSC' in scene and 'cp MUSIC_STYLE_RND' in scene
    assert 'ld [wLastMusicSoundID], a' in scene
    assert 'MUSIC_STYLE_BIKE_SONG_OFF_BIT' in scene
    assert 'call Random' not in scene # gate must never reroll while entering

    style = between(options, 'ResolveMusicStyle::', 'LookupMusicStyleMap:')
    assert 'call LookupJohtoMapGSCMusic' in style
    assert 'ld a, [wMapMusicSoundID]' in style and 'cp e' in style
    assert 'MUSIC_STYLE_BIKE_SONG_OFF_BIT' in style
    assert '.legacyStyle' in style and '.johtoRND' in style
    assert 'call Random' in style.split('.johtoRND',1)[1]
    assert 'MUSIC_STYLE_GSC_CUSTOM_BIT' in style
    # RBY and custom and global style paths remain; no save format change.
    assert 'MusicStyleRandomExtraMap' in style

    header = between(overworld, 'LoadMapHeader::', 'CopyMapConnectionHeader::')
    assert header.count('callba CheckJohtoMusicSceneTransition') == 1
    assert header.index('callab JohtoPilotLoadMapMusic') < header.index('callba CheckJohtoMusicSceneTransition')
    assert 'callba CheckJohtoMusicSceneTransition' in header.split('.musicSceneLoaded',1)[1]
    assert 'SECTION "Runtime Options Menu", ROMX' in main
    assert 'wJohtoGateMusicSourceLocalID:: ds 1' in wram
    assert 'wLastJohtoMusicSceneID:: ds 1' in wram
    assert 'wEventFlags::' in wram.split('wLastJohtoMusicSceneID:: ds 1',1)[1][:165]
    assert 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 26' in ids

class JohtoMusicScene241Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime=get('engine/johto_pilot_runtime.asm')
        cls.options=get('engine/menu/options_menu.asm')
        cls.home=get('home/overworld.asm')
        cls.wram=get('wram.asm')
        cls.main=get('main.asm')
        cls.ids=get('constants/region_map_constants.asm')
    def check(self, **updates):
        vals = dict(runtime=self.runtime, options=self.options, overworld=self.home,
                    wram=self.wram, main=self.main, ids=self.ids)
        vals.update(updates)
        check_contract(**vals)
    def test_current_stable_id_contract(self): self.check()
    def test_gold_active_scene_mappings_match_source_catalog(self):
        # Reference data is in MUS Gold's data/maps/maps.asm (in handoff ZIP).
        gold = [
            (0, 'NEW_BARK_TOWN'), (1,'ROUTE29'), (2,'CHERRYGROVE_CITY'),
            (3,'ROUTE30'), (4,'ROUTE30'), (125,'CHERRYGROVE_CITY'),
            (5,'VIOLET_CITY'), (6,'ROUTE30'), (7,'ROUTE30'),
            (8,'UNION_CAVE'),
        ]
        active=[int(v) for v in re.findall(r'(?m)^\s*db\s+.*; slot\s*\d+: ID\s*(\d+)',between(self.options,'JohtoActiveGSCMusic::','JohtoActiveGSCMusicEnd::'))]
        self.assertEqual(active, [0,1,2,3,4,125,5,6,7,102,20,19,16,8])
        for local,scene in gold:
            self.assertIn(scene, self.options)
        self.assertNotIn('JOHTO_ROUTE31_VIOLET_GATE', between(self.options,'JohtoActiveGSCMusic::','JohtoActiveGSCMusicEnd::'))
    def test_old_wlastmap_gate_source_regression_fails(self):
        bad=self.runtime.replace('ld a, [wJohtoGateMusicSourceLocalID]\n    cp JOHTO_ROUTE_31_LOCAL_ID','ld a, [wLastMap]\n    cp JOHTO_ROUTE_31_LOCAL_ID',1)
        with self.assertRaises(AssertionError): self.check(runtime=bad)
    def test_stale_warped_map_source_regression_fails(self):
        bad=self.runtime.replace('ld a, c\n    ld [wJohtoGateMusicSourceLocalID], a','ld a, [wWarpedFromWhichMap]\n    ld [wJohtoGateMusicSourceLocalID], a',1)
        with self.assertRaises(AssertionError): self.check(runtime=bad)
    def test_wrong_native_slot_gold_song_regression_fails(self):
        bad=self.options.replace('db MUSIC_GBP_GSC_VIOLET_CITY     ; slot 6:', 'db MUSIC_GBP_GSC_CHERRYGROVE_CITY     ; slot 6:',1)
        with self.assertRaises(AssertionError): self.check(options=bad)
    def test_scene_cache_deletion_regression_fails(self):
        bad=self.options.replace('ld [wLastMusicSoundID], a\n\tret\n\n; Legacy RBY ID', 'ret\n\n; Legacy RBY ID',1)
        with self.assertRaises(AssertionError): self.check(options=bad)
    def test_repeated_random_in_neutral_gate_regression_fails(self):
        bad=self.options.replace('CheckJohtoMusicSceneTransition::','CheckJohtoMusicSceneTransition::\n\tcall Random',1)
        with self.assertRaises(AssertionError): self.check(options=bad)
    def test_music_cache_call_must_run_for_both_map_headers(self):
        bad=self.home.replace('callba CheckJohtoMusicSceneTransition','call CheckJohtoMusicSceneTransition',1)
        with self.assertRaises(AssertionError): self.check(overworld=bad)
    def test_bike_song_off_should_keep_scene_resolution(self):
        bad=self.options.replace('bit MUSIC_STYLE_BIKE_SONG_OFF_BIT, b\n\tjp z, .legacyStyle','jp .legacyStyle',1)
        with self.assertRaises(AssertionError): self.check(options=bad)

if __name__=='__main__': unittest.main()
