; MOVE-5.62.169: isolated persistence for party extended-move flags.
; The existing four move bytes and party/box structures do not change.
; Called only with MBC1 SRAM bank 1 already enabled by the save loader.
; No hook in the move-selection path until all identity consumers are ready.
;
; A two-byte signature and nibble validation prevent interpreting random
; legacy SRAM tail bytes as live expansion flags. The independent XOR check
; detects ordinary corruption; this is not an authenticated checksum.

EXT_PARTY_MAGIC_0 EQU $d3
EXT_PARTY_MAGIC_1 EQU $69
EXT_PARTY_CHECK_SEED EQU $b7

LoadExtendedPartyFlagsFromSRAM::
	; Runtime contexts are never restored from SAV; initialize them separately.
	xor a
	ld [wExtendedLearningMoveOrdinal], a
	ld [wExtendedStatusMoveFlags], a
	ld [wExtendedActiveMoveOrdinal], a
	ld a, [sExtendedPartyFlagsMagic0]
	cp EXT_PARTY_MAGIC_0
	jr nz, .zero
	ld a, [sExtendedPartyFlagsMagic1]
	cp EXT_PARTY_MAGIC_1
	jr nz, .zero
	ld hl, sExtendedPartyMoveFlags
	ld b, PARTY_LENGTH
	ld c, EXT_PARTY_CHECK_SEED
.check
	ld a, [hli]
	and $f0
	jr nz, .zero
	dec hl
	ld a, [hli]
	xor c
	ld c, a
	dec b
	jr nz, .check
	ld a, [sExtendedPartyFlagsChecksum]
	cp c
	jr nz, .zero
	ld hl, sExtendedPartyMoveFlags
	ld de, wExtendedPartyMoveFlags
	ld bc, PARTY_LENGTH
	jp CopyData
.zero
	xor a
	ld hl, wExtendedPartyMoveFlags
	ld bc, PARTY_LENGTH
	jp FillMemory

SaveExtendedPartyFlagsToSRAM::
	; Invalidate the signature before writing bytes (power-loss safety).
	xor a
	ld [sExtendedPartyFlagsMagic0], a
	ld [sExtendedPartyFlagsMagic1], a
	ld hl, wExtendedPartyMoveFlags
	ld de, sExtendedPartyMoveFlags
	ld b, PARTY_LENGTH
	ld c, EXT_PARTY_CHECK_SEED
.loop
	ld a, [hli]
	and $0f
	ld [de], a
	inc de
	xor c
	ld c, a
	dec b
	jr nz, .loop
	ld a, c
	ld [sExtendedPartyFlagsChecksum], a
	ld a, EXT_PARTY_MAGIC_1
	ld [sExtendedPartyFlagsMagic1], a
	ld a, EXT_PARTY_MAGIC_0
	ld [sExtendedPartyFlagsMagic0], a
	ret
