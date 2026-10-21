; SPID: stable Johto physical local ID -> dense registered runtime slot.
; $ff means inactive/illegal, never an implicit default map or a header.
; C alone changes this 256-byte table when a real map is integrated.
JohtoStableIDToActiveSlot::
	db $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f ; $00-$0f
	db $10, $11, $12, $13, $14, $15, $16, $17, $18, $1c, $1d, $ff, $ff, $ff, $ff, $ff ; $10-$1f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $20-$2f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $19, $1a ; $30-$3f
	db $1b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $40-$4f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $50-$5f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $60-$6f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $70-$7f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $80-$8f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $90-$9f
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $a0-$af
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $b0-$bf
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $c0-$cf
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $d0-$df
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $e0-$ef
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff ; $f0-$ff
JohtoStableIDToActiveSlotEnd::
ASSERT JohtoStableIDToActiveSlotEnd - JohtoStableIDToActiveSlot == 256
ASSERT NUM_JOHTO_MAPS < $ff ; $ff is the invalid active slot sentinel

; Input E=stable physical Johto ID; output E=active slot or $ff.
; Preserve BC/HL/D for same-bank calls. Far callers use callab and read E,
; not A or carry (bank restoration may overwrite A/flags).
GetJohtoActiveSlot::
	push bc
	push hl
	ld c, e
	ld b, 0
	ld hl, JohtoStableIDToActiveSlot
	add hl, bc
	ld e, [hl]
	; Defend against a damaged/misregistered table even at runtime.  No
	; out-of-range dense slot may index an arbitrary Bank/Header pointer.
	ld a, e
	cp NUM_JOHTO_ACTIVE_MAPS
	jr c, .valid
	ld e, JOHTO_INVALID_ACTIVE_SLOT
.valid
	pop hl
	pop bc
	ret

; REG-5.62.118: Johto's independent local-ID tables, in Bank $40.
; Keep the pointer and bank entries in exactly the same local-ID order.
JohtoMapHeaderPointers::
	dw NewBarkTown_h ; local $00 (legacy NEW_BARK_TOWN = $E7)
	dw JohtoRoute29_h ; local $01 (legacy JOHTO_ROUTE_29 = $F4)
	dw JohtoCherrygroveCity_h ; local $02 (legacy $CE)
	dw JohtoRoute30_h ; local $03 (legacy $0B)
	dw JohtoRoute31_h ; local $04 (legacy $F8)
	dw JohtoVioletCity_h ; local $05 (legacy $F9)
	dw JohtoRoute31VioletGate_h ; local $06 (legacy $FA)
	dw JohtoRoute32_h ; local $07 (legacy $FB)
	dw JohtoUnionCave1F_h ; local $08 (native $FC)
	dw JohtoRoute33_h ; local $09 (native $FC)
	dw JohtoAzaleaTown_h ; local $0A (native $FC)
	dw JohtoIlexAzaleaGate_h ; local $0B (native $FC)
	dw JohtoIlexForest_h ; local $0C (native $FC)
	dw JohtoRoute34IlexForestGate_h ; local $0D (native $FC)
	dw JohtoRoute34_h ; local $0E (native $FC)
	dw JohtoGoldenrodCity_h ; local $0F (native $FC)
	dw JohtoRoute36_h ; local $10 (native $FC)
	dw JohtoRoute35_h ; local $11 (native $FC)
	dw JohtoRoute35GoldenrodGate_h ; local $12 (native $FC)
	dw JohtoRoute36RuinsGate_h ; local $13 (native $FC)
	dw JohtoRuinsOfAlphOutside_h ; local $14 (native $FC)
	dw JohtoRoute37_h ; local $15 (native $FC)
	dw JohtoEcruteakCity_h ; local $16 (native $FC)
	dw JohtoRoute38EcruteakGate_h ; stable ID $17 -> active slot 23
	dw JohtoRoute38_h ; stable ID $18 -> active slot 24
	dw JohtoRoute42EcruteakGate_h ; stable $3E -> slot $19
	dw JohtoRoute42_h ; stable $3F -> slot $1a
	dw JohtoMahoganyTown_h ; stable $40 -> slot $1b
 dw JohtoRoute39_h ; stable ID25 -> slot28
 dw JohtoOlivineCity_h ; stable ID26 -> slot29
JohtoMapHeaderPointersEnd::

JohtoMapHeaderBanks::
	db BANK(NewBarkTown_h)
	db BANK(JohtoRoute29_h)
	db BANK(JohtoCherrygroveCity_h)
	db BANK(JohtoRoute30_h)
	db BANK(JohtoRoute31_h)
	db BANK(JohtoVioletCity_h)
	db BANK(JohtoRoute31VioletGate_h)
	db BANK(JohtoRoute32_h)
	db BANK(JohtoUnionCave1F_h)
	db BANK(JohtoRoute33_h)
	db BANK(JohtoAzaleaTown_h)
	db BANK(JohtoIlexAzaleaGate_h)
	db BANK(JohtoIlexForest_h)
	db BANK(JohtoRoute34IlexForestGate_h)
	db BANK(JohtoRoute34_h)
	db BANK(JohtoGoldenrodCity_h)
	db BANK(JohtoRoute36_h)
	db BANK(JohtoRoute35_h)
	db BANK(JohtoRoute35GoldenrodGate_h)
	db BANK(JohtoRoute36RuinsGate_h)
	db BANK(JohtoRuinsOfAlphOutside_h)
	db BANK(JohtoRoute37_h)
	db BANK(JohtoEcruteakCity_h)
	db BANK(JohtoRoute38EcruteakGate_h)
	db BANK(JohtoRoute38_h)
	db BANK(JohtoRoute42EcruteakGate_h)
	db BANK(JohtoRoute42_h)
	db BANK(JohtoMahoganyTown_h)
 db BANK(JohtoRoute39_h)
 db BANK(JohtoOlivineCity_h)
JohtoMapHeaderBanksEnd::

; REG-5.62.120: old-engine aliases for registered Johto local IDs.
; Keep in local-ID order. New Johto physical maps use
; REGION_NATIVE_MAP_SLOT (shared), never new sequential legacy IDs.
; A table row equal to $ff remains INVALID, not a map.
JohtoMapLegacyAliases::
	db NEW_BARK_TOWN
	db JOHTO_ROUTE_29
	db JOHTO_CHERRYGROVE_CITY
	db JOHTO_ROUTE_30
	db JOHTO_ROUTE_31
	db JOHTO_VIOLET_CITY
	db JOHTO_ROUTE31_VIOLET_GATE
	db JOHTO_ROUTE_32
	db REGION_NATIVE_MAP_SLOT
	db REGION_NATIVE_MAP_SLOT ; Route33 has no legacy alias
	db REGION_NATIVE_MAP_SLOT ; Azalea Town has no legacy alias
	db REGION_NATIVE_MAP_SLOT ; Ilex south gate, native only
	db REGION_NATIVE_MAP_SLOT ; Ilex forest, native only
	db REGION_NATIVE_MAP_SLOT ; North gate
	db REGION_NATIVE_MAP_SLOT ; Route34
	db REGION_NATIVE_MAP_SLOT ; Goldenrod City
	db REGION_NATIVE_MAP_SLOT ; Route36
	db REGION_NATIVE_MAP_SLOT ; Route35
	db REGION_NATIVE_MAP_SLOT ; Route35 Goldenrod north/south Gate
	db REGION_NATIVE_MAP_SLOT ; Route36 Ruins gate
	db REGION_NATIVE_MAP_SLOT ; Ruins of Alph Outside
	db REGION_NATIVE_MAP_SLOT ; Route37
	db REGION_NATIVE_MAP_SLOT ; EcruteakCity
	db REGION_NATIVE_MAP_SLOT ; Route38EcruteakGate
	db REGION_NATIVE_MAP_SLOT ; Route38
	db REGION_NATIVE_MAP_SLOT ; Route42 Ecruteak gate
	db REGION_NATIVE_MAP_SLOT ; Route42
	db REGION_NATIVE_MAP_SLOT ; MahoganyTown
 db REGION_NATIVE_MAP_SLOT ; Route39
 db REGION_NATIVE_MAP_SLOT ; OlivineCity
JohtoMapLegacyAliasesEnd::

; Song map indexed by Johto local ID rather than the shared $FC slot.
; Do not assume adjacent routes share a GSC theme.
JohtoNativeMapSongBanks::
	db MUSIC_PALLET_TOWN, 0 ; New Bark
	db MUSIC_ROUTES1, 0 ; Route29
	db MUSIC_CITIES1, 0 ; Cherrygrove
	db MUSIC_ROUTES3, 0 ; Route30
	db MUSIC_ROUTES3, 0 ; Route31
	db MUSIC_CITIES1, 0 ; Violet
	db MUSIC_CITIES1, 0 ; Route31 gate, source-dependent in the legacy path
	db MUSIC_ROUTES3, 0 ; Route32
	db MUSIC_DUNGEON2, 0 ; Union Cave 1F
	db MUSIC_ROUTES3, 0 ; Route33, Gold Route30 theme family
	db MUSIC_CITIES2, 0 ; Azalea Town, existing compatible city family
	db MUSIC_ROUTES2, 0 ; Ilex south gate, Gold Route36 music family
	db MUSIC_DUNGEON2, 0 ; Ilex Forest, compatible Union Cave music family
	db MUSIC_ROUTES2, 0 ; Route34 north gate, existing Route36 family
	db MUSIC_ROUTES2, 0 ; Route34, existing Route36 family
	db MUSIC_CITIES1, 0 ; Goldenrod
	db MUSIC_ROUTES2, 0 ; Route36
	db MUSIC_ROUTES2, 0 ; Route35
	db MUSIC_ROUTES2, 0 ; Route35 Goldenrod gate (Gold Route36 theme)
	db MUSIC_ROUTES2, 0 ; Route36 Ruins gate
	db MUSIC_DUNGEON2, 0 ; Ruins of Alph Outside
	db MUSIC_ROUTES2, 0 ; Route37; GB Player selects GSC Route37
	db MUSIC_CITIES1, 0 ; EcruteakCity; GB Player selects original GSC city theme
	db MUSIC_ROUTES2, 0 ; Route38EcruteakGate, Gold Route37 music family
	db MUSIC_ROUTES2, 0 ; Route38, Gold Route37 music family
	db MUSIC_ROUTES2, 0 ; Gold gate LAKE_OF_RAGE compatible route family
	db MUSIC_ROUTES2, 0 ; Gold Route42 LAKE_OF_RAGE compatible route family
	db MUSIC_CITIES1, 0 ; Gold MahoganyTown CHERRYGROVE_CITY family
 db MUSIC_ROUTES2, 0 ; Gold Route39 MUSIC_ROUTE_37
 db MUSIC_CITIES1, 0 ; Gold OlivineCity MUSIC_VIOLET_CITY
JohtoNativeMapSongBanksEnd::

GetJohtoNativeMapSong::
	ld a, [wCurLocalMapID]
	ld e, a
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	ret z ; no out-of-bounds music lookup for a bad physical ID
	ld l, e
	ld h, 0
	add hl, hl ; 16-bit slot * 2, safe beyond slot 127
	ld bc, JohtoNativeMapSongBanks
	add hl, bc
	ld a, [hli]
	ld [wMapMusicSoundID], a
	ld a, [hl]
	ld [wMapMusicROMBank], a
	ret

; Kept above the table-count assertions to catch all future registrations.
; End of safe song lookup.

ASSERT JohtoMapLegacyAliasesEnd - JohtoMapLegacyAliases == NUM_JOHTO_MAPS
ASSERT JohtoMapHeaderPointersEnd - JohtoMapHeaderPointers == NUM_JOHTO_MAPS * 2
ASSERT JohtoMapHeaderBanksEnd - JohtoMapHeaderBanks == NUM_JOHTO_MAPS
ASSERT JohtoNativeMapSongBanksEnd - JohtoNativeMapSongBanks == NUM_JOHTO_MAPS * 2
ASSERT NEW_BARK_TOWN == $E7
ASSERT JOHTO_ROUTE_29 == $F4
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1
ASSERT JOHTO_CHERRYGROVE_LOCAL_ID == 2
ASSERT JOHTO_CHERRYGROVE_CITY == $CE
ASSERT JOHTO_ROUTE_30_LOCAL_ID == 3
ASSERT JOHTO_ROUTE_30 == $0B
ASSERT JOHTO_ROUTE_31_LOCAL_ID == 4
ASSERT JOHTO_ROUTE_31 == $F8
ASSERT JOHTO_VIOLET_CITY_LOCAL_ID == 5
ASSERT JOHTO_VIOLET_CITY == $F9
ASSERT JOHTO_VIOLET_CITY < REGION_WARP_ESCAPE
ASSERT JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID == 6
ASSERT JOHTO_ROUTE31_VIOLET_GATE == $FA
ASSERT JOHTO_ROUTE31_VIOLET_GATE < REGION_WARP_ESCAPE
ASSERT JOHTO_ROUTE_32_LOCAL_ID == 7
ASSERT JOHTO_ROUTE_32 == $FB
ASSERT JOHTO_ROUTE_32 < REGION_WARP_ESCAPE
