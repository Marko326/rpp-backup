; MOVE-5.62.171: per-slot extended identity decoder.
; A low byte alone is never a complete extended identity; use the
; slot's own saved mask bit before choosing either ROM move table.
;
; Inputs: A = unchanged low byte of a move slot, B = slot index (0..3),
;         C = sidecar bits (bit 0..3 correspond to slots 0..3).
; Output: HL = full move ID, carry clear on valid identity.
;         Carry set on invalid slot, a legacy $ff sentinel, or an undefined
;         extended ID. A and B are clobbered; C and DE are preserved.
; For an ordinary empty slot (low byte $00, flag clear), HL is $0000.
; For any extended ordinal 1..N (low byte equals the one-based ordinal,
; flag set), HL is $0100 + ordinal - 1.
;
; The old 168 $ff experiment deliberately returns invalid here: a future
; explicit migration must convert it, not silently mistake it for another ID.
DecodeExperimentalMoveSlotID::
	ld l, a
	ld a, b
	cp NUM_MOVES
	jr nc, .invalid
	ld h, 0
	ld a, b
	and a
	ld a, c
	jr z, .bitReady
.shift
	srl a
	dec b
	jr nz, .shift
.bitReady
	and 1
	jr z, .legacy
	ld a, l
	and a ; no extended move may store $00 (the empty-slot sentinel)
	jr z, .invalid
	dec a ; one-based storage becomes zero-based index
	cp NUM_EXTENDED_MOVES
	jr nc, .invalid
	ld l, a
	ld h, HIGH(EXT_MOVE_POWER_WHIP)
	and a
	ret
.legacy
	ld a, l
	cp EXT_MOVE_SLOT_ESCAPE
	jr z, .invalid
	and a
	ret
.invalid
	scf
	ret

; MOVE-5.62.169: translate a live player's battle slot to an ordinal.
; Input wExtendedMoveFlagsScratch = zero-based move slot;
; writes wExtendedActiveMoveOrdinal = 0 for legacy / 1..N expanded.
; The far-call trampoline clobbers A, so it MUST NOT be the return ABI.
; A bad/empty/undefined encoded slot writes 0.
GetPlayerBattleExtendedOrdinal::
	push bc
	push de
	push hl
	ld a, [wExtendedMoveFlagsScratch]
	ld b, a
	cp NUM_MOVES
	jr nc, .zero
	ld c, a
	ld hl, wBattleMonMoves
	ld e, a
	ld d, 0
	add hl, de
	ld d, [hl] ; stored low byte
	ld a, [wExtendedBattleMoveFlags]
	ld e, c
	ld c, a
.shift
	ld a, e
	and a
	ld a, c
	jr z, .bit
	srl a
	ld c, a
	dec e
	jr .shift
.bit
	and 1
	jr z, .zero
	ld a, d
	and a
	jr z, .zero
	cp NUM_EXTENDED_MOVES + 1
	jr nc, .zero
	jr .done
.zero
	xor a
.done
	ld [wExtendedActiveMoveOrdinal], a
	pop hl
	pop de
	pop bc
	ret

; Set or clear one extended identity bit after a successful LearnMove.
; Inputs wExtendedMoveFlagsScratch = slot index 0..3;
; wExtendedLearningMoveOrdinal = new ordinal (0 for legacy).
; wWhichPokemon identifies the Party member. BC/DE/HL preserved.
SetPartyExtendedMoveSlot::
	push bc
	push de
	push hl
	ld a, [wExtendedMoveFlagsScratch]
	ld c, a
	cp NUM_MOVES
	jr nc, .done
	ld a, [wWhichPokemon]
	cp PARTY_LENGTH
	jr nc, .done
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	push hl
	ld e, c
	ld hl, .bits
	add hl, de
	ld c, [hl]
	pop hl
	ld a, [wExtendedLearningMoveOrdinal]
	and a
	jr z, .clear
	ld a, [hl]
	or c
	ld [hl], a
	jr .battle
.clear
	ld a, c
	cpl
	and [hl]
	ld [hl], a
.battle
	; Learning can occur in battle through EXP gains: keep the active
	; battle record in sync only for the currently selected party member.
	ld a, [wIsInBattle]
	and a
	jr z, .done
	ld a, [wPlayerMonNumber]
	ld e, a
	ld a, [wWhichPokemon]
	cp e
	jr nz, .done
	ld a, [hl]
	ld [wExtendedBattleMoveFlags], a
.done
	pop hl
	pop de
	pop bc
	ret
.bits
	db 1, 2, 4, 8

; Returns the flag mask of the active Party member (zero for bad index).
; Preserves BC, DE; clobbers HL and A.
GetCurrentPartyExtendedMoveMask::
	push bc
	push de
	ld a, [wWhichPokemon]
	cp PARTY_LENGTH
	jr nc, .bad
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, [hl]
	and $0f
	jr .done
.bad
	xor a
.done
	ld [wExtendedMoveFlagsScratch], a ; far-call-safe return
	pop de
	pop bc
	ret

; Prepare the current Summary screen flag mask after LoadMonData.
; Only Party and the active PC box have sidecar coverage; other locations
; stay ordinary until their identity lifecycles are implemented.
LoadExtendedStatusMoveMask::
	xor a
	ld [wExtendedStatusMoveFlags], a
	ld a, [wMonDataLocation]
	and a
	jr z, .party
	cp BOX_DATA
	ret nz
	jpba ReadExtendedCurrentBoxStatusMask
.party
	call GetCurrentPartyExtendedMoveMask
	ld [wExtendedStatusMoveFlags], a
	ret

; Fight menu uses one-based selected/pending positions; the same index
; conversion must apply to battle/Party mask bits and stock move/PP bytes.
SwapExtendedBattleMenuFlags::
	push bc
	push de
	push hl
	; MOVE-5.62.176: both menu indices are one-based, exactly as
	; SwapMovesInMenu.swapBytes uses them for the move and PP bytes.
	ld a, [wMenuItemToSwap]
	dec a
	cp NUM_MOVES
	jr nc, .done
	ld e, a
	ld d, 0
	ld hl, .bits
	add hl, de
	ld c, [hl]
	ld a, [wCurrentMenuItem]
	dec a
	cp NUM_MOVES
	jr nc, .done
	ld e, a
	ld hl, .bits
	add hl, de
	ld b, [hl]
	ld hl, wExtendedBattleMoveFlags
	call .swap
	ld a, [wPlayerMonNumber]
	cp PARTY_LENGTH
	jr nc, .done
	ld e, a
	; MOVE-5.62.176: .swap stores the previous flag mask in D.
	; Clear D before forming the Party WRAM address; otherwise the
	; high byte redirects the write outside wExtendedPartyMoveFlags.
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	call .swap
.done
	pop hl
	pop de
	pop bc
	ret
.swap
	ld d, [hl]
	ld a, d
	and c
	jr z, .firstZero
	ld a, d
	and b
	ret nz
	jr .flip
.firstZero
	ld a, d
	and b
	ret z
.flip
	ld a, b
	or c
	xor d
	ld [hl], a
	ret
.bits
	db 1, 2, 4, 8

; MOVE-5.62.171: shift only the four extension-identity bits
; after DeleteMove compacts the move/PP bytes. Nothing else in the Party
; structure is changed. Input wWhichPokemon = party slot,
; wExtendedMoveFlagsScratch = deleted raw move slot 0..3.
ShiftExtendedPartyMoveFlagsOnDelete::
	push bc
	push de
	push hl
	ld a, [wExtendedMoveFlagsScratch]
	cp NUM_MOVES
	jr nc, .done
	ld c, a
	ld b, 0
	ld hl, .lowMasks
	add hl, bc
	ld e, [hl]
	ld hl, .upperMasks
	add hl, bc
	ld d, [hl]
	ld a, [wWhichPokemon]
	cp PARTY_LENGTH
	jr nc, .done
	ld c, a
	ld b, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, bc
	ld c, [hl]
	ld a, c
	and e
	ld b, a
	ld a, c
	and d
	srl a
	or b
	ld [hl], a
.done
	pop hl
	pop de
	pop bc
	ret
.lowMasks
	db $00, $01, $03, $07
.upperMasks
	db $0e, $0c, $08, $00
