; FIS-5.62.83: the SELECT shortcut fishes only while on land, facing a
; tile accepted by the existing fishing test. All other SELECT presses retain
; the old TryRideBike path (including Surf and Cycling Road restrictions).
TryFishOrRideBike::
	ld a, [wWalkBikeSurfState]
	cp 2 ; R2 will handle surfing independently
	jp z, .rideBike
	predef GetTileAndCoordsInFrontOfPlayer ; refresh, never trust a stale tile
	callba IsNextTileShoreOrWater
	jp c, .rideBike

	; Old saves may contain arbitrary values in the formerly unused bytes.
	ld a, [wLastUsedFishingRodMagic]
	cp $a7
	jr nz, .noRecordedRod
	ld a, [wLastUsedFishingRod]
	cp OLD_ROD
	jr c, .noRecordedRod
	cp SUPER_ROD + 1
	jr nc, .noRecordedRod
	ld b, a
	push bc
	call IsItemInBag ; never conjure up a rod that is no longer held
	pop bc
	jr z, .missingRod

	ld a, b
	ld [wcf91], a
	ld [wPseudoItemID], a ; distinguish SELECT from a deliberate Bag use
	ld [wd11e], a
	call GetItemName
	call CopyStringToCF4B
	call EnableBikeShortcutText
	; An overworld SELECT cast already has the map in place. Reuse the
	; existing R0 redraw-skip handoff, without changing FishingInit.
	ld a, $80
	ld [wRepeatFishingRod], a
	call UseItem ; original rod encounter, text, sound and animation
	; A no-bite SELECT cast offers the same retry as the Bag. A rejected
	; cast may leave the temporary bit-7 redraw marker: never prompt for it.
	ld a, [wRepeatFishingRod]
	bit 7, a
	jr nz, .cancelCast
	and a
	jr z, .closeCast
	callab CheckRepeatFishingRod
	jr .doneCast ; the retry dialog already closed its own text window
.cancelCast
	xor a
	ld [wRepeatFishingRod], a
.closeCast
	call CloseBikeShortcutText
.doneCast
	xor a
	ld [wPseudoItemID], a ; do not leak the shortcut item identity
	scf ; consume this SELECT frame, including any A/START pressed with it
	ret

.noRecordedRod
	call EnableBikeShortcutText
	ld hl, .registerRodText
	jr .showMessage
.missingRod
	call EnableBikeShortcutText
	ld hl, .missingRodText
.showMessage
	call PrintText
	call CloseBikeShortcutText
	scf ; the shoreline message also consumes this SELECT press
	ret

.rideBike
	call TryRideBike
	and a ; clear carry: preserve the existing bike button flow
	ret

.registerRodText
	text "Use a rod from"
	line "the BAG first."
	prompt
.missingRodText
	text "That rod isn't"
	line "in your BAG."
	prompt

; Only the actual Bag's successful rod path calls this. SELECT casts and
; R0 auto-retries must not overwrite the player's last deliberate selection.
RememberBagFishingRod::
	ld a, [wcf91]
	cp OLD_ROD
	ret c
	cp SUPER_ROD + 1
	ret nc
	ld [wLastUsedFishingRod], a
	ld a, $a7
	ld [wLastUsedFishingRodMagic], a
	; Called only after a successful deliberate Bag rod use. Trigger the
	; pending no-bite question now, not on a later Safari walking step.
	callab CheckRepeatFishingRod
	ret

TryRideBike::
	xor a
.setUp
	ld a,BICYCLE
	ld [wcf91],a
	ld [wPseudoItemID],a
	ld [wd11e],a ; store item ID for GetItemName
	call GetItemName
	call CopyStringToCF4B ; copy name to wcf4b
.tryForBike
	ld b,BICYCLE
	call IsItemInBag
	jr nz,.hasBike
	call EnableBikeShortcutText
	ld hl,TextNoBike ; if no bike
	call PrintText
	jr .cleanUp
.hasBike
	farcall IsBikeRidingAllowed
	jr c,.checkSurfing
	call EnableBikeShortcutText
.checkSurfing
	ld a,[wWalkBikeSurfState]
	cp a,2
	jr nz,.checkCyclingRoad ; if not surfing
	call EnableBikeShortcutText
.checkCyclingRoad
	ld a,[wd732] ; cycling road
	bit 5,a
	jr z,.useItem ;if not on cycling road skip text
	call EnableBikeShortcutText
.useItem
	call UseItem
.cleanUp
	call CloseBikeShortcutText
	ret

TextNoBike:
	TX_FAR _NoBicycleText1
	db "@"

EnableBikeShortcutText: ; Gets everything setup to let you display text properly
	call EnableAutoTextBoxDrawing
	ld a, 1 ; not 0
	ld [hSpriteIndexOrTextID], a
	farcall DisplayTextIDInit
	ret

CloseBikeShortcutText: ; Closes the text out properly to prevent glitches
	ld a,[H_LOADEDROMBANK]
	push af
	jp CloseTextDisplay
