"""Park and two gate regressions including intentional negative mutations."""
import os
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_park_activation_audit_286 import audit
GOLD=Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None

class Park286Tests(unittest.TestCase):
    def test_park_26_maps_gold_source_and_all_23_checks(self):
        got=audit(ROOT,GOLD)
        self.assertEqual('PASS_STATIC_ONLY',got['status'],got['errors'])
        self.assertEqual(23,len(got['checks']))
        self.assertFalse(got['rom_built'])
        self.assertFalse(got['phone_accepted'])

    def wrong(self,rel,old,new,expected):
        src=(ROOT/rel).read_bytes() if isinstance(old,bytes) else (ROOT/rel).read_text()
        self.assertIn(old,src)
        mutated=src.replace(old,new,1)
        self.assertNotEqual(src,mutated)
        report=audit(ROOT,GOLD,{rel:mutated})
        self.assertIn(expected,report['errors'],report['errors'])

    def test_wrong_gold_block_rejected(self):
        p='maps/johto_pilot/NationalPark.runtime.blk'
        b=(ROOT/p).read_bytes()
        self.wrong(p,b[:1],bytes([b[0]^1]),'NationalPark_source_runtime_exact')
    def test_wrong_east_gate_block_rejected(self):
        p='maps/johto_pilot/Route36NationalParkGate.runtime.blk'
        b=(ROOT/p).read_bytes()
        self.wrong(p,b[:1],bytes([b[0]^1]),'Route36NationalParkGate_source_runtime_exact')
    def test_shortened_park_collision_rejected(self):
        p='maps/johto_pilot/NationalPark.roles.bin';b=(ROOT/p).read_bytes()
        self.assertIn('NationalPark_role_bytes',audit(ROOT,GOLD,{p:b[:-1]})['errors'])
    def test_missing_park_collision_dispatch_rejected(self):
        self.wrong('engine/johto_land_collision_gateway_272.asm',
                   'cp JOHTO_NATIONAL_PARK_LOCAL_ID','cp JOHTO_GOLDENROD_CITY_LOCAL_ID',
                   'park_and_gates_reach_land_collision')
    def test_gate_wrong_graphics_rejected(self):
        self.wrong('data/johto_park_runtime_286.asm','JohtoParkEastGateRuntimeHeader::\n    db JOHTO_PARK_GATE',
                   'JohtoParkEastGateRuntimeHeader::\n    db JOHTO_PARK',
                   'park_unique_tileset_and_gate_metatiles')
    def test_bad_south_warp_ordinal_rejected(self):
        self.wrong('data/johto_park_runtime_286.asm','db 0, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR',
                   'db 0, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                   'south_gate_object_destinations_exact')
    def test_bad_east_gate_warp_ordinal_rejected(self):
        self.wrong('data/johto_park_runtime_286.asm','db 4, 9, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                   'db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                   'east_gate_object_destinations_exact')
    def test_r36_legacy_ruins_gate_warp_cannot_change(self):
        self.wrong('data/johto_ruins_north_runtime.asm','db 13, 47, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                   'db 13, 47, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                   'old_route36_ruins_warps_preserved')
    def test_wrong_park_south_destination_rejected(self):
        self.wrong('data/johto_park_runtime_286.asm','db 47, 10, 0, JOHTO_REGISTERED_WARP_SELECTOR',
                   'db 47, 10, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                   'park_object_destinations_exact')
    def test_no_bike_permission_for_park_rejected(self):
        self.wrong('data/bike_riding_tilesets.asm','JOHTO_PARK,$FF','JOHTO_PARK_GATE,$FF',
                   'park_music_gate_reuse_and_bike_rules')
    def test_cut_park_gate_pointer_table_rejected(self):
        self.wrong('data/warp_tile_ids.asm','dw JohtoParkGateWarpTileIDs',
                   'dw JohtoParkWarpTileIDs','new_warp_pointer_table_in_bounds')
    def test_wrong_version_rejected(self):
        self.wrong('data/game_version.asm','FIX-5.62.295@','FIX-5.62.285@',
                   'version_286_and_26_active')

if __name__=='__main__':unittest.main()
