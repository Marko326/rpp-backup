# REF-337｜Ecruteak / Mahogany Pokémon Center arrival Warp fix

## User-reported symptoms
- Ecruteak City: entering the Pokémon Center transitions to a black/empty room.
- Mahogany Town: entering the Pokémon Center places the player on the right-hand carpet rather than the left-hand carpet.

## Root cause
The runtime map event has two distinct Warp concepts:

1. The event's **list position** is the source-map ordinal saved as `wWarpedFromWhichWarp`. `JohtoRegisteredWarpRoutes` uses that ordinal to resolve the destination stable map ID.
2. The event's **third byte** is the destination map's Warp ID. `WarpFound1` copies it into `wDestinationWarpID`, which selects an arrival Warp in the target map.

These values are not interchangeable. The previous audit checked the registered source ordinal and target map ID, but did not check the target Warp ID written by the outdoor RuntimeObjects event.

## Minimal runtime correction
- `data/johto_corridor_runtime_294.asm`: Ecruteak City `(27,23)` remains source ordinal 4 (the fifth active runtime warp event), but its destination Warp ID changes `4 -> 0`.
- `data/johto_east_runtime_300.asm`: Mahogany Town `(13,15)` remains source ordinal 1 (the second active runtime warp event), but its destination Warp ID changes `1 -> 0`.
- Both target center maps expose two active 1F carpets; destination Warp ID 0 selects the first/left carpet. Gold's corresponding city doors both target center Warp #1.
- Keep the registered source ordinals Ecruteak=4 and Mahogany=1, the two indoor exit routes, and their town return destination IDs unchanged.

## Regression coverage
`tools/johto_batch_centers_336_audit.py` now checks the exact RuntimeObjects event order and destination Warp IDs. `tools/tests/test_johto_batch_centers_336.py` injects the two original wrong values and requires both to fail. Gold reference validation confirms both outdoor doors have `destination_warp_number == 1`.

## Verification boundary
Static migration audit, Warp-arrival audit, Pokecenter audits, focused unit tests, and patch replay are source-level checks only. No ROM was assembled or linked in this change. The user must rebuild Red/Blue/TEST and verify ROM0 >= 64 bytes, relevant ROMX bank headroom, Ecruteak entry no longer black-screens, Mahogany entry lands on the left carpet, and both indoor carpets still return to the correct town.
