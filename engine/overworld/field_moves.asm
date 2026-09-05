; Copied pretty much verbatim from proof-of-concept code by Yenatch.
; Expanded by Mateo to work more like Gen 2, and to fix a bug with Cut requiring the wrong badge.
; Additional comments added by Mateo to clarify existing yenatch code and new Mateo code.
TryFieldMove:: ; predef
	call GetPredefRegisters

.Main:
	call TrySurf
	ret z
	call TryCut
	ret z
	call TryHeadbutt
	ret

TrySurf:
; Check if you are already surfing, and don't do anything if you are.
	ld a, [wWalkBikeSurfState]
	cp 2
	jr z, .no

; Check to make sure you are facing a surfable tile.
	call IsSurfTile
	jr nc, .no

; Check to make sure you aren't on top of a cliff or something.
	ld hl,TilePairCollisionsWater
	call CheckForTilePairCollisions2
	jr c, .no

; First check whether a party Pokemon knows SURF and the player has the proper badge.
	ld d, SURF
	call HasPartyMove
	jr nz, .cannotSurf

	ld a, [wObtainedKantoBadges]
	bit 4, a ; SOUL_BADGE
	jr z, .cannotSurf

; If SURF can be used, check whether surfing is allowed on the current map.
	call Text2_EnterTheText
	callba IsSurfingAllowed ; in current Pokered, this is callba IsSurfingAllowed
	ld hl,wd728
	bit 1,[hl]
	res 1,[hl]
	jr z,.no2

; If SURF can be used, skip "The water is calm." and ask immediately.
	ld hl, WantToSurfTxt
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .no2

; Call the Surf routine if the player said Yes.
	callba PreferSurfingPikachuForFieldSurf
	call GetPartyMonName2
	ld a, SURFBOARD
	ld [wcf91], a
	ld [wPseudoItemID], a
	call UseItem
	call Text3_DrakesDeception

.yes
	xor a
	ret

.cannotSurf
	; If SURF cannot be used yet, only keep the calm-water message.
	call Text2_EnterTheText
	ld hl, WaterIsCalmTxt
	call PrintText
	call ManualTextScroll
	call Text3_DrakesDeception
	jr .no

.no2
	call Text3_DrakesDeception
.no
	ld a, 1
	and a
	ret

TryCut: ; yenatch's code originally checked for the SOUL_BADGE like SURF does by mistake.
	call IsCutTile
	jr nc, .no

	; First check whether a party Pokemon knows CUT and the player has the proper badge.
	ld d, CUT
	call HasPartyMove
	jr nz, .cannotCut

	ld a, [wObtainedKantoBadges]
	bit 1, a ; CASCADE_BADGE
	jr z, .cannotCut

	; If CUT can be used, skip "This tree can be Cut!" and ask immediately.
	call Text2_EnterTheText
	ld hl,WantToCutTxt
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .no2

	; Calls the CUT routine if they said Yes.
	call GetPartyMonName2
	farcall Cut2
	call Text3_DrakesDeception

.yes
	xor a
	ret

.cannotCut
	; If CUT cannot be used yet, keep the original tree message.
	call Text2_EnterTheText
	ld hl,CanBeCutTxt
	call PrintText
	call ManualTextScroll
	call Text3_DrakesDeception
	jr .no

.no2
	call Text3_DrakesDeception
.no
	ld a, 1
	and a
	ret

HandleBoulderInteraction::
	; This routine is called before DisplayTextID handles the sprite's normal text.
	; Return the result in wWhichTrade because the predef wrapper restores AF:
	; 0 = handled boulder, 1 = not a boulder.
	ld a, [hSpriteIndexOrTextID]
	ld b, a
	ld a, [wNumSprites]
	cp b
	jr c, .notBoulder ; sign IDs are above the sprite count

	call GetSpriteMovementByte2Pointer
	ld a, [hl]
	cp BOULDER_MOVEMENT_BYTE_2
	jr nz, .notBoulder

	; From here on, own the complete text lifecycle just like CUT and SURF.
	call Text2_EnterTheText

	; If Strength is already active, show which Pokemon can move boulders.
	ld hl, wd728
	bit 0, [hl]
	jr z, .checkRequirements
	ld d, STRENGTH
	call HasPartyMove
	jr nz, .cannotUse
	call GetPartyMonName2
	ld hl, CanMoveBouldersOnlyTxt
	call PrintText
	jr .closeHandled

.checkRequirements
	; Match CUT and SURF: check the move first, then the required badge.
	ld d, STRENGTH
	call HasPartyMove
	jr nz, .cannotUse

	ld a, [wObtainedKantoBadges]
	bit 3, a ; RAINBOW_BADGE
	jr z, .cannotUse

	; The player can use Strength, so skip the warning and ask immediately.
	ld hl, WantToUseStrengthTxt
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .closeHandled

	; Enable boulder pushing and show only "<Pokemon> can move boulders."
	call GetPartyMonName2
	ld hl, wd728
	set 0, [hl]
	ld hl, CanMoveBouldersOnlyTxt
	call PrintText

.closeHandled
	; Close the box here. DisplayTextID is skipped for handled boulders,
	; so there is no outer text wait and no blank follow-up box.
	call Text3_DrakesDeception
	xor a
	ld [wWhichTrade], a
	ret

.cannotUse
	; Without the move or Rainbow Badge, keep the original boulder warning.
	ld hl, BoulderNeedsStrengthTxt
	call PrintText
	call ManualTextScroll
	call Text3_DrakesDeception
	xor a
	ld [wWhichTrade], a
	ret

.notBoulder
	ld a, 1
	ld [wWhichTrade], a
	ret

TryHeadbutt:
	call IsHeadbuttTile
	jr nc, .no

	; Match CUT and SURF: if a party Pokemon knows HEADBUTT, ask
	; immediately; otherwise, only show the tree's environmental hint.
	ld d, HEADBUTT
	call HasPartyMove
	jr nz, .cannotHeadbutt

	call Text2_EnterTheText
	ld hl, WantToUseHeadbuttTxt
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .no2

	; Calls the HEADBUTT routine if they said Yes.
	call GetPartyMonName2
	farcall UseHeadbuttOW2
	call Text3_DrakesDeception

.yes
	xor a
	ret

.cannotHeadbutt
	; HEADBUTT has no badge requirement. If nobody knows the move,
	; keep the environmental tree hint instead of silently doing nothing.
	call Text2_EnterTheText
	ld hl, HeadbuttTreeHintTxt
	call PrintText
	call ManualTextScroll
	call Text3_DrakesDeception
	jr .no

.no2
	call Text3_DrakesDeception
.no
	ld a, 1
	and a
	ret

IsHeadbuttTile:
	ld a, [wCurMapTileset]
	and a ; OVERWORLD
	jr z, .overworld
	
	cp FOREST
	jr z, .forest
	
	cp PLATEAU
	jr z, .plateau
	
	jr .no
	
.plateau
	ld a, [wTileInFrontOfPlayer]
	cp $17
	jr z, .yes
	jr .no
	
.forest
	ld a, [wTileInFrontOfPlayer]
	cp $12
	jr z, .yes
	jr .no
	
.overworld
	ld a, [wTileInFrontOfPlayer]
	cp $50
	jr z, .yes
.no
	and a
	ret
.yes
	scf
	ret


IsSurfTile:
	ld a, [wCurMapTileset]
	ld hl, WaterTilesets2
	ld de,1
	call IsInArray
	jr nc, .no

	ld a, [wCurMapTileset]
	cp SHIP_PORT
	ld a, [wTileInFrontOfPlayer]
	jr z, .ok
	cp $48 ; east shore (safari zone)
	jr z, .yes
	cp $32 ; east shore
	jr z, .yes
.ok
	cp $14 ; water
	jr z, .yes
.no
	and a
	ret
.yes
	scf
	ret

; tilesets with water
; originally contained DOJO but that tileset does not exist in Red++
; just make sure this has all tilesets you want to surf in listed
WaterTilesets2: ; Renamed from what Yenatch called it, since that had overlap errors
	db OVERWORLD
	db FOREST
	db SAFARI ; New tileset in Red++
	db GYM
	db SHIP
	db SHIP_PORT
	db CAVERN
	db FACILITY
	db PLATEAU
	db ICE_CAVERN
	db -1

IsCutTile:
	ld a, [wCurMapTileset]
	and a ; OVERWORLD
	jr z, .overworld

	cp GYM
	jr z, .gym

	jr .no

.gym
	ld a, [wTileInFrontOfPlayer]
	cp $50 ; gym cut tree
	jr z, .yes
	jr .no

.overworld ; commented out options would let you run this when talking to tall grass if restored.
	ld a, [wTileInFrontOfPlayer]
	cp $3d ; cut tree
	jr z, .yes
;	cp $52 ; grass
;	jr z, .yes
;	jr .no

.no
	and a
	ret
.yes
	scf
	ret


HasPartyMove::
; Return z (optional: in wWhichTrade) if a PartyMon has move d.
; Updates wWhichPokemon.

	push bc
	push de
	push hl

	ld a, [wPartyCount]
	and a
	jr z, .no
	ld b, a
	ld c, 0
	ld hl, wPartyMons + (wPartyMon1Moves - wPartyMon1)
.loop
	ld e, NUM_MOVES
.check_move
	ld a, [hli]
	cp d
	jr z, .yes
	dec e
	jr nz, .check_move

	ld a, wPartyMon2 - wPartyMon1 - NUM_MOVES
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a

	inc c
	ld a, c
	cp b
	jr c, .loop
	jr .no

.yes
	ld a, c
	ld [wWhichPokemon], a
	xor a ; probably redundant
	ld [wWhichTrade], a
	jr .done
.no
	ld a, 1
	and a
	ld [wWhichTrade], a
.done
	pop hl
	pop de
	pop bc
	ret


CheckRepeatFishingRodOverworld::
; Retry is deliberately short-lived: only a no-bite result leaves this set.
	ld a, [wRepeatFishingRod]
	and a
	ret z
	call CheckRepeatFishingRod
	; Do not leak the YES/NO A/B press into the rest of this overworld frame.
	xor a
	ld [hJoyHeld], a
	ld [hJoyPressed], a
	ld [hJoyReleased], a
	ret

CheckRepeatFishingRod::
; Consume first. A retry that also gets no bite will set it again itself.
	ld a, [wRepeatFishingRod]
	and a
	ret z
	ld b, a
	xor a
	ld [wRepeatFishingRod], a
	push bc
	call Text2_EnterTheText
	ld hl, UseRodAgainText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	pop bc
	; Rebuild the shared item-name buffer exactly like normal Bag item use.
	ld a, b
	ld [wd11e], a
	push bc
	call GetItemName
	call CopyStringToCF4B
	pop bc
	ld a, b
	ld [wcf91], a
	ld [wPseudoItemID], a
	call UseItem
	call Text3_DrakesDeception
	ret
.done
	pop bc
	call Text3_DrakesDeception
	ret

UseRodAgainText:
	text "Use the"
	line "rod again?@@"

Text2_EnterTheText: ; Gets everything setup to let you display text properly
	call EnableAutoTextBoxDrawing
	ld a, 1 ; not 0
	ld [hSpriteIndexOrTextID], a
	farcall DisplayTextIDInit
	ret

Text3_DrakesDeception: ; Closes the text out properly to prevent glitches
	ld a,[H_LOADEDROMBANK]
	push af
	jp CloseTextDisplay
	
CanBeCutTxt:
	text "This tree can be"
	line "Cut!@@"
	
WantToCutTxt:
	text "Want to use"
	line "Cut?@@"

WaterIsCalmTxt:
	text "The water is"
	line "calm!@@"

WantToSurfTxt:
	text "Want to use"
	line "Surf?@@"

BoulderNeedsStrengthTxt:
	TX_FAR _BoulderText
	db "@"

WantToUseStrengthTxt:
	text "Want to use"
	line "Strength?@@"

CanMoveBouldersOnlyTxt:
	TX_FAR _CanMoveBouldersText
	db "@"

HeadbuttTreeHintTxt:
	text "A #mon might be"
	line "hiding in tree!@@"

WantToUseHeadbuttTxt:
	text "Want to use"
	line "Headbutt?@@"
