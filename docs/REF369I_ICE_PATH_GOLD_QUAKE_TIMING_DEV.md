# REF-369I@ — Gold Ice Path B1F boulder drop cadence correction (development)

## Evidence and root cause

Gold source in the user's REF312 references, `maps/IcePathB1F.asm`:
`disappear -> pause 30 -> playsound SFX_STRENGTH -> earthquake 80 -> text`.
In `engine/overworld/scripting.asm`, `Script_pause` calls `DelayFrames` with `c=2`
for each tick, so `pause 30` maps to 60 display frames.
`Script_earthquake` copies its script byte to `step_shake` and its low six
bits to a following `step_sleep`. Gold `MovementFunction_ScreenShake` uses
low six bits for duration and high two bits for amplitude. Decimal `80=$50`
thus means 16 shake movement steps, amplitude 2, and then 16 sleep steps;
it does **not** mean 80 shake steps.

REF-369G/H mistakenly called the 16-step Burned Tower quake five times
(160 display frames of continuous shaking) and waited only 30 frames.

## This focused change

- Keep hide-on-pit and two distinct saved flag groups before animation.
- Wait 60 frames, play the existing Strength sound, call the existing
  `JohtoBurnedTowerEarthquake16` **once** (16 steps held 2 display frames each),
  then wait 32 display frames (the 16-step Gold sleep cadence), then show text.
- No changes to the generic push dust/flicker routine; global-style rOBP1
  changes are documented in TODO and need a separate scoped comparison.
- Gold shake *amplitude* is 2; the reused current helper's vertical excursion
  may not precisely match it. Do not claim visual frame-exact Gold parity.
- This is source-level cadence comparison, not a ROM/MAP compilation or
  device-timed playback proof. Device verification remains required.

## User test focus

On the existing REF-369H test state, check normal pushes still collide
and display current dust feedback; push one stone into a fresh PIT,
observe roughly one second pause plus a brief quake and settle before
`The boulder fell through.`; confirm the saved stone/hole state and B2F
sprite appear correctly. Confirm B2F Save no corruption, other maps unchanged.
Player PIT still closed. Do not commit until approved.
