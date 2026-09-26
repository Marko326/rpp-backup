; GLR-5.51.00: data-driven Gym Leader badge/TM reward flow.
; Input: e = GymLeaderRewardData entry index (0-7).
GiveGymLeaderReward::
	ld a, e
	add a
	add a
	add a ; 8 bytes per entry
	ld e, a
	ld d, 0
	ld hl, GymLeaderRewardData
	add hl, de

	; show the badge/reward introduction text
	ld a, [hli]
	ld [hSpriteIndexOrTextID], a
	push hl
	call DisplayTextID
	pop hl

	; EVENT_BEAT_* is the bit immediately after EVENT_GOT_TM* in the same byte
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld c, [hl]
	inc hl
	ld a, c
	add a
	ld b, a
	ld a, [de]
	or b
	ld [de], a

	; preserve the event byte/mask while GiveItem and DisplayTextID run
	ld a, c
	push af
	push de
	ld c, [hl]
	inc hl
	ld b, 1
	push hl
	call GiveItem
	pop hl
	jr nc, .bagFull

	ld a, [hli]
	inc hl ; skip the bag-full text ID
	push hl
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	pop hl
	pop de
	pop af
	ld b, a
	ld a, [de]
	or b
	ld [de], a
	jr .setBadge

.bagFull
	inc hl ; skip the received-TM text ID
	ld a, [hli]
	push hl
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	pop hl
	pop de
	pop af

.setBadge
	ld a, [hl]
	ld hl, wObtainedKantoBadges
	or [hl]
	ld [hl], a
	ret

; badge text ID, shared event byte, got-TM mask, TM item,
; received-TM text ID, bag-full text ID, badge mask
GymLeaderRewardData:
	db $4
	dwEventFlagAddress EVENT_GOT_TM34
	db 1 << (EVENT_GOT_TM34 % 8), TM_36, $5, $6, 1 << 0

	db $5
	dwEventFlagAddress EVENT_GOT_TM11
	db 1 << (EVENT_GOT_TM11 % 8), TM_11, $6, $7, 1 << 1

	db $6
	dwEventFlagAddress EVENT_GOT_TM24
	db 1 << (EVENT_GOT_TM24 % 8), TM_24, $7, $8, 1 << 2

	db $9
	dwEventFlagAddress EVENT_GOT_TM21
	db 1 << (EVENT_GOT_TM21 % 8), TM_21, $a, $b, 1 << 3

	db $9
	dwEventFlagAddress EVENT_GOT_TM06
	db 1 << (EVENT_GOT_TM06 % 8), TM_06, $a, $b, 1 << 4

	db $a
	dwEventFlagAddress EVENT_GOT_TM46
	db 1 << (EVENT_GOT_TM46 % 8), TM_46, $b, $c, 1 << 5

	db $a
	dwEventFlagAddress EVENT_GOT_TM38
	db 1 << (EVENT_GOT_TM38 % 8), TM_38, $b, $c, 1 << 6

	db $c
	dwEventFlagAddress EVENT_GOT_TM27
	db 1 << (EVENT_GOT_TM27 % 8), TM_27, $d, $e, 1 << 7
