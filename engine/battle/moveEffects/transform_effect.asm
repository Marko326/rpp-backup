; Automatic entry passes E=0 for player, E=1 for enemy (Bankswitch
; overwrites A). Preserve the caller's turn: an entry effect is not a move.
ImposterTransformEffect_:
	ld a, [H_WHOSETURN]
	push af
	ld a, e
	ld [H_WHOSETURN], a
	ld hl, wImposterEntryFlags
	set 1, [hl]
	call TransformEffect_
	ld hl, wImposterEntryFlags
	res 1, [hl]
	pop af
	ld [H_WHOSETURN], a
	ret

TransformEffect_:
	ld hl, wBattleMonSpecies
	ld de, wEnemyMonSpecies
	ld bc, wEnemyBattleStatus3
	ld a, [H_WHOSETURN]
	and a
	jr z, .playerUser
	; BTL-5.62.19: enemy user targets the player, so the Fly/Dig test must
	; inspect the player's BattleStatus1 instead of the turn selector itself.
	ld a, [wPlayerBattleStatus1]
	jr .hitTest
.playerUser
	ld hl, wEnemyMonSpecies
	ld de, wBattleMonSpecies
	ld bc, wPlayerBattleStatus3
	ld [wPlayerMoveListIndex], a
	; Player user targets the enemy; preserve the target's BattleStatus1 for the
	; Invulnerable test after the Transform identity checks.
	ld a, [wEnemyBattleStatus1]
.hitTest
	; TRN-5.62.18: reject a second Transform before any animation/data copy, and
	; reject an already-identical Species + runtime form. Same Species with a
	; different regional form is still a meaningful Transform and remains allowed.
	push af
	ld a, [bc]
	bit Transformed, a
	jr nz, .identityFailed
	call .sameSpeciesAndForm
	jr nz, .differentIdentity
.identityFailed
	pop af
	jp .failed
.differentIdentity
	pop af
	bit Invulnerable, a ; is mon invulnerable to typical attacks? (fly/dig)
	jp nz, .failed
	push hl
	push de
	push bc
	; TRN-5.62.18: all failure conditions have passed. Cache the user's exact
	; pre-transform palette before the animation changes Species/Form. A short-lived
	; staging bit makes palette reloads during the animation use this cache without
	; changing the stock timing of the battle-status Transformed flag.
	callba CacheTransformUserPalette
	ld hl, wPlayerBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jr z, .transformEffect
	ld hl, wEnemyBattleStatus2
.transformEffect
; animation(s) played are different if target has Substitute up
	bit HasSubstituteUp, [hl]
	push af
	ld hl, HideSubstituteShowMonAnim
	ld b, BANK(HideSubstituteShowMonAnim)
	call nz, Bankswitch
	; Entry-only Transform has no selected move. Play the actual stock
	; Transform animation by its ID, without editing MoveNum or costing a turn.
	; The stock TransformAnim already runs SE_TRANSFORM_MON at its end, so
	; do NOT redraw the species a second time after the animation.
	ld a, [wImposterEntryFlags]
	bit 1, a
	jr z, .manualTransformAnimation
	ld a, [wOptions]
	add a
	jr c, .directTransformRedraw
	; A send-out can interrupt a turn already holding an animation ID/type.
	; Save both in the helper so that a switch does not change that move.
	callba PlayImposterTransformAnimation
	jr .animationComplete
.manualTransformAnimation
	ld a, [wOptions]
	add a
	jr c, .directTransformRedraw
	ld hl, PlayCurrentMoveAnimation
	ld b, BANK(PlayCurrentMoveAnimation)
	jr .gotAnimToPlay
.directTransformRedraw
	ld hl, AnimationTransformMon
	ld b, BANK(AnimationTransformMon)
.gotAnimToPlay
	call Bankswitch
.animationComplete
	ld hl, ReshowSubstituteAnim
	ld b, BANK(ReshowSubstituteAnim)
	pop af
	call nz, Bankswitch
	pop bc
	ld a, [bc]
	set Transformed, a ; mon is now Transformed
	ld [bc], a
	; The permanent battle-status bit now owns palette restoration.
	callba ClearTransformPaletteStaging
	pop de
	pop hl
	push hl
; transform user into opposing Pokemon
; species
	ld a, [hl]
	ld [de], a
; type 1, type 2, catch rate, and moves
	ld bc, $5
	add hl, bc
	inc de
	inc de
	inc de
	inc de
	inc de
	inc bc
	inc bc
	call CopyData
	; MOVE-5.62.184: the four copied move bytes must travel together
	; with their slot identity bits. The banked helper updates only the
	; acting side's nibble. Preserve the CopyData source/destination
	; pointers: the following DV copy still depends on both.
	push hl
	push de
	callba CopyTransformBattleMoveMask
	pop de
	pop hl
	ld a, [H_WHOSETURN]
	and a
	jr nz, .saveEnemyDVs
	jr .next
.saveEnemyDVs
; save enemy mon DVs at wTransformedEnemyMonOriginalDVs
	ld a, [de]
	ld [wTransformedEnemyMonOriginalDVs], a
	inc de
	ld a, [de]
	ld [wTransformedEnemyMonOriginalDVs + 1], a
	dec de
.next
; DVs
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
; Attack, Defense, Speed, and Special stats
	inc hl
	inc hl
	inc hl
	inc de
	inc de
	inc de
	ld bc, $8
	call CopyData
	ld bc, wBattleMonMoves - wBattleMonPP
	add hl, bc ; ld hl, wBattleMonMoves
	ld b, NUM_MOVES
.copyPPLoop
; 5 PP for all moves
	ld a, [hli]
	and a
	jr z, .lessThanFourMoves
	ld a, $5
	ld [de], a
	inc de
	dec b
	jr nz, .copyPPLoop
	jr .copyStats
.lessThanFourMoves
; 0 PP for blank moves
	xor a
	ld [de], a
	inc de
	dec b
	jr nz, .lessThanFourMoves
.copyStats
; original (unmodified) stats and stat mods
	pop hl
	ld a, [hl]
	ld [wd11e], a
	call GetMonName
	ld hl, wEnemyMonUnmodifiedAttack
	ld de, wPlayerMonUnmodifiedAttack
	call .copyBasedOnTurn ; original (unmodified) stats
	ld hl, wEnemyMonStatMods
	ld de, wPlayerMonStatMods
	call .copyBasedOnTurn ; stat mods
	ld hl, TransformedText
	call PrintText
	scf ; the manual move wrapper needs an unambiguous success result
	ret

.sameSpeciesAndForm
; Return Z only when both active battle slots have the same Species and runtime
; regional form. Preserve the Transform copy pointers used by the caller.
	push bc
	push de
	push hl
	ld a, [wEnemyMonSpecies]
	ld d, a
	ld a, [wBattleMonSpecies]
	cp d
	jr nz, .identityCompared
	ld e, 0 ; player battle slot
	callba RegionalFormGetBattleSlotFormIdentity
	ld a, d
	push af
	ld e, 1 ; enemy battle slot
	callba RegionalFormGetBattleSlotFormIdentity
	ld e, d
	pop af
	cp e
.identityCompared
	pop hl
	pop de
	pop bc
	ret

.copyBasedOnTurn
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotStatsOrModsToCopy
	push hl
	ld h, d
	ld l, e
	pop de
.gotStatsOrModsToCopy
	ld bc, $8
	jp CopyData

.failed
	ld a, [wImposterEntryFlags]
	bit 1, a
	jr z, .showFailure
	and a ; silent entry failure returns with carry clear
	ret ; a failed entry effect must not print a move-failure message
.showFailure
	; BTL-5.62.19: ResidualEffects1 skips the common post-move pause. Match
	; other direct-failure effects so the move-use text remains readable first.
	ld c, 50
	call DelayFrames
	callab PrintButItFailedText_
	and a ; failed manual Transform must not enter the copied-move continuation
	ret

TransformedText:
	TX_FAR _TransformedText
	db "@"

; TRF-5.62.208: a successful direct Transform can immediately execute one of
; the copied moves as the same action. Return the Bank-F continuation in HL,
; matching MimicEffect_'s existing stack contract. Entry-only Imposter calls
; TransformEffect_ directly and never enters this follow-up gateway.
TransformMoveFollowup_::
	call TransformEffect_
	jp nc, .failed
	ld a, [H_WHOSETURN]
	and a
	jp nz, .enemyTurn
	; Only a direct Transform action gets a follow-up. Mirror Move / Metronome
	; keep their own root-action semantics instead of recursively adding an action.
IF DEF(BATTLE_TEST_BUILD)
	ld a, [wFlags_D733]
	bit BIT_TEST_BATTLE, a
	jr z, .playerRootFromHistory
	ld a, [wTestBattlePlayerSelectedMove]
	jr .playerRootReady
.playerRootFromHistory
ENDC
	ld a, [wPlayerLastSelectedMove]
.playerRootReady
	cp TRANSFORM
	jp nz, .playerDone
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jp z, .chooseRandomCopiedMove ; Link exchanges one slot only, as Mimic does
	; Use the ordinary four-move menu after the copied list and 5 PP are ready.
	; TRF-208 display fix: round-start backup can show an airborne (hidden)
	; opponent even after it landed earlier in this round.  The follow-up
	; menu restores that backup on exit, incorrectly erasing its live sprite.
	; Refresh it now, after Transform animation, before opening that menu.
	call SaveScreenTilesToBuffer1
	; Use regular battle move selection with B suppressed (mode 3).
	; A must confirm the copied move; B cannot consume the follow-up.
	ld a, 3
	ld [wMoveMenuType], a
	ld a, 1
	ld [wAnimationID], a
	callab MoveSelectionMenu
	call LoadScreenTilesFromBuffer1
	callab DrawHUDsAndHPBars
IF DEF(BATTLE_TEST_BUILD)
	; GetCurrentMove intentionally reads this override in the test ROM.
	ld a, [wFlags_D733]
	bit BIT_TEST_BATTLE, a
	jr z, .loadPlayerFollowup
	; The test menu omits the ordinary cursor preview; read the chosen slot
	; explicitly (only A confirms; B is not a watched key).
	ld hl, wBattleMonMoves
	ld b, NUM_MOVES
	xor a
.scanTestCopiedMoves
	or [hl]
	inc hl
	dec b
	jr nz, .scanTestCopiedMoves
	and a
	jr nz, .testCopiedMovesExist
	ld a, STRUGGLE
	ld [wPlayerSelectedMove], a
	jr .saveTestFollowupMove
.testCopiedMovesExist
	ld a, [wPlayerMoveListIndex]
	ld c, a
	ld b, 0
	ld hl, wBattleMonMoves
	add hl, bc
	ld a, [hl]
	ld [wPlayerSelectedMove], a
.saveTestFollowupMove
	ld a, [wPlayerSelectedMove]
	ld [wTestBattlePlayerSelectedMove], a
ENDC
.loadPlayerFollowup
	callab GetCurrentMove
	ld hl, CheckIfPlayerNeedsToChargeUp
	ret
.enemyTurn
	ld a, [wEnemyLastSelectedMove]
	cp TRANSFORM
	jp nz, .enemyDone
.chooseRandomCopiedMove
	; Enemies and Link battles cannot open the local player's follow-up menu.
	; TEST-214 fixes slot 1 only for controlled enemy-mirror cases. Official
	; ROM and all other test cases retain Mimic's non-empty-slot PRNG rule.
IF DEF(BATTLE_TEST_BUILD)
	ld a, [wTestSuiteGuard]
	cp $5a
	jr nz, .randomCopiedSlot
	ld a, [wTestSuitePhase]
	cp $41 ; E-LATE-FLY: copied player slot 1 is Fly
	jr z, .fixedEnemySlot
	cp $43 ; E-LATE-DIG: copied player slot 1 is Dig
	jr z, .fixedEnemySlot
	cp $45 ; E-LATE-EXT: copied player slot 1 is EXT01 Power Whip
	jr z, .fixedEnemySlot
	cp $47 ; E-LATE-KO: copied player slot 1 is Swift
	jr z, .fixedEnemySlot
	cp $49 ; E-LATE-SUB: copied player slot 1 is Tackle
	jr z, .fixedEnemySlot
	cp $4e ; E-CHARGE baseline: copied player slot 1 is Fly
	jr nz, .randomCopiedSlot
.fixedEnemySlot
	ld a, [H_WHOSETURN]
	and a
	jr z, .randomCopiedSlot
	ld a, [wEnemyMonMoves + 1]
	and a
	jr z, .randomCopiedSlot ; malformed fixture -> native fallback
	ld bc, $0401 ; four candidate moves; index 1 is selected
	push bc ; .copiedMoveFound consumes one saved BC
	jp .copiedMoveFound
.randomCopiedSlot
ENDC
	; Pick a non-empty copied slot with the same far-PRNG convention as Mimic.
	callab BattleRandomFar
	ld a, e
	and 3
	ld c, a
	ld b, NUM_MOVES
.scanCopiedMove
	push bc
	ld a, [H_WHOSETURN]
	and a
	ld hl, wBattleMonMoves
	jr z, .gotCopiedMoveList
	ld hl, wEnemyMonMoves
.gotCopiedMoveList
	ld b, 0
	ld a, c
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	and a
	jr nz, .copiedMoveFound
	pop bc
	inc c
	ld a, c
	and 3
	ld c, a
	dec b
	jr nz, .scanCopiedMove
	; Defensive fallback for malformed/empty move lists; ordinary battles
	; normally have at least one real move to copy.
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemyStruggle
	ld a, STRUGGLE
	ld [wPlayerSelectedMove], a
	xor a
	ld [wPlayerMoveListIndex], a
IF DEF(BATTLE_TEST_BUILD)
	jp .loadPlayerFollowup ; test-only fixed-slot selection grows this routine
ELSE
	jr .loadPlayerFollowup ; original official-ROM encoding
ENDC
.enemyStruggle
	ld a, STRUGGLE
	ld [wEnemySelectedMove], a
	xor a
	ld [wEnemyMoveListIndex], a
	jr .loadEnemyFollowup
.copiedMoveFound
	pop bc
	ld d, a ; preserve move ID while storing the selected slot index
	ld a, [H_WHOSETURN]
	and a
	jr nz, .storeEnemyCopiedMove
	ld a, c
	ld [wPlayerMoveListIndex], a
	ld a, d
	ld [wPlayerSelectedMove], a
IF DEF(BATTLE_TEST_BUILD)
	jp .loadPlayerFollowup
ELSE
	jr .loadPlayerFollowup
ENDC
.storeEnemyCopiedMove
	ld a, c
	ld [wEnemyMoveListIndex], a
	ld a, d
	ld [wEnemySelectedMove], a
.loadEnemyFollowup
	callab GetCurrentMove
	ld hl, CheckIfEnemyNeedsToChargeUp
	ret
.playerDone
	ld hl, ExecutePlayerMoveDone
	ret
.enemyDone
	ld hl, ExecuteEnemyMoveDone
	ret
.failed
	; Failed Transform consumes only the already-started Transform action.
	ld a, [H_WHOSETURN]
	and a
	ld hl, ExecutePlayerMoveDone
	jr z, .returnContinuation
	ld hl, ExecuteEnemyMoveDone
.returnContinuation
	ret
