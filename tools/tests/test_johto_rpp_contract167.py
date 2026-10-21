"""MAP-5.62.167: fail-closed Gold collision and graphics mapping tests."""
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rpp_batch import audit_land_collisions
from johto_rpp_tileset_contract import (
    check_runtime_contract, expected_gold_prefix, matches_gold_prefix, tile_palettes,
)


class GoldJohtoConversionContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = bytearray((ROOT/'gfx/blocksets/johto.bst').read_bytes()[:2048])
        cls.gold[6*16:7*16] = bytes([7])*16
        cls.gold = bytes(cls.gold)

    def test_documented_base_transform_and_all_gfx_clones(self):
        b = check_runtime_contract(self.gold, ROOT)
        self.assertEqual(b[:2048], expected_gold_prefix(self.gold))
        self.assertTrue(matches_gold_prefix(self.gold, b))
        pals = tile_palettes(ROOT/'color/tilesets/johto.asm')
        for a, b in ((5, 0x20), (0x4c, 0x21), (6, 0x30), (7, 0x5b)):
            self.assertEqual(pals[a], pals[b], (a, b))
        self.assertEqual(len(re.findall(r'(?m)^\s*db\s+"[A-Z]+-5\.62\.\d+[A-Z]?@"',
                                        (ROOT/'data/game_version.asm').read_text())), 1)

    def test_other_gold_block_mismatch_is_not_silently_accepted(self):
        blocks = bytearray((ROOT/'gfx/blocksets/johto.bst').read_bytes())
        blocks[11] ^= 1
        self.assertFalse(matches_gold_prefix(self.gold, blocks))
        bad_gold = bytearray(self.gold)
        bad_gold[6*16] = 1
        with self.assertRaises(ValueError):
            expected_gold_prefix(bytes(bad_gold))

    def test_gold_walkable_ladder_not_silently_emitted_as_wall(self):
        # A 1x1 Gold metatile with 4 LADDER quadrants on block 06.
        labels = [['WALL'] * 4 for _ in range(128)]
        labels[6] = ['LADDER'] * 4
        block = bytes([6])
        good = (ROOT/'gfx/blocksets/johto.bst').read_bytes()
        whitelist = set((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
        self.assertEqual(audit_land_collisions(block,block,1,1,self.gold,good,labels,whitelist), [])
        wrong = bytearray(good)
        wrong[6*16:7*16] = bytes([7])*16
        issues = audit_land_collisions(block,block,1,1,self.gold,wrong,labels,whitelist)
        self.assertEqual(issues[0]['code'], 'missing_walkable_collision_mapping')
        self.assertEqual(issues[0]['count'], 4)

    def test_converted_variant_must_be_audited_not_its_source_block(self):
        labels = [['WALL'] * 4 for _ in range(128)]
        labels[6] = ['LADDER'] * 4
        original = bytes([6])
        installed = (ROOT/'gfx/blocksets/johto.bst').read_bytes()
        passable = set((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
        bad_variant_id = len(installed) // 16
        # Source is valid; a newly generated variant silently reuses wall $07.
        final_blocks = installed + bytes([7]) * 16
        self.assertEqual(audit_land_collisions(original, original, 1, 1,
                                               self.gold, final_blocks, labels, passable), [])
        found = audit_land_collisions(original, bytes([bad_variant_id]), 1, 1,
                                      self.gold, final_blocks, labels, passable)
        self.assertEqual(found[0]['code'], 'missing_walkable_collision_mapping')
        self.assertEqual(found[0]['count'], 4)

    def test_reject_invalid_final_candidate_indices(self):
        labels = [['LADDER'] * 4 for _ in range(128)]
        with self.assertRaisesRegex(ValueError, 'invalid staged geometry'):
            audit_land_collisions(b'\x06', b'\xff', 1, 1, self.gold,
                                  (ROOT/'gfx/blocksets/johto.bst').read_bytes(),
                                  labels, {0x5b})

    def test_palette_drift_rejected_before_staging(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            for relative in ('gfx/blocksets/johto.bst','gfx/tilesets/johto.png',
                             'gfx/tilesets/johto.tilecoll','color/tilesets/johto.asm'):
                dest=root/relative
                dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(ROOT/relative,dest)
            palette=root/'color/tilesets/johto.asm'
            rows=palette.read_text().splitlines(keepends=True)
            rows[6]=rows[6].replace('tilepal 0, GRAY,', 'tilepal 0, BROWN,', 1)
            palette.write_text(''.join(rows))
            with self.assertRaisesRegex(ValueError,'clone 30 differs in CGB palette'):
                check_runtime_contract(self.gold, root)
            palette.write_bytes((ROOT/'color/tilesets/johto.asm').read_bytes())
            land=root/'gfx/tilesets/johto.tilecoll'
            land.write_bytes(land.read_bytes().replace(bytes([0x5b]),b''))
            with self.assertRaisesRegex(ValueError,'LADDER not walkable'):
                check_runtime_contract(self.gold,root)

    def test_ambiguous_floor_is_review_not_broad_passability(self):
        labels = [['WALL'] * 4 for _ in range(128)]
        labels[5] = ['FLOOR'] * 4
        runtime = bytearray((ROOT/'gfx/blocksets/johto.bst').read_bytes())
        runtime[5*16:6*16] = bytes([0x3c])*16
        found = audit_land_collisions(bytes([5]),bytes([5]),1,1,self.gold,runtime,labels,{3,4,5,6,0x40,0x5b})
        self.assertEqual([i['code'] for i in found], ['floor_collision_requires_spatial_review'])

if __name__ == '__main__':
    unittest.main()
