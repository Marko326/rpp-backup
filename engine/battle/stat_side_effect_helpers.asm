; BSE-5.62.38: shared damaging stat-side-effect framework.
; Keep probability policy and pre-KO user-side stat effects out of crowded Bank F.

; BSE-5.62.38: resolve the current move for the unified stat-side-effect
; framework without changing HOME's general GetCurrentMoveID contract. In an
; automated Test Battle, the dedicated slot stores the root test move; once
; Metronome or a direct Mirror Move copy has selected a child, the real child
; lives in wPlayerSelectedMove instead.
GetDamageSideEffectMoveID:
GetStatSideEffectMoveID:
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wFlags_D733]
	bit BIT_TEST_BATTLE, a
	jr z, .playerSelected
	ld a, [wMoveDexPlayerMetronomeDerived]
	and a
	jr nz, .playerSelected
	ld a, [wPlayerBattleStatus3]
	bit MirrorMoveBoost, a
	jr nz, .playerSelected
	ld a, [wTestBattlePlayerSelectedMove]
	ret
.playerSelected
	ld a, [wPlayerSelectedMove]
	ret
.enemy
	ld a, [wEnemySelectedMove]
	ret

; SUB-5.62.42: apply damaging user-side stat effects before target-KO exit.
; Recoil is now resolved separately before the attacker's Substitute returns.
; The stock stat-up helpers temporarily replace the move effect and clear the
; animation ID, so preserve both fields across the far call back into Bank F.
HandleSelfStatAfterDamageEffect:
	; Resolve by real Move ID, not the mutable move-effect byte. Breaking a
	; Substitute can clear that byte before this point, but user-side effects
	; (including Draco Meteor's self-drop) must still resolve after a hit.
	call GetStatSideEffectMoveID
	ld c, a
	ld hl, SelfStatAfterDamageMoveEffects
.findMove
	ld a, [hli]
	cp -1
	ret z
	cp c
	jr z, .foundMove
	inc hl ; skip effect byte
	jr .findMove
.foundMove
	ld c, [hl] ; effect to dispatch

	ld hl, wPlayerMoveEffect
	ld de, wPlayerMoveNum
	ld a, [H_WHOSETURN]
	and a
	jr z, .saveAndRun
	ld hl, wEnemyMoveEffect
	ld de, wEnemyMoveNum
.saveAndRun
	ld a, [hl]
	push af
	ld a, [de]
	push af
	ld a, c
	ld [hl], a
	callab JumpMoveEffect

	; Stat-up helpers may replace the effect byte and clear the animation ID.
	; Rebuild the side pointers because the far call is allowed to clobber them.
	ld hl, wPlayerMoveEffect
	ld de, wPlayerMoveNum
	ld a, [H_WHOSETURN]
	and a
	jr z, .restore
	ld hl, wEnemyMoveEffect
	ld de, wEnemyMoveNum
.restore
	pop af
	ld [de], a
	pop af
	ld [hl], a
	ret

SelfStatAfterDamageMoveEffects:
	db METAL_CLAW,   ATTACK_UP1_SIDE_EFFECT
	db METEOR_MASH,  ATTACK_UP1_SIDE_EFFECT
	db STEEL_WING,   DEFENSE_UP1_SIDE_EFFECT
	db SILVER_WIND,  SILVER_WIND_EFFECT
	db ANCIENTPOWER, SILVER_WIND_EFFECT
	db MIND_BLAST,   SILVER_WIND_EFFECT
	db DRACO_METEOR, SELF_SPECIAL_DOWN1_EFFECT
	db -1

; Resolve damaging stat-change secondary chances by real Move ID instead of
; encoding probability into the effect ID. A zero table value means guaranteed;
; unlisted legacy users retain Red's old 85/256 (~33%) fallback. Carry = success.
RollStatSideEffectChance:
	call GetStatSideEffectMoveID
	ld c, a
	ld hl, StatSideEffectChanceTable
.loop
	ld a, [hli]
	cp -1
	jr z, .legacyDefault
	cp c
	jr z, .found
	inc hl ; skip chance byte
	jr .loop
.found
	ld a, [hl]
	jr .roll
.legacyDefault
	ld a, $55 ; preserve old 85/256 behaviour for any unlisted legacy user
.roll
	and a
	jr z, .always
	ld d, a
	callab BattleRandomFar
	ld a, e
	cp d
	ret
.always
	scf
	ret

StatSideEffectChanceTable:
; 10% (26/256 = 10.16%)
	db BUBBLEBEAM,   $1a
	db AURORA_BEAM,  $1a
	db CONSTRICT,    $1a
	db BUBBLE,       $1a
	db ACID,         $1a
	db PSYCHIC_M,    $1a
	db METAL_CLAW,   $1a
	db FLASH_CANNON, $1a
	db MOONBLAST,    $1a ; Gen I Special balance: modern 30% Sp. Atk drop -> 10% Special drop
	db SHADOW_BALL,  $1a ; Gen I Special balance: modern 20% Sp. Def drop -> 10% Special drop
	db ENERGY_BALL,  $1a
	db SILVER_WIND,  $1a
	db BUG_BUZZ,     $1a
	db EARTH_POWER,  $1a
	db ANCIENTPOWER, $1a
	db MIND_BLAST,   $1a

; 20% (51/256 = 19.92%)
	db METEOR_MASH,  $33
	db CRUNCH,       $33

; 30% (77/256 = 30.08%)
	db IRON_TAIL,    $4d
	db STEEL_WING,   $4d ; RPP custom balance: 30% user Defense +1
	db MUDDY_WATER,  $4d
	db MUD_BOMB,     $4d
	db LUSTER_PURGE, $4d ; Gen I Special balance signature chance

; Guaranteed on a successful damaging hit.
	db ICY_WIND,     $00
	db MUD_SLAP,     $00
	db ROCK_TOMB,    $00
	db LOW_SWEEP,    $00
	db -1
