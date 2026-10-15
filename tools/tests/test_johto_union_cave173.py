"""Regression contract for Gold walk-on cave entrance, safe immediate return, and water animation."""
from pathlib import Path
from PIL import Image
import re
import unittest
ROOT = Path(__file__).resolve().parents[2]


def read(rel):
    return (ROOT/rel).read_text()


class Cave173RuntimePath(unittest.TestCase):
    def test_only_original_gold_route32_warp(self):
        src=read('data/mapObjects/JohtoRoute32.asm')
        cave=read('data/mapObjects/JohtoUnionCave1F.asm')
        self.assertEqual(re.findall(r'^\s*db\s+(\d+),\s*(\d+),\s*0,\s*REGION_WARP_ESCAPE',src,re.M), [('79','6')])
        self.assertIn('db 3, 17, 0, REGION_WARP_ESCAPE',cave)
        self.assertIn('db $01',cave)  # B1F and Route33 exits stay sealed

    def test_step_before_transfer_and_no_other_global_walls_open(self):
        state=read('engine/overworld/player_state.asm')
        self.assertIn('callba JohtoRoute32CaveWarpTileCheck',state)
        helper=read('engine/overworld/region_map_lookup.asm')
        approach=helper.split('JohtoRoute32CaveEntranceCheck::')[1].split('JohtoRoute32CaveWarpTileCheck::')[0]
        warp=helper.split('JohtoRoute32CaveWarpTileCheck::')[1].split('GetJohtoWarpArrivalStep::')[0]
        self.assertRegex(approach,r'cp 6[\s\S]*cp 80[\s\S]*cp PLAYER_DIR_UP[\s\S]*scf')
        self.assertRegex(warp,r'cp 6[\s\S]*cp 79[\s\S]*scf')
        src=read('home/overworld.asm')
        collision=src.split('CollisionCheckOnLand::')[1].split('CheckTilePassable::')[0]
        self.assertRegex(collision,r'call CheckForJumpingAndTilePairCollisions[\s\S]*?callba JohtoRoute32CaveEntranceCheck[\s\S]*?jr c, \.noCollision[\s\S]*?call CheckTilePassable')
        self.assertNotRegex(src.split('ExtraWarpCheck::')[1].split('MapEntryAfterBattle::')[0],r'callba JohtoRoute32CaveEntranceCheck|JohtoRoute32CaveEntranceCheck')
        self.assertEqual((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes(),bytes([3,4,5,6,64,91,255]))

    def test_cave_entry_steps_inward_before_down_to_exit(self):
        fence=read('main.asm').split('JohtoNativeCollisionFence::')[1].split('SECTION "Johto Route 29 Display Name"')[0]
        self.assertNotIn('callba IsPlayerStandingOnWarp',fence)
        helper=read('engine/overworld/region_map_lookup.asm')
        self.assertIn('GetJohtoWarpArrivalStep::',helper)
        self.assertNotIn('db REGION_NATIVE_MAP_SLOT, JOHTO_UNION_CAVE_1F_LOCAL_ID, 3, 17, JOHTO_ROUTE_32, D_UP',helper)
        self.assertIn('db JOHTO_ROUTE_32, JOHTO_ROUTE_32_LOCAL_ID, 79, 6, REGION_NATIVE_MAP_SLOT, D_DOWN',helper)
        extra=read('home/overworld.asm').split('ExtraWarpCheck::')[1].split('MapEntryAfterBattle::')[0]
        self.assertNotIn('JohtoUnionCaveExitCheck',extra)
        self.assertIn('db JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID',helper)

    def test_native_arrival_step_preserves_legacy_doors(self):
        step=read('engine/overworld/npc_movement.asm').split('PlayerStepOutFromDoor:')[1].split('_EndNPCMovementScript:',1)[0]
        self.assertIn('callab GetJohtoWarpArrivalStep',step)
        self.assertRegex(step,r'ld a, e[\s\S]*jr nz, \.stepFromProfile[\s\S]*call IsPlayerStandingOnDoorTile')
        self.assertRegex(step,r'\.stepFromProfile[\s\S]*pop af[\s\S]*ld \[wSimulatedJoypadStatesEnd\], a')
        self.assertIn('ld a, D_DOWN',step)

    def test_rock_cannot_be_animated_water_is_tile_14(self):
        # Hardware-agnostic check of RPP's runtime hardcoded animation target.
        anim=read('home/vcopy.asm').split('UpdateMovingBgTiles::',1)[1].split('UpdateMovingBgTiles_flower:',1)[0]
        self.assertIn('vTileset + $14 * $10',anim)
        tiles=(ROOT/'gfx/blocksets/johto_union_cave.bst').read_bytes()
        pic=Image.open(ROOT/'gfx/tilesets/johto_union_cave.png').convert('RGB')
        # Gold water is tile 0x14, whose identical pixel art must now be at RPP 0x14.
        gold_tiles=Path(__import__('os').environ.get('JOHTO_GOLD_SOURCE',str(ROOT/'pokegold-master')))/'gfx/tilesets/cave.png'
        if not gold_tiles.is_file():
            self.skipTest('complete Gold cave tileset required for original pixel comparison')
        src=Image.open(gold_tiles).convert('RGB')
        def pixel_tile(img,idx):
            w=img.width//8; x=idx%w*8;y=idx//w*8
            return img.crop((x,y,x+8,y+8)).tobytes()
        self.assertEqual(pixel_tile(pic,0x14),pixel_tile(src,0x14))
        self.assertEqual(pixel_tile(pic,0x1c),pixel_tile(src,0x1c))
        self.assertGreater(tiles.count(0x14),0)
        self.assertGreater(tiles.count(0x1c),0)
        self.assertNotIn(0x14, (ROOT/'gfx/tilesets/johto_union_cave.tilecoll').read_bytes())


if __name__=='__main__': unittest.main()
