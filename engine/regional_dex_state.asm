; DEX-5.62.114: only the independent form-bit storage helpers.
; Species Pokédex Seen/Owned remain authoritative for the 208-entry totals.
; These helpers do not register encounters or change Pokédex rendering yet.
; D = species, E = runtime form. Carry indicates a registered identity;
; on success C is its permanent bit ID (0..79).
RegionalDexFindSlot::
	ld hl,RegionalDexSlots
	ld c,0
.loop
	ld a,[hli]
	cp d
	jr nz,.next
	ld a,[hl]
	cp e
	jr z,.found
.next
	inc hl
	inc c
	ld a,c
	cp REGIONAL_DEX_SLOT_COUNT
	jr nz,.loop
	and a
	ret
.found
	scf
	ret

; Read or set independent Seen. Return A = 0 when unset/unregistered,
; nonzero when set; Z reflects the returned state.
RegionalDexSeenTest::
	ld b,FLAG_TEST
	jr RegionalDexSeenAction
RegionalDexSeenSet::
	ld b,FLAG_SET
RegionalDexSeenAction:
	call RegionalDexFindSlot
	jr nc,.missing
	ld hl,wRegionalDexSeen
	jr RegionalDexRunFlag
.missing
	xor a
	ret

; Owned implies Seen. The 10 Owned bytes are split across two existing
; saved reserve ranges (8 + 2), without shifting any original save offsets.
RegionalDexOwnedTest::
	ld b,FLAG_TEST
	jr RegionalDexOwnedAction
RegionalDexOwnedSet::
	push de
	call RegionalDexSeenSet
	pop de
	ld b,FLAG_SET
RegionalDexOwnedAction:
	call RegionalDexFindSlot
	jr nc,.missing
	ld a,c
	cp 64
	jr c,.first64
	sub 64
	ld c,a
	ld hl,wRegionalDexOwnedTail
	jr RegionalDexRunFlag
.first64
	ld hl,wRegionalDexOwned
	jr RegionalDexRunFlag
.missing
	xor a
	ret

RegionalDexRunFlag:
	predef FlagActionPredef
	ld a,c ; FlagAction returns its result in C, not in A.
	and a
	ret
