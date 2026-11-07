"""Restore REF-345's deliberately closed registry in a temporary test fixture.

These staging tests must keep rejecting premature opening, but the live
REF-348 project *correctly* has both floors active.  Never mutate the real
worktree or weaken the historical negative cases.
"""
from pathlib import Path


def restore_closed_stage(root: Path) -> None:
    p = root / 'constants/region_map_constants.asm'
    text = p.read_text()
    assert 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 63' in text
    p.write_text(text.replace('DEF NUM_JOHTO_ACTIVE_MAPS EQU 63',
                              'DEF NUM_JOHTO_ACTIVE_MAPS EQU 61'))

    p = root / 'data/johto_stable_id_slots.asm'
    text = p.read_text()
    before = 'JOHTO_INVALID_ACTIVE_SLOT, 61, 62, JOHTO_INVALID_ACTIVE_SLOT'
    after = 'JOHTO_INVALID_ACTIVE_SLOT, JOHTO_INVALID_ACTIVE_SLOT, JOHTO_INVALID_ACTIVE_SLOT, JOHTO_INVALID_ACTIVE_SLOT'
    assert before in text
    p.write_text(text.replace(before, after, 1))

    p = root / 'engine/johto_pilot_runtime.asm'
    text = p.read_text()
    begin = text.index('JohtoRegisteredWarpRoutes::')
    end = text.index('JohtoRegisteredWarpRoutesEnd::', begin)
    region = text[begin:end]
    region = '\n'.join(line for line in region.splitlines()
                       if not (line.strip().startswith('db MAP_REGION_JOHTO,')
                               and 'JOHTO_BURNED_TOWER_' in line)) + '\n'
    p.write_text(text[:begin] + region + text[end:])

    p = root / 'data/game_version.asm'
    text = p.read_text()
    import re
    match = re.search(r'(?m)^\s*db "REF-\d{3}[A-Z]?@"$', text)
    assert match is not None
    p.write_text(text[:match.start()] + 'db "REF-344@"' + text[match.end():])
