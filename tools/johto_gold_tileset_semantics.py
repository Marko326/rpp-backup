#!/usr/bin/env python3
"""Resolve Gold tileset Meta/Coll files through the actual source labels.

Do not infer filenames from TILESET_* names. Gold deliberately aliases some
resources (for example TILESET_DARK_CAVE shares cave metatiles/collision).
This helper is read-only and exists so batch migration tools fail closed on
source semantics instead of silently guessing a path.
"""
from __future__ import annotations

import re
from pathlib import Path

try:
    from johto_gold_compat import resolve_gold_root
except ImportError:
    from tools.johto_gold_compat import resolve_gold_root


def _symbol_for_tileset(tileset: str) -> str:
    if not tileset.startswith('TILESET_'):
        raise ValueError(f'not a Gold TILESET_* name: {tileset}')
    return 'Tileset' + ''.join(part.title() for part in tileset.removeprefix('TILESET_').split('_'))


def _resolve_after_label(text: str, label: str, directive: str) -> str:
    lines = text.splitlines()
    starts = [i for i, line in enumerate(lines)
              if re.fullmatch(r'\s*' + re.escape(label) + r'::{0,1}\s*', line)]
    if len(starts) != 1:
        raise ValueError(f'Gold tileset label missing/duplicate: {label}')
    for line in lines[starts[0] + 1:]:
        # Consecutive labels are aliases for the same following resource.
        stripped = line.split(';', 1)[0].strip()
        m = re.fullmatch(directive + r'\s+"([^"]+)"', stripped)
        if m:
            return m.group(1)
        if stripped.startswith('SECTION '):
            break
    raise ValueError(f'Gold tileset resource not found after {label}')


def resolve_tileset_resources(gold_root: Path, tileset: str) -> dict[str, str]:
    gold = resolve_gold_root(gold_root)
    symbol = _symbol_for_tileset(tileset)
    gfx = (gold / 'gfx/tilesets.asm').read_text(encoding='utf-8', errors='replace')
    meta = _resolve_after_label(gfx, symbol + 'Meta', 'INCBIN')
    coll = _resolve_after_label(gfx, symbol + 'Coll', 'INCLUDE')
    return {'symbol': symbol, 'metatiles': meta, 'collision': coll}


def collision_rows(gold_root: Path, tileset: str) -> list[tuple[str, str, str, str]]:
    gold = resolve_gold_root(gold_root)
    rel = resolve_tileset_resources(gold, tileset)['collision']
    text = (gold / rel).read_text(encoding='utf-8', errors='replace')
    rows = []
    for raw in re.findall(r'\btilecoll\s+([^;\n]+)', text):
        parts = tuple(part.strip() for part in raw.split(','))
        if len(parts) != 4 or not all(parts):
            raise ValueError(f'invalid Gold tilecoll row in {rel}: {raw}')
        rows.append(parts)
    if not rows:
        raise ValueError(f'no Gold tilecoll rows found: {rel}')
    return rows
