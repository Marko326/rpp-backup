# REF-369K@ — Ice Path B1F scoped no-flash boulder dust (development)

## Evidence

Video GOLD版推石头.mp4 at ~32.3–33.4 s shows an independent white local effect still visible after the boulder is hidden. 67728.mp4 (project) shows boulder palette cycling and legacy dust ~5.1–5.8 s before disappearance ~5.9 s. The reference `engine/overworld/map_objects.asm` spawns a temporary Gold dust object (`SpawnStrengthBoulderDust`) rather than pausing to flash OBP1.

## Minimal isolated change

`DoBoulderDustAnimation` checks `wCurMap=JOHTO_RUNTIME_MAP_HANDLE` and `wCurLocalMapID=JOHTO_ICE_PATH_B1F_LOCAL_ID` before selecting the quiet alternate entry. Other maps call `AnimateBoulderDust` unchanged. The quiet entry sets bit 7 in `wWhichAnimationOffsets` and runs the same dust OAM motion, load/cleanup, but skips both the initial `rOBP1` write and eight `rOBP1` xor toggles. No event flags, SRAM state, collisions, player PIT, map objects, BANK0 logic or legacy Kanto drop scripts are changed.

## Remaining differences

This removes one confirmed source of sprite flashing but does not implement Gold's asynchronous *temporary* dust object; project dust still runs before the map-scripted disappear. The video also suggests the current 1px quake is smaller than Gold's 2px effect. Gold script's `earthquake 80` includes sleep. User should build ROM and verify no visible flashing on all four B1F stones, local dust visible, hole/quake/text sequence, B2F Save return, and Kanto legacy behavior. No ROM built and no Git commit by AI.
