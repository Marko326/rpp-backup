"""P17: real Gold source, generic pipeline, native double-door fault injection."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
sys.path.insert(0,str(ROOT/'tools'))
from johto_ilex_gate_runtime_audit import audit_ilex_forest, FOREST_FILES
from johto_indoor_common import gold_warps, rpp_warps


class ForestRuntimeP17(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/IlexForest.asm').is_file():
            raise AssertionError('full original Gold source required for P17; no skips')

    def test_gold_resources_are_from_general_pipeline(self):
        # Rerun the existing general tool, compare its output to live assets.
        with TemporaryDirectory() as temp:
            root=Path(temp)
            run=subprocess.run([sys.executable,'tools/johto_rpp_pipeline.py',
                 '--project',str(ROOT),'--gold-root',str(GOLD),'--gold-map','IlexForest',
                 '--output',str(root)],cwd=ROOT,text=True,capture_output=True,timeout=120)
            self.assertEqual(run.returncode,0,run.stdout+'\n'+run.stderr)
            # The generic source stage stays byte-identical to Gold. Live
            # Forest blocks/graphics have ONLY native ledge-pair adaptations.
            from johto_rpp_ledge_converter import (build_forest_native_pairs,
                         clone_forest_tiles_and_palettes)
            from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
            from PIL import Image
            srcmap=(root/'preserved_gold_art_candidate/IlexForest.blk').read_bytes()
            srcblocks=(root/'preserved_gold_art_candidate/forest.bst').read_bytes()
            labels,_=collision_labels(GOLD,'forest',gold_resource_aliases(GOLD))
            rows=[tuple(x.strip() for x in row.split(',')) for row in labels]
            expected_map,expected_blocks,actions,variants=build_forest_native_pairs(
                srcmap,srcblocks,rows)
            self.assertEqual((ROOT/'maps/JohtoIlexForest.blk').read_bytes(),expected_map)
            self.assertEqual((ROOT/'gfx/blocksets/johto_ilex_forest.bst').read_bytes(),expected_blocks)
            self.assertEqual((len(actions),variants),(10,5))
            converted,expected_pal=clone_forest_tiles_and_palettes(
                GOLD/'gfx/tilesets/forest.png',GOLD/'gfx/tilesets/forest_palette_map.asm')
            with Image.open(ROOT/'gfx/tilesets/johto_ilex_forest.png') as img:
                self.assertEqual(img.convert('RGB').tobytes(),converted.convert('RGB').tobytes())
            self.assertEqual((ROOT/'color/tilesets/johto_ilex_forest.asm').read_text(),expected_pal)
            actual=bytearray((ROOT/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes())
            ref=bytearray((root/'gold_collision_mask.bin').read_bytes())
            self.assertEqual(len(ref),216)
            self.assertEqual(actual,ref,'Gold HOP takeoffs are enterable; solid cliff remains blocked')

    def test_tileset_32_header_and_palette_indices(self):
        # Calculated ROM table byte offsets for all registered tileset IDs.
        # 8-bit-only arithmetic aliases ID 32 to prior table entries.
        self.assertEqual(32*12, 0x180)
        self.assertEqual(32*8, 0x100)
        self.assertEqual(audit_ilex_forest(ROOT,GOLD), [])

    def test_negative_tileset_32_header_overflow_rejected(self):
        self.mutate('engine/overworld/tileset_header.asm',
           '\tadd hl, de ; id * 12\n\tld de, Tilesets',
           '\tadd hl, bc ; WRONG\n\tld de, Tilesets',
           'tileset 32 table offset must be 16-bit')

    def test_negative_tileset_32_palette_overflow_rejected(self):
        self.mutate('color/loadpalettes.asm',
           '\tld d,0\n\tld e,a\n\tsla e\n\trl d',
           '\tld d,0\n\tld e,a\n\tsla e\n\tnop',
           'tileset 32 palette offset must be 16-bit')

    def test_negative_forest_right_facing_return_rejected(self):
        # Warp object plus collision permission is not enough: ExtraWarpCheck
        # refuses an inner-map coordinate without this narrowly scoped rule.
        self.mutate('home/overworld.asm',
            'cp 42\n\tjr z, .forestReturns\n\tcp 43\n\tjr nz, .ordinaryCheck',
            'cp 42\n\tjr nz, .ordinaryCheck\n\tcp 43\n\tjr nz, .ordinaryCheck',
            'Forest x3/y42,43 right-facing ExtraWarpCheck')

    def test_bidirectional_double_warp_preserves_east(self):
        self.assertEqual(audit_ilex_forest(ROOT,GOLD),[])
        gate=rpp_warps(ROOT,'JohtoIlexAzaleaGate')
        forest=rpp_warps(ROOT,'JohtoIlexForest')
        self.assertEqual([(v['x'],v['y']) for v in gate],[(9,4),(9,5),(0,4),(0,5)])
        self.assertEqual([(v['x'],v['y']) for v in forest],[(3,42),(3,43)])
        self.assertEqual((len(gold_warps(GOLD,'IlexForest')),len(forest)),(3,2))

    def test_standing_has_no_autowarp(self):
        self.assertEqual(audit_ilex_forest(ROOT,GOLD),[])
        text=(ROOT/'home/overworld.asm').read_text()
        step=text.split('CheckWarpsNoCollisionLoop::',1)[1].split('CheckWarpsCollision::',1)[0]
        self.assertLess(step.index('call IsJohtoSouthGatePortal'),
                        step.index('callba IsPlayerStandingOnDoorTileOrWarpTile'))

    def mutate(self,rel,before,after,error):
        with TemporaryDirectory() as td:
            root=Path(td)
            for f in FOREST_FILES:
                dst=root/f;dst.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/f,dst)
            target=root/rel
            if isinstance(before,bytes):
                data=target.read_bytes();self.assertIn(before,data)
                target.write_bytes(data.replace(before,after,1))
            else:
                data=target.read_text();self.assertIn(before,data)
                target.write_text(data.replace(before,after,1))
            issues=audit_ilex_forest(root,GOLD)
            self.assertTrue(any(error in i for i in issues),issues)

    def test_negative_wrong_direction_rejected(self):
        self.mutate('home/overworld.asm',
           '.gateGoesWest\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_LEFT',
           '.gateGoesWest\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_RIGHT',
           'wrong-direction Warp')
        self.mutate('home/overworld.asm',
           '.gateReturnsEast\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_RIGHT',
           '.gateReturnsEast\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_LEFT',
           'wrong-direction Warp')

    def test_negative_auto_step_warp_rejected(self):
        self.mutate('home/overworld.asm',
           'call IsJohtoSouthGatePortal\n\tjr nc, .checkOrdinaryWarpTile',
           'and a\n\tjr nc, .checkOrdinaryWarpTile',
           'standing carpet must not instantly Warp')

    def test_negative_swapped_gate_warps_rejected(self):
        self.mutate('data/mapObjects/JohtoIlexAzaleaGate.asm',
                    'db 4, 0, 0, REGION_WARP_ESCAPE',
                    'db 4, 0, 1, REGION_WARP_ESCAPE',
                    'west/east two-lane gate Warp')

    def test_negative_wrong_forest_return_rejected(self):
        self.mutate('data/mapObjects/JohtoIlexForest.asm',
                    'db 42, 3, 2, REGION_WARP_ESCAPE',
                    'db 42, 3, 0, REGION_WARP_ESCAPE',
                    'south forest double return Warp')

    def test_negative_broken_native_return_rejected(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'JOHTO_ILEX_FOREST_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
                    'JOHTO_ILEX_FOREST_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
                    'native region warp graph')

    def test_negative_north_gate_unsealed_rejected(self):
        p=ROOT/'maps/JohtoIlexForest.blocked_mask.bin';raw=bytearray(p.read_bytes())
        pos=5*4+1//8;self.assertTrue(raw[pos]&2)
        corrupt=bytearray(raw);corrupt[pos]&=~2
        self.mutate('maps/JohtoIlexForest.blocked_mask.bin',bytes(raw),bytes(corrupt),
                    'Route34 north exit must remain blocked')

    def test_negative_original_gold_art_drift_rejected(self):
        p=ROOT/'gfx/blocksets/johto_ilex_forest.bst';raw=p.read_bytes()
        self.mutate('gfx/blocksets/johto_ilex_forest.bst',raw[:8],b'\0'*8,
                    'native Forest ledge block variants differ from Gold conversion')

    def test_negative_old_18_cell_mask_limit_rejected(self):
        self.mutate('engine/overworld/johto_route33_collision.asm',
                    'ld a, [wCurrentMapHeight2]\n\tcp b',
                    'ld a, 18\n\tcp b',
                    'shared mask must accept 54-cell height')

    def test_negative_ledge_takeoff_blocked_rejected(self):
        p=ROOT/'maps/JohtoIlexForest.blocked_mask.bin';raw=bytearray(p.read_bytes())
        x,y=22,2;pos=y*4+x//8;self.assertFalse(raw[pos]&(1<<(x%8)))
        corrupt=bytearray(raw);corrupt[pos]|=1<<(x%8)
        self.mutate('maps/JohtoIlexForest.blocked_mask.bin',bytes(raw),bytes(corrupt),
                    'Gold forest HOP takeoff cells must be enterable')

    def test_all_gold_hop_actions_have_legal_two_cell_landings(self):
        # Gold defines directions on the takeoff cell. The RPP controller
        # advances once on trigger, then once via one simulated press.
        from johto_gold_sources import gold_block_sources
        from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
        from johto_indoor_common import gold_dimensions
        aliases=gold_resource_aliases(GOLD)
        labels,_=collision_labels(GOLD,'forest',aliases)
        w,h=gold_dimensions(GOLD,'IlexForest')
        layout=(GOLD/gold_block_sources(GOLD)['IlexForest']).read_bytes()
        def role(x,y):
            if not (0<=x<2*w and 0<=y<2*h):
                return 'OUT_OF_BOUNDS'
            b=layout[(y//2)*w+x//2]
            return labels[b].split(',')[(y%2)*2+(x%2)].strip()
        hop_dirs={'HOP_LEFT':((-1,0),), 'HOP_DOWN':((0,1),),
                  'HOP_DOWN_LEFT':((0,1),(-1,0)),
                  'HOP_DOWN_RIGHT':((0,1),(1,0))}
        actual=[]
        for y in range(2*h):
            for x in range(2*w):
                r=role(x,y)
                if r not in hop_dirs:
                    continue
                for dx,dy in hop_dirs[r]:
                    actual.append((x,y,dx,dy))
                    self.assertEqual(role(x+dx,y+dy),'WALL', (x,y,dx,dy))
                    self.assertEqual(role(x+2*dx,y+2*dy),'FLOOR',(x,y,dx,dy))
        self.assertEqual(len(actual),10)
        # These seven third cells are precisely why the old universal
        # three-cell RPP leap is dangerous in this Gold forest.
        self.assertEqual(sum(role(x+3*dx,y+3*dy)=='HEADBUTT_TREE'
                             for x,y,dx,dy in actual),7)

    def test_gold_forest_only_leap_count_and_legacy_tables_kept(self):
        src=(ROOT/'engine/overworld/ledges.asm').read_text()
        original_end='ld [wSimulatedJoypadStatesIndex], a'
        forest_scope='cp JOHTO_ILEX_FOREST\n\tld a, $2\n\tjr nz, .hopCountReady\n\tdec a'
        self.assertIn(forest_scope,src)
        self.assertNotIn('.ilexHops',src)
        self.assertIn('JohtoIlexForestLedgeTiles:',src)
        self.assertIn('db SPRITE_FACING_RIGHT, $05,$42,D_RIGHT',src)
        home=(ROOT/'home/overworld.asm').read_text()
        self.assertIn('jr nz, .checkRunningButton',home)
        self.assertIn('bit 6, a\n\tjr nz, .notRunning',home)
        self.assertEqual(src.count(original_end),1)
        self.assertIn('db 9, 10, PLAYER_DIR_LEFT',src)
        self.assertIn('db 6, 6, PLAYER_DIR_DOWN',src)
        self.assertIn('db SPRITE_FACING_LEFT,  $05,$3B,D_LEFT',src)

    def test_negative_ledge_behind_wall_open_rejected(self):
        p=ROOT/'maps/JohtoIlexForest.blocked_mask.bin';raw=bytearray(p.read_bytes())
        x,y=24,3;pos=y*4+x//8;self.assertTrue(raw[pos]&(1<<(x%8)))
        corrupt=bytearray(raw);corrupt[pos]&=~(1<<(x%8))
        self.mutate('maps/JohtoIlexForest.blocked_mask.bin',bytes(raw),bytes(corrupt),
                    'Gold forest ledge wall must remain blocked')

    def test_negative_ledge_missing_corner_direction_rejected(self):
        self.mutate('engine/overworld/ledges.asm',
                    'db SPRITE_FACING_RIGHT, $05,$42,D_RIGHT',
                    'db SPRITE_FACING_RIGHT, $05,$41,D_RIGHT',
                    'native Forest ledge tile-pair trigger/facing/two-cell scope missing')

    def test_negative_native_barrier_tile_rejected(self):
        p=ROOT/'gfx/blocksets/johto_ilex_forest.bst';original=p.read_bytes()
        self.assertIn(bytes([0x40]),original)
        self.mutate('gfx/blocksets/johto_ilex_forest.bst',original,
                    original.replace(bytes([0x40]),bytes([0x2a]),1),
                    'native Forest ledge block variants differ from Gold conversion')

    def test_negative_running_during_jump_rejected(self):
        self.mutate('home/overworld.asm',
                    'bit 6, a\n\tjr nz, .notRunning',
                    'bit 6, a\n\tjr z, .notRunning',
                    'Forest hopping must not be accelerated by held B')

    def test_negative_ledge_wrong_jump_count_rejected(self):
        self.mutate('engine/overworld/ledges.asm',
                    'cp JOHTO_ILEX_FOREST\n\tld a, $2\n\tjr nz, .hopCountReady\n\tdec a',
                    'cp JOHTO_ILEX_FOREST\n\tld a, $2\n\tjr nz, .hopCountReady\n\tnop',
                    'native Forest ledge tile-pair trigger/facing/two-cell scope missing')


if __name__=='__main__':
    unittest.main()
