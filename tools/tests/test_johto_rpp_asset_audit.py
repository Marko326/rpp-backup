"""P1-3 artifact tests. All source data is synthetic; no real ROM required."""
import csv
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_rpp_asset_audit import (AuditError, audit, emit, gfx_signatures,
                                   load_png_tiles, main, safe_output, blocks_for,
                                   collision_labels, gold_resource_aliases)

try:
    from PIL import Image
except ImportError:
    Image = None


def tile(kind, fg):
    out = Image.new('RGBA', (8, 8), (0, 0, 0, 255))
    pix = out.load()
    for y in range(8):
        for x in range(8):
            on = {'vert': x % 2 == 0, 'horizontal': y % 2 == 0,
                  'checker': (x + y) % 2 == 0, 'diag': x == y,
                  'cross': x in (3, 4) or y in (3, 4)}[kind]
            if on:
                pix[x, y] = (*fg, 255)
    return out


def atlas(path, defs):
    path.parent.mkdir(parents=True, exist_ok=True)
    img = Image.new('RGBA', (16, 16))
    for i, (kind, fg) in enumerate(defs):
        img.paste(tile(kind, fg), ((i % 2)*8, (i // 2)*8))
    img.save(path)


def fixture(root):
    gold = root/'gold'
    project = root/'rpp'
    for d in [gold/'data/maps', gold/'constants', gold/'maps', gold/'data/tilesets',
              gold/'gfx/tilesets', project/'gfx/blocksets', project/'gfx/tilesets',
              project/'color/tilesets']:
        d.mkdir(parents=True, exist_ok=True)
    (gold/'data/maps/maps.asm').write_text('''\
map CherrygroveCity, TILESET_JOHTO, TOWN, LANDMARK
map Route30, TILESET_JOHTO, ROUTE, LANDMARK
''')
    (gold/'constants/map_constants.asm').write_text('''\
map_const CHERRYGROVE_CITY, 2, 2
map_const ROUTE_30, 2, 2
''')
    (gold/'data/maps/blocks.asm').write_text('''\
CherrygroveCity_Blocks:
Route30_Blocks:
 INCBIN "maps/Common.blk"
''')
    (gold/'maps/Common.blk').write_bytes(bytes([0, 1, 2, 3]))
    (gold/'data/tilesets/johto_metatiles.bin').write_bytes(
        b''.join(bytes([i]*16) for i in range(4)))
    (gold/'data/tilesets/johto_collision.asm').write_text(
        'tilecoll FLOOR, FLOOR, FLOOR, FLOOR\n'*4)
    atlas(gold/'gfx/tilesets/johto.png', [
        ('vert', (255,255,255)), ('horizontal', (255,255,255)),
        ('checker', (255,255,255)), ('diag', (255,255,255))])
    # RPP outdoor: same 32px artwork for Gold block #1, despite different IDs.
    # RPP block with bytes [1] has only *pattern* for Gold block #2.
    # RPP block with bytes [3] matches only the raw tile indexes of Gold #3.
    (project/'gfx/blocksets/outdoor.bst').write_bytes(
        bytes([2]*16) + bytes([1]*16) + bytes([3]*16))
    atlas(project/'gfx/tilesets/outdoor.png', [
        ('cross', (255,255,255)), ('checker', (255,0,0)),
        ('horizontal', (255,255,255)), ('cross', (255,255,255))])
    return gold, project


@unittest.skipIf(Image is None, 'Pillow unavailable')
class AssetAuditTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.gold, self.project = fixture(self.root)

    def tearDown(self):
        self.tmp.cleanup()

    def test_four_graphic_categories_and_candidate_indices(self):
        result = audit(self.gold, self.project)
        self.assertEqual(result['registered_maps'], 2)
        rows = result['metatiles']
        self.assertEqual([x['status'] for x in rows],
                         ['UNMATCHED', 'PIXEL_EXACT', 'PATTERN_ONLY', 'RAW_BYTES_ONLY'])
        self.assertEqual(rows[1]['candidates'][0]['rpp_metatile_id'], 0)
        self.assertEqual(rows[2]['candidates'][0]['rpp_metatile_id'], 1)
        self.assertEqual(rows[3]['candidates'][0]['rpp_metatile_id'], 2)
        self.assertTrue(all(x['collision_status'] == 'NOT_RPP_VALIDATED' for x in rows))

    def test_shared_layout_frequency_and_first_route(self):
        rows = audit(self.gold, self.project)['map_priority']
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]['source_layout'], 'maps/Common.blk')
        self.assertEqual(rows[1]['source_layout'], 'maps/Common.blk')
        self.assertEqual(rows[0]['unmatched_cells'], 1)
        self.assertEqual(rows[0]['raw_bytes_only_cells'], 1)
        self.assertIn('$00:1', rows[0]['priority_manual_ids'])

    def test_write_reports_and_no_source_mutation(self):
        protected = [self.gold/'maps/Common.blk', self.project/'gfx/blocksets/outdoor.bst']
        before = [hashlib.sha256(p.read_bytes()).digest() for p in protected]
        target = self.root/'separate'
        self.assertEqual(main(['--gold-root', str(self.gold),
                               '--project', str(self.project), '--output', str(target)]), 0)
        self.assertTrue((target/'asset_audit.json').is_file())
        self.assertTrue((target/'00_审计摘要.md').is_file())
        with (target/'metatile_matches.csv').open(encoding='utf-8-sig') as f:
            self.assertEqual(len(list(csv.DictReader(f))), 4)
        self.assertEqual([hashlib.sha256(p.read_bytes()).digest() for p in protected], before)

    def test_output_must_be_external_empty(self):
        with self.assertRaises(AuditError):
            safe_output(self.gold, self.project, self.project/'report')
        with self.assertRaises(AuditError):
            safe_output(self.gold, self.project, self.root)
        out = self.root/'outside'
        out.mkdir()
        (out/'existing.txt').write_text('safe')
        with self.assertRaises(AuditError):
            safe_output(self.gold, self.project, out)

    def test_invalid_source_layout_size_fail_closed(self):
        (self.gold/'maps/Common.blk').write_bytes(bytes([0]))
        with self.assertRaisesRegex(AuditError, '长度错误'):
            audit(self.gold, self.project)

    def test_out_of_range_tiles_are_not_pixel_verified(self):
        (self.gold/'data/tilesets/johto_metatiles.bin').write_bytes(
            bytes([99]*16) + b''.join(bytes([i]*16) for i in range(1, 4)))
        (self.gold/'maps/Common.blk').write_bytes(bytes([0,1,2,3]))
        result = audit(self.gold, self.project)
        row = result['metatiles'][0]
        self.assertEqual(row['gold_art_issue'], 'OUT_OF_RANGE')
        self.assertNotIn(row['status'], ('PIXEL_EXACT','PATTERN_ONLY'))

    def test_missing_gold_png_is_not_assumed_equal(self):
        (self.gold/'gfx/tilesets/johto.png').unlink()
        result = audit(self.gold, self.project)
        self.assertEqual(result['gold_summary'][0]['pixel_exact'], 0)
        self.assertEqual(result['gold_summary'][0]['pattern_only'], 0)
        self.assertTrue(all(r['gold_art_issue']=='PNG_MISSING' for r in result['metatiles']))

    def test_collision_count_mismatch_stays_unverified(self):
        (self.gold/'data/tilesets/johto_collision.asm').write_text('tilecoll FLOOR, FLOOR, FLOOR, FLOOR\n')
        rows = audit(self.gold, self.project)['metatiles']
        self.assertTrue(all(r['collision_status']=='COLLISION_COUNT_MISMATCH' for r in rows))

    def test_existing_8x8_art_can_build_new_32x32_block(self):
        # RPP owns the needed 8x8 graphic, but has not composed this full block.
        atlas(self.project/'gfx/tilesets/outdoor.png', [
            ('vert', (255,255,255)), ('checker', (255,0,0)),
            ('horizontal', (255,255,255)), ('cross', (255,255,255))])
        report = audit(self.gold, self.project)
        source = report['metatiles'][0]
        self.assertEqual(source['status'], 'RECOMPOSE_8X8')
        self.assertEqual(source['candidates'][0]['rpp_tileset'], 'outdoor')
        self.assertEqual(source['candidates'][0]['rpp_tile_ids'], [0]*16)
        self.assertEqual(report['map_priority'][0]['recompose_8x8_cells'], 1)
        self.assertEqual(source['collision_status'], 'NOT_RPP_VALIDATED')

    def test_shape_only_recomposition_never_becomes_pixel_exact(self):
        atlas(self.project/'gfx/tilesets/outdoor.png', [
            ('vert', (255,0,0)), ('checker', (255,0,0)),
            ('horizontal', (255,255,255)), ('cross', (255,255,255))])
        report = audit(self.gold, self.project)
        self.assertEqual(report['metatiles'][0]['status'], 'RECOMPOSE_PATTERN_8X8')
        self.assertEqual(report['map_priority'][0]['recompose_pattern_8x8_cells'], 1)

    def test_gold_asm_shared_metatile_and_collision_sources(self):
        # Source asm owns the alias; there is no dark_cave_metatiles.bin.
        (self.gold/'gfx/tilesets.asm').write_text("""\
TilesetCaveMeta::
TilesetDarkCaveMeta::
INCBIN "data/tilesets/cave_metatiles.bin"
TilesetCaveColl::
TilesetDarkCaveColl::
INCLUDE "data/tilesets/cave_collision.asm"
TilesetDarkCaveGFX::
INCBIN "gfx/tilesets/dark_cave.2bpp.lz"
""")
        (self.gold/'data/tilesets/cave_metatiles.bin').write_bytes(bytes([0]*16))
        (self.gold/'data/tilesets/cave_collision.asm').write_text(
            'tilecoll WALL, WALL, WALL, WALL\n')
        aliases = gold_resource_aliases(self.gold)
        raw, path, remainder = blocks_for(self.gold, 'dark_cave', 'gold', aliases)
        self.assertEqual(raw, bytes([0]*16))
        self.assertEqual(remainder, 0)
        self.assertEqual(path, 'data/tilesets/cave_metatiles.bin')
        labels, coll_path = collision_labels(self.gold, 'dark_cave', aliases)
        self.assertEqual(coll_path, 'data/tilesets/cave_collision.asm')
        self.assertEqual(labels, ['WALL,WALL,WALL,WALL'])

    def test_gold_shared_resources_are_used_by_full_audit(self):
        (self.gold/'gfx/tilesets.asm').write_text("""\
TilesetJohtoMeta::
INCBIN "data/tilesets/johto_metatiles.bin"
TilesetJohtoColl::
INCLUDE "data/tilesets/johto_collision.asm"
TilesetCaveMeta::
TilesetDarkCaveMeta::
INCBIN "data/tilesets/cave_metatiles.bin"
TilesetCaveColl::
TilesetDarkCaveColl::
INCLUDE "data/tilesets/cave_collision.asm"
""")
        with (self.gold/'data/maps/maps.asm').open('a') as f:
            f.write('map DarkCave, TILESET_DARK_CAVE, CAVE, LANDMARK\n')
        with (self.gold/'constants/map_constants.asm').open('a') as f:
            f.write('map_const DARK_CAVE, 2, 2\n')
        with (self.gold/'data/maps/blocks.asm').open('a') as f:
            f.write('DarkCave_Blocks:\n INCBIN "maps/DarkCave.blk"\n')
        (self.gold/'maps/DarkCave.blk').write_bytes(bytes([0]*4))
        (self.gold/'data/tilesets/cave_metatiles.bin').write_bytes(bytes([0]*16))
        (self.gold/'data/tilesets/cave_collision.asm').write_text(
            'tilecoll WALL, WALL, WALL, WALL\n')
        atlas(self.gold/'gfx/tilesets/dark_cave.png', [('vert',(255,255,255))]*4)
        result = audit(self.gold, self.project)
        caves = [r for r in result['gold_summary'] if r['gold_tileset']=='dark_cave']
        self.assertEqual(len(caves), 1)
        self.assertEqual(caves[0]['gold_metatile_file'], 'data/tilesets/cave_metatiles.bin')
        self.assertEqual(caves[0]['gold_collision_file'], 'data/tilesets/cave_collision.asm')
        self.assertEqual(caves[0]['gold_collision_rows'], 1)
        self.assertEqual(result['registered_maps'], 3)

    def test_facility_legacy_terminal_zero_is_explicitly_reported(self):
        payload = bytes([3]*16)*128 + b'\x00'
        (self.project/'gfx/blocksets/facility.bst').write_bytes(payload)
        raw, source, tail = blocks_for(self.project, 'facility', 'rpp')
        self.assertEqual(raw, payload[:-1])
        self.assertEqual(tail, 1)
        self.assertEqual(source, 'gfx/blocksets/facility.bst')
        result = audit(self.gold, self.project)
        self.assertEqual(result['rpp_inventory']['facility']['metatile_count'], 128)
        self.assertEqual(result['rpp_inventory']['facility']['trailing_partial_bytes'], 1)
        self.assertIn('facility', result['diagnostics']['rpp_partial_trailing_files'])
        self.assertEqual((self.project/'gfx/blocksets/facility.bst').read_bytes(), payload)

    def test_unknown_or_nonzero_bst_partial_tail_is_rejected(self):
        for name, suffix in [('facility', b'\x01'), ('other', b'\x00')]:
            (self.project/'gfx/blocksets'/f'{name}.bst').write_bytes(bytes([3]*16)*128+suffix)
            with self.assertRaisesRegex(AuditError, '非完整区块字节'):
                blocks_for(self.project, name, 'rpp')

    def test_deterministic_reports(self):
        result = audit(self.gold, self.project)
        a,b = self.root/'out1', self.root/'out2'
        emit(result, a)
        emit(result, b)
        self.assertEqual(sorted(x.name for x in a.iterdir()), sorted(x.name for x in b.iterdir()))
        for name in (x.name for x in a.iterdir()):
            self.assertEqual((a/name).read_bytes(), (b/name).read_bytes())


if __name__ == '__main__':
    unittest.main()
