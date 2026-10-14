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
JohtoMapHeaderPointersEnd::

JohtoMapHeaderBanks::
	db BANK(NewBarkTown_h)
	db BANK(JohtoRoute29_h)
	db BANK(JohtoCherrygroveCity_h)
	db BANK(JohtoRoute30_h)
	db BANK(JohtoRoute31_h)
	db BANK(JohtoVioletCity_h)
	db BANK(JohtoRoute31VioletGate_h)
JohtoMapHeaderBanksEnd::

; REG-5.62.120: old-engine aliases for registered Johto local IDs.
; Keep in local-ID order; new Johto maps need an unused unique legacy
; alias until the rest of the overworld has native region-aware map IDs.
JohtoMapLegacyAliases::
	db NEW_BARK_TOWN
	db JOHTO_ROUTE_29
	db JOHTO_CHERRYGROVE_CITY
	db JOHTO_ROUTE_30
	db JOHTO_ROUTE_31
	db JOHTO_VIOLET_CITY
	db JOHTO_ROUTE31_VIOLET_GATE
JohtoMapLegacyAliasesEnd::

ASSERT JohtoMapLegacyAliasesEnd - JohtoMapLegacyAliases == NUM_JOHTO_MAPS
ASSERT JohtoMapHeaderPointersEnd - JohtoMapHeaderPointers == NUM_JOHTO_MAPS * 2
ASSERT JohtoMapHeaderBanksEnd - JohtoMapHeaderBanks == NUM_JOHTO_MAPS
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
