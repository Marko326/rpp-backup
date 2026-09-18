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
