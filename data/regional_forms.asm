; FORM-5.26.00: table-driven regional-form data.
;
; The engine never names a concrete regional Pokémon. To add another form,
; define its complete header/learnset/evolution/palettes below, add one descriptor row,
; and (only if it should appear in the wild) add one wild encounter row.
;
; Descriptor layout:
;   species, form id, persistent marker,
;   full MonBaseStats-compatible header pointer,
;   level-up learnset pointer,
;   evolution data pointer (stock-compatible entries),
;   normal palette pointer,
;   shiny palette pointer,
;   optional Pokédex metrics bank + pointer
;
; Descriptor/header/learnset/evolution/palette data stay with the generic engine in bank
; $34. Sprite binaries and optional height/weight metric records may live in other
; roomy banks; their descriptor fields carry the required bank/pointer information.


; Optional regional-form Pokédex metrics layout. Zero means "inherit the stock
; Species field", so forms only spend ROM on height/weight values that differ.
; Long description text and category are intentionally shared with the Species.
RF_DEX_HEIGHT         EQU 0 ; feet, inches; 0,0 = inherit
RF_DEX_WEIGHT         EQU 2 ; little-endian tenths of a pound; 0 = inherit
RF_DEX_SIZE           EQU 4

SECTION "Regional Form Data", ROMX, BANK[$34]

RegionalFormDescriptors::
	db RATTATA, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanRattataBaseStats
	dw AlolanRattataLevelMoves
	dw AlolanRattataEvolutions
	dw AlolanRattataPreviewPalette
	dw AlolanRattataShinyPalette
	db BANK(AlolanRattataDexMetrics)
	dw AlolanRattataDexMetrics

	db RATICATE, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanRaticateBaseStats
	dw AlolanRaticateLevelMoves
	dw AlolanRaticateEvolutions
	dw AlolanRaticatePreviewPalette
	dw AlolanRaticateShinyPalette
	db BANK(AlolanRaticateDexMetrics)
	dw AlolanRaticateDexMetrics

	db VULPIX, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanVulpixBaseStats
	dw AlolanVulpixLevelMoves
	dw AlolanVulpixEvolutions
	dw AlolanVulpixPreviewPalette
	dw AlolanVulpixShinyPalette
	db 0
	dw 0 ; height/weight match normal Vulpix

	db NINETALES, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanNinetalesBaseStats
	dw AlolanNinetalesLevelMoves
	dw AlolanNinetalesEvolutions
	dw AlolanNinetalesPreviewPalette
	dw AlolanNinetalesShinyPalette
	db 0
	dw 0 ; height/weight match normal Ninetales

	db RAICHU, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanRaichuBaseStats
	dw AlolanRaichuLevelMoves
	dw AlolanRaichuEvolutions
	dw AlolanRaichuPreviewPalette
	dw AlolanRaichuShinyPalette
	db BANK(AlolanRaichuDexMetrics)
	dw AlolanRaichuDexMetrics

	db SANDSHREW, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanSandshrewBaseStats
	dw AlolanSandshrewLevelMoves
	dw AlolanSandshrewEvolutions
	dw AlolanSandshrewPreviewPalette
	dw AlolanSandshrewShinyPalette
	db BANK(AlolanSandshrewDexMetrics)
	dw AlolanSandshrewDexMetrics

	db SANDSLASH, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanSandslashBaseStats
	dw AlolanSandslashLevelMoves
	dw AlolanSandslashEvolutions
	dw AlolanSandslashPreviewPalette
	dw AlolanSandslashShinyPalette
	db BANK(AlolanSandslashDexMetrics)
	dw AlolanSandslashDexMetrics

	db DIGLETT, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanDiglettBaseStats
	dw AlolanDiglettLevelMoves
	dw AlolanDiglettEvolutions
	dw AlolanDiglettPreviewPalette
	dw AlolanDiglettShinyPalette
	db BANK(AlolanDiglettDexMetrics)
	dw AlolanDiglettDexMetrics

	db DUGTRIO, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanDugtrioBaseStats
	dw AlolanDugtrioLevelMoves
	dw AlolanDugtrioEvolutions
	dw AlolanDugtrioPreviewPalette
	dw AlolanDugtrioShinyPalette
	db BANK(AlolanDugtrioDexMetrics)
	dw AlolanDugtrioDexMetrics

	db GEODUDE, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanGeodudeBaseStats
	dw AlolanGeodudeLevelMoves
	dw AlolanGeodudeEvolutions
	dw AlolanGeodudePreviewPalette
	dw AlolanGeodudeShinyPalette
	db BANK(AlolanGeodudeDexMetrics)
	dw AlolanGeodudeDexMetrics

	db GRAVELER, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanGravelerBaseStats
	dw AlolanGravelerLevelMoves
	dw AlolanGravelerEvolutions
	dw AlolanGravelerPreviewPalette
	dw AlolanGravelerShinyPalette
	db BANK(AlolanGravelerDexMetrics)
	dw AlolanGravelerDexMetrics

	db GOLEM, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanGolemBaseStats
	dw AlolanGolemLevelMoves
	dw AlolanGolemEvolutions
	dw AlolanGolemPreviewPalette
	dw AlolanGolemShinyPalette
	db BANK(AlolanGolemDexMetrics)
	dw AlolanGolemDexMetrics

	db GRIMER, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanGrimerBaseStats
	dw AlolanGrimerLevelMoves
	dw AlolanGrimerEvolutions
	dw AlolanGrimerPreviewPalette
	dw AlolanGrimerShinyPalette
	db BANK(AlolanGrimerDexMetrics)
	dw AlolanGrimerDexMetrics

	db MUK, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanMukBaseStats
	dw AlolanMukLevelMoves
	dw AlolanMukEvolutions
	dw AlolanMukPreviewPalette
	dw AlolanMukShinyPalette
	db BANK(AlolanMukDexMetrics)
	dw AlolanMukDexMetrics

	db MAROWAK, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanMarowakBaseStats
	dw AlolanMarowakLevelMoves
	dw AlolanMarowakEvolutions
	dw AlolanMarowakPreviewPalette
	dw AlolanMarowakShinyPalette
	db BANK(AlolanMarowakDexMetrics)
	dw AlolanMarowakDexMetrics
	db 0 ; terminator: species 0 is never a valid descriptor

; Wild-only producer table: map, species, form.
; Stored/trainer/link Pokémon resolve their form from the persistent marker.
RegionalFormWildEncounters::
	db ROUTE_1, RATTATA, FORM_ALOLA
	; FORM-5.22.00: Route 7 Vulpix uses the Alolan descriptor. Other maps
	; continue to produce normal Vulpix, so both forms remain obtainable.
	db ROUTE_7, VULPIX, FORM_ALOLA
	db $ff ; terminator: no real map uses this entry here

; FORM-5.26.00 bulk-imported forms intentionally do not add wild-map rows here.
; Their descriptors are live for Pokédex/data testing, while encounter placement remains
; a separate balance decision instead of being silently changed by a data-only batch.

; -----------------------------------------------------------------------------
; Alolan Rattata
; -----------------------------------------------------------------------------
; Complete MonBaseStats-compatible record. Unlike the old partial override,
; every header field now has an independent slot for the form: stats, types,
; catch/base EXP, sprite size/pointers, tutor flags, growth, TM/HM flags and
; picture bank. Values that currently match normal Rattata are copied on purpose
; so future edits do not need engine changes.
AlolanRattataBaseStats::
	db DEX_RATTATA
	db 30 ; base hp
	db 56 ; base attack
	db 35 ; base defense
	db 72 ; base speed
	db 25 ; base special
	db NORMAL ; type 1
	db DARK ; type 2
	db 255 ; catch rate
	db 57 ; base exp yield
	db $55 ; sprite dimensions
	dw AlolanRattataPicFront
	dw AlolanRattataPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility (currently mirrors normal Rattata)
	tmlearn 3,5,6,8
	tmlearn 9,10,11,12,13,14,16
	tmlearn 17,18,19,20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 44
	tmlearn 51,54
	db BANK(AlolanRattataPicFront)

; Independent level-up learnset. FORM-5.20.06 temporarily changed Lv.4 to BITE
; to prove form separation; FORM-5.21.00 restores the normal move progression
; while keeping this as a completely separate table.
AlolanRattataLevelMoves::
	db 1,TACKLE
	db 1,TAIL_WHIP
	db 4,QUICK_ATTACK
	db 7,FOCUS_ENERGY
	db 10,BITE
	db 13,IRON_TAIL
	db 16,HYPER_FANG
	db 19,SUCKER_PUNCH
	db 22,CRUNCH
	db 25,FEINT_ATTACK
	db 28,SUPER_FANG
	db 31,DOUBLE_EDGE
	db 34,COUNTER
	db 0

AlolanRattataEvolutions::
	; No time-of-day system: use the canonical level threshold without night.
	db EV_LEVEL,20,RATICATE
	db 0

AlolanRattataPreviewPalette::
	RGB 15, 16, 19
	RGB 06, 06, 05
AlolanRattataShinyPalette::
	RGB 21, 17, 15
	RGB 19, 09, 11


; -----------------------------------------------------------------------------
; Alolan Raticate
; -----------------------------------------------------------------------------
; FORM-5.25.00: official six-stat Alolan Raticate is 75/71/70/40/80/77
; (BST 413), while normal Raticate is 55/81/60/50/70/97 (also 413). This
; Gen-I-style engine has one Special stat, so there is no official one-to-one
; value to copy. Preserve the project's normal five-stat total instead:
;   normal total = 55 + 81 + 60 + 97 + 50 = 343
;   Alola Special = 343 - (75 + 71 + 70 + 77) = 50
; This deterministic residual rule keeps regional redistribution total-neutral.
AlolanRaticateBaseStats::
	db DEX_RATICATE
	db 75
	db 71
	db 70
	db 77
	db 50 ; five-stat residual; preserves normal Raticate total 343
	db NORMAL
	db DARK
	db 90
	db 116
	db $77
	dw AlolanRaticatePicFront
	dw AlolanRaticatePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0
	tmlearn 3,5,6,8
	tmlearn 9,10,11,12,13,14,15,16
	tmlearn 17,18,19,20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 44
	tmlearn 51,54
	db BANK(AlolanRaticatePicFront)

; Independent table; values intentionally mirror the project's current Raticate
; progression instead of importing the old project's custom move balance.
AlolanRaticateLevelMoves::
	db 1,TACKLE
	db 1,TAIL_WHIP
	db 4,QUICK_ATTACK
	db 7,FOCUS_ENERGY
	db 10,BITE
	db 13,IRON_TAIL
	db 16,HYPER_FANG
	db 19,SUCKER_PUNCH
	db 20,LEER
	db 24,CRUNCH
	db 29,FEINT_ATTACK
	db 34,SUPER_FANG
	db 39,DOUBLE_EDGE
	db 44,COUNTER
	db 0
AlolanRaticateEvolutions::
	db 0
AlolanRaticatePreviewPalette::
	RGB 22, 18, 14
	RGB 07, 07, 06
AlolanRaticateShinyPalette::
	RGB 12, 09, 07
	RGB 18, 06, 11


; -----------------------------------------------------------------------------
; Alolan Vulpix
; -----------------------------------------------------------------------------
; Sprite/palette/learnset/evolution references come from the user-supplied
; "Furret...pic" package. That source represents Alolan Vulpix as ICE/FAIRY
; and uses SUN_STONE at level 30 because this branch has no ICE_STONE item constant.
AlolanVulpixBaseStats::
	db DEX_VULPIX
	db 38
	db 41
	db 40
	db 65
	db 65
	db ICE
	db FAIRY
	db 190
	db 63
	db $66
	dw AlolanVulpixPicFront
	dw AlolanVulpixPicBack
	m_tutor 8
	m_tutor 13
	m_tutor 0
	m_tutor 0
	db 0
	tmlearn 6,8
	tmlearn 9,10,13,14
	tmlearn 0
	tmlearn 28,29,30,31,32
	tmlearn 33,34,39
	tmlearn 43,44,46
	tmlearn 49,50,55
	db BANK(AlolanVulpixPicFront)

AlolanVulpixLevelMoves::
	db 1,TACKLE
	db 4,LEER
	db 7,QUICK_ATTACK
	db 11,ICE_SHARD
	db 14,NIGHT_SHADE
	db 17,DRAININGKISS
	db 20,ICE_FANG
	db 23,HEX
	db 26,AURORA_BEAM
	db 28,ZEN_HEADBUTT
	db 34,HYPNOSIS
	db 37,EXTRASENSORY
	db 40,SHADOW_BALL
	db 46,ICE_BEAM
	db 50,DAZZLINGLEAM
	db 0

AlolanVulpixEvolutions::
	db EV_ITEM,SUN_STONE,30,NINETALES
	db 0

AlolanVulpixPreviewPalette::
	RGB 19, 23, 28
	RGB 09, 14, 18
AlolanVulpixShinyPalette::
	RGB 27, 20, 27
	RGB 21, 11, 12


; -----------------------------------------------------------------------------
; Alolan Ninetales
; -----------------------------------------------------------------------------
AlolanNinetalesBaseStats::
	db DEX_NINETALES
	; Alolan redistribution established by the regional-stat plan: same BST,
	; Attack 67 / Speed 109 instead of normal Ninetales 76 / 100.
	db 73
	db 67
	db 75
	db 109
	db 100
	db ICE
	db FAIRY
	db 75
	db 178
	db $77
	dw AlolanNinetalesPicFront
	dw AlolanNinetalesPicBack
	m_tutor 8
	m_tutor 13
	m_tutor 0
	m_tutor 0
	db 0
	tmlearn 6,8
	tmlearn 9,10,13,14,15
	tmlearn 0
	tmlearn 27,28,29,30,31,32
	tmlearn 33,34,39
	tmlearn 43,44,46
	tmlearn 49,50,55
	db BANK(AlolanNinetalesPicFront)

AlolanNinetalesLevelMoves::
	db 1,CONFUSE_RAY
	db 11,ICE_SHARD
	db 17,DRAININGKISS
	db 20,ICE_FANG
	db 23,HEX
	db 26,AURORA_BEAM
	db 28,ZEN_HEADBUTT
	db 34,HYPNOSIS
	db 37,EXTRASENSORY
	db 40,SHADOW_BALL
	db 46,ICE_BEAM
	db 55,DAZZLINGLEAM
	db 60,PSYCHIC_M
	db 65,BLIZZARD
	; The supplied source has FLEUR_CANNON at Lv70, but this branch has no
	; FLEUR_CANNON move constant. Do not silently substitute another move.
	db 75,AMNESIA
	db 0

AlolanNinetalesEvolutions::
	db 0

AlolanNinetalesPreviewPalette::
	RGB 19, 23, 27
	RGB 09, 14, 18
AlolanNinetalesShinyPalette::
	RGB 24, 19, 31
	RGB 14, 07, 21



; -----------------------------------------------------------------------------
; Alolan Raichu
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanRaichuBaseStats::
	db DEX_RAICHU
	db 60 ; base hp
	db 85 ; base attack
	db 50 ; base defense
	db 110 ; base speed
	db 100 ; base special
	db ELECTRIC
	db PSYCHIC
	db 75 ; catch rate
	db 122 ; base exp yield
	db $77 ; sprite dimensions
	dw AlolanRaichuPicFront
	dw AlolanRaichuPicBack
	; move tutor compatibility flags
	m_tutor 1,2,3,4,5,6,7,8
	m_tutor 9,10,11,12,13,14
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 1,2,3,4,5,6,7,8
	tmlearn 9,10,11,12,13,14,15,16
	tmlearn 17,18,19,20,21,22,23,24
	tmlearn 25,26,28,29,30,31,32
	tmlearn 33,34,35,36,37,38,39,40
	tmlearn 41,42,43,44,45,46,47,48
	tmlearn 49,50,51,52,53,54,55
	db BANK(AlolanRaichuPicFront)

AlolanRaichuLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 60,PSYCHO_BOOST
	db 1,THUNDERSHOCK
	db 1,LEER
	db 5,GROWL
	db 10,QUICK_ATTACK
	db 13,DRAININGKISS
	db 21,DOUBLE_TEAM
	db 23,NUZZLE
	db 26,SIGNAL_BEAM
	db 30,PSYBEAM
	db 35,SURF
	db 40,THUNDERBOLT
	db 45,PSYCHIC_M
	db 52,THUNDER
	db 0

AlolanRaichuEvolutions::
	db 0

AlolanRaichuPreviewPalette::
	RGB 31, 26, 07
	RGB 30, 15, 04
AlolanRaichuShinyPalette::
	RGB 31, 24, 09
	RGB 20, 13, 08


; -----------------------------------------------------------------------------
; Alolan Sandshrew
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanSandshrewBaseStats::
	db DEX_SANDSHREW
	db 50 ; base hp
	db 75 ; base attack
	db 90 ; base defense
	db 40 ; base speed
	db 25 ; base special
	db ICE
	db STEEL
	db 255 ; catch rate
	db 93 ; base exp yield
	db $66 ; sprite dimensions
	dw AlolanSandshrewPicFront
	dw AlolanSandshrewPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 1,3,5,6,8
	tmlearn 9,10,16
	tmlearn 17,18,19,20
	tmlearn 26,27,28,31,32
	tmlearn 34,35,36,39,40
	tmlearn 44,48
	tmlearn 50,51,54
	db BANK(AlolanSandshrewPicFront)

AlolanSandshrewLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 40,IRON_HEAD
	; db 50,ICICLE_CRASH
	db 1,SCRATCH
	db 1,HARDEN
	db 7,POISON_STING
	db 9,MUD_SLAP
	db 12,HONE_CLAWS
	db 15,ICE_SHARD
	db 17,METAL_CLAW
	db 20,FURY_SWIPES
	db 25,PIN_MISSILE
	db 29,DIG
	db 35,SLASH
	db 45,X_SCISSOR
	db 55,EARTHQUAKE
	db 0

AlolanSandshrewEvolutions::
	db EV_LEVEL,22,SANDSLASH
	db 0

AlolanSandshrewPreviewPalette::
	RGB 20, 25, 28
	RGB 12, 15, 22
AlolanSandshrewShinyPalette::
	RGB 20, 28, 21
	RGB 12, 22, 16


; -----------------------------------------------------------------------------
; Alolan Sandslash
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanSandslashBaseStats::
	db DEX_SANDSLASH
	db 75 ; base hp
	db 100 ; base attack
	db 120 ; base defense
	db 65 ; base speed
	db 45 ; base special
	db ICE
	db STEEL
	db 90 ; catch rate
	db 163 ; base exp yield
	db $77 ; sprite dimensions
	dw AlolanSandslashPicFront
	dw AlolanSandslashPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 1,3,5,6,8
	tmlearn 9,10,15,16
	tmlearn 17,18,19,20
	tmlearn 26,27,28,31,32
	tmlearn 34,35,36,39,40
	tmlearn 44,48
	tmlearn 50,51,54
	db BANK(AlolanSandslashPicFront)

AlolanSandslashLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 40,IRON_HEAD
	; db 50,ICICLE_CRASH
	; db 60,GLACIALLANCE
	db 1,HONE_CLAWS
	db 1,ICE_SHARD
	db 1,METAL_CLAW
	db 1,FURY_SWIPES
	db 25,PIN_MISSILE
	db 29,DIG
	db 35,SLASH
	db 45,X_SCISSOR
	db 55,EARTHQUAKE
	db 66,GUILLOTINE
	db 0

AlolanSandslashEvolutions::
	db 0

AlolanSandslashPreviewPalette::
	RGB 22, 27, 28
	RGB 12, 21, 24
AlolanSandslashShinyPalette::
	RGB 23, 28, 22
	RGB 13, 24, 12


; -----------------------------------------------------------------------------
; Alolan Diglett
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanDiglettBaseStats::
	db DEX_DIGLETT
	db 10 ; base hp
	db 55 ; base attack
	db 30 ; base defense
	db 90 ; base speed
	db 45 ; base special
	db GROUND
	db STEEL
	db 255 ; catch rate
	db 81 ; base exp yield
	db $55 ; sprite dimensions
	dw AlolanDiglettPicFront
	dw AlolanDiglettPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 6,8
	tmlearn 9,10
	tmlearn 20
	tmlearn 26,27,28,31,32
	tmlearn 34,35,36
	tmlearn 44,48
	tmlearn 50,51
	db BANK(AlolanDiglettPicFront)

AlolanDiglettLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 23,IRON_HEAD
	db 1,ROCK_POLISH
	db 1,SCRATCH
	db 1,SAND_ATTACK
	db 4,GROWL
	db 10,DIG
	db 14,METAL_CLAW
	db 18,ROCK_TOMB
	db 26,SLASH
	db 30,EARTHQUAKE
	db 35,NIGHT_SLASH
	db 0

AlolanDiglettEvolutions::
	db EV_LEVEL,26,DUGTRIO
	db 0

AlolanDiglettPreviewPalette::
	RGB 25, 16, 08
	RGB 09, 11, 11
AlolanDiglettShinyPalette::
	RGB 20, 07, 05
	RGB 09, 11, 11


; -----------------------------------------------------------------------------
; Alolan Dugtrio
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanDugtrioBaseStats::
	db DEX_DUGTRIO
	db 35 ; base hp
	db 100 ; base attack
	db 60 ; base defense
	db 110 ; base speed
	db 70 ; base special
	db GROUND
	db STEEL
	db 50 ; catch rate
	db 153 ; base exp yield
	db $77 ; sprite dimensions
	dw AlolanDugtrioPicFront
	dw AlolanDugtrioPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 6,8
	tmlearn 9,10,15
	tmlearn 20
	tmlearn 26,27,28,31,32
	tmlearn 34,35,36
	tmlearn 44,48
	tmlearn 50,51
	db BANK(AlolanDugtrioPicFront)

AlolanDugtrioLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 28,IRON_HEAD
	; db 49,EARTH_CRUSH
	; db 60,TITAN_IMPACT
	db 1,ROCK_POLISH
	db 1,NIGHT_SLASH
	db 10,DIG
	db 14,METAL_CLAW
	db 18,ROCK_TOMB
	db 23,DIG
	db 31,SLASH
	db 34,EARTHQUAKE
	db 38,ROCK_SLIDE
	db 42,NIGHT_SLASH
	db 45,METEOR_MASH
	db 53,SKULL_BASH
	db 0

AlolanDugtrioEvolutions::
	db 0

AlolanDugtrioPreviewPalette::
	RGB 25, 16, 08
	RGB 09, 11, 11
AlolanDugtrioShinyPalette::
	RGB 20, 07, 05
	RGB 09, 11, 11


; -----------------------------------------------------------------------------
; Alolan Geodude
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanGeodudeBaseStats::
	db DEX_GEODUDE
	db 40 ; base hp
	db 80 ; base attack
	db 100 ; base defense
	db 20 ; base speed
	db 30 ; base special
	db ROCK
	db ELECTRIC
	db 255 ; catch rate
	db 86 ; base exp yield
	db $55 ; sprite dimensions
	dw AlolanGeodudePicFront
	dw AlolanGeodudePicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 9,10
	m_tutor 0
	m_tutor 0
	db 3 ; growth rate
	; TM/HM compatibility
	tmlearn 1,6,8
	tmlearn 9,10
	tmlearn 17,18,19
	tmlearn 26,28,31,32
	tmlearn 34,35,36,37,38
	tmlearn 44,47,48
	tmlearn 50,54
	db BANK(AlolanGeodudePicFront)

AlolanGeodudeLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 26,ACCELEROCK
	; db 43,SPRCELL_SLAM
	db 1,TACKLE
	db 1,HARDEN
	db 7,MUD_SLAP
	db 10,ROCK_POLISH
	db 13,ROCK_THROW
	db 16,NUZZLE
	db 19,ANCIENTPOWER
	db 23,THUNDERPUNCH
	db 29,MUD_BOMB
	db 32,ROCK_BLAST
	db 35,DIG
	db 39,EARTHQUAKE
	db 47,ROCK_SLIDE
	db 51,EXPLOSION
	db 0

AlolanGeodudeEvolutions::
	db EV_LEVEL,25,GRAVELER
	db 0

AlolanGeodudePreviewPalette::
	RGB 18, 20, 22
	RGB 10, 12, 14
AlolanGeodudeShinyPalette::
	RGB 24, 17, 15
	RGB 15, 13, 07


; -----------------------------------------------------------------------------
; Alolan Graveler
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanGravelerBaseStats::
	db DEX_GRAVELER
	db 55 ; base hp
	db 95 ; base attack
	db 115 ; base defense
	db 35 ; base speed
	db 45 ; base special
	db ROCK
	db ELECTRIC
	db 120 ; catch rate
	db 134 ; base exp yield
	db $77 ; sprite dimensions
	dw AlolanGravelerPicFront
	dw AlolanGravelerPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 9,10
	m_tutor 0
	m_tutor 0
	db 3 ; growth rate
	; TM/HM compatibility
	tmlearn 1,6,8
	tmlearn 9,10
	tmlearn 17,18,19
	tmlearn 26,28,31,32
	tmlearn 34,35,36,37,38
	tmlearn 44,47,48
	tmlearn 50,54
	db BANK(AlolanGravelerPicFront)

AlolanGravelerLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 26,ACCELEROCK
	; db 49,SPRCELL_SLAM
	db 1,TACKLE
	db 1,HARDEN
	db 7,MUD_SLAP
	db 10,ROCK_POLISH
	db 13,ROCK_THROW
	db 16,NUZZLE
	db 20,ANCIENTPOWER
	db 23,THUNDERPUNCH
	db 29,MUD_BOMB
	db 34,ROCK_BLAST
	db 40,DIG
	db 45,EARTHQUAKE
	db 53,ROCK_SLIDE
	db 57,EXPLOSION
	db 0

AlolanGravelerEvolutions::
	db EV_TRADE,1,GOLEM
	db EV_LEVEL,40,GOLEM
	db 0

AlolanGravelerPreviewPalette::
	RGB 20, 21, 21
	RGB 08, 10, 11
AlolanGravelerShinyPalette::
	RGB 23, 14, 12
	RGB 16, 11, 07


; -----------------------------------------------------------------------------
; Alolan Golem
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanGolemBaseStats::
	db DEX_GOLEM
	db 80 ; base hp
	db 120 ; base attack
	db 130 ; base defense
	db 45 ; base speed
	db 55 ; base special
	db ROCK
	db ELECTRIC
	db 45 ; catch rate
	db 177 ; base exp yield
	db $77 ; sprite dimensions
	dw AlolanGolemPicFront
	dw AlolanGolemPicBack
	; move tutor compatibility flags
	m_tutor 0
	m_tutor 9,10
	m_tutor 0
	m_tutor 0
	db 3 ; growth rate
	; TM/HM compatibility
	tmlearn 1,6,8
	tmlearn 9,10,15
	tmlearn 17,18,19
	tmlearn 26,28,31,32
	tmlearn 34,35,36,37,38
	tmlearn 44,47,48
	tmlearn 50,54
	db BANK(AlolanGolemPicFront)

AlolanGolemLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 1,FOCUS_BLAST
	; db 26,ACCELEROCK
	; db 44,SPRCELL_SLAM
	; db 65,ZIPPY_ZAP
	; db 70,EARTH_CRUSH
	db 1,TACKLE
	db 1,HARDEN
	db 7,MUD_SLAP
	db 10,ROCK_POLISH
	db 13,ROCK_THROW
	db 16,NUZZLE
	db 20,ANCIENTPOWER
	db 23,THUNDERPUNCH
	db 30,ROCK_BLAST
	db 36,DIG
	db 49,ROCK_SLIDE
	db 55,EARTHQUAKE
	db 61,SKULL_BASH
	db 75,EXPLOSION
	db 0

AlolanGolemEvolutions::
	db 0

AlolanGolemPreviewPalette::
	RGB 19, 20, 18
	RGB 08, 10, 11
AlolanGolemShinyPalette::
	RGB 25, 15, 12
	RGB 19, 07, 03


; -----------------------------------------------------------------------------
; Alolan Grimer
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanGrimerBaseStats::
	db DEX_GRIMER
	db 80 ; base hp
	db 80 ; base attack
	db 50 ; base defense
	db 25 ; base speed
	db 40 ; base special
	db POISON
	db DARK
	db 190 ; catch rate
	db 90 ; base exp yield
	db $55 ; sprite dimensions
	dw AlolanGrimerPicFront
	dw AlolanGrimerPicBack
	; move tutor compatibility flags
	m_tutor 5,8
	m_tutor 9,10,11,12,13,14
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 1,6,8
	tmlearn 9,10,12,16
	tmlearn 21,24
	tmlearn 25,28,31,32
	tmlearn 34,35,36,37,38
	tmlearn 44,47,48
	tmlearn 50,54
	db BANK(AlolanGrimerPicFront)

AlolanGrimerLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 7,PURSUIT
	db 1,POUND
	db 1,POISON_GAS
	db 4,HARDEN
	db 10,BITE
	db 13,SLUDGE
	db 17,DISABLE
	db 21,MUD_BOMB
	db 24,TOXIC
	db 27,ICE_PUNCH
	db 30,SLUDGE_WAVE
	db 34,SCREECH
	db 36,HAZE
	db 38,GUNK_SHOT
	db 42,ACID_ARMOR
	db 0

AlolanGrimerEvolutions::
	db EV_LEVEL,38,MUK
	db 0

AlolanGrimerPreviewPalette::
	RGB 27, 24, 03
	RGB 14, 19, 14
AlolanGrimerShinyPalette::
	RGB 29, 26, 03
	RGB 29, 02, 20


; -----------------------------------------------------------------------------
; Alolan Muk
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanMukBaseStats::
	db DEX_MUK
	db 105 ; base hp
	db 105 ; base attack
	db 75 ; base defense
	db 50 ; base speed
	db 65 ; base special
	db POISON
	db DARK
	db 75 ; catch rate
	db 157 ; base exp yield
	db $77 ; sprite dimensions
	dw AlolanMukPicFront
	dw AlolanMukPicBack
	; move tutor compatibility flags
	m_tutor 5,8
	m_tutor 9,10,11,12,13,14
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 1,6,8
	tmlearn 9,10,12,15,16
	tmlearn 21,24
	tmlearn 25,28,31,32
	tmlearn 34,35,36,37,38
	tmlearn 44,47,48
	tmlearn 50,54
	db BANK(AlolanMukPicFront)

AlolanMukLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 7,PURSUIT
	; db 58,NIGHT_BIND
	db 1,POISON_GAS
	db 4,HARDEN
	db 12,BITE
	db 15,SLUDGE
	db 18,DISABLE
	db 21,MUD_BOMB
	db 27,ICE_PUNCH
	db 30,SLUDGE_WAVE
	db 33,SCREECH
	db 36,CRUNCH
	db 39,HAZE
	db 43,EARTHQUAKE
	db 47,GUNK_SHOT
	db 50,ACID_ARMOR
	db 0

AlolanMukEvolutions::
	db 0

AlolanMukPreviewPalette::
	RGB 31, 12, 17
	RGB 06, 17, 07
AlolanMukShinyPalette::
	RGB 29, 07, 13
	RGB 12, 04, 12


; -----------------------------------------------------------------------------
; Alolan Marowak
; -----------------------------------------------------------------------------
; FORM-5.26.00 bulk import: sprite/header compatibility/palettes/learnset are
; sourced from the user-provided Furret package. Stats/types follow the
; verified regional-form reference and the project's five-stat residual rule.
AlolanMarowakBaseStats::
	db DEX_MAROWAK
	db 60 ; base hp
	db 80 ; base attack
	db 110 ; base defense
	db 45 ; base speed
	db 50 ; base special
	db FIRE
	db GHOST
	db 75 ; catch rate
	db 124 ; base exp yield
	db $66 ; sprite dimensions
	dw AlolanMarowakPicFront
	dw AlolanMarowakPicBack
	; move tutor compatibility flags
	m_tutor 8
	m_tutor 9,10
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate
	; TM/HM compatibility
	tmlearn 1,3,6,8
	tmlearn 9,10,13,14,15
	tmlearn 17,18,19
	tmlearn 26,27,28,31,32
	tmlearn 34,35,36,37,38,40
	tmlearn 44,48
	tmlearn 50,54
	db BANK(AlolanMarowakPicFront)

AlolanMarowakLevelMoves::
	; Source moves unavailable in this branch are intentionally omitted:
	; db 1,FOCUS_BLAST
	; db 27,MACH_PUNCH
	; db 35,SHADOW_SLAM
	; db 50,POLTERGEIST
	db 1,TACKLE
	db 1,GROWL
	db 3,LEER
	db 7,BONE_CLUB
	db 11,HEADBUTT
	db 13,LEER
	db 17,FOCUS_ENERGY
	db 23,DIG
	db 30,FLAME_WHEEL
	db 38,THRASH
	db 42,BONEMERANG
	db 46,FLARE_BLITZ
	db 54,OUTRAGE
	db 58,DOUBLE_EDGE
	db 62,OUTRAGE
	db 0

AlolanMarowakEvolutions::
	db 0

AlolanMarowakPreviewPalette::
	RGB 20, 19, 12
	RGB 16, 10, 04
AlolanMarowakShinyPalette::
	RGB 18, 21, 15
	RGB 14, 15, 04


; Graphics are a separate section on purpose. Future forms can put their sprites
; in another roomy bank without changing the descriptor engine.
SECTION "Regional Form Graphics - Alolan Rattata Family", ROMX, BANK[$3E]
AlolanRattataPicFront:: INCBIN "pic/bmon/rattata_alola.pic"
AlolanRattataPicBack::  INCBIN "pic/monback/rattata_alolab.pic"
AlolanRaticatePicFront:: INCBIN "pic/bmon/raticate_alola.pic"
AlolanRaticatePicBack::  INCBIN "pic/monback/raticate_alolab.pic"


; FORM-5.22.00: user-provided Alolan Vulpix/Ninetales battle sprites. Bank $34
; is intentionally left for descriptors/engine data; bank $3E keeps this
; expansion inside the original 1 MiB ROM and the form header stores the pic bank.
SECTION "Regional Form Graphics - Alolan Vulpix Family", ROMX, BANK[$3E]
AlolanVulpixPicFront:: INCBIN "pic/bmon/vulpix_alola.pic"
AlolanVulpixPicBack::  INCBIN "pic/monback/vulpix_alolab.pic"
AlolanNinetalesPicFront:: INCBIN "pic/bmon/ninetales_alola.pic"
AlolanNinetalesPicBack::  INCBIN "pic/monback/ninetales_alolab.pic"

; FORM-5.26.00: additional user-supplied Alolan battle sprites.
SECTION "Regional Form Graphics - Alola Bulk Batch", ROMX, BANK[$3E]
AlolanRaichuPicFront:: INCBIN "pic/bmon/raichu_alola.pic"
AlolanRaichuPicBack::  INCBIN "pic/monback/raichu_alolab.pic"
AlolanSandshrewPicFront:: INCBIN "pic/bmon/sandshrew_alola.pic"
AlolanSandshrewPicBack::  INCBIN "pic/monback/sandshrew_alolab.pic"
AlolanSandslashPicFront:: INCBIN "pic/bmon/sandslash_alola.pic"
AlolanSandslashPicBack::  INCBIN "pic/monback/sandslash_alolab.pic"
AlolanDiglettPicFront:: INCBIN "pic/bmon/diglett_alola.pic"
AlolanDiglettPicBack::  INCBIN "pic/monback/diglett_alolab.pic"
AlolanDugtrioPicFront:: INCBIN "pic/bmon/dugtrio_alola.pic"
AlolanDugtrioPicBack::  INCBIN "pic/monback/dugtrio_alolab.pic"
AlolanGeodudePicFront:: INCBIN "pic/bmon/geodude_alola.pic"
AlolanGeodudePicBack::  INCBIN "pic/monback/geodude_alolab.pic"
AlolanGravelerPicFront:: INCBIN "pic/bmon/graveler_alola.pic"
AlolanGravelerPicBack::  INCBIN "pic/monback/graveler_alolab.pic"
AlolanGolemPicFront:: INCBIN "pic/bmon/golem_alola.pic"
AlolanGolemPicBack::  INCBIN "pic/monback/golem_alolab.pic"
AlolanGrimerPicFront:: INCBIN "pic/bmon/grimer_alola.pic"
AlolanGrimerPicBack::  INCBIN "pic/monback/grimer_alolab.pic"
AlolanMukPicFront:: INCBIN "pic/bmon/muk_alola.pic"
AlolanMukPicBack::  INCBIN "pic/monback/muk_alolab.pic"
AlolanMarowakPicFront:: INCBIN "pic/bmon/marowak_alola.pic"
AlolanMarowakPicBack::  INCBIN "pic/monback/marowak_alolab.pic"


; -----------------------------------------------------------------------------
; Optional regional-form Pokédex metrics
; -----------------------------------------------------------------------------
; FORM-5.25.00 keeps only gameplay-relevant numeric differences here. Category
; and long Pokédex descriptions are shared with the Species. Web-verified Alolan
; Rattata/Raticate heights match their normal forms, but their weights differ.
; Vulpix/Ninetales match both height and weight and therefore need no record.
SECTION "Regional Form Pokedex Metrics", ROMX, BANK[$3E]

AlolanRattataDexMetrics::
	db 0,0 ; height 1'00" matches normal -> inherit
	dw 84 ; 8.4 lb

AlolanRaticateDexMetrics::
	db 0,0 ; height 2'04" matches normal -> inherit
	dw 562 ; 56.2 lb

; FORM-5.26.00 bulk metrics: only differing height/weight values are stored.
AlolanRaichuDexMetrics::
	db 2,4 ; height override 2'04"
	dw 463 ; 46.3 lb

AlolanSandshrewDexMetrics::
	db 2,4 ; height override 2'04"
	dw 882 ; 88.2 lb

AlolanSandslashDexMetrics::
	db 3,11 ; height override 3'11"
	dw 1213 ; 121.3 lb

AlolanDiglettDexMetrics::
	db 0,0 ; height matches normal -> inherit
	dw 22 ; 2.2 lb

AlolanDugtrioDexMetrics::
	db 0,0 ; height matches normal -> inherit
	dw 1468 ; 146.8 lb

AlolanGeodudeDexMetrics::
	db 0,0 ; height matches normal -> inherit
	dw 448 ; 44.8 lb

AlolanGravelerDexMetrics::
	db 0,0 ; height matches normal -> inherit
	dw 2425 ; 242.5 lb

AlolanGolemDexMetrics::
	db 5,7 ; height override 5'07"
	dw 6967 ; 696.7 lb

AlolanGrimerDexMetrics::
	db 2,4 ; height override 2'04"
	dw 926 ; 92.6 lb

AlolanMukDexMetrics::
	db 3,3 ; height override 3'03"
	dw 1146 ; 114.6 lb

AlolanMarowakDexMetrics::
	db 0,0 ; height matches normal -> inherit
	dw 750 ; 75.0 lb
