; WLD-5.62.23: wild/fishing producer helpers live in roomy bank $3B.
; This keeps producer data out of capacity-constrained bank $34 and moves the
; fishing-only shiny-chain helper out of packed bank $03.

; D = map id, E = encounter selector (source + exact slot).
; Returns A = runtime form and carry set when that exact producer slot is mapped.
RegionalFormFindWildForm::
	ld hl,RegionalFormWildEncounters
.loop
	ld a,[hl]
	cp $ff
	jr z,.notFound
	cp d
	jr nz,.next
	inc hl
	ld a,[hl]
	dec hl
	cp e
	jr nz,.next
	inc hl
	inc hl
	ld a,[hl]
	scf
	ret
.next
	ld bc,RF_WILD_SIZE
	add hl,bc
	jr .loop
.notFound
	and a
	ret

; Far-call-safe byte-return wrapper. CALLBA consumes A while restoring the
; caller bank, so return the runtime form in E and the match state in carry.
RegionalFormGetWildFormBySlot::
	call RegionalFormFindWildForm
	ret nc
	ld e,a
	scf
	ret

; D = stock rod response (0/2) or bite-flag + exact slot.
; E = hooked Species on bites. Returns normalized stock RodResponse (0/1/2) in E.
RegionalFormStageFishingRodResponse::
	bit 7,d
	jr nz,.bite
	ld e,d
	ret
.bite
	ld a,e
	ld [wEnemyMonSpecies2],a
	ld a,d
	and REGIONAL_WILD_SLOT_MASK
	ld e,a
	ld a,[wRepeatFishingRod]
	cp OLD_ROD
	jr z,.oldRod
	cp GOOD_ROD
	jr z,.goodRod
	ld a,e
	or REGIONAL_WILD_SUPER_ROD
	jr .sourceReady
.oldRod
	ld a,e
	or REGIONAL_WILD_OLD_ROD
	jr .sourceReady
.goodRod
	ld a,e
	or REGIONAL_WILD_GOOD_ROD
.sourceReady
	ld e,a
	ld a,[wCurMap]
	ld d,a
	callba RegionalFormStageWildEncounter
	ld e,1
	ret

; Fishing-only shiny-chain helper moved from bank $03. The bank-$03 caller
; preserves BC around CALLBA because BC contains the selected level/species.
CheckChainFishingShiny::
	push de
	push bc
	ld a,[wChainFishingStreak]
	cp 21
	jr c,.ok
	ld a,20
.ok
	sla a
	push af
	ld a,[wChainFishingStreak]
	cp $ff
	jr z,.maxChain
	inc a
	ld [wChainFishingStreak],a
.maxChain
	pop af
	ld e,a
	inc e
.loop
	dec e
	jr z,.end
	call Random
	cp $aa
	jr nz,.loop
	ld hl,wExtraFlags
	set 0,[hl]
	xor a
	ld [wChainFishingStreak],a
.end
	pop bc
	pop de
	ret
