import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from tileset_index_preflight_267 import inspect, audit

class TilesetIndexRegression(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.h=(ROOT/'engine/overworld/tileset_header.asm').read_text()
        cls.p=(ROOT/'color/loadpalettes.asm').read_text()

    def test_current_source(self):
        result=audit(ROOT)
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result)
        self.assertTrue(all(result['checks'].values()))

    def test_old_header_bug_is_rejected(self):
        old='''ld d, 0
    ld a, [wCurMapTileset]
    add a
    add a
    ld b, a
    add a
    add b
    jr nc, .noCarry
    inc d
.noCarry
    ld e, a
    ld hl, Tilesets
    add hl, de
    ld de, wTilesetBank'''
        self.assertEqual('FAIL', inspect('LoadTilesetHeader:\n'+old+'\n.copyTilesetHeaderLoop:',self.p)['status'])

    def test_palette_8_bit_wrap_is_rejected(self):
        old='''LoadTilesetPalette:
    ld a,b
    push af
    ld d,0
    ld e,a
    sla e
    sla e
    sla e
    ld hl, MapPaletteSets
    add hl,de
    ld d,h
    ld e,l
.nextPalette:'''
        self.assertEqual('FAIL',inspect(self.h,old)['status'])

    def test_dropped_high_byte_is_rejected(self):
        self.assertEqual('FAIL',inspect(self.h.replace('ld d, h\n\tld e, l','ld d, 0\n\tld e, l',1),self.p)['status'])
        self.assertEqual('FAIL',inspect(self.h,self.p.replace('ld h,0\n\tadd hl,hl','ld h,1\n\tadd hl,hl',1))['status'])

    def test_known_previous_overflow(self):
        def old(n):
            low=(n*8)&255
            four=(n*4)&255
            out=low+four
            return (out&255) + (256 if out>255 else 0)
        self.assertEqual(372,old(31))
        self.assertEqual(128,old(32))
        self.assertEqual(384,32*12)
        self.assertEqual(0,(32*8)&255)
        self.assertEqual(256,32*8)

if __name__=='__main__': unittest.main()
