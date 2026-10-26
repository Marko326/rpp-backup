"""Gold Cherrygrove public room NPC-only runtime data; negative mutations."""
from pathlib import Path
import os,sys,unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_cherrygrove_public_audit import audit
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',ROOT/'pokegold-master'))

class CherrygrovePublicNPCOnly(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir(): raise AssertionError('Gold original checkout required')
    def mutate(self,path,old,new,expected):
        raw=(ROOT/path).read_text()
        self.assertEqual(raw.count(old),1,(path,old))
        errs=audit(ROOT,GOLD,{path:raw.replace(old,new,1)})
        self.assertTrue(any(expected in x for x in errs),errs)
    def test_gold_real_npc_only_contract(self):
        self.assertEqual(audit(ROOT,GOLD),[])
    def test_wrong_mart_cast_is_rejected(self):
        self.mutate('data/mapObjects/JohtoCherrygroveMart.asm',
            'object SPRITE_JOHTO_COOLTRAINER_M, 7, 6, WALK, 2, 2',
            'object SPRITE_JOHTO_COOLTRAINER_M, 6, 6, WALK, 2, 2','NPC1 sprite/position/move')
    def test_wrong_pc_fisher_palette_is_rejected(self):
        self.mutate('color/sprites.asm',
            '; SPRITE_JOHTO_FISHER_RED: CherrygrovePokecenter1F Gold PAL_NPC_RED\n\tdb PAL_OW_RED',
            '; SPRITE_JOHTO_FISHER_RED: CherrygrovePokecenter1F Gold PAL_NPC_RED\n\tdb PAL_OW_BLUE',
            'FISHER_RED Gold palette')
    def test_missing_real_mart_city_warp_is_rejected(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
            'db JOHTO_CHERRYGROVE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_CHERRYGROVE_MART_LOCAL_ID',
            'db JOHTO_CHERRYGROVE_LOCAL_ID, 3, 0, MAP_REGION_JOHTO, JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID',
            'runtime source Warp target')
    def test_missing_pc_live_door_collision_is_rejected(self):
        self.mutate('engine/overworld/johto_route33_collision.asm',
            'cp 29\n jr nz, .deny', 'cp 28\n jr nz, .deny',
            'live door collision and direction')
    def test_reject_pc_stair_opening(self):
        self.mutate('data/mapObjects/JohtoCherrygrovePokecenter1F.asm',
            'db $02\n db 7, 3, 4, REGION_WARP_ESCAPE',
            'db $03\n db 7, 3, 4, REGION_WARP_ESCAPE',
            'exactly two outdoor exits')

if __name__ == '__main__':unittest.main()
