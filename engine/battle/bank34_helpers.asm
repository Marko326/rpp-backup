; Relocatable battle helpers moved out of capacity-constrained Bank F.
; Their public labels stay unchanged; Bank F callers use callab.
; Each public routine commits its useful result to WRAM/VRAM before returning,
; because the existing far-call wrapper restores the ROM bank through A/B/C/HL.

; Update base power for moves whose power depends on the current battle state.
; Hex: 65 normally, 130 if the target has a major status condition.
; Electro Ball: 120/80/60 based on the existing player/enemy Speed comparison.
; Output is written directly to wPlayerMovePower/wEnemyMovePower, so no return
; register needs to survive the bank switch.
UpdateVariableMovePower:
	ld a, [H_WHOSETURN]
	and a
	jr z, .playerTurn
; Enemy's turn: target the player and update the enemy move power.
	ld a, [wEnemySelectedMove]
	ld de, wBattleMonStatus
	ld hl, wEnemyMovePower
	jr .checkMove
.playerTurn
	ld a, [wPlayerSelectedMove]
	ld de, wEnemyMonStatus
	ld hl, wPlayerMovePower
.checkMove
	cp HEX
	jr z, .hex
	cp ELECTRO_BALL
	ret nz

; Preserve the selected move-power address while StringCmp advances HL/DE.
	push hl
	ld de, wBattleMonSpeed ; player speed value
	ld hl, wEnemyMonSpeed ; enemy speed value
	ld c, $2
	call StringCmp ; compare speed values
	pop hl ; POP does not alter the comparison flags
	ld a, 80
	jr z, .store
	jr nc, .playerFaster
; Enemy is faster: player gets 60 BP, enemy gets 120 BP.
	ld a, [H_WHOSETURN]
	and a
	ld a, 60
	jr z, .store
	add a
	jr .store
.playerFaster
; Player is faster: player gets 120 BP, enemy gets 60 BP.
	ld a, [H_WHOSETURN]
	and a
	ld a, 60
	jr nz, .store
	add a
	jr .store

.hex
	ld a, [de]
	and a
	ld a, 65
	jr z, .store
	add a ; 130 BP if the target is statused
.store
	ld [hl], a
	ret

PrintEnemyMonGender: ; called during battle
	ld a, [wEnemyMonSpecies]
	ld de, wEnemyMonDVs
	call PrintGenderCommon
	coord hl, 9, 1
	ld [hl], a
	ret

PrintPlayerMonGender: ; called during battle
	ld a, [wBattleMonSpecies]
	ld de, wBattleMonDVs
	call PrintGenderCommon
	coord hl, 17, 8
	ld [hl], a
	ret

PrintGenderCommon:
	ld [wGenderTemp], a
	callba GetMonGender
	ld a, [wGenderTemp]
	and a
	jr z, .noGender
	dec a
	jr z, .male
	ld a, "♀"
	ret
.male
	ld a, "♂"
	ret
.noGender
	ld a, " "
	ret

PrintEnemyMonShiny: ; show shiny symbol beside gender symbol
	ld de, wEnemyMonDVs
	call PrintShinyCommon
	coord hl, 10, 1
	ld [hl], a
	ret

PrintPlayerMonShiny: ; show shiny symbol beside gender symbol
	ld de, wBattleMonDVs
	call PrintShinyCommon
	coord hl, 18, 8
	ld [hl], a
	ret

PrintShinyCommon:
	callba IsMonShiny
	ld a, "[SHINY]"
	ret nz
	ld a, " "
	ret

; THRASH-5.19.18: failed Thrash/Petal Dance/Outrage attempts end the lock early.
; PrintMoveFailureText is shared by the player/enemy miss paths, so keep the
; duplicated status cleanup here rather than spending scarce Bank F space twice.
StopThrashingAfterFailedMove:
	ld hl, wPlayerBattleStatus1
	ldh a, [H_WHOSETURN]
	and a
	jr z, .clear
	ld hl, wEnemyBattleStatus1
.clear
	res ThrashingAbout, [hl]
	ret

; MIRROR-5.19.19: called through the existing tail bank-switch at battle init,
; so Bank $14 does not grow beyond its four-byte slack.
InitMirrorMoveMemoryAndPlayBattleMusic:
	xor a
	ld [wPlayerLastSelectedMove], a
	ld [wEnemyLastSelectedMove], a
	callab PlayBattleMusic
	ret

; Clear the copied-move damage marker for the acting side. Used when a
; move-calling effect (currently Metronome/Mimic) starts a second call layer,
; because only the move copied directly by Mirror Move is boosted.
ClearMirrorMoveBoost:
	push hl
	ld hl, wPlayerBattleStatus3
	ldh a, [H_WHOSETURN]
	and a
	jr z, .clear
	ld hl, wEnemyBattleStatus3
.clear
	res MirrorMoveBoost, [hl]
	pop hl
	ret

; PureRGB-style Mirror Move memory/transition, without PureRGB's priority change.
; The memory stores the last move that reached executable selection after status
; gating and is intentionally not cleared when a battler switches or cannot act.
; On success, play Mirror Move's transition before reloading the copied move.
MirrorMoveCopyMove_:
	ldh a, [H_WHOSETURN]
	and a
	ld a, [wEnemyLastSelectedMove]
	ld hl, wPlayerSelectedMove
	ld de, wPlayerMoveNum
	jr z, .gotRememberedMove
	ld a, [wPlayerLastSelectedMove]
	ld hl, wEnemySelectedMove
	ld de, wEnemyMoveNum
.gotRememberedMove
	cp MIRROR_MOVE
	jr z, .failed
	and a
	jr z, .failed

	; PureRGB transition: temporarily expose Mirror Move as the real selected
	; move so RPP's animation preparer stages Mirror Move rather than the copy.
	push af
	ld [hl], MIRROR_MOVE
	push hl
	push de
	callab PlayCurrentMoveAnimation
	pop de
	pop hl
	pop af
	ld [hl], a

	; The direct copied move may receive the non-STAB 1.2x damage adjustment.
	push af
	ld hl, wPlayerBattleStatus3
	ldh a, [H_WHOSETURN]
	and a
	jr z, .markBoost
	ld hl, wEnemyBattleStatus3
.markBoost
	set MirrorMoveBoost, [hl]
	pop af

	; ReloadMoveData lives in Bank F. Reproduce its small body here instead of
	; passing the move ID through Bankswitch, which overwrites A with the bank ID.
	ld [wd11e], a
	dec a
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld a, BANK(Moves)
	call FarCopyData
	callab IncrementMovePP
	call GetMoveName
	call CopyStringToCF4B
	ld a, $1
	and a
	ret

.failed
	ld hl, MirrorMoveFailedText
	call PrintText
	xor a
	ret

MirrorMoveFailedText:
	TX_FAR _MirrorMoveFailedText
	db "@"

; MIRROR-5.19.21: finish SelectEnemyMove's write in roomy bank $34.
; In Link Battle the remote side transmits only its move-slot index. During an
; automatic continuation that slot still names the root caller (for example
; Mirror Move/Metronome), while wEnemySelectedMove already holds the actual
; child move (for example Fly). Preserve that child and MirrorMoveBoost only
; when the battler truly bypassed MoveSelectionMenu. Status gating such as
; sleep/freeze happens after a fresh choice and therefore must not preserve it.
FinalizeEnemyMoveSelectionForMirrorMove:
	ld a, [wd11e]
	inc a ; CANNOT_MOVE / $ff is not a fresh selection
	jr z, .storeWithoutClearing

	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr nz, .freshSelection

	ld a, [wEnemyBattleStatus2]
	and (1 << NeedsToRecharge) | (1 << UsingRage)
	ret nz
	ld a, [wEnemyBattleStatus1]
	and (1 << ChargingUp) | (1 << ThrashingAbout) | (1 << UsingTrappingMove) | (1 << StoringEnergy)
	ret nz
	ld a, [wPlayerBattleStatus1]
	bit UsingTrappingMove, a
	ret nz

.freshSelection
	ld hl, wEnemyBattleStatus3
	res MirrorMoveBoost, [hl]
.storeWithoutClearing
	ld a, [wd11e]
	ld [wEnemySelectedMove], a
	ret
