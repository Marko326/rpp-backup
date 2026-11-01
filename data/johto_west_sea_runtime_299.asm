; MAP-299: Olivine west -> Route40 -> Route41 -> Cianwood outdoor sea chain.
; Gold blocks and mature NPC-243 collision/water roles are preserved. Whirl
; Islands, Whirlpool, trainers, items and all Cianwood indoor Warps stay closed.

JohtoRoute40Blocks:: INCBIN "maps/johto_pilot/Route40.runtime.blk"
ASSERT @ - JohtoRoute40Blocks == JOHTO_ROUTE_40_WIDTH * JOHTO_ROUTE_40_HEIGHT
JohtoRoute41Blocks:: INCBIN "maps/johto_pilot/Route41.runtime.blk"
ASSERT @ - JohtoRoute41Blocks == JOHTO_ROUTE_41_WIDTH * JOHTO_ROUTE_41_HEIGHT
JohtoCianwoodBlocks:: INCBIN "maps/johto_pilot/CianwoodCity.runtime.blk"
ASSERT @ - JohtoCianwoodBlocks == JOHTO_CIANWOOD_CITY_WIDTH * JOHTO_CIANWOOD_CITY_HEIGHT

; The connection reader consumes pointers in the source header's active bank.
; Keep explicit mirrors here rather than relying on cross-bank pointer accidents.
JohtoRoute40EastOlivineMirror:: INCBIN "maps/johto_pilot/OlivineCity.runtime.blk"
ASSERT @ - JohtoRoute40EastOlivineMirror == JOHTO_OLIVINE_CITY_WIDTH * JOHTO_OLIVINE_CITY_HEIGHT

JohtoWestSeaLocalScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoRoute40RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_40_HEIGHT, JOHTO_ROUTE_40_WIDTH
    dw JohtoRoute40Blocks
    dw JohtoRoute40TextPointers
    dw JohtoWestSeaLocalScript
    db SOUTH | EAST
    ; South -> Route41 north, Gold offset -15 blocks.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute41Blocks + 15
    dw wOverworldMap + (JOHTO_ROUTE_40_HEIGHT + 3) * (JOHTO_ROUTE_40_WIDTH + 6) + 3
    db JOHTO_ROUTE_40_WIDTH
    db JOHTO_ROUTE_41_WIDTH
    db 0
    db 30
    dw wOverworldMap + 7 + JOHTO_ROUTE_41_WIDTH
    ; East -> Olivine west, Gold offset -9 blocks.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute40EastOlivineMirror + JOHTO_OLIVINE_CITY_WIDTH * 9
    dw wOverworldMap + 3 * (JOHTO_ROUTE_40_WIDTH + 6) + JOHTO_ROUTE_40_WIDTH + 3
    db 9
    db JOHTO_OLIVINE_CITY_WIDTH
    db 18
    db 0
    dw wOverworldMap + 7 + JOHTO_OLIVINE_CITY_WIDTH
    dw JohtoRoute40RuntimeObjects
JohtoRoute40HeaderEnd::
ASSERT JohtoRoute40HeaderEnd - JohtoRoute40RuntimeHeader == 34

JohtoRoute41RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_41_HEIGHT, JOHTO_ROUTE_41_WIDTH
    dw JohtoRoute41Blocks
    dw JohtoRoute41TextPointers
    dw JohtoWestSeaLocalScript
    db NORTH | WEST
    ; North -> Route40 south, Gold offset +15 blocks.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute40Blocks + JOHTO_ROUTE_40_WIDTH * (JOHTO_ROUTE_40_HEIGHT - 3)
    dw wOverworldMap + 3 + 15
    db JOHTO_ROUTE_40_WIDTH
    db JOHTO_ROUTE_40_WIDTH
    db JOHTO_ROUTE_40_HEIGHT * 2 - 1
    db -30
    dw wOverworldMap + 1 + JOHTO_ROUTE_40_HEIGHT * (JOHTO_ROUTE_40_WIDTH + 6)
    ; West -> Cianwood east, Gold offset 0.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoCianwoodBlocks + JOHTO_CIANWOOD_CITY_WIDTH - 3
    dw wOverworldMap + 3 * (JOHTO_ROUTE_41_WIDTH + 6)
    db JOHTO_ROUTE_41_HEIGHT
    db JOHTO_CIANWOOD_CITY_WIDTH
    db 0
    db JOHTO_CIANWOOD_CITY_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_CIANWOOD_CITY_WIDTH
    dw JohtoRoute41RuntimeObjects
JohtoRoute41HeaderEnd::
ASSERT JohtoRoute41HeaderEnd - JohtoRoute41RuntimeHeader == 34

JohtoCianwoodRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_CIANWOOD_CITY_HEIGHT, JOHTO_CIANWOOD_CITY_WIDTH
    dw JohtoCianwoodBlocks
    dw JohtoCianwoodTextPointers
    dw JohtoWestSeaLocalScript
    db EAST
    ; East -> Route41 west, Gold offset 0.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute41Blocks
    dw wOverworldMap + 3 * (JOHTO_CIANWOOD_CITY_WIDTH + 6) + JOHTO_CIANWOOD_CITY_WIDTH + 3
    db JOHTO_ROUTE_41_HEIGHT
    db JOHTO_ROUTE_41_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_ROUTE_41_WIDTH
    dw JohtoCianwoodRuntimeObjects
JohtoCianwoodHeaderEnd::
ASSERT JohtoCianwoodHeaderEnd - JohtoCianwoodRuntimeHeader == 23

ASSERT BANK(JohtoRoute40RuntimeHeader) == BANK(JohtoRoute40Blocks)
ASSERT BANK(JohtoRoute41RuntimeHeader) == BANK(JohtoRoute41Blocks)
ASSERT BANK(JohtoCianwoodRuntimeHeader) == BANK(JohtoCianwoodBlocks)

; Gold readable signs only. All event/NPC/indoor content remains deferred.
JohtoRoute40RuntimeObjects::
    db $05
    db 0
    db 1
    db 8, 16, 1
    db 0

JohtoRoute41RuntimeObjects::
    db $05
    db 0 ; four Whirl Islands cave entries remain intentionally closed
    db 0
    db 0

JohtoCianwoodRuntimeObjects::
    db $05
    db 0 ; six Gold indoor Warps remain sealed
    db 5
    db 34, 20, 1
    db 45, 7, 2
    db 43, 24, 3
    db 47, 19, 4
    db 32, 8, 5
    db 0

JohtoRoute40TextPointers:
    dw JohtoRoute40SignText
JohtoRoute40SignText:
    text "ROUTE 40"
    para "CIANWOOD CITY"
    done
    db "@"

JohtoRoute41TextPointers:
    ; No Gold BGEVENT_READ signs on Route41.

JohtoCianwoodTextPointers:
    dw JohtoCianwoodSignText
    dw JohtoCianwoodGymSignText
    dw JohtoCianwoodCenterSignText
    dw JohtoCianwoodPharmacySignText
    dw JohtoCianwoodStudioSignText
JohtoCianwoodSignText:
    text "CIANWOOD CITY"
    done
    db "@"
JohtoCianwoodGymSignText:
    text "CIANWOOD GYM"
    done
    db "@"
JohtoCianwoodCenterSignText:
    text "#MON CENTER"
    done
    db "@"
JohtoCianwoodPharmacySignText:
    text "PHARMACY"
    done
    db "@"
JohtoCianwoodStudioSignText:
    text "PHOTO STUDIO"
    done
    db "@"

; Exact mature role grids: 0=floor, 1=blocked, 2=Gold WATER.
JohtoRoute40Roles:: INCBIN "maps/johto_pilot/Route40.roles.bin"
JohtoRoute41Roles:: INCBIN "maps/johto_pilot/Route41.roles.bin"
JohtoCianwoodRoles:: INCBIN "maps/johto_pilot/CianwoodCity.roles.bin"

; E=0/1/2 for recognized sea-chain map, E=3 otherwise.
; Off-map targets are left to the explicit edge contract and return floor here.
JohtoWestSeaSpatialRoleAhead::
    ld e, 3
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_40_LOCAL_ID
    jr z, .route40
    cp JOHTO_ROUTE_41_LOCAL_ID
    jr z, .route41
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    ret nz
    ld hl, JohtoCianwoodRoles
    ld b, JOHTO_CIANWOOD_CITY_WIDTH * 2
    ld c, JOHTO_CIANWOOD_CITY_HEIGHT * 2
    jr .common
.route40
    ld hl, JohtoRoute40Roles
    ld b, JOHTO_ROUTE_40_WIDTH * 2
    ld c, JOHTO_ROUTE_40_HEIGHT * 2
    jr .common
.route41
    ld hl, JohtoRoute41Roles
    ld b, JOHTO_ROUTE_41_WIDTH * 2
    ld c, JOHTO_ROUTE_41_HEIGHT * 2
.common
    push hl
    ld a, [wXCoord]
    ld e, a
    ld a, [wYCoord]
    ld d, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    cp PLAYER_DIR_RIGHT
    jr nz, .bad
    inc e
    jr .bounds
.north
    dec d
    jr .bounds
.south
    inc d
    jr .bounds
.west
    dec e
.bounds
    ld a, e
    cp b
    jr nc, .offMap
    ld a, d
    cp c
    jr nc, .offMap
    ; 16-bit y*width+x.
    ld h, 0
    ld l, 0
.row
    ld a, d
    and a
    jr z, .index
    push de
    ld d, 0
    ld e, b
    add hl, de
    pop de
    dec d
    jr .row
.index
    ld d, 0
    add hl, de
    pop de
    add hl, de
    ld e, [hl]
    ret
.offMap
    pop hl
    ld e, 0
    ret
.bad
    pop hl
    ld e, 1
    ret

; Land movement: WATER is passable only while already surfing.
JohtoWestSeaSpatialStep::
    call JohtoWestSeaSpatialRoleAhead
    ld a, e
    cp 2
    jr nz, .notWater
    ld a, [wWalkBikeSurfState]
    cp 2
    jr z, .allow
    jr .block
.notWater
    and a
    jr z, .allow
.block
    ld e, 1
    ret
.allow
    ld e, 0
    ret

; Land-only edge contract. The Olivine/Route40 east-west seam has five Gold
; FLOOR lanes; the Route40/41 and Route41/Cianwood seams are water-only.
JohtoWestSeaIsKnownClosedEdge::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jr z, .olivine
    cp JOHTO_ROUTE_40_LOCAL_ID
    jr z, .route40
    cp JOHTO_ROUTE_41_LOCAL_ID
    jp z, .route41
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jp z, .cianwood
    ld e, 1
    ret
.olivine
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .olivineWest
    cp PLAYER_DIR_RIGHT
    jp z, .rightClosed
    cp PLAYER_DIR_UP
    jr z, .olivineNorth
    cp PLAYER_DIR_DOWN
    jr z, .downClosedOlivine
    ret
.olivineNorth
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 18
    jp c, .closed
    cp 22
    jp c, .open
    jp .closed
.olivineWest
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
    cp 20
    jp z, .open
    cp 22
    jp c, .closed
    cp 26
    jp c, .open
    jp .closed
.downClosedOlivine
    ld a, [wYCoord]
    cp JOHTO_OLIVINE_CITY_HEIGHT * 2 - 1
    ret c
    jp .closed
.route40
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .route40East
    cp PLAYER_DIR_DOWN
    jr z, .downClosed40
    cp PLAYER_DIR_LEFT
    jr z, .leftClosed
    cp PLAYER_DIR_UP
    jr z, .upClosed
    ret
.route40East
    ld a, [wXCoord]
    cp JOHTO_ROUTE_40_WIDTH * 2 - 1
    ret c
    ld a, [wYCoord]
    cp 2
    jr z, .open
    cp 4
    jr c, .closed
    cp 8
    jr c, .open
    jr .closed
.downClosed40
    ld a, [wYCoord]
    cp JOHTO_ROUTE_40_HEIGHT * 2 - 1
    ret c
    jr .closed ; Route41 seam is WATER only
.route41
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .upClosed
    cp PLAYER_DIR_LEFT
    jr z, .leftClosed
    cp PLAYER_DIR_RIGHT
    jr z, .rightClosed41
    cp PLAYER_DIR_DOWN
    jr z, .downClosed41
    ret
.rightClosed41
    ld a, [wXCoord]
    cp JOHTO_ROUTE_41_WIDTH * 2 - 1
    ret c
    jr .closed
.downClosed41
    ld a, [wYCoord]
    cp JOHTO_ROUTE_41_HEIGHT * 2 - 1
    ret c
    jr .closed
.cianwood
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .rightClosedCianwood
    cp PLAYER_DIR_LEFT
    jr z, .leftClosed
    cp PLAYER_DIR_UP
    jr z, .upClosed
    cp PLAYER_DIR_DOWN
    jr z, .downClosedCianwood
    ret
.rightClosedCianwood
    ld a, [wXCoord]
    cp JOHTO_CIANWOOD_CITY_WIDTH * 2 - 1
    ret c
    jr .closed ; Route41 seam is WATER only
.downClosedCianwood
    ld a, [wYCoord]
    cp JOHTO_CIANWOOD_CITY_HEIGHT * 2 - 1
    ret c
    jr .closed
.leftClosed
    ld a, [wXCoord]
    and a
    ret nz
    jr .closed
.rightClosed
    ld a, [wXCoord]
    cp JOHTO_OLIVINE_CITY_WIDTH * 2 - 1
    ret c
    jr .closed
.upClosed
    ld a, [wYCoord]
    and a
    ret nz
.closed
    ld e, 1
    ret
.open
    ld e, 0
    ret

; Carry=1 only on a verified reciprocal WATER seam.
JohtoWestSeaSeamWaterAhead::
    ld a, [wCurLocalMapID]
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jr z, .olivine
    cp JOHTO_ROUTE_40_LOCAL_ID
    jr z, .route40
    cp JOHTO_ROUTE_41_LOCAL_ID
    jr z, .route41
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jp z, .cianwood
    and a
    ret
.olivine
    ld a, [wSpriteStateData1 + 9]
    cp SPRITE_FACING_LEFT
    jp nz, .no
    ld a, [wXCoord]
    and a
    jp nz, .no
    ld a, [wYCoord]
    cp 26
    jp c, .no
    cp 32
    jr c, .yes
    jr .no
.route40
    ld a, [wSpriteStateData1 + 9]
    cp SPRITE_FACING_RIGHT
    jr z, .route40East
    cp SPRITE_FACING_DOWN
    jr nz, .no
    ld a, [wYCoord]
    cp JOHTO_ROUTE_40_HEIGHT * 2 - 1
    jr nz, .no
    ld a, [wXCoord]
    cp 2
    jr c, .no
    cp 19
    jr c, .yes
    jr .no
.route40East
    ld a, [wXCoord]
    cp JOHTO_ROUTE_40_WIDTH * 2 - 1
    jr nz, .no
    ld a, [wYCoord]
    cp 8
    jr c, .no
    cp 14
    jr c, .yes
    jr .no
.route41
    ld a, [wSpriteStateData1 + 9]
    cp SPRITE_FACING_UP
    jr z, .route41North
    cp SPRITE_FACING_LEFT
    jr nz, .no
    ld a, [wXCoord]
    and a
    jr nz, .no
    ld a, [wYCoord]
    and a
    jr z, .no
    cp 46
    jr c, .yes
    jr .no
.route41North
    ld a, [wYCoord]
    and a
    jr nz, .no
    ld a, [wXCoord]
    cp 32
    jr c, .no
    cp 49
    jr c, .yes
    jr .no
.cianwood
    ld a, [wSpriteStateData1 + 9]
    cp SPRITE_FACING_RIGHT
    jr nz, .no
    ld a, [wXCoord]
    cp JOHTO_CIANWOOD_CITY_WIDTH * 2 - 1
    jr nz, .no
    ld a, [wYCoord]
    and a
    jr z, .no
    cp 46
    jr c, .yes
.no
    and a
    ret
.yes
    scf
    ret

; Carry=1 when a Surf step points outside this finite four-map chain and was
; not already accepted by JohtoWestSeaSeamWaterAhead.
JohtoWestSeaUnsafeSurfEdge::
    push bc
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .clear
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .clear
    ld a, [wCurLocalMapID]
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jr z, .check
    cp JOHTO_ROUTE_40_LOCAL_ID
    jr z, .check
    cp JOHTO_ROUTE_41_LOCAL_ID
    jr z, .check
    cp JOHTO_CIANWOOD_CITY_LOCAL_ID
    jr nz, .clear
.check
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_RIGHT
    jr z, .right
    cp PLAYER_DIR_DOWN
    jr nz, .clear
    ld a, [wYCoord]
    ld b, a
    ld a, [wCurrentMapHeight2]
    dec a
    cp b
    jr z, .blocked
    jr c, .blocked
    jr .clear
.left
    ld a, [wXCoord]
    and a
    jr z, .blocked
    jr .clear
.up
    ld a, [wYCoord]
    and a
    jr z, .blocked
    jr .clear
.right
    ld a, [wXCoord]
    ld b, a
    ld a, [wCurrentMapWidth2]
    dec a
    cp b
    jr z, .blocked
    jr c, .blocked
.clear
    and a
    pop bc
    ret
.blocked
    scf
    pop bc
    ret

; Preserves BC/DE/HL. Supports Olivine's existing accepted role grid plus the
; three new maps, and checks reciprocal WATER seams before local bounds.
JohtoWestSeaGoldWaterProbe::
    push bc
    push de
    push hl
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .notWater
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .notWater
    call JohtoWestSeaSeamWaterAhead
    jr c, .water
    ld a, [wCurLocalMapID]
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jr nz, .newMap
    callab JohtoSouthGoldWaterProbe
    jr c, .water
    jr .notWater
.newMap
    call JohtoWestSeaSpatialRoleAhead
    ld a, e
    cp 2
    jr z, .water
.notWater
    pop hl
    pop de
    pop bc
    and a
    ret
.water
    pop hl
    pop de
    pop bc
    scf
    ret

; Carry=1 only for a mature walkable FLOOR target. Unsafe outer Surf edges are
; never interpreted as shore even if a preview tile happens to look passable.
JohtoWestSeaGoldShoreProbe::
    push bc
    push de
    push hl
    call JohtoWestSeaUnsafeSurfEdge
    jr c, .notShore
    ld a, [wCurLocalMapID]
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jr nz, .newMap
    callab JohtoSouthGoldShoreProbe
    jr c, .shore
    jr .notShore
.newMap
    call JohtoWestSeaSpatialRoleAhead
    ld a, e
    and a
    jr nz, .notShore
    call JohtoWestSeaSpatialStep
    ld a, e
    and a
    jr nz, .notShore
.shore
    pop hl
    pop de
    pop bc
    scf
    ret
.notShore
    pop hl
    pop de
    pop bc
    and a
    ret
