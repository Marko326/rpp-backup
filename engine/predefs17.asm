; Oak Lab preview: temporarily treat the currently selected Starter as owned
; so ShowPokedexData renders height, weight and description for arbitrary
; configured Starter species instead of only the original three.
StarterDex:
	; RegionalFormShowStarterDex keeps the selected internal Species in
	; wCapturedMonSpecies for this synchronous one-shot. Convert it to the
	; Pokédex-number bit index before touching wPokedexOwned.
	ld a,[wCapturedMonSpecies]
	ld [wd11e],a
	predef IndexToPokedex
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_SET
	ld hl,wPokedexOwned
	predef FlagActionPredef

	; ShowPokedexData expects the internal Species ID again.
	ld a,[wCapturedMonSpecies]
	ld [wd11e],a
	predef ShowPokedexData

	; Starter preview runs before ownership is awarded. Restore the temporary
	; owned bit so merely inspecting a ball never changes Pokédex progress.
	ld a,[wCapturedMonSpecies]
	ld [wd11e],a
	predef IndexToPokedex
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_RESET
	ld hl,wPokedexOwned
	predef FlagActionPredef
	ld a,[wCapturedMonSpecies]
	ld [wd11e],a
	ret
