; REF-349 ROM0 relief helpers.
;
; These routines were HOME/ROM0 helpers in REF-348. Inputs/outputs are RAM- or
; flag-based; callers use callab/jpba. Keep lookup data in this same bank.
;
; ABI reminder: Bankswitch preserves return flags and DE, but clobbers A/BC/HL.
; Callers that need those registers across a far call must save them explicitly.
SECTION "REF349 ROM0 Relief Helpers", ROMX, BANK[$2A]

; If the player is in an outside map (a town or route), set the Z flag.
; The Johto pilot uses a dedicated nonzero tileset but is still outdoors.
CheckIfInOutsideMap::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jr nz, .legacyTileset
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .legacyTileset
	callab JohtoPilotGetOutdoorFlag ; E = 1 outdoors, 0 indoors
	ld a, e
	cp 1
	ret
.legacyTileset
	ld a, [wCurMapTileset]
	and a ; most Kanto towns/routes have tileset 0 (OVERWORLD)
	ret z
	cp PLATEAU ; Route 23 / Indigo Plateau
	ret

; Gold GATE environments allow cycling; check each active gate's stable
; identity (including vertical north gate), not its shared gate tileset.
; Gold INDOOR gates and Kanto/house rules stay unchanged. Carry = allowed.
IsBikeRidingAllowed::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jr nz, .legacyBike
	ld a, [wCurRegion]
	dec a ; Johto region=1; same Z flag as cp 1, saving one ROM0 byte
	jr nz, .legacyBike
	ld a, [wCurLocalMapID]
	; Gold Dark Cave is CAVE (bike-eligible), despite using the RPP
	; INDOOR animation flag. Restrict this exception to the two active Dark Cave regions.
	cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
	jp z, .darkCaveBike
	cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
	jp z, .darkCaveBike
	cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID
	jr z, .allowed
	cp JOHTO_ROUTE_32_RUINS_OF_ALPH_GATE_LOCAL_ID
	jr z, .allowed
	cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	jr z, .allowed
	cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID
	jr z, .allowed
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jr z, .allowed
    cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
    jr z, .allowed
    cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
    jr z, .allowed
    cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
    jr z, .allowed
    ; REF-367J: Ice Path 1F is Gold CAVE; mounting needs Gold FLOOR permission.
	cp JOHTO_ICE_PATH_1F_LOCAL_ID
	jp z, .icePathBike
	cp JOHTO_ICE_PATH_B1F_LOCAL_ID
	jp z, .icePathB1FBike
    ; ROM0-neutral permit mask: IDs64..67 + 72..75. At this stage
    ; 64..67 are town/Route43 and its two Gold gates; 72/73 outdoors,
    ; 74 is Route29/46 Gold gate, 75 is inactive. Re-review before ID75 activation.
    and $f4
    cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
    jr z, .allowed
.legacyBike
	ld a, [wCurMap]
	cp ROUTE_23
	jr z, .allowed
	cp INDIGO_PLATEAU
	jr z, .allowed
	ld a, [wCurMapTileset]
	ld b, a
	ld hl, BikeRidingTilesets
.loop
	ld a, [hli]
	cp b
	jr z, .allowed
	inc a
	jr nz, .loop
	and a
	ret
.allowed
	scf
	ret
.darkCaveBike
	; This helper is also called when loading the riding sprite after a
	; map transition. Gold keeps an existing bike through CAVE entrances,
	; even on a carpet. Only mounting anew must require Gold FLOOR_TILE.
	ld a, [wWalkBikeSurfState]
	cp 1
	jr z, .allowed
	callab JohtoDarkCaveBikeFloorAllowed349
	ret
.icePathBike
	; Keep an already-mounted bike on cave entry; only new mounting checks FLOOR.
	ld a, [wWalkBikeSurfState]
	cp 1
	jr z, .allowed
	callab JohtoIcePath1FBikeFloorAllowed367J
	ret
.icePathB1FBike
	ld a, [wWalkBikeSurfState]
	cp 1
	jr z, .allowed
	callab JohtoIcePathB1FBikeFloorAllowed367K
	ret
INCLUDE "data/bike_riding_tilesets.asm"

; State-only part of PartyMenuInit, also used by the Battle/Summary fast path.
PartyMenuInitState::
	ld hl, wd730
	set 6, [hl] ; turn off letter printing delay
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld hl, wTopMenuItemY
	inc a
	ld [hli], a ; top menu item Y
	xor a
	ld [hli], a ; top menu item X
	ld a, [wPartyAndBillsPCSavedMenuItem]
	push af
	ld [hli], a ; current menu item ID
	inc hl
	ld a, [wPartyCount]
	and a ; are there more than 0 pokemon in the party?
	jr z, .storeMaxMenuItemID
	dec a
; if party is not empty, the max menu item ID is ([wPartyCount] - 1)
; otherwise, it is 0
.storeMaxMenuItemID
	ld [hli], a ; max menu item ID
	ld a, [wForcePlayerToChooseMon]
	and a
	ld a, A_BUTTON | B_BUTTON
	jr z, .next
	xor a
	ld [wForcePlayerToChooseMon], a
	inc a ; a = A_BUTTON
.next
	; MENU-5.61.17: SELECT belongs only to START -> Pokémon. Other callers may
	; use NORMAL_PARTY_MENU too, so the dedicated START type is the scope guard.
	ld b, a
	ld a, [wIsInBattle]
	and a
	jr nz, .restoreWatchedKeys
	ld a, [wPartyMenuTypeOrMessageID]
	cp START_PARTY_MENU
	jr nz, .restoreWatchedKeys
	ld a, b
	or SELECT
	jr .storeWatchedKeys
.restoreWatchedKeys
	ld a, b
.storeWatchedKeys
	ld [hli], a ; menu watched keys
	pop af
	ld [hl], a ; old menu item ID
	ret

; TM/HM name builder. Its prefix strings stay in this bank with the code.
GetMachineName::
; copies the name of the TM/HM in [wd11e] to wcd6d
	push hl
	push de
	push bc
	ld a,[wd11e]
	push af
	cp TM_01 ; is this a TM? [not HM]
	jr nc,.WriteTM
; if HM, then write "HM" and add 5 to the item ID, so we can reuse the
; TM printing code
	add 5
	ld [wd11e],a
	ld hl,HiddenPrefix ; points to "HM"
	ld bc,2
	jr .WriteMachinePrefix
.WriteTM
	ld hl,TechnicalPrefix ; points to "TM"
	ld bc,2
.WriteMachinePrefix
	ld de,wcd6d
	call CopyData
	ld a,[wd11e]
	sub TM_01 - 1
	ld b, "0"
.FirstDigit
	sub 10
	jr c,.SecondDigit
	inc b
	jr .FirstDigit
.SecondDigit
	add 10
	push af
	ld a,b
	ld [de],a
	inc de
	pop af
	ld b, "0"
	add b
	ld [de],a
	inc de
	ld a,"@"
	ld [de],a
	pop af
	ld [wd11e],a
	pop bc
	pop de
	pop hl
	ret
TechnicalPrefix::
	db "TM"
HiddenPrefix::
	db "HM"

; Trainer encounter music selection and its class lookup tables.
PlayTrainerMusic::
	ld a, [wEngagedTrainerClass]
	cp OPP_SONY1
	ret z
	cp OPP_SONY2
	ret z
	cp OPP_SONY3
	ret z
	ld a, [wGymLeaderNo]
	and a
	ret nz
	xor a
	ld [wAudioFadeOutControl], a
	ld a, $ff
	call PlaySound
	ld a, 0 ; BANK(Music_MeetEvilTrainer)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, [wEngagedTrainerClass]
	ld b, a
	ld hl, EvilTrainerList
.evilTrainerListLoop
	ld a, [hli]
	cp $ff
	jr z, .noEvilTrainer
	cp b
	jr nz, .evilTrainerListLoop
	ld a, MUSIC_MEET_EVIL_TRAINER
	jr .PlaySound
.noEvilTrainer
	ld hl, FemaleTrainerList
.femaleTrainerListLoop
	ld a, [hli]
	cp $ff
	jr z, .maleTrainer
	cp b
	jr nz, .femaleTrainerListLoop
	ld a, MUSIC_MEET_FEMALE_TRAINER
	jr .PlaySound
.maleTrainer
	ld a, MUSIC_MEET_MALE_TRAINER
.PlaySound
	ld [wNewSoundID], a
	jp PlayMusic
INCLUDE "data/trainer_types.asm"

ASSERT BANK(CheckIfInOutsideMap) == $2a
ASSERT BANK(IsBikeRidingAllowed) == $2a
ASSERT BANK(BikeRidingTilesets) == BANK(IsBikeRidingAllowed)
ASSERT BANK(PartyMenuInitState) == $2a
ASSERT BANK(GetMachineName) == $2a
ASSERT BANK(TechnicalPrefix) == BANK(GetMachineName)
ASSERT BANK(HiddenPrefix) == BANK(GetMachineName)
ASSERT BANK(PlayTrainerMusic) == $2a
ASSERT BANK(FemaleTrainerList) == BANK(PlayTrainerMusic)
ASSERT BANK(EvilTrainerList) == BANK(PlayTrainerMusic)

; REF-350: Player sprite state reset is called from two bank-1 paths,
; which have only 4B free in the last MAP. Keep their near calls intact and
; use a compact HOME gateway rather than adding two six-byte far calls there.
ResetPlayerSpriteData_ROMX::
	ld hl, wSpriteStateData1
	call ResetPlayerSpriteData_ClearSpriteData
	ld hl, wSpriteStateData2
	call ResetPlayerSpriteData_ClearSpriteData
	ld a, $1
	ld [wSpriteStateData1], a
	ld [wSpriteStateData2 + $0e], a
	ld hl, wSpriteStateData1 + 4
	ld [hl], $3c     ; set Y screen pos
	inc hl
	inc hl
	ld [hl], $40     ; set X screen pos
	ret

ResetPlayerSpriteData_ClearSpriteData::
	ld bc, $10
	xor a
	jp FillMemory

ASSERT BANK(ResetPlayerSpriteData_ROMX) == $2a
ASSERT BANK(ResetPlayerSpriteData_ClearSpriteData) == BANK(ResetPlayerSpriteData_ROMX)
