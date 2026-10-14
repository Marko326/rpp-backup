; REG-5.62.118: Johto's independent local-ID tables, in Bank $40.
; Keep the pointer and bank entries in exactly the same local-ID order.
JohtoMapHeaderPointers::
	dw NewBarkTown_h ; local $00 (legacy NEW_BARK_TOWN = $E7)
	dw JohtoRoute29_h ; local $01 (legacy JOHTO_ROUTE_29 = $F4)
	dw JohtoCherrygroveCity_h ; local $02 (legacy $CE)
JohtoMapHeaderPointersEnd::

JohtoMapHeaderBanks::
	db BANK(NewBarkTown_h)
	db BANK(JohtoRoute29_h)
	db BANK(JohtoCherrygroveCity_h)
JohtoMapHeaderBanksEnd::

; REG-5.62.120: old-engine aliases for registered Johto local IDs.
; Keep in local-ID order; new Johto maps need an unused unique legacy
; alias until the rest of the overworld has native region-aware map IDs.
JohtoMapLegacyAliases::
	db NEW_BARK_TOWN
	db JOHTO_ROUTE_29
	db JOHTO_CHERRYGROVE_CITY
JohtoMapLegacyAliasesEnd::

ASSERT JohtoMapLegacyAliasesEnd - JohtoMapLegacyAliases == NUM_JOHTO_MAPS
ASSERT JohtoMapHeaderPointersEnd - JohtoMapHeaderPointers == NUM_JOHTO_MAPS * 2
ASSERT JohtoMapHeaderBanksEnd - JohtoMapHeaderBanks == NUM_JOHTO_MAPS
ASSERT NEW_BARK_TOWN == $E7
ASSERT JOHTO_ROUTE_29 == $F4
ASSERT JOHTO_ROUTE_29_LOCAL_ID == 1
ASSERT JOHTO_CHERRYGROVE_LOCAL_ID == 2
ASSERT JOHTO_CHERRYGROVE_CITY == $CE
