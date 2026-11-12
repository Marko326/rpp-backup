; REF-367B dormant Ice Path 8x8 Gold role lookup. NOT INCLUDED in main.asm.
; Enable only together with tile/header registration, ICE slide, 4 Strength
; stones and 4 PIT transitions.  No Rock Smash objects at this stage.
;
; ABI when this is installed in the chosen ROMX bank:
; input: B=Y, C=X, wCurLocalMapID = one of 70/95/96/97/98.
; output: A=role index in docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json
;         (unsupported map or out-of-bounds returns role 1 = WALL).
; preserves: BC, DE; clobbers HL and flags.  No SBC HL,DE on LR35902.
;
; NOTE: Exact physical map width, height and role order matter.  In particular,
; ID97 is 10x18 and cannot use ID96's 20-wide role rows.
JohtoIcePathGoldRoleAt367B::
    push de
    ld a, [wCurLocalMapID]
    cp JOHTO_ICE_PATH_1F_LOCAL_ID
    jp z, .map1f
    cp JOHTO_ICE_PATH_B1F_LOCAL_ID
    jp z, .mapb1f
    cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID
    jp z, .mapb2fm
    cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID
    jp z, .mapb2fb
    cp JOHTO_ICE_PATH_B3F_LOCAL_ID
    jp z, .mapb3f
    jp .wall
.map1f
    ld a, b
    cp 36
    jp nc, .wall
    ld a, c
    cp 40
    jp nc, .wall
    ld de, JohtoIcePath1FRoleBytes367B
    jp .width40
.mapb1f
    ld a, b
    cp 36
    jp nc, .wall
    ld a, c
    cp 20
    jp nc, .wall
    ld de, JohtoIcePathB1FRoleBytes367B
    jp .width20
.mapb2fm
    ld a, b
    cp 18
    jp nc, .wall
    ld a, c
    cp 20
    jp nc, .wall
    ld de, JohtoIcePathB2FMahoganyRoleBytes367B
    jp .width20
.mapb2fb
    ld a, b
    cp 18
    jp nc, .wall
    ld a, c
    cp 10
    jp nc, .wall
    ld de, JohtoIcePathB2FBlackthornRoleBytes367B
    jp .width10
.mapb3f
    ld a, b
    cp 18
    jp nc, .wall
    ld a, c
    cp 20
    jp nc, .wall
    ld de, JohtoIcePathB3FRoleBytes367B
    jp .width20
.width40
    push de                    ; role base
    ld l, b
    ld h, 0
    add hl, hl                 ; 2*y
    add hl, hl                 ; 4*y
    add hl, hl                 ; 8*y
    ld d, h
    ld e, l                    ; DE = 8*y
    add hl, hl                 ; 16*y
    add hl, hl                 ; 32*y
    add hl, de                 ; 40*y
    jp .addX
.width20
    push de                    ; role base
    ld l, b
    ld h, 0
    add hl, hl                 ; 2*y
    add hl, hl                 ; 4*y
    ld d, h
    ld e, l                    ; DE = 4*y
    add hl, hl                 ; 8*y
    add hl, hl                 ; 16*y
    add hl, de                 ; 20*y
    jp .addX
.width10
    push de                    ; role base
    ld l, b
    ld h, 0
    add hl, hl                 ; 2*y
    ld d, h
    ld e, l                    ; DE = 2*y
    add hl, hl                 ; 4*y
    add hl, hl                 ; 8*y
    add hl, de                 ; 10*y
.addX
    ld d, 0
    ld e, c
    add hl, de                 ; width*y + x
    pop de                     ; role base
    add hl, de
    ld a, [hl]
    pop de                     ; original DE
    ret
.wall
    ld a, 1                    ; Gold WALL role index
    pop de
    ret

; Stored alongside lookup when this file is *eventually* included.  The
; staged guards keep all five map IDs inactive until the remaining game engine
; behaviour is complete; these INCBINs do not currently consume ROM space.
JohtoIcePath1FRoleBytes367B::
    INCBIN "data/johto_ice_path_stage/IcePath1F.roles.bin"
ASSERT @ - JohtoIcePath1FRoleBytes367B == 40 * 36
JohtoIcePathB1FRoleBytes367B::
    INCBIN "data/johto_ice_path_stage/IcePathB1F.roles.bin"
ASSERT @ - JohtoIcePathB1FRoleBytes367B == 20 * 36
JohtoIcePathB2FMahoganyRoleBytes367B::
    INCBIN "data/johto_ice_path_stage/IcePathB2FMahoganySide.roles.bin"
ASSERT @ - JohtoIcePathB2FMahoganyRoleBytes367B == 20 * 18
JohtoIcePathB2FBlackthornRoleBytes367B::
    INCBIN "data/johto_ice_path_stage/IcePathB2FBlackthornSide.roles.bin"
ASSERT @ - JohtoIcePathB2FBlackthornRoleBytes367B == 10 * 18
JohtoIcePathB3FRoleBytes367B::
    INCBIN "data/johto_ice_path_stage/IcePathB3F.roles.bin"
ASSERT @ - JohtoIcePathB3FRoleBytes367B == 20 * 18
