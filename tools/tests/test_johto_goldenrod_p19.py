"""P19 Goldenrod exterior + travel features, source-only, no ROM build."""
import os
import re
import subprocess
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
sys.path.insert(0,str(ROOT/'tools'))
from johto_indoor_collision_adapter import plan_gold_quadrant_collision

class GoldenrodP19(unittest.TestCase):
    def test_gold_exact_blocks_and_mask(self):
        self.assertEqual((ROOT/'maps/JohtoGoldenrodCity.blk').read_bytes(),
                         (GOLD/'maps/GoldenrodCity.blk').read_bytes())
        _, mask=plan_gold_quadrant_collision(GOLD,'GoldenrodCity','johto_modern')
        self.assertEqual((ROOT/'maps/JohtoGoldenrodCity.blocked_mask.bin').read_bytes(),mask)
        self.assertEqual(len(mask),180)

    def test_only_34_south_and_goldenrod_north_are_open(self):
        city=(ROOT/'data/mapHeaders/JohtoGoldenrodCity.asm').read_text()
        route=(ROOT/'data/mapHeaders/JohtoRoute34.asm').read_text()
        self.assertRegex(city,r'(?m)^\s*db SOUTH\s*$')
        self.assertRegex(route,r'(?m)^\s*db NORTH\s*$')
        obj=(ROOT/'data/mapObjects/JohtoGoldenrodCity.asm').read_text()
        self.assertIn('db $01 ; only Gold north Route35 gate warp #13',obj)
        self.assertIn('db 1, 19, 2, REGION_WARP_ESCAPE',obj)
        self.assertIn('db $00 ; NPCs and scripts deferred',obj)
        self.assertIn('callba JohtoGoldenrodEdgeFence',(ROOT/'main.asm').read_text())
        self.assertIn('callba JohtoNativeCanStepAhead',(ROOT/'home/overworld.asm').read_text())
        self.assertIn('call JohtoGoldenrodCanStepAhead',(ROOT/'engine/overworld/johto_route33_collision.asm').read_text())
        code=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        self.assertIn('cp 18\n\tjr c, .blocked',code)
        self.assertIn('cp 22\n\tjr nc, .blocked',code)

    def test_gold_two_way_connection_offsets(self):
        cmd=[sys.executable,str(ROOT/'tools/johto_rpp_connection_guard.py'),
             '--project',str(ROOT),'--gold-root',str(GOLD),
             '--edge','JohtoRoute34','JohtoGoldenrodCity','Route34','GoldenrodCity','north',
             '--edge','JohtoGoldenrodCity','JohtoRoute34','GoldenrodCity','Route34','south']
        result=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_bike_sign_safe_one_item_and_retry(self):
        data=(ROOT/'data/mapObjects/JohtoGoldenrodCity.asm').read_text()
        script=(ROOT/'scripts/JohtoGoldenrodCity.asm').read_text()
        self.assertIn('db 30, 28, 1',data)
        for pattern in ('ld b, BICYCLE','call IsItemInBag','lb bc, BICYCLE, 1',
                        'call GiveItem','jr nc, .bagFull','SetEvent EVENT_GOT_BICYCLE'):
            self.assertIn(pattern,script)
        # A blocked sign can be activated from the Gold walkable east neighbor.
        mask=(ROOT/'maps/JohtoGoldenrodCity.blocked_mask.bin').read_bytes()
        self.assertFalse(bool(mask[30*5+29//8] & (1<<(29%8))))
        self.assertIn('JOHTO_MODERN',(ROOT/'data/bike_riding_tilesets.asm').read_text())

    def test_fly_arrival_and_legacy_badge_preservation(self):
        menu=(ROOT/'engine/johto_fly_town_map.asm').read_text()
        warp=(ROOT/'engine/fly_town_map_helpers.asm').read_text()
        move=(ROOT/'engine/menu/start_sub_menus.asm').read_text()
        self.assertIn('JOHTO_GOLDENROD_FLY_SELECTOR',menu)
        self.assertIn('FLYWARP_DATA JOHTO_GOLDENROD_CITY_WIDTH, 28, 15',warp)
        self.assertIn('cp JOHTO_GOLDENROD_FLY_SELECTOR',warp)
        self.assertRegex(move,r'cp MAP_REGION_JOHTO\s+jr z, \.checkFlyLocation\s+ld a, \[wObtainedKantoBadges\]\s+bit 2, a')
        events=(ROOT/'constants/event_constants.asm').read_text()
        self.assertIn('ASSERT EVENT_JOHTO_FLY_GOLDENROD == $457',events)

if __name__=='__main__': unittest.main()
