# REF-369R@ — Gold Strength smoke: post-hide lifetime and overlapping pushes

## Evidence and scope

REF-369Q device video and prior Gold comparison show a post-drop smoke puff that appears too briefly. The supplied REF-369Q review also documents single-slot state being overwritten by a subsequent push. Gold `MovementFunction_BoulderDust` creates a moving temporary object tied to the boulder; the prior RPP version had one four-byte singleton, with 64 frames measured **from push acceptance** rather than guaranteed smoke time **after the stone disappears**.

This development candidate makes two restricted changes **only to Johto smoke**, not to the Strength collision, Kanto, pit event, save, quake, dialogue or sound:

1. Keep a separate four-byte temporary state for each of two simultaneous puffs. Slot A uses existing CD56–CD59; slot B uses CD51–CD54 within the existing six-byte overworld animation scratch. All WRAM addresses and SRAM formats remain unchanged. On a third overlapping push, the slot with fewer frames remaining is reused (not a full reproduction of Gold's variable-sized temp-object pool).
2. Dust follows the correct source stone until its sprite is marked `$FF` hidden. On **the first** hidden frame, it freezes its last screen position and receives 60 additional display frames (~1 s at 60 Hz), with a packed-bit guard against re-arming. Normal pushes retain 64 display frames counted from initiation. Both timers continue to age even when four OAM pieces cannot be displayed because of sprite capacity.

Gold artwork (2×2, two alternating tiles), palette 5, direction offsets, existing `START` and B1F dialogue cleanup remain unchanged; cleanup now clears both timers. The normal OAM guard reserves the last four shadow/fishing entries. The second state is not SRAM; the map-entry clearing range zeroes it. `CD50` remains untouched (emotion/character scratch). Because other field-move animations use this same scratch block when invoked, the START/map cleanup is relevant; concurrent triggered non-START field moves still require device verification.

## Audits / evidence caveat

Added `johto_gold_dust_lifecycle_369r_audit.py` to the maintained `validate_current_project.py --skip-pytest` gate, alongside the previously unregistered O/P/Q checks. Existing affected auditors and negative-mutation tests were updated for a genuine two-slot code path; the tests deliberately reject missing second-slot drawing, premature expiry, repeated hidden re-arming, wrong OAM bounds, missing cleanup, palette changes and Kanto regressions.

**This is source validation only.** No ROM build or device verification has been performed by the assistant. The ~60-frame post-hide target is based on the user-supplied Gold video observation, not a verified instruction-for-instruction reimplementation of all Gold temp-object scheduling. In dense OAM scenes a puff may not be drawn in every frame, even while its lifetime continues.

## Minimum phone acceptance

- Normal push: smoke follows the moving stone, does not snap to D-pad direction, expires normally.
- Pit: the stone disappears first, with a white puff staying near the hole for roughly a second, then quake and text as previously tested.
- Quickly push twice: both clouds coexist where OAM capacity permits; if a third push occurs before expiry, the older remaining puff may be replaced (documented ceiling).
- Open START during smoke; repeat B2F Save, re-enter B1F, reload a save. No stale OAM / text / map corruption.
- Kanto push remains quiet without palette flash; no claimed new device test for Kanto.
