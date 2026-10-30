# FIX-5.62.256 — Restore Gold-directed Ruins ledges

## Root cause

The previous FIX-255 change tried to repair the Ruins left corner by adding a
generic compact-tile pair (`$06 -> $3B`) to a Ruins-only pair table. This was
the wrong abstraction for this map. Ruins reuses compact visual/collision tile
IDs across different Gold source coordinates, and Gold marks some HOP cells
whose two-cell landing is still blocked.

The older NPC reference branch already had the correct map-specific contract:
`HandleLedges` dispatches Ruins to a coordinate + facing-direction whitelist
and then calls the shared `.foundMatch` executor. The current branch had
accidentally dropped that coordinate whitelist while porting the south exterior.

## Gold source contract

Gold `RuinsOfAlphOutside` has 14 HOP collision cells but 16 physically valid
directed jumps. Composite corner roles allow more than one direction from the
same coordinate:

- `(5,30)` is `HOP_DOWN_LEFT`: DOWN and LEFT are both valid.
- `(10,30)` is `HOP_DOWN_RIGHT`: DOWN and RIGHT are both valid.
- `(8,32)` is `HOP_DOWN_RIGHT`: DOWN and RIGHT are both valid.

Gold also labels `(9,30)` as `HOP_DOWN`, but the landing cell `(9,32)` is WALL.
That direction must not trigger. The coordinate table intentionally omits it.

The exact 16 entries are ported from the old NPC branch's `.ruinsHops` table
and independently recomputed from Gold collision roles, the intervening wall,
and the landing / downhill-chain geometry.

## Runtime change

- Ruins dispatches to `JohtoAlphSouthHops`, not a generic tile-pair table.
- The handler compares `wXCoord`, `wYCoord`, and `wPlayerDirection`, converts
  the matched direction to the D-pad mask, then reuses the existing shared
  `.foundMatch` animation / simulated-input executor.
- Route29, Route30, Route31, Route32, VioletCity, and Kanto pair tables are
  unchanged.
- The FIX-255 Select-input preservation remains unchanged.
- No map layout, graphics, Surf, Cut, Warp, SRAM, or NPC script changes.

## Static verification and acceptance boundary

The new test compares all 16 entries to the safe Gold-derived direction set,
checks the unsafe `(9,30,DOWN)` negative case, verifies composite left/right
corners, and ensures the Select fix and other map pair tables remain present.
The Field Moves audit now verifies the coordinate table against Gold geometry
rather than merely checking that a Ruins table exists.

## User acceptance

The user has reported that FIX-256 was tested on device and works. This is a
user-reported acceptance result; the assistant did not build/link the ROM or
run a phone/emulator. The accepted behavior is the coordinate/direction table
above, including the blocked `(9,30,DOWN)` landing. The current static tests
remain separate from that device report.
