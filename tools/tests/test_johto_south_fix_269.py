"""Mutation tests for the MAP-269 south field and roof regression fixes."""
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_south_fix_269_audit import audit
ROOT=Path(__file__).resolve().parents[2]

class South269(unittest.TestCase):
    def test_accepted_reference(self):
        self.assertEqual([],audit(ROOT))

    def test_bad_west_port_or_lost_jump_fails(self):
        with tempfile.TemporaryDirectory() as d:
            dest=Path(d)
            for rel in ('data/johto_route33_runtime.asm','engine/johto_pilot_runtime.asm',
                        'engine/overworld/ledges.asm','engine/overworld/cut.asm','engine/johto_south_geometry.asm',
                        'engine/johto_south_roofs_269.asm','home/overworld.asm','color/loadpalettes.asm',
                        'color/sprites.asm','color/data/map_palette_sets.asm','gfx/blocksets/johto_ilex_forest.bst',
                        'gfx/tilesets/johto_ilex_forest.png','gfx/tilesets/johto_new_bark_roofs.png',
                        'gfx/tilesets/johto_violet_roofs.png','gfx/tilesets/johto_azalea_roofs.png',
                        'gfx/tilesets/johto_goldenrod_roofs.png', 'maps/johto_pilot/IlexForest.gold.blk',
                        'maps/johto_pilot/IlexForest.runtime.blk'):
                (dest/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(ROOT/rel,dest/rel)
            p=dest/'data/johto_route33_runtime.asm'
            original=p.read_text()
            p.write_text(original.replace('cp 14\n    jp z, .seamAllowed','cp 14\n    ret z',1))
            self.assertTrue(any('seam' in x.lower() for x in audit(dest)))
            p.write_text(original)
            p=dest/'maps/johto_pilot/IlexForest.runtime.blk'
            data=bytearray(p.read_bytes());data[26]^=1;p.write_bytes(data)
            self.assertTrue(any('six accepted' in x for x in audit(dest)))

if __name__=='__main__':unittest.main()
