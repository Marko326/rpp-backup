; Restore a conventional item list from the absolute entry index in wWhichPokemon.
; Keep the previous scroll when the selected entry is still visible so child
; quantity/Yes-No dialogs do not make the list jump. If an operation removes a
; whole slot, the following item naturally takes the same absolute index;
; removing the final slot selects the previous real item; an empty list selects Cancel.
RestoreItemListPosition::
	ld a,[wListPointer]
	ld l,a
	ld a,[wListPointer + 1]
	ld h,a
	ld b,[hl] ; number of real list entries; Cancel is at absolute index b
	ld a,[wWhichPokemon]
	cp b
	jr c,.targetValid
	ld a,b
	and a
	jr z,.targetValid ; empty list: Cancel is index 0
	dec a ; deleted final/out-of-range entry: select previous real item
.targetValid
	ld c,a ; c = desired absolute index

	; Clamp the old scroll to the new list's maximum scroll (count - 2).
	ld a,b
	cp 2
	jr c,.zeroMaxScroll
	sub 2
	ld b,a
	jr .clampScroll
.zeroMaxScroll
	xor a
	ld b,a
.clampScroll
	ld a,[wListScrollOffset]
	cp b
	jr c,.scrollWithinMax
	ld a,b
.scrollWithinMax
	; A stale scroll can never begin below the desired entry.
	cp c
	jr c,.scrollNotPastTarget
	jr z,.scrollNotPastTarget
	ld a,c
.scrollNotPastTarget
	ld [wListScrollOffset],a
	ld b,a
	ld a,c
	sub b ; desired cursor row
	cp 3
	jr c,.storeRow
	; Desired entry is below the visible 3-row window. Put it on row 2.
	ld a,c
	sub 2
	ld [wListScrollOffset],a
	ld a,2
.storeRow
	ld [wCurrentMenuItem],a
	ret


; Remove an inventory item while insulating the surrounding list UI from the
; legacy whole-slot removal side effects. The inventory primitive still updates
; the item count/list limits, but cursor restoration is handled separately from
; wWhichPokemon by RestoreItemListPosition.
; INPUT: DE = wNumBagItems or wNumBoxItems (callba consumes HL/BC)
RemoveItemFromInventoryPreserveListState::
	ld a,[wListScrollOffset]
	push af
	ld a,[wSavedListScrollOffset]
	push af
	ld a,[wBagSavedMenuItem]
	push af
	ld h,d
	ld l,e
	call RemoveItemFromInventory
	pop af
	ld [wBagSavedMenuItem],a
	pop af
	ld [wSavedListScrollOffset],a
	pop af
	ld [wListScrollOffset],a
	ret
