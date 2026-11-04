#!/usr/bin/env python3
"""REF-339: enumerate ALL active Johto maps, compare outdoor border to Gold.

The compact RPP map starts with the border block in RuntimeObjects.  The
source .blk can be byte-identical and still show an incorrect forest/ocean
outside its physical map.  Gold's outdoor border is authoritative only for
maps using the unchanged JOHTO_PILOT (Gold Johto) blockset.  Other tilesets
remap block IDs and must not be mass-rewritten; enumerate them for review.

Static-only. Does not simulate VBlank/VRAM updates or compile/link a ROM.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from johto_surf_coverage_audit import read_active_maps

# Maintainers should review this exception on the *independent* mature forest
# blockset rather than blindly copying Gold's numeric border block $05.
REVIEWED_REMAP = {'IlexForest': ('JOHTO_ILEX_FOREST', 0x00)}


def audit(root: Path, gold_root: Path, overrides: dict[str, str] | None = None) -> dict[str, Any]:
    root, gold_root = Path(root), Path(gold_root)
    overrides = overrides or {}
    errors: list[str] = []
    warnings: list[str] = []
    rows: list[dict] = []

    def read(relative: str) -> str:
        return overrides.get(relative, (root / relative).read_text(encoding='utf-8'))

    attrs = {
        m.group(1): int(m.group(2), 16)
        for m in re.finditer(
            r'(?m)^\s*map_attributes\s+(\w+)\s*,\s*[^,]+,\s*\$([\da-fA-F]+)\s*,',
            (gold_root / 'data/maps/attributes.asm').read_text(encoding='utf-8'))
    }
    maps = read_active_maps(root)
    descriptors = read('data/johto_header_descriptors.asm').split('JohtoHeaderDescriptors::', 1)[1].split('JohtoHeaderDescriptorsEnd::', 1)[0]
    headers = re.findall(r'(?m)^\s*dw\s+(\w+RuntimeHeader)\s*$', descriptors)
    if len(headers) != len(maps):
        errors.append(f'header cardinality {len(headers)} != active maps {len(maps)}')

    # Runtime headers and their object tables live in multiple source files.
    combined = '\n'.join(read(str(p.relative_to(root))) for p in sorted([*(root / 'data').rglob('*.asm'), *(root / 'engine').rglob('*.asm')]))
    # Avoid scanning tools, docs or Gold reference files, which may contain
    # similarly named historical labels.
    for item, header in zip(maps, headers):
        name = item['map']
        match = re.search(r'(?m)^' + re.escape(header) + r'::\s*\n(?P<body>.*?)(?=^\w[\w.]*::|\Z)', combined, re.S | re.M)
        if not match:
            errors.append(f'{name}: missing runtime header {header}')
            continue
        body = match['body']
        tileset = re.search(r'(?m)^\s*db\s+(JOHTO_\w+)\b', body)
        object_rows = re.findall(r'(?m)^\s*dw\s+(\w+RuntimeObjects)\s*$', body)
        if not tileset or not object_rows:
            errors.append(f'{name}: cannot determine tileset or RuntimeObjects')
            continue
        objects = object_rows[-1]
        match_obj = re.search(r'(?m)^' + re.escape(objects) + r'::\s*\n\s*db\s+\$([\da-fA-F]+)', combined)
        if not match_obj:
            errors.append(f'{name}: missing border byte at {objects}')
            continue
        runtime = int(match_obj[1], 16)
        expected = attrs.get(name)
        if expected is None:
            errors.append(f'{name}: absent from Gold attributes')
            continue
        family = tileset[1]
        if family == 'JOHTO_PILOT':
            verdict = 'PASS' if runtime == expected else 'MISMATCH'
            if runtime != expected:
                errors.append(f'{name}: shared Johto blockset border ${runtime:02x} != Gold ${expected:02x}')
        elif name in REVIEWED_REMAP:
            expected_family, expected_runtime = REVIEWED_REMAP[name]
            verdict = 'REMAP_REVIEWED' if (family, runtime) == (expected_family, expected_runtime) else 'REMAP_CHANGED'
            if verdict == 'REMAP_CHANGED':
                errors.append(f'{name}: independent forest tileset/border contract changed')
        else:
            verdict = 'REMAP_IDENTICAL' if runtime == expected else 'REMAP_REVIEW_NEEDED'
            if verdict == 'REMAP_REVIEW_NEEDED':
                warnings.append(f'{name}: {family} remaps border ${expected:02x}->${runtime:02x}; do not mass-rewrite')
        rows.append(dict(slot=item['slot'], map=name, stable_id=item['stable_id'],
                         tileset=family, gold_border=f'${expected:02x}',
                         runtime_border=f'${runtime:02x}', verdict=verdict))

    # Three visual block families are distinct in the live $FC outdoor blockset.
    # $35 is water art, $05 a forest/tree, and $71 a stone cliff. A copied
    # border value is only safe when its blockset and water collision remain.
    blocks = (root / 'gfx/blocksets/johto.bst').read_bytes()
    water = blocks[0x35*16:(0x35+1)*16]
    forest = blocks[0x05*16:(0x05+1)*16]
    stone = blocks[0x71*16:(0x71+1)*16]
    if not (len(blocks) >= (0x71+1)*16 and set(water) == {0x14} and
            set(forest) == {0x1e, 0x1f, 0x2e, 0x2f, 0x3e, 0x3f} and
            set(stone) == {0x3c}):
        errors.append('shared Johto forest/water/stone block semantic roles changed')

    # The map loader must fill the *whole out-of-map* buffer with the object
    # border before copying the physical map and connection strips.
    loader = read('home/overworld.asm')
    region = loader.split('LoadTileBlockMap::', 1)[-1].split('LoadNorthSouthConnectionsTileMap::', 1)[0]
    if not ('ld a,[wMapBackgroundTile]' in region and '.backgroundTileLoop' in region and
            '.rowLoop' in region and 'callab PatchJohtoBordersAfterBlockLoad300' in region):
        errors.append('out-of-map border fill or post-load renderer changed')
    if loader.count('ld de,wMapBackgroundTile') != 1:
        errors.append('map object -> background block loader changed')

    # Screenshot-specific risk: Cherrygrove is a short (20x9) map.  Simulate
    # each 5x6 block viewport around each of its 142 Gold WATER cells. Verify
    # all indices lie within the 1300-byte block buffer; the SW edge must use
    # water block $35 in all outside-map cells, not forest $05.
    surf = read('engine/johto_violet_field_skills.asm')
    segment = surf.split('JohtoCherrygroveGoldWaterCells::', 1)[-1].split('JohtoCherrygroveGoldWaterCellsEnd::', 1)[0]
    coords = [(int(y), int(x)) for y, x in re.findall(r'(?m)^\s*db\s+(\d+)\s*,\s*(\d+)\s*$', segment)]
    if len(coords) != 142:
        errors.append(f'Cherrygrove WATER table unexpectedly has {len(coords)} cells (expected 142)')
    viewport_count, edge_cells = 0, 0
    for y, x in coords:
        if y >= 18 or x >= 40:
            errors.append(f'Cherrygrove WATER table has off-map coordinate {(x,y)}')
            continue
        row0, col0 = y//2 + 1, x//2 + 1
        for dy in range(5):
            for dx in range(6):
                ry, rx = row0 + dy, col0 + dx
                index = ry * (20 + 2*3) + rx
                if index < 0 or index >= 1300:
                    errors.append(f'Cherrygrove viewport buffer overrun at {(x,y)} -> {index}')
                if (ry < 3 or ry >= 3 + 9 or rx < 3 or rx >= 3 + 20):
                    edge_cells += 1
                viewport_count += 1
    cherrygrove = next((r for r in rows if r['map'] == 'CherrygroveCity'), None)
    if cherrygrove is None or cherrygrove['runtime_border'] != '$35':
        errors.append('Cherrygrove visible out-of-map ocean must use Gold border $35')

    return dict(status='PASS_STATIC_ONLY' if not errors else 'FAIL', active_maps=len(maps),
                outdoor_shared_count=sum(r['tileset']=='JOHTO_PILOT' for r in rows),
                other_tileset_count=sum(r['tileset']!='JOHTO_PILOT' for r in rows),
                water_viewports=len(coords), viewport_blocks=viewport_count,
                outside_viewport_blocks=edge_cells, errors=errors, warnings=warnings,
                rows=rows, note='Static Gold/source and viewport-buffer coverage only; dynamic Surf, CGB VRAM/VBlank and ROM builds not exercised.')


def main() -> int:
    cli=argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--project',type=Path,default=Path('.'))
    cli.add_argument('--gold-root',type=Path,required=True)
    cli.add_argument('--json',action='store_true')
    args=cli.parse_args()
    result=audit(args.project,args.gold_root)
    print(json.dumps(result,ensure_ascii=False,indent=2) if args.json else
          f"{result['status']}: {result['active_maps']} maps, "
          f"{result['outdoor_shared_count']} common-tileset maps, "
          f"{result['water_viewports']} Cherrygrove Surf viewports, "
          f"{len(result['errors'])} errors, {len(result['warnings'])} review notes" )
    return 1 if result['errors'] else 0

if __name__=='__main__':
    sys.exit(main())
