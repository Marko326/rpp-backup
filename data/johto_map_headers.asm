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
	db MUSIC_CITIES1, 0 ; Goldenrod, compatible city music family
JohtoNativeMapSongBanksEnd::

GetJohtoNativeMapSong::
	ld a, [wCurLocalMapID]
	add a
	ld c, a
	ld b, 0
	ld hl, JohtoNativeMapSongBanks
	add hl, bc
	ld a, [hli]
	ld [wMapMusicSoundID], a
	ld a, [hl]
	ld [wMapMusicROMBank], a
	ret

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
