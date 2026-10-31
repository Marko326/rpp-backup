"""ILEX-217 immutable forest HOP clones, independently of source .gold.blk.

Gold's original .blk remains immutable in this project. Mature RPP source
replaces six block positions with four visual/collision clones to enable the
shared tile-pair hop engine; this *intentional* runtime delta must be exact.
"""
CLONED_BLOCKS = {
    26: (28, 40),
    27: (26, 41),
    112: (24, 42),
    176: (25, 43),
    177: (28, 40),
    178: (27, 44),
}


def expected_runtime(gold: bytes) -> bytes:
    if len(gold) != 405:
        raise ValueError('IlexForest Gold block map must be 405 bytes')
    result = bytearray(gold)
    for offset, (original, clone) in CLONED_BLOCKS.items():
        if result[offset] != original:
            raise ValueError(f'IlexForest Gold original differs at {offset}: {result[offset]} != {original}')
        result[offset] = clone
    return bytes(result)
