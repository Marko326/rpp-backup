"""Fast independent validator checks; no original Gold source required."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_gold_sources import gold_block_sources
from johto_rpp_validate import (checked_file, compare_graphics,
                                diagnostic, make_result, verify, write_reports)


class JohtoValidatorUnitTest(unittest.TestCase):
    def test_blocks_parser_resolves_multiple_labels_and_rejects_unsafe(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root/'data/maps').mkdir(parents=True)
            blocks = root/'data/maps/blocks.asm'
            blocks.write_text('ExampleMart_Blocks:\nOtherMart_Blocks:\n'
                              '\tINCBIN "maps/Mart.blk" ; shared\n')
            self.assertEqual(gold_block_sources(root), {
                'ExampleMart': 'maps/Mart.blk', 'OtherMart': 'maps/Mart.blk'})
            blocks.write_text('Unsafe_Blocks:\n\tINCBIN "maps/../outside.blk"\n')
            with self.assertRaises(ValueError):
                gold_block_sources(root)
            blocks.write_text('Broken_Blocks:\nSECTION "Next", ROMX\n')
            with self.assertRaises(ValueError):
                gold_block_sources(root)

    def test_graphics_match_when_clone_only(self):
        orig_block = bytes([0x05, 0x4c, 0x06] + [0] * 13)
        converted = bytes([0x20, 0x21, 0x30] + [0] * 13)
        self.assertEqual(compare_graphics(b'\0', b'\0', orig_block, converted), [])

    def test_changed_graphics_fail(self):
        self.assertEqual(compare_graphics(b'\0', b'\0', bytes(16), bytes([2]+[0]*15)), [0])

    def test_disallow_path_traversal(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                checked_file(Path(tmp), '../../etc/passwd')

    def test_missing_stage_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            report = verify(root, root, root)
            self.assertEqual(report['status'], 'FAILED')
            self.assertEqual(report['summary']['global_errors'], 5)

    def test_html_report_is_escaped_and_machine_readable(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            report = make_result([], [diagnostic('test_error', '<script>')], {}, {})
            write_reports(root, report)
            html = (root/'verification/index.html').read_text()
            self.assertIn('&lt;script&gt;', html)
            self.assertNotIn('<script>', html)
            self.assertIn('"status": "FAILED"',
                          (root/'verification/verification.json').read_text())

    def test_reject_output_within_project(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            project = root/'project'
            project.mkdir()
            script = Path(__file__).resolve().parents[1]/'johto_rpp_pipeline.py'
            proc = subprocess.run([sys.executable, str(script), '--project', str(project),
                                   '--gold-root', str(root/'gold'),
                                   '--output', str(project/'staging')],
                                  capture_output=True, text=True)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn('separate', proc.stderr)


if __name__ == '__main__':
    unittest.main()
