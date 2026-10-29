; P3-004 / TEST-230: Gold's 45-landmark read-only Johto Town Map browsing.
; Current destination identity stays (region, stable local ID); these are NOT
; active map slot indexes. This bank also owns copied names for safe far reads.
LoadJohtoBrowseEntry::
; in: E = browse index, out: D = Y, E = X, wBuffer = @-terminated name.
; callab restores A/BC/HL, but DE and WRAM survive.
	ld a, e
	cp JOHTO_TOWNMAP_LANDMARK_COUNT
	jr c, .valid
	xor a
.valid
	add a
	add a
	ld c, a
	ld b, 0
	ld hl, JohtoBrowseEntries
	add hl, bc
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	push de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wBuffer
.copyName
	ld a, [hli]
	ld [de], a
	inc de
	cp "@"
	jr nz, .copyName
	pop de
	ret

; LOC-240: shared Continue/Save info name provider. Both menu pages call this
; through callba, so nothing needs to be added to near-full bank $1C.
; The legacy LoadTownMapEntry can return a name pointer in a different ROM bank
; (e.g. Violet City's name is in bank $35), which becomes invalid when the
; calling bank $1C tries to read the name. Copy Johto's browse name into WRAM
; while this bank is selected instead. Do not change Kanto's existing path.
GetCurrentMapNameForSaveScreen::
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jr nz, .kanto
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .kanto
	; Stable ID -> active-slot profile -> Gold browse landmark; a house
	; inherits its city, and the neutral gate inherits the Route31 anchor.
	callab JohtoPilotGetTownMapLandmark ; E = landmark index
	call LoadJohtoBrowseEntry          ; wBuffer = copied name ending in @
	ld hl, wBuffer
.replaceLineBreak
	ld a, [hl]
	cp "@"
	ret z
	cp "_"
	jr nz, .nextChar
	ld [hl], " "
.nextChar
	inc hl
	jr .replaceLineBreak
.kanto
	callab GetMapNameForSaveScreen
	ret

; Gold original browse order (45 landmarks, independently of map unlocks). All Johto landmarks remain visible,
; independently of visited flags, Fly registrations, and unfinished maps.
JohtoBrowseEntries:
	db 116, 148 ; NewBarkTownName
	dw JohtoNewBarkName
	db 116, 136 ; Route29Name
	dw JohtoRoute29TownMapName
	db 116, 108 ; CherrygroveCityName
	dw JohtoCherrygroveName
	db  96, 108 ; Route30Name
	dw JohtoRoute30TownMapName
	db  76, 104 ; Route31Name
	dw JohtoRoute31TownMapName
	db  76,  92 ; VioletCityName
	dw JohtoVioletName
	db  74,  93 ; SproutTowerName
	dw JohtoBrowseSproutTowerName
	db 108,  92 ; Route32Name
	dw JohtoRoute32TownMapName
	db  92,  84 ; RuinsOfAlphName
	dw JohtoBrowseRuinsOfAlphName
	db 140,  92 ; UnionCaveName
	dw JohtoUnionCaveTownMapName
	db 140,  90 ; Route33Name
	dw JohtoBrowseRoute33Name
	db 140,  76 ; AzaleaTownName
	dw JohtoAzaleaName
	db 138,  78 ; SlowpokeWellName
	dw JohtoBrowseSlowpokeWellName
	db 136,  60 ; IlexForestName
	dw JohtoBrowseIlexForestName
	db 128,  60 ; Route34Name
	dw JohtoBrowseRoute34Name
	db 108,  60 ; GoldenrodCityName
	dw JohtoGoldenrodName
	db 108,  58 ; RadioTowerName
	dw JohtoBrowseRadioTowerName
	db  92,  60 ; Route35Name
	dw JohtoBrowseRoute35Name
	db  76,  60 ; NationalParkName
	dw JohtoBrowseNationalParkName
	db  76,  72 ; Route36Name
	dw JohtoBrowseRoute36Name
	db  68,  76 ; Route37Name
	dw JohtoBrowseRoute37Name
	db  60,  76 ; EcruteakCityName
	dw JohtoEcruteakName
	db  58,  78 ; TinTowerName
	dw JohtoBrowseTinTowerName
	db  58,  74 ; BurnedTowerName
	dw JohtoBrowseBurnedTowerName
	db  60,  60 ; Route38Name
	dw JohtoBrowseRoute38Name
	db  64,  44 ; Route39Name
	dw JohtoBrowseRoute39Name
	db  76,  44 ; OlivineCityName
	dw JohtoOlivineName
	db  78,  46 ; LighthouseName
	dw JohtoBrowseLighthouseName
	db  80,  36 ; Route40Name
	dw JohtoBrowseRoute40Name
	db 108,  36 ; WhirlIslandsName
	dw JohtoBrowseWhirlIslandsName
	db 116,  36 ; Route41Name
	dw JohtoBrowseRoute41Name
	db 116,  28 ; CianwoodCityName
	dw JohtoCianwoodName
	db  60, 100 ; Route42Name
	dw JohtoBrowseRoute42Name
	db  60,  92 ; MtMortarName
	dw JohtoBrowseMtMortarName
	db  60, 116 ; MahoganyTownName
	dw JohtoMahoganyName
	db  52, 116 ; Route43Name
	dw JohtoBrowseRoute43Name
	db  44, 116 ; LakeOfRageName
	dw JohtoBrowseLakeOfRageName
	db  60, 128 ; Route44Name
	dw JohtoBrowseRoute44Name
	db  54, 138 ; IcePathName
	dw JohtoBrowseIcePathName
	db  60, 140 ; BlackthornCityName
	dw JohtoBlackthornName
	db  52, 140 ; DragonsDenName
	dw JohtoBrowseDragonsDenName
	db  80, 140 ; Route45Name
	dw JohtoBrowseRoute45Name
	db  88, 120 ; DarkCaveName
	dw JohtoBrowseDarkCaveName
	db 104, 132 ; Route46Name
	dw JohtoBrowseRoute46Name
	db  84, 156 ; SilverCaveName
	dw JohtoBrowseSilverCaveName
JohtoBrowseEntriesEnd:
ASSERT JohtoBrowseEntriesEnd - JohtoBrowseEntries == 4 * JOHTO_TOWNMAP_LANDMARK_COUNT
JohtoNewBarkName:        db "New Bark_Town@"
JohtoRoute29TownMapName: db "Route 29@"
JohtoCherrygroveName:    db "Cherrygrove_City@"
JohtoRoute30TownMapName: db "Route 30@"
JohtoRoute31TownMapName: db "Route 31@"
JohtoRoute32TownMapName: db "Route 32@"
JohtoUnionCaveTownMapName: db "Union Cave@"
JohtoVioletName:         db "Violet City@"
JohtoAzaleaName:         db "Azalea Town@"
JohtoGoldenrodName:      db "Goldenrod_City@"
JohtoEcruteakName:       db "Ecruteak_City@"
JohtoOlivineName:        db "Olivine_City@"
JohtoCianwoodName:       db "Cianwood_City@"
JohtoMahoganyName:       db "Mahogany_Town@"
JohtoBlackthornName:     db "Blackthorn_City@"

JohtoBrowseSproutTowerName: db "Sprout_Tower@"
JohtoBrowseRuinsOfAlphName: db "Ruins_Of Alph@"
JohtoBrowseRoute32Name: db "Route 32@"
JohtoBrowseRoute33Name: db "Route 33@"
JohtoBrowseSlowpokeWellName: db "Slowpoke_Well@"
JohtoBrowseIlexForestName: db "Ilex_Forest@"
JohtoBrowseRoute34Name: db "Route 34@"
JohtoBrowseRadioTowerName: db "Radio Tower@"
JohtoBrowseRoute35Name: db "Route 35@"
JohtoBrowseNationalParkName: db "National_Park@"
JohtoBrowseRoute36Name: db "Route 36@"
JohtoBrowseRoute37Name: db "Route 37@"
JohtoBrowseTinTowerName: db "Tin Tower@"
JohtoBrowseBurnedTowerName: db "Burned_Tower@"
JohtoBrowseRoute38Name: db "Route 38@"
JohtoBrowseRoute39Name: db "Route 39@"
JohtoBrowseLighthouseName: db "Lighthouse@"
JohtoBrowseRoute40Name: db "Route 40@"
JohtoBrowseWhirlIslandsName: db "Whirl_Islands@"
JohtoBrowseRoute41Name: db "Route 41@"
JohtoBrowseRoute42Name: db "Route 42@"
JohtoBrowseMtMortarName: db "Mt.Mortar@"
JohtoBrowseRoute43Name: db "Route 43@"
JohtoBrowseLakeOfRageName: db "Lake Of_Rage@"
JohtoBrowseRoute44Name: db "Route 44@"
JohtoBrowseIcePathName: db "Ice Path@"
JohtoBrowseDragonsDenName: db "Dragon's_Den@"
JohtoBrowseRoute45Name: db "Route 45@"
JohtoBrowseDarkCaveName: db "Dark Cave@"
JohtoBrowseRoute46Name: db "Route 46@"
JohtoBrowseSilverCaveName: db "Silver Cave@"

