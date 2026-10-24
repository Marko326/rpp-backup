"""Regression for Gold Olivine Tim/Good Rod passive NPC, not a ROM test."""
import os
from pathlib import Path
import sys
import tempfile
import unittest
from shutil import copytree

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',ROOT/'pokegold-master'))
sys.path.insert(0,str(ROOT/'tools'))
from johto_olivine_passive_npc_audit import audit

class PassiveNPC241DEV(unittest.TestCase):
    def test_original_gold_parity_and_safe_a(self):
        self.assertEqual(audit(ROOT,GOLD),[])

    def test_negative_mutations(self):
        with tempfile.TemporaryDirectory() as d:
            dir=Path(d)
            for name in ('data/mapObjects/JohtoOlivineTimsHouse.asm',
                         'engine/overworld/johto_passive_house_npc.asm',
                         'color/sprites.asm'):
                dest=dir/name; dest.parent.mkdir(parents=True,exist_ok=True)
                dest.write_text((ROOT/name).read_text())
            # Audit is fail-closed for a missing module: use full required files via symlinks
            for name in ('data/mapObjects/JohtoOlivineGoodRodHouse.asm',
                        'constants/sprite_constants.asm','data/sprite_sets.asm',
                        'main.asm','engine/overworld/map_sprites.asm',
                        'home/overworld.asm','gfx/sprites/johto_fishing_guru.png'):
                path=dir/name;path.parent.mkdir(parents=True,exist_ok=True)
                path.symlink_to(ROOT/name)
            for file,before,after in (
                ('data/mapObjects/JohtoOlivineTimsHouse.asm', '2, 3, STAY, NONE','3, 3, STAY, NONE'),
                ('engine/overworld/johto_passive_house_npc.asm','cp 3\n','cp 4\n'),
                ('color/sprites.asm','db PAL_OW_GREEN\n\n\nAnimationTileset1Palettes:', 'db PAL_OW_RED\n\n\nAnimationTileset1Palettes:'),
            ):
                p=dir/file;original=(ROOT/file).read_text();self.assertIn(before,original)
                p.write_text(original.replace(before,after,1))
                self.assertTrue(audit(dir,GOLD), f'{file} mutation passed')
                p.write_text(original)

if __name__=='__main__': unittest.main()
