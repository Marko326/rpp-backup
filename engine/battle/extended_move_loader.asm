; MOVE-5.62.169: second-table 16-bit readers for the current two-move
; experiment. The legacy $ff Power Whip escape remains for compatibility;
; durable multi-move identity uses one-based slot bytes and sidecar flags.
; Call while banked into this section, or via a proper banked wrapper.
; HL = full 16-bit move ID ($0100...), DE = destination buffer.
; On success copy data and return carry clear; on bad ID carry set, leave DE intact.
; CopyExtendedMoveStats requires six output bytes; name requires sufficient space.
CopyExtendedMoveStats::
	ld a, h
	cp HIGH(EXT_MOVE_POWER_WHIP)
	jr nz, .invalid
	ld a, l
	cp NUM_EXTENDED_MOVES
	jr nc, .invalid
	push bc
	push hl
	ld hl, ExtendedMoves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld b, MoveEnd - Moves
.copy
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy
	pop hl
	pop bc
	and a
	ret
.invalid
	scf
	ret

; HL = full 16-bit move ID, DE = destination text buffer.
; Copies the @-terminated name; never uses the legacy MoveNames index.
; MOVE-5.62.169: prepare full ID inside the far-called bank, not before
; callba (which uses HL for its routine target). The caller receives wcd6d.
LoadExperimentalPowerWhipNameToCD6D::
	ld hl, EXT_MOVE_POWER_WHIP
	ld de, wcd6d
	jp CopyExtendedMoveName

; MOVE-5.62.169: direct name reader for the second full move ID.
; Sidecar slot identity, not the old $ff escape, distinguishes Play Rough.
LoadExperimentalPlayRoughNameToCD6D::
	ld hl, EXT_MOVE_PLAY_ROUGH
	ld de, wcd6d
	jp CopyExtendedMoveName

CopyExtendedMoveName::
	ld a, h
	cp HIGH(EXT_MOVE_POWER_WHIP)
	jr nz, .invalid
	ld a, l
	cp NUM_EXTENDED_MOVES
	jr nc, .invalid
	push bc
	push hl
	add a
	ld c, a
	ld b, 0
	ld hl, ExtendedMoveNamePointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
.copy
	ld a, [hli]
	ld [de], a
	inc de
	cp "@"
	jr nz, .copy
	pop hl
	pop bc
	and a
	ret
.invalid
	scf
	ret

; MOVE-5.62.169: called from the usual FinalizeCurrentMoveLoad only.
; Overlay second-table combat data after the stock accessor safely loaded
; VINE_WHIP rather than indexing Moves with the reserved $FF escape.
MaybeLoadExperimentalMoveBattleStats::
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .legacy
	ld a, [wExtendedActiveMoveOrdinal]
	and a
	jr z, .legacy
	ld c, a
	ld a, [wPlayerSelectedMove]
	cp c ; a scoped ext selected-slot ID, not just matching low bytes
	jr nz, .legacy
	dec c
	ld l, c
	ld h, HIGH(EXT_MOVE_POWER_WHIP)
	ld de, wPlayerMoveNum
	jp CopyExtendedMoveStats
.legacy
	call GetCurrentMoveID
	cp EXT_MOVE_SLOT_ESCAPE
	ret nz
	ld a, [H_WHOSETURN]
	and a
	ld de, wPlayerMoveNum
	jr z, .player
	ld de, wEnemyMoveNum
.player
	ld hl, EXT_MOVE_POWER_WHIP
	jp CopyExtendedMoveStats
