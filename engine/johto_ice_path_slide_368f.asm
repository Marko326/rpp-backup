; REF-368F Ice Path live automatic slide. Called from ROM0 ONLY at the end
; of a real step and at the next frame's input boundary. The old REF-367D
; native prototype remains dormant; do not include/duplicate its role grids.
;
; wIcePathSlideHeading is an alias for the previously unused $D67C byte,
; and ClearVariablesOnEnterMap resets it. Values are PLAYER_DIR_* or zero.
; Movement still uses the original land/sprite collision, step animation,
; step counting and stair/warp checking. No forced movement on arrival,
; during script simulation, ledge animation, Surf, or after a battle.
;
; The read wrappers load the player coordinates *inside the target bank*: callab
; overwrites B with BANK() and HL with its target, so coordinates must not
; be passed in BC from this dispatch. ICE is returned via the Z flag.
; Bankswitch restores the old ROM bank in A; never test A after callab.

JohtoIcePathArmAfterStep368F::
    ld a, [wd730]
    bit 7, a ; scripted movement or simulated input
    jr nz, .clear
    ld a, [wd736]
    bit 6, a ; jumping over a ledge
    jr nz, .clear
    ld a, [wWalkBikeSurfState]
    cp 2 ; Surf
    jr z, .clear
    call JohtoIcePathPlayerOnIce368F
    jr nz, .clear
    ld a, [wPlayerMovingDirection]
    cp PLAYER_DIR_UP
    jr z, .arm
    cp PLAYER_DIR_DOWN
    jr z, .arm
    cp PLAYER_DIR_LEFT
    jr z, .arm
    cp PLAYER_DIR_RIGHT
    jr nz, .clear
.arm
    ld [wIcePathSlideHeading], a
    ret
.clear
    xor a
    ld [wIcePathSlideHeading], a
    ret

JohtoIcePathInjectSlideInput368F::
    ld a, [wIcePathSlideHeading]
    and a
    ret z ; not sliding: completely preserve the real joypad input
    ld a, [wd730]
    bit 7, a ; scripts and scripted hops own their own movement
    jr nz, .clear
    ld a, [wd736]
    bit 6, a
    jr nz, .clear
    ld a, [wWalkBikeSurfState]
    cp 2
    jr z, .clear
    ld a, [wCurOpponent]
    and a
    jr nz, .clear
    call JohtoIcePathPlayerOnIce368F
    jr nz, .clear
    ld a, [wIcePathSlideHeading]
    cp PLAYER_DIR_RIGHT
    jr z, .right
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr nz, .clear
    ld a, D_DOWN
    jr .force
.right
    ld a, D_RIGHT
    jr .force
.left
    ld a, D_LEFT
    jr .force
.up
    ld a, D_UP
.force
    ld [hJoyHeld], a ; overwrite mid-ICE steering with the last step heading
    xor a
    ld [hJoyPressed], a ; block START/SELECT/A until collision/end of slide
    ld [hJoyReleased], a
    ret
.clear
    xor a
    ld [wIcePathSlideHeading], a
    ret

; Return Z only when the *current player cell* is a Gold ICE role.
; Reject other regions even if the stable local ID numerically matches.
JohtoIcePathPlayerOnIce368F::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jp nz, .notIce
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, .notIce
    ld a, [wCurLocalMapID]
    cp JOHTO_ICE_PATH_1F_LOCAL_ID
    jp z, .one
    cp JOHTO_ICE_PATH_B1F_LOCAL_ID
    jp z, .b1
    cp JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID
    jp z, .b2m
    cp JOHTO_ICE_PATH_B2F_BLACKTHORN_SIDE_LOCAL_ID
    jp z, .b2b
    cp JOHTO_ICE_PATH_B3F_LOCAL_ID
    jp z, .b3
.notIce
    ld a, 1
    and a ; Z clear
    ret
.one
    callab JohtoIcePath1FIsIce368F
    ret
.b1
    callab JohtoIcePathB1FIsIce368F
    ret
.b2m
    callab JohtoIcePathB2FMahoganyIsIce368F
    ret
.b2b
    callab JohtoIcePathB2FBlackthornIsIce368F
    ret
.b3
    callab JohtoIcePathB3FIsIce368F
    ret
