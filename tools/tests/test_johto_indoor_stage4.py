"""TOOLS.004: source-traced tileset capacity, palette, and lossless isolated art."""
import json
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
import sys
import unittest
import os
from PIL import Image

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE', str(ROOT / 'pokegold-master')))
sys.path.insert(0,str(TOOLS))

from johto_indoor_common import ConversionError
from johto_indoor_palette_vram_audit import (inspect, loader_window, parse_tilepals)
from johto_indoor_tiles_converter import (build_mapping, strict_2bpp,
                                          stage_dedicated_gold_tileset)
from johto_indoor_resource_budget import inspect as budget_inspect
from johto_indoor_pipeline import pipeline
from johto_indoor_manifest import verify_manifest


class PaletteAndEncoderUnitTests(unittest.TestCase):
    def test_valid_palette_line(self):
        self.assertEqual(parse_tilepals('tilepal 0, GRAY, GRAY, RED, RED, RED, ROOF, ROOF, BROWN ; note'),
                         ['GRAY','GRAY','RED','RED','RED','ROOF','ROOF','BROWN'])

    def test_palette_bad_row_rejected(self):
        for row in ('tilepal 0, GRAY, RED', 'tilepal 1, GRAY, GRAY, GRAY, GRAY, GRAY, GRAY, GRAY, GRAY',
                    'db $12', 'tilepal 0, GRAY, GRAY, RED, RED, BAD-ENTRY, RED, ROOF, ROOF'):
            with self.subTest(row=row), self.assertRaises(ConversionError):
                parse_tilepals(row)

    def test_missing_loader_evidence_rejected(self):
        with self.assertRaises(ConversionError):
            loader_window('LoadTilesetTilePatternData::\n ld bc,$600\n ret\nNextRoutine:\n')

    def test_source_window_parse(self):
        raw='LoadTilesetTilePatternData::\n ld de,vTileset\n ld bc,$600\n call FarCopyData2\n ret\nNextRoutine:\n'
        self.assertEqual(loader_window(raw)['fixed_copy_8x8_slots'],96)

    def test_fixed_2bpp_is_roundtrip_verified_and_padded(self):
        image=Image.new('L',(8,8))
        for y in range(8):
            for x in range(8): image.putpixel((x,y),(255,170,85,0)[x%4])
        data=strict_2bpp(image,4)
        self.assertEqual(len(data),64)
        self.assertEqual(data[:2],bytes([0x55,0x33]))
        self.assertEqual(data[16:],bytes(48))

    def test_reject_extra_or_non_gray_tiles(self):
        image=Image.new('L',(16,8),255)
        with self.assertRaises(ConversionError): strict_2bpp(image,1)
        image.putpixel((0,0),128)
        with self.assertRaises(ConversionError): strict_2bpp(image,2)


@unittest.skipUnless(GOLD.is_dir(), 'Gold source tree required')
class RealSourceStage4Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.art,_=build_mapping(ROOT,GOLD)
        cls.budget=budget_inspect(ROOT,GOLD,cls.art)

    def test_source_trace_and_restrictions(self):
        res=inspect(ROOT,GOLD,self.art,self.budget)
        self.assertEqual(res['source_trace']['graphics_label'],'Gate_GFX')
        self.assertEqual(res['loader']['fixed_copy_bytes'],1536)
        self.assertEqual(res['loader']['fixed_copy_8x8_slots'],96)
        self.assertEqual(res['existing_palette']['source_entries'],96)
        self.assertEqual(res['candidate']['compact_candidate_tile_ids'],22)
        self.assertTrue(res['candidate']['pixel_cells_fit_fixed_copy_window'])
        self.assertFalse(res['import_allowed'])
        self.assertFalse(res['existing_palette']['gold_to_rpp_color_parity_proven'])

    def test_missing_palette_include_is_fatal(self):
        from johto_indoor_palette_vram_audit import read as original_read
        def fake_read(base, name):
            data=original_read(base,name)
            if name == 'color/data/map_palette_assignments.asm':
                return data.replace('INCLUDE "color/tilesets/gate.asm"','; missing include')
            return data
        with patch('johto_indoor_palette_vram_audit.read',side_effect=fake_read):
            with self.assertRaises(ConversionError): inspect(ROOT,GOLD,self.art,self.budget)

    def test_wrong_graphics_symbol_is_fatal(self):
        from johto_indoor_palette_vram_audit import read as original_read
        def fake_read(base,name):
            data=original_read(base,name)
            if name=='main.asm': return data.replace('Gate_GFX:', 'Missing_Gate_GFX:')
            return data
        with patch('johto_indoor_palette_vram_audit.read', side_effect=fake_read):
            with self.assertRaises(ConversionError): inspect(ROOT,GOLD,self.art,self.budget)

    def test_exceeding_slot_window_is_detected(self):
        larger=dict(self.budget)
        larger['gold']=dict(self.budget['gold'],distinct_tile_ids_referenced=97)
        result=inspect(ROOT,GOLD,self.art,larger)
        self.assertFalse(result['candidate']['pixel_cells_fit_fixed_copy_window'])
        self.assertIn('CANDIDATE_TILE_IDS_EXCEED_FIXED_COPY_WINDOW',result['warnings'])

    def test_isolated_candidate_compacts_tile_ids_and_source_pixels(self):
        with TemporaryDirectory() as folder:
            base=Path(folder)
            report=stage_dedicated_gold_tileset(GOLD,base)
            self.assertEqual(report['used_compacted_blocks'],13)
            self.assertEqual(report['compacted_tile_ids'],22)
            self.assertEqual(report['fixed_2bpp_bytes'],1536)
            blocks=(base/report['blockset']).read_bytes()
            self.assertEqual(len(blocks),14*16)
            self.assertEqual(report['reserved_black_border_block_id'],13)
            self.assertEqual(report['reserved_black_border_tile_id'],22)
            self.assertEqual(blocks[13*16:], bytes([22]*16))
            self.assertTrue(all(t<22 for t in blocks[:13*16]))
            self.assertTrue((base/report['fixed_2bpp']).is_file())
            original=Image.open(GOLD/'gfx/tilesets/gate.png').convert('RGBA')
            compact=Image.open(base/report['atlas']).convert('RGBA')
            for new_id,old_id in enumerate(report['source_tile_ids']):
                src=(old_id%16*8, old_id//16*8)
                dst=(new_id%8*8, new_id//8*8)
                self.assertEqual(original.crop((*src,src[0]+8,src[1]+8)).tobytes(),
                                 compact.crop((*dst,dst[0]+8,dst[1]+8)).tobytes())

    def test_pipeline_manifest_tracks_new_audit_and_graphics(self):
        with TemporaryDirectory() as folder:
            out=Path(folder)/'audit'
            summary=pipeline(ROOT,GOLD,out)
            self.assertFalse(summary['import_allowed'])
            self.assertIn('PALETTE_VRAM_UNVERIFIED',summary['blockers'])
            report=json.loads((out/'09_palette_vram.json').read_text())
            self.assertEqual(report['loader']['fixed_copy_8x8_slots'],96)
            manifest=json.loads((out/'07_source_manifest.json').read_text())
            self.assertIn('tools/johto_indoor_palette_vram_audit.py',manifest['sources']['rpp'])
            self.assertIn('color/data/map_palette_assignments.asm',manifest['sources']['rpp'])
            self.assertIn('09_palette_vram.json',manifest['generated_files'])
            self.assertTrue(verify_manifest(ROOT,GOLD,out)['valid'])
            (out/'isolated_gold_art_candidate/gate.fixed96.2bpp').write_bytes(b'bad')
            self.assertFalse(verify_manifest(ROOT,GOLD,out)['valid'])


if __name__=='__main__': unittest.main()
