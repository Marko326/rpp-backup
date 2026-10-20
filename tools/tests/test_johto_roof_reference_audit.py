"""Gold-derived roof gate including mutations for missing future map enrollment."""
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',ROOT/'pokegold-master'))
sys.path.insert(0,str(ROOT/'tools'))
from johto_roof_reference_audit import audit

REQUIRED=(
    'tools/johto_native_maps.json',
    'color/loadpalettes.asm',
    'engine/overworld/johto_goldenrod_roof_gfx.asm',
    'home/overworld.asm',
    'Makefile',
    'main.asm',
    'gfx/tilesets/johto.png',
    'gfx/tilesets/johto_modern.png',
    'gfx/tilesets/johto_azalea_roofs.png',
    'gfx/tilesets/johto_violet_roofs.png',
    'gfx/tilesets/johto_goldenrod_roofs.png',
)

class RoofGoldReferenceGate(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path=Path(self.tmp.name)
        for relative in REQUIRED:
            target=self.path/relative
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/relative,target)
        for src in (ROOT/'data/mapHeaders').glob('*.asm'):
            dest=self.path/'data/mapHeaders'/src.name
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(src,dest)

    def assert_rejected(self, text):
        errors=audit(self.path,GOLD)
        self.assertTrue(any(text in e for e in errors),errors)

    def test_gold_registry_roofs_and_runtime_tables_match(self):
        self.assertEqual(audit(self.path,GOLD),[])

    def test_route34_going_green_again_is_rejected(self):
        path=self.path/'engine/overworld/johto_goldenrod_roof_gfx.asm'
        src=path.read_text()
        self.assertIn('db 4 ; 0e Route34',src)
        path.write_text(src.replace('db 4 ; 0e Route34','db 0 ; 0e Route34'))
        self.assert_rejected('graphics roof local-ID table')

    def test_one_wrong_original_roof_rgb_is_rejected(self):
        path=self.path/'color/loadpalettes.asm'
        src=path.read_text()
        self.assertIn('RGB 25,25,00',src)
        path.write_text(src.replace('RGB 25,25,00','RGB 20,31,14'))
        self.assert_rejected('Gold roof RGB5')

    def test_corrupted_original_roof_tiles_are_rejected(self):
        from PIL import Image
        path=self.path/'gfx/tilesets/johto_violet_roofs.png'
        with Image.open(path) as source:
            image=source.copy()
        px=image.getpixel((13, 7))
        image.putpixel((13, 7), (px+85) % 256)
        image.save(path)
        self.assert_rejected('violet rooftop PNG')

    def test_missing_png_source_is_rejected(self):
        (self.path/'gfx/tilesets/johto_azalea_roofs.png').unlink()
        self.assert_rejected('azalea rooftop PNG')

    def test_missing_generation_rule_is_rejected(self):
        path=self.path/'Makefile'
        path.write_text(path.read_text().replace(
            'gfx/tilesets/johto_%_roofs.2bpp: gfx/tilesets/johto_%_roofs.png',
            'gfx/tilesets/johto_%_roofs.2bpp: gfx/tilesets/johto_%_roofs.jpeg'))
        self.assert_rejected('roof PNG-to-2bpp Makefile rule')

    def test_new_outdoor_map_without_a_roof_group_fails_closed(self):
        path=self.path/'tools/johto_native_maps.json'
        contents=json.loads(path.read_text())
        row=dict(contents['maps'][-1])
        row['local_id']=len(contents['maps'])
        row['header']='JohtoRoute35_h'
        contents['maps'].append(row)
        path.write_text(json.dumps(contents))
        hdr=self.path/'data/mapHeaders/JohtoRoute35.asm'
        hdr.write_text('JohtoRoute35_h:\n\tdb JOHTO_MODERN\n')
        self.assert_rejected('roof local-ID table')

    def mutate_selector(self, old, new):
        path=self.path/'engine/overworld/johto_goldenrod_roof_gfx.asm'
        src=path.read_text()
        self.assertEqual(src.count(old),1,old)
        path.write_text(src.replace(old,new))
        self.assert_rejected('roof runtime selector source/BANK/group dispatch mismatch')

    def test_swapping_violet_and_azalea_roof_sources_is_rejected(self):
        # Both labels still exist and both PNGs match Gold, but the displayed
        # art would be wrong. This regression was missed by the old gate.
        path=self.path/'engine/overworld/johto_goldenrod_roof_gfx.asm'
        src=path.read_text()
        violet='ld hl,JohtoVioletRoofs_GFX'
        azalea='ld hl,JohtoAzaleaRoofs_GFX'
        self.assertEqual(src.count(violet),1)
        self.assertEqual(src.count(azalea),1)
        path.write_text(src.replace(violet,'ld hl,__TEMP_ROOF__')
                            .replace(azalea,violet)
                            .replace('ld hl,__TEMP_ROOF__',azalea))
        self.assert_rejected('roof runtime selector source/BANK/group dispatch mismatch')

    def test_wrong_roof_source_bank_is_rejected(self):
        self.mutate_selector('ld a,BANK(JohtoVioletRoofs_GFX)',
                             'ld a,BANK(JohtoAzaleaRoofs_GFX)')

    def test_wrong_group_dispatch_branch_is_rejected(self):
        self.mutate_selector('cp 5', 'cp 4')

    def test_wrong_base_roof_tile_offset_is_rejected(self):
        self.mutate_selector('ld hl,NewBark_GFX + $0a * $10',
                             'ld hl,NewBark_GFX + $0b * $10')

    def test_selector_comments_and_whitespace_do_not_change_contract(self):
        path=self.path/'engine/overworld/johto_goldenrod_roof_gfx.asm'
        src=path.read_text()
        self.assertIn('ld hl,JohtoVioletRoofs_GFX',src)
        path.write_text(src.replace('ld hl,JohtoVioletRoofs_GFX',
                                    'ld   hl, JohtoVioletRoofs_GFX ; Gold art'))
        self.assertEqual(audit(self.path,GOLD),[])

    def test_missing_connection_hook_is_rejected(self):
        path=self.path/'home/overworld.asm'
        src=path.read_text()
        self.assertIn('callba PatchGoldenrodRoofOnConnection',src)
        path.write_text(src.replace('callba PatchGoldenrodRoofOnConnection','nop'))
        self.assert_rejected('roof full-load or connection hook')

if __name__=='__main__':
    unittest.main()
