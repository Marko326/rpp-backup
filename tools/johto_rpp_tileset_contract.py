"""Checked Gold Johto to RPP graphics/collision translation contract.

Gold metatile ID $06 consists of LADDER graphics $07. The runtime RPP engine
uses a global passable 8x8 tile list, where $07 must stay blocked because it is
also used by walls. RPP therefore uses pixel/palette-identical $5B ONLY for
this metatile. All other Gold metatiles must remain byte-for-byte unchanged.
No ROM compilation or project mutation is performed here.
"""
from pathlib import Path

# All clone entries must be pixel AND palette identical; $5B is a dedicated
# walkable clone and the others are directional ledge graphics clones.
CLONE_TO_GOLD = {0x20: 0x05, 0x21: 0x4c, 0x30: 0x06, 0x5b: 0x07}
GOLD_TO_RUNTIME_LADDER_BLOCK = 6


def expected_gold_prefix(gold):
    if len(gold) != 128 * 16 or gold[6*16:7*16] != bytes([7])*16:
        raise ValueError('Gold Johto metatiles: missing original LADDER block 06')
    fixed = bytearray(gold)
    fixed[6*16:7*16] = bytes([0x5b])*16
    return bytes(fixed)


def tile_palettes(palette_file):
    import re
    lines = Path(palette_file).read_text().splitlines()
    rows = []
    for line in lines:
        m = re.match(r'^\s*tilepal\s+0\s*,\s*([^;]+)', line)
        if m:
            values = [v.strip() for v in m.group(1).split(',')]
            if len(values) != 8:
                raise ValueError('invalid eight-column Johto tilepal row')
            rows.extend(values)
    if len(rows) != 96:
        raise ValueError('Johto palette must describe exactly 96 tiles')
    return rows


def check_runtime_contract(gold, project):
    """Raise on unknown graphics drift, wrong colors, or blocked Gold ladders."""
    from PIL import Image
    project = Path(project)
    blocks = (project / 'gfx/blocksets/johto.bst').read_bytes()
    if len(blocks) % 16 or len(blocks) // 16 < 133:
        raise ValueError('RPP Johto blockset missing existing variants')
    if blocks[:2048] != expected_gold_prefix(gold):
        raise ValueError('RPP Johto base metatiles differ from documented LADDER-only remap')
    # A new runtime tile number is valid only if there is exactly one consumer.
    uses = [(i//16, i%16) for i, tile in enumerate(blocks) if tile == 0x5b]
    if uses != [(6, i) for i in range(16)]:
        raise ValueError('RPP walkable LADDER $5B leaked to another metatile')
    whitelist = (project / 'gfx/tilesets/johto.tilecoll').read_bytes()
    if not whitelist.endswith(b'\xff') or whitelist.count(0xff) != 1:
        raise ValueError('invalid Johto land collision terminator')
    if 0x5b not in whitelist[:-1] or 0x07 in whitelist[:-1]:
        raise ValueError('Gold LADDER not walkable or wall tile $07 incorrectly walkable')
    im = Image.open(project / 'gfx/tilesets/johto.png').convert('RGBA')
    if im.size != (128,48):
        raise ValueError('unexpected Johto graphics dimensions')
    palettes = tile_palettes(project / 'color/tilesets/johto.asm')
    def img(i):
        return im.crop(((i%16)*8, (i//16)*8, (i%16+1)*8, (i//16+1)*8)).tobytes()
    for clone, original in CLONE_TO_GOLD.items():
        if img(clone) != img(original):
            raise ValueError(f'Johto clone {clone:02X} differs in pixel data')
        if palettes[clone] != palettes[original]:
            raise ValueError(f'Johto clone {clone:02X} differs in CGB palette')
    return blocks


def matches_gold_prefix(gold, runtime):
    """Inventory-only shape check, not a guarantee of gameplay collisions."""
    try:
        return len(runtime) % 16 == 0 and runtime.startswith(expected_gold_prefix(gold))
    except ValueError:
        return False


def gold_visual_tile(tile):
    return CLONE_TO_GOLD.get(tile, tile)
