#!/usr/bin/env python3
"""REF-369F Ice Path Gold perimeter border-block audit (static only).

Gold maps/attributes.asm: 1F $09; B1F, Mahogany B2F, Blackthorn B2F, B3F $19.
This is not a ROM or phone-validation substitute.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re

BORDERS = {
    'ice_path_1f_runtime_367e.asm': ('JohtoIcePath1FObjects367E::', 0x09),
    'ice_path_b1f_runtime_367k.asm': ('JohtoIcePathB1FObjects367K::', 0x19),
    'ice_path_b2f_mahogany_runtime_368a.asm': ('JohtoIcePathB2FMahoganyObjects368A::', 0x19),
    'ice_path_b2f_blackthorn_runtime_368c.asm': ('JohtoIcePathB2FBlackthornObjects368C::', 0x19),
    'ice_path_b3f_runtime_368b.asm': ('JohtoIcePathB3FObjects368B::', 0x19),
}

def audit(root: Path, overrides: dict[str, str] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}
    errors = []
    for name, (label, want) in BORDERS.items():
        rel = 'data/johto_ice_path_stage/' + name
        src = overrides.get(rel, (root / rel).read_text())
        if src.count(label) != 1:
            errors.append(name + ': missing or duplicate object label')
            continue
        rest = src.split(label, 1)[1]
        match = re.match(r'\s*db\s+\$([0-9a-fA-F]{2})\b', rest)
        if not match or int(match.group(1), 16) != want:
            errors.append(f'{name}: wrong border, expected ${want:02X}')
    # Gold-derived source blockset IDs validate the expected graphic semantics.
    bst = (root / 'gfx/blocksets/johto_ice_path_gold.bst').read_bytes()
    if len(bst) != 64*16 or bst[9*16:10*16] != bytes([18]*16) or bst[25*16:26*16] != bytes([6,7,6,7,22,23,22,23]*2):
        errors.append('Gold tileset block 09/19 changed: ground/rock semantics unsafe')
    if 'db "REF-369@"' not in (root/'data/game_version.asm').read_text():
        errors.append('REF-369F version absent')
    return errors

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--root', default='.')
    args=p.parse_args()
    errors = audit(Path(args.root))
    if errors:
        print('FAIL:', *errors, sep='\n - ')
        raise SystemExit(1)
    print('PASS: Ice Path 1F/B1F/B2F/B3F Gold perimeter border metadata; static only')
