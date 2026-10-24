CeladonMansion1Object:
	db $f ; border block

	db $5 ; warps
	db $b, $4, $2, $ff
	db $b, $5, $2, $ff
	db $0, $4, $4, $ff
	db $1, $7, $1, CELADON_MANSION_2
	db $1, $2, $2, CELADON_MANSION_2

	db $1 ; signs
	db $9, $4, $5 ; CeladonMansion1Text5

IF DEF(BATTLE_TEST_BUILD)
	db $5 ; four original NPCs + one test-only NPC
ELSE
	db $4 ; original four NPCs
ENDC
	object SPRITE_OLD_MEDIUM_WOMAN, $3, $4, STAY, UP, $1 ; person
	object SPRITE_FOULARD_WOMAN, $0, $5, STAY, DOWN, $2 ; person
	object SPRITE_HIKER, $1, $5, STAY, DOWN, $3 ; person
	object SPRITE_BRUNETTE_GIRL, $2, $6, STAY, LEFT, $4 ; person
IF DEF(BATTLE_TEST_BUILD)
	; User-finalized position at ($00,$0A); TEST ROM only, text pointer 6.
	object SPRITE_POKEY, $0, $0A, STAY, LEFT, $6 ; RUN-009 TEST
ENDC
