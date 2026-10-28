#!/usr/bin/env python3
"""Immutable Gold outdoor-seam reference, separated from legacy RPP ABI checks.

This module validates the user-provided Gold source against the frozen 142-edge
contract. It does NOT audit the current RPP runtime headers or certify gameplay.
"""
from pathlib import Path
import re
from johto_gold_compat import resolve_gold_root

class ConnectionError(ValueError):
    pass


# Immutable *direct overworld seam* contract for the user's pokegold-master.
# All 142 directed edges across 368 Gold maps (including the Kanto reference
# edges); DOOR/WARP links are not seamless connections and remain the domain of
# the existing gatehouse/door audit tools. This is authoritative, NOT a list
# of maps that RPP has implemented. Do not edit entries merely to make a test
# pass: compare with original Gold and review the map topology first.
GOLD_DIRECT_SEAMS = """\
NewBarkTown west Route29 0
NewBarkTown east Route27 0
CherrygroveCity north Route30 5
CherrygroveCity east Route29 0
VioletCity south Route32 0
VioletCity west Route36 0
VioletCity east Route31 9
AzaleaTown west Route34 -18
AzaleaTown east Route33 0
CianwoodCity east Route41 0
GoldenrodCity north Route35 5
GoldenrodCity south Route34 5
OlivineCity north Route39 5
OlivineCity west Route40 9
EcruteakCity south Route37 5
EcruteakCity west Route38 5
EcruteakCity east Route42 9
MahoganyTown north Route43 0
MahoganyTown west Route42 0
MahoganyTown east Route44 0
LakeOfRage south Route43 5
BlackthornCity south Route45 0
BlackthornCity west Route44 9
SilverCaveOutside east Route28 9
Route26 west Route27 45
Route27 west NewBarkTown 0
Route27 east Route26 -45
Route28 west SilverCaveOutside -9
Route29 north Route46 10
Route29 west CherrygroveCity 0
Route29 east NewBarkTown 0
Route30 north Route31 -10
Route30 south CherrygroveCity -5
Route31 south Route30 10
Route31 west VioletCity -9
Route32 north VioletCity 0
Route32 south Route33 0
Route33 north Route32 0
Route33 west AzaleaTown 0
Route34 north GoldenrodCity -5
Route34 east AzaleaTown 18
Route35 north Route36 0
Route35 south GoldenrodCity -5
Route36 north Route37 10
Route36 south Route35 0
Route36 east VioletCity 0
Route37 north EcruteakCity -5
Route37 south Route36 -10
Route38 west Route39 0
Route38 east EcruteakCity -5
Route39 south OlivineCity -5
Route39 east Route38 0
Route40 south Route41 -15
Route40 east OlivineCity -9
Route41 north Route40 15
Route41 west CianwoodCity 0
Route42 west EcruteakCity -9
Route42 east MahoganyTown 0
Route43 north LakeOfRage -5
Route43 south MahoganyTown 0
Route44 west MahoganyTown 0
Route44 east BlackthornCity -9
Route45 north BlackthornCity 0
Route45 west Route46 36
Route46 south Route29 -10
Route46 east Route45 -36
PewterCity south Route2 5
PewterCity east Route3 5
Route2 north PewterCity -5
Route2 south ViridianCity -5
ViridianCity north Route2 5
ViridianCity south Route1 10
ViridianCity west Route22 4
Route22 east ViridianCity -4
Route1 north ViridianCity -10
Route1 south PalletTown 0
PalletTown north Route1 0
PalletTown south Route21 0
Route21 north PalletTown 0
Route21 south CinnabarIsland 0
CinnabarIsland north Route21 0
CinnabarIsland east Route20 0
Route20 west CinnabarIsland 0
Route20 east Route19 -9
Route19 north FuchsiaCity 0
Route19 west Route20 9
FuchsiaCity south Route19 0
FuchsiaCity west Route18 7
FuchsiaCity east Route15 9
Route18 west Route17 -38
Route18 east FuchsiaCity -7
Route17 north Route16 0
Route17 east Route18 38
Route16 south Route17 0
Route16 east CeladonCity -9
CeladonCity west Route16 9
CeladonCity east Route7 5
Route7 west CeladonCity -5
Route7 east SaffronCity -9
Route15 west FuchsiaCity -9
Route15 east Route14 -9
Route14 north Route13 0
Route14 west Route15 9
Route13 north Route12 20
Route13 south Route14 0
Route12 north LavenderTown 0
Route12 south Route13 -20
Route12 west Route11 9
Route11 west VermilionCity 0
Route11 east Route12 -9
LavenderTown north Route10South 0
LavenderTown south Route12 0
LavenderTown west Route8 0
VermilionCity north Route6 5
VermilionCity east Route11 0
Route6 north SaffronCity -5
Route6 south VermilionCity -5
SaffronCity north Route5 5
SaffronCity south Route6 5
SaffronCity west Route7 9
SaffronCity east Route8 9
Route5 north CeruleanCity -5
Route5 south SaffronCity -5
CeruleanCity north Route24 6
CeruleanCity south Route5 5
CeruleanCity west Route4 5
CeruleanCity east Route9 9
Route9 south Route10North 20
Route9 west CeruleanCity -9
Route24 north Route25 0
Route24 south CeruleanCity -6
Route25 south Route24 0
Route3 west PewterCity -5
Route3 east Route4 0
Route4 west Route3 0
Route4 east CeruleanCity -5
Route8 west SaffronCity -9
Route8 east LavenderTown 0
Route10North north Route9 -20
Route10North south Route10South 0
Route10South north Route10North 0
Route10South south LavenderTown 0
"""

# Original Gold uses direct outdoor seams at these places, while this RPP
# project intentionally connects them through independently registered gates
# and forest routes. Both ends may exist without a direct RPP seam.
# This exception set is *not* a license to omit any other registered edge.
GATE_REPLACED_DIRECT_SEAMS = {
    ('AzaleaTown', 'west', 'Route34'),       # via Ilex Forest / Route34 gate
    ('Route34', 'east', 'AzaleaTown'),
    ('GoldenrodCity', 'north', 'Route35'),  # via Route35GoldenrodGate
    ('Route35', 'south', 'GoldenrodCity'),
}


def frozen_gold_direct_seams():
    result = {}
    for row in GOLD_DIRECT_SEAMS.splitlines():
        parts = row.split()
        if len(parts) != 4 or parts[1] not in ('north', 'south', 'west', 'east'):
            raise ConnectionError('Invalid frozen Gold seam contract: '+row)
        current, direction, target, offset = parts
        key = (current, direction)
        if key in result:
            raise ConnectionError('Duplicate frozen Gold seam: '+str(key))
        result[key] = (target, int(offset))
    if len(result) != 142:
        raise ConnectionError(f'Frozen Gold seams incomplete: {len(result)} != 142')
    reverse = {'north':'south', 'south':'north', 'west':'east', 'east':'west'}
    for (current,direction),(target,offset) in result.items():
        if result.get((target,reverse[direction])) != (current,-offset):
            raise ConnectionError(f'Gold seam missing reverse: {current} {direction}->{target}')
    return result


def check_frozen_gold_source(gold_root):
    """Independently compare ALL Gold source seams to the frozen 142 records.

    The Gold source is needed for .blk geometry anyway; absent/modified Gold
    must not allow the all-active release gate to claim full coverage.
    """
    gold_root = resolve_gold_root(gold_root, require_core=False)
    path = gold_root / 'data/maps/attributes.asm'
    current = None
    entries = set()
    seen = {}
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.split(';', 1)[0].strip()
        m = re.match(r'^map_attributes\s+(\w+)\s*,', line)
        if m:
            current = m.group(1)
            if current in entries:
                raise ConnectionError('Duplicate Gold map attributes: '+current)
            entries.add(current)
        if line.startswith('connection ') and current is not None:
            m = re.fullmatch(r'connection\s+(north|south|west|east),\s*(\w+),\s*(\w+),\s*([+-]?\d+)', line)
            if not m or current is None:
                raise ConnectionError('Unparseable Gold connection: '+line)
            direction,target,unused_symbol,offset=m.groups()
            key=(current,direction)
            if key in seen:
                raise ConnectionError('Duplicate Gold connection: '+str(key))
            seen[key]=(target,int(offset))
    if len(entries) != 368:
        raise ConnectionError(f'Gold attributes: expected 368 maps, found {len(entries)}')
    frozen=frozen_gold_direct_seams()
    if seen != frozen:
        missing=sorted(set(frozen)-set(seen))
        extra=sorted(set(seen)-set(frozen))
        changed=sorted(k for k in seen.keys() & frozen.keys() if seen[k]!=frozen[k])
        raise ConnectionError(f'Gold direct connection contract mismatch: missing={missing[:4]} '
                              f'extra={extra[:4]} changed={[(k,seen[k],frozen[k]) for k in changed[:4]]}')
    if any((a,d) not in frozen or frozen[(a,d)][0]!=b
           for a,d,b in GATE_REPLACED_DIRECT_SEAMS):
        raise ConnectionError('Gate-replaced Gold seam exceptions differ from frozen Gold')
    return frozen
