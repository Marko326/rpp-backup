; P4-002: Johto fly locations follow original 11-stop reference order.
; These are physical stable local IDs, NOT old mapconsts. Only visited *and*
; registered destinations can be selected. The loader uses the original
; six-byte RBY FLYWARP_DATA payload for Gold-verified landing positions.
DEF JOHTO_FLY_TOWN_COUNT EQU 11

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
	callba DrawJohtoPilotFlyPlayerMarker
	xor a
	ld [wWhichTownMapLocation], a
	call .findForward
.render
	coord hl, 1, 0
	lb bc, 2, 11
	call ClearScreenArea
	ld a, [wWhichTownMapLocation]
	call .entry
	; HL = row; fields: id,event-byte,event-mask,Y,X,namePtr,warpPtr.
	inc hl
	inc hl
	inc hl
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	push hl
	callba DrawJohtoPilotFlyCursor
	pop hl
	ld a, [hli]
	ld d, [hl]
	ld e, a
	coord hl, 1, 0
	call PlaceString
	ld c, 12
	call DelayFrames
.input
	call DelayFrame
	call JoypadLowSensitivity
	ld a, [hJoy5]
	and A_BUTTON | B_BUTTON | D_UP | D_DOWN
	ld b, a
	ld a, [hJoyPressed]
	and START | SELECT
	or b
	jp z, .input
	bit 0, b
	jr nz, .accept
	ld a, SFX_TINK
	call PlaySound
	bit 1, b
	jp nz, .cancel
	bit 6, b
	jr nz, .next
	bit 7, b
	jr nz, .previous
	; START/SELECT restore the first visited place.
	xor a
	ld [wWhichTownMapLocation], a
	call .findForward
	jp .render
.next
	ld a, [wWhichTownMapLocation]
	inc a
	cp JOHTO_FLY_TOWN_COUNT
	jr c, .nextStore
	xor a
.nextStore
	ld [wWhichTownMapLocation], a
	call .findForward
	jp .render
.previous
	ld a, [wWhichTownMapLocation]
	dec a
	cp $ff
	jr nz, .previousStore
	ld a, JOHTO_FLY_TOWN_COUNT - 1
.previousStore
	ld [wWhichTownMapLocation], a
	call .findBackward
	jp .render
.accept
	call .isUnlocked
	jp z, .input
	ld a, SFX_HEAL_AILMENT
	call PlaySound
	ld a, [wWhichTownMapLocation]
	call .entry
	ld a, [hl] ; accepted physical stable ID (not Fly selector)
	ld [wJohtoFlySelectedLocalID], a
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

.findForward
	ld b, JOHTO_FLY_TOWN_COUNT
.forwardLoop
	push bc
	call .isUnlocked
	pop bc
	ret nz
	ld a, [wWhichTownMapLocation]
	inc a
	cp JOHTO_FLY_TOWN_COUNT
	jr c, .forwardStore
	xor a
.forwardStore
	ld [wWhichTownMapLocation], a
	dec b
	jr nz, .forwardLoop
	ret
.findBackward
	ld b, JOHTO_FLY_TOWN_COUNT
.backwardLoop
	push bc
	call .isUnlocked
	pop bc
	ret nz
	ld a, [wWhichTownMapLocation]
	dec a
	cp $ff
	jr nz, .backwardStore
	ld a, JOHTO_FLY_TOWN_COUNT - 1
.backwardStore
	ld [wWhichTownMapLocation], a
	dec b
	jr nz, .backwardLoop
	ret

.isUnlocked
	ld a, [wWhichTownMapLocation]
	call .entry
	ld e, [hl] ; stable local ID
	push hl
	callab GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	pop hl
	jr z, .locked
	inc hl
	ld a, [hli] ; saved-event byte offset
	ld e, a
	ld d, 0
	ld a, [hl] ; mask
	push af
	ld hl, wEventFlags
	add hl, de
	pop af
	and [hl]
	ret
.locked
	xor a
	ret

.entry
	; 9 bytes per row, index*9 = index*8 + index.
	ld e, a
	ld d, 0
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, de
	ld de, JohtoPilotFlyDestinations
	add hl, de
	ret

; Runs on regular map load, including Continue, before the Kanto-only
; missable object lookup. No effects on Kanto, roads, or disabled Johto slots.
JohtoPilotRecordFlyVisit::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	ld b, a
	ld hl, JohtoPilotFlyDestinations
	ld c, JOHTO_FLY_TOWN_COUNT
.visitLoop
	ld a, [hli]
	cp b
	jr z, .visitFound
	ld de, 8
	add hl, de
	dec c
	jr nz, .visitLoop
	ret
.visitFound
	ld a, [hli]
	ld e, a
	ld d, 0
	ld a, [hl]
	push af
	ld hl, wEventFlags
	add hl, de
	pop af
	or [hl]
	ld [hl], a
	ret

; Fly dispatch invoked after the animation changes scratch memory.
JohtoPilotApplyNewBarkFlyWarp::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, SoftReset
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, SoftReset
	ld a, [wJohtoFlySelectedLocalID]
	ld b, a
	ld hl, JohtoPilotFlyDestinations
	ld c, JOHTO_FLY_TOWN_COUNT
.warpSearch
	ld a, [hli]
	cp b
	jr z, .warpFound
	ld de, 8
	add hl, de
	dec c
	jr nz, .warpSearch
	jp SoftReset
.warpFound
	ld e, b
	push hl
	callab GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jp z, SoftReset
	pop hl
	; Recheck the saved unlock event; disallow corrupted/unvisited Fly.
	ld a, [hli]
	ld e, a
	ld d, 0
	ld a, [hli]
	push hl
	push af
	ld hl, wEventFlags
	add hl, de
	pop af
	and [hl]
	jp z, SoftReset
	pop hl
	; Skip Town Map Y,X and name pointer, reach Fly warp-data pointer.
	ld de, 4
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, JOHTO_RUNTIME_MAP_HANDLE
	ld [wCurMap], a
	ld [wDestinationMap], a
	ld a, MAP_REGION_JOHTO
	ld [wCurRegion], a
	ld a, [wJohtoFlySelectedLocalID]
	ld [wCurLocalMapID], a
	ld de, wCurrentTileBlockMapViewPointer
	ld c, 6
.copyWarp
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyWarp
	ret

; Row: stableID,event-byte-offset,event-bit-mask,MapY,MapX,name pointer,
;       six-byte fly-warp pointer. The full list is from NPC-5.62.243; future
;       towns stay invisible until registered and visited.
JohtoPilotFlyDestinations:
	db JOHTO_NEW_BARK_LOCAL_ID, EVENT_JOHTO_FLY_NEW_BARK / 8, (1 << (EVENT_JOHTO_FLY_NEW_BARK % 8)), 116, 148
	dw .nameNewBark, .warpNewBark
	db JOHTO_CHERRYGROVE_LOCAL_ID, EVENT_JOHTO_FLY_CHERRYGROVE / 8, (1 << (EVENT_JOHTO_FLY_CHERRYGROVE % 8)), 116, 108
	dw .nameCherrygrove, .warpCherrygrove
	db JOHTO_VIOLET_CITY_LOCAL_ID, EVENT_JOHTO_FLY_VIOLET / 8, (1 << (EVENT_JOHTO_FLY_VIOLET % 8)), 76, 92
	dw .nameViolet, .warpViolet
	db JOHTO_AZALEA_TOWN_LOCAL_ID, EVENT_JOHTO_FLY_AZALEA / 8, (1 << (EVENT_JOHTO_FLY_AZALEA % 8)), 140, 76
	dw .nameAzalea, .warpAzalea
	db JOHTO_GOLDENROD_CITY_LOCAL_ID, EVENT_JOHTO_FLY_GOLDENROD / 8, (1 << (EVENT_JOHTO_FLY_GOLDENROD % 8)), 108, 60
	dw .nameGoldenrod, .warpGoldenrod
	db JOHTO_ECRUTEAK_CITY_LOCAL_ID, EVENT_JOHTO_FLY_ECRUTEAK / 8, (1 << (EVENT_JOHTO_FLY_ECRUTEAK % 8)), 60, 76
	dw .nameEcruteak, .warpEcruteak
	db JOHTO_OLIVINE_CITY_LOCAL_ID, EVENT_JOHTO_FLY_OLIVINE / 8, (1 << (EVENT_JOHTO_FLY_OLIVINE % 8)), 76, 44
	dw .nameOlivine, .warpOlivine
	db JOHTO_MAHOGANY_TOWN_LOCAL_ID, EVENT_JOHTO_FLY_MAHOGANY / 8, (1 << (EVENT_JOHTO_FLY_MAHOGANY % 8)), 60, 116
	dw .nameMahogany, .warpMahogany
	db JOHTO_CIANWOOD_CITY_LOCAL_ID, EVENT_JOHTO_FLY_CIANWOOD / 8, (1 << (EVENT_JOHTO_FLY_CIANWOOD % 8)), 116, 28
	dw .nameCianwood, .warpCianwood
	db JOHTO_LAKE_OF_RAGE_LOCAL_ID, EVENT_JOHTO_FLY_LAKE_OF_RAGE / 8, (1 << (EVENT_JOHTO_FLY_LAKE_OF_RAGE % 8)), 44, 116
	dw .nameLake, .warpLake
	db JOHTO_BLACKTHORN_CITY_LOCAL_ID, EVENT_JOHTO_FLY_BLACKTHORN / 8, (1 << (EVENT_JOHTO_FLY_BLACKTHORN % 8)), 60, 140
	dw .nameBlackthorn, .warpBlackthorn
.end:
ASSERT .end - JohtoPilotFlyDestinations == JOHTO_FLY_TOWN_COUNT * 9
.nameNewBark: db "New Bark_Town@"
.warpNewBark:
	FLYWARP_DATA JOHTO_NEW_BARK_WIDTH, 6, 13
.nameCherrygrove: db "Cherrygrove_City@"
.warpCherrygrove:
	FLYWARP_DATA JOHTO_CHERRYGROVE_WIDTH, 4, 29
.nameViolet: db "Violet City@"
.warpViolet:
	FLYWARP_DATA 20, 26, 31
.nameAzalea: db "Azalea Town@"
.warpAzalea:
	FLYWARP_DATA 20, 10, 15
.nameGoldenrod: db "Goldenrod_City@"
.warpGoldenrod:
	FLYWARP_DATA 20, 28, 15
.nameEcruteak: db "Ecruteak_City@"
.warpEcruteak:
	FLYWARP_DATA 20, 28, 23
.nameOlivine: db "Olivine_City@"
.warpOlivine:
	FLYWARP_DATA 20, 22, 13
.nameMahogany: db "Mahogany_Town@"
.warpMahogany:
	FLYWARP_DATA 10, 14, 15
.nameCianwood: db "Cianwood_City@"
.warpCianwood:
	FLYWARP_DATA 15, 44, 23
.nameLake: db "Lake of Rage@"
.warpLake:
	FLYWARP_DATA 20, 29, 21
.nameBlackthorn: db "Blackthorn_City@"
.warpBlackthorn:
	FLYWARP_DATA 20, 30, 21
