"""REF-310 park-gate background palette source-accuracy and failure injection."""
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gate_palette_audit_310 import audit

GOLD=os.getenv('JOHTO_GOLD_SOURCE') or os.getenv('GOLD_SOURCE_ROOT')

class GatePalette310(unittest.TestCase):
    def test_all_ten_active_gatehouses_share_gold_colors_not_geometry(self):
        r=audit(ROOT, GOLD)
        self.assertEqual('PASS_STATIC_ONLY',r['status'],r['errors'])
        self.assertEqual([104,105],r['park_gate_ids'])
        self.assertFalse(r['rom_built'])
        self.assertFalse(r['device_verified'])

    def test_park_palette_faults_are_rejected(self):
        palette=ROOT/'color/data/map_palette_sets.asm'
        with tempfile.TemporaryDirectory() as tmp:
            path=Path(tmp); (path/'color/data').mkdir(parents=True)
            (path/'tools').mkdir()
            (path/'data').mkdir()
            (path/'color/tilesets').mkdir(parents=True)
            # audit needs a handful of real read-only sources; others are symlinks.
            for f in ['tools/johto_gatehouse_profiles_303.json','data/johto_pilot_runtime_assets.asm',
                      'data/tileset_headers.asm','color/data/map_palettes.asm',
                      'color/tilesets/johto_park_gate.asm','color/tilesets/johto_gate.asm']:
                dst=path/f; dst.parent.mkdir(parents=True,exist_ok=True)
                dst.symlink_to(ROOT/f)
            original=palette.read_text()
            (path/'color/data/map_palette_sets.asm').write_text(original)
            cases={
                'generic_park_green':('db INDOOR_GRAY, INDOOR_RED, JOHTO_GATE_GOLD_GREEN, INDOOR_BLUE\n    db INDOOR_YELLOW, JOHTO_GATE_GOLD_BROWN, INDOOR_LIGHT_BLUE, CRYS_TEXTBOX ; Park Gates',
                                      'db INDOOR_GRAY, INDOOR_RED, INDOOR_GREEN, INDOOR_BLUE\n    db INDOOR_YELLOW, JOHTO_GATE_GOLD_BROWN, INDOOR_LIGHT_BLUE, CRYS_TEXTBOX ; Park Gates'),
                'generic_park_brown':('db INDOOR_YELLOW, JOHTO_GATE_GOLD_BROWN, INDOOR_LIGHT_BLUE, CRYS_TEXTBOX ; Park Gates',
                                      'db INDOOR_YELLOW, INDOOR_BROWN, INDOOR_LIGHT_BLUE, CRYS_TEXTBOX ; Park Gates'),
            }
            # Comment is intentionally part of the original line; tests only modify Park Gates row.
            for name,(old,new) in cases.items():
                text=original
                if old not in text and name=='generic_park_green':
                    old=old.replace('; Park Gates','; Park Gates: exact Gold indoor GREEN/BROWN')
                    new=new.replace('; Park Gates','; Park Gates: exact Gold indoor GREEN/BROWN')
                if old not in text and name=='generic_park_brown':
                    old=old.replace('; Park Gates','; Park Gates: exact Gold indoor GREEN/BROWN')
                    new=new.replace('; Park Gates','; Park Gates: exact Gold indoor GREEN/BROWN')
                self.assertIn(old,text)
                (path/'color/data/map_palette_sets.asm').write_text(text.replace(old,new))
                with self.subTest(name=name):
                    r=audit(path,None)
                    self.assertEqual('FAIL',r['status'])
                    self.assertTrue(any('both_gate_tilesets' in e for e in r['errors']),r['errors'])

    @unittest.skipUnless(GOLD,'Gold reference not provided')
    def test_compare_all_gold_tile_tags_and_rgb(self):
        self.assertEqual('PASS_STATIC_ONLY',audit(ROOT,GOLD)['status'])

if __name__=='__main__':
    unittest.main()
