"""VIOLET-247: map-local Cut/Surf/HOP source and runtime contract."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

class VioletFieldContract(unittest.TestCase):
    def test_gold_counts_and_coordinates(self):
        # Checked against bundled Gold VioletCity.blk and johto_collision.asm.
        asm = (ROOT/'engine/johto_violet_field_skills.asm').read_text()
        water = asm.split('JohtoVioletGoldWaterCells::',1)[1].split('JohtoVioletGoldWaterCellsEnd::',1)[0]
        cells = [(int(y), int(x)) for y,x in re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+)\s*$', water)]
        self.assertEqual(140,len(cells))
        self.assertEqual(140,len(set(cells)))
        self.assertTrue(all(0<=y<36 and 0<=x<40 for y,x in cells))
        self.assertIn('(x=36,y=19)',asm)
        self.assertIn('cp $63',asm)
        self.assertIn('cp JOHTO_VIOLET_CITY_LOCAL_ID',asm)

    def test_maps_scoped_and_not_global_whitelist(self):
        asm=(ROOT/'engine/johto_violet_field_skills.asm').read_text()
        for token in ('JOHTO_RUNTIME_MAP_HANDLE','MAP_REGION_JOHTO',
                      'JOHTO_VIOLET_CITY_LOCAL_ID','wCurMapWidth'):
            self.assertIn(token,asm)
        ledge=(ROOT/'engine/overworld/ledges.asm').read_text()
        self.assertRegex(ledge,r'cp JOHTO_VIOLET_CITY_LOCAL_ID\s+jr z, \.supportedJohtoLedges')
        self.assertIn('db SPRITE_FACING_DOWN,  $06,$21,D_DOWN',ledge)

    def test_all_surf_and_cut_routes_connected(self):
        for path, tokens in {
            'engine/overworld/field_moves.asm': ('callab JohtoVioletWaterAhead','callab JohtoVioletCutTreeAhead'),
            'engine/items/items.asm': ('callab JohtoVioletWaterAhead',),
            'home/overworld.asm': ('callab JohtoVioletWaterAhead',),
            'engine/overworld/cut.asm': ('callab JohtoVioletCutTreeAhead','db $63, $8D')
        }.items():
            contents=(ROOT/path).read_text()
            for token in tokens:self.assertIn(token,contents)

    def test_live_block_clone_only_replaces_cut_quadrant(self):
        asm=(ROOT/'data/johto_pilot_runtime_assets.asm').read_text()
        self.assertIn('JohtoPilotVioletCutClearedBlock::',asm)
        part=asm.split('JohtoPilotVioletCutClearedBlock::',1)[1].split('JohtoPilot_BlockEnd::',1)[0]
        raw=re.findall(r'\$([0-9a-fA-F]{2})',part)
        self.assertEqual(16,len(raw))
        old=(ROOT/'gfx/blocksets/johto.bst').read_bytes()[0x63*16:(0x63+1)*16]
        new=bytes(int(x,16) for x in raw)
        self.assertEqual(old[:8],new[:8])
        self.assertEqual(old[10:12],new[10:12])
        self.assertEqual(old[14:16],new[14:16])
        self.assertEqual(new[8:10],b'\x05\x05')
        self.assertEqual(new[12:14],b'\x05\x05')
        self.assertEqual(141,len((ROOT/'gfx/blocksets/johto.bst').read_bytes())//16)

    def test_water_is_not_walkable_without_surf(self):
        # Source Gold collision cells must remain distinct from the RPP
        # 8x8 whitelist, otherwise the player could walk into the river.
        import os
        gold=os.environ.get('GOLD_SOURCE_ROOT')
        if not gold:self.skipTest('Gold reference root not set')
        src=Path(gold)
        pattern=re.compile(r'tilecoll\s+(.+?)\s*;\s*([0-9a-fA-F]+)')
        roles={int(m.group(2),16):m.group(1).replace(' ','').split(',')
               for line in (src/'data/tilesets/johto_collision.asm').read_text().splitlines()
               if (m:=pattern.search(line))}
        gold_blocks=(src/'maps/VioletCity.blk').read_bytes()
        runtime_blocks=(ROOT/'maps/johto_pilot/VioletCity.runtime.blk').read_bytes()
        rpp_tiles=(ROOT/'gfx/blocksets/johto.bst').read_bytes()
        allowed=set((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes()) - {0xff}
        self.assertEqual(len(gold_blocks),len(runtime_blocks))
        count=0
        for old,new in zip(gold_blocks,runtime_blocks):
            mb=rpp_tiles[new*16:new*16+16]
            for quadrant,role in enumerate(roles[old]):
                if role!='WATER':continue
                count+=1
                row=quadrant//2*2
                col=quadrant%2*2
                ids={mb[(row+dy)*4+col+dx] for dx in range(2) for dy in range(2)}
                self.assertFalse(ids & allowed, (hex(old),hex(new),ids&allowed))
        self.assertEqual(140,count)

    def test_cut_swap_cannot_capture_kanto_cut_tiles(self):
        # The shared historical CutTreeBlockSwaps table is invoked only for
        # a cuttable Kanto tile; Kanto block $63 has no $3d/$52 target.
        base=(ROOT/'gfx/blocksets/overworld.bst').read_bytes()
        metatile=base[0x63*16:0x64*16]
        self.assertEqual(16,len(metatile))
        self.assertTrue(set(metatile).isdisjoint({0x3d,0x52}))

    def test_original_gold_tree_count(self):
        # Optional strict Gold source comparison when reference is provided.
        import os
        raw=os.environ.get('GOLD_SOURCE_ROOT')
        if not raw:self.skipTest('Gold reference root not set')
        source=Path(raw)
        tiles=(source/'data/tilesets/johto_collision.asm').read_text()
        pattern=re.compile(r'tilecoll\s+(.+?)\s*;\s*([0-9a-fA-F]+)')
        coll={int(m.group(2),16):m.group(1).replace(' ','').split(',')
              for line in tiles.splitlines() if (m:=pattern.search(line))}
        data=(source/'maps/VioletCity.blk').read_bytes()
        self.assertEqual(360,len(data))
        locations={name:set() for name in ('WATER','CUT_TREE','HOP_DOWN')}
        for idx,bid in enumerate(data):
            for k,name in enumerate(coll[bid]):
                if name in locations:locations[name].add(((idx//20)*2+k//2,(idx%20)*2+k%2))
        self.assertEqual([140,1,3],[len(locations[n]) for n in locations])
        listed=(ROOT/'engine/johto_violet_field_skills.asm').read_text().split('JohtoVioletGoldWaterCells::',1)[1].split('JohtoVioletGoldWaterCellsEnd::',1)[0]
        runtime={(int(y),int(x)) for y,x in re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+)\s*$',listed)}
        self.assertEqual(runtime,locations['WATER'])
        self.assertEqual({(19,36)},locations['CUT_TREE'])
        self.assertEqual({(22,26),(22,28),(22,29)},locations['HOP_DOWN'])

if __name__=='__main__':unittest.main()
