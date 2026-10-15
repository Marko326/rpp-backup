; EGG-A4-5.61.75: runtime move types that inherit the acting Pokemon's first type.
; Keep the policy table-driven so another move can opt in with one data byte.

ApplyCurrentMovePrimaryTypeOverride::
	call GetCurrentMoveID
	call IsPrimaryTypeMove
	ret nc
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wBattleMonType1]
	ld [wPlayerMoveType], a
	ret
.enemy
	ld a, [wEnemyMonType1]
	ld [wEnemyMoveType], a
	ret

; Input: C = enemy AI candidate real move ID (callba does not preserve A).
ApplyEnemyCandidatePrimaryTypeOverride::
	; MOVE-5.62.155: evaluate mapped Bite as BUG for enemy AI.
	ld a, c
	cp BITE
	jr nz, .primaryType
	push bc ; IsInArray overwrites B/C, including the candidate move ID.
	ld a, [wEnemyMonSpecies]
	call IsBugBiteSpecies
	pop bc
	jr nc, .primaryType
	ld a, BUG
	ld [wEnemyMoveType], a
	xor a
	ld [wEnemyMoveEffect], a
	ret
.primaryType
	ld a, c
	call IsPrimaryTypeMove
	ret nc
	ld a, [wEnemyMonType1]
	ld [wEnemyMoveType], a
	ret

IsPrimaryTypeMove:
	ld hl, PrimaryTypeMoveIDs
	ld de, 1
	jp IsInArray

PrimaryTypeMoveIDs:
	db EGG_BOMB
	db $ff

; GetCurrentMove loads a real selected move into the side-specific six-byte move
; buffer, then tail-calls here. Keep its original name-loading behavior intact.
FinalizeCurrentMoveLoad::
	call ApplyCurrentMovePrimaryTypeOverride
	call ApplyCurrentBugBiteOverride
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	call GetCurrentBattleMoveNamePointer
	jp CopyStringToCF4B

; Metronome / Mirror Move / Mimic reload an already-selected child move. Their
; historical return contract is NZ on success, so preserve it here.
FinalizeReloadedMoveData::
	call ApplyCurrentMovePrimaryTypeOverride
	call ApplyCurrentBugBiteOverride
	call GetMoveName
	call GetCurrentBattleMoveNamePointer
	call CopyStringToCF4B
	ld a, $1
	and a
	ret

; MOVE-5.62.155: battle-only reinterpretation of real BITE ($2C).
; The six-byte current move buffer is temporary; stored IDs, PP, animation,
; and the global Bite move record remain unchanged.
ApplyCurrentBugBiteOverride:
	call GetCurrentMoveID
	cp BITE
	ret nz
	call GetActingBattleSpecies
	call IsBugBiteSpecies
	ret nc
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, BUG
	ld [wPlayerMoveType], a
	xor a ; NO_ADDITIONAL_EFFECT
	ld [wPlayerMoveEffect], a
	ret
.enemy
	ld a, BUG
	ld [wEnemyMoveType], a
	xor a
	ld [wEnemyMoveEffect], a
	ret

; Input: none; output A=the currently acting species. Transform already
; updates the runtime species, so copied moves follow the current user.
GetActingBattleSpecies:
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wBattleMonSpecies]
	ret
.enemy
	ld a, [wEnemyMonSpecies]
	ret

; Carry set for species authorized to reinterpret BITE during battle.
; Keep this explicit so unrelated Bug-types are not silently affected.
IsBugBiteSpecies:
	ld hl, BugBiteSpeciesIDs
	ld de, 1
	jp IsInArray

BugBiteSpeciesIDs:
	db CATERPIE, METAPOD, BUTTERFREE
	db WEEDLE, KAKUNA, BEEDRILL
	db PARAS, PARASECT
	db $ff

; Call only after the original GetName/GetMoveName has filled wcd6d.
; This never changes the global move name or out-of-battle screens.
GetCurrentBattleMoveNamePointer:
	call GetCurrentMoveID
	cp BITE
	jr nz, .normal
	call GetActingBattleSpecies
	call IsBugBiteSpecies
	jr nc, .normal
	ld de, BugBiteBattleName
	ret
.normal
	ld de, wcd6d ; IsInArray overwrites DE, so set it last.
	ret

BugBiteBattleName:
	db "Bug Bite@"

; Only the regular in-battle Fight menu calls this entry. Mimic, relearn,
; Party/PC, and all other FormatMovesString callers stay stock.
FormatBugBiteBattleMovesString::
	ld hl, wMoves
	ld de, wMovesString
	ld b, 0
.moveLoop
	ld a, [hli]
	and a
	jr z, .dashLoop
	push hl
	cp BITE
	jr nz, .normalMove
	push bc
	push de ; IsInArray uses DE as its stride and B/C as scratch.
	ld a, [wBattleMonSpecies]
	call IsBugBiteSpecies
	pop de
	pop bc
	jr nc, .ordinaryBite
	ld hl, BugBiteBattleName
	jr .copyName
.ordinaryBite
	ld a, BITE
.normalMove
	ld [wd0b5], a
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	ld hl, wcd6d
.copyName
	ld a, [hli]
	cp "@"
	jr z, .endName
	ld [de], a
	inc de
	jr .copyName
.endName
	ld a, b
	ld [wNumMovesMinusOne], a
	inc b
	ld a, $4e ; line break
	ld [de], a
	inc de
	pop hl
	ld a, b
	cp NUM_MOVES
	jr z, .done
	jr .moveLoop
.dashLoop
	ld a, "-"
	ld [de], a
	inc de
	inc b
	ld a, b
	cp NUM_MOVES
	jr z, .done
	ld a, $4e
	ld [de], a
	inc de
	jr .dashLoop
.done
	ld a, "@"
	ld [de], a
	ret
