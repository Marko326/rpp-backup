; SCK-5.48.00: Silph Co. Card Key doors share one data-driven handler.
; Door events are still committed on the following map-script update, matching
; the original wCardKeyDoorY/X + wCurrentMapScriptFlags bit 5 timing.
PrintCardKeyText:
	call FindSilphCoDoorData
	ret nc
	predef GetTileAndCoordsInFrontOfPlayer
	ld a, [wTileInFrontOfPlayer]
	cp $18
	jr z, .cardKeyDoorInFrontOfPlayer
	cp $24
	jr z, .cardKeyDoorInFrontOfPlayer
	ld b, a
	ld a, [wCurMap]
	cp SILPH_CO_11F
	ret nz
	ld a, b
	cp $5e
	ret nz
.cardKeyDoorInFrontOfPlayer
	ld b, CARD_KEY
	call IsItemInBag
	jr z, .noCardKey
	call GetCoordsInFrontOfPlayer
	push de
	tx_pre_id CardKeySuccessText
	ld [hSpriteIndexOrTextID], a
	call PrintPredefTextID
	pop de
	srl d
	ld a, d
	ld b, a
	ld [wCardKeyDoorY], a
	srl e
	ld a, e
	ld c, a
	ld [wCardKeyDoorX], a
	ld a, [wCurMap]
	cp SILPH_CO_11F
	jr nz, .notSilphCo11F
	ld a, $3
	jr .replaceCardKeyDoorTileBlock
.notSilphCo11F
	ld a, $e
.replaceCardKeyDoorTileBlock
	ld [wNewTileBlockID], a
	predef ReplaceTileBlock
	ld hl, wCurrentMapScriptFlags
	set 5, [hl]
	ld a, SFX_GO_INSIDE
	jp PlaySound
.noCardKey
	tx_pre_id CardKeyFailText
	ld [hSpriteIndexOrTextID], a
	jp PrintPredefTextID

; SCK-5.48.00: called by Silph Co. 2F-11F map scripts. The descriptor table
; replaces each floor's coordinate search, event setter, and locked-door restore
; code while keeping the original event timing and tile behavior.
HandleSilphCoCardKeyDoors:
	call FindSilphCoDoorData
	ret nc
	push hl
	call .setOpenedDoorEvent
	pop hl
.restoreLockedDoors
	ld a, [hli]
	cp $ff
	ret z
	ld b, a ; block Y
	ld a, [hli]
	ld c, a ; block X
	ld a, [hli]
	ld [wNewTileBlockID], a ; locked-door block
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a ; event flag byte address
	ld a, [hli]
	push hl
	ld h, d
	ld l, e
	and [hl]
	jr nz, .doorAlreadyUnlocked
	predef ReplaceTileBlock
.doorAlreadyUnlocked
	pop hl
	jr .restoreLockedDoors

.setOpenedDoorEvent
	ld a, [wCardKeyDoorY]
	and a
	ret z
	ld d, a
	ld a, [wCardKeyDoorX]
	ld e, a
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp d
	jr nz, .skipAfterY
	ld a, [hli]
	cp e
	jr z, .found
	inc hl
	inc hl
	inc hl
	inc hl
	jr .loop
.skipAfterY
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	jr .loop
.found
	inc hl ; skip locked-door block
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hl]
	ld h, d
	ld l, e
	or [hl]
	ld [hl], a
	xor a
	ld [wCardKeyDoorY], a
	ld [wCardKeyDoorX], a
	ret

; Returns carry set and HL = current floor's door records when wCurMap is
; a Silph Co. Card Key floor. Each record is Y, X, locked block, event address,
; event mask; $ff terminates a floor's records.
FindSilphCoDoorData:
	ld hl, SilphCoDoorDataByMap
	ld a, [wCurMap]
	ld c, a
.loop
	ld a, [hli]
	cp $ff
	ret z ; cp $ff clears carry on the terminator
	cp c
	jr z, .found
	inc hl
	inc hl
	jr .loop
.found
	ld a, [hli]
	ld h, [hl]
	ld l, a
	scf
	ret

silph_card_key_door: MACRO
	db \1, \2, \3
	dw wEventFlags + ((\4) / 8)
	db 1 << ((\4) % 8)
ENDM

SilphCoDoorDataByMap:
	dbw SILPH_CO_2F,  .floor2
	dbw SILPH_CO_3F,  .floor3
	dbw SILPH_CO_4F,  .floor4
	dbw SILPH_CO_5F,  .floor5
	dbw SILPH_CO_6F,  .floor6
	dbw SILPH_CO_7F,  .floor7
	dbw SILPH_CO_8F,  .floor8
	dbw SILPH_CO_9F,  .floor9
	dbw SILPH_CO_10F, .floor10
	dbw SILPH_CO_11F, .floor11
	db $ff

.floor2
	silph_card_key_door $02, $02, $54, EVENT_SILPH_CO_2_UNLOCKED_DOOR1
	silph_card_key_door $05, $02, $54, EVENT_SILPH_CO_2_UNLOCKED_DOOR2
	db $ff
.floor3
	silph_card_key_door $04, $04, $5f, EVENT_SILPH_CO_3_UNLOCKED_DOOR1
	silph_card_key_door $04, $08, $5f, EVENT_SILPH_CO_3_UNLOCKED_DOOR2
	db $ff
.floor4
	silph_card_key_door $06, $02, $54, EVENT_SILPH_CO_4_UNLOCKED_DOOR1
	silph_card_key_door $04, $06, $54, EVENT_SILPH_CO_4_UNLOCKED_DOOR2
	db $ff
.floor5
	silph_card_key_door $02, $03, $5f, EVENT_SILPH_CO_5_UNLOCKED_DOOR1
	silph_card_key_door $06, $03, $5f, EVENT_SILPH_CO_5_UNLOCKED_DOOR2
	silph_card_key_door $05, $07, $5f, EVENT_SILPH_CO_5_UNLOCKED_DOOR3
	db $ff
.floor6
	silph_card_key_door $06, $02, $5f, EVENT_SILPH_CO_6_UNLOCKED_DOOR
	db $ff
.floor7
	silph_card_key_door $03, $05, $54, EVENT_SILPH_CO_7_UNLOCKED_DOOR1
	silph_card_key_door $02, $0a, $54, EVENT_SILPH_CO_7_UNLOCKED_DOOR2
	silph_card_key_door $06, $0a, $54, EVENT_SILPH_CO_7_UNLOCKED_DOOR3
	db $ff
.floor8
	silph_card_key_door $04, $03, $5f, EVENT_SILPH_CO_8_UNLOCKED_DOOR
	db $ff
.floor9
	silph_card_key_door $04, $01, $5f, EVENT_SILPH_CO_9_UNLOCKED_DOOR1
	silph_card_key_door $02, $09, $54, EVENT_SILPH_CO_9_UNLOCKED_DOOR2
	silph_card_key_door $05, $09, $54, EVENT_SILPH_CO_9_UNLOCKED_DOOR3
	silph_card_key_door $06, $05, $5f, EVENT_SILPH_CO_9_UNLOCKED_DOOR4
	db $ff
.floor10
	silph_card_key_door $04, $05, $54, EVENT_SILPH_CO_10_UNLOCKED_DOOR
	db $ff
.floor11
	silph_card_key_door $06, $03, $20, EVENT_SILPH_CO_11_UNLOCKED_DOOR
	db $ff

CardKeySuccessText:
	TX_FAR _CardKeySuccessText1
	TX_SFX_ITEM_1
	TX_FAR _CardKeySuccessText2
	db "@"

CardKeyFailText:
	TX_FAR _CardKeyFailText
	db "@"

; d = Y
; e = X
GetCoordsInFrontOfPlayer:
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	and a
	jr nz, .notFacingDown
; facing down
	inc d
	ret
.notFacingDown
	cp SPRITE_FACING_UP
	jr nz, .notFacingUp
; facing up
	dec d
	ret
.notFacingUp
	cp SPRITE_FACING_LEFT
	jr nz, .notFacingLeft
; facing left
	dec e
	ret
.notFacingLeft
; facing right
	inc e
	ret
