"""MUS-282: runtime gate branch flow and bike-off music-cursor regression."""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_gate_music_bike_audit import audit, trace_gate_source


class TestGateMusicContinuity282(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = (ROOT / 'engine/johto_pilot_runtime.asm').read_text()
        cls.audio = (ROOT / 'home/audio.asm').read_text()
        cls.home = (ROOT / 'home/overworld.asm').read_text()
        cls.options = (ROOT / 'engine/menu/options_menu.asm').read_text()

    def report(self, **overrides):
        return audit(ROOT, None, overrides)

    def expect_fail(self, needle, **overrides):
        report = self.report(**overrides)
        self.assertEqual(report['status'], 'FAIL', report)
        self.assertTrue(any(needle in e for e in report['errors']), report['errors'])

    def test_five_active_gates_walk_bike_on_off_stay_idempotent(self):
        report = self.report()
        self.assertEqual(report['status'], 'PASS_STATIC_ONLY', report['errors'])
        self.assertTrue(any(c['check'] == 'music_bank_stub_clears_carry' for c in report['checks']))
        self.assertTrue(any(c['check'] == 'gate_warp_no_forced_music_restart' for c in report['checks']))

    def test_violet_city_music_does_not_fall_into_azalea_branch(self):
        gate='JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID'
        city='JOHTO_VIOLET_CITY_LOCAL_ID'
        rby=self.runtime.split('JohtoPilotLoadMapMusic::',1)[1].split('; Outdoor boundary contract',1)[0]
        gsc=self.options.split('LookupJohtoMapGSCMusic:',1)[1].split('JohtoActiveGSCMusic::',1)[0]
        self.assertEqual(trace_gate_source(rby,gate,city,'rby'),city)
        self.assertEqual(trace_gate_source(gsc,gate,city,'gsc'),city)

    def test_missing_violet_jump_fails_even_with_all_source_names_present(self):
        patched=self.runtime.replace('''    ret nz
    ; MUS-282: the city side must use its own music profile.  Falling
    ; through into .southForestGate silently reverted to the gate default.
    jp .sourceValid
.route35GoldenrodGate''', '''    ret nz
.route35GoldenrodGate''', 1)
        self.assertNotEqual(patched,self.runtime)
        self.expect_fail('rby_resolved_source_JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID_JOHTO_VIOLET_CITY_LOCAL_ID',
                         **{'engine/johto_pilot_runtime.asm':patched})

    def test_south_forest_gate_must_preserve_forest_source(self):
        patched=self.runtime.replace('''    cp JOHTO_ILEX_FOREST_LOCAL_ID
    ret nz
    jp .sourceValid''','''    cp JOHTO_ILEX_FOREST_LOCAL_ID
    ret nz
    ret''',1)
        self.assertNotEqual(patched,self.runtime)
        self.expect_fail('rby_resolved_source_JOHTO_ILEX_AZALEA_GATE_LOCAL_ID_JOHTO_ILEX_FOREST_LOCAL_ID',
                         **{'engine/johto_pilot_runtime.asm':patched})

    def test_north_forest_gate_gsc_must_preserve_route34_source(self):
        patched=self.options.replace('''    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .activeSlot''', '''    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z, .gateDefault''',1)
        self.assertNotEqual(patched,self.options)
        self.expect_fail('gsc_resolved_source_JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID_JOHTO_ROUTE_34_LOCAL_ID',
                         **{'engine/menu/options_menu.asm':patched})

    def test_bike_song_off_stale_carry_must_not_bypass_cache(self):
        patched=self.audio.replace('''CompareMapMusicBankWithCurrentBank:
	; MUS-282: this bank comparator is currently a no-op.  Never leak the
	; carry from the preceding CP $2 / BIT when Bike Song is disabled:
	; that used to bypass the same-song cache and restart gate music.
	and a
	ret''', '''CompareMapMusicBankWithCurrentBank:
	ret''',1)
        self.assertNotEqual(patched,self.audio)
        self.expect_fail('music_bank_stub_clears_carry', **{'home/audio.asm':patched})

    def test_gate_warp_must_not_force_fresh_song(self):
        patched=self.home.replace('''	call UpdateMusic6Times
	call PlayDefaultMusicFadeOutCurrent''', '''	call UpdateMusic6Times
	call PlayDefaultMusic''',1)
        self.assertNotEqual(patched,self.home)
        self.expect_fail('gate_warp_no_forced_music_restart',**{'home/overworld.asm':patched})

    def test_invalid_route34_gate_source_falls_back_not_random_song(self):
        gate='JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID'
        other='JOHTO_ROUTE_29_LOCAL_ID'
        rby=self.runtime.split('JohtoPilotLoadMapMusic::',1)[1].split('; Outdoor boundary contract',1)[0]
        gsc=self.options.split('LookupJohtoMapGSCMusic:',1)[1].split('JohtoActiveGSCMusic::',1)[0]
        self.assertEqual(trace_gate_source(rby,gate,other,'rby'),gate)
        self.assertEqual(trace_gate_source(gsc,gate,other,'gsc'),gate)


if __name__=='__main__': unittest.main()
