"""Regression tests for the out-of-map filler, not just the interior art."""
import hashlib
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

TOOLS = Path(__file__).resolve().parents[1]
RPP = TOOLS.parent
sys.path.insert(0, str(TOOLS))
from johto_indoor_border_adapter import build, _preview
from johto_indoor_common import ConversionError

SOURCE_FILES = (
    'gfx/tilesets/johto_gate.png',
    'gfx/blocksets/johto_gate.bst',
    'maps/JohtoRoute31VioletGate.blk',
    'data/mapObjects/JohtoRoute31VioletGate.asm',
    'gfx/tilesets/gate.tilecoll',
    'color/tilesets/johto_gate.asm',
)


class BorderAdapterTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.rpp = Path(self.tmp.name)/'rpp'
        for rel in SOURCE_FILES:
            dest = self.rpp/rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(RPP/rel, dest)
        # A function-patched checkout already has a black border. Recreate the
        # original .159 regression as a fixture, so this test remains useful
        # after the script and gameplay patches have both been applied.
        obj=self.rpp/'data/mapObjects/JohtoRoute31VioletGate.asm'
        if 'db $0d' in obj.read_text():
            import re
            obj.write_text(re.sub(r'(?m)^(\s*db \$)0d[^\n]*',
                                  r'\g<1>0a ; legacy RPP border',obj.read_text(),count=1))
            bst=self.rpp/'gfx/blocksets/johto_gate.bst'
            bst.write_bytes(bst.read_bytes()[:13*16])
            atlasfile=self.rpp/'gfx/tilesets/johto_gate.png'
            with Image.open(atlasfile) as img: atlas=img.convert('RGB')
            atlas.paste((255,255,255),((21%16)*8,(21//16)*8,(21%16+1)*8,(21//16+1)*8))
            atlas.save(atlasfile)
        self.out = Path(self.tmp.name)/'separate_output'

    def test_dedicated_solid_black_impassable_border_preserves_interior(self):
        inputs={rel:hashlib.sha256((self.rpp/rel).read_bytes()).hexdigest()
                for rel in SOURCE_FILES}
        report=build(self.rpp,self.out)
        self.assertEqual(report['original_border_metatile'],10)
        self.assertEqual(report['new_border_metatile'],13)
        # Slot availability depends on the verified Gold palette mapping.
        # Do not pin the former gray-tagged slot 21 after a palette correction.
        from johto_indoor_border_adapter import _load_palette_entries
        palette = _load_palette_entries(self.rpp/'color/tilesets/johto_gate.asm')
        used=set((self.rpp/'gfx/blocksets/johto_gate.bst').read_bytes())
        walkable=set((self.rpp/'gfx/tilesets/gate.tilecoll').read_bytes()[:-1])
        expected=min(i for i in range(96)
                     if i not in used and i not in walkable and palette[i]=='GRAY')
        self.assertEqual(report['new_black_tile_slot'],expected)
        self.assertTrue(report['interior_pixel_identical'])
        self.assertTrue(report['border_all_black'])
        self.assertTrue(report['non_walkable'])
        self.assertFalse(report['gameplay_tested'])
        self.assertFalse(report['generated_2bpp'])
        self.assertFalse((self.out/'gfx/tilesets/johto_gate.2bpp').exists())
        self.assertEqual(len((self.out/'gfx/blocksets/johto_gate.bst').read_bytes()),14*16)
        self.assertIn('db $0d', (self.out/'data/mapObjects/JohtoRoute31VioletGate.asm').read_text())
        self.assertEqual(inputs,{rel:hashlib.sha256((self.rpp/rel).read_bytes()).hexdigest()
                                 for rel in SOURCE_FILES})
        png=Image.open(self.out/'preview_including_border.png').convert('RGB')
        self.assertEqual(png.size, (224,192))
        for x,y in ((0,0),(16,48),(210,50),(16,190),(200,190)):
            self.assertEqual(png.getpixel((x,y)),(0,0,0))

    def test_unrelated_map_block_and_warp_data_not_modified(self):
        a=build(self.rpp,self.out)
        self.assertEqual((self.rpp/'maps/JohtoRoute31VioletGate.blk').read_bytes(),
                         (RPP/'maps/JohtoRoute31VioletGate.blk').read_bytes())
        self.assertEqual((self.out/'data/mapObjects/JohtoRoute31VioletGate.asm').read_text().count('JOHTO_VIOLET_CITY'),2)
        self.assertEqual((self.out/'data/mapObjects/JohtoRoute31VioletGate.asm').read_text().count('JOHTO_ROUTE_31'),2)

    def test_missing_blocked_unused_gray_tile_refuses_to_overwrite_tiles(self):
        p=self.rpp/'color/tilesets/johto_gate.asm'
        p.write_text(p.read_text().replace('GRAY','RED'))
        with self.assertRaisesRegex(ConversionError,'没有空闲'):
            build(self.rpp,self.out)

    def test_broken_collision_terminator_refused(self):
        p=self.rpp/'gfx/tilesets/gate.tilecoll'
        p.write_bytes(p.read_bytes()[:-1])
        with self.assertRaisesRegex(ConversionError,'终止符'):
            build(self.rpp,self.out)

    def test_bad_map_border_reference_refused(self):
        p=self.rpp/'data/mapObjects/JohtoRoute31VioletGate.asm'
        p.write_text(p.read_text().replace('db $0a','db $ff',1))
        with self.assertRaisesRegex(ConversionError,'外围 ID'):
            build(self.rpp,self.out)

    def test_non_lossless_png_refused(self):
        p=self.rpp/'gfx/tilesets/johto_gate.png'
        with Image.open(p) as img: rgba=img.convert('RGB')
        rgba.putpixel((0,0),(123,123,123))
        rgba.save(p)
        with self.assertRaisesRegex(ConversionError,'四色灰度'):
            build(self.rpp,self.out)

    def test_output_must_not_touch_rpp_or_reuse_directory(self):
        with self.assertRaisesRegex(ConversionError,'源码外'):
            build(self.rpp,self.rpp/'preview')
        self.out.mkdir()
        (self.out/'keep').write_text('keep')
        with self.assertRaisesRegex(ConversionError,'为空'):
            build(self.rpp,self.out)

    def test_same_input_generates_identical_assets_and_report(self):
        first=build(self.rpp,self.out)
        second_out=Path(self.tmp.name)/'output_two'
        second=build(self.rpp,second_out)
        self.assertEqual(first, second)
        for item in first['generated_source_paths']:
            self.assertEqual((self.out/item).read_bytes(),(second_out/item).read_bytes())
        self.assertEqual((self.out/'preview_including_border.png').read_bytes(),
                         (second_out/'preview_including_border.png').read_bytes())


if __name__=='__main__': unittest.main()
