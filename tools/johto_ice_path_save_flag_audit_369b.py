#!/usr/bin/env python3
"""REF-369B stage-1 audit: Ice Path save-event ownership and migration safety.

This is a source audit only. It does not assemble ROM or prove device behavior.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

EVENTS = 'constants/event_constants.asm'
WRAM = 'wram.asm'
B1 = 'data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm'
B2 = 'data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm'
ESCAPE = 'engine/johto_ice_path_escape_368d.asm'
DARK_CAVE = 'engine/johto_dark_cave_stage2.asm'
VERSION = 'data/game_version.asm'

# event index, absolute WRAM byte, bit. The event index is relative to the
# beginning of wEventFlags, not a WRAM address and not a byte offset by itself.
EXPECTED = {
    'EVENT_SEAFOAM2_BOULDER1_DOWN_HOLE': (0x438, 0xD852, 0),
    'EVENT_SEAFOAM2_BOULDER2_DOWN_HOLE': (0x439, 0xD852, 1),
    'EVENT_JOHTO_ICE_PATH_PIT_1_FILLED': (0x43A, 0xD852, 2),
    'EVENT_JOHTO_ICE_PATH_PIT_2_FILLED': (0x43B, 0xD852, 3),
    'EVENT_JOHTO_ICE_PATH_PIT_3_FILLED': (0x43C, 0xD852, 4),
    'EVENT_JOHTO_ICE_PATH_PIT_4_FILLED': (0x43D, 0xD852, 5),
    'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_A': (0x43E, 0xD852, 6),
    'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_B': (0x43F, 0xD852, 7),
    'EVENT_SEAFOAM3_BOULDER1_DOWN_HOLE': (0x440, 0xD853, 0),
    'EVENT_SEAFOAM3_BOULDER2_DOWN_HOLE': (0x441, 0xD853, 1),
    'EVENT_9CA': (0x442, 0xD853, 2),  # Ice Path outdoor escape anchor A
    'EVENT_9CB': (0x443, 0xD853, 3),  # Ice Path outdoor escape anchor B
    'EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED': (0x444, 0xD853, 4),
    'EVENT_JOHTO_ICE_PATH_BOULDER_2_DROPPED': (0x445, 0xD853, 5),
    'EVENT_JOHTO_ICE_PATH_BOULDER_3_DROPPED': (0x446, 0xD853, 6),
    'EVENT_JOHTO_ICE_PATH_BOULDER_4_DROPPED': (0x447, 0xD853, 7),
    'EVENT_SEAFOAM4_BOULDER1_DOWN_HOLE': (0x448, 0xD854, 0),
    'EVENT_SEAFOAM4_BOULDER2_DOWN_HOLE': (0x449, 0xD854, 1),
    'EVENT_JOHTO_FLY_OLIVINE': (0x44A, 0xD854, 2),
    'EVENT_JOHTO_FLY_CIANWOOD': (0x44B, 0xD854, 3),
    'EVENT_JOHTO_FLY_LAKE_OF_RAGE': (0x44C, 0xD854, 4),
    'EVENT_JOHTO_FLY_BLACKTHORN': (0x44D, 0xD854, 5),
    'EVENT_9D6': (0x44E, 0xD854, 6),  # Dark Cave outdoor escape anchor A
    'EVENT_9D7': (0x44F, 0xD854, 7),  # Dark Cave outdoor escape anchor B
    'EVENT_JOHTO_FLY_ECRUTEAK': (0x450, 0xD855, 0),
    'EVENT_JOHTO_FLY_MAHOGANY': (0x451, 0xD855, 1),
    'EVENT_BEAT_ARTICUNO': (0x452, 0xD855, 2),
    'EVENT_JOHTO_FLY_NEW_BARK': (0x453, 0xD855, 3),
    'EVENT_JOHTO_FLY_CHERRYGROVE': (0x454, 0xD855, 4),
    'EVENT_JOHTO_FLY_VIOLET': (0x455, 0xD855, 5),
    'EVENT_JOHTO_FLY_AZALEA': (0x456, 0xD855, 6),
    'EVENT_JOHTO_FLY_GOLDENROD': (0x457, 0xD855, 7),
}
EVENT_RE = re.compile(
    r'^\s*const\s+(\w+)\s*;\s*current\s+([0-9A-F]{3}),\s*'
    r'\((D[0-9A-F]{3}),\s*bit\s+([0-7])\)\s*$'
)


def audit(root: Path, overrides: dict[str, str | bytes] | None = None) -> list[str]:
    root = Path(root)
    overrides = overrides or {}

    def read(name: str) -> str:
        value = overrides.get(name)
        if isinstance(value, bytes):
            return value.decode()
        if isinstance(value, str):
            return value
        return (root / name).read_text()

    errors: list[str] = []
    def ck(ok: bool, message: str) -> None:
        if not ok:
            errors.append(message)

    events_text = read(EVENTS)
    parsed: dict[str, tuple[int, int, int]] = {}
    all_indices: list[int] = []
    region_indices: list[int] = []
    for line in events_text.splitlines():
        match = EVENT_RE.match(line)
        if not match:
            continue
        name, idx_hex, address_hex, bit_text = match.groups()
        idx, address, bit = int(idx_hex, 16), int(address_hex, 16), int(bit_text)
        parsed[name] = (idx, address, bit)
        all_indices.append(idx)
        if 0x438 <= idx <= 0x457:
            region_indices.append(idx)
        # Every current comment must match the actual event-array arithmetic.
        ck(address == 0xD7CB + idx // 8 and bit == idx % 8,
           f'{name} event annotation does not match wEventFlags base/index')

    ck(len(all_indices) == len(set(all_indices)), 'active event indices contain an alias/duplicate')
    ck(region_indices == list(range(0x438, 0x458)),
       'D852-D855 active event range is not contiguous or has a duplicate/missing slot')
    for name, expected in EXPECTED.items():
        ck(parsed.get(name) == expected, f'{name} must own event/address/bit {expected}, got {parsed.get(name)}')

    b1, b2 = read(B1), read(B2)
    wram = read(WRAM)
    escape, dark = read(ESCAPE), read(DARK_CAVE)
    version = read(VERSION)

    ck('wEventFlags:: ; d7cb\n\tds 139' in wram,
       'wEventFlags base/139-byte save layout must not move or resize')
    ck('DEF JOHTO_ICE_PATH_PIT_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_PIT_1_FILLED / 8' in b1 and
       'DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED / 8' in b1,
       'Ice Path PIT/source flags must derive from their named events, not hand-written byte offsets')
    ck('DEF JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B EQU $c0' in b1,
       'migration signature must remain the reserved D852 bits 6..7')
    for name in (
        'EVENT_JOHTO_ICE_PATH_PIT_1_FILLED', 'EVENT_JOHTO_ICE_PATH_PIT_2_FILLED',
        'EVENT_JOHTO_ICE_PATH_PIT_3_FILLED', 'EVENT_JOHTO_ICE_PATH_PIT_4_FILLED',
        'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_A', 'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_B',
        'EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED', 'EVENT_JOHTO_ICE_PATH_BOULDER_2_DROPPED',
        'EVENT_JOHTO_ICE_PATH_BOULDER_3_DROPPED', 'EVENT_JOHTO_ICE_PATH_BOULDER_4_DROPPED',
    ):
        ck(name in b1, f'B1F runtime lacks explicit allocation assertion/reference for {name}')

    migration = ''
    if 'JohtoIcePathInitializePitState369B::' in b1:
        migration = b1.split('JohtoIcePathInitializePitState369B::', 1)[1].split(
            'JohtoIcePathB1FHideDropped369B::', 1)[0]
    ck(bool(migration), 'one-time REF-369A save migration routine is missing')
    ck('and JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B' in migration and
       'cp JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B' in migration and
       'and $c3' in migration and 'and $0f' in migration and
       'or JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B' in migration,
       'migration must preserve D852 bits0..1 / D853 bits0..3, clear only old puzzle bits, then set signature')
    ck(migration.count('ld [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B], a') == 1 and
       migration.count('ld [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B], a') == 1 and
       'wEventFlags + 137' not in migration and 'wEventFlags + 138' not in migration and
       'EVENT_9D7 / 8 + 1' not in migration,
       'migration may write only D852/D853; it must never touch D854/D855')
    ck('call JohtoIcePathInitializePitState369B' in
       b1.split('JohtoIcePathB1FScript367K::', 1)[1].split('JohtoIcePathB1FTextPointers367K:', 1)[0],
       'B1F must run save migration before replaying dropped-stone visibility')
    ck('callab JohtoIcePathInitializePitState369B' in
       b2.split('JohtoIcePathB2FMahoganyScript368A::', 1)[1].split('JohtoIcePathB2FMahoganyTextPointers368A:', 1)[0],
       'B2F must run save migration before reading PIT visibility flags')

    ck('db $04, $08, $10, $20' in b1 and 'db $10, $20, $40, $80' in b1,
       'four hole masks must occupy D852 bits2..5 and source-rock masks D853 bits4..7')
    ck('bit 2, a' in b2 and 'bit 3, a' in b2 and 'bit 4, a' in b2 and 'bit 5, a' in b2,
       'B2F deposited-rock visibility must read the four D852 PIT bits 2..5')

    # Existing shared bytes retain their other owners.
    ck('EVENT_9CA / 8' in escape and 'EVENT_9CB' in escape and 'and $0c' in escape,
       'Ice Path outdoor Escape Rope anchors must remain on D853 bits2..3')
    ck('EVENT_9D6 / 8' in dark and 'EVENT_9D7' in dark,
       'Dark Cave outdoor anchors must remain on D854 bits6..7')
    ck(all(name in events_text for name in (
        'EVENT_JOHTO_FLY_ECRUTEAK', 'EVENT_JOHTO_FLY_MAHOGANY', 'EVENT_BEAT_ARTICUNO',
        'EVENT_JOHTO_FLY_NEW_BARK', 'EVENT_JOHTO_FLY_CHERRYGROVE',
        'EVENT_JOHTO_FLY_VIOLET', 'EVENT_JOHTO_FLY_AZALEA', 'EVENT_JOHTO_FLY_GOLDENROD')),
       'D855 must retain all eight original Fly/Articuno event owners')


    ice_owned_events = {
        'EVENT_JOHTO_ICE_PATH_PIT_1_FILLED', 'EVENT_JOHTO_ICE_PATH_PIT_2_FILLED',
        'EVENT_JOHTO_ICE_PATH_PIT_3_FILLED', 'EVENT_JOHTO_ICE_PATH_PIT_4_FILLED',
        'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_A', 'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_B',
        'EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED', 'EVENT_JOHTO_ICE_PATH_BOULDER_2_DROPPED',
        'EVENT_JOHTO_ICE_PATH_BOULDER_3_DROPPED', 'EVENT_JOHTO_ICE_PATH_BOULDER_4_DROPPED',
    }
    for asm_path in root.rglob('*.asm'):
        rel = asm_path.relative_to(root).as_posix()
        if rel in {EVENTS, B1}:
            continue
        body = asm_path.read_text(errors='replace')
        for event_name in ice_owned_events:
            ck(event_name not in body,
               f'{event_name} must remain owned only by the Ice Path B1F save module, found in {rel}')

    ice_owned_events = {
        'EVENT_JOHTO_ICE_PATH_PIT_1_FILLED', 'EVENT_JOHTO_ICE_PATH_PIT_2_FILLED',
        'EVENT_JOHTO_ICE_PATH_PIT_3_FILLED', 'EVENT_JOHTO_ICE_PATH_PIT_4_FILLED',
        'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_A', 'EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_B',
        'EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED', 'EVENT_JOHTO_ICE_PATH_BOULDER_2_DROPPED',
        'EVENT_JOHTO_ICE_PATH_BOULDER_3_DROPPED', 'EVENT_JOHTO_ICE_PATH_BOULDER_4_DROPPED',
    }
    for asm_path in root.rglob('*.asm'):
        rel = asm_path.relative_to(root).as_posix()
        if rel in {EVENTS, B1}:
            continue
        body = asm_path.read_text(errors='replace')
        for event_name in ice_owned_events:
            ck(event_name not in body,
               f'{event_name} must remain owned only by the Ice Path B1F save module, found in {rel}')

    active_ice_path = '\n'.join(line.split(';', 1)[0] for line in (b1 + '\n' + b2).splitlines())
    ck('EVENT_9D7 / 8 + 1' not in active_ice_path and 'EVENT_JOHTO_FLY_' not in active_ice_path and
       'EVENT_BEAT_ARTICUNO' not in active_ice_path and 'wEventFlags + 138' not in active_ice_path,
       'Ice Path code must not alias or write the D855 Fly/Articuno event byte')

    # REF-369S player PIT activation does not change save flag ownership.
    ck('db 2, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR' in b1 and
       'db 13, 12, 5, JOHTO_REGISTERED_WARP_SELECTOR' in b1,
       'Gold four player PIT sources must remain valid independently of D852/D853')
    land_policy = b1.split('JohtoIcePathB1FLandDecision367K::', 1)[1].split('JohtoIcePathB1FIsIce368F::', 1)[0]
    ck('cp 3 ; PIT: Gold B1F has exactly four' in land_policy and 'jp z, .allow' in land_policy,
       'player PIT collision must allow only the four Gold registered source cells')
    ck(any(f'db "{v}"' in version for v in ('REF-369B@', 'REF-369C@', 'REF-369E@', 'REF-369F@', 'REF-369G@', 'REF-369H@', 'REF-369I@', 'REF-369O@', 'REF-369@')),
       'event ownership still requires REF-369B@ or REF-369C@ development label')
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    errors = audit(args.root)
    for error in errors:
        print('FAIL:', error)
    if not errors:
        print('PASS_STATIC_ONLY: D852-D855 ownership, REF-369A migration isolation, and player PIT state isolation')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
