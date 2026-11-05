; REF-348: Gold Burned Tower B1F runtime, collision, boulder, and pitfall arrival.
; NPCs, legendary beasts, items, scene flags, and story scripts intentionally omitted.

JohtoBurnedTowerB1F_GFX::
    INCBIN "gfx/tilesets/johto_burned_tower_b1f.2bpp"
JohtoBurnedTowerB1F_GFXEnd::
; gfx/tilesets/%.2bpp uses tools/gfx --trim-whitespace: source PNG has
; 96 tile cells, but trailing 31 blank tiles are removed (65 retained).
; The active B1F map never refers to reserved block $30 (tile $7f).
ASSERT JohtoBurnedTowerB1F_GFXEnd - JohtoBurnedTowerB1F_GFX == 65 * 16

JohtoBurnedTowerB1F_Block::
    INCBIN "gfx/blocksets/johto_burned_tower_b1f.bst"
JohtoBurnedTowerB1F_BlockEnd::
ASSERT JohtoBurnedTowerB1F_BlockEnd - JohtoBurnedTowerB1F_Block == 64 * 16

JohtoBurnedTowerB1FRuntimeBlocks::
    INCBIN "maps/johto_pilot/BurnedTowerB1F.runtime.blk"
JohtoBurnedTowerB1FRuntimeBlocksEnd::
ASSERT JohtoBurnedTowerB1FRuntimeBlocksEnd - JohtoBurnedTowerB1FRuntimeBlocks == JOHTO_BURNED_TOWER_B1F_WIDTH * JOHTO_BURNED_TOWER_B1F_HEIGHT

JohtoBurnedTowerB1FRoles::
    INCBIN "maps/johto_pilot/BurnedTowerB1F.gold_roles.bin"
JohtoBurnedTowerB1FRolesEnd::
ASSERT JohtoBurnedTowerB1FRolesEnd - JohtoBurnedTowerB1FRoles == 20 * 18

JohtoBurnedTowerB1FRuntimeHeader::
    db JOHTO_BURNED_TOWER_B1F
    db JOHTO_BURNED_TOWER_B1F_HEIGHT, JOHTO_BURNED_TOWER_B1F_WIDTH
    dw JohtoBurnedTowerB1FRuntimeBlocks
    dw JohtoBurnedTowerB1FTextPointers
    dw JohtoBurnedTowerB1FScript
    db 0 ; no adjacent seams
    dw JohtoBurnedTowerB1FRuntimeObjects
JohtoBurnedTowerB1FRuntimeHeaderEnd::
ASSERT JohtoBurnedTowerB1FRuntimeHeaderEnd - JohtoBurnedTowerB1FRuntimeHeader == 12
ASSERT BANK(JohtoBurnedTowerB1FRuntimeHeader) == BANK(JohtoBurnedTowerB1FRuntimeBlocks)

JohtoBurnedTowerB1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoBurnedTowerB1FTextPointers:
JohtoBurnedTowerB1FRuntimeObjects::
    db $09 ; exact Gold CAVE/DAY border
    db 6 ; five arrival-only landing points, then the only active return ladder
    db 3, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal0 arrival-only from 1F PIT
    db 7, 17, 6, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal1 arrival-only from 1F PIT
    db 8, 10, 8, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal2 arrival-only from 1F PIT
    db 13, 3, 9, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal3 arrival-only from 1F PIT
    db 14, 17, 11, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal4 arrival-only from 1F PIT
    db 15, 7, 13, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal5 ladder -> 1F ordinal13
    db 0 ; no signs / NPC dialogue
    db 1 ; one functional Gold boulder; no trainers or story actors
    object SPRITE_BOULDER, 17, 4, STAY, BOULDER_MOVEMENT_BYTE_2, $1

; Role IDs are frozen from BurnedTowerB1F.gold_roles.bin.
DEF JOHTO_BURNED_TOWER_B1F_ROLE_FLOOR EQU 0
DEF JOHTO_BURNED_TOWER_B1F_ROLE_HOP_DOWN EQU 1
DEF JOHTO_BURNED_TOWER_B1F_ROLE_HOP_DOWN_LEFT EQU 2
DEF JOHTO_BURNED_TOWER_B1F_ROLE_HOP_LEFT EQU 3
DEF JOHTO_BURNED_TOWER_B1F_ROLE_HOP_RIGHT EQU 4
DEF JOHTO_BURNED_TOWER_B1F_ROLE_LADDER EQU 5
DEF JOHTO_BURNED_TOWER_B1F_ROLE_UP_WALL EQU 6
DEF JOHTO_BURNED_TOWER_B1F_ROLE_WALL EQU 7

; Input B=Gold Y, C=Gold X. Returns A=spatial Gold collision role;
; out-of-bounds is WALL so player/boulder checks fail closed.
JohtoBurnedTowerB1FGetRoleAtBC::
    ld a, b
    cp 18
    jr nc, .wall
    ld a, c
    cp 20
    jr nc, .wall
    ld a, b
    ld h, 0
    ld l, a
    add hl, hl ; 2Y
    add hl, hl ; 4Y
    ld d, h
    ld e, l
    add hl, hl ; 8Y
    add hl, hl ; 16Y
    add hl, de ; 20Y
    ld a, c
    ld e, a
    ld d, 0
    add hl, de
    ld de, JohtoBurnedTowerB1FRoles
    add hl, de
    ld a, [hl]
    ret
.wall
    ld a, JOHTO_BURNED_TOWER_B1F_ROLE_WALL
    ret

; Gold CAVE directional UP_WALL semantics plus the complete spatial walk mask.
; HOP cells are walkable; HandleLedges owns the directional two-cell jump.
JohtoBurnedTowerB1FLandDecision::
    ld e, 2 ; defer if called outside this stable map
    push bc
    push de
    push hl
    ld a, [wCurLocalMapID]
    cp JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    jr z, .currentMap
    ld a, 2
    jr .finish
.currentMap
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .target
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoBurnedTowerB1FGetRoleAtBC
    cp JOHTO_BURNED_TOWER_B1F_ROLE_UP_WALL
    jr z, .blocked
.target
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jr z, .right
    jr .blocked
.up
    dec b
    jr .checkTarget
.down
    inc b
    jr .checkTarget
.left
    dec c
    jr .checkTarget
.right
    inc c
.checkTarget
    call JohtoBurnedTowerB1FGetRoleAtBC
    cp JOHTO_BURNED_TOWER_B1F_ROLE_WALL
    jr z, .blocked
    cp JOHTO_BURNED_TOWER_B1F_ROLE_UP_WALL
    jr nz, .allowed
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    jr z, .blocked
.allowed
    ld a, 0
    jr .finish
.blocked
    ld a, 1
.finish
    pop hl
    pop de
    pop bc
    ld e, a
    ret

; Boulder push collision wrapper: stock code still checks tile pairs and sprite
; overlap, but ambiguous visual IDs are first qualified by Gold spatial role.
; Only FLOOR cells may receive the boulder; HOP/UP_WALL/WALL/LADDER are blocked.
JohtoBurnedTowerB1FCheckForCollisionWhenPushingBoulder::
    ld a, [wCurLocalMapID]
    cp JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    jr nz, .legacy
    predef GetTileTwoStepsInFrontOfPlayer
    ld b, d ; target Y beyond the boulder
    ld c, e ; target X beyond the boulder
    call JohtoBurnedTowerB1FGetRoleAtBC
    cp JOHTO_BURNED_TOWER_B1F_ROLE_FLOOR
    jr nz, .blocked
.legacy
    callba CheckForCollisionWhenPushingBoulderLegacy
    ret
.blocked
    ld a, $ff
    ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a
    ret

; Warp trigger modes: 0=arrival-only/no trigger, 1=DOWN carpet, 2=step-in PIT/LADDER.
JohtoBurnedTowerWarpTriggerMode::
    push bc
    push de
    push hl
    ld a, [wCurLocalMapID]
    cp JOHTO_BURNED_TOWER_1F_LOCAL_ID
    jr z, .oneF
    cp JOHTO_BURNED_TOWER_B1F_LOCAL_ID
    jr z, .basement
    xor a
    jr .warpModeDone
.oneF
    ld a, [wYCoord]
    cp 15
    jr nz, .oneFStepIn
    ld a, [wXCoord]
    cp 9
    jr z, .carpet
    cp 10
    jr z, .carpet
.oneFStepIn
    ld a, [wYCoord]
    ld d, a
    ld a, [wXCoord]
    ld e, a
    ld hl, .OneFStepInWarpCells
    ld b, 12
.loopStepIn
    ld a, [hli]
    cp d
    jr nz, .skipStepInX
    ld a, [hli]
    cp e
    jr z, .stepIn
    jr .nextStepIn
.skipStepInX
    inc hl
.nextStepIn
    dec b
    jr nz, .loopStepIn
    xor a
    jr .warpModeDone
.carpet
    ld a, 1
    jr .warpModeDone
.stepIn
    ld a, 2
    jr .warpModeDone
.basement
    ld a, [wYCoord]
    cp 15
    jr nz, .noWarpTrigger
    ld a, [wXCoord]
    cp 7
    jr nz, .noWarpTrigger
    ld a, 2
    jr .warpModeDone
.noWarpTrigger
    xor a
.warpModeDone
    pop hl
    pop de
    pop bc
    ld e, a
    ret
.OneFStepInWarpCells
    ; Gold 1F PIT ordinals 2-12 and lower LADDER ordinal13 (Y,X pairs).
    db 4, 5, 5, 5, 6, 5, 6, 4, 4, 15, 5, 15
    db 7, 10, 14, 5, 14, 4, 14, 14, 14, 15, 15, 7

; Gold FallIntoMapScript: only 1F PIT ordinals 2-12 land with MAPSETUP_FALL.
; The lower ladder and the B1F return ladder use the ordinary map transition.
JohtoBurnedTowerMaybeFallWarp::
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_BURNED_TOWER_1F_LOCAL_ID
    ret nz
    ld a, [wWarpedFromWhichWarp]
    cp 2
    ret c
    cp 13
    ret nc
    ld a, [wDestinationWarpID]
    cp 5
    ret nc
    ; Flag the next EnterMap before the ONE registered-warp resolution in
    ; WarpFound2.  Resolving here as well would change the source stable ID and
    ; make the second lookup fail (the B1F landing ordinals are arrival-only).
    ld hl, wd732
    set 7, [hl] ; private pitfall-arrival animation selector
    call GBFadeOutToWhite
    ret

; EnterMap calls this banked dispatcher instead of EnterMapAnim directly.
; All non-pitfall maps retain the stock animation byte-for-byte.
JohtoEnterMapAnimationDispatcher::
    ld a, [wd732]
    bit 7, a
    jr z, .normal
    ld hl, wd732
    res 7, [hl]
    res 3, [hl] ; no stale warp-pad / dungeon warp after the fall
    res 4, [hl]
    ; Clear the ordinary step-out and standing-on-warp flags. Five B1F PIT
    ; landing cells are receive-only, not immediate/standing source triggers.
    ld hl, wd736
    res 0, [hl]
    res 1, [hl]
    res 2, [hl]
    call JohtoBurnedTowerFallEntryAnim
    ret
.normal
    callba EnterMapAnim
    ret

; Gold StepFunction_Skyfall: 16-frame pause before the 16 quarter-sine offsets.
; Video comparison (both recordings ~60fps): Gold displays each skyfall offset
; for 2 video frames; REF-348 previously displayed each for 1 and looked rushed.
; Gold then plays Strength, followed by 16 shake steps + step_sleep 16.
JohtoBurnedTowerFallEntryAnim::
    callba InitFacingDirectionList
    ; Make the initial position visible from above when the white fade lifts,
    ; rather than briefly flashing the player at ground level.
    ld a, [wSavedPlayerScreenY]
    add -87
    ld [wSpriteStateData1 + 4], a
    call Delay3
    call GBFadeInFromWhite
    ld a, GSSFX_BURNED_TOWER_KINESIS ; exact Gold SFX_KINESIS, existing crysaudio data
    call PlaySound
    ld c, 16
    call DelayFrames
    ld hl, .SkyfallOffsets
    ld b, 16
.skyfallLoop
    ld a, [wSavedPlayerScreenY]
    add [hl]
    ld [wSpriteStateData1 + 4], a
    inc hl
    push hl
    push bc
    ld c, 2 ; Gold skyfall's 1 object step per 2 captured display frames
    call DelayFrames
    pop bc
    pop hl
    dec b
    jr nz, .skyfallLoop
    ld a, GSSFX_BURNED_TOWER_STRENGTH ; exact Gold SFX_STRENGTH, existing crysaudio data
    call PlaySound
    call JohtoBurnedTowerEarthquake16
    ld c, 32 ; Gold step_sleep 16: 16 movement ticks at 2 captured frames/tick
    call DelayFrames
    call PlayDefaultMusic
    callba RestoreFacingDirectionAndYScreenPos
    ret
.SkyfallOffsets
    db -87, -78, -69, -60, -51, -43, -36, -29, -22, -17, -12, -8, -5, -2, -1, 0

JohtoBurnedTowerEarthquake16::
    ; Reuse ShakeElevator's SCY oscillation core, but use Gold's pacing:
    ; 16 shake steps, each held for 2 captured frames (Gold temporary
    ; SPRITEMOVEDATA_SCREENSHAKE object), not 16 rapid display frames.
    ; Preserve scroll baseline; no elevator SFX/music/redraw.
    ld a, [hSCY]
    ld d, a
    ld e, 1
    ld b, 16
.shakeLoop
    ld a, e
    xor $fe
    ld e, a
    add d
    ld [hSCY], a
    push bc
    push de
    ld c, 2 ; Gold video shake flips vertical offset every 2 frames
    call DelayFrames
    pop de
    pop bc
    dec b
    jr nz, .shakeLoop
    ld a, d
    ld [hSCY], a
    ret
