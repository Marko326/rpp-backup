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
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	ld de, wcd6d
	jp CopyStringToCF4B

; Metronome / Mirror Move / Mimic reload an already-selected child move. Their
; historical return contract is NZ on success, so preserve it here.
FinalizeReloadedMoveData::
	call ApplyCurrentMovePrimaryTypeOverride
	call GetMoveName
	call CopyStringToCF4B
	ld a, $1
	and a
	ret
