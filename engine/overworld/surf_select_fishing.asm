; FIS-5.62.87 R2: helpers outside the packed rod-item Bank $03.
; The existing R0/R1 state and no-bite retry loop are not replaced.

; Carry clear = allowed. On Surf, Bag use has wPseudoItemID = 0;
; SELECT and repeat casts carry the rod ID there. Both routes must work.
CheckFishingEligibleR2::
	ld a, [wWalkBikeSurfState]
	cp 2
	jr nz, .checkLand
	ld a, [wcf91]
	cp OLD_ROD
	jr c, .cannotFish
	cp SUPER_ROD + 1
	jr nc, .cannotFish
	ld b, a
	ld a, [wPseudoItemID]
	and a ; Bag clears the pseudo-item; a direct rod use is legitimate
	jr z, .allowed
	cp b ; SELECT / no-bite repeat must match this rod
	jr nz, .cannotFish
.allowed
	and a
	ret
.checkLand
	; Preserve carry returned by the same preexisting tile validator.
	callba IsNextTileShoreOrWater
	ret
.cannotFish
	scf
	ret

; Surf keeps the same result text and 10+84-frame initial pacing.
; On a bite, bob the Surf sprite and show the exclamation bubble; never
; load land rod pose tiles, reserve rod OAM or change the Surf state.
PresentFishingResultR2::
	ld a, [wWalkBikeSurfState]
	cp 2
	jr z, .surf
	; Legacy land/bicycle animation path, including state restoration.
	ld hl, wWalkBikeSurfState
	ld a, [hl]
	push af
	push hl
	ld [hl], 0
	callba FishingAnim
	pop hl
	pop af
	ld [hl], a
	ret
.surf
	ld c, 94 ; same 10+84 frame wait, without drawing fishing OAM
	call DelayFrames
	ld a, [wRodResponse]
	and a
	ld hl, .noNibble
	jr z, .showText
	cp 2
	ld hl, .nothingHere
	jr z, .showText
	; A bite: shake only the current Surf sprite (including its mount).
	; No rod tiles/OAM reservation: the Surf graphics stay loaded.
	ld b, 10
.shakeSurf
	ld hl, wSpriteStateData1 + 4 ; player's Surf sprite screen Y
	ld a, [hl]
	xor 1
	ld [hl], a
	call Delay3
	dec b
	jr nz, .shakeSurf ; even toggles restore the exact original Y
	; The bubble predef updates OAM and restores normal sprite updates.
	xor a
	ld [wEmotionBubbleSpriteIndex], a ; player / Surf mount
	ld [wWhichEmotionBubble], a ; exclamation
	predef EmotionBubble
	ld hl, .aBite
.showText
	call PrintText
	call LoadFontTilePatterns
	ret
.noNibble
	TX_FAR _NoNibbleText
	db "@"
.nothingHere
	TX_FAR _NothingHereText
	db "@"
.aBite
	TX_FAR _ItsABiteText
	db "@"
