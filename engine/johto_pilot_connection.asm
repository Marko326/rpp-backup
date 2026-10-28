; Region-aware $FC map-connection resolver. Supports all four directions and
; sparse stable IDs, while preserving legacy Kanto-to-Kanto connections.
; Input D = direction, E = raw connected-map handle from the live header.
; Output E = real Kanto mapconst or $FC handle; updates current region/local ID.
; A connection with an unregistered source/direction/target fails closed.
JohtoPilotSelectConnection::
    ld a, e
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr z, .needsRouting
    ; Ordinary legacy Kanto connections are never remapped.
    ld a, [wCurRegion]
    cp MAP_REGION_KANTO
    ret z
.needsRouting
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .kantoSource
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    jr .haveSource
.kantoSource
    ld a, [wCurRegion]
    cp MAP_REGION_KANTO
    jp nz, SoftReset
    ld a, [wCurMap]
.haveSource
    ld c, a
    ld b, JOHTO_PILOT_SOURCE_CONNECTION_COUNT
    ld hl, JohtoPilotSourceConnections
.loop
    ld a, b
    and a
    jp z, SoftReset
    dec b
    ld a, [wCurRegion]
    cp [hl] ; source region
    inc hl
    jr nz, .skipFour
    ld a, [hli] ; source local ID
    cp c
    jr nz, .skipThree
    ld a, [hli] ; direction
    cp d
    jr nz, .skipTwo
    ld a, [hli] ; target region
    cp MAP_REGION_JOHTO
    jr z, .toJohto
    cp MAP_REGION_KANTO
    jp nz, SoftReset
    ld a, [hl]
    cp JOHTO_REGISTERED_WARP_SELECTOR
    jp nc, SoftReset ; reject reserved selectors
    cp e ; declared raw Kanto destination must match connection header
    jp nz, SoftReset
    ld [wCurLocalMapID], a
    xor a
    ld [wCurRegion], a
    ld e, [hl]
    ret
.toJohto
    ld a, e
    cp JOHTO_RUNTIME_MAP_HANDLE
    jp nz, SoftReset
    ld e, [hl]
    push hl
    callab GetJohtoActiveSlot ; don't trust merely preallocated stable IDs
    ld a, e
    pop hl
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld a, [hl]
    ld [wCurLocalMapID], a
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret
.skipFour
    inc hl ; source ID
.skipThree
    inc hl ; direction
.skipTwo
    inc hl ; destination region
    inc hl ; destination ID
    jr .loop
