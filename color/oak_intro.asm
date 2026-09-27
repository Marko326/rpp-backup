; Helper functions for oak intro

GetOakPalID:
	ld a, PAL_PROF_OAK
	jr GotIntroTrainerPalID

GetOakIntroMonPalID:
	call ClearScreen
; NEW-5.61.08: match Oak's first Pokémon to the Red++/Blue++ build.
IF DEF(_RED)
	ld a, PAL_NIDORINO
ENDC
IF DEF(_BLUE)
	ld a, PAL_NIDORINA
ENDC
	jr GotIntroMonPalID

GetRedPalID:
	call ClearScreen
	ld a, [wPlayerGender]
	and a
	jr z, .male
	ld a, PAL_PLAYER_F
	jr .female
.male
	ld a, PAL_PLAYER_M
.female
	jr GotIntroTrainerPalID

GetRivalPalID:
	call ClearScreen
	ld a, PAL_GARY1
	jr GotIntroTrainerPalID

GotIntroMonPalID:
	ld e,0
	ld d,a

	ld a,2
	ld [rSVBK],a
	CALL_INDIRECT LoadPokemonPalette
	xor a
	ld [rSVBK],a
	ret

GotIntroTrainerPalID:
	ld e,0
	ld d,a

	ld a,2
	ld [rSVBK],a
	CALL_INDIRECT LoadTrainerPalette
	xor a
	ld [rSVBK],a
	ret

