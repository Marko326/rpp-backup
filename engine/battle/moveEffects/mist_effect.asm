MistEffect_:
	ld hl, wPlayerBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jr z, .mistEffect
	ld hl, wEnemyBattleStatus2
.mistEffect
	bit ProtectedByMist, [hl] ; is mon protected by mist?
	jr nz, .mistAlreadyInUse
	set ProtectedByMist, [hl] ; mon is now protected by mist
	callab PlayCurrentMoveAnimation
	ld hl, ShroudedInMistText
	jp PrintText
.mistAlreadyInUse
	; BTL-5.61.55: ResidualEffects1 skips the core pause; keep the move-use text
	; visible briefly before printing the failure message.
	ld c, 50
	call DelayFrames
	jpab PrintButItFailedText_

ShroudedInMistText:
	TX_FAR _ShroudedInMistText
	db "@"
