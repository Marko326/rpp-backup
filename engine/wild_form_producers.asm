; WLD-5.61.61: explicit-form bridges for wild producers that select an entry
; outside the normal grass/water encounter routine. Keep these helpers in roomy
; bank $3B instead of adding producer-specific logic to tight bank $03 / $34.

; CALLBA restores the caller ROM bank through A and uses BC/HL internally, so
; arguments and return values that must survive the bank switch travel through DE.
; D = stock rod response (0/2) or REGIONAL_FISHING_SLOT_FLAG | 0-based slot.
; E = selected Species for a bite. Returns the normalized stock response in E.
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
