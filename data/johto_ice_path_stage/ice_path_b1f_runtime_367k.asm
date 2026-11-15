; B1F Gold map: live ICE sliding, four Strength boulders and four player PIT drops.
; All original Gold 8 warp ordinals are preserved. Pit #3-#6 are step-in
; one-way player falls to four arrival-only B2F Mahogany ICE cells.

JohtoIcePathB1FRuntimeBlocks367K::
    INCBIN "maps/johto_ice_path_stage/IcePathB1F.runtime.blk"
ASSERT @ - JohtoIcePathB1FRuntimeBlocks367K == 10 * 18
JohtoIcePathB1FGoldRoles367K::
    INCBIN "data/johto_ice_path_stage/IcePathB1F.roles.bin"
ASSERT @ - JohtoIcePathB1FGoldRoles367K == 20 * 36

JohtoIcePathB1FRuntimeHeader367K::
    db JOHTO_ICE_PATH
    db 18, 10
    dw JohtoIcePathB1FRuntimeBlocks367K
    dw JohtoIcePathB1FTextPointers367K
    dw JohtoIcePathB1FScript367K
    db 0 ; underground, no exterior connections
    dw JohtoIcePathB1FObjects367K
JohtoIcePathB1FRuntimeHeader367KEnd::
ASSERT JohtoIcePathB1FRuntimeHeader367KEnd - JohtoIcePathB1FRuntimeHeader367K == 12
ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FRuntimeBlocks367K)

JohtoIcePathB1FScript367K::
    call EnableAutoTextBoxDrawing
    call JohtoIcePathInitializePitState369B
    call JohtoIcePathB1FHideDropped369B
    ld hl, wFlags_0xcd60
    bit 7, [hl] ; pending Gold boulder destination check
    ret z
    ; MoveSprite queues an NPC step; DelayFrameHook only updates OAM and
    ; cannot move it. Wait for the engine's real movement script to finish
    ; (wd730 bit 0 cleared on the final $FF command), then check the hole.
    ; Never hide a boulder during its still-in-progress moving frame.
    ld a, [wd730]
    bit 0, a
    ret nz
    res 7, [hl]
    jp JohtoIcePathB1FCheckStoneDrop369B
; Text pointer IDs stay valid even though the shared Strength interaction
; consumes A-button on moving boulders; never expose object bytes as text.
JohtoIcePathB1FTextPointers367K:
    dw JohtoIcePathB1FStaticStoneText367M ; stone $1, (11,7)
    dw JohtoIcePathB1FStaticStoneText367M ; stone $2, (7,8)
    dw JohtoIcePathB1FStaticStoneText367M ; stone $3, (8,9)
    dw JohtoIcePathB1FStaticStoneText367M ; stone $4, (17,7)
    ; Script-only text ID 5. wNumSprites is 4 on B1F, so 5 skips
    ; DisplayTextID's sprite-ID lookup and uses this in-bank pointer.
    dw JohtoIcePathB1FBoulderFellText369G
JohtoIcePathB1FTextPointers367KEnd::
ASSERT JohtoIcePathB1FTextPointers367KEnd - JohtoIcePathB1FTextPointers367K == 5 * 2

; Valid fallback text if a map script ever displays the boulder text ID.
; Normal use is handled by the existing Strength A-button predef.
JohtoIcePathB1FStaticStoneText367M:
    text "A heavy boulder."
    line "It won't budge."
    done
    db "@"
ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FTextPointers367K)
ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FStaticStoneText367M)

JohtoIcePathB1FObjects367K::
    db $19 ; Gold B1F border block (Gold map_attributes): rock wall, not floor $09
    db 8 ; original Gold #1-#8 SOURCE slots; third byte is target ordinal
    db 15, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> 1F #3
    db 3, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR ; #2 -> B2F Mahogany Gold #1
    db 2, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR ; #3 PIT -> B2F Mahogany #3
    db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR ; #4 PIT -> B2F Mahogany #4
    db 12, 5, 4, JOHTO_REGISTERED_WARP_SELECTOR ; #5 PIT -> B2F Mahogany #5
    db 13, 12, 5, JOHTO_REGISTERED_WARP_SELECTOR ; #6 PIT -> B2F Mahogany #6
    db 25, 5, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #7 -> 1F #4
    db 27, 11, 0, JOHTO_REGISTERED_WARP_SELECTOR ; #8 -> B2F Blackthorn Gold #1
    db 0 ; no sign / item / encounter
    ; Four real Strength sprites; Gold coordinates, original order 1..4.
    ; A saved event bit hides each rock permanently after dropping into a PIT.
    db 4
    object SPRITE_BOULDER, 11, 7, STAY, BOULDER_MOVEMENT_BYTE_2, $1
    object SPRITE_BOULDER, 7, 8, STAY, BOULDER_MOVEMENT_BYTE_2, $2
    object SPRITE_BOULDER, 8, 9, STAY, BOULDER_MOVEMENT_BYTE_2, $3
    object SPRITE_BOULDER, 17, 7, STAY, BOULDER_MOVEMENT_BYTE_2, $4

; Exact Gold 20x36 8x8 collision roles. B=Y C=X; A=role or WALL.
JohtoIcePathB1FRoleAt367K::
    push de
    ld a, b
    cp 36
    jr nc, .wall
    ld a, c
    cp 20
    jr nc, .wall
    ld l, b
    ld h, 0
    add hl, hl
    add hl, hl  ; 4*y
    ld d, h
    ld e, l
    add hl, hl ; 8*y
    add hl, hl ; 16*y
    add hl, de ; 20*y
    ld d, 0
    ld e, c
    add hl, de
    ld de, JohtoIcePathB1FGoldRoles367K
    add hl, de
    ld a, [hl]
    pop de
    ret
.wall
    ld a, 1
    pop de
    ret

; Derive target cell in BC from current coordinate and direction.
JohtoIcePathB1FRoleAhead367K::
    push bc
    push hl
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
    jr nz, .invalid
    inc c
    jr .check
.up
    dec b
    jr .check
.down
    inc b
    jr .check
.left
    dec c
.check
    ; Sprite collision owns moving rocks. Hard-coding their original tiles
    ; would leave invisible walls after a rock has been pushed away.
    call JohtoIcePathB1FRoleAt367K
    jr .done
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

; E=0 walkable, E=1 wall. Floors and Gold ICE walk normally.
; Only the four Gold PIT tiles admit player steps; their registered
; step-in warps own the fall and exact B2F Mahogany arrival coordinate.
JohtoIcePathB1FLandDecision367K::
    push bc
    call .policy
    pop bc
    ret
.policy
    ld e, 1
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .target
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB1FRoleAt367K
    pop hl
    pop bc
    cp 6 ; cannot move north out of UP_WALL
    ret z
.target
    call JohtoIcePathB1FRoleAhead367K
    cp 1 ; WALL / unspawned fixed stone
    ret z
    cp 3 ; PIT: Gold B1F has exactly four, all registered as step-in falls
    jp z, .allow
    cp 4 ; LADDER: all four original B1F stair cells may be walked on
    jr nz, .wallDirection
    ; Here target is LADDER. All four Gold stairs #1/#2/#7/#8 are open.
    ; Read current Y/X and direction, derive target again to distinguish.
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .notUp
    dec b
    jr .checkLadder
.notUp
    cp PLAYER_DIR_DOWN
    jr nz, .notDown
    inc b
    jr .checkLadder
.notDown
    cp PLAYER_DIR_LEFT
    jr nz, .notLeft
    dec c
    jr .checkLadder
.notLeft
    inc c
.checkLadder
    ld a, c
    cp 3
    jr nz, .ladder5
    ld a, b
    cp 15
    jr z, .allow
    ret
.ladder5
    cp 5
    jr nz, .ladder11
    ld a, b
    cp 25
    jr z, .allow
    ret
.ladder11
    cp 11 ; Gold #8 is at (11,27), not (5,25) Gold #7
    jr nz, .ladder17
    ld a, b
    cp 27
    jr z, .allow
    ret
.ladder17
    cp 17
    ret nz
    ld a, b
    cp 3
    jr z, .allow
    ret
.wallDirection
    cp 6 ; never enter UP_WALL heading DOWN
    jr nz, .allow
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret z
.allow
    ld e, 0
    ret

; Gold CAVE permits new bicycle mounting only on FLOOR; ICE cannot mount.
JohtoIcePathB1FBikeFloorAllowed367K::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB1FRoleAt367K
    pop hl
    pop bc
    and a
    jr nz, .no
    scf
    ret
.no
    and a
    ret

; REF-368F farcall ABI: Z set only on ICE at BC, other flags inert.
; Use flags instead of A because Bankswitch restores the old ROM bank in A.
JohtoIcePathB1FIsIce368F::
    push bc
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB1FRoleAt367K
    cp 2
    pop bc ; preserve the ICE equality flag
    ret

; REF-369B save allocation. Event indices are byte offsets from wEventFlags
; (D7CB), not absolute WRAM addresses. Never add an extra byte to EVENT_9D7 / 8:
; that moves D854 to D855 and aliases the entire Johto Fly / Articuno byte.
;
; D852: bits 0..1 Seafoam B2F; bits 2..5 Ice Path PIT occupancy;
;       bits 6..7 one-time REF-369A save migration signature.
; D853: bits 0..1 Seafoam B3F; bits 2..3 Ice Path outdoor escape anchor;
;       bits 4..7 Ice Path source-boulder disappearance.
; D854: bits 0..1 Seafoam B4F; bits 2..5 Johto Fly; bits 6..7 Dark Cave anchor.
; D855: all eight bits are live Fly / Articuno events. Ice Path never writes it.
; This reuses the existing 139-byte save-backed event array; no WRAM/SRAM resize.
DEF JOHTO_ICE_PATH_PIT_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_PIT_1_FILLED / 8
DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED / 8
DEF JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B EQU $c0
ASSERT EVENT_JOHTO_ICE_PATH_PIT_1_FILLED / 8 == JOHTO_ICE_PATH_PIT_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_PIT_2_FILLED / 8 == JOHTO_ICE_PATH_PIT_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_PIT_3_FILLED / 8 == JOHTO_ICE_PATH_PIT_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_PIT_4_FILLED / 8 == JOHTO_ICE_PATH_PIT_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_PIT_1_FILLED % 8 == 2
ASSERT EVENT_JOHTO_ICE_PATH_PIT_2_FILLED % 8 == 3
ASSERT EVENT_JOHTO_ICE_PATH_PIT_3_FILLED % 8 == 4
ASSERT EVENT_JOHTO_ICE_PATH_PIT_4_FILLED % 8 == 5
ASSERT EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_A / 8 == JOHTO_ICE_PATH_PIT_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_B / 8 == JOHTO_ICE_PATH_PIT_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_A % 8 == 6
ASSERT EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_B % 8 == 7
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED / 8 == JOHTO_ICE_PATH_STONE_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_2_DROPPED / 8 == JOHTO_ICE_PATH_STONE_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_3_DROPPED / 8 == JOHTO_ICE_PATH_STONE_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_4_DROPPED / 8 == JOHTO_ICE_PATH_STONE_FLAGS_369B
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED % 8 == 4
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_2_DROPPED % 8 == 5
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_3_DROPPED % 8 == 6
ASSERT EVENT_JOHTO_ICE_PATH_BOULDER_4_DROPPED % 8 == 7
ASSERT JOHTO_ICE_PATH_PIT_FLAGS_369B == 135 ; D852 relative to wEventFlags at D7CB
ASSERT JOHTO_ICE_PATH_STONE_FLAGS_369B == 136 ; D853 relative to wEventFlags at D7CB
ASSERT JOHTO_ICE_PATH_PIT_FLAGS_369B < 139
ASSERT JOHTO_ICE_PATH_STONE_FLAGS_369B < 139

; REF-369A stored hole state in D855 by calculating EVENT_9D7 / 8 + 1.
; That byte is not free: it contains Fly Ecruteak, Fly Mahogany, Articuno,
; Fly New Bark, Cherrygrove, Violet, Azalea and Goldenrod. We cannot infer
; which bits a REF-369A save had before the collision, so never try to repair
; or clear D855 automatically. Back up such saves before first REF-369B load.
; The old puzzle's partial progress is reset once in the two newly-owned bytes.
JohtoIcePathInitializePitState369B::
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
    and JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B
    cp JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B
    ret z
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
    and $c3 ; preserve Seafoam B2F bits 0..1; clear PIT bits 2..5
    or JOHTO_ICE_PATH_PIT_MIGRATION_MASK_369B
    ld [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B]
    and $0f ; preserve Seafoam B3F and Ice Path escape anchor bits 0..3
    ld [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B], a
    ret

; Every map reload replays the four saved source-disappearance bits.
; Keep SPRITE_BOULDER picture ID and valid graphics slot untouched.
; The HOME text-return InitMapSprites re-reads every picture ID even for
; hidden objects: zero would underflow to $ff and index outside the
; SpriteSheetPointerTable. Off-map coordinates alone suppress draw/collision.
JohtoIcePathB1FHideDropped369B::
    ld a, [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B]
    bit 4, a
    jr z, .second
    xor a
    ; Gold's disappear precedes pause/quake: invalidate the *rendered*
    ; sprite facing/animation (C1x2) as well as off-map coordinates (C2x4/5).
    ; Otherwise DelayFrameHook's OAM rebuild still draws this stone until the
    ; next ordinary sprite update. Keep C1x0 picture ID intact (REF-369E).
    dec a ; $ff: invisible render frame and off-map coordinates
    ld [wSpriteStateData1 + $12], a ; visible sprite frame (C1x2)
    ld [wSpriteStateData2 + $14], a
    ld [wSpriteStateData2 + $15], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B]
.second
    bit 5, a
    jr z, .third
    xor a
    ; Gold's disappear precedes pause/quake: invalidate the *rendered*
    ; sprite facing/animation (C1x2) as well as off-map coordinates (C2x4/5).
    ; Otherwise DelayFrameHook's OAM rebuild still draws this stone until the
    ; next ordinary sprite update. Keep C1x0 picture ID intact (REF-369E).
    dec a ; $ff: invisible render frame and off-map coordinates
    ld [wSpriteStateData1 + $22], a ; visible sprite frame (C1x2)
    ld [wSpriteStateData2 + $24], a
    ld [wSpriteStateData2 + $25], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B]
.third
    bit 6, a
    jr z, .fourth
    xor a
    ; Gold's disappear precedes pause/quake: invalidate the *rendered*
    ; sprite facing/animation (C1x2) as well as off-map coordinates (C2x4/5).
    ; Otherwise DelayFrameHook's OAM rebuild still draws this stone until the
    ; next ordinary sprite update. Keep C1x0 picture ID intact (REF-369E).
    dec a ; $ff: invisible render frame and off-map coordinates
    ld [wSpriteStateData1 + $32], a ; visible sprite frame (C1x2)
    ld [wSpriteStateData2 + $34], a
    ld [wSpriteStateData2 + $35], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B]
.fourth
    bit 7, a
    ret z
    xor a
    ; Gold's disappear precedes pause/quake: invalidate the *rendered*
    ; sprite facing/animation (C1x2) as well as off-map coordinates (C2x4/5).
    ; Otherwise DelayFrameHook's OAM rebuild still draws this stone until the
    ; next ordinary sprite update. Keep C1x0 picture ID intact (REF-369E).
    dec a ; $ff: invisible render frame and off-map coordinates
    ld [wSpriteStateData1 + $42], a ; visible sprite frame (C1x2)
    ld [wSpriteStateData2 + $44], a
    ld [wSpriteStateData2 + $45], a
    ret

; Called only after the stock boulder push animation has ended. The index is
; 1-based, and CheckBoulderCoords returns a 1-based Gold PIT ordinal.
JohtoIcePathB1FCheckStoneDrop369B::
    ld a, [wBoulderSpriteIndex]
    and a
    ret z
    cp 5
    ret nc
    ld [H_SPRITEINDEX], a
    ld hl, .pitCoords
    call CheckBoulderCoords
    ret nc
    ld a, [wCoordIndex]
    dec a
    ld e, a
    ld d, 0
    ld hl, .holeMasks
    add hl, de
    ld b, [hl]
    ld hl, wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B
    ld a, [hl]
    and b
    ret nz ; a filled hole cannot receive another boulder
    ld a, [hl]
    or b
    ld [hl], a
    ld a, [wBoulderSpriteIndex]
    dec a
    ld e, a
    ld d, 0
    ld hl, .stoneMasks
    add hl, de
    ld b, [hl]
    ld hl, wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B
    ld a, [hl]
    or b
    ld [hl], a
    call JohtoIcePathB1FHideDropped369B
    ; Gold IcePathB1F.StoneTable: disappear, pause 30 script ticks,
    ; play Strength, earthquake 80, then show the fall message.
    ; Gold Script_pause sleeps TWO display frames per tick (60 frames).
    ; Gold Script_earthquake decodes 80 ($50) as 16 shake steps with
    ; amplitude 2, then 16 step_sleep ticks. This project's existing
    ; Burned Tower quake anim holds each shake step for two display frames.
    ; The 16 shake steps use 2-pixel oscillation, one step every two
    ; display frames. Gold's step_sleep 16 then rests for 16 frames.
    ; Do not share Burned Tower's amplitude-1 quake.
    ; Both save flags and sprite hiding happen before this feedback.
    ld c, 60
    call DelayFrames
    ld a, GSSFX_BURNED_TOWER_STRENGTH
    call PlaySound
    call JohtoIcePathGoldQuake369M
    ld c, 16
    call DelayFrames
    ; Gold: opentext / writetext / waitbutton / closetext.
    ; Use the project-owned DisplayTextID lifecycle, not raw PrintText:
    ; DisplayTextID initializes the Window, waits for A/B, restores the
    ; map sprites and returns with its ROM-bank stack balanced.
    ; Remove any transient dust before the dialogue takes over OAM/VRAM.
    xor a
    ld [wJohtoGoldDustFrames], a
    ld [wJohtoGoldDustSlot2Frames369R], a
    ld a, 5 ; B1F script-only text pointer, above four object sprite IDs
    ld [hSpriteIndexOrTextID], a
    jp DisplayTextID
.pitCoords
    db 2, 11, 7, 4, 12, 5, 13, 12, $ff ; Y,X from Gold warps #3..#6
.holeMasks
    db $04, $08, $10, $20
.stoneMasks
    db $10, $20, $40, $80

; Gold post-drop message; only displayed after the saved source/hole bits
; have been committed and the source sprite moved out of map bounds.
JohtoIcePathB1FBoulderFellText369G:
    text "The boulder fell"
    line "through."
    done
    db "@"

; REF-369M: local interpretation of Gold IcePathB1F `earthquake 80`.
; High bits $40 request displacement 2, low six bits $10 request 16
; shake steps. Unlike the Burned Tower scene this uses +/-2 pixel SCY.
; One Gold movement step here is held for two project display frames.
; Resting step_sleep 16 happens in the caller AFTER restoring hSCY.
JohtoIcePathGoldQuake369M::
    ld a, [hSCY]
    ld d, a
    ld e, 2
    ld b, 16
.shakeLoop
    ld a, e
    xor $fc ; alternate +2 and -2, never +/-1
    ld e, a
    add d
    ld [hSCY], a
    push bc
    push de
    ld c, 2
    call DelayFrames
    pop de
    pop bc
    dec b
    jr nz, .shakeLoop
    ld a, d
    ld [hSCY], a ; restore before static wait and text
    ret

; Distinguish Gold PIT from cave FLOOR/ICE before the stock boulder action.
; The stock push predef already checks other sprite occupancy; this adds
; directional wall/ladder/out-of-map protection and filled-hole exclusion.
JohtoIcePathB1FCheckPush369B::
    predef GetTileTwoStepsInFrontOfPlayer
    ; The stock predef computes the tile TWO steps ahead for the screen,
    ; but D/E only advance ONE map cell: the currently occupied boulder.
    ; Advance the map position once more, using the same $ffdb facing bits
    ; as the stock boulder/sprite collision routine. Checking the boulder's
    ; present FLOOR cell instead let it slide inside fixed WALL rocks.
    ld b, d
    ld c, e
    ld a, [$ffdb]
    bit 0, a ; down
    jr nz, .targetDown
    bit 1, a ; up
    jr nz, .targetUp
    bit 2, a ; left
    jr nz, .targetLeft
    bit 3, a ; right
    jr nz, .targetRight
    jp .blocked ; invalid direction must fail closed
.targetDown
    inc b
    jr .checkTarget
.targetUp
    dec b
    jr .checkTarget
.targetLeft
    dec c
    jr .checkTarget
.targetRight
    inc c
.checkTarget
    call JohtoIcePathB1FRoleAt367K
    and a ; FLOOR
    jr z, .checkSprites
    cp 2 ; Gold ICE
    jr z, .checkSprites
    cp 3 ; Gold PIT
    jr nz, .blocked
    ld a, b
    cp 2
    jr nz, .hole2
    ld a, c
    cp 11
    jr nz, .hole2
    ld b, $04
    jr .checkHole
.hole2
    ld a, b
    cp 7
    jr nz, .hole3
    ld a, c
    cp 4
    jr nz, .hole3
    ld b, $08
    jr .checkHole
.hole3
    ld a, b
    cp 12
    jr nz, .hole4
    ld a, c
    cp 5
    jr nz, .hole4
    ld b, $10
    jr .checkHole
.hole4
    ld a, b
    cp 13
    jr nz, .blocked
    ld a, c
    cp 12
    jr nz, .blocked
    ld b, $20
.checkHole
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
    and b
    jr nz, .blocked
.checkSprites
    callba CheckForBoulderCollisionWithSprites
    jr c, .blocked ; Bankswitch overwrites A but preserves carry
    xor a
    ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a
    ret
.blocked
    ld a, $ff
    ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a
    ret
