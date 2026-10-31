; MAP-297: Ecruteak west gate -> Route38 -> Route39 -> Olivine City.
; Outdoor maps use Gold geometry; unbuilt Olivine/Route39 interiors stay sealed.
JohtoRoute38EcruteakGateBlocks:: INCBIN "maps/johto_pilot/Route38EcruteakGate.runtime.blk"
ASSERT @ - JohtoRoute38EcruteakGateBlocks == JOHTO_ROUTE_38_ECRUTEAK_GATE_WIDTH * JOHTO_ROUTE_38_ECRUTEAK_GATE_HEIGHT
JohtoRoute38Blocks:: INCBIN "maps/johto_pilot/Route38.runtime.blk"
ASSERT @ - JohtoRoute38Blocks == JOHTO_ROUTE_38_WIDTH * JOHTO_ROUTE_38_HEIGHT
JohtoRoute39Blocks:: INCBIN "maps/johto_pilot/Route39.runtime.blk"
ASSERT @ - JohtoRoute39Blocks == JOHTO_ROUTE_39_WIDTH * JOHTO_ROUTE_39_HEIGHT
JohtoOlivineBlocks:: INCBIN "maps/johto_pilot/OlivineCity.runtime.blk"
ASSERT @ - JohtoOlivineBlocks == JOHTO_OLIVINE_CITY_WIDTH * JOHTO_OLIVINE_CITY_HEIGHT

; Connection reader is source-bank local, so keep explicit same-bank mirrors.
JohtoEcruteakWestRoute38Mirror:: INCBIN "maps/johto_pilot/Route38.runtime.blk"
ASSERT @ - JohtoEcruteakWestRoute38Mirror == JOHTO_ROUTE_38_WIDTH * JOHTO_ROUTE_38_HEIGHT
JohtoRoute38WestRoute39Mirror:: INCBIN "maps/johto_pilot/Route39.runtime.blk"
ASSERT @ - JohtoRoute38WestRoute39Mirror == JOHTO_ROUTE_39_WIDTH * JOHTO_ROUTE_39_HEIGHT
JohtoRoute38EastEcruteakMirror:: INCBIN "maps/johto_pilot/EcruteakCity.runtime.blk"
ASSERT @ - JohtoRoute38EastEcruteakMirror == JOHTO_ECRUTEAK_WIDTH * JOHTO_ECRUTEAK_HEIGHT
JohtoRoute39EastRoute38Mirror:: INCBIN "maps/johto_pilot/Route38.runtime.blk"
ASSERT @ - JohtoRoute39EastRoute38Mirror == JOHTO_ROUTE_38_WIDTH * JOHTO_ROUTE_38_HEIGHT
JohtoRoute39SouthOlivineMirror:: INCBIN "maps/johto_pilot/OlivineCity.runtime.blk"
ASSERT @ - JohtoRoute39SouthOlivineMirror == JOHTO_OLIVINE_CITY_WIDTH * JOHTO_OLIVINE_CITY_HEIGHT
JohtoOlivineNorthRoute39Mirror:: INCBIN "maps/johto_pilot/Route39.runtime.blk"
ASSERT @ - JohtoOlivineNorthRoute39Mirror == JOHTO_ROUTE_39_WIDTH * JOHTO_ROUTE_39_HEIGHT

JohtoRoute38EcruteakGateRuntimeHeader::
    db JOHTO_GATE
    db JOHTO_ROUTE_38_ECRUTEAK_GATE_HEIGHT, JOHTO_ROUTE_38_ECRUTEAK_GATE_WIDTH
    dw JohtoRoute38EcruteakGateBlocks
    dw JohtoRoute38EcruteakGateTextPointers
    dw JohtoCorridorLocalScript
    db 0 ; both mouths are registered collision Warps
    dw JohtoRoute38EcruteakGateRuntimeObjects
JohtoRoute38EcruteakGateHeaderEnd::
ASSERT JohtoRoute38EcruteakGateHeaderEnd - JohtoRoute38EcruteakGateRuntimeHeader == 12

JohtoRoute38RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_38_HEIGHT, JOHTO_ROUTE_38_WIDTH
    dw JohtoRoute38Blocks
    dw JohtoRoute38TextPointers
    dw JohtoCorridorLocalScript
    db WEST | EAST
    ; WEST -> Route39, zero row offset. This is the real walkable seam.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute38WestRoute39Mirror + JOHTO_ROUTE_39_WIDTH - 3
    dw wOverworldMap + 3 * (JOHTO_ROUTE_38_WIDTH + 6)
    db JOHTO_ROUTE_38_HEIGHT
    db JOHTO_ROUTE_39_WIDTH
    db 0
    db JOHTO_ROUTE_39_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_39_WIDTH
    ; EAST -> Ecruteak display strip only; entry remains through Gate Warps.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute38EastEcruteakMirror + JOHTO_ECRUTEAK_WIDTH * 5
    dw wOverworldMap + 3 * (JOHTO_ROUTE_38_WIDTH + 6) + JOHTO_ROUTE_38_WIDTH + 3
    db JOHTO_ROUTE_38_HEIGHT
    db JOHTO_ECRUTEAK_WIDTH
    db 10
    db 0
    dw wOverworldMap + 7 + JOHTO_ECRUTEAK_WIDTH
    dw JohtoRoute38RuntimeObjects
JohtoRoute38HeaderEnd::
ASSERT JohtoRoute38HeaderEnd - JohtoRoute38RuntimeHeader == 34

JohtoRoute39RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_39_HEIGHT, JOHTO_ROUTE_39_WIDTH
    dw JohtoRoute39Blocks
    dw JohtoRoute39TextPointers
    dw JohtoCorridorLocalScript
    db SOUTH | EAST
    ; SOUTH -> Olivine, Gold -5 blocks: road x0..9 aligns city x5..14.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute39SouthOlivineMirror + 5
    dw wOverworldMap + (JOHTO_ROUTE_39_HEIGHT + 3) * (JOHTO_ROUTE_39_WIDTH + 6) + 3
    db JOHTO_ROUTE_39_WIDTH
    db JOHTO_OLIVINE_CITY_WIDTH
    db 0
    db 10
    dw wOverworldMap + 7 + JOHTO_OLIVINE_CITY_WIDTH
    ; EAST -> Route38, zero row offset.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoRoute39EastRoute38Mirror
    dw wOverworldMap + 3 * (JOHTO_ROUTE_39_WIDTH + 6) + JOHTO_ROUTE_39_WIDTH + 3
    db JOHTO_ROUTE_38_HEIGHT
    db JOHTO_ROUTE_38_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_ROUTE_38_WIDTH
    dw JohtoRoute39RuntimeObjects
JohtoRoute39HeaderEnd::
ASSERT JohtoRoute39HeaderEnd - JohtoRoute39RuntimeHeader == 34

JohtoOlivineRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_OLIVINE_CITY_HEIGHT, JOHTO_OLIVINE_CITY_WIDTH
    dw JohtoOlivineBlocks
    dw JohtoOlivineTextPointers
    dw JohtoCorridorLocalScript
    db NORTH ; Route40 west and all buildings remain closed
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoOlivineNorthRoute39Mirror + JOHTO_ROUTE_39_WIDTH * (JOHTO_ROUTE_39_HEIGHT - 3)
    dw wOverworldMap + 3 + 5
    db JOHTO_ROUTE_39_WIDTH
    db JOHTO_ROUTE_39_WIDTH
    db JOHTO_ROUTE_39_HEIGHT * 2 - 1
    db -10
    dw wOverworldMap + 1 + JOHTO_ROUTE_39_HEIGHT * (JOHTO_ROUTE_39_WIDTH + 6)
    dw JohtoOlivineRuntimeObjects
JohtoOlivineHeaderEnd::
ASSERT JohtoOlivineHeaderEnd - JohtoOlivineRuntimeHeader == 23

ASSERT BANK(JohtoRoute38EcruteakGateRuntimeHeader) == BANK(JohtoRoute38EcruteakGateBlocks)
ASSERT BANK(JohtoRoute38RuntimeHeader) == BANK(JohtoRoute38Blocks)
ASSERT BANK(JohtoRoute39RuntimeHeader) == BANK(JohtoRoute39Blocks)
ASSERT BANK(JohtoOlivineRuntimeHeader) == BANK(JohtoOlivineBlocks)
ASSERT BANK(JohtoEcruteakWestRoute38Mirror) == BANK(JohtoEcruteakRuntimeHeader)

JohtoRoute38EcruteakGateRuntimeObjects::
    db $0d
    db 4
    db 4, 0, 0, JOHTO_REGISTERED_WARP_SELECTOR ; west -> Route38 upper carpet
    db 5, 0, 1, JOHTO_REGISTERED_WARP_SELECTOR ; west -> Route38 lower carpet
    db 4, 9, 0, JOHTO_REGISTERED_WARP_SELECTOR ; east -> Ecruteak upper carpet
    db 5, 9, 1, JOHTO_REGISTERED_WARP_SELECTOR ; east -> Ecruteak lower carpet
    db 0
    db 0

JohtoRoute38RuntimeObjects::
    db $05
    db 2
    db 8, 35, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 9, 35, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 2
    db 7, 33, 1
    db 13, 5, 2
    db 0

JohtoRoute39RuntimeObjects::
    db $05
    db 0 ; barn/farmhouse interiors remain sealed
    db 3
    db 31, 5, 1
    db 5, 9, 2
    db 7, 15, 3
    db 0

JohtoOlivineRuntimeObjects::
    db $05
    db 0 ; all 11 Gold building/port Warps remain sealed
    db 6
    db 11, 17, 1
    db 24, 20, 2
    db 11, 7, 3
    db 28, 30, 4
    db 21, 14, 5
    db 17, 20, 6
    db 0

; Reference-project readable signs only; trainers/story/NPCs remain deferred.
JohtoRoute38EcruteakGateTextPointers:
    dw JohtoRoute38EcruteakGateOfficerText
JohtoRoute38EcruteakGateOfficerText:
    text "NEW BARK TOWN?"
    line "PROF. ELM lives"
    cont "there, right?"
    para "You've come a long"
    line "way to get here."
    done
    db "@"

JohtoRoute38TextPointers:
    dw JohtoRoute38SignText
    dw JohtoRoute38TrainerTipsText
JohtoRoute38SignText:
    text "ROUTE 38"
    done
    db "@"
JohtoRoute38TrainerTipsText:
    text "TRAINER TIPS"
    para "Check your party"
    line "before you travel."
    done
    db "@"

JohtoRoute39TextPointers:
    dw JohtoRoute39TipsText
    dw JohtoRoute39MoomooText
    dw JohtoRoute39SignText
JohtoRoute39TipsText:
    text "TRAINER TIPS"
    para "Keep your party"
    line "ready to travel."
    done
    db "@"
JohtoRoute39MoomooText:
    text "MOOMOO FARM"
    line "FRESH MILK"
    done
    db "@"
JohtoRoute39SignText:
    text "ROUTE 39"
    para "OLIVINE CITY -"
    line "ECRUTEAK CITY"
    done
    db "@"

JohtoOlivineTextPointers:
    dw JohtoOlivineSignText
    dw JohtoOlivinePortSignText
    dw JohtoOlivineGymSignText
    dw JohtoOlivineLighthouseSignText
    dw JohtoOlivineCenterSignText
    dw JohtoOlivineMartSignText
JohtoOlivineSignText:
    text "OLIVINE CITY"
    para "THE PORT WITH A"
    line "SEA BREEZE"
    done
    db "@"
JohtoOlivinePortSignText:
    text "OLIVINE PORT"
    done
    db "@"
JohtoOlivineGymSignText:
    text "OLIVINE GYM"
    line "LEADER: JASMINE"
    done
    db "@"
JohtoOlivineLighthouseSignText:
    text "LIGHTHOUSE"
    done
    db "@"
JohtoOlivineCenterSignText:
    text "#MON CENTER"
    done
    db "@"
JohtoOlivineMartSignText:
    text "#MON MART"
    done
    db "@"

; Return E=1 only for an unregistered outside step. Preview-only Ecruteak/38
; east-west is deliberately not walkable; passage there is the Gate Warp.
JohtoWestIsKnownClosedEdge::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .gate
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .route38
    cp JOHTO_ROUTE_39_LOCAL_ID
    jr z, .route39
    cp JOHTO_OLIVINE_CITY_LOCAL_ID
    jp z, .olivine
    ld e, 1
    ret
.gate
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .leftClosed
    cp PLAYER_DIR_RIGHT
    jr z, .rightClosed
    cp PLAYER_DIR_UP
    jr z, .upClosed
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_HEIGHT * 2 - 1
    ret c
    jp .closed
.leftClosed
    ld a, [wXCoord]
    and a
    ret nz
    jp .closed
.rightClosed
    ld a, [wXCoord]
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_WIDTH * 2 - 1
    ret c
    jp .closed
.upClosed
    ld a, [wYCoord]
    and a
    ret nz
    jp .closed
.route38
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .r38west
    cp PLAYER_DIR_RIGHT
    jr z, .r38east
    cp PLAYER_DIR_UP
    jr z, .upClosed
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp JOHTO_ROUTE_38_HEIGHT * 2 - 1
    ret c
    jp .closed
.r38west
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
    cp 8
    jr c, .closed
    cp 12
    ret c
    jr .closed
.r38east
    ld a, [wXCoord]
    cp JOHTO_ROUTE_38_WIDTH * 2 - 1
    ret c
    jr .closed
.route39
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .r39east
    cp PLAYER_DIR_DOWN
    jr z, .r39south
    cp PLAYER_DIR_LEFT
    jr z, .leftClosed
    cp PLAYER_DIR_UP
    jr z, .upClosed
    ret
.r39east
    ld a, [wXCoord]
    cp JOHTO_ROUTE_39_WIDTH * 2 - 1
    ret c
    ld a, [wYCoord]
    cp 8
    jr c, .closed
    cp 12
    ret c
    jr .closed
.r39south
    ld a, [wYCoord]
    cp JOHTO_ROUTE_39_HEIGHT * 2 - 1
    ret c
    ld a, [wXCoord]
    cp 8
    jr c, .closed
    cp 12
    ret c
    jr .closed
.olivine
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .olivineNorth
    cp PLAYER_DIR_LEFT
    jp z, .leftClosed
    cp PLAYER_DIR_RIGHT
    jr z, .olivineEast
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp JOHTO_OLIVINE_CITY_HEIGHT * 2 - 1
    ret c
    jr .closed
.olivineNorth
    ld a, [wYCoord]
    and a
    ret nz
    ld a, [wXCoord]
    cp 18
    jr c, .closed
    cp 22
    ret c
    jr .closed
.olivineEast
    ld a, [wXCoord]
    cp JOHTO_OLIVINE_CITY_WIDTH * 2 - 1
    ret c
.closed
    ld e, 1
    ret

; Entering a carpet must bypass its static wall role, but must NOT Warp on
; step-on. Only the subsequent outward collision is a Warp attempt.
JohtoWestPortalBeforeStep::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .cityBefore
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .routeBefore
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    ret nz
    ld a, [wYCoord]
    cp 4
    jr z, .gateBeforeLane
    cp 5
    ret nz
.gateBeforeLane
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .gateBeforeLeft
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 8
    jr z, .yes
    ret
.gateBeforeLeft
    ld a, [wXCoord]
    cp 1
    jr z, .yes
    ret
.cityBefore
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    ret nz
    ld a, [wXCoord]
    cp 1
    ret nz
    ld a, [wYCoord]
    cp 18
    jr z, .yes
    cp 19
    ret nz
    jr .yes
.routeBefore
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    cp 34
    ret nz
    ld a, [wYCoord]
    cp 8
    jr z, .yes
    cp 9
    ret nz
.yes
    ld e, 1
    ret

JohtoWestPortalAfterStep::
    ld e, 0 ; all four mouths are collision carpets, never STEP_ON doors
    ret

JohtoWestPortalArrivalStep::
    ld e, 0 ; remain on destination carpet; reverse exit is immediately valid
    ret

JohtoWestPortalCollisionExit::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
    jr z, .cityExit
    cp JOHTO_ROUTE_38_LOCAL_ID
    jr z, .routeExit
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    ret nz
    ld a, [wYCoord]
    cp 4
    jr z, .gateExitLane
    cp 5
    ret nz
.gateExitLane
    ld a, [wXCoord]
    and a
    jr z, .gateWestExit
    cp 9
    ret nz
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    jr z, .exitYes
    ret
.gateWestExit
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .exitYes
    ret
.cityExit
    ld a, [wXCoord]
    and a
    ret nz
    ld a, [wYCoord]
    cp 18
    jr z, .cityFacing
    cp 19
    ret nz
.cityFacing
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_LEFT
    jr z, .exitYes
    ret
.routeExit
    ld a, [wXCoord]
    cp 35
    ret nz
    ld a, [wYCoord]
    cp 8
    jr z, .routeFacing
    cp 9
    ret nz
.routeFacing
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret nz
.exitYes
    ld e, 1
    ret
