"""Guard the existing map-change SFX selection and the exact cave patch baseline."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class UnionCaveSounds(unittest.TestCase):
    def test_use_existing_rpp_sfx_not_new_audio_samples(self):
        sound = (ROOT / 'home/overworld.asm').read_text().split('PlayMapChangeSound::', 1)[1].split('CheckIfInOutsideMap::', 1)[0]
        helper = (ROOT / 'engine/overworld/region_map_lookup.asm').read_text().split('GetJohtoCaveMapChangeSFX::', 1)[1]
        music = (ROOT / 'constants/music_constants.asm').read_text()
        self.assertIn('const SFX_GO_INSIDE', music)
        self.assertIn('const SFX_GO_OUTSIDE', music)
        self.assertRegex(helper, r'cp JOHTO_ROUTE_32[\s\S]*?cp REGION_NATIVE_MAP_SLOT[\s\S]*?cp JOHTO_UNION_CAVE_1F_LOCAL_ID[\s\S]*?ld e, SFX_GO_INSIDE')
        self.assertRegex(helper, r'\.checkExit[\s\S]*?cp REGION_NATIVE_MAP_SLOT[\s\S]*?cp JOHTO_ROUTE_32[\s\S]*?cp JOHTO_ROUTE_32_LOCAL_ID[\s\S]*?ld e, SFX_GO_OUTSIDE')
        self.assertIn('callab GetJohtoCaveMapChangeSFX', sound)
        self.assertIn('ld a, e', sound)
        self.assertIn('aCoord 8, 8', sound)
        self.assertIn('cp $0b', sound)
        self.assertRegex(sound, r'\.playSound\s+call PlaySound')

    def test_gold_cave_entry_and_immediate_return_not_regressed(self):
        obj = (ROOT/'data/mapObjects/JohtoRoute32.asm').read_text()
        self.assertRegex(obj, r'db 79, 6, 0, REGION_WARP_ESCAPE')
        movement = (ROOT/'engine/overworld/npc_movement.asm').read_text()
        self.assertIn('callab GetJohtoWarpArrivalStep', movement)
        self.assertIn('ld [wSimulatedJoypadStatesEnd], a', movement)
        self.assertNotIn('db REGION_NATIVE_MAP_SLOT, JOHTO_UNION_CAVE_1F_LOCAL_ID, 3, 17, JOHTO_ROUTE_32, D_UP', (ROOT / 'engine/overworld/region_map_lookup.asm').read_text())
        self.assertIn('JohtoRoute32CaveWarpTileCheck', (ROOT/'engine/overworld/player_state.asm').read_text())

    def test_water_animation_is_not_rock_animation(self):
        src=(ROOT/'home/vcopy.asm').read_text()
        self.assertIn('vTileset + $14 * $10', src)
        pal=(ROOT/'color/tilesets/johto_union_cave.asm').read_text()
        self.assertIn('WATER', pal)

if __name__ == '__main__':
    unittest.main()
