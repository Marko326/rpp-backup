"""Review-only South Johto candidate fixture tests. No ROM compilation."""
import json,shutil,sys,tempfile,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_south_geometry_preflight_268 import verify,VerificationError

ROOT=Path(__file__).resolve().parents[2]

class SouthCandidateGeometryTests(unittest.TestCase):
    def test_six_candidates_are_faithful_and_unregistered(self):
        self.assertEqual(verify(ROOT),{'candidates':6,'internal_warp_arcs':15,'runtime_registered':6})

    def test_source_and_masks_are_rejected_when_mutated(self):
        with tempfile.TemporaryDirectory() as td:
            temp=Path(td)
            shutil.copytree(ROOT/'docs/JOHTO_BATCH_SOUTH_268',temp/'docs/JOHTO_BATCH_SOUTH_268')
            shutil.copytree(ROOT/'maps/johto_pilot/candidates268',temp/'maps/johto_pilot/candidates268')
            (temp/'maps/johto_pilot').mkdir(parents=True,exist_ok=True)
            for name in ('AzaleaTown','IlexForestAzaleaGate','IlexForest','Route34IlexForestGate','Route34','GoldenrodCity'):
                shutil.copy2(ROOT/'maps/johto_pilot'/f'{name}.gold.blk',temp/'maps/johto_pilot'/f'{name}.gold.blk')
                shutil.copy2(ROOT/'maps/johto_pilot'/f'{name}.runtime.blk',temp/'maps/johto_pilot'/f'{name}.runtime.blk')
            # FIX-273: the approved compact gate runtime is a distinct file;
            # the original Gold .runtime.blk remains a separate oracle.
            for name in ('IlexForestAzaleaGate','Route34IlexForestGate'):
                shutil.copy2(ROOT/'maps/johto_pilot'/f'{name}.mature.blk', temp/'maps/johto_pilot'/f'{name}.mature.blk')
            (temp/'data').mkdir()
            shutil.copy2(ROOT/'data/johto_south_runtime.asm',temp/'data/johto_south_runtime.asm')
            (temp/'constants').mkdir();shutil.copy2(ROOT/'constants/region_map_constants.asm',temp/'constants/region_map_constants.asm')
            shutil.copy2(ROOT/'data/game_version.asm',temp/'data/game_version.asm')
            # The active version contract also tracks the post-.269 ROMX roof
            # wrapper, so mutation fixtures must carry that relevant source.
            (temp/'engine').mkdir()
            shutil.copy2(ROOT/'engine/johto_south_roofs_269.asm',temp/'engine/johto_south_roofs_269.asm')
            self.assertEqual(verify(temp)['candidates'],6)
            candidate=temp/'maps/johto_pilot/candidates268/AzaleaTown.candidate.blk'
            original=candidate.read_bytes();candidate.write_bytes(bytes([original[0]^1])+original[1:])
            with self.assertRaises(VerificationError):verify(temp)
            candidate.write_bytes(original)
            mask=temp/'maps/johto_pilot/candidates268/IlexForest.walk_mask_review.bin'
            original=mask.read_bytes();mask.write_bytes(original[:-1]+bytes([original[-1]^1]))
            with self.assertRaises(VerificationError):verify(temp)

    def test_unregistered_houses_never_approved(self):
        row=json.loads((ROOT/'maps/johto_pilot/candidates268/GoldenrodCity.gold_geometry_review.json').read_text())
        self.assertTrue(any(not x['planned_open'] for x in row['warps']))
        self.assertTrue(all(x['runtime_registered'] is False for x in row['warps']))

if __name__=='__main__':unittest.main()
