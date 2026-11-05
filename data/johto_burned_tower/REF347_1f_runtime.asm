; REF-347 Burned Tower 1F, upgraded in REF-348 with active PIT/ladder routes.
; 1F is TOWER/DAY, never JOHTO_UNION_CAVE/NITE.
JohtoBurnedTower1F_GFX:: INCBIN "gfx/tilesets/johto_burned_tower_1f.2bpp"
JohtoBurnedTower1F_Block:: INCBIN "gfx/blocksets/johto_burned_tower_1f.bst"
JohtoBurnedTower1F_BlockEnd::
ASSERT JohtoBurnedTower1F_BlockEnd - JohtoBurnedTower1F_Block == 64 * 16
JohtoBurnedTower1FRuntimeBlocks:: INCBIN "maps/johto_pilot/BurnedTower1F.runtime.blk"
JohtoBurnedTower1FRuntimeBlocksEnd::
ASSERT JohtoBurnedTower1FRuntimeBlocksEnd - JohtoBurnedTower1FRuntimeBlocks == 10 * 9
JohtoBurnedTower1FRuntimeHeader::
    db JOHTO_BURNED_TOWER_1F
    db 9, 10
    dw JohtoBurnedTower1FRuntimeBlocks
    dw JohtoBurnedTower1FTextPointers
    dw JohtoBurnedTower1FScript
    db 0 ; no cardinals
    dw JohtoBurnedTower1FRuntimeObjects
JohtoBurnedTower1FRuntimeHeaderEnd::
ASSERT JohtoBurnedTower1FRuntimeHeaderEnd - JohtoBurnedTower1FRuntimeHeader == 12
ASSERT BANK(JohtoBurnedTower1FRuntimeHeader) == BANK(JohtoBurnedTower1FRuntimeBlocks)
JohtoBurnedTower1FScript::
    call EnableAutoTextBoxDrawing
    ret
JohtoBurnedTower1FTextPointers:
JohtoBurnedTower1FRuntimeObjects::
    db $00 ; Gold border
    db 14 ; Gold order: two DOWN carpets, eleven PITs, one lower ladder
    db 15, 9, 5, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal0 carpet -> Ecruteak Gold #13
    db 15, 10, 5, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal1 carpet -> Ecruteak Gold #13
    db 4, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal2 Gold (5,4) PIT -> B1F arrival0
    db 5, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal3 Gold (5,5) PIT -> arrival0
    db 6, 5, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal4 Gold (5,6) PIT -> arrival0
    db 6, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal5 Gold (4,6) PIT -> arrival0
    db 4, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal6 Gold (15,4) PIT -> arrival1
    db 5, 15, 1, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal7 Gold (15,5) PIT -> arrival1
    db 7, 10, 2, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal8 Gold (10,7) PIT -> arrival2
    db 14, 5, 3, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal9 Gold (5,14) PIT -> arrival3
    db 14, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal10 Gold (4,14) PIT -> arrival3
    db 14, 14, 4, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal11 Gold (14,14) PIT -> arrival4
    db 14, 15, 4, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal12 Gold (15,14) PIT -> arrival4
    db 15, 7, 5, JOHTO_REGISTERED_WARP_SELECTOR ; ordinal13 Gold (7,15) ladder -> B1F ladder5
    db 0 ; no signs
    db 0 ; no actors/plot

; Original Gold 16x16 role grid: FLOOR=0, LADDER=1, PIT=2, WALL=3, CARPET=4.
; REF-348 opens active PIT/LADDER cells; Gold walls remain blocked.
JohtoBurnedTower1FRoles:: INCBIN "maps/johto_pilot/BurnedTower1F.gold_roles.bin"
ASSERT @ - JohtoBurnedTower1FRoles == 20 * 18

; Called through existing ROM0 land gateway (callab). E=0 pass, E=1 block.
; Exact source/target cell, not a visual-tile-only whitelist.
JohtoBurnedTower1FLandDecision::
    push bc
    push hl
    push de
    ld a, [wXCoord]
    ld e, a
    ld a, [wYCoord]
    ld d, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jr nz, .blocked
    inc e
    jr .bounds
.up
    dec d
    jr .bounds
.down
    inc d
    jr .bounds
.left
    dec e
.bounds
    ld a, e
    cp 20
    jr nc, .blocked
    ld a, d
    cp 18
    jr nc, .blocked
    ld hl, JohtoBurnedTower1FRoles
    ld bc, 20
.row
    ld a, d
    and a
    jr z, .column
    add hl, bc
    dec d
    jr .row
.column
    ld d, 0
    add hl, de
    ld a, [hl]
    cp 0 ; FLOOR
    jr z, .open
    cp 1 ; Gold LADDER, active step-in trigger
    jr z, .open
    cp 2 ; Gold PIT, active step-in trigger
    jr z, .open
    cp 4 ; Gold WARP_CARPET_DOWN, directional exit
    jr z, .open
.blocked
    ld a, 1
    jr .done
.open
    xor a
.done
    pop de
    pop hl
    pop bc
    ld e, a
    ret

; Exterior is a normal Gold step-in DOOR, like an existing center/house.
; BeforeStep uses the coordinate before stepping up, after-step uses the door cell.
JohtoBurnedTowerCityBeforeStep::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 5
    ret nz
    ld a, [wYCoord]
    cp 6
    ret nz
    ld e, 1
    ret
JohtoBurnedTowerCityAfterStep::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret nz
    ld a, [wXCoord]
    cp 5
    ret nz
    ld a, [wYCoord]
    cp 5
    ret nz
    ld e, 2 ; STEP_ON, not a standing direction carpet
    ret

; Both interiors exit only by pressing DOWN on the exact bottom carpets.
JohtoBurnedTower1FDownCarpet::
    ld e, 0
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 15
    ret nz
    ld a, [wXCoord]
    cp 9
    jr z, .yes
    cp 10
    ret nz
.yes
    ld e, 1
    ret
