"""Consecutive Gold maps: use the existing converter and refuse skipped routes."""
import os
import sys
import shutil
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_ROOT', os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold')))
sys.path.insert(0, str(ROOT / 'tools'))
from johto_indoor_common import ConversionError
from johto_rpp_pipeline import stage_adjacent_pair, stage_gold_map_candidate
from johto_rpp_asset_audit import layout_inventory, tileset_key
from johto_indoor_collision_adapter import (plan_gold_quadrant_collision,
                                             validated_downhill_ledge_chain)


class AdjacentPairPipeline233(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD / 'data/maps/attributes.asm').is_file():
            raise RuntimeError('JOHTO_GOLD_ROOT must point to the full pokegold source')

    def test_route39_olivine_pair_is_exact_and_stays_offline(self):
        with TemporaryDirectory() as temp:
            target = Path(temp) / 'pair'
            report = stage_adjacent_pair(ROOT, GOLD, target, ('Route39', 'OlivineCity'))
            self.assertEqual([(x['from'], x['direction'], x['to'], x['gold_offset_blocks'])
                              for x in report['direct_seams']], [
                ('Route39', 'south', 'OlivineCity', -5),
                ('OlivineCity', 'north', 'Route39', 5)])
            self.assertEqual([(x['width'], x['height']) for x in report['maps']],
                             [(10, 18), (20, 18)])
            self.assertTrue(report['source_geometry_verified'])
            self.assertFalse(report['runtime_approved'])
            self.assertEqual(report['status'], 'OFFLINE_PAIR_REVIEW_REQUIRED')
            for name in ('Route39', 'OlivineCity'):
                original = (GOLD / 'maps' / f'{name}.blk').read_bytes()
                staged = (target / name / 'preserved_gold_art_candidate' / f'{name}.blk').read_bytes()
                self.assertEqual(staged, original)
                self.assertTrue((target / name / 'gold_collision_mask.bin').is_file())
            with self.assertRaises(ConversionError):
                stage_adjacent_pair(ROOT, GOLD, target, ('Route39', 'OlivineCity'))

    def test_nonadjacent_pair_is_rejected_before_writing_files(self):
        with TemporaryDirectory() as temp:
            dest = Path(temp) / 'pair'
            with self.assertRaisesRegex(ConversionError, 'not a direct bidirectional'):
                stage_adjacent_pair(ROOT, GOLD, dest, ('Route38', 'OlivineCity'))
            self.assertFalse(dest.exists())

    def test_duplicate_and_unregistered_names_rejected(self):
        with TemporaryDirectory() as temp:
            for pair in (('Route39', 'Route39'), ('Route39', 'NotRealGoldMap')):
                with self.assertRaises(ConversionError):
                    stage_adjacent_pair(ROOT, GOLD, Path(temp) / 'pair', pair)

    def test_staged_rpp_game_resources_match_gold_and_generated_masks(self):
        # The new game-side binary resources must not be approximated by hand;
        # registration and runtime permissions stay out of this staging step.
        for name, dimensions in [('Route39', (10, 18)), ('OlivineCity', (20, 18))]:
            self.assertEqual((ROOT/'maps'/f'Johto{name}.blk').read_bytes(),
                             (GOLD/'maps'/f'{name}.blk').read_bytes())
            geometry, expected_mask = plan_gold_quadrant_collision(GOLD, name, 'johto')
            self.assertEqual((geometry['width_cells'], geometry['height_cells']),
                             (dimensions[0] * 2, dimensions[1] * 2))
            self.assertEqual((ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes(),
                             expected_mask)

    def test_gold_seam_mutation_is_rejected_even_if_both_maps_exist(self):
        # Check topology independently against Gold attributes. Copy only the
        # relevant source file, not thousands of assets, to fault-inject it.
        with TemporaryDirectory() as temp:
            fakegold = Path(temp) / 'gold'
            (fakegold / 'data/maps').mkdir(parents=True)
            attrs = (GOLD / 'data/maps/attributes.asm').read_text(encoding='utf-8')
            source = '\tconnection north, Route39, ROUTE_39, 5'
            self.assertIn(source, attrs)
            (fakegold / 'data/maps/attributes.asm').write_text(
                attrs.replace(source, '\tconnection north, Route39, ROUTE_39, 4', 1),
                encoding='utf-8')
            # All source audits run before generating candidate resources.
            # Call frozen source checker directly, since this synthetic tree
            # does not purport to contain an entire Gold checkout.
            from johto_rpp_connection_guard import check_frozen_gold_source, ConnectionError
            with self.assertRaisesRegex(ConnectionError, 'mismatch'):
                check_frozen_gold_source(fakegold)

    def test_route39_three_tier_downhill_is_proven_by_full_source_chain(self):
        geometry, _ = plan_gold_quadrant_collision(GOLD, 'Route39', 'johto')
        self.assertEqual(len(geometry['hops']), 20)
        self.assertEqual(geometry['unsafe_hop_candidates'], [])
        expected = {(x, 22, 0, 1) for x in (7, 10, 11, 12, 13)}
        found = {(h['x'], h['y'], h['dx'], h['dy']) for h in geometry['hops']}
        self.assertTrue(expected <= found, expected - found)
        # Preserve the existing Ruins audit: a ledge ending on a wall is
        # still prohibited; the enhanced predicate must not "fix" it.
        ruins, _ = plan_gold_quadrant_collision(GOLD, 'RuinsOfAlphOutside', 'johto')
        self.assertEqual(len(ruins['hops']), 16)
        self.assertEqual(len(ruins['unsafe_hop_candidates']), 1)

    def test_chained_ledge_negative_intermediate_wall_and_final_landing(self):
        # Proof starts at first HOP landing, and requires walls before each
        # next HOP then an ordinary in-bounds final landing.
        cells = [{'role': role} for role in
                 ['HOP_DOWN', 'WALL', 'HOP_DOWN', 'WALL', 'FLOOR']]
        self.assertEqual(validated_downhill_ledge_chain(cells, 1, 5, 0, 0), 2)
        cells[3]['role'] = 'FLOOR'  # previously accepted by "HOP" alone
        self.assertEqual(validated_downhill_ledge_chain(cells, 1, 5, 0, 0), -1)
        cells[3]['role'] = 'WALL'
        cells[4]['role'] = 'WALL'  # unreachable last landing
        self.assertEqual(validated_downhill_ledge_chain(cells, 1, 5, 0, 0), -1)
        self.assertEqual(validated_downhill_ledge_chain(cells, 1, 5, 0, 4), -1)

    def test_paired_live_runtime_contract_has_real_rpp_wiring(self):
        from johto_adjacent_pair_runtime_audit import audit
        self.assertEqual(audit(ROOT, GOLD), [])

    def test_paired_live_gold_water_mask_mutation_is_blocked(self):
        from johto_adjacent_pair_runtime_audit import audit
        key='maps/JohtoOlivineCity.water_mask.bin'
        mask=bytearray((ROOT/key).read_bytes())
        mask[0] ^= 1
        self.assertTrue(any('Surf bitmap' in x for x in audit(ROOT, GOLD, {key:bytes(mask)})))

    def test_paired_live_wrong_seam_target_is_blocked(self):
        from johto_adjacent_pair_runtime_audit import audit
        key='engine/overworld/region_map_lookup.asm'
        original=(ROOT/key).read_text()
        needle='db JOHTO_ROUTE_39_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID'
        self.assertIn(needle,original)
        modified=original.replace(needle,
            'db JOHTO_ROUTE_39_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_42_LOCAL_ID',1)
        self.assertTrue(any('runtime connection' in x for x in audit(ROOT,GOLD,{key:modified})))

    def test_paired_live_wrong_id_slot_or_fly_is_blocked(self):
        from johto_adjacent_pair_runtime_audit import audit
        key='data/johto_map_headers.asm'
        registry=(ROOT/key).read_text()
        bad=registry.replace('dw JohtoRoute39_h ; stable ID25 -> slot28',
                             'dw JohtoRoute39_h ; stable ID25 -> slot27',1)
        self.assertTrue(any('dense active slot' in x for x in audit(ROOT,GOLD,{key:bad})))
        key='engine/johto_fly_town_map.asm'
        fly=(ROOT/key).read_text().replace('ld a, JOHTO_OLIVINE_CITY_LOCAL_ID',
                                           'ld a, JOHTO_MAHOGANY_TOWN_LOCAL_ID',1)
        self.assertTrue(any('Fly cursor' in x for x in audit(ROOT,GOLD,{key:fly})))

    def test_gold_indoor_warps_remain_sealed_in_generated_masks(self):
        from johto_adjacent_pair_runtime_audit import audit
        self.assertEqual(audit(ROOT,GOLD),[])
        city = (ROOT/'data/mapObjects/JohtoOlivineCity.asm').read_text()
        self.assertIn('db $01 ; one audited home entrance', city)
        self.assertIn('db 11, 29, 0, REGION_WARP_ESCAPE', city)

    def test_unbuilt_olivine_warp_cannot_be_activated(self):
        from johto_adjacent_pair_runtime_audit import audit
        key='data/mapObjects/JohtoOlivineCity.asm'
        city=(ROOT/key).read_text()
        anchor='db $01 ; one audited home entrance'
        self.assertEqual(city.count(anchor),1)
        mutated=city.replace(anchor,'db $02 ; two accidentally opened entrances',1)
        self.assertTrue(any('one real Warp' in x for x in audit(ROOT,GOLD,{key:mutated})))

    def test_olivine_house_door_warp_cannot_be_retargeted(self):
        from johto_adjacent_pair_runtime_audit import audit
        key='data/mapObjects/JohtoOlivineCity.asm'
        city=(ROOT/key).read_text()
        anchor='db 11, 29, 0, REGION_WARP_ESCAPE'
        self.assertEqual(city.count(anchor),1)
        mutated=city.replace(anchor,'db 11, 30, 0, REGION_WARP_ESCAPE',1)
        self.assertTrue(any('one real Warp' in x for x in audit(ROOT,GOLD,{key:mutated})))

    def test_legacy_single_map_staging_remains_available(self):
        with TemporaryDirectory() as temp:
            inv = {x['name']: x for x in layout_inventory(GOLD)}
            out = Path(temp) / 'Route39'
            report = stage_gold_map_candidate(ROOT, GOLD, out, 'Route39',
                                               tileset_key(inv['Route39']['tileset']))
            self.assertEqual(report['status'], 'OFFLINE_REVIEW_REQUIRED')
            self.assertEqual((report['width'], report['height']), (10, 18))
            self.assertFalse(report['runtime_approved'])
            self.assertTrue(report['staged_blk_matches_gold'])


if __name__ == '__main__':
    unittest.main()
