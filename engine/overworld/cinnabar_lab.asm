GiveFossilToCinnabarLab:
	ld hl, wd730
	set 6, [hl]
	xor a
	ld [wCurrentMenuItem], a
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, [wFilteredBagItemsCount]
	dec a
	ld [wMaxMenuItem], a
	ld a, 2
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	ld a, [wFilteredBagItemsCount]
	dec a
	ld bc, 2
	ld hl, 3
	call AddNTimes
	dec l
	ld b, l
	ld c, $d
	coord hl, 0, 0
	call TextBoxBorder
	call UpdateSprites
	call PrintFossilsInBag
	ld hl, wd730
	res 6, [hl]
	call HandleMenuInput
	bit 1, a ; pressed B?
	jr nz, .cancelledGivingFossil
	ld hl, wFilteredBagItems
	ld a, [wCurrentMenuItem]
	ld d, 0
	ld e, a
	add hl, de
	ld a, [hl]
	ld [$ffdb], a
	cp DOME_FOSSIL
	jr z, .choseDomeFossil
	cp HELIX_FOSSIL
	jr z, .choseHelixFossil
	ld b, AERODACTYL
	jr .fossilSelected
.choseHelixFossil
	ld b, OMANYTE
	jr .fossilSelected
.choseDomeFossil
	ld b, KABUTO
.fossilSelected
	ld [wFossilItem], a
	ld a, b
	ld [wFossilMon], a
	call LoadFossilItemAndMonName
	ld hl, LabFossil_610ae
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .cancelledGivingFossil
	; FSL-5.42.01: revival is immediate, but keep the original convenience of
	; sending the Pokémon to the current Box when the party is full.
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	jr c, .haveRoom
	ld a, [wNumInBox]
	cp MONS_PER_BOX
	jr nc, .noRoom
.haveRoom
	ld hl, LabFossil_610b3
	call PrintText
	ld a, [wFossilItem]
	ld [hItemToRemoveID], a
	callba RemoveItemByID
	scf
	ret
.noRoom
	ld hl, LabFossilNoRoomText
	call PrintText
	and a
	ret
.cancelledGivingFossil
	ld hl, LabFossil_610bd
	call PrintText
	and a
	ret

LabFossil_610ae:
	TX_FAR _Lab4Text_610ae
	db "@"

LabFossil_610b3:
	TX_FAR _Lab4Text_610b3
	db "@"

LabFossilNoRoomText:
	TX_FAR _BoxIsFullText
	db "@"

LabFossil_610bd:
	TX_FAR _Lab4Text_610bd
	db "@"

PrintFossilsInBag:
; Prints each fossil in the player's bag on a separate line in the menu.
	ld hl, wFilteredBagItems
	xor a
	ld [hItemCounter], a
.loop
	ld a, [hli]
	cp $ff
	ret z
	push hl
	ld [wd11e], a
	call GetItemName
	coord hl, 2, 2
	ld a, [hItemCounter]
	ld bc, SCREEN_WIDTH * 2
	call AddNTimes
	ld de, wcd6d
	call PlaceString
	ld hl, hItemCounter
	inc [hl]
	pop hl
	jr .loop

; loads the names of the fossil item and the resulting mon
LoadFossilItemAndMonName:
	ld a, [wFossilMon]
	ld [wd11e], a
	call GetMonName
	call CopyStringToCF4B
	ld a, [wFossilItem]
	ld [wd11e], a
	call GetItemName
	ret
