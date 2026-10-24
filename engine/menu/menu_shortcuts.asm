; MENU-5.61.17: menu-only shortcut executors live in expansion bank $3D.
; Keep Bag Pockets bank $35 focused on the reusable Bag core; this also prevents
; the fixed-bank Warp Destination Helpers section from being displaced.

HandleBagStartShortcut::
	; TM/HM keeps the established HM01 shortcut. Every other categorized START
	; Pocket jumps to its final owned entry. The mode check is repeated here so a
	; stale/unexpected caller cannot move a conventional ITEMLISTMENU cursor.
	ld a, [wBagPocketActive]
	cp BAG_POCKET_MODE_START
	ret nz
	ld a, [wBagPocketCurrent]
	cp BAG_POCKET_TM_HM
	jr nz, .categorizedLastEntry
	jpba JumpBagPocketToHM01
.categorizedLastEntry
	callba GetCurrentBagPocketCount
	and a
	ret z
	dec a
	callba StoreCurrentBagPocketSavedPosition
	jpba LoadCurrentBagPocketCursor

QuickSwapPartyMonWithFirst::
	; Keep the actual party-record swap in the established bank-$04 routine.
	; Slot 1 swapping with itself is deliberately a no-op.
	ld a, [wCurrentMenuItem]
	and a
	ret z
	ld a, 1 ; wMenuItemToSwap counts from 1, so 1 means the lead Pokémon
	ld [wMenuItemToSwap], a
	callab SwitchPartyMon
	ret
