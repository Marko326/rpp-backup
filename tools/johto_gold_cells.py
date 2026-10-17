#!/usr/bin/env python3
"""Shared, read-only Gold 16x16 collision/quadrant decoding.

This is data decoding, not a gameplay collision or ROM implementation.
"""
from pathlib import Path
import re


def decode_cells(layout: bytes, metatiles: bytes, collision: str,
                 width_blocks: int, height_blocks: int,
                 *, graphic_slots: int = 96) -> list[dict]:
    """Return Gold quadrants with role, image ID and four 8x8 graphic IDs.

    Reject malformed source before indexing it; callers add map-specific
    geometry/behavior assertions independently.
    """
    rows = [tuple(v.strip() for v in raw.split(','))
            for raw in re.findall(r'\btilecoll\s+([^;\n]+)', collision)]
    if (len(layout) != width_blocks * height_blocks or
            len(metatiles) != 128 * 16 or len(rows) != 128 or
            any(len(row) != 4 or not all(row) for row in rows) or
            any(block >= 128 for block in layout)):
        raise ValueError('invalid Gold layout/metatiles/tilecoll table')
    cells = []
    for y in range(height_blocks * 2):
        for x in range(width_blocks * 2):
            block = layout[(y // 2) * width_blocks + x // 2]
            quadrant = (y % 2) * 2 + x % 2
            offset = block * 16 + (y % 2) * 8 + (x % 2) * 2
            graphics = tuple(metatiles[offset + i] for i in (0, 1, 4, 5))
            if max(graphics) >= graphic_slots:
                raise ValueError(f'Gold image exceeds {graphic_slots} slots: {(x, y)}')
            cells.append(dict(x=x, y=y, role=rows[block][quadrant],
                              image_id=graphics[2], block_id=block,
                              graphics=graphics))
    return cells


def read_route33(gold: Path) -> tuple[bytes, bytes, list[dict]]:
    """Load the same immutable Gold Route33 source for all three audits."""
    gold = Path(gold)
    layout = (gold / 'maps/Route33.blk').read_bytes()
    metatiles = (gold / 'data/tilesets/johto_modern_metatiles.bin').read_bytes()
    collision = (gold / 'data/tilesets/johto_modern_collision.asm').read_text()
    return layout, metatiles, decode_cells(layout, metatiles, collision, 10, 9)
