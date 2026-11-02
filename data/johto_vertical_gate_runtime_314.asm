; DEV-314: shared, data-driven vertical gate threshold runtime.
; Each compatible vertical gate adds map-local rows to these tables; it does
; not add another copy of the before/after/arrival/bounds branch code.
; ID65/66 are shared gatehouses; ID67 carries the outdoor Route43 portal pairs.
; DEV-319 registered ID66; DEV-320 restores its Gold two-lane north carpet movement.
; The south ID65 return carpet remains on the normal collision path.

; Before-step rows: map ID, direction, standing X, standing Y.
; Route43 has two different outdoor carpet pairs with different contracts:
; - north ID66 pair (17/18,31): allow entry from y30 and lateral lane changes;
; - south ID65 pair (9/10,51): NEVER bypass DOWN, because y52 must collide
;   so CheckWarpsCollision can dispatch the registered return Warp.
JohtoVerticalGateBeforeStepProfiles314::
    db JOHTO_MAHOGANY_TOWN_LOCAL_ID, PLAYER_DIR_UP, 9, 2
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 6
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 5, 6
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 4, 1
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 1
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 6
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 5, 6
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_UP, 4, 1
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 1
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 36 ; Gold #3 DOOR only
    ; Gold ID66 north WARP_CARPET_DOWN pair: re-enter from north and switch
    ; between the two registered carpet lanes, but never step beyond rails.
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 30
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 30
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 17, 31
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 18, 31
    db $ff
JohtoVerticalGateBeforeStepProfilesEnd314::
ASSERT JohtoVerticalGateBeforeStepProfilesEnd314 - JohtoVerticalGateBeforeStepProfiles314 == 57

; After-step rows: map ID, direction, destination X, destination Y, result.
; E=2 = exact solid DOOR; E=1 = DOWN collision-only carpet exit;
; E=3 = safe lateral lane change onto a paired carpet (not an outward Warp).
JohtoVerticalGateAfterStepProfiles314::
    db JOHTO_MAHOGANY_TOWN_LOCAL_ID, PLAYER_DIR_UP, 9, 1, 2
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 7, 1
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 5, 7, 1
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 4, 0, 2
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 0, 2
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 9, 51, 1
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 10, 51, 1
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 4, 7, 1
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_DOWN, 5, 7, 1
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_UP, 4, 0, 2
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, PLAYER_DIR_UP, 5, 0, 2
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_UP, 17, 35, 2 ; solid DOOR
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 17, 31, 1 ; ID66 DOWN collision exit
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_DOWN, 18, 31, 1 ; ID66 DOWN collision exit
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_RIGHT, 18, 31, 3 ; ID66 lateral lane change only
    db JOHTO_ROUTE_43_LOCAL_ID, PLAYER_DIR_LEFT, 17, 31, 3 ; ID66 lateral lane change only
    db $ff
JohtoVerticalGateAfterStepProfilesEnd314::
ASSERT JohtoVerticalGateAfterStepProfilesEnd314 - JohtoVerticalGateAfterStepProfiles314 == 81

; Arrival rows: map ID, landing X, landing Y, automatic step direction.
; Town plus ID65/ID66 upper DOOR landings step south. All carpets stay put.
JohtoVerticalGateArrivalProfiles314::
    db JOHTO_MAHOGANY_TOWN_LOCAL_ID, 9, 1, D_DOWN
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 4, 0, D_DOWN
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 5, 0, D_DOWN
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, 4, 0, D_DOWN
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, 5, 0, D_DOWN
    db JOHTO_ROUTE_43_LOCAL_ID, 17, 35, D_DOWN ; arrival from ID66 south carpet onto DOOR
    db $ff
JohtoVerticalGateArrivalProfilesEnd314::
ASSERT JohtoVerticalGateArrivalProfilesEnd314 - JohtoVerticalGateArrivalProfiles314 == 25

; Closed-edge rows: map ID, width in 16x16 cells, height in 16x16 cells.
; ID65 and ID66 are 10x8 cells; unregistered physical edges stay closed.
JohtoVerticalGateBoundsProfiles314::
    db JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID, 10, 8
    db JOHTO_ROUTE_43_GATE_LOCAL_ID, 10, 8
    db $ff
JohtoVerticalGateBoundsProfilesEnd314::
ASSERT JohtoVerticalGateBoundsProfilesEnd314 - JohtoVerticalGateBoundsProfiles314 == 7

; In: current map, player direction and standing coordinate before the step.
; Out: E=1 only for a configured vertical-gate threshold; otherwise E=0.
JohtoVerticalGateBeforeStep314::
    ld e, 0
    ld hl, JohtoVerticalGateBeforeStepProfiles314
.loop
    ld a, [hli]
    cp $ff
    ret z
    ld b, a
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld d, a
    ld a, [hli]
    ld e, a
    ld a, [wCurLocalMapID]
    cp b
    jr nz, .next
    ld a, [wPlayerDirection]
    cp c
    jr nz, .next
    ld a, [wXCoord]
    cp d
    jr nz, .next
    ld a, [wYCoord]
    cp e
    jr nz, .next
    ld e, 1
    ret
.next
    ld e, 0
    jr .loop

; After a successful step, return the configured STEP_ON/COLLISION result.
JohtoVerticalGateAfterStep314::
    ld e, 0
    ld hl, JohtoVerticalGateAfterStepProfiles314
.loop
    ld a, [hli]
    cp $ff
    ret z
    ld b, a
    ld a, [wCurLocalMapID]
    cp b
    jr nz, .skipMap
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld d, a
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld b, a
    ld a, [wPlayerDirection]
    cp c
    jr nz, .next
    ld a, [wXCoord]
    cp d
    jr nz, .next
    ld a, [wYCoord]
    cp e
    jr nz, .next
    ld e, b
    ret
.skipMap
    ld de, 4
    add hl, de
.next
    ld e, 0
    jr .loop

 ; Only E=1 may authorize an outward collision Warp. E=3 is reserved for
; successful sideways movement between ID66's two carpet cells and must
; never let a collision against either outer rail trigger a Warp.
JohtoVerticalGateCollisionExit314::
    call JohtoVerticalGateAfterStep314
    ld a, e
    cp 1
    ret z
    ld e, 0
    ret

; Gold door landing may step once; a carpet landing never auto-steps.
JohtoVerticalGateArrivalStep314::
    ld e, 0
    ld hl, JohtoVerticalGateArrivalProfiles314
.loop
    ld a, [hli]
    cp $ff
    ret z
    ld b, a
    ld a, [wCurLocalMapID]
    cp b
    jr nz, .skipMap
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld d, a
    ld a, [hli]
    ld b, a
    ld a, [wXCoord]
    cp c
    jr nz, .next
    ld a, [wYCoord]
    cp d
    jr nz, .next
    ld e, b
    ret
.skipMap
    ld de, 3
    add hl, de
.next
    ld e, 0
    jr .loop

; Fail closed at the physical edge of each configured finite gatehouse map.
JohtoVerticalGateClosedEdge314::
    ld e, 0
    ld hl, JohtoVerticalGateBoundsProfiles314
.loop
    ld a, [hli]
    cp $ff
    ret z
    ld b, a
    ld a, [wCurLocalMapID]
    cp b
    jr nz, .skipMap
    ld a, [hli]
    ld b, a ; width
    ld a, [hli]
    ld c, a ; height
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    ret nz
    ld a, [wXCoord]
    dec b
    cp b
    ret nz
    jr .blocked
.up
    ld a, [wYCoord]
    and a
    ret nz
    jr .blocked
.down
    ld a, [wYCoord]
    dec c
    cp c
    ret nz
    jr .blocked
.left
    ld a, [wXCoord]
    and a
    ret nz
.blocked
    ld e, 1
    ret
.skipMap
    inc hl
    inc hl
    jr .loop

ASSERT BANK(JohtoVerticalGateBeforeStep314) == BANK(JohtoVerticalGateBeforeStepProfiles314)
ASSERT BANK(JohtoVerticalGateAfterStep314) == BANK(JohtoVerticalGateAfterStepProfiles314)
ASSERT BANK(JohtoVerticalGateArrivalStep314) == BANK(JohtoVerticalGateArrivalProfiles314)
ASSERT BANK(JohtoVerticalGateClosedEdge314) == BANK(JohtoVerticalGateBoundsProfiles314)
