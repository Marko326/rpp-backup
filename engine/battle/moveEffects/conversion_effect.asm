ConversionEffect_:
	ld hl, wEnemyMonType1
	ld de, wBattleMonType1
	ld a, [H_WHOSETURN]
	and a
	ld a, [wEnemyBattleStatus1]
	jr z, .conversionEffect
	push hl
	ld h, d
	ld l, e
	pop de
	ld a, [wPlayerBattleStatus1]
.conversionEffect
	bit Invulnerable, a ; is mon immune to typical attacks (dig/fly)
	jr z, .copyTargetTypes
	; BTL-5.61.55: ResidualEffects1 skips the core pause; keep the move-use text
	; visible briefly before printing the failure message.
	ld c, 50
	call DelayFrames
	jr PrintButItFailedText
.copyTargetTypes
; copy target's types to user
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ld hl, PlayCurrentMoveAnimation
	call CallBankF
	ld hl, ConvertedTypeText
	jp PrintText

ConvertedTypeText:
	TX_FAR _ConvertedTypeText
	db "@"

PrintButItFailedText:
	ld hl, PrintButItFailedText_
CallBankF:
	ld b, BANK(PrintButItFailedText_)
	jp Bankswitch
