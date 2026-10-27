; P3-004 / TEST-230: first native Johto Fly selector, New Bark only.
; Reuses the reference's Town Map load, icon and Fly handoff behaviour.
; No new town unlock flags, unregistered destinations or legacy map aliases.
LoadJohtoPilotFlyTownMap::
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
	ld a, 1
	ld [wFlyLocationsAxis], a ; use Gold Johto artwork
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
	callba DrawJohtoPilotFlyPlayerMarker
.render
	coord hl, 1, 0
	lb bc, 2, 11
	call ClearScreenArea
	lb de, 116, 148 ; Gold New Bark landmark, Y then X
	callba DrawJohtoPilotFlyCursor
	coord hl, 1, 0
	ld de, .newBarkName
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
	jr nz, .accept
	bit 1, b
	jr nz, .cancel
	ld a, SFX_TINK
	call PlaySound
	jp .render ; only one valid destination; no phantom towns
.accept
	ld a, SFX_HEAL_AILMENT
	call PlaySound
	ld a, JOHTO_PILOT_FLY_SELECTOR
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
.newBarkName
	db "New Bark_Town@"

; Called by the shared Fly special-warp dispatcher only for selector $FD.
; The destination is an authenticated native (region, local ID), never $FD.
JohtoPilotApplyNewBarkFlyWarp::
	; Refuse a synthetic Fly selector outside the two registered native maps.
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, SoftReset
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, SoftReset
	ld e, JOHTO_NEW_BARK_LOCAL_ID
	callab GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jp z, SoftReset
	ld a, JOHTO_RUNTIME_MAP_HANDLE
	ld [wCurMap], a
	ld [wDestinationMap], a
	ld a, MAP_REGION_JOHTO
	ld [wCurRegion], a
	ld a, JOHTO_NEW_BARK_LOCAL_ID
	ld [wCurLocalMapID], a
	ld hl, .newBarkFlyWarp
	ld de, wCurrentTileBlockMapViewPointer
	ld c, 6
.copyWarp
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyWarp
	ret
.newBarkFlyWarp
	; Original Gold New Bark landing X=13, Y=6, a walkable tile.
	FLYWARP_DATA JOHTO_NEW_BARK_WIDTH, 6, 13
