; REF-368A: Ice Path B2F Mahogany Side (Gold stable ID96), walk-only pilot.
; B1F Gold #2 <-> B2F Gold #1; B3F Gold #1 <-> B2F Gold #2 now live.
; Four receive-only Gold B1F PIT arrivals #3-#6 have their real ICE
; coordinates. They must not be active EXIT warps; only #1/#2 ladders exit.
; ICE movement is handled by the live slide controller; items/NPCs deferred.
JohtoIcePathB2FMahoganyRuntimeBlocks368A::
    INCBIN "maps/johto_ice_path_stage/IcePathB2FMahoganySide.runtime.blk"
ASSERT @ - JohtoIcePathB2FMahoganyRuntimeBlocks368A == 10 * 9
JohtoIcePathB2FMahoganyGoldRoles368A::
    INCBIN "data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin"
ASSERT @ - JohtoIcePathB2FMahoganyGoldRoles368A == 20 * 18

JohtoIcePathB2FMahoganyRuntimeHeader368A::
    db JOHTO_ICE_PATH
    db 9, 10
    dw JohtoIcePathB2FMahoganyRuntimeBlocks368A
    dw JohtoIcePathB2FMahoganyTextPointers368A
    dw JohtoIcePathB2FMahoganyScript368A
    db 0 ; no map connections; all arrivals require registered Gold Warp
    dw JohtoIcePathB2FMahoganyObjects368A
JohtoIcePathB2FMahoganyRuntimeHeader368AEnd::
ASSERT JohtoIcePathB2FMahoganyRuntimeHeader368AEnd - JohtoIcePathB2FMahoganyRuntimeHeader368A == 12
ASSERT BANK(JohtoIcePathB2FMahoganyRuntimeHeader368A) == BANK(JohtoIcePathB2FMahoganyRuntimeBlocks368A)

JohtoIcePathB2FMahoganyScript368A::
    call EnableAutoTextBoxDrawing
    callab JohtoIcePathInitializePitState369B
    jp JohtoIcePathB2FMahoganySyncLanded369B
JohtoIcePathB2FMahoganyTextPointers368A:
    dw JohtoIcePathB2FMahoganyStoneText369A
    dw JohtoIcePathB2FMahoganyStoneText369A
    dw JohtoIcePathB2FMahoganyStoneText369A
    dw JohtoIcePathB2FMahoganyStoneText369A
JohtoIcePathB2FMahoganyStoneText369A:
    text "It's stuck deep"
    line "in the ice."
    done
    db "@"
ASSERT BANK(JohtoIcePathB2FMahoganyStoneText369A) == BANK(JohtoIcePathB2FMahoganyRuntimeHeader368A)
JohtoIcePathB2FMahoganyObjects368A::
    db $19 ; Gold B2F Mahogany border: rock wall (Gold map_attributes), not floor $09
    db 6 ; Gold six ordinals: #1/#2 are exit ladders; #3-#6 arrival-only ICE
    db 1, 17, 1, JOHTO_REGISTERED_WARP_SELECTOR ; #1 -> B1F Gold #2
    db 11, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; #2 -> B3F Gold #1
    db 4, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR ; #3 PIT receive-only, no return
    db 6, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR ; #4 PIT receive-only, no return
    db 12, 4, 4, JOHTO_REGISTERED_WARP_SELECTOR ; #5 PIT receive-only, no return
    db 12, 12, 5, JOHTO_REGISTERED_WARP_SELECTOR ; #6 PIT receive-only, no return
    db 0 ; no sign / item / encounter
    db 4 ; Gold lower-floor rocks appear only after their B1F PIT is filled
    object SPRITE_BOULDER, 11, 3, STAY, NONE, $1
    object SPRITE_BOULDER, 4, 7, STAY, NONE, $2
    object SPRITE_BOULDER, 3, 12, STAY, NONE, $3
    object SPRITE_BOULDER, 12, 13, STAY, NONE, $4

; Gold 20 x 18 8x8 role lookup, B=Y C=X. Fail closed outside the map.
JohtoIcePathB2FMahoganyRoleAt368A::
    push de
    ld a, b
    cp 18
    jr nc, .wall
    ld a, c
    cp 20
    jr nc, .wall
    ld l, b
    ld h, 0
    add hl, hl
    add hl, hl ; 4*y
    ld d, h
    ld e, l
    add hl, hl ; 8*y
    add hl, hl ; 16*y
    add hl, de ; 20*y
    ld d, 0
    ld e, c
    add hl, de
    ld de, JohtoIcePathB2FMahoganyGoldRoles368A
    add hl, de
    ld a, [hl]
    pop de
    ret
.wall
    ld a, 1
    pop de
    ret

JohtoIcePathB2FMahoganyRoleAhead368A::
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
    jr .read
.up
    dec b
    jr .read
.down
    inc b
    jr .read
.left
    dec c
.read
    call JohtoIcePathB2FMahoganyRoleAt368A
    jr .done
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

; E=0: Gold FLOOR or ICE pass, and only B1F return ladder (17,1).
; E=1: wall, PIT arrivals, any unimplemented role/edge; only two ladders pass.
JohtoIcePathB2FMahoganyLandDecision368A::
    ld e, 1
    call JohtoIcePathB2FMahoganyRoleAhead368A
    and a ; Gold role 0 FLOOR
    jr z, .allow
    cp 2 ; Gold ICE is ordinary walking until slide stage
    jr z, .allow
    cp 4 ; Gold ladder: must match B1F Gold #2 return
    ret nz
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .notUp
    dec b
    jr .stair
.notUp
    cp PLAYER_DIR_DOWN
    jr nz, .notDown
    inc b
    jr .stair
.notDown
    cp PLAYER_DIR_LEFT
    jr nz, .notLeft
    dec c
    jr .stair
.notLeft
    cp PLAYER_DIR_RIGHT
    ret nz
    inc c
.stair
    ld a, c
    cp 17
    jr nz, .b3fLadder
    ld a, b
    cp 1
    jr z, .allow
    ret
.b3fLadder
    cp 9
    ret nz
    ld a, b
    cp 11
    ret nz
.allow
    ld e, 0
    ret

; Only Gold FLOOR role 0 permits mounting anew. ICE never does.
JohtoIcePathB2FMahoganyBikeFloorAllowed368A::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB2FMahoganyRoleAt368A
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
JohtoIcePathB2FMahoganyIsIce368F::
    push bc
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB2FMahoganyRoleAt368A
    cp 2
    pop bc ; preserve the ICE equality flag
    ret

; The Gold B2F warp slots #3..#6 are receive-only; a dropped stone is
; a stationary obstacle, not a new warp or a movable Strength sprite.
; Use only persistent hole bits; other object and save data stay unchanged.
; Hidden receiver rocks keep the original nonzero picture ID and VRAM slot.
; On Save/text return, InitMapSprites enumerates all wNumSprites slots and
; subtracts one from every picture ID before SpriteSheetPointerTable lookup.
; Setting a hidden rock ID to zero is invalid and can read rogue sprite data.
JohtoIcePathB2FMahoganySyncLanded369B::
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
    bit 2, a
    jr nz, .second
    xor a
    ; Missing B1F drop must not leave an invisible collision body.
    dec a ; $ff off map
    ld [wSpriteStateData1 + $12], a ; hide current rendered OAM frame before fade
    ld [wSpriteStateData2 + $14], a
    ld [wSpriteStateData2 + $15], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
.second
    bit 3, a
    jr nz, .third
    xor a
    ; Missing B1F drop must not leave an invisible collision body.
    dec a ; $ff off map
    ld [wSpriteStateData1 + $22], a ; hide current rendered OAM frame before fade
    ld [wSpriteStateData2 + $24], a
    ld [wSpriteStateData2 + $25], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
.third
    bit 4, a
    jr nz, .fourth
    xor a
    ; Missing B1F drop must not leave an invisible collision body.
    dec a ; $ff off map
    ld [wSpriteStateData1 + $32], a ; hide current rendered OAM frame before fade
    ld [wSpriteStateData2 + $34], a
    ld [wSpriteStateData2 + $35], a
    ld a, [wEventFlags + JOHTO_ICE_PATH_PIT_FLAGS_369B]
.fourth
    bit 5, a
    ret nz
    xor a
    ; Missing B1F drop must not leave an invisible collision body.
    dec a ; $ff off map
    ld [wSpriteStateData1 + $42], a ; hide current rendered OAM frame before fade
    ld [wSpriteStateData2 + $44], a
    ld [wSpriteStateData2 + $45], a
    ret
