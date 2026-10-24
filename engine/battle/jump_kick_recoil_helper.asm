; JUMP_KICK_EFFECT recoil is self-inflicted and must bypass Substitute. The
; missed move leaves wDamage=0 in Gen I, so the legacy /8 calculation resolves
; to exactly 1 HP. Use the normal self HP subtractor after calculating recoil.
HandleJumpKickCrashRecoil::
    ld hl, wDamage
    ld a, [hli]
    ld b, [hl]
    srl a
    rr b
    srl a
    rr b
    srl a
    rr b
    ld [hl], b
    dec hl
    ld [hli], a
    or b
    jr nz, .applyRecoil
    inc a
    ld [hl], a
.applyRecoil
    ld hl, JumpKickCrashText
    call PrintText
    ld b, $4
    predef PredefShakeScreenHorizontally
    jpab ApplyDamageToActingPokemonRealHPWithDamagePointer

JumpKickCrashText:
    TX_FAR _KeptGoingAndCrashedText
    db "@"
