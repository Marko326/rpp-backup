"""MAP-5.62.168: real Gold negative tests for FINAL map/block artifacts."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0, str(ROOT / 'tools'))
import johto_rpp_batch as converter
from johto_rpp_validate import verify, gold_collision_labels, staged_walkability_errors


class FinalArtifactAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD / 'data/tilesets/johto_collision.asm').exists():
            raise unittest.SkipTest('Full Gold source required for final artifact regression')

    def test_bad_conversion_variant_blocks_route32_candidate(self):
        convert_real = converter.convert_one
        def inject_bad_variant(name, data, width, height, gold_blocks, labels, shared, intern):
            result = convert_real(name, data, width, height,
                                  gold_blocks, labels, shared, intern)
            if name != 'Route32' or result[0] is None:
                return result
            out, stage, hops, collisions, issues, triggers = result
            source_pos = data.index(6)  # Gold block $06 is four LADDER cells.
            new_blocks = bytearray(stage[0])
            new_id = len(new_blocks) // 16
            new_blocks.extend(bytes([7]) * 16)  # Gold wall art; impassable in RPP.
            bad_layout = bytearray(out)
            bad_layout[source_pos] = new_id
            return (bytes(bad_layout), (new_blocks, stage[1]),
                    hops, collisions, issues, triggers)
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(converter, 'convert_one', side_effect=inject_bad_variant):
                converter.batch(GOLD, ROOT, Path(tmp))
            rows = json.loads((Path(tmp) / 'manifest.json').read_text())['maps']
            route32 = next(row for row in rows if row['name'] == 'Route32')
            self.assertEqual(route32['status'], 'blocked')
            self.assertIn('missing_walkable_collision_mapping',
                          {issue['code'] for issue in route32['findings']})
            self.assertFalse((Path(tmp) / 'candidate_maps/Route32.blk').exists())

    def test_independent_validator_rejects_mutated_exported_route32(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)
            converter.batch(GOLD, ROOT, output)
            self.assertNotEqual(verify(output, GOLD, ROOT)['status'], 'FAILED')
            target = output / 'candidate_maps/Route32.blk'
            good = target.read_bytes()
            original = (GOLD / 'maps/Route32.blk').read_bytes()
            pos = original.index(6)
            shared = (output/'johto_blockset_candidate.bst').read_bytes()
            labels = gold_collision_labels(GOLD/'data/tilesets/johto_collision.asm')
            passable = set((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes()[:-1])
            # Choose a runtime block which contradicts Gold LADDER in this slot.
            bad_block = next(i for i in range(len(shared)//16) if
                staged_walkability_errors(bytes([6]), bytes([i]), 1, 1,
                                          labels, shared, passable))
            damaged = bytearray(good)
            damaged[pos] = bad_block
            target.write_bytes(damaged)
            validation = verify(output, GOLD, ROOT)
            self.assertEqual(validation['status'], 'FAILED')
            route32 = next(row for row in validation['maps'] if row['name']=='Route32')
            self.assertIn('candidate_walkability_regression',
                          {item['code'] for item in route32['issues']})
            target.write_bytes(good)
            self.assertNotEqual(verify(output, GOLD, ROOT)['status'], 'FAILED')


if __name__ == '__main__':
    unittest.main()
