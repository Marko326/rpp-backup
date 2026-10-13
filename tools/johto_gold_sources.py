#!/usr/bin/env python3
"""Resolve Gold map labels to layout files, including shared INCBIN aliases.

This is a read-only source parser, not a map importer. Fail closed on an
unresolved/unsafe mapping rather than guessing maps/<map name>.blk.
"""
from pathlib import Path
import re

BLOCK_LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)_Blocks:{1,2}$')
BLOCK_FILE = re.compile(r'^INCBIN\s+"(maps/[A-Za-z0-9_./-]+\.blk)"$')


def gold_block_sources(gold):
    """Return {GoldMapName: 'maps/ActualSharedLayout.blk'} from blocks.asm."""
    source = gold / 'data/maps/blocks.asm'
    pending = []
    mapping = {}
    for number, original in enumerate(source.read_text(encoding='utf-8').splitlines(), 1):
        line = original.split(';', 1)[0].strip()
        if not line:
            continue
        label = BLOCK_LABEL.fullmatch(line)
        if label:
            pending.append(label[1])
            continue
        incbin = BLOCK_FILE.fullmatch(line)
        if incbin:
            layout = incbin[1]
            path = Path(layout)
            if ('..' in path.parts or path.is_absolute() or
                    path.parts[0] != 'maps'):
                raise ValueError(f'Unsafe Gold layout at {source}:{number}: {layout}')
            if pending:
                for name in pending:
                    if name in mapping:
                        raise ValueError(f'Duplicate Gold blocks label: {name}')
                    mapping[name] = layout
                pending.clear()
            continue
        if pending:
            raise ValueError(f'Unresolved Gold blocks labels at {source}:{number}: {pending}')
    if pending:
        raise ValueError(f'Unresolved Gold blocks labels at EOF: {pending}')
    if not mapping:
        raise ValueError(f'No Gold blocks found in {source}')
    return mapping
