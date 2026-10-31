"""FIX-275 regression and mutation checks for old NPC-243 ILEX/GATE reuse."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_mature_reuse_275_audit import audit
ROOT=Path(__file__).resolve().parents[2]
PATHS=(
  'maps/johto_pilot/IlexForest.mature_blocked_mask.bin',
  'color/tilesets/johto_ilex_forest.asm',
  'engine/johto_ilex_mature_runtime_275.asm',
  'constants/region_map_constants.asm',
  'engine/johto_south_geometry.asm',
  'engine/johto_violet_field_skills.asm',
  'home/overworld.asm',
  'main.asm',
)

class MatureReuse275(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        for rel in PATHS:
            p=self.root/rel;p.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT/rel,p)
    def mutate(self, rel,old,new,part):
        p=self.root/rel;s=p.read_text();self.assertIn(old,s)
        p.write_text(s.replace(old,new,1))
        self.assertTrue(any(part in x for x in audit(self.root)), audit(self.root))
    def test_original_exact_source_and_interfaces(self):
        self.assertEqual([],audit(self.root))
    def test_width_names_resolve_for_forest_and_west_border(self):
        self.mutate('engine/johto_ilex_mature_runtime_275.asm',
                    'JOHTO_SOUTH_ILEXFOREST_WIDTH',
                    'JOHTO_ILEX_FOREST_WIDTH', 'undefined mature runtime width')
        # Set up a new isolated fixture for independent west-border validation.
        p=self.root/'engine/johto_ilex_mature_runtime_275.asm'
        p.write_text((ROOT/'engine/johto_ilex_mature_runtime_275.asm').read_text().replace(
            'JOHTO_SOUTH_AZALEATOWN_WIDTH','JOHTO_AZALEA_TOWN_WIDTH',1))
        self.assertTrue(any('undefined mature runtime width' in x for x in audit(self.root)))

    def test_cut_cp_carry_must_clear_on_uncut_0f(self):
        self.mutate('engine/johto_south_geometry.asm',
                    'cp $2d\n    jr z, .cutCleared\n    and a',
                    'cp $2d\n    ret nz\n    and a','uncut $0F')
    def test_surf_requires_gold_safe_land_not_empty_tilecoll(self):
        self.mutate('engine/johto_violet_field_skills.asm',
                    'callab JohtoSouthGoldShoreProbe',
                    'callab JohtoSouthGoldWaterProbe','Surf can enter')
    def test_border_hook_must_be_after_map_buffer_load(self):
        self.mutate('home/overworld.asm',
                    'callab PatchJohtoSouthBordersAfterBlockLoad',
                    'callab JohtoSouthRoofOnConnection','Azalea outdoor west')
    def test_mature_palette_cannot_be_replaced_with_new_guess(self):
        self.mutate('color/tilesets/johto_ilex_forest.asm',
                    'tilepal 0, GRAY, BROWN, BROWN, RED, YELLOW',
                    'tilepal 0, GRAY, BROWN, BROWN, RED, GREEN','palette drift')
    def test_mature_block_mask_drift_fails(self):
        p=self.root/'maps/johto_pilot/IlexForest.mature_blocked_mask.bin'
        b=bytearray(p.read_bytes());b[0]^=1;p.write_bytes(b)
        self.assertTrue(any('216-byte' in x for x in audit(self.root)))

if __name__=='__main__':unittest.main()
