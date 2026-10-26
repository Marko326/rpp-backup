"""Two House1 maps added in one batch; source evidence, not ROM acceptance."""
from pathlib import Path
import os
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', ROOT/'pokegold-master'))
sys.path.insert(0, str(ROOT/'tools'))

ROOMS = (
    ('OlivineTimsHouse', 'JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID', 32, 47, (25,11), 3, 1),
    ('OlivineGoodRodHouse', 'JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID', 35, 48, (13,15), 6, 2),
)

class OlivineHouseBatch241DEV(unittest.TestCase):
    def test_two_house_batch_gold_warp_graph(self):
        city = (ROOT/'data/mapObjects/JohtoOlivineCity.asm').read_text()
        gold_city = (GOLD/'maps/OlivineCity.asm').read_text()
        resolver = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        self.assertIn('db $06 ; three tested houses plus Pokecenter, Cafe, and Mart', city)
        self.assertEqual(len(re.findall(r'(?m)^\s*db\s+\d+,\s*\d+,\s*\d+,\s*REGION_WARP_ESCAPE',city)),6)
        first = (ROOT/'maps/JohtoOlivinePunishmentSpeechHouse.blk').read_bytes()
        mask = (ROOT/'maps/JohtoOlivinePunishmentSpeechHouse.blocked_mask.bin').read_bytes()
        self.assertEqual(len(mask),8)
        self.assertEqual(len(first),16)
        for name, local_id, stable, slot, (x,y), gold_exit, city_index in ROOMS:
            sub = ROOT/'data/mapObjects'/f'Johto{name}.asm'
            obj = sub.read_text()
            gold_source = (GOLD/'maps'/f'{name}.asm').read_text()
            self.assertRegex(gold_city, rf'warp_event\s+{x},\s*{y},\s+{("OLIVINE_TIMS_HOUSE" if name=="OlivineTimsHouse" else "OLIVINE_GOOD_ROD_HOUSE")},\s*1')
            self.assertEqual((ROOT/'maps'/f'Johto{name}.blk').read_bytes(),first)
            self.assertEqual(len(re.findall(r'(?m)^\s*db\s+7,\s*[23],',obj)),2)
            for exit_x in (2,3):
                self.assertIn(f'db 7, {exit_x}, {city_index}, REGION_WARP_ESCAPE',obj)
                self.assertRegex(gold_source,rf'warp_event\s+{exit_x},\s*7,\s*OLIVINE_CITY,\s*{gold_exit}\b')
            self.assertIn(f'db {y}, {x}, 0, REGION_WARP_ESCAPE',city)
            for src, warp, dest, target in (
                ('JOHTO_OLIVINE_CITY_LOCAL_ID',city_index,0,local_id),
                (local_id,0,city_index,'JOHTO_OLIVINE_CITY_LOCAL_ID'),
                (local_id,1,city_index,'JOHTO_OLIVINE_CITY_LOCAL_ID')):
                self.assertEqual(resolver.count(f'db {src}, {warp}, {dest}, MAP_REGION_JOHTO, {target}'),1)
        self.assertIn('db 11, 29, 0, REGION_WARP_ESCAPE',city)

    def test_all_house_returns_step_off_the_solid_gold_doors(self):
        from johto_warp_arrival_audit import profiles, audit
        profile_source = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        city = (ROOT/'data/mapObjects/JohtoOlivineCity.asm').read_text()
        arrivals = profiles(profile_source)
        all_city = [(y,x,origin,direction) for alias,mid,y,x,origin,direction in arrivals
                    if alias == 'REGION_NATIVE_MAP_SLOT' and mid == 'JOHTO_OLIVINE_CITY_LOCAL_ID']
        expected = [(11,29,'REGION_NATIVE_MAP_SLOT','D_DOWN'),
                    (11,25,'REGION_NATIVE_MAP_SLOT','D_DOWN'),
                    (15,13,'REGION_NATIVE_MAP_SLOT','D_DOWN'),
                    (21,13,'REGION_NATIVE_MAP_SLOT','D_DOWN'),
                    (21,7,'REGION_NATIVE_MAP_SLOT','D_DOWN'),
                    (17,19,'REGION_NATIVE_MAP_SLOT','D_DOWN')]
        self.assertEqual(all_city, expected)
        # All six destinations are exact Gold exterior warps and their
        # NEXT cells must be walkable. Neither inside exit lane auto-steps.
        mask = (ROOT/'maps/JohtoOlivineCity.blocked_mask.bin').read_bytes()
        for y,x,_,_ in expected:
            self.assertIn(f'db {y}, {x}, 0, REGION_WARP_ESCAPE', city)
            self.assertTrue(mask[y*5+x//8] & (1<<(x%8)))
            self.assertFalse(mask[(y+1)*5+x//8] & (1<<(x%8)))
        self.assertFalse(any(mid in ('JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID',
                                      'JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID',
                                      'JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID')
                             for _,mid,*_ in arrivals))
        self.assertEqual(audit(ROOT,GOLD), [])

    def test_registered_dense_slots_and_unimplemented_events(self):
        table=(ROOT/'data/johto_map_headers.asm').read_text()
        for name, symbol, stable, slot, _, _, _ in ROOMS:
            self.assertIn(f'dw Johto{name}_h ; stable ID{stable} -> slot{slot}',table)
            self.assertIn(f'db BANK(Johto{name}_h)',table)
            obj=(ROOT/'data/mapObjects'/f'Johto{name}.asm').read_text()
            self.assertIn('db $01 ; Gold',obj)
            self.assertEqual(len(re.findall(r'(?m)^\s*object SPRITE_',obj)),1)
            self.assertNotIn('OPP_',obj) ; self.assertNotIn('ITEM ',obj)
        self.assertIn('DEF NUM_JOHTO_MAPS EQU 57',(ROOT/'constants/region_map_constants.asm').read_text())

    def test_six_outdoor_doors_are_exact_and_ordered(self):
        city=(ROOT/'data/mapObjects/JohtoOlivineCity.asm').read_text()
        entries=re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*REGION_WARP_ESCAPE',city)
        self.assertEqual(entries,[('11','29','0'),('11','25','0'),('15','13','0'),('21','13','0'),('21','7','0'),('17','19','0')])

if __name__=='__main__':
    unittest.main()
