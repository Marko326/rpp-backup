# REF-369Q — Gold boulder-tracked dust (development candidate)

## Source comparison
Gold `engine/overworld/map_objects.asm` uses `SpawnStrengthBoulderDust`, then `MovementFunction_BoulderDust` attaches the temporary object to the tracked boulder via `STEP_TYPE_TRACKING_OBJECT`. Directional offsets: down (0,-4), up (0,8), left (6,2), right (-6,2). `SetFacingBoulderDust` determines the two facing frames.

## RPP implementation
`BeginJohtoGoldStrengthDust369L` now captures the **actual source boulder index** plus the accepted facing into one overworld-only packed byte at CD59 (shares the unused-during-overworld-trade OT-ID buffer); it does not cache the target cell. The renderer calls `UpdateJohtoGoldDustAnchor369Q` each frame (even when OAM capacity prevents drawing) and uses the moving boulder's C1x4/C1x6 screen coordinates and the captured facing to position the OAM 2x2 dust. If C1x2 becomes $ff after PIT hiding, last visible coordinates are kept. Joystick direction is never sampled after acceptance.

No OAM/OBJ tile/palette/shake/SFX/dialogue/event/SRAM changes. START entry and PIT text still clear dust. Kanto still routes through the quiet legacy animation. No WRAM or SRAM offsets shift; no BANK0 change.

## Verification caveat
Static checks and patch replay verify code structure and selected negative mutations, not actual display behavior. On-device repeat a push, change D-pad directions while dust lingers, push into PIT, and open START immediately afterward. Confirm dust location and lifetime against Gold reference video.
