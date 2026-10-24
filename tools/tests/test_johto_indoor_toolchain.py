"""Source-only regression tests. No ROM compilation or mutation."""
import sys
import tempfile
import unittest
import os
from pathlib import Path

TOOLS=Path(__file__).resolve().parents[1]
ROOT=TOOLS.parent
sys.path.insert(0,str(TOOLS))
from johto_indoor_common import (ConversionError, safe_roots, rpp_warps, gold_warps,
                                 gold_dimensions,gold_dimensions_catalog,rpp_dimensions, warp_tile_ids)
from johto_native_warp_converter import analyze
from johto_bidirectional_warp_validator import validate
from johto_indoor_tiles_converter import (
    build_mapping, stage_dedicated_gold_tileset, resolve_rpp_tileset_atlas)
from johto_indoor_collision_adapter import check, plan_gold_quadrant_collision
from johto_indoor_registration_generator import generate
from johto_indoor_pipeline import pipeline, prestage_unregistered, _gold_outdoor_pairs

GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))  # local test fixture; skip when Gold source not provided

class IndoorToolchainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise unittest.SkipTest('Gold source tree must be supplied for integration test')

    def test_route15_reference_has_four_edge_warps(self):
        records=rpp_warps(ROOT,'Route15Gate1F')
        self.assertEqual([(r['x'],r['y']) for r in records[:4]],[(0,4),(0,5),(7,4),(7,5)])

    def test_dimensions_and_coordinate_order(self):
        self.assertEqual(rpp_dimensions(ROOT,'JohtoRoute31VioletGate'),(5,4))
        self.assertEqual(gold_dimensions(GOLD,'Route31VioletGate'),(5,4))
        self.assertEqual([(q['x'],q['y']) for q in gold_warps(GOLD,'Route31VioletGate')],
                         [(0,4),(0,5),(9,4),(9,5)])

    def test_corpus_dimension_parser_handles_underscored_ship_cabins(self):
        self.assertEqual(gold_dimensions(GOLD,'FastShipCabins_NNW_NNE_NE'), (4,16))
        self.assertEqual(gold_dimensions(GOLD,'FastShipCabins_SW_SSW_NW'), (4,16))
        self.assertEqual(gold_dimensions(GOLD,'FastShipCabins_SE_SSE_CaptainsCabin'), (5,17))

    def test_forest_carpet_approach_is_enumerated_not_runtime_approved(self):
        geometry, _ = plan_gold_quadrant_collision(GOLD, 'IlexForest', 'forest')
        edges = geometry['portal_edges']
        matches = [e for e in edges if (e['from_x'],e['from_y'],
                   e['to_x'],e['to_y'],e['direction']) == (3,41,3,42,'DOWN')]
        self.assertEqual(len(matches),1)
        self.assertEqual(matches[0]['to_role'],'WARP_CARPET_RIGHT')
        self.assertFalse(matches[0]['rpp_runtime_verified'])

    def test_full_corpus_skips_only_user_excluded_beta_map(self):
        from johto_rpp_pipeline import full_gold_corpus
        with tempfile.TemporaryDirectory() as td:
            result = full_gold_corpus(ROOT, GOLD, Path(td)/'corpus')
            self.assertEqual(result['registered_maps'],368)
            self.assertEqual(result['scanned_maps'],367)
            self.assertEqual(result['source_ok'],367)
            self.assertEqual(result['source_failed'],0)
            self.assertEqual(result['excluded_count'],1)
            self.assertEqual(result['excluded_maps'], [
                {'map': 'SafariZoneBeta', 'reason': 'USER_EXCLUDED_BETA_MAP'}])
            self.assertEqual(result['runtime_maps_verified'],0)

    def test_native_tile_40_walkable_not_auto_warp(self):
        plan=analyze(ROOT,GOLD)
        self.assertEqual(len(plan['outside_warps']),4)
        self.assertFalse(any(w['potential_standing_trigger'] for w in plan['outside_warps']))
        self.assertNotIn(0x40,warp_tile_ids(ROOT,'NewBarkWarpTileIDs'))
        self.assertTrue(plan['engine']['extra_warp_checks_johto_explicit'])

    def test_bidirectional_static_graph_is_not_gameplay_approval(self):
        result=validate(ROOT,analyze(ROOT,GOLD))
        self.assertEqual(result['graph_check'],'PASS')
        self.assertFalse(result['gameplay_accepted'])
        self.assertFalse(any(x['code']=='OUTDOOR_STANDING_TRIGGER_RISK' for x in result['findings']))

    def test_gold_art_is_not_assumed_compatible(self):
        report,staged=build_mapping(ROOT,GOLD)
        self.assertEqual(report['width'],5)
        self.assertEqual(report['height'],4)
        self.assertFalse(report['can_stage_pixel_exact_candidate'])
        self.assertIsNone(staged)

    def test_isolated_art_has_same_block_cells_as_gold(self):
        with tempfile.TemporaryDirectory() as path:
            result=stage_dedicated_gold_tileset(GOLD,Path(path))
            self.assertEqual(result['used_compacted_blocks'],13)
            self.assertEqual(len((Path(path)/result['layout']).read_bytes()),20)
            self.assertEqual(len((Path(path)/result['blockset']).read_bytes()),14*16)
            self.assertEqual(result['status'],'PIXEL_ASSET_CANDIDATE_ONLY')

    def test_dedicated_johto_gate_collision_alias_is_derived_from_runtime_header(self):
        artwork,_=build_mapping(ROOT,GOLD,'Route34IlexForestGate','gate','johto_gate')
        result=check(ROOT,GOLD,artwork,'johto_gate')
        self.assertEqual(result['rpp_tilecoll_file'],'gfx/tilesets/gate.tilecoll')
        self.assertFalse(result['auto_approve'])
        self.assertEqual(result['status'],'COLLISION_REVIEW_REQUIRED')

    def test_collision_requires_explicit_review(self):
        artwork,_=build_mapping(ROOT,GOLD)
        result=check(ROOT,GOLD,artwork)
        self.assertFalse(result['auto_approve'])
        self.assertEqual(result['status'],'COLLISION_REVIEW_REQUIRED')

    def test_registration_references(self):
        out=generate(ROOT)
        self.assertTrue(out['components']['object_table'])
        self.assertTrue(out['components']['map_header'])
        self.assertIn('status',out)

    def test_native_route33_and_cave_registration_use_local_id_not_shared_fc(self):
        self.assertEqual(rpp_dimensions(ROOT, 'JohtoRoute33'), (10, 9))
        self.assertEqual(rpp_dimensions(ROOT, 'JohtoUnionCave1F'), (10, 18))
        for name in ('JohtoRoute33', 'JohtoUnionCave1F'):
            result = generate(ROOT, name)
            self.assertEqual(result['registration_strategy'], 'native')
            self.assertEqual(result['failed_checks'], [])
            self.assertFalse(result['status'] == 'GAMEPLAY_ACCEPTED')

    def test_native_dimension_mismatch_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            fixture=Path(td)
            (fixture/'data/mapHeaders').mkdir(parents=True)
            (fixture/'constants').mkdir()
            (fixture/'data/mapHeaders/FakeRoad.asm').write_text(
                'FakeRoad_h:\n db FAKE_ROAD_HEIGHT, FAKE_ROAD_WIDTH\n')
            (fixture/'constants/map_constants.asm').write_text(
                'mapconst FAKE_ROAD, 9, 10\n')
            (fixture/'constants/region_map_constants.asm').write_text(
                'DEF FAKE_ROAD_WIDTH EQU 11\nDEF FAKE_ROAD_HEIGHT EQU 9\n')
            with self.assertRaises(ConversionError):
                rpp_dimensions(fixture, 'FakeRoad')
            (fixture/'constants/map_constants.asm').write_text('')
            self.assertEqual(rpp_dimensions(fixture, 'FakeRoad'), (11, 9))
            (fixture/'constants/region_map_constants.asm').write_text(
                'DEF FAKE_ROAD_WIDTH EQU 11\n')
            with self.assertRaises(ConversionError):
                rpp_dimensions(fixture, 'FakeRoad')

    def test_safe_output_blocks_project_and_gold(self):
        with self.assertRaises(ConversionError):safe_roots(ROOT,GOLD,ROOT/'reports')
        with self.assertRaises(ConversionError):safe_roots(ROOT,GOLD,GOLD/'reports')

    def test_registered_north_gate_must_not_use_preflight_bypass(self):
        # P18 integration requires full runtime Warp audit, never offline-only preflight.
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaisesRegex(ConversionError, '已登记'):
                prestage_unregistered(ROOT, GOLD, Path(td)/'north',
                    gold_room='Route34IlexForestGate',
                    rpp_room='JohtoRoute34IlexForestGate',
                    rpp_tileset='johto_gate')

    def test_prestage_must_reject_existing_gate_to_prevent_skipping_warp_audit(self):
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaisesRegex(ConversionError,'已登记'):
                prestage_unregistered(ROOT,GOLD,Path(td)/'stage',
                    gold_room='Route31VioletGate',
                    rpp_room='JohtoRoute31VioletGate')

    def test_house_atlas_t2_and_gate_atlas_are_resolved_without_guessing(self):
        self.assertEqual(resolve_rpp_tileset_atlas(ROOT, 'house').name, 'house.t2.png')
        self.assertEqual(resolve_rpp_tileset_atlas(ROOT, 'gate').name, 'gate.t1.png')
        self.assertEqual(resolve_rpp_tileset_atlas(ROOT, 'johto_gate').name, 'johto_gate.png')
        with tempfile.TemporaryDirectory() as td:
            atlas = Path(td)/'gfx/tilesets'
            atlas.mkdir(parents=True)
            (atlas/'house.png').write_bytes(b'fake')
            (atlas/'house.t2.png').write_bytes(b'fake')
            with self.assertRaisesRegex(ConversionError, 'expected one PNG'):
                resolve_rpp_tileset_atlas(Path(td), 'house')

    def test_unregistered_olivine_house_preflight_keeps_warps_sealed(self):
        with tempfile.TemporaryDirectory() as td:
            target = Path(td)/'house'
            result = prestage_unregistered(
                ROOT, GOLD, target,
                gold_room='OlivinePunishmentSpeechHouse',
                rpp_room='JohtoOlivinePunishmentSpeechHousePrestageFixture',
                gold_tileset='house', rpp_tileset='house',
                gold_outside_map='OlivineCity', rpp_outside_map='JohtoOlivineCity')
            pair = result['gold_outdoor_pairs']
            self.assertTrue(pair['verified_single_outside_house_topology'])
            self.assertEqual([(x['x'], x['y'], x['dest_id'])
                              for x in pair['outside_to_indoor_1_based']], [(29, 11, 1)])
            self.assertEqual([(x['x'], x['y'], x['dest_id'])
                              for x in result['gold_warps_1_based']], [(2, 7, 5), (3, 7, 5)])
            self.assertEqual(len(result['gold_interactions']['npcs']), 2)
            self.assertEqual(len(result['gold_interactions']['backgrounds']), 2)
            self.assertEqual(len(result['rpp_outdoor_state']['existing_active_warps']), 3)  # three independently registered Olivine houses
            self.assertFalse(result['runtime_warp_enabled'])
            self.assertFalse(result['import_allowed'])
            self.assertEqual(result['art_exact_blocks'], 0)
            self.assertTrue((target/'isolated_gold_art_candidate/house.fixed96.2bpp').exists())
            self.assertIn('OUTDOOR_WARP_NOT_ENABLED', result['blockers'])
            self.assertNotIn('ROUTE34_NOT_CONNECTED', result['blockers'])
            self.assertTrue((target/'12_gold_interactions.json').exists())

    def test_registered_house_cannot_be_prepared_as_unregistered(self):
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaisesRegex(ConversionError, '已登记'):
                prestage_unregistered(ROOT, GOLD, Path(td)/'bad',
                    gold_room='OlivinePunishmentSpeechHouse',
                    rpp_room='JohtoOlivinePunishmentSpeechHouse',
                    gold_tileset='house',rpp_tileset='house')

    def test_preflight_refuses_false_house_outside_return(self):
        original = gold_warps(GOLD, 'OlivinePunishmentSpeechHouse')
        invalid = [dict(w) for w in original]
        invalid[1]['dest_id'] = 4
        with self.assertRaisesRegex(ConversionError, '室内出口'):
            _gold_outdoor_pairs(GOLD, 'OlivinePunishmentSpeechHouse', 'OlivineCity', invalid)
        with self.assertRaisesRegex(ConversionError, '未发现'):
            _gold_outdoor_pairs(GOLD, 'OlivinePunishmentSpeechHouse', 'Route39', original)

    def test_prestage_without_outside_is_explicitly_unreviewed(self):
        with tempfile.TemporaryDirectory() as td:
            result = prestage_unregistered(
                ROOT, GOLD, Path(td)/'house', gold_room='OlivinePunishmentSpeechHouse',
                rpp_room='JohtoOlivinePunishmentSpeechHousePrestageFixture',
                gold_tileset='house', rpp_tileset='house')
            self.assertIn('GOLD_OUTDOOR_RETURN_NOT_REVIEWED', result['blockers'])
            self.assertIsNone(result['gold_outdoor_pairs'])

    def test_pipeline_generates_only_external_reports(self):
        with tempfile.TemporaryDirectory() as path:
            target=Path(path)/'audit'
            result=pipeline(ROOT,GOLD,target)
            self.assertFalse(result['import_allowed'])
            self.assertTrue((target/'REPORT_zh.md').is_file())
            self.assertTrue((target/'05_registration.json').is_file())
            self.assertFalse((target/'Route31VioletGate.pixel_candidate.blk').exists())
            self.assertTrue((target/'06_isolated_original_art.json').exists())
            with self.assertRaises(ConversionError): pipeline(ROOT,GOLD,target)

if __name__=='__main__':unittest.main()
