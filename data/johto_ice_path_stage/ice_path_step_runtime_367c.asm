; REF-367C native Ice Path movement probe, for eventual ROMX integration.
; DORMANT: not INCLUDEd by main.asm until the full ice-slide/PIT/Strength
; transitions, object occupancy, graphics, map headers and outdoor warps exist.
; Uses the exact Gold role reader from ice_path_role_runtime_367b.asm in the
; SAME ROMX bank.  No WRAM scratch, ROM0 bytes or movement hooks changed.
;
; JohtoIcePathProbeStep367C
;   Input B = player's current Y, C = X; D = PLAYER_DIR_*.
;   Current wCurLocalMapID is one of 70/95/96/97/98.
;   Output carry clear / A=0 if forbidden.
;          carry set   / A=1 for passable ground/ladder/carpet/ledge,
;                       A=2 for ICE, A=3 for a B1F PIT landing.
;   Preserves BC, DE, HL.  Never moves player or fires a warp.
;   Strength boulder sprite occupancy MUST be checked by the caller before
;   accepting a nonzero result; this routine only handles Gold *terrain*.
;
; JohtoIcePathContinueSlide367C
;   Same inputs. Carry set with A=next role 1/2/3 only when player already
;   stands on ICE and the cell AHEAD is traversable. If blocked, carry clear
;   to let the overworld accept a NEW user direction without a collision loop.
;   A live caller MUST keep the slide heading across frames (not replace it
;   with mid-slide joypad input), must disarm on map loading/arrival and must
;   route every accepted step through ordinary player animation/collision.
;
; Gold role ordinals (REF367A source contract):
; FLOOR=0 WALL=1 ICE=2 PIT=3 LADDER=4 DOWN_CARPET=5
; UP_WALL=6 HOP_DOWN=7 HOP_DOWN_LEFT=8.

JohtoIcePathProbeStep367C::
    push bc
    push de
    push hl
    ; Reject unknown headings: do not turn an invalid direction into a
    ; valid x/y offset or let the wraparound arithmetic pass a border.
    ld a, d
    cp PLAYER_DIR_UP
    jr z, .headingValid
    cp PLAYER_DIR_DOWN
    jr z, .headingValid
    cp PLAYER_DIR_LEFT
    jr z, .headingValid
    cp PLAYER_DIR_RIGHT
    jp nz, .blocked
.headingValid
    ; Reject invalid start cells. PIT is consumed by the map warp handler,
    ; so a new player step must never walk back OUT of a pending fall.
    call JohtoIcePathGoldRoleAt367B
    cp 1
    jp z, .blocked
    cp 3
    jp z, .blocked
    ; A Gold UP_WALL cannot be exited to the north, even if the tile
    ; immediately north is an ordinary FLOOR.
    cp 6
    jr nz, .target
    ld a, d
    cp PLAYER_DIR_UP
    jp z, .blocked
.target
    ld a, d
    cp PLAYER_DIR_UP
    jr z, .north
    cp PLAYER_DIR_DOWN
    jr z, .south
    cp PLAYER_DIR_LEFT
    jr z, .west
    inc c
    jr .read
.north
    dec b
    jr .read
.south
    inc b
    jr .read
.west
    dec c
.read
    ; The Gold reader fails closed on underflow, overflow, other stable
    ; IDs, and the 10-wide ID97 map (never use ID96's 20-wide stride).
    call JohtoIcePathGoldRoleAt367B
    cp 1
    jr z, .blocked
    cp 6 ; entering UP_WALL from above is forbidden
    jr nz, .downHop
    ld a, d
    cp PLAYER_DIR_DOWN
    jr z, .blocked
    jr .ground
.downHop
    cp 7
    jr nz, .downLeftHop
    ld a, d
    cp PLAYER_DIR_UP
    jr z, .blocked
    jr .ground
.downLeftHop
    cp 8
    jr nz, .hazards
    ld a, d
    cp PLAYER_DIR_UP
    jr z, .blocked
    cp PLAYER_DIR_RIGHT
    jr z, .blocked
    jr .ground
.hazards
    cp 2
    jr z, .ice
    cp 3
    jr z, .pit
.ground
    ld a, 1
    jr .allowed
.ice
    ld a, 2
    jr .allowed
.pit
    ; Only B1F PIT coordinates are active falling entries. Other map's
    ; ICE arrival points are role=2, NEVER inverse PIT warps.
    ld a, [wCurLocalMapID]
    cp JOHTO_ICE_PATH_B1F_LOCAL_ID
    jr nz, .blocked
    ld a, 3
.allowed
    scf
    pop hl
    pop de
    pop bc
    ret
.blocked
    xor a
    pop hl
    pop de
    pop bc
    ret

JohtoIcePathContinueSlide367C::
    push bc
    push de
    push hl
    call JohtoIcePathGoldRoleAt367B
    cp 2 ; no automatic movement from ground, PIT arrival, or ladder
    jr nz, .stop
    call JohtoIcePathProbeStep367C
    jr nc, .stop
    pop hl
    pop de
    pop bc
    ret
.stop
    xor a
    pop hl
    pop de
    pop bc
    ret
