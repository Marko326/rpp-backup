#!/usr/bin/env python3
"""REF-323: Gold Route44/Blackthorn border and Mahogany roof-on-seam audit.

Independent of the optional full pokegold source tree; checks executable
palette-selection path and runtime object border, not only matching .blk hashes.
This is a static source guard, not proof of a rendered emulator frame.
"""
from __future__ import annotations
from pathlib import Path
import re


def audit(root: Path, gold_root: Path | None = None,
          changes: dict[str, str | bytes] | None = None) -> dict:
    root = Path(root)
    changes = changes or {}
    checks = []

    def read(rel: str) -> str:
        item = changes.get(rel)
        if item is None:
            return (root / rel).read_text(encoding='utf-8')
        if isinstance(item, bytes):
            return item.decode('utf-8')
        return item

    def check(name: str, ok: bool):
        checks.append({'name': name, 'passed': bool(ok)})

    def border_object(src: str, label: str) -> str | None:
        match = re.search(r'(?m)^' + re.escape(label)
                          + r'::\s*\n\s*db\s+(\$[0-9a-fA-F]{2})\b', src)
        return match.group(1).lower() if match else None

    road = read('data/johto_route44_runtime_324.asm')
    town = read('data/johto_blackthorn_runtime_326.asm')
    pal = read('color/loadpalettes.asm')
    check('route44_gold_rock_border',
          border_object(road, 'JohtoRoute44RuntimeObjects') == '$71')
    check('blackthorn_gold_rock_border',
          border_object(town, 'JohtoBlackthornRuntimeObjects') == '$71')

    # Route44's view may still contain Mahogany roofs. The roof palette is
    # selected on CURRENT map changes, not per tile's owning source map.
    selection = pal.split('ApplyJohtoGoldRoofPalette269:', 1)[-1].split('.newbark', 1)[0]
    check('route44_inherits_mahogany_roof_colors', bool(re.search(
        r'(?m)^\s*cp JOHTO_ROUTE_44_LOCAL_ID\s*\n\s*jp z,\s*\.route42\s*$',
        selection)))
    check('mahogany_roof_reference_still_selected', bool(re.search(
        r'(?m)^\s*cp JOHTO_MAHOGANY_TOWN_LOCAL_ID\s*\n\s*jp z,\s*\.route42\s*$',
        selection)))
    check('gold_roof_palette_and_live_copy',
          'call ApplyJohtoGoldRoofPalette269' in pal.split('LoadTilesetPalette:', 1)[-1]
          and 'ld hl,W2_BgPaletteData + 6 * 8' in pal
          and bool(re.search(r'JohtoRoute42RoofPalette300:\s*\n'
                             r'\s*RGB 27,31,27\s*\n\s*RGB 12,19,00\s*\n\s*RGB 06,10,00', pal)))

    if gold_root is not None:
        attrs = (Path(gold_root) / 'data/maps/attributes.asm').read_text(encoding='utf-8')
        for name, identifier in (('Route44', 'ROUTE_44'), ('BlackthornCity', 'BLACKTHORN_CITY')):
            check('gold_reference_' + name + '_border_71',
                  bool(re.search(r'(?m)^\s*map_attributes\s+' + name + r',\s*'
                                 + identifier + r',\s*\$71\s*,', attrs)))

    return {'status': 'PASS_STATIC_ONLY' if all(c['passed'] for c in checks) else 'FAIL',
            'checks': checks, 'errors': [c['name'] for c in checks if not c['passed']]}
