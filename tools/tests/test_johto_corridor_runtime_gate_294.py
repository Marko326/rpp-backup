"""MAP-294 fault-injection: gate must detect missing live pieces."""
import sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_corridor_runtime_gate_294 import audit
class Corridor294(unittest.TestCase):
 def test_real(self):
  r=audit(ROOT);self.assertEqual(r['status'],'PASS_STATIC_ONLY',r['errors'])
 def change(self,file,old,new,expected):
  s=(ROOT/file).read_text();self.assertIn(old,s)
  r=audit(ROOT,changes={file:s.replace(old,new,1)})
  self.assertIn(expected,r['errors'])
 def test_script_bank(self):
  self.change('data/johto_corridor_runtime_294.asm','dw JohtoCorridorLocalScript','dw JohtoSouthScript','bank_local_scripts_and_mirrors')
 def test_map_header(self):
  self.change('data/johto_header_descriptors.asm','dw JohtoEcruteakRuntimeHeader','dw JohtoSouthScript','two_real_headers_and_active_slots')
 def test_land_dispatch(self):
  self.change('engine/johto_land_collision_gateway_272.asm','cp JOHTO_ECRUTEAK_CITY_LOCAL_ID','cp JOHTO_ROUTE_38_LOCAL_ID','real_land_dispatch_for_both')
 def test_wrong_mirror_offset(self):
  self.change('data/johto_corridor_runtime_294.asm','JohtoRoute37SouthRoute36Mirror + 10','JohtoRoute37SouthRoute36Mirror + 9','north_south_header_mirrors_and_exact_preview')
 def test_missing_boundary(self):
  self.change('engine/johto_pilot_runtime.asm','callab JohtoCorridor37Edge','callab JohtoCorridorEcruteakEdge','closed_edges_dispatch_and_single_exit')
 def test_wrong_gold(self):
  s=bytearray((ROOT/'maps/johto_pilot/Route37.runtime.blk').read_bytes());s[0]^=1
  r=audit(ROOT,changes={'maps/johto_pilot/Route37.runtime.blk':bytes(s)})
  self.assertIn('Route37_gold_unchanged',r['errors'])
 def test_missing_route37_hops(self):
  self.change('engine/overworld/ledges.asm','cp JOHTO_ROUTE_37_LOCAL_ID\n\tjp z, .route37Gold','cp JOHTO_ROUTE_38_LOCAL_ID\n\tjp z, .route37Gold','JohtoRoute37GoldHops_live_dispatch_and_ledge_guard')
 def test_missing_ecruteak_hops(self):
  self.change('engine/overworld/ledges.asm','cp JOHTO_ECRUTEAK_CITY_LOCAL_ID\n\tjp z, .ecruteakGold','cp JOHTO_ROUTE_38_LOCAL_ID\n\tjp z, .ecruteakGold','JohtoEcruteakGoldHops_live_dispatch_and_ledge_guard')
 def test_broken_ecruteak_pond_roles(self):
  a=bytearray((ROOT/'maps/johto_pilot/EcruteakCity.roles.bin').read_bytes())
  a[a.index(2)]=0
  r=audit(ROOT,changes={'maps/johto_pilot/EcruteakCity.roles.bin':bytes(a)})
  self.assertIn('ecruteak_water_20_live_spatial_surf',r['errors'])
 def test_removed_connection(self):
  self.change('data/johto_pilot_source_resources.asm','JOHTO_ROUTE_37_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID','JOHTO_ROUTE_37_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID','four_reciprocal_routes_and_no_unreviewed_west_east')
if __name__=='__main__':unittest.main()
