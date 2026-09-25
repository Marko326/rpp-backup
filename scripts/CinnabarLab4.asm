Lab4Script:
	jp EnableAutoTextBoxDrawing

Lab4TextPointers:
	dw Lab4Text1
	dw Lab4Text2

Lab4Script_GetFossilsInBag:
; construct a list of all fossils in the player's bag
	xor a
	ld [wFilteredBagItemsCount], a
	ld de, wFilteredBagItems
	ld hl, FossilsList
.loop
	ld a, [hli]
	and a
	jr z, .done
	push hl
	push de
	ld [wd11e], a
	ld b, a
	predef GetQuantityOfItemInBag
	pop de
	pop hl
	ld a, b
	and a
	jr z, .loop

	; A fossil's in the bag
	ld a, [wd11e]
	ld [de], a
	inc de
	push hl
	ld hl, wFilteredBagItemsCount
	inc [hl]
	pop hl
	jr .loop
.done
	ld a, $ff
	ld [de], a
	ret

FossilsList:
	db DOME_FOSSIL
	db HELIX_FOSSIL
	db OLD_AMBER
	db $00

Lab4Text1:
	TX_ASM
	; FSL-5.42.01: fossil revival completes in one interaction. The old
	; hand-in/wait/return progress events are retained only as reserved IDs.
	ld hl, Lab4Text_75dc6
	call PrintText
	call Lab4Script_GetFossilsInBag
	ld a, [wFilteredBagItemsCount]
	and a
	jr z, .noFossil
	callba GiveFossilToCinnabarLab
	jr nc, .done
	ld hl, Lab4FossilRevivedText
	call PrintText
	ld a, [wFossilMon]
	ld b, a
	ld c, 30
	call GivePokemon
	jr .done

.noFossil
	ld hl, Lab4Text_75dcb
	call PrintText
.done
	jp TextScriptEnd

Lab4Text_75dc6:
	TX_FAR _Lab4Text_75dc6
	db "@"

Lab4Text_75dcb:
	TX_FAR _Lab4Text_75dcb
	db "@"

Lab4FossilRevivedText:
	TX_FAR _Lab4FossilRevivedText
	db "@"

Lab4Text2:
	TX_ASM
	ld hl, Trader9Name
	call SetCustomName
	ld a, $9
	ld [wWhichTrade], a
	predef DoInGameTradeDialogue
	jp TextScriptEnd
	
Trader9Name:
	db "Ross@"
