#!/usr/bin/env python3
"""Current maintained source gate: static ASM checks, migration audit and all tests.

This does NOT assemble/link a ROM or substitute for device acceptance. Older
DEV/REF milestone scripts can still be run separately for targeted diagnosis;
this is the preferred single entrypoint for a received project archive.

Usage:
    python tools/validate_current_project.py
    python tools/validate_current_project.py --gold-root /path/to/pokegold-master
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def run_command(label: str, command: list[str], env: dict[str, str]) -> tuple[str, int, str]:
    try:
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                text=True, errors='replace', check=False)
        return label, result.returncode, result.stdout + result.stderr
    except OSError as exc:
        return label, 127, str(exc)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gold-root', type=Path,
                        help='optional original pokegold-master tree; strengthens the Gold source audit')
    parser.add_argument('--skip-pytest', action='store_true',
                        help='only run static and migration checks')
    parser.add_argument('--jobs', type=int, default=4,
                        help='parallel pytest groups (1-4, default 4)')
    args = parser.parse_args(argv)
    if not 1 <= args.jobs <= 4:
        parser.error('--jobs must be from 1 to 4')
    env = os.environ.copy()
    if args.gold_root:
        if not args.gold_root.is_dir():
            parser.error(f'--gold-root does not exist: {args.gold_root}')
        env['GOLD_SOURCE_ROOT'] = str(args.gold_root.resolve())
        # Some historical Gold-backed tests use the older Johto-specific name.
        # Export both aliases so --gold-root actually enables, rather than skips,
        # every relevant source/warp/collision test in the grouped pytest run.
        env['JOHTO_GOLD_SOURCE'] = str(args.gold_root.resolve())
    checks = [
        ('ASM local-symbol preflight', [sys.executable, 'tools/asm_symbol_preflight.py']),
        ('active table-length preflight', [sys.executable, 'tools/johto_table_assert_preflight.py', '--root', '.']),
        # Hard gate for newly enabled maps, source Warp object ordinals,
        # end-to-end arrival movement and field move public-entry dispatch.
        ('warp / field-entry activation gate',
         [sys.executable, 'tools/johto_warp_field_entry_gate.py', '--root', '.']),
        # REF-367H: active Ice Path tileset ID41 must have runtime CGB palette
        # tables and a real name-sign dispatcher. Run before legacy milestone
        # audits which may stop early on obsolete 65-map/168-Warp contracts.
        ('Ice Path 1F live graphics / palette / name-sign gate',
         [sys.executable, 'tools/johto_ice_path_1f_367e_audit.py', '--root', '.']),
        ('Ice Path B1F live stairs / cave safety gate',
         [sys.executable, 'tools/johto_ice_path_b1f_367k_audit.py', '--root', '.']),
        ('Ice Path B2F Mahogany sole stair / arrival-only pit / walk gate',
         [sys.executable, 'tools/johto_ice_path_b2f_mahogany_368a_audit.py', '--root', '.']),
        ('Ice Path B3F Gold fourth floor / two open reciprocal stair gate',
         [sys.executable, 'tools/johto_ice_path_b3f_368b_audit.py', '--root', '.']),
        ('Ice Path B2F Blackthorn Gold stairs / directed hop / source gate',
         [sys.executable, 'tools/johto_ice_path_b2f_blackthorn_368c_audit.py', '--root', '.']),
        ('Ice Path REF368D Gold stair / both ledges / bicycle / rope gate',
         [sys.executable, 'tools/johto_ice_path_stair_ledge_368d_audit.py', '--root', '.']),
        ('Ice Path REF368E five-floor bicycle item / SELECT / mounted-transfer gate',
         [sys.executable, 'tools/johto_ice_path_bicycle_368e_audit.py', '--root', '.']),
        ('Johto Gold Strength asynchronous dust / quiet Kanto gate',
         [sys.executable, 'tools/johto_strength_gold_dust_369l_audit.py', '--root', '.']),
        ('REF-369N Gold 2x2 dust / OAM capacity / quiet Kanto',
         [sys.executable, 'tools/johto_gold_dust_quadrants_369n_audit.py', '--root', '.']),
        ('REF-369M Gold dust palette / local Ice Path 2px quake / Kanto isolation',
         [sys.executable, 'tools/johto_ice_path_gold_visual_369m_audit.py', '--root', '.']),
        ('REF369O actual movement completion / Gold push SFX gate',
         [sys.executable, 'tools/johto_strength_push_drop_369o_audit.py', '--root', '.']),
        ('REF369P dialogue and START dust cleanup gate',
         [sys.executable, 'tools/johto_ice_path_text_dust_369p_audit.py', '--root', '.']),
        ('REF369Q accepted-boulder tracking gate',
         [sys.executable, 'tools/johto_gold_dust_tracking_369q_audit.py', '--root', '.']),
        ('REF369R two-slot post-hide smoke gate',
         [sys.executable, 'tools/johto_gold_dust_lifecycle_369r_audit.py', '--root', '.']),
        ('REF369S Gold Ice Path 4 player PIT / receive-only safe arrival gate',
         [sys.executable, 'tools/johto_ice_path_player_fall_369s_audit.py', '--root', '.']),
        ('REF369T Ice Path standard cave fade / early B2F stone hide / Gold fast slide',
         [sys.executable, 'tools/johto_ice_path_pit_fade_sprite_slide_369t_audit.py', '--root', '.']),
        ('REF369U common black pit fall / Gold cave rock palette / B2F first-frame sprites',
         [sys.executable, 'tools/johto_ice_path_pit_arrival_visual_369u_audit.py', '--root', '.']),
        ('REF-369V silent PIT/no pre-render regression',
         [sys.executable, 'tools/johto_pit_silent_transition_369v_audit.py']),
        ('Ice Path REF369B save-event ownership / one-time migration gate',
         [sys.executable, 'tools/johto_ice_path_save_flag_audit_369b.py', '--root', '.']),
        ('Ice Path REF369E hidden stone Sprite-ID safety / menu return gate',
         [sys.executable, 'tools/johto_ice_path_sprite_hide_369e_audit.py', '--root', '.']),
        ('Ice Path REF369F Gold five-map perimeter / border block gate',
         [sys.executable, 'tools/johto_ice_path_border_369f_audit.py', '--root', '.']),
        ('Ice Path REF369G Gold boulder drop feedback / one-shot gate',
         [sys.executable, 'tools/johto_ice_path_boulder_fall_369g_audit.py', '--root', '.']),
        ('Ice Path REF369J immediate boulder disappear before quake / OAM gate',
         [sys.executable, 'tools/johto_ice_path_immediate_disappear_369j_audit.py', '--root', '.']),
        ('Ice Path REF369H B1F push-target coordinates / fixed-wall gate',
         [sys.executable, 'tools/johto_ice_path_boulder_target_369h_audit.py', '--root', '.']),
        ('Ice Path REF369B WIP Strength boulders / saved PIT landing gate',
         [sys.executable, 'tools/johto_ice_path_strength_pit_369b_audit.py', '--root', '.']),
        ('Ice Path REF368F live slide step/input/bank-safety gate',
         [sys.executable, 'tools/johto_ice_path_slide_368f_audit.py', '--root', '.']),
        ('active map name-sign contract',
         [sys.executable, 'tools/johto_map_name_sign_audit.py', '--project', '.']),
        ('Dark Cave Gold field-move audit',
         [sys.executable, 'tools/johto_dark_cave_365_audit.py', '--root', '.'] +
         (['--gold-root', str(args.gold_root.resolve())] if args.gold_root else [])),
        # Gold ICE stage: original five source maps remain exact; native
        # dormant controller is still unlinked, live REF368F slide has its own
        # separate real-step/joypad gate; player PIT is now enabled by REF369S exact one-way Gold routes; boulder dropping has a separate gate.
        ('Ice Path Gold source-staging gate',
         [sys.executable, 'tools/johto_ice_path_367_stage_audit.py', '--root', '.']),
        ('Ice Path directional movement and Strength/PIT reference gate',
         [sys.executable, 'tools/johto_ice_path_367_movement.py', '--root', '.']),
        ('Ice Path native Gold ice / PIT branch-level audit',
         [sys.executable, 'tools/johto_ice_path_367_native_audit.py', '--root', '.']),
        ('Ice Path dormant native slide-heading state audit',
         [sys.executable, 'tools/johto_ice_path_367_slide_audit.py', '--root', '.']),
        ('current migration audit', [sys.executable, 'tools/johto_pilot_migration_audit.py', '--project', '.'] +
            (['--gold-root', str(args.gold_root.resolve())] if args.gold_root else [])),
    ]
    for label, command in checks:
        name, code, output = run_command(label, command, env)
        print(f'[{"PASS" if code == 0 else "FAIL"}] {name}', flush=True)
        print(output.rstrip(), flush=True)
        if code:
            print('Source gate failed; remaining checks were not reported as passing.', file=sys.stderr)
            return 1
    if not args.skip_pytest:
        test_files = sorted(str(p.relative_to(ROOT)) for p in (ROOT/'tools/tests').glob('test_*.py'))
        if not test_files:
            print('[FAIL] No pytest test files found', file=sys.stderr)
            return 1
        # Group independently to keep individual pytest processes bounded.
        groups = [test_files[i:i + 19] for i in range(0, len(test_files), 19)]
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = {
                pool.submit(run_command, f'pytest group {idx + 1}/{len(groups)}',
                            [sys.executable, '-m', 'pytest', '-q', '--tb=short', *files], env): idx
                for idx, files in enumerate(groups)
            }
            outputs = [None] * len(groups)
            for future in as_completed(futures):
                outputs[futures[future]] = future.result()
        failed = False
        for name, code, output in outputs:
            print(f'[{"PASS" if code == 0 else "FAIL"}] {name}', flush=True)
            print(output.rstrip(), flush=True)
            failed |= bool(code)
        if failed:
            print('FAIL: at least one pytest group failed', file=sys.stderr)
            return 1
    print('PASS: source/test checks only; ROM link, fresh MAP, and device test remain required.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
