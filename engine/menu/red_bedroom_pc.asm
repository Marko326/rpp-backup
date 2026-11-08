; REF-357 (#45): the bedroom PC offers the original Player's item PC before
; the Pokédex, then the unchanged full Pokémon Center-style PC afterward.
; The early path must save Buffer2 before entering PlayerPC directly, because
; PlayerPC restores that buffer when Log off closes its standalone menu.

OpenRedBedroomPC::
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .playerItemsOnly
	callba ActivatePC
	ret

.playerItemsOnly
	call SaveScreenTilesToBuffer2
	ld hl, wFlags_0xcd60
	res 3, [hl] ; stand-alone Player PC, not a generic PC submenu
	callba PlayerPC
	ret

; REF-356 historical pre-Pokédex rejection, preserved but not assembled:
; .temporarilyUnavailable
; 	ld hl, RedBedroomPCUnavailableText
; 	call PrintText
; 	ret
;
; RedBedroomPCUnavailableText:
; 	text "The PC can't be"
; 	line "used right now."
; 	prompt
; 	db "@"
