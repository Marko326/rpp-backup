"""SPID C-stage negative-injection tests for the shared sparse-ID contract.

Static source-level checks only: not a ROM build or emulator CPU verification.
"""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_fixed_id_audit import audit, check_active_slot_mapping, HEADERS, REGISTRY


class SparseActiveSlotContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.headers = (ROOT / HEADERS).read_text(encoding='utf-8')
        cls.registry = json.loads((ROOT / REGISTRY).read_text(encoding='utf-8'))['maps']

    def table_mutation(self, before, after, expected):
        self.assertIn(before, self.headers)
        mutated = self.headers.replace(before, after, 1)
        errors = audit(ROOT, {HEADERS: mutated})
        self.assertTrue(any(expected in e for e in errors), errors)

    def test_0_through_22_identity_unchanged(self):
        self.assertEqual([], check_active_slot_mapping(self.headers, self.registry))
        self.assertEqual(list(range(23)), [item['local_id'] for item in self.registry[:23]])
        self.assertEqual([23,24,62,63], [item['local_id'] for item in self.registry[23:]])

    def test_id_25_is_inactive_before_registered(self):
        self.table_mutation('$18, $ff, $ff', '$18, $19, $ff',
                            'active slot table mismatch at stable ID 25')

    def test_id_62_cannot_alias_slot_22(self):
        line = ' ; $30-$3f'
        source_line = next(x for x in self.headers.splitlines() if x.endswith(line))
        fields = source_line.split(';')[0].strip()[3:].split(', ')
        self.assertEqual('$19', fields[14])
        fields[14] = '$16'  # 62 decimal, a duplicate of slot 22
        self.table_mutation(source_line, 'db '+', '.join(fields)+line,
                            'active slot table mismatch at stable ID 62')

    def test_101_and_221_are_inactive_and_255_is_forbidden(self):
        for stable in (101, 221, 255):
            row = next(x for x in self.headers.splitlines()
                       if x.lstrip().startswith('db ') and
                       int(x.rsplit('$', 2)[-2].split('-',1)[0],16) <= stable <=
                       int(x.rsplit('$', 1)[-1], 16))
            # Guarded independently by the 256-entry count and exact registry image.
            self.assertEqual('$ff', row.split(';')[0].strip()[3:].split(', ')[stable % 16])

    def test_sparse_62_to_slot_25_without_dummy_maps(self):
        self.assertEqual([], check_active_slot_mapping(self.headers, self.registry))
        self.assertEqual(25, [m['local_id'] for m in self.registry].index(62))
        row = next(x for x in self.headers.splitlines() if x.endswith(' ; $30-$3f'))
        fields = row.split(';')[0].strip()[3:].split(', ')
        self.assertEqual(['$19','$1a'], fields[14:16])
        fields[14] = '$17'  # duplicate west slot 23 must fail
        corrupted = self.headers.replace(row,'	db '+', '.join(fields)+' ; $30-$3f')
        self.assertTrue(any('active slot table mismatch at stable ID 62' in e
                            for e in check_active_slot_mapping(corrupted,self.registry)))

    def test_duplicate_stable_id_is_detected(self):
        future = copy.deepcopy(self.registry)
        future.append({'local_id': 22})
        errors = check_active_slot_mapping(self.headers, future)
        self.assertTrue(any('duplicate stable ID 22' in e for e in errors), errors)

    def test_bad_id_is_detected(self):
        future = copy.deepcopy(self.registry)
        future.append({'local_id': 255})
        errors = check_active_slot_mapping(self.headers, future)
        self.assertTrue(any('invalid $ff stable ID' in e for e in errors), errors)

    def test_truncated_table_is_detected(self):
        self.table_mutation('$ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $f0-$ff',
                            '$ff ; $f0-$ff', 'requires exactly 256 bytes')

    def test_invalid_header_lookup_bypass_is_rejected(self):
        rel = 'engine/overworld/region_map_lookup.asm'
        src = (ROOT / rel).read_text()
        modified = src.replace('.johto\n\tcall GetJohtoActiveSlot',
                               '.johto\n\tnop', 1)
        self.assertNotEqual(src, modified)
        self.assertTrue(any('sparse runtime header missing' in e
                            for e in audit(ROOT, {rel: modified})))

    def test_16bit_music_and_town_offsets_are_mandatory(self):
        for rel, start, stop, expected in (
            (HEADERS, 'GetJohtoNativeMapSong::', 'ASSERT JohtoMapLegacyAliasesEnd',
             'sparse runtime RBY music missing'),
            ('engine/town_map.asm', 'LoadTownMapEntry:', 'GetMapNameForSaveScreen:',
             'sparse runtime Town Map name'),
        ):
            src = (ROOT / rel).read_text()
            i = src.index(start)
            j = src.index(stop, i)
            mid = src[i:j].replace('add hl, hl', 'add a', 1)
            self.assertNotEqual(src[i:j], mid)
            errors = audit(ROOT, {rel: src[:i]+mid+src[j:]})
            self.assertTrue(any(expected in e for e in errors), errors)

    def test_corrupt_save_and_invalid_warp_reset_must_stay(self):
        rel = 'engine/overworld/region_map_lookup.asm'
        src = (ROOT / rel).read_text()
        modified = src.replace('\tjp SoftReset', '	ld e, JOHTO_ROUTE_32', 1)
        self.assertTrue(any('sparse runtime native Continue missing' in e
                            for e in audit(ROOT, {rel: modified})))

    def test_legacy_last_map_sentinel_must_be_numeric_and_audited(self):
        # LAST_MAP is documented as an $ff sentinel, NOT an ASM EQU symbol.
        # A stray `ld a, LAST_MAP` passes old static reviews but breaks RGBASM.
        rel = 'engine/overworld/region_map_lookup.asm'
        src = (ROOT / rel).read_text()
        self.assertIn('ld a, $ff ; legacy LAST_MAP sentinel', src)
        malformed = src.replace('ld a, $ff ; legacy LAST_MAP sentinel',
                                'ld a, LAST_MAP', 1)
        self.assertNotEqual(malformed, src)
        errors = audit(ROOT, {rel: malformed})
        self.assertTrue(any('sparse runtime native Continue missing' in e
                            for e in errors), errors)

    def test_town_map_rom0_relocation_and_far_call_abi(self):
        # The user specifically protects ROM0; regression to ROM0 must fail
        # the actual project gate, not just a source-layout-only test.
        main = (ROOT / 'main.asm').read_text()
        self.assertIn('SECTION "Johto Town Map Common ROMX", ROMX, BANK[JOHTO_ROM_BANK]', main)
        broken = main.replace('SECTION "Johto Town Map Common ROMX", ROMX, BANK[JOHTO_ROM_BANK]',
                              'SECTION "Johto Town Map Common ROM0", ROM0', 1)
        errors = audit(ROOT, {'main.asm': broken})
        self.assertTrue(any('Town Map ROM0 protection' in error for error in errors), errors)

        town = (ROOT / 'engine/town_map.asm').read_text()
        self.assertEqual(3, town.count('call GetJohtoTownMapCurrentIndex'))
        broken = town.replace('callab GetJohtoTownMapCurrentIndexFar',
                              'call GetJohtoTownMapCurrentIndexFar', 1)
        errors = audit(ROOT, {'engine/town_map.asm': broken})
        self.assertTrue(any('ROMX far-call ABI' in error for error in errors), errors)

        home = (ROOT / 'home.asm').read_text()
        self.assertIn('callab TownMapSpriteBlinkingAnimation', home)
        errors = audit(ROOT, {'home.asm': home.replace(
            'callab TownMapSpriteBlinkingAnimation',
            'call TownMapSpriteBlinkingAnimation', 1)})
        self.assertTrue(any('ROM0 blinking caller' in error for error in errors), errors)

    def test_kanto_legacy_map_path_is_unchanged(self):
        src = (ROOT / 'engine/overworld/region_map_lookup.asm').read_text()
        block = src.split('ResolveRegionMapHeader::', 1)[1].split('\n.johto\n', 1)[0]
        self.assertIn('callab GetKantoMapHeaderPointer', block)
        self.assertIn('call GetKantoMapHeaderBank', block)
        self.assertEqual([], audit(ROOT))


if __name__ == '__main__':
    unittest.main()
