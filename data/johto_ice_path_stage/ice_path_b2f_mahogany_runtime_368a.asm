; REF-368A: Ice Path B2F Mahogany Side (Gold stable ID96), walk-only pilot.
; B1F Gold #2 <-> B2F Gold #1; B3F Gold #1 <-> B2F Gold #2 now live.
; Gold ICE is ordinary walkable floor for now; dropped boulders and four
; ICE arrival-only slots #3-#6 are deliberately not active source warps.
; ICE movement is now handled by the shared live slide controller; PIT arrivals, Strength, items and NPCs remain disabled.
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
    ret
JohtoIcePathB2FMahoganyTextPointers368A:
JohtoIcePathB2FMahoganyObjects368A::
    db $09 ; Gold ice cave border block
    db 6 ; Gold six source ordinals; only #1 is an active stair
    db 1, 17, 1, JOHTO_REGISTERED_WARP_SELECTOR ; #1 -> B1F Gold #2
    db 11, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; #2 -> B3F Gold #1
    db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR ; #3 PIT arrival ICE, never return
    db $ff, $ff, 3, JOHTO_REGISTERED_WARP_SELECTOR ; #4 PIT arrival ICE, never return
    db $ff, $ff, 4, JOHTO_REGISTERED_WARP_SELECTOR ; #5 PIT arrival ICE, never return
    db $ff, $ff, 5, JOHTO_REGISTERED_WARP_SELECTOR ; #6 PIT arrival ICE, never return
    db 0 ; no sign / item / encounter
    db 0 ; no NPC or dropped boulder objects before Strength implementation

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
