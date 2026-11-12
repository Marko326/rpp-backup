; REF-367D dormant native slide-direction state transitions for Ice Path.
; Requires ice_path_role_runtime_367b.asm + ice_path_step_runtime_367c.asm
; in the SAME ROMX bank. NO main.asm INCLUDE or player hook in this batch.
;
; Caller owns a distinct runtime slide-heading byte (not yet allocated):
;   0 = idle, PLAYER_DIR_* = previous heading while sliding.
; Do not borrow wUnusedD71F: existing item routines write to that byte.
;
; JohtoIcePathArmSlide367D
;   Inputs B=Gold Y, C=Gold X, D=direction of COMPLETED normal player step.
;   Outputs E=heading if destination is ICE, otherwise E=0;
;           carry set only if newly armed. BC, D and HL preserved.
;   Invoke ONLY after an actual walk step finishes; never on warp arrival.
;
; JohtoIcePathResolveSlide367D
;   Inputs B=Y, C=X, D=current user-requested direction (0 or PLAYER_DIR_*),
;          E=previous slide heading (0 or PLAYER_DIR_*).
;   Outputs A=effective direction, E=updated slide heading;
;           carry set iff active slide overrides user input.
;   If next cell is blocked, clear E and let ordinary input/collision run.
;   NEVER bypass ordinary sprite, boulder or map collision checks.
;
; JohtoIcePathClearSlide367D
;   Output E=0. Must be called on map transition, Continue, fall, Surf,
;   menu/script takeover, battle and other scripted player movement.  Live
;   integration must prove those paths before these maps may be activated.
;
; Gold role 2 = ICE; physical next-step permission supplied by REF-367C.

JohtoIcePathArmSlide367D::
    push bc
    push hl
    ld a, d
    cp PLAYER_DIR_UP
    jr z, .valid
    cp PLAYER_DIR_DOWN
    jr z, .valid
    cp PLAYER_DIR_LEFT
    jr z, .valid
    cp PLAYER_DIR_RIGHT
    jr nz, .idle
.valid
    call JohtoIcePathGoldRoleAt367B
    cp 2
    jr nz, .idle
    ld e, d
    ld a, d
    scf
    pop hl
    pop bc
    ret
.idle
    xor a
    ld e, a
    pop hl
    pop bc
    ret

JohtoIcePathResolveSlide367D::
    push bc
    push hl
    ld a, e
    cp PLAYER_DIR_UP
    jr z, .active
    cp PLAYER_DIR_DOWN
    jr z, .active
    cp PLAYER_DIR_LEFT
    jr z, .active
    cp PLAYER_DIR_RIGHT
    jr nz, .stopped
.active
    push de
    ld d, e
    call JohtoIcePathContinueSlide367C
    jr nc, .noMoreSlide
    pop de
    ld a, e
    scf
    pop hl
    pop bc
    ret
.noMoreSlide
    pop de
.stopped
    ld e, 0
    xor a ; carry clear even if the step detector previously set carry
    ld a, d ; ordinary requested direction is not lost after stop
    pop hl
    pop bc
    ret

JohtoIcePathClearSlide367D::
    xor a
    ld e, a
    ret
