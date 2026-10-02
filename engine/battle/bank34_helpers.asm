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
	; EGG-A4-5.61.75: copied Egg Bomb inherits the acting mon's primary type too.
	jpba FinalizeReloadedMoveData

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

; ---------------------------------------------------------------------------
; BATTLE-5.61.18 - later-generation Fly / Dig move interactions
; ---------------------------------------------------------------------------
; Called only after the target's Invulnerable bit is known to be set.  The
; target's selected move identifies which semi-invulnerable state is active:
; Fly or Dig are the only moves that currently set that bit in this project.
;
; Return carry set when the current attacking move may hit this state; carry
; clear means the legacy invulnerability miss remains in force.  Bankswitch does
; not alter carry, so this survives callab without consuming a WRAM scratch byte.
; A table flag separately requests 2x already-calculated damage before the normal
; accuracy test.
;
; This table is intentionally identity-based instead of effect-based. Expanded
; moves may reuse legacy animation/effect bytes, so GetCurrentMoveID and the real
; selected move IDs are required for safe future extension.
DEF SEMI_INVUL_DOUBLE_DAMAGE EQU 1 << 0

GetSemiInvulnerableMoveInteraction::
	ldh a,[H_WHOSETURN]
	and a
	ld a,[wEnemySelectedMove]
	jr z,.gotTargetMove
	; During automated test battles the player-side current selection lives in
	; the dedicated test slot, matching GetCurrentMove/GetCurrentMoveID.
	ld a,[wFlags_D733]
	bit BIT_TEST_BATTLE,a
	ld a,[wTestBattlePlayerSelectedMove]
	jr nz,.gotTargetMove
	ld a,[wPlayerSelectedMove]
.gotTargetMove
	ld b,a                           ; target's active Fly / Dig move ID
	call GetCurrentMoveID
	ld c,a                           ; real attacking move ID
	ld hl,SemiInvulnerableMoveInteractions
.loop
	ld a,[hli]                       ; target semi-invulnerable move
	and a
	jr z,.noInteraction
	cp b
	jr nz,.skipAttackAndFlags
	ld a,[hli]                       ; attacking move
	cp c
	jr nz,.skipFlags
	ld a,[hl]                        ; flags
	bit 0,a
	call nz,DoubleSemiInvulnerableMoveDamage
	scf
	ret
.skipFlags
	inc hl                           ; flags
	jr .loop
.skipAttackAndFlags
	inc hl                           ; attacking move
	inc hl                           ; flags
	jr .loop
.noInteraction
	and a                            ; clear carry
	ret

; Double normal calculated damage with the same $ffff saturation used by
; Counter.  Fissure is deliberately not marked for this path.
DoubleSemiInvulnerableMoveDamage:
	ld hl,wDamage + 1
	ld a,[hl]
	add a
	ld [hld],a
	ld a,[hl]
	adc a
	ld [hl],a
	ret nc
	ld a,$ff
	ld [hli],a
	ld [hl],a
	ret

; target state, attacking move, flags
; Thunder / Hurricane are allowed to target Fly but keep their normal accuracy.
; Only Gust / Twister and Earthquake receive the later-generation 2x modifier.
SemiInvulnerableMoveInteractions:
	db DIG, EARTHQUAKE, SEMI_INVUL_DOUBLE_DAMAGE
	db DIG, FISSURE,    0
	db FLY, GUST,       SEMI_INVUL_DOUBLE_DAMAGE
	db FLY, TWISTER,    SEMI_INVUL_DOUBLE_DAMAGE
	db FLY, THUNDER,    0
	db FLY, HURRICANE,  0
	db 0

; ---------------------------------------------------------------------------
; BATTLE-5.61.20 - move-rule helpers relocated from capacity-constrained Bank F
; ---------------------------------------------------------------------------

; Preserve the original critical-hit rules while keeping the hot Bank-F path
; small. The only public result is wCriticalHitOrOHKO.
CriticalHitTest_:
	xor a
	ld [wCriticalHitOrOHKO], a
	ld a, [H_WHOSETURN]
	and a
	ld hl, wPlayerMovePower
	ld de, wPlayerBattleStatus2
	jr z, .calcCriticalHitProbability
	ld hl, wEnemyMovePower
	ld de, wEnemyBattleStatus2
.calcCriticalHitProbability
	ld a, [hld]
	and a
	ret z

	ld c, 0
	ld a, [de]
	bit 2, a
	jr z, .checkCritMove
	inc c
.checkCritMove
	ld hl, HighCriticalMoves
	ld a, [H_WHOSETURN]
	and a
	jr z, .playersTurn
	ld a, [wEnemySelectedMove]
	ld b, a
	jr .checkAlwaysCrit
.playersTurn
	ld a, [wPlayerSelectedMove]
	ld b, a
.checkAlwaysCrit
	cp ALWAYS_CRIT_MOVE_1
	jr z, .critSuccess
	cp ALWAYS_CRIT_MOVE_2
	jr z, .critSuccess
.loop
	ld a, [hli]
	cp b
	jr z, .highCritical
	inc a
	jr nz, .loop
	jr .skipHighCritical
.highCritical
	inc c
	inc c
.skipHighCritical
	; Preserve the existing A + Left critical-hit debug shortcut.
	ld a, [hJoyInput]
	cp a, $21
	jr nz, .calculate
	inc c
	inc c
.calculate
	ld hl, .chances
	ld b, 0
	add hl, bc
	push hl
	callab BattleRandomFar
	ld a, e
	pop hl
	cp [hl]
	ret nc
.critSuccess
	ld a, 1
	ld [wCriticalHitOrOHKO], a
	ret

.chances
	; 6.25% 12.1% 24.6% 33.2% 49.6% 49.6% 49.6%
	db $11, $20, $40, $55, $80, $80, $80

; Keep the data beside its only runtime consumer after relocation.
INCLUDE "data/high_crit_moves.asm"

; Seismic Toss / Night Shade use attacker level; SonicBoom and Dragon Rage use
; fixed damage; Psywave keeps the existing 1..floor(1.5*level)-1 random range.
; The acting side is resolved here so Bank F does not need a cross-bank pointer ABI.
CalculateSpecialMoveDamage_:
	ld hl, wBattleMonLevel
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotAttackerLevel
	ld hl, wEnemyMonLevel
.gotAttackerLevel
	ld a, [hl]
	ld c, a
	call GetCurrentMoveID
	cp SEISMIC_TOSS
	jr z, .levelDamage
	cp NIGHT_SHADE
	jr z, .levelDamage
	ld b, SONICBOOM_DAMAGE
	cp SONICBOOM
	jr z, .storeDamage
	ld b, DRAGON_RAGE_DAMAGE
	cp DRAGON_RAGE
	jr z, .storeDamage

	; Psywave
	ld b, c
	ld a, c
	srl a
	add b
	ld b, a
.randomLoop
	push bc
	callab BattleRandomFar
	ld a, e
	pop bc
	and a
	jr z, .randomLoop
	cp b
	jr nc, .randomLoop
	ld b, a
	jr .storeDamage

.levelDamage
	ld b, c
.storeDamage
	ld hl, wDamage
	xor a
	ld [hli], a
	ld a, b
	ld [hl], a
	ret
