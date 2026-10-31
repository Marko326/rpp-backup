; R33-266: Route33 Gold 10x9, exact modern art + coordinate collision.
JohtoModern_GFX:: INCBIN "gfx/tilesets/johto_modern.2bpp"
JohtoModern_Block:: INCBIN "gfx/blocksets/johto_modern.bst"
JohtoModern_BlockEnd::
ASSERT JohtoModern_BlockEnd - JohtoModern_Block == 128 * 16
JohtoRoute33RuntimeBlocks::
    INCBIN "maps/johto_pilot/Route33.runtime.blk"
JohtoRoute33RuntimeBlocksEnd::
ASSERT JohtoRoute33RuntimeBlocksEnd - JohtoRoute33RuntimeBlocks == JOHTO_ROUTE_33_WIDTH * JOHTO_ROUTE_33_HEIGHT
JohtoRoute33RuntimeHeader::
    db JOHTO_MODERN
    db JOHTO_ROUTE_33_HEIGHT, JOHTO_ROUTE_33_WIDTH
    dw JohtoRoute33RuntimeBlocks
    dw JohtoRoute33TextPointers
    dw JohtoRoute33Script
    db WEST ; Source-verified Route33 -> Azalea exterior Gold 0 offset
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoSouthAzaleaTownBlocks + 20 - 3
    dw wOverworldMap + 3 * (JOHTO_ROUTE_33_WIDTH + 6)
    db JOHTO_ROUTE_33_HEIGHT
    db 20
    db 0
    db 39
    dw wOverworldMap + 6 + 2 * 20
    dw JohtoRoute33RuntimeObjects
JohtoRoute33RuntimeHeaderEnd::
ASSERT JohtoRoute33RuntimeHeaderEnd - JohtoRoute33RuntimeHeader == 23
ASSERT BANK(JohtoRoute33RuntimeHeader) == BANK(JohtoRoute33RuntimeBlocks)
JohtoRoute33Script::
    call EnableAutoTextBoxDrawing
    ret
JohtoRoute33TextPointers:
    dw JohtoRoute33Sign
JohtoRoute33Sign:
    text "ROUTE 33"
    done
    db "@"
JohtoRoute33RuntimeObjects::
    db $05 ; Gold outside border; no unregistered region seams
    db 1 ; precise Gold cave entrance at (11,9)
    db 9, 11, 1, JOHTO_REGISTERED_WARP_SELECTOR ; cave's new south ordinal 1
    db 1
    db 11, 11, 1
    db 0 ; trainer/fruit tree withheld pending event implementation

; Each byte is the exact Gold 16x16 collision role at (x,y), with
; 0 for FLOOR/GRASS/HOP and 1 for solid/other; 20*18 bytes.
JohtoRoute33BlockedCells::
    INCBIN "maps/johto_pilot/Route33.blocked_mask.bin"
JohtoRoute33BlockedCellsEnd::
ASSERT JohtoRoute33BlockedCellsEnd - JohtoRoute33BlockedCells == 20 * 18

; Return E=2 for any other map, E=1 for blocked, E=0 for allowed.
; Exactly one CAVE landing exception from (11,10) looking north.
; Do NOT override sprite collision (caller checks it first).
JohtoRoute33StepPolicy::
    ld e, 2
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_33_LOCAL_ID
    ret nz
    ld e, 1
    ld a, [wXCoord]
    ld b, a
    ld a, [wYCoord]
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
    inc b
    jr .bounds
.up
    ld a, b
    cp 11
    jr nz, .upNormal
    ld a, c
    cp 10
    jr nz, .upNormal
    ld e, 0 ; Gold CAVE special entrance (11,9), never another wall
    ret
.upNormal
    dec c
    jr .bounds
.down
    inc c
    jr .bounds
.left
    ; FIX-269: the Gold Route33/Azalea west connector is x=0,
    ; y=14/15.  An 8-bit DEC here wraps the target x to $ff and
    ; the generic bounds check creates an invisible wall despite the
    ; prior outdoor-seam guard allowing it.  Only this verified lane
    ; may leave the map; every other west-border coordinate stays solid.
    ld a, b
    and a
    jr nz, .leftInside
    ld a, c
    cp 14
    jp z, .seamAllowed
    cp 15
    jp z, .seamAllowed
    ret
.leftInside
    dec b
.bounds
    ld a, b
    cp JOHTO_ROUTE_33_WIDTH * 2
    ret nc
    ld a, c
    cp JOHTO_ROUTE_33_HEIGHT * 2
    ret nc
    ; 16-bit index = y*20+x, because the original map is 20x18 cells.
    ld l, c
    ld h, 0
    add hl, hl
    add hl, hl ; 4*y
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl ; 16*y
    add hl, de ; 20*y
    ld d, 0
    ld e, b
    add hl, de
    ld de, JohtoRoute33BlockedCells
    add hl, de
    ld e, [hl]
    ret
.seamAllowed
    ld e, 0
    ret
