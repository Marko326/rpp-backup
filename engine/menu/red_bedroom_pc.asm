; Red's bedroom PC is locked until the Pokédex is obtained.
; After that it enters the exact same full ActivatePC path used by Pokémon Center PCs,
; including Pokémon storage, Player's item storage, Oak's PC, and League PC as available.

OpenRedBedroomPC::
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .temporarilyUnavailable
	callba ActivatePC
	ret

.temporarilyUnavailable
	ld hl, RedBedroomPCUnavailableText
	call PrintText
	ret

RedBedroomPCUnavailableText:
	text "The PC can't be"
	line "used right now."
	prompt
	db "@"
