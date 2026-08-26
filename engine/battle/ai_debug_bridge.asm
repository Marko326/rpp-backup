; AI debug execution bridge.
; Moved out of bankF because battle core is at the ROMX bank limit.
; Debug infrastructure only; no AI strategy lives here.

AIDebugPrintLockedEnemyAction::
	; Debug is strictly limited to the dedicated trainer test fixture.
	ld a, [wIsInBattle]
	cp 2
	ret nz
	ld a, [wTrainerClass]
	cp BUG_CATCHER
	ret nz
	ld a, [wTrainerNo]
	cp 4
	ret nz

	; wAIActionPreselected = 1 means the decision is locked but has not reached
	; its execution point yet. Once shown, set it to 2 so a later faint is not
	; incorrectly reported as "cancelled before execution".
	ld a, [wAIPlannedSwitchTarget]
	inc a
	jr z, .move
	callab AIDebugPrintSwitchDecision
	jr .shown
.move
	ld a, [wEnemySelectedMove]
	inc a
	ret z ; no executable enemy move this turn
	callab AIDebugPrintSelectedMove
.shown
	ld a, 2
	ld [wAIActionPreselected], a
	ret
