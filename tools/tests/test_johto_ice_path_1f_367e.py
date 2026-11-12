"""REF-367E 1F map stage and deliberate fault injection guards."""
from pathlib import Path
import shutil
from tools.johto_ice_path_1f_367e_audit import audit

ROOT = Path(__file__).resolve().parents[2]


def test_good_1f_stage():
    assert audit(ROOT) == []


def test_wrong_gold_render_bytes_detected(tmp_path):
    shutil.copytree(ROOT, tmp_path / 'r', ignore=shutil.ignore_patterns('.git', '__pycache__', '*.pyc'))
    root = tmp_path / 'r'
    art = root / 'gfx/tilesets/johto_ice_path_gold_96tiles.bin'
    bad = bytearray(art.read_bytes())
    bad[20] ^= 0x01
    art.write_bytes(bad)
    assert any('tile bytes corrupt' in s for s in audit(root))


def test_wrong_outdoor_exit_coord_detected(tmp_path):
    shutil.copytree(ROOT, tmp_path / 'r', ignore=shutil.ignore_patterns('.git', '__pycache__', '*.pyc'))
    root = tmp_path / 'r'
    p = root / 'data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm'
    p.write_text(p.read_text().replace('db 27, 36, 1,', 'db 27, 35, 1,'))
    assert any('Gold warp' in s for s in audit(root))


def test_unseal_stair_detected(tmp_path):
    shutil.copytree(ROOT, tmp_path / 'r', ignore=shutil.ignore_patterns('.git', '__pycache__', '*.pyc'))
    root = tmp_path / 'r'
    p = root / 'data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm'
    p.write_text(p.read_text().replace('db 5, 37, 0,', 'db $ff, $ff, 0,'))
    assert any('Gold warp' in s for s in audit(root))


def test_cli_audit_works_without_pythonpath():
    import subprocess
    import os
    env = os.environ.copy()
    env.pop('PYTHONPATH', None)
    proc = subprocess.run(['python', 'tools/johto_ice_path_1f_367e_audit.py', '--root', '.'],
                          cwd=ROOT, env=env, capture_output=True, text=True)
    assert proc.returncode == 0, proc.stderr + proc.stdout


def test_ice_path_1f_walk_only_new_map_review():
    """Live 1F has Gold objects (2 outdoors + 2 open B1F), ICE walkable."""
    source=(ROOT / 'data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm').read_text()
    assert 'JohtoIcePath1FLandDecision367F::' in source
    assert 'cp 4 ; Gold LADDER:' in source
    assert 'ld e, 0 ; FLOOR / ICE / carpet / legal ledge is WALKABLE' in source
    assert source.count('db $ff, $ff,') == 0
    from tools.johto_warp_field_entry_gate import audit as gate_audit
    result=gate_audit(ROOT)
    assert result['status']=='PASS_SOURCE_ONLY', result['errors']


def _mutated_project(tmp_path, relative_path, before, after):
    root = tmp_path / 'r'
    shutil.copytree(ROOT, root, ignore=shutil.ignore_patterns('.git', '__pycache__', '*.pyc'))
    file = root / relative_path
    content = file.read_text(encoding='utf8')
    assert before in content
    file.write_text(content.replace(before, after, 1), encoding='utf8')
    return audit(root)


def test_ice_path_palette_set_missing_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'color/data/map_palette_sets.asm',
        'db CAVE_YELLOW, CAVE_BROWN, CAVE_LIGHT_BLUE, CRYS_TEXTBOX\nMapPaletteSetsEnd::',
        'MapPaletteSetsEnd::')
    assert any('palette set runtime row' in i for i in issues)


def test_ice_path_palette_assignment_missing_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'color/data/map_palette_assignments.asm',
        'INCLUDE "color/tilesets/johto_ice_path_1f.asm"',
        '; INCLUDE "color/tilesets/johto_ice_path_1f.asm"')
    assert any('palette assignment runtime INCLUDE' in i for i in issues)


def test_ice_path_wrong_gold_palette_mapping_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'color/tilesets/johto_ice_path_1f.asm',
        'tilepal 0, YELLOW, YELLOW, YELLOW, YELLOW, GREEN, GRAY, GRAY, WATER',
        'tilepal 0, YELLOW, YELLOW, YELLOW, YELLOW, BROWN, GRAY, GRAY, WATER')
    assert any('not the 96 Gold tile palette IDs' in i for i in issues)


def test_ice_path_missing_map_sign_dispatch_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'engine/overworld/map_name_sign.asm',
        'cp JOHTO_ICE_PATH_1F_LOCAL_ID', 'cp JOHTO_ICE_PATH_B1F_LOCAL_ID')
    assert any('map-name sign ID dispatch' in i for i in issues)


def test_ice_path_save_name_fallback_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'engine/fly_town_map_helpers.asm',
        'dw JohtoPilotIcePathName', 'dw JohtoPilotRoute44Name')
    assert any('Save/Continue/Town Map' in i for i in issues)


def test_active_surf_inventory_accepts_ice_path_gold_block_directory():
    from tools.johto_surf_coverage_audit import read_active_maps
    active = read_active_maps(ROOT)
    assert len(active) == 67
    assert any(row['map'] == 'IcePath1F' and row['stable_id'] == 70
               and row['source_asset'] == 'maps/johto_ice_path_stage/IcePath1F.gold.blk'
               for row in active)


def test_validation_runs_ice_palette_and_name_gate_before_historical_audits():
    source = (ROOT / 'tools/validate_current_project.py').read_text()
    assert source.index('Ice Path 1F live graphics / palette / name-sign gate') < source.index(
        'Dark Cave Gold field-move audit')
    assert source.index('active map name-sign contract') < source.index(
        'Dark Cave Gold field-move audit')


def test_palette_macro_must_be_indented_for_rgbasm_052(tmp_path):
    """Recreate the exact REF-367H rgbasm error: unexpected number at tilepal."""
    issues = _mutated_project(tmp_path, 'color/tilesets/johto_ice_path_1f.asm',
        '\ttilepal 0, BROWN, BROWN, BROWN, BROWN, BROWN, BROWN, BROWN, BROWN',
        'tilepal 0, BROWN, BROWN, BROWN, BROWN, BROWN, BROWN, BROWN, BROWN')
    assert any('palette macro not indented at line 4' in i for i in issues)


def test_all_active_ice_palettes_are_macro_indented():
    import re
    data = (ROOT / 'color/tilesets/johto_ice_path_1f.asm').read_text(encoding='utf8')
    assert not re.search(r'(?m)^tilepal\b', data)
    assert len(re.findall(r'(?m)^\s+tilepal 0,', data)) == 12


def test_ice_path_1f_floor_suffix_and_bike_policy():
    """The map-sign and public item-entry routes must reach their real hooks."""
    assert audit(ROOT) == []
    sign = (ROOT / 'engine/overworld/map_name_sign.asm').read_text()
    assert '.johtoIcePath\n    ld hl, .JohtoIcePathName\n    ld b, 1' in sign
    relief = (ROOT / 'home/rom0_relief_349.asm').read_text()
    assert 'cp JOHTO_ICE_PATH_1F_LOCAL_ID\n\tjp z, .icePathBike' in relief


def test_ice_path_floor_tag_regression_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'engine/overworld/map_name_sign.asm',
        '    ld b, 1 ; 1F: reuse the existing Kanto map-sign floor suffix path',
        '    ld b, 0 ; bug: missing 1F')
    assert any('floor tag missing' in issue for issue in issues)


def test_ice_path_bike_public_entry_regression_detected(tmp_path):
    issues = _mutated_project(tmp_path, 'home/rom0_relief_349.asm',
        'cp JOHTO_ICE_PATH_1F_LOCAL_ID', 'cp JOHTO_ICE_PATH_B1F_LOCAL_ID')
    assert any('bike-entry stable-ID dispatch' in issue for issue in issues)


def test_ice_path_bike_illegal_ice_mount_detected(tmp_path):
    issues = _mutated_project(tmp_path,
        'data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm',
        '    cp 5 ; Gold WARP_CARPET_DOWN also has FLOOR permission',
        '    cp 2 ; bug: allow mounting on ICE')
    assert any('bike-floor predicate' in issue for issue in issues)


def test_ice_path_1f_gold_roles_mount_only_on_floor():
    from collections import Counter
    roles = (ROOT/'data/johto_ice_path_stage/IcePath1F.roles.bin').read_bytes()
    assert len(roles) == 40*36
    assert Counter(roles)[0] == 815
    assert Counter(roles)[5] == 3
    assert Counter(roles)[2] == 234
    assert sum(int(role in (0,5)) for role in roles) == 818
