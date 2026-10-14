; FLY-5.62.140: Johto-only Fly selector.  Kanto city/special Fly stays
; untouched; the regular Town Map still has its independent Johto landmark list.
; One-time unlock bits are stored in existing saved wEventFlags unused slots.
; Routes are never Fly destinations; interiors and Teleport are not enabled.
LoadJohtoFlyTownMap::
	; The party icon must be captured before the Town Map uses menu scratch.
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wPartySpecies
	add hl, de
	ld a, [hl]
	ld [wFlySelectedSpecies], a
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	call ClearSprites
	ld a, 1 ; LoadTownMap's Johto artwork selector, not Fly axis
	ld [wFlyLocationsAxis], a
	callba LoadTownMap
	callab LoadPlayerSpriteGraphicsForFlyTownMap
	call LoadFontTilePatterns
	callab LoadFlyTownMapIcon
	ld hl, wUpdateSpritesEnabled
	ld a, [hl]
	push af
	ld [hl], $ff
	push hl
	coord hl, 0, 0
	ld a, $3f
	ld [hl], a
	; Display a fixed player marker at the current Johto map landmark.
	callba DrawJohtoFlyCurrentPlayerMarker
	; Initialize the first visited town, skipping locked entries.
	xor a
	ld [wWhichTownMapLocation], a
	call .findForward
	jp .render

.render
	coord hl, 1, 0
	lb bc, 2, 11
	call ClearScreenArea
	ld a, [wWhichTownMapLocation]
	call .loadEntry
	; B = map y, C = map x; DE = name, A = destination ID.
	push af
	push de
	ld d, b
	ld e, c
	callba DrawJohtoFlyCursor
	pop de
	pop af
	coord hl, 1, 0
	call PlaceString
	ld c, 12
	call DelayFrames
.inputLoop
	call DelayFrame
	call JoypadLowSensitivity
	ld a, [hJoy5]
	and A_BUTTON | B_BUTTON | D_UP | D_DOWN
	ld b, a
	ld a, [hJoyPressed]
	and START | SELECT
	or b
	jr z, .inputLoop
	bit 0, b
	jp nz, .accept
	; FIX-5.62.141: match Kanto Fly's cursor/cancel SFX on input.
	ld a, SFX_TINK
	call PlaySound
	bit 1, b
	jp nz, .cancel
	bit 6, b
	jp nz, .next
	bit 7, b
	jp nz, .previous
	bit 3, b
	jp nz, .start
	bit 2, b
	jp nz, .select
	jr .inputLoop
.next
	ld a, [wWhichTownMapLocation]
	inc a
	cp 2
	jr c, .nextReady
	xor a
.nextReady
	ld [wWhichTownMapLocation], a
	call .findForward
	jp .render
.previous
	ld a, [wWhichTownMapLocation]
	dec a
	cp $ff
	jp nz, .previousReady
	ld a, 1
.previousReady
	ld [wWhichTownMapLocation], a
	call .findBackward
	jp .render
.start
	; On the first Johto Fly release, START returns to New Bark.
.select
	xor a
	ld [wWhichTownMapLocation], a
	call .findForward
	jp .render
.accept
	call .isCurrentUnlocked
	jp z, .inputLoop ; no persisted flypoint for an old save until next town visit
	; Same confirmation SFX as Kanto Fly; only play for unlocked destinations.
	ld a, SFX_HEAL_AILMENT
	call PlaySound
	ld a, [wWhichTownMapLocation]
	call .loadEntry
	ld [wDestinationMap], a
	ld hl, wd732
	set 3, [hl]
	inc hl
	set 7, [hl]
.cancel
	xor a
	ld [wTownMapSpriteBlinkingEnabled], a
	call GBPalWhiteOutWithDelay3
	pop hl
	pop af
	ld [hl], a
	pop af
	ld [hTilesetType], a
	ret

; In A: compact Fly city index 0=New Bark, 1=Cherrygrove.
; Out: A=legacy map alias; B=y C=x DE=ROM string.
.loadEntry
	and 1
	add a
	add a
	ld e, a
	ld d, 0
	ld hl, .entries
	add hl, de
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	; destination IDs are in a separate tiny table to keep 4-byte entry format
	push bc
	ld a, [wWhichTownMapLocation]
	and 1
	ld l, a
	ld h, 0
	ld bc, .destinations
	add hl, bc
	ld a, [hl]
	pop bc
	ret
.entries
	db 116, 148
	dw .newBarkName
	db 116, 108
	dw .cherrygroveName
.destinations
	db NEW_BARK_TOWN, JOHTO_CHERRYGROVE_CITY
.newBarkName
	db "New Bark_Town@"
.cherrygroveName
	db "Cherrygrove_City@"

.findForward
	; Two entries, so checking the current and then the other is bounded.
	call .isCurrentUnlocked
	ret nz
	ld a, [wWhichTownMapLocation]
	xor 1
	ld [wWhichTownMapLocation], a
	ret
.findBackward
	call .findForward
	ret
.isCurrentUnlocked
	ld a, [wWhichTownMapLocation]
	and a
	jr nz, .testCherrygrove
	ld hl, wEventFlags + EVENT_JOHTO_FLY_NEW_BARK / 8
	bit EVENT_JOHTO_FLY_NEW_BARK % 8, [hl]
	ret
.testCherrygrove
	ld hl, wEventFlags + EVENT_JOHTO_FLY_CHERRYGROVE / 8
	bit EVENT_JOHTO_FLY_CHERRYGROVE % 8, [hl]
	ret
