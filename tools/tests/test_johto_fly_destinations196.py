"""Fail-closed negative tests for original-Gold Fly destination onboarding."""
import json
import os
import shutil
from pathlib import Path
from tempfile import TemporaryDirectory
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_fly_destination_audit import audit,FILES,GOLD_FILES


class JohtoFlyDestinations196(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        assert (cls.gold/GOLD_FILES[0]).is_file(),'Full original Gold required'

    def setUp(self):
        self.t=TemporaryDirectory();self.addCleanup(self.t.cleanup)
        self.root=Path(self.t.name)
        for name in (*FILES,'maps/JohtoAzaleaTown.blocked_mask.bin','maps/JohtoGoldenrodCity.blocked_mask.bin','maps/JohtoEcruteakCity.blocked_mask.bin','maps/JohtoMahoganyTown.blocked_mask.bin','maps/JohtoOlivineCity.blocked_mask.bin','maps/JohtoGoldenrodCity.blocked_mask.bin','maps/JohtoGoldenrodCity.blocked_mask.bin','maps/JohtoGoldenrodCity.blocked_mask.bin','maps/JohtoGoldenrodCity.blocked_mask.bin'):
            f=self.root/name;f.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/name,f)

    def mutation(self,file,old,new):
        p=self.root/file;text=p.read_text();self.assertIn(old,text)
        p.write_text(text.replace(old,new,1))
        self.assertTrue(audit(self.root,self.gold))

    def test_five_city_gold_fly_chain_complete(self):
        self.assertEqual(audit(self.root,self.gold),[])

    def test_missing_fly_registration_fails(self):
        self.mutation('tools/johto_native_maps.json','"gold_fly_landmark": "AZALEA_TOWN"','"gold_fly_landmark": null')

    def test_wrong_deferred_city_identity_fails(self):
        p=self.root/'tools/johto_native_maps.json';d=json.loads(p.read_text())
        m=dict(d['maps'][10],local_id=11,local_symbol='JOHTO_ECRUTEAK_CITY_LOCAL_ID',gold_fly_landmark=None)
        m['feature_status']=dict(m['feature_status'],fly='DEFERRED');d['maps'].append(m)
        p.write_text(json.dumps(d))
        self.assertTrue(any('ECRUTEAK' in e for e in audit(self.root,self.gold)))

    def test_deferred_ecruteak_must_not_claim_fly_allowed(self):
        # Historical test ID is pinned by the release gate; it now checks the
        # opposite failure: a built Fly city cannot silently become deferred.
        p=self.root/'tools/johto_native_maps.json'
        d=json.loads(p.read_text())
        row=next(m for m in d['maps'] if m['local_symbol']=='JOHTO_ECRUTEAK_CITY_LOCAL_ID')
        self.assertEqual(row['gold_fly_landmark'],'ECRUTEAK_CITY')
        self.assertEqual(row['feature_status']['fly'],'ALLOWED')
        row['feature_status']['fly']='DEFERRED'
        p.write_text(json.dumps(d))
        self.assertTrue(any('reviewed full integration' in e for e in audit(self.root,self.gold)))

    def test_shared_native_slot_is_not_fly_selector(self):
        self.mutation('engine/johto_fly_town_map.asm',
                      'JOHTO_VIOLET_CITY, JOHTO_AZALEA_FLY_SELECTOR',
                      'JOHTO_VIOLET_CITY, REGION_NATIVE_MAP_SLOT')

    def test_wrong_region_must_not_unlock(self):
        self.mutation('engine/overworld/missable_objects.asm',
                      'cp MAP_REGION_JOHTO\n\tjr nz, .notJohtoAzalea',
                      'cp MAP_REGION_KANTO\n\tjr nz, .notJohtoAzalea')

    def test_unvisited_destination_cannot_be_selected(self):
        self.mutation('engine/johto_fly_town_map.asm',
                      'jp z, .inputLoop ; locked destinations cannot be selected',
                      'jp nz, .inputLoop ; accept locked destination')

    def test_fifth_menu_slot_must_be_reachable(self):
        self.mutation('engine/johto_fly_town_map.asm',
                      '.forwardLoop\n\tcall .isCurrentUnlocked\n\tret nz\n\tld a, [wWhichTownMapLocation]\n\tinc a\n\tcp 10',
                      '.forwardLoop\n\tcall .isCurrentUnlocked\n\tret nz\n\tld a, [wWhichTownMapLocation]\n\tinc a\n\tcp 6')

    def test_unsafe_landing_must_fail(self):
        self.mutation('engine/fly_town_map_helpers.asm',
                      'FLYWARP_DATA JOHTO_AZALEA_TOWN_WIDTH, 10, 15',
                      'FLYWARP_DATA JOHTO_AZALEA_TOWN_WIDTH, 0, 0')

    def test_incorrect_native_map_restoration_must_fail(self):
        self.mutation('engine/fly_town_map_helpers.asm',
                      'cp JOHTO_GOLDENROD_FLY_SELECTOR',
                      'cp JOHTO_ROUTE_33_LOCAL_ID')

    def test_wrong_arrival_tileset_must_fail(self):
        self.mutation('engine/special_warps.asm',
                      'ld a, JOHTO_MODERN\n\tjr .storeTileset',
                      'ld a, JOHTO\n\tjr .storeTileset')

    def test_screen_offset_is_not_tileset_value(self):
        self.mutation('engine/special_warps.asm',
                      'xor a\n.done\n\tld [wYOffsetSinceLastSpecialWarp], a',
                      'nop\n.done\n\tld [wYOffsetSinceLastSpecialWarp], a')

    def test_goldenrod_spot_cannot_be_blocked(self):
        p=self.root/'maps/JohtoGoldenrodCity.blocked_mask.bin'
        data=bytearray(p.read_bytes());data[28*5+15//8] |= 1<<(15%8);p.write_bytes(data)
        self.assertTrue(any('Goldenrod Fly spawn' in e for e in audit(self.root,self.gold)))

    def test_fifth_city_event_cannot_be_removed(self):
        self.mutation('engine/overworld/missable_objects.asm',
                      'set EVENT_JOHTO_FLY_GOLDENROD % 8, [hl]',
                      'set EVENT_JOHTO_FLY_AZALEA % 8, [hl]')

    def test_goldenrod_spot_cannot_be_blocked(self):
        p=self.root/'maps/JohtoGoldenrodCity.blocked_mask.bin'
        data=bytearray(p.read_bytes());data[28*5+15//8] |= 1<<(15%8);p.write_bytes(data)
        self.assertTrue(any('Goldenrod Fly spawn' in e for e in audit(self.root,self.gold)))

    def test_fifth_city_event_cannot_be_removed(self):
        self.mutation('engine/overworld/missable_objects.asm',
                      'set EVENT_JOHTO_FLY_GOLDENROD % 8, [hl]',
                      'set EVENT_JOHTO_FLY_AZALEA % 8, [hl]')

    def test_event_bit_layout_stable_for_old_saves(self):
        self.mutation('constants/event_constants.asm',
                      'ASSERT EVENT_JOHTO_FLY_AZALEA == $456',
                      'ASSERT EVENT_JOHTO_FLY_AZALEA == $457')

    def test_route33_is_not_a_fly_destination(self):
        p=self.root/'tools/johto_native_maps.json';d=json.loads(p.read_text())
        d['maps'][9]['feature_status']['fly']='ALLOWED';p.write_text(json.dumps(d))
        self.assertTrue(audit(self.root,self.gold))


    def test_ecruteak_fly_selector_requires_stable_map_identity(self):
        self.mutation('engine/fly_town_map_helpers.asm',
                      'ld a, [wJohtoFlySelectedLocalID]',
                      'ld a, [wWhichTownMapLocation]')

    def test_accepted_menu_choice_must_be_handed_to_warp(self):
        self.mutation('engine/johto_fly_town_map.asm',
                      'ld [wJohtoFlySelectedLocalID], a',
                      'ld [wWhichTownMapLocation], a')

    def test_physical_map_resolution_cannot_read_shared_menu_scratch(self):
        self.mutation('engine/fly_town_map_helpers.asm',
                      '.goldenrodOrEcruteak\n\tld a, [wJohtoFlySelectedLocalID]',
                      '.goldenrodOrEcruteak\n\tld a, [wWhichTownMapLocation]')

    def test_fly_handoff_wram_byte_cannot_be_removed(self):
        self.mutation('wram.asm','wJohtoFlySelectedLocalID:: ; d7ab',
                      'wUnusedFlyHandoff:: ; d7ab')

    def test_ecruteak_spawn_must_be_safe(self):
        p=self.root/'maps/JohtoEcruteakCity.blocked_mask.bin'
        data=bytearray(p.read_bytes());data[28*5+23//8] |= 1<<(23%8);p.write_bytes(data)
        self.assertTrue(any('Ecruteak Fly spawn' in e for e in audit(self.root,self.gold)))

    def test_ecruteak_visit_must_be_logged(self):
        self.mutation('engine/overworld/missable_objects.asm',
                      'set EVENT_JOHTO_FLY_ECRUTEAK % 8, [hl]',
                      'set EVENT_JOHTO_FLY_GOLDENROD % 8, [hl]')

    def test_missing_gold_source_fails_closed(self):
        with TemporaryDirectory() as tmp:
            g=Path(tmp);self.assertTrue(audit(self.root,g))

    def test_changed_gold_azalea_spawn_fails(self):
        with TemporaryDirectory() as tmp:
            g=Path(tmp)
            for rel in GOLD_FILES:
                p=g/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(self.gold/rel,p)
            p=g/'data/maps/spawn_points.asm';t=p.read_text()
            self.assertIn('spawn AZALEA_TOWN,                15, 10',t)
            p.write_text(t.replace('spawn AZALEA_TOWN,                15, 10',
                                   'spawn AZALEA_TOWN,                 0,  0',1))
            self.assertTrue(audit(self.root,g))


if __name__=='__main__':unittest.main()
