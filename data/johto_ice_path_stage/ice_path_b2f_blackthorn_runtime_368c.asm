; REF-368C: Gold Ice Path B2F Blackthorn Side, stable ID97, 5x9 blocks.
; STEP_IN Gold #1 (3,15) <-> B1F #8 (5,25)
; STEP_IN Gold #2 (3,3) <-> B3F #2 (15,5).
; Gold ICE is passable with live automatic sliding; Strength/PIT/items/NPCs remain unfinished.
JohtoIcePathB2FBlackthornRuntimeBlocks368C::
    INCBIN "maps/johto_ice_path_stage/IcePathB2FBlackthornSide.runtime.blk"
ASSERT @ - JohtoIcePathB2FBlackthornRuntimeBlocks368C == 5 * 9
JohtoIcePathB2FBlackthornGoldRoles368C::
    INCBIN "data/johto_ice_path_stage/IcePathB2FBlackthornSide.roles.bin"
ASSERT @ - JohtoIcePathB2FBlackthornGoldRoles368C == 10 * 18

JohtoIcePathB2FBlackthornRuntimeHeader368C::
    db JOHTO_ICE_PATH
    db 9, 5
    dw JohtoIcePathB2FBlackthornRuntimeBlocks368C
    dw JohtoIcePathB2FBlackthornTextPointers368C
    dw JohtoIcePathB2FBlackthornScript368C
    db 0 ; no map connection
    dw JohtoIcePathB2FBlackthornObjects368C
JohtoIcePathB2FBlackthornRuntimeHeader368CEnd::
ASSERT JohtoIcePathB2FBlackthornRuntimeHeader368CEnd - JohtoIcePathB2FBlackthornRuntimeHeader368C == 12
ASSERT BANK(JohtoIcePathB2FBlackthornRuntimeHeader368C) == BANK(JohtoIcePathB2FBlackthornRuntimeBlocks368C)

JohtoIcePathB2FBlackthornScript368C::
    call EnableAutoTextBoxDrawing
    ret
JohtoIcePathB2FBlackthornTextPointers368C:
JohtoIcePathB2FBlackthornObjects368C::
    db $19 ; original Gold border block 25 (Blackthorn B2F)
    db 2 ; original Gold #1/#2 source ordinals
    db 15, 3, 7, JOHTO_REGISTERED_WARP_SELECTOR ; #1 -> B1F Gold #8
    db 3, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR ; #2 -> B3F Gold #2
    db 0 ; no hidden Ice Heal; not implemented
    db 0 ; no TM Rest/item objects; not implemented

; Role grid is 10 columns by 18 rows: use y*10+x (not Mahogany width 20).
; BC=Y/X; A=Gold role, with off-edge and wrap blocked as WALL.
JohtoIcePathB2FBlackthornRoleAt368C::
    push de
    ld a, b
    cp 18
    jr nc, .wall
    ld a, c
    cp 10
    jr nc, .wall
    ld l, b
    ld h, 0
    add hl, hl ; 2*y
    ld d, h
    ld e, l
    add hl, hl ; 4*y
    add hl, hl ; 8*y
    add hl, de ; 10*y
    ld d, 0
    ld e, c
    add hl, de
    ld de, JohtoIcePathB2FBlackthornGoldRoles368C
    add hl, de
    ld a, [hl]
    pop de
    ret
.wall
    ld a, 1
    pop de
    ret

; BC receives the target XY; A receives the Gold role, and BC is restored.
JohtoIcePathB2FBlackthornRoleAhead368C::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    cp PLAYER_DIR_RIGHT
    jr nz, .invalid
    inc c
    jr .read
.north
    dec b
    jr .read
.south
    inc b
    jr .read
.west
    dec c
.read
    call JohtoIcePathB2FBlackthornRoleAt368C
    jr .done
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

; Gold one-way ledges: directed jumps are handled by HandleLedges;
; directional walls are not generic solid blocks. A normal step is denied
; for illegal crossing, and only the two registered ladders can be entered.
; E=0 pass, E=1 block (including invalid/edge coordinates).
JohtoIcePathB2FBlackthornLandDecision368C::
    ld e, 1
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    push hl
    call JohtoIcePathB2FBlackthornRoleAt368C
    pop hl
    cp 6 ; Gold UP_WALL cannot exit north
    jr z, .currentWall
    cp 7 ; HOP_DOWN cannot reverse north
    jr z, .currentDownHop
    cp 8 ; HOP_DOWN_LEFT rejects north/right
    jr z, .currentDownLeftHop
    jr .target
.currentWall
.currentDownHop
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    jr .target
.currentDownLeftHop
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    cp PLAYER_DIR_RIGHT
    ret z
.target
    call JohtoIcePathB2FBlackthornRoleAhead368C
    and a ; FLOOR
    jp z, .allow
    cp 2 ; ICE walk-only
    jp z, .allow
    cp 1 ; WALL
    ret z
    cp 6 ; crossing northern edge of UP_WALL from above forbidden
    jr nz, .ledge
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret z
    jr .allow
.ledge
    cp 7 ; HOP_DOWN may be entered only from north or sideways
    jr nz, .ledgeLeft
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    jr .allow
.ledgeLeft
    cp 8 ; HOP_DOWN_LEFT only DOWN/LEFT
    jr nz, .ladder
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    cp PLAYER_DIR_RIGHT
    ret z
    jr .allow
.ladder
    cp 4 ; Gold LADDER must match exactly #1 or #2
    ret nz
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    cp PLAYER_DIR_RIGHT
    ret nz
    inc c
    jr .stair
.north
    dec b
    jr .stair
.south
    inc b
    jr .stair
.west
    dec c
.stair
    ld a, c
    cp 3
    ret nz
    ld a, b
    cp 3
    jr z, .allow
    cp 15
    ret nz
.allow
    ld e, 0
    ret

; Bike can newly mount on FLOOR only; ICE, HOP, WALL and stairs disallow it.
JohtoIcePathB2FBlackthornBikeFloorAllowed368C::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB2FBlackthornRoleAt368C
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
JohtoIcePathB2FBlackthornIsIce368F::
    push bc
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePathB2FBlackthornRoleAt368C
    cp 2
    pop bc ; preserve the ICE equality flag
    ret
