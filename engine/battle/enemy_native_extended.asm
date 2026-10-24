; MOVE-5.62.189: enemy native source -> full four-slot battle identities.
; No source entries are enabled by default. Add explicit wild/trainer entries
; only when final encounter content is assigned. An unlisted opponent retains
; its legacy moves and the zero enemy-side mask set by LoadEnemyMonData.
;
; Wild entry (7 bytes): species, form, mask(bits 0..3), four move low bytes.
; Trainer entry (8 bytes): class, trainer number, zero-based party position,
;                         mask(bits 0..3), four move low bytes.
; Each marked slot MUST hold ordinal 1..NUM_EXTENDED_MOVES; unmarked slots
; are ordinary identities, even when the low byte is identical. No 0/$ff
; marked slots. Keep identical keys unique. Neither Party nor SRAM is edited.
SECTION "Enemy Native Full Move Sources", ROMX

ApplyNativeEnemyMoveSource::
	; A successful Transform owns its own temporary copied identity; do not
	; reinterpret the copied four slots via a native source.
	ld a, [wEnemyBattleStatus3]
	bit Transformed, a
	ret nz
	ld a, [wIsInBattle]
	cp 2
	jr z, .trainer
	cp 1
	ret nz
.wild
	ld hl, WildNativeExtendedMoveSources
.wildLoop
	ld a, [hli]
	cp $ff
	ret z
	ld b, a
	ld a, [wEnemyMonSpecies2]
	cp b
	jr nz, .skipWild
	ld a, [hli]
	ld b, a
	ld a, [wEnemyMonForm]
	cp b
	jr z, .apply
	ld bc, 5 ; mask and four move bytes
	add hl, bc
	jr .wildLoop
.skipWild
	ld bc, 6 ; form, mask, four move bytes
	add hl, bc
	jr .wildLoop
.trainer
	ld hl, TrainerNativeExtendedMoveSources
.trainerLoop
	ld a, [hli]
	cp $ff
	ret z
	ld b, a
	ld a, [wTrainerClass]
	cp b
	jr nz, .skipTrainer
	ld a, [hli]
	ld b, a
	ld a, [wTrainerNo]
	cp b
	jr nz, .skipTrainerTail2
	ld a, [hli]
	ld b, a
	ld a, [wWhichPokemon]
	cp b
	jr z, .apply
	ld bc, 5 ; mask and four move bytes
	add hl, bc
	jr .trainerLoop
.skipTrainerTail2
	ld bc, 6 ; party slot, mask, four bytes
	add hl, bc
	jr .trainerLoop
.skipTrainer
	ld bc, 7 ; trainer no, party slot, mask, four bytes
	add hl, bc
	jr .trainerLoop
.apply
	; HL points to the matching record's mask, followed by 4 bytes.
	; The enemy battle mask is high nibble; preserve player low nibble.
	ld a, [hli]
	and $0f
	swap a
	ld b, a
	ld a, [wExtendedBattleMoveFlags]
	and $0f
	or b
	ld [wExtendedBattleMoveFlags], a
	ld de, wEnemyMonMoves
	ld bc, NUM_MOVES
	jp CopyData

; Stock LoadMovePPs is intentionally unchanged for all other callers.
; We only repair native enemy flagged slots from their validated ordinal.
LoadNativeEnemyExtendedMovePP::
	ld a, [wExtendedBattleMoveFlags]
	swap a
	and $0f
	ret z
	ld b, a ; enemy four-bit mask
	ld c, 0 ; zero-based slot
.loop
	bit 0, b
	jr z, .next
	push bc
	ld e, c
	ld d, 0
	ld hl, wEnemyMonMoves
	add hl, de
	ld e, [hl]
	ld a, e
	and a
	jr z, .skipSlot
	cp NUM_EXTENDED_MOVES + 1
	jr nc, .skipSlot
	; CALLBA overwrites BC via Bankswitch. Preserve the slot index
	; before reading it again to write this PP byte.
	push bc
	callba LoadExtendedMoveStatsByOrdinalToCD6D
	pop bc
	ld a, [wcd6d + 5]
	ld hl, wEnemyMonPP
	ld e, c
	ld d, 0
	add hl, de
	ld [hl], a
.skipSlot
	pop bc
.next
	srl b
	inc c
	ld a, c
	cp NUM_MOVES
	jr nz, .loop
	ret

; Production tables are intentionally empty until real move sources are designed.
; Test-only Rattata and Route 8 Super Nerd assignments were removed
; during MOVE-5.62.189 acceptance cleanup.
WildNativeExtendedMoveSources::
	db $ff
TrainerNativeExtendedMoveSources::
	db $ff
