"""Developer Surf review: future map onboarding and every gameplay input path."""
import json
import os
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_surf_build_gate_296 import audit, SURF, SPATIAL, ENTRY, ITEMS, HOME, MANIFEST
from johto_surf_coverage_audit import read_active_maps
from johto_surf_manifest_from_gold_296 import generate
GOLD=Path(os.environ.get('GOLD_SOURCE_ROOT') or os.environ.get('JOHTO_GOLD_SOURCE') or
          '/mnt/data/reference/REFERENCES/Gold/pokegold-master')

class SurfBuildGate296(unittest.TestCase):
    def assert_bad(self, result, expected):
        self.assertEqual(result['status'],'FAIL',result)
        self.assertIn(expected,'; '.join(result['errors']))

    def mutate_source(self,path,before,after,expected):
        original=(ROOT/path).read_text(encoding='utf8')
        self.assertIn(before,original)
        self.assert_bad(audit(ROOT,overrides={path:original.replace(before,after,1)}),expected)

    def test_all_active_water_maps_with_no_external_reference(self):
        result=audit(ROOT)
        self.assertEqual(result['status'],'PASS_STATIC_ONLY',result['errors'])
        self.assertEqual(result['active_maps'],28)
        self.assertEqual(result['water_maps'],13)
        self.assertEqual(len(result['checked']),28)
        self.assertEqual(sum(x['water_cells'] for x in result['checked']),1150)
        self.assertEqual(len([r for r in result['checked'] if r['handler']=='GOLD_SPATIAL']),5)

    def test_new_active_map_cannot_escape_without_manual_water_review(self):
        fake={'map':'FutureWaterRoute','stable_id':99,
              'source_asset':'maps/johto_pilot/Route37.gold.blk','exact_gold':True}
        self.assert_bad(audit(ROOT,active_override=read_active_maps(ROOT)+[fake]),
                        'FutureWaterRoute: NEW ACTIVE MAP NOT SURF-REVIEWED')

    def test_new_manifest_entry_alone_cannot_authorize_unimplemented_surf(self):
        base=json.loads((ROOT/MANIFEST).read_text())
        rows=read_active_maps(ROOT)
        fake=dict(rows[-1]); fake['map']='FutureWaterRoute'; fake['stable_id']=99
        # Even if someone copies an existing water profile into an approved
        # manifest, a map without real runtime ID/selector must still fail.
        copied=dict(base['maps'][-1]); copied['map']=fake['map'];copied['stable_id']=99
        base['maps'].append(copied)
        self.assert_bad(audit(ROOT,active_override=rows+[fake],manifest_override=base),
                        'FutureWaterRoute: active WATER map has no live stable ID/tileset')

    def test_source_bytes_modified_without_gold_reference_still_block_build(self):
        item=read_active_maps(ROOT)[-1]
        raw=(ROOT/item['source_asset']).read_bytes()
        self.assert_bad(audit(ROOT,bytes_override={item['source_asset']:raw+b'\x00'}),
                        'Gold source bytes changed without Surf review')

    def test_dry_map_runtime_cannot_introduce_unreviewed_water(self):
        rel='maps/johto_pilot/Route37.roles.bin'
        blob=bytearray((ROOT/rel).read_bytes())
        self.assertNotIn(2,blob)
        blob[18]=2
        self.assert_bad(audit(ROOT,bytes_override={rel:bytes(blob)}),
                        'Route37: runtime WATER role=2 appeared on Gold-dry map')

    def test_missing_ecruteak_swim_branch(self):
        self.mutate_source(SURF,'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .southModern',
                           'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .legacy',
                           'EcruteakCity: WATER exists, Surf movement/shore not routed')

    def test_missing_route35_swim_branch(self):
        self.mutate_source(SURF,'cp JOHTO_ROUTE_35_LOCAL_ID\n    jp z, .southModern',
                           'cp JOHTO_ROUTE_35_LOCAL_ID\n    jp z, .legacy',
                           'Route35: WATER exists, Surf movement/shore not routed')

    def test_missing_legacy_route32_swim_branch(self):
        self.mutate_source(SURF,'cp JOHTO_ROUTE_32_LOCAL_ID\n\tjp z, .route32',
                           'cp JOHTO_ROUTE_32_LOCAL_ID\n\tjp z, .legacy',
                           'Route32: legacy WATER movement/shore branch not executable')

    def test_modern_tileset_movement_missing(self):
        self.mutate_source(SURF,'cp JOHTO_MODERN\n    jp z, .southModern',
                           'cp JOHTO_MODERN\n    jp z, .legacy',
                           'WATER exists, tileset JOHTO_MODERN not routed')

    def test_a_button_not_forwarded(self):
        self.mutate_source(ENTRY,'callab JohtoVioletWaterAhead\n\tret c',
                           'callab JohtoVioletWaterAhead\n\tret nc',
                           'SURF_INPUT: A-button')

    def test_item_not_forwarded(self):
        self.mutate_source(ITEMS,'callab JohtoVioletWaterAhead\n\tjr c, .shoreOrWater',
                           'callab JohtoVioletWaterAhead\n\tjr nc, .shoreOrWater',
                           'SURF_INPUT: Surfboard/item')

    def test_swimming_probe_not_used(self):
        self.mutate_source(SURF,'callab JohtoSouthGoldWaterProbe\n    jp c, .water',
                           'callab JohtoSouthGoldWaterProbe\n    jp nc, .water',
                           'SURF_MOVE_LAND: shared Gold movement/shore')

    def test_disembark_land_safety_broken(self):
        self.mutate_source(SURF,'callab JohtoSouthGoldShoreProbe\n    jp c, .floorShore',
                           'callab JohtoSouthGoldShoreProbe\n    jp nc, .floorShore',
                           'SURF_MOVE_LAND: shared Gold movement/shore')

    def test_dpad_up_step_broken(self):
        self.mutate_source(SPATIAL,'.north\n    dec d\n    jp .bounds',
                           '.north\n    inc d\n    jp .bounds',
                           'SURF_DPAD: Gold four-direction')

    def test_dpad_right_step_broken(self):
        self.mutate_source(SPATIAL,'cp PLAYER_DIR_RIGHT\n    jp nz, .bad\n    inc e',
                           'cp PLAYER_DIR_RIGHT\n    jp nz, .bad\n    dec e',
                           'SURF_DPAD: Gold four-direction')

    def test_shore_rom0_carry_broken(self):
        self.mutate_source(HOME,'callab JohtoOverworldSurfDecision\n\tjr nc, .johtoSurfNotWater',
                           'callab JohtoOverworldSurfDecision\n\tjr c, .johtoSurfNotWater',
                           'SURF_MOVE_LAND: ROM0')

    def test_faked_branch_after_legacy_unreachable(self):
        source=(ROOT/SURF).read_text()
        src='    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n    jp z, .southModern\n'
        self.assertIn(src,source)
        modified=source.replace(src,'',1).replace('\tjp .legacy\n.violet',
                      '\tjp .legacy\n'+src+'.violet',1)
        self.assert_bad(audit(ROOT,overrides={SURF:modified}),
                        'EcruteakCity: WATER exists, Surf movement/shore not routed')

    def test_role_mask_wrong_cell(self):
        rel='maps/johto_pilot/EcruteakCity.roles.bin'
        blob=bytearray((ROOT/rel).read_bytes())
        index=blob.index(2)
        blob[index]=0
        self.assert_bad(audit(ROOT,bytes_override={rel:bytes(blob)}),
                        'EcruteakCity: role=2 grid does not match Gold WATER')

    def test_dev_review_is_not_a_user_build_hook(self):
        make=(ROOT/'Makefile').read_text()
        self.assertNotIn('surf-preflight',make)
        self.assertNotIn('johto_surf_build_gate_296.py',make)
        master=(ROOT/'tools/johto_pilot_migration_audit.py').read_text()
        self.assertIn('all_active_surf_build_gate_296',master)
        self.assertIn('audit_surf_build_296(project',master)

    def test_developer_check_runs_gold_and_selftests_before_patch(self):
        from johto_surf_dev_check_296 import review
        if not GOLD.is_dir():
            self.skipTest('Original Gold required for developer review')
        result=review(ROOT,GOLD)
        self.assertEqual(result['status'],'PASS_STATIC_ONLY',result)
        self.assertTrue(all(result['fault_injection'].values()))
        self.assertFalse(result['rom_built'])

    @unittest.skipUnless(GOLD.is_dir(),'Requires Gold original to check the locked manifest')
    def test_manifest_generated_from_gold_is_exact(self):
        self.assertEqual(generate(ROOT,GOLD),json.loads((ROOT/MANIFEST).read_text()))
        result=audit(ROOT,GOLD)
        self.assertEqual(result['status'],'PASS_STATIC_ONLY',result['errors'])

if __name__=='__main__': unittest.main()
