; Type effectiveness and STAB calculations moved out of Bank F.
; Keep the battle and AI paths together with the shared TypeEffects table.

; function to adjust the base damage of an attack to account for type effectiveness
AdjustDamageForMoveType:
; values for player turn
	ld hl,wBattleMonType
	ld a,[hli]
	ld b,a    ; b = type 1 of attacker
	ld c,[hl] ; c = type 2 of attacker
	ld hl,wEnemyMonType
	ld a,[hli]
	ld d,a    ; d = type 1 of defender
	ld e,[hl] ; e = type 2 of defender
	ld a,[wPlayerMoveType]
	ld [wMoveType],a
	ld a,[H_WHOSETURN]
	and a
	jr z,.next
; values for enemy turn
	ld hl,wEnemyMonType
	ld a,[hli]
	ld b,a    ; b = type 1 of attacker
	ld c,[hl] ; c = type 2 of attacker
	ld hl,wBattleMonType
	ld a,[hli]
	ld d,a    ; d = type 1 of defender
	ld e,[hl] ; e = type 2 of defender
	ld a,[wEnemyMoveType]
	ld [wMoveType],a
.next
; store wDamage in the multiplicand beforehand
	xor a
	ld [H_MULTIPLICAND], a
	ld hl, wDamage
	ld a, [hli]
	ld [H_MULTIPLICAND + 1], a
	ld a, [hl]
	ld [H_MULTIPLICAND + 2], a
; continue on
	ld a,[wMoveType] ; move type
	cp b ; does the move type match type 1 of the attacker?
	jr z,.sameTypeAttackBonus
	cp c ; does the move type match type 2 of the attacker?
	jr z,.sameTypeAttackBonus
	jr .skipSameTypeAttackBonus
.sameTypeAttackBonus
; if the move type matches one of the attacker's types
; multiply by 3/2
	ld hl, H_MULTIPLIER
	ld [hl], 3
	call Multiply
	
	ld [hl], 2
	ld b, 4
	call Divide
	
	ld hl,wDamageMultipliers
	set 7,[hl] ; STAB
.skipSameTypeAttackBonus
	ld a,[wMoveType]
	ld b,a
	ld hl,TypeEffects
.loop
	ld a,[hli] ; a = "attacking type" of the current type pair
	cp a,$ff
	jr z, StoreDamage
	cp b ; does move type match "attacking type"?
	jr nz,.nextTypePair
	ld a,[hl] ; a = "defending type" of the current type pair
	cp d ; does type 1 of defender match "defending type"?
	jr z,.matchingPairFound
	cp e ; does type 2 of defender match "defending type"?
	jr z,.matchingPairFound
	jr .nextTypePair
.matchingPairFound
; if the move type matches the "attacking type" and one of the defender's types matches the "defending type"
	push hl
	push bc
	inc hl
	ld a,[hl] ; a = damage multiplier
	ld [H_MULTIPLIER],a
	
; done if type immunity
	and a
	jr z, .typeImmunityDone
	
; update damage multipliers
	cp $a
	ld hl, wDamageMultipliers
	jr c, .nve
	set 1, [hl]
	jr .multiply
.nve
	set 0, [hl]
; apply damage multiplier
.multiply
	call Multiply

; divide by 10
	ld a,10
	ld [H_DIVISOR], a
	ld b,$04
	call Divide

	pop bc
	pop hl
.nextTypePair
	inc hl
	inc hl
	jp .loop
	
.typeImmunityDone
	call StoreDamage
	ld a, $7f
	ld [wDamageMultipliers], a
	ld a, 1
	ld [wMoveMissed], a
	pop bc
	pop hl
	ret
	
StoreDamage:
; store the result of those multiply/divide operations back in wDamage
	ld hl, wDamage
	ld a, [H_QUOTIENT + 2]
	ld [hli], a
	ld a, [H_QUOTIENT + 3]
	ld [hl], a
	ret

; function to tell how effective the type of an enemy attack is on the player's current pokemon
; modified to take dual types into effect
; the result is stored in [wTypeEffectiveness]
; ($00 immune; $02 or $05 NVE; $0a neutral; $14 or $28 SE)
; as far is can tell, this is only used once in some AI code to help decide which move to use
AIGetTypeEffectiveness:
	ld a,[wEnemyMoveType]
	ld d,a                    ; d = type of enemy move
	ld hl,wBattleMonType
	ld b,[hl]              ; b = type 1 of player's pokemon
	ld a,10
	ld [H_MULTIPLIER],a           ; initialize [wd11e] to neutral effectiveness
	ld hl,TypeEffects
.loop
	ld a,[hli]
	cp a,$ff
	jr z, .start2
	cp d                   ; match the type of the move
	jr nz,.nextTypePair1
	ld a,[hli]
	cp b                   ; match with type 1 of pokemon
	jr z,.match
	jr .nextTypePair2
.nextTypePair1
	inc hl
.nextTypePair2
	inc hl
	jr .loop
.match
	ld a,[hl]
	ld [H_MULTIPLIER],a           ; store damage multiplier
.start2
    ld hl,wBattleMonType+1
    ld a,[hl]
    cp b
    jr nz,.checksecondtype
    ld a, [H_MULTIPLIER]
    ld [wTypeEffectiveness], a
	ret
.checksecondtype
    ld b,[hl]
    xor a
    ld [H_MULTIPLICAND],a
    ld [H_MULTIPLICAND+1],a
    ld a,10
    ld [H_MULTIPLICAND+2],a
    ld hl,TypeEffects
.loop2
    ld a,[hli]
    cp a,$ff
    jr z,.multandret
    cp d ; match the type
    jr nz, .nextTypePair3
    ld a,[hli]
    cp b ; match with type 2 of pokemon
    jr z,.match2
    jr .nextTypePair4
.nextTypePair3
    inc hl
.nextTypePair4
    inc hl
    jr .loop2
.match2
    ld a,[hl]
    ld [H_MULTIPLICAND+2],a
.multandret
    call Multiply
    ld a, 10
    ld [H_DIVISOR], a
    ld b, 4
    call Divide
    ld a, [H_QUOTIENT+3]
    ld [wd11e], a
    ret

INCLUDE "data/type_effects.asm"
