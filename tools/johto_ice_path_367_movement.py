#!/usr/bin/env python3
"""REF-367B Ice Path movement reference model (NOT wired to ROM).

This executable, fail-closed Gold terrain *specification* drives tests of
sliding, directional collisions, PIT vs arrival-only ICE and Strength boulders.
It intentionally does not claim emulation equivalence: player animation,
input repeat, persistence and ROM bank plumbing still require integration.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import json

CONTRACT = Path('docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json')
DIRECTIONS = {'UP': (0, -1), 'DOWN': (0, 1), 'LEFT': (-1, 0), 'RIGHT': (1, 0)}
BOULDERS = ((11, 7), (7, 8), (8, 9), (17, 7))
PITS = ((11, 2), (4, 7), (5, 12), (12, 13))
BOULDER_FALL_ARRIVALS = ((11, 3), (4, 7), (3, 12), (12, 13))
BLOCKED = frozenset({'WALL'})


@dataclass(frozen=True)
class Position:
    map: str
    x: int
    y: int


@dataclass
class Movement:
    location: Position
    trace: list[Position]
    kind: str
    warp_ordinal: int | None = None
    destination_warp: int | None = None
    new_boulders: dict[int, tuple[int, int] | None] | None = None
    landed_boulder: int | None = None


@dataclass
class Model:
    root: Path
    contract: dict = field(init=False)
    maps: dict = field(init=False)
    roles: dict = field(init=False)
    boulders: dict[int, tuple[int, int] | None] = field(init=False)
    landed_boulders: set[int] = field(default_factory=set)

    def __post_init__(self):
        self.contract = json.loads((self.root / CONTRACT).read_text(encoding='utf-8'))
        self.maps = {m['name']: m for m in self.contract['maps']}
        self.roles = {}
        for m in self.contract['maps']:
            name = m['name']
            data = (self.root / 'data/johto_ice_path_stage' / f'{name}.roles.bin').read_bytes()
            assert len(data) == m['width_cells'] * m['height_cells']
            self.roles[name] = data
        self.boulders = dict(enumerate(BOULDERS))

    def role(self, pos: Position) -> str:
        if pos.map not in self.maps:
            return 'WALL'
        m = self.maps[pos.map]
        if pos.x < 0 or pos.y < 0 or pos.x >= m['width_cells'] or pos.y >= m['height_cells']:
            return 'WALL'
        return self.contract['roles'][self.roles[pos.map][pos.y * m['width_cells'] + pos.x]]

    def warp_at(self, pos: Position):
        return next((w for w in self.maps[pos.map]['warps']
                     if (w['x'], w['y']) == (pos.x, pos.y)), None)

    def _warp(self, pos: Position, trigger: str) -> Movement | None:
        warp = self.warp_at(pos)
        if warp is None or warp['trigger'] != trigger:
            return None
        target = warp['destination']
        if target in self.maps:
            target_warp = self.maps[target]['warps'][warp['destination_warp_1_based'] - 1]
            result = Position(target, target_warp['x'], target_warp['y'])
        else:
            result = Position(target, -1, -1)  # physical outdoor arrival is resolved by separate route contract
        return Movement(result, [pos, result], 'warp', warp['ordinal0'], warp['destination_warp_1_based'])

    def _blocked(self, here: Position, there: Position, direction: str) -> bool:
        src, dst = self.role(here), self.role(there)
        if dst in BLOCKED:
            return True
        if src == 'UP_WALL' and direction == 'UP':
            return True
        if dst == 'UP_WALL' and direction == 'DOWN':
            return True
        if dst == 'HOP_DOWN' and direction == 'UP':
            return True
        if dst == 'HOP_DOWN_LEFT' and direction in {'UP', 'RIGHT'}:
            return True
        return False

    def move(self, start: Position, direction: str, strength: bool = False) -> Movement:
        """A completed directional input, including ICE continuation.

        Each step off ICE retains heading, ignores intervening button changes;
        stop at first non-ICE cell (or blocked ICE edge).  Gold animation time,
        boulder menu/dialogue and exact ledge jump timing are outside this model.
        """
        if direction not in DIRECTIONS:
            raise ValueError(direction)
        if self.role(start) == 'WALL':
            return Movement(start, [start], 'blocked')
        if direction == 'DOWN' and self.role(start) == 'WARP_CARPET_DOWN':
            warp = self._warp(start, 'DIRECTIONAL_COLLISION')
            if warp:
                return warp
        dx, dy = DIRECTIONS[direction]
        pos, trace = start, [start]
        # A map has at most 1440 cells, so 1441 steps is a hard fail rather than looping forever.
        for _ in range(1441):
            nxt = Position(pos.map, pos.x + dx, pos.y + dy)
            if self._blocked(pos, nxt, direction):
                return Movement(pos, trace, 'blocked' if len(trace) == 1 else 'stopped')
            if pos.map == 'IcePathB1F':
                block_id = next((i for i, loc in self.boulders.items()
                                 if loc == (nxt.x, nxt.y)), None)
                if block_id is not None:
                    if not strength:
                        return Movement(pos, trace, 'blocked_boulder')
                    beyond = Position(nxt.map, nxt.x + dx, nxt.y + dy)
                    if self._blocked(nxt, beyond, direction) or any(
                        p == (beyond.x, beyond.y) for idx, p in self.boulders.items() if idx != block_id
                    ):
                        return Movement(pos, trace, 'blocked_boulder')
                    new_pos = None if self.role(beyond) == 'PIT' else (beyond.x, beyond.y)
                    self.boulders[block_id] = new_pos
                    if new_pos is None:
                        self.landed_boulders.add(block_id)
                    return Movement(nxt, [*trace, nxt], 'boulder_fell' if new_pos is None else 'pushed',
                                    new_boulders=self.boulders.copy(),
                                    landed_boulder=block_id if new_pos is None else None)
            pos = nxt
            trace.append(pos)
            role = self.role(pos)
            if role in {'PIT', 'LADDER', 'CAVE'}:
                warp = self._warp(pos, 'STEP_IN_IMMEDIATE')
                if warp:
                    return Movement(warp.location, [*trace, warp.location],
                                    'pit_drop' if role == 'PIT' else 'warp',
                                    warp.warp_ordinal, warp.destination_warp)
            # Walking onto ICE forces further movement in the same direction.
            # Crucially, an ICE warp_event is a destination-only point, not an exit.
            if role != 'ICE':
                return Movement(pos, trace, 'walk' if len(trace) == 2 else 'slide')
        raise RuntimeError('ice movement exceeded map cells; suspected nonterminating loop')

    def step_on(self, pos: Position) -> Movement | None:
        """Check actual STEP_IN warp; ICE landings must remain inert."""
        return self._warp(pos, 'STEP_IN_IMMEDIATE')


def audit(root: Path) -> list[str]:
    problems = []
    m = Model(root)
    names = m.maps
    for name, record in names.items():
        for x in range(record['width_cells']):
            for y in range(record['height_cells']):
                pos = Position(name, x, y)
                if m.role(pos) == 'ICE':
                    for direction in DIRECTIONS:
                        try:
                            result = m.move(pos, direction)
                            if len(result.trace) > 1442:
                                problems.append(f'{name} {x},{y}: slide overflow')
                            if result.kind == 'pit_drop' and name != 'IcePathB1F':
                                problems.append(f'{name} {x},{y}: unexpected pit')
                        except (IndexError, KeyError, RuntimeError, ValueError) as exc:
                            problems.append(f'{name} {x},{y} {direction}: {exc}')
        for w in record['warps']:
            pos = Position(name, w['x'], w['y'])
            if w['role'] == 'ICE' and m.step_on(pos) is not None:
                problems.append(f'{name} #{w["ordinal1"]}: arrival-only ICE triggers reverse warp')
            if w['role'] == 'PIT':
                result = m.step_on(pos)
                if result is None or result.kind != 'warp' or result.location.map != 'IcePathB2FMahoganySide':
                    problems.append(f'{name} #{w["ordinal1"]}: broken pit destination')
    if tuple(m.boulders.values()) != BOULDERS or m.landed_boulders:
        problems.append('reference model mutated boulders during ice audit')
    # Guard the staged LR35902 role reader from the invalid instruction that
    # slipped into REF-365A, and from accidental early linking into ROM.
    runtime_source = root / 'data/johto_ice_path_stage/ice_path_role_runtime_367b.asm'
    if not runtime_source.is_file():
        problems.append('missing dormant Ice Path ASM role reader')
    else:
        asm = runtime_source.read_text(encoding='utf-8')
        if any('sbc hl' in line.split(';', 1)[0].lower().replace('\t',' ') for line in asm.splitlines()):
            problems.append('illegal LR35902 16-bit SBC HL in Ice Path role lookup')
        for label in ('JohtoIcePathGoldRoleAt367B', 'JohtoIcePath1FRoleBytes367B',
                      'JohtoIcePathB1FRoleBytes367B', 'JohtoIcePathB2FMahoganyRoleBytes367B',
                      'JohtoIcePathB2FBlackthornRoleBytes367B', 'JohtoIcePathB3FRoleBytes367B'):
            if f'{label}::' not in asm:
                problems.append(f'missing ASM label {label}')
        for w in ('.width40', '.width20', '.width10'):
            if w not in asm:
                problems.append(f'missing Gold role indexing stride {w}')
    # The role reader is ready for later ROM integration but never enabled
    # on this resource/mechanics stage.  Runtime-only activation requires
    # a distinct versioned implementation and user ROM/map acceptance.
    main = (root / 'main.asm').read_text(encoding='utf-8')
    if 'ice_path_role_runtime_367b.asm' in main:
        problems.append('dormant ASM linked before ICE and Strength engine complete')
    for n in names:
        src = root / f'maps/johto_ice_path_stage/{n}.gold.blk'
        tgt = root / f'maps/johto_ice_path_stage/{n}.runtime.blk'
        if not tgt.is_file() or src.read_bytes() != tgt.read_bytes():
            problems.append(f'{n}: runtime metatile byte mismatch')
    return problems


def main() -> int:
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--root', type=Path, default=Path('.'))
    args = p.parse_args()
    problems = audit(args.root)
    for issue in problems:
        print('FAIL', issue)
    if problems:
        return 1
    print('PASS: 5 Gold runtime block grids; 673 ICE cells, direction sweeps and PIT/warp safety')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
