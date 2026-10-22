; ILEX-5.62.216: Johto Fly selector covers seven visited towns; Kanto Fly stays
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
	cp 11
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
	ld a, 10
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
	jp z, .inputLoop ; locked destinations cannot be selected
	; Same confirmation SFX as Kanto Fly; only play for unlocked destinations.
	ld a, SFX_HEAL_AILMENT
	call PlaySound
	ld a, [wWhichTownMapLocation]
	call .loadEntry
	push af
	; Never carry the Fly list cursor in shared $cd3d across the flight.
	; Goldenrod and Ecruteak share legacy selector $FE, but their frozen
	; physical IDs are different. Store that choice in dedicated WRAM.
	ld a, [wWhichTownMapLocation]
 cp 10
 jr z,.selectBlackthorn
 cp 9
 jr z,.selectLake
 cp 8
 jr z, .selectCianwood
 cp 7
 jr z, .selectMahogany
 cp 6
 jr z, .selectOlivine
 cp 5
 jr z, .selectEcruteak
 cp 4
 jr z, .selectGoldenrod
 ld a, $ff ; first four destinations use legacy selector IDs
 jr .storeFlyLocal
.selectBlackthorn
 ld a,JOHTO_BLACKTHORN_CITY_LOCAL_ID
 jr .storeFlyLocal
.selectLake
 ld a,JOHTO_LAKE_OF_RAGE_LOCAL_ID
 jr .storeFlyLocal
.selectCianwood
 ld a, JOHTO_CIANWOOD_CITY_LOCAL_ID
 jr .storeFlyLocal
.selectOlivine
 ld a, JOHTO_OLIVINE_CITY_LOCAL_ID
 jr .storeFlyLocal
.selectMahogany
 ld a, JOHTO_MAHOGANY_TOWN_LOCAL_ID
 jr .storeFlyLocal
.selectEcruteak
 ld a, JOHTO_ECRUTEAK_CITY_LOCAL_ID
 jr .storeFlyLocal
.selectGoldenrod
 ld a, JOHTO_GOLDENROD_CITY_LOCAL_ID
.storeFlyLocal
	ld [wJohtoFlySelectedLocalID], a
	pop af
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

; In A: Fly city index 0..8 = New Bark, Cherrygrove, Violet, Azalea, Goldenrod, Ecruteak, Olivine, Mahogany, Cianwood.
; Out: A=legacy map alias; B=y C=x DE=ROM string.
.loadEntry
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
	db  76,  92
	dw .violetName
	db 140,  76
	dw .azaleaName
	db 108, 60
	dw .goldenrodName
	db  60, 76
	dw .ecruteakName
	db 76, 44
 dw .olivineName
 db 60, 116
	dw .mahoganyName
 db 116, 28
 dw .cianwoodName
 db 44, 116
 dw .lakeName
 db 60, 140
 dw .blackthornName
.destinations
	; FLY-5.62.196: $FD selector resolves separately to (JOHTO, local 10).
	db NEW_BARK_TOWN, JOHTO_CHERRYGROVE_CITY, JOHTO_VIOLET_CITY, JOHTO_AZALEA_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR, JOHTO_GOLDENROD_FLY_SELECTOR
.newBarkName
	db "New Bark_Town@"
.cherrygroveName
	db "Cherrygrove_City@"
.violetName
	db "Violet City@"
.azaleaName
	db "Azalea Town@"
.goldenrodName
	db "Goldenrod_City@"
.ecruteakName
	db "Ecruteak_City@"
.olivineName
 db "Olivine_City@"
.mahoganyName
	db "Mahogany_Town@"

.cianwoodName
 db "Cianwood_City@"
.lakeName
 db "Lake of Rage@"
.blackthornName
 db "Blackthorn_City@"
.findForward
	ld b, 11
.forwardLoop
	call .isCurrentUnlocked
	ret nz
	ld a, [wWhichTownMapLocation]
	inc a
	cp 11
	jr c, .forwardStore
	xor a
.forwardStore
	ld [wWhichTownMapLocation], a
	dec b
	jr nz, .forwardLoop
	ret
.findBackward
	ld b, 11
.backwardLoop
	call .isCurrentUnlocked
	ret nz
	ld a, [wWhichTownMapLocation]
	dec a
	cp $ff
	jr nz, .backwardStore
	ld a, 10
.backwardStore
	ld [wWhichTownMapLocation], a
	dec b
	jr nz, .backwardLoop
	ret
.isCurrentUnlocked
	ld a, [wWhichTownMapLocation]
	and a
	jr z, .testNewBark
	cp 1
	jr z, .testCherrygrove
	cp 2
	jr z, .testViolet
	cp 3
	jr z, .testAzalea
	cp 4
	jr z, .testGoldenrod
	cp 5
 jr z, .testEcruteak
 cp 6
 jr z, .testOlivine
 cp 7
 jr z,.testMahogany
 cp 8
 jr z,.testCianwood
 cp 10
 jr z,.testBlackthorn
 ld hl,wEventFlags + EVENT_JOHTO_FLY_LAKE_OF_RAGE / 8
 bit EVENT_JOHTO_FLY_LAKE_OF_RAGE % 8,[hl]
 ret
.testBlackthorn
 ld hl,wEventFlags + EVENT_JOHTO_FLY_BLACKTHORN / 8
 bit EVENT_JOHTO_FLY_BLACKTHORN % 8,[hl]
 ret
.testCianwood
 ld hl,wEventFlags + EVENT_JOHTO_FLY_CIANWOOD / 8
 bit EVENT_JOHTO_FLY_CIANWOOD % 8,[hl]
 ret
.testMahogany
 ld hl, wEventFlags + EVENT_JOHTO_FLY_MAHOGANY / 8
	bit EVENT_JOHTO_FLY_MAHOGANY % 8, [hl]
	ret
.testOlivine
 ld hl, wEventFlags + EVENT_JOHTO_FLY_OLIVINE / 8
 bit EVENT_JOHTO_FLY_OLIVINE % 8, [hl]
 ret
.testEcruteak
	ld hl, wEventFlags + EVENT_JOHTO_FLY_ECRUTEAK / 8
	bit EVENT_JOHTO_FLY_ECRUTEAK % 8, [hl]
	ret
.testGoldenrod
	ld hl, wEventFlags + EVENT_JOHTO_FLY_GOLDENROD / 8
	bit EVENT_JOHTO_FLY_GOLDENROD % 8, [hl]
	ret
.testAzalea
	ld hl, wEventFlags + EVENT_JOHTO_FLY_AZALEA / 8
	bit EVENT_JOHTO_FLY_AZALEA % 8, [hl]
	ret
.testViolet
	ld hl, wEventFlags + EVENT_JOHTO_FLY_VIOLET / 8
	bit EVENT_JOHTO_FLY_VIOLET % 8, [hl]
	ret
.testNewBark
	ld hl, wEventFlags + EVENT_JOHTO_FLY_NEW_BARK / 8
	bit EVENT_JOHTO_FLY_NEW_BARK % 8, [hl]
	ret
.testCherrygrove
	ld hl, wEventFlags + EVENT_JOHTO_FLY_CHERRYGROVE / 8
	bit EVENT_JOHTO_FLY_CHERRYGROVE % 8, [hl]
	ret

