"""Exact Gold house contract and targeted mutation rejection; not ROM proof."""
from pathlib import Path
from tempfile import TemporaryDirectory
import hashlib
import re
import shutil
import sys
import unittest
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_olivine_house_runtime_audit import audit
from johto_indoor_tiles_converter import strict_2bpp

# At test time Gold is supplied by the project's original-source test environment.
import os
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',str(ROOT / 'pokegold-master')))

RPP_PATHS = (
    'constants/johto_fixed_map_ids.asm',
    'data/mapObjects/JohtoOlivineCity.asm',
    'data/mapObjects/JohtoOlivinePunishmentSpeechHouse.asm',
    'engine/overworld/region_map_lookup.asm',
    'engine/overworld/johto_route33_collision.asm',
    'maps/JohtoOlivinePunishmentSpeechHouse.blocked_mask.bin',
    'maps/JohtoOlivinePunishmentSpeechHouse.blk',
    'gfx/blocksets/johto_house.bst',
    'gfx/tilesets/johto_house.png',
    'Makefile',
    'home/overworld.asm', 'main.asm', 'scripts/JohtoOlivinePunishmentSpeechHouse.asm',
)

class OlivineHouse240DEV(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise AssertionError('Gold original source is required; no skipped acceptance checks')

    def test_original_gold_source_and_runtime_contract(self):
        self.assertEqual(audit(ROOT,GOLD),[])

    def test_house_png_is_the_reproducible_fixed_96_slot_source(self):
        png=ROOT/'gfx/tilesets/johto_house.png'
        with Image.open(png) as image:
            self.assertEqual(image.mode,'L')
            self.assertEqual(image.size,(64,96))
            self.assertLessEqual(set(image.tobytes()),{0,85,170,255})
            encoded=strict_2bpp(image,96)
        self.assertEqual(len(encoded),1536)
        self.assertEqual(hashlib.sha256(encoded).hexdigest(),
                         '141ed8ac9fc3b774aca51d426212239e9175b1dc4aede9e491f331d97538b1a9')
        built=ROOT/'gfx/tilesets/johto_house.2bpp'
        if built.exists():
            self.assertEqual(encoded,built.read_bytes())
        rules=(ROOT/'Makefile').read_text()
        self.assertRegex(rules,r'(?m)^gfx/tilesets/johto_house\.2bpp: gfx/tilesets/johto_house\.png\n\t\$\(RGBGFX\) -o \$@ \$<\n\t@test .*1536')

    def test_all_direct_2bpp_and_1bpp_references_have_png_sources(self):
        pattern=re.compile(r'INCBIN\s+["\']([^"\']+\.(?:2bpp|1bpp))["\']')
        refs=[]
        missing=[]
        source_files=[*ROOT.rglob('*.asm'), *ROOT.rglob('*.inc')]
        for source in source_files:
            if 'RPP_PROJECT_CONTEXT' in source.parts:
                continue
            try: text=source.read_text()
            except UnicodeDecodeError: continue
            for asset in pattern.findall(text):
                refs.append((source,asset))
                png=ROOT/(asset.rsplit('.',1)[0]+'.png')
                if not png.is_file(): missing.append(f'{source.relative_to(ROOT)} -> {asset} (missing {png.relative_to(ROOT)})')
        self.assertGreaterEqual(len(refs),250,'graphics-source scan unexpectedly covered too few assembly references')
        self.assertEqual(missing,[],'direct graphics includes must have tracked PNG sources: '+ '; '.join(missing))

    def mutate(self,path,old,new,error):
        with TemporaryDirectory() as folder:
            copy=Path(folder)
            for rel in RPP_PATHS:
                dest=copy/rel;dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,dest)
            f=copy/path
            src=f.read_text();self.assertIn(old,src)
            f.write_text(src.replace(old,new,1))
            self.assertTrue(any(error in msg for msg in audit(copy,GOLD)),error)

    def test_development_plan_exists_and_is_linked(self):
        plan = ROOT/'docs/JOHTO_INDOOR_HOUSE_PLAN_240_DEV.md'
        self.assertTrue(plan.is_file(), 'the original ZIP did not contain this DEV plan: package it as a new file')
        self.assertIn('OlivinePunishmentSpeechHouse', plan.read_text())
        self.assertIn('docs/JOHTO_INDOOR_HOUSE_PLAN_240_DEV.md',
                      (ROOT/'tools/JOHTO_INDOOR_TOOLCHAIN_zh.md').read_text())

    def test_city_outdoor_warp_must_not_move(self):
        self.mutate('data/mapObjects/JohtoOlivineCity.asm',
                    'db 11, 29, 0, REGION_WARP_ESCAPE',
                    'db 11, 28, 0, REGION_WARP_ESCAPE',
                    'city door (29,11)')

    def test_house_reverse_warp_and_sibling_exit_protected(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'db JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID',
                    'db JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_CITY_LOCAL_ID',
                    'native Warp resolver')

    def test_house_selector_short_jump_cannot_overflow(self):
        # The first naive insertion adds eight bytes into the selector and
        # pushes two pre-existing ROM0 JR instructions past signed +127.
        self.mutate('home/overworld.asm',
            '\tcp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\n\tjr c, .maybeHouse',
            '\tcp JOHTO_OLIVINE_CITY_LOCAL_ID\n\tjr z, .yes\n'
            '\tcp JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID\n\tjr z, .yes\n'
            '\tcp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID\n\tjr c, .notGate',
            'ROM0 portal JR out of range')

    def test_north_gate_short_jump_cannot_overflow(self):
        self.mutate('engine/overworld/johto_route33_collision.asm',
            'jp z, .mahoganyNorthDoor ; sparse house check lengthened this route past JR +127',
            'jr z, .mahoganyNorthDoor',
            'JR out of range')

    def test_outside_exact_step_on_fence_protected(self):
        self.mutate('engine/overworld/johto_route33_collision.asm',
                    'cp 12\n jp z, .clear\n.westConnection',
                    'cp 13\n jp z, .clear\n.westConnection',
                    'EXACT step-on')

    def test_house_double_exit_no_air_wall(self):
        with TemporaryDirectory() as folder:
            copy=Path(folder)
            for rel in RPP_PATHS:
                dest=copy/rel;dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,dest)
            p=copy/'maps/JohtoOlivinePunishmentSpeechHouse.blocked_mask.bin'
            m=bytearray(p.read_bytes());m[7] |= (1<<2);p.write_bytes(m)
            self.assertTrue(any('walkable' in e for e in audit(copy,GOLD)))

    def test_gold_room_script_cannot_silently_change(self):
        with TemporaryDirectory() as folder:
            fake=Path(folder)/'maps';fake.mkdir(parents=True)
            for name in ('OlivineCity.asm','OlivinePunishmentSpeechHouse.asm'):
                shutil.copyfile(GOLD/'maps'/name,fake/name)
            p=fake/'OlivinePunishmentSpeechHouse.asm'
            s=p.read_text();self.assertIn('warp_event  3,  7, OLIVINE_CITY, 5',s)
            p.write_text(s.replace('warp_event  3,  7, OLIVINE_CITY, 5','warp_event  3,  7, OLIVINE_CITY, 4',1))
            self.assertTrue(any('Gold original house exit' in e for e in audit(ROOT,fake.parent)))

if __name__=='__main__':unittest.main()
