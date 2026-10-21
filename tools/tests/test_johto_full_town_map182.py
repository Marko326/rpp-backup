"""Gold 45-landmark Town Map browser and RGBDS scoped-label regressions."""
import os
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil
import sys
import re
import unittest
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_town_map_bike_audit import audit

RPP_FILES = ('engine/town_map.asm','data/town_map_entries.asm',
             'data/bike_riding_tilesets.asm','data/mapHeaders/JohtoUnionCave1F.asm',
             'home/overworld.asm','tools/johto_native_maps.json',
             'gfx/tilemaps/johto_map.kmp')
GOLD_FILES = ('data/maps/landmarks.asm','engine/events/overworld.asm',
              'gfx/pokegear/johto.bin')

def find_duplicate_asm_labels(source):
    """Find duplicate global or scoped local RGBDS labels in one include file.

    RGBDS local labels such as `.showPage2` belong to the preceding global
    label, and they may be declared without a trailing colon. Checking only
    `label:` misses this exact historical assembler failure.
    """
    current_global = None
    seen = {}
    duplicates = []
    for line_no, line in enumerate(source.splitlines(), 1):
        code = line.split(';', 1)[0].strip()
        global_match = re.fullmatch(r'([A-Za-z_][\w#]*):{1,2}', code)
        local_match = re.fullmatch(r'(\.[A-Za-z_][\w#]*)(?::{1,2})?', code)
        if global_match:
            current_global = global_match.group(1)
            name = current_global
        elif local_match:
            name = f'{current_global}{local_match.group(1)}'
        else:
            continue
        if name in seen:
            duplicates.append((name, seen[name], line_no))
        seen[name] = line_no
    return duplicates


class JohtoFullTownMap182(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        value = os.environ.get('JOHTO_GOLD_SOURCE')
        if not value:
            raise RuntimeError('Gold required for Gold Town Map tests')
        cls.gold = Path(value)
        if not all((cls.gold / r).is_file() for r in GOLD_FILES):
            raise RuntimeError('incomplete Gold directory')

    def test_all_45_gold_landmarks_in_original_order(self):
        self.assertEqual(audit(ROOT,self.gold),[])
        text=(ROOT/'engine/town_map.asm').read_text()
        self.assertIn('DEF NUM_JOHTO_TOWNMAP_ENTRIES EQU 45',text)
        self.assertIn('db 0, 1, 2, 3, 4, 5, 5, 7, 9', (ROOT/'engine/overworld/johto_town_map_helpers.asm').read_text())

    def test_a_different_unsupported_gold_landmark_cannot_move(self):
        with TemporaryDirectory() as tmp:
            rpp=Path(tmp)/'rpp'
            for rel in RPP_FILES:
                dest=rpp/rel
                dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(ROOT/rel,dest)
            path=rpp/'engine/town_map.asm'
            src=path.read_text()
            original='db 140,  90 ; Route33Name'
            self.assertIn(original,src)
            path.write_text(src.replace(original,'db 140,  91 ; Route33Name',1))
            issues=audit(rpp,self.gold)
            self.assertTrue(any('Gold=' in x and 'Route33' in x for x in issues),issues)

    def test_options_scoped_labels_unique_and_mutation_is_caught(self):
        for rel in ('engine/menu/options_menu.asm', 'engine/town_map.asm',
                    'crysaudio/engine.asm', 'crysaudio/rbsfx.asm',
                    'home/init.asm', 'main.asm', 'wram.asm'):
            self.assertEqual(find_duplicate_asm_labels((ROOT / rel).read_text()), [], rel)
        text = (ROOT / 'engine/menu/options_menu.asm').read_text()
        self.assertEqual(len(re.findall(r'(?m)^\.showPage2$', text)), 1)
        # Regression: .182 shipped a redundant `jp .loop` stub under the
        # same local label. The scanner must reject the exact old mistake.
        old = '.showPage2\n\tld a,1'
        self.assertIn(old, text)
        broken = text.replace(old, '.showPage2\n\tjp .loop\n\n' + old, 1)
        duplicates = find_duplicate_asm_labels(broken)
        self.assertTrue(any(name == 'DisplayOptionMenu.showPage2'
                            for name, _, _ in duplicates), duplicates)


if __name__=='__main__':
    unittest.main()
