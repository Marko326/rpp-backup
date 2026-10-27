; P3-001: runtime connection selector for maps using the shared $FC handle.
; Input D=WEST/EAST, E=connected map handle. Non-$FC connections pass through.
; For $FC, source stable ID + direction must match the source-authentic table.
JohtoPilotSelectConnection::
    ld a, e
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    ld c, a
    ld b, JOHTO_PILOT_SOURCE_CONNECTION_COUNT
    ld hl, JohtoPilotSourceConnections
.loop
    ld a, [hli]
    cp c
    jr nz, .skipRow
    ld a, [hli]
    cp d
    jr nz, .skipTarget
    ld a, [hli]
    ld [wCurLocalMapID], a
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret
.skipRow
    inc hl ; direction
.skipTarget
    inc hl ; target ID
    dec b
    jr nz, .loop
    jp SoftReset
