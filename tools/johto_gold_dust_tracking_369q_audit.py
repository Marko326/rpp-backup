#!/usr/bin/env python3
"""REF-369Q: guard source-boulder tracking, no player-direction retargeting.

Static source audit only; Gold video/device verification remains necessary.
"""
from pathlib import Path

DUST = 'engine/overworld/johto_gold_strength_dust_369l.asm'
PUSH = 'engine/overworld/push_boulder.asm'
WRAM = 'wram.asm'
OAM = 'engine/overworld/oam.asm'
START = 'engine/menu/start_menu.asm'
KANTO = 'engine/overworld/ssanne.asm'
FALL = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
VERSION = 'data/game_version.asm'


def audit(root: Path, overrides=None):
    # REF-369R extends the original Q single-source design to two tracked
    # slots; keep Q's public entrypoint but validate actual new control flow.
    try:
        from tools.johto_gold_dust_lifecycle_369r_audit import audit as lifecycle
    except ModuleNotFoundError:
        from johto_gold_dust_lifecycle_369r_audit import audit as lifecycle
    return lifecycle(root, overrides)


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default='.', type=Path)
    errors = audit(ap.parse_args().root)
    for error in errors:
        print('FAIL:', error)
    if errors:
        raise SystemExit(1)
    print('PASS: Gold source-boulder dust tracking, freeze after hide, no live D-pad retarget, Kanto isolation')
