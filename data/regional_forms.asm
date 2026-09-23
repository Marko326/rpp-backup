; FORM-5.22.00: table-driven regional-form data.
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
;   shiny palette pointer
;
; Descriptor/header/learnset/evolution/palette data stay with the generic engine in bank
; $34. Sprite binaries themselves may live in any ROM bank because each complete
; form header carries its own picture bank.

SECTION "Regional Form Data", ROMX, BANK[$34]

RegionalFormDescriptors::
	db RATTATA, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanRattataBaseStats
	dw AlolanRattataLevelMoves
	dw AlolanRattataEvolutions
	dw AlolanRattataPreviewPalette
	dw AlolanRattataShinyPalette

	db RATICATE, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanRaticateBaseStats
	dw AlolanRaticateLevelMoves
	dw AlolanRaticateEvolutions
	dw AlolanRaticatePreviewPalette
	dw AlolanRaticateShinyPalette

	db VULPIX, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanVulpixBaseStats
	dw AlolanVulpixLevelMoves
	dw AlolanVulpixEvolutions
	dw AlolanVulpixPreviewPalette
	dw AlolanVulpixShinyPalette

	db NINETALES, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanNinetalesBaseStats
	dw AlolanNinetalesLevelMoves
	dw AlolanNinetalesEvolutions
	dw AlolanNinetalesPreviewPalette
	dw AlolanNinetalesShinyPalette
	db 0 ; terminator: species 0 is never a valid descriptor

; Wild-only producer table: map, species, form.
; Stored/trainer/link Pokémon resolve their form from the persistent marker.
RegionalFormWildEncounters::
	db ROUTE_1, RATTATA, FORM_ALOLA
	; FORM-5.22.00: Route 7 Vulpix uses the Alolan descriptor. Other maps
	; continue to produce normal Vulpix, so both forms remain obtainable.
	db ROUTE_7, VULPIX, FORM_ALOLA
	db $ff ; terminator: no real map uses this entry here

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
; FORM-5.21.03: official stats 75/71/70/40/80/77. This Gen-I engine has one
; Special stat; follow the project's later-generation convention and map Sp.Def
; 80 to Special. Other balance fields follow this project's normal Raticate.
AlolanRaticateBaseStats::
	db DEX_RATICATE
	db 75
	db 71
	db 70
	db 77
	db 80 ; Special <- official Sp.Def
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


; Graphics are a separate section on purpose. Future forms can put their sprites
; in another roomy bank without changing the descriptor engine.
SECTION "Regional Form Graphics - Alolan Rattata Family", ROMX, BANK[$34]
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
