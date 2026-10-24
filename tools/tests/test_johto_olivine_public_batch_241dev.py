"""OLIV-241: public interiors require Gold-source-verified offline batch before runtime enabling."""
import copy
import hashlib
import json
import os
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
RPP = TOOLS.parent
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(RPP/'pokegold-master')))
from johto_indoor_common import ConversionError, gold_warps
from johto_indoor_batch import validate_jobs, run_batch
from johto_indoor_pipeline import _gold_outdoor_pairs

MANIFEST = json.loads((TOOLS/'manifests/olivine_public_buildings_241.json').read_text(encoding='utf-8'))
ROOMS = {
    'olivine_pokecenter_1f': (5, 4, 4, 3, 52),
    'olivine_mart': (6, 4, 3, 2, 49),
    'olivine_cafe': (4, 4, 2, 2, 37),
}


class SchemaGuards(unittest.TestCase):
    def test_all_three_jobs_strict_and_unique(self):
        self.assertEqual(len(validate_jobs(MANIFEST)), 3)
        self.assertEqual({j['id'] for j in MANIFEST['jobs']}, set(ROOMS))

    def test_bad_names_types_and_unapproved_mode_rejected(self):
        for key, bad in [('id', '../untrusted'), ('rpp_room', 'Johto/Oops'),
                         ('gold_outside_map', '../OlivineCity'),
                         ('allow_nonlocal_warps', 'yes'),
                         ('mode', 'install_runtime')]:
            sample = copy.deepcopy(MANIFEST)
            sample['jobs'][0][key] = bad
            with self.subTest(key=key), self.assertRaises(ConversionError):
                validate_jobs(sample)

    def test_duplicate_omitted_and_unknown_job_fields_rejected(self):
        sample = copy.deepcopy(MANIFEST)
        sample['jobs'].append(copy.deepcopy(sample['jobs'][0]))
        with self.assertRaises(ConversionError): validate_jobs(sample)
        sample = copy.deepcopy(MANIFEST)
        del sample['jobs'][1]['gold_tileset']
        with self.assertRaises(ConversionError): validate_jobs(sample)
        sample = copy.deepcopy(MANIFEST)
        sample['jobs'][2]['auto_activate'] = True
        with self.assertRaises(ConversionError): validate_jobs(sample)


@unittest.skipUnless(GOLD.is_dir(), 'Requires Gold original full tree')
class GoldSourceContracts(unittest.TestCase):
    def test_pokecenter_stairs_must_not_be_accepted_as_city_return(self):
        warps = gold_warps(GOLD, 'OlivinePokecenter1F')
        with self.assertRaises(ConversionError):
            _gold_outdoor_pairs(GOLD, 'OlivinePokecenter1F', 'OlivineCity', warps)
        status = _gold_outdoor_pairs(GOLD, 'OlivinePokecenter1F', 'OlivineCity', warps,
                                     allow_nonlocal_warps=True)
        self.assertFalse(status['verified_single_outside_house_topology'])
        self.assertEqual(status['nonlocal_indoor_warps_1_based'], [
            {'id': 3, 'x': 0, 'y': 7, 'dest_map': 'POKECENTER_2F', 'dest_id': 1}])
        self.assertEqual(len(status['inside_to_outside_1_based']), 2)
        self.assertFalse(status['runtime_approved'])

    def test_unrelated_city_warp_cannot_be_used_for_a_room_return(self):
        warps = gold_warps(GOLD, 'OlivineMart')
        tampered = copy.deepcopy(warps)
        tampered[0]['dest_id'] = 7  # Cafe is a different entrance
        with self.assertRaises(ConversionError):
            _gold_outdoor_pairs(GOLD, 'OlivineMart', 'OlivineCity', tampered)

    def test_candidate_assets_are_grounded_and_stay_unregistered(self):
        main = (RPP/'main.asm').read_text()
        headers = (RPP/'data/johto_map_headers.asm').read_text()
        obj = (RPP/'data/mapObjects/JohtoOlivineCity.asm').read_text()
        self.assertIn('db $06 ; three tested houses plus Pokecenter, Cafe, and Mart', obj)
        for job in MANIFEST['jobs']:
            rel = job['id']
            d = TOOLS/'olivine_public_candidates'/rel
            manifest = json.loads((d/'provenance.json').read_text())
            self.assertEqual(manifest['candidate_status'], 'OFFLINE_ONLY_NEVER_REGISTERED')
            self.assertEqual([*manifest['dimensions_blocks']], list(ROOMS[rel][:2]))
            self.assertEqual(len(manifest['warps_gold_one_based']), ROOMS[rel][3])
            self.assertEqual(len(manifest['npc_gold']), ROOMS[rel][2])
            self.assertEqual(len(manifest['compacted_source_ids']), ROOMS[rel][4])
            for fname, sha in manifest['asset_sha256'].items():
                self.assertEqual(hashlib.sha256((d/fname).read_bytes()).hexdigest(), sha)
            for p in d.glob('*.png'):
                self.assertNotIn('INCBIN "'+str(p.relative_to(RPP)).replace('\\','/')+'"', main)
            self.assertIn('dw '+job['rpp_room']+'_h', headers)
            self.assertIn(job['rpp_room']+'Blocks: INCBIN', main)
        shared = TOOLS/'olivine_public_candidates/shared_gold_sprites'
        sprites = json.loads((shared/'provenance.json').read_text())
        self.assertEqual(len(sprites['sha256']), 8)
        for f, digest in sprites['sha256'].items():
            self.assertEqual(hashlib.sha256((shared/f).read_bytes()).hexdigest(), digest)
        pc = TOOLS/'olivine_public_candidates/olivine_pokecenter_1f'
        mask = (pc/'JohtoOlivinePokecenter1F.blocked_mask.bin').read_bytes()
        self.assertEqual(len(mask), 16)
        # row7, x0 (stair to Pokecenter2F) must NOT be traversable.
        self.assertEqual(mask[7*2] & 1, 1)

    def test_offline_batch_refuses_to_overwrite_now_registered_rooms(self):
        """After runtime registration, the old offline installer must fail closed."""
        files = ('main.asm', 'home/overworld.asm',
                 'engine/overworld/region_map_lookup.asm',
                 'data/mapObjects/JohtoOlivineCity.asm',
                 'data/johto_map_headers.asm')
        before = {f:hashlib.sha256((RPP/f).read_bytes()).hexdigest() for f in files}
        with TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ConversionError, '目标室内已登记'):
                run_batch(RPP, GOLD, Path(temp)/'batch', MANIFEST)
        self.assertEqual(before, {f:hashlib.sha256((RPP/f).read_bytes()).hexdigest() for f in files})


if __name__ == '__main__':
    unittest.main()
