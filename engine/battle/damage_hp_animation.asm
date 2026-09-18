; BATTLE-5.19.9
; Direct opponent-target damage uses exact effective-HP-loss percentages.
;
; Only ordinary attacks where the acting side and target HUD are opposite mons
; use the accelerated path (H_WHOSETURN == wHPBarType):
;   < 25% max HP loss = original UpdateHPBar2, unchanged
;   25% - <50%         = normal    : 1 pixel / 1 frame
;   50% - <75%         = fast      : 2 pixels / 1 frame
;   >=75%               = very fast : 4 pixels / 1 frame
;
; Confusion self-damage and Jump Kick / Hi Jump Kick crash damage have
; H_WHOSETURN != wHPBarType and therefore also keep original UpdateHPBar2.
; Healing, ordinary recoil, items and other generic HP-bar callers never enter
; this wrapper and retain their existing cadence.
;
; BATTLE-5.19.9 smooth display refinement:
; accelerated damage temporarily disables normal one-third AutoBG transfer.
; Each real animation wait requests a TILE-ONLY VBlank row copy, so battle
; Pokemon palette attributes are left untouched. Enemy HUD copies one row;
; player HUD copies two rows so its numeric HP remains synchronized.
; The >=75% tier uses 4 visible pixels/frame to retain the punch of the older
; chunkier AutoBG presentation while still updating every display frame.

DEF HP_DAMAGE_SPEED_NORMAL    EQU 1
DEF HP_DAMAGE_SPEED_FAST      EQU 2
DEF HP_DAMAGE_SPEED_VERY_FAST EQU 3

UpdateAttackDamageHPBar:
	; The normal player->enemy and enemy->player paths have matching turn/HUD
	; selectors (0/0 or 1/1). Self-inflicted paths deliberately mismatch.
	ld a, [H_WHOSETURN]
	ld b, a
	ld a, [wHPBarType]
	cp b
	jr nz, .original

	; Calculate effective damage = old HP - new HP. wHPBar* HP values are
	; little-endian, while wHPBarHPDifference is big-endian for TX_NUM.
	ld a, [wHPBarOldHP]
	ld c, a
	ld a, [wHPBarOldHP + 1]
	ld b, a
	ld a, [wHPBarNewHP]
	ld e, a
	ld a, [wHPBarNewHP + 1]
	ld d, a
	ld a, c
	sub e
	ld e, a
	ld a, b
	sbc d
	ld d, a
	ld a, e
	ld [wHPBarHPDifference + 1], a
	ld a, d
	ld [wHPBarHPDifference], a

	; Classify against max HP without division. BC = damage, DE = max HP.
	; 25%: 4D >= M. 50%: 2D >= M. 75%: 4D >= 3M.
	ld b, d
	ld c, e
	ld a, [wHPBarMaxHP]
	ld e, a
	ld a, [wHPBarMaxHP + 1]
	ld d, a

	ld h, b
	ld l, c
	add hl, hl ; 2 * damage
	ld b, h
	ld c, l   ; keep 2 * damage in BC
	add hl, hl ; 4 * damage
	call .compareHLDE
	jr c, .original ; 4D < M => strictly below 25%

	ld h, b
	ld l, c
	call .compareHLDE
	jr c, .normal ; 2D < M => 25% - <50%

	; BC currently holds 2D. Build 4D in BC and 3M in HL.
	add hl, hl
	ld b, h
	ld c, l
	ld h, d
	ld l, e
	add hl, hl
	add hl, de
	ld a, b
	cp h
	jr c, .fast
	jr nz, .veryFast
	ld a, c
	cp l
	jr c, .fast

.veryFast
	ld a, HP_DAMAGE_SPEED_VERY_FAST
	jr .setSpeed
.fast
	ld a, HP_DAMAGE_SPEED_FAST
	jr .setSpeed
.normal
	ld a, HP_DAMAGE_SPEED_NORMAL
.setSpeed
	ld [wHPBarDamageSpeed], a
	xor a
	ld [wHPBarDamagePhase], a

	; callab consumes HL, so rebuild the HUD tile pointer from wHPBarType.
	ld a, [wHPBarType]
	and a
	jr z, .enemyHUD
	coord hl, 10, 9
	jr .animate
.enemyHUD
	coord hl, 2, 2
.animate
	call AttackHPBar_AnimateDamage

	; Scratch state must never leak into a later battle/menu operation.
	xor a
	ld [wHPBarDamageSpeed], a
	ld [wHPBarDamagePhase], a
	ret

.original
	; BATTLE-5.19.7: <25% and self-inflicted damage use the unmodified original
	; animation, including numeric HP pacing and the original 2-frame pixel wait.
	ld a, [wHPBarType]
	and a
	jr z, .originalEnemyHUD
	coord hl, 10, 9
	predef UpdateHPBar2
	ret
.originalEnemyHUD
	coord hl, 2, 2
	predef UpdateHPBar2
	ret

.compareHLDE
	; Carry set iff unsigned HL < DE.
	ld a, h
	cp d
	ret nz
	ld a, l
	cp e
	ret

; Animate an accelerated direct-damage decrease one actual HP point at a time
; so the player's number still counts down, while visible timing is driven by
; bar pixels rather than by one DelayFrame per HP point.
; hl = HUD HP-bar tile pointer.
AttackHPBar_AnimateDamage:
	; Keep intermediate 1-pixel states in wTileMap from leaking through the
	; normal top/middle/bottom AutoBG cycle. Dedicated tile-only VBlank copies
	; below expose only the intended 1/2/4-pixel visible steps.
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a

	; Keep the final target HP in DE while wHPBarNewHP temporarily walks toward it.
	ld a, [wHPBarNewHP]
	ld e, a
	ld a, [wHPBarNewHP + 1]
	ld d, a
.loop
	ld a, [wHPBarOldHP]
	ld c, a
	ld a, [wHPBarOldHP + 1]
	ld b, a
	ld a, b
	cp d
	jr nz, .step
	ld a, c
	cp e
	jr z, .done
.step
	push de
	dec bc
	ld a, c
	ld [wHPBarNewHP], a
	ld a, b
	ld [wHPBarNewHP + 1], a
	call AttackHPBar_CalcOldNewHPBarPixels
	ld a, e
	sub d
	call AttackHPBar_PrintHPNumber
	and a
	jr z, .noPixelDifference
	call AttackHPBar_AnimatePixels
.noPixelDifference
	ld a, [wHPBarNewHP]
	ld [wHPBarOldHP], a
	ld a, [wHPBarNewHP + 1]
	ld [wHPBarOldHP + 1], a
	pop de
	jr .loop

.done
	; Draw the exact final bar state. GetHPBarLength intentionally floors all
	; nonzero HP to at least 1 pixel, so handle 0 HP separately.
	ld a, d
	or e
	jr z, .fainted
	ld b, d
	ld c, e
	ld a, [wHPBarMaxHP]
	ld e, a
	ld a, [wHPBarMaxHP + 1]
	ld d, a
	call AttackHPBar_GetLength
	jr .drawFinal
.fainted
	ld e, 0
.drawFinal
	call AttackHPBar_PrintHPNumber
	ld d, 6
	call AttackDrawHPBarWithColor
	; Expose the exact final bar/number once, then restore the caller's AutoBG
	; state. No Delay3 is needed because this copy is not waiting for a third.
	call AttackHPBar_WaitVisibleFrame
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

; a = number of bar pixels to remove, e = current bar length in pixels.
AttackHPBar_AnimatePixels:
	push hl
.loop
	push af
	; Draw the next shorter state so the first visible accelerated frame moves.
	dec e
	ld d, 6
	call AttackDrawHPBarWithColor
	call WaitAttackDamageHPBarFrame
	pop af
	dec a
	jr nz, .loop
	pop hl
	ret

; Accelerated-path wait policy. 1 px/frame needs no phase; the 2 px/frame and
; 4 px/frame tiers carry phase across individual HP steps.
WaitAttackDamageHPBarFrame:
	ld a, [wHPBarDamageSpeed]
	cp HP_DAMAGE_SPEED_FAST
	jr z, .fast
	cp HP_DAMAGE_SPEED_VERY_FAST
	jr z, .veryFast
	; 25%-<50% and any unexpected value use one visible pixel per frame.
	jp AttackHPBar_WaitVisibleFrame
.fast
	; Submit two successive pixel states before exposing the latest one.
	ld a, [wHPBarDamagePhase]
	xor 1
	ld [wHPBarDamagePhase], a
	ret nz
	jp AttackHPBar_WaitVisibleFrame
.veryFast
	; Four visible pixels/frame restores the very-fast feel while the dedicated
	; copy keeps the motion regular instead of bunching several frames together.
	ld a, [wHPBarDamagePhase]
	inc a
	cp 4
	jr nc, .veryFastWait
	ld [wHPBarDamagePhase], a
	ret
.veryFastWait
	xor a
	ld [wHPBarDamagePhase], a
	jp AttackHPBar_WaitVisibleFrame

; Queue a TILE-ONLY row transfer for the next VBlank and wait exactly one frame.
; Bit 7 of H_VBCOPYBGNUMROWS requests the BATTLE-5.19.9 tile-only path in
; VBlankCopyBgMap. The low 7 bits are the actual row count.
; This deliberately leaves CGB BG attributes untouched: battle Pokemon graphics
; share these rows, so rewriting their attributes would corrupt their palettes.
AttackHPBar_WaitVisibleFrame:
	push bc
	push de
	push hl

	ld a, [wHPBarType]
	and a
	jr z, .enemyHUD

	; Player: row 9 contains the bar and row 10 contains numeric HP.
	coord hl, 0, 9
	ld de, 9 * BG_MAP_WIDTH
	ld b, $82
	jr .schedule

.enemyHUD
	; Enemy: only row 2 is needed.
	coord hl, 0, 2
	ld de, 2 * BG_MAP_WIDTH
	ld b, $81

.schedule
	; H_VBCOPYBGSRC low byte doubles as the enable flag. Enable only after the
	; source high byte, destination and mode/count have all been prepared.
	xor a
	ld [H_VBCOPYBGSRC], a
	ld c, l
	ld a, h
	ld [H_VBCOPYBGSRC + 1], a
	ld a, b
	ld [H_VBCOPYBGNUMROWS], a

	ld a, [H_AUTOBGTRANSFERDEST]
	ld l, a
	ld a, [H_AUTOBGTRANSFERDEST + 1]
	ld h, a
	add hl, de
	ld a, l
	ld [H_VBCOPYBGDEST], a
	ld a, h
	ld [H_VBCOPYBGDEST + 1], a

	ld a, c
	ld [H_VBCOPYBGSRC], a

	pop hl
	pop de
	pop bc
	jp DelayFrame

; Same HP-number update as UpdateHPBar_PrintHPNumber, but without DelayFrame.
; The original path never calls this routine.
AttackHPBar_PrintHPNumber:
	push af
	push de
	ld a, [wHPBarType]
	and a
	jr z, .done ; enemy HUD has no numeric HP display
	ld a, [wHPBarOldHP]
	ld [wHPBarTempHP + 1], a
	ld a, [wHPBarOldHP + 1]
	ld [wHPBarTempHP], a
	push hl
	ld a, [hFlags_0xFFF6]
	bit 0, a
	jr z, .normalOffset
	ld de, $9
	jr .position
.normalOffset
	ld de, $15
.position
	add hl, de
	push hl
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ld de, wHPBarTempHP
	lb bc, 2, 3
	call PrintNumber
	pop hl
.done
	pop de
	pop af
	ret

; Calculate old/new HP bar lengths from the shared HP animation variables.
; Returns d = new pixels, e = old pixels.
AttackHPBar_CalcOldNewHPBarPixels:
	push hl
	ld hl, wHPBarMaxHP
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	push de
	call AttackHPBar_GetLength
	ld a, e
	pop de
	pop bc
	push af
	call AttackHPBar_GetLength
	pop af
	ld d, e
	ld e, a
	pop hl
	ret

; bc * 48 / de, matching GetHPBarLength including its 1-pixel nonzero floor.
AttackHPBar_GetLength:
	push hl
	xor a
	ld hl, H_MULTIPLICAND
	ld [hli], a
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld [hl], $30
	call Multiply
	ld a, d
	and a
	jr z, .maxHPSmaller256
	srl d
	rr e
	srl d
	rr e
	ld a, [H_MULTIPLICAND + 1]
	ld b, a
	ld a, [H_MULTIPLICAND + 2]
	srl b
	rr a
	srl b
	rr a
	ld [H_MULTIPLICAND + 2], a
	ld a, b
	ld [H_MULTIPLICAND + 1], a
.maxHPSmaller256
	ld a, e
	ld [H_DIVISOR], a
	ld b, $4
	call Divide
	ld a, [H_MULTIPLICAND + 2]
	ld e, a
	pop hl
	and a
	ret nz
	ld e, $1
	ret

; Local copy of DrawHPBarWithColor so the attack-only engine can stay in a
; relocatable ROMX section without adding code to the nearly-full HP-bar bank.
AttackDrawHPBarWithColor:
	call DrawHPBar
	push bc
	push de
	push hl

	ld a, [wHPBarType]
	or a
	ld hl, wEnemyHPBarColor
	jr z, .gotHPBarColorVar
	dec a
	ld hl, wPlayerHPBarColor
	jr z, .gotHPBarColorVar

	ld hl, wPartyMenuHPBarColors
	ld b, 0
	ld a, [wCurrentMenuItem]
	ld c, a
	add hl, bc
.gotHPBarColorVar
	call GetHealthBarColor

	ld a, 2
	ld [rSVBK], a
	ld a, [wHPBarType]
	ld c, a
	cp 2
	jr nz, .inBattle

	ld a, [hl]
	push af
	ld hl, W2_TilesetPaletteMap
	ld bc, SCREEN_WIDTH * 2
	ld a, [wCurrentMenuItem]
	call AddNTimes
	ld bc, SCREEN_WIDTH * 2
	pop af
	inc a
	call FillMemory
	ld a, 3
	ld [W2_StaticPaletteMapChanged], a
	jr .done
.inBattle
	ld a, [hl]
	add PAL_GREENBAR
	ld d, a
	ld a, c
	and a
	ld e, 2
	jr nz, .loadPalette
	inc e
.loadPalette
	CALL_INDIRECT LoadSGBPalette
.done
	ld a, 1
	ld [W2_ForceBGPUpdate], a
	xor a
	ld [rSVBK], a
	pop hl
	pop de
	pop bc
	ret
