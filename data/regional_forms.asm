; FORM-5.21.00: table-driven regional-form data.
;
; The engine never names a concrete regional Pokémon. To add another form,
; define its complete header/learnset/palettes below, add one descriptor row,
; and (only if it should appear in the wild) add one wild encounter row.
;
; Descriptor layout:
;   species, form id, persistent marker,
;   full MonBaseStats-compatible header pointer,
;   level-up learnset pointer,
;   normal palette pointer,
;   shiny palette pointer
;
; Descriptor/header/learnset/palette data stay with the generic engine in bank
; $34. Sprite binaries themselves may live in any ROM bank because each complete
; form header carries its own picture bank.

SECTION "Regional Form Data", ROMX, BANK[$34]

RegionalFormDescriptors::
	db RATTATA, FORM_ALOLA, REGIONAL_FORM_MARKER_ALOLA
	dw AlolanRattataBaseStats
	dw AlolanRattataLevelMoves
	dw AlolanRattataPreviewPalette
	dw AlolanRattataShinyPalette
	db 0 ; terminator: species 0 is never a valid descriptor

; Wild-only producer table: map, species, form.
; Stored/trainer/link Pokémon resolve their form from the persistent marker.
RegionalFormWildEncounters::
	db ROUTE_1, RATTATA, FORM_ALOLA
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

AlolanRattataPreviewPalette::
	RGB 15, 16, 19
	RGB 06, 06, 05
AlolanRattataShinyPalette::
	RGB 21, 17, 15
	RGB 19, 09, 11

; Graphics are a separate section on purpose. Future forms can put their sprites
; in another roomy bank without changing the descriptor engine.
SECTION "Regional Form Graphics - Alolan Rattata", ROMX, BANK[$34]
AlolanRattataPicFront:: INCBIN "pic/bmon/rattata_alola.pic"
AlolanRattataPicBack::  INCBIN "pic/monback/rattata_alolab.pic"
