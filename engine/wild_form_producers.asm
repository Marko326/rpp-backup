; WLD-5.61.62: explicit-form bridges for wild producers that select an entry
; outside the normal grass/water encounter routine. Keep these helpers in roomy
; bank $3B instead of adding producer-specific logic to tight producer banks.

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

; WLD-5.61.62: shared static-wild staging. E = source | 0-based slot.
; Scripted static encounters enter through the ROM0 bridge; OW_POKEMON objects
; use the wrapper below so the exact map object id becomes the slot identity.
RegionalFormStageStaticEncounter::
	ld a,[wCurOpponent]
	ld [wEnemyMonSpecies2],a
	ld a,[wCurMap]
	ld d,a
	callba RegionalFormStageWildEncounter
	ret

RegionalFormStageStaticObjectEncounter::
	ld a,[wSpriteIndex]
	dec a ; object ids are 1-based; producer slots are 0-based
	cp REGIONAL_WILD_SLOT_MASK + 1
	jr nc,.unsupportedObject
	or REGIONAL_WILD_STATIC_OBJECT
	ld e,a
	jr RegionalFormStageStaticEncounter
.unsupportedObject
	; More than 16 map objects cannot be represented by the selector's low nybble.
	; Route such an unsupported object through an impossible selector so staging
	; explicitly clears transient Form instead of aliasing another object slot.
	ld e,$ff
	jr RegionalFormStageStaticEncounter
