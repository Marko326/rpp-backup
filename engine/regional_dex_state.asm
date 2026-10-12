; DEX-5.62.115: storage for up to 128 independent form identities.
; Species Pokédex Seen/Owned still control 208-entry totals; nothing yet
; registers encounters or modifies Pokédex UI. D=species, E=runtime form.
; Carry indicates a registered identity, C=permanent ID (currently 0..79).
;
; DEX-5.62.116/S2A: call only after LoadEnemyMonData has resolved the
; untransformed encounter/party header. It is also called from non-battle
; materialization (e.g. direct-to-box gifts), which must NOT count as an
; actual encounter here; S2B will register successfully obtained gifts.
RegionalDexMarkBattleEnemySeen::
	ld a,[wIsInBattle]
	cp 1 ; wild encounter
	jr z,.register
	cp 2 ; trainer opponent
	ret nz ; previews, gifts, unrelated materializations
.register
	ld a,[wEnemyMonSpecies2] ; source identity, not Transform's display Species
	ld d,a
	ld a,[wEnemyMonForm] ; resolved original form from header
	ld e,a
	jp RegionalDexSeenSet ; no slot -> no mutation, flag set is idempotent

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
	ld a,c
	cp 80
	jr c,.first80
	sub 80
	ld c,a
	ld hl,wRegionalDexSeenExtra ; 80..127: 6 bytes at $D7A4
	jr RegionalDexRunFlag
.first80
	ld hl,wRegionalDexSeen ; 0..79: original 10 bytes
	jr RegionalDexRunFlag
.missing
	xor a
	ret

; Owned implies Seen. The fixed-address storage is 8 + 6 + 2 bytes.
; 0..63 remain in the original block; 64..111 use the expanded tail;
; 112..127 live after the Seen extension. All 0..79 bit IDs are unchanged.
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
	cp 112
	jr nc,.last16
	cp 64
	jr c,.first64
	sub 64
	ld c,a
	ld hl,wRegionalDexOwnedTail ; 64..111, 6 saved bytes
	jr RegionalDexRunFlag
.last16
	sub 112
	ld c,a
	ld hl,wRegionalDexOwnedLast ; 112..127, 2 saved bytes
	jr RegionalDexRunFlag
.first64
	ld hl,wRegionalDexOwned ; 0..63, original 8 bytes
	jr RegionalDexRunFlag
.missing
	xor a
	ret

RegionalDexRunFlag:
	predef FlagActionPredef
	ld a,c ; FlagAction returns its result in C, not in A.
	and a
	ret
