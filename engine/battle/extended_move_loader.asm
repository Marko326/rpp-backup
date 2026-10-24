; MOVE-5.62.171: second-table 16-bit readers using NUM_EXTENDED_MOVES
; capacity experiment. The legacy $ff Power Whip escape remains for compatibility;
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

; MOVE-5.62.171: generic six-byte reader. E carries the one-based ordinal
; across CALLBA; the record is copied to wcd6d for PP/status callers.
LoadExtendedMoveStatsByOrdinalToCD6D::
	ld a, e
	cp 1
	jr c, .invalid
	cp NUM_EXTENDED_MOVES + 1
	jr nc, .invalid
	dec a
	ld l, a
	ld h, HIGH(EXT_MOVE_BASE_ID)
	ld de, wcd6d
	jp CopyExtendedMoveStats
.invalid
	scf
	ret

; HL = full 16-bit move ID, DE = destination text buffer.
; Copies the @-terminated name; never uses the legacy MoveNames index.
; MOVE-5.62.169: prepare full ID inside the far-called bank, not before
; callba (which uses HL for its routine target). The caller receives wcd6d.
; MOVE-5.62.171: generic name reader. E carries the one-based extended ordinal
; across CALLBA because Bankswitch owns A/BC/HL. The result is written to wcd6d.
LoadExtendedMoveNameByOrdinalToCD6D::
	ld a, e
	cp 1
	jr c, .invalid
	cp NUM_EXTENDED_MOVES + 1
	jr nc, .invalid
	dec a
	ld l, a
	ld h, HIGH(EXT_MOVE_BASE_ID)
	ld de, wcd6d
	jp CopyExtendedMoveName
.invalid
	scf
	ret

LoadExperimentalPowerWhipNameToCD6D::
	ld e, EXT_MOVE_LOW_POWER_WHIP
	jr LoadExtendedMoveNameByOrdinalToCD6D

LoadExperimentalPlayRoughNameToCD6D::
	ld e, EXT_MOVE_LOW_PLAY_ROUGH
	jr LoadExtendedMoveNameByOrdinalToCD6D

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

; MOVE-5.62.182B: current-move finalizer has already resolved
; the acting side's matching slot and full identity. Overlay the second
; table for either side. A forced/derived ordinary move has ordinal zero.
MaybeLoadExperimentalMoveBattleStats::
	ld a, [wExtendedActiveMoveOrdinal]
	and a
	jr z, .legacy
	ld c, a
	ldh a, [H_WHOSETURN]
	and a
	ld de, wPlayerMoveNum
	jr z, .selected
	ld de, wEnemyMoveNum
.selected
	dec c
	ld l, c
	ld h, HIGH(EXT_MOVE_POWER_WHIP)
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
