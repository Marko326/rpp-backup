; Type effectiveness and STAB calculations moved out of Bank F.
; Keep the battle and AI paths together with the shared TypeEffects table.
;
; TypeEffects stays compact in ROM, but the source uses readable macros such as
; type_effect_group / super_effective / not_very_effective / no_effect.
; Move-specific exceptions live in MoveTypeEffectOverrides instead of polluting
; the global type chart.

TYPE_EFFECT_TYPE_MASK  EQU $1f
TYPE_EFFECT_IMMUNE_CODE EQU $00
TYPE_EFFECT_NVE_CODE    EQU $20
TYPE_EFFECT_SE_CODE     EQU $40
TYPE_EFFECT_MULT_MASK   EQU $60
TYPE_EFFECT_GROUP_FLAG  EQU $80

; Base chart source macros. ASSERT prevents future type IDs from being silently
; truncated by the five-bit packed representation.
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

; Move-specific rules stay explicit and rare. Generic form is available for
; future custom moves; named wrappers keep common cases readable.
move_type_effect_override: MACRO
	assert (\2) <= TYPE_EFFECT_TYPE_MASK
	db \1, \2, \3
ENDM

immune_type_override: MACRO
	move_type_effect_override \1, \2, 0
ENDM

not_very_effective_override: MACRO
	move_type_effect_override \1, \2, 5
ENDM

neutral_type_override: MACRO
	move_type_effect_override \1, \2, 10
ENDM

super_effective_override: MACRO
	move_type_effect_override \1, \2, 20
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

; Input:  A = attacking type, B = defending type
; Output: A = multiplier (0, 5, 10, or 20)
; Clobbers: A, C, HL
GetTypeEffectivenessForDefender:
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

; Input:  A = move ID, B = defending type
; Output: A = override multiplier, carry set if an override exists
; Clobbers: A, C, HL
GetMoveTypeEffectOverride:
	ld c, a
	ld hl, MoveTypeEffectOverrides
.loop
	ld a, [hli]
	and a
	ret z ; move ID 0 terminates the exception table and clears carry
	cp c
	jr nz, .skipEntry
	ld a, [hli]
	cp b
	jr z, .found
	inc hl ; skip multiplier
	jr .loop
.skipEntry
	inc hl ; skip defending type
	inc hl ; skip multiplier
	jr .loop
.found
	ld a, [hl]
	scf
	ret

; Input:  D = move ID, E = attacking type, B = defending type
; Output: A = multiplier (move override first, then global chart)
; Clobbers: A, C, HL
GetTypeEffectivenessForMoveAndDefender:
	ld a, d
	call GetMoveTypeEffectOverride
	ret c
	ld a, e
	jp GetTypeEffectivenessForDefender

; Input: A = multiplier (0, 5, 10, or 20)
; Output: carry set only when immunity was applied
; Clobbers: A, B, HL
ApplyTypeMultiplierValue:
	cp 10
	ret z
	and a
	jr z, .immune
	cp 5
	ld hl, wDamageMultipliers
	jr z, .nve
	set 1, [hl]
	jr .multiply
.nve
	set 0, [hl]
.multiply
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, 10
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	and a ; clear carry
	ret
.immune
	ld [H_MULTIPLIER], a
	call StoreDamage
	ld a, $7f
	ld [wDamageMultipliers], a
	ld a, 1
	ld [wMoveMissed], a
	scf
	ret

; Apply an override only when the global chart would otherwise be neutral.
; This lets future custom moves create new SE/NVE/immunity relationships without
; changing ordinary moves or re-applying overrides that replaced an existing rule.
; Input: A = defending type, B = move ID
; Output: carry set only when an immunity override was applied
; Preserves: B, D, E
ApplyNeutralMoveOverride:
	push bc
	push de
	ld e, a ; temporary defending type
	ld a, b ; move ID
	ld b, e
	call GetMoveTypeEffectOverride
	jr nc, .noApply
	ld d, a ; save override multiplier
	ld a, [wMoveType]
	call GetTypeEffectivenessForDefender
	cp 10
	jr nz, .noApply
	ld a, d
	call ApplyTypeMultiplierValue
	pop de
	pop bc
	ret
.noApply
	pop de
	pop bc
	and a ; clear carry
	ret

; Input: B = move ID, D/E = defender types
; Output: carry set only when an immunity override was applied
ApplyNeutralMoveOverrides:
	ld a, d
	call ApplyNeutralMoveOverride
	ret c
	ld a, d
	cp e
	ret z
	ld a, e
	jp ApplyNeutralMoveOverride

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
	call GetCurrentMoveID
	ld b, a ; keep the real move ID for move-specific type overrides
	ld a,[wMoveType]
	call FindTypeEffectGroup
	jr nc, .applyNeutralOverrides
.loop
	ld a,[hli]
	bit 7, a
	jr nz, .applyNeutralOverrides
	ld c,a
	and TYPE_EFFECT_TYPE_MASK
	cp d ; does type 1 of defender match?
	jr z,.matchingType1
	cp e ; does type 2 of defender match?
	jr z,.matchingType2
	jr .loop
.matchingType1
	ld a, d
	jr .matchingPairFound
.matchingType2
	ld a, e
.matchingPairFound
; If this move overrides the matched defender type, use the override. Otherwise
; decode the ordinary packed multiplier. Save scan state around helper calls.
	push hl
	push bc
	push de
	ld e, a ; temporary matched defender type
	ld a, b ; move ID
	ld b, e
	call GetMoveTypeEffectOverride
	jr c, .applyMatchedMultiplier
	pop de
	pop bc
	ld a, c
	and TYPE_EFFECT_MULT_MASK
	jr z, .baseMultiplierReady
	cp TYPE_EFFECT_NVE_CODE
	ld a, 5
	jr z, .baseMultiplierReady
	ld a, 20
.baseMultiplierReady
	push bc
	push de
.applyMatchedMultiplier
	call ApplyTypeMultiplierValue
	pop de
	pop bc
	pop hl
	ret c
	jr .loop
.applyNeutralOverrides
; Overrides for relationships absent from the base table are applied here.
; Existing base relationships were already replaced in-place above, preserving
; the original chart order for ordinary damage calculations.
	call ApplyNeutralMoveOverrides
	ret c
	jp StoreDamage

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
; D is supplied by trainer AI as the candidate move ID so move-specific overrides
; are evaluated consistently with real battle damage.
AIGetTypeEffectiveness:
	ld a,[wEnemyMoveType]
	ld e,a                    ; e = type of enemy move
	ld hl,wBattleMonType
	ld b,[hl]                 ; b = type 1 of player's pokemon
	call GetTypeEffectivenessForMoveAndDefender
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
	call GetTypeEffectivenessForMoveAndDefender
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
