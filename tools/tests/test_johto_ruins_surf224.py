"""Gold-backed regression for the Surf behavior lost during the Ruins gate merge."""
import os
import shutil
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_surf_runtime_audit import audit
from johto_field_moves_preflight import audit as preflight

FILES = (
    'engine/overworld/johto_union_cave_surf.asm',
    'engine/overworld/field_moves.asm',
    'engine/items/items.asm',
    'engine/menu/start_sub_menus.asm',
    'home/overworld.asm',
    'tools/johto_native_maps.json',
    'constants/tilesets.asm',
    'engine/special_warps.asm',
    'main.asm',
    'maps/JohtoRoute32.blk', 'maps/JohtoRoute35.blk',
    'maps/JohtoRuinsOfAlphOutside.blk',
    'gfx/blocksets/johto.bst', 'gfx/tilesets/johto.tilecoll',
    'maps/JohtoUnionCave1F.blk',
    'gfx/blocksets/johto_union_cave.bst',
    'gfx/tilesets/johto_union_cave.tilecoll',
)

class RuinsSurf224(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ['JOHTO_GOLD_SOURCE'])
        assert (cls.gold/'maps/RuinsOfAlphOutside.blk').is_file()

    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for rel in FILES:
            dest = self.root/rel
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/rel,dest)

    def mutate(self, rel, old, new, expected):
        path = self.root/rel
        text = path.read_text()
        self.assertIn(old,text)
        path.write_text(text.replace(old,new,1))
        self.assertIn(expected, ' '.join(audit(self.root,self.gold)))

    def test_original_gold_water_all_48_cells(self):
        self.assertEqual(audit(self.root,self.gold), [])
        self.assertEqual(preflight(self.root,self.gold), [])

    def test_disabled_ruins_surf_dispatch_fails(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
            'jp z, IsJohtoRuinsWaterAhead', 'jp nz, IsJohtoRuinsWaterAhead',
            'Ruins Surf runtime missing/changed')

    def test_badge_gate_ruins_removed_fails(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
            'cp JOHTO_RUINS_OF_ALPH_LOCAL_ID\n\tjr nz, .kanto',
            'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjr nz, .kanto',
            'Ruins Surf runtime missing/changed')

    def test_ruins_water_upper_bound_fails(self):
        self.mutate('engine/overworld/johto_union_cave_surf.asm',
            'cp 14\n\tjr nc, .lower', 'cp 15\n\tjr nc, .lower',
            'Ruins Surf runtime missing/changed')

    def test_ruins_water_land_collision_fails(self):
        # Use a real water coordinate and flip its rendering ID into the
        # walkable list. No fake passable water may escape the geometry audit.
        p = self.root/'gfx/tilesets/johto.tilecoll'
        cur=p.read_bytes()
        data=(self.root/'maps/JohtoRuinsOfAlphOutside.blk').read_bytes()
        blocks=(self.root/'gfx/blocksets/johto.bst').read_bytes()
        y,x=6,2
        off=data[(y//2)*10+x//2]*16+(y%2*2)*4+(x%2*2)
        tile=blocks[off]
        self.assertNotIn(tile,cur[:-1])
        p.write_bytes(cur[:-1]+bytes([tile])+cur[-1:])
        self.assertIn('erroneously walkable on land',' '.join(audit(self.root,self.gold)))

    def test_ruins_metatile_out_of_range_fails(self):
        # Simulate the exact user-reported corruption: the map references
        # $8A but the merged JOHTO blockset stops at $89.
        p = self.root/'gfx/blocksets/johto.bst'
        cur = p.read_bytes()
        self.assertEqual(cur[0x8A*16:0x8B*16],
                         bytes.fromhex('3b0606063b0606063b0606064b4c214c'))
        p.write_bytes(cur[:-16])
        self.assertIn('Ruins metatile $8A out of range',
                      ' '.join(audit(self.root, self.gold)))

    def test_ruins_metatile_wrong_art_fails(self):
        p = self.root/'gfx/blocksets/johto.bst'
        cur = bytearray(p.read_bytes())
        cur[0x8A*16] ^= 1
        p.write_bytes(cur)
        self.assertIn('Ruins metatile $8A differs from reviewed backup branch',
                      ' '.join(audit(self.root, self.gold)))

    def test_ruins_surf_contract_cannot_be_deferred(self):
        self.mutate('tools/johto_native_maps.json',
            '"surf": "ALLOWED"', '"surf": "DEFERRED"',
            'Surf status must be ALLOWED')

if __name__=='__main__':unittest.main()
