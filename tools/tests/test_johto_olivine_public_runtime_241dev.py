"""Source-contract tests for Olivine public interiors (not a compiled ROM proof)."""
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_olivine_public_runtime import ROOMS, build, sha256

ROOMS_GOLD = {
    'JohtoOlivinePokecenter1F': ('OlivinePokecenter1F', (3,4), 4),
    'JohtoOlivineCafe': ('OlivineCafe', (2,3), 2),
    'JohtoOlivineMart': ('OlivineMart', (2,3), 3),
}

class PublicBuildingRuntimeTests(unittest.TestCase):
    def source(self, rel):
        return (ROOT / rel).read_text(encoding='utf-8')

    def test_city_doors_gold_and_arrival_step(self):
        city = self.source('data/mapObjects/JohtoOlivineCity.asm')
        self.assertRegex(city, r'(?m)^\s*db \$06 ; three tested houses plus Pokecenter, Cafe, and Mart')
        lookup = self.source('engine/overworld/region_map_lookup.asm')
        gold = (ROOT / 'tools/olivine_public_candidates').resolve()
        mask = (ROOT / 'maps/JohtoOlivineCity.blocked_mask.bin').read_bytes()
        for x,y,index,label,gold_name,original_entry in (
            (13,21,3,'POKECENTER_1F','OLIVINE_POKECENTER_1F',1),
            (7,21,4,'CAFE','OLIVINE_CAFE',1),
            (19,17,5,'MART','OLIVINE_MART',2)):
            self.assertIn(f'db {y}, {x}, 0, REGION_WARP_ESCAPE',city)
            self.assertIn(f'db REGION_NATIVE_MAP_SLOT, JOHTO_OLIVINE_CITY_LOCAL_ID, {y}, {x}, REGION_NATIVE_MAP_SLOT, D_DOWN',lookup)
            self.assertRegex(lookup, rf'(?m)^\s*db JOHTO_OLIVINE_CITY_LOCAL_ID, {index}, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_{label}_LOCAL_ID')
            stride=5
            self.assertTrue(mask[y*stride+x//8] & (1 << (x%8)),f'exterior door must be solid at {(x,y)}')
            self.assertFalse(mask[(y+1)*stride+x//8] & (1 << (x%8)),f'step below door blocked {(x,y+1)}')
        self.assertEqual(self.source('constants/region_map_constants.asm').count('NUM_JOHTO_MAPS EQU 57'),1)

    def test_room_warps_gold_and_no_unsafe_stair(self):
        lookup = self.source('engine/overworld/region_map_lookup.asm')
        headers = self.source('data/johto_map_headers.asm')
        for room,(gold_name,(x1,x2),num_npcs) in ROOMS_GOLD.items():
            s=self.source('data/mapObjects/'+room+'.asm')
            self.assertIn('db $02 ; two outdoor exits',s)
            for i,x in enumerate((x1,x2)):
                self.assertIn(f'db 7, {x},',s)
            self.assertEqual(len(re.findall(r'(?m)^\s*object SPRITE_',s)),num_npcs)
            self.assertIn(f'dw {room}_h',headers)
        pc=self.source('data/mapObjects/JohtoOlivinePokecenter1F.asm')
        self.assertNotIn('db 7, 0,',pc)
        self.assertIn('JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID',lookup)
        mask=(ROOT/'maps/JohtoOlivinePokecenter1F.blocked_mask.bin').read_bytes()
        self.assertTrue(mask[7*2]&1,'Gold Pokecenter staircase must be blocked')

    def test_npc_and_passive_A_contract(self):
        guard=self.source('engine/overworld/johto_passive_house_npc.asm')
        self.assertIn('IsDeferredOlivineHouseNPC::', guard)
        for v in ('POKECENTER_1F','CAFE','MART'):
            self.assertIn('cp JOHTO_OLIVINE_'+v+'_LOCAL_ID',guard)
        self.assertIn('.publicNPC\n',guard)
        public=guard.split('.publicNPC\n',1)[1].split('.inHouse\n',1)[0]
        self.assertNotIn('GetTileAndCoordsInFrontOfPlayer',public,
                         'Moving NPCs must remain inert at their new coordinates')
        self.assertIn('scf\n\tret',public)
        for room in ROOMS_GOLD:
            s=self.source('data/mapObjects/'+room+'.asm')
            self.assertRegex(s,r'(?m)^\s*db \$00 ; no BG events')
        self.assertIn('Signs in Tim',guard)

    def test_public_collision_return_preserves_carry_and_handled_flag(self):
        source=self.source('engine/overworld/johto_route33_collision.asm')
        dispatch=source.split('JohtoNativeCanStepAhead::',1)[1]
        for label in ('.olivinePokecenter','.olivineCafe','.olivineMart'):
            segment=dispatch.split('\n'+label+'\n ld hl,',1)[1].split('\n.',1)[0]
            self.assertIn('call JohtoModernMaskedStep\n jp .handled',segment)
            self.assertNotIn('jp JohtoModernMaskedStep',segment)
        self.assertIn('.handled\n ld e, 1\n ret',dispatch)

    def test_gold_pc_red_palette_and_reinstall_template_stay_consistent(self):
        # A former installer fixture and the gate RGB audit used to restore
        # / require POKECENTER_TABLE even after the user's Gold-red correction.
        from johto_gate_rgb_audit import _sets
        rows = _sets(self.source('color/data/map_palette_sets.asm'))
        self.assertEqual(rows[37][1], 'INDOOR_RED')
        self.assertEqual(rows[37][2], 'JOHTO_GATE_GOLD_GREEN')
        self.assertEqual(rows[38][2], 'JOHTO_GATE_GOLD_GREEN')
        self.assertEqual(rows[38][5], 'JOHTO_GATE_GOLD_BROWN')
        self.assertEqual(rows[12][1], 'POKECENTER_TABLE')  # Kanto remains unchanged
        installer = self.source('tools/install_olivine_public_runtime.py')
        self.assertIn("s += '; JOHTO_OLIVINE_POKECENTER\\n\\tdb INDOOR_GRAY\\n\\tdb INDOOR_RED", installer)
        self.assertIn('db JOHTO_GATE_GOLD_GREEN', installer)
        self.assertIn('db JOHTO_GATE_GOLD_BROWN', installer)
        self.assertNotIn("s += '; JOHTO_OLIVINE_POKECENTER\\n\\tdb INDOOR_GRAY\\n\\tdb POKECENTER_TABLE", installer)

    def test_old_pc_red_palette_is_rejected_by_real_gate_rgb_checker(self):
        from johto_gate_rgb_audit import verify
        import os
        import shutil
        from tempfile import TemporaryDirectory
        gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
        if not gold.is_dir():
            self.skipTest('Gold source required for RGB source check')
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ('map_palette_sets.asm', 'map_palettes.asm', 'map_palette_constants.asm'):
                source = ROOT / 'color/data' / name
                target = root / 'color/data' / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, target)
            self.assertEqual(verify(root, gold), [])
            target = root / 'color/data/map_palette_sets.asm'
            text = target.read_text()
            prefix, suffix = text.split('; JOHTO_OLIVINE_POKECENTER', 1)
            self.assertIn('db INDOOR_RED', suffix)
            suffix = suffix.replace('db INDOOR_RED', 'db POKECENTER_TABLE', 1)
            target.write_text(prefix + '; JOHTO_OLIVINE_POKECENTER' + suffix)
            errors = verify(root, gold)
            self.assertTrue(any('tileset palette sets changed' in error for error in errors), errors)

    def test_generated_runtime_tiles_match_manifest(self):
        manifest=json.loads((ROOT/'tools/olivine_public_runtime_manifest.json').read_text())
        self.assertEqual(len(manifest['maps']),3)
        for entry in manifest['maps']:
            tileset=entry['tileset']
            for rel,data in [
                (f'gfx/tilesets/{tileset}.png','atlas'),
                (f'gfx/blocksets/{tileset}.bst','blockset'),
                (f'gfx/tilesets/{tileset}.tilecoll','tilecoll'),
                (f'color/tilesets/{tileset}.asm','palette')]:
                self.assertEqual(sha256((ROOT/rel).read_bytes()),entry['runtime_hashes'][data])
            self.assertLessEqual(len(entry['npc_walkable_foot_tile_ids']),96)
            self.assertFalse(set(entry['blocked_foot_tile_ids']) & set(entry['npc_walkable_foot_tile_ids']))

if __name__=='__main__': unittest.main()
