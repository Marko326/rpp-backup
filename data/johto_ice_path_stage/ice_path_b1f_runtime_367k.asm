; REF-367L B1F Gold map preview, ordinary walk, 4 visible fixed boulders, no slide/Strength/PIT.
; Original warp ordinals are preserved. Only 1F return ladders #1/#7
; are active; B2F ladders #2/#8 and PIT #3-#6 are sealed.

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
    ret
; REF-367M: object text IDs $1-$4 below must NEVER index past this
; table.  A stationary boulder is not a Strength object in this stage,
; so A-button uses DisplayTextID instead of HandleBoulderInteraction.
JohtoIcePathB1FTextPointers367K:
    dw JohtoIcePathB1FStaticStoneText367M ; stone $1, (11,7)
    dw JohtoIcePathB1FStaticStoneText367M ; stone $2, (7,8)
    dw JohtoIcePathB1FStaticStoneText367M ; stone $3, (8,9)
    dw JohtoIcePathB1FStaticStoneText367M ; stone $4, (17,7)
JohtoIcePathB1FTextPointers367KEnd::
ASSERT JohtoIcePathB1FTextPointers367KEnd - JohtoIcePathB1FTextPointers367K == 4 * 2

; A legitimate, inert interaction for the four temporary fixed stone props.
; Do not mark them BOULDER_MOVEMENT_BYTE_2 until Strength/PIT works.
JohtoIcePathB1FStaticStoneText367M:
    text "A heavy boulder."
    line "It won't budge."
    done
    db "@"
ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FTextPointers367K)
ASSERT BANK(JohtoIcePathB1FRuntimeHeader367K) == BANK(JohtoIcePathB1FStaticStoneText367M)

JohtoIcePathB1FObjects367K::
    db $09 ; Gold ice path border
    db 8 ; original Gold #1-#8 SOURCE slots; third byte is target ordinal
    db 15, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> 1F #3
    db $ff, $ff, 1, JOHTO_REGISTERED_WARP_SELECTOR ; #2 B2F sealed
    db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR ; #3 PIT sealed
    db $ff, $ff, 3, JOHTO_REGISTERED_WARP_SELECTOR ; #4 PIT sealed
    db $ff, $ff, 4, JOHTO_REGISTERED_WARP_SELECTOR ; #5 PIT sealed
    db $ff, $ff, 5, JOHTO_REGISTERED_WARP_SELECTOR ; #6 PIT sealed
    db 25, 5, 3, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #7 -> 1F #4
    db $ff, $ff, 7, JOHTO_REGISTERED_WARP_SELECTOR ; #8 B2F sealed
    db 0 ; no sign / item / encounter
    ; REF-367M: Gold boulders use four valid local text pointer IDs.
    ; Pushing is intentionally disabled until the B1F PIT/Strength phase.
    ; They remain fixed non-Strength props; no unintended push interaction.
    db 4
    object SPRITE_BOULDER, 11, 7, STAY, NONE, $1
    object SPRITE_BOULDER, 7, 8, STAY, NONE, $2
    object SPRITE_BOULDER, 8, 9, STAY, NONE, $3
    object SPRITE_BOULDER, 17, 7, STAY, NONE, $4

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
    ; Hard-block only visible stationary Gold boulders (four object records above).
    ld a, b
    cp 7
    jr nz, .y8
    ld a, c
    cp 11
    jr z, .blocked
    cp 17
    jr z, .blocked
.y8
    ld a, b
    cp 8
    jr nz, .y9
    ld a, c
    cp 7
    jr z, .blocked
.y9
    ld a, b
    cp 9
    jr nz, .read
    ld a, c
    cp 8
    jr z, .blocked
.read
    call JohtoIcePathB1FRoleAt367K
    jr .done
.blocked
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

; E=0 walkable, E=1 wall. Floors and Gold ICE walk normally.
; B1F holes and two lower-floor ladders remain impassable.
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
    cp 3 ; PIT (four B2F drops): sealed
    ret z
    cp 4 ; LADDER: only original B1F #1 and #7 may be walked on
    jr nz, .wallDirection
    ; Here target is LADDER. Its two other Gold stairs #2/#8 are closed.
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
    ret nz
    ld a, b
    cp 25
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
