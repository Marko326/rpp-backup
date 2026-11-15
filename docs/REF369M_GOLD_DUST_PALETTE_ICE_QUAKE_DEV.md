# REF-369M@ · Gold dust palette and isolated Ice Path earthquake (development)

## Source and scope

Gold reference: `REFERENCES/Gold/pokegold-master/engine/overworld/map_objects.asm` (`SpawnStrengthBoulderDust`, `MovementFunction_BoulderDust`), `map_object_action.asm` (`SetFacingBoulderDust`), `engine/overworld/scripting.asm` (`Script_earthquake`), and `maps/IcePathB1F.asm` (`earthquake 80`). Project source REF-369L is the incremental baseline.

## Changed runtime behavior

1. `DrawJohtoGoldStrengthDust369L` retains separate 32-frame temporary OAM life and existing two-frame graphic but now uses `PAL_OW_EMOJI` (RPP index 5, corresponding to Gold `PAL_OW_EMOTE` 5), not rock index 7. No global `rOBP1` writes.
2. Only B1F's **boulder-fell** event changes from shared `JohtoBurnedTowerEarthquake16` to local `JohtoIcePathGoldQuake369M`. Gold `$50` quake means amplitude 2 and 16 steps. It alternates +/-2 pixels at 2 display frames per step, restores `hSCY`, then waits 16 frames. Existing pause 60 frames, original Strength sound, disappear-before-feedback, stone-event flags, collision and saves are unchanged.
3. Neither Kanto's quiet `AnimateBoulderDustQuiet369K` nor Kanto sound/movement/Seafoam event is modified. Burned Tower's screen shake is also unchanged.

## Validation boundaries

Source audit including wrong-palette, Kanto flash, wrong quake amplitude/rest, SCY restoration and cross-region mutation tests; project existing targeted suite and patch forward/reverse SHA/permissions replay. The exact Gold temporary-object timing/placement remains an approximation in this RPP rendering architecture; **not** claimed pixel-identical without a new mobile ROM video comparison. No ROM/MAP produced, no Commit/Push.
