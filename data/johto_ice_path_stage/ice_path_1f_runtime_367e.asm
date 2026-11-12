; REF-367F: LIVE Ice Path 1F (stable ID70) ordinary-walking preview.
; Separate Gold ice tileset is registered, only outdoor Warp #1/#2 active.
; Gold ICE cells are temporarily normal walkable terrain; no auto-slide.
; Gold B1F stairs #3/#4 now connect the two B1F return ladders.
; Not an R2 completion of the full Ice Path; no Strength, Rock Smash,
; wild events or NPCs. B1F preview has blocked lower-floor exits.

JohtoIcePath1FGoldGFX367E::
    INCBIN "gfx/tilesets/johto_ice_path_gold_96tiles.bin"
ASSERT @ - JohtoIcePath1FGoldGFX367E == 96 * 16
JohtoIcePath1FGoldBlocks367E::
    INCBIN "gfx/blocksets/johto_ice_path_gold.bst"
ASSERT @ - JohtoIcePath1FGoldBlocks367E == 64 * 16
JohtoIcePath1FGoldRoles367E::
    INCBIN "data/johto_ice_path_stage/IcePath1F.roles.bin"
ASSERT @ - JohtoIcePath1FGoldRoles367E == 40 * 36
JohtoIcePath1FRuntimeBlocks367E::
    INCBIN "maps/johto_ice_path_stage/IcePath1F.runtime.blk"
ASSERT @ - JohtoIcePath1FRuntimeBlocks367E == 20 * 18

JohtoIcePath1FRuntimeHeader367E::
    db JOHTO_ICE_PATH
    db 18, 20
    dw JohtoIcePath1FRuntimeBlocks367E
    dw JohtoIcePath1FTextPointers367E
    dw JohtoIcePath1FScript367E
    db 0 ; no map connections (all entrances use Gold Warp)
    dw JohtoIcePath1FObjects367E
JohtoIcePath1FRuntimeHeader367EEnd::
ASSERT JohtoIcePath1FRuntimeHeader367EEnd - JohtoIcePath1FRuntimeHeader367E == 12
ASSERT BANK(JohtoIcePath1FRuntimeHeader367E) == BANK(JohtoIcePath1FRuntimeBlocks367E)
ASSERT BANK(JohtoIcePath1FGoldGFX367E) == BANK(JohtoIcePath1FGoldBlocks367E)

JohtoIcePath1FScript367E::
    call EnableAutoTextBoxDrawing
    ret
JohtoIcePath1FTextPointers367E:
JohtoIcePath1FObjects367E::
    db $09 ; Gold Ice Path border block
    db 4 ; retain Gold #1/#2 outdoors AND #3/#4 stair ordinal slots
    ; Object format is Y, X, 0-based DESTINATION warp ordinal, selector.
    db 19, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #1 -> Route44 #1
    db 27, 36, 1, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #2 -> Blackthorn #7
    db 5, 37, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #3 to B1F Gold #1
    db 13, 37, 6, JOHTO_REGISTERED_WARP_SELECTOR ; Gold #4 to B1F Gold #7
    db 0 ; no signs / items / encounters
    db 0 ; no NPCs or Rock Smash objects

; REF-367F walk-only Ice Path 1F.  ICE (role2) is ordinary walkable FLOOR
; during 1F layout testing. Gold ladder (role4) enters active B1F.
; Role indexes sourced from the original Gold block collision, not the
; compact visual tile IDs.  This is NEVER a full Ice Path R2 implementation.
JohtoIcePath1FRoleAt367F::
    push de
    ld a, b
    cp 36
    jr nc, .wall
    ld a, c
    cp 40
    jr nc, .wall
    ld l, b
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de
    ld d, 0
    ld e, c
    add hl, de
    ld de, JohtoIcePath1FGoldRoles367E
    add hl, de
    ld a, [hl]
    pop de
    ret
.wall
    ld a, 1
    pop de
    ret

JohtoIcePath1FRoleAhead367F::
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
    call JohtoIcePath1FRoleAt367F
    jr .done
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

JohtoIcePath1FLandDecision367F::
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
    call JohtoIcePath1FRoleAt367F
    pop hl
    pop bc
    cp 6 ; cannot leave UP_WALL northward
    ret z
.target
    call JohtoIcePath1FRoleAhead367F
    cp 1 ; WALL
    ret z
    cp 3 ; PIT: not implemented on 1F
    ret z
    cp 4 ; Gold LADDER: exactly these two 1F stair positions are open
    jr nz, .notLadder367K
    ; Both role-4 positions are registered Warp objects and safe to enter.
    jr .allow
.notLadder367K:
    cp 6 ; cannot enter UP_WALL from above
    jr nz, .hopDown
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret z
    jr .allow
.hopDown
    cp 7
    jr nz, .hopDownLeft
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    jr .allow
.hopDownLeft
    cp 8
    jr nz, .allow
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    cp PLAYER_DIR_RIGHT
    ret z
.allow
    ld e, 0 ; FLOOR / ICE / carpet / legal ledge is WALKABLE
    ret

; REF-367J: Gold CAVE bike permission for the single active Ice Path 1F.
; Preserve Gold FLOOR_TILE semantics: FLOOR(0) or carpet(5) may mount;
; ICE(2), walls, ladders and ledges cannot start a fresh ride.
; Existing mounted sprite is handled by the public IsBikeRidingAllowed caller.
; Carry set = may mount, carry clear = denied.
JohtoIcePath1FBikeFloorAllowed367J::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoIcePath1FRoleAt367F
    pop hl
    pop bc
    and a ; Gold FLOOR role=0
    jr z, .allowed
    cp 5 ; Gold WARP_CARPET_DOWN also has FLOOR permission
    jr z, .allowed
    and a ; clear carry for ICE, WALL, LADDER, HOP and UP_WALL
    ret
.allowed
    scf
    ret
