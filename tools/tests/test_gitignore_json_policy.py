"""Prevent source JSON from silently disappearing into a global Git ignore.

Policy is aligned with the user-provided NPC-5.62.243 reference branch:
source JSON is visible by default; disposable generated JSON is ignored only
in explicit output/cache directories. Uses actual Git ignore matching.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

SOURCE_JSON = (
    'tools/johto_pilot_door_contracts.json',
    'tools/future_route_contract.json',
    'tools/nested/future_indoor_contract.json',
    'data/johto/map_manifest.json',
    'docs/johto/source_fingerprint.json',
    'RPP_COMMIT_RESTORE/manifest.json',
)
GENERATED_JSON = (
    'extras/report.json',
    'extras/maps/report.json',
    'tools/generated_reports/report.json',
    'tools/generated_reports/batch/route32.json',
    'tools/cache/state.json',
    'tools/cache/johto/staging.json',
)


def ignored_by_git(root: Path, relative_path: str) -> bool:
    proc = subprocess.run(
        ['git', '-C', str(root), 'check-ignore', '--no-index', '--quiet', '--', relative_path],
        capture_output=True, text=True,
    )
    if proc.returncode not in (0, 1):
        raise RuntimeError(f'git check-ignore failed: {proc.stderr}')
    return proc.returncode == 0


def make_fixture(dst: Path, ignore_text: str) -> None:
    subprocess.run(['git', 'init', '-q', str(dst)], check=True, capture_output=True, text=True)
    (dst / '.gitignore').write_text(ignore_text, encoding='utf-8')
    (dst / 'tools').mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'tools/.gitignore', dst / 'tools/.gitignore')


def assert_json_policy(test: unittest.TestCase, root: Path) -> None:
    for path in SOURCE_JSON:
        test.assertFalse(ignored_by_git(root, path), f'source JSON unexpectedly ignored: {path}')
    for path in GENERATED_JSON:
        test.assertTrue(ignored_by_git(root, path), f'generated JSON should be ignored: {path}')


class GitIgnoreJsonPolicyTests(unittest.TestCase):
    def test_source_and_generated_json_follow_reference_branch_policy(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            make_fixture(root, (ROOT / '.gitignore').read_text(encoding='utf-8'))
            assert_json_policy(self, root)

    def test_global_json_ignore_regression_is_detected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            # Negative injection: a future maintainer accidentally restores a catch-all.
            make_fixture(root, (ROOT / '.gitignore').read_text(encoding='utf-8') + '\n*.json\n')
            self.assertTrue(ignored_by_git(root, 'tools/future_route_contract.json'))
            self.assertFalse(ignored_by_git(root, 'README.md'))

    def test_unscoped_source_files_remain_visible_in_nested_tools(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            make_fixture(root, (ROOT / '.gitignore').read_text(encoding='utf-8'))
            for path in ('tools/generated_reports_source/contract.json',
                         'tools/cache_source/manifest.json',
                         'src/data/generated_reports/catalog.json'):
                self.assertFalse(ignored_by_git(root, path), path)

    def test_ignored_generated_json_does_not_hide_adjacent_non_json_source(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            make_fixture(root, (ROOT / '.gitignore').read_text(encoding='utf-8'))
            for path in ('tools/generated_reports/README.md', 'extras/source.asm',
                         'tools/cache/README.md'):
                self.assertFalse(ignored_by_git(root, path), path)


if __name__ == '__main__':
    unittest.main()
