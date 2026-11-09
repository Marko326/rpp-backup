"""REF-347 user video regressions: door exit, physical sign, static rock art."""
from pathlib import Path
import re,unittest
ROOT=Path(__file__).resolve().parents[2]
def source(rel):return (ROOT/rel).read_text()
class TestBurnedTower347Video(unittest.TestCase):
 def test_city_door_return_steps_out_not_west_gate(self):
  s=source('engine/johto_pilot_runtime.asm')
  part=s.split('JohtoPilotGateArrivalStep::',1)[1].split('JohtoPilotGateDoorApproachAllowed::',1)[0]
  self.assertIn('cp JOHTO_ECRUTEAK_CITY_LOCAL_ID',part)
  self.assertRegex(part,r'cp 5\s+jr nz, \.westPortalDispatch\s+ld a, \[wYCoord\]\s+cp 5')
  self.assertIn('ld e, D_DOWN\n    ret',part)
  self.assertIn('JohtoWestPortalArrivalStep',part)
  self.assertIn('call JohtoPilotIsVerticalGatePairMap314',part)
 def test_only_reviewed_cave_and_gold_city_doors_auto_step(self):
  s=source('engine/johto_pilot_runtime.asm')
  part=s.split('JohtoPilotGateArrivalStep::',1)[1].split('\n.verticalGateArrivalDispatch314',1)[0]
  self.assertEqual(part.count('ld e, D_DOWN'),2)
  code='\n'.join(line.split(';',1)[0] for line in part.splitlines())
  self.assertRegex(code,r'(?s)cp JOHTO_ROUTE_31_LOCAL_ID.*?cp 34.*?cp 5.*?ld e, D_DOWN')
  self.assertRegex(code,r'(?s)cp JOHTO_ECRUTEAK_CITY_LOCAL_ID.*?cp 5.*?cp 5.*?ld e, D_DOWN')
 def test_burned_tower_location_popup(self):
  s=source('engine/overworld/map_name_sign.asm')
  part=s.split('.ResolvePhysicalLandmark',1)[-1]
  self.assertIn('cp JOHTO_BURNED_TOWER_1F_LOCAL_ID\n\tjp z, .johtoBurnedTower',s)
  self.assertIn('.johtoBurnedTower\n\tld hl, .JohtoBurnedTowerName',s)
  self.assertIn('.JohtoBurnedTowerName: db "Burned Tower@"',s)
  self.assertIn('JohtoBrowseBurnedTowerName: db "Burned_Tower@"',source('engine/johto_pilot_town_map_browse.asm'))
 def test_static_gold_rock_graphics_never_water_animated(self):
  s=source('data/tileset_headers.asm')
  self.assertRegex(s,r'tileset JohtoBurnedTower1F_Block,.*\bINDOOR\b')
  self.assertNotRegex(s,r'tileset JohtoBurnedTower1F_Block,.*\bCAVE\b')
  animator=source('home/vcopy.asm')
  self.assertIn('ret z ; no animations if indoors',animator)
  block=(ROOT/'gfx/blocksets/johto_burned_tower_1f.bst').read_bytes()
  self.assertIn(0x14,block)
 def test_ref348_1f_open_pits_without_changing_exit_carpet_semantics(self):
  # REF-347 had two closed exit carpets; REF-348 legitimately opened 11 PITs
  # and one ladder.  The earlier "B1F must be absent" expectation is obsolete.
  rt=source('data/johto_burned_tower/REF347_1f_runtime.asm')
  self.assertIn('db 14 ; Gold order: two DOWN carpets, eleven PITs, one lower ladder',rt)
  self.assertIn('cp 4 ; Gold WARP_CARPET_DOWN, directional exit',rt)
  self.assertIn('dw JohtoBurnedTowerB1FRuntimeHeader',source('data/johto_header_descriptors.asm'))
  b1f=source('data/johto_burned_tower/REF348_b1f_runtime.asm')
  self.assertIn('db 6 ; five arrival-only landing points',b1f)
  self.assertIn('JohtoBurnedTowerMaybeFallWarp::',b1f)
if __name__=='__main__':unittest.main()
