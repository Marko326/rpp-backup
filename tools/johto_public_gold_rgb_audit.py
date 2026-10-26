#!/usr/bin/env python3
"""Gold-exact indoor background RGB audit for shared Johto PC and MART.

Inspects the live palette set, actual tilepal roles, and underlying RGB slots.
Cherrygrove reuses Olivine's tilesets; this deliberately does not alter Kanto.
Source-only verification; it is not a ROM or LCD rendering test.
"""
from pathlib import Path
import re
import sys

from johto_gate_rgb_audit import _gold_indoor, _rpp_palettes, _sets

ROLE_TO_GOLD = {
    'GRAY': 'GRAY', 'RED': 'RED', 'GREEN': 'GREEN',
    'WATER': 'WATER', 'YELLOW': 'YELLOW', 'BROWN': 'BROWN', 'ROOF': 'ROOF',
}
BUILDINGS = (
    ('POKECENTER', 37, 'johto_olivine_pokecenter', 'JohtoCherrygrovePokecenter1F',
     { 'GREEN': 'JOHTO_GATE_GOLD_GREEN' }),
    ('MART', 38, 'johto_olivine_mart', 'JohtoCherrygroveMart',
     { 'GREEN': 'JOHTO_GATE_GOLD_GREEN', 'BROWN': 'JOHTO_GATE_GOLD_BROWN' }),
)

def verify(rpp: Path, gold: Path, overrides=None):
    overrides = overrides or {}
    errors = []
    def read(path, from_gold=False):
        if not from_gold and path in overrides:
            return overrides[path]
        return ((gold if from_gold else rpp) / path).read_text()
    try:
        palettes = _rpp_palettes(read('color/data/map_palettes.asm'))
        gold_palettes = _gold_indoor(read('gfx/tilesets/bg_tiles.pal', True))
        sets = _sets(read('color/data/map_palette_sets.asm'))
        consts = read('color/data/map_palette_constants.asm').split('; Named', 1)[0]
        nums = {name: int(num, 16) for name, num in re.findall(r'\bconst\s+(\w+)\s*;\s*([0-9A-Fa-f]{2})\b', consts)}
        installer = read('tools/install_olivine_public_runtime.py')
        for building, index, asset, city_header, gold_slots in BUILDINGS:
            header = read('data/mapHeaders/' + city_header + '.asm')
            if 'JOHTO_OLIVINE_' + ('POKECENTER' if building == 'POKECENTER' else 'MART') not in header:
                errors.append(f'{building}: Cherrygrove no longer shares Olivine tileset')
            if len(sets) <= index:
                errors.append(f'{building}: missing runtime palette set {index}')
                continue
            slots = sets[index]
            tilepal = read('color/tilesets/' + asset + '.asm')
            roles = []
            for row in tilepal.splitlines():
                if re.match(r'^\s*tilepal\s+0,', row):
                    roles += [v.strip() for v in row.split(',',1)[1].split(';')[0].split(',')]
            if len(roles) != 96:
                errors.append(f'{building}: unexpected {len(roles)} tile palette roles, expected 96')
            for role, target_symbol in gold_slots.items():
                if role not in roles:
                    errors.append(f'{building}: intended {role} is unused in actual tiles')
                role_index = {'GRAY':0,'RED':1,'GREEN':2,'WATER':3,
                              'YELLOW':4,'BROWN':5,'ROOF':6}[role]
                if slots[role_index] != target_symbol:
                    errors.append(f'{building}: {role} points to {slots[role_index]} instead of {target_symbol}')
            for role in set(roles) & ROLE_TO_GOLD.keys():
                role_index = {'GRAY':0,'RED':1,'GREEN':2,'WATER':3,
                              'YELLOW':4,'BROWN':5,'ROOF':6}[role]
                symbol = slots[role_index]
                if symbol not in nums:
                    errors.append(f'{building}: missing map palette constant {symbol}')
                elif palettes[nums[symbol]] != gold_palettes[ROLE_TO_GOLD[role]]:
                    errors.append(f'{building}: Gold {role} RGB differs at {symbol}')
            # A rerun of the Olivine installer must not restore the old slots.
            template = installer.split("s += '; JOHTO_OLIVINE_" + building + "\\n",1)
            if len(template) != 2:
                errors.append(f'{building}: installer template absent')
            else:
                text = template[1].split("'",1)[0]
                for symbol in gold_slots.values():
                    if symbol not in text:
                        errors.append(f'{building}: installer would revert {symbol}')
        # Kanto protected independent of Johto's shared public palettes.
        if len(sets) <= 12 or sets[12][2] != 'INDOOR_GREEN' or sets[12][1] != 'POKECENTER_TABLE':
            errors.append('Kanto indoor palette set modified')
        if palettes[0x0b][0] != (30,28,26) or palettes[0x0e][0] != (30,28,26):
            errors.append('Kanto INDOOR_GREEN/BROWN underlying RGB modified')
    except (OSError, ValueError, IndexError, KeyError) as exc:
        errors.append('Gold public RGB source failure: ' + str(exc))
    return errors

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--rpp', type=Path, required=True)
    parser.add_argument('--gold', type=Path, required=True)
    args = parser.parse_args()
    errs = verify(args.rpp, args.gold)
    print('GOLD JOHTO PC/MART RGB', 'PASS' if not errs else 'FAIL', errs)
    sys.exit(bool(errs))
