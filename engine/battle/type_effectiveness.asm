; Type effectiveness and STAB calculations moved out of Bank F.
; Keep the battle and AI paths together with the shared TypeEffects table.
;
; TypeEffects stays compact in ROM while readable macros describe each relationship.
; Group headers use bit 7; matchup bytes keep bit 7 clear, so every relationship
; still costs only one byte.

TYPE_EFFECT_TYPE_MASK    EQU $1f
TYPE_EFFECT_IMMUNE_CODE  EQU $00
TYPE_EFFECT_NVE_CODE     EQU $20
TYPE_EFFECT_SE_CODE      EQU $40
TYPE_EFFECT_MULT_MASK    EQU $60
TYPE_EFFECT_GROUP_FLAG   EQU $80

; Readable source macros. These still emit one byte per matchup.
; ASSERT prevents future type IDs from being silently truncated.
type_effect_group: MACRO
	assert (\1) <= TYPE_EFFECT_TYPE_MASK
	db TYPE_EFFECT_GROUP_FLAG | (\1)
ENDM

super_effective: MACRO
	assert (\1) <= TYPE_EFFECT_TYPE_MASK
	db (\1) | TYPE_EFFECT_SE_CODE
ENDM

not_very_effective: MACRO
	assert (\1) <= TYPE_EFFECT_TYPE_MASK
	db (\1) | TYPE_EFFECT_NVE_CODE
ENDM

no_effect: MACRO
	assert (\1) <= TYPE_EFFECT_TYPE_MASK
	db (\1) | TYPE_EFFECT_IMMUNE_CODE
ENDM

; Input:  A = attacking type
; Output: HL = first packed matchup in that attacking-type group
;         carry set if the group exists, clear if it does not
; Clobbers: A, C, HL
FindTypeEffectGroup:
	ld c, a
	ld hl, TypeEffects
.nextGroup
	ld a, [hli]
.nextHeader
	cp $ff
	ret z ; equal also clears carry
	and TYPE_EFFECT_TYPE_MASK
	cp c
	jr z, .found
.skipGroup
	ld a, [hli]
	bit 7, a
	jr z, .skipGroup
	jr .nextHeader
.found
	scf
	ret

; Input:  D = attacking type, B = defending type
; Output: A = multiplier (0, 5, 10, or 20)
; Clobbers: A, C, HL
GetTypeEffectivenessForDefender:
	ld a, d
	call FindTypeEffectGroup
	ld a, 10
	ret nc
.loop
	ld a, [hli]
	bit 7, a
	jr nz, .neutral
	ld c, a
	and TYPE_EFFECT_TYPE_MASK
	cp b
	jr z, .match
	jr .loop
.match
	ld a, c
	and TYPE_EFFECT_MULT_MASK
	ret z ; immunity: A = 0
	cp TYPE_EFFECT_NVE_CODE
	ld a, 5
	ret z
	ld a, 20
	ret
.neutral
	ld a, 10
	ret

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
	call FindTypeEffectGroup
	jr nc, StoreDamage
.loop
	ld a,[hli]
	bit 7, a
	jp nz, StoreDamage
	ld c,a
	and TYPE_EFFECT_TYPE_MASK
	cp d ; does type 1 of defender match?
	jr z,.matchingPairFound
	cp e ; does type 2 of defender match?
	jr z,.matchingPairFound
	jr .loop
.matchingPairFound
; if the move type and one of the defender's types match this packed matchup
	push hl
	push bc
	ld a,c
	and TYPE_EFFECT_MULT_MASK
	jr z,.typeImmunityDone
	cp TYPE_EFFECT_NVE_CODE
	ld a,5
	ld hl,wDamageMultipliers
	jr z,.nve
	ld a,20
	set 1,[hl]
	jr .multiply
.nve
	set 0,[hl]
.multiply
	ld [H_MULTIPLIER],a
	call Multiply

; divide by 10
	ld a,10
	ld [H_DIVISOR], a
	ld b,$04
	call Divide

	pop bc
	pop hl
	jr .loop

.typeImmunityDone
; keep the old immunity path's H_MULTIPLIER = 0 side effect
	ld [H_MULTIPLIER],a
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
	ld b,[hl]                 ; b = type 1 of player's pokemon
	call GetTypeEffectivenessForDefender
	ld [H_MULTIPLIER],a
	ld hl,wBattleMonType+1
	ld a,[hl]
	cp b
	jr nz,.checksecondtype
	ld a,[H_MULTIPLIER]
	ld [wTypeEffectiveness], a
	ret
.checksecondtype
	ld b,[hl]
	xor a
	ld [H_MULTIPLICAND],a
	ld [H_MULTIPLICAND+1],a
	ld a,10
	ld [H_MULTIPLICAND+2],a
	call GetTypeEffectivenessForDefender
	ld [H_MULTIPLICAND+2],a
	call Multiply
	ld a, 10
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT+3]
	ld [wd11e], a
	ret

INCLUDE "data/type_effects.asm"
