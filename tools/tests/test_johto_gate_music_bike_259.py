"""MUS-259: automatic current-Gold-gate music/bike coverage and mutations."""
import json, os, sys, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gate_music_bike_audit import audit
GOLD=Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None

class GoldGateMusicBike259(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files={name:(ROOT/name).read_text(encoding='utf-8') for name in (
            'home/overworld.asm','engine/johto_pilot_runtime.asm',
            'engine/menu/options_menu.asm','home/audio.asm',
            'data/bike_riding_tilesets.asm','tools/johto_gate_music_bike_contracts.json',
            'tools/johto_map_name_sign_contracts.json')}
    def audit(self, **changes):
        return audit(ROOT,GOLD,{**self.files,**changes})
    def assert_failure(self,reason,**changes):
        report=self.audit(**changes)
        self.assertEqual(report['status'],'FAIL',report)
        self.assertTrue(any(reason in error for error in report['errors']),report['errors'])
    def test_all_active_gold_gate_policies(self):
        report=self.audit()
        self.assertEqual(report['status'],'PASS_STATIC_ONLY',report['errors'])
        self.assertFalse(report['runtime_verified'])
    def test_reference_gold_real_gates_and_indoor_exceptions(self):
        if GOLD is None: self.skipTest('Gold source required for environment comparisons')
        report=self.audit()
        self.assertTrue(report['gold_checked'])
        self.assertEqual(report['status'],'PASS_STATIC_ONLY',report['errors'])
    def test_missing_north_gate_bike_fails(self):
        home=self.files['home/overworld.asm'].replace('\tcp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n\tjr z, .allowed\n','',1)
        self.assert_failure('bike_every_eligible_gate',**{'home/overworld.asm':home})
    def test_bike_leak_to_house_or_kanto_fails(self):
        tiles=self.files['data/bike_riding_tilesets.asm']+'\n db JOHTO_GATE\n'
        self.assert_failure('bike_no_global_gate_tileset',**{'data/bike_riding_tilesets.asm':tiles})
    def test_missing_one_gate_music_source_fails(self):
        runtime=self.files['engine/johto_pilot_runtime.asm'].replace('    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n    jr nz, .notGateMusicEntry','    cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n    jr z, .notGateMusicEntry',1)
        self.assert_failure('capture_every_gate_source',**{'engine/johto_pilot_runtime.asm':runtime})
    def test_north_gate_wrong_rby_source_fails(self):
        runtime=self.files['engine/johto_pilot_runtime.asm'].replace('    cp JOHTO_ROUTE_36_LOCAL_ID\n    jr z, .sourceValid','    cp JOHTO_ROUTE_29_LOCAL_ID\n    jr z, .sourceValid',1)
        self.assert_failure('rby_gate_source_profile',**{'engine/johto_pilot_runtime.asm':runtime})
    def test_north_gate_forced_gsc_song_fails(self):
        options=self.files['engine/menu/options_menu.asm'].replace('    cp JOHTO_ROUTE_36_LOCAL_ID\n    jr z, .activeSlot','    cp JOHTO_ROUTE_29_LOCAL_ID\n    jr z, .activeSlot',1)
        self.assert_failure('gsc_gate_source_profile',**{'engine/menu/options_menu.asm':options})
    def test_same_scene_restart_fails(self):
        opt=self.files['engine/menu/options_menu.asm'].replace('cp c\n\tret z\n','cp c\n\tjr z, .considerRestart\n',1)
        self.assert_failure('music_cursor_kept_on_same_scene',**{'engine/menu/options_menu.asm':opt})
    def test_new_gate_without_contract_fails(self):
        signs=json.loads(self.files['tools/johto_map_name_sign_contracts.json'])
        signs['active_maps'].append({'id':'JOHTO_FAKE_NEW_GATE_LOCAL_ID','role':'neutral','town_map_name':'Route 40'})
        self.assert_failure('active_gold_gate_coverage',**{'tools/johto_map_name_sign_contracts.json':json.dumps(signs)})
    def test_indoor_named_gate_cannot_get_bike_just_from_name(self):
        contract=json.loads(self.files['tools/johto_gate_music_bike_contracts.json'])
        contract['active_gates'][2]['gold_environment']='INDOOR'
        self.assert_failure('gate_policy_',**{'tools/johto_gate_music_bike_contracts.json':json.dumps(contract)})
    def test_wrong_arrival_source_contract_fails(self):
        contract=json.loads(self.files['tools/johto_gate_music_bike_contracts.json'])
        contract['active_gates'][2]['sources'][0]='JOHTO_ROUTE_29_LOCAL_ID'
        self.assert_failure('entry_sources_',**{'tools/johto_gate_music_bike_contracts.json':json.dumps(contract)})

if __name__=='__main__': unittest.main()
