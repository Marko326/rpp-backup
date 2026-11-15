# REF-369J@ | Gold Ice Path boulder disappears before quake (development)

## User device comparison and original source

The user's Gold movie and project comparison show Gold: push into PIT, boulder **disappears at movement completion**, pause, SFX_STRENGTH, earthquake, text. Project REF-369I instead leaves the stone visibly standing at the pit during the pause / shake.

The bundled reference `REFERENCES/Gold/pokegold-master/maps/IcePathB1F.asm` executes `disappear` as the **first command** of all four stone handlers, before their shared `.FinishBoulder` (`pause 30 -> SFX_STRENGTH -> earthquake 80`).

## Confirmed project bug

`JohtoIcePathB1FHideDropped369B` correctly sets each dropped stone's C2x4/C2x5 off-map coordinates to `$ff`, but only changes map coordinates. `home.asm:DelayFrameHook` calls `PrepareOAMData`; that renderer looks at the still-active C1x2 rendered sprite frame. Without setting C1x2 to its offscreen sentinel `$ff`, the old picture can remain drawn during blocking `DelayFrames` / quake. Gold hide semantics require **both** off-map collision state and **immediate render state**.

## Local correction

For each of the four guarded dropped stones, write `$ff` to its C1x2 sprite frame **before** writing `$ff` to existing C2x4/C2x5 coordinates. This happens after the saved PIT and dropped-source flags have been set and before `DelayFrames`/sound/quake. Do **not** write C1x0 sprite picture ID or C2xE VRAM slot; preserving these is essential to REF-369E's Save-return fix. No new BANK0 code, event bits, SRAM format, collision, maps, or generic Strength dust changes.

`tools/johto_ice_path_immediate_disappear_369j_audit.py` enforces all four guarded C1x2 writes, the live fade order, correct source sprite IDs, and the DelayFrame/OAM link; mutation tests independently remove each write.

## Verification scope

Code/pytest and patch replay can confirm source invariants only. User to build ROM/MAP; push one stone into PIT and check the sprite vanishes **before** the pause or first shake, then validate text, B2F landing, B1F/B2F Save, and collision. Player PIT is still disabled. Gold dust and exact quake amplitude/tempo remain separate comparisons. Do not commit.
