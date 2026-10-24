; Red's bedroom PC is locked until the Pokédex is obtained.
; After that it enters the exact same full ActivatePC path used by Pokémon Center PCs,
; including Pokémon storage, Player's item storage, Oak's PC, and League PC as available.

; Recording-only branch: use the 2F bedroom PC to select an animation run.
; All regular Red/Blue ROMs built from this branch include the gallery.
OpenRedBedroomPC::
	callba VideoBedroomPCMenu
	ret
