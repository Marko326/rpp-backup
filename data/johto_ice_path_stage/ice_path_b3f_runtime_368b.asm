; REF-368B: original Gold fourth Ice Path floor B3F (stable local ID98).
; Gold warp #1 (3,5) <-> Mahogany B2F #2 (9,11) only.
; Gold warp #2 (15,5) leads to active Blackthorn B2F Gold #2.
; No Gold ICE cells on B3F; Rock Smash, NeverMeltIce and Strength/PIT are not activated.
JohtoIcePathB3FRuntimeBlocks368B::
    INCBIN "maps/johto_ice_path_stage/IcePathB3F.runtime.blk"
ASSERT @ - JohtoIcePathB3FRuntimeBlocks368B == 10 * 9
JohtoIcePathB3FGoldRoles368B::
    INCBIN "data/johto_ice_path_stage/IcePathB3F.roles.bin"
ASSERT @ - JohtoIcePathB3FGoldRoles368B == 20 * 18

JohtoIcePathB3FRuntimeHeader368B::
    db JOHTO_ICE_PATH
    db 9, 10
    dw JohtoIcePathB3FRuntimeBlocks368B
    dw JohtoIcePathB3FTextPointers368B
    dw JohtoIcePathB3FScript368B
    db 0 ; no map connections
    dw JohtoIcePathB3FObjects368B
JohtoIcePathB3FRuntimeHeader368BEnd::
ASSERT JohtoIcePathB3FRuntimeHeader368BEnd - JohtoIcePathB3FRuntimeHeader368B == 12
ASSERT BANK(JohtoIcePathB3FRuntimeHeader368B) == BANK(JohtoIcePathB3FRuntimeBlocks368B)

JohtoIcePathB3FScript368B::
    call EnableAutoTextBoxDrawing
    ret
JohtoIcePathB3FTextPointers368B:
JohtoIcePathB3FObjects368B::
    db $19 ; Gold Ice Path B3F border block 25 (Gold source)
    db 2 ; Gold #1/#2: only Mahogany return active
    db 5, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR ; #1 -> Mahogany B2F Gold #2
    db 5, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR ; #2 -> Blackthorn B2F Gold #2
    db 0 ; no sign/item/event
    db 0 ; no NPC, smash rock, or NeverMeltIce object yet

; Gold role lookup 20 columns x 18 rows; B=Y, C=X, outside = WALL.
JohtoIcePathB3FRoleAt368B::
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
    ld de, JohtoIcePathB3FGoldRoles368B
    add hl, de
    ld a, [hl]
    pop de
    ret
.wall
    ld a, 1
    pop de
    ret

JohtoIcePathB3FRoleAhead368B::
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
    call JohtoIcePathB3FRoleAt368B
    jr .done
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

; E=0: Gold FLOOR or ICE pass, and only B1F return ladder (17,1).
; E=1: wall, sealed B3F (9,11), any unimplemented role/edge.
; E=0: walkable Gold FLOOR, or original Mahogany return LADDER (3,5).
; E=1: Gold WALL or unimplemented roles; both Gold ladders are live.
JohtoIcePathB3FLandDecision368B::
    ld e, 1
    call JohtoIcePathB3FRoleAhead368B
    and a ; Gold FLOOR
    jr z, .allow
    cp 4 ; Gold LADDER
    ret nz
    ; A ladder must be the known (3,5) Mahogany-side return.
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
    ret nz
    inc c
    jr .stair
.up
    dec b
    jr .stair
.down
    inc b
    jr .stair
.left
    dec c
.stair
    ld a, c
    cp 3
    jr z, .checkY
    cp 15
    ret nz
.checkY
    ld a, b
    cp 5
    ret nz
.allow
    ld e, 0
    ret

; Gold CAVE allows mounting on FLOOR only; preserve pre-existing ride state.
JohtoIcePathB3FBikeFloorAllowed368B::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB3FRoleAt368B
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
JohtoIcePathB3FIsIce368F::
    push bc
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB3FRoleAt368B
    cp 2
    pop bc ; preserve the ICE equality flag
    ret
