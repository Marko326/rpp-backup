#!/usr/bin/env python3
"""Fail-closed review for Johto field moves; Route32 + Cave 1F Surf staged.

The RPP Surfboard has TWO water allow-lists plus collision checks. Dig and
Escape Rope share a legacy Kanto return destination. This preflight checks
that unreviewed Johto tilesets have not been switched on by adding one token.
It is not a simulator and does not replace Surf runtime, ROM or phone checks.
"""
from pathlib import Path
import argparse
import json
import re
from johto_gold_cells import decode_cells

def registered_johto_tilesets(root: Path) -> frozenset[str]:
    """Use the actual tileset registry, not a map-by-map hardcoded whitelist.

    This project appends native Johto tilesets from the JOHTO entry onward.
    Reject missing/ambiguous registries instead of silently skipping new types.
    """
    registry = (root / 'constants/tilesets.asm').read_text(encoding='utf-8')
    names = re.findall(r'(?m)^\s*const\s+([A-Z][A-Z0-9_]*)\b', registry)
    if names.count('JOHTO') != 1 or len(names) != len(set(names)):
        raise ValueError('tileset registry lacks a unique JOHTO boundary or has duplicate names')
    return frozenset(names[names.index('JOHTO'):])


def section(source: str, label: str, stop: str = '$FF') -> list[str]:
    """Read a simple `db` terminated allow-list without consuming other labels."""
    match = re.search(rf'(?m)^{re.escape(label)}::?\s*(?:;[^\n]*)?$', source)
    if match is None:
        raise ValueError(f'missing {label} table')
    out = []
    for line in source[match.end():].splitlines():
        line = line.split(';', 1)[0].strip()
        if not line:
            continue
        if not line.lower().startswith('db '):
            raise ValueError(f'{label} unterminated before {line[:35]}')
        out.extend(x.strip() for x in line[3:].split(','))
        if any(x.upper() in ('$FF', '-1', '255') for x in out):
            return out
    raise ValueError(f'{label} missing terminator')


def audit(root: Path, gold: Path) -> list[str]:
    errors = []
    try:
        field = (root / 'engine/overworld/field_moves.asm').read_text()
        items = (root / 'engine/items/items.asm').read_text()
        home = (root / 'home/overworld.asm').read_text()
        special = (root / 'engine/special_warps.asm').read_text()
        start = (root / 'engine/menu/start_sub_menus.asm').read_text()
        headbutt = (root / 'engine/overworld/headbutt.asm').read_text()
        native = (root / 'engine/overworld/johto_union_cave_surf.asm').read_text()
        identities = json.loads((root / 'tools/johto_native_maps.json').read_text())
        gold_cave = (gold / 'data/tilesets/cave_collision.asm').read_text()
        johto_tilesets = registered_johto_tilesets(root)
    except (OSError, ValueError) as exc:
        return [f'Field Move sources/contract unavailable: {exc}']

    if 'tilecoll WATER, WATER, WATER, WATER' not in gold_cave:
        errors.append('Gold cave water collision reference changed; review Surf conversion')
    if identities.get('schema_version') != 1 or len(identities.get('maps', [])) < 9:
        errors.append('Johto map capability contract missing/incomplete')
    else:
        for entry in identities['maps']:
            features = entry.get('feature_status', {})
            for name in ('surf', 'dig', 'escape_rope'):
                local_id = entry.get('local_id')
                expected = ('ALLOWED' if (name == 'surf' and local_id in (7, 8, 17, 20, 22))
                            or (name in ('dig', 'escape_rope') and local_id == 8)
                            else 'DEFERRED')
                if features.get(name) != expected:
                    errors.append(f'Johto local {entry.get("local_id")}: {name} must be {expected}; no other runtime permission reviewed')

    for source, label, purpose in ((field, 'WaterTilesets2', 'facing tile Surf'),
                                   (items, 'WaterTilesets', 'Surfboard/fishing'),
                                   (items, 'EscapeRopeTilesets', 'Dig/Escape Rope')):
        try:
            names = section(source, label)
        except ValueError as exc:
            errors.append(str(exc))
            continue
        enabled = johto_tilesets.intersection(names)
        if enabled:
            errors.append(f'{purpose}: unreviewed Johto tileset(s) enabled in {label}: '
                          + ', '.join(sorted(enabled)))

    # The Gold headbutt collision role is not the same as a Cut tree.
    # Both A-button and Pokemon-menu Headbutt must use the same reviewed
    # native quadrants rather than a global JOHTO tile image whitelist.
    try:
        cells = decode_cells(
            (gold / 'maps/EcruteakCity.blk').read_bytes(),
            (gold / 'data/tilesets/johto_metatiles.bin').read_bytes(),
            (gold / 'data/tilesets/johto_collision.asm').read_text(),20,18)
        expected = [(cell['y'],cell['x']) for cell in cells
                    if cell['role']=='HEADBUTT_TREE']
        cut_cells = [(cell['y'],cell['x']) for cell in cells
                     if cell['role']=='CUT_TREE']
        table = re.search(r'(?m)^JohtoEcruteakHeadbuttCells::\s*\n'
                          r'((?:\s*db\s+[^\n]+\n)+)', native)
        entries = (re.findall(r'(?m)^\s*db\s+(\d+),\s*(\d+)\s*$',table[1])
                   if table else [])
        actual = [(int(y),int(x)) for y,x in entries]
        if actual != expected or len(actual)!=50 or cut_cells:
            errors.append('Ecruteak Headbutt: Gold 50 cells or zero Cut cells mismatch')
        for label, source, token in (
            ('A-button Headbutt', field, 'callba IsJohtoEcruteakHeadbuttTreeAhead'),
            ('party-menu Headbutt', headbutt, 'callba IsJohtoEcruteakHeadbuttTreeAhead'),
            ('Headbutt runtime', native, 'IsJohtoEcruteakHeadbuttTreeAhead::'),
            ('Headbutt region ID', native, 'cp JOHTO_ECRUTEAK_CITY_LOCAL_ID')):
            if token not in source:
                errors.append(f'Ecruteak {label}: reviewed native handler missing')
        row = next(e for e in identities['maps'] if e['local_id']==22)
        if row['feature_status'].get('cut') != 'DEFERRED':
            errors.append('Ecruteak Cut status must remain DEFERRED without Gold Cut trees')
    except (OSError, ValueError, KeyError, StopIteration) as exc:
        errors.append(f'Ecruteak Headbutt Gold verification unavailable: {exc}')

    # These calls guard both bag- and party-menu paths, and the return route.
    for label, source, token in (
        ('water interaction', field, 'call IsSurfTile'),
        ('Surfboard shore', items, 'call IsNextTileShoreOrWater'),
        ('Surfboard collision', items, 'ld hl,TilePairCollisionsWater'),
        ('Dig eligibility', start, 'callba CanUseEscapeRope'),
        ('Escape Rope eligibility', items, 'call CanUseEscapeRope'),
        ('legacy return route', special, 'ld a, [wLastBlackoutMap]'),
        ('legacy map snapshot', home, 'ld [wLastMap],a'),
    ):
        if token not in source:
            errors.append(f'{label} preflight call/state removed: {token}')
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp', type=Path, required=True)
    parser.add_argument('--gold', type=Path, required=True)
    args = parser.parse_args()
    errors = audit(args.rpp, args.gold)
    print(json.dumps({'status': 'FAIL' if errors else 'PASS',
                      'errors': errors, 'surf_enabled_maps': ['JOHTO_ROUTE_32', 'JOHTO_UNION_CAVE_1F', 'JOHTO_ROUTE_35', 'JOHTO_RUINS_OF_ALPH_LOCAL_ID', 'JOHTO_ECRUTEAK_CITY_LOCAL_ID'],
                      'dig_escape_rope_enabled': ['JOHTO_UNION_CAVE_1F'],
                      'phone_verified': False}, ensure_ascii=False, indent=2))
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
