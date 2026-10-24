; DUAL-5.19.31: active Red++/Blue++ title-screen rotation pools.
; Each build compiles exactly one 16-entry list, matching the original
; international Red/Blue version split while keeping Red++ species IDs.
TitleMons:
; mons on the title screen are randomly chosen from here
IF DEF(_RED)
	db WEEDLE
	db NIDORAN_M
	db SCYTHER
	db PIKACHU
	db CLEFAIRY
	db RHYDON
	db ABRA
	db GASTLY
	db DITTO
	db PIDGEOTTO
	db ONIX
	db PONYTA
	db MAGIKARP
ENDC
IF DEF(_GREEN)
	db CATERPIE
	db NIDORAN_F
	db PINSIR
	db PIKACHU
	db CLEFAIRY
	db RHYDON
	db ABRA
	db GASTLY
	db DITTO
	db PIDGEOTTO
	db ONIX
	db PONYTA
	db MAGIKARP
ENDC
IF DEF(_BLUE)
	db MANKEY
	db HITMONLEE
	db VULPIX
	db CHANSEY
	db AERODACTYL
	db JOLTEON
	db SNORLAX
	db GLOOM
	db POLIWAG
	db DODUO
	db PORYGON
	db GENGAR
	db RAICHU
ENDC
