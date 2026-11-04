# REF-338 | Blackthorn City Gold Pokémon Center | DEV candidate

## Verified baseline

Clean user ZIP `REF-337.zip`, branch `常规功能备份`, HEAD `3345afba3ff541e04a73bbf56c8d688786842910`, with no uncommitted source modifications. Development patch only. Confirmed 56 active maps and 131 registered warps before modification.

## Gold-accurate entry and separate warp identities

- Original Gold BlackthornCity `warp_event 21,29,BLACKTHORN_POKECENTER_1F,1` is its **5th Gold event**; other Blackthorn building entries remain inactive.
- The current active runtime city adds **only one** warp, so its source ordinal for `JohtoRegisteredWarpRoutes` is `0`. Its third byte is the **destination** center warp index `0` (the left carpet), not Gold ordinal 5 or source ordinal.
- Original Gold center warp events #1 `warp_event 3,7,BLACKTHORN_CITY,5` and #2 `warp_event 4,7,BLACKTHORN_CITY,5`, plus #3 upstairs. Runtime registers only the two DOWN-facing exits `(3,7)` and `(4,7)` independently, each returning to Blackthorn City active exterior warp 0. Upstairs and storage are still deferred.
- New indoor stable ID is `85` (`JOHTO_BLACKTHORN_POKECENTER_1F_LOCAL_ID`), appended active slot `56`. Gold 5×4 blocks byte-for-byte match common Pokecenter 1F; runtime tile/block/collision/palette assets reuse the accepted shared center. Own 20-byte Gold `.blk` and immediately following RGBASM `ASSERT` prevent earlier REF-336 resource size regression.
- From outside `(21,30)` facing UP, step onto `(21,29)` and trigger exact registered door. No other town building becomes open; indoor LEFT/RIGHT carpet movement must not trigger a warp, only DOWN.
- Nurse Yes reuses existing Gold treatment and records actual center stable ID 85; No preserves previous heal. START selects Blackthorn's already-existing Fly row 10, and only if unlocked; eleven Fly rows remain unchanged, no independent center Fly stop.

## Static validation and scope

- Standalone `tools/johto_blackthorn_center_338_audit.py` verifies Gold collision roles, door fifth event, both exit carpets, source/destination ordinal distinction, individual routes, active slot, Gold block dimensions, restoration target, healing and unchanged Fly lock.
- `tools/tests/test_johto_blackthorn_center_338.py` exercises positive and fault-injected incorrect target warp (4 out of range/1 wrong carpet), return routing, source index, nurse, door direction, Gold blocks and Fly destination count. Integrated into Gold migration audit.
- No ROM was assembled/linked by assistant and no device/old-save validation is claimed. Latest Red, Blue, TEST MAPs are required to check ROM0 at least 64B and relevant ROMX bank headroom; do not infer current bank availability from old REF-337 MAPs.

## Device acceptance checklist

1. On Blackthorn City outdoor map, approach center entrance `(21,29)` upward from `(21,30)` and land on left indoor carpet `(3,7)` with graphics and nurse visible (not black).
2. Both `(3,7)` and `(4,7)` indoor exits respond to DOWN and return to Blackthorn City, LEFT/RIGHT switching between carpets does not teleport; all other Blackthorn houses/gym remain closed in this phase.
3. Nurse No leaves heal record unchanged; Yes plays accepted animation and updates last successful heal to ID85.
4. Open Pokémon → Fly and press START. If Blackthorn is unlocked, focus existing city destination; otherwise do not bypass unlock. No new Fly list entry.
5. Smoke-test the previous Mahogany and Ecruteak center doors, old-save Continue and Save, and all three build MAPs.

No Git commit, push, cleaning artifacts or ROM builds performed in this development delivery.
